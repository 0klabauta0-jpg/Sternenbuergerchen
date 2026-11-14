"""Flugabwehr-Kit (14.11.2026): the two air-defence vehicles of the relay ridge (GM02).

"Hagel"      heavy eight-wheeled truck with a four-barrelled flak mount on the bed.
"Donnerkeil" the same truck carrying two raised missiles on an erector frame.

User brief: only the basic idea "truck with a gun mount / truck with missiles",
with own German names. Both are own low-poly designs in the Windbruch kit style
(same helper class and scale: 1 unit = 1 map cell, a person is about 0.6 tall).
No third-party model or drawing was used as a template. Long axis along X, cab
towards -X. Pivot: footprint centre on the ground. Emplaced: outriggers down.

Run:  python3 art/flugabwehr_kit_20261114/build_kit.py   (needs the bpy module)
Writes GLB files to Assets/curated/flugabwehr_kit_20261114/ and kit_manifest.json.
"""
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "art" / "windbruch_kit_20261114"))
import build_kit as kit  # Asset helper, palette, export

OUT = ROOT / "Assets" / "curated" / "flugabwehr_kit_20261114"
kit.PALETTE.update({"mil": "76806f", "mil_dark": "4d564c", "mil_light": "98a08c", "tyre": "232527", "enemy_red": "e0452f",
                    "missile": "d6d0be"})
kit.EMISSIVE.update({"enemy_red": 1.2})
Asset = kit.Asset
AXLES = (-1.12, -0.5, 0.42, 1.04)


def truck_base(a: Asset) -> None:
    """Chassis, eight wheels, armoured cab, equipment locker, bed, outriggers."""
    a.box((3.05, 0.78, 0.16), (0.0, 0, 0.44), "steel_dark", 0.03)
    for x in AXLES:
        a.box((0.12, 1.02, 0.1), (x, 0, 0.3), "steel_dark", 0.02)                         # axle
        for sy in (-1, 1):
            a.cyl(0.27, 0.24, (x, sy * 0.52, 0.27), "tyre", seg=12, rot=(90, 0, 0), bevel=0.05)
            a.cyl(0.12, 0.26, (x, sy * 0.52, 0.27), "mil_dark", seg=8, rot=(90, 0, 0))
    for sy in (-1, 1):                                                                    # mudguards over each pair
        for x in (-0.81, 0.73):
            a.box((1.28, 0.28, 0.06), (x, sy * 0.52, 0.6), "mil_dark", 0.02)
    # cab: sloped armour, slit windows, heavy bumper
    a.box((0.98, 1.06, 0.36), (-1.02, 0, 0.72), "mil", 0.06)
    a.box((0.9, 1.0, 0.34), (-0.98, 0, 1.04), "mil", 0.08, taper=0.8)
    a.box((0.05, 0.62, 0.17), (-1.44, 0, 1.03), "glass", 0.01, (0, -14, 0))
    for sy in (-1, 1):
        a.box((0.34, 0.04, 0.15), (-1.05, sy * 0.47, 1.04), "glass", 0.01, (sy * 9, 0, 0))
        a.box((0.3, 0.05, 0.3), (-1.05, sy * 0.535, 0.72), "mil_dark", 0.02)              # door plate
        a.box((0.07, 0.07, 0.05), (-1.5, sy * 0.36, 0.66), "lamp", 0.01)
    a.box((0.16, 1.1, 0.2), (-1.53, 0, 0.5), "steel_dark", 0.04)
    a.box((0.06, 0.5, 0.1), (-1.6, 0, 0.5), "hazard" if "hazard" in kit.PALETTE else "yellow", 0.01)
    a.box((0.4, 0.4, 0.05), (-0.92, 0, 1.23), "mil_dark", 0.015)                          # roof hatch
    a.pipe((-0.62, 0.4, 1.2), (-0.62, 0.4, 1.9), 0.012, "steel_dark", seg=5)              # whip antenna
    # locker block behind the cab with the house stripe
    a.box((0.46, 1.0, 0.56), (-0.3, 0, 0.8), "mil_dark", 0.05)
    a.box((0.48, 1.02, 0.08), (-0.3, 0, 0.86), "orange", 0.01)
    a.box((0.2, 0.3, 0.12), (-0.3, -0.25, 1.12), "mil", 0.03)
    a.box((0.06, 0.06, 0.06), (-0.3, 0.3, 1.11), "enemy_red", 0.01)
    # bed
    a.box((1.78, 1.04, 0.1), (0.62, 0, 0.57), "mil", 0.02)
    a.box((1.8, 1.06, 0.05), (0.62, 0, 0.5), "mil_dark", 0.01)
    a.box((0.08, 1.0, 0.16), (1.5, 0, 0.5), "steel_dark", 0.02)
    for sy in (-1, 1):
        a.box((0.06, 0.05, 0.06), (1.54, sy * 0.4, 0.52), "enemy_red", 0.008)
    # outriggers, lowered
    for x in (-0.05, 1.36):
        for sy in (-1, 1):
            a.box((0.12, 0.42, 0.1), (x, sy * 0.72, 0.42), "steel_dark", 0.02)
            a.pipe((x, sy * 0.9, 0.42), (x, sy * 0.9, 0.05), 0.04, "steel", seg=6)
            a.cyl(0.14, 0.05, (x, sy * 0.9, 0.025), "steel_dark", seg=8)


