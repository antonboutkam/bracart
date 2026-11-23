"""Recover generator measurements from saved source after an interrupted render run.
Does not modify blend/GLB files. Counts evaluated Blender geometry, not glTF UV splits.
"""
import bpy, sys, json, os, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
for name in sys.argv[sys.argv.index('--')+1:]:
    folder=ROOT/name
    bpy.ops.wm.open_mainfile(filepath=str(folder/(name+'.blend')))
    ob=next(o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    if rig.animation_data: rig.animation_data.action=None
    for track in rig.animation_data.nla_tracks: track.mute=True
    for pb in rig.pose.bones: pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
    bpy.context.view_layer.update()
    ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles()
    coords=[ob.matrix_world@v.co for v in me.vertices]
    report={'character':name,'stage':ob.get('stage','character study'),'vertices':len(me.vertices),'triangles':len(me.loop_triangles),'bones':len(rig.data.bones),'materials':len(me.materials),'height_m':max(v.z for v in coords)-min(v.z for v in coords),'glTF_forward':'-Z','clips':sorted(a.name for a in bpy.data.actions if a.users),'blendshapes':[k.name for k in ob.data.shape_keys.key_blocks][1:],'measured_from':name+'.blend','source_sha256':{f:hashlib.sha256((ROOT/'tools'/f).read_bytes()).hexdigest() for f in ('build_characters.py','character_clothes.py','character_hair.py','character_materials.py')},'notes':['Real evaluated Blender geometry; use glb-validation.json for actual GLB triangle counts.',ob.get('UV_note','See model UV metadata.'),'Native Godot capture and all-animation intersection review remain separate validation.']}
    ev.to_mesh_clear();(folder/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print('SOURCE_MEASURED',json.dumps(report),flush=True)
if bpy.app.background and os.environ.get('BORACER_FAST_EXIT')=='1':
    sys.stdout.flush();sys.stderr.flush();os._exit(0)
