#!/usr/bin/env python3
"""Rebuild six photo/reference-driven landmarks (Blender 4.5+).
Run: blender -b --python game/tools/build_uithoorn_landmarks.py
Optional after --: landmark slugs and --preview (Cycles render; CPU). Meter scale, Y-up GLB, ground Y=0,
front +Z. Embedded cropped base-color textures + Principled PBR materials.
Original source photos and generated reference sheets remain untouched.
"""
import bpy, bmesh, math, json, shutil, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SOURCES=ROOT/'assets/straatbeeld/uithoorn'
OUT=ROOT/'game/assets/models'
TEXTURES=ROOT/'game/assets/textures/uithoorn-landmarks'
IDS=['rechthuis','schanskerk','fort-aan-de-drecht','irenebrug','thamerkerk','de-hoeksteen']
PREF={'rechthuis':'het_rechthuis','schanskerk':'de_schanskerk','fort-aan-de-drecht':'fort_aan_de_drecht','irenebrug':'irenebrug','thamerkerk':'thamerkerk','de-hoeksteen':'de_hoeksteen'}
REPORT={}
M={};OBJ=[];SLUG=''
def material(name,color,rough=.8,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.use_backface_culling=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m

def texmat(file,role):
 # crop boxes are authored after inspecting supplied panels; no reference-sheet
 # labels, black/white canvas or photos of the complete building are tiled.
 boxes=json.loads((SOURCES/'texture-crops.json').read_text()) if (SOURCES/'texture-crops.json').exists() else {}
 box=boxes.get(SLUG,{}).get(file.name)
 im=bpy.data.images.load(str(file),check_existing=False);w,h=im.size
 if box is None:
  # Largest connected vertical and horizontal span of content: safe fallback.
  px=list(im.pixels);good=[]
  for yy in range(h):
   count=sum(1 for xx in range(w) if .055<sum(px[(yy*w+xx)*4:(yy*w+xx)*4+3])/3<.93)
   if count>w*.12:good.append(yy)
  y0,y1=(min(good),max(good)+1) if good else (0,h)
  box=[0,max(0,1-y1/h),1,min(1,1-y0/h)]
 x0,y0,x1,y1=box;x0=int(x0*w);x1=int(x1*w);yb=int((1-y1)*h);yt=int((1-y0)*h)
 pixels=list(im.pixels);crop=[]
 for yy in range(yb,yt):crop.extend(pixels[(yy*w+x0)*4:(yy*w+x1)*4])
 ci=bpy.data.images.new(SLUG+'_'+role,x1-x0,yt-yb,alpha=False);ci.pixels=crop
 td=TEXTURES/SLUG;td.mkdir(parents=True,exist_ok=True);ci.filepath_raw=str(td/(role+'.png'));ci.file_format='PNG';ci.save();ci.pack()
 m=material(SLUG+'_'+role,(1,1,1),.84 if role!='window' else .3)
 nt=m.node_tree;node=nt.nodes.new('ShaderNodeTexImage');node.image=ci;nt.links.new(node.outputs['Color'],nt.nodes.get('Principled BSDF').inputs['Base Color'])
 # Subtle masonry relief uses supplied color solely as a local height proxy.
 if role in ['wall','roof','base']:
  bump=nt.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.045;nt.links.new(node.outputs['Color'],bump.inputs['Height']);nt.links.new(bump.outputs['Normal'],nt.nodes.get('Principled BSDF').inputs['Normal'])
 return m

def register(ob,mat):
 ob.data.materials.append(mat);OBJ.append(ob);return ob

def uv_box(ob,tile=0,aspect=1):
 for old in list(ob.data.uv_layers): ob.data.uv_layers.remove(old)
 uv=ob.data.uv_layers.new(name='UVMap')
 for p in ob.data.polygons:
  n=p.normal;axes=(0,1) if abs(n.z)>.7 else ((0,2) if abs(n.y)>.7 else (1,2))
  vals=[ob.data.vertices[ob.data.loops[i].vertex_index].co for i in p.loop_indices]
  lo=[min(v[a] for v in vals) for a in axes];hi=[max(v[a] for v in vals) for a in axes]
  for i,v in zip(p.loop_indices,vals):uv.data[i].uv=tuple((v[a]-lo[k])/((tile/(aspect if k else 1)) or max(.001,hi[k]-lo[k])) for k,a in enumerate(axes))

def box(name,loc,size,mat,tile=0,rot=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);uv_box(o,tile);o.rotation_euler.z=rot;return register(o,mat)

def mesh(name,verts,faces,mat,tile=2,aspect=1):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free();ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);uv_box(ob,tile,aspect);return register(ob,mat)

