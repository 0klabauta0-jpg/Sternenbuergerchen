"""Ground Mission 02 "Relay Ridge" (14.11.2026): rebuilt 128 x 128 map.

Replaces the old mixed-theme map with its station-floor block by a frontier
map in the Windbruch style: a relay site on a rock plateau, two landing
fields, a tarred road up two ramps, trails over the side ramps and a dry
riverbed. Grid, markers, patrol routes and enemy team data are taken unchanged
from the old map (now maps/Ground_Mission02_128x128_legacy_theme_fixture.json),
so the scenario data/mission_scenarios/ground_mission02_128x128.json keeps
working as it is.

Run:  python3 tools/build_ground_mission02.py
"""
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_windbruch_outpost as wb  # shared hex, noise, ramp and asset helpers

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "maps" / "Ground_Mission02_128x128.json"
LEGACY = ROOT / "maps" / "Ground_Mission02_128x128_legacy_theme_fixture.json"
SIZE = 128
SQ3H = wb.SQ3H
DIRS = wb.DIRS
plane, cell_at, fbm, blob, dist = wb.plane, wb.cell_at, wb.fbm, wb.blob, wb.dist_to_polyline

RIVERBED = [(26, 14), (48, 36), (70, 54), (88, 72), (100, 90), (110, 112)]
PLATEAU = (128.0, 69.0, 25.0, 17.5)           # relay plateau: centre x, z, radii
KNOLL = (132.5, 65.5, 4.6, 3.2)               # pedestal of the relay dish
# name, plane point below the cliff, uphill direction, band width, base level
RAMPS = [
    ("westrampe", (99.0, 71.0), 0, 4, 0),
    ("nordrampe", (123.5, 46.0), 5, 4, 0),
    ("suedsteig", (118.0, 93.0), 1, 2, 0),
    ("oststeig", (160.0, 73.6), 3, 2, 0),
]
PADS = [
    {"id": "gm02_pad_alpha", "center": (63.9, 91.4), "size": (6.2, 5.2), "name": "LZ · ALPHA"},
    {"id": "gm02_pad_bravo", "center": (130.6, 28.2), "size": (6.2, 5.2), "name": "LZ · BRAVO"},
]
YARD = (121.0, 70.2)
ROADS = [
    [(67.4, 90.1), (80.0, 88.4), (90.0, 79.6), "foot:westrampe"],
    ["head:westrampe", (111.0, 71.0), YARD],
    [(127.0, 29.4), (125.0, 38.0), "foot:nordrampe"],
    ["head:nordrampe", (126.6, 58.0), (124.0, 66.0), YARD],
    [YARD, (131.0, 73.4), (136.0, 76.2)],
]
TRAILS = [
    [(68.0, 92.0), (86.0, 97.0), (104.0, 96.5), "foot:suedsteig"],
    ["head:suedsteig", (121.0, 83.0), (124.0, 74.0)],
    [(128.0, 30.5), (150.0, 44.0), (166.0, 62.0), "foot:oststeig"],
    ["head:oststeig", (148.0, 76.0), (138.0, 77.0)],
    [(82.0, 62.4), (101.0, 79.7)],
    [(128.0, 55.4), (128.0, 62.4), (117.0, 71.0)],
    [(136.0, 76.2), (143.0, 81.4)],
    [(120.0, 83.1), (125.0, 71.0)],
]
# The two air-defence vehicles (own designs, art/flugabwehr_kit_20261114): long axis along X, cab towards -X.
FA = "res://Assets/curated/flugabwehr_kit_20261114/"
wb.ASSETS.update({"hagel": (FA + "fa_hagel.glb", 1.6, 0.75, 3, True, 80), "donnerkeil": (FA + "fa_donnerkeil.glb", 1.6, 0.75, 3, True, 80)})
# (asset, x, z, rotation, scale); kit pieces face +Z at rotation 0
PROPS = [
    # relay site on the plateau
    ("comm_dish", 132.5, 65.3, 0, 1.0),
    ("container_hall", 115.4, 64.4, 0, 1.0),
    ("hull_hab", 114.6, 76.6, 10, 1.0),
    ("power", 127.6, 76.4, 0, 1.0),
    ("solar", 126.6, 81.4, 0, 1.0),
    ("solar", 129.8, 81.8, 0, 1.0),
    ("container_orange", 118.6, 67.6, 90, 1.0),
    ("container_petrol", 131.8, 59.6, 20, 1.0),
    ("crates", 119.4, 61.4, 0, 1.0),
    ("barrels", 119.4, 73.4, 0, 1.0),
    ("crates", 129.6, 69.2, 0, 1.0),
    # air-defence corner: flak truck "Hagel" and missile truck "Donnerkeil" either side of the objective
    ("hagel", 138.6, 74.4, 18, 1.0),
    ("donnerkeil", 133.2, 79.0, -14, 1.0),
    ("container_stack", 142.4, 73.0, -20, 1.0),
    ("power", 144.6, 72.6, 90, 1.0),
    ("crates", 130.4, 77.6, 0, 1.0),
    ("barrels", 137.6, 80.4, 0, 1.0),
    ("container_petrol", 146.6, 80.0, 60, 1.0),
    # landing fields
    ("fuel_unit", 59.4, 95.6, 90, 0.35),
    ("container_orange", 68.6, 94.6, 30, 1.0),
    ("crates", 66.4, 87.4, 0, 1.0),
    ("barrels", 60.4, 87.6, 0, 1.0),
    ("container_petrol", 135.4, 31.4, -20, 1.0),
    ("crates", 133.0, 24.6, 0, 1.0),
    ("barrels", 127.4, 25.4, 0, 1.0),
    # along the routes
    ("wreck_wing", 95.5, 64.0, 35, 1.0),
    ("wreck_engine", 90.5, 61.0, -20, 1.0),
    ("container_stack", 104.6, 75.6, 15, 1.0),
    ("crates", 103.4, 67.4, 0, 1.0),
    ("container_orange", 121.4, 50.4, 70, 1.0),
    ("barrels", 127.4, 49.6, 0, 1.0),
    ("wreck_wing", 146.4, 50.6, -60, 1.0),
    ("crates", 113.4, 91.4, 0, 1.0),
    ("container_petrol", 76.4, 84.6, 10, 1.0),
]


