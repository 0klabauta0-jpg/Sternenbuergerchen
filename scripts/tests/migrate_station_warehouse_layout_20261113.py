"""Bounded, offline Station64/192 content revision; never a runtime transform."""
import copy
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = "warehouse_axes_v1"


def grid_of(point, data):
    dx = (point["x"] - data["grid_origin"]["x"]) / data["tile_size"]["half_width"]
    dy = (point["y"] - data["grid_origin"]["y"]) / data["tile_size"]["half_height"]
    r = (dy - dx) / math.sqrt(3)
    q = (dx + dy) * 0.5 - r * 0.5
    cube = [q, -q-r, r]
    rounded = [round(x) for x in cube]
    largest = max(range(3), key=lambda i: abs(cube[i] - rounded[i]))
    rounded[largest] = -sum(rounded[i] for i in range(3) if i != largest)
    return rounded[0], rounded[2]


def migrate(data, offset):
    result = copy.deepcopy(data)
    if result["place_presentation"].get("station_module_layout", {}).get("schema") == SCHEMA:
        return result, {"already_current": True}
    tiles = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in data["tiles"]}
    q0, r0, width, height, anchor = 22+offset, 23+offset, 20, 18, 31+offset
    source = {(q, r) for q in range(q0, q0+width) for r in range(r0, r0+height)}
    mapping = {(q, r): (q - (r-anchor)//2, r) for q, r in source}
    assert len(set(mapping.values())) == len(mapping)
    # Close the displacement chains into a permutation. The outside endpoint
    # returns to the vacated source, so no unrelated tile payload is deleted.
    inverse = {target: origin for origin, target in mapping.items()}
    for end in set(mapping.values()) - source:
        start = end
        while start in inverse:
            start = inverse[start]
        mapping[end] = start
    assert set(mapping) == set(mapping.values())
    updated = dict(tiles)
    for origin, target in mapping.items():
        updated[target] = copy.deepcopy(tiles[origin])
        updated[target]["grid_position"] = {"x": target[0], "y": target[1]}
    # The existing station-to-warehouse pipe remains connected to its unchanged
    # eastern half. Four real blocker cells bridge the shifted station branch.
    added_pipes = []
    for q in range(38+offset, 42+offset):
        grid = (q, 40+offset)
        tile = updated[grid]
        tile.update({"object_type_id": "spacekit_pipe_straight", "object_rotation_degrees": 90.0,
                     "walkable": False, "blocks_los": False, "cover_value": 35, "object_height": 1})
        added_pipes.append(list(grid))
    result["tiles"] = [updated[(t["grid_position"]["x"], t["grid_position"]["y"])] for t in data["tiles"]]
    moved_points = []
    def point(value, name):
        grid = grid_of(value, data)
        if grid not in source:
            return
        shift = mapping[grid][0] - grid[0]
        if not shift:
            return
        value["x"] += shift * data["tile_size"]["half_width"]
        value["y"] += shift * data["tile_size"]["half_height"]
        moved_points.append(name)
    for name, value in result.get("markers", {}).items():
        point(value, "marker:"+name)
    for name, values in result.get("patrol_paths", {}).items():
        for i, value in enumerate(values):
            point(value, "patrol:"+name+":"+str(i))
    # The actual eastern door leaf, distinct from the interior computer marker.
    q, r = 40+offset, 31+offset
    plane_x, plane_y = q+0.5*r, math.sqrt(3)*0.5*r
    result["markers"]["station_entry_door"] = {
        "marker_type_id": "objective_point", "name": "Station East Door",
        "placement_context": "editor_only", "symbol": "flag",
        "color": copy.deepcopy(data["markers"]["objective_point"]["color"]),
        "x": data["grid_origin"]["x"]+(plane_x-plane_y)*data["tile_size"]["half_width"],
        "y": data["grid_origin"]["y"]+(plane_x+plane_y)*data["tile_size"]["half_height"],
    }
    result["place_presentation"]["station_module_layout"] = {
        "schema": SCHEMA, "row_anchor": anchor,
        "source_region": [q0, r0, width, height],
        "pipe_extension_cells": added_pipes,
        "pipe_transition_cell": [41+offset,40+offset],
    }
    assert result["place_presentation"]["props"] == data["place_presentation"]["props"]
    assert result["place_presentation"]["building_authoring"] == data["place_presentation"]["building_authoring"]
    for prop in data["place_presentation"]["props"]:
        for grid in prop.get("reserved_grids", []):
            key = tuple(int(x) for x in grid)
            assert updated[key] == tiles[key], ("building changed", key)
    changed = set(mapping) | {tuple(g) for g in added_pipes}
    assert all(updated[key] == value for key, value in tiles.items() if key not in changed)
    assert len(result["tiles"]) == len(data["tiles"])
    return result, {"changed_region_cells": len(changed), "moved_points": moved_points,
                    "pipe_extension_cells": added_pipes, "original_tile_count": len(tiles),
                    "warehouse_payload_unchanged": True, "outside_region_unchanged": True}


def main():
    reports = []
    for name, offset in [("station_outpost_64x64", 0), ("station_outpost_192x192", 64)]:
        path = ROOT / "maps" / (name+".json")
        original = path.read_bytes()
        result, audit = migrate(json.loads(original), offset)
        if audit.get("already_current"):
            continue
        path.write_text(json.dumps(result, ensure_ascii=False, indent="\t")+"\n", encoding="utf-8")
        assert migrate(result, offset)[0] == result
        reports.append(dict(map=str(path.relative_to(ROOT)), before_sha256=hashlib.sha256(original).hexdigest(),
                            after_sha256=hashlib.sha256(path.read_bytes()).hexdigest(), **audit))
    if reports:
        destination = ROOT/"docs/qa/review_completion_20261113/station_layout_migration.json"
        destination.write_text(json.dumps({"schema":SCHEMA,"maps":reports}, indent=2)+"\n",encoding="utf-8")
    print(json.dumps(reports))


if __name__ == "__main__":
    main()
