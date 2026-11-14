"""Build maps/windbruch_outpost.json: a hand-directed, procedurally filled
frontier outpost on a mesa terrace (Grafikpass R3, 14.11.2026).

Deterministic. Run from the repository root:

    python3 tools/build_windbruch_outpost.py

Coordinates
- "plane" = the 3D ground plane in cell units (x east, z south), the same
  space place_presentation uses for pads, props and structures.
- cells are axial (q, r) of hex_axial_v1; the map is an odd-r offset rectangle.
- heights follow explicit_hex_ramps_v1: plateaus on even levels, one ramp row
  per level with a flat landing row between two rises.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "maps" / "windbruch_outpost.json"
STYLE_SOURCE = ROOT / "maps" / "station_outpost_64x64.json"

# The settlement core keeps its hand-directed 88 x 72 box at cells (0..87, 0..71).
# Around it lies the campaign region: 512 columns x 256 rows like every other
# campaign location, as an odd-r offset rectangle starting at (COL0, ROW0).
CORE_COLS, CORE_ROWS = 88, 72
COLS, ROWS = 512, 256
COL0, ROW0 = -200, -90
SQ3H = 0.8660254037844386
DIRS = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
ORIGIN = (1536.0, 64.0)
HALF_W, HALF_H = 64.0, 32.0


# ---------------------------------------------------------------- geometry
def plane(q: int, r: int) -> tuple[float, float]:
    return q + 0.5 * r, SQ3H * r


def cell_at(x: float, z: float) -> tuple[int, int]:
    r = z / SQ3H
    q = x - 0.5 * r
    # cube rounding
    cx, cz = q, r
    cy = -cx - cz
    rx, ry, rz = round(cx), round(cy), round(cz)
    dx, dy, dz = abs(rx - cx), abs(ry - cy), abs(rz - cz)
    if dx > dy and dx > dz:
        rx = -ry - rz
    elif dy <= dz:
        rz = -rx - ry
    return int(rx), int(rz)


def world(x: float, z: float) -> dict:
    return {"x": ORIGIN[0] + (x - z) * HALF_W, "y": ORIGIN[1] + (x + z) * HALF_H}


def hex_line(a: tuple[int, int], b: tuple[int, int]) -> list[tuple[int, int]]:
    def cube(c):
        return c[0], -c[0] - c[1], c[1]
    ax, ay, az = cube(a)
    bx, by, bz = cube(b)
    n = max(abs(ax - bx), abs(ay - by), abs(az - bz))
    out = []
    for i in range(n + 1):
        t = i / n if n else 0.0
        x, y, z = ax + (bx - ax) * t + 1e-6, ay + (by - ay) * t + 1e-6, az + (bz - az) * t - 2e-6
        rx, ry, rz = round(x), round(y), round(z)
        dx, dy, dz = abs(rx - x), abs(ry - y), abs(rz - z)
        if dx > dy and dx > dz:
            rx = -ry - rz
        elif dy <= dz:
            rz = -rx - ry
        out.append((int(rx), int(rz)))
    return out


# ------------------------------------------------------------------- noise
def _hash(ix: int, iz: int, seed: int) -> float:
    h = (ix * 1597334677) ^ (iz * 3812015801) ^ (seed * 2654435761)
    h &= 0xFFFFFFFF
    h = ((h ^ (h >> 16)) * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 3266489917) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFFFF) / float(0xFFFFFF)


def value_noise(x: float, z: float, seed: int) -> float:
    ix, iz = math.floor(x), math.floor(z)
    fx, fz = x - ix, z - iz
    ux, uz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    a = _hash(ix, iz, seed)
    b = _hash(ix + 1, iz, seed)
    c = _hash(ix, iz + 1, seed)
    d = _hash(ix + 1, iz + 1, seed)
    return (a + (b - a) * ux) * (1 - uz) + (c + (d - c) * ux) * uz


def fbm(x: float, z: float, seed: int) -> float:
    """Roughly -1..1."""
    return (value_noise(x, z, seed) * 0.6 + value_noise(x * 2.1, z * 2.1, seed + 7) * 0.28
            + value_noise(x * 4.3, z * 4.3, seed + 19) * 0.12) * 2.0 - 1.0


def blob(x, z, cx, cz, rx, rz, seed, wobble=0.22):
    d = 1.0 - math.hypot((x - cx) / rx, (z - cz) / rz)
    return d + wobble * fbm(x * 0.14, z * 0.14, seed)


def dist_to_polyline(x, z, pts):
    best = 1e9
    for (ax, az), (bx, bz) in zip(pts, pts[1:]):
        vx, vz = bx - ax, bz - az
        t = max(0.0, min(1.0, ((x - ax) * vx + (z - az) * vz) / (vx * vx + vz * vz)))
        best = min(best, math.hypot(x - ax - vx * t, z - az - vz * t))
    return best


# ------------------------------------------------------------ design input
RIVER_WEST = [(-201, 58), (-160, 60), (-125, 52), (-95, 43), (-70, 45), (-45, 33), (-20, 27)]
RIVER_EAST = [(110, 63), (135, 60), (160, 70), (185, 78), (215, 72), (250, 80), (285, 76), (313, 84)]
RIVERBED = RIVER_WEST + [(-1, 31), (11, 35), (22, 41), (33, 44.5), (45, 46), (57, 44.5), (68, 48), (78, 53), (90, 56)] + RIVER_EAST
NORTH_GULLY = [(-1, 14), (10, 17), (22, 13.5), (34, 9.5), (44, 5), (52, -1), (55, -10), (50, -20), (54, -30)]

# Regional canyons: carved low ground that ties the outlying sites together.
PISTES = {
    "sued": [(17, 54.5), (16.5, 63), (19, 78), (21, 92)],
    "westschleife": [(-95, 43), (-112, 8), (-62, -28), (18, -40), (50, -27)],
    "ostschleife": [(172, 74), (196, 30), (150, -12), (96, -34), (70, -30)],
    "suedwest": [(21, 99), (-58, 106), (-118, 86), (-125, 52)],
    "suedost": [(24, 101), (100, 116), (150, 96), (172, 76)],
}
# Outlying sites: (centre x, z, clear radius). Regional highlands keep out.
SITES = {
    "absturzfeld": (-95.0, 43.0, 14.0),
    "bohrstelle": (172.0, 72.0, 13.0),
    "horchposten": (58.0, -42.0, 19.0),
    "altfeld": (22.0, 100.0, 12.0),
}

# name, plane point somewhere below the cliff, uphill direction, band width, base level
RAMPS = [
    ("hauptrampe", (41.0, 46.0), 2, 4, 0),
    ("ostpfad", (66.5, 46.0), 2, 2, 0),
    ("hintertuer", (36.5, 9.0), 5, 2, 0),
    ("gratsteig", (60.0, 24.0), 2, 3, 2),
    ("nordwest_kuppe", (17.0, 24.0), 2, 2, 0),
    ("horch_unten", (55.0, -33.0), 2, 3, 0),
    ("horch_oben", (61.5, -40.5), 2, 2, 2),
]
AUTO_RAMP_LIMIT = 40

PADS = [
    {"id": "fortified_pad_01", "center": (24.5, 50.2), "size": (6.2, 5.2), "name": "LANDEFELD · 01"},
    {"id": "windbruch_pad_02", "center": (35.5, 53.4), "size": (5.5, 4.2), "name": "FRACHT · 02"},
    {"id": "windbruch_pad_03", "center": (22.0, 100.0), "size": (5.5, 4.2), "name": "ALTFELD · 03"},
]

# plane way-points; cells in between are filled with hex lines. A string names
# a ramp end: "foot:<ramp>" is the flat ground below it, "head:<ramp>" above.
YARD = (48.5, 29.44)          # the yard road runs along hex row 34
ROAD_TURN = (40.0, 29.44)     # main ramp head -> here follows a hex axis, then east
ROADS = [
    [(28.0, 50.2), (33.0, 49.8), (37.5, 48.4), "foot:hauptrampe"],        # landing field -> main ramp
    [(35.5, 51.2), (35.8, 49.2)],                                          # cargo pad spur
    ["head:hauptrampe", ROAD_TURN, YARD, (54.5, 29.44)],                   # main ramp -> through the yard
]
TRAILS = [
    [(54.5, 29.44), (57.5, 32.4), "head:ostpfad"],                        # yard -> east path
    ["foot:ostpfad", (68.5, 48.5)],
    [(41.5, 29.44), (41.2, 22.5), "head:hintertuer"],                     # yard -> back door
    ["foot:hintertuer", (34.5, 9.0)],
    [(54.5, 29.44), (56.5, 25.6), "foot:gratsteig"],                      # yard -> ridge
    ["head:gratsteig", (60.0, 13.6), (63.6, 12.4)],                       # ridge top to the relay
    [(14.0, 36.5), (16.0, 31.0), "foot:nordwest_kuppe"],                  # river -> north-west knoll
    [(21.0, 48.0), (18.0, 44.5), (15.0, 39.0)],                           # landing field -> river west
    [(18.6, 46.0), (16.6, 50.5), (17.0, 54.5)],                                          # landing field -> south pass
    [(54.0, -30.0), "foot:horch_unten"],                                   # gully -> listening post
    ["head:horch_unten", (59.0, -39.5), "foot:horch_oben"],
    ["head:horch_oben", (61.5, -44.6)],
]

MARKERS = {
    "spawn_alpha": ("spawn_alpha", "Landefeld", (24.5, 50.2), "diamond", (0.38, 0.78, 1.0)),
    "ship_return": ("interaction_hold_zone", "Rückflug zum Heimatpad", (24.5, 50.2), "circle", (0.48, 0.9, 1.0)),
    "spawn_bravo": ("spawn_bravo", "Trockenbett Ost", (80.0, 54.0), "diamond", (1.0, 0.56, 0.42)),
    "objective_point": ("objective_point", "Relaisstation Bastion Silex", (64.6, 13.4), "flag", (1.0, 0.86, 0.24)),
    "outpost_chip": ("interaction_computer", "Außenposten-Chip bergen", (64.6, 13.4), "circle", (1.0, 0.86, 0.24)),
    "spawn_enemy_defense": ("spawn_enemy_defense", "Außenpostenwache", (50.5, 29.44), "diamond", (0.98, 0.35, 0.29)),
    "rally_hauptrampe": ("rally_point", "Fuß der Hauptrampe", (40.0, 46.6), "circle", (0.48, 0.9, 1.0)),
    "recon_ostkante": ("recon_note", "Ostkante über dem Trockenbett", (62.4, 34.2), "cross", (0.86, 0.68, 1.0)),
    "recon_hintertuer": ("recon_note", "Hintertür Nord", (37.0, 8.0), "cross", (0.86, 0.68, 1.0)),
    "recon_absturzfeld": ("recon_note", "Absturzfeld im Westtal", (-95.0, 43.0), "cross", (0.86, 0.68, 1.0)),
    "recon_bohrstelle": ("recon_note", "Alte Bohrstelle Ost", (172.0, 74.0), "cross", (0.86, 0.68, 1.0)),
    "recon_horchposten": ("recon_note", "Horchposten Nord", (61.5, -44.6), "cross", (0.86, 0.68, 1.0)),
    "recon_altfeld": ("recon_note", "Altes Landefeld Süd", (21.0, 95.5), "cross", (0.86, 0.68, 1.0)),
}

KIT = "res://Assets/curated/windbruch_kit_20261114/"
# asset -> (scene path, half width x, half depth z, object_height, blocks_los, cover)
ASSETS = {
    "hull_hab": (KIT + "wb_hull_hab_long.glb", 1.7, 0.95, 3, True, 80),
    "container_hall": (KIT + "wb_container_hall.glb", 2.55, 1.75, 3, True, 80),
    "comm_dish": (KIT + "wb_comm_dish.glb", 1.2, 1.05, 4, True, 80),
    "bunker": (KIT + "wb_bunker_entrance.glb", 1.45, 1.15, 3, True, 80),
    "container_orange": (KIT + "wb_container_orange.glb", 1.0, 0.45, 2, True, 65),
    "container_petrol": (KIT + "wb_container_petrol.glb", 1.0, 0.45, 2, True, 65),
    "container_stack": (KIT + "wb_container_stack.glb", 1.05, 0.95, 3, True, 75),
    "crates": (KIT + "wb_crate_cluster.glb", 0.45, 0.4, 1, False, 45),
    "barrels": (KIT + "wb_barrel_cluster.glb", 0.45, 0.35, 1, False, 40),
    "power": (KIT + "wb_power_unit.glb", 0.9, 0.55, 2, True, 65),
    "solar": (KIT + "wb_solar_array.glb", 1.25, 0.5, 1, False, 35),
    "wreck_wing": (KIT + "wb_wreck_wing.glb", 2.25, 0.8, 2, True, 70),
    "wreck_engine": (KIT + "wb_wreck_engine.glb", 1.05, 0.55, 2, True, 65),
    "depot_hall": ("res://scenes/terrain/frontier_hall_exterior.tscn", 1.92, 1.34, 3, True, 80),
    "depot_habitat": ("res://scenes/terrain/frontier_habitat_exterior.tscn", 1.29, 1.36, 3, True, 80),
    # existing project models, at the scales the game already uses for them
    "fuel_unit": ("res://Assets/curated/frontier_illustrated_20261101/structures_pass04/utility_fuel_01.glb", 2.34, 1.62, 3, True, 75),
    "freibeuter": ("res://Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/buccaneer_01.glb", 5.88, 5.5, 3, True, 80),
}

# (asset, x, z, rotation about Y in degrees, scale). Front of a kit piece faces +Z at rotation 0.
PROPS = [
    # --- the yard on the terrace: old depot buildings and what settlers added.
    # North of the road: stores and workshops. South of it: living quarters.
    ("container_hall", 45.2, 25.4, 90, 1.0),
    ("depot_hall", 51.6, 24.6, 0, 1.2),
    ("power", 48.6, 21.4, 0, 1.0),
    ("container_stack", 55.4, 23.6, 8, 1.0),
    ("container_petrol", 48.6, 26.8, 78, 1.0),
    ("depot_habitat", 60.2, 28.2, 90, 1.15),
    ("hull_hab", 46.4, 33.4, -8, 1.0),
    ("hull_hab", 54.2, 34.4, 14, 1.0),
    ("fuel_unit", 50.4, 32.6, 0, 0.35),
    ("container_orange", 42.6, 32.2, 58, 1.0),
    ("solar", 51.4, 20.6, 0, 1.0),
    ("solar", 54.4, 20.6, 0, 1.0),
    ("wreck_engine", 61.8, 19.6, 35, 1.0),
    ("crates", 47.4, 28.0, 10, 1.0),
    ("crates", 54.8, 27.6, -30, 1.0),
    ("crates", 48.8, 30.9, 60, 1.0),
    ("barrels", 52.6, 30.8, 0, 1.0),
    ("barrels", 43.8, 30.8, 45, 1.0),
    ("barrels", 56.6, 35.6, -20, 1.0),
    # --- edges of the terrace: container cover instead of towers
    ("container_stack", 63.4, 32.4, -30, 1.0),
    ("container_petrol", 63.8, 35.6, -40, 1.0),
    ("container_orange", 38.6, 22.0, 20, 1.0),
    ("crates", 39.4, 24.4, 0, 1.0),
    ("wreck_wing", 55.0, 39.8, 160, 1.0),
    # --- the ridge with the relay
    ("comm_dish", 66.8, 10.8, 0, 1.0),
    ("power", 63.4, 9.6, 0, 1.0),
    ("container_petrol", 54.8, 12.6, 15, 1.0),
    ("crates", 65.0, 12.6, 20, 1.0),
    ("barrels", 61.6, 14.6, 0, 1.0),
    # --- landing field: pad 01 stays free for the player's ship
    ("freibeuter", 35.5, 53.4, 150, 0.22),
    ("fuel_unit", 20.2, 53.4, 90, 0.35),
    ("container_stack", 29.6, 54.6, 12, 1.0),
    ("crates", 28.8, 47.6, 0, 1.0),
    ("barrels", 19.8, 51.0, 30, 1.0),
    ("container_orange", 40.0, 55.2, 75, 1.0),
    ("container_petrol", 31.6, 46.4, -25, 1.0),
    # --- wreckage in the open ground
    ("wreck_wing", 19.6, 41.6, 28, 1.0),
    ("wreck_engine", 52.2, 49.6, -20, 1.0),
    ("wreck_wing", 72.4, 45.6, -35, 1.0),
    ("wreck_engine", 12.2, 22.6, 60, 1.0),
    ("wreck_wing", 30.6, 16.4, 70, 1.0),
    ("container_orange", 74.6, 50.4, 10, 1.0),
    # --- hermit on the north-west knoll
    ("hull_hab", 13.4, 10.4, 20, 1.0),
    ("solar", 16.8, 12.4, 0, 1.0),
    ("barrels", 15.4, 8.6, 0, 1.0),
    # ================= the region around the core =================
    # --- crash field in the west valley
    ("wreck_wing", -103.5, 34.5, 20, 1.0),
    ("wreck_wing", -89.6, 48.4, -70, 1.0),
    ("wreck_wing", -106.5, 40.0, 110, 1.0),
    ("wreck_engine", -92.4, 38.6, 40, 1.0),
    ("wreck_engine", -101.5, 47.6, -15, 1.0),
    ("container_orange", -87.0, 39.2, 30, 1.0),
    ("crates", -97.0, 47.8, 0, 1.0),
    ("barrels", -90.6, 39.6, 0, 1.0),
    # --- old drill site in the east valley
    ("container_hall", 170.0, 66.4, 0, 1.0),
    ("power", 171.8, 61.6, 0, 1.0),
    ("solar", 165.4, 63.6, 0, 1.0),
    ("solar", 168.6, 62.6, 0, 1.0),
    ("container_stack", 179.0, 69.4, 20, 1.0),
    ("hull_hab", 163.6, 68.4, 10, 1.0),
    ("barrels", 173.4, 69.6, 0, 1.0),
    ("crates", 176.8, 70.4, 0, 1.0),
    ("container_petrol", 181.6, 66.4, -30, 1.0),
    # --- listening post on the north plateau
    ("hull_hab", 63.6, -47.4, 0, 1.0),
    ("solar", 66.4, -45.4, 0, 1.0),
    ("power", 58.8, -47.2, 0, 1.0),
    ("container_petrol", 51.4, -42.4, 20, 1.0),
    ("crates", 54.6, -40.6, 0, 1.0),
    ("barrels", 66.4, -40.6, 0, 1.0),
    # --- abandoned landing field in the south
    ("wreck_engine", 22.6, 100.4, 25, 1.0),
    ("fuel_unit", 15.6, 102.0, 90, 0.35),
    ("container_stack", 28.0, 97.2, -15, 1.0),
    ("wreck_wing", 26.4, 105.6, 40, 1.0),
    ("barrels", 18.2, 96.6, 0, 1.0),
    ("crates", 27.2, 102.6, 0, 1.0),
    ("container_orange", 14.6, 96.4, 60, 1.0),
]

PATROLS = {
    "hof_runde": [(42.5, 29.44), (54.5, 29.44), (57.4, 22.2), (48.8, 23.6)],
    "kanten_wache": [(40.5, 38.0), (56.0, 37.5), (65.0, 34.0), (60.0, 26.0)],
}


# ----------------------------------------------------------------- terrain
def core_level(x: float, z: float, border: float) -> int:
    level = 0
    # the terrace that carries the settlement
    if blob(x, z, 49.0, 28.0, 20.5, 12.5, 11) > 0.0:
        level = 2
    # the ridge behind it with the comm mast
    if blob(x, z, 66.0, 11.5, 14.5, 8.0, 23) > 0.0 or blob(x, z, 52.0, 10.0, 8.5, 4.6, 29) > 0.0:
        level = 4
    if blob(x, z, 71.0, 8.5, 6.0, 3.6, 31, 0.15) > 0.0:
        level = 6
    # north-west knoll
    if blob(x, z, 15.5, 12.5, 9.0, 6.5, 37) > 0.0:
        level = max(level, 2)
    if blob(x, z, 13.0, 10.5, 4.6, 3.2, 41, 0.15) > 0.0:
        level = max(level, 4)
    # free-standing mesas: cover and sight breaks in the open ground
    for cx, cz, rx, rz, lv, seed in [
        (8.5, 46.0, 3.6, 2.6, 2, 51), (29.5, 60.0, 4.6, 2.8, 2, 53), (56.5, 53.5, 5.4, 3.0, 2, 57),
        (77.5, 41.0, 4.6, 3.8, 2, 59), (81.0, 26.0, 4.8, 6.5, 2, 61), (27.5, 33.0, 3.2, 2.3, 2, 63),
        (79.0, 40.0, 2.4, 2.0, 4, 65), (82.0, 24.0, 2.6, 3.4, 4, 67), (47.0, 60.5, 3.4, 2.4, 2, 69),
        (25.0, 20.0, 3.0, 2.4, 2, 71), (69.0, 60.0, 4.0, 2.6, 2, 73),
    ]:
        if blob(x, z, cx, cz, rx, rz, seed, 0.16) > 0.0:
            level = max(level, lv)
    # broken rim so the map does not end in a straight edge
    # In the region the rim is no longer a closed box: in broad lobes the low
    # ground runs out into bays, so the cliff line wanders instead of following
    # the old rectangle.
    bay = 30.0 * max(0.0, fbm(x * 0.04, z * 0.04, 205) - 0.45)
    rim = border - 1.2 - 2.2 * fbm(x * 0.09, z * 0.09, 83) - 5.0 * fbm(x * 0.05, z * 0.05, 207) + bay
    if rim < 0.0:
        level = max(level, 4 if rim < -1.6 else 2)
    return level


def core_border(x: float, z: float) -> float:
    return min(x, CORE_COLS - x, z, CORE_ROWS * SQ3H - z)


def map_border(x: float, z: float) -> float:
    return min(x - COL0, COL0 + COLS - 0.5 - x, z - ROW0 * SQ3H, (ROW0 + ROWS - 1) * SQ3H - z)


ROUTE_LINES = [RIVER_WEST + [(-1, 31)], [(90, 56)] + RIVER_EAST] + list(PISTES.values())


def region_field(x: float, z: float) -> float:
    n = 0.62 * fbm(x * 0.016, z * 0.016, 211) + 0.38 * fbm(x * 0.045, z * 0.045, 223)
    n += 0.30 * max(0.0, min(1.0, (-z - 5.0) / 60.0))          # highlands in the north
    n -= 0.70 * max(0.0, 1.0 - dist_to_polyline(x, z, RIVERBED) / 15.0)   # the river runs in a broad valley
    return n


REGION_THRESHOLDS = [0.0, 0.0, 0.0]


def calibrate_region() -> None:
    samples = []
    for row in range(ROW0, ROW0 + ROWS, 4):
        for col in range(COL0, COL0 + COLS, 4):
            samples.append(region_field(col + 0.5 * (row & 1), SQ3H * row))
    samples.sort()
    for i, share in enumerate((0.50, 0.77, 0.93)):
        REGION_THRESHOLDS[i] = samples[int(share * (len(samples) - 1))]


def region_level(x: float, z: float) -> int:
    n = region_field(x, z)
    level = 0
    for i, lv in enumerate((2, 4, 6)):
        if n >= REGION_THRESHOLDS[i]:
            level = lv
    for cx, cz, radius in SITES.values():
        if math.hypot(x - cx, z - cz) < radius * (1.0 + 0.2 * fbm(x * 0.1, z * 0.1, 241)):
            level = 0
    # listening post: a designed two-step plateau
    if blob(x, z, 58.0, -44.0, 13.0, 8.0, 251) > 0.0:
        level = 2
    if blob(x, z, 62.0, -46.0, 5.5, 3.6, 257, 0.12) > 0.0:
        level = 4
    return level


def design_level(x: float, z: float) -> int:
    border = core_border(x, z)
    if border >= 1.6:
        level = core_level(x, z, border)
    else:
        # the rock massif that frames the core, then the open region
        # its outer edge wanders in broad lobes and steps down over a terrace,
        # so the frame reads as a grown rock massif and not as the old map edge
        ring = 2.0 + 16.0 * fbm(x * 0.035, z * 0.035, 201) + 4.0 * fbm(x * 0.12, z * 0.12, 203)
        if border > -ring:
            level = core_level(x, z, border)
            if border < -0.55 * ring:
                level = min(level, 2)
        else:
            level = region_level(x, z)
        edge = map_border(x, z)
        rim = edge - 4.0 - 3.0 * fbm(x * 0.07, z * 0.07, 229)
        if rim < 0.0 or edge < 1.6:
            level = max(level, 6 if rim < -2.5 else 4)
    # carved low ground wins over everything above
    widen = 2.5 * max(0.0, min(1.0, -border / 12.0))
    if dist_to_polyline(x, z, RIVERBED) < 2.7 + widen + 0.9 * fbm(x * 0.11, z * 0.11, 91):
        level = 0
    if dist_to_polyline(x, z, NORTH_GULLY) < 2.2 + 0.8 * fbm(x * 0.12, z * 0.12, 97):
        level = 0
    if border < 12.0:
        for line in PISTES.values():
            if dist_to_polyline(x, z, line) < 2.3 + 0.7 * fbm(x * 0.12, z * 0.12, 263):
                level = 0
    for pad in PADS:
        px, pz = pad["center"]
        if abs(x - px) < pad["size"][0] * 0.5 + 1.8 and abs(z - pz) < pad["size"][1] * 0.5 + 1.8:
            level = 0
    return level


def build_levels() -> dict:
    calibrate_region()
    levels = {}
    for row in range(ROW0, ROW0 + ROWS):
        for col in range(COL0, COL0 + COLS):
            q, r = col - row // 2, row
            x, z = plane(q, r)
            levels[(q, r)] = design_level(x, z)
    # majority clean-up: no single-cell spikes or pits
    for _ in range(3):
        nxt = dict(levels)
        for (q, r), lv in levels.items():
            around = [levels.get((q + dq, r + dr), lv) for dq, dr in DIRS]
            same = sum(1 for a in around if a == lv)
            if same <= 1:
                nxt[(q, r)] = max(set(around), key=around.count)
        levels = nxt
    # a level change of more than one plateau step is a tall cliff: fine.
    return levels


RAMP_PROFILE = {-2: (0, False), -1: (0, False), 0: (0, True), 1: (1, False), 2: (1, True), 3: (2, False), 4: (2, False)}


def carve_band(levels: dict, ramps: dict, owner: dict, name: str, first, direction: int, width: int, base: int) -> None:
    dq, dr = DIRS[direction]
    lq, lr = DIRS[(direction + 4) % 6]
    half = width // 2
    for i in range(-half, width - half):
        for k, (rise, ramp) in RAMP_PROFILE.items():
            c = (first[0] + i * lq + k * dq, first[1] + i * lr + k * dr)
            if c not in levels:
                continue
            levels[c] = base + rise
            if ramp:
                ramps[c] = direction
                owner[c] = name
            else:
                ramps.pop(c, None)
    owner[name] = (first, (first[0] + 3 * dq, first[1] + 3 * dr))


def carve_ramps(levels: dict) -> tuple[dict, dict]:
    """Returns ramp cells {cell: direction} and their names; edits levels."""
    ramps, owner = {}, {}
    for name, start, direction, width, base in RAMPS:
        dq, dr = DIRS[direction]
        cell = cell_at(*start)
        # march uphill to the first plateau cell
        guard = 0
        while levels.get((cell[0] + dq, cell[1] + dr), 99) < base + 2 and guard < 40:
            cell = (cell[0] + dq, cell[1] + dr)
            guard += 1
        if guard >= 40 or levels.get((cell[0] + dq, cell[1] + dr), 99) == 99:
            raise SystemExit("ramp %s finds no cliff" % name)
        top = (cell[0] + dq, cell[1] + dr)       # first plateau row (k = 3)
        carve_band(levels, ramps, owner, name, (top[0] - 3 * dq, top[1] - 3 * dr), direction, width, base)
    return ramps, owner


def flood(levels: dict, ramps: dict, start) -> set:
    """Cells reachable on foot from start by the explicit ramp rules, props ignored."""
    def endpoint(cell, neighbour):
        direction = ramps.get(cell, -1)
        if direction < 0:
            return float(levels[cell])
        dq, dr = DIRS[direction]
        delta = (neighbour[0] - cell[0], neighbour[1] - cell[1])
        if delta == (dq, dr):
            return levels[cell] + 1.0
        if delta == (-dq, -dr):
            return float(levels[cell])
        return levels[cell] + 0.5
    seen, queue = {start}, [start]
    while queue:
        cur = queue.pop()
        for dq, dr in DIRS:
            nxt = (cur[0] + dq, cur[1] + dr)
            if nxt in seen or nxt not in levels:
                continue
            if abs(endpoint(cur, nxt) - endpoint(nxt, cur)) < 1e-6:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def auto_ramps(levels: dict, ramps: dict, owner: dict) -> list:
    """Regional ramps where a straight cliff of exactly one plateau step meets
    reachable ground. Lower ramps first, then second steps from what they open."""
    width, made = 3, []
    placed = [plane(*owner[name][0]) for name, *_ in RAMPS]

    def valid(first, direction, base):
        dq, dr = DIRS[direction]
        lq, lr = DIRS[(direction + 4) % 6]
        for i in range(-2, 3):
            for k in range(-3, 7):
                c = (first[0] + i * lq + k * dq, first[1] + i * lr + k * dr)
                if c in ramps or levels.get(c, -9) != (base if k <= 2 else base + 2):
                    return False
        return True

    for base, limit, spacing in ((0, 26, 30.0), (2, 14, 26.0)):
        reach = flood(levels, ramps, cell_at(*MARKERS["spawn_alpha"][2]))
        found = []
        for row in range(ROW0 + 8, ROW0 + ROWS - 8, 2):
            for col in range(COL0 + 8, COL0 + COLS - 8, 2):
                first = (col - row // 2, row)
                if levels[first] != base or first not in reach:
                    continue
                x, z = plane(*first)
                if core_border(x, z) > -16.0 or map_border(x, z) < 12.0:
                    continue
                if any(math.hypot(x - cx, z - cz) < radius + 6.0 for cx, cz, radius in SITES.values()):
                    continue
                for direction in range(6):
                    if valid(first, direction, base):
                        found.append((min(dist_to_polyline(x, z, line) for line in ROUTE_LINES), first, direction))
                        break
        found.sort()
        count = 0
        for _, first, direction in found:
            x, z = plane(*first)
            if count >= limit or any(math.hypot(x - px, z - pz) < spacing for px, pz in placed):
                continue
            if not valid(first, direction, base):
                continue
            name = "region_%d_%02d" % (base, count)
            carve_band(levels, ramps, owner, name, first, direction, width, base)
            made.append((name, direction, width))
            placed.append((x, z))
            count += 1
    return made


def stroke(cells: set, pts, width: int = 1):
    for a, b in zip(pts, pts[1:]):
        for c in hex_line(cell_at(*a), cell_at(*b)):
            cells.add(c)
            if width > 1:
                cells.add((c[0] + 1, c[1]))


def main() -> None:
    levels = build_levels()
    ramps, ramp_info = carve_ramps(levels)

    spec = {name: (direction, width) for name, _, direction, width, _ in RAMPS}
    regional = auto_ramps(levels, ramps, ramp_info)
    for name, direction, width in regional:
        spec[name] = (direction, width)

    def band(name: str, k: int) -> list:
        direction, width = spec[name]
        first, _ = ramp_info[name]
        dq, dr = DIRS[direction]
        lq, lr = DIRS[(direction + 4) % 6]
        half = width // 2
        return [(first[0] + i * lq + k * dq, first[1] + i * lr + k * dr) for i in range(-half, width - half)]

    def resolve(point):
        if isinstance(point, str):
            which, name = point.split(":")
            cells = band(name, -2 if which == "foot" else 4)
            mid = cells[len(cells) // 2]
            return plane(*mid)
        return point

    roads, trails = set(), set()
    for pts in ROADS:
        stroke(roads, [resolve(p) for p in pts])
    for pts in TRAILS:
        stroke(trails, [resolve(p) for p in pts])
    # the built road and the foot paths continue over their ramps
    for k in range(-2, 5):
        for c in band("hauptrampe", k)[1:3]:
            roads.add(c)
    for line in PISTES.values():
        stroke(trails, line)
    stroke(trails, [(54.0, -30.0), (50.0, -20.0), (55.0, -10.0), (52.0, -1.0)])
    for name in spec:
        if name == "hauptrampe":
            continue
        for k in range(-2, 5):
            trails.add(band(name, k)[len(band(name, k)) // 2])

    surfaces = {}
    for cell, lv in levels.items():
        x, z = plane(*cell)
        surface = "ground"
        if lv >= 2 and fbm(x * 0.2, z * 0.2, 131) > 0.05:
            surface = "rock"
        if lv == 0 and (dist_to_polyline(x, z, RIVERBED) < 2.0 + 0.8 * fbm(x * 0.15, z * 0.15, 137)):
            surface = "sand"
        if lv == 0 and core_border(x, z) < 0.0 and fbm(x * 0.03, z * 0.03, 271) > 0.42:
            surface = "sand"                                # dune fields in the open region
        if cell in trails:
            surface = "sand"
        if cell in roads:
            surface = "road"
        for pad in PADS:
            px, pz = pad["center"]
            if abs(x - px) < pad["size"][0] * 0.5 + 0.3 and abs(z - pz) < pad["size"][1] * 0.5 + 0.3:
                surface = "road"
        surfaces[cell] = surface

    # ---------------------------------------------------------------- props
    props, solids = [], {}

    def level_at(x, z):
        return levels[cell_at(x, z)]

    def add_solid(x, z, rot, half_w, half_d, height, los, cover, grow=0.0):
        c, sn = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        reach = int(math.ceil(max(half_w, half_d))) + 2
        q0, r0 = cell_at(x, z)
        for dq in range(-reach, reach + 1):
            for dr in range(-reach, reach + 1):
                cell = (q0 + dq, r0 + dr)
                if cell not in levels:
                    continue
                px, pz = plane(*cell)
                wx, wz = px - x, pz - z
                lx, lz = wx * c - wz * sn, wx * sn + wz * c
                if abs(lx) <= half_w + grow and abs(lz) <= half_d + grow:
                    old = solids.get(cell)
                    if old is None or height > old[0]:
                        solids[cell] = (height, los, cover)

    def add_prop(asset, x, z, rot, scale=1.0):
        path, half_w, half_d, height, los, cover = ASSETS[asset]
        on_pad = any(abs(x - p["center"][0]) < p["size"][0] * 0.5 and abs(z - p["center"][1]) < p["size"][1] * 0.5 for p in PADS)
        props.append({"asset": asset, "center": [round(x, 3), round(z, 3)], "path": path, "scale": scale,
                      "rotation_degrees": rot, "elevation": level_at(x, z) * 0.75 + (0.12 if on_pad else 0.0)})
        if half_w > 0.0:
            add_solid(x, z, rot, half_w * scale, half_d * scale, height, los, cover)

    for asset, x, z, rot, scale in PROPS:
        add_prop(asset, x, z, rot, scale)

    # bunker: set against the foot of the ridge, door towards the terrace
    bx, bz = 63.4, 26.0
    while level_at(bx, bz - 0.25) < 4:
        bz -= 0.25
    add_prop("bunker", bx, bz + 1.25, 0)

    # checkpoint at the head of the main ramp: two containers flank the road
    head = plane(*band("hauptrampe", 5)[2])
    toward = (ROAD_TURN[0] - head[0], ROAD_TURN[1] - head[1])
    norm = math.hypot(*toward)
    along = (toward[0] / norm, toward[1] / norm)
    across = (-along[1], along[0])
    gx, gz = head[0] + along[0] * 1.8, head[1] + along[1] * 1.8
    road_angle = math.degrees(math.atan2(-along[1], along[0]))
    add_prop("container_orange", gx + across[0] * 2.3, gz + across[1] * 2.3, road_angle + 12)
    add_prop("container_petrol", gx - across[0] * 2.4 + along[0] * 1.4, gz - across[1] * 2.4 + along[1] * 1.4, road_angle - 16)
    add_prop("crates", gx + across[0] * 2.2 + along[0] * 2.0, gz + across[1] * 2.2 + along[1] * 2.0, 0)
    add_prop("barrels", gx - across[0] * 2.3 - along[0] * 0.6, gz - across[1] * 2.3 - along[1] * 0.6, 0)

    # crate cover above the east path and the back door
    for name, shift in (("ostpfad", 1.0), ("hintertuer", -1.0)):
        hx, hz = plane(*band(name, 5)[0])
        add_prop("crates", hx + 1.8 * shift, hz + (-1.4 if name == "ostpfad" else 1.5), 0)
        add_prop("barrels", hx - 1.6 * shift, hz + (-2.0 if name == "ostpfad" else 2.1), 0)

    on_route = sorted(c for c in solids if c in roads or c in trails or c in ramps)
    if on_route:
        raise SystemExit("props block route cells: %s" % [tuple(round(v, 1) for v in plane(*c)) for c in on_route])

    # --------------------------------------------------- loose rock cover
    keep_clear = set(roads) | set(trails) | set(ramps)
    for name in spec:
        for k in range(-3, 6):
            keep_clear.update(band(name, k))
    for marker in MARKERS.values():
        mq, mr = cell_at(*marker[2])
        keep_clear.update((mq + dq, mr + dr) for dq in range(-2, 3) for dr in range(-2, 3))
    for pad in PADS:
        px, pz = pad["center"]
        for cell in levels:
            x, z = plane(*cell)
            if abs(x - px) < pad["size"][0] * 0.5 + 1.6 and abs(z - pz) < pad["size"][1] * 0.5 + 1.6:
                keep_clear.add(cell)
    near_solid = set()
    for (q, r) in solids:
        near_solid.update((q + dq, r + dr) for dq in range(-1, 2) for dr in range(-1, 2))
    rocks = {}
    for cell, lv in levels.items():
        if cell in keep_clear or cell in near_solid or cell in solids:
            continue
        x, z = plane(*cell)
        if YARD[0] - 9 < x < YARD[0] + 11 and YARD[1] - 9 < z < YARD[1] + 7:
            continue
        chance = 0.0
        if value_noise(x * 0.31, z * 0.31, 151) > 0.80:
            chance = 0.55                                   # boulder fields
        if any(levels.get((cell[0] + dq, cell[1] + dr), lv) >= lv + 2 for dq, dr in DIRS):
            chance = max(chance, 0.10)                      # talus at a cliff foot
        if surfaces[cell] == "sand":
            chance *= 0.35
        if chance > 0.0 and core_border(x, z) < 0.0:
            # the region stays quiet: loose rock only along routes and at sites
            close = any(math.hypot(x - cx, z - cz) < radius + 3.0 for cx, cz, radius in SITES.values()) \
                or min(dist_to_polyline(x, z, line) for line in ROUTE_LINES + [NORTH_GULLY]) < 8.0
            chance = chance * 0.6 if close else 0.0
        roll = _hash(cell[0], cell[1], 163)
        if roll < chance:
            rocks[cell] = (round(0.82 + 0.4 * _hash(cell[0], cell[1], 167), 3), int(_hash(cell[0], cell[1], 173) * 360))

    # ------------------------------------------------------------- tiles
    tiles = []
    for (q, r), lv in sorted(levels.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        ramp = ramps.get((q, r), -1)
        tile = {
            "grid_position": {"x": q, "y": r},
            "type_id": "ground_flat",
            "height_level": lv,
            "surface_type": surfaces[(q, r)],
            "edge_type": "slope" if ramp >= 0 else "cliff",
            "ramp_direction": ramp,
            "walkable": True,
            "blocks_los": False,
            "cover_value": 0,
        }
        if (q, r) in solids and ramp < 0:
            height, los, cover = solids[(q, r)]
            tile.update({"walkable": False, "blocks_los": los, "cover_value": cover, "object_height": height,
                         "object_type_id": "frontier_scene_solid", "object_rotation_degrees": 0.0, "object_scale": 1.0})
        elif (q, r) in rocks:
            scale, rot = rocks[(q, r)]
            tile.update({"walkable": False, "blocks_los": True, "cover_value": 55, "object_height": 2,
                         "object_type_id": "glut_sandstone_04", "object_rotation_degrees": rot, "object_scale": scale})
        tiles.append(tile)

    # ------------------------------------------------- reachability check
    by_cell = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in tiles}

    def endpoint(tile, neighbour):
        if tile["ramp_direction"] < 0:
            return float(tile["height_level"])
        dq, dr = DIRS[tile["ramp_direction"]]
        delta = (neighbour[0] - tile["grid_position"]["x"], neighbour[1] - tile["grid_position"]["y"])
        if delta == (dq, dr):
            return tile["height_level"] + 1.0
        if delta == (-dq, -dr):
            return float(tile["height_level"])
        return tile["height_level"] + 0.5

    start = cell_at(*MARKERS["spawn_alpha"][2])
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
    problems = []
    for marker_id, marker in MARKERS.items():
        cell = cell_at(*marker[2])
        if not by_cell[cell]["walkable"] or cell not in seen:
            problems.append("marker %s at %s (level %d) is blocked or unreachable" % (marker_id, cell, levels[cell]))
    for name, *_ in RAMPS:
        for k in (-2, 4):
            if band(name, k)[len(band(name, k)) // 2] not in seen:
                problems.append("ramp end %s k=%d unreachable" % (name, k))
    for pts in PATROLS.values():
        for point in pts:
            if cell_at(*point) not in seen:
                problems.append("patrol point %s unreachable" % (point,))
    if problems:
        raise SystemExit("\n".join(problems))

    style = json.loads(STYLE_SOURCE.read_text(encoding="utf-8"))
    markers = {}
    for marker_id, (kind, name, (x, z), symbol, (cr, cg, cb)) in MARKERS.items():
        markers[marker_id] = {
            "marker_type_id": kind, "name": name, "placement_context": "editor_only", "symbol": symbol,
            "color": {"r": cr, "g": cg, "b": cb, "a": 0.98}, **world(x, z),
        }
    data = {
        "tactical_grid_rules": "hex_tactical_v1",
        "grid_topology": "hex_axial_v1",
        "map_name": "windbruch_outpost",
        "mission_slot_count": 4,
        "grid_origin": {"x": ORIGIN[0], "y": ORIGIN[1]},
        "grid_size": {"x": COLS, "y": ROWS},
        "tile_size": {"half_width": HALF_W, "half_height": HALF_H},
        "terrain_visual_theme_id": "frontier_illustrated_v1",
        "regional_height_step": 0.75,
        "regional_terrain_version": 3,
        "campaign_chapter": "chapter_one_v1",
        "place_world": {
            "id": "windbruch", "kind": "frontier_region", "version": 2, "seed": "campaign:windbruch",
            "core_bounds": [0.0, 0.0, float(CORE_COLS), round(CORE_ROWS * SQ3H, 3)],
            "regional_extent": {"layout": "odd_r_offset", "offset_min": [COL0, ROW0], "size": [COLS, ROWS]},
            "sites": {name: [cx, cz] for name, (cx, cz, _) in SITES.items()},
            "regional_ramps": len(regional),
        },
        "singleplayer_site": {"location_id": "fortified_outpost", "landing_pads": [
            {"id": "fortified_pad_01", "grid": list(cell_at(*PADS[0]["center"])), "marker_id": "ship_return"}]},
        "terrain_height_rules": "explicit_hex_ramps_v1",
        "enemy_team_configs": style["enemy_team_configs"],
        "patrol_paths": {name: [world(x, z) for x, z in pts] for name, pts in PATROLS.items()},
        "markers": markers,
        "place_presentation": {
            "initial_camera_size": 24.0,
            "pads": [{"id": p["id"], "center": list(p["center"]), "size": list(p["size"]), "name": p["name"]} for p in PADS],
            "structures": [],
            "props": props,
            # plane rectangle whose cliffs keep the detailed quarry-stone face
            "cliff_detail_bounds": [-8.0, -8.0, CORE_COLS + 8.0, round(CORE_ROWS * SQ3H + 8.0, 3)],
        },
        "tiles": tiles,
    }
    OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    counts = {}
    for t in tiles:
        counts[t["height_level"]] = counts.get(t["height_level"], 0) + 1
    print("tiles", len(tiles), "levels", dict(sorted(counts.items())), "ramps", len(ramps),
          "roads", sum(1 for s in surfaces.values() if s == "road"), "sand", sum(1 for s in surfaces.values() if s == "sand"))
    for name, _, _, _, _ in RAMPS:
        print("ramp", name, ramp_info[name], "foot", tuple(round(v, 1) for v in plane(*band(name, -2)[spec[name][1] // 2])),
              "head", tuple(round(v, 1) for v in plane(*band(name, 4)[spec[name][1] // 2])))
    by_level = {}
    for prop in props:
        by_level.setdefault(levels[cell_at(*prop["center"])], []).append(prop["asset"])
    for lv in sorted(by_level):
        print("  props on level", lv, ":", ", ".join(sorted(by_level[lv])))
    print("regional ramps", len(regional), "reachable", sum(1 for name, _, _ in regional if band(name, 4)[1] in seen))
    print("sand share %.3f" % (sum(1 for v in surfaces.values() if v == "sand") / len(surfaces)))
    print("props", len(props), "solid cells", len(solids), "rocks", len(rocks), "reachable walkable cells", len(seen))
    for marker_id, marker in MARKERS.items():
        print("marker", marker_id, "level", levels[cell_at(*marker[2])])


if __name__ == "__main__":
    main()
