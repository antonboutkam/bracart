"""Assemble labelled review sheets from the actual fixed-camera mesh renders."""
from pathlib import Path
from PIL import Image, ImageDraw
base=Path(__file__).resolve().parents[1]
root=base/'persons' if (base/'persons'/'boaz').is_dir() else base
review=root/'boaz'/'review-step1'
for filename in ['01-front.png','02-three-quarter.png','03-side.png','05-face.png']:
    before=Image.open(review/'before'/'renders'/filename).convert('RGB')
    after=Image.open(review/'after'/'renders'/filename).convert('RGB')
    assert before.size==after.size==(600,720), (before.size,after.size)
    sheet=Image.new('RGB',(1200,760),'#182433')
    sheet.paste(before,(0,40)); sheet.paste(after,(600,40))
    draw=ImageDraw.Draw(sheet)
    draw.text((20,14),'VOOR - oorspronkelijke mesh',fill='white')
    draw.text((620,14),'NA - stap 1 kandidaat, wacht op goedkeuring',fill='white')
    sheet.save(review/(filename[:-4]+'-comparison.jpg'),quality=94)
    print('REVIEW_SHEET',review/(filename[:-4]+'-comparison.jpg'))
