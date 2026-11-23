"""Reproducible BoRacer character studies. Run with Blender --background --python.
All meshes, skin weights, expression shapes, animation and atlas are authored here.
Front in authoring space: -Y. Export is rotated to glTF -Z, with +Y up.
"""
import bpy, math, random, json, struct, sys, os
from mathutils import Vector, Matrix
from pathlib import Path
from array import array

BASE = Path(__file__).resolve().parents[1]
ROOT = BASE / 'persons' if (BASE / 'persons' / 'boaz').is_dir() else BASE
# Blender batch/importlib execution does not always expose this tools directory.
if str(Path(__file__).resolve().parent) not in sys.path:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
from character_hair import build_hair
import character_clothes
import character_materials

def finish_batch():
    # Optional workaround for PulseAudio hanging during Blender's final teardown.
    # Only after all explicit saves/reports succeed, and never in interactive Blender.
    if bpy.app.background and os.environ.get('BORACER_FAST_EXIT')=='1':
        sys.stdout.flush(); sys.stderr.flush(); os._exit(0)
random.seed(73)
PALETTE = [
 ('Skin','#EEC09A',.64,0),('Ear','#D98F72',.72,0),('Blush','#E7A183',.8,0),
 ('Hair','#EAAF43',.48,0),('HairLight','#F5C562',.5,0),('HairDark','#BF7A27',.6,0),
 ('White','#F5EDE0',.65,0),('Iris','#835125',.42,0),('Pupil','#211812',.35,0),
 ('Mouth','#743F35',.8,0),('Lip','#BA785B',.7,0),('Blue','#0868B8',.85,0),
 ('BlueDark','#174471',.9,0),('Red','#C82435',.86,0),('Gold','#E8AD46',.32,.72),
 ('Steel','#718592',.34,.8),('DarkSteel','#344653',.45,.7),('Leather','#6D422B',.78,0),
 ('Tan','#B77941',.76,0),('Sole','#D5A445',.85,0),('Green','#176B42',.85,0),
 ('Olive','#648B41',.9,0),('Orange','#D77A31',.83,0),('Denim','#185C92',.94,0),
 ('DenimLight','#3475A4',.92,0),('Glove','#303630',.78,0),('Stitch','#CDAE68',.85,0),
 ('Feather','#E85327',.8,0),('Leaf','#35854B',.83,0),('Highlight','#FFFFFF',.25,0),
 ('EyeWhite','#EEE6D7',.21,0),('EyeIris','#78491F',.24,0),
]
COLORS={name:i for i,(name,*_) in enumerate(PALETTE)}
parts=[]; bones={}; FACE={}

# Character-specific anatomy: shared sculpting helper, distinct facial landmarks.
ANATOMY = {
    'boaz': dict(head_size=1.12, head_width=1.025, eye_width=.025,
                 eye_height=.021, eye_depth=.011, cheek_volume=.012,
                 mouth_width=.050, torso_length=.94, leg_length=.94),
    'ravi': dict(head_size=1.10, head_width=1.0, eye_width=.0255,
                 eye_height=.0225, eye_depth=.0105, cheek_volume=.010,
                 mouth_width=.047, torso_length=.95, leg_length=.93,
                 eye_spacing=.049, eye_level=.979, nose_width=.014,
                 smile_depth=.015, smile_level=.910),
}

def anatomy_point(p, profile):
    """Continuous piecewise rest-space map shared by mesh, morphs and bones.

    Shoes keep their original proportions; torso/legs shorten together, and all
    head-attached geometry follows the same neck pivot without a hair redesign.
    """
    p=p.copy(); z=p.z
    leg=profile['leg_length']; torso=profile['torso_length']
    if z<=.10: pass
    elif z<=.47: p.z=.10+(z-.10)*leg
    elif z<=.79: p.z=.10+.37*leg+(z-.47)*torso
    else:
        p.z=.10+.37*leg+.32*torso+(z-.79)*profile['head_size']
        p.x*=profile['head_width']; p.y*=profile['head_width']
    return p

def apply_anatomy(ob, rig, profile):
    # Apply the identical mapping to every morph target and the rest skeleton.
    for key in ob.data.shape_keys.key_blocks:
        for v in key.data: v.co=anatomy_point(v.co,profile)
    bpy.context.view_layer.objects.active=rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for bone in rig.data.edit_bones:
        bone.head=anatomy_point(bone.head,profile)
        bone.tail=anatomy_point(bone.tail,profile)
    bpy.ops.object.mode_set(mode='OBJECT'); rig.select_set(False)


def srgb(v): return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4

def atlas(name):
    size=2048; al,orm=character_materials.textures(PALETTE,size)
    ims=[]
    for suffix,pix in [('basecolor',al),('orm',orm)]:
        im=bpy.data.images.new(name+'_'+suffix,size,size,alpha=True)
        im.colorspace_settings.name='sRGB' if suffix=='basecolor' else 'Non-Color'
        im.pixels.foreach_set(pix.ravel()); im.update()
        im.filepath_raw=str(ROOT/name/(name+'_'+suffix+'.png')); im.file_format='PNG'; im.save(); im.pack(); ims.append(im)
    mat=bpy.data.materials.new(name+'_Atlas_PBR'); mat.use_nodes=True
    n=mat.node_tree.nodes; l=mat.node_tree.links; p=n.get('Principled BSDF')
    tex=n.new('ShaderNodeTexImage'); tex.image=ims[0]; tex.label='2048px PBR atlas with dedicated head UV region'
    tex2=n.new('ShaderNodeTexImage'); tex2.image=ims[1]
    sep=n.new('ShaderNodeSeparateColor'); l.new(tex.outputs['Color'],p.inputs['Base Color'])
    l.new(tex2.outputs['Color'],sep.inputs['Color']); l.new(sep.outputs['Green'],p.inputs['Roughness']); l.new(sep.outputs['Blue'],p.inputs['Metallic'])
    return mat

