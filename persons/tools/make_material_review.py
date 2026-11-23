"""Label before/after mesh renders and draw the actual exported UV layout."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import sys,json
from check_character_hair_scope import GLB
ROOT=Path(__file__).resolve().parents[1]
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
font=lambda size:ImageFont.truetype(FONT,size)
for name in sys.argv[1:] or ['boaz','ravi']:
    folder=ROOT/name; review=folder/'review-materials-2026-11-21'
    for view,title in [('02-three-quarter','Driekwart'),('05-face','Gezicht')]:
        canvas=Image.new('RGB',(1200,810),'#14212a');draw=ImageDraw.Draw(canvas)
        draw.text((22,13),f'{name.upper()} / {title} / echte Blender-modellen',font=font(25),fill='#f3c568')
        draw.text((22,51),'VOOR',font=font(21),fill='white')
        draw.text((622,51),'NA - materiaalverbetering',font=font(21),fill='white')
        for i,variant in enumerate(['before','after']):
            path=review/variant/'renders'/(view+'.png')
            with Image.open(path) as source: canvas.paste(source.convert('RGB'),(i*600,90))
        canvas.save(review/(view+'-comparison.jpg'),quality=94)
    glb=GLB(folder/(name+'.glb'))
    canvas=Image.new('RGB',(1024,1084),'#14212a')
    with Image.open(folder/(name+'_basecolor.png')) as source:
        canvas.paste(source.convert('RGB').resize((1024,1024)),(0,60))
    draw=ImageDraw.Draw(canvas)
    draw.text((18,16),'UV: eigen hoofdvlak + gedeelde materiaalvlakken',font=font(23),fill='white')
    for mesh in glb.doc['meshes']:
        for prim in mesh['primitives']:
            uv=glb.acc(prim['attributes']['TEXCOORD_0'])
            indices=[v[0] for v in glb.acc(prim['indices'])]
            for t in range(0,len(indices),3):
                points=[(round(uv[i][0]*1024),60+round(uv[i][1]*1024)) for i in indices[t:t+3]]
                draw.line(points+[points[0]],fill='#42372b',width=1)
    canvas.save(review/'uv-layout.png')
    maps=Image.new('RGB',(1024,574),'#14212a');draw=ImageDraw.Draw(maps)
    draw.text((18,14),'Base color (sRGB)',font=font(23),fill='white')
    draw.text((530,14),'ORM (lineair: R=1, G=ruw, B=metaal)',font=font(18),fill='white')
    for i,suffix in enumerate(['basecolor','orm']):
        with Image.open(folder/(name+'_'+suffix+'.png')) as source:maps.paste(source.convert('RGB').resize((512,512)),(i*512,62))
    maps.save(review/'texture-maps.png')
    print('REVIEW_SHEETS',name,flush=True)
