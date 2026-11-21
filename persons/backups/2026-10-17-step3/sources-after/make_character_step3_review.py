"""Freeze step 3 outputs and compose honest matched-camera render comparisons."""
from pathlib import Path
import shutil, sys
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
BASELINE=ROOT/'backups/2026-10-17-step3'
for name in (sys.argv[1:] or ['boaz','ravi']):
    folder=ROOT/name; review=folder/'review-step3'; after=review/'after'
    if after.exists(): raise SystemExit(f'Refusing to overwrite frozen review snapshot: {after}')
    after.mkdir(parents=True)
    for suffix in ('.blend','.glb','_basecolor.png','_orm.png'):
        shutil.copy2(folder/(name+suffix),after/(name+suffix))
    for filename in ('validation.json','glb-validation.json','blender-import-validation.json'):
        shutil.copy2(folder/filename,after/filename)
    shutil.copytree(folder/'renders',after/'renders')
    for filename in ('scope-audit.json','render-provenance.json'):
        if (review/filename).exists(): shutil.copy2(review/filename,after/filename)
    if (folder/(name+'.cape-contact.json')).exists():
        shutil.copy2(folder/(name+'.cape-contact.json'),after/'cape-contact.json')
    for filename in ('01-front.png','02-three-quarter.png','03-side.png','04-back.png','05-face.png','06-kart-pose.png'):
        before=Image.open(BASELINE/name/'renders'/filename).convert('RGB')
        image=Image.open(after/'renders'/filename).convert('RGB')
        assert before.size==image.size
        w,h=before.size; canvas=Image.new('RGB',(w*2,h+38),'#183044')
        canvas.paste(before,(0,38));canvas.paste(image,(w,38))
        draw=ImageDraw.Draw(canvas);draw.text((14,13),f'{name.upper()} - STAP 2 / VOOR',fill='white')
        draw.text((w+14,13),'STAP 3 / KOSTUUMKANDIDAAT',fill='white')
        canvas.save(review/(Path(filename).stem+'-comparison.jpg'),quality=94)
    print('FROZEN_REVIEW',after)