def mesh(name,verts,faces,color,bone='spine',weights=None,tag=None):
    if name.startswith('Eye_white_'): color='EyeWhite'
    elif name.startswith('Iris_'): color='EyeIris'
    m=bpy.data.meshes.new(name); m.from_pydata(verts,[],faces); m.update()
    ob=bpy.data.objects.new(name,m); bpy.context.collection.objects.link(ob); parts.append(ob)
    ob.data.materials.append(MAT)
    for f in m.polygons: f.use_smooth=True
    uv=m.uv_layers.new(name='PaletteUV'); k=COLORS[color]; cx=k%8; cy=k//8
    lo=Vector((min(v[0] for v in verts),min(v[1] for v in verts),min(v[2] for v in verts)))
    hi=Vector((max(v[0] for v in verts),max(v[1] for v in verts),max(v[2] for v in verts)))
    for f in m.polygons:
        if name=='Body_Head_sculpted':
            for li,coord in zip(f.loop_indices,character_materials.head_uv(verts,f.vertices)):
                uv.data[li].uv=coord
            continue
        axes=(0,2) if abs(f.normal.y)>.5 else ((1,2) if abs(f.normal.x)>.5 else (0,1))
        for li in f.loop_indices:
            v=Vector(verts[m.loops[li].vertex_index]); a,b=axes
            u=(v[a]-lo[a])/max(.0001,hi[a]-lo[a]); w=(v[b]-lo[b])/max(.0001,hi[b]-lo[b])
            uv.data[li].uv=((cx+.06+.88*u)/8,(cy+.06+.88*w)/8)
    for i in range(len(verts)):
        ws=weights[i] if weights else {bone:1}
        for bn,w in ws.items():
            if w>0:
                vg=ob.vertex_groups.get(bn) or ob.vertex_groups.new(name=bn); vg.add([i],w,'REPLACE')
    if tag:
        vg=ob.vertex_groups.new(name='face_'+tag); vg.add(list(range(len(verts))),1,'REPLACE')
    return ob

def ell(name,c,s,col,bone='spine',seg=16,rings=10,tag=None):
    vs=[]
    for j in range(rings+1):
        t=math.pi*j/rings
        for i in range(seg):
            a=2*math.pi*i/seg
            vs.append((c[0]+s[0]*math.sin(t)*math.cos(a),c[1]+s[1]*math.sin(t)*math.sin(a),c[2]+s[2]*math.cos(t)))
    fs=[(j*seg+i,j*seg+(i+1)%seg,(j+1)*seg+(i+1)%seg,(j+1)*seg+i) for j in range(rings) for i in range(seg)]
    return mesh(name,vs,fs,col,bone,tag=tag)

def tube(name,points,radii,col,bone='spine',sides=8,weights=None,flat=1):
    vs=[]; ws=[]
    for j,p in enumerate(points):
        p=Vector(p); tangent=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(0,j-1)])
        if tangent.length<1e-6: tangent=Vector((0,0,1))
        tangent.normalize(); ref=Vector((0,1,0))
        if abs(tangent.dot(ref))>.95: ref=Vector((1,0,0))
        u=tangent.cross(ref).normalized(); v=tangent.cross(u).normalized()
        r=radii[j] if isinstance(radii,(tuple,list)) else radii
        for i in range(sides):
            a=2*math.pi*i/sides; vs.append(tuple(p+r*(u*math.cos(a)+v*math.sin(a)*flat)))
            if weights: ws.append(weights[j])
    fs=[tuple(range(sides-1,-1,-1))]
    fs += [(j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i) for j in range(len(points)-1) for i in range(sides)]
    fs.append(tuple((len(points)-1)*sides+i for i in range(sides)))
    return mesh(name,vs,fs,col,bone,ws if weights else None)

def curve(name,pts,r,col,bone='spine',sides=6): return tube(name,pts,r,col,bone,sides)

def box(name,c,s,col,bone='spine',bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1,location=c); ob=bpy.context.object; ob.name=name
    ob.dimensions=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=ob.modifiers.new('Soft tailored edges','BEVEL'); mod.width=bevel; mod.segments=3
    bpy.ops.object.modifier_apply(modifier=mod.name)
    verts=[tuple(ob.matrix_world@v.co) for v in ob.data.vertices]; faces=[tuple(p.vertices) for p in ob.data.polygons]
    bpy.data.objects.remove(ob,do_unlink=True)
    return mesh(name,verts,faces,col,bone)

def ringbody(name,sections,col,bone='spine',n=24,weights=None):
    vs=[]; ws=[]
    for j,(z,rx,ry,y) in enumerate(sections):
        for i in range(n):
            a=2*math.pi*i/n; vs.append((rx*math.cos(a),y+ry*math.sin(a),z))
            if weights: ws.append(weights[j])
    fs=[tuple(range(n-1,-1,-1))]+[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(len(sections)-1) for i in range(n)]+[tuple((len(sections)-1)*n+i for i in range(n))]
    return mesh(name,vs,fs,col,bone,ws if weights else None)

def leaf(name,start,end,width,col,bone='head'):
    a,b=Vector(start),Vector(end); d=b-a; side=d.cross(Vector((0,1,0))).normalized()*width
    vs=[]
    for i in range(7):
        t=i/6; c=a+d*t; c.y-=math.sin(math.pi*t)*.007; w=math.sin(math.pi*t)**.8
        vs.extend([tuple(c-side*w),tuple(c+Vector((0,-.005,0))),tuple(c+side*w)])
    fs=[]
    for i in range(6):
        for j in range(2): fs.append((i*3+j,i*3+j+1,(i+1)*3+j+1,(i+1)*3+j))
    ob=mesh(name,vs,fs,col,bone)
    bpy.context.view_layer.objects.active=ob; ob.select_set(True)
    mod=ob.modifiers.new('Leaf thickness','SOLIDIFY'); mod.thickness=.0015; bpy.ops.object.modifier_apply(modifier=mod.name); ob.select_set(False)
    curve(name+'_vein',[tuple(a),tuple(a+d*.5+Vector((0,-.009,0))),tuple(b)],.0013,'Stitch',bone)

def clothes_api():
    return dict(mesh=mesh,ell=ell,curve=curve,tube=tube,box=box,ringbody=ringbody,parts=parts,solidify=solidify)

def solidify(ob, thickness):
    bpy.context.view_layer.objects.active=ob; ob.select_set(True)
    mod=ob.modifiers.new('Tailored material thickness','SOLIDIFY'); mod.thickness=thickness
    bpy.ops.object.modifier_apply(modifier=mod.name); ob.select_set(False)

def lion(name,center,scale,back=False,bone='spine'):
    return character_clothes.lion(clothes_api(),name,center,scale,back,bone)

def clover(name,c,size,bone='spine',back=False):
    for dx,dz in [(-1,1),(1,1),(-1,-1),(1,-1)]:
        ell(name,(c[0]+dx*size*.36,c[1],c[2]+dz*size*.36),(size*.43,.0025,size*.43),'Green',bone,12,8)
    curve(name+'_stem',[(c[0],c[1],c[2]),(c[0]+size*.25,c[1],c[2]-size*1.1)],.002,'Green',bone)