def hagel() -> Asset:
    """Flak truck: turntable, shielded mount, four barrels at 42 degrees, ammunition drums, search radar."""
    a = Asset("fa_hagel")
    truck_base(a)
    cx = 0.72
    a.cyl(0.46, 0.1, (cx, 0, 0.67), "steel_dark", seg=14)
    a.box((0.62, 0.56, 0.4), (cx - 0.05, 0, 0.92), "mil", 0.06)
    a.box((0.3, 0.74, 0.3), (cx - 0.16, 0, 1.02), "mil_dark", 0.05)                       # trunnion block
    elev = math.radians(42)
    ux, uz = math.cos(elev), math.sin(elev)
    for sy in (-1, 1):
        a.cyl(0.19, 0.2, (cx - 0.2, sy * 0.5, 0.98), "mil_dark", seg=10, rot=(90, 0, 0), bevel=0.03)  # drums
        a.box((0.05, 0.3, 0.52), (cx + 0.2, sy * 0.3, 1.12), "mil_light", 0.015, (0, -42, 0))         # splinter shield
        for dz in (0.0, 0.13):
            base = (cx - 0.05, sy * 0.13, 1.06 + dz)
            tip = (base[0] + ux * 1.45, base[1], base[2] + uz * 1.45)
            a.pipe(base, tip, 0.035, "steel_dark", seg=6)
            mid = (base[0] + ux * 0.5, base[1], base[2] + uz * 0.5)
            a.pipe(base, mid, 0.055, "mil_dark", seg=6)                                   # recoil sleeve
            a.pipe((tip[0] - ux * 0.14, tip[1], tip[2] - uz * 0.14), tip, 0.055, "steel", seg=6)  # muzzle brake
    a.box((0.2, 0.22, 0.2), (cx - 0.42, 0, 0.84), "dark", 0.03)                           # gunner seat
    a.box((0.2, 0.22, 0.06), (cx - 0.42, 0.0, 1.0), "mil_light", 0.01, (0, 20, 0))        # sight
    # search radar on the locker
    a.pipe((-0.3, 0.12, 1.08), (-0.3, 0.12, 1.42), 0.03, "steel_dark", seg=6)
    a.box((0.07, 0.66, 0.3), (-0.3, 0.12, 1.56), "mil_light", 0.02, (0, -12, 28))
    a.box((0.09, 0.2, 0.08), (-0.27, 0.12, 1.56), "steel_dark", 0.01, (0, -12, 28))
    a.crate(1.32, -0.3, 0.62, 0.24, "mil_dark", 8)                                        # ammunition boxes on the bed
    a.crate(1.34, 0.26, 0.62, 0.22, "orange", -6)
    return a


