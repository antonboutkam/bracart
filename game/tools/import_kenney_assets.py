#!/usr/bin/env python3
"""Install only selected CC0 files from pinned official Kenney archives.

Supply the three archives in --archive-dir; downloads are deliberately separate.
The importer never extracts arbitrary archive paths or installs full packs.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import zipfile

BASE = Path(__file__).resolve().parents[1]
PACKS = {
    'nature': ('nature-kit', 'fa7974a0d342bfe63c38664ba9f8ec1a4aab8ea25f099bdc56870e33588c4d9d',
               'https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip',
               {f'Models/GLTF format/{n}.glb': f'nature/{n}.glb' for n in ['tree_oak', 'tree_default', 'plant_bush', 'flower_redA']}),
    'particles': ('particle-pack', 'b631d4b07f7002549fdcf155f01141ad482f79f3440e4e301eed49ce5f1d8958',
                  'https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip',
                  {'PNG (Transparent)/smoke_01.png': 'particles/smoke.png', 'PNG (Transparent)/spark_01.png': 'particles/spark.png'}),
    'impacts': ('impact-sounds', '029d734af1582474edf3a694d1b0cebc97c1c152f2f39fa34d4c2bafc5de77f8',
                'https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip',
                {'Audio/impactWood_light_000.ogg': 'impacts/wood_light.wav',
                 'Audio/impactPlank_medium_000.ogg': 'impacts/wood_plank.wav',
                 'Audio/impactGeneric_light_000.ogg': 'impacts/generic_light.wav',
                 'Audio/impactSoft_medium_000.ogg': 'impacts/soft_medium.wav'}),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive-dir', type=Path, default=Path('/tmp'))
    parser.add_argument('--verify', action='store_true', help='Check installed payload/license hashes without archives')
    args = parser.parse_args()
    destination = BASE / 'assets/third_party/kenney'
    manifest_path = destination / 'manifest.json'
    if args.verify:
        manifest = json.loads(manifest_path.read_text())
        entries = manifest['assets'] + manifest['licenses']
        for entry in entries:
            assert sha((destination / entry['path']).read_bytes()) == entry['sha256'], entry['path']
        print(f'Kenney: {len(entries)} asset/license hashes OK')
        return
    destination.mkdir(parents=True, exist_ok=True)
    manifest = {'author': 'Kenney (www.kenney.nl)', 'license': 'CC0-1.0',
                'license_url': 'https://creativecommons.org/publicdomain/zero/1.0/',
                'attribution_required': False, 'retrieved_date': '2026-10-17',
                'archives': [], 'assets': [], 'licenses': []}
    for key, (slug, expected, url, selection) in PACKS.items():
        archive = args.archive_dir / f'boracer-kenney-{key}.zip'
        payload = archive.read_bytes()
        assert sha(payload) == expected, f'Unexpected archive bytes: {archive}'
        manifest['archives'].append({'pack': slug, 'source': f'https://kenney.nl/assets/{slug}',
                                     'url': url, 'sha256': expected, 'bytes': len(payload)})
        with zipfile.ZipFile(archive) as source:
            license_bytes = source.read('License.txt')
            assert b'Creative Commons Zero' in license_bytes
            license_path = f'licenses/{slug}-License.txt'
            target = destination / license_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(license_bytes)
            manifest['licenses'].append({'path': license_path, 'pack': slug, 'sha256': sha(license_bytes)})
            for member, output in selection.items():
                raw = source.read(member)
                target = destination / output
                target.parent.mkdir(parents=True, exist_ok=True)
                changes = 'none; original bytes, filename may differ'
                if output.endswith('.wav'):
                    with tempfile.NamedTemporaryFile(suffix='.ogg') as temporary:
                        temporary.write(raw)
                        temporary.flush()
                        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', temporary.name,
                                        '-map_metadata', '-1', '-c:a', 'pcm_s16le', '-ar', '44100',
                                        '-ac', '1', str(target)], check=True)
                    changes = 'OGG decoded to mono PCM16 WAV 44100 Hz; no EQ/gain/trim'
                else:
                    target.write_bytes(raw)
                manifest['assets'].append({'path': output, 'pack': slug, 'member': member,
                                           'source_sha256': sha(raw), 'sha256': sha(target.read_bytes()),
                                           'bytes': target.stat().st_size, 'changes': changes})
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Installed {len(manifest["assets"])} selected assets and 3 original licenses')


if __name__ == '__main__':
    main()
