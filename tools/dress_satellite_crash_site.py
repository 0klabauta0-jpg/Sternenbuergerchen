"""Satellite crash site (14.11.2026): dressing pass over the campaign map.

Terrain, markers, resource sites, ramps and the regional extent stay exactly as
the campaign builder made them. This pass adds what the place was missing: a
raised landing pad, a tarred road to the trade post, trails, the satellite
wreck at the end of a long impact furrow with berms and shed parts, a visible
freighter wreck and ore outcrops at the three resource sites, a small trade
post ensemble and loose rock cover in the core.

Idempotent: always starts from the map as committed in BASE_REVISION.
Run:  python3 tools/dress_satellite_crash_site.py
"""
import json
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_windbruch_outpost as wb  # shared hex, noise and asset helpers

ROOT = Path(__file__).resolve().parents[1]
MAP = "maps/satellite_crash_site.json"
BASE_REVISION = "068784888"
DIRS = wb.DIRS
plane, cell_at, fbm, dist = wb.plane, wb.cell_at, wb.fbm, wb.dist_to_polyline
KIT = "res://Assets/curated/absturz_kit_20261114/"
ASSETS = dict(wb.ASSETS)
ASSETS.update({
    "sat_wreck": (KIT + "ab_satellite_wreck.glb", 1.5, 1.0, 2, True, 70),
    "solar_fragment": (KIT + "ab_solar_fragment.glb", 0.7, 0.3, 1, False, 35),
    "debris": (KIT + "ab_debris_small.glb", 0.0, 0.0, 0, False, 0),
    "berm": (KIT + "ab_furrow_berm.glb", 0.0, 0.0, 0, False, 0),
    "ore_a": (KIT + "ab_ore_outcrop_a.glb", 0.6, 0.5, 1, False, 45),
    "ore_b": (KIT + "ab_ore_outcrop_b.glb", 0.6, 0.5, 1, False, 45),
    "freighter_hull": (KIT + "ab_freighter_hull.glb", 0.0, 0.0, 0, False, 0),
})
PAD = {"id": "satellite_pad_01", "center": (12.5, 9.6), "size": (6.2, 5.2), "name": "LANDEFELD · 01"}
FURROW = ((9.0, 22.0), (34.4, 31.7))
SKIPS = [(2.6, 19.6, 1.5), (-3.0, 17.4, 1.1), (-7.4, 15.8, 0.8)]          # where it first touched down
ROADS = [[(15.9, 9.6), (22.0, 6.0), (27.5, -1.0), (32.4, -6.4)]]
TRAILS = [
    [(14.0, 12.4), (19.0, 17.5), (28.0, 25.6), (36.4, 31.0)],               # landing field -> satellite
    [(9.2, 10.4), (4.0, 11.4), (0.6, 11.9)],                                # -> A-Benit ridge
    [(33.4, -5.4), (37.0, 3.0), (38.6, 11.6)],                              # trade post -> freighter wreck
    [(38.6, 13.4), (40.4, 19.4), (43.0, 21.0)],                             # -> B-Benit
    [(28.0, 25.6), (36.0, 22.6), (42.6, 22.2)],
]
CORE = (-22.0, -28.0, 72.0, 48.0)
# (asset, x, z, rotation, scale, solid)
PROPS = [
    ("container_stack", 26.6, -9.4, 10, 1.0, True), ("container_petrol", 37.4, -8.2, 25, 1.0, True),
    ("crates", 29.6, -6.6, 0, 1.0, True), ("barrels", 36.6, -5.0, 0, 1.0, True), ("power", 38.0, -11.6, 0, 1.0, True),
    ("solar", 26.4, -13.0, 0, 1.0, True), ("solar", 23.2, -12.4, 0, 1.0, True), ("hull_hab", 22.6, -7.6, 12, 1.0, True),
    ("container_orange", 17.6, 6.4, 40, 1.0, True), ("crates", 9.4, 6.4, 0, 1.0, True), ("barrels", 16.4, 12.9, 0, 1.0, True),
    ("fuel_unit", 8.2, 13.6, 90, 0.35, True),
    # freighter wreck: visuals inside the cells the resource site already blocks
    ("freighter_hull", 44.6, 13.4, 25, 1.0, False), ("wreck_wing", 42.2, 10.2, -30, 1.0, False),
    ("wreck_wing", 47.2, 16.8, 60, 1.0, False), ("wreck_engine", 41.4, 16.6, 15, 1.0, False),
    ("debris", 39.4, 9.4, 0, 1.0, False), ("debris", 50.2, 13.0, 70, 1.0, False), ("debris", 44.0, 19.4, 30, 1.0, False),
    # ore sites
    ("ore_a", -2.8, 10.8, 0, 1.0, True), ("ore_a", -2.2, 14.0, 70, 1.0, True), ("ore_a", 0.9, 9.9, -40, 0.8, True),
    ("ore_b", 45.2, 20.4, 0, 1.0, True), ("ore_b", 42.4, 23.6, 50, 1.0, True), ("ore_b", 45.4, 23.4, -60, 0.8, True),
]


