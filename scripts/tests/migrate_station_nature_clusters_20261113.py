"""Bounded authored nature relocation; all real object facts move with the tile.

Default: plan only. --apply writes the two maps and an invertible audit.
--check reconstructs the recorded inputs and proves a deterministic replay.
No Godot execution, gameplay RNG, rendering override or new map metadata.
"""
import argparse
from collections import Counter, deque
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "docs/qa/review_completion_20261113"
AUDIT = QA / "station_nature_clusters.json"
REVISION = "station_nature_clusters_v1"
NATURE = {"nature_rock_cover", "nature_tree_blocker"}
OBJECT_FACTS = {"walkable", "blocks_los", "cover_value", "object_height",
                "object_type_id", "object_rotation_degrees", "object_scale"}
MAX_DISTANCE = 6
DIRECTIONS = ((1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1))
spec = importlib.util.spec_from_file_location("station_coordinates", Path(__file__).with_name("migrate_station_warehouse_layout_20261113.py"))
coordinates = importlib.util.module_from_spec(spec)
spec.loader.exec_module(coordinates)


def cell(tile):
    return int(tile["grid_position"]["x"]), int(tile["grid_position"]["y"])


def distance(a, b):
    q, r = a[0]-b[0], a[1]-b[1]
    return max(abs(q), abs(r), abs(q+r))


def disk(center, radius):
    return {(center[0]+q, center[1]+r) for q in range(-radius, radius+1)
            for r in range(-radius, radius+1) if max(abs(q), abs(r), abs(q+r)) <= radius}


