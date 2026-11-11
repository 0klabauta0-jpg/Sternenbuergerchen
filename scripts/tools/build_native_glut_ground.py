"""Compile only the three Glut ground maps to TerrainMapData's saved hex format.

The committed 96 x 98 inputs are read from the integration baseline by
default. --source-dir accepts an exported copy of the same authoring inputs.
Existing semantic IDs, pads and resource records stay fixed. Depot and chip
compounds move east; the safe campaign checkpoint contains no surface actors.
"""
from argparse import ArgumentParser
from collections import Counter, deque
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

# Broad authored landforms, in the physical hex plane (x, axial row). Each
# ellipse contributes nested, connected shelves; their unions make ridges.
# The small coherent contour offset breaks symmetry without single-cell noise.
MESAS = {
    "A": [(-150,-72,53,30,8),(-112,-39,48,25,6),(-68,-78,39,24,8),
          (-35,-38,35,21,6),(25,-66,41,27,8),(12,61,37,25,6),
          (-71,59,43,27,8),(-129,104,52,29,8),(48,102,37,25,6),
          (131,-82,40,25,8),(156,-18,42,24,6),(135,27,28,20,6),
          (171,88,45,26,8),(219,-69,40,28,6),(233,5,51,26,8),
          (280,83,42,27,6),(321,-40,48,34,8),(335,137,43,29,8),
          (-30,24,31,20,6),(61,57,27,21,6),(58,-23,28,18,6),
          (103,110,34,27,8),(217,125,45,29,8),(234,-104,40,22,8)],
    "B": [(-147,-72,62,25,8),(-81,-43,49,23,6),(-27,-66,43,27,8),
          (31,-46,33,24,6),(86,-76,40,25,8),(151,-60,39,22,6),
          (210,-88,53,29,8),(285,-63,52,27,8),(-133,21,53,24,6),
          (-79,49,48,24,8),(-16,67,34,21,6),(48,75,36,22,8),
          (104,78,35,20,6),(162,12,35,22,8),(223,76,45,26,8),
          (283,53,43,25,6),(333,99,47,30,8),(-77,140,57,25,8),
          (23,143,43,22,6),(139,139,51,29,8),
          (61,18,22,15,6),(71,-15,30,20,6),(123,-9,27,18,6),
          (-11,26,23,16,4),(291,-4,34,23,6)],
    "C": [(-143,-62,61,33,8),(-88,-23,45,29,8),(-58,30,41,27,8),
          (-102,105,55,31,8),(4,102,39,25,6),(26,-61,40,27,8),
          (70,-80,40,25,8),(66,90,32,21,6),(151,-62,40,24,8),
          (174,1,33,25,8),(190,84,39,24,8),(249,-51,43,27,8),
          (282,8,39,24,8),(302,106,51,30,8),(343,-89,43,28,8),
          (117,95,31,27,8),(219,105,35,24,8),(318,-40,42,28,8),
          (205,-83,26,26,6),(183,43,21,17,6)],
}

# Open loops are deliberately legible from the landing region. C retains the
# previous crossing centres, but the two climbs now have explicit straight
# ramp approaches and level benches. Saved bridge footprints are overlaid last.
COMPOSITION_ROUTES = {
    "A": ROUTES["A"] + [
        [(34,-8),(63,-24),(94,-30),(145,-35),(196,-23),(246,-6),(288,26),(220,46)],
        [(37,38),(16,53),(-27,50),(-64,27),(-64,-9)],
        [(144,51),(143,73),(170,106)],
        [(246,-74),(283,-53),(308,-14),(320,71),(259,110)],
    ],
    "B": ROUTES["B"] + [
        [(66,-9),(88,6),(125,40)],
        [(249,-52),(277,-22),(281,18)],
        [(219,37),(252,91),(179,77)],
    ],
    "C": [
        [(12,11),(52,24),(59,39),(63,46),(79,46),(90,46),(96,46),(111,46),
         (114,49),(150,41),(179,44),(239,41),(341,35)],
        [(12,11),(45,-9),(63,-12),(79,-12),(94,-12),(110,-12),
         (111,-10),(136,4),(151,24),(150,41)],
        [(150,41),(169,66),(213,82),(253,72),(281,50),(239,41)],
        [(136,4),(165,-25),(207,-33),(235,-9),(239,41)],
    ],
}