def main() -> None:
    raw = subprocess.run(["git", "show", "%s:%s" % (BASE_REVISION, MAP)], cwd=ROOT, capture_output=True, check=True).stdout
    data = json.loads(raw.decode("utf-8"))
    origin = data["grid_origin"]
    wb.ORIGIN = (float(origin["x"]), float(origin["y"]))
    tiles = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in data["tiles"]}
    resources = json.loads((ROOT / "data/singleplayer/location_resources.json").read_text(encoding="utf-8"))
    sites = {k: plane(*v["grid"]) for k, v in resources.get("satellite_crash", resources).items() if isinstance(v, dict) and "grid" in v}

    def marker_plane(m):
        a, b = (m["x"] - origin["x"]) / 64.0, (m["y"] - origin["y"]) / 32.0
        return ((a + b) * 0.5, (b - a) * 0.5)

    points = {k: marker_plane(m) for k, m in data["markers"].items()}
    points.update(sites)
    # the old stand-in objects make way for the new models
    for t in tiles.values():
        if t.get("object_type_id") in ("spacekit_satellite_dish_detailed", "station_container_wide"):
            for key in ("object_type_id", "object_height", "object_rotation_degrees", "object_scale"):
                t.pop(key, None)
            t.update({"walkable": True, "blocks_los": False, "cover_value": 0})

    roads, trails, furrow = set(), set(), set()
    for line in ROADS:
        wb.stroke(roads, line)
    for line in TRAILS:
        wb.stroke(trails, line)
    (fx0, fz0), (fx1, fz1) = FURROW
    length = math.hypot(fx1 - fx0, fz1 - fz0)
    ux, uz = (fx1 - fx0) / length, (fz1 - fz0) / length
    for cell, t in tiles.items():
        x, z = plane(*cell)
        if not (CORE[0] < x < CORE[2] and CORE[1] < z < CORE[3]):
            continue
        along = (x - fx0) * ux + (z - fz0) * uz
        across = abs((x - fx0) * uz - (z - fz0) * ux)
        width = 0.9 + 0.9 * max(0.0, min(1.0, along / length)) + 0.35 * fbm(x * 0.3, z * 0.3, 411)
        if -0.5 <= along <= length + 0.6 and across < width:
            furrow.add(cell)
        if any(math.hypot(x - sx, z - sz) < radius for sx, sz, radius in SKIPS):
            furrow.add(cell)
    pad_cells = {c for c in tiles if abs(plane(*c)[0] - PAD["center"][0]) < PAD["size"][0] * 0.5 + 0.3
                 and abs(plane(*c)[1] - PAD["center"][1]) < PAD["size"][1] * 0.5 + 0.3}
    for cell in roads | trails | furrow | pad_cells:
        t = tiles.get(cell)
        if t is None or t["height_level"] != 0 or t.get("ramp_direction", -1) >= 0 or not t["walkable"]:
            continue
        t["surface_type"] = "road" if (cell in roads or cell in pad_cells) else "sand"

    props, solids = [], {}

    def add_prop(asset, x, z, rot, scale=1.0, solid=True):
        path, half_w, half_d, height, los, cover = ASSETS[asset]
        on_pad = abs(x - PAD["center"][0]) < PAD["size"][0] * 0.5 and abs(z - PAD["center"][1]) < PAD["size"][1] * 0.5
        level = tiles[cell_at(x, z)]["height_level"]
        props.append({"asset": asset, "center": [round(x, 3), round(z, 3)], "path": path, "scale": scale,
                      "rotation_degrees": round(rot, 2), "elevation": level * 0.75 + (0.12 if on_pad else 0.0)})
        if not solid or half_w <= 0.0:
            return
        c, sn = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        q0, r0 = cell_at(x, z)
        reach = int(math.ceil(max(half_w, half_d) * scale)) + 2
        for dq in range(-reach, reach + 1):
            for dr in range(-reach, reach + 1):
                cell = (q0 + dq, r0 + dr)
                if cell not in tiles:
                    continue
                px, pz = plane(*cell)
                lx, lz = (px - x) * c - (pz - z) * sn, (px - x) * sn + (pz - z) * c
                if abs(lx) <= half_w * scale and abs(lz) <= half_d * scale:
                    solids[cell] = (height, los, cover)

    for asset, x, z, rot, scale, solid in PROPS:
        add_prop(asset, x, z, rot, scale, solid)
    yaw = -math.degrees(math.atan2(uz, ux))
    add_prop("sat_wreck", fx1 + ux * 0.4, fz1 + uz * 0.4, yaw, 1.6)
    steps = int(length / 2.3)
    for i in range(steps):                                      # berms on both sides, with gaps
        along = 1.0 + i * 2.3
        widen = 1.5 + 0.9 * along / length
        for side in (-1, 1):
            if wb._hash(i, side, 421) < 0.22:
                continue
            jitter = (wb._hash(i, side, 431) - 0.5) * 0.5
            add_prop("berm", fx0 + ux * along - uz * side * (widen + jitter), fz0 + uz * along + ux * side * (widen + jitter),
                     yaw + (wb._hash(i, side, 433) - 0.5) * 24.0, 1.0 + 0.8 * along / length)
    for i in range(14):                                         # shed parts fan out towards the wreck
        along = length * (0.18 + 0.8 * wb._hash(i, 3, 441))
        off = (2.6 + 3.4 * wb._hash(i, 5, 443)) * (1 if wb._hash(i, 7, 445) > 0.5 else -1)
        x, z = fx0 + ux * along - uz * off, fz0 + uz * along + ux * off
        if tiles[cell_at(x, z)]["height_level"] == 0:
            add_prop("solar_fragment" if i % 5 == 0 else "debris", x, z, 360.0 * wb._hash(i, 9, 447), 1.3, i % 5 == 0)

    keep = set(roads) | set(trails) | set(furrow) | pad_cells
    for x, z in points.values():
        q, r = cell_at(x, z)
        keep.update((q + dq, r + dr) for dq in range(-1, 2) for dr in range(-1, 2) if abs(dq + dr) <= 1)
    for cell in list(solids):
        if cell in keep or not tiles[cell]["walkable"] or tiles[cell].get("ramp_direction", -1) >= 0:
            del solids[cell]
    near_solid = {(q + dq, r + dr) for (q, r) in solids for dq in range(-1, 2) for dr in range(-1, 2)}
    rocks = {}
    for cell, t in tiles.items():
        x, z = plane(*cell)
        if not (CORE[0] < x < CORE[2] and CORE[1] < z < CORE[3]) or not t["walkable"] or t.get("object_type_id"):
            continue
        if cell in keep or cell in near_solid or cell in solids or t.get("ramp_direction", -1) >= 0 or t["surface_type"] == "road":
            continue
        if any(math.hypot(x - px, z - pz) < 3.0 for px, pz in points.values()):
            continue
        if dist(x, z, list(FURROW)) < 4.0 or abs(x - PAD["center"][0]) < 6.0 and abs(z - PAD["center"][1]) < 5.5:
            continue
        lv = t["height_level"]
        chance = 0.5 if wb.value_noise(x * 0.31, z * 0.31, 451) > 0.82 else 0.0
        if any(tiles.get((cell[0] + dq, cell[1] + dr), t)["height_level"] >= lv + 2 for dq, dr in DIRS):
            chance = max(chance, 0.10)
        if t["surface_type"] == "sand":
            chance *= 0.35
        if wb._hash(cell[0], cell[1], 463) < chance:
            rocks[cell] = (round(0.82 + 0.4 * wb._hash(cell[0], cell[1], 467), 3), int(wb._hash(cell[0], cell[1], 473) * 360))
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
    problems += ["route cell blocked %s" % (plane(*c),) for c in (roads | trails) if c in tiles and c in solids]
    if problems:
        raise SystemExit("\n".join(problems))

    presentation = data["place_presentation"]
    presentation["pads"] = [{"id": PAD["id"], "center": list(PAD["center"]), "size": list(PAD["size"]), "name": PAD["name"]}]
    presentation["props"] = props
    presentation["cliff_detail_bounds"] = list(CORE)
    data["place_world"]["dressing"] = {"revision": "absturz_r1_20261114", "base_revision": BASE_REVISION,
                                       "furrow_plane": [list(FURROW[0]), list(FURROW[1])], "tool": "tools/dress_satellite_crash_site.py"}
    data["singleplayer_site"]["visual_status"] = "dressed 14.11.2026 (pad, road, wreck, furrow, sites); no user style approval"
    (ROOT / MAP).write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    changed = sum(1 for c in solids) + len(rocks)
    print("props", len(props), "new blocked cells", changed, "rocks", len(rocks), "furrow cells", len(furrow), "reachable", len(seen))
    for name, (x, z) in points.items():
        print(" ", name, cell_at(x, z), "ok")


if __name__ == "__main__":
    main()
