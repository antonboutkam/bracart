"""Step 3 costume geometry; authoring-space metres. No face/rig/atlas changes.
API is injected from build_characters to retain one source for primitive/UV/weight rules.
"""
import math
import bmesh
from mathutils import Vector


def lion(g, name, center, scale, back=False, bone='spine'):
    mesh,ell,curve=g['mesh'],g['ell'],g['curve']
    cx,cy,cz=center; direction=1 if back else -1
    def p(x,z,d=.001): return (cx+x*scale,cy+direction*d,cz+z*scale)
    # Closed sculpted silhouettes instead of a stack of little circular beads.
    def relief(label,outline,d=.0018):
        vs=[p(x,z,0) for x,z in outline]+[p(x,z,d) for x,z in outline]; n=len(outline)
        fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
        fs += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        ob=mesh(name+label,vs,fs,'Gold',bone)
        ob['heraldic_silhouette']=True
        return ob
    relief('_rampant_body',[(-.19,.22),(-.04,.25),(.13,.12),(.14,-.10),(.05,-.24),(-.12,-.21),(-.17,-.06),(-.10,.08)])
    mane=[]
    for i in range(30):
        a=2*math.pi*i/30; r=1 if i%2==0 else .83
        mane.append((-.125+.235*r*math.cos(a),.32+.285*r*math.sin(a)))
    relief('_flowing_mane',mane,.0025)
    relief('_head',[(-.21,.48),(-.04,.49),(.015,.38),(-.07,.24),(-.21,.27),(-.26,.33),(-.39,.34),(-.43,.41),(-.25,.42)],.003)
    ell(name+'_ear',p(-.12,.49,.004),(.053*scale,.0017,.062*scale),'Gold',bone,8,6)
    ell(name+'_eye',p(-.23,.409,.005),(.020*scale,.001,.019*scale),'Leather',bone,8,6)
    limbs=[('reaching_arm',[(-.08,.22),(.10,.26),(.26,.42),(.22,.53),(.13,.55),(.17,.43),(.04,.34),(-.13,.32)]),
           ('raised_arm',[(-.16,.18),(-.32,.13),(-.45,.28),(-.51,.33),(-.60,.30),(-.56,.23),(-.49,.23),(-.36,.02),(-.16,.06)]),
           ('front_haunch',[(-.10,-.13),(-.21,-.24),(-.39,-.23),(-.45,-.30),(-.57,-.30),(-.55,-.38),(-.38,-.36),(-.27,-.33),(-.04,-.27)]),
           ('rear_haunch',[(.06,-.13),(.25,-.28),(.24,-.43),(.11,-.50),(-.03,-.48),(-.08,-.54),(.13,-.58),(.22,-.52),(.35,-.47),(.34,-.26),(.15,-.12)])]
    for label,outline in limbs: relief('_'+label,outline,.0022)
    curve(name+'_curling_tail',[p(x,z,.0015) for x,z in [(.07,-.11),(.35,-.04),(.46,.13),(.40,.30),(.42,.49),(.55,.57),(.61,.48),(.54,.40)]],.034*scale,'Gold',bone,6)
    relief('_tail_tuft',[(.49,.46),(.58,.44),(.66,.48),(.66,.58),(.61,.55),(.59,.65),(.56,.57)],.002)
    # Raised flowing mane ridges keep the lion readable at race distance.
    for j in range(4):
        x=-.02+j*.035
        curve(name+'_mane_ridge',[p(x-.12,.46,.004),p(x+.015,.32,.004),p(x-.08,.16,.004)],.010*scale,'Sole',bone,5)
    for x,z in [(-.58,.28),(.19,.53),(-.55,-.33),(.03,-.52)]:
        for k in (-1,0,1):
            curve(name+'_claw',[p(x,z+k*.025,.003),p(x-.055,z+k*.025+.012,.003)],.012*scale,'Gold',bone,5)