def back_hair():
    # A fitted rear hair shell and overlapping nape locks cover the whole cranium.
    vs=[]; rows=[(.924,.073,.067),(.945,.111,.088),(.980,.128,.102),(1.024,.126,.103),(1.065,.106,.090),(1.096,.068,.058),(1.111,.015,.015)]
    for z,rx,ry in rows:
        for i in range(19):
            a=math.pi*i/18; vs.append((rx*math.cos(a),.010+ry*math.sin(a),z))
    mesh('Hair_rear_shell',vs,[(j*19+i,j*19+i+1,(j+1)*19+i+1,(j+1)*19+i) for j in range(len(rows)-1) for i in range(18)],'HairDark','head')
    for row,z in enumerate([1.069,1.027,.986]):
        for i in range(12):
            a=.02+math.pi*(i+.2*(row%2))/11.6
            rx=[.110,.124,.123][row]; ry=[.092,.103,.100][row]
            start=Vector((rx*.94*math.cos(a),.012+ry*.94*math.sin(a),z+.015))
            mid=Vector((rx*1.04*math.cos(a+.06),.012+ry*1.09*math.sin(a+.06),z-.010))
            end=Vector((rx*.96*math.cos(a+.11),.012+ry*1.04*math.sin(a+.11),z-.049))
            tube('Hair_nape_lock',[tuple(start),tuple(start.lerp(mid,.5)),tuple(mid),tuple(mid.lerp(end,.6)),tuple(end)],[.010,.018,.018,.012,.0007],'HairLight' if i%4==0 else 'Hair','head',8,flat=.62)
    for i in range(8):
        x=-.084+i*.023
        tube('Hair_crown_sweep',[(x-.015,.005,1.089),(x,.023,1.106),(x+.015,.049,1.099),(x+.021,.070,1.073)],[.010,.015,.014,.0007],'HairLight' if i%3==0 else 'Hair','head',8,flat=.6)

def original_face(ravi):
    # Shaped chin, broad soft cheeks and a cranium; not a spherical placeholder.
    ringbody('Body_Head',[(.838,.032,.035,0),(.849,.066,.059,-.004),(.873,.102,.079,-.003),(.905,.123,.091,0),(.947,.132 if not ravi else .127,.097,.001),(.988,.125,.100,.004),(1.031,.116,.096,.008),(1.067,.087,.077,.01),(1.083,.03,.03,.012)],'Skin','head',32)
    ell('Neck',(0,0,.828),(.038,.038,.046),'Skin','neck')
    for s in [-1,1]:
        suffix='L' if s>0 else 'R'
        ell('Ear_'+suffix,(s*.126,.004,.946),(.024,.018,.036),'Skin','head',16,10)
        ell('Ear_inner_'+suffix,(s*.138,-.011,.947),(.010,.004,.022),'Ear','head',12,8)
        x=s*.052; z=.976 if not ravi else .981
        ell('Eye_socket_'+suffix,(x,-.086,z),(.037,.015,.041),'Lip','head',20,12)
        ell('Eye_white_'+suffix,(x,-.094,z),(.032,.015,.036),'White','head',20,12,tag='eye_'+suffix)
        ell('Iris_'+suffix,(x-s*.002,-.108,z),(.018,.005,.023),'Iris','head',20,10,tag='eye_'+suffix)
        ell('Pupil_'+suffix,(x-s*.002,-.112,z),(.010,.0028,.015),'Pupil','head',16,10,tag='eye_'+suffix)
        ell('Eye_glint_'+suffix,(x-.006,-.115,z+.009),(.005,.0015,.006),'Highlight','head',10,8,tag='eye_'+suffix)
        ell('Eye_glint_small_'+suffix,(x+.007,-.114,z-.007),(.0023,.001,.0026),'Highlight','head',8,6,tag='eye_'+suffix)
        pts=[(x+.033*math.cos(a),-.105+.006*math.sin(a),z+.037*math.sin(a)) for a in [math.pi*i/12 for i in range(13)]]
        ob=curve('Upper_lid_'+suffix,pts,.0025,'HairDark','head'); vg=ob.vertex_groups.new(name='face_lid_'+suffix); vg.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        brow=[(x+s*t,-.091,.1+z+.006*math.sin((t+.028)/.056*math.pi)) for t in [-.028,-.014,0,.014,.028]]
        # Brows below fringe, just above eyelids.
        brow=[(a,b,c-.046) for a,b,c in brow]
        ob=curve('Brow_'+suffix,brow,[.003,.005,.0055,.004,.002],'HairDark','head',8)
        vg=ob.vertex_groups.new(name='face_brow_'+suffix); vg.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        ell('Rosy_cheek_'+suffix,(s*.083,-.083,.928),(.025,.004,.011),'Blush','head',16,8)
    ell('Nose_bridge',(0,-.093,.955),(.014,.014,.024),'Skin','head',16,10)
    ell('Nose_tip',(0,-.110,.947),(.019,.017,.012),'Skin','head',16,10)
    for s in [-1,1]: ell('Nostril',(s*.009,-.122,.942),(.003,.0016,.0017),'Lip','head',8,6)
    # Inset smile surface, bounded by a soft lower lip and a single inset tooth strip.
    verts=[]
    for i in range(17):
        x=-.043+.086*i/16; t=x/.043; top=.911+.012*t*t; bottom=top-.013*(1-t*t)
        verts.extend([(x,-.092+.016*abs(t)**2,top),(x,-.092+.016*abs(t)**2,bottom)])
    mesh('Smile_inset',verts,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(16)],'Mouth','head',tag='mouth')
    curve('Lower_lip',[(x,-.093+.016*(x/.043)**2,.898+.025*(x/.043)**2) for x in [-.043,-.032,-.021,0,.021,.032,.043]],.0025,'Lip','head')
    verts=[]
    for i in range(13):
        x=-.036+.072*i/12; t=x/.043; z=.911+.012*t*t
        verts.extend([(x,-.093+.016*t*t,z-.001),(x,-.093+.016*t*t,z-.005)])
    mesh('Upper_teeth',verts,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(12)],'White','head',tag='mouth')


