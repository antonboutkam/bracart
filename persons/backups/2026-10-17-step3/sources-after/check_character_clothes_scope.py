"""Step 3 GLB scope audit: face, hair, skin, rig, motion and textures.
Uses exported payloads rather than trusting unchanged generator text.
"""
from check_character_hair_scope import GLB
from collections import Counter
from pathlib import Path
import argparse, json, math, hashlib, sys


def protected(glb,precision):
    joints=[glb.node_name(i) for i in glb.doc['skins'][0]['joints']]
    result=Counter(); counts={'head_neck':0,'skin':0,'hair':0}
    for mesh in glb.doc['meshes']:
        for prim in mesh['primitives']:
            attrs={k:glb.acc(v) for k,v in prim['attributes'].items()}
            targets=[{k:glb.acc(v) for k,v in t.items()} for t in prim.get('targets',[])]
            inds=[v[0] for v in glb.acc(prim['indices'])]; cache={}
            for t in range(0,len(inds),3):
                ix=inds[t:t+3]
                tiles={min(7,int(attrs['TEXCOORD_0'][i][0]*8))+8*min(7,int((1-attrs['TEXCOORD_0'][i][1])*8)) for i in ix}
                head=all(all(joints[int(j)] in ('head','neck') or w<1e-6 for j,w in zip(attrs['JOINTS_0'][i],attrs['WEIGHTS_0'][i])) for i in ix)
                group='head_neck' if head else ('skin' if tiles.issubset({0,1,2}) else ('hair' if tiles.issubset({3,4,5}) else None))
                if group is None: continue
                counts[group]+=1; records=[]
                for i in ix:
                    if i in cache:
                        records.append(cache[i]); continue
                    rec=[]
                    for k in sorted(attrs):
                        val=attrs[k][i]
                        if k=='JOINTS_0': val=tuple(joints[int(j)] for j in val)
                        else: val=tuple(round(float(v),precision if k!='NORMAL' else max(4,precision-2)) for v in val)
                        rec.append((k,val))
                    rec.extend((str(j),tuple((k,tuple(round(float(v),precision) for v in a[i])) for k,a in sorted(tar.items()))) for j,tar in enumerate(targets))
                    cache[i]=hashlib.sha256(repr(rec).encode()).hexdigest()
                    records.append(cache[i])
                result[(group,min(tuple(records[j:]+records[:j]) for j in range(3)))]+=1
    return result,counts


def exact_protected_positions(glb):
    """Compare unrounded float32 positions and oriented triangle multiplicities."""
    joints=[glb.node_name(i) for i in glb.doc['skins'][0]['joints']]; result=Counter()
    for mesh in glb.doc['meshes']:
        for prim in mesh['primitives']:
            attrs={k:glb.acc(v) for k,v in prim['attributes'].items()}
            inds=[v[0] for v in glb.acc(prim['indices'])]
            for t in range(0,len(inds),3):
                ix=inds[t:t+3]
                tiles={min(7,int(attrs['TEXCOORD_0'][i][0]*8))+8*min(7,int((1-attrs['TEXCOORD_0'][i][1])*8)) for i in ix}
                head=all(all(joints[int(j)] in ('head','neck') or w<1e-6 for j,w in zip(attrs['JOINTS_0'][i],attrs['WEIGHTS_0'][i])) for i in ix)
                if not head and not tiles.issubset({0,1,2,3,4,5}): continue
                records=[attrs['POSITION'][i] for i in ix]
                result[min(tuple(records[j:]+records[:j]) for j in range(3))]+=1
    return result


def audit(before,after):
    a,b=GLB(before),GLB(after)
    print('SCOPE: baseline strict',file=sys.stderr,flush=True); strict_a,ca=protected(a,7)
    print('SCOPE: candidate strict',file=sys.stderr,flush=True); strict_b,cb=protected(b,7)
    aa,bb=strict_a,strict_b
    if strict_a!=strict_b:
        print('SCOPE: baseline rounded fallback',file=sys.stderr,flush=True); aa,_=protected(a,6)
        print('SCOPE: candidate rounded fallback',file=sys.stderr,flush=True); bb,_=protected(b,6)
    checks={'protected_position_payloads_exact':exact_protected_positions(a)==exact_protected_positions(b),
      'protected_head_hair_skin_attributes_preserved_1um_rounded':aa==bb,
      'rig_and_inverse_bind_matrices_unchanged':a.rig()==b.rig(),
      'node_transforms_unchanged':a.node_transforms()==b.node_transforms(),
      'animation_payloads_unchanged':a.animations()==b.animations(),
      'embedded_images_unchanged':a.images()==b.images(),
      'materials_unchanged':a.doc['materials']==b.doc['materials'],
      'morph_names_unchanged':[m.get('extras',{}).get('targetNames') for m in a.doc['meshes']]==[m.get('extras',{}).get('targetNames') for m in b.doc['meshes']],
      'morph_defaults_unchanged':[m.get('weights') for m in a.doc['meshes']]==[m.get('weights') for m in b.doc['meshes']]}
    return {'baseline':str(before),'candidate':str(after),'baseline_sha256':a.sha256,'candidate_sha256':b.sha256,'passed':all(checks.values()),'checks':checks,'strict_0_1um_rounded_preserved':strict_a==strict_b,'before_protected_triangles':ca,'after_protected_triangles':cb,'protected_removed_or_changed':sum((aa-bb).values()),'protected_added_or_changed':sum((bb-aa).values()),'precision':{'position_uv_weights_morph_decimals':7 if strict_a==strict_b else 6,'normal_decimals':5 if strict_a==strict_b else 4},'limitations':['Position payloads are compared without rounding; normals, UVs, weights and morphs use the reported decimal precision.','Protected triangles are selected by head/neck weights or skin/hair palette; garment skinning and intersections need separate visual review.','No Godot runtime or artistic acceptance claim.']}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('before',type=Path);p.add_argument('after',type=Path);p.add_argument('--output',type=Path); args=p.parse_args()
    report=audit(args.before,args.after); text=json.dumps(report,indent=2)+'\n'
    if args.output: args.output.write_text(text)
    print(text,end='');raise SystemExit(0 if report['passed'] else 1)
