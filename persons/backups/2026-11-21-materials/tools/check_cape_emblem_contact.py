"""Measure actual rest-mesh cape occlusion of gold relief using Blender BVH rays.
Only reads saved meshes. Arguments are .blend paths; writes .cape-contact.json.
Not a motion, garment/vehicle or visual quality certificate.
"""
import bpy, sys, json, os
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
for arg in sys.argv[sys.argv.index('--')+1:]:
    path=Path(arg).resolve();bpy.ops.wm.open_mainfile(filepath=str(path))
    ob=next(o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers));me=ob.data;me.calc_loop_triangles()
    cape={g.index for g in ob.vertex_groups if g.name.startswith('cape_')}
    vertices=[v.co.copy() for v in me.vertices];red=[];gold=[];uv=me.uv_layers.active.data
    for tri in me.loop_triangles:
        if not all(any(g.group in cape and g.weight>.00001 for g in me.vertices[i].groups) for i in tri.vertices): continue
        tiles={min(7,int(uv[i].uv.x*8))+8*min(7,int(uv[i].uv.y*8)) for i in tri.loops}
        if tiles=={13}: red.append(tuple(tri.vertices))
        if tiles=={14}: gold.append(tuple(tri.vertices))
    bvh=BVHTree.FromPolygons(vertices,red,all_triangles=True)
    distances=[];missing=0
    for tri in gold:
        p=sum((vertices[i] for i in tri),Vector())/3
        hit,normal,index,distance=bvh.ray_cast(p+Vector((0,-.04,0)),Vector((0,1,0)),.08)
        if hit is None: missing+=1;continue
        # Blender authoring mesh is rotated 180deg: outward cape normal is -Y.
        distances.append(hit.y-p.y)
    report={'blend':str(path),'red_cape_triangles':len(red),'gold_emblem_triangles':len(gold),'samples_with_red_surface':len(distances),'samples_missing_red_surface':missing,'occluded_centroids_more_than_0_5mm':sum(d<-.0005 for d in distances),'minimum_gold_clearance_m':min(distances) if distances else None,'maximum_gold_clearance_m':max(distances) if distances else None,'centroids_more_than_6mm_above_cloth':sum(d>.006 for d in distances),'passed':bool(distances) and missing==0 and not any(d<-.0005 or d>.006 for d in distances),'limits':['Rest pose only, triangle centroids; this is not exhaustive intersection detection.','Centroids lacking a red ray hit are reported separately.','Sign convention uses this generator saved Blender -Y-facing cape.']}
    out=path.with_suffix('.cape-contact.json');out.write_text(json.dumps(report,indent=2)+'\n');print('CAPE_CONTACT',json.dumps(report),flush=True)
if bpy.app.background and os.environ.get('BORACER_FAST_EXIT')=='1':
    sys.stdout.flush();sys.stderr.flush();os._exit(0)
