"""Independent GLB regression audit: hair-only changes must preserve step 1.

Usage: python3 check_character_hair_scope.py BASELINE.glb CANDIDATE.glb [--output report.json]
No Blender modules or third-party packages; never modifies the assets.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import struct


class GLB:
    def __init__(self, path):
        self.path = Path(path)
        raw = self.path.read_bytes()
        self.sha256 = hashlib.sha256(raw).hexdigest()
        assert struct.unpack_from('<4sII', raw) == (b'glTF', 2, len(raw))
        chunks = {}
        offset = 12
        while offset < len(raw):
            size, kind = struct.unpack_from('<II', raw, offset)
            offset += 8
            chunks[kind] = raw[offset:offset + size]
            offset += size
        self.doc = json.loads(chunks[0x4E4F534A])
        self.binary = chunks[0x004E4942]
        self.cache = {}

    def unpack(self, view_index, offset, component_type, width, count):
        view = self.doc['bufferViews'][view_index]
        assert view.get('buffer', 0) == 0
        fmt = '<' + {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}[component_type] * width
        stride = view.get('byteStride', struct.calcsize(fmt))
        start = view.get('byteOffset', 0) + offset
        return [struct.unpack_from(fmt, self.binary, start + i * stride) for i in range(count)]

    def acc(self, index):
        if index in self.cache:
            return self.cache[index]
        accessor = self.doc['accessors'][index]
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT2': 4, 'MAT3': 9, 'MAT4': 16}[accessor['type']]
        component_type = accessor['componentType']
        data = self.unpack(accessor['bufferView'], accessor.get('byteOffset', 0), component_type, width, accessor['count']) if 'bufferView' in accessor else [(0,) * width] * accessor['count']
        if 'sparse' in accessor:
            sparse = accessor['sparse']
            indices, values = sparse['indices'], sparse['values']
            ix = self.unpack(indices['bufferView'], indices.get('byteOffset', 0), indices['componentType'], 1, sparse['count'])
            val = self.unpack(values['bufferView'], values.get('byteOffset', 0), component_type, width, sparse['count'])
            for i, v in zip(ix, val):
                data[i[0]] = v
        if accessor.get('normalized') and component_type != 5126:
            divisor = {5120: 127, 5121: 255, 5122: 32767, 5123: 65535, 5125: 4294967295}[component_type]
            data = [tuple(max(-1, v / divisor) for v in row) for row in data]
        assert all(math.isfinite(v) for row in data for v in row), 'Non-finite accessor values'
        self.cache[index] = data
        return data

    def node_name(self, index):
        return self.doc['nodes'][index].get('name', str(index))

    def node_transforms(self):
        return {self.node_name(i): {k: n[k] for k in ('translation', 'rotation', 'scale', 'matrix', 'weights') if k in n} for i, n in enumerate(self.doc['nodes'])}

    def rig(self):
        skins = []
        for skin in self.doc.get('skins', []):
            joints = skin['joints']
            nodes = []
            for i in joints:
                n = self.doc['nodes'][i]
                nodes.append({k: n[k] for k in ('name', 'translation', 'rotation', 'scale', 'matrix') if k in n} | {'children': [self.node_name(c) for c in n.get('children', [])]})
            skins.append({'joints': nodes, 'inverse_bind_matrices': self.acc(skin['inverseBindMatrices'])})
        return skins

    def animations(self):
        result = {}
        for animation in self.doc.get('animations', []):
            channels = []
            for channel in animation['channels']:
                sampler = animation['samplers'][channel['sampler']]
                target = channel['target']
                channels.append((self.node_name(target['node']), target['path'], sampler.get('interpolation', 'LINEAR'), self.acc(sampler['input']), self.acc(sampler['output'])))
            result[animation['name']] = sorted(channels, key=lambda x: x[:2])
        return result

    def images(self):
        result = []
        for image in self.doc.get('images', []):
            view = self.doc['bufferViews'][image['bufferView']]
            start = view.get('byteOffset', 0)
            result.append(hashlib.sha256(self.binary[start:start + view['byteLength']]).hexdigest())
        return result

    def triangles(self):
        groups = {'hair': Counter(), 'non_hair': Counter()}
        hair_edges = Counter()
        head_weight_errors = 0
        bounds = [[], [], []]
        morph_names = []
        degenerate = 0
        skin = self.doc['skins'][0]
        joint_names = [self.node_name(i) for i in skin['joints']]
        for mesh in self.doc['meshes']:
            morph_names.append(mesh.get('extras', {}).get('targetNames', []))
            for primitive in mesh['primitives']:
                assert primitive.get('mode', 4) == 4
                attrs = {k: self.acc(v) for k, v in primitive['attributes'].items()}
                targets = [{k: self.acc(v) for k, v in t.items()} for t in primitive.get('targets', [])]
                indices = [v[0] for v in self.acc(primitive['indices'])] if 'indices' in primitive else list(range(len(attrs['POSITION'])))
                for p in attrs['POSITION']:
                    for axis in range(3):
                        bounds[axis].append(p[axis])
                signatures = []
                for i in range(len(attrs['POSITION'])):
                    record = []
                    for key in sorted(attrs):
                        values = attrs[key][i]
                        if key == 'JOINTS_0':
                            record.append((key, tuple(joint_names[int(v)] for v in values)))
                        else:
                            # Rounded export floats, 0.1 micrometre for position/morph.
                            record.append((key, tuple(round(float(v), 7) for v in values)))
                    record.extend((str(j), tuple((k, tuple(round(float(v), 7) for v in t[k][i])) for k in sorted(t))) for j, t in enumerate(targets))
                    signatures.append(hashlib.sha256(repr(record).encode()).hexdigest())
                for start in range(0, len(indices), 3):
                    tri = indices[start:start + 3]
                    tiles = {min(7, int(attrs['TEXCOORD_0'][i][0] * 8)) + 8 * min(7, int((1 - attrs['TEXCOORD_0'][i][1]) * 8)) for i in tri}
                    assert len(tiles) == 1, 'Triangle crosses palette tiles'
                    hair = next(iter(tiles)) in (3, 4, 5)
                    group = 'hair' if hair else 'non_hair'
                    vertex_hashes = [signatures[i] for i in tri]
                    canonical = min(tuple(vertex_hashes[j:] + vertex_hashes[:j]) for j in range(3))
                    groups[group][canonical] += 1
                    p = [attrs['POSITION'][i] for i in tri]
                    u, v = [[p[j][a] - p[0][a] for a in range(3)] for j in (1, 2)]
                    cross = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
                    if sum(x*x for x in cross) < 1e-24:
                        degenerate += 1
                    if hair:
                        pts = [tuple(round(x, 6) for x in pt) for pt in p]
                        for a, b in zip(pts, pts[1:] + pts[:1]):
                            hair_edges[tuple(sorted((a, b)))] += 1
                        for i in tri:
                            joints = attrs['JOINTS_0'][i]
                            weights = attrs['WEIGHTS_0'][i]
                            if any(joint_names[int(j)] != 'head' and w > 1e-5 for j, w in zip(joints, weights)):
                                head_weight_errors += 1
        return {'groups': groups, 'hair_boundary_edges': sum(v == 1 for v in hair_edges.values()), 'hair_nonmanifold_edges': sum(v > 2 for v in hair_edges.values()), 'hair_head_weight_errors': head_weight_errors, 'bounds': [[min(axis), max(axis)] for axis in bounds], 'degenerate_triangles': degenerate, 'morph_names': morph_names}


def audit(baseline, candidate):
    before, after = GLB(baseline), GLB(candidate)
    a, b = before.triangles(), after.triangles()
    checks = {
        'non_hair_geometry_normals_uv_weights_morphs_unchanged': a['groups']['non_hair'] == b['groups']['non_hair'],
        'rig_and_inverse_bind_matrices_unchanged': before.rig() == after.rig(),
        'all_node_transforms_unchanged': before.node_transforms() == after.node_transforms(),
        'all_animation_payloads_unchanged': before.animations() == after.animations(),
        'embedded_images_unchanged': before.images() == after.images(),
        'materials_unchanged': before.doc['materials'] == after.doc['materials'],
        'morph_names_unchanged': a['morph_names'] == b['morph_names'],
        'morph_default_weights_unchanged': [m.get('weights', []) for m in before.doc['meshes']] == [m.get('weights', []) for m in after.doc['meshes']],
        'hair_weighted_to_head': b['hair_head_weight_errors'] == 0,
        'hair_geometry_changed': a['groups']['hair'] != b['groups']['hair'],
    }
    def summary(data):
        return {k: v for k, v in data.items() if k != 'groups'} | {'triangles': sum(sum(v.values()) for v in data['groups'].values()), 'non_hair_triangles': sum(data['groups']['non_hair'].values()), 'hair_palette_triangles': sum(data['groups']['hair'].values())}
    return {'baseline': str(baseline), 'candidate': str(candidate), 'baseline_sha256': before.sha256, 'candidate_sha256': after.sha256, 'vertex_attribute_decimal_precision': 7, 'checks': checks, 'passed': all(checks.values()), 'before': summary(a), 'after': summary(b), 'non_hair_triangles_removed_or_changed': sum((a['groups']['non_hair'] - b['groups']['non_hair']).values()), 'non_hair_triangles_added_or_changed': sum((b['groups']['non_hair'] - a['groups']['non_hair']).values()), 'hair_palette_triangles_retained_exactly': sum((a['groups']['hair'] & b['groups']['hair']).values()), 'limitations': ['Hair palette includes eyebrows/lashes, so their identity needs visual review.', 'Topology edges are welded by rounded position; overlapping components can share edges. Boundary/nonmanifold counts are descriptive, not a watertightness certificate.', 'No visual quality, intersection, Godot runtime or motion quality claim.']}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = audit(args.baseline, args.candidate)
    text = json.dumps(report, indent=2) + '\n'
    if args.output:
        args.output.write_text(text)
    print(text, end='')
    raise SystemExit(0 if report['passed'] else 1)
