"""Compile only the three Glut ground maps to TerrainMapData's saved hex format.

The committed 96 x 98 inputs are read from the integration baseline by
default. --source-dir accepts an exported copy of the same authoring inputs.
Existing semantic IDs, pads and resource records stay fixed. Depot and chip
compounds move east; the safe campaign checkpoint contains no surface actors.
"""
from argparse import ArgumentParser
from hashlib import sha256
import json
from math import cos, sin, sqrt
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = "639a49d657086c9e436de89979fa04cc5d69ba39"
MAPS = {"A": "satellite_crash_site", "B": "trade_outpost", "C": "fortified_outpost"}
WIDTH, HEIGHT = 512, 256
MIN_COLUMN, MIN_ROW = -170, -108
DIRECTIONS = ((1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1))

# Layout is in offset columns and axial rows. The old site occupies an
# irregular axial core, so the regional approaches meet its flat apron.
ROUTES = {
    "A": [
        [(-165, -53), (-106, -35), (-64, -9), (-28, 8), (12, 11), (47, 13), (89, 33), (144, 51), (220, 46), (341, 51)],
        [(34, -8), (61, -25), (79, -53), (115, -57), (173, -41), (246, -74), (340, -55)],
        [(37, 38), (62, 61), (108, 82), (170, 106), (259, 110), (320, 71)],
    ],
    "B": [
        [(12, 11), (58, 29), (87, 45), (125, 40), (160, 35), (219, 37), (281, 18), (341, 19)],
        [(12, 11), (-28, 29), (-73, 88), (3, 109), (121, 109), (179, 77), (150, 41)],
        [(22, 16), (66, -9), (121, -26), (182, -70), (249, -52), (310, -20)],
    ],
    "C": [
        [(12, 11), (52, 24), (82, 43), (114, 49), (150, 41), (179, 44), (239, 41), (341, 35)],
        [(12, 11), (45, -9), (76, -13), (111, -10), (136, 4), (151, 24), (150, 41)],
    ],
}
# Authoring displacements are axial q only. Offworld campaign state contains
# no live actors or per-grid persistent entities at a legal checkpoint.
# Landing apron, local resource sites and the existing A mission targets
# share a low branch of the larger valley, with broad graduated shoulders.
LOCAL_A_ROUTES = [
    [(-1, 14), (12.5, 11), (25, 2), (34, -8)],
    [(12.5, 11), (25, 17), (38.5, 15), (43.5, 25), (37, 38)],
]
FIELD_LZ = {"B": (44, 29, 0), "C": (67, 46, 2)}
DEPOT_SHIFT = {"B": 66, "C": 91}
DEPOT_HEIGHT = {"B": 0, "C": 4}
DEPOT_MARKERS = {
    "B": ("objective_point", "recover_crate", "spawn_enemy_defense"),
    "C": ("objective_point", "outpost_chip", "spawn_enemy_defense"),
}


def distance_to_route(x, y, route):
    nearest = float("inf")
    for (ax, ay), (bx, by) in zip(route, route[1:]):
        dx, dy = bx - ax, by - ay
        t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
        nearest = min(nearest, (x - ax - t * dx) ** 2 + (y - ay - t * dy) ** 2)
    return nearest


