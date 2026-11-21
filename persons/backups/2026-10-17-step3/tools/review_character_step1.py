"""Fixed-camera Boaz anatomy comparison, from saved meshes, never illustrations.

Run after build_characters.py -- boaz. This does not alter either blend/GLB.
Blender --background --threads 4 --python persons/tools/review_character_step1.py
"""
import bpy, importlib.util, os, shutil, sys
from pathlib import Path
spec=importlib.util.spec_from_file_location('character_builder',Path(__file__).with_name('build_characters.py'))
build=importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
root=build.ROOT
name=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'boaz'
backup='2026-10-17-ravi-step1' if name=='ravi' else '2026-10-17-step1'
review=root/name/'review-step1'; review.mkdir(exist_ok=True)
for label,source in [('before',root/'backups'/backup/name/(name+'.blend')),
                     ('after',review/'after'/(name+'.blend') if (review/'after'/(name+'.blend')).exists() else root/name/(name+'.blend'))]:
    bpy.ops.wm.open_mainfile(filepath=str(source))
    ob=bpy.data.objects[name.capitalize()+'_Character']; rig=bpy.data.objects['CharacterRig']
    rig.animation_data.action=None
    for track in rig.animation_data.nla_tracks: track.mute=True
    for bone in rig.pose.bones:
        bone.rotation_euler=(0,0,0); bone.location=(0,0,0)
    for key in ob.data.shape_keys.key_blocks: key.value=0
    bpy.context.scene.frame_set(1); bpy.context.view_layer.update()
    scene=bpy.context.scene; scene.cycles.samples=16; scene.cycles.use_denoising=False
    scene.render.resolution_x=600; scene.render.resolution_y=720
    build.OUT=review/label; (build.OUT/'renders').mkdir(parents=True,exist_ok=True)
    for fn,angle,target,scale in [('01-front.png',0,.57,1.43),
                                  ('02-three-quarter.png',32,.57,1.43),
                                  ('03-side.png',90,.57,1.43),
                                  ('05-face.png',12,.94,.44)]:
        if label=='after' and not fn.startswith('05'):
            # The clean builder already rendered these exact cameras/lights at
            # 600x720 / 16 samples. Reuse those pixels instead of repeating work.
            source_render=review/'after'/'renders'/fn
            if not source_render.exists(): shutil.copy2(root/name/'renders'/fn,source_render)
        else:
            build.render_view(scene.camera,fn,angle,4 if fn.startswith('05') else 9,target=target,scale=scale)
    print('FIXED_CAMERA_REVIEW_COMPLETE',label,flush=True)
build.finish_batch()
