"""One-time upgrade of the original studies; a clean build already includes this.
Adds rear hair and clears Boaz's cape from the tunic, then exports neutral GLBs.
Guarded against applying the geometry upgrade more than once to a saved source.
"""
import bpy, importlib.util, math, sys
from pathlib import Path
from mathutils import Matrix, Vector

spec=importlib.util.spec_from_file_location('character_builder',Path(__file__).with_name('build_characters.py'))
build=importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['boaz','ravi']
for name in names:
    out=build.ROOT/name; bpy.ops.wm.open_mainfile(filepath=str(out/(name+'.blend')))
    rig=bpy.data.objects['CharacterRig']; ob=bpy.data.objects[name.capitalize()+'_Character']
    for key in ob.data.shape_keys.key_blocks: key.value=0
    ob.active_shape_key_index=0
    rig.animation_data.action=None
    for tr in rig.animation_data.nla_tracks: tr.mute=True
    for pb in rig.pose.bones: pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
    bpy.context.view_layer.update()
    if not ob.get('rear_hair_refined'):
        factor=rig.data.bones['head'].tail_local.z/1.07
        build.parts=[]; build.MAT=ob.data.materials[0]; build.back_hair()
        transform=Matrix.Rotation(math.pi,4,'Z')@Matrix.Scale(factor,4)
        for part in build.parts: part.data.transform(transform)
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        for part in build.parts: part.select_set(True)
        bpy.context.view_layer.objects.active=ob; bpy.ops.object.join()
        if name=='boaz':
            cape={g.index for g in ob.vertex_groups if g.name.startswith('cape_')}
            for v in ob.data.vertices:
                if any(g.group in cape and g.weight>0 for g in v.groups):
                    for key in ob.data.shape_keys.key_blocks: key.data[v.index].co.y-=.015*factor
        ob['rear_hair_refined']=True
    for key in ob.data.shape_keys.key_blocks: key.value=0
    bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_morph=True,export_skins=True,export_yup=True,export_materials='EXPORT',export_cameras=False,export_lights=False,export_force_sampling=True)
    print('REFINED',name,flush=True)
build.finish_batch()