def roof(name,x,y,w,d,z,h,mat,hip=True):
 # Closed hip roof (all four sloped sides and underside).
 a,b=w/2,d/2;run=min(w,d)*.32
 if hip:
  v=[(x-a,y-b,z),(x+a,y-b,z),(x+a,y+b,z),(x-a,y+b,z),(x-a+run,y,z+h),(x+a-run,y,z+h)];f=[(0,3,2,1),(0,1,5,4),(1,2,5),(2,3,4,5),(3,0,4)]
 else:
  v=[(x-a,y-b,z),(x+a,y-b,z),(x+a,y+b,z),(x-a,y+b,z),(x,y-b,z+h),(x,y+b,z+h)];f=[(0,3,2,1),(0,1,4),(3,5,2),(0,4,5,3),(1,2,5,4)]
 image=next((n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE'),None)
 return mesh(name,v,f,mat,2.4,(image.size[0]/image.size[1]) if image else 1)

def cyl(name,loc,r,depth,mat,vertices=16,r2=None):
 bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc);o=bpy.context.object;o.name=name;uv_box(o,2);return register(o,mat)

def beam(name,a,b,width,mat):
 mid=(Vector(a)+Vector(b))/2;o=box(name,mid,(width,width,(Vector(b)-Vector(a)).length),mat);o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();return o

def arch(name,x,y,z,w,h,mat,depth=.08):
 # Extruded round-arched opening with closed back, front and edge surfaces.
 outline=[(-w/2,0),(w/2,0),(w/2,h-w/2)]
 for i in range(1,13):
  ang=i*math.pi/12;outline.append((math.cos(ang)*w/2,h-w/2+math.sin(ang)*w/2))
 N=len(outline);v=[(x+xx,y+dy,z+zz) for dy in [-depth/2,depth/2] for xx,zz in outline]
 f=[tuple(range(N-1,-1,-1)),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)]
 return mesh(name,v,f,mat,0)