# q, r, upward direction, bottom level, number of rises. A full ramp is
# followed by five flat cells before the next rise, never a ramp chain.
STAIRS = {
    "A": [("west_rim",-80,27,5,0,4),("east_overlook",119,50,(2,1,1,2),0,4),
          ("north_table",150,-54,2,0,6)],
    "B": [("southern_overlook",15,104,2,0,6),("depot_watch",145,36,(2,3,2,1,2,1),0,6),
          ("western_pass",-117,88,2,0,4)],
    "C": [("main_lower",40,46,0,0,2),("main_upper",73,46,0,2,2),
          ("flank_lower",69,-12,0,0,2),("flank_upper",96,-12,0,2,2),
          ("citadel_overlook",149,40,(2,1,1,2),4,4)],
}
CORNER_BANDS={"A":(109,50,0),"B":(133,38,0),"C":(137,48,4)}


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


def composed_height(zone, x, r):
    """Large coherent silhouettes; detail never creates a random height pin."""
    height = 0
    if zone == "C":
        lower_bank = 73 + 8 * sin(r / 21) + 3 * sin(r / 7)
        upper_bank = 105 + 7 * sin(r / 31) + 3 * sin(r / 11)
        height = 2 if x >= lower_bank else 0
        if x >= upper_bank:
            height = 4
    for cx, cy, rx, ry, peak in MESAS[zone]:
        # B's oblique shelves create a different grain from A's branching wash.
        yy = r - cy + (x - cx) * (0.23 if zone == "B" else -0.06)
        radial = sqrt(((x - cx) / rx) ** 2 + (yy / ry) ** 2)
        phase = 3 * sin(cx * 0.137 + cy * 0.17)
        radial += (0.13 * sin((x-cx)/rx*3.7 + sin((r-cy)/ry*2) + phase)
                   + 0.08 * cos((r-cy)/ry*5 + phase*1.7) - 0.05 * sin((x+r)/9))
        level = 0
        for boundary, shelf in ((1.10, 1), (0.98, 2), (0.84, max(2,peak-2)), (0.63, peak)):
            if radial < boundary:
                level = min(peak, shelf)
        height = max(height, level)
    return height


def hex_disk(q, r, radius):
    for dq in range(-radius, radius + 1):
        for dr in range(max(-radius, -dq - radius), min(radius, -dq + radius) + 1):
            yield q + dq, r + dr


def carve_flat(index, cells, height, protected, surface="ground"):
    for position in cells:
        if position not in index or position in protected:
            continue
        tile = index[position]
        tile.update(height_level=height, ramp_direction=-1, edge_type="cliff",
                    surface_type=surface, walkable=True, blocks_los=False, cover_value=0)
        if tile.get("object_type_id") == "glut_sandstone_04":
            for key in ("object_type_id", "object_height", "object_rotation_degrees", "object_scale"):
                tile.pop(key, None)


def author_stair(index, spec, protected):
    name, q, r, direction, bottom, rises = spec
    directions = [direction] * rises if isinstance(direction,int) else list(direction)
    if len(directions) != rises:
        raise ValueError(f"{name}: one direction per rise required")
    start=(q,r)
    bends=[]
    # Each stage has one five-hex-wide ramp band and flat turning platforms.
    # Consecutive bands may turn by 60 degrees, but never bend inside a ramp.
    for rise, direction in enumerate(directions):
        if rise and (direction-directions[rise-1]) % 6 not in (0,1,5):
            raise ValueError(f"{name}: turns must be 60 degrees")
        dq,dr=DIRECTIONS[direction]
        sq,sr=DIRECTIONS[(direction+2)%6]
        last_step=8 if rise==rises-1 else 6
        for step in range(last_step+1):
            level=bottom+rise+(1 if step>=4 else 0)
            for lane in range(-2,3):
                position=(q+step*dq+lane*sq,r+step*dr+lane*sr)
                if position in protected:
                    raise ValueError(f"{name}: ramp approach touches persistent footprint {position}")
                carve_flat(index,[position],level,protected,"ground")
                if step==3:
                    index[position].update(ramp_direction=direction,edge_type="slope")
        bends.append((q,r,bottom+rise))
        q,r=q+last_step*dq,r+last_step*dr
    end=(q,r)
    for q0,r0,level in bends:
        carve_flat(index,hex_disk(q0,r0,2),level,protected)
    carve_flat(index, hex_disk(*start, 2), bottom, protected)
    carve_flat(index, hex_disk(*end, 4), bottom + rises, protected, "rock")
    return {"id": name, "start_axial": start, "end_axial": end,
            "bottom": bottom, "top": bottom + rises, "direction": directions[0],
            "directions":directions,"band_width_hex":5,
            "ramp_cells": 5 * rises, "flat_cells_between_rises": 5}


