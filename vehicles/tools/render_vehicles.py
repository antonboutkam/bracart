"""Fresh GLB import and studio views. Run in Blender: -- vehicle [view ...]."""
import bpy,sys,math,json,os
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:];name=args[0];out=ROOT/name
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(out/f'{name}-improved.glb'))
model=[o for o in bpy.context.scene.objects if o.type=='MESH']
report={'meshes':len(model),'materials':len(bpy.data.materials),'images':len(bpy.data.images),'missing_images':[i.name for i in bpy.data.images if i.source=='FILE' and not i.packed_file and not Path(bpy.path.abspath(i.filepath)).exists()],'godot_runtime_tested':False}
assert model and not report['missing_images']
(out/'source/blender-import-report.json').write_text(json.dumps(report,indent=2))
print('STUDIO_SETUP',name,flush=True)
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=12;sc.cycles.use_denoising=True;sc.cycles.denoiser='OPENIMAGEDENOISE';sc.cycles.denoising_use_gpu=False;sc.cycles.max_bounces=4;sc.cycles.glossy_bounces=2
sc.render.threads_mode='FIXED';sc.render.threads=int(os.environ.get('BORACER_RENDER_THREADS','4'));sc.render.use_persistent_data=True
sc.world=bpy.data.worlds.new('Neutral studio');sc.world.use_nodes=True
sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.26,.32,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.5
floor=bpy.data.materials.new('Preview floor');floor.use_nodes=True
floor.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.045,.06,.08,1)
floor.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.78
print('STUDIO_FLOOR',name,flush=True)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.006));bpy.context.object.data.materials.append(floor)
target=Vector((0,0,.47 if name in ['purple-passion','raketfiets'] else .38))
for p,power,size in [((1.8,1.3,3.2),380,2.6),((-2,.3,1.7),270,2.3),((.4,-2.5,2.6),480,2.0)]:
 bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
print('STUDIO_CAMERA',name,flush=True)
bpy.ops.object.camera_add();cam=bpy.context.object;sc.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=2.25
sc.view_settings.view_transform='Standard';sc.view_settings.exposure=-1.3
sc.render.resolution_x=640;sc.render.resolution_y=512;sc.render.resolution_percentage=100
views={'front-right':(1.5,2.1,1.40),'rear-right':(1.5,-2.1,1.40),'left':(-2.8,0,.60),'right':(2.8,0,.60),'front':(0,3,.60),'rear':(0,-3,.60),'top':(0,.001,3.5),'bottom':(0,-.001,-3.5),'rear-left':(-1.5,-2.1,1.4)}
print('RENDER_START',name,flush=True)
for label in (args[1:] or views):
 if label!='front-right':sc.render.resolution_percentage=50;sc.cycles.samples=8
 else:sc.render.resolution_percentage=int(os.environ.get('BORACER_HERO_PERCENT','100'))
 cam.data.ortho_scale=2.65 if label in ['top','bottom'] else 2.25
 print('RENDER_VIEW',name,label,flush=True)
 if label=='bottom':bpy.data.objects['Plane'].hide_render=True
 cam.location=views[label];cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(out/'previews'/f'{label}.png');bpy.ops.render.render(write_still=True)
 if label=='bottom':bpy.data.objects['Plane'].hide_render=False
 print('PREVIEW_DONE',name,label,flush=True)
import os
sys.stdout.flush();os._exit(0)