def child_face(profile):
    """Continuous latitudinal head with sculpted cheeks, muzzle and eye sockets.

    Unlike separate cheek ellipsoids, the entire facial silhouette and soft
    socket transitions are part of one surface. Dense rings cover the eyes and
    mouth, with a rounded closed chin and crown.
    """
    sections=[(.831,.012,.020,.001),(.838,.039,.042,-.001),
              (.850,.068,.059,-.003),(.864,.089,.071,-.002),
              (.881,.108,.082,-.001),(.900,.123,.089,0),
              (.920,.133,.095,.001),(.940,.135,.098,.002),
              (.960,.132,.099,.003),(.980,.126,.100,.004),
              (1.000,.122,.100,.006),(1.022,.115,.096,.008),
              (1.044,.103,.089,.009),(1.062,.084,.075,.010),
              (1.077,.055,.051,.011),(1.085,.009,.010,.012)]
    # Smooth cubic interpolation adds contour rings without faceting the chin.
    def interp(k,t,index):
        a=sections[max(0,k-1)][index]; b=sections[k][index]
        c=sections[k+1][index]; d=sections[min(len(sections)-1,k+2)][index]
        return .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
    rows=[]
    for k in range(len(sections)-1):
        for j in range(3): rows.append(tuple(interp(k,j/3,i) for i in range(4)))
    rows.append(sections[-1]); n=64; vs=[]
    def gauss(x,z,cx,cz,sx,sz):
        return math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
    for z,rx,ry,cy in rows:
        for i in range(n):
            a=2*math.pi*i/n; x=rx*math.cos(a); y=cy+ry*math.sin(a)
            if math.sin(a)<0:
                front=(-math.sin(a))**6
                cheeks=sum(gauss(x,z,sign*.076,.925,.046,.033) for sign in [-1,1])
                sockets=sum(gauss(x,z,sign*.050,.978,.031,.030) for sign in [-1,1])
                muzzle=gauss(x,z,0,.908,.060,.029)
                y+=front*(-profile['cheek_volume']*cheeks+.006*sockets-.004*muzzle)
            vs.append((x,y,z))
    fs=[tuple(range(n-1,-1,-1))]
    fs.extend((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i)
              for j in range(len(rows)-1) for i in range(n))
    fs.append(tuple((len(rows)-1)*n+i for i in range(n)))
    mesh('Body_Head_sculpted',vs,fs,'Skin','head')
    ell('Neck',(0,0,.823),(.037,.037,.043),'Skin','neck')
    for sign in [-1,1]:
        side='L' if sign>0 else 'R'; x=sign*profile.get('eye_spacing',.050); z=profile.get('eye_level',.976)
        ell('Ear_'+side,(sign*.128,.004,.944),(.023,.018,.032),'Skin','head',20,12)
        ell('Ear_inner_'+side,(sign*.139,-.009,.945),(.009,.004,.019),'Ear','head',16,10)
        # Whites sit inside the facial contour. No separate coloured socket ring.
        ell('Eye_white_'+side,(x,-.086,z),(profile['eye_width'],profile['eye_depth'],profile['eye_height']),'White','head',24,16,tag='eye_'+side)
        ell('Iris_'+side,(x-sign*.001,-.096,z),(.013,.0038,.014),'Iris','head',24,14,tag='eye_'+side)
        ell('Pupil_'+side,(x-sign*.001,-.099,z),(.007,.002,.009),'Pupil','head',20,12,tag='eye_'+side)
        ell('Eye_glint_'+side,(x-.004,-.101,z+.007),(.003,.001,.0038),'Highlight','head',12,8,tag='eye_'+side)
        ell('Eye_glint_small_'+side,(x+.005,-.100,z-.006),(.0014,.0008,.0016),'Highlight','head',8,6,tag='eye_'+side)
        for upper in [True,False]:
            pts=[]
            for i in range(21):
                a=math.pi*i/20+(0 if upper else math.pi)
                pts.append((x+profile['eye_width']*math.cos(a),-.087-.008*math.sin(a)**2,z+profile['eye_height']*math.sin(a)))
            lid=curve(('Upper_lid_' if upper else 'Lower_lid_')+side,pts,.0019 if upper else .0015,'Skin','head',8)
            vg=lid.vertex_groups.new(name='face_lid_'+side); vg.add(list(range(len(lid.data.vertices))),1,'REPLACE')
        # Fine warm upper lash line gives a readable lid without a pink eye rim.
        curve('Upper_lash_'+side,[(x+.024*math.cos(a),-.088-.008*math.sin(a)**2,z+(profile['eye_height']-.001)*math.sin(a)) for a in [math.pi*i/20 for i in range(21)]],.0009,'HairDark','head',6)
        brow=curve('Brow_'+side,[(x+t,-.087,.1+z-.067+.006*math.sin((t+.024)/.048*math.pi)) for t in [-.024,-.012,0,.012,.024]],[.002,.0038,.004,.003,.0015],'HairDark','head',8)
        vg=brow.vertex_groups.new(name='face_brow_'+side); vg.add(list(range(len(brow.data.vertices))),1,'REPLACE')
    # Small bridge and softly embedded tip replace the previous protruding ball.
    ell('Nose_bridge',(0,-.096,.956),(.010,.009,.017),'Skin','head',20,12)
    ell('Nose_tip',(0,-.105,.946),(profile.get('nose_width',.015),.011,.009),'Skin','head',24,14)
    for sign in [-1,1]: ell('Nostril',(sign*.007,-.114,.942),(.002,.0012,.0012),'Lip','head',10,8)
    width=profile['mouth_width']; vs=[]
    # Broad shallow smile follows the rounded muzzle instead of a tiny sticker.
    def face_surface_y(x,z):
        # Lay the mouth on the actual cheek/muzzle contour. A flat smile plane
        # sinks into the cheeks and makes a broad grin look like a tiny slit.
        a,b=next((a,b) for a,b in zip(rows,rows[1:]) if a[0]<=z<=b[0])
        f=(z-a[0])/(b[0]-a[0]); rx,ry,cy=[a[k]+f*(b[k]-a[k]) for k in [1,2,3]]
        front=math.sqrt(max(0,1-(x/rx)**2))
        cheeks=sum(gauss(x,z,sign*.076,.925,.046,.033) for sign in [-1,1])
        sockets=sum(gauss(x,z,sign*.050,.978,.031,.030) for sign in [-1,1])
        muzzle=gauss(x,z,0,.908,.060,.029)
        return cy-ry*front+front**6*(-profile['cheek_volume']*cheeks+.006*sockets-.004*muzzle)
    def smilepoint(t,lower=False):
        x=width*t; z=profile.get('smile_level',.909)+.013*t*t-(profile.get('smile_depth',.017)*(1-t*t) if lower else 0)
        return (x,face_surface_y(x,z)-.0015,z)
    for i in range(33):
        t=-1+2*i/32; vs.extend([smilepoint(t),smilepoint(t,True)])
    mesh('Smile_inset',vs,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(32)],'Mouth','head',tag='mouth')
    curve('Lower_lip',[smilepoint(-1+2*i/24,True) for i in range(25)],.0017,'Lip','head',8)
    # Individual rounded tooth surfaces, including the child's front-tooth gap.
    # These are geometry inside the grin, not a texture or costume alteration.
    for left,right in [(-.77,-.52),(-.49,-.27),(-.24,-.045),(.055,.26),(.29,.50),(.53,.77)]:
        tv=[]
        for i in range(5):
            t=left+(right-left)*i/4; x,y,z=smilepoint(t)
            tv.extend([(x,y-.001,z-.001),(x,y-.0015,z-.006+abs(t)*.0015)])
        mesh('Upper_tooth',tv,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(4)],'White','head',tag='mouth')