def window(x,y,z,w,h,side=0,texture=True,facing=None):
 mat=M.get('window',M['glass']) if texture else M['glass']
 # Closed sill/frame and inset colored/textured pane, not a photo billboard.
 outward=facing if facing is not None else (-1 if side or y<0 else 1)
 outer=box('Window stone surround',(x,y,z),(w+.24,.16,h+.24),M['cream']);inner=box('Window inset UV',(x,y+outward*.10,z),(w,.08,h),mat)
 # Planar central crop preserves the source image aspect instead of squeezing
 # a wide window/shutters patch into a narrow vertical glazing bay.
 image=next((n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE'),None)
 if image:
  crop_u=min(1,(w/h)/(image.size[0]/image.size[1]))
  for poly in inner.data.polygons:
   if abs(poly.normal.y)>.7:
    for li in poly.loop_indices:
     uv=inner.data.uv_layers.active.data[li].uv;uv.x=.5+(uv.x-.5)*crop_u
 if side:
  # rotate assembled facade feature around its own anchor
  for o in [outer,inner]:
   rel=o.location-Vector((x,y,z));o.location=Vector((x,y,z))+Vector((-rel.y*side,rel.x*side,rel.z));o.rotation_euler.z=side*math.pi/2
 return inner

def clock(x,y,z,r):
 o=cyl('Clock face',(x,y,z),r,.09,M['cream'],32);o.rotation_euler.x=math.pi/2
 outward=-1 if y<0 else 1;yo=y+outward*.08
 beam('Clock hand',(x,yo,z),(x+.02,yo,z+r*.7),.055,M['dark']);beam('Clock hand',(x,yo,z),(x+r*.5,yo,z-.18),.055,M['dark'])

def rechthuis():
 box('Brick main building',(0,0,4.3),(22,14,8.6),M['wall'],3)
 box('Stone base',(0,0,.32),(22.4,14.4,.64),M['stone'],2)
 roof('Hipped tile roof',0,0,23,15,8.7,3.8,M['roof'])
 for yy in [-7.12,7.12]:
  for x in [-8,-4,0,4,8]:
   for z in [2.4,6.5]:window(x,yy,z,2,2.5,texture=True)
   if yy<0:
    box('Separate black awning',(x,yy-.65,4.1),(3,1.4,.14),M['dark'])
    for sx in [-1,1]:box('Burgundy shutter',(x+sx*1.35,yy-.10,6.5),(.45,.16,2.5),M['burgundy'])
 for side in [-1,1]:
  for y in [-4,0,4]:
   for z in [2.4,6.5]:window(side*11.13,y,z,1.65,2.5,side=side)
 for x in [-7,-2.4,2.4,7]:
  box('Dormer',(x,-3.9,10.4),(2,2.8,1.8),M['cream']);window(x,-5.36,10.4,1.35,1.45,texture=False);roof('Dormer cap',x,-3.9,2.35,3.1,11.35,.25,M['roof'])
 for x in [-9,9]:box('Chimney',(x,1.3,12.0),(.8,.8,2.8),M['wall'],2)
 box('Waterside terrace',(0,10,.35),(25,7,.7),M['stone'],3);box('Glazed waterside pavilion',(0,8.2,2.2),(21,2.3,3.4),M['glass'])
 box('Waterside dark canopy',(0,9.6,4.1),(23,4,.18),M['dark'])
 for x in range(-11,12,2):box('Terrace upright',(x,13.3,1.15),(.08,.08,1.6),M['cream'])
 for z in [.8,1.5]:box('Terrace horizontal',(0,13.3,z),(23,.08,.08),M['cream'])
 box('Street balcony',(0,-8.2,5.15),(5,2.2,.25),M['cream'])
 for x in [-2.4,0,2.4]:box('Balcony upright',(x,-9.2,5.8),(.08,.08,1.3),M['dark'])
 box('Balcony rail',(0,-9.2,6.3),(5,.08,.08),M['dark'])

def schanskerk():
 box('Nave brick volume',(0,4,7),(17,48,14),M['wall'],3)
 roof('Nave closed gabled roof',0,4,18,49,14,6,M['roof'],False)
 for s in [-1,1]:
  box('Lower side aisle',(s*10,4,3.8),(4.4,47,7.6),M['wall'],3)
  roof('Aisle closed roof',s*10,4,5.1,48,7.7,2,M['roof'])
  for y in range(-15,25,6):
   # side arches made in local XZ then rotated around center
   a=arch('Romanesque side window',0,0,0,2.1,4.8,M['glass']);a.rotation_euler.z=s*math.pi/2;a.location=(s*12.27,y,2.0)
   box('Side buttress',(s*12.3,y+2.4,4.5),(.9,.9,9),M['wall'],2)
   a=arch('Clerestory round arch',0,0,0,1.4,3.3,M['glass']);a.rotation_euler.z=s*math.pi/2;a.location=(s*8.6,y,10.0)
 for x in [-8,8]:
  box('Square brick bell tower',(x,-21,12.2),(6,7,24.4),M['wall'],3)
  for z in [6,13,20,24.6]:box('Tower cornice',(x,-21,z),(6.5,7.5,.35),M['cream'])
  for xx in [-1.3,1.3]:arch('Belfry round opening',x+xx,-24.56,19.2,1.5,3.2,M['dark'])
  clock(x,-24.66,16.6,1.15)
  cyl('Square pointed slate spire',(x,-21,31),4.7,13,M['roof'],4,r2=0).rotation_euler.z=math.pi/4
  beam('Tower cross stem',(x,-21,37.5),(x,-21,39),.10,M['gold']);beam('Tower cross arm',(x-.4,-21,38.5),(x+.4,-21,38.5),.10,M['gold'])
 box('Front central facade',(0,-21,8),(10,6.8,16),M['wall'],3)
 roof('Front pediment',0,-21,11,7.2,16,5,M['roof'],False)
 arch('Round entrance stone',0,-24.5,.2,4.6,5.5,M['cream']);arch('Round wooden entrance',0,-24.62,.2,3.6,4.8,M['dark'])
 # Rose window set in round stone ring, matching actual facade photograph.
 o=cyl('Rose stone surround',(0,-24.56,12.3),2.5,.15,M['cream'],32);o.rotation_euler.x=math.pi/2
 o=cyl('Rose glazing',(0,-24.68,12.3),2.13,.12,M['glass'],32);o.rotation_euler.x=math.pi/2
 for i in range(12):
  a=i*math.tau/12;beam('Rose tracery',(0,-24.8,12.3),(math.cos(a)*2,-24.8,12.3+math.sin(a)*2),.07,M['cream'])
 cyl('Apse masonry',(0,27,6),8.4,12,M['wall'],10);cyl('Apse slate cap',(0,27,14),8.8,4,M['roof'],10,r2=0)

def thamerkerk():
 # Octagonal clipped rectangular footprint, built as a watertight prism.
 w,d,c=22,17,2.8;poly=[(-w/2+c,-d/2),(w/2-c,-d/2),(w/2,-d/2+c),(w/2,d/2-c),(w/2-c,d/2),(-w/2+c,d/2),(-w/2,d/2-c),(-w/2,-d/2+c)]
 v=[(x,y,z) for z in [0,9] for x,y in poly];f=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)];mesh('Clipped brick hall',v,f,M['wall'],3)
 # Closed radial hip shell covers clipped corners exactly.
 v=[(x*1.04,y*1.04,9.1) for x,y in poly]+[(-3,0,14),(3,0,14)];f=[tuple(range(7,-1,-1)),(0,1,9,8),(1,2,9),(2,3,9),(3,4,9),(4,5,8,9),(5,6,8),(6,7,8),(7,0,8)];mesh('Clipped hipped tile roof',v,f,M['roof'],2.1)
 for yy in [-8.57,8.57]:
  outward=-1 if yy<0 else 1
  for x in [-6.2,-2.2,2.2,6.2]:
   arch('White round window surround',x,yy,2.3,1.8,4.5,M['cream']);arch('Round window inset',x,yy+outward*.10,2.48,1.48,4.13,M['glass'])
   for dx in [-.4,0,.4]:box('Window vertical glazing bar',(x+dx,yy+outward*.17,4.4),(.045,.05,3.3),M['cream'])
   for z in [3.3,4.4,5.5]:box('Window horizontal bar',(x,yy+outward*.17,z),(1.45,.05,.045),M['cream'])
 for side in [-1,1]:
  a=arch('End arched window',0,0,0,2,4.6,M['glass']);a.rotation_euler.z=side*math.pi/2;a.location=(side*11.04,0,2.6)
 box('White entrance portico entablature',(0,-9.4,6.7),(4.6,2.2,.65),M['cream'])
 for x in [-1.8,1.8]:cyl('White portico column',(x,-10,3),.23,6,M['cream'],16)
 box('Entrance dark double door',(0,-8.67,2.5),(2,.18,5),M['dark'])
 cyl('White octagonal tower base',(0,0,14.6),1.8,1.8,M['cream'],8)
 for x,y in [(0,-1.7),(0,1.7),(-1.7,0),(1.7,0)]:
  if y:clock(x,y,15.1,.65)
 cyl('Bell dark interior',(0,0,17.5),1.20,3,M['dark'],8)
 for i in range(8):
  a=i*math.tau/8;cyl('Open cupola white column',(math.cos(a)*1.55,math.sin(a)*1.55,17.5),.13,3,M['cream'],8)
 cyl('Cupola white cornice',(0,0,19.1),1.9,.35,M['cream'],8)
 cyl('Cupola domed cap',(0,0,20.1),1.9,1.7,M['roof'],8,r2=.50)
 cyl('Cupola finial',(0,0,21.2),.45,1.0,M['cream'],8,r2=.03)
 beam('Gold weather vane',(0,0,21.6),(0,0,23),.08,M['gold']);beam('Gold weather vane arrow',(-.6,0,22.6),(.6,0,22.6),.08,M['gold'])