def shoulder(g,s,side,bone):
    mesh,curve,ell=g['mesh'],g['curve'],g['ell']
    # Two nested domed shells with a rolled rim, open beneath the arm.
    for layer,(cx,cz,rx,ry,h) in enumerate([(.141,.749,.064,.057,.043),(.161,.730,.059,.052,.027)]):
        vs=[]; n=24; rows=6
        for j in range(rows):
            a=(.10+j/(rows-1)*1.45)
            for i in range(n):
                t=2*math.pi*i/n
                vs.append((s*(cx+rx*math.sin(a)*math.cos(t)),ry*math.sin(a)*math.sin(t),cz+h*math.cos(a)))
        fs=[tuple(range(n-1,-1,-1))]+[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(rows-1) for i in range(n)]
        ob=mesh('Shoulder_domed_lame_%s_%d'%(side,layer),vs,fs,'Steel' if not layer else 'DarkSteel',bone)
        # Every shell gets a real inner face and edge thickness.
        g['solidify'](ob,.002)
        curve('Shoulder_rolled_gold_rim_'+side,[vs[(rows-1)*n+i%n] for i in range(n+1)],.0026,'Gold',bone)
    for x in (-.038,.038): ell('Shoulder_rivet_'+side,(s*(.141+x),-.039,.769),(.0035,.0035,.0035),'Gold',bone,8,6)
    start=len(g['parts']); lion(g,'Shoulder_lion_'+side,(s*.143,-.045,.758),.039,bone=bone)
    for ob in g['parts'][start:]:
        for v in ob.data.vertices:
            u=(v.co.x-s*.141)/.064; z=(v.co.z-.749)/.043
            depth=max(0,-v.co.y-.045)
            v.co.y=-.057*math.sqrt(max(.10,1-u*u-z*z))-.0015-depth*.5


def bracer(g,s,side,pts,bone):
    tube,box,curve=g['tube'],g['box'],g['curve']
    tube('Layered_leather_bracer_'+side,pts[4:],[.034,.033,.027],'Leather',bone,14)
    # Three overlapping tapered plates follow the forearm instead of one tiny bar.
    for j in range(3):
        t=j/3; a=Vector(pts[4]).lerp(Vector(pts[6]),t); b=Vector(pts[4]).lerp(Vector(pts[6]),min(1,t+.40))
        a.y=-.022; b.y=-.023
        tube('Bracer_lame_'+side,[tuple(a),tuple(b)],[.029-j*.002,.027-j*.002],'Steel',bone,10,flat=.45)
        curve('Bracer_lame_edge_'+side,[(a.x-s*.021,-.027,a.z),(a.x,-.038,a.z+.003),(a.x+s*.021,-.027,a.z)],.002,'Gold',bone)
    for idx in [4,5]:
        p=Vector(pts[idx]); q=p+Vector((s*.007,0,-.012))
        tube('Bracer_leather_cinch_'+side,[tuple(p),tuple(q)],[.036 if idx==4 else .032]*2,'Tan',bone,14)
        box('Bracer_cinch_buckle_'+side,(p.x,-.037,p.z-.006),(.018,.008,.015),'Gold',bone,.002)


def shoes(g,ravi,s,side,foot,shin):
    ringbody,tube,ell,curve,box=g['ringbody'],g['tube'],g['ell'],g['curve'],g['box']
    # Oval anatomical sole outline, a generous toe and narrower heel. Flat base z=0.
    for label,sections,col in [
      ('Outsole',[(0,.044,.084,-.034),(.012,.053,.096,-.036),(.025,.055,.097,-.037)],'Sole'),
      ('Midsole',[(.024,.055,.097,-.037),(.040,.053,.094,-.037),(.046,.049,.088,-.036)],'White' if ravi else 'Gold')]:
        ob=ringbody(label+'_'+side,sections,col,foot,28)
        for v in ob.data.vertices: v.co.x+=s*.082
    ell('Shoe_sculpted_upper_'+side,(s*.082,-.030,.068),(.051,.084,.044),'Green' if ravi else 'Leather',foot,24,12)
    ell('Rounded_toe_protector_'+side,(s*.082,-.092,.064),(.049,.041,.028),'White' if ravi else 'Gold',foot,24,10)
    if ravi:
        box('Sneaker_padded_tongue_'+side,(s*.082,-.030,.100),(.049,.058,.020),'Green',foot,.009)
        ell('Sneaker_heel_panel_'+side,(s*.082,.026,.076),(.046,.031,.031),'Orange',foot,16,8)
        # An actual rolled padded collar wraps the ankle opening.
        for col,z,rx,ry in [('White',.090,.039,.033),('Green',.103,.037,.029)]:
            curve('Sneaker_rolled_collar_'+side,[(s*.082+rx*math.cos(a),.012+ry*math.sin(a),z) for a in [2*math.pi*i/24 for i in range(25)]],.006,col,foot)
        for j in range(4):
            y=-.013-j*.017; z=.116-j*.006
            curve('Crossed_laces_'+side,[(s*.059,y,z),(s*.105,y-.012,z-.001)],.0026,'White',foot,6)
            curve('Crossed_laces_'+side,[(s*.105,y,z),(s*.059,y-.012,z-.001)],.0026,'White',foot,6)
        for sign in [-1,1]:
            curve('Sneaker_orange_panel_'+side,[(s*.082+sign*.046,-.061,.074),(s*.082+sign*.052,-.025,.080),(s*.082+sign*.043,.010,.076)],.008,'Orange',foot,8)
            # Outsole tread is an actual inset relief below the pale midsole.
            for j in range(5):
                box('Sneaker_tread_'+side,(s*.082+sign*.046,-.086+j*.031,.017),(.014,.014,.014),'Sole',foot,.003)
    else:
        tube('Boot_tall_shaped_shaft_'+side,[(s*.082,.006,.089),(s*.082,.003,.134),(s*.081,.001,.197)],[.036,.039,.040],'Leather',shin,20)
        # Rolled cuff, layered shin shield and two straps.
        tube('Boot_rolled_cuff_'+side,[(s*.081,.001,.189),(s*.081,.001,.207)],[.045,.044],'Tan',shin,20)
        ell('Boot_front_leather_reinforcement_'+side,(s*.081,-.029,.147),(.030,.012,.042),'Tan',shin,16,10)
        for z in (.119,.178):
            tube('Boot_leather_strap_'+side,[(s*.081,.001,z),(s*.081,.001,z+.012)],[.043,.043],'Leather',shin,20)
            box('Boot_gold_buckle_'+side,(s*.111,-.030,z+.006),(.020,.010,.016),'Gold',shin,.003)
            box('Boot_buckle_inset_'+side,(s*.111,-.036,z+.006),(.010,.003,.008),'Leather',shin,.001)
        curve('Boot_instep_strap_'+side,[(s*.035,-.034,.075),(s*.055,-.034,.104),(s*.082,-.034,.115),(s*.108,-.034,.104),(s*.129,-.034,.075)],.007,'Tan',foot)
        box('Boot_instep_buckle_'+side,(s*.082,-.046,.114),(.030,.015,.008),'Gold',foot,.003)
        curve('Toe_rolled_edge_'+side,[(s*.082+.048*math.cos(a),-.091+.040*math.sin(a),.062) for a in [math.pi+math.pi*i/20 for i in range(21)]],.0024,'Sole',foot)


