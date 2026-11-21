"""Author UV paint maps (no baked reference lighting). Python 3 + Pillow."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
from math import cos,sin,pi,tau
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
NAMES=['golden-rocket-racer','purple-passion','rainbow','raketfiets','retro']
PALETTE={'golden-rocket-racer':(239,187,40),'purple-passion':(97,13,189),'rainbow':(230,30,30),'raketfiets':(0,153,201),'retro':(245,77,12)}
S=2048
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def star(d,c,r,color,ratio=1):
 x,y=c;d.polygon([(x+cos(-pi/2+i*pi/5)*r*(1 if i%2==0 else .43),y+sin(-pi/2+i*pi/5)*r*ratio*(1 if i%2==0 else .43)) for i in range(10)],fill=color)
def roundel(d,c,r,ratio=1):
 x,y=c;d.ellipse((x-r,y-r*ratio,x+r,y+r*ratio),fill=(255,250,232))
 # Scale typography with the same metric ratio as the circular badge.
 tile=Image.new('RGBA',(400,400));td=ImageDraw.Draw(tile);td.text((200,204),'8',font=ImageFont.truetype(FONT,330),anchor='mm',fill=(12,13,14,255))
 tile=tile.resize((int(r*1.65),int(r*1.65*ratio)),Image.Resampling.LANCZOS)
 d._image.paste(tile,(int(x-tile.width/2),int(y-tile.height/2)),tile)
def rainbow(size,fin=False,nose=False):
 y,x=np.mgrid[0:size,0:size];u=x/(size-1);v=1-y/(size-1)
 # Height on cylindrical hull; top red, bottom violet; slight diagonal sweep.
 h=(1+np.cos(tau*v))/2
 t=np.clip((1-h)*.84+u*.12,0,1)
 if fin:t=np.clip(y/(size-1)*.75+x/(size-1)*.23,0,1)
 colors=np.array([(244,24,44),(255,124,0),(255,222,0),(19,196,62),(0,174,225),(28,67,222),(105,20,193),(211,15,157)],float)
 a=t*7;i=np.minimum(a.astype(int),6);f=(a-i)[...,None]
 return Image.fromarray((colors[i]*(1-f)+colors[i+1]*f).astype('uint8'))
def flames(d,cy,flip=False):
 # Ivory forward field with curved orange/red tongues sweeping aft.
 pts=[(0,cy-275),(650,cy-275)]
 for j in range(6):
  y=cy-275+j*110
  pts.extend([(620,y),(770,y+8),(960,y+40),(1080,y+20),(1000,y+65),(845,y+72),(750,y+90)])
 pts.extend([(610,cy+335),(0,cy+335)])
 d.polygon(pts,fill=(255,236,195))
 # Smooth tongues via sampled sinusoidal contours, all pointing toward rear.
 for j in range(5):
  y=cy-225+j*105
  upper=[];lower=[]
  for k in range(81):
   t=k/80;x=430+570*t;center=y+35*sin(t*pi*1.7+j*.7);w=32*(1-t)**.6
   upper.append((x,center-w));lower.append((x,center+w))
  d.polygon(upper+lower[::-1],fill=(236,53,12))
for name in NAMES:
 out=ROOT/name/'source';out.mkdir(exist_ok=True)
 for kind in ['body','nose','fin']:
  n=S if kind=='body' else 1024
  im=rainbow(n,fin=kind=='fin') if name=='rainbow' else Image.new('RGB',(n,n),PALETTE[name]);d=ImageDraw.Draw(im)
  if kind=='body':
   for cy in (S*.25,S*.75):
    if name=='golden-rocket-racer':
     d.rectangle((0,cy-29,S,cy+29),fill=(112,89,27));cx=820;rx=175;ry=rx*.79
     d.ellipse((cx-rx,cy-ry,cx+rx,cy+ry),fill=(110,83,23));star(d,(cx,cy),rx*.88,(244,194,52),.79);star(d,(cx-45,cy-30),rx*.73,(42,38,21),.79)
    elif name=='purple-passion':
     for x,dy,r in [(820,0,183),(435,-125,75),(1170,-150,91),(1190,140,70),(390,130,53)]:star(d,(x,cy+dy),r,(255,194,24),.79)
    elif name=='rainbow':star(d,(820,cy),185,(255,255,250),.79)
    elif name=='retro':flames(d,cy);roundel(d,(820,cy),163,.79)
   if name=='raketfiets':
    for cy in [S*.25,S*.75]:
     # Lower side trim using the circumference below the horizontal midline.
     sign=1 if cy<S/2 else -1
     y=cy+sign*110;d.rectangle((0,y-19,S,y+19),fill=(242,34,158));y+=sign*42;d.rectangle((0,y-17,S,y+17),fill=(254,244,218))
   # Badges on upper forward shoulders at the UV seam.
   for cy in [0,S]:
    if name=='retro':roundel(d,(130,cy),104,.79)
    elif name=='golden-rocket-racer':star(d,(130,cy),85,(103,77,24),.79)
    elif name=='purple-passion':star(d,(150,cy),87,(255,195,24),.79)
  elif kind=='nose':
   if name=='retro':
    d.rectangle((0,0,n,n),fill=(255,236,203));d.rectangle((0,0,170,n),fill=(245,77,12))
   if name=='raketfiets':
    # UV seam is the crown: three parallel stripes, narrowing at the tip.
    for center in [-.062,0,.062,.938,1,1.062]:
     d.polygon([(0,center*n-6),(n,center*n-19),(n,center*n+19),(0,center*n+6)],fill=(255,216,10))
    for cy in [.25*n,.75*n]:d.polygon([(110,cy+50),(500,cy+120),(460,cy+35)],fill=(235,28,32))
    d.rectangle((0,n*.46,n,n*.54),fill=(255,242,218))
  else:
   if name=='golden-rocket-racer':d.rectangle((0,n*.30,n,n*.41),fill=(112,89,27))
   elif name=='purple-passion':
    d.rectangle((0,0,n,n*.12),fill=(250,190,27));star(d,(n*.46,n*.47),n*.205,(255,197,20))
   elif name=='rainbow':star(d,(n*.48,n*.52),n*.21,(255,255,250))
   elif name=='retro':
    # Cream tongues rising from root onto orange fin.
    for j in range(5):
     x=70+j*225;pts=[(x-70,n),(x-50,700),(x+20,590),(x-5,450),(x+110,580),(x+80,760),(x+110,n)];d.polygon(pts,fill=(255,237,207))
    roundel(d,(n*.48,n*.36),n*.19)
  im.save(out/f'{kind}-paint.png')
 # Pennant artwork, used on the actual double-sided wavy cloth mesh.
 if name=='raketfiets':
  im=Image.new('RGB',(1024,512),(228,15,29));d=ImageDraw.Draw(im);star(d,(430,256),160,(255,250,232));im.save(out/'flag-paint.png')
print('Paint maps created for',', '.join(NAMES))
