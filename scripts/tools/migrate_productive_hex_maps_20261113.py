"""One-time authored-map migration; tile facts and logical grid cells stay fixed.

Square8 originals are retained as explicit legacy import fixtures. World-space
markers/patrols and plane-space dressing must follow the new Hex cell geometry.
The script deliberately preserves the original tiles text instead of reformatting
hundreds of thousands of authored tiles. Re-running is a no-op.
"""
import json
import math
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
NAMES = (
    "Ground_Mission01_32x32 Ground_Mission02_128x128 fireteam_command_drill_24x24 "
    "frontier_workyard_24x20 station_outpost_64x64 station_outpost_192x192 wall_test_4x4 "
    "satellite_crash_site trade_outpost fortified_outpost polisa_station distress_orbit "
    "campaign_intro_base homebase_frontier_exploration base_interior_navigation test_mission test_mission_32x32_slots8"
).split()


def replace_field(text, key, value):
    match = re.search(r'"' + re.escape(key) + r'"\s*:\s*', text)
    if not match:
        return text.replace("{", "{\n\t" + json.dumps(key) + ": " + json.dumps(value) + ",", 1)
    _, length = json.JSONDecoder().raw_decode(text[match.end():])
    return text[:match.end()] + json.dumps(value, ensure_ascii=False, indent="\t") + text[match.end()+length:]


def migrate(path):
    original = path.read_text(encoding="utf-8-sig")
    data = json.loads(original)
    if data.get("tactical_grid_rules") == "hex_tactical_v1":
        return False
    text = original
    if data.get("grid_topology", "square8") == "square8":
        legacy = path.parent / "legacy" / (path.stem + "_square8_20261113.json")
        legacy.parent.mkdir(exist_ok=True)
        if not legacy.exists():
            legacy.write_bytes(path.read_bytes())
        elif legacy.read_bytes() != path.read_bytes():
            raise ValueError(f"Refusing to replace different legacy source {legacy}")
        origin, size = data["grid_origin"], data["tile_size"]

        def world(point):
            a = (point["x"] - origin["x"]) / size["half_width"]
            b = (point["y"] - origin["y"]) / size["half_height"]
            q, r = (a+b)/2, (b-a)/2
            x, y = q + r/2, r*math.sqrt(3)/2
            return dict(point, x=origin["x"]+(x-y)*size["half_width"],
                        y=origin["y"]+(x+y)*size["half_height"])

        if "markers" in data:
            text = replace_field(text, "markers", {key: world(value) for key, value in data["markers"].items()})
        if "patrol_paths" in data:
            text = replace_field(text, "patrol_paths", {key: [world(p) for p in points] for key, points in data["patrol_paths"].items()})
        presentation = data.get("place_presentation", {})
        if presentation:
            for prop in presentation.get("props", []):
                q, r = prop["center"]
                prop["center"] = [q+r/2, r*math.sqrt(3)/2]
            text = replace_field(text, "place_presentation", presentation)
        text = replace_field(text, "grid_topology", "hex_axial_v1")
    text = replace_field(text, "tactical_grid_rules", "hex_tactical_v1")
    # Verify that migration does not change the authored simulation tiles.
    assert json.loads(text)["tiles"] == data["tiles"]
    path.write_text(text, encoding="utf-8", newline="\n")
    return True


def migrate_inherited_scene_markers(path):
    """Two old sandbox maps inherited these exact Square8 scene positions."""
    original = path.read_text(encoding="utf-8-sig")
    data = json.loads(original)
    if data.get("markers"):
        return False
    origin, size = data["grid_origin"], data["tile_size"]
    markers = {}
    for name, (q, r) in {"spawn_alpha": (3, 7), "spawn_bravo": (4, 0), "objective_point": (4, 4)}.items():
        x, y = q+r/2, r*math.sqrt(3)/2
        markers[name] = {"x":origin["x"]+(x-y)*size["half_width"],
                         "y":origin["y"]+(x+y)*size["half_height"], "marker_type_id":name}
    path.write_text(replace_field(original, "markers", markers), encoding="utf-8", newline="\n")
    return True


if __name__ == "__main__":
    changed = [name for name in NAMES if migrate(ROOT / "maps" / (name + ".json"))]
    for name in ["wall_test_4x4", "test_mission"]:
        if migrate_inherited_scene_markers(ROOT / "maps" / (name + ".json")):
            changed.append(name + " inherited markers")
    print("Migrated:", ", ".join(changed))