def hoeksteen():
 box('Main square masonry volume',(0,0,6.25),(25,25,12.5),M['wall'],4)
 box('Stone tiled plinth',(0,0,.65),(25.2,25.2,1.3),M['base'],2)
 box('Flat dark roof',(0,0,12.55),(25.4,25.4,.22),M['dark'])
 for yy in [-12.57,12.57]:
  for x in [-9,-5,1.5,5.5,9.5]:window(x,yy,6.8,3.2,9.4,texture=True)
  for x in [-12.5,-2.5,12.5]:box('White vertical concrete frame',(x,yy-.13,6.3),(.24,.28,12.6),M['cream'])
  for z in [1.4,6.6,12.3]:box('White concrete horizontal',(0,yy-.14,z),(25.3,.28,.24),M['cream'])
 for side in [-1,1]:
  for z in [3.5,7.2,10.6]:
   for y in [-8,-4,0,4,8]:window(side*12.57,y,z,3.5,1.1,side=side,texture=False)
 box('Low entry annex',(16,5,2.4),(7,12,4.8),M['wall'],4)
 box('Annex flat overhang',(16,5,4.9),(8,13,.25),M['cream'])
 box('Separate glazed stair tower',(14,-7,6),(3.4,7,12),M['glass'])
 for z in [0,3,6,9,12]:box('Stair concrete landing',(14,-7,z+.1),(3.6,7.2,.2),M['cream'])
 for x in [12.25,15.75]:
  for y in [-10.6,-3.4]:box('Stair white corner',(x,y,6),(.13,.13,12),M['cream'])
 box('Red double door',(16,-1.1,1.4),(2.4,.16,2.8),M.get('door',M['red']))
 # Rietveld rooftop red square is a 3D outline, not a decal.
 for x in [-1.3,1.3]:box('Roof red open frame',(x,6,13.6),(.25,.5,2.3),M['red'])
 box('Roof red frame top',(0,6,14.65),(2.8,.5,.25),M['red'])
 # Raised identifying lettering on water-facing facade.
 bpy.ops.object.text_add(location=(-.5,-12.85,8.3),rotation=(math.pi/2,0,0));o=bpy.context.object;o.name='GERRIT facade lettering';o.data.body='GERRIT.';o.data.size=1.2;o.data.extrude=.025;o.data.materials.append(M['cream']);bpy.ops.object.convert(target='MESH');o=bpy.context.object;bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.0001);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);bm.free();OBJ.append(o)

