#!/usr/bin/env python3
"""Build an offline listening page for the selected CC0 material sounds."""
import argparse
import html
import os
from pathlib import Path
import re
import wave
from render_commands import update_page, write_overview_indexes

GAME = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', default='GAME-10001')
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,79}', args.project):
        parser.error('project must be a plain directory name')
    folder = GAME.parent / 'renders' / args.project / 'materiaalgeluiden'
    folder.mkdir(parents=True, exist_ok=True)
    cards = []
    for key, label in [('wood_light', 'Hout: lichte landing'), ('wood_plank', 'Karton: gekozen plankgeluid'), ('soft_medium', 'Plastic: gekozen zachte impact'), ('generic_light', 'Asfalt: korte tik')]:
        source = GAME / 'assets/third_party/kenney/impacts' / (key+'.wav')
        with wave.open(str(source)) as clip:
            assert clip.getnchannels()==1 and clip.getsampwidth()==2
            duration = clip.getnframes()/clip.getframerate()
        link = html.escape(os.path.relpath(source, folder), quote=True)
        cards.append(f'<section><h2>{html.escape(label)}</h2><audio controls preload="none" src="{link}"></audio><p>{duration:.3f} seconden · mono PCM16</p></section>')
    page = folder / 'index.html'
    page.write_text('<!doctype html><meta charset="utf-8"><title>Landings- en botsingsgeluiden</title>'
        '<style>body{background:#10223a;color:#edf5ff;font:18px system-ui;padding:28px;max-width:1100px;margin:auto}a{color:#64ddff}section{margin:24px 0}audio{width:min(100%,600px)}</style>'
        '<h1>Landings- en botsingsgeluiden</h1><p><a href="../index.html">Terug naar het renderoverzicht</a></p>'
        '<p>Geselecteerde Kenney Impact Sounds, CC0. Dit zijn bronclips voor de gekozen spelmaterialen, geen opgenomen gameplaymix. Karton en plastic gebruiken een gekozen plank-/zachte impact; de maker benoemt die niet als karton of plastic.</p>'
        '<p><a href="https://kenney.nl/assets/impact-sounds">Bron en licentie</a></p>'+''.join(cards))
    page.write_text(update_page(page))
    write_overview_indexes(folder.parent)
    print(page)


if __name__ == '__main__':
    main()
