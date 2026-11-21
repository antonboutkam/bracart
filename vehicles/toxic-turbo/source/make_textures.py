"""Create the original UV paintwork; requires Pillow. Run before build_model.py."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import math, random
HERE=Path(__file__).resolve().parent
random.seed(37)
S=2048
im=Image.new('RGB',(S,S),(27,30,32));d=ImageDraw.Draw(im)
lime=(169,239,2)
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',410)
for cy in (512,1536):
    # Large irregular toxic patch, with a crisp, recognizable biohazard symbol.
    cx=850; rx=290;ry=270
    pts=[]
    for i in range(160):
        a=i*math.tau/160;r=1+.045*math.sin(5*a)+.035*math.cos(7*a)
        pts.append((cx+rx*r*math.cos(a),cy+ry*r*math.sin(a)))
    d.polygon(pts,fill=lime)
    badge=Image.new('RGBA',(520,520)); bd=ImageDraw.Draw(badge)
    bd.text((260,251),'☣',font=font,anchor='mm',fill=(12,16,14,255),stroke_width=1)
    if cy>1024:badge=badge.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    im.paste(badge,(cx-260,cy-260),badge)
    for j in range(23):
        x=random.choice([random.randint(200,510),random.randint(1190,1660)]); y=cy+random.randint(-285,285)
        r=random.randint(8,39)
        d.ellipse((x-r*1.6,y-r*.7,x+r*1.6,y+r*.7),fill=lime)
        if j%4==0:d.ellipse((x-r,y-r*1.6,x+r,y+r),fill=lime)
# upper front badge, on upper surface seam (v=0/1)
for y in (-12,2036):
    d.ellipse((25,y-150,345,y+150),fill=lime)
    f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',240)
    d.text((185,y),'☣',font=f,anchor='mm',fill=(12,16,14))
im.save(HERE/'body-paint.png')
im=Image.new('RGB',(1024,1024),lime);d=ImageDraw.Draw(im)
for j in range(25):
    x=random.randrange(1024);y=random.randrange(1024);rx=random.randrange(24,100);ry=random.randrange(22,80)
    a=random.random()*math.tau;pts=[]
    for i in range(64):
        t=i*math.tau/64;r=1+.12*math.sin(3*t+j)
        xx=rx*r*math.cos(t);yy=ry*r*math.sin(t)
        pts.append((x+xx*math.cos(a)-yy*math.sin(a),y+xx*math.sin(a)+yy*math.cos(a)))
    d.polygon(pts,fill=(23,27,25))
im.save(HERE/'fin-paint.png')
print('Created body and fin paint textures')