def border(q: int, r: int) -> int:
    return min(q, SIZE - 1 - q, r, SIZE - 1 - r)


def design_level(q: int, r: int) -> int:
    x, z = plane(q, r)
    level = 0
    if blob(x, z, *PLATEAU, 311) > 0.0:
        level = 2
    if blob(x, z, *KNOLL, 313, 0.1) > 0.0:
        level = 4
    # the ridge that gives the place its name: behind and east of the relay
    for cx, cz, rx, rz, lv, seed in ((146.0, 56.0, 13.0, 4.5, 4, 317), (149.0, 55.0, 6.0, 2.2, 6, 319),
                                     (104.0, 52.0, 9.0, 5.0, 2, 331), (106.0, 51.0, 4.0, 2.2, 4, 337),
                                     (84.0, 104.0, 10.0, 4.0, 2, 347), (60.0, 60.0, 8.0, 5.0, 2, 349),
                                     (58.0, 59.0, 3.4, 2.2, 4, 353), (150.0, 96.0, 9.0, 5.0, 2, 359),
                                     (96.0, 30.0, 10.0, 5.0, 2, 367), (160.0, 38.0, 8.0, 5.0, 2, 373),
                                     (40.0, 42.0, 6.0, 4.0, 2, 379), (44.0, 78.0, 6.0, 4.0, 2, 383)):
        if blob(x, z, cx, cz, rx, rz, seed, 0.18) > 0.0:
            level = max(level, lv)
    edge = border(q, r)
    rim = edge - 2.5 - 4.5 * fbm(x * 0.07, z * 0.07, 389)
    if rim < 0.0 or edge < 2:
        level = max(level, 4 if rim < -1.8 else 2)
    if dist(x, z, RIVERBED) < 2.6 + 0.9 * fbm(x * 0.11, z * 0.11, 397) and blob(x, z, *PLATEAU, 311) <= 0.0 and edge >= 2:
        level = 0
    for pad in PADS:
        px, pz = pad["center"]
        if abs(x - px) < pad["size"][0] * 0.5 + 3.0 and abs(z - pz) < pad["size"][1] * 0.5 + 3.0:
            level = 0
    return level


