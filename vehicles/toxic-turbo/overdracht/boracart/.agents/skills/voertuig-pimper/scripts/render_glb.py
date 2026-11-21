"""Blender: --python render_glb.py -- model.glb --out-dir previews [--views front-right,top].
Reimports the GLB and renders only; does not modify or re-export the vehicle.
"""
import argparse,json,sys,os
from pathlib import Path
import bpy
from mathutils import Vector

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('glb',type=Path);p.add_argument('--out-dir',required=True,type=Path)
p.add_argument('--views',default='all');p.add_argument('--width',type=int,default=640);p.add_argument('--height',type=int,default=480);p.add_argument('--samples',type=int,default=12)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
views={'front-right':(1.5,2.1,1.0),'front-left':(-1.5,2.1,1.0),'rear-right':(1.5,-2.1,1.0),'rear-left':(-1.5,-2.1,1.0),'left':(-3,0,.12),'right':(3,0,.12),'front':(0,3,.12),'rear':(0,-3,.12),'top':(0,.001,3.5)}
chosen=['front-right','rear-right','left','right','front','rear','top','rear-left'] if a.views=='all' else a.views.split(',')
if any(v not in views for v in chosen):p.error('Unknown view; choose '+','.join(views))
if min(a.width,a.height,a.samples)<1:p.error('Resolution and sample count must be positive')
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(a.glb.resolve()))
vs=[o.matrix_world@Vector(c) for o in bpy.context.scene.objects if o.type=='MESH' for c in o.bound_box]
if not vs:p.error('No mesh geometry found')
lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)]);target=(lo+hi)/2
unit=max(hi-lo)/1.85
if unit<=0:p.error('Zero-sized geometry')
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=a.samples;sc.cycles.use_denoising=True
sc.world=bpy.data.worlds.new('Neutral Studio');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.24,.30,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
floor=bpy.data.materials.new('Studio floor');floor.use_nodes=True;n=floor.node_tree.nodes['Principled BSDF'];n.inputs['Base Color'].default_value=(.055,.07,.09,1);n.inputs['Roughness'].default_value=.78
bpy.ops.mesh.primitive_plane_add(size=200*unit,location=(target.x,target.y,lo.z-.006*unit));bpy.context.object.data.materials.append(floor)
for pos,power,size in [((1.8,1.3,2.8),350,2.6),((-2,.3,1.3),250,2.3),((.4,-2.5,2.2),450,2.0)]:
 bpy.ops.object.light_add(type='AREA',location=target+Vector(pos)*unit);o=bpy.context.object;o.data.energy=power*unit*unit;o.data.shape='DISK';o.data.size=size*unit;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;sc.camera=cam;cam.data.type='ORTHO';cam.data.sensor_fit='HORIZONTAL';sc.view_settings.view_transform='Standard';sc.view_settings.exposure=-1.3
sc.render.resolution_x=a.width;sc.render.resolution_y=a.height;sc.render.resolution_percentage=100
a.out_dir.mkdir(parents=True,exist_ok=True);done=[]
for name in chosen:
 cam.location=target+Vector(views[name])*unit;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
 inv=cam.rotation_euler.to_quaternion().inverted();projected=[inv@(v-target) for v in vs]
 width=2*max(abs(v.x) for v in projected);height=2*max(abs(v.y) for v in projected)
 cam.data.ortho_scale=max(width,height*(a.width/a.height))*1.15
 sc.render.filepath=str(a.out_dir/(name+'.png'));bpy.ops.render.render(write_still=True);done.append(name);print('PREVIEW_DONE',name,flush=True)
(a.out_dir/'render-report.json').write_text(json.dumps({'input':str(a.glb.resolve()),'views':done,'resolution':[a.width,a.height],'samples':a.samples,'orientation_note':'Views assume glTF +Y up / -Z front. Check source orientation against references.'},indent=2)+'\n')
sys.stdout.flush();os._exit(0)
