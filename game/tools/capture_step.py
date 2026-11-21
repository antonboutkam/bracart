#!/usr/bin/env python3
"""Capture native Godot phase evidence; preserves every run and isolates saves."""
import argparse
import datetime as dt
import hashlib
import html
import json
import os
from pathlib import Path
import re
import subprocess
import struct
import shutil
import tempfile
from render_commands import update_page, latest_successful_run, write_overview_indexes

GAME = Path(__file__).resolve().parents[1]
STEPS = ('stap-25-uithoorn-landmarks', 'stap-24-achteruitkijkspiegels', 'stap-00-start', 'stap-03-kleding', 'stap-04-materialen', 'stap-05-animatie', 'stap-06-werelden', 'stap-07-effecten', 'stap-08-interface', 'stap-09-keukentafel', 'stap-10-dashboard', 'stap-11-straatleven', 'stap-12-gebouwen-objecten', 'stap-13-garage-hemel', 'stap-14-vliegtuig', 'stap-15-keuken-avontuur', 'stap-16-vogeltje', 'stap-17-groen-cc0', 'stap-18-racefeedback', 'stap-19-haarlem-landmarks', 'stap-20-coureurreacties', 'stap-21-tracks-v2', 'stap-22-overwinningspodium', 'stap-23-stunt-edition')

def inspect_capture_frames(run, captures):
    invalid_frames = []
    for capture in captures:
        png = (run / capture['filename']).read_bytes()
        width, height = struct.unpack('>II', png[16:24]) if len(png) >= 24 and png[:8] == b'\x89PNG\r\n\x1a\n' else (0, 0)
        capture['width'], capture['height'] = width, height
        if width < 640 or height < 360:
            invalid_frames.append(capture['filename'])
    distinct_frames = len({item['sha256'] for item in captures})
    return invalid_frames, distinct_frames

def uithoorn_standalone_links(run):
    """Publish the actual approved studio frame beside the identical source GLB."""
    cards = []
    sources = GAME.parent / 'assets' / 'straatbeeld' / 'uithoorn'
    labels = {'rechthuis': 'Het Rechthuis', 'schanskerk': 'Schanskerk',
              'fort-aan-de-drecht': 'Fort aan de Drecht', 'irenebrug': 'Irenebrug',
              'thamerkerk': 'Thamerkerk', 'de-hoeksteen': 'De Hoeksteen'}
    for slug, label in labels.items():
        folder = sources / slug
        shutil.copy2(run / f'{slug}-studio-voor.png', folder / 'preview.png')
        links = ' · '.join(f'<a href="{html.escape(os.path.relpath(folder / filename, run), quote=True)}">{title}</a>'
                           for filename, title in [('model.glb', 'Zelfstandig GLB'), ('model.blend', 'Blenderbron'), ('preview.png', 'Voorbeeld')])
        cards.append(f'<li>{html.escape(label)}: {links}</li>')
    return ('<section><h2>Zelfstandige modellen</h2><p>De GLB-bestanden bevatten de materialen en kleurtexturen. '
            'Open ze in een glTF-viewer, Blender of Godot. De voorbeelden zijn native Godot-studiobeelden van dezelfde modellen.</p>'
            '<ul>' + ''.join(cards) + '</ul></section>')