def main() -> None:
    wb.ORIGIN = (0.0, 0.0)
    wb.RAMPS = RAMPS
    legacy = json.loads(LEGACY.read_text(encoding="utf-8"))
    markers = legacy["markers"]

    def marker_plane(m):
        return (m["x"] / 128.0 + m["y"] / 64.0, m["y"] / 64.0 - m["x"] / 128.0)

    points = {name: marker_plane(m) for name, m in markers.items()}
    patrols = {name: [marker_plane(p) for p in pts] for name, pts in legacy["patrol_paths"].items()}
    levels = {(q, r): design_level(q, r) for r in range(SIZE) for q in range(SIZE)}
    # every authored point stands on flat ground of its surroundings
    for name, (x, z) in list(points.items()) + [(k, p) for k, pts in patrols.items() for p in pts]:
        c = cell_at(x, z)
        want = 2 if blob(x, z, *PLATEAU, 311) > -0.12 else 0
        for dq in range(-2, 3):
            for dr in range(-2, 3):
                n = (c[0] + dq, c[1] + dr)
                if n in levels and abs(dq + dr) <= 2 and border(*n) >= 2:
                    levels[n] = want
    for _ in range(3):                                   # no one-cell needles or pits
        for (q, r), lv in list(levels.items()):
            around = [levels.get((q + dq, r + dr), lv) for dq, dr in DIRS]
            if sum(1 for v in around if v == lv) <= 1:
                levels[(q, r)] = max(set(around), key=around.count)
    ramps, owner = wb.carve_ramps(levels)
    spec = {name: (direction, width) for name, _, direction, width, _ in RAMPS}

    def band(name, k):
        direction, width = spec[name]
        first = owner[name][0]
        dq, dr = DIRS[direction]
        lq, lr = DIRS[(direction + 4) % 6]
        half = width // 2
        return [(first[0] + i * lq + k * dq, first[1] + i * lr + k * dr) for i in range(-half, width - half)]

    def anchor(p):
        if isinstance(p, str):
            kind, name = p.split(":")
            cells = band(name, -2 if kind == "foot" else 4)
            return plane(*cells[len(cells) // 2])
        return p

    roads, trails = set(), set()
    for line in ROADS:
        wb.stroke(roads, [anchor(p) for p in line])
    for name in ("westrampe", "nordrampe"):
        for k in range(-2, 5):
            for c in band(name, k)[1:3]:
                roads.add(c)
    for line in TRAILS:
        wb.stroke(trails, [anchor(p) for p in line])
    for name in ("suedsteig", "oststeig"):
        for k in range(-2, 5):
            trails.add(band(name, k)[len(band(name, k)) // 2])
    roads = {c for c in roads if c in levels}
    trails = {c for c in trails if c in levels and c not in roads}
    # a road or trail never crosses a cliff except on its ramp
    for c in list(roads | trails):
        if c not in ramps and levels[c] not in (0, 2):
            levels[c] = 2 if blob(*plane(*c), *PLATEAU, 311) > -0.1 else 0

    surfaces = {}
    for cell, lv in levels.items():
        x, z = plane(*cell)
        surface = "ground"
        if lv >= 2 and fbm(x * 0.2, z * 0.2, 131) > 0.05:
            surface = "rock"
        if lv == 0 and dist(x, z, RIVERBED) < 2.2 + 0.8 * fbm(x * 0.15, z * 0.15, 137):
            surface = "sand"
        if lv == 0 and fbm(x * 0.035, z * 0.035, 271) > 0.6:
            surface = "sand"
        if cell in trails:
            surface = "sand"
        if cell in roads:
            surface = "road"
        for pad in PADS:
            px, pz = pad["center"]
            if abs(x - px) < pad["size"][0] * 0.5 + 0.3 and abs(z - pz) < pad["size"][1] * 0.5 + 0.3:
                surface = "road"
        surfaces[cell] = surface

    props, solids = [], {}
    for asset, x, z, rot, scale in PROPS:
        path, half_w, half_d, height, los, cover = wb.ASSETS[asset]
        props.append({"asset": asset, "center": [x, z], "path": path, "scale": scale, "rotation_degrees": rot,
                      "elevation": levels[cell_at(x, z)] * 0.75})
        c, sn = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        q0, r0 = cell_at(x, z)
        reach = int(math.ceil(max(half_w, half_d) * scale)) + 2
        for dq in range(-reach, reach + 1):
            for dr in range(-reach, reach + 1):
                cell = (q0 + dq, r0 + dr)
                if cell not in levels:
                    continue
                px, pz = plane(*cell)
                lx, lz = (px - x) * c - (pz - z) * sn, (px - x) * sn + (pz - z) * c
                if abs(lx) <= half_w * scale and abs(lz) <= half_d * scale:
                    solids[cell] = (height, los, cover)
    blocked_route = sorted(c for c in solids if c in roads or c in trails or c in ramps)
    if blocked_route:
        raise SystemExit("props block route cells: %s" % [tuple(round(v, 1) for v in plane(*c)) for c in blocked_route])

    keep_clear = set(roads) | set(trails) | set(ramps)
    for name in spec:
        for k in range(-3, 6):
            keep_clear.update(band(name, k))
    for x, z in list(points.values()) + [p for pts in patrols.values() for p in pts]:
        mq, mr = cell_at(x, z)
        keep_clear.update((mq + dq, mr + dr) for dq in range(-2, 3) for dr in range(-2, 3))
    near_solid = {(q + dq, r + dr) for (q, r) in solids for dq in range(-1, 2) for dr in range(-1, 2)}
    rocks = {}
    for cell, lv in levels.items():
        x, z = plane(*cell)
        if cell in keep_clear or cell in near_solid or surfaces[cell] == "road":
            continue
        if any(abs(x - p["center"][0]) < p["size"][0] * 0.5 + 1.6 and abs(z - p["center"][1]) < p["size"][1] * 0.5 + 1.6 for p in PADS):
            continue
        if math.hypot(x - YARD[0], z - YARD[1]) < 7.0:
            continue
        chance = 0.5 if wb.value_noise(x * 0.31, z * 0.31, 151) > 0.8 else 0.0
        if any(levels.get((cell[0] + dq, cell[1] + dr), lv) >= lv + 2 for dq, dr in DIRS):
            chance = max(chance, 0.10)
        if surfaces[cell] == "sand":
            chance *= 0.35
        if wb._hash(cell[0], cell[1], 163) < chance:
            rocks[cell] = (round(0.82 + 0.4 * wb._hash(cell[0], cell[1], 167), 3), int(wb._hash(cell[0], cell[1], 173) * 360))

    tiles = []
    for (q, r), lv in sorted(levels.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        ramp = ramps.get((q, r), -1)
        tile = {"grid_position": {"x": q, "y": r}, "type_id": "ground_flat", "height_level": lv,
                "surface_type": surfaces[(q, r)], "edge_type": "slope" if ramp >= 0 else "cliff", "ramp_direction": ramp,
                "walkable": True, "blocks_los": False, "cover_value": 0}
        if (q, r) in solids and ramp < 0:
            height, los, cover = solids[(q, r)]
            tile.update({"walkable": False, "blocks_los": los, "cover_value": cover, "object_height": height,
                         "object_type_id": "frontier_scene_solid", "object_rotation_degrees": 0.0, "object_scale": 1.0})
        elif (q, r) in rocks:
            scale, rot = rocks[(q, r)]
            tile.update({"walkable": False, "blocks_los": True, "cover_value": 55, "object_height": 2,
                         "object_type_id": "glut_sandstone_04", "object_rotation_degrees": rot, "object_scale": scale})
        tiles.append(tile)

    by_cell = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in tiles}

    def endpoint(tile, neighbour):
        if tile["ramp_direction"] < 0:
            return float(tile["height_level"])
        dq, dr = DIRS[tile["ramp_direction"]]
        delta = (neighbour[0] - tile["grid_position"]["x"], neighbour[1] - tile["grid_position"]["y"])
        return tile["height_level"] + (1.0 if delta == (dq, dr) else 0.0 if delta == (-dq, -dr) else 0.5)

    start = cell_at(*points["spawn_alpha"])
    seen, queue = {start}, [start]
    while queue:
        cur = queue.pop()
        for dq, dr in DIRS:
            nxt = (cur[0] + dq, cur[1] + dr)
            if nxt in seen or nxt not in by_cell or not by_cell[nxt]["walkable"]:
                continue
            if abs(endpoint(by_cell[cur], nxt) - endpoint(by_cell[nxt], cur)) < 1e-6:
                seen.add(nxt)
                queue.append(nxt)
    problems = ["%s at %s unreachable (level %d)" % (name, cell_at(x, z), levels[cell_at(x, z)])
                for name, (x, z) in list(points.items()) + [(k, p) for k, pts in patrols.items() for p in pts]
                if cell_at(x, z) not in seen]
    problems += ["ramp %s end unreachable" % name for name in spec for k in (-2, 4) if band(name, k)[len(band(name, k)) // 2] not in seen]
    if problems:
        raise SystemExit("\n".join(problems))

    data = {
        "tactical_grid_rules": "hex_tactical_v1", "grid_topology": "hex_axial_v1", "map_name": legacy["map_name"],
        "mission_slot_count": legacy["mission_slot_count"], "grid_origin": {"x": 0, "y": 0}, "grid_size": {"x": SIZE, "y": SIZE},
        "tile_size": legacy["tile_size"], "terrain_visual_theme_id": "frontier_illustrated_v1",
        "regional_height_step": 0.75, "regional_terrain_version": 3, "terrain_height_rules": "explicit_hex_ramps_v1",
        "place_world": {"id": "relay_ridge", "kind": "frontier_mission_map", "version": 2, "seed": "mission:gm02-relay-ridge"},
        "enemy_team_configs": legacy["enemy_team_configs"], "patrol_paths": legacy["patrol_paths"], "markers": markers,
        "place_presentation": {
            "initial_camera_size": 24.0,
            "pads": [{"id": p["id"], "center": list(p["center"]), "size": list(p["size"]), "name": p["name"]} for p in PADS],
            "structures": [], "props": props},
        "tiles": tiles,
    }
    OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    counts = {}
    for t in tiles:
        counts[t["surface_type"]] = counts.get(t["surface_type"], 0) + 1
    print("tiles", len(tiles), "surfaces", counts, "ramp cells", len(ramps), "props", len(props), "rocks", len(rocks), "reachable", len(seen))
    for name, (x, z) in points.items():
        print("marker", name, cell_at(x, z), "level", levels[cell_at(x, z)])


if __name__ == "__main__":
    main()
