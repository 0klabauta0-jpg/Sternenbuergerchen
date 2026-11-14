"""Trade outpost (14.11.2026): dressing pass over the campaign map.

Terrain, markers, pads, services, structures, resource sites and the regional
extent stay as the campaign builder made them. This pass replaces the old
Space-Kit rocks by the sandstone used everywhere else, furnishes the free port
and the far storage outpost with kit pieces, marks both ore sites with
outcrops, adds two trails and loose rock cover.

Idempotent: always starts from the map as committed in BASE_REVISION.
Run:  python3 tools/dress_trade_outpost.py
"""
import json
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_windbruch_outpost as wb  # shared hex, noise and asset helpers

ROOT = Path(__file__).resolve().parents[1]
MAP = "maps/trade_outpost.json"
BASE_REVISION = "068784888"
DIRS = wb.DIRS
plane, cell_at, fbm = wb.plane, wb.cell_at, wb.fbm
KIT = "res://Assets/curated/absturz_kit_20261114/"
ASSETS = dict(wb.ASSETS)
ASSETS.update({"ore_a": (KIT + "ab_ore_outcrop_a.glb", 0.6, 0.5, 1, False, 45),
               "ore_c": (KIT + "ab_ore_outcrop_c.glb", 0.6, 0.5, 1, False, 45)})
TRAILS = [
    [(23.4, 11.8), (29.0, 10.6), (32.6, 9.2)],                              # free port -> C-Benit
    [(21.0, 14.0), (26.0, 19.5), (31.4, 24.2)],                             # free port -> A-Benit
]
CORES = [(-20.0, -24.0, 70.0, 46.0), (104.0, 14.0, 146.0, 52.0)]
# (asset, x, z, rotation, scale)
PROPS = [
    # free port
    ("container_stack", 27.6, 5.4, 15, 1.0), ("container_orange", 27.0, 9.0, 80, 1.0), ("container_petrol", 5.0, 6.6, -20, 1.0),
    ("crates", 10.4, 5.8, 0, 1.0), ("barrels", 25.8, 13.0, 0, 1.0), ("solar", 9.0, -1.6, 0, 1.0), ("solar", 12.2, -2.0, 0, 1.0),
    ("solar", 22.6, -2.2, 0, 1.0), ("power", 27.0, 0.6, 0, 1.0), ("hull_hab", 3.4, 1.2, 20, 1.0), ("crates", 6.6, 12.8, 0, 1.0),
    ("barrels", 17.4, 14.8, 0, 1.0), ("wreck_engine", 29.8, 12.6, 40, 1.0),
    # ore sites
    ("ore_c", 35.7, 7.5, 0, 1.0), ("ore_c", 35.5, 10.3, 60, 1.0), ("ore_c", 32.9, 6.5, -40, 0.8),
    ("ore_a", 34.3, 24.1, 0, 1.0), ("ore_a", 33.9, 26.9, 70, 1.0), ("ore_a", 30.9, 26.9, -30, 0.8),
    # far storage outpost
    ("container_stack", 118.4, 31.0, 10, 1.0), ("container_petrol", 128.8, 30.0, -25, 1.0), ("crates", 120.6, 28.0, 0, 1.0),
    ("barrels", 125.8, 28.4, 0, 1.0), ("power", 130.4, 34.2, 0, 1.0), ("solar", 118.4, 35.6, 0, 1.0), ("solar", 118.2, 38.2, 0, 1.0),
    ("hull_hab", 131.2, 38.6, -15, 1.0), ("wreck_wing", 115.2, 26.2, 30, 1.0), ("crates", 126.6, 39.8, 0, 1.0),
    ("container_orange", 120.8, 40.6, 60, 1.0),
]


def in_core(x, z):
    return any(c[0] < x < c[2] and c[1] < z < c[3] for c in CORES)


