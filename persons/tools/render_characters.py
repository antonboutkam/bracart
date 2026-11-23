"""Render saved .blend characters, without rebuilding geometry or re-exporting GLB."""
import bpy, importlib.util, sys, json, faulthandler, os
from pathlib import Path

faulthandler.enable()
spec=importlib.util.spec_from_file_location('character_builder',Path(__file__).with_name('build_characters.py'))
build=importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['boaz','ravi']
views=set(os.environ.get('BORACER_VIEWS','01,02,03,04,05,06').split(','))
for name in names:
    out=build.ROOT/name; build.OUT=out
    bpy.ops.wm.open_mainfile(filepath=str(out/(name+'.blend')))
    scene=bpy.context.scene
    build.character_materials.configure_preview(scene, int(os.environ.get('BORACER_SAMPLES','64')))
    scene.render.resolution_x=600; scene.render.resolution_y=720
    print('RENDER_START',name,flush=True)
    cam=scene.camera; rig=bpy.data.objects['CharacterRig']
    ob=bpy.data.objects[name.capitalize()+'_Character']
    for key in ob.data.shape_keys.key_blocks: key.value=0
    ob.active_shape_key_index=0
    bpy.context.view_layer.update()
    for fn,a in [('01-front.png',0),('02-three-quarter.png',32),('03-side.png',90),('04-back.png',180)]:
        if fn[:2] in views: build.render_view(cam,fn,a)
    if '05' in views: build.render_view(cam,'05-face.png',12,4,target=.94 if name=='boaz' else .91,scale=.44)
    action=bpy.data.actions['Kart_Sit']; rig.animation_data.action=action
    if len(action.slots): rig.animation_data.action_slot=action.slots[0]
    scene.frame_set(1)
    if '06' in views: build.render_view(cam,'06-kart-pose.png',40,11,target=.60,scale=1.35)
    rig.animation_data.action=None
    for pb in rig.pose.bones: pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
    scene.frame_set(1); bpy.context.view_layer.update()
    cam.location=(1.4,2.4,1.0)
    from mathutils import Vector
    cam.rotation_euler=(Vector((0,0,.57))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.ortho_scale=1.43
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(name+'.blend')))
    deps=bpy.context.evaluated_depsgraph_get(); ev=ob.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles()
    report={'character':name,'Blender':bpy.app.version_string,'vertices':len(me.vertices),'triangles':len(me.loop_triangles),'skeleton_bones':len(rig.data.bones),'materials':len(me.materials),'height_m':1.15,'glTF_forward':'-Z','clips':[a.name for a in bpy.data.actions],'blendshapes':[k.name for k in ob.data.shape_keys.key_blocks][1:],'stage':'Material refinement 2026-11-21; Godot checks reported separately'}
    ev.to_mesh_clear(); (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print('RENDER_COMPLETE',name,flush=True)
build.finish_batch()