def relief(zone, x, r):
    if zone == "A":
        center = 83 + 14 * sin((r - 4) / 39) + 7 * sin(r / 17)
        bank = abs(x - center) - (9 + 3 * sin(r / 29))
        # The asymmetric shoulder remains contiguous with the plateau.
        bank += 4 * sin(r / 18) if x < center else 2.5 * cos(r / 23)
        # Three broad shelves. Shift their breaks along the ravine so
        # escarpments do not appear as an even staircase on both sides.
        terrace = 0
        for threshold, level in [(-0.8, 1), (2.5 + 1.2 * sin(r / 13), 2),
                                 (7 + 3 * cos(r / 21), 5), (17 + 3 * sin(r / 16), 8)]:
            if bank > threshold:
                terrace = level
        valley_distance = sqrt(min(distance_to_route(x, r, route) for route in LOCAL_A_ROUTES))
        local_bank = max(0, int((valley_distance - 6) / 2.5))
        # Long spurs break up the high plain without adding isolated columns.
        ridge = 2 if sin(x / 32 + 1.2 * sin(r / 31)) + cos(r / 23) < -0.7 else 0
        height = min(max(0, terrace - ridge), local_bank)
        wash = abs(x - center - 2.2 * cos(r / 6)) < 3.5 + sin(r / 12)
        return height, "rock" if height >= 2 else ("sand" if wash else "ground"), False
    if zone == "B":
        ridge = abs(r - (62 - x * 0.34 + 16 * sin(x / 41)))
        spur = abs(r - (-64 + x * 0.25 + 14 * cos(x / 28)))
        fold = min(ridge, spur) + 3 * cos(x / 14)
        height = max(0, min(7, int((31 - fold) / 3.5)))
        return height, "rock" if height >= 2 else ("ground" if fold > 46 else "sand"), False
    fault = abs(x - 114 - 0.23 * r - 6 * sin(r / 20))
    branch = abs(x - 254 + 0.38 * r + 12 * sin(r / 18))
    if min(fault, branch) < 2.6:
        return 0, "rock", True
    if x < 98 and r > -30:
        height = max(0, min(4, int((x - 73) / 6)))
    else:
        highland = sin((x - r) / 24) + cos(r / 13)
        height = 4 + 2 * int(highland > -0.2) + 2 * int(highland > 1.05)
    return height, "rock" if height >= 2 else "sand", False


def geology_tile(zone, q, r, column, route_distances):
    x = column + (r % 2) * 0.5
    height, surface, fault = relief(zone, x, r)
    main, *alternates = route_distances
    route = main < 3.5**2 or min(alternates) < 2.7**2
    apron = main < 8.0**2 or min(alternates) < 6.0**2
    distance_to_core = max(-30 - q, q - 65, -30 - r, r - 67)
    # Match the old valley floor at its interface. The corridor elevation
    # rises one level at a time where the route enters the eastern shelf.
    if zone == "C":
        road_height = max(0, min(4, int((x - 76) / 7)))
    elif zone == "A":
        main_bank = abs(x - (83 + 14 * sin((r - 4) / 39) + 7 * sin(r / 17)))
        road_height = min(height, max(0, min(8, int((main_bank - 11) / 3.8))))
    else:
        road_height = max(0, height - 3)
    if zone != "A" and distance_to_core < 4:
        height = min(height, max(0, distance_to_core - 1))
        road_height = min(road_height, height)
    if apron and not fault:
        height = min(height, road_height + 1)
    bridge = zone == "C" and fault and route and road_height > 0
    if route:
        height, surface = road_height, "road" if bridge else "ground"
    blocked = fault and not bridge
    tile = {
        "grid_position": {"x": q, "y": r},
        "type_id": "ground_flat",
        "height_level": height,
        "surface_type": surface,
        "edge_type": "slope" if apron and not blocked else "cliff",
        "walkable": not blocked,
        "blocks_los": False,
    }
    if bridge:
        tile["object_type_id"] = "glut_bridge_deck"
    # Small groups of existing rock props are placed on exposed terraces,
    # away from travel corridors. The highland mass comes from terrain.
    if not apron and not blocked and height in (2, 3) and sin(q / 4) + cos(r / 6) > 1.66:
        seed = sha256(f"glut-v2:{zone}:geology:{q}:{r}".encode()).digest()
        if seed[0] < 19:
            tile.update(object_type_id="glut_sandstone_04", object_height=2,
                        object_rotation_degrees=int.from_bytes(seed[1:3]) % 360,
                        object_scale=round(0.82 + seed[3] / 900, 3),
                        walkable=False, blocks_los=True, cover_value=55)
    return tile


