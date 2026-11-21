#!/usr/bin/env python3
"""Copy the reviewed Gifspuwer and derive convex clipping planes without dependencies."""
import hashlib
import itertools
import json
import math
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/monters/gifspuwer-monsterbreker-test"
DEST = ROOT / "game/assets/monsters/gifspuwer-breekbaar"


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def planes_for(points):
    planes = {}
    for a, b, c in itertools.combinations(points, 3):
        u, v = sub(b, a), sub(c, a)
        n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        length = math.sqrt(dot(n, n))
        if length < 1e-9:
            continue
        n = tuple(x / length for x in n)
        d = dot(n, a)
        distances = [dot(n, point) - d for point in points]
        if max(distances) > 1e-6 and min(distances) < -1e-6:
            continue
        if max(distances) > 1e-6:
            n, d = tuple(-x for x in n), -d
        # Enclose every source point, including floating-point export noise.
        d = max(dot(n, point) for point in points)
        plane = (*n, d)
        planes[tuple(round(x, 6) for x in plane)] = plane
    assert len(planes) >= 4, "Collider must span a closed 3D convex volume"
    return list(planes.values())


def main():
    data = json.loads((SOURCE / "breekstukken.json").read_text())
    pieces = {piece["id"]: piece for piece in data["pieces"]}
    assert len(pieces) == len(data["pieces"]) == 76
    assert data["up"] == "+Y" and data["front"] == "+Z" and data["units"] == "m"
    assert math.isclose(sum(p["scoreWeight"] for p in pieces.values()), 1.0)
    hulls = {}
    for name, piece in pieces.items():
        assert name == piece["node"] and piece["scoreWeight"] > 0
        assert piece["collider"]["type"] == "convexHull"
        points = piece["collider"]["points"]
        assert 4 <= len(points) <= 64
        assert all(len(p) == 3 and all(math.isfinite(x) for x in p) for p in points)
        for neighbor in piece["neighbors"]:
            assert neighbor != name and name in pieces[neighbor]["neighbors"]
        hulls[name] = planes_for(points)
    reached = {name for name, piece in pieces.items() if piece["grounded"]}
    queue = list(reached)
    for name in queue:
        for neighbor in pieces[name]["neighbors"]:
            if neighbor not in reached:
                reached.add(neighbor)
                queue.append(neighbor)
    assert reached == pieces.keys(), "Unsupported pieces in source"
    DEST.mkdir(parents=True, exist_ok=True)
    for name in ("gifspuwer-breekbaar.glb", "breekstukken.json"):
        shutil.copyfile(SOURCE / name, DEST / name)
    derived = {
        "source_sha256": hashlib.sha256((SOURCE / "breekstukken.json").read_bytes()).hexdigest(),
        "planes": hulls,
    }
    (DEST / "collision-planes.json").write_text(json.dumps(derived, separators=(",", ":")) + "\n")
    print(f"Copied Gifspuwer: {len(pieces)} pieces, {sum(map(len, hulls.values()))} convex planes; source unchanged.")


if __name__ == "__main__":
    main()
