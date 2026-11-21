"""Shared export/optimization stage, executed by build_model.py."""
import bpy,json
from mathutils import Vector
# Reload the source paint to ensure the packed copy reflects the latest artwork.
for im in bpy.data.images:
 if im.name.startswith(('body-paint','fin-paint','nose-paint','flag-paint')):
  im.filepath=str(HERE/im.name.split('.')[0])+'.png';im.reload();im.pack()
for o in bpy.context.scene.objects:
 if o.type=='MESH' and any(len(p.vertices)!=3 for p in o.data.polygons):
  m=o.modifiers.new('Export triangulation','TRIANGULATE');bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
initial=sum(len(o.data.polygons) for o in meshes)
candidates=[o for o in meshes if len(o.data.polygons)>300]
fixed=sum(len(o.data.polygons) for o in meshes if o not in candidates)
ratio=min(1.,max(.15,(BUDGET-fixed)/max(1,initial-fixed)))
if ratio<1:
 for o in candidates:
  bpy.context.view_layer.objects.active=o;m=o.modifiers.new('Game mesh triangle budget','DECIMATE');m.ratio=ratio;m.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=m.name)
# Remove numerically collapsed triangles left by bevels/decimation.
import bmesh
removed=0
for o in meshes:
 bm=bmesh.new();bm.from_mesh(o.data);bad=[f for f in bm.faces if f.calc_area()<5e-13];removed+=len(bad)
 if bad:bmesh.ops.delete(bm,geom=bad,context='FACES_ONLY');bm.to_mesh(o.data);o.data.update()
 bm.free()
print('Removed collapsed triangles',removed,flush=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/f'{NAME}-improved.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_cameras=False,export_lights=False)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'{NAME}-improved.blend'))
bpy.context.view_layer.update()
vs=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
dims=[max(v[i] for v in vs)-min(v[i] for v in vs) for i in range(3)]
report={'triangles':sum(len(o.data.polygons) for o in meshes),'triangles_before_optimization':initial,'mesh_objects':len(meshes),'dimensions_blender_xyz':dims,'dimensions_godot_xyz':[dims[0],dims[2],dims[1]],'materials':len(bpy.data.materials),'wheel_pivots':{o.name:list(o.location) for o in bpy.context.scene.objects if o.type=='EMPTY' and o.name.startswith('Wheel_')}}
(OUT/'source'/'build-report.json').write_text(json.dumps(report,indent=2));print('BUILD_REPORT',json.dumps(report),flush=True)