def write_context_gallery(project):
    folder = project / 'gebouwen-en-objecten'
    folder.mkdir(exist_ok=True)
    step12 = project / 'stap-12-gebouwen-objecten'
    latest = latest_successful_run(step12) if step12.is_dir() else None
    subjects = []
    if latest is not None and (latest / 'subjects.json').is_file():
        subjects = json.loads((latest / 'subjects.json').read_text())
    sections = []
    for category, title in [('gebouwen', 'Gebouwen langs de weg'), ('objecten', 'Voorwerpen op de keukentafel')]:
        cards = []
        for item in subjects:
            filename = item['filename']
            if item['category'] != category or Path(filename).name != filename or not (latest / filename).is_file():
                continue
            source = '../stap-12-gebouwen-objecten/' + latest.name + '/' + filename
            cards.append(f'<figure><a href="{html.escape(source)}"><img loading="lazy" src="{html.escape(source)}" alt="{html.escape(item["label"])}"></a><figcaption>{html.escape(item["label"])}</figcaption></figure>')
        if not cards:
            # Existing real in-world captures are useful while the dedicated run is pending.
            fallback = ([('stap-06-werelden', 'boaz-hud-haarlem-1888.png', 'Haarlemse straat vanuit de racecamera'),
                         ('stap-06-werelden', 'boaz-hud-uithoorn-2056.png', 'Uithoornse wijk vanuit de racecamera')] if category == 'gebouwen' else
                        [('stap-09-keukentafel', 'keukentafel-'+key+'.png', label) for key, label in [('monitor','Monitor en toetsenbord op tafel'),('megaphone','Megafoon op tafel'),('can','Blikje op tafel'),('remote','Afstandsbediening op tafel'),('globe','Glazen bol op tafel'),('scissors','Schaar op tafel')]])
            for step, filename, label in fallback:
                step_folder = project / step
                previous = latest_successful_run(step_folder) if step_folder.is_dir() else None
                if previous is not None and (previous / filename).is_file():
                    source = f'../{step}/{previous.name}/{filename}'
                    cards.append(f'<figure><a href="{source}"><img loading="lazy" src="{source}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)} · eerdere native opname</figcaption></figure>')
            cards.insert(0, '<p class="note">De aparte galerijrun is nog niet gemaakt. Hieronder staan beschikbare eerdere beelden; maak stap12 voor de huidige zes gebouwen en elf objectgroepen met overzichten.</p>')
        sections.append(f'<h2>{title}</h2><section>{"".join(cards)}</section>')
    page = folder / 'index.html'
    page.write_text('<!doctype html><meta charset="utf-8"><title>Gebouwen en objecten in hun omgeving</title>'
        '<style>body{background:#10223a;color:#edf5ff;font:17px system-ui;padding:28px;max-width:1600px;margin:auto}a{color:#64ddff}section{display:flex;flex-wrap:wrap;gap:20px}figure{margin:0;width:min(100%,600px);background:#1c3349;border-radius:12px;overflow:hidden}img{display:block;width:100%}figcaption{padding:14px}.note{width:100%}</style>'
        '<h1>Gebouwen en objecten in hun omgeving</h1><p>Gebouwen staan in hun echte straat; keukenobjecten blijven op de tafel, met de spelwereld eromheen. Geen losse studiokopieën.</p>'
        '<p><a href="../stap-12-gebouwen-objecten/index.html">Actuele galerijrun maken of bekijken</a> · <a href="../index.html">Terug naar het renderoverzicht</a></p>'+''.join(sections))
    page.write_text(update_page(page))

