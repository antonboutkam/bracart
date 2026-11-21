"""Structural GLB checks. This is not the Khronos validator or a Godot runtime test."""
import json,struct,math
from pathlib import Path
import numpy as np
import sys
NAME=sys.argv[1]
P=Path(__file__).resolve().parents[1]/NAME
b=(P/f'{NAME}-improved.glb').read_bytes()
magic,version,length=struct.unpack_from('<III',b)
assert magic==0x46546c67 and version==2 and length==len(b)
n,t=struct.unpack_from('<II',b,12);assert t==0x4e4f534a
d=json.loads(b[20:20+n]);off=20+n;n,t=struct.unpack_from('<II',b,off);assert t==0x004e4942
binary=b[off+8:off+8+n]
components={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}
sizes={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
def acc(i):
 a=d['accessors'][i];v=d['bufferViews'][a['bufferView']];dt=np.dtype(components[a['componentType']]);width=sizes[a['type']]
 start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',dt.itemsize*width)
 return np.ndarray((a['count'],width),dtype=dt,buffer=binary,offset=start,strides=(stride,dt.itemsize))
triangles=0;degenerate=0;primitives=0
for v in d['bufferViews']:assert v.get('byteOffset',0)+v['byteLength']<=len(binary)
for m in d['meshes']:
 for p in m['primitives']:
  primitives+=1;assert p.get('mode',4)==4
  pos=acc(p['attributes']['POSITION']);assert np.isfinite(pos).all()
  ix=acc(p['indices']).reshape(-1);assert ix.max()<len(pos) and len(ix)%3==0
  tris=pos[ix.reshape(-1,3)];areas=np.linalg.norm(np.cross(tris[:,1]-tris[:,0],tris[:,2]-tris[:,0]),axis=1)
  degenerate+=int((areas<1e-12).sum());triangles+=len(ix)//3
  if 'NORMAL' in p['attributes']:assert np.isfinite(acc(p['attributes']['NORMAL'])).all()
  assert p.get('material') is not None
for im in d.get('images',[]):assert 'bufferView' in im and 'uri' not in im
for buf in d['buffers']:assert 'uri' not in buf
assert degenerate==0, f'{degenerate} collapsed triangles'
wheel_nodes=[n for n in d['nodes'] if n.get('name') in ['Wheel_Rear_L','Wheel_Rear_R']]
assert len(wheel_nodes)==2
assert all(n.get('children') for n in wheel_nodes)
for n in wheel_nodes:assert abs(n['translation'][1]-.211)<.001 and abs(n['translation'][2]-.387)<.001
# Resolve node transforms and measure the exported glTF, including hierarchy.
def matrix(n):
 if 'matrix' in n:return np.array(n['matrix']).reshape(4,4).T
 x,y,z,w=n.get('rotation',[0,0,0,1]);R=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
 M=np.eye(4);M[:3,:3]=R@np.diag(n.get('scale',[1,1,1]));M[:3,3]=n.get('translation',[0,0,0]);return M
world={}
def visit(i,parent):
 n=d['nodes'][i];world[i]=parent@matrix(n)
 for ch in n.get('children',[]):visit(ch,world[i])
for i in d['scenes'][d.get('scene',0)]['nodes']:visit(i,np.eye(4))
points=[];centers={}
for i,n in enumerate(d['nodes']):
 if 'mesh' not in n:continue
 nodepoints=[]
 for p in d['meshes'][n['mesh']]['primitives']:
  pos=acc(p['attributes']['POSITION']);v=(world[i]@np.c_[pos,np.ones(len(pos))].T).T[:,:3];points.append(v);nodepoints.append(v)
 v=np.concatenate(nodepoints);centers[n.get('name','')]=(v.min(0)+v.max(0))/2
pts=np.concatenate(points);lo=pts.min(0);hi=pts.max(0);dim=hi-lo
assert .85<dim[0]<1.0 and .80<dim[1]<1.20 and 1.80<dim[2]<1.95
assert triangles <= (35000 if NAME in ['rainbow','raketfiets'] else 45000)
assert len(d.get('images',[])) >= 2
assert any('TEXCOORD_0' in p['attributes'] for m in d['meshes'] for p in m['primitives'])
assert len([n for n in d['nodes'] if n.get('name','').startswith('Wheel_') and n.get('children')])==3
assert not d.get('cameras') and not d.get('skins')
if NAME=='raketfiets':
 assert any(n.get('name')=='Flag_Cloth' for n in d['nodes'])
 assert not any(n.get('name','').startswith('Fin_') for n in d['nodes'])
else:
 assert len([n for n in d['nodes'] if n.get('name','').startswith(('Fin_Dorsal','Fin_Lateral'))])==3
if NAME=='purple-passion':assert any(n.get('name')=='Beacon_Emissive_Orb' for n in d['nodes'])
assert abs(lo[1])<.003
assert centers['Light_Nose'][2]<-.93 and centers['Rear_Thruster_Emitter'][2]>.85
r={'container':'GLB 2.0','size_bytes':len(b),'triangles':triangles,'degenerate_triangles':degenerate,'draw_primitives':primitives,'meshes':len(d['meshes']),'materials':len(d['materials']),'embedded_images':len(d.get('images',[])),'external_resources':False,'rear_wheel_pivots':'checked: local X axle, centered at Y=.211 / Z=.387','dimensions_godot_xyz_m':dim.tolist(),'ground_y_m':float(lo[1]),'orientation':'checked: +Y up, nose -Z, thruster +Z','checks_passed':True,'validation_scope':'Structural binary/accessor checks only. See separate Blender and Godot import reports. No Khronos validator or gameplay test.'}
(P/'source'/'validation-report.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))

# Exported geometry is authoritative for the report dimensions (cached Blender
# bounding boxes can lag behind joins/modifiers).
build_path=P/'source'/'build-report.json'
if build_path.exists():
 report=json.loads(build_path.read_text())
 report['dimensions_godot_xyz']=dim.tolist()
 report['dimensions_blender_xyz']=[float(dim[0]),float(dim[2]),float(dim[1])]
 report['dimension_measurement']='Final GLB vertex positions with complete node transforms'
 build_path.write_text(json.dumps(report,indent=2))
