"""Polisar R09 (14.11.2026): authored layout facts.

Revision of the R08 layout after the user's annotated target (R04 image):
compact pads, a larger interior, larger upright rings centred on a longer
cross axle, solar wings on the left arm, four fuel tanks on the right arm and
two dock heads further out. Units are map plane units (one hex centre step),
local to origin_plane; x runs along the axle, z points to the front (map south).

Run:  python3 art/polisar_r09_20261114/author_layout.py
Writes layout.json next to this file. build_candidate.py compiles it.
"""
import json
from pathlib import Path

ART = Path(__file__).resolve().parent
T = 0.25  # half wall thickness

HUB = [-18, -2, 18, 23]
# Pad edge and the second small-pad row keep the R08 hex row phase (whole rows
# of sqrt(3)/2 from the R08 edge at z = 24): a landed ship snaps to a hex
# centre, and only this phase keeps its footprint on existing deck cells.
ROW = 0.8660254037844386
PAD_EDGE = round(24 + 4 * ROW, 4)
ROW2 = round(PAD_EDGE + 10 * ROW, 4)
CONCOURSE = [-46, 21, 46, PAD_EDGE]
AXLE_Z = 24.0
AXLE_Y = -2.2
RING_X = 50.0
RING_RADIUS = 34.0

ROOMS = [
    ("infantry", "INFANTERIE", [-24, -18, -8, -2], [-16, -2], "front", "yellow"),
    ("armor", "RÜSTUNG", [-8, -18, 8, -2], [0, -2], "front", "yellow"),
    ("engineering", "TECHNIK", [8, -18, 24, -2], [16, -2], "front", "cyan"),
    ("supplies", "VERSORGUNG", [-34, 2, -18, 18], [-18, 10], "right", "cyan"),
    ("freight", "FRACHT", [18, 2, 34, 18], [18, 10], "left", "yellow"),
]
DOOR = 4.0

PADS = [
    ("polisa_pad_01", "01", (-33, PAD_EDGE + 4.0), (10.0, 8.0), "M"),
    ("polisa_pad_02", "02", (-21, PAD_EDGE + 4.0), (10.0, 8.0), "M"),
    ("polisa_pad_03", "03", (0, PAD_EDGE + 6.0), (14.0, 12.0), "L"),
    ("polisa_pad_04", "04", (14, PAD_EDGE + 3.0), (8.0, 6.0), "S"),
    ("polisa_pad_05", "05", (24, PAD_EDGE + 3.0), (8.0, 6.0), "S"),
    ("polisa_pad_06", "06", (14, ROW2 + 3.0), (8.0, 6.0), "S"),
    ("polisa_pad_07", "07", (24, ROW2 + 3.0), (8.0, 6.0), "S"),
]
R08_PAD_SIZES = {"M": [12.0, 12.0], "L": [16.0, 24.0], "S": [8.0, 6.0]}
MARGIN = 0.65


def wall(rect, height, window, room):
    return {"rect": [round(v, 3) for v in rect], "height": height, "window": window, "room": room}


def split(a, b, gaps):
    """Segments of [a, b] left after cutting the (centre, width) gaps."""
    out, cur = [], a
    for centre, width in sorted(gaps):
        if centre - width / 2 > cur:
            out.append((cur, centre - width / 2))
        cur = centre + width / 2
    if cur < b:
        out.append((cur, b))
    return out


