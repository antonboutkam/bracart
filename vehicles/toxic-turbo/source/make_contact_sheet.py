from PIL import Image,ImageDraw,ImageFont,ImageOps
from pathlib import Path
P=Path(__file__).resolve().parent.parent
views=[('front-right','Voor rechts'),('rear-right','Achter rechts'),('rear-left','Achter links'),('left','Links'),('right','Rechts'),('top','Boven'),('front','Voor'),('rear','Achter')]
W,H=640,510
im=Image.new('RGB',(W*3,H*3+90),(19,25,33));d=ImageDraw.Draw(im)
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',23)
title=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',32)
d.text((24,23),'TOXIC TURBO  /  verbeterde GLB',font=title,fill=(182,244,20))
for i,(file,label) in enumerate(views):
 x=i%3*W;y=i//3*H+90
 tile=Image.open(P/'previews'/f'{file}.png').convert('RGB');tile=ImageOps.fit(tile,(W,480))
 im.paste(tile,(x,y));d.text((x+18,y+480),label,font=font,fill=(224,231,238))
x=2*W+30;y=2*H+140
for text in ['Echte 3D-geometrie','Ingebedde PBR-textures','Open cockpit en bediening','Afzonderlijke wielpivots','Neus: -Z / boven: +Y']:
 d.text((x,y),text,font=font,fill=(210,220,228));y+=50
im.save(P/'previews'/'overzicht.jpg',quality=93)
print('Saved previews/overzicht.jpg')
