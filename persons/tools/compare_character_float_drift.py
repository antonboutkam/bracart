"""Measure actual float drift when hair-only GLB hashes differ.

Matches non-hair triangles by coarse geometry then checks every actual vertex
attribute and morph value. Coarse buckets never imply acceptance themselves.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path

from check_character_hair_scope import GLB


def triangles(g):
    groups = defaultdict(list)
    for mesh in g.doc['meshes']:
        for p in mesh['primitives']:
            attrs = {k: g.acc(v) for k, v in p['attributes'].items()}
            for j, target in enumerate(p.get('targets', [])):
                attrs.update({f'morph_{j}_{k}': g.acc(v) for k, v in target.items()})
            indices = [v[0] for v in g.acc(p['indices'])]
            for start in range(0, len(indices), 3):
                ids = indices[start:start + 3]
                uv = attrs['TEXCOORD_0'][ids[0]]
                tile = int(uv[0] * 8) + 8 * int((1 - uv[1]) * 8)
                if tile in (3, 4, 5):
                    continue
                positions = [tuple(round(v, 5) for v in attrs['POSITION'][i]) for i in ids]
                offset = min(range(3), key=lambda j: tuple(positions[j:] + positions[:j]))
                ids = ids[offset:] + ids[:offset]
                key = (tile, tuple(positions[offset:] + positions[:offset]))
                groups[key].append((ids, attrs))
    return groups


def compare(baseline, candidate):
    a, b = GLB(baseline), GLB(candidate)
    first, second = triangles(a), triangles(b)
    maximum = defaultdict(float)
    drifted_triangles = 0
    unmatched = sum(len(v) for k, v in first.items() if k not in second)
    unmatched += sum(len(v) for k, v in second.items() if k not in first)
    for key in first.keys() & second.keys():
        left, right = first[key], second[key].copy()
        unmatched += abs(len(left) - len(right))
        for ids, attrs in left:
            if not right:
                break
            # Repeated overlapping surfaces are disambiguated with actual UVs.
            best = min(range(len(right)), key=lambda j: sum(abs(x-y) for i, k in zip(ids, right[j][0]) for semantic in ('POSITION', 'TEXCOORD_0') for x, y in zip(attrs[semantic][i], right[j][1][semantic][k])))
            other_ids, other_attrs = right.pop(best)
            assert attrs.keys() == other_attrs.keys()
            changed = False
            for semantic in attrs:
                delta = max(abs(x-y) for i, j in zip(ids, other_ids) for x, y in zip(attrs[semantic][i], other_attrs[semantic][j]))
                maximum[semantic] = max(maximum[semantic], delta)
                changed |= delta > 0
            drifted_triangles += changed
    tolerances = {k: (0 if k.startswith('JOINTS') else 1e-4 if 'NORMAL' in k or 'TANGENT' in k else 1e-7) for k in maximum}
    return {'baseline': str(baseline), 'candidate': str(candidate), 'baseline_sha256': a.sha256, 'candidate_sha256': b.sha256, 'unmatched_triangles': unmatched, 'triangles_with_any_float_drift': drifted_triangles, 'maximum_absolute_delta_by_attribute': dict(maximum), 'allowed_absolute_delta_by_attribute': tolerances, 'passed_with_measured_export_float_tolerance': unmatched == 0 and all(delta <= tolerances[k] for k, delta in maximum.items()), 'interpretation': 'Supplement to strict scope audit; does not claim bit-identical geometry. Position and UV/morph limit 1e-7; normal/tangent vector components 1e-4; joint indices exact. Matching checks every actual value after spatial grouping.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = compare(args.baseline, args.candidate)
    text = json.dumps(report, indent=2) + '\n'
    if args.output:
        args.output.write_text(text)
    print(text, end='')
    raise SystemExit(0 if report['passed_with_measured_export_float_tolerance'] else 1)
