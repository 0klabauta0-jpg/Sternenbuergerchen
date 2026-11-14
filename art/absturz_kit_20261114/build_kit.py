"""Absturz-Kit (14.11.2026): pieces for the satellite crash site.

Own low-poly designs in the Windbruch kit style (same helper class, palette
and scale: 1 unit = 1 map cell, a person is about 0.6 tall, front faces -Y).
Pivot: footprint centre on the ground.

Run:  python3 art/absturz_kit_20261114/build_kit.py   (needs the bpy module)
Writes GLB files to Assets/curated/absturz_kit_20261114/ and kit_manifest.json.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "art" / "windbruch_kit_20261114"))
import build_kit as kit  # Asset helper, palette, export

OUT = ROOT / "Assets" / "curated" / "absturz_kit_20261114"
kit.PALETTE.update({"earth": "b9653f", "earth_dark": "8e4a2f", "scorch": "4b3a33", "rock": "a05a3c", "rock_dark": "7c432e",
                    "benit_a": "3fb0a6", "benit_b": "6878e0", "benit_c": "e39a2f", "foil": "c9a24a"})
Asset = kit.Asset


def satellite_wreck() -> Asset:
    """The crashed survey satellite, nose buried at the end of its furrow. Footprint about 3.4 x 2.4."""
    a = Asset("ab_satellite_wreck")
    a.box((2.6, 1.9, 0.12), (0.1, 0.0, 0.03), "scorch", 0.04, (0, 0, 8))                 # burnt ground
    a.box((1.5, 1.05, 1.0), (0.2, 0.0, 0.42), "cream", 0.14, (0, -24, 12))               # bus, tilted into the soil
    a.box((1.52, 0.5, 0.5), (0.2, 0.0, 0.5), "foil", 0.05, (0, -24, 12))                 # gold foil band
    a.box((0.5, 1.1, 0.5), (-0.55, 0.05, 0.62), "steel_dark", 0.06, (0, -24, 12))        # instrument block
    a.cyl(0.3, 0.5, (-1.0, 0.1, 0.95), "steel_dark", r2=0.42, seg=10, rot=(0, -64, 12))  # thruster cone
    a.box((0.9, 0.9, 0.5), (0.95, 0.0, 0.14), "earth_dark", 0.12, (0, 0, 30))            # thrown-up soil at the nose
    a.box((0.7, 0.6, 0.36), (1.25, 0.55, 0.1), "earth", 0.1, (0, 0, -20))
    a.box((0.6, 0.7, 0.3), (1.2, -0.6, 0.1), "earth", 0.1, (0, 0, 15))
    # one wing still attached, bent upwards; the other torn off
    a.box((0.18, 0.9, 0.12), (0.1, -0.85, 0.72), "steel", 0.02, (18, -24, 12))
    a.box((1.5, 0.05, 0.86), (0.05, -1.55, 1.12), "solar", 0.0, (62, -10, 12))
    a.box((1.56, 0.07, 0.06), (0.05, -1.55, 1.12), "steel", 0.0, (62, -10, 12))
    a.box((0.06, 0.07, 0.9), (0.05, -1.55, 1.12), "steel", 0.0, (62, -10, 12))
    a.box((0.2, 0.5, 0.12), (0.2, 0.7, 0.6), "steel", 0.02, (-20, -24, 12))              # stub of the lost wing
    # dish knocked off its mount, lying beside the bus
    a.cyl(0.62, 0.2, (-0.5, 1.0, 0.2), "cream_light", r2=0.16, seg=14, rot=(28, 12, 0))
    a.cyl(0.05, 0.5, (-0.5, 1.0, 0.36), "steel_dark", seg=6, rot=(28, 12, 0))
    a.pipe((-0.2, 0.3, 0.8), (-0.45, 0.85, 0.3), 0.04, "steel_dark")
    a.pipe((0.5, -0.2, 0.9), (0.9, -0.6, 1.5), 0.03, "steel_dark")                       # bent antenna
    a.box((0.1, 0.07, 0.05), (0.36, 0.3, 0.98), "lamp", 0.01)                            # the data unit still blinks
    return a


def solar_fragment() -> Asset:
    """Torn-off solar wing, half standing in the dirt. Footprint about 1.7 x 0.9."""
    a = Asset("ab_solar_fragment")
    a.box((1.6, 0.06, 0.8), (0.0, 0.0, 0.34), "solar", 0.0, (-58, 6, 0))
    a.box((1.66, 0.08, 0.07), (0.0, -0.21, 0.02), "steel", 0.0, (-58, 6, 0))
    for x in (-0.8, 0.0, 0.8):
        a.box((0.06, 0.08, 0.84), (x, 0.0, 0.34), "steel", 0.0, (-58, 6, 0))
    a.box((0.5, 0.4, 0.2), (-0.5, 0.25, 0.06), "earth", 0.08, (0, 0, 20))
    a.box((0.3, 0.2, 0.1), (0.6, -0.3, 0.04), "steel_dark", 0.02, (0, 0, 40))
    return a


def debris_small() -> Asset:
    """Small parts shed along the furrow. Footprint about 1.2 x 1.0."""
    a = Asset("ab_debris_small")
    a.box((0.5, 0.34, 0.05), (-0.3, 0.2, 0.05), "cream", 0.01, (10, 6, 25))
    a.box((0.34, 0.3, 0.2), (0.3, -0.2, 0.1), "foil", 0.04, (0, 12, -20))
    a.cyl(0.14, 0.26, (0.1, 0.3, 0.12), "steel_dark", r2=0.2, seg=8, rot=(70, 0, 30))
    a.box((0.44, 0.05, 0.3), (-0.25, -0.3, 0.14), "solar", 0.0, (-50, 0, -30))
    a.pipe((0.4, 0.2, 0.03), (0.0, -0.05, 0.05), 0.03, "steel")
    a.box((0.16, 0.16, 0.12), (0.5, 0.25, 0.06), "steel", 0.03, (0, 0, 40))
    return a


def furrow_berm() -> Asset:
    """Thrown-up earth along the impact furrow. Runs along X, about 2.4 x 0.8, low enough to step over."""
    a = Asset("ab_furrow_berm")
    for i, (x, y, w, h, rot) in enumerate(((-0.8, 0.02, 0.9, 0.26, 8), (0.0, -0.04, 1.0, 0.36, -6), (0.82, 0.03, 0.86, 0.24, 12))):
        a.box((w, 0.62, h), (x, y, h * 0.5 - 0.02), "earth" if i != 1 else "earth_dark", 0.11, (0, 0, rot), taper=0.62)
    a.box((0.3, 0.26, 0.2), (0.45, 0.3, 0.08), "rock_dark", 0.06, (0, 0, 30), taper=0.8)
    a.box((0.22, 0.2, 0.14), (-0.5, -0.32, 0.06), "rock", 0.05, (0, 0, -20), taper=0.8)
    return a


def ore_outcrop(name: str, crystal: str) -> Asset:
    """Readable ore site: rock teeth with coloured Benit crystals. Footprint about 1.6 x 1.3."""
    a = Asset(name)
    for x, y, w, d, h, rot in ((-0.3, 0.1, 0.9, 0.7, 0.8, 10), (0.4, -0.15, 0.7, 0.6, 0.56, -25), (0.1, 0.45, 0.5, 0.5, 0.4, 40)):
        a.box((w, d, h), (x, y, h * 0.5), "rock" if h > 0.5 else "rock_dark", 0.1, (0, 0, rot), taper=0.66)
    for x, y, h, rx, ry in ((-0.05, -0.3, 0.6, 14, -10), (0.32, 0.22, 0.46, -18, 8), (-0.55, -0.2, 0.36, 8, 20), (0.6, -0.4, 0.3, -10, -16)):
        a.box((0.16, 0.16, h), (x, y, h * 0.5 + 0.1), crystal, 0.03, (rx, ry, 30), taper=0.4)
    return a


def freighter_hull() -> Asset:
    """Broken cargo fuselage for the salvage site: open end, ribs, cargo spilling out. Footprint about 4.6 x 2.1."""
    a = Asset("ab_freighter_hull")
    a.box((4.2, 1.9, 1.5), (-0.1, 0.0, 0.7), "cream", 0.24, (0, 4, 0))
    a.box((4.24, 1.94, 0.34), (-0.1, 0.0, 0.5), "petrol", 0.05, (0, 4, 0))
    a.box((1.2, 1.5, 0.7), (-1.3, 0.0, 1.55), "cream_dark", 0.14, (0, 4, 0))             # cockpit hump
    a.box((0.5, 1.2, 0.3), (-1.75, 0.0, 1.62), "glass", 0.05, (0, 4, 0))
    a.box((0.12, 1.7, 1.3), (2.0, 0.0, 0.74), "steel_dark", 0.0, (0, 4, 0))              # torn open cargo end
    for x in (0.6, 1.2, 1.8):
        a.box((0.1, 2.0, 1.56), (x, 0.0, 0.72), "steel_dark", 0.02, (0, 4, 0))
    a.box((1.0, 0.5, 0.1), (2.6, -0.4, 0.06), "steel", 0.02, (0, 0, 20))                 # ripped floor plate
    a.crate(2.7, 0.5, 0.0, 0.42, "orange", 20)
    a.crate(3.1, -0.2, 0.0, 0.34, "cream_dark", -30)
    a.box((1.4, 0.7, 0.3), (-0.6, 1.2, 0.1), "earth", 0.1, (0, 0, 12), taper=0.7)        # ploughed-up soil
    a.box((1.2, 0.6, 0.26), (0.4, -1.2, 0.1), "earth_dark", 0.1, (0, 0, -8), taper=0.7)
    a.cyl(0.42, 0.9, (-0.9, -1.15, 0.5), "steel_dark", r2=0.5, seg=10, rot=(0, 86, 0))   # engine pod
    return a


def main() -> None:
    kit.OUT = OUT
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for asset in (satellite_wreck(), solar_fragment(), debris_small(), furrow_berm(),
                  ore_outcrop("ab_ore_outcrop_a", "benit_a"), ore_outcrop("ab_ore_outcrop_b", "benit_b"),
                  ore_outcrop("ab_ore_outcrop_c", "benit_c"), freighter_hull()):
        manifest[asset.name] = asset.export()
    (OUT / "kit_manifest.json").write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
    print(json.dumps({k: v["triangles"] for k, v in manifest.items()}))


if __name__ == "__main__":
    main()