def encoded(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def digest(value):
    return hashlib.sha256(encoded(value)).hexdigest()


def rank(*parts):
    return int(hashlib.sha256(encoded([REVISION, *parts])).hexdigest()[:16], 16)


def substrate(tile):
    return {k: v for k, v in tile.items() if k not in OBJECT_FACTS and k != "grid_position"}


def free(tile):
    return (not tile.get("object_type_id") and tile.get("walkable") is True
            and tile.get("blocks_los") is False and tile.get("cover_value", 0) == 0
            and tile.get("object_height", 0) == 0)


def payloads(data):
    return Counter(digest({k: v for k, v in t.items() if k != "grid_position"}) for t in data["tiles"])


def pipe_cells(map_path):
    removal = json.loads((QA / "station_pipe_removal.json").read_text(encoding="utf-8"))
    outer = json.loads((QA / "station_outer_layout_migration.json").read_text(encoding="utf-8"))
    original = {tuple(v["grid"]) for r in removal["maps"] if r["map"] == map_path for v in r["removed_cells"]}
    mapping = {tuple(v["from"]): tuple(v["to"]) for r in outer["maps"] if r["map"] == map_path for v in r["moved_cells"]}
    assert original, ("missing pipe provenance", map_path)
    return original | {mapping.get(p, p) for p in original}


def protected_cells(data, map_path):
    protected = set()
    def protect(points, radius):
        for p in points: protected.update(disk(p, radius))
    # Keep modules, floors, slopes, height boundaries and their access margins.
    for tile in data["tiles"]:
        kind = tile.get("type_id", "")
        obj = tile.get("object_type_id", "")
        if (tile.get("edge_type") != "none" or tile.get("ramp_direction", -1) != -1
                or "floor" in kind or obj and obj not in NATURE):
            protect([cell(tile)], 2)
    for prop in data["place_presentation"].get("props", []):
        protect([tuple(int(v) for v in p) for p in prop.get("reserved_grids", [])], 3)
    authoring = data["place_presentation"].get("building_authoring", {})
    protect([tuple(int(v) for v in key.split(",")) for key in authoring.get("base_tiles", {})], 3)
    markers = {name: coordinates.grid_of(p, data) for name, p in data.get("markers", {}).items()}
    protect(markers.values(), 4)
    def corridor(a, b, radius):
        # Conservative complete hex geodesic corridor, not a new runtime pathfinder.
        length = distance(a, b)
        for q in range(min(a[0], b[0])-radius, max(a[0], b[0])+radius+1):
            for r in range(min(a[1], b[1])-radius, max(a[1], b[1])+radius+1):
                p = q, r
                if distance(a, p)+distance(p, b) <= length+2*radius: protected.add(p)
    for points in data.get("patrol_paths", {}).values():
        grids = [coordinates.grid_of(p, data) for p in points]
        protect(grids, 3)
        for a, b in zip(grids, grids[1:]+grids[:1]): corridor(a, b, 2)
    if "station_entry_door" in markers:
        for name in ("spawn_alpha", "spawn_bravo", "approach_guard_post", "objective_point"):
            if name in markers: corridor(markers[name], markers["station_entry_door"], 3)
    pipes = pipe_cells(map_path)
    protect(pipes, 1)
    return protected, pipes


def ring_stays_connected(target, tiles, blocked):
    # Conservative flat-ground test: never obstruct a local narrow passage.
    around = disk(target, 2)
    level = tiles[target]["height_level"]
    usable = {p for p in around if p in tiles and p not in blocked and p != target
              and tiles[p]["height_level"] == level and tiles[p].get("edge_type") == "none"}
    neighbors = {p for p in disk(target, 1)-{target} if p in usable}
    if len(neighbors) < 3: return False
    visited = {min(neighbors)}
    queue = deque(visited)
    while queue:
        q, r = queue.popleft()
        for dq, dr in DIRECTIONS:
            p = q+dq, r+dr
            if p in usable and p not in visited:
                visited.add(p)
                queue.append(p)
    return neighbors <= visited


def migrate(data, map_path):
    assert data["grid_topology"] == "hex_axial_v1"
    assert data["place_presentation"]["station_module_layout"]["ensembles_revision"] == "all_station_ensembles_v1"
    tiles = {cell(t): t for t in data["tiles"]}
    protected, pipes = protected_cells(data, map_path)
    nature = {p for p, t in tiles.items() if t.get("object_type_id") in NATURE}
    eligible = {p for p in nature if p not in protected and tiles[p].get("edge_type") == "none"
                and "floor" not in tiles[p]["type_id"] and tiles[p].get("ramp_direction", -1) == -1}
    remaining = set(eligible)
    occupied = set(nature)
    blocked = {p for p, t in tiles.items() if not t.get("walkable", False)}
    used = set()
    moves = []
    cluster = 0
    for seed in sorted(eligible, key=lambda p: rank(map_path, p)):
        if seed not in remaining: continue
        nearby = [p for p in remaining-{seed} if distance(seed, p) <= 8 and substrate(tiles[p]) == substrate(tiles[seed])]
        nearby.sort(key=lambda p: (distance(seed, p), rank(map_path, seed, p)))
        group = [seed]+nearby[:1+rank(map_path, "size", seed)%2]
        remaining.difference_update(group)
        selected = []
        for origin in group:
            candidates = [p for p in disk(origin, MAX_DISTANCE) if p in tiles and p not in protected
                          and p not in used and p not in nature and free(tiles[p])
                          and substrate(tiles[p]) == substrate(tiles[origin])
                          and all(distance(p, other) >= 2 for other in occupied-set(group))
                          and all(distance(p, other) >= 2 for _, other in selected)]
            if selected:
                candidates = [p for p in candidates if 2 <= distance(p, selected[0][1]) <= 4]
                candidates.sort(key=lambda p: (abs(distance(p, selected[0][1])-3), rank(map_path, origin, p)))
            else:
                candidates.sort(key=lambda p: (abs(distance(p, origin)-3), rank(map_path, origin, p)))
            for target in candidates:
                current_blocks = (blocked-set(group)) | {p for _, p in selected}
                if ring_stays_connected(target, tiles, current_blocks):
                    selected.append((origin, target))
                    break
        if len(selected) != len(group): continue  # Atomic small group; no forced placement.
        cluster += 1
        for origin, target in selected:
            used.add(target)
            occupied.remove(origin)
            occupied.add(target)
            blocked.remove(origin)
            blocked.add(target)
            moves.append({"from": list(origin), "to": list(target), "cluster": cluster,
                          "object_type_id": tiles[origin]["object_type_id"],
                          "source_before": copy.deepcopy(tiles[origin]), "target_before": copy.deepcopy(tiles[target])})
    result = copy.deepcopy(data)
    revised = {cell(t): t for t in result["tiles"]}
    for move in moves:
        origin, target = tuple(move["from"]), tuple(move["to"])
        revised[origin] = copy.deepcopy(tiles[target])
        revised[origin]["grid_position"] = {"x": origin[0], "y": origin[1]}
        revised[target] = copy.deepcopy(tiles[origin])
        revised[target]["grid_position"] = {"x": target[0], "y": target[1]}
    result["tiles"] = [revised[cell(t)] for t in data["tiles"]]
    assert payloads(result) == payloads(data)
    assert all(substrate(revised[p]) == substrate(t) for p, t in tiles.items())
    assert all(revised[p] == tiles[p] for p in protected if p in tiles)
    assert {k:v for k,v in result.items() if k != "tiles"} == {k:v for k,v in data.items() if k != "tiles"}
    assert all(1 <= distance(tuple(m["from"]), tuple(m["to"])) <= MAX_DISTANCE for m in moves)
    record = {"map": map_path, "before_canonical_sha256": digest(data), "after_canonical_sha256": digest(result),
              "nature_count": len(nature), "eligible_count": len(eligible), "moved_count": len(moves),
              "cluster_count": cluster, "max_hex_distance": MAX_DISTANCE,
              "protected_cells": [list(p) for p in sorted(protected & tiles.keys())],
              "original_and_relocated_pipe_cells": [list(p) for p in sorted(pipes)], "moves": moves}
    return result, record


def verify_current(audit):
    assert audit["schema"] == REVISION
    for record in audit["maps"]:
        path = ROOT / record["map"].removeprefix("res://")
        current = json.loads(path.read_text(encoding="utf-8"))
        assert digest(current) == record["after_canonical_sha256"], ("after hash", path)
        before = copy.deepcopy(current)
        restored = {cell(t): t for t in before["tiles"]}
        for move in record["moves"]:
            restored[tuple(move["from"])] = move["source_before"]
            restored[tuple(move["to"])] = move["target_before"]
        before["tiles"] = [restored[cell(t)] for t in before["tiles"]]
        assert digest(before) == record["before_canonical_sha256"]
        replay, replay_record = migrate(before, record["map"])
        assert replay == current and replay_record["moves"] == record["moves"]
        assert not set(map(tuple, record["protected_cells"])) & {tuple(m[k]) for m in record["moves"] for k in ("from", "to")}
    return [{k:r[k] for k in ("map", "nature_count", "eligible_count", "moved_count", "cluster_count")} for r in audit["maps"]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if AUDIT.exists():
        print("STATION_NATURE_CHECK " + json.dumps(verify_current(json.loads(AUDIT.read_text(encoding="utf-8")))) )
        return
    assert not args.check, "no applied migration audit"
    planned = []
    for name in ("station_outpost_64x64", "station_outpost_192x192"):
        path = ROOT / "maps" / (name+".json")
        original = path.read_bytes()
        data = json.loads(original)
        result, record = migrate(data, "res://maps/"+path.name)
        output = (json.dumps(result, ensure_ascii=False, indent="\t")+"\n").encode("utf-8")
        record.update(before_sha256=hashlib.sha256(original).hexdigest(), after_sha256=hashlib.sha256(output).hexdigest())
        planned.append((path, original, output, record))
    print(json.dumps([{k:r[k] for k in ("map", "nature_count", "eligible_count", "moved_count", "cluster_count")} for _,_,_,r in planned]))
    if args.apply:
        for path, original, _, _ in planned: assert path.read_bytes() == original, "concurrent map change"
        assert all(r["moved_count"] > 0 for _,_,_,r in planned)
        for path, _, output, _ in planned: path.write_bytes(output)
        audit = {"schema":REVISION, "maps":[r for _,_,_,r in planned], "native_and_navigation_status":"pending"}
        AUDIT.write_text(json.dumps(audit, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
        print("STATION_NATURE_CHECK " + json.dumps(verify_current(audit)))


if __name__ == "__main__": main()