def clean_legacy_tile(tile, zone, source_tiles):
    q, r = tile["grid_position"]["x"], tile["grid_position"]["y"]
    variants = {"A": (1,), "B": (2,), "C": (2, 3)}[zone]
    if (any((q * 17 + r * 31 + variant * 7) % 29 == 0 for variant in variants)
            and not tile.get("object_type_id")
            and tile["height_level"] == 1 and tile["cover_value"] == 30
            and tile["surface_type"] == "rock" and tile["edge_type"] == "slope"):
        neighbors = [source_tiles.get((q + dq, r + dr), {}) for dq, dr in DIRECTIONS]
        ground = [neighbor.get("surface_type") for neighbor in neighbors if neighbor.get("height_level") == 0]
        surface = max(("sand", "ground", "rock"), key=ground.count)
        return dict(tile, height_level=0, cover_value=0, edge_type="none", surface_type=surface)
    return tile


def move_depot(zone, data, old):
    if zone not in DEPOT_SHIFT:
        return {}, set()
    shift = DEPOT_SHIFT[zone]
    height = DEPOT_HEIGHT[zone]
    presentation = data["place_presentation"]
    compound = presentation["structures"][-1]
    compound["center"][0] += shift
    compound["terrain_height_level"] = height
    if zone == "C":
        compound["name"] = "GESICHERTER AUSSENPOSTEN"
        presentation["structures"][0]["name"] = "LANDEZONEN-KONTROLLE"
        presentation["structures"][1]["name"] = "SCHUTZRAUM"
        presentation["pads"][0]["name"] = "GLUT 1 · 01"
    for key in DEPOT_MARKERS[zone]:
        data["markers"][key]["x"] += 64 * shift
        data["markers"][key]["y"] += 32 * shift
    moved, removed = {}, set()
    for (q, r), tile in old.items():
        # Includes the saved solid footprint and guard/interaction aprons.
        if abs(q + r * .5 - 59) > 9 or abs(r - 40) > 9:
            continue
        target_q = q + shift
        moved[target_q, r] = dict(clean_legacy_tile(tile, zone, old), grid_position={"x": target_q, "y": r},
                                  height_level=height, edge_type="slope")
        removed.add((q, r))
    # The front wall and its overhang were added after the original saved
    # solid footprint. Keep the adjacent approach and interaction cells open.
    front_wall = ((37, 37), (38, 37), (39, 37), (40, 37),
                  (37, 38), (38, 38), (39, 38))
    for q, r in front_wall:
        moved[q + shift, r].update(object_type_id="frontier_scene_solid",
                                   walkable=False, blocks_los=True,
                                   object_height=3, cover_value=80)
    return moved, removed


