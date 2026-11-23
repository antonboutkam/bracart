"""Fresh Blender roundtrip check of exported GLBs; not a Godot runtime test."""
import bpy, sys, json, math, os, hashlib
from pathlib import Path

for arg in sys.argv[sys.argv.index('--')+1:]:
    path=Path(arg).resolve()
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)
    bpy.ops.import_scene.gltf(filepath=str(path))
    # Blender's importer also creates a custom bone-display Icosphere.
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]; rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    print('IMPORTED_OBJECTS',[(o.name,o.type) for o in bpy.context.scene.objects],flush=True)
    assert len(meshes)==len(rigs)==1, (len(meshes),len(rigs))
    ob=meshes[0]; rig=rigs[0]; assert ob.data.shape_keys and len(ob.data.shape_keys.key_blocks)>=11
    assert all(abs(k.value)<1e-6 for k in ob.data.shape_keys.key_blocks[1:]), 'Non-neutral facial defaults'
    assert any(m.type=='ARMATURE' for m in ob.modifiers)
    assert len(bpy.data.actions)>=6
    assert all(im.packed_file for im in bpy.data.images if im.type=='IMAGE'), 'Images not embedded on import'
    if rig.animation_data: rig.animation_data.action=None
    for tr in rig.animation_data.nla_tracks: tr.mute=True
    for pb in rig.pose.bones: pb.rotation_quaternion=(1,0,0,0); pb.location=(0,0,0); pb.rotation_euler=(0,0,0)
    bpy.context.view_layer.update()
    coords=[ob.matrix_world@v.co for v in ob.data.vertices]
    height=max(v.z for v in coords)-min(v.z for v in coords)
    assert abs(height-1.15)<.002, height
    sampled=[]
    for action in list(bpy.data.actions):
        if not action.slots: continue
        try:
            rig.animation_data.action=action; rig.animation_data.action_slot=action.slots[0]
        except RuntimeError: continue
        for f in [1,8,16]:
            bpy.context.scene.frame_set(f); bpy.context.view_layer.update()
            ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()); me=ev.to_mesh()
            assert all(all(math.isfinite(x) for x in v.co) for v in me.vertices)
            ev.to_mesh_clear()
        sampled.append(action.name)
    image_sizes={node.image.name:list(node.image.size) for material in ob.data.materials if material.use_nodes for node in material.node_tree.nodes if node.type=='TEX_IMAGE' and node.image}
    report={'file':path.name,'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'Blender':bpy.app.version_string,'fresh_Blender_import':'passed','height_m':height,'meshes':len(meshes),'armatures':len(rigs),'morph_targets':len(ob.data.shape_keys.key_blocks)-1,'sampled_animations':sampled,'embedded_image_sizes':image_sizes,'Godot_runtime':'not tested'}
    path.with_name('blender-import-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print('IMPORT_CHECK',json.dumps(report),flush=True)
if bpy.app.background and os.environ.get('BORACER_FAST_EXIT')=='1':
    sys.stdout.flush(); sys.stderr.flush(); os._exit(0)
