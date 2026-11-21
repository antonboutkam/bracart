#!/usr/bin/env python3
"""Keep safe, working-directory-independent commands in existing render HTML."""
import argparse
import datetime as dt
import html
import json
from html.parser import HTMLParser
from pathlib import Path
import re
import shlex
from urllib.parse import urlsplit

GAME = Path(__file__).resolve().parents[1]
RENDERS = GAME.parent / 'renders'
START = '<!-- boracer-render-commands:start -->'
END = '<!-- boracer-render-commands:end -->'
BLOCK = re.compile(re.escape(START) + r'.*?' + re.escape(END), re.S)
STEP_NAMES = {
 'stap-25-uithoorn-landmarks':'Uithoorn · zes landmarks met fotomaterialen',
 'stap-23-stunt-edition':'Stunt Edition · selectie en cockpit',
 'stap-00-start':'Startcapture', 'stap-03-kleding':'Kostuums Boaz en Ravi',
 'stap-04-materialen':'Materialen Boaz en Ravi', 'stap-05-animatie':'Animaties Boaz en Ravi',
 'stap-06-werelden':'Werelden Haarlem en Uithoorn', 'stap-07-effecten':'Beloningen en weereffecten',
 'stap-08-interface':'Interface', 'stap-09-keukentafel':'Keukentafel',
 'stap-10-dashboard':'Dashboard', 'stap-11-straatleven':'Straatleven',
 'stap-12-gebouwen-objecten':'Gebouwen en objecten', 'stap-13-garage-hemel':'Garage en hemel',
 'stap-14-vliegtuig':'Vliegtuig en condensspoor',
 'stap-15-keuken-avontuur':'Keukentafel: tunnels, looping en schansen',
 'stap-16-vogeltje':'Vogeltje in de lucht',
 'stap-17-groen-cc0':'Groenaccenten met CC0-modellen',
 'stap-18-racefeedback':'Landingsstof, vonken en finishviering',
 'stap-22-overwinningspodium':'Winnaars op het 3D-podium',
 'stap-21-tracks-v2':'Zes grotere circuits · Versie 2',
 'stap-20-coureurreacties':'Coureurs: achteromblik, knipoog en turbo',
 'stap-19-haarlem-landmarks':'Haarlem: Amsterdamse Poort en Teylers Museum',
}



def command(script, *args):
    return shlex.join(['python3', str((GAME / 'tools' / script).resolve()), *args])