def main():
    walls, rooms, furniture = [], [], []
    for rid, title, r, door, side, accent in ROOMS:
        x0, z0, x1, z1 = r
        if side == "front":
            walls.append(wall([x0, z0 - T, x1, z0 + T], 3.3, False, rid))
            for a, b in split(x0, x1, [(door[0], DOOR)]):
                walls.append(wall([a, z1 - T, b, z1 + T], 0.65, True, rid))
            if rid == "infantry":
                walls.append(wall([x0 - T, z0, x0 + T, z1], 1.05, True, rid))
            walls.append(wall([x1 - T, z0, x1 + T, z1], 1.05, True, rid))
            anchor = [door[0], door[1] - 1.4]
        else:
            walls.append(wall([x0, z0 - T, x1, z0 + T], 1.05, False, rid))
            walls.append(wall([x0, z1 - T, x1, z1 + T], 0.65, True, rid))
            outer, inner = (x0, x1) if side == "right" else (x1, x0)
            walls.append(wall([outer - T, z0, outer + T, z1], 1.05, True, rid))
            for a, b in split(z0, z1, [(door[1], DOOR)]):
                walls.append(wall([inner - T, a, inner + T, b], 1.05, True, rid))
            anchor = [door[0] + (-2 if side == "right" else 2), door[1]]
        rooms.append({"id": rid, "title": title, "rect": r, "door": door, "door_side": side, "door_width": DOOR,
                      "accent": accent, "service_anchor": anchor, "sector": "B"})

    pad_gaps = [(p[2][0], 4.0 if p[4] == "L" else 2.5) for p in PADS if p[2][1] < ROW2]
    for a, b in split(CONCOURSE[0], CONCOURSE[2], pad_gaps):
        walls.append(wall([a, PAD_EDGE - T, b, PAD_EDGE + T], 1.0, True, "pad_access_"))
    for a, b in split(HUB[0], HUB[2], [(0, 6.0)]):
        walls.append(wall([a, 21 - T, b, 21 + T], 1.0, True, "lobby_entry_"))
    for sx in (-1, 1):
        walls.append(wall([sx * 18 - T, 18, sx * 18 + T, 21], 1.0, True, "lobby_entry_return"))
        walls.append(wall([sx * 18 - T, -2, sx * 18 + T, 2], 1.0, True, "lobby_entry_return"))
        lo, hi = sorted((sx * 46, sx * 18.25))
        walls.append(wall([lo, 21 - T, hi, 21 + T], 1.0, True, "concourse_rear"))
        walls.append(wall([sx * 46 - T, 21, sx * 46 + T, PAD_EDGE], 1.0, True, "concourse_end"))

    def item(fid, kind, rect, height, room, accent, **extra):
        furniture.append(dict({"id": fid, "kind": kind, "rect": rect, "height": height, "room": room,
                               "accent": accent, "sector": "B"}, **extra))

    item("infantry_counter", "counter", [-22.5, -6.0, -18.0, -4.8], 0.9, "infantry", "cyan")
    item("infantry_goods0", "goods", [-22.6, -16.3, -18.6, -14.8], 1.7, "infantry", "cyan")
    item("infantry_goods1", "goods", [-13.4, -16.3, -9.4, -14.8], 1.7, "infantry", "cyan")
    item("infantry_rack", "rack", [-23.3, -12.6, -22.1, -8.6], 1.7, "infantry", "cyan")
    item("engineering_counter", "counter", [18.0, -6.0, 22.5, -4.8], 0.9, "engineering", "cyan")
    item("engineering_goods0", "goods", [9.4, -16.3, 13.4, -14.8], 1.7, "engineering", "cyan")
    item("engineering_goods1", "goods", [18.6, -16.3, 22.6, -14.8], 1.7, "engineering", "cyan")
    item("engineering_rack", "rack", [22.1, -12.6, 23.3, -8.6], 1.7, "engineering", "cyan")
    item("armor_counter", "counter", [-6.8, -5.8, -3.6, -4.6], 0.9, "armor", "yellow")
    for name, x in (("light", -5.0), ("medium", 0.0), ("heavy", 5.0)):
        item("showcase_" + name, "armor", [x - 2.5, -16.9, x + 2.5, -14.1], 0.3, "armor", "yellow", armor=name)
    item("supplies_counter", "counter", [-25.6, 13.6, -21.0, 14.8], 0.9, "supplies", "cyan")
    for i, z in enumerate((2.4, 9.2)):
        item("supplies_goods%d" % i, "goods", [-33.5, z, -29.5, z + 1.5], 1.7, "supplies", "cyan")
    item("supplies_rack", "rack", [-27.2, 2.4, -23.2, 3.6], 1.7, "supplies", "cyan")
    item("freight_counter", "counter", [21.0, 13.6, 24.8, 14.8], 0.9, "freight", "yellow")
    item("freight_goods0", "cargo", [23.0, 3.2, 28.0, 7.2], 0.35, "freight", "yellow")
    item("freight_goods1", "cargo", [27.6, 9.6, 32.6, 13.6], 0.35, "freight", "yellow")
    item("globe", "globe", [-2.2, 7.8, 2.2, 12.2], 0.65, "hub", "cyan")
    for sx in (-1, 1):
        for name, z in (("front", 17.3), ("rear", 0.4)):
            lo, hi = sorted((sx * 8.0, sx * 14.0))
            item("bench_%s_%s" % (name, "l" if sx < 0 else "r"), "bench", [lo, z, hi, z + 1.4], 0.5, "hub", "cyan")

    pads = [{"id": pid, "number": number, "center": list(center), "size": list(size),
             "reserve_envelope": [round(size[0] - 2 * MARGIN, 3), round(size[1] - 2 * MARGIN, 3)],
             "class": cls, "sector": "B"} for pid, number, center, size, cls in PADS]
    markers = {p["id"]: p["center"] for p in pads}
    markers.update({"trade_service": [0, 17], "objective_point": [0, 17], "spawn_alpha": pads[0]["center"],
                    "ship_return": pads[0]["center"], "spawn_bravo": pads[4]["center"]})

    blocked, modules = [], []
    for sx, tag in ((-1, "left"), (1, "right")):
        def rr(a, z0, b, z1):
            lo, hi = sorted((sx * a, sx * b))
            return [lo, z0, hi, z1]
        blocked.append({"id": tag, "rect": rr(34, -18, 46, 21), "height": 4, "kind": "technical_zone"})
        blocked.append({"id": tag + "_inner", "rect": rr(24, -18, 34, 2), "height": 4, "kind": "technical_zone"})
        modules += [
            {"id": tag + "_plant", "rect": rr(35.2, -17.0, 45.0, -6.0), "height": 3.2, "kind": "plant"},
            {"id": tag + "_tank", "rect": rr(35.2, -4.0, 45.0, 8.0), "height": 4.4, "kind": "tank"},
            {"id": tag + "_vent", "rect": rr(35.2, 10.0, 45.0, 20.0), "height": 2.8, "kind": "vent"},
            {"id": tag + "_store", "rect": rr(25.0, -17.0, 33.0, 1.0), "height": 3.6, "kind": "reactor"},
        ]
    # Rear half: decoration beyond the map boundary (z < -20). No decks, no tiles.
    rear = []
    for i, (x0, x1, depth, height, kind) in enumerate([
            (-46, -34, 14, 4.2, "reactor"), (-33, -21, 18, 3.4, "plant"), (-20, -9, 12, 5.0, "vent"),
            (-8, 8, 20, 6.2, "sign"), (9, 20, 12, 5.0, "vent"), (21, 33, 18, 3.4, "tank"),
            (34, 46, 14, 4.2, "reactor")]):
        rear.append({"id": "rear%d" % i, "rect": [x0, -21.0 - depth, x1, -20.6], "height": height, "kind": kind})

    layout = {
        "schema": "polisa_authored_layout_v9",
        "revision": "polisar_r09",
        "display_name": "POLISAR",
        "origin_plane": [0, -70],
        "grid_size": [512, 256],
        "grid_offset_bounds": [-256, -104, 255, 151],
        "space_bounds": [-256, -90, 256, 132],
        "map_boundary_local_z": -20.0,
        "standard_camera": {"yaw": 24, "pitch": 50, "size": 66, "focus_local": [0, 14]},
        "station_camera": {"yaw": 12, "pitch": 50, "size": 128, "focus_local": [0, 16]},
        "sectors": [{"id": "B", "center_x": 0, "hub": HUB, "concourse": CONCOURSE}],
        "decks": [{"id": "hub", "rect": HUB, "kind": "hub"}, {"id": "concourse", "rect": CONCOURSE, "kind": "bridge"}]
        + [{"id": r["id"], "rect": r["rect"], "kind": "room"} for r in rooms]
        + [{"id": "small_connector14", "rect": [12.5, PAD_EDGE + 6.0, 15.5, ROW2], "kind": "bridge"},
           {"id": "small_connector24", "rect": [22.5, PAD_EDGE + 6.0, 25.5, ROW2], "kind": "bridge"}],
        "walls": walls, "rooms": rooms, "furniture": furniture, "pads": pads, "markers": markers,
        "blocked_zones": blocked, "technical_modules": modules, "rear_decoration": rear,
        "globe": {"centers": [[0, 10]]},
        "pad_aliases": {"B_M1": "polisa_pad_01", "B_M2": "polisa_pad_02", "B_L3": "polisa_pad_03", "B_S4": "polisa_pad_04",
                        "B_S5": "polisa_pad_05", "B_S6": "polisa_pad_06", "B_S7": "polisa_pad_07"},
        "pad_scale_source": {"path": "maps/homebase_frontier_exploration.json",
                             "json_pointer": "/homebase_exploration/landing_pads/0/size",
                             "sha256": "7fc1c5fae3b726dd4e44840e4320737cad02e4d20eec2d6fd5cf61153669701a",
                             "small_size": [8.0, 6.0], "reserve_margin": MARGIN, "r08_sizes": R08_PAD_SIZES},
        "engineering": {
            "ring_x": [-RING_X, RING_X], "ring_z": AXLE_Z, "ring_center_y": AXLE_Y, "ring_radius": RING_RADIUS,
            "ring_width": 3.2, "ring_yaw_degrees": 0, "r08_ring_radius": 28,
            "axle_x": [-104, 104], "axle_y": AXLE_Y, "axle_z": AXLE_Z, "axle_radius": 1.6, "r08_axle_x": [-88, 88],
            "solar_wings": [{"id": "solar_rear", "center": [-74, AXLE_Z - 19], "size": [18, 22]},
                            {"id": "solar_front", "center": [-74, AXLE_Z + 19], "size": [18, 22]}],
            "fuel_tanks": [{"id": "tank_%d" % i, "center": [x, AXLE_Z + dz], "length": 13.0, "radius": 3.6}
                           for i, (x, dz) in enumerate([(66, -8), (82, -8), (66, 8), (82, 8)])],
            "outer_ports": [
                {"id": "port_left", "label": "Dock 1", "center": [-98, AXLE_Z], "facing": [-1, 0],
                 "approach_rect": [-140.0, AXLE_Z - 10, -106.0, AXLE_Z + 10], "arm_from": [-RING_X, AXLE_Z],
                 "arm_to": [-98, AXLE_Z], "r08_center_x": -82, "visual_only": True},
                {"id": "port_right", "label": "Dock 2", "center": [98, AXLE_Z], "facing": [1, 0],
                 "approach_rect": [106.0, AXLE_Z - 10, 140.0, AXLE_Z + 10], "arm_from": [RING_X, AXLE_Z],
                 "arm_to": [98, AXLE_Z], "r08_center_x": 82, "visual_only": True}],
        },
        "passages": [{"id": "pad_access_%d" % i, "center": [c, PAD_EDGE], "width": w, "clear_height": 2.3,
                      "status": "open_geometry", "wall_group": "pad_access_"} for i, (c, w) in enumerate(sorted(pad_gaps))]
        + [{"id": "lobby_entry_0", "center": [0, 21], "width": 6.0, "clear_height": 2.3, "status": "open_geometry",
            "wall_group": "lobby_entry_"}],
    }
    (ART / "layout.json").write_text(json.dumps(layout, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print("walls", len(walls), "furniture", len(furniture), "pads", len(pads))


if __name__ == "__main__":
    main()
