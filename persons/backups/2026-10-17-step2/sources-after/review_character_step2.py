"""Step-2 comparisons using saved meshes and exactly matching cameras.

Run only after both clean builds finish. No blend/GLB is overwritten.
"""
import bpy, importlib.util, shutil, sys
from pathlib import Path

spec = importlib.util.spec_from_file_location('character_builder', Path(__file__).with_name('build_characters.py'))
build = importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
names = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['boaz', 'ravi']
for name in names:
    root = build.ROOT
    baseline = root/'backups'/'2026-10-17-step2'/'boaz' if name == 'boaz' else root/'ravi'/'review-step1'/'after'
    review = root/name/'review-step2'
    for label, source in [('before', baseline), ('after', root/name)]:
        dest = review/label
        (dest/'renders').mkdir(parents=True, exist_ok=True)
        for filename in ['01-front.png', '02-three-quarter.png', '03-side.png', '04-back.png', '06-kart-pose.png']:
            shutil.copy2(source/'renders'/filename, dest/'renders'/filename)
        bpy.ops.wm.open_mainfile(filepath=str(source/(name+'.blend')))
        ob = bpy.data.objects[name.capitalize()+'_Character']; rig = bpy.data.objects['CharacterRig']
        rig.animation_data.action = None
        for track in rig.animation_data.nla_tracks: track.mute = True
        for bone in rig.pose.bones:
            bone.rotation_euler = (0,0,0); bone.location = (0,0,0)
        for key in ob.data.shape_keys.key_blocks: key.value = 0
        scene = bpy.context.scene
        scene.frame_set(1); bpy.context.view_layer.update()
        scene.cycles.samples = 16; scene.cycles.use_denoising = False; scene.cycles.device = 'CPU'
        scene.render.resolution_x = 600; scene.render.resolution_y = 720
        build.OUT = dest
        build.render_view(scene.camera, '05-face.png', 12, 4, target=.94, scale=.44)
        print('STEP2_REVIEW_FACE_COMPLETE', name, label, flush=True)
build.finish_batch()
