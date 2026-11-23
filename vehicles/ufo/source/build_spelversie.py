"""Build an editable UFO shape study. Blender +Y forward exports to glTF -Z."""
import bpy, math
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color,metal=0,rough=.35):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m
teal=material('Turquoise emaille',(.008,.30,.27),.28,.24);cream=material('Ivoor',(.92,.79,.53),.18);orange=material('Oranje cockpitlijst',(.93,.19,.025),.22);metal=material('Gepolijst metaal',(.5,.57,.6),.85,.21);gold=material('Messing',(.8,.49,.08),.75);rubber=material('Banden',(.013,.017,.02),0,.75);seat=material('Zwarte bekleding',(.023,.026,.03),0,.62);red=material('Rode lamp',(.85,.018,.015),.25);green=material('Groene lamp',(.02,.7,.27),.2);yellow=material('Gele lamp',(1,.57,.025),.2)
def finish(o,name,ma):
 o.name=name;o.data.materials.append(ma)
 for f in o.data.polygons:f.use_smooth=True
 return o
def ball(name,loc,scale,ma):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=32,location=loc);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,ma)
def box(name,loc,size,ma,bevel=.04):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Ronde hoeken','BEVEL');mod.width=bevel;mod.segments=4;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return finish(o,name,ma)
def cyl(name,loc,r,depth,ma,axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=r,depth=depth,location=loc);o=bpy.context.object
 if axis=='X':o.rotation_euler[1]=math.pi/2
 if axis=='Y':o.rotation_euler[0]=math.pi/2
 return finish(o,name,ma)
def ring(name,rx,ry,z,r,ma,cy=0):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.resolution_u=16;curve.bevel_depth=r;curve.bevel_resolution=3
 sp=curve.splines.new('POLY');sp.points.add(127)
 for i,p in enumerate(sp.points):
  a=math.tau*i/128;p.co=(rx*math.cos(a),cy+ry*math.sin(a),z,1)
 sp.use_cyclic_u=True;o=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(o);o.data.materials.append(ma);return o
# True recessed opening: subtract an elliptical cutter from a single closed shell.
shell=ball('Schotel carrosserie',(0,0,.46),(.56,.88,.26),teal)
bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=1,depth=1,location=(0,-.02,.85));cut=bpy.context.object;cut.scale=(.255,.38,1.1);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
mod=shell.modifiers.new('Open cockpit','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cut;bpy.context.view_layer.objects.active=shell;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
# Surrounding bright bands follow the oval silhouette.
ring('Chroom stootrand',.55,.865,.46,.022,metal)
ring('Lichte band',.525,.825,.52,.028,cream)
ring('Cockpitrand',.255,.38,.70,.026,orange,cy=-.02)
box('Cockpit bodem',(0,-.02,.35),(.42,.63,.055),seat)
box('Seat_Cushion',(0,-.13,.40),(.35,.29,.08),seat)
back=box('Stoelleuning',(0,-.31,.56),(.36,.10,.34),seat);back.rotation_euler[0]=-.12
box('Dashboard',(0,.28,.52),(.30,.09,.08),seat)
cyl('Pook',(0,.27,.60),.015,.12,metal);ball('Pookknop',(0,.27,.68),(.033,.033,.033),gold)
for x,ma in [(-.09,red),(.0,green),(.09,yellow)]:ball('Dashboard knop',(x,.29,.58),(.018,.018,.015),ma)
# Four wheels are the consistent choice from the underside reference.
for side in (-1,1):
 for y,label in ((.48,'Front'),(-.48,'Rear')):
  x=side*.38;z=.16
  bpy.ops.object.empty_add(location=(x,y,z));p=bpy.context.object;p.name='Wheel_'+label+('_L' if side<0 else '_R')
  for n,r,d,m in [('Band',.16,.12,rubber),('Velg',.09,.13,metal),('Naaf',.037,.14,gold)]:
   o=cyl(n,(x,y,z),r,d,m,'X');o.parent=p;o.matrix_parent_inverse=p.matrix_world.inverted()
# Fairground canopy is behind the driver. This is not a gameplay camera guarantee.
cyl('Kap steun',(0,-.60,.79),.10,.30,cream)
ball('Kap',(0,-.60,.96),(.23,.23,.09),teal)
ring('Kap rand',.22,.22,.94,.015,gold,cy=-.60)
ball('Kap knop',(0,-.60,1.065),(.045,.045,.045),gold)
for i in range(12):
 a=math.tau*i/12;ma=[red,yellow,green][i%3]
 ball('Kermislamp',(math.cos(a)*.534,math.sin(a)*.838,.53),(.034,.034,.034),ma)
for y,ma in ((.865,yellow),(-.865,red)):
 cyl('Rijrichting lamp rand',(0,y,.47),.075,.045,metal,'Y');cyl('Rijrichting lamp',(0,y+(.025 if y>0 else -.025),.47),.055,.05,ma,'Y')
# Reduce the width for the existing track and vehicle framing contract.
roots=[o for o in bpy.context.scene.objects if o.parent is None]
bpy.ops.object.empty_add(location=(0,0,0));root=bpy.context.object;root.name='UFO_Root'
for o in roots:
 o.parent=root
root.scale.x=.86
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ufo-spel.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'ufo-spel.glb'),export_format='GLB',export_yup=True,export_apply=True)