def author_corner_band(zone,index,protected):
    """One continuous five-cell shoulder around a 60-degree terrace corner.

    Adjacent ramps deliberately change from direction 2 to direction 1.
    Their shared flank endpoints are H+0.5; all low/high neighbours are
    explicitly sculpted at H/H+1. This is a visible native corner specimen,
    not a hidden exception to the tile transition contract.
    """
    q0,r0,bottom=CORNER_BANDS[zone]
    footprint=[(q,r) for q in range(q0-2,q0+7) for r in range(r0-4,r0+5)
               if max(abs(q-q0-2),abs(r-r0),abs(q-q0-2+r-r0))<=6]
    for q,r in footprint:
        if (q,r) in protected or index[q,r]["ramp_direction"]>=0:
            raise ValueError(f"{zone}: corner band overlaps an existing authored feature")
        high=r<r0 or q>=q0+3
        carve_flat(index,[(q,r)],bottom+int(high),protected,"ground")
    ramps=[(q0,r0,2),(q0+1,r0,2),(q0+2,r0,1),(q0+2,r0+1,1),(q0+2,r0+2,1)]
    for q,r,direction in ramps:
        index[q,r].update(height_level=bottom,ramp_direction=direction,edge_type="slope")
    return {"id":"curved_corner_band","start_axial":[q0+1,r0+2],
            "end_axial":[q0+4,r0],"bottom":bottom,"top":bottom+1,
            "direction":2,"directions":[2,2,1,1,1],"band_width_hex":5,
            "ramp_cells":5,"flat_cells_between_rises":0,
            "corner_axial":[q0+2,r0],"profile":"shared_midheight_side_edges"}


def compose_terrain(zone, data, index):
    # Preserve actual persistent assets and every previously authored bridge.
    # Existing decorative rocks keep their footprint and adopt their shelf.
    protected = {p: dict(t) for p, t in index.items()
                 if t.get("object_type_id") not in (None, "", "glut_sandstone_04", "spacekit_rock_large_a")}
    old_rocks = {p: dict(t) for p, t in index.items() if t.get("object_type_id") == "spacekit_rock_large_a"}
    for (q, r), tile in index.items():
        x = q + r * 0.5
        height = composed_height(zone, x, r)
        routes = COMPOSITION_ROUTES[zone]
        route_distance = sqrt(min(distance_to_route(x, r, route) for route in routes))
        if zone == "A":
            route_distance = min(route_distance, sqrt(min(distance_to_route(x, r, route) for route in LOCAL_A_ROUTES)))
        # A wide basin joins all existing settlement anchors organically.
        basin = ((x - 17) / (30 if zone == "A" else 35)) ** 2 + ((r - 16) / 27) ** 2
        route_height = (0 if x < 73 else 2 if x < 105 else 4) if zone == "C" else 0
        if route_distance < 5.0 + 0.8 * sin((x + r) / 19):
            height = route_height
        if basin < 1:
            height = 0
        surface = "rock" if height >= 2 else "ground"
        if route_distance < 1.8:
            surface = "sand" if zone == "A" else "ground"
        fault = zone == "C" and min(abs(x - 114 - 0.23 * r - 6 * sin(r / 20)),
                                    abs(x - 254 + 0.38 * r + 12 * sin(r / 18))) < 2.6
        tile.clear()
        tile.update(grid_position={"x": q, "y": r}, type_id="ground_flat",
                    height_level=0 if fault else height, surface_type="rock" if fault else surface,
                    edge_type="cliff", ramp_direction=-1, walkable=not fault,
                    blocks_los=False, cover_value=0)
    # Preserve flat object aprons, landing pads and the original mission loop.
    for position, tile in protected.items():
        if tile.get("object_type_id") != "glut_bridge_deck":
            carve_flat(index, hex_disk(*position, 2), int(tile["height_level"]), protected)
    carve_flat(index, hex_disk(7, 11, 7), 0, protected)
    if zone in FIELD_LZ:
        q, r, height = FIELD_LZ[zone]
        carve_flat(index, hex_disk(q, r, 5), height, protected)
    # Bridge approach decks are level H4; the ravine keeps its exact authored
    # footprint and is never silently converted into a second walkable layer.
    for (q, r), tile in protected.items():
        if tile.get("object_type_id") == "glut_bridge_deck":
            for cell in hex_disk(q, r, 2):
                if cell in index and index[cell]["walkable"]:
                    carve_flat(index, [cell], 4, protected)
    stairs = [author_stair(index, spec, protected) for spec in STAIRS[zone]]
    stairs.append(author_corner_band(zone,index,protected))
    for position, tile in old_rocks.items():
        height = index[position]["height_level"]
        tile.update(height_level=height, ramp_direction=-1, edge_type="cliff")
        index[position].update(tile)
    for position, tile in protected.items():
        index[position].clear()
        index[position].update(tile, ramp_direction=-1, edge_type="cliff")
    # Small connected contour remnants are absorbed, not rendered as pins.
    for _ in range(2):
        isolated = [p for p, t in index.items() if t["height_level"] > 0
                    and t["ramp_direction"] == -1 and not t.get("object_type_id")
                    and all(index.get((p[0]+dq,p[1]+dr), t)["height_level"] < t["height_level"]
                            for dq,dr in DIRECTIONS)]
        for p in isolated:
            height=max(index.get((p[0]+dq,p[1]+dr),index[p])["height_level"] for dq,dr in DIRECTIONS)
            index[p].update(height_level=height, surface_type="rock" if height>=2 else "ground")
    # A bounded existing asset vocabulary adds local rhythm to cliff toes.
    candidates = []
    for (q, r), tile in index.items():
        if tile.get("object_type_id") or not tile["walkable"] or tile["ramp_direction"] >= 0:
            continue
        height = tile["height_level"]
        neighbors = [index.get((q+dq, r+dr), tile) for dq,dr in DIRECTIONS]
        if height >= 2 and any(height - n["height_level"] >= 2 for n in neighbors):
            tile.update(blocks_los=True, cover_value=25)
        if height in (2,4,6) and any(n["height_level"] >= height + 2 for n in neighbors):
            seed = sha256(f"glut-composition-v3:{zone}:{q}:{r}".encode()).digest()
            candidates.append((seed, (q,r)))
    chosen = []
    for seed, (q,r) in sorted(candidates):
        if any(max(abs(q-a),abs(r-b),abs(q-a+r-b)) < 4 for a,b in chosen):
            continue
        if any(index.get(p,{}).get("ramp_direction",-1) >= 0 for p in hex_disk(q,r,5)):
            continue
        index[q,r].update(object_type_id="glut_sandstone_04", object_height=2,
                          object_rotation_degrees=int.from_bytes(seed[1:3]) % 360,
                          object_scale=round(0.86+seed[3]/1100,3), walkable=False,
                          blocks_los=True,cover_value=55)
        chosen.append((q,r))
        if len(chosen) >= 72:
            break
    return stairs, protected


