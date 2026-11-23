"""Portable, deterministic colour/roughness textures; no Blender-only shaders.

The head has its own cylindrical UV region. Other parts intentionally share
padded material swatches; this is not a complete unique production unwrap.
"""
import math
import numpy as np

# Face occupies unused upper-left atlas quadrant, isolated from palette swatches.
FACE_RECT = (.015, .515, .485, .985)
OVERRIDES = {
    'Skin': ('#E7AE83', .52, 0), 'Ear': ('#CD785D', .58, 0),
    'Hair': ('#D99526', .39, 0), 'HairLight': ('#EDB64D', .42, 0),
    'HairDark': ('#995B1D', .50, 0), 'Lip': ('#A65C48', .57, 0),
    'Blue': ('#0758AB', .79, 0), 'BlueDark': ('#16365F', .86, 0),
    'Red': ('#BF152B', .78, 0), 'Gold': ('#DC9D39', .30, .83),
    'Steel': ('#9AAAB5', .27, .92), 'DarkSteel': ('#374853', .40, .83),
    'Leather': ('#593422', .57, 0), 'Tan': ('#A96B38', .65, 0),
    'Green': ('#146540', .79, 0), 'Olive': ('#59843C', .85, 0),
    'Orange': ('#E27926', .75, 0), 'Denim': ('#16446C', .90, 0),
    'DenimLight': ('#396685', .86, 0), 'Sole': ('#C59643', .82, 0),
}
FABRIC = {'Blue','BlueDark','Red','White','Green','Olive','Orange','Feather','Leaf'}
LEATHER = {'Leather','Tan','Glove'}
HAIR = {'Hair','HairLight','HairDark'}


def rgb(hex_value):
    return np.array([int(hex_value[i:i+2], 16)/255 for i in (1,3,5)], dtype=np.float32)


def textures(palette, size=2048):
    """Return sRGB-encoded base colour and linear ORM float buffers.

    Blender image pixels for byte PNGs are encoded values; do not linearise
    these a second time. The shader performs the sRGB decode on sampling.
    """
    tile = size//8
    al = np.ones((size,size,4), dtype=np.float32)
    orm = np.ones_like(al)
    y,x = np.mgrid[:tile,:tile].astype(np.float32)
    u=x/(tile-1); v=y/(tile-1)
    # Stable analytic grain, independent of Python/NumPy random implementations.
    grain=np.mod(np.sin(x*12.9898+y*78.233)*43758.5453,1)-.5
    weave=np.sin(x*math.pi/2)*np.sin(y*math.pi/2)
    for k in range(64):
        name,hex_value,rough,metal=palette[k%len(palette)]
        hex_value,rough,metal=OVERRIDES.get(name,(hex_value,rough,metal))
        shade=np.ones_like(u); roughness=np.full_like(u,rough)
        if name in FABRIC:
            shade+=.014*weave+.005*grain
            roughness+=.024*weave
        elif name.startswith('Denim'):
            twill=np.sin((x-y*.70)*math.pi/2)
            shade+=.025*twill+.008*weave
            roughness+=.020*twill
        elif name in LEATHER:
            pores=grain*.035+np.sin(x*.27+np.sin(y*.31))*.009
            shade+=pores; roughness+=grain*.055
        elif name in HAIR:
            shade+=.065*(v-.5)+.018*np.sin(u*math.pi*16+v*1.8)
            roughness+=.025*np.sin(u*math.pi*16)
        elif metal:
            brush=np.sin(y*math.pi)*.006+grain*.007
            shade+=brush; roughness+=grain*.040
        elif name=='EyeIris':
            radius=np.sqrt(((u-.5)/.44)**2+((v-.5)/.44)**2)
            angle=np.arctan2(v-.5,u-.5)
            shade*=1-.40*np.clip((radius-.72)/.25,0,1)
            shade+=.075*np.sin(angle*42+radius*5)*np.exp(-((radius-.6)/.35)**2)
        elif name=='Skin':
            shade+=.025*(v-.5)
        row,col=divmod(k,8); sl=np.s_[row*tile:(row+1)*tile,col*tile:(col+1)*tile]
        al[sl][:,:,:3]=np.clip(rgb(hex_value)*shade[:,:,None],0,1)
        orm[sl][:,:,0]=1 # AO deliberately unbaked: no fixed lighting in colour.
        orm[sl][:,:,1]=np.clip(roughness,.08,.98)
        orm[sl][:,:,2]=metal
    # A dedicated head texture, painted in cylindrical rest-space coordinates.
    x0,y0,x1,y1=[round(a*size) for a in FACE_RECT]
    yy,xx=np.mgrid[:y1-y0,:x1-x0].astype(np.float32)
    fu=xx/max(1,x1-x0-1); fv=yy/max(1,y1-y0-1)
    def spot(cx,cy,sx,sy):
        return np.exp(-((fu-cx)/sx)**2-((fv-cy)/sy)**2)
    cheeks=spot(.390,.375,.060,.085)+spot(.610,.375,.060,.085)
    nose=spot(.5,.455,.025,.055)
    lips=spot(.5,.285,.075,.035)
    temple=spot(.35,.60,.055,.19)+spot(.65,.60,.055,.19)
    face=np.broadcast_to(rgb('#E7AE83'),(y1-y0,x1-x0,3)).copy()
    face*=1+.030*(fv[:,:,None]-.5)
    warm=np.clip(.31*cheeks+.12*nose+.12*lips,0,.4)[:,:,None]
    face=face*(1-warm)+rgb('#DF7E65')*warm
    face*=1-.018*temple[:,:,None]
    al[y0:y1,x0:x1,:3]=np.clip(face,0,1)
    orm[y0:y1,x0:x1,1]=.52-.025*nose
    orm[y0:y1,x0:x1,2]=0
    return al,orm


def head_uv(vertices, polygon):
    """Seam at the back of the head; cheeks get stable, distinct UV positions."""
    us=[math.atan2(vertices[i][0],-vertices[i][1])/(2*math.pi)+.5 for i in polygon]
    if max(us)-min(us)>.5:
        us=[u+1 if u<.5 else u for u in us]
    x0,y0,x1,y1=FACE_RECT
    # 3% internal gutter also accommodates the tiny back-seam overrun.
    return [(x0+(x1-x0)*(.03+.94*u), y0+(y1-y0)*(.03+.94*(vertices[i][2]-.831)/.254))
            for i,u in zip(polygon,us)]


def configure_preview(scene, samples=64):
    scene.cycles.samples=samples
    scene.cycles.use_denoising=True
    scene.cycles.denoising_use_gpu=False
    scene.cycles.device='CPU'
    scene.cycles.use_adaptive_sampling=True
    scene.cycles.adaptive_threshold=.05
    scene.cycles.adaptive_min_samples=8
    scene.cycles.max_bounces=6
    scene.cycles.diffuse_bounces=2
    scene.cycles.glossy_bounces=3
    scene.view_settings.look='AgX - Medium High Contrast'
    scene.view_settings.exposure=-.35
    # Model identity is judged under the SAME lighting in before/after renders.
    for name,power in [('STUDIO_Key',145),('STUDIO_Fill',45),('STUDIO_Rim',180)]:
        light=scene.objects.get(name)
        if light: light.data.energy=power
    floor=scene.objects.get('STUDIO_Floor')
    if floor:
        mat=floor.data.materials[0]
        mat.use_nodes=True
        bsdf=mat.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value=(.09,.125,.15,1)
        bsdf.inputs['Roughness'].default_value=.87
