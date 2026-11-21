"""Reimport final GLB and render eight inspection angles with neutral studio lighting."""
import bpy,math,json
from mathutils import Vector
from pathlib import Path
OUT=Path(__file__).resolve().parent.parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(OUT/'toxic-turbo-improved.glb'))
model=[o for o in bpy.context.scene.objects if o.type=='MESH']
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True
sc.world=bpy.data.worlds.new('Neutral Studio');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.24,.30,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
floor=bpy.data.materials.new('Studio ground');floor.use_nodes=True;floor.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.055,.07,.09,1);floor.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.78
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.006));bpy.context.object.data.materials.append(floor)
target=Vector((0,0,.37))
for p,power,size in [((1.8,1.3,3.2),350,2.6),((-2,.3,1.7),250,2.3),((.4,-2.5,2.6),450,2.0)]:
 bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;sc.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=2.20
sc.view_settings.view_transform='Standard';sc.view_settings.exposure=-1.3
sc.render.resolution_x=900;sc.render.resolution_y=680;sc.render.resolution_percentage=100
views=[('front-right',(1.5,2.1,1.28)),('rear-right',(1.5,-2.1,1.28)),('left',(-2.8,0,.66)),('right',(2.8,0,.66)),('front',(0,3,.62)),('rear',(0,-3,.62)),('top',(0,.001,3.5)),('rear-left',(-1.5,-2.1,1.28))]
import sys
if '--' in sys.argv:
 args=sys.argv[sys.argv.index('--')+1:];views=views[int(args[0]):int(args[1])]
for name,p in views:
 sc.render.resolution_x=800 if name=='front-right' else 480;sc.render.resolution_y=600 if name=='front-right' else 360;sc.cycles.samples=12 if name=='front-right' else 8
 cam.location=p;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(OUT/'previews'/f'{name}.png');bpy.ops.render.render(write_still=True);print('PREVIEW_DONE',name,flush=True)

import sys,os
sys.stdout.flush();os._exit(0)
