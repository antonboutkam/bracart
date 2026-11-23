"""Render frozen baseline and current model under identical studio settings.

BORACER_REVIEW_VARIANTS=before,after BORACER_VIEWS=02,05 ... -- boaz
After images are also copied to the current renders directory. Never save the
baseline .blend. One Blender process, resumable per character/view.
"""
import bpy, sys, os, json, hashlib, shutil, faulthandler
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_characters as build
faulthandler.enable()

VIEWS={'01':('01-front.png',0,9,.57,1.43),
       '02':('02-three-quarter.png',32,9,.57,1.43),
       '03':('03-side.png',90,9,.57,1.43),
       '04':('04-back.png',180,9,.57,1.43),
       '05':('05-face.png',12,4,None,.44),
       '06':('06-kart-pose.png',40,11,.60,1.35)}
for name in sys.argv[sys.argv.index('--')+1:]:
    folder=build.ROOT/name
    review=folder/'review-materials-2026-11-21'
    provenance_path=review/'render-provenance.json'
    provenance=json.loads(provenance_path.read_text()) if provenance_path.exists() else {}
    for variant in os.environ.get('BORACER_REVIEW_VARIANTS','before,after').split(','):
        source=(build.ROOT/'backups/2026-11-21-materials'/name) if variant=='before' else folder
        blend=source/(name+'.blend')
        bpy.ops.wm.open_mainfile(filepath=str(blend))
        scene=bpy.context.scene
        build.character_materials.configure_preview(scene,int(os.environ.get('BORACER_SAMPLES','64')))
        scene.render.resolution_x=600; scene.render.resolution_y=720
        scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG'
        build.OUT=review/variant
        (build.OUT/'renders').mkdir(parents=True,exist_ok=True)
        rig=bpy.data.objects['CharacterRig']; ob=bpy.data.objects[name.capitalize()+'_Character']
        rig.animation_data.action=None
        for track in rig.animation_data.nla_tracks: track.mute=True
        for pb in rig.pose.bones: pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
        for key in ob.data.shape_keys.key_blocks: key.value=0
        scene.frame_set(1);bpy.context.view_layer.update()
        for key in os.environ.get('BORACER_VIEWS','01,02,03,04,05,06').split(','):
            fn,a,e,target,scale=VIEWS[key]
            # Spend review time on the material comparison and face; the four
            # unchanged silhouette/pose checks remain clear at a smaller size.
            detail=key in ('02','05')
            scene.cycles.samples=int(os.environ.get('BORACER_SAMPLES','64')) if detail else 16
            scene.render.resolution_x=600 if detail else 480
            scene.render.resolution_y=720 if detail else 576
            scene.cycles.denoising_quality='HIGH' if detail else 'BALANCED'
            scene.cycles.denoising_prefilter='ACCURATE' if detail else 'FAST'
            if key=='06':
                action=bpy.data.actions['Kart_Sit'];rig.animation_data.action=action
                if len(action.slots):rig.animation_data.action_slot=action.slots[0]
                scene.frame_set(1);bpy.context.view_layer.update()
            if target is None:target=.94 if name=='boaz' else .91
            print('REVIEW_RENDER',name,variant,fn,flush=True)
            faulthandler.dump_traceback_later(180,repeat=True)
            build.render_view(scene.camera,fn,a,e,target,scale)
            faulthandler.cancel_dump_traceback_later()
            rendered=build.OUT/'renders'/fn
            if variant=='after':shutil.copy2(rendered,folder/'renders'/fn)
            provenance[f'{variant}/{fn}']={
                'blend_sha256':hashlib.sha256(blend.read_bytes()).hexdigest(),
                'glb_sha256':hashlib.sha256((source/(name+'.glb')).read_bytes()).hexdigest(),
                'render_sha256':hashlib.sha256(rendered.read_bytes()).hexdigest(),
                'Blender':bpy.app.version_string,'samples':scene.cycles.samples,
                'denoising':scene.cycles.use_denoising,'camera':[a,e,target,scale],
                'denoising_quality':scene.cycles.denoising_quality,
                'denoising_prefilter':scene.cycles.denoising_prefilter,
                'adaptive_threshold':scene.cycles.adaptive_threshold,
                'max_bounces':scene.cycles.max_bounces,
                'resolution':[scene.render.resolution_x,scene.render.resolution_y],
                'look':scene.view_settings.look,'exposure':scene.view_settings.exposure,
                'kind':'Actual Blender mesh, not Godot gameplay'}
            provenance_path.write_text(json.dumps(provenance,indent=2)+'\n')
    print('MATERIAL_REVIEW_COMPLETE',name,flush=True)
build.finish_batch()
