"""Toxic Turbo: procedural, editable Blender source. Blender 4.3+ / 5.x.
Run: blender -b -t 6 --python source/build_model.py
Coordinates in helpers: X right, longitudinal + rear, H up, meters.
Native Blender Y = -longitudinal; glTF export therefore faces -Z, +Y up.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
from math import sin,cos,pi,tau
HERE=Path(__file__).resolve().parent; OUT=HERE.parent
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(19)
def V(p):return Vector((p[0],-p[1],p[2]))
def mat(name,color,metal=0,rough=.3,emission=0,texture=None):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Metallic'].default_value=metal;n.inputs['Roughness'].default_value=rough
 if emission:n.inputs['Emission Color'].default_value=(*color,1);n.inputs['Emission Strength'].default_value=emission
 if texture:
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(HERE/texture));t.image.pack();m.node_tree.links.new(t.outputs['Color'],n.inputs['Base Color'])
 return m
lime=mat('Paint • toxic lime',(.48,.87,.002),.25,.26)
bodymat=mat('Paint • UV biohazard and organic splashes',(1,1,1),.36,.28,texture='body-paint.png')
finmat=mat('Paint • spotted lime fins',(1,1,1),.22,.28,texture='fin-paint.png')
black=mat('Mechanical • graphite',(.027,.034,.04),.72,.3)
chrome=mat('Metal • brushed polished steel',(.48,.55,.61),.92,.23)
edge=mat('Metal • satin alloy',(.22,.27,.30),.85,.3)
rubber=mat('Rubber • tire',(.012,.016,.019),0,.77)
leather=mat('Upholstery • charcoal vinyl',(.018,.022,.025),0,.57)
seam=mat('Upholstery • seams',(.055,.065,.066),0,.7)
glow=mat('Light • lime emitter',(.57,1,.006),.05,.22,3)
core=mat('Light • warm white core',(.93,1,.38),.0,.23,5)
yellow=mat('Light • amber', (1,.64,.008),.15,.2,2)
red=mat('Light • red',(.8,.008,.006),.15,.23,2)
blue=mat('Controls • blue',(.008,.22,.7),.25,.22)
gold=mat('Controls • yellow',(.93,.61,.006),.35,.22)
def finish(o,name,ma,smooth=True):
 o.name=name;o.data.materials.append(ma)
 if smooth:
  for f in o.data.polygons:f.use_smooth=True
 return o
def mesh(name,verts,faces,ma,uv=None,smooth=True):
 me=bpy.data.meshes.new(name);me.from_pydata([V(p) for p in verts],[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,name,ma,smooth)
 if uv:
  layer=me.uv_layers.new(name='UVMap')
  for p in me.polygons:
   for li in p.loop_indices:layer.data[li].uv=uv[me.loops[li].vertex_index]
 return o
def bevel(o,w=.008,n=3):
 b=o.modifiers.new('Soft manufactured edges','BEVEL');b.width=w;b.segments=n
 return o
def cube(name,p,scale,ma,b=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=V(p));o=bpy.context.object;o.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,ma,False)
 if b:bevel(o,b)
 return o
def ball(name,p,scale,ma,seg=16,rings=10):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,radius=1,location=V(p));o=bpy.context.object;o.scale=scale;return finish(o,name,ma)
def rod(name,a,b,r,ma,verts=16,r2=None):
 av=V(a);bv=V(b);delta=bv-av
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r,radius2=r if r2 is None else r2,depth=delta.length,location=(av+bv)/2)
 o=bpy.context.object;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();return finish(o,name,ma)
def tube(name,pts,r,ma,segments=8):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=1;c.bevel_depth=r;c.resolution_u=1;c.bevel_resolution=1;c.resolution_u=8
 s=c.splines.new('POLY');s.points.add(len(pts)-1)
 for p,q in zip(s.points,pts):p.co=(*V(q),1)
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(ma);return o
def ring(name,p,r,minor,ma,axis='long',N=48,M=8):
 vs=[];fs=[]
 for i in range(N):
  a=tau*i/N
  for j in range(M):
   b=tau*j/M;R=r+minor*cos(b)
   q=(minor*sin(b),R*cos(a),R*sin(a)) if axis=='x' else (R*cos(a),minor*sin(b),R*sin(a))
   vs.append(tuple(p[k]+q[k] for k in range(3)))
 for i in range(N):
  for j in range(M):fs.append((i*M+j,((i+1)%N)*M+j,((i+1)%N)*M+(j+1)%M,i*M+(j+1)%M))
 return mesh(name,vs,fs,ma)
def lathe(name,profile,ma,N=64):
 # profile entries: longitudinal, radius, height of axis (constant)
 vs=[];uv=[];fs=[]
 for j,(l,r,h) in enumerate(profile):
  for i in range(N+1):
   a=tau*i/N;vs.append((r*cos(a),l,h+r*sin(a)));uv.append((j/(len(profile)-1),i/N))
 for j in range(len(profile)-1):
  for i in range(N):
   k=j*(N+1)+i;fs.append((k,k+1,k+1+N+1,k+N+1))
 return mesh(name,vs,fs,ma,uv)
def bolt(name,p,axis='x',size=.008):
 q=list(p);q[0 if axis=='x' else 1]+=.008
 return rod(name,p,q,size,chrome,6)
# Continuous body shell: open ring sectors define a real cavity, not a deck.
sections=[(-.60,.257,.207,.337,0),(-.54,.276,.220,.337,0),(-.45,.289,.222,.337,0),(-.38,.295,.221,.337,.35),(-.32,.300,.222,.337,.70),(-.22,.304,.221,.337,.82),(0,.302,.216,.337,.87),(.18,.29,.224,.337,.84),(.32,.274,.241,.337,.68),(.40,.26,.244,.337,.35),(.45,.248,.234,.337,0),(.57,.225,.208,.337,0),(.65,.207,.187,.337,0)]
vs=[];uv=[];fs=[];N=64
for l,rx,rz,h,a in sections:
 for i in range(N+1):
  theta=pi/2+a+(tau-2*a)*i/N
  vs.append((rx*cos(theta),l,h+rz*sin(theta)));uv.append(((l+.60)/1.25,(theta-pi/2)/tau))
for j in range(len(sections)-1):
 for i in range(N):
  k=j*(N+1)+i;fs.append((k,k+1,k+N+2,k+N+1))
hull=mesh('Body_Main • open cockpit shell',vs,fs,bodymat,uv)
# Cockpit inner walls connect to the exact shell opening edges.
wallvs=[];wallfs=[]
for j,(l,rx,rz,h,a) in enumerate(sections):
 if a<=0:continue
 for side in (-1,1):
  x=side*rx*sin(a);top=h+rz*cos(a)
  wallvs.extend([(x,l,top),(x*.88,l,.245)])
for j in range(len(wallvs)//4-1):
 for off in (0,2):
  k=j*4+off;wallfs.append((k,k+4,k+5,k+1))
mesh('Cockpit_Interior • recessed side walls',wallvs,wallfs,leather)
cube('Cockpit_Floor',(0,.02,.244),(.38,.74,.025),leather,.025)
for s in (-1,1):
 pts=[]
 for l,rx,rz,h,a in sections:
  if -.45<=l<=.45:pts.append((s*rx*sin(a),l,h+rz*cos(a)+.004))
 tube('Cockpit_Rim',pts,.015,lime)
 tube('Cockpit_Inner_piping',[(x*.94,l,h-.014) for x,l,h in pts],.006,black)
# Nose ogive, seams and bolted lime collar.
lathe('Body_NoseCone',[(-.944,.036,.337),(-.925,.060,.337),(-.89,.096,.337),(-.84,.143,.337),(-.77,.190,.337),(-.69,.229,.337),(-.62,.252,.337)],black)
lathe('Body_NoseRing',[(-.626,.254,.337),(-.614,.260,.337),(-.555,.279,.337),(-.544,.277,.337)],lime)
for l,r in [(-.626,.254),(-.548,.278)]:ring('Nose_Collar_Steel_Seam',(0,l,.337),r,.004,chrome)
for i in range(12):
 a=tau*i/12;x=.269*cos(a);h=.337+.269*sin(a)
 ball('Nose_Rivet',(x,-.579,h),(.009,.009,.009),chrome,12,8)
rod('Light_Nose_Housing',(0,-.935,.337),(0,-.954,.337),.052,chrome,48)
rod('Light_Nose',(0,-.954,.337),(0,-.961,.337),.041,glow,48)
ball('Light_Nose_Lens',(0,-.963,.337),(.034,.012,.034),core,24,12)
# Seat, rear bucket and stitched segmented cushions.
seat=cube('Seat_Back • bucket',(0,.271,.433),(.335,.082,.270),black,.034);seat.rotation_euler.x=math.radians(12)
cube('Seat_Cushion',(0,.105,.284),(.31,.29,.066),leather,.029)
for row in range(3):
 for s in (-1,1):
  o=cube('Seat_Back_Padded_Segment',(s*.074,.222+row*.009,.352+row*.069),(.141,.035,.063),leather,.014);o.rotation_euler.x=math.radians(12)
for s in (-1,1):
 o=cube('Seat_Side_Bolster',(s*.154,.201,.412),(.048,.095,.238),leather,.023);o.rotation_euler.x=math.radians(12)
 for j in range(3):cube('Seat_Base_Segmented',(s*.074,-.001+j*.077,.322),(.14,.067,.020),leather,.009)
# Integrated control console, button bezels and a ball-topped joystick.
cube('Dashboard_Lime_Bezel',(0,-.329,.542),(.325,.155,.035),lime,.045)
cube('Dashboard_Control_Plate',(0,-.330,.564),(.293,.124,.016),black,.035)
for s,ma in [(-1,red),(1,blue)]:
 rod('Control_Button_Bezel',(s*.098,-.333,.572),(s*.098,-.333,.581),.029,chrome,24)
 ball('Control_Button',(s*.098,-.333,.582),(.023,.023,.013),ma,20,10)
for x in [-.048,.043]:
 for l in [-.37,-.30]:ball('Control_Indicator',(x,l,.578),(.009,.009,.006),yellow if l<-.33 else red,12,8)
rod('Joystick_Gaiter',(0,-.334,.576),(0,-.334,.595),.027,rubber,20,r2=.017)
rod('Joystick_Stem',(0,-.334,.593),(0,-.334,.635),.007,chrome)
ball('Joystick_Knob',(0,-.334,.642),(.022,.022,.022),gold,20,12)
# Rear thruster, tapered metal steps, turbine vanes and inset emitter.
lathe('Rear_Thruster_Housing',[(.52,.188,.335),(.60,.235,.335),(.69,.247,.335),(.73,.247,.335),(.76,.225,.335),(.84,.218,.335),(.887,.205,.335),(.905,.19,.335)],black)
for l,r,w in [(.615,.238,.013),(.718,.247,.014),(.775,.225,.010),(.874,.208,.010),(.906,.187,.012)]:ring('Thruster_Stepped_Alloy_Ring',(0,l,.335),r,w,chrome)
lathe('Thruster_Inner_Reflector',[(.91,.181,.335),(.875,.153,.335),(.855,.12,.335)],edge)
for i in range(24):
 a=tau*i/24
 rod('Thruster_Turbine_Vane',(.145*cos(a),.875,.335+.145*sin(a)),(.181*cos(a+.10),.90,.335+.181*sin(a+.1)),.005,black,6)
rod('Rear_Thruster_Emitter',(0,.866,.335),(0,.89,.335),.133,glow,64)
for r,l in [(.126,.893),(.105,.899),(.079,.902)]:ring('Emitter_Optic_Ring',(0,l,.335),r,.0035,lime)
ball('Rear_Thruster_Core',(0,.901,.335),(.067,.013,.067),core,32,16)
for i in range(12):
 a=tau*i/12
 ball('Thruster_Housing_Bolt',(.235*cos(a),.726,.335+.235*sin(a)),(.007,.009,.007),chrome,12,8)
cube('Rear_Light_Frame',(0,.701,.603),(.132,.063,.078),black,.016)
cube('Rear_Light_Red',(0,.737,.603),(.105,.012,.050),red,.009)
for x in [-.035,-.017,0,.017,.035]:cube('Rear_Light_Lens_Rib',(x,.745,.603),(.002,.002,.044),yellow,.0005)
# Real tire profiles with curved shoulders; separate axle pivots for wheel groups.
def wheel(name,p,r,width,spokes=10):
 group=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(group);group.location=V(p);group.empty_display_size=.05; group['rotation_axis']='local X';children=[]
 N=64; profile=[(-.50,.68),(-.50,.82),(-.43,.94),(-.28,.99),(-.10,1),(.10,1),(.28,.99),(.43,.94),(.50,.82),(.50,.68)]
 vs=[];fs=[]
 for xx,rr in profile:
  for i in range(N):
   a=tau*i/N;vs.append((p[0]+xx*width,p[1]+r*rr*cos(a),p[2]+r*rr*sin(a)))
 for j in range(len(profile)):
  for i in range(N):fs.append((j*N+i,j*N+(i+1)%N,((j+1)%len(profile))*N+(i+1)%N,((j+1)%len(profile))*N+i))
 children.append(mesh(name+'_Tire',vs,fs,rubber))
 for side in [-1,1]:
  x=p[0]+side*width*.503
  children.append(ring(name+'_Sidewall_bead',(x,p[1],p[2]),r*.86,.0025,rubber,'x',64,6))
  children.append(ring(name+'_Steel_lip',(x,p[1],p[2]),r*.69,.009,chrome,'x',48,8))
  children.append(ring(name+'_Rim_barrel',(x-side*.012,p[1],p[2]),r*.62,.012,black,'x',48,8))
  for i in range(spokes):
   a=tau*i/spokes
   children.append(rod(name+'_Spoke',(x,p[1]+r*.18*cos(a),p[2]+r*.18*sin(a)),(x-side*.009,p[1]+r*.64*cos(a+.13),p[2]+r*.64*sin(a+.13)),.009,edge,8))
  children.append(rod(name+'_Hub',(x-side*.018,p[1],p[2]),(x+side*.014,p[1],p[2]),r*.21,chrome,24))
  children.append(ball(name+'_Hub_cap',(x+side*.019,p[1],p[2]),(.011,r*.13,r*.13),edge,16,8))
  for i in range(5):
   a=tau*i/5
   children.append(ball(name+'_Lug',(x+side*.019,p[1]+r*.15*cos(a),p[2]+r*.15*sin(a)),(.004,.004,.004),chrome,8,6))
 # Shallow physical tread cuts use inset dark ribs following the tire's crown.
 for i in range(40):
  a=tau*i/40
  pts=[]
  for j in range(7):
   t=-.33+j*.11;rr=r*(.996-.06*(abs(t)/.50)**3);an=a+.07*(1-abs(t)/.50)
   pts.append((p[0]+width*t,p[1]+rr*cos(an),p[2]+rr*sin(an)))
  children.append(tube(name+'_Tread',pts,.0018,black))
 bpy.context.view_layer.update()
 for o in children:
  mw=o.matrix_world.copy();o.parent=group;o.matrix_world=mw
 return group
for s,tag in [(-1,'L'),(1,'R')]:
 wheel('Wheel_Rear_'+tag,(s*.364,.387,.211),.211,.156)
 # Silver arched fender following the upper tire, a proper 3D rolled sheet.
 vs=[];fs=[]
 for i in range(33):
  a=.10+(pi-.20)*i/32
  for xx in [s*.274,s*.452]:vs.append((xx,.387+.235*cos(a),.211+.235*sin(a)))
 for i in range(32):fs.append((2*i,2*i+1,2*i+3,2*i+2))
 o=mesh('Fender_'+tag,vs,fs,chrome);m=o.modifiers.new('Sheet thickness','SOLIDIFY');m.thickness=.010;bevel(o,.004,2)
 for xx in [s*.275,s*.451]:tube('Fender_Rolled_Edge',[(xx,.387+.235*cos(.1+(pi-.2)*i/32),.211+.235*sin(.1+(pi-.2)*i/32)) for i in range(33)],.005,black)
 # exposed lower frame and sweep up around rear assembly
 tube('Side_Pipe_'+tag,[(s*.302,-.42,.128),(s*.355,-.43,.128),(s*.39,-.38,.128),(s*.39,.51,.128),(s*.35,.64,.17),(s*.285,.66,.24)],.016,black)
 rod('Frame_Belly_Bracket',(s*.17,-.42,.128),(s*.31,-.42,.128),.016,black,12)
 rod('Side_Pipe_Silver_Inlay',(s*.39,-.32,.128),(s*.39,.20,.128),.012,chrome,20)
 for l in [-.33,.15]:ring('Pipe_Collar',(s*.39,l,.128),.019,.004,edge)
 rod('Suspension_Trailing_Arm',(s*.455,.387,.211),(s*.365,-.05,.153),.014,black)
 rod('Suspension_Piston',(s*.374,-.05,.163),(s*.374,.14,.19),.026,chrome,24)
 rod('Suspension_Gaiter',(s*.374,-.11,.155),(s*.374,-.02,.17),.024,rubber,20)
 rod('Shock_Steel_Shaft',(s*.328,.165,.205),(s*.328,.16,.46),.012,chrome)
 rod('Shock_Damper',(s*.328,.16,.30),(s*.328,.155,.48),.023,black)
 pts=[]
 for i in range(121):
  a=tau*7*i/120;pts.append((s*.328+.030*cos(a),.16+.030*sin(a),.30+.17*i/120))
 tube('Suspension_Coil',pts,.004,edge)
 for h in [.29,.47]:rod('Shock_Collar',(s*.328,.16,h-.006),(s*.328,.16,h+.006),.035,chrome,20)
 for l,h in [(.15,.47),(.387,.211),(.62,.49)]:ball('Suspension_Joint',(s*.34,l,h),(.027,.027,.027),black)
 # cylindrical engine tanks over each wheel
 rod('Engine_Cylinder_'+tag,(s*.28,.29,.513),(s*.28,.655,.513),.058,chrome,32)
 for l in [.31,.42,.60,.646]:
  ring('Engine_Cylinder_Collar',(s*.28,l,.513),.059,.007,black)
 ball('Engine_Cylinder_End',(s*.28,.666,.513),(.048,.016,.048),edge,20,12)
 rod('Tank_Feed_Pipe',(s*.28,.31,.51),(s*.20,.22,.54),.016,black)
 # tubular cage visibly anchored at joints
 tube('Frame_Outer_'+tag,[(s*.36,.03,.19),(s*.35,.13,.47),(s*.27,.28,.596),(s*.21,.58,.59),(s*.32,.69,.41),(s*.36,.59,.14)],.015,black)
 for p in [(s*.35,.13,.47),(s*.27,.28,.596),(s*.32,.69,.41)]:ball('Frame_Ball_Joint',p,(.022,.022,.022),edge)
 # front and rear facing yellow auxiliaries, housed on cage
 for l,direction in [(.12,-1),(.65,1)]:
  rod('Auxiliary_Lamp_Housing',(s*.358,l,.337),(s*.358,l+direction*.043,.337),.046,black,32)
  ring('Auxiliary_Lamp_Trim',(s*.358,l+direction*.045,.337),.037,.006,chrome,N=32)
  rod('Rear_Lamps_Yellow_'+tag,(s*.358,l+direction*.045,.337),(s*.358,l+direction*.049,.337),.032,yellow,32)
  ball('Auxiliary_Lamp_Lens',(s*.358,l+direction*.051,.337),(.023,.008,.023),core,16,10)
# Compact discrete support wheels preserve the ambiguous illustrated undercarriage.
wheel('Wheel_Support_Front',(0,-.66,.092),.092,.078,6)
wheel('Wheel_Support_Rear',(0,.68,.091),.091,.075,6)
for l in [-.66,.68]:rod('Support_Wheel_Fork',(-.052,l,.092),(.052,l,.092),.014,black)
# Thick, organic swept fins, textured on both faces with rounded edges.
def fin(name,profile,thickness):
 # profile list (x,l,h), thickness offset along X for dorsal; arbitrary side fins use explicit side offset
 vs=[];uv=[]
 for s in [-1,1]:
  for x,l,h in profile:
   width=(.095-.077*min(1,max(0,(h-.558)/.292))) if name=='Fin_Dorsal' else thickness
   vs.append((x+s*width/2,l,h));uv.append(((l-.30)/.48,(h-.40)/.48))
 n=len(profile);fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
 for i in range(n):j=(i+1)%n;fs.append((i,j,n+j,n+i))
 o=mesh(name,vs,fs,finmat,uv,False);bevel(o,.009,3);return o
fin('Fin_Dorsal',[(0,.36,.558),(0,.43,.672),(0,.55,.80),(0,.66,.848),(0,.79,.85),(0,.76,.785),(0,.70,.72),(0,.72,.686),(0,.67,.645),(0,.69,.585)],.027)
for s in [-1,1]:
 fin('Fin_Lateral_'+('R' if s>0 else 'L'),[(s*.205,.49,.39),(s*.29,.50,.47),(s*.435,.64,.56),(s*.43,.71,.545),(s*.355,.76,.452),(s*.23,.71,.37)],.022)
 rod('Fin_Mount_Brace',(s*.19,.52,.39),(s*.29,.65,.46),.015,black)
for l in [.43,.61]:
 cube('Dorsal_Fin_Mount',(0,l,.566),(.10,.065,.033),black,.008)
 for s in [-1,1]:ball('Fin_Mount_Bolt',(s*.038,l,.587),(.008,.008,.006),chrome,12,8)
# Belly plate and visible fasteners on body ends.
cube('Undercarriage_Belly',(0,-.04,.132),(.39,.97,.024),edge,.018)
for s in [-1,1]:
 for l in [-.43,-.23,-.03,.17]:bolt('Belly_Fastener',(s*.183,l,.117),size=.006)
 for l in [-.48,.33]:
  for h in [.23,.41]:ball('Body_Panel_Fastener',(s*.282,l,h),(.006,.007,.007),chrome,12,8)
print('STAGE geometry complete',len(bpy.context.scene.objects),flush=True)
# Convert curves, apply bevels, enforce outward normals, apply scale.
bpy.ops.object.select_all(action='DESELECT')
for o in list(bpy.context.scene.objects):
 if o.type in {'MESH','CURVE'}:
  bpy.context.view_layer.objects.active=o;o.select_set(True)
  if o.type=='CURVE':bpy.ops.object.convert(target='MESH')
  for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
# Consolidate static parts by material, keep lights and wheel pivots separate.
wheel_parts={o for g in bpy.context.scene.objects if g.type=='EMPTY' and g.name.startswith('Wheel_') for o in g.children}
static={o.name for o in bpy.context.scene.objects if o.type=='MESH' and o not in wheel_parts and not any(k in o.name for k in ['Light','Emitter','Core','Lamp'])}
print('STAGE joining static',flush=True)
for ma in list(bpy.data.materials):
 obs=[o for o in bpy.context.scene.objects if o.name in static and o.type=='MESH' and o.data.materials and o.data.materials[0]==ma]
 if len(obs)<2:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Static_'+ma.name.split(' • ')[0]+'_'+ma.name.split(' • ')[-1]
# Wheel child meshes can share one draw per wheel while retaining centered group pivots.
for g in [o for o in bpy.context.scene.objects if o.type=='EMPTY']:
 if g.type!='EMPTY' or not g.name.startswith('Wheel_'):continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in g.children:o.select_set(True)
 bpy.context.view_layer.objects.active=g.children[0];bpy.ops.object.join();o=bpy.context.object;o.name=g.name+'_Mesh';bpy.context.scene.cursor.location=g.location;bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
bpy.context.scene.cursor.location=(0,0,0)
root=bpy.data.objects.new('ToxicTurbo',None);bpy.context.collection.objects.link(root)
for o in list(bpy.context.scene.objects):
 if o!=root and not o.parent:o.parent=root
root['front']='-Z in glTF / Godot';root['units']='meters';root['design']='Reconstruction from provided illustrated references; underside inferred.'
print('STAGE export',flush=True)
exec(compile((HERE/'export_asset.py').read_text(),str(HERE/'export_asset.py'),'exec'))
import sys,os
sys.stdout.flush();os._exit(0)
