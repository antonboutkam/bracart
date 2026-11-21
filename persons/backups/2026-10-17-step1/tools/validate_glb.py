"""Inspect actual exported GLB data using Python's standard library."""
import json, math, struct, sys
from pathlib import Path

def validate(path):
    raw=path.read_bytes(); magic,version,length=struct.unpack_from('<4sII',raw)
    assert (magic,version,length)==(b'glTF',2,len(raw)), 'Invalid GLB header'
    chunks={}; offset=12
    while offset<len(raw):
        size,kind=struct.unpack_from('<II',raw,offset); offset+=8
        chunks[kind]=raw[offset:offset+size]; offset+=size
    doc=json.loads(chunks[0x4e4f534a]); binary=chunks[0x004e4942]
    assert len(doc['buffers'])==1 and 'uri' not in doc['buffers'][0]
    def acc(i):
        a=doc['accessors'][i]; assert 'sparse' not in a, 'Sparse accessor requires separate handling'
        view=doc['bufferViews'][a['bufferView']]; n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
        fmt={5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'}[a['componentType']]
        size=struct.calcsize('<'+fmt*n); stride=view.get('byteStride',size); start=view.get('byteOffset',0)+a.get('byteOffset',0)
        return [struct.unpack_from('<'+fmt*n,binary,start+j*stride) for j in range(a['count'])]
    total=verts=0; positions=[]; maxweights=0; minweight=1
    for mesh in doc['meshes']:
        assert all(abs(w)<1e-7 for w in mesh.get('weights',[])), 'Facial expressions must be off in the bind pose'
        for p in mesh['primitives']:
            assert p.get('mode',4)==4
            at=p['attributes']; assert all(k in at for k in ['POSITION','NORMAL','TEXCOORD_0','JOINTS_0','WEIGHTS_0'])
            assert 'JOINTS_1' not in at, 'More than four joint influences'
            pos=acc(at['POSITION']); positions+=pos; verts+=len(pos)
            total+=(len(acc(p['indices'])) if 'indices' in p else len(pos))//3
            for v in pos+acc(at['NORMAL']): assert all(math.isfinite(x) for x in v)
            for w in acc(at['WEIGHTS_0']):
                maxweights=max(maxweights,sum(x>1e-5 for x in w)); minweight=min(minweight,sum(w)); assert abs(sum(w)-1)<.002
            assert len(p.get('targets',[]))>=10, 'Missing facial targets'
    lo=[min(v[i] for v in positions) for i in range(3)]; hi=[max(v[i] for v in positions) for i in range(3)]
    assert abs(lo[1])<.001 and abs(hi[1]-lo[1]-1.15)<.002, (lo,hi)
    for image in doc['images']: assert 'bufferView' in image and 'uri' not in image, 'External image dependency'
    clips=[a.get('name') for a in doc.get('animations',[])]; assert len(clips)==6 and set(clips)=={'Idle','Run','Jump','Cheer','Kart_Sit','Kart_Steer'}, clips
    assert len(doc.get('skins',[]))==1
    report={'file':path.name,'bytes':len(raw),'vertices':verts,'triangles':total,'triangle_target_met':12000<=total<=25000,'materials':len(doc['materials']),'embedded_images':len(doc['images']),'joints':len(doc['skins'][0]['joints']),'max_weights':maxweights,'bounds_min':lo,'bounds_max':hi,'animations':clips,'structural_checks':'passed','Godot_runtime':'not tested'}
    path.with_name('glb-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__':
    for arg in sys.argv[1:]: validate(Path(arg))