def tunic_panels(g):
    mesh,curve=g['mesh'],g['curve']
    for s in (-1,1):
        for rear in (False,True):
            sign=1 if rear else -1; vs=[]; nx,nz=8,6
            for j in range(nz+1):
                t=j/nz
                for i in range(nx+1):
                    u=i/nx; x=s*((.010+.085*u)*(1+.20*t))
                    y=sign*(.063+.018*t+.009*math.sin(math.pi*u)*math.sin(math.pi*t)-.016*u*u)
                    z=.502-.093*t+.005*math.sin(math.pi*u)*t
                    vs.append((x,y,z))
            ob=mesh('Sculpted_split_tunic_panel',vs,[(j*(nx+1)+i,j*(nx+1)+i+1,(j+1)*(nx+1)+i+1,(j+1)*(nx+1)+i) for j in range(nz) for i in range(nx)],'Blue','hips')
            g['solidify'](ob,.004)
            edge=[vs[j*(nx+1)] for j in range(nz+1)]+[vs[nz*(nx+1)+i] for i in range(1,nx+1)]+[vs[j*(nx+1)+nx] for j in range(nz-1,-1,-1)]
            curve('Tunic_rolled_gold_hem',edge,.0027,'Gold','hips')
            curve('Tunic_inset_border',[(v[0]*.95,v[1]+sign*.002,v[2]+.008) for v in vs[nz*(nx+1):]],.001,'Sole','hips')


def cape_surface(x,z):
    t=(.779-z)/.465; width=.102+.065*t; u=x/width
    return .065+.083*t+.015*math.cos(u*math.pi*3)*(.25+.75*t)+.020*u*u


def cape_weights(x,z):
    t=max(0,min(1,(.779-z)/.465)); u=max(-1,min(1,x/(.102+.065*t)))
    q=u+1; ci=min(1,int(q)); f=q-ci; h=min(2,t*2.8); bj=min(1,int(h)); ff=h-bj
    return {'cape_%d_%d'%(cc,j):w*vw for cc,w in [(ci-1,1-f),(ci,f)] for j,vw in [(bj,1-ff),(bj+1,ff)]}


def tessellate_contact_relief(ob,max_edge=.005):
    """Fill polygons must follow cape folds between their original corners.

    Adaptive tessellation preserves the closed silhouette and UV/deform layers;
    projection after this step fits the interior, preventing cloth occlusion.
    """
    bm=bmesh.new();bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    for _ in range(6):
        edges=[e for e in bm.edges if e.calc_length()>max_edge]
        if not edges: break
        bmesh.ops.subdivide_edges(bm,edges=edges,cuts=1,use_grid_fill=True)
        bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>3])
    bm.to_mesh(ob.data);bm.free();ob.data.update()