def make_head(ravi):
    child_face(ANATOMY['ravi' if ravi else 'boaz'])
    build_hair('ravi' if ravi else 'boaz', mesh)

def build_skeleton():
    arm=bpy.data.armatures.new('BoRacer_Humanoid'); rig=bpy.data.objects.new('CharacterRig',arm); bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig; rig.select_set(True); bpy.ops.object.mode_set(mode='EDIT')
    def bone(n,a,b,parent=None):
        eb=arm.edit_bones.new(n); eb.head=a; eb.tail=b
        if parent: eb.parent=arm.edit_bones[parent]
        bones[n]=(Vector(a),Vector(b)); return eb
    bone('root',(0,0,0),(0,0,.12)); bone('hips',(0,0,.44),(0,0,.56),'root')
    bone('spine',(0,0,.56),(0,0,.69),'hips'); bone('chest',(0,0,.69),(0,0,.79),'spine')
    bone('neck',(0,0,.79),(0,0,.85),'chest'); bone('head',(0,0,.85),(0,0,1.07),'neck')
    for s,side in [(1,'L'),(-1,'R')]:
        bone('clavicle.'+side,(0,0,.765),(s*.126,0,.755),'chest')
        bone('upper_arm.'+side,(s*.126,0,.755),(s*.207,0,.635),'clavicle.'+side)
        bone('forearm.'+side,(s*.207,0,.635),(s*.272,-.008,.527),'upper_arm.'+side)
        bone('hand.'+side,(s*.272,-.008,.527),(s*.298,-.01,.482),'forearm.'+side)
        for f in range(5):
            x=s*(.284+(f-1.5)*.010); z=.488-abs(f-2)*.002
            bone('finger%d.01.%s'%(f,side),(x,-.013,z),(x+s*.009,-.013,z-.021),'hand.'+side)
            bone('finger%d.02.%s'%(f,side),(x+s*.009,-.013,z-.021),(x+s*.015,-.01,z-.038),'finger%d.01.%s'%(f,side))
        bone('thigh.'+side,(s*.066,0,.47),(s*.078,0,.275),'hips')
        bone('shin.'+side,(s*.078,0,.275),(s*.082,0,.10),'thigh.'+side)
        bone('foot.'+side,(s*.082,0,.10),(s*.082,-.091,.052),'shin.'+side)
        bone('toe.'+side,(s*.082,-.091,.052),(s*.082,-.132,.052),'foot.'+side)
    for col in [-1,0,1]:
        for j in range(3):
            bone('cape_%d_%d'%(col,j),(col*.075,.069+j*.013,.77-j*.14),(col*.095,.082+j*.013,.63-j*.14),'chest' if j==0 else 'cape_%d_%d'%(col,j-1))
    bpy.ops.object.mode_set(mode='OBJECT'); rig.select_set(False); rig.show_in_front=True
    return rig

def limbs(ravi):
    for s,side in [(1,'L'),(-1,'R')]:
        ua='upper_arm.'+side; fa='forearm.'+side; hand='hand.'+side; thigh='thigh.'+side; shin='shin.'+side; foot='foot.'+side
        pts=[(s*.125,0,.753),(s*.15,0,.717),(s*.186,0,.667),(s*.207,0,.635),(s*.228,-.003,.600),(s*.252,-.006,.56),(s*.273,-.008,.524)]
        ws=[{ua:1},{ua:1},{ua:.85,fa:.15},{ua:.5,fa:.5},{ua:.15,fa:.85},{fa:1},{fa:.8,hand:.2}]
        tube('Arm_'+side,pts,[.039,.039,.034,.030,.030,.026,.022],'Skin',ua,12,ws)
        tube('Sleeve_'+side,pts[:4],[.047,.048,.043,.037],'White' if ravi else 'Blue',ua,12,ws[:4])
        if ravi:
            ell('Shirt_rounded_shoulder_seam_'+side,(s*.124,0,.748),(.052,.049,.044),'White',ua,20,10)
            tube('Rolled_sleeve_'+side,[pts[2],pts[3]],[.044,.039],'White',ua,12,[{ua:.85,fa:.15},{ua:.5,fa:.5}])
        else:
            character_clothes.shoulder(clothes_api(),s,side,ua)
            character_clothes.bracer(clothes_api(),s,side,pts,fa)
        ell('Palm_'+side,(s*.286,-.01,.501),(.026,.020,.035),'Skin',hand,12,8)
        if ravi:
            ell('FingerlessGlove_'+side,(s*.283,-.009,.509),(.028,.022,.029),'Glove',hand,12,8)
            box('Glove_patch_'+side,(s*.283,-.031,.512),(.035,.007,.022),'Leather',hand,.006)
        for f in range(4):
            x=s*(.284+(f-1.5)*.010); z=.488-abs(f-2)*.002
            tube('Finger_%d_%s'%(f,side),[(x,-.013,z),(x+s*.009,-.013,z-.021),(x+s*.015,-.01,z-.034)], [.0065,.006,.004],'Skin',sides=8,weights=[{'finger%d.01.%s'%(f,side):1},{'finger%d.01.%s'%(f,side):.5,'finger%d.02.%s'%(f,side):.5},{'finger%d.02.%s'%(f,side):1}])
        tube('Thumb_'+side,[(s*.268,-.024,.505),(s*.261,-.032,.488),(s*.262,-.034,.474)],[.009,.007,.0045],'Skin','finger4.01.'+side,8)
        pts=[(s*.064,0,.49),(s*.068,0,.43),(s*.072,0,.35),(s*.078,0,.285),(s*.079,0,.265),(s*.081,0,.20),(s*.082,0,.13),(s*.082,0,.10)]
        ws=[{thigh:1},{thigh:1},{thigh:1},{thigh:.65,shin:.35},{thigh:.35,shin:.65},{shin:1},{shin:1},{shin:.8,foot:.2}]
        tube('Jeans_'+side if ravi else 'Leg_'+side,pts,[.056,.057,.049,.043,.041,.036,.032,.026],'Denim' if ravi else 'BlueDark',thigh,14,ws)
        if ravi:
            tube('Jeans_cuff_'+side,[(s*.082,0,.151),(s*.082,0,.122)],[.036,.036],'DenimLight',shin,14)
            tube('Ankle_'+side,[(s*.082,0,.122),(s*.082,0,.082)],[.024,.024],'Skin',shin,12)
            seam_pts=[(s*.116,-.018,.43),(s*.119,-.022,.35),(s*.115,-.020,.28),(s*.112,-.016,.17)]
            tube('Denim_articulated_seam_'+side,seam_pts,.0012,'Stitch',thigh,6,weights=[{thigh:1},{thigh:1},{thigh:.5,shin:.5},{shin:1}])
            curve('Pocket_seam_'+side,[(s*.06,-.051,.446),(s*.068,-.053,.417),(s*.092,-.045,.413)],.0014,'Stitch',thigh)
        else:
            character_clothes.knee(clothes_api(),s,side,shin)
        character_clothes.shoes(clothes_api(),ravi,s,side,foot,shin)