def compile_map(zone, name, source_dir, output_dir):
    filename = name + ".json"
    if source_dir is None:
        source = subprocess.check_output(["git", "show", f"{BASE}:maps/{filename}"], cwd=ROOT)
    else:
        source = (source_dir / filename).read_bytes()
    data = json.loads(source)
    if data["grid_topology"] != "hex_axial_v1" or len(data["tiles"]) != 9408:
        raise ValueError(f"{filename}: expected the 96 x 98 authoring input")
    old = {(tile["grid_position"]["x"], tile["grid_position"]["y"]): tile for tile in data["tiles"]}
    moved, removed = move_depot(zone, data, old)
    tiles = []
    for r in range(MIN_ROW, MIN_ROW + HEIGHT):
        for column in range(MIN_COLUMN, MIN_COLUMN + WIDTH):
            q = column - r // 2
            if (q, r) in moved:
                tiles.append(moved[q, r])
                continue
            preserved = old.get((q, r))
            if zone == "A" and preserved is not None:
                # Preserve working objects and their immediate apron. The
                # old procedural field is superseded by the valley profile.
                if preserved.get("object_type_id") not in (None, "", "spacekit_rock_large_a"):
                    tiles.append(preserved)
                    continue
                if min(distance_to_route(q + r * .5, r, route) for route in LOCAL_A_ROUTES) < 4.0**2:
                    tiles.append(clean_legacy_tile(preserved, zone, old))
                    continue
            elif preserved is not None:
                if (q, r) in removed and preserved.get("object_type_id") == "frontier_scene_solid":
                    tiles.append({"grid_position": {"x": q, "y": r}, "type_id": "ground_flat", "surface_type": "ground", "height_level": 0, "edge_type": "none"})
                else:
                    tiles.append(clean_legacy_tile(preserved, zone, old))
                continue
            distances = [distance_to_route(column, r, route) for route in ROUTES[zone]]
            tiles.append(geology_tile(zone, q, r, column, distances))
    # High ground only needs a LOS flag along exposed escarpments; the
    # interior of a same-height plateau is clear.
    index = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in tiles}
    if zone in FIELD_LZ:
        q0, r0, pad_height = FIELD_LZ[zone]
        for dq in range(-5, 6):
            for dr in range(-5, 6):
                distance = max(abs(dq), abs(dr), abs(dq + dr))
                if distance > 5:
                    continue
                tile = index[q0 + dq, r0 + dr]
                if tile.get("object_type_id") not in (None, "", "spacekit_rock_large_a", "glut_sandstone_04"):
                    raise ValueError("Field LZ overlaps a persistent object")
                tile.pop("object_type_id", None)
                tile.update(height_level=pad_height if distance <= 3 else max(0, pad_height - distance + 3),
                            edge_type="slope", surface_type="ground", walkable=True,
                            blocks_los=False, object_height=0, cover_value=0)
    isolated_rises = [
        tile for (q, r), tile in index.items()
        if tile["height_level"] == 1 and not tile.get("object_type_id")
        and all(index.get((q + dq, r + dr), {}).get("height_level", 0) == 0
                for dq, dr in DIRECTIONS)
    ]
    for tile in isolated_rises:
        tile.update(height_level=0, edge_type="none", cover_value=0)
    for (q, r), tile in index.items():
        if tile["height_level"] < 3 or tile.get("object_type_id") or tile["edge_type"] != "cliff":
            continue
        if any(tile["height_level"] - index.get((q + dq, r + dr), tile)["height_level"] >= 2
               for dq, dr in DIRECTIONS):
            tile.update(blocks_los=True, cover_value=25)
    data["tiles"] = tiles
    data["grid_size"] = {"x": WIDTH, "y": HEIGHT}
    data["regional_terrain_version"] = 2
    data["regional_height_step"] = 0.75
    data["place_world"]["regional_extent"] = {
        "version": 2,
        "layout": "odd_r_offset",
        "offset_min": [MIN_COLUMN, MIN_ROW],
        "axial_min": [min(t["grid_position"]["x"] for t in tiles), MIN_ROW],
        "source_sha256": sha256(source).hexdigest(),
        "profile": zone,
        "routes_offset": ROUTES[zone],
        "depot_q_displacement": DEPOT_SHIFT.get(zone, 0),
        "field_lz": FIELD_LZ.get(zone),
    }
    target = output_dir / filename
    temporary = target.with_suffix(".json.tmp")
    with temporary.open("w", encoding="utf-8", newline="\n") as output:
        root = {key: value for key, value in data.items() if key != "tiles"}
        output.write(json.dumps(root, ensure_ascii=False, indent=2)[:-2])
        output.write(',\n  "tiles": [\n')
        output.write(",\n".join("    " + json.dumps(tile, separators=(",", ":"), ensure_ascii=False) for tile in tiles))
        output.write("\n  ]\n}\n")
    temporary.replace(target)


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("zones", nargs="+", choices=MAPS)
    parser.add_argument("--source-dir", type=Path)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "maps")
    args = parser.parse_args()
    for zone in args.zones:
        compile_map(zone, MAPS[zone], args.source_dir, args.output_dir)


if __name__ == "__main__":
    main()
