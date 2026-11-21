#!/usr/bin/env python3
"""Publiceer één bevroren karakterfase en maak daarna automatisch Godot-beelden."""
import argparse
import datetime as dt
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from sync_assets import copy_glb

PHASES = {3: ('stap-03-kleding', 'costume-step3'),
          4: ('stap-04-materialen', 'uv-pbr-step4'),
          5: ('stap-05-animatie', 'animation-step5')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--step', type=int, choices=PHASES, required=True)
    parser.add_argument('--project', default='GAME-10001')
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--defer-capture', action='store_true',
                        help='Importeer zonder native capture wanneer de displaysocket aantoonbaar geblokkeerd is; beeldreview blijft open.')
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,79}', args.project):
        parser.error('project must be a plain directory name')
    # Alle controlebeelden en lokale tests gebruiken uitsluitend tijdelijk spelprofiel.
    manifest_path = GAME / 'assets/manifest.json'
    manifest = json.loads(manifest_path.read_text())
    snapshots = {}
    for name in ('boaz', 'ravi'):
        source = ROOT / f'persons/{name}/review-step{args.step}/after/{name}.glb'
        live = ROOT / f'persons/{name}/{name}.glb'
        if not source.is_file() or source.read_bytes() != live.read_bytes():
            parser.error(f'Bevroren fase ontbreekt of wijkt af van gecontroleerde bron: {source}')
        snapshots[name] = source
    with tempfile.TemporaryDirectory(prefix='boracer-publish-') as temporary:
        tmp = Path(temporary)
        prepared = {}
        for name, source in snapshots.items():
            prepared[name] = copy_glb(source, tmp / f'{name}.glb')
        run = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S-%fZ')
        backup = GAME / 'validation/backups' / args.project / f'character-step{args.step}' / run
        backup.mkdir(parents=True, exist_ok=False)
        shutil.copyfile(manifest_path, backup / 'manifest.json')
        for name in snapshots:
            shutil.copyfile(GAME / f'assets/models/{name}.glb', backup / f'{name}.glb')
        for name in snapshots:
            target = GAME / f'assets/models/{name}.glb'
            staged = target.with_suffix('.glb.new')
            shutil.copyfile(tmp / f'{name}.glb', staged)
            staged.replace(target)
            manifest[name] = dict(prepared[name], integration_stage=PHASES[args.step][1],
                                  visual_review='pending klant; zie centrale fasebeelden')
        staged_manifest = manifest_path.with_suffix('.json.new')
        staged_manifest.write_text(json.dumps(manifest, indent=2) + '\n')
        staged_manifest.replace(manifest_path)
        env = dict(os.environ)
        env.update({f'XDG_{key}_HOME': str(tmp / key.lower()) for key in ('CACHE', 'CONFIG', 'DATA')})
        print(f'Bronnen bevroren; vorige gamekopieën bewaard: {backup}', flush=True)
        command = [args.godot, '--headless', '--audio-driver', 'Dummy', '--path', str(GAME), '--import']
        with (backup / 'import.log').open('w') as log:
            imported = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT)
        if imported.returncode:
            print(f'Godot-import mislukt. Bekijk {backup / "import.log"}; vorige assets blijven in backup.', file=sys.stderr)
            return imported.returncode
        if args.defer_capture:
            print('Godot-import geslaagd; native beeldreview uitgesteld. '
                  'Voer tools/capture_review.py uit vanuit een grafische desktopsessie.', flush=True)
            return 0
        # Verplichte enginebeelden na iedere gepubliceerde fase; geen screenshots nabootsen.
        return subprocess.run([sys.executable, str(GAME / 'tools/capture_step.py'),
                               '--project', args.project, '--step', PHASES[args.step][0],
                               '--godot', args.godot], env=env).returncode


if __name__ == '__main__':
    sys.exit(main())