def fort():
 # Actual low concrete front + earth-covered rear, intentionally no fake castle.
 box('Low concrete barracks',(0,0,2.5),(53,15,5),M['wall'],4)
 box('Earth covered rear',(0,8,2.5),(54,25,5),M['roof'],4)
 cyl('Rounded protruding casemate',(24,-8,2.5),8,5,M['wall'],32)
 cyl('Casemate earth cap',(24,-8,5.05),8.2,.45,M['roof'],32)
 for x in range(-23,23,5):
  arch('Fort arched surround',x,-7.60,.35,2.2,3.4,M['stone']);arch('Fort recessed door',x,-7.74,.38,1.75,3.05,M.get('opening',M['dark']))
 for x in [-3,3]:box('Entrance concrete side',(x,-8,2.8),(1.2,3,5.6),M['wall'],3)
 box('Fort access bridge',(0,-16,.65),(5.5,16,.5),M['stone'],3)
 for s in [-1,1]:
  box('Raised open gate post',(s*3,-11,4.4),(.45,.45,8.8),M['green'])
  # open gate leaves parallel to access bridge, readable from side
  box('Open green gate leaf',(s*3,-13.7,3.4),(.15,5.1,6.7),M.get('gate',M['green']))
  for y in range(-22,-8,2):box('Bridge rail upright',(s*2.65,y,1.5),(.12,.12,1.5),M['green'])
  for z in [1,2]:box('Bridge railing',(s*2.65,-16,z),(.12,16,.12),M['green'])
 for x in range(-22,25,9):cyl('Roof vent',(x,3,5.8),.22,1.4,M['dark'],12)
 # Small armoured dome is explicit separate readable feature.
 cyl('Armoured cupola base',(-17,6,5.4),2.3,.5,M['stone'],24);cyl('Armoured observation dome',(-17,6,6),1.6,.8,M['dark'],24,r2=.85)