def outfit(ravi):
    ringbody('Shirt' if ravi else 'Tunic',[(.495 if ravi else .46,.100,.066,0),(.51,.091,.062,0),(.57,.090,.063,0),(.64,.108,.069,0),(.72,.121,.071,.003),(.77,.106,.063,.004),(.797,.047,.036,0)],'White' if ravi else 'Blue','spine',24,weights=[{'hips':1},{'hips':.6,'spine':.4},{'spine':1},{'spine':.6,'chest':.4},{'chest':1},{'chest':1},{'chest':1}])
    ringbody('Belt',[(.496,.101,.069,0),(.531,.098,.069,0)],'Leather','hips',32)
    box('Belt_buckle',(0,-.073,.515),(.043,.012,.034),'Gold','hips',.004)
    box('Buckle_inset',(0,-.081,.515),(.027,.004,.019),'Leather','hips',.002)
    curve('Buckle_prong',[(-.008,-.085,.515),(.012,-.085,.515)],.002,'Gold','hips')
    for s in [-1,1]:
        for x in [.041,.073]: box('Belt_loop',(s*x,-.065,.516),(.011,.011,.040),'Tan','hips',.002)
        box('Utility_pouch',(s*.108,-.004,.487),(.046,.055,.081),'Tan','hips',.009)
        box('Pouch_flap',(s*.108,-.035,.509),(.048,.012,.029),'Leather' if not ravi else 'Orange','hips',.006)
        ell('Pouch_stud',(s*.108,-.043,.505),(.004,.002,.004),'Gold','hips',8,6)
    if ravi:
        # Open vest panels wrap around the shirt instead of a solid green torso.
        for s in [-1,1]:
            vs=[]
            for z,w,ry in [(.538,.088,.067),(.59,.094,.071),(.68,.113,.076),(.745,.116,.075),(.778,.085,.060)]:
                for i in range(9):
                    a=-math.pi/2+.16+(math.pi+.25)*i/8
                    vs.append((s*w*math.cos(a),ry*math.sin(a),z))
            ob=mesh('ExplorerVest',vs,[(j*9+i,j*9+i+1,(j+1)*9+i+1,(j+1)*9+i) for j in range(4) for i in range(8)],'Olive','chest')
            bpy.context.view_layer.objects.active=ob; ob.select_set(True)
            mod=ob.modifiers.new('Vest cloth thickness','SOLIDIFY'); mod.thickness=.004; bpy.ops.object.modifier_apply(modifier=mod.name); ob.select_set(False)
            curve('Vest_orange_piping',[(s*.014,-.068,.553),(s*.018,-.074,.625),(s*.019,-.077,.71),(s*.014,-.059,.773)],.0023,'Orange','chest')
            for z,x in [(.591,.062),(.705,.066)]:
                box('Vest_pocket',(s*x,-.068,z),(.053,.020,.044),'Green','chest',.006)
                box('Pocket_flap',(s*x,-.081,z+.015),(.053,.009,.017),'Olive','chest',.004)
                ell('Pocket_button',(s*x,-.088,z+.013),(.003,.002,.003),'Gold','chest',8,6)
            leaf('Vest_leaf_badge',(s*.070,-.083,.631),(s*.055,-.084,.668),.011,'Sole','chest')
            # Continuous backpack shoulder straps run over the shoulder to the pack.
            curve('Backpack_strap',[(s*.079,.079,.574),(s*.094,.079,.719),(s*.091,.031,.789),(s*.085,-.029,.786),(s*.079,-.073,.745),(s*.075,-.081,.671),(s*.074,-.075,.584),(s*.079,.079,.574)],.010,'Tan','chest',8)
            box('Strap_buckle',(s*.079,-.087,.731),(.026,.009,.035),'Gold','chest',.003)
            box('Strap_buckle_hole',(s*.079,-.093,.731),(.014,.003,.022),'Leather','chest',.002)
        box('Backpack',(0,.106,.660),(.175,.091,.218),'Orange','chest',.024)
        box('Pack_main_panel',(0,.158,.646),(.133,.020,.149),'Tan','chest',.012)
        box('Pack_top_flap',(0,.159,.735),(.158,.026,.050),'Green','chest',.012)
        clover('Pack_clover',(0,.172,.648),.033,'chest',True)
        for s in [-1,1]:
            box('Pack_side_pocket',(s*.094,.107,.627),(.030,.068,.083),'Green','chest',.010)
            box('Pack_vertical_strap',(s*.054,.174,.66),(.012,.010,.179),'Leather','chest',.003)
            for z in [.73,.594]: box('Pack_strap_fastener',(s*.054,.181,z),(.020,.008,.017),'Gold','chest',.002)
        curve('Pack_handle',[(-.035,.112,.771),(-.030,.112,.800),(0,.112,.806),(.030,.112,.800),(.035,.112,.771)],.005,'Leather','chest')
        character_clothes.ravi_details(clothes_api())
        # Small rocket patch on the side panel, while retaining the main clover.
        leaf('Rocket_patch',(.095,.143,.683),(.095,.145,.719),.008,'White','chest')
        ringbody('Headband',[(1.006,.127,.103,.009),(1.038,.124,.102,.009)],'Green','head',40)
        curve('Headband_top_seam',[(.126*math.cos(a),.009+.103*math.sin(a),1.036) for a in [2*math.pi*i/40 for i in range(41)]],.0013,'Olive','head')
        leaf('Red_orange_feather',(.106,-.009,1.045),(.154,.001,1.182),.022,'Feather')
        leaf('Green_leaf_A',(.111,-.014,1.050),(.183,-.018,1.095),.020,'Green')
        leaf('Green_leaf_B',(.109,-.023,1.045),(.164,-.034,1.060),.018,'Leaf')
        ell('Headband_pin',(.118,-.060,1.033),(.012,.005,.012),'Sole','head',12,8)
        ell('Headband_knot',(0,.111,1.023),(.021,.012,.019),'Green','head')
        leaf('Band_tail_A',(0,.112,1.019),(-.041,.125,.951),.019,'Green')
        leaf('Band_tail_B',(0,.112,1.019),(.034,.130,.958),.017,'Green')
    else:
        ringbody('Red_collar',[(.776,.060,.041,0),(.803,.049,.038,0)],'Red','chest',28)
        curve('Collar_gold_piping',[(-.057,-.030,.792),(-.025,-.043,.783),(0,-.045,.780),(.025,-.043,.783),(.057,-.030,.792)],.002,'Gold','chest')
        mark_start=len(parts)
        lion('Chest_lion',(0,-.073,.667),.126,bone='chest')
        for mark in parts[mark_start:]:
            for v in mark.data.vertices:
                # Conform the relief to the curved blue cloth, with a shallow real thickness.
                depth=max(0,min(.004,-v.co.y-.073))
                v.co.y=-.070*math.sqrt(max(.05,1-(v.co.x/.113)**2))-.002-depth*.3
        character_clothes.tunic_panels(clothes_api())
        for s in [-1,1]:
            ell('Cape_clasp',(s*.086,-.035,.772),(.014,.007,.014),'Gold','chest',12,8)
        character_clothes.cape(clothes_api())