def donnerkeil() -> Asset:
    """Missile truck: erector frame raised to 55 degrees with two missiles, hydraulic ram, guidance mast."""
    a = Asset("fa_donnerkeil")
    truck_base(a)
    px, pz = 1.3, 0.72                                                                    # pivot at the tail
    angle = math.radians(55)
    ux, uz = -math.cos(angle), math.sin(angle)                                            # along the raised frame
    nx, nz = math.sin(angle), math.cos(angle)                                             # its upper side
    a.box((0.3, 0.9, 0.24), (px, 0, pz - 0.04), "steel_dark", 0.04)
    length = 2.05
    mid = (px + ux * length * 0.5, 0.0, pz + uz * length * 0.5)
    a.box((length, 0.86, 0.08), mid, "mil_dark", 0.02, (0, 55, 0))                        # frame bed
    for sy in (-1, 1):
        a.box((length, 0.07, 0.16), (mid[0] + nx * 0.04, sy * 0.44, mid[2] + nz * 0.04), "mil", 0.015, (0, 55, 0))
    for t in (0.18, 0.5, 0.82):                                                           # cradles
        c = (px + ux * length * t + nx * 0.08, 0.0, pz + uz * length * t + nz * 0.08)
        a.box((0.1, 0.9, 0.12), c, "steel", 0.015, (0, 55, 0))
    for sy in (-1, 1):
        y = sy * 0.21
        off = 0.25                                                                        # missile axis above the frame
        tail = (px + ux * 0.1 + nx * off, y, pz + uz * 0.1 + nz * off)
        nose = (px + ux * 1.78 + nx * off, y, pz + uz * 1.78 + nz * off)
        a.pipe(tail, nose, 0.15, "missile", seg=12)
        band = (px + ux * 1.3 + nx * off, y, pz + uz * 1.3 + nz * off)
        a.pipe((band[0] - ux * 0.07, y, band[2] - uz * 0.07), (band[0] + ux * 0.07, y, band[2] + uz * 0.07), 0.156, "orange", seg=12)
        tip = (nose[0] + ux * 0.2, y, nose[2] + uz * 0.2)
        a.cyl(0.15, 0.4, tip, "red", r2=0.02, seg=12, rot=(0, -35, 0))              # nose cone
        a.cyl(0.11, 0.1, (tail[0] - ux * 0.05, y, tail[2] - uz * 0.05), "steel_dark", r2=0.14, seg=10, rot=(0, -35, 0))
        fin_c = (tail[0] + ux * 0.2, y, tail[2] + uz * 0.2)
        a.box((0.34, 0.5, 0.03), fin_c, "mil_light", 0.005, (0, 55, 0))
        a.box((0.34, 0.03, 0.5), fin_c, "mil_light", 0.005, (0, 55, 0))
    # hydraulic ram from the bed to the frame
    ram_top = (px + ux * 1.15 - nx * 0.03, 0.0, pz + uz * 1.15 - nz * 0.03)
    a.pipe((0.2, 0.0, 0.64), ram_top, 0.055, "steel", seg=8)
    a.pipe((0.2, 0.0, 0.64), (0.2 + (ram_top[0] - 0.2) * 0.55, 0.0, 0.64 + (ram_top[2] - 0.64) * 0.55), 0.08, "mil_dark", seg=8)
    a.box((0.3, 0.4, 0.14), (0.2, 0, 0.66), "steel_dark", 0.03)
    # guidance mast on the locker
    a.pipe((-0.3, 0.2, 1.08), (-0.3, 0.2, 1.62), 0.03, "steel_dark", seg=6)
    a.cyl(0.2, 0.08, (-0.34, 0.2, 1.68), "mil_light", r2=0.06, seg=10, rot=(0, -70, 0))
    a.box((0.06, 0.06, 0.06), (-0.3, 0.2, 1.84), "enemy_red", 0.01)
    a.crate(0.55, -0.34, 0.62, 0.2, "mil_dark", 0)
    return a


def main() -> None:
    kit.OUT = OUT
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for asset in (hagel(), donnerkeil()):
        manifest[asset.name] = asset.export()
    (OUT / "kit_manifest.json").write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
    print(json.dumps(manifest))


if __name__ == "__main__":
    main()
