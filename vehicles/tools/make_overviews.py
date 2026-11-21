"""Combine exported-GLB inspection views into labeled contact sheets."""
from PIL import Image,ImageDraw,ImageOps
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
NAMES=['golden-rocket-racer','purple-passion','rainbow','raketfiets','retro']
views=['front-right','rear-right','left','right','front','rear','top','bottom','rear-left']
for name in (sys.argv[1:] or NAMES):
 sheet=Image.new('RGB',(1440,1230),(19,26,35));d=ImageDraw.Draw(sheet)
 for i,label in enumerate(views):
  im=Image.open(ROOT/name/'previews'/f'{label}.png').convert('RGB');im=ImageOps.contain(im,(480,382),Image.Resampling.LANCZOS);x=i%3*480;y=i//3*410;sheet.paste(im,(x+(480-im.width)//2,y+25));d.text((x+15,y+7),f'{name} / {label}',fill='white')
 sheet.save(ROOT/name/'previews/overzicht.jpg',quality=92)
if not all((ROOT/name/'previews'/f'{view}.png').exists() for name in NAMES for view in views):
 sys.exit(0)
allviews=Image.new('RGB',(1280,5*537),(19,26,35));d=ImageDraw.Draw(allviews)
for i,name in enumerate(NAMES):
 for j,label in enumerate(['front-right','left']):
  im=Image.open(ROOT/name/'previews'/f'{label}.png').convert('RGB');im=ImageOps.contain(im,(640,512),Image.Resampling.LANCZOS);allviews.paste(im,(j*640+(640-im.width)//2,i*537+25+(512-im.height)//2))
 d.text((20,i*537+7),name,fill='white')
allviews.save(ROOT/'verbeterde-voertuigen.jpg',quality=93)
