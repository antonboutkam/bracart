#!/usr/bin/env python3
"""Inspect a local GLB without modifying it. Structural checks, not full Khronos validation."""
import argparse,json,struct,sys
from pathlib import Path
import numpy as np


def inspect(path):
    raw=path.read_bytes()
    if len(raw)<20:raise ValueError('Truncated GLB')
    magic,version,length=struct.unpack_from('<III',raw)
    if magic!=0x46546c67 or version!=2 or length!=len(raw):raise ValueError('Invalid GLB 2.0 header')
    offset=12;doc=None;binary=b''
    while offset<len(raw):
        size,kind=struct.unpack_from('<II',raw,offset);offset+=8
        if offset+size>len(raw):raise ValueError('Chunk outside GLB container')
        chunk=raw[offset:offset+size];offset+=size
        if kind==0x4e4f534a:doc=json.loads(chunk)
        elif kind==0x004e4942:binary=chunk
    if doc is None:raise ValueError('Missing JSON chunk')
    dtype={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}
    widths={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT2':4,'MAT3':9,'MAT4':16}
    for view in doc.get('bufferViews',[]):
        if view.get('buffer',0)==0 and view.get('byteOffset',0)+view['byteLength']>len(binary):
            raise ValueError('Buffer view outside binary chunk')
    def accessor(index):
        a=doc['accessors'][index]
        if 'sparse' in a:raise ValueError('Sparse accessors require a full glTF validator')
        view=doc['bufferViews'][a['bufferView']]
        if view.get('buffer',0)!=0:raise ValueError('External buffers are not loaded by this audit')
        dt=np.dtype(dtype[a['componentType']]);width=widths[a['type']]
        stride=view.get('byteStride',dt.itemsize*width);start=a.get('byteOffset',0)
        span=(a['count']-1)*stride+dt.itemsize*width if a['count'] else 0
        if start+span>view['byteLength']:raise ValueError('Accessor outside buffer view')
        return np.ndarray((a['count'],width),dtype=dt,buffer=binary,offset=view.get('byteOffset',0)+start,strides=(stride,dt.itemsize))
    positions={};triangles=0;degenerate=0;primitives=0;without_material=0;warnings=[]
    for i,m in enumerate(doc.get('meshes',[])):
        pp=[]
        for p in m['primitives']:
            primitives+=1;pos=accessor(p['attributes']['POSITION']);pp.append(pos)
            if not np.isfinite(pos).all():raise ValueError('Nonfinite vertex position')
            for name,a in p['attributes'].items():
                if not np.isfinite(accessor(a)).all():raise ValueError(f'Nonfinite {name}')
            ix=accessor(p['indices']).ravel() if 'indices' in p else np.arange(len(pos))
            if len(ix) and (ix.min()<0 or ix.max()>=len(pos)):raise ValueError('Vertex index outside positions')
            mode=p.get('mode',4)
            if mode==4:
                if len(ix)%3:raise ValueError('Incomplete triangle')
                faces=ix.reshape(-1,3)
            elif mode==5:
                faces=np.array([[ix[k],ix[k+1],ix[k+2]] for k in range(max(0,len(ix)-2))],dtype=int).reshape(-1,3)
            elif mode==6:
                faces=np.array([[ix[0],ix[k],ix[k+1]] for k in range(1,len(ix)-1)],dtype=int).reshape(-1,3)
            else:
                warnings.append(f'Nontriangle primitive mode {mode}');faces=np.empty((0,3),int)
            vv=pos[faces];triangles+=len(faces)
            degenerate+=int((np.linalg.norm(np.cross(vv[:,1]-vv[:,0],vv[:,2]-vv[:,0]),axis=1)<1e-12).sum())
            without_material+=int('material' not in p)
        positions[i]=np.concatenate(pp) if pp else np.empty((0,3))
    def transform(node):
        if 'matrix' in node:return np.array(node['matrix']).reshape(4,4).T
        x,y,z,w=node.get('rotation',[0,0,0,1]);R=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
        out=np.eye(4);out[:3,:3]=R@np.diag(node.get('scale',[1,1,1]));out[:3,3]=node.get('translation',[0,0,0]);return out
    all_points=[];nodes=[]
    def visit(i,parent,ancestors):
        if i in ancestors:raise ValueError('Cycle in node hierarchy')
        node=doc['nodes'][i];world=parent@transform(node);entry={'name':node.get('name',str(i)),'pivot_xyz':world[:3,3].tolist()}
        if 'mesh' in node:
            pos=positions[node['mesh']];v=(world@np.c_[pos,np.ones(len(pos))].T).T[:,:3]
            if len(v):
                all_points.append(v);entry.update(min_xyz=v.min(0).tolist(),max_xyz=v.max(0).tolist())
        nodes.append(entry)
        for child in node.get('children',[]):visit(child,world,ancestors|{i})
    for i in doc['scenes'][doc.get('scene',0)]['nodes']:visit(i,np.eye(4),set())
    if not all_points:raise ValueError('No visible mesh vertices')
    pts=np.concatenate(all_points);lo=pts.min(0);hi=pts.max(0)
    external=[r['uri'] for key in ['buffers','images'] for r in doc.get(key,[]) if 'uri' in r and not r['uri'].startswith('data:')]
    if external:warnings.append('External resources present')
    if degenerate:warnings.append(f'{degenerate} collapsed triangles')
    if without_material:warnings.append(f'{without_material} primitives use glTF default material')
    return {'file':str(path),'size_bytes':len(raw),'container':'GLB 2.0','generator':doc.get('asset',{}).get('generator'),'triangles':triangles,'degenerate_triangles':degenerate,'mesh_count':len(doc.get('meshes',[])),'draw_primitives':primitives,'materials':len(doc.get('materials',[])),'embedded_images':sum('bufferView' in i for i in doc.get('images',[])),'external_resources':external,'min_xyz_m':lo.tolist(),'max_xyz_m':hi.tolist(),'dimensions_xyz_m':(hi-lo).tolist(),'nodes':nodes,'warnings':warnings,'structural_checks_passed':True,'scope':'Local binary/accessor/geometry checks; not a full Khronos validator or an engine test.'}


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('glb',type=Path);p.add_argument('--report',type=Path);p.add_argument('--strict',action='store_true');args=p.parse_args()
    try:r=inspect(args.glb.resolve())
    except (ValueError,KeyError,IndexError,OSError,struct.error) as e:p.exit(1,f'Audit failed: {e}\n')
    if args.report:args.report.parent.mkdir(parents=True,exist_ok=True);args.report.write_text(json.dumps(r,indent=2)+'\n')
    brief={k:v for k,v in r.items() if k!='nodes'};print(json.dumps(brief,indent=2))
    if args.strict and r['warnings']:p.exit(1,'Strict audit failed; see warnings.\n')

if __name__=='__main__':main()
