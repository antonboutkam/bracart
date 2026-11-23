"""Audit actual exported geometry, skinning, morphs and animations across UV edits."""
from check_character_hair_scope import GLB
from collections import Counter
from pathlib import Path
import hashlib,json,sys,struct,gc


def triangle_records(glb, precision=None):
    # Stream one accessor at a time: retaining all 20 morph payloads for both
    # models alongside Cycles can exhaust a small batch runner's memory.
    result=Counter()
    joints=[glb.node_name(i) for i in glb.doc['skins'][0]['joints']]
    for mesh in glb.doc['meshes']:
        for prim in mesh['primitives']:
            count=glb.doc['accessors'][prim['attributes']['POSITION']]['count']
            hashes=[hashlib.sha256() for _ in range(count)]
            sources=[('base/'+k,k,v) for k,v in sorted(prim['attributes'].items()) if k!='TEXCOORD_0']
            for j,target in enumerate(prim.get('targets',[])):
                sources.extend((str(j)+'/'+k,k,v) for k,v in sorted(target.items()))
            for label,key,accessor in sources:
                rows=glb.acc(accessor)
                prefix=label.encode()+b'\0'
                for i,row in enumerate(rows):
                    if key=='JOINTS_0': payload=repr(tuple(joints[int(v)] for v in row)).encode()
                    else:
                        values=tuple(round(float(v),precision) for v in row) if precision is not None else row
                        payload=struct.pack('<'+'f'*len(values),*values)
                    hashes[i].update(prefix+payload)
                glb.cache.clear()
                del rows
            records=[h.digest() for h in hashes]
            del hashes
            inds=[row[0] for row in glb.acc(prim['indices'])]
            glb.cache.clear()
            for i in range(0,len(inds),3):
                tri=[records[j] for j in inds[i:i+3]]
                result[min(tuple(tri[j:]+tri[:j]) for j in range(3))]+=1
    return result


def audit(name):
    root=Path(__file__).resolve().parents[1]
    before=root/'backups/2026-11-21-materials'/name/(name+'.glb')
    after=root/name/(name+'.glb')
    a,b=GLB(before),GLB(after)
    print('AUDIT',name,'exact exported triangle attributes',flush=True)
    ra=triangle_records(a); gc.collect(); rb=triangle_records(b)
    strict=ra==rb
    if not strict:
        ra,rb=triangle_records(a,6),triangle_records(b,6)
    anim_a,anim_b=a.animations(),b.animations()
    animation_delta=0.; animation_schema=anim_a.keys()==anim_b.keys()
    if animation_schema:
        for clip in anim_a:
            channels_a,channels_b=anim_a[clip],anim_b[clip]
            animation_schema &= len(channels_a)==len(channels_b)
            for ca,cb in zip(channels_a,channels_b):
                animation_schema &= ca[:3]==cb[:3] and len(ca[3])==len(cb[3]) and len(ca[4])==len(cb[4])
                for rows_a,rows_b in zip(ca[3:],cb[3:]):
                    for row_a,row_b in zip(rows_a,rows_b):
                        animation_schema &= len(row_a)==len(row_b)
                        animation_delta=max(animation_delta,max((abs(x-y) for x,y in zip(row_a,row_b)),default=0))
    checks={
        'triangle_attributes_preserved_at_reported_precision':ra==rb,
        'rig_and_inverse_bind_matrices_exact':a.rig()==b.rig(),
        'node_transforms_exact':a.node_transforms()==b.node_transforms(),
        'animations_preserved_within_1e_7':animation_schema and animation_delta<=1e-7,
        'morph_names_exact':[m.get('extras',{}).get('targetNames') for m in a.doc['meshes']]==[m.get('extras',{}).get('targetNames') for m in b.doc['meshes']],
        'morph_defaults_exact':[m.get('weights') for m in a.doc['meshes']]==[m.get('weights') for m in b.doc['meshes']],
        'one_material_two_images':len(b.doc['materials'])==1 and len(b.doc['images'])==2,
        'textures_changed':a.images()!=b.images(),
    }
    report={'passed':all(checks.values()),'checks':checks,'triangle_attributes_bit_exact':strict,
            'animation_payloads_bit_exact':anim_a==anim_b,'animation_max_abs_delta':animation_delta,
            'triangle_attribute_decimals':None if strict else 6,
            'removed_or_changed_triangles':sum((ra-rb).values()),'added_or_changed_triangles':sum((rb-ra).values()),
            'baseline_sha256':a.sha256,'candidate_sha256':b.sha256,
            'scope':'UVs and embedded material images may change. All other triangle attributes, including every morph delta, are checked.',
            'limits':'No artistic acceptance, intersection or performance claim.'}
    output=root/name/'review-materials-2026-11-21'/'scope-audit.json'
    output.parent.mkdir(exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2),flush=True)
    return report['passed']

if __name__=='__main__':
    outcomes=[audit(n) for n in sys.argv[1:] or ['boaz','ravi']]
    raise SystemExit(0 if all(outcomes) else 1)