def main() -> None:
    raw = subprocess.run(["git", "show", "%s:%s" % (BASE_REVISION, MAP)], cwd=ROOT, capture_output=True, check=True).stdout
    data = json.loads(raw.decode("utf-8"))
    origin = data["grid_origin"]
    wb.ORIGIN = (float(origin["x"]), float(origin["y"]))
    tiles = {(int(t["grid_position"]["x"]), int(t["grid_position"]["y"])): t for t in data["tiles"]}
    resources = json.loads((ROOT / "data/singleplayer/location_resources.json").read_text(encoding="utf-8"))
    sites = {k: plane(int(v["grid"][0]), int(v["grid"][1])) for k, v in resources.get("trade_outpost", {}).items() if isinstance(v, dict) and "grid" in v}

    def marker_plane(m):
        a, b = (m["x"] - origin["x"]) / 64.0, (m["y"] - origin["y"]) / 32.0
        return ((a + b) * 0.5, (b - a) * 0.5)

    points = {k: marker_plane(m) for k, m in data["markers"].items()}
    points.update(sites)
    presentation = data["place_presentation"]
    pads = presentation.get("pads", [])
    swapped = 0
    for (q, r), t in tiles.items():                             # old Space-Kit rocks -> the sandstone of the other maps
        if t.get("object_type_id") == "spacekit_rock_large_a":
            t.update({"object_type_id": "glut_sandstone_04", "object_rotation_degrees": int(wb._hash(q, r, 173) * 360),
                      "object_scale": round(0.82 + 0.4 * wb._hash(q, r, 167), 3)})
            swapped += 1
    trails = set()
    for line in TRAILS:
        wb.stroke(trails, line)
    for cell in trails:
        t = tiles.get(cell)
        if t and t["height_level"] == 0 and t.get("ramp_direction", -1) < 0 and t["walkable"] and t["surface_type"] == "ground":
            t["surface_type"] = "sand"
    props, solids = list(presentation.get("props", [])), {}
    for asset, x, z, rot, scale in PROPS:
        path, half_w, half_d, height, los, cover = ASSETS[asset]
        props.append({"asset": asset, "center": [x, z], "path": path, "scale": scale, "rotation_degrees": rot,
                      "elevation": tiles[cell_at(x, z)]["height_level"] * 0.75})
        c, sn = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        q0, r0 = cell_at(x, z)
        reach = int(math.ceil(max(half_w, half_d) * scale)) + 2
        for dq in range(-reach, reach + 1):
            for dr in range(-reach, reach + 1):
                cell = (q0 + dq, r0 + dr)
                if cell in tiles:
                    px, pz = plane(*cell)
                    lx, lz = (px - x) * c - (pz - z) * sn, (px - x) * sn + (pz - z) * c
                    if abs(lx) <= half_w * scale and abs(lz) <= half_d * scale:
                        solids[cell] = (height, los, cover)
    keep = set(trails) | {c for c, t in tiles.items() if t["surface_type"] == "road" and in_core(*plane(*c))}
    for x, z in points.values():
        q, r = cell_at(x, z)
        keep.update((q + dq, r + dr) for dq in range(-1, 2) for dr in range(-1, 2) if abs(dq + dr) <= 1)
    for pad in pads:
        keep.update(c for c in tiles if abs(plane(*c)[0] - pad["center"][0]) < pad["size"][0] * 0.5 + 1.2
                    and abs(plane(*c)[1] - pad["center"][1]) < pad["size"][1] * 0.5 + 1.2)
    for cell in list(solids):
        if cell in keep or not tiles[cell]["walkable"] or tiles[cell].get("ramp_direction", -1) >= 0:
            del solids[cell]
    near_solid = {(q + dq, r + dr) for (q, r) in solids for dq in range(-1, 2) for dr in range(-1, 2)}
    rocks = {}
    for cell, t in tiles.items():
        x, z = plane(*cell)
        if not in_core(x, z) or not t["walkable"] or t.get("object_type_id") or cell in keep or cell in near_solid or cell in solids:
            continue
        if t.get("ramp_direction", -1) >= 0 or t["surface_type"] == "road" or any(math.hypot(x - px, z - pz) < 3.0 for px, pz in points.values()):
            continue
        if any(abs(x - s["center"][0]) < s["size"][0] * 0.5 + 2.5 and abs(z - s["center"][1]) < s["size"][2] * 0.5 + 2.5 for s in presentation.get("structures", [])):
            continue
        lv = t["height_level"]
        chance = 0.5 if wb.value_noise(x * 0.31, z * 0.31, 481) > 0.83 else 0.0
        if any(tiles.get((cell[0] + dq, cell[1] + dr), t)["height_level"] >= lv + 2 for dq, dr in DIRS):
            chance = max(chance, 0.10)
        if t["surface_type"] == "sand":
            chance *= 0.35
        if wb._hash(cell[0], cell[1], 487) < chance:
            rocks[cell] = (round(0.82 + 0.4 * wb._hash(cell[0], cell[1], 491), 3), int(wb._hash(cell[0], cell[1], 499) * 360))
    for cell, (height, los, cover) in solids.items():
        tiles[cell].update({"walkable": False, "blocks_los": los, "cover_value": cover, "object_height": height,
                            "object_type_id": "frontier_scene_solid", "object_rotation_degrees": 0.0, "object_scale": 1.0})
    for cell, (scale, rot) in rocks.items():
        tiles[cell].update({"walkable": False, "blocks_los": True, "cover_value": 55, "object_height": 2,
                            "object_type_id": "glut_sandstone_04", "object_rotation_degrees": rot, "object_scale": scale})

    def endpoint(tile, neighbour):
        ramp = tile.get("ramp_direction", -1)
        if ramp < 0:
            return float(tile["height_level"])
        dq, dr = DIRS[ramp]
        delta = (neighbour[0] - tile["grid_position"]["x"], neighbour[1] - tile["grid_position"]["y"])
        return tile["height_level"] + (1.0 if delta == (dq, dr) else 0.0 if delta == (-dq, -dr) else 0.5)

    start = cell_at(*points["spawn_alpha"])
    seen, queue = {start}, [start]
    while queue:
        cur = queue.pop()
        for dq, dr in DIRS:
            nxt = (cur[0] + dq, cur[1] + dr)
            if nxt in seen or nxt not in tiles or not tiles[nxt]["walkable"]:
                continue
            if abs(endpoint(tiles[cur], nxt) - endpoint(tiles[nxt], cur)) < 1e-6:
                seen.add(nxt)
                queue.append(nxt)
    problems = ["%s at %s blocked or unreachable" % (name, cell_at(x, z)) for name, (x, z) in points.items()
                if not tiles[cell_at(x, z)]["walkable"] or cell_at(x, z) not in seen]
    if problems:
        raise SystemExit("\n".join(problems))

    presentation["props"] = props
    presentation["cliff_detail_bounds"] = list(CORES[0])
    data["place_world"]["dressing"] = {"revision": "handelsposten_r1_20261114", "base_revision": BASE_REVISION,
                                       "tool": "tools/dress_trade_outpost.py"}
    data["singleplayer_site"]["visual_status"] = "dressed 14.11.2026 (kit pieces, ore outcrops, sandstone); no user style approval"
    (ROOT / MAP).write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print("props", len(props), "new blocked cells", len(solids) + len(rocks), "rocks", len(rocks), "rocks swapped", swapped, "reachable", len(seen))
    for name, (x, z) in points.items():
        print(" ", name, cell_at(x, z), "ok")


if __name__ == "__main__":
    main()
