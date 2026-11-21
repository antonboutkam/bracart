#!/usr/bin/env python3
"""Maak vanuit een grafische desktopsessie alle actuele GAME-10001 reviewbeelden."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', default='GAME-10001')
    args = parser.parse_args()
    game = Path(__file__).resolve().parents[1]
    manifest = json.loads((game / 'assets/manifest.json').read_text())
    stage = manifest.get('boaz', {}).get('integration_stage')
    phases = {'costume-step3': 'stap-03-kleding', 'uv-pbr-step4': 'stap-04-materialen',
              'animation-step5': 'stap-05-animatie'}
    steps = ([phases[stage]] if stage in phases else [])
    steps.extend(['stap-06-werelden', 'stap-07-effecten', 'stap-08-interface', 'stap-09-keukentafel', 'stap-10-dashboard', 'stap-11-straatleven', 'stap-12-gebouwen-objecten', 'stap-13-garage-hemel', 'stap-14-vliegtuig', 'stap-15-keuken-avontuur', 'stap-16-vogeltje', 'stap-17-groen-cc0', 'stap-18-racefeedback'])
    audio = subprocess.run([sys.executable, str(game / 'tools/review_material_audio.py'), '--project', args.project])
    if audio.returncode:
        return audio.returncode
    for step in steps:
        result = subprocess.run([sys.executable, str(game / 'tools/capture_step.py'),
                                 '--project', args.project, '--step', step])
        if result.returncode:
            print('Capture gestopt. Bekijk het log in de getoonde runmap. '
                  'Gebruik een grafische desktopsessie; eerdere geslaagde runs blijven bewaard.', file=sys.stderr)
            return result.returncode
    print(f'Alle beelden bewaard onder {game.parent / "renders" / args.project}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
