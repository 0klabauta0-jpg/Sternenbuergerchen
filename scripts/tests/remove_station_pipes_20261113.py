"""Remove the user-rejected authored Station pipes, including their blockers."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GROUND_TYPES = {
    "nature_ground_dirt", "nature_ground_sand_dirt", "nature_ground_grass_patch",
    "ground_flat", "station_set_floor_panel", "station_set_floor_panel_straight",
}


def remove_pipes(data):
    result = copy.deepcopy(data)
    reserved = {tuple(grid) for prop in data["place_presentation"]["props"]
                for grid in prop.get("reserved_grids", [])}
    removed = []
    for before, tile in zip(data["tiles"], result["tiles"]):
        if not tile.get("object_type_id", "").startswith("spacekit_pipe"):
            continue
        grid = [tile["grid_position"]["x"], tile["grid_position"]["y"]]
        assert tuple(grid) not in reserved, ("warehouse reservation", grid)
        # These exact authored pipe facts are the only facts being removed.
        assert tile["type_id"] in GROUND_TYPES, ("unexpected substrate", grid)
        assert (tile["walkable"], tile["blocks_los"], tile["cover_value"], tile["object_height"]) == (False, False, 35, 1)
        removed.append({"grid": grid, "object_type_id": tile["object_type_id"]})
        tile.pop("object_type_id")
        tile.pop("object_rotation_degrees", None)
        tile.update(walkable=True, blocks_los=False, cover_value=0, object_height=0)
        for key in ["type_id", "height_level", "edge_type", "surface_type", "grid_position"]:
            assert tile[key] == before[key]
    layout = result["place_presentation"]["station_module_layout"]
    layout["pipe_extension_cells"] = []
    layout.pop("pipe_transition_cell", None)
    for key in ["props", "building_authoring"]:
        assert result["place_presentation"][key] == data["place_presentation"][key]
    assert result["markers"] == data["markers"]
    assert result["patrol_paths"] == data["patrol_paths"]
    assert not any(t.get("object_type_id", "").startswith("spacekit_pipe") for t in result["tiles"])
    return result, removed


def main():
    records = []
    for name in ["station_outpost_64x64", "station_outpost_192x192"]:
        path = ROOT / "maps" / (name + ".json")
        original = path.read_bytes()
        revised, removed = remove_pipes(json.loads(original))
        assert remove_pipes(revised) == (revised, [])
        if not removed:
            continue
        path.write_text(json.dumps(revised, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
        records.append({"map": "res://maps/" + name + ".json",
                        "before_sha256": hashlib.sha256(original).hexdigest(),
                        "after_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                        "removed_cells": removed, "warehouse_and_terrain_preserved": True})
    if records:
        (ROOT / "docs/qa/review_completion_20261113/station_pipe_removal.json").write_text(
            json.dumps({"revision": "station_pipes_removed_v1", "maps": records}, indent=2) + "\n", encoding="utf-8")
    print(json.dumps([{ "map": r["map"], "removed_count": len(r["removed_cells"])} for r in records]))


if __name__ == "__main__":
    main()
