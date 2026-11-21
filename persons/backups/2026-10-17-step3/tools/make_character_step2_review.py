"""Label actual Blender before/after pixels; never synthesise model appearances."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
for name in sys.argv[1:] or ['boaz', 'ravi']:
    review = root/name/'review-step2'
    for filename in ['01-front.png', '02-three-quarter.png', '03-side.png', '04-back.png', '05-face.png', '06-kart-pose.png']:
        before = Image.open(review/'before'/'renders'/filename).convert('RGB')
        after = Image.open(review/'after'/'renders'/filename).convert('RGB')
        assert before.size == after.size == (600,720)
        sheet = Image.new('RGB', (1200,760), '#182433')
        sheet.paste(before, (0,40)); sheet.paste(after, (600,40))
        draw = ImageDraw.Draw(sheet)
        draw.text((20,14), 'VOOR - stap 1 anatomie, oorspronkelijk haar', fill='white')
        draw.text((620,14), 'NA - stap 2 sculpturaal haar', fill='white')
        sheet.save(review/(filename[:-4]+'-comparison.jpg'), quality=94)
        print('STEP2_REVIEW_SHEET', review/(filename[:-4]+'-comparison.jpg'))
