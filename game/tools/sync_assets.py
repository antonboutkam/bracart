#!/usr/bin/env python3
"""Snapshot finished GLBs without writing into the asset authors' workspaces."""
import argparse
import hashlib
import json
import shutil
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / 'game'
VEHICLES = ['raketfiets', 'purple-passion', 'golden-rocket-racer', 'toxic-turbo', 'retro', 'rainbow']

def copy_glb(source, destination):
    data = source.read_bytes()
    magic, version, size = struct.unpack_from('<4sII', data)
    if magic != b'glTF' or version != 2 or size != len(data):
        raise ValueError(f'Incomplete GLB: {source}')
    json_size, _ = struct.unpack_from('<II', data, 12)
    document = json.loads(data[20:20 + json_size])
    if any('uri' in item and not item['uri'].startswith('data:')
           for key in ('buffers', 'images') for item in document.get(key, [])):
        raise ValueError(f'External resources: {source}')
    destination.write_bytes(data)
    return {'source': str(source.relative_to(ROOT)), 'sha256': hashlib.sha256(data).hexdigest(),
            'materials': len(document.get('materials', []))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vehicles', nargs='+', choices=VEHICLES,
                        help='Finished models; default: retain current approved list, initially retro')
    args = parser.parse_args()
    manifest = {}
    previous_path = GAME / 'assets/manifest.json'
    previous = json.loads(previous_path.read_text()) if previous_path.exists() else {}
    chosen = args.vehicles or [name for name in VEHICLES if previous.get(name, {}).get('playable')] or ['retro']
    for name in chosen:
        folder = ROOT / 'vehicles' / name
        improved = folder / f'{name}-improved.glb'
        source = improved if improved.exists() else folder / f'{name}.glb'
        manifest[name] = copy_glb(source, GAME / 'assets/models' / f'{name}.glb')
        manifest[name]['playable'] = True
    for name in ['boaz', 'ravi']:
        manifest[name] = copy_glb(ROOT / 'persons' / name / f'{name}.glb', GAME / 'assets/models' / f'{name}.glb')
    artwork = {'logo.png': 'logo.png', 'tracks/sweer-impressie-baan.png': 'sunset.png',
               'user-interface/store-interface.png': 'garage.png'}
    for world in ['regenbogenrijk', 'haarlem-1888', 'uithoorn-2056', 'keukentafel']:
        artwork[f'worlds/{world}/{world}.png'] = f'{world}.png'
    for source, target in artwork.items():
        shutil.copyfile(ROOT / source, GAME / 'assets/ui' / target)
    # Remove only snapshots managed by the previous manifest, never source files.
    for name in previous:
        if name in VEHICLES and name not in chosen:
            files = [GAME / 'assets/models' / f'{name}.glb',
                     GAME / 'assets/models' / f'{name}.glb.import']
            files.extend((GAME / 'assets/models').glob(f'{name}_*.png*'))
            for path in files:
                path.unlink(missing_ok=True)
    (GAME / 'assets/manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Copied {len(chosen)} finished vehicle(s), 2 provisional drivers and 7 images. Sources unchanged.')

if __name__ == '__main__':
    main()
