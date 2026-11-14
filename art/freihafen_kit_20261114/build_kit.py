"""Freihafen-Kit (14.11.2026): commercial depot pieces for the trade outpost.

Direction after the user's reference sheets "Freihafen / Distribution Center"
and "Rostgrenze Aussenposten": pale panel buildings on a dark base with one
orange band, flat roofs with plant on top, a walled paved yard, container
rows, tanks, a radio mast and small cyan lights. Own low-poly designs in the
Windbruch kit style (same helper class and scale: 1 unit = 1 map cell, a
person is about 0.6 tall, front faces -Y). Pivot: footprint centre on the ground.

Run:  python3 art/freihafen_kit_20261114/build_kit.py   (needs the bpy module)
Writes GLB files to Assets/curated/freihafen_kit_20261114/ and kit_manifest.json.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "art" / "windbruch_kit_20261114"))
import build_kit as kit  # Asset helper, palette, export

OUT = ROOT / "Assets" / "curated" / "freihafen_kit_20261114"
kit.PALETTE.update({"panel": "cfc8b6", "panel_dark": "a29d8f", "panel_light": "e2dccb", "interior": "25282a",
                    "cyan": "8fe6e0", "window": "ffd79a", "plant": "5f8a4a", "white": "c9c6ba", "tyre": "232527",
                    "hazard": "e0b23a", "apron": "46484c", "apron_kerb": "b9b6aa", "apron_line": "d98a2b",
                    "apron_paint": "bdb9ad"})
kit.EMISSIVE.update({"cyan": 2.4, "window": 1.1})
Asset = kit.Asset


def shell(a: Asset, w: float, d: float, h: float, plinth: float = 0.14) -> None:
    """Shared building body: plinth, pale panels, dark base band, orange band, roof with parapet."""
    a.box((w, d, plinth), (0, 0, plinth * 0.5), "concrete_dark", 0.02)
    a.box((w - 0.2, d - 0.2, h - plinth), (0, 0, plinth + (h - plinth) * 0.5), "panel", 0.07)
    a.box((w - 0.16, d - 0.16, 0.26), (0, 0, plinth + 0.13), "steel_dark", 0.03)
    a.box((w - 0.16, d - 0.16, 0.09), (0, 0, plinth + 0.33), "orange", 0.02)
    a.box((w - 0.1, d - 0.1, 0.12), (0, 0, h - 0.02), "panel_dark", 0.03)
    a.box((w - 0.5, d - 0.5, 0.05), (0, 0, h + 0.035), "concrete", 0.01)
    for sx in (-1, 1):                                          # corner posts
        for sy in (-1, 1):
            a.box((0.2, 0.2, h - plinth - 0.1), (sx * (w * 0.5 - 0.13), sy * (d * 0.5 - 0.13), plinth + (h - plinth) * 0.5), "panel_dark", 0.04)


def roof_unit(a: Asset, x: float, y: float, z: float, w: float = 0.7, d: float = 0.5) -> None:
    a.box((w, d, 0.26), (x, y, z + 0.13), "panel_light", 0.04)
    a.box((w * 0.9, d * 0.9, 0.04), (x, y, z + 0.275), "steel_dark", 0.01)
    a.cyl(min(w, d) * 0.3, 0.05, (x, y, z + 0.3), "steel", seg=10)


def gate(a: Asset, x: float, front: float, base: float, w: float, h: float, open_share: float, shelves: bool) -> None:
    """Loading gate in a projecting portal. open_share 1.0 = fully open."""
    a.box((w + 0.5, 0.36, h + 0.42), (x, front - 0.1, base + (h + 0.42) * 0.5), "panel_dark", 0.06)
    a.box((w + 0.52, 0.38, 0.1), (x, front - 0.1, base + h + 0.3), "orange", 0.02)
    a.box((w, 0.1, h), (x, front - 0.26, base + h * 0.5), "interior", 0.0)
    a.box((w * 0.7, 0.05, 0.05), (x, front - 0.31, base + h + 0.1), "lamp", 0.01)
    closed = h * (1.0 - open_share)
    ribs = int(closed / 0.11)
    for i in range(ribs):
        a.box((w, 0.05, 0.085), (x, front - 0.3, base + h - 0.055 - i * 0.11), "steel" if i % 2 else "panel_dark", 0.008)
    if shelves:                                                 # goods visible inside the open gate
        for i, (dx, s, c) in enumerate(((-0.52, 0.34, "white"), (-0.1, 0.4, "orange"), (0.36, 0.34, "cream_dark"), (0.62, 0.26, "white"))):
            a.box((s, 0.06, s * 0.9), (x + dx * w * 0.5 / 0.7, front - 0.3, base + s * 0.45), c, 0.015)
        a.box((w * 0.94, 0.05, 0.04), (x, front - 0.3, base + h * open_share * 0.62), "steel", 0.0)
        for dx in (-0.4, 0.1, 0.45):
            a.box((0.22, 0.06, 0.18), (x + dx * w * 0.6, front - 0.3, base + h * open_share * 0.62 + 0.11), "white" if dx < 0.3 else "petrol", 0.012)
    for sx in (-1, 1):                                          # hazard posts and a cyan door light
        a.box((0.1, 0.1, 0.36), (x + sx * (w * 0.5 + 0.12), front - 0.33, base + 0.18), "hazard", 0.02)
        a.box((0.05, 0.04, 0.12), (x + sx * (w * 0.5 + 0.12), front - 0.3, base + h * 0.72), "cyan", 0.008)


def warehouse() -> Asset:
    """Storage hall of the free port: two loading gates, one open. Footprint 6.0 x 4.0, height about 2.5."""
    a = Asset("fh_warehouse")
    w, d, h = 6.0, 4.0, 2.05
    shell(a, w, d, h)
    front = -d * 0.5 + 0.1
    gate(a, -1.45, front, 0.14, 1.8, 1.2, 1.0, True)
    gate(a, 1.45, front, 0.14, 1.8, 1.2, 0.3, False)
    a.box((0.9, 0.08, 0.5), (0.0, front - 0.02, 1.0), "petrol_dark", 0.02)                # notice board between the gates
    a.box((0.7, 0.03, 0.12), (0.0, front - 0.07, 1.12), "window", 0.006)
    for side in (-1, 1):                                                                  # high strip windows on both ends
        a.box((0.05, 2.7, 0.2), (side * (w * 0.5 - 0.09), 0.1, 1.62), "glass", 0.01)
        a.box((0.08, 0.5, 0.9), (side * (w * 0.5 - 0.08), 1.3, 0.7), "panel_dark", 0.02)   # downpipe housing
    a.box((5.0, 0.05, 0.2), (0, d * 0.5 - 0.09, 1.62), "glass", 0.01)
    for x in (-1.45, 1.45):                                                               # roof lights over each bay
        a.box((1.9, 2.6, 0.2), (x, 0.3, h + 0.1), "panel", 0.05)
        a.box((1.5, 2.2, 0.06), (x, 0.3, h + 0.215), "glass", 0.015)
        for i in (-1, 0, 1):
            a.box((1.56, 0.05, 0.07), (x, 0.3 + i * 0.72, h + 0.225), "steel_dark", 0.0)
    roof_unit(a, 0.0, 1.0, h + 0.06, 0.6, 0.8)
    roof_unit(a, 0.0, -0.2, h + 0.06, 0.6, 0.6)
    a.cyl(0.11, 0.5, (2.75, 1.5, h + 0.3), "steel_dark", seg=8)
    a.cyl(0.16, 0.08, (2.75, 1.5, h + 0.56), "steel", seg=8)
    a.pipe((-2.8, -1.5, h + 0.06), (-2.8, 1.5, h + 0.06), 0.05, "orange")
    a.pipe((-2.75, -1.4, h + 0.02), (-2.75, -1.4, h + 0.9), 0.02, "steel_dark")           # whip antenna
    a.box((0.05, 0.05, 0.05), (-2.75, -1.4, h + 0.92), "cyan", 0.0)
    return a


def office() -> Asset:
    """Office and crew quarters. Footprint 3.7 x 3.0, height about 1.6."""
    a = Asset("fh_office")
    w, d, h = 3.7, 3.0, 1.34
    shell(a, w, d, h)
    front = -d * 0.5 + 0.1
    a.box((2.0, 0.07, 0.46), (0.55, front - 0.01, 0.9), "steel_dark", 0.015)              # window band, lit
    a.box((1.9, 0.05, 0.36), (0.55, front - 0.04, 0.9), "window", 0.008)
    for i in range(1, 4):
        a.box((0.04, 0.07, 0.38), (0.55 - 0.95 + i * 0.475, front - 0.045, 0.9), "steel_dark", 0.0)
    a.door(-1.1, front - 0.02, 0.14, w=0.4, h=0.76, color="petrol", frame="steel_dark")
    a.steps(-1.1, front - 0.06, 0.14, w=0.62, count=2, rise=0.07, run=0.14)
    a.box((0.9, 0.44, 0.06), (-1.1, front - 0.22, 1.08), "orange", 0.015)                 # canopy
    for sx in (-1, 1):
        a.pipe((-1.1 + sx * 0.4, front - 0.4, 0.14), (-1.1 + sx * 0.4, front - 0.4, 1.06), 0.018, "steel_dark")
        a.box((0.05, 0.04, 0.1), (-1.1 + sx * 0.34, front - 0.03, 0.72), "cyan", 0.006)
    for x in (0.0, 1.1):                                                                  # planters under the windows
        a.box((0.8, 0.22, 0.16), (x, front - 0.16, 0.22), "concrete", 0.02)
        for dx in (-0.25, 0.0, 0.25):
            a.box((0.16, 0.14, 0.16), (x + dx, front - 0.16, 0.36), "plant", 0.04)
    for side in (-1, 1):
        a.box((0.05, 1.5, 0.3), (side * (w * 0.5 - 0.09), -0.2, 0.92), "window", 0.008)
    roof_unit(a, 0.9, 0.5, h + 0.06, 0.8, 0.6)
    a.box((1.0, 0.8, 0.14), (-0.9, 0.5, h + 0.13), "panel", 0.03)                         # roof hatch
    a.box((0.5, 0.4, 0.03), (-0.9, 0.5, h + 0.21), "steel_dark", 0.008)
    a.cyl(0.3, 0.1, (-1.3, -0.7, h + 0.42), "panel_light", r2=0.1, seg=12, rot=(40, 0, 20))  # small dish
    a.pipe((-1.3, -0.7, h + 0.06), (-1.3, -0.7, h + 0.4), 0.025, "steel_dark")
    return a


def workshop() -> Asset:
    """Workshop and parts store: half-open roll gate, tyres, gas bottles. Footprint 3.8 x 3.2, height about 1.9."""
    a = Asset("fh_workshop")
    w, d, h = 3.8, 3.2, 1.62
    shell(a, w, d, h)
    front = -d * 0.5 + 0.1
    gate(a, -0.5, front, 0.14, 1.7, 1.06, 0.55, False)
    a.box((0.9, 0.06, 0.34), (-0.5, front - 0.31, 0.34), "steel", 0.02)                   # workbench inside
    a.box((0.3, 0.06, 0.2), (-0.8, front - 0.31, 0.6), "red", 0.02)
    a.door(1.35, front - 0.02, 0.14, w=0.36, h=0.72, color="petrol", frame="steel_dark")
    for i in range(3):                                                                    # tyre stack
        a.cyl(0.2, 0.11, (0.72, front - 0.32, 0.2 + i * 0.115), "tyre", seg=12, bevel=0.03)
    a.cyl(0.2, 0.11, (0.95, front - 0.5, 0.26), "tyre", seg=12, rot=(74, 0, 30), bevel=0.03)
    for i, c in enumerate(("petrol", "orange", "petrol")):                                # gas bottles in a rack
        a.cyl(0.07, 0.5, (1.64, front - 0.24 - i * 0.16, 0.39), c, seg=8, bevel=0.02)
    a.box((0.06, 0.6, 0.06), (1.72, front - 0.4, 0.46), "steel_dark", 0.0)
    for side in (-1, 1):
        a.box((0.05, 1.8, 0.2), (side * (w * 0.5 - 0.09), 0.1, 1.2), "glass", 0.01)
    roof_unit(a, 0.9, 0.3, h + 0.06, 0.9, 0.7)
    a.cyl(0.1, 0.7, (-1.4, 1.0, h + 0.4), "steel_dark", seg=8)                            # exhaust stack
    a.cyl(0.15, 0.07, (-1.4, 1.0, h + 0.76), "steel", seg=8)
    a.box((1.2, 0.9, 0.08), (-0.6, 0.6, h + 0.1), "solar", 0.01, (0, 0, 0))
    return a


def tank_pair() -> Asset:
    """Two storage tanks on one slab with pipework. Footprint 2.5 x 1.4, height about 2.0."""
    a = Asset("fh_tank_pair")
    a.box((2.5, 1.4, 0.12), (0, 0, 0.06), "concrete_dark", 0.02)
    for x in (-0.62, 0.62):
        a.cyl(0.52, 1.5, (x, 0.08, 0.95), "panel", seg=16, bevel=0.05)
        a.cyl(0.535, 0.2, (x, 0.08, 0.36), "steel_dark", seg=16)
        a.cyl(0.535, 0.16, (x, 0.08, 1.2), "orange", seg=16)
        a.cyl(0.52, 0.2, (x, 0.08, 1.8), "panel_light", r2=0.3, seg=16)
        a.cyl(0.14, 0.1, (x, 0.08, 1.94), "steel_dark", seg=8)
        a.pipe((x, -0.5, 0.3), (x, -0.5, 1.3), 0.035, "steel")
        a.pipe((x, -0.5, 1.3), (x, -0.2, 1.3), 0.035, "steel")
    a.pipe((-0.62, -0.5, 0.3), (0.62, -0.5, 0.3), 0.045, "steel")
    a.box((0.34, 0.24, 0.4), (0.0, -0.52, 0.32), "petrol", 0.04)                          # valve cabinet
    a.box((0.12, 0.03, 0.08), (0.0, -0.645, 0.42), "cyan", 0.006)
    a.ladder(-0.62, -0.46, 0.12, 1.7, w=0.2)
    return a


def radio_mast() -> Asset:
    """Lattice radio mast with relay dishes. Footprint 1.1 x 1.1, height about 4.6."""
    a = Asset("fh_radio_mast")
    a.box((1.1, 1.1, 0.14), (0, 0, 0.07), "concrete_dark", 0.02)
    a.box((0.56, 0.44, 0.62), (0.0, -0.1, 0.45), "panel", 0.05)
    a.box((0.58, 0.46, 0.08), (0.0, -0.1, 0.42), "orange", 0.01)
    a.box((0.1, 0.03, 0.06), (0.14, -0.335, 0.6), "cyan", 0.004)
    foot, head, z0, z1 = 0.4, 0.11, 0.14, 3.9
    for sx in (-1, 1):
        for sy in (-1, 1):
            a.pipe((sx * foot, sy * foot, z0), (sx * head, sy * head, z1), 0.028, "steel_dark", seg=6)
    levels = 7
    for i in range(1, levels + 1):
        t = i / levels
        s, z = foot + (head - foot) * t, z0 + (z1 - z0) * t
        p, zp = foot + (head - foot) * (i - 1) / levels, z0 + (z1 - z0) * (i - 1) / levels
        for sx, sy, ex, ey in ((-1, -1, 1, -1), (1, -1, 1, 1), (1, 1, -1, 1), (-1, 1, -1, -1)):
            a.pipe((sx * s, sy * s, z), (ex * s, ey * s, z), 0.014, "steel", seg=5)
            a.pipe((sx * p, sy * p, zp), (ex * s, ey * s, z), 0.012, "steel", seg=5)
    a.box((0.34, 0.34, 0.06), (0, 0, z1), "steel_dark", 0.01)
    a.pipe((0, 0, z1), (0, 0, 4.5), 0.03, "steel_dark")
    a.box((0.08, 0.08, 0.08), (0, 0, 4.54), "cyan", 0.01)
    for sx, sy in ((1, 0), (-1, 0), (0, 1)):                                              # panel antennas at the head
        a.box((0.07 if sx else 0.2, 0.2 if sx else 0.07, 0.6), (sx * 0.22, sy * 0.22, 3.55), "panel_light", 0.015)
    a.cyl(0.26, 0.09, (0.0, -0.34, 3.0), "panel_light", r2=0.08, seg=12, rot=(90, 0, 0))  # relay dishes
    a.cyl(0.2, 0.08, (0.36, -0.05, 2.45), "panel_light", r2=0.06, seg=12, rot=(0, 90, 0))
    return a


def wall(length: float, lamp: bool) -> Asset:
    """Perimeter wall, length along X (user decision 14.11.2026: a wall, not a see-through fence).
    Dark footing, pale panels with the orange band, a cap; optional lamp pillar at the left end."""
    a = Asset("fh_wall_%d%s" % (int(length), "_lamp" if lamp else ""))
    a.box((length, 0.2, 0.12), (0, 0, 0.06), "steel_dark", 0.015)
    a.box((length, 0.14, 0.5), (0, 0, 0.36), "panel", 0.015)
    a.box((length, 0.155, 0.07), (0, 0, 0.3), "orange", 0.0)
    a.box((length, 0.2, 0.06), (0, 0, 0.63), "panel_dark", 0.012)
    joints = int(length) + 1
    for i in range(joints):
        x = -length * 0.5 + i * length / (joints - 1)
        tall = lamp and i == 0
        if tall:
            a.box((0.2, 0.24, 0.84), (x, 0, 0.42), "panel_dark", 0.02)
            a.box((0.1, 0.1, 0.08), (x, 0, 0.88), "cyan", 0.012)
        else:
            a.box((0.05, 0.17, 0.5), (x, 0, 0.36), "panel_dark", 0.0)
    return a


def gate_frame() -> Asset:
    """Yard gate: two pillars, a beam with sign and lights, guard booth; no barrier. Clear opening 2.4 wide."""
    a = Asset("fh_gate")
    for sx in (-1, 1):
        a.box((0.4, 0.4, 1.1), (sx * 1.4, 0, 0.55), "panel", 0.05)
        a.box((0.42, 0.42, 0.2), (sx * 1.4, 0, 0.1), "steel_dark", 0.02)
        a.box((0.42, 0.42, 0.09), (sx * 1.4, 0, 0.36), "orange", 0.01)
        a.box((0.1, 0.04, 0.14), (sx * 1.4, -0.21, 0.78), "cyan", 0.006)
    a.box((3.2, 0.26, 0.2), (0, 0, 1.2), "steel_dark", 0.04)
    a.box((1.4, 0.3, 0.3), (0, 0, 1.2), "orange", 0.03)
    a.box((1.0, 0.03, 0.14), (0, -0.16, 1.2), "window", 0.006)
    for x in (-0.95, 0.95):
        a.box((0.14, 0.1, 0.05), (x, -0.12, 1.08), "lamp", 0.008)
    a.box((0.8, 0.7, 0.9), (2.1, 0.0, 0.5), "panel", 0.06)                                # booth
    a.box((0.82, 0.72, 0.16), (2.1, 0.0, 0.13), "steel_dark", 0.02)
    a.box((0.6, 0.06, 0.3), (2.1, -0.34, 0.66), "window", 0.01)
    a.box((0.9, 0.8, 0.06), (2.1, 0.0, 0.98), "orange", 0.02)
    return a


def container_row(name: str, colors, top) -> Asset:
    """Neat block of freight containers, long side along X. Footprint about 2.1 x 2.8."""
    a = Asset(name)
    for i, c in enumerate(colors):
        a.container(0.0, (i - (len(colors) - 1) * 0.5) * 0.93, 0.0, c)
    for y, c in top:
        a.container(0.0, y, 0.85, c)
    return a


def pallet_stack() -> Asset:
    """Wrapped goods on pallets. Footprint about 1.3 x 0.8."""
    a = Asset("fh_pallet_stack")
    for x, hgt, c in ((-0.36, 0.5, "white"), (0.34, 0.34, "cream_dark")):
        a.box((0.62, 0.62, 0.07), (x, 0, 0.035), "rust", 0.008)
        a.box((0.56, 0.56, hgt), (x, 0, 0.07 + hgt * 0.5), c, 0.03)
        a.box((0.57, 0.57, 0.05), (x, 0, 0.07 + hgt * 0.6), "orange" if c == "white" else "petrol", 0.006)
    a.box((0.3, 0.3, 0.26), (0.36, 0.0, 0.54), "white", 0.03, (0, 0, 20))
    return a


def yard_lamp() -> Asset:
    """Lamp post for the yard."""
    a = Asset("fh_yard_lamp")
    a.box((0.2, 0.2, 0.1), (0, 0, 0.05), "concrete_dark", 0.02)
    a.pipe((0, 0, 0.1), (0, 0, 1.5), 0.028, "steel_dark")
    a.box((0.4, 0.05, 0.05), (0.16, 0, 1.5), "steel_dark", 0.0)
    a.box((0.2, 0.12, 0.05), (0.3, 0, 1.47), "panel_dark", 0.01)
    a.box((0.16, 0.09, 0.03), (0.3, 0, 1.435), "cyan", 0.004)
    return a


# Apron of the trade outpost free port, in map plane coordinates (x, z). The road deck draws the paved cells
# as a union of round lanes, which leaves a zigzag on the two edges that cross the hex rows. This flat frame
# lies over the rim of that deck: straight kerb, orange line, asphalt band, plus the painted yard markings.
# Colours and layer heights follow scripts/terrain/frontier_road_deck.gd.
APRON_RECT = (-4.3, -3.4, 29.8, 14.6)
APRON_EAST_OPENING = (3.6, 5.06)                                # the road to the C-Benit site leaves here
APRON_BAYS = [(-1.9, -0.9, 1.25, 1.6), (1.2, -0.9, 1.25, 1.6), (4.3, -0.9, 1.25, 1.6), (-1.9, 3.6, 1.25, 1.6),
              (-1.9, 8.6, 1.25, 1.6), (1.2, 8.6, 1.25, 1.6), (-1.9, 12.3, 1.25, 1.6)]
APRON_HAZARD = [(15.55, 4.45, 1.0, 0.62), (18.45, 4.45, 1.0, 0.62), (22.5, 4.2, 0.95, 0.5)]
APRON_LANE = (5.0, 26.5, 6.3)                                   # dashed line: x from, x to, z


def apron_frame() -> Asset:
    a = Asset("fh_apron_trade_outpost")
    x0, z0, x1, z1 = APRON_RECT
    cx, cz = (x0 + x1) * 0.5, (z0 + z1) * 0.5

    def strip(ax, az, bx, bz, top, color, thick=0.02):          # axis-aligned flat box between two plane points
        a.box((abs(bx - ax), abs(bz - az), thick), ((ax + bx) * 0.5 - cx, -((az + bz) * 0.5 - cz), top - thick * 0.5), color, 0.0)

    def ring(inset, width, top, color, gap):
        l, r, n, s = x0 + inset, x1 - inset, z0 + inset, z1 - inset
        strip(l, n, r, n + width, top, color)
        strip(l, s - width, r, s, top, color)
        strip(l, n, l + width, s, top, color)
        if gap:
            strip(r - width, n, r, APRON_EAST_OPENING[0], top, color)
            strip(r - width, APRON_EAST_OPENING[1], r, s, top, color)
        else:
            strip(r - width, n, r, s, top, color)

    ring(0.0, 0.10, 0.082, "apron_kerb", True)
    ring(0.10, 0.045, 0.088, "apron_line", True)
    ring(0.145, 0.8, 0.094, "apron", False)

    def outline(x, z, hw, hd, color, w=0.06):
        strip(x - hw, z - hd, x + hw, z - hd + w, 0.098, color, 0.006)
        strip(x - hw, z + hd - w, x + hw, z + hd, 0.098, color, 0.006)
        strip(x - hw, z - hd, x - hw + w, z + hd, 0.098, color, 0.006)
        strip(x + hw - w, z - hd, x + hw, z + hd, 0.098, color, 0.006)

    for x, z, hw, hd in APRON_BAYS:
        outline(x, z, hw, hd, "apron_paint")
    for x, z, hw, hd in APRON_HAZARD:
        outline(x, z, hw, hd, "apron_line", 0.08)
        for i in (-1, 0, 1):
            strip(x + i * hw * 0.5 - 0.05, z - hd, x + i * hw * 0.5 + 0.05, z + hd, 0.098, "apron_line", 0.006)
    x = APRON_LANE[0]
    while x < APRON_LANE[1]:
        strip(x, APRON_LANE[2] - 0.04, x + 0.8, APRON_LANE[2] + 0.04, 0.098, "apron_paint", 0.006)
        x += 1.5
    return a


def main() -> None:
    kit.OUT = OUT
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    assets = [warehouse(), office(), workshop(), tank_pair(), radio_mast(), gate_frame(), pallet_stack(),
              yard_lamp(), apron_frame(), wall(4.0, True), wall(4.0, False), wall(2.0, False), wall(1.0, False),
              container_row("fh_container_row_a", ("white", "orange", "white"), ((-0.47, "petrol"),)),
              container_row("fh_container_row_b", ("panel_dark", "white", "petrol"), ((0.0, "white"), (0.93, "orange")))]
    for asset in assets:
        manifest[asset.name] = asset.export()
    (OUT / "kit_manifest.json").write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
    print(json.dumps({k: v["triangles"] for k, v in manifest.items()}))


if __name__ == "__main__":
    main()
