"""Assemble actual Blender renders into labelled review sheets (requires Pillow)."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

BASE=Path(__file__).resolve().parents[1]
ROOT=BASE/'persons' if (BASE/'persons'/'boaz').is_dir() else BASE
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
VIEWS=[('01-front.png','Voor'),('02-three-quarter.png','Driekwart'),('03-side.png','Zij'),('04-back.png','Achter'),('05-face.png','Gezicht'),('06-kart-pose.png','Kartzitpose')]

def main():
    for name in sys.argv[1:] or ['boaz','ravi']:
        out=Image.new('RGB',(1500,1350),'#13202a'); d=ImageDraw.Draw(out)
        d.text((30,20),name.upper()+' / BLENDER 3D',font=ImageFont.truetype(FONT,30),fill='#f3c66a')
        d.text((30,62),'Materiaalstudie - echte Blender-geometrie, geen gameplaybeeld',font=ImageFont.truetype(FONT,18),fill='#c3d0db')
        for i,(file,label) in enumerate(VIEWS):
            im=Image.open(ROOT/name/'renders'/file).convert('RGB'); im.thumbnail((490,550))
            x=(i%3)*500; y=105+(i//3)*610
            out.paste(im,(x+(500-im.width)//2,y))
            d.text((x+20,y+553),label,font=ImageFont.truetype(FONT,21),fill='#f2eee4')
        out.save(ROOT/name/'renders'/'overzicht.jpg',quality=93)

if __name__=='__main__': main()
