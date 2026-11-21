#!/usr/bin/env python3
"""Validate supplied voxel monsters, then copy a portable snapshot into the game."""
import hashlib
import json
import re
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/monters/monster-blokjes-10/json"
DEST = ROOT / "game/assets/monsters"
NEIGHBORS = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]


def main():
    snapshots = []
    for path in sorted(SOURCE.glob("*.json")):
        raw = path.read_bytes()
        data = json.loads(raw)
        assert data["id"] == path.stem and re.fullmatch(r"[a-z0-9-]+", data["id"]), path
        assert isinstance(data["name"], str) and data["name"].strip(), path
        blocks = data["blocks"]
        assert 1 <= len(blocks) <= 6000, path
        cells = set()
        for block in blocks:
            assert all(type(block[k]) is int and abs(block[k]) <= 64 for k in ("x", "y", "z")), path
            assert block["y"] >= 0 and re.fullmatch(r"#[A-Fa-f0-9]{6}", block["color"]), path
            cell = tuple(block[k] for k in ("x", "y", "z"))
            assert cell not in cells, (path, "duplicate", cell)
            cells.add(cell)
        reached = {cell for cell in cells if cell[1] == 0}
        queue = deque(reached)
        while queue:
            cell = queue.popleft()
            for direction in NEIGHBORS:
                neighbor = tuple(a + b for a, b in zip(cell, direction))
                if neighbor in cells and neighbor not in reached:
                    reached.add(neighbor)
                    queue.append(neighbor)
        assert reached == cells, (path, "unsupported blocks")
        info = {
            "id": data["id"], "name": data["name"], "blocks": len(blocks),
            "dimensions": [max(c[i] for c in cells) - min(c[i] for c in cells) + 1 for i in range(3)],
            "source": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(raw).hexdigest(),
        }
        snapshots.append((path.name, raw, info))
    assert len(snapshots) == 10, "Expected the ten supplied monsters; check the source directory."
    DEST.mkdir(parents=True, exist_ok=True)
    for name, raw, _ in snapshots:
        (DEST / name).write_bytes(raw)
    (DEST / "catalog.json").write_text(json.dumps([info for _, _, info in snapshots], indent=2) + "\n")
    print(f"Copied {len(snapshots)} validated monsters; source files unchanged.")


if __name__ == "__main__":
    main()
