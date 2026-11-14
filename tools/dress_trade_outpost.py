"""Trade outpost (14.11.2026): dressing pass over the campaign map.

Terrain, markers, pads, services, structures, resource sites and the regional
extent stay as the campaign builder made them. This pass replaces the old
Space-Kit rocks by the sandstone used everywhere else, turns the free port into
a paved, fenced depot yard with its own buildings (Freihafen kit), furnishes
the far storage outpost, marks both ore sites with outcrops, adds a road, a
trail and loose rock cover.

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
FH = "res://Assets/curated/freihafen_kit_20261114/"
ASSETS.update({"fh_tanks": (FH + "fh_tank_pair.glb", 1.25, 0.7, 3, True, 80), "fh_mast": (FH + "fh_radio_mast.glb", 0.5, 0.5, 5, False, 60),
               "fh_row_a": (FH + "fh_container_row_a.glb", 1.05, 1.4, 3, True, 80), "fh_row_b": (FH + "fh_container_row_b.glb", 1.05, 1.4, 3, True, 80),
               "fh_pallets": (FH + "fh_pallet_stack.glb", 0.65, 0.4, 1, False, 45), "fh_lamp": (FH + "fh_yard_lamp.glb", 0.0, 0.0, 0, False, 0),
               "fh_gate": (FH + "fh_gate.glb", 0.0, 0.0, 0, False, 0)})
STRUCTURE_MODELS = {"TradeHall": "fh_warehouse", "OutpostHabitat": "fh_office", "OutpostMechanic": "fh_workshop",
                    "Außenposten · Lager": "fh_warehouse"}
TRAILS = [
    [(22.0, 14.72), (26.0, 19.0), (31.4, 21.0)],                            # south gate -> road to A-Benit
]
# Free port after the user's "Distribution Center" reference (14.11.2026): buildings, goods yard and landing
# field on one paved apron inside a fence. The fence stays clear of the landing pads and their overhang.
YARD = (-3.5, -3.0, 29.0, 14.0)                                             # x0, z0, x1, z1 of the paved cells
FENCE = (-4.45, -3.55, 29.95, 14.722432)                                    # fence line around it
SOUTH_GATE = (22.0, FENCE[3])                                               # trail to the A-Benit site
EAST_GATE = (FENCE[2], 4.330127)                                            # road to the C-Benit site
GATE_HALF = 1.4
# Road out of the east gate: past both ore sites, then along the open plain to the far storage outpost.
ROAD_EAST = [(29.0, 4.330127), (31.8, 4.330127), (33.6, 7.4), (33.4, 13.0), (32.0, 20.0), (29.5, 24.0), (29.5, 29.0),
             (34.0, 34.0), (40.0, 38.105118), (127.0, 38.105118)]
APRON = ("fh_apron_trade_outpost", 12.75, 5.6)                              # frame and markings, see the kit
FENCE_RUNS = [                                                              # (x0, z0, x1, z1)
    (FENCE[0], FENCE[1], FENCE[2], FENCE[1]),                               # north
    (FENCE[0], FENCE[1], FENCE[0], FENCE[3]),                               # west
    (FENCE[2], FENCE[1], FENCE[2], EAST_GATE[1] - GATE_HALF),               # east, north of the gate
    (FENCE[2], EAST_GATE[1] + GATE_HALF, FENCE[2], FENCE[3]),               # east, south of the gate
    (FENCE[0], FENCE[3], SOUTH_GATE[0] - GATE_HALF, FENCE[3]),              # south, west of the gate
    (SOUTH_GATE[0] + GATE_HALF, FENCE[3], FENCE[2], FENCE[3]),              # south, east of the gate (behind its booth)
]
CORES = [(-20.0, -24.0, 70.0, 46.0), (104.0, 14.0, 146.0, 52.0)]
# (asset, x, z, rotation, scale)
PROPS = [
    # free port: goods yard in the west; one free cell between neighbouring container blocks
    ("fh_row_a", -1.9, -0.9, 0, 1.0), ("fh_row_b", 1.2, -0.9, 0, 1.0), ("fh_row_a", 4.3, -0.9, 0, 1.0),
    ("fh_row_a", -1.9, 3.6, 0, 1.0), ("fh_row_b", -1.9, 8.6, 0, 1.0), ("fh_row_a", 1.2, 8.6, 0, 1.0),
    ("fh_row_b", -1.9, 12.3, 0, 1.0),
    ("fh_pallets", 1.0, 2.6, 0, 1.0), ("fh_pallets", 2.4, 3.9, 90, 1.0), ("crates", 4.4, 2.4, 0, 1.0),
    ("fh_pallets", 1.4, 12.4, 0, 1.0),
    # behind and between the buildings
    ("solar", 7.0, -1.5, 0, 1.0), ("solar", 9.8, -1.5, 0, 1.0), ("power", 12.3, -1.6, 0, 1.0), ("barrels", 11.0, 1.4, 0, 1.0),
    ("barrels", 15.2, -1.7, 0, 1.0), ("fh_pallets", 19.0, -1.7, 0, 1.0),
    ("container_orange", 22.6, -1.7, 0, 1.0), ("fh_pallets", 20.6, 4.9, 0, 1.0),
    ("crates", 24.7, 4.7, 0, 1.0),
    # plant corner in the east
    ("fh_tanks", 27.2, -1.2, 0, 1.0), ("fh_mast", 27.6, 2.0, 0, 1.0),
    ("container_orange", 27.4, 9.6, 80, 1.0), ("barrels", 25.6, 12.9, 0, 1.0), ("crates", 6.3, 10.4, 0, 1.0),
    ("fh_lamp", -3.2, 1.6, 0, 1.0), ("fh_lamp", 5.0, -2.5, 0, 1.0), ("fh_lamp", 13.4, -2.5, 0, 1.0), ("fh_lamp", 25.2, -2.5, 0, 1.0),
    ("fh_lamp", 6.6, 7.0, 180, 1.0), ("fh_lamp", 6.6, 13.6, 180, 1.0), ("fh_lamp", 24.6, 13.6, 180, 1.0), ("fh_lamp", 26.2, 6.4, 180, 1.0),
    ("fh_gate", SOUTH_GATE[0], SOUTH_GATE[1], 0, 1.0), ("fh_gate", EAST_GATE[0], EAST_GATE[1], 90, 1.0),
    ("wreck_engine", 38.6, 15.6, 40, 1.0),
    # ore sites
    ("ore_c", 36.2, 7.5, 0, 1.0), ("ore_c", 36.0, 10.3, 60, 1.0), ("ore_c", 36.6, 5.4, -40, 0.8),
    ("ore_a", 34.3, 24.1, 0, 1.0), ("ore_a", 33.9, 26.9, 70, 1.0), ("ore_a", 30.9, 26.9, -30, 0.8),
    # far storage outpost
    ("container_stack", 118.4, 31.0, 10, 1.0), ("container_petrol", 128.8, 30.0, -25, 1.0), ("crates", 120.6, 28.0, 0, 1.0),
    ("barrels", 125.8, 28.4, 0, 1.0), ("power", 130.4, 34.2, 0, 1.0), ("solar", 132.0, 30.6, 0, 1.0), ("solar", 134.8, 30.8, 0, 1.0),
    ("hull_hab", 131.2, 38.6, -15, 1.0), ("wreck_wing", 115.2, 26.2, 30, 1.0), ("crates", 126.6, 39.8, 0, 1.0),
    ("container_orange", 120.8, 40.6, 60, 1.0),
]
ROAD_DECK = 0.09                                                            # frontier_road_deck.DECK_HEIGHT


def fence_pieces(x0, z0, x1, z1):
    """4/2/1 pieces along a run; the last one is pulled back so the run ends exactly at its end point."""
    length = math.hypot(x1 - x0, z1 - z0)
    ux, uz = (x1 - x0) / length, (z1 - z0) / length
    rot = 0 if abs(ux) > abs(uz) else 90
    out, at, index = [], 0.0, 0
    while length - at > 0.05:
        left = length - at
        size = 4 if left >= 4 else 2 if left >= 2 else 1
        start = at if left >= size else length - size
        name = "fh_wall_4_lamp" if size == 4 and index % 2 == 0 else "fh_wall_%d" % size
        mid = start + size * 0.5
        out.append((name, x0 + ux * mid, z0 + uz * mid, rot))
        at, index = start + size, index + 1
    return out


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
    old_roads = {c for c, t in tiles.items() if t["surface_type"] == "road" and in_core(*plane(*c))}
    trails, paved = set(), set()
    for line in TRAILS:
        wb.stroke(trails, line)
    wb.stroke(paved, ROAD_EAST)
    passages = set(paved)
    for cell in tiles:
        x, z = plane(*cell)
        if YARD[0] <= x <= YARD[2] and YARD[1] <= z <= YARD[3]:
            paved.add(cell)
        if abs(z - SOUTH_GATE[1]) < 0.3 and abs(x - SOUTH_GATE[0]) < GATE_HALF - 0.2:
            passages.add(cell)
        if abs(x - EAST_GATE[0]) < 0.6 and abs(z - EAST_GATE[1]) < GATE_HALF - 0.2:
            passages.add(cell)
    for cell in paved:
        t = tiles[cell]
        if not t["walkable"] and t.get("object_type_id") == "frontier_scene_solid" and cell in passages:
            raise SystemExit("road cell %s runs into a building or prop" % (cell,))
        if t["height_level"] != 0 or t.get("ramp_direction", -1) >= 0:
            raise SystemExit("paved cell %s is not flat ground" % (cell,))
        t["surface_type"] = "road"
        if not t["walkable"] and str(t.get("object_type_id", "")).startswith(("glut_sandstone", "spacekit_rock")):
            t.update({"walkable": True, "blocks_los": False, "cover_value": 0, "object_height": 0, "object_type_id": ""})
    beside_road = {(q + dq, r + dr) for (q, r) in paved for dq, dr in DIRS}
    for cell in beside_road - paved:                                # no boulders right at the kerb
        t = tiles.get(cell)
        if t and not t["walkable"] and str(t.get("object_type_id", "")).startswith(("glut_sandstone", "spacekit_rock")):
            t.update({"walkable": True, "blocks_los": False, "cover_value": 0, "object_height": 0, "object_type_id": ""})
    for cell in trails:
        t = tiles.get(cell)
        if t and t["height_level"] == 0 and t.get("ramp_direction", -1) < 0 and t["walkable"] and t["surface_type"] == "ground":
            t["surface_type"] = "sand"
    props, solids = list(presentation.get("props", [])), {}
    for asset, x, z, rot, scale in PROPS:
        path, half_w, half_d, height, los, cover = ASSETS[asset]
        props.append({"asset": asset, "center": [x, z], "path": path, "scale": scale, "rotation_degrees": rot,
                      "elevation": tiles[cell_at(x, z)]["height_level"] * 0.75 + (ROAD_DECK if cell_at(x, z) in paved else 0.0)})
        if half_w <= 0.0:
            continue
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
    keep = set(trails) | old_roads | passages
    for x, z in points.values():
        q, r = cell_at(x, z)
        keep.update((q + dq, r + dr) for dq in range(-1, 2) for dr in range(-1, 2) if abs(dq + dr) <= 1)
    for pad in pads:
        keep.update(c for c in tiles if abs(plane(*c)[0] - pad["center"][0]) < pad["size"][0] * 0.5 + 1.2
                    and abs(plane(*c)[1] - pad["center"][1]) < pad["size"][1] * 0.5 + 1.2)
    for cell in list(solids):
        if cell in keep or not tiles[cell]["walkable"] or tiles[cell].get("ramp_direction", -1) >= 0:
            del solids[cell]
    props.append({"asset": APRON[0], "center": [APRON[1], APRON[2]], "path": FH + APRON[0] + ".glb", "scale": 1.0,
                  "rotation_degrees": 0, "elevation": 0.0})
    for x0, z0, x1, z1 in FENCE_RUNS:                               # the perimeter wall: one blocked cell row
        for name, x, z, rot in fence_pieces(x0, z0, x1, z1):
            props.append({"asset": name, "center": [round(x, 3), round(z, 3)], "path": FH + name + ".glb", "scale": 1.0,
                          "rotation_degrees": rot, "elevation": 0.0})
        length = math.hypot(x1 - x0, z1 - z0)
        ux, uz = (x1 - x0) / length, (z1 - z0) / length
        for cell, t in tiles.items():
            x, z = plane(*cell)
            if not (FENCE[0] - 1.0 < x < FENCE[2] + 1.0 and FENCE[1] - 1.0 < z < FENCE[3] + 1.0):
                continue
            along, across = (x - x0) * ux + (z - z0) * uz, abs((x - x0) * uz - (z - z0) * ux)
            if -0.15 <= along <= length + 0.15 and across <= 0.47 and t["walkable"]:
                if cell in keep:
                    raise SystemExit("fence would block kept cell %s" % (cell,))
                solids[cell] = (2, True, 80)
    near_solid = {(q + dq, r + dr) for (q, r) in solids for dq in range(-1, 2) for dr in range(-1, 2)}
    rocks = {}
    for cell, t in tiles.items():
        x, z = plane(*cell)
        if not in_core(x, z) or not t["walkable"] or t.get("object_type_id") or cell in keep or cell in near_solid or cell in solids or cell in beside_road:
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

    for spec in presentation.get("structures", []):
        model = STRUCTURE_MODELS.get(spec.get("id", ""))
        if model:
            spec["model"] = FH + model + ".glb"
    presentation["props"] = props
    presentation["cliff_detail_bounds"] = list(CORES[0])
    data["place_world"]["dressing"] = {"revision": "handelsposten_r2_20261114", "base_revision": BASE_REVISION,
                                       "tool": "tools/dress_trade_outpost.py"}
    data["singleplayer_site"]["visual_status"] = "dressed 14.11.2026 (kit pieces, ore outcrops, sandstone); no user style approval"
    (ROOT / MAP).write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print("props", len(props), "new blocked cells", len(solids) + len(rocks), "rocks", len(rocks), "rocks swapped", swapped, "reachable", len(seen))
    for name, (x, z) in points.items():
        print(" ", name, cell_at(x, z), "ok")


if __name__ == "__main__":
    main()