def irenebrug():
 # Four 10.5m openings plus five piers, bridge span 47m.
 box('Bridge concrete deck',(0,0,3.75),(47,12,.5),M['stone'],4)
 box('Asphalt roadway',(0,0,4.03),(47,8,.1),M.get('road',M['dark']),3)
 for x in [-23.5,-11.75,0,11.75,23.5]:box('Concrete river pier',(x,0,1.6),(1.25,11,3.2),M['wall'],3)
 for y in [-5.3,5.3]:
  box('Sidewalk',(0,y,4.15),(47,1.25,.25),M['stone'],3)
  for x in range(-23,24,2):box('Blue bridge post',(x,y,4.9),(.13,.13,1.5),M['blue'])
  for z in [4.65,5.2,5.6]:box('White horizontal railing',(0,y,z),(47,.10,.10),M['cream'])
 for x in range(-22,24,4):box('Center lane stripe',(x,0,4.10),(2,.12,.015),M['cream'])
 box('Bridge keeper house',(4,7.5,5.5),(5,4,3),M.get('house',M['wall']),2)
 roof('Green keeper hip roof',4,7.5,5.7,4.7,7,1.5,M['green'])
 for x in [2.2,4,5.8]:window(x,5.44,5.8,1.3,1.4,texture=False,facing=-1)
 for xx in [-15,15]:
  for yy in [-4.6,4.6]:
   box('Barrier pedestal',(xx,yy,4.65),(.8,.8,1.2),M['cream'])
   for i in range(10):box('Raised red white barrier',(xx,yy,5.5+i*.45),(.12,.12,.45),M['red'] if i%2 else M['cream'])
   box('Traffic signal black case',(xx-1,yy,6.6),(.45,.35,1.1),M['dark'])
   for zz,col in [(6.9,'red'),(6.35,'green')]:
    o=cyl('Traffic signal lens',(xx-1,yy-.2,zz),.13,.05,M[col],16);o.rotation_euler.x=math.pi/2

BUILD={'rechthuis':rechthuis,'schanskerk':schanskerk,'fort-aan-de-drecht':fort,'irenebrug':irenebrug,'thamerkerk':thamerkerk,'de-hoeksteen':hoeksteen}