def command_block(project='GAME-10001', step=None, audio=False, historical=False, all_steps=False):
    if all_steps:
        rows = [('Alle actuele Godot-renders opnieuw maken', command('capture_review.py', '--project', project))]
    elif audio == 'impacts':
        rows = [('Deze luisterpagina vernieuwen', command('review_material_audio.py', '--project', project))]
    elif audio:
        rows = [('Deze audiovoorbeelden opnieuw maken', command('build_vehicle_audio.py'))]
    elif step or historical:
        rows = [('Deze Godot-pagina opnieuw maken', command('capture_step.py', '--project', project, '--step', step or 'stap-03-kleding'))]
    else:
        return '' # Navigation indexes do not own a game-capture command.
    cards = ''.join('<p>' + html.escape(title) + '</p><button type="button" class="boracer-copy">Kopieer commando</button><pre><code>' + html.escape(text) + '</code></pre>' for title, text in rows)
    if all_steps:
        note = ('Voer dit commando uit in een terminal binnen een grafische desktopsessie. '
                'Het maakt de actuele karakterfase en alle spelonderdelen achter elkaar, inclusief het vogeltje. '
                'Nieuwe beelden worden per onderdeel in een aparte runmap bewaard.')
    elif audio == 'impacts':
        note = ('Dit commando vernieuwt de luisterpagina van de geselecteerde bestaande WAV-clips. '
                'Een grafische Godot-sessie is daarvoor niet nodig.')
    elif audio:
        note = ('Dit Python-commando maakt de afgeleide WAV-bestanden en deze offline audiovoorbeelden opnieuw. '
                'Een grafische Godot-sessie is daarvoor niet nodig; het bronbestand blijft behouden.')
    elif historical:
        note = ('Dit zijn historische Blender-stills. Dit commando maakt alleen actuele Godot-kledingbeelden; '
                'het overschrijft of reproduceert deze Blender-stills niet. Gebruik een terminal binnen een grafische desktopsessie.')
    else:
        note = ('Voer dit commando uit in een terminal binnen een grafische desktopsessie. '
                'Het werkt vanuit iedere werkmap en bewaart nieuwe beelden in een aparte runmap.')
    return (START + '<section class="boracer-render-commands"><style>.boracer-render-commands{margin:28px 0;padding:20px;border:1px solid #58819e;border-radius:12px;background:#10243b;color:#edf5ff;font:16px system-ui}'
            '.boracer-render-commands pre{white-space:pre-wrap;overflow-wrap:anywhere;word-break:break-word;background:#071727;padding:14px;border-radius:6px;line-height:1.6}'
            '.boracer-render-commands button{padding:8px 12px;border-radius:6px;cursor:pointer;background:#c4edff;color:#10243b;border:0}</style>'
            '<h2>Zelf beelden of voorbeelden maken</h2><p>' + html.escape(note) + '</p>' + cards + '</section>'
            '<script>document.querySelectorAll(".boracer-render-commands .boracer-copy").forEach(function(b){b.onclick=function(){var c=b.nextElementSibling;' 
            'if(navigator.clipboard){navigator.clipboard.writeText(c.textContent).then(function(){b.textContent="Gekopieerd";},function(){selectCode();});}else{selectCode();}'
            'function selectCode(){var r=document.createRange();r.selectNodeContents(c);var s=window.getSelection();s.removeAllRanges();s.addRange(r);b.textContent="Geselecteerd: kopieer met Ctrl+C";}};});</script>' + END)


