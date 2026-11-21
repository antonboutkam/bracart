import json,struct,hashlib
from pathlib import Path
GAME = Path(__file__).resolve().parents[1]
out={}
for name in ['boaz','ravi']:
 p=(GAME / 'assets/models')/(name+'.glb'); b=p.read_bytes(); jlen=struct.unpack_from('<I',b,12)[0]; d=json.loads(b[20:20+jlen]); binary=b[28+jlen:]
 def values(idx):
  a=d['accessors'][idx]
  result=[(0,0,0)]*a['count']
  if 'bufferView' in a:
   v=d['bufferViews'][a['bufferView']]; off=v.get('byteOffset',0)+a.get('byteOffset',0); stride=v.get('byteStride',12)
   result=[struct.unpack_from('<fff',binary,off+i*stride) for i in range(a['count'])]
  if 'sparse' in a:
   sp=a['sparse']; si=sp['indices']; sv=sp['values']; iv=d['bufferViews'][si['bufferView']]; vv=d['bufferViews'][sv['bufferView']]
   fmt={5121:'B',5123:'H',5125:'I'}[si['componentType']]; size=struct.calcsize(fmt)
   for i in range(sp['count']):
    index=struct.unpack_from('<'+fmt,binary,iv.get('byteOffset',0)+si.get('byteOffset',0)+i*size)[0]
    result[index]=struct.unpack_from('<fff',binary,vv.get('byteOffset',0)+sv.get('byteOffset',0)+i*12)
  return result
 summary={}
 for m in d['meshes']:
  names=m.get('extras',{}).get('targetNames',[])
  if 'wink_left' not in names:continue
  for target in ['wink_left','wink_right','blink']:
   points=[]
   for prim in m['primitives']:
    pos=values(prim['attributes']['POSITION']); delta=values(prim['targets'][names.index(target)]['POSITION'])
    points += [p for p,v in zip(pos,delta) if max(map(abs,v))>1e-7]
   summary[target]={'changed_vertices':len(points),'x_min':min(v[0] for v in points),'x_max':max(v[0] for v in points)}
 assert summary['wink_left']['x_max']<0 and summary['wink_right']['x_min']>0
 out[name]={'sha256':hashlib.sha256(b).hexdigest(),'morphs':summary,'one_eye_only':True}
(GAME / 'validation/driver-reactions-morphs.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