def face_shapes(ob,ravi):
    ob.shape_key_add(name='Basis')
    groups={g.name:g.index for g in ob.vertex_groups if g.name.startswith('face_')}
    memberships={k:[] for k in groups}
    for v in ob.data.vertices:
        for g in v.groups:
            for name,idx in groups.items():
                if idx==g.group: memberships[name].append(v.index)
    def shape(name,fn):
        key=ob.shape_key_add(name=name)
        key.value=0
        for group,inds in memberships.items():
            for i in inds: key.data[i].co=fn(group,ob.data.vertices[i].co.copy())
    def expression(kind):
        def fn(g,p):
            if 'eye_' in g:
                side=g[-1]; z=.981 if ravi else .976
                if kind in ['blink','wink_'+('left' if side=='L' else 'right')]: p.z=z+(p.z-z)*.045
                if kind=='surprised': p.z=z+(p.z-z)*1.10
            if 'lid_' in g and kind in ['blink','wink_'+('left' if g[-1]=='L' else 'right')]:
                z=.981 if ravi else .976; p.z=z+(p.z-z)*.06
            if 'mouth' in g:
                if kind in ['mouth_open','laugh','surprised']: p.z=.920+(p.z-.920)*2.0
                if kind in ['smile','happy','cheer','celebrate']: p.z+=.006*min(1,abs(p.x)/.043)
                if kind in ['sad','angry','frown']: p.z-=.012*min(1,abs(p.x)/.043)
            if 'brow_' in g:
                if kind in ['brows_up','surprised','nervous']: p.z+=.012
                if kind in ['angry','brows_down']: p.z+=abs(p.x)*.16-.012
                if kind in ['sad','frown']: p.z+=.010-abs(p.x)*.15
                if kind in ['confident','cheeky','playful'] and g.endswith('L'): p.z+=.009
            return p
        return fn
    for name in ['neutral','smile','happy','laugh','surprised','angry','sad','wink_left','wink_right','mouth_open','blink','frown','brows_up','brows_down','confident','cheeky','playful','cheer','celebrate','nervous']:
        shape(name,expression(name))

def animations(rig):
    for pb in rig.pose.bones: pb.rotation_mode='XYZ'
    def reset():
        for pb in rig.pose.bones: pb.rotation_euler=(0,0,0); pb.location=(0,0,0)
    def frame(f,rots={},height=0):
        reset(); rig.pose.bones['hips'].location.y=height
        for n,r in rots.items(): rig.pose.bones[n].rotation_euler=tuple(math.radians(v) for v in r)
        for pb in rig.pose.bones:
            pb.keyframe_insert(data_path='rotation_euler',frame=f,group=pb.name)
            if pb.name=='hips': pb.keyframe_insert(data_path='location',frame=f,group=pb.name)
    def clip(name,frames):
        rig.animation_data_create(); act=bpy.data.actions.new(name); rig.animation_data.action=act
        for f,rots,h in frames: frame(f,rots,h)
        tr=rig.animation_data.nla_tracks.new(); tr.name=name; st=tr.strips.new(name,int(act.frame_range[0]),act); st.extrapolation='NOTHING'; tr.mute=True
    clip('Idle',[(1,{},0),(31,{'chest':(1.2,0,0),'head':(-1,0,1)},.003),(61,{},0)])
    run=[]
    for f,phase in [(1,0),(7,math.pi/2),(13,math.pi),(19,3*math.pi/2),(25,2*math.pi)]:
        rot={'spine':(7,0,0)}
        for side,sgn in [('L',1),('R',-1)]:
            v=math.cos(phase)*sgn; rot['thigh.'+side]=(-32*v,0,0); rot['shin.'+side]=(max(0,v)*58+8,0,0)
            rot['upper_arm.'+side]=(27*v,0,-20*sgn); rot['forearm.'+side]=(-38,0,0)
        for c in [-1,0,1]:
            for j in range(3): rot['cape_%d_%d'%(c,j)]=(8+6*math.sin(phase+j*.8),0,0)
        run.append((f,rot,.008*abs(math.sin(phase))))
    clip('Run',run)
    clip('Jump',[(1,{},0),(8,{'thigh.L':(-24,0,0),'thigh.R':(-24,0,0),'shin.L':(48,0,0),'shin.R':(48,0,0)},-.04),(17,{'upper_arm.L':(0,0,90),'upper_arm.R':(0,0,-90),'thigh.L':(-25,0,0),'shin.L':(42,0,0)},.16),(28,{},0),(36,{},0)])
    cheer={'upper_arm.L':(0,0,125),'upper_arm.R':(0,0,-125),'forearm.L':(-15,0,0),'forearm.R':(-15,0,0),'head':(-8,0,0)}
    clip('Cheer',[(1,{},0),(12,cheer,.015),(24,{**cheer,'chest':(0,0,5)},.025),(36,{**cheer,'chest':(0,0,-5)},.015),(48,{},0)])
    seat={'thigh.L':(-80,0,-8),'thigh.R':(-80,0,8),'shin.L':(83,0,0),'shin.R':(83,0,0),'upper_arm.L':(-55,-22,-14),'upper_arm.R':(-55,22,14),'forearm.L':(-42,0,0),'forearm.R':(-42,0,0)}
    for side in ['L','R']:
        for i in range(5): seat['finger%d.01.%s'%(i,side)]=(55,0,0); seat['finger%d.02.%s'%(i,side)]=(55,0,0)
    clip('Kart_Sit',[(1,seat,0),(31,seat,0)])
    clip('Kart_Steer',[(1,seat,0),(16,{**seat,'chest':(0,-9,-6),'head':(0,8,0)},0),(31,seat,0),(46,{**seat,'chest':(0,9,6),'head':(0,-8,0)},0),(61,seat,0)])
    rig.animation_data.action=None; reset()
    return seat