class MetaTag(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refresh = None

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag.lower() == 'meta' and str(attributes.get('http-equiv', '')).lower() == 'refresh':
            self.refresh = attributes.get('content', '')


def static_refresh_link(match):
    parser = MetaTag()
    parser.feed(match.group())
    if parser.refresh is None:
        return match.group()
    target = re.search(r'(?:^|;)\s*url\s*=\s*(.*?)\s*$', parser.refresh, re.I)
    if not target:
        return ''
    href = target.group(1).strip('"\'')
    if re.match(r'^[a-z][a-z0-9+.-]*:', href, re.I) or href.startswith('//'):
        return ''
    return '<p class="boracer-latest-link">Nieuwste geslaagde capture: <a href="' + html.escape(href, quote=True) + '">open de beelden</a>.</p>'


def add_commands(document, project='GAME-10001', step=None, audio=False, historical=False):
    document = BLOCK.sub('', document)
    document = re.sub(r'<pre[^>]*>(?:(?!</pre>).)*capture_review\.py(?:(?!</pre>).)*</pre>', '', document, flags=re.S|re.I)
    document = re.sub(r'<meta\b[^>]*>', static_refresh_link, document, flags=re.I)
    block = command_block(project, step, audio, historical)
    heading = re.search(r'</h1\s*>', document, re.I)
    if heading:
        at = heading.end()
    else:
        body = re.search(r'<body\b[^>]*>', document, re.I)
        at = body.end() if body else len(document)
    return document[:at] + block + document[at:]


def page_context(path, renders=RENDERS):
    parts = Path(path).relative_to(renders).parts
    project = parts[0] if len(parts) > 1 else 'GAME-10001'
    step = next((p for p in parts if p in STEP_NAMES), None)
    if 'gebouwen-en-objecten' in parts:
        step = 'stap-12-gebouwen-objecten'
    audio = 'impacts' if 'materiaalgeluiden' in parts else 'audio' in parts
    return project, step, audio, any('blender' in p.lower() for p in parts)


def run_success(run):
    """Metadata failures never become successes just because partial PNGs exist."""
    if not any(p.is_file() for p in run.glob('*.png')):
        return False
    metadata = run / 'metadata.json'
    if metadata.exists():
        try:
            data = json.loads(metadata.read_text())
        except (ValueError, OSError):
            return False
        return isinstance(data, dict) and data.get('complete') is True and data.get('exit_code') == 0
    # A live/interrupted native job writes capture.log before metadata.json.
    # Its partial images are not an old image-only gallery or proof of success.
    return not (run / "capture.log").exists()


def run_order(run):
    try:
        data = json.loads((run / 'metadata.json').read_text())
        return dt.datetime.fromisoformat(data['created_utc'].replace('Z', '+00:00')).timestamp(), run.name
    except (OSError, ValueError, KeyError, TypeError):
        try:
            stamp = dt.datetime.strptime(run.name, '%Y%m%dT%H%M%S-%fZ').replace(tzinfo=dt.timezone.utc).timestamp()
        except ValueError:
            stamp = run.stat().st_mtime
        return stamp, run.name


def latest_successful_run(step):
    candidates = [p for p in Path(step).iterdir() if p.is_dir() and not p.is_symlink() and run_success(p)]
    return max(candidates, key=run_order) if candidates else None


def relative_assets(document, prefix):
    """Inline an existing gallery while keeping image, log and metadata targets."""
    def replace(match):
        target = html.unescape(match.group(3))
        if not target or target.startswith(('#','/')) or urlsplit(target).scheme:
            return match.group()
        return match.group(1) + match.group(2) + html.escape(prefix + target, quote=True) + match.group(2)
    return re.sub(r'((?:href|src|poster)\s*=\s*)([\"\'])(.*?)(?:\2)', replace, document, flags=re.I|re.S)


def named_document(document, title):
    document = re.sub(r'<h1\b[^>]*>.*?</h1\s*>', '<h1>'+html.escape(title)+'</h1>', document, count=1, flags=re.I|re.S)
    document = re.sub(r'<title\b[^>]*>.*?</title\s*>', '<title>'+html.escape(title)+'</title>', document, count=1, flags=re.I|re.S)
    return document


def step_wrapper(folder, project):
    folder = Path(folder)
    title = STEP_NAMES.get(folder.name, folder.name)
    run = latest_successful_run(folder)
    if run:
        source = run / 'index.html'
        if source.is_file():
            gallery = BLOCK.sub('', source.read_text())
            gallery = re.sub(r'<pre[^>]*>(?:(?!</pre>).)*capture_review\.py(?:(?!</pre>).)*</pre>', '', gallery, flags=re.S|re.I)
            gallery = re.sub(r'<(?:!doctype|/?(?:html|head|body))\b[^>]*>', '', gallery, flags=re.I)
            gallery = re.sub(r'<(?:title|h1)\b[^>]*>.*?</(?:title|h1)\s*>', '', gallery, flags=re.I|re.S)
            gallery = relative_assets(gallery, run.name + '/')
        else:
            gallery = '<main>'+''.join('<figure><a href="'+html.escape(run.name+'/'+p.name,quote=True)+'"><img loading="lazy" src="'+html.escape(run.name+'/'+p.name,quote=True)+'"></a><figcaption>'+html.escape(p.name)+'</figcaption></figure>' for p in sorted(run.glob('*.png')))+'</main>'
        source_link = ' · <a href="'+html.escape(run.name+'/index.html',quote=True)+'">oorspronkelijke runpagina</a>' if source.is_file() else ''
        body = '<p>Laatste geslaagde opname: '+html.escape(run.name)+source_link+'.</p>'+gallery
    else:
        attempts = [p for p in folder.iterdir() if p.is_dir() and not p.is_symlink()]
        attempt = max(attempts,key=run_order) if attempts else None
        body = '<p>Er zijn nog geen geslaagde beelden voor deze pagina. Maak ze met het commando hierboven.</p>'
        if attempt:
            log = attempt / 'capture.log'
            excerpt = log.read_text(errors='replace')[-5000:] if log.is_file() else 'Geen capturelog beschikbaar.'
            body += '<details><summary>Laatste capturelog</summary><p><a href="'+html.escape(attempt.name+'/capture.log',quote=True)+'">volledig log</a></p><pre>'+html.escape(excerpt)+'</pre></details>'
    document = ('<!doctype html><meta charset="utf-8"><title>'+html.escape(title)+'</title>'
                '<style>body{background:#152333;color:#fff;font:17px system-ui;padding:24px}a{color:#64ddff}main{display:flex;flex-wrap:wrap}figure{margin:12px;width:46%}img{width:100%}pre{white-space:pre-wrap;overflow-wrap:anywhere}</style>'
                '<h1>'+html.escape(title)+'</h1><p><a href="../index.html">Terug naar het renderoverzicht</a></p>'+body)
    return add_commands(document,project=project,step=folder.name)


def update_page(path, renders=RENDERS):
    path = Path(path)
    project, step, audio, historical = page_context(path,renders)
    if path.name == 'index.html' and path.parent.name in STEP_NAMES:
        return step_wrapper(path.parent,project)
    document = path.read_text()
    if step and not historical:
        document = named_document(document,STEP_NAMES[step])
    return add_commands(document,project=project,step=step,audio=audio,historical=historical)


def overview_page(folder, project_level, pending=()):
    folder = Path(folder)
    title = folder.name+' · renderoverzicht' if project_level else 'BoRacer · centrale renders'
    links = []
    for sub in sorted(folder.iterdir()):
        if not sub.is_dir() or sub.is_symlink() or not ((sub/'index.html').is_file() or sub/'index.html' in pending):
            continue
        label = STEP_NAMES.get(sub.name, {'materiaalgeluiden':'Landings- en botsingsgeluiden', 'audio':'Voertuiggeluiden', 'blender-stap-03':'Historische Blender-kledingreview', 'gebouwen-en-objecten':'Gebouwen en objecten in hun omgeving'}.get(sub.name,sub.name))
        links.append('<li><a href="'+html.escape(sub.name+'/index.html',quote=True)+'">'+html.escape(label)+'</a></li>')
    return ('<!doctype html><meta charset="utf-8"><title>'+html.escape(title)+'</title>'
            '<style>body{background:#10223a;color:#edf5ff;font:18px system-ui;padding:32px}a{color:#64ddff}li{margin:18px}</style>'
            '<h1>'+html.escape(title)+'</h1>'+(command_block(folder.name,all_steps=True) if project_level else '')+'<p>Kies een pagina: de laatste geslaagde beelden staan direct bij het eigen maakcommando. Historische Blenderbeelden en offline audio blijven apart gelabeld.</p><ul>'+''.join(links)+'</ul>')


def write_overview_indexes(project, renders=RENDERS):
    (project/'index.html').write_text(overview_page(project,True))
    (renders/'index.html').write_text(overview_page(renders,False))


def refresh_html(renders=RENDERS, check=False):
    renders = Path(renders)
    updates = {p:update_page(p,renders) for p in sorted(renders.rglob('*.html'))}
    for project in renders.iterdir():
        if not project.is_dir() or project.is_symlink(): continue
        for step in project.iterdir():
            if step.is_dir() and step.name in STEP_NAMES:
                updates[step/'index.html'] = step_wrapper(step,project.name)
        if (project/'index.html').is_file():
            updates[project/'index.html'] = overview_page(project,True,updates)
    updates[renders/'index.html'] = overview_page(renders,False,updates)
    changed = 0
    for path,revised in updates.items():
        if not path.is_file() or path.read_text() != revised:
            changed += 1
            if not check: path.write_text(revised)
    return len(updates),changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=RENDERS)
    parser.add_argument('--check',action='store_true',help='Read-only: fail if a page needs updating.')
    args = parser.parse_args()
    count,changed = refresh_html(args.root,args.check)
    print(f'{count} HTML pages checked; {changed} '+('need updating' if args.check else 'updated'))
    return 1 if args.check and changed else 0


if __name__ == '__main__':
    raise SystemExit(main())