def write_indexes(project):
    write_context_gallery(project)
    write_overview_indexes(project)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', default='GAME-10001')
    parser.add_argument('--step', required=True, choices=STEPS)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,79}', args.project):
        parser.error('project must be a plain directory name')
    run = GAME.parent / 'renders' / args.project / args.step / dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S-%fZ')
    run.mkdir(parents=True, exist_ok=False)
    script = {'stap-25-uithoorn-landmarks': 'tests/uithoorn_landmarks_visual.gd', 'stap-24-achteruitkijkspiegels': 'tests/rear_view_capture.gd', 'stap-23-stunt-edition': 'tests/stunt_edition_capture.gd', 'stap-22-overwinningspodium': 'tests/victory_podium_capture.gd', 'stap-21-tracks-v2': 'tests/tracks_v2_capture.gd', 'stap-20-coureurreacties': 'tests/driver_reactions_capture.gd', 'stap-19-haarlem-landmarks': 'tests/haarlem_landmarks_capture.gd',
              'stap-07-effecten': 'tests/effects_capture.gd',
              'stap-09-keukentafel': 'tests/kitchen_capture.gd',
              'stap-10-dashboard': 'tests/dashboard_capture.gd',
              'stap-11-straatleven': 'tests/street_life_capture.gd',
              'stap-12-gebouwen-objecten': 'tests/objects_context_capture.gd',
              'stap-13-garage-hemel': 'tests/garage_sky_capture.gd',
              'stap-14-vliegtuig': 'tests/aircraft_capture.gd',
              'stap-15-keuken-avontuur': 'tests/kitchen_adventure_capture.gd',
              'stap-16-vogeltje': 'tests/birds_capture.gd',
              'stap-17-groen-cc0': 'tests/quickwins_capture.gd',
              'stap-18-racefeedback': 'tests/quickwins_capture.gd'}.get(args.step, 'tests/step_capture.gd')
    expected = {'stap-25-uithoorn-landmarks': 38, 'stap-24-achteruitkijkspiegels': 10, 'stap-23-stunt-edition': 6, 'stap-22-overwinningspodium': 18, 'stap-21-tracks-v2': 56, 'stap-20-coureurreacties': 36, 'stap-19-haarlem-landmarks': 6, 'stap-06-werelden': 22, 'stap-07-effecten': 10, 'stap-08-interface': 20,
                'stap-09-keukentafel': 13, 'stap-10-dashboard': 6, 'stap-11-straatleven': 20,
                'stap-12-gebouwen-objecten': 20, 'stap-13-garage-hemel': 15, 'stap-14-vliegtuig': 3, 'stap-15-keuken-avontuur': 20, 'stap-16-vogeltje': 3, 'stap-17-groen-cc0': 4, 'stap-18-racefeedback': 5}.get(args.step, 12)
    assets = []
    for directory in (GAME / 'assets', GAME / 'scripts'):
        assets.extend(p for p in directory.rglob('*') if p.is_file() and not p.name.endswith(('.import', '.uid')))
    for name in ('boaz', 'ravi'):
        assets.extend(p for p in (GAME.parent / 'persons' / name).glob('*') if p.suffix in ('.glb', '.png'))
    if args.step == 'stap-25-uithoorn-landmarks':
        assets.extend((GAME.parent / 'assets' / 'straatbeeld' / 'uithoorn').glob('*/model.glb'))
    hashes = {str(p.relative_to(GAME.parent)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(assets)}
    metadata = {'project': args.project, 'step': args.step, 'created_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
                'renderer': 'native Godot; SubViewport studio and actual GameMain HUD',
                'scenario': ('Zes technische overviews, twee selectieschermen en 48 echte auto-drive/racecamera-opnames vanaf de startgrid; geen volledige gespeelde racevideo.' if args.step == 'stap-21-tracks-v2' else 'Geënsceneerde reviewposes en racemomenten; geen opgenomen volledige race.'), 'asset_sha256': hashes,
                'script': script, 'script_sha256': hashlib.sha256((GAME / script).read_bytes()).hexdigest(), 'captures': []}
    with tempfile.TemporaryDirectory(prefix='boracer-capture-') as isolated:
        env = dict(os.environ, BORACER_CAPTURE_DIR=str(run), BORACER_CAPTURE_STEP=args.step)
        env.update({f'XDG_{key}_HOME': str(Path(isolated) / key.lower()) for key in ('CACHE', 'CONFIG', 'DATA')})
        command = [args.godot, '--path', str(GAME), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', '1280x720', '--script', script]
        metadata['command'] = command
        with (run / 'capture.log').open('w') as log:
            result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT)
    metadata['exit_code'] = result.returncode
    if (run / 'subjects.json').is_file():
        metadata['subjects_sha256'] = hashlib.sha256((run / 'subjects.json').read_bytes()).hexdigest()
    metadata['captures'] = [{'filename': p.name, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size} for p in sorted(run.glob('*.png'))]
    invalid_frames, distinct_frames = inspect_capture_frames(run, metadata['captures'])
    metadata['invalid_frames'] = invalid_frames
    metadata['distinct_frames'] = distinct_frames
    metadata['complete'] = result.returncode == 0 and len(metadata['captures']) >= expected and not invalid_frames and distinct_frames >= 2
    (run / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    labels = {item['filename']: item['label'] for item in json.loads((run / 'subjects.json').read_text())} if (run / 'subjects.json').is_file() else {}
    cards = ''.join(f'<figure><a href="{html.escape(c["filename"])}"><img loading="lazy" src="{html.escape(c["filename"])}"></a><figcaption>{html.escape(labels.get(c["filename"], c["filename"]))}</figcaption></figure>' for c in metadata['captures'])
    status = 'Native Godot · capture voltooid' if metadata['complete'] else 'Native Godot · capture niet voltooid'
    standalone = uithoorn_standalone_links(run) if metadata['complete'] and args.step == 'stap-25-uithoorn-landmarks' else ''
    recovery = ''
    if not metadata['complete']:
        excerpt = (run / 'capture.log').read_text(errors='replace')[-3000:]
        recovery = ('<p>Er zijn nog geen volledige enginebeelden. Gebruik het commando bovenaan deze pagina vanuit een grafische desktopterminal.</p>'
                    f'<details><summary>Werkelijke foutmelding</summary><pre>{html.escape(excerpt)}</pre></details>')
    (run / 'index.html').write_text(f'<!doctype html><meta charset="utf-8"><title>{html.escape(args.project)} {args.step}</title><style>body{{background:#152333;color:#fff;font:16px sans-serif;padding:24px}}a{{color:#64ddff}}pre{{white-space:pre-wrap}}main{{display:flex;flex-wrap:wrap}}figure{{margin:12px;width:46%}}img{{width:100%}}</style><h1>{html.escape(args.project)} · {args.step}</h1><p>{status} · <a href="metadata.json">metadata</a> · <a href="capture.log">log</a></p>{recovery}<main>{cards}</main>')
    if standalone:
        index = run / 'index.html'
        index.write_text(index.read_text().replace('<main>', standalone + '<main>', 1))
    if metadata['complete']:
        latest = run.parent / 'latest'
        if latest.is_symlink():
            latest.unlink()
        if not latest.exists():
            latest.symlink_to(run.name, target_is_directory=True)
        (run.parent / 'index.html').write_text(f'<!doctype html><meta charset="utf-8"><h1>{html.escape(args.step)}</h1><p>Nieuwste geslaagde capture: <a href="{run.name}/index.html">open de beelden</a>.</p>')
    elif not (run.parent / 'index.html').exists():
        (run.parent / 'index.html').write_text(f'<!doctype html><meta charset="utf-8"><h1>Capture nog niet geslaagd</h1><p>Er zijn geen volledige enginebeelden. <a href="{run.name}/index.html">Bekijk de poging en het foutlog</a>.</p>')
    for folder in (run, run.parent):
        index = folder / 'index.html'
        index.write_text(update_page(index))
    write_indexes(run.parent.parent)
    print(run / 'index.html')
    raise SystemExit(0 if metadata['complete'] else result.returncode or 1)

if __name__ == '__main__':
    main()