def cape(g):
    # Visible fabric load path: clasps -> rounded shoulder bridges -> cape edge.
    for s in (-1,1):
        g['tube']('Cape_shoulder_fabric_bridge',[(s*.086,-.035,.772),(s*.104,-.008,.786),(s*.108,.026,.790),(s*.104,.064,.784),(s*.099,.089,.766)],[.009,.014,.015,.013,.010],'Red','chest',10)
    g['curve']('Cape_rear_collar_roll',[(-.080,.053,.791),(-.04,.047,.799),(0,.045,.800),(.04,.047,.799),(.080,.053,.791)],.007,'Red','chest',10)
    mesh=g['mesh']; nx,nz=32,22; vs=[]; ws=[]
    for j in range(nz+1):
        t=j/nz; z=.779-.465*t; width=.102+.065*t
        for i in range(nx+1):
            u=-1+2*i/nx; x=width*u; zz=z+.009*math.cos(u*math.pi*3)*(t**6)
            vs.append((x,cape_surface(x,zz),zz)); ws.append(cape_weights(x,zz))
    ob=mesh('Cape_sculpted_weighted_folds',vs,[(j*(nx+1)+i,j*(nx+1)+i+1,(j+1)*(nx+1)+i+1,(j+1)*(nx+1)+i) for j in range(nz) for i in range(nx)],'Red',weights=ws)
    g['solidify'](ob,.0035)
    # Red rolled hem, with weights at every sample, so it follows the three chains.
    for inds in ([j*(nx+1) for j in range(nz+1)], [j*(nx+1)+nx for j in range(nz+1)], [nz*(nx+1)+i for i in range(nx+1)]):
        pts=[vs[i] for i in inds]; g['tube']('Cape_rolled_fabric_hem',pts,.0022,'Red',sides=6,weights=[cape_weights(p[0],p[2]) for p in pts])
    start=len(g['parts']); lion(g,'Cape_large_lion',(0,.13,.566),.164,True,'cape_0_1')
    for mark in g['parts'][start:]:
        tessellate_contact_relief(mark)
        for v in mark.data.vertices:
            depth=max(0,v.co.y-.13)
            v.co.y=cape_surface(v.co.x,v.co.z)+.0015+depth*.5
        for vg in list(mark.vertex_groups): mark.vertex_groups.remove(vg)
        for v in mark.data.vertices:
            for bn,w in cape_weights(v.co.x,v.co.z).items():
                vg=mark.vertex_groups.get(bn) or mark.vertex_groups.new(name=bn); vg.add([v.index],w,'REPLACE')


def ravi_details(g):
    curve,ell,box=g['curve'],g['ell'],g['box']
    # Soft shaped collar and pocket gussets make this a garment with volume.
    for s in (-1,1):
        curve('Vest_padded_collar',[(s*.051,-.033,.789),(s*.037,-.052,.773),(s*.025,-.073,.731)],.008,'Green','chest',8)
        for z,x in [(.591,.062),(.705,.066)]:
            curve('Vest_pocket_rolled_edge',[(s*(x-.023),-.082,z+.007),(s*(x-.023),-.084,z-.016),(s*(x+.023),-.084,z-.016),(s*(x+.023),-.082,z+.007)],.0015,'Orange','chest',6)
            ell('Vest_soft_pocket_volume',(s*x,-.075,z-.005),(.025,.010,.019),'Green','chest',12,8)
        # Broad green sides, seam and padded orange flap on the pack.
        ell('Pack_soft_side',(s*.073,.115,.661),(.028,.043,.088),'Green','chest',16,10)
        curve('Pack_panel_stitch',[(s*.063,.172,.708),(s*.063,.174,.586),(s*.024,.174,.574)],.0014,'Stitch','chest',6)
        box('Pack_flap_cinch',(s*.049,.180,.720),(.017,.009,.043),'Tan','chest',.004)
    curve('Pack_flap_rolled_edge',[(-.074,.176,.737),(-.065,.178,.713),(0,.179,.709),(.065,.178,.713),(.074,.176,.737)],.0028,'Orange','chest',8)


def knee(g,s,side,bone):
    outline=[(0,.045),(.034,.025),(.037,-.009),(0,-.045),(-.037,-.009),(-.034,.025)]
    vs=[(s*.078+x,-.041,.279+z) for x,z in outline]
    vs += [(s*.078+x*.77,-.060,.279+z*.78) for x,z in outline]
    vs += [(s*.078,-.066,.281)]
    fs=[(i,(i+1)%6,(i+1)%6+6,i+6) for i in range(6)]+[(6+i,6+(i+1)%6,12) for i in range(6)]+[tuple(range(5,-1,-1))]
    g['mesh']('Forged_knee_shield_'+side,vs,fs,'Gold',bone)
    g['curve']('Knee_rolled_border_'+side,vs[:6]+[vs[0]],.0026,'Sole',bone)
    g['curve']('Knee_formed_ridge_'+side,[(s*.078,-.060,.314),(s*.078,-.068,.280),(s*.078,-.057,.249)],.0017,'Sole',bone)