def can_cross(index, source, target):
    a, b = index.get(source), index.get(target)
    if not a or not b or not a.get("walkable",True) or not b.get("walkable",True):
        return False
    difference = (target[0]-source[0],target[1]-source[1])
    if difference not in DIRECTIONS:
        return False
    direction = DIRECTIONS.index(difference)
    heights = []
    for tile, outgoing in ((a,direction),(b,(direction+3)%6)):
        ramp = tile.get("ramp_direction",-1)
        if ramp == -1:
            heights.append(tile["height_level"])
        elif outgoing == ramp:
            heights.append(tile["height_level"]+1)
        elif outgoing == (ramp+3)%6:
            heights.append(tile["height_level"])
        else:
            heights.append(tile["height_level"]+0.5)
    return heights[0] == heights[1]


def validate_composition(zone, data, index, stairs, protected):
    failures = []
    ramp_count = 0
    for (q,r), tile in index.items():
        direction = tile.get("ramp_direction",-1)
        if direction < 0:
            continue
        ramp_count += 1
        if not 0 <= direction <= 5 or not 0 <= tile["height_level"] <= 7:
            failures.append(["invalid_ramp",q,r])
            continue
        dq,dr = DIRECTIONS[direction]
        if not can_cross(index,(q-dq,r-dr),(q,r)) or not can_cross(index,(q,r),(q+dq,r+dr)):
            failures.append(["disconnected_ramp",q,r])
    expected_ramps=sum(stair["ramp_cells"] for stair in stairs)
    if ramp_count!=expected_ramps:
        failures.append(["ramp_count",ramp_count,expected_ramps])
    start=(7,11)
    reached={start}
    queue=deque([start])
    while queue:
        current=queue.popleft()
        for dq,dr in DIRECTIONS:
            target=(current[0]+dq,current[1]+dr)
            if target not in reached and can_cross(index,current,target):
                reached.add(target)
                queue.append(target)
    anchors=[]
    for name, marker in data["markers"].items():
        # Invert the canonical legacy Iso projection, then the physical hex
        # plane. Marker interaction anchors may sit on their solid object;
        # an adjacent reachable flat is the appropriate narrow authoring gate.
        px=(marker["x"]-data["grid_origin"]["x"])/128
        pz=(marker["y"]-data["grid_origin"]["y"])/64
        x,z=px+pz,pz-px
        r=round(z/(sqrt(3)/2));q=round(x-r*.5)
        nearby=[p for p in hex_disk(q,r,2) if p in reached]
        anchors.append({"id":name,"axial":[q,r],"reachable_adjacent":bool(nearby)})
        if not nearby:
            failures.append(["marker_unreachable",name,q,r])
    for stair in stairs:
        for key in ("start_axial","end_axial"):
            if tuple(stair[key]) not in reached:
                failures.append(["stair_unreachable",stair["id"],key])
    bridges=[p for p,t in index.items() if t.get("object_type_id")=="glut_bridge_deck"]
    if any(p not in reached for p in bridges):
        failures.append(["bridge_unreachable",sum(p not in reached for p in bridges)])
    resources=json.loads((ROOT/"data/singleplayer/location_resources.json").read_text(encoding="utf-8"))
    resource_checks=[]
    for identifier, resource in resources.get(data["singleplayer_site"]["location_id"],{}).items():
        q,r=map(int,resource["grid"])
        accessible=any(p in reached for p in hex_disk(q,r,1))
        resource_checks.append({"id":identifier,"grid":[q,r],"reachable_adjacent":accessible})
        if not accessible:
            failures.append(["resource_unreachable",identifier,q,r])
    footprint_fields=("object_type_id","object_height","object_rotation_degrees","object_scale",
                      "walkable","blocks_los","cover_value","height_level")
    changed_footprints=[p for p,t in protected.items()
                        if any(index[p].get(k)!=t.get(k) for k in footprint_fields)]
    if changed_footprints:
        failures.append(["persistent_footprint_changed",len(changed_footprints)])
    isolated_h1=sum(t["height_level"]==1 and t["ramp_direction"]==-1 and not t.get("object_type_id")
                    and all(index.get((p[0]+dq,p[1]+dr),{}).get("height_level",0)==0
                            for dq,dr in DIRECTIONS) for p,t in index.items())
    if isolated_h1:
        failures.append(["isolated_h1",isolated_h1])
    return {"zone":zone,"status":"PASS" if not failures else "FAIL",
            "tiles":len(index),"height_histogram":dict(sorted(Counter(t["height_level"] for t in index.values()).items())),
            "ramp_cells":ramp_count,"reachable_cells":len(reached),"marker_checks":anchors,
            "bridge_cells":len(bridges),"preserved_object_cells":len(protected),
            "persistent_footprint_changes":len(changed_footprints),"isolated_objectless_h1":isolated_h1,
            "resource_checks":resource_checks,
            "new_rock_prop_budget":72,"stairs":stairs,"failures":failures,
            "scope":"offline data authoring check; no native gameplay/performance acceptance"}


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
    stairs, protected = compose_terrain(zone, data, index)
    report = validate_composition(zone, data, index, stairs, protected)
    data["tiles"] = tiles
    data["grid_size"] = {"x": WIDTH, "y": HEIGHT}
    data["regional_terrain_version"] = 3
    data["regional_height_step"] = 0.75
    data["terrain_height_rules"] = "explicit_hex_ramps_v1"
    data["place_world"]["regional_extent"] = {
        "version": 3,
        "layout": "odd_r_offset",
        "offset_min": [MIN_COLUMN, MIN_ROW],
        "axial_min": [min(t["grid_position"]["x"] for t in tiles), MIN_ROW],
        "source_sha256": sha256(source).hexdigest(),
        "profile": zone,
        "routes_offset": COMPOSITION_ROUTES[zone],
        "explicit_ramp_passages": stairs,
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
    report["map_sha256"] = sha256(target.read_bytes()).hexdigest()
    (output_dir / f"{zone}_authoring_check.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"zone":zone,"status":report["status"],"ramps":report["ramp_cells"],
                      "reachable":report["reachable_cells"],"failures":report["failures"]}))
    return report


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("zones", nargs="+", choices=MAPS)
    parser.add_argument("--source-dir", type=Path)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "output/native_glut_maps/explicit_ramps_candidate")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    reports=[compile_map(zone, MAPS[zone], args.source_dir, args.output_dir) for zone in args.zones]
    if any(report["failures"] for report in reports):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
