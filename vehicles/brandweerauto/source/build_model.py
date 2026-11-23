import bpy, math
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def mat(name,color,metal=0,rough=.3):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
red=mat('Rood emaille',(.62,.012,.018),.32); cream=mat('Ivoor',(.88,.73,.48),.18); brass=mat('Messing',(.8,.47,.08),.75); chrome=mat('Chroom',(.55,.61,.65),.85,.22); rubber=mat('Rubber',(.013,.018,.024),0,.75); black=mat('Bekleding',(.025,.028,.032),0,.6); blue=mat('Blauw glas',(.015,.18,.85),.35,.19); yellow=mat('Koplamp', (1,.7,.19),.2)
def finish(o,name,ma):
 o.name=name;o.data.materials.append(ma)
 for p in o.data.polygons:p.use_smooth=True
 return o
def box(name,loc,scale,ma,bev=.05):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bev:
  mod=o.modifiers.new('Afgeronde randen','BEVEL');mod.width=bev;mod.segments=3;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
  mod=o.modifiers.new('Normaal','WEIGHTED_NORMAL');mod.keep_sharp=True
 return finish(o,name,ma)
def ball(name,loc,scale,ma):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=loc);o=bpy.context.object;o.scale=scale;return finish(o,name,ma)
def cyl(name,loc,radius,depth,ma,axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=radius,depth=depth,location=loc);o=bpy.context.object
 if axis=='X':o.rotation_euler[1]=math.pi/2
 if axis=='Y':o.rotation_euler[0]=math.pi/2
 return finish(o,name,ma)
def rod(name,a,b,r,ma):
 d=Vector(b)-Vector(a);o=cyl(name,(Vector(a)+Vector(b))/2,r,d.length,ma);o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return o
# Forward is +Y in Blender, exported as -Z in glTF.
box('Chassis',(0,0,.25),(.65,1.52,.18),black)
box('Rode carrosserie',(0,-.05,.43),(.72,1.45,.31),red,.11)
box('Motorkap',(0,.52,.62),(.59,.57,.29),red,.11)
box('Motorkap accent',(0,.52,.77),(.32,.42,.025),cream,.012)
box('Achterbouw',(0,-.62,.62),(.64,.26,.39),red,.07)
box('Achterpaneel',(0,-.765,.62),(.48,.035,.24),cream,.03)
# Readable open cockpit with seat surface used by Godot.
box('Cockpit bodem',(0,-.10,.60),(.46,.53,.06),black,.025)
box('Seat_Cushion',(0,-.18,.665),(.38,.32,.09),black,.04)
back=box('Stoelleuning',(0,-.39,.80),(.39,.12,.38),black,.05);back.rotation_euler[0]=-.12
for x in (-.27,.27):box('Cockpitrand',(x,-.08,.67),(.09,.64,.11),cream,.04)
box('Dashboard',(0,.24,.71),(.45,.12,.12),black,.035)
rod('Pook',(0,.23,.76),(0,.18,.86),.018,chrome);ball('Pookknop',(0,.18,.87),(.035,.035,.035),brass)
for x in (-.13,.13):ball('Dashboard knop',(x,.25,.78),(.018,.018,.015),yellow)
# Wheels pivot around X, tires near ground.
for side in (-1,1):
 for y,label in ((.52,'Front'),(-.50,'Rear')):
  x=side*.39;z=.20
  bpy.ops.object.empty_add(location=(x,y,z)); pivot=bpy.context.object;pivot.name='Wheel_'+label+('_L' if side<0 else '_R')
  for n,r,d,m in [('Tire',.20,.13,rubber),('Hub',.115,.14,chrome),('Hubcap',.055,.15,brass)]:
   o=cyl(n,(x,y,z),r,d,m,'X');o.parent=pivot;o.matrix_parent_inverse=pivot.matrix_world.inverted()
  ball('Spatbord',(side*.36,y,.38),(.15,.25,.12),red)
# front grille and headlights on forward face
box('Radiateur',(0,.827,.58),(.27,.05,.25),chrome,.035)
for x in (-.09,-.045,0,.045,.09):box('Grille spijl',(x,.858,.58),(.014,.015,.18),black,.004)
for x in (-.27,.27):
 cyl('Koplamp rand',(x,.795,.57),.072,.05,chrome,'Y');cyl('Koplamp glas',(x,.83,.57),.057,.025,yellow,'Y')
 rod('Zwaailicht voet',(x,-.55,.80),(x,-.55,.94),.025,brass)
 cyl('Zwaailicht',(x,-.55,.97),.045,.09,blue)
# bell and arch, ladder along side
rod('Bel beugel links',(-.17,-.59,.82),(-.17,-.59,1.02),.015,brass);rod('Bel beugel rechts',(.17,-.59,.82),(.17,-.59,1.02),.015,brass);rod('Bel beugel boven',(-.17,-.59,1.02),(.17,-.59,1.02),.015,brass)
ball('Bel',(0,-.59,.96),(.065,.065,.055),brass)
for x in (-1,1):
 for z in (.53,.69):rod('Ladder stijl',(x*.39,-.68,z),(x*.39,-.27,z),.012,brass)
 for y in (-.64,-.55,-.46,-.37,-.28):rod('Ladder sport',(x*.39,y,.53),(x*.39,y,.69),.01,brass)
rod('Voorbumper',(-.36,.87,.29),(.36,.87,.29),.035,chrome)
rod('Achterbumper',(-.34,-.80,.29),(.34,-.80,.29),.03,chrome)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'brandweerauto-improved.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'brandweerauto-improved.glb'),export_format='GLB',export_yup=True,export_apply=True)