def run(slug):
 global SLUG,M,OBJ
 SLUG=slug;OBJ=[];bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 M={k:material(k,c) for k,c in {'cream':(.81,.79,.69),'stone':(.40,.39,.34),'dark':(.025,.035,.043),'glass':(.085,.17,.20),'burgundy':(.22,.025,.045),'gold':(.65,.40,.07),'red':(.65,.035,.025),'green':(.06,.15,.09),'blue':(.025,.13,.29)}.items()}
 M['glass'].node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.22
 for p in sorted((SOURCES/slug).glob('*texture.png')):
  role=p.stem.split('_')[-2];M[role]=texmat(p,role)
 M.setdefault('wall',M['stone']);M.setdefault('roof',M['dark'])
 BUILD[slug]()
 bpy.context.view_layer.update()
 # Audit welded topology per authored component. Components overlap by design.
 bad=[];deg=0;tri=0
 for o in OBJ:
  bm=bmesh.new();bm.from_mesh(o.data);bad_edges=sum(not e.is_manifold for e in bm.edges);bm.free()
  if bad_edges:bad.append({'object':o.name,'nonmanifold_edges':bad_edges})
  deg+=sum(p.area<1e-9 for p in o.data.polygons);tri+=sum(len(p.vertices)-2 for p in o.data.polygons)
 coords=[o.matrix_world@v.co for o in OBJ for v in o.data.vertices];mins=[min(v[i] for v in coords) for i in range(3)];maxs=[max(v[i] for v in coords) for i in range(3)]
 # Join by material cuts draw calls while preserving custom UVs.
 bpy.ops.object.select_all(action='DESELECT')
 for o in OBJ:o.select_set(True)
 bpy.context.view_layer.objects.active=OBJ[0];bpy.ops.object.join();model=bpy.context.object;model.name='Uithoorn_'+slug
 model['source']='User-supplied photos, reference sheet and manifest; original photographs take precedence'
 model['scale_note']='Game reconstruction; estimates except documented Hoeksteen main block. See source manifest.'
 model['front']='Godot +Z';model['landmark_id']=slug
 out=OUT/('uithoorn-'+slug+'.glb');OUT.mkdir(parents=True,exist_ok=True)
 bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_yup=True,export_materials='EXPORT',export_extras=True)
 shutil.copy2(out,SOURCES/slug/'model.glb')
 REPORT[slug]={'glb':str(out.relative_to(ROOT)),'mesh_components':len(OBJ),'triangles':tri,'nonmanifold':bad,'degenerate_faces':deg,'blender_min_xyz':mins,'blender_max_xyz':maxs,'godot_min_xyz':[mins[0],mins[2],-maxs[1]],'godot_max_xyz':[maxs[0],maxs[2],-mins[1]],'godot_size_xyz':[maxs[0]-mins[0],maxs[2]-mins[2],maxs[1]-mins[1]],'front':'Godot +Z','textures':sorted(p.name for p in (TEXTURES/slug).glob('*.png'))}
 # Standalone scene includes neutral floor, camera and broad studio light.
 center=Vector(((mins[0]+maxs[0])/2,(mins[1]+maxs[1])/2,(mins[2]+maxs[2])/2));span=max(maxs[i]-mins[i] for i in range(3))
 bpy.ops.mesh.primitive_plane_add(size=span*200,location=(0,0,-.06));floor=bpy.context.object;floor.name='Preview floor (not in GLB)';floor.data.materials.append(material('Preview floor',(.12,.15,.16)))
 bpy.ops.object.camera_add(location=center+Vector((span*.95,-span*1.25,span*.82)));cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span*1.55;bpy.context.scene.camera=cam
 bpy.ops.object.light_add(type='AREA',location=center+Vector((0,-span*.5,span)));key=bpy.context.object;key.data.energy=span*span*100;key.data.shape='DISK';key.data.size=span*.8
 bpy.ops.object.light_add(type='SUN',location=(0,0,span));sun=bpy.context.object;sun.rotation_euler=(.3,-.4,-.5);sun.data.energy=1.8
 scene=bpy.context.scene;scene.world.color=(.45,.45,.45);scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.render.resolution_x=960;scene.render.resolution_y=720;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=str(SOURCES/slug/'preview.png');scene.view_settings.view_transform='AgX'
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCES/slug/'model.blend'))
 if '--preview' in sys.argv: bpy.ops.render.render(write_still=True)
 report=OUT/'uithoorn-build-report.json';old=json.loads(report.read_text()) if report.exists() else {};old.update(REPORT);report.write_text(json.dumps(old,indent=2)+'\n')
 print('LANDMARK_COMPLETE',slug,json.dumps(REPORT[slug]),flush=True)

args=[a for a in (sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []) if not a.startswith('--')] or IDS
for slug in args:
 if not slug.startswith('--'): run(slug)
report=OUT/'uithoorn-build-report.json';old=json.loads(report.read_text()) if report.exists() else {};old.update(REPORT);report.write_text(json.dumps(old,indent=2)+'\n')
