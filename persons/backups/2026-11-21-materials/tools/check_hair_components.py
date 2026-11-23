"""Audit generated hair component topology without Blender or asset mutation.

Checks every component independently: edge incidence, winding, finite vertices,
positive signed volume and head attachment. Intersections are not tested.
"""
import argparse
from collections import Counter
import json
import math
from pathlib import Path

from character_hair import build_hair


def inspect_character(character):
    components = []

    def inspect(name, vertices, faces, color, bone):
        edges, oriented = Counter(), Counter()
        volume = 0.
        for face in faces:
            for a, b in zip(face, face[1:] + face[:1]):
                edges[tuple(sorted((a, b)))] += 1
                oriented[(a, b)] += 1
            for j in range(1, len(face) - 1):
                a, b, c = [vertices[i] for i in (face[0], face[j], face[j + 1])]
                volume += (a[0]*(b[1]*c[2]-b[2]*c[1]) + a[1]*(b[2]*c[0]-b[0]*c[2]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6
        checks = {
            'head_attachment': bone == 'head',
            'finite_vertices': all(math.isfinite(v) for p in vertices for v in p),
            'closed_manifold_edges': all(n == 2 for n in edges.values()),
            'consistent_winding': all(oriented[(a, b)] == oriented[(b, a)] for a, b in edges),
            'positive_signed_volume': volume > 1e-12,
        }
        components.append({'name': name, 'vertices': len(vertices), 'triangles': sum(len(f) - 2 for f in faces), 'signed_volume': volume, 'checks': checks})
        return name

    build_hair(character, inspect)
    return {'character': character, 'passed': all(all(c['checks'].values()) for c in components), 'triangles': sum(c['triangles'] for c in components), 'components': components, 'limitations': ['Checks generator output, not exported/imported GLB.', 'Closed components can overlap or self-intersect; visual review remains necessary.']}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    reports = [inspect_character(c) for c in ('boaz', 'ravi')]
    text = json.dumps(reports, indent=2) + '\n'
    if args.output:
        args.output.write_text(text)
    for report in reports:
        print(report['character'], 'PASS' if report['passed'] else 'FAIL', len(report['components']), 'components,', report['triangles'], 'triangles')
    raise SystemExit(0 if all(r['passed'] for r in reports) else 1)