def setup_stage():
    scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=16; scene.cycles.use_denoising=False; scene.cycles.device='CPU'
    scene.render.resolution_x=600; scene.render.resolution_y=720; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=False
    scene.world.color=(.18,.18,.18)
    scene.view_settings.view_transform='AgX'
    bpy.ops.mesh.primitive_plane_add(size=200); floor=bpy.context.object; floor.name='STUDIO_Floor'
    m=bpy.data.materials.new('STUDIO_Backdrop'); m.diffuse_color=(.09,.125,.15,1); floor.data.materials.append(m)
    def light(n,p,power,size):
        dat=bpy.data.lights.new(n,'AREA'); dat.energy=power; dat.shape='DISK'; dat.size=size
        ob=bpy.data.objects.new(n,dat); scene.collection.objects.link(ob); ob.location=p; ob.rotation_euler=(Vector((0,0,.6))-ob.location).to_track_quat('-Z','Y').to_euler()
    light('STUDIO_Key',(-1.6,2.0,2.7),180,2)
    light('STUDIO_Fill',(1.4,1.2,1.5),95,1.5)
    light('STUDIO_Rim',(0,-1.6,2.2),220,1.3)
    character_materials.configure_preview(scene)
    camdat=bpy.data.cameras.new('STUDIO_Camera'); cam=bpy.data.objects.new('STUDIO_Camera',camdat); scene.collection.objects.link(cam); scene.camera=cam
    camdat.type='ORTHO'; camdat.ortho_scale=1.43; camdat.lens=55
    cam.location=(1.4,2.4,1.0); cam.rotation_euler=(Vector((0,0,.57))-cam.location).to_track_quat('-Z','Y').to_euler()
    return cam,floor

def render_view(cam,name,azimuth,elevation=9,target=.57,scale=1.43):
    a=math.radians(azimuth); e=math.radians(elevation)
    cam.location=(2.7*math.sin(a)*math.cos(e),2.7*math.cos(a)*math.cos(e),target+2.7*math.sin(e))
    cam.rotation_euler=(Vector((0,0,target))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.ortho_scale=scale
    bpy.context.scene.render.filepath=str(OUT/'renders'/name); bpy.ops.render.render(write_still=True)

def main(name):
    global MAT,parts,bones,OUT
    parts=[]; bones={}; OUT=ROOT/name
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)
    MAT=atlas(name); rig=build_skeleton(); ravi=name=='ravi'
    make_head(ravi); limbs(ravi); outfit(ravi)
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); ob=bpy.context.object; ob.name=name.capitalize()+'_Character'
    # Remove degenerate pole triangles and weld the individual ellipsoid poles.
    import bmesh
    bm=bmesh.new(); bm.from_mesh(ob.data); bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(ob.data); bm.free()
    face_shapes(ob,ravi)
    apply_anatomy(ob,rig,ANATOMY[name])
    # Normalise actual silhouette height, including Ravi's feather, to 1.15m.
    rest=ob.data.shape_keys.key_blocks[0].data
    height=max(v.co.z for v in rest); zmin=min(v.co.z for v in rest); scale=1.15/(height-zmin)
    transform=Matrix.Rotation(math.pi,4,'Z')@Matrix.Scale(scale,4)@Matrix.Translation((0,0,-zmin))
    ob.data.transform(transform,shape_keys=True); rig.data.transform(transform)
    mod=ob.modifiers.new('Humanoid_skin','ARMATURE'); mod.object=rig; ob.parent=rig
    tri=ob.modifiers.new('Export_triangles','TRIANGULATE')
    seat=animations(rig)
    ob['source']='character-sheet.png + '+name+'-stijl.md'; ob['stage']=name.capitalize()+' material refinement 2026-11-21'; ob['forward']='-Z in glTF / Godot'; ob['height_m']=1.15
    ob['UV_note']='Dedicated head region with rear cylindrical seam; other parts share padded material swatches. Not a full unique production unwrap.'
    ob['rear_hair_refined']=True
    rig['clips']='Idle, Run, Jump, Cheer, Kart_Sit, Kart_Steer'; rig['facial_note']='Prototype geometry expressions; validate close-up before production.'
    bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.context.scene.render.fps=30
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_morph=True,export_skins=True,export_yup=True,export_materials='EXPORT',export_cameras=False,export_lights=False,export_force_sampling=True)
    cam,floor=setup_stage()
    # Keep the saved source in bind pose, with its render studio available.
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(name+'.blend')))
    # Resume-safe automation: rendering can run in small BORACER_VIEWS blocks.
    if os.environ.get('BORACER_BUILD_ONLY')=='1':
        print('CHARACTER_BUILD_SAVED',name,flush=True)
        return
    for fn,a in [('01-front.png',0),('02-three-quarter.png',32),('03-side.png',90),('04-back.png',180)]: render_view(cam,fn,a)
    render_view(cam,'05-face.png',12,4,target=.92*scale,scale=.44)
    # Physical render of actual deformed mesh, no illustrative substitute.
    action=next(a for a in bpy.data.actions if a.name=='Kart_Sit'); rig.animation_data.action=action
    if hasattr(rig.animation_data,'action_slot') and len(action.slots): rig.animation_data.action_slot=action.slots[0]
    bpy.context.scene.frame_set(1); render_view(cam,'06-kart-pose.png',40,11,target=.60,scale=1.35)
    rig.animation_data.action=None; bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    deps=bpy.context.evaluated_depsgraph_get(); ev=ob.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles()
    report={'character':name,'vertices':len(me.vertices),'triangles':len(me.loop_triangles),'bones':len(rig.data.bones),'materials':len(me.materials),'height_m':1.15,'glTF_forward':'-Z','clips':[a.name for a in bpy.data.actions if a.users],'blendshapes':[k.name for k in ob.data.shape_keys.key_blocks][1:],'notes':['Procedural reconstruction, not an exact sculpt of the supplied illustrations.','Dedicated head UV; other parts share material swatches.','Godot runtime import and full gameplay animation require separate verification.']}
    ev.to_mesh_clear(); (OUT/'validation.json').write_text(json.dumps(report,indent=2))
    print('CHARACTER_COMPLETE',json.dumps(report))

if __name__=='__main__':
    names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['boaz','ravi']
    for name in names: main(name)
    finish_batch()
