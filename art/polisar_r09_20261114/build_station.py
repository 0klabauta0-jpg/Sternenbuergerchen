"""Polisar R09 (14.11.2026): the station as an editable Blender asset.

Builds the whole station from layout.json (the same facts that produce the
map tiles), so walls, rooms, pads and blockers sit exactly where the game
walks. Everything else follows the user's annotated target: upright rings
centred on a long cross axle, radial spokes and diagonal braces, solar wings
on the left arm, four fuel tanks on the right arm, two dock heads at the arm
ends and a dim rear half beyond the map boundary.

Coordinates: layout (x, z, up) -> Blender (x, -z, up). The map plane is
Blender XY, Z is up, the axle runs along X, ring planes are YZ. One Blender
unit is one map plane unit; the pivot is the layout origin on the deck plane.
glTF export (Y up) gives Godot x = layout x, z = layout z, y = up, so the
model sits on the station origin with scale 1 and no extra rotation.

Run:  python3 art/polisar_r09_20261114/build_station.py   (needs the bpy module)
Writes blender/polisar_r09.blend (ignored by Godot), the GLB to
Assets/curated/polisar_r09_20261114/ and model_manifest.json.
"""
import hashlib
import json
import math
from pathlib import Path

import bpy  # must come first: it makes bmesh and mathutils importable
import bmesh
from mathutils import Euler, Matrix, Vector

ART = Path(__file__).resolve().parent
ROOT = ART.parents[1]
OUT = ROOT / "Assets" / "curated" / "polisar_r09_20261114"
L = json.loads((ART / "layout.json").read_text(encoding="utf-8"))
E = L["engineering"]

PALETTE = {
    "hull": "c3c5bb", "hull_shade": "a2a69d", "graphite": "2a3238", "steel": "7d898b", "steel_dark": "566266",
    "deck": "58686e", "deck_inset": "4a5a61", "floor_light": "77868b", "pad": "505e65",
    "teal": "3f7479", "ochre": "d2a443", "cyan_paint": "6fbfbd", "tank": "bfc1b8",
    "solar": "1a3156", "solar_frame": "98a3a7", "glass": "44707c",
    "cyan": "7fe0dc", "holo": "2f93d6", "warm": "ffc974",
}
for _name in ("hull", "hull_shade", "graphite", "steel", "steel_dark", "teal", "ochre", "tank"):
    _rgb = [int(int(PALETTE[_name][i:i + 2], 16) * 0.56) for i in (0, 2, 4)]
    PALETTE[_name + "_dim"] = "%02x%02x%02x" % tuple(_rgb)
EMISSIVE = {"cyan": 1.2, "holo": 0.7, "warm": 1.5}
ALPHA = {"glass": 0.42, "holo": 0.82}
DECK_TOP = 0.02


def lin(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def material(color: str):
    mat = bpy.data.materials.get("polisar_" + color)
    if mat is None:
        mat = bpy.data.materials.new("polisar_" + color)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        rgb = [lin(int(PALETTE[color][i:i + 2], 16) / 255.0) for i in (0, 2, 4)]
        bsdf.inputs["Base Color"].default_value = (*rgb, ALPHA.get(color, 1.0))
        bsdf.inputs["Roughness"].default_value = 0.6 if color in ("glass", "solar", "holo") else 0.85
        bsdf.inputs["Metallic"].default_value = 0.12 if color.startswith(("steel", "graphite")) else 0.0
        if color in EMISSIVE:
            bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
            bsdf.inputs["Emission Strength"].default_value = EMISSIVE[color]
        if color in ALPHA:
            bsdf.inputs["Alpha"].default_value = ALPHA[color]
            mat.surface_render_method = "BLENDED"
    return mat


class Part:
    """One mesh object. All coordinates are layout coordinates (x, z, up)."""

    def __init__(self, name: str, collection: str):
        self.name, self.collection = name, collection
        self.bm = bmesh.new()
        self.colors: list[str] = []
        self.scratch = bpy.data.meshes.new("scratch")

    def _merge(self, part, color, loc, rot=(0.0, 0.0, 0.0)):
        matrix = Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot)).to_matrix().to_4x4()
        bmesh.ops.transform(part, matrix=matrix, verts=part.verts)
        if color not in self.colors:
            self.colors.append(color)
        index = self.colors.index(color)
        for face in part.faces:
            face.material_index = index
        part.to_mesh(self.scratch)
        part.free()
        self.bm.from_mesh(self.scratch)

    def box(self, x, z, y0, sx, sz, h, color, bevel=None, yaw=0.0, rot=None):
        """Box standing on height y0. rot=(rx, ry, rz) in Blender axes overrides yaw."""
        part = bmesh.new()
        bmesh.ops.create_cube(part, size=1.0)
        for v in part.verts:
            v.co = Vector((v.co.x * sx, v.co.y * sz, v.co.z * h))
        if bevel is None:
            bevel = 0.07 if min(sx, sz, h) >= 0.6 else 0.0
        if bevel > 0.0:
            bmesh.ops.bevel(part, geom=list(part.edges), offset=min(bevel, min(sx, sz, h) * 0.45), segments=1,
                            affect="EDGES", profile=0.5)
        self._merge(part, color, (x, -z, y0 + h * 0.5), rot if rot is not None else (0, 0, yaw))

    def cbox(self, x, z, yc, sx, sz, h, color, rot, bevel=0.0):
        """Box centred on (x, z, yc) with a free Blender rotation."""
        part = bmesh.new()
        bmesh.ops.create_cube(part, size=1.0)
        for v in part.verts:
            v.co = Vector((v.co.x * sx, v.co.y * sz, v.co.z * h))
        if bevel > 0.0:
            bmesh.ops.bevel(part, geom=list(part.edges), offset=bevel, segments=1, affect="EDGES", profile=0.5)
        self._merge(part, color, (x, -z, yc), rot)

    def cyl(self, x, z, y0, h, r, color, seg=14, r2=None, bevel=0.0):
        part = bmesh.new()
        bmesh.ops.create_cone(part, cap_ends=True, cap_tris=False, segments=seg, radius1=r,
                              radius2=r if r2 is None else r2, depth=h)
        if bevel > 0.0:
            rim = [e for e in part.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-6]
            bmesh.ops.bevel(part, geom=rim, offset=bevel, segments=1, affect="EDGES", profile=0.5)
        self._merge(part, color, (x, -z, y0 + h * 0.5))

    def pipe(self, a, b, r, color, seg=8, r2=None):
        """Cylinder between two layout points (x, z, up)."""
        va, vb = Vector((a[0], -a[1], a[2])), Vector((b[0], -b[1], b[2]))
        axis = vb - va
        part = bmesh.new()
        bmesh.ops.create_cone(part, cap_ends=True, cap_tris=False, segments=seg, radius1=r,
                              radius2=r if r2 is None else r2, depth=axis.length)
        quat = Vector((0, 0, 1)).rotation_difference(axis.normalized())
        bmesh.ops.transform(part, matrix=quat.to_matrix().to_4x4(), verts=part.verts)
        self._merge(part, color, (va + vb) * 0.5)

    def beam(self, a, b, w, color):
        self.pipe(a, b, w * 0.7071, color, seg=4)

    def sphere(self, x, z, y, r, color, seg=16):
        part = bmesh.new()
        bmesh.ops.create_uvsphere(part, u_segments=seg, v_segments=seg // 2, radius=r)
        self._merge(part, color, (x, -z, y))

    def prism(self, pts, y0, y1, color):
        """Vertical extrusion of a convex polygon given as layout (x, z) points."""
        part = bmesh.new()
        top = [part.verts.new((x, -z, y1)) for x, z in pts]
        bottom = [part.verts.new((x, -z, y0)) for x, z in pts]
        part.faces.new(top)
        part.faces.new(list(reversed(bottom)))
        n = len(pts)
        for i in range(n):
            part.faces.new([top[i], bottom[i], bottom[(i + 1) % n], top[(i + 1) % n]])
        bmesh.ops.recalc_face_normals(part, faces=list(part.faces))
        self._merge(part, color, (0, 0, 0))

    def annulus(self, x, z, y, r_out, r_in, color, seg=48, h=0.012):
        part = bmesh.new()
        for i in range(seg):
            a0, a1 = math.tau * i / seg, math.tau * (i + 1) / seg
            quad = [(r_in, a0), (r_out, a0), (r_out, a1), (r_in, a1)]
            lo = [part.verts.new((r * math.cos(a), r * math.sin(a), 0.0)) for r, a in quad]
            hi = [part.verts.new((r * math.cos(a), r * math.sin(a), h)) for r, a in quad]
            part.faces.new(hi)
            part.faces.new(list(reversed(lo)))
        self._merge(part, color, (x, -z, y))

    def torus_x(self, x, z, y, r_out, r_in, width, colors, seg=72, chamfer=0.45):
        """Upright ring around the X axis: plane YZ in Blender. colors(i, face) -> name;
        face is 'outer', 'side' or 'inner'."""
        half = width * 0.5
        section = [(-half, r_in), (-half, r_out - chamfer), (-half + chamfer, r_out),
                   (half - chamfer, r_out), (half, r_out - chamfer), (half, r_in)]
        kinds = ["side", "outer", "outer", "outer", "side", "inner"]
        for i in range(seg):
            a0, a1 = math.tau * i / seg, math.tau * (i + 1) / seg
            for k in range(len(section)):
                (xa, ra), (xb, rb) = section[k], section[(k + 1) % len(section)]
                part = bmesh.new()
                quad = [(xa, ra, a0), (xb, rb, a0), (xb, rb, a1), (xa, ra, a1)]
                part.faces.new([part.verts.new((px, r * math.sin(a), r * math.cos(a))) for px, r, a in quad])
                self._merge(part, colors(i, kinds[k]), (x, -z, y))

    def finish(self):
        mesh = bpy.data.meshes.new(self.name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=0.0004)
        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        self.bm.to_mesh(mesh)
        tris = sum(len(f.verts) - 2 for f in self.bm.faces)
        self.bm.free()
        for color in self.colors:
            mesh.materials.append(material(color))
        obj = bpy.data.objects.new(self.name, mesh)
        col = bpy.data.collections.get(self.collection)
        if col is None:
            col = bpy.data.collections.new(self.collection)
            bpy.context.scene.collection.children.link(col)
        col.objects.link(obj)
        return obj, tris


def centre(r):
    return (r[0] + r[2]) * 0.5, (r[1] + r[3]) * 0.5


def size(r):
    return r[2] - r[0], r[3] - r[1]


# ================================================================ structure
def build_structure() -> Part:
    p = Part("Struktur_Innenbereich", "01_Struktur_Innenbereich")
    hub = L["sectors"][0]["hub"]
    con = L["sectors"][0]["concourse"]
    for deck in L["decks"]:
        (cx, cz), (sx, sz) = centre(deck["rect"]), size(deck["rect"])
        p.box(cx, cz, DECK_TOP - 0.5, sx, sz, 0.5, "deck", 0.0)
        if deck["kind"] == "room":
            p.box(cx, cz, DECK_TOP, sx - 0.9, sz - 0.9, 0.012, "deck_inset", 0.0)
    (cx, cz), (sx, sz) = centre(hub), size(hub)
    p.box(cx, cz, DECK_TOP, sx - 0.8, sz - 0.8, 0.012, "floor_light", 0.0)
    for i in range(1, 6):                                   # floor seams of the plaza
        p.box(hub[0] + sx * i / 6.0, cz, DECK_TOP + 0.012, 0.07, sz - 1.2, 0.004, "steel", 0.0)
    for i in range(1, 4):
        p.box(cx, hub[1] + sz * i / 4.0, DECK_TOP + 0.012, sx - 1.2, 0.07, 0.004, "steel", 0.0)
    for zone in L["blocked_zones"]:
        (cx, cz), (sx, sz) = centre(zone["rect"]), size(zone["rect"])
        p.box(cx, cz, DECK_TOP - 0.5, sx, sz, 0.5, "graphite", 0.0)
    # pressure hull below the decks, stepped like a keel
    p.box(0, 2.5, -3.6, 91.0, 40.0, 3.1, "hull", 0.5)
    p.box(0, 2.5, -5.0, 70.0, 30.0, 1.4, "hull_shade", 0.4)
    p.box(0, 2.5, -5.9, 44.0, 18.0, 0.9, "graphite", 0.3)
    p.box(0, (con[1] + con[3]) * 0.5, -4.4, 92.0, con[3] - con[1] + 0.3, 3.9, "hull_shade", 0.4)          # the spine that carries the concourse
    for x in range(-40, 41, 10):
        p.box(x, con[3] + 0.12, -2.6, 2.6, 0.3, 1.5, "graphite", 0.05)        # service bays in the spine front
        p.box(x, con[3] + 0.3, -1.5, 1.6, 0.08, 0.16, "cyan", 0.0)
    for x in range(-42, 43, 12):
        p.box(x, -18.3, -2.6, 5.0, 0.5, 1.6, "teal", 0.08)
    for wall in L["walls"]:
        (cx, cz), (sx, sz) = centre(wall["rect"]), size(wall["rect"])
        h = float(wall["height"])
        along_x = sx >= sz
        if h >= 3.0:                                        # tall rear wall of a shop
            p.box(cx, cz, DECK_TOP, sx, sz, h, "hull", 0.06)
            p.box(cx, cz + 0.03, 2.25, sx - 0.3, sz + 0.06, 0.42, "teal", 0.0)
            p.box(cx, cz + sz * 0.5 + 0.03, 2.95, sx - 0.6, 0.05, 0.1, "cyan", 0.0)
            p.box(cx, cz, DECK_TOP, sx + 0.1, sz + 0.1, 0.22, "graphite", 0.0)
            for k in range(int(sx // 4)):
                p.box(cx - sx * 0.5 + 2.0 + k * 4.0, cz, DECK_TOP + 0.3, 0.12, sz + 0.05, h - 0.5, "hull_shade", 0.0)
        else:
            base = min(h, 0.46)
            p.box(cx, cz, DECK_TOP, sx, sz, base, "hull", 0.04)
            if wall["window"] and h > base:
                gx, gz = (sx - 0.1, sz * 0.34) if along_x else (sx * 0.34, sz - 0.1)
                p.box(cx, cz, DECK_TOP + base, gx, gz, h - base - 0.06, "glass", 0.0)
            elif h > base:
                p.box(cx, cz, DECK_TOP + base, sx * (1.0 if along_x else 0.7), sz * (0.7 if along_x else 1.0), h - base - 0.06, "hull_shade", 0.0)
            p.box(cx, cz, DECK_TOP + h - 0.06, sx, sz, 0.06, "steel", 0.0)
            count = max(1, int(max(sx, sz) // 3.0))
            for k in range(count + 1):                       # posts
                t = k / count - 0.5
                px, pz = (cx + t * (sx - 0.16), cz) if along_x else (cx, cz + t * (sz - 0.16))
                p.box(px, pz, DECK_TOP, 0.16 if along_x else sx + 0.04, sz + 0.04 if along_x else 0.16, h, "steel_dark", 0.0)
    for room in L["rooms"]:
        accent = "ochre" if room["accent"] == "yellow" else "cyan_paint"
        dx, dz = room["door"]
        front = room["door_side"] == "front"
        half = room["door_width"] * 0.5 + 0.13
        for s in (-1, 1):
            px, pz = (dx + s * half, dz) if front else (dx, dz + s * half)
            p.box(px, pz, DECK_TOP, 0.3, 0.3, 1.7, "graphite", 0.04)
            p.box(px, pz, DECK_TOP + 0.5, 0.34, 0.34, 0.5, accent, 0.0)
            p.box(px, pz, DECK_TOP + 1.7, 0.2, 0.2, 0.1, "warm", 0.0)
        tx, tz = (room["door_width"], 0.7) if front else (0.7, room["door_width"])
        p.box(dx, dz, DECK_TOP + 0.012, tx, tz, 0.012, accent, 0.0)
        if front:                                            # shop sign bar on the rear wall
            (cx, _), (sx, _) = centre(room["rect"]), size(room["rect"])
            p.box(cx, room["rect"][1] + 0.45, 2.7, sx * 0.62, 0.22, 0.6, "graphite", 0.04)
            p.box(cx, room["rect"][1] + 0.6, 2.72, sx * 0.62 - 0.3, 0.04, 0.05, accent, 0.0)
    for passage in L["passages"]:                            # open gate frames at every access
        cx, cz = passage["center"]
        half, top = passage["width"] * 0.5 + 0.16, float(passage["clear_height"])
        for s in (-1, 1):
            p.box(cx + s * half, cz, DECK_TOP, 0.32, 0.62, top, "graphite", 0.05)
            p.box(cx + s * half, cz + 0.33, DECK_TOP + 0.9, 0.12, 0.04, 0.9, "warm", 0.0)
        p.box(cx, cz, DECK_TOP + top, passage["width"] + 0.9, 0.7, 0.34, "hull", 0.06)
        p.box(cx, cz + 0.37, DECK_TOP + top + 0.1, passage["width"] * 0.6, 0.04, 0.1, "ochre", 0.0)
    for item in L["furniture"]:
        build_furniture(p, item)
    return p


def build_furniture(p: Part, item: dict) -> None:
    (cx, cz), (sx, sz) = centre(item["rect"]), size(item["rect"])
    h = float(item["height"])
    accent = "cyan_paint" if item["accent"] == "cyan" else "ochre"
    kind = item["kind"]
    y = DECK_TOP
    if kind == "globe":
        p.cyl(cx, cz, y, 0.66, 2.2, "graphite", 18, bevel=0.08)
        p.cyl(cx, cz, y + 0.66, 0.12, 2.28, "steel", 18)
        p.cyl(cx, cz, y + 0.78, 0.05, 1.5, "cyan", 20)
        p.sphere(cx, cz, 1.9, 1.08, "holo", 20)
        for rot in ((90, 0, 0), (0, 90, 0), (0, 0, 0)):
            part = bmesh.new()
            bmesh.ops.create_circle(part, cap_ends=False, segments=28, radius=1.12)
            ring = bmesh.ops.extrude_edge_only(part, edges=list(part.edges))
            for v in [g for g in ring["geom"] if isinstance(g, bmesh.types.BMVert)]:
                v.co *= 1.035
            p._merge(part, "cyan", (cx, -cz, 1.9), rot)
        for i in range(4):
            a = math.tau * i / 4 + math.pi / 4
            p.box(cx + math.cos(a) * 1.85, cz + math.sin(a) * 1.85, y + 0.78, 0.6, 0.5, 0.36, "steel", 0.04, yaw=-math.degrees(a))
            p.box(cx + math.cos(a) * 1.85, cz + math.sin(a) * 1.85, y + 1.14, 0.44, 0.34, 0.03, "cyan", 0.0, yaw=-math.degrees(a))
        p.annulus(cx, cz, y + 0.014, 5.65, 5.5, "cyan")
        p.annulus(cx, cz, y + 0.014, 3.4, 3.32, "cyan_paint")
        return
    if kind == "bench":
        p.box(cx, cz, y + 0.3, sx, sz * 0.62, 0.16, "hull", 0.04)
        p.box(cx, cz - sz * 0.36, y + 0.46, sx, 0.16, 0.5, "steel", 0.03)
        for s in (-1, 1):
            p.box(cx + s * (sx * 0.5 - 0.3), cz, y, 0.22, sz * 0.5, 0.3, "graphite", 0.0)
        p.box(cx + sx * 0.5 + 0.55, cz, y, 0.62, 0.62, 0.42, "teal", 0.05)      # planter box
        p.sphere(cx + sx * 0.5 + 0.55, cz, y + 0.62, 0.3, "cyan_paint", 8)
        return
    if kind == "counter":
        p.box(cx, cz, y, sx, sz, h, "graphite", 0.05)
        p.box(cx, cz, y + h, sx + 0.1, sz + 0.1, 0.09, "hull", 0.0)
        p.box(cx, cz, y + 0.28, sx - 0.4, sz + 0.03, 0.34, "steel", 0.0)
        p.box(cx + sx * 0.22, cz, y + h + 0.09, 1.0, 0.12, 0.52, "graphite", 0.03)
        p.box(cx + sx * 0.22, cz + 0.07, y + h + 0.16, 0.84, 0.03, 0.36, "cyan", 0.0)
        p.box(cx - sx * 0.26, cz, y + h + 0.09, 0.6, 0.46, 0.2, "steel", 0.03)
        p.box(cx - sx * 0.26, cz, y + h + 0.29, 0.34, 0.24, 0.16, accent, 0.0)
    elif kind == "goods":
        for s in (-1, 1):
            p.box(cx + s * (sx * 0.5 - 0.06), cz, y, 0.12, sz, h + 0.5, "graphite", 0.0)
        p.box(cx, cz - sz * 0.5 + 0.04, y, sx, 0.08, h + 0.5, "deck_inset", 0.0)
        for level in (0.18, 0.84, 1.5):
            p.box(cx, cz, y + level, sx, sz, 0.08, "steel", 0.0)
            for n in range(4):
                bx = cx + (n - 1.5) * sx * 0.23
                color = (accent, "hull", "teal", "hull_shade")[(n + int(level * 10)) % 4]
                p.box(bx, cz + 0.04, y + level + 0.08, sx * 0.17, sz * 0.66, 0.34 + 0.08 * ((n + int(level * 3)) % 2), color, 0.03)
    elif kind == "rack":
        along_x = sx >= sz
        p.box(cx, cz, y, sx, sz, 0.14, "graphite", 0.0)
        p.box(cx, cz, y + h + 0.3, sx, sz, 0.1, "graphite", 0.0)
        count = int(max(sx, sz) / 0.55)
        for n in range(count):
            t = (n + 0.5) / count - 0.5
            px, pz = (cx + t * sx, cz) if along_x else (cx, cz + t * sz)
            p.box(px, pz, y + 0.14, 0.14, 0.14, h + 0.16, "steel_dark", 0.0)
            p.box(px, pz, y + 0.5, 0.26, 0.26, 0.9, "hull" if n % 3 else accent, 0.03)
    elif kind == "cargo":
        p.box(cx, cz, y, sx, sz, h, "graphite", 0.04)
        for ix, dx in enumerate((-1.3, 1.3)):
            for iz, dz in enumerate((-0.95, 0.95)):
                color = ("ochre", "hull_shade", "teal", "ochre")[ix * 2 + iz]
                p.box(cx + dx, cz + dz, y + h, 1.9, 1.5, 1.1, color, 0.06)
                p.box(cx + dx, cz + dz, y + h, 0.16, 1.54, 1.12, "graphite", 0.0)
                p.box(cx + dx, cz + dz, y + h + 1.1, 1.94, 1.54, 0.08, "steel", 0.0)
        p.box(cx - 1.3, cz - 0.95, y + h + 1.18, 1.3, 1.1, 0.8, "hull", 0.05)
    elif kind == "armor":
        p.box(cx, cz, y, sx - 0.16, sz - 0.2, h, "graphite", 0.04)
        p.box(cx, cz, y + h, sx - 0.5, sz - 0.6, 0.04, accent, 0.0)
        p.box(cx, cz - sz * 0.46, y, sx - 0.16, 0.16, 2.9, "deck_inset", 0.0)
        for s in (-1, 1):
            p.box(cx + s * (sx * 0.5 - 0.1), cz - sz * 0.3, y, 0.12, sz * 0.5, 2.9, "hull_shade", 0.0)
            p.box(cx + s * (sx * 0.5 - 0.17), cz - sz * 0.42, y + 0.3, 0.05, 0.08, 2.4, "cyan", 0.0)
        p.box(cx, cz - sz * 0.3, y + 2.9, sx - 0.1, sz * 0.52, 0.12, "hull", 0.0)


# ====================================================================== roofs
def build_roofs() -> Part:
    p = Part("Daecher", "02_Daecher")
    for room in L["rooms"]:
        (cx, cz), (sx, sz) = centre(room["rect"]), size(room["rect"])
        p.box(cx, cz, 3.34, sx + 0.5, sz + 0.5, 0.36, "hull", 0.14)
        p.box(cx, cz, 3.7, sx - 2.0, sz - 2.0, 0.14, "hull_shade", 0.05)
        p.box(cx - sx * 0.25, cz - sz * 0.2, 3.84, 2.4, 2.0, 0.5, "graphite", 0.08)
        p.cyl(cx + sx * 0.22, cz + sz * 0.15, 3.84, 0.3, 1.1, "steel", 12)
    hub = L["sectors"][0]["hub"]
    (cx, cz), (sx, sz) = centre(hub), size(hub)
    for i in range(7):
        p.box(hub[0] + sx * i / 6.0, cz, 3.5, 0.3, sz, 0.3, "hull", 0.0)
    for i in range(5):
        p.box(cx, hub[1] + sz * i / 4.0, 3.5, sx, 0.3, 0.3, "hull", 0.0)
    p.box(cx, cz, 3.6, sx - 0.3, sz - 0.3, 0.05, "glass", 0.0)
    return p


# ======================================================================= pads
def build_pads() -> Part:
    p = Part("Pads", "03_Pads")
    for pad in L["pads"]:
        cx, cz = pad["center"]
        sx, sz = pad["size"]
        cls = pad["class"]
        cut = 0.6 if cls == "S" else 0.9
        x0, x1, z0, z1 = cx - sx / 2, cx + sx / 2, cz - sz / 2, cz + sz / 2
        outline = [(x0 + cut, z0), (x1 - cut, z0), (x1, z0 + cut), (x1, z1 - cut), (x1 - cut, z1), (x0 + cut, z1), (x0, z1 - cut), (x0, z0 + cut)]
        p.prism(outline, -0.55, DECK_TOP, "pad")
        inner = [(cx + (x - cx) * (1 - 0.5 / sx), cz + (z - cz) * (1 - 0.5 / sz)) for x, z in outline]
        p.prism(inner, -1.25, -0.55, "hull")
        p.prism([(cx + (x - cx) * 0.7, cz + (z - cz) * 0.7) for x, z in outline], -1.9, -1.25, "graphite")
        inset = 0.42 if cls == "S" else 0.55
        for s in (-1, 1):                                      # ochre border, kept inside the deck
            p.box(cx, cz + s * (sz / 2 - inset), DECK_TOP, sx - 2 * cut - 0.3, 0.1, 0.012, "ochre", 0.0)
            p.box(cx + s * (sx / 2 - inset), cz, DECK_TOP, 0.1, sz - 2 * cut - 0.3, 0.012, "ochre", 0.0)
            for t in (-1, 1):
                p.box(cx + s * (sx / 2 - 0.3), cz + t * (sz / 2 - cut - 0.25), DECK_TOP, 0.2, 0.2, 0.09, "cyan", 0.0)
            p.box(cx + s * sx * 0.24, cz, DECK_TOP, 0.1, sz * 0.42, 0.012, "hull", 0.0)   # touchdown bars
            p.box(cx + s * (sx / 2 - 0.2), cz, -1.0, 0.5, sz * 0.4, 0.5, "graphite", 0.05)  # service trunk
            p.box(cx + s * (sx / 2 + 0.06), cz, -0.86, 0.06, sz * 0.3, 0.1, "warm", 0.0)
        p.cyl(cx, cz, DECK_TOP, 0.012, 0.3, "cyan", 12)
        p.box(cx + sx * 0.3, cz - sz * 0.22, DECK_TOP, 1.5, 1.2, 0.012, "graphite", 0.0)   # lift hatch
        if cls == "L":
            for dz in (sz * 0.26, sz * 0.36):
                for s in (-1, 1):
                    p.box(cx + s * 0.75, cz + dz + 0.38, DECK_TOP, 1.7, 0.3, 0.012, "ochre", 0.0, yaw=s * 28)
        # hazard blocks on the front corners
        for s in (-1, 1):
            p.box(cx + s * (sx / 2 - cut - 0.5), cz + sz / 2 - 0.22, DECK_TOP, 0.9, 0.24, 0.012, "ochre", 0.0)
    for deck in L["decks"]:
        if deck["id"].startswith("small_connector"):
            (cx, cz), (sx, sz) = centre(deck["rect"]), size(deck["rect"])
            for s in (-1, 1):
                p.box(cx + s * (sx / 2 - 0.05), cz, DECK_TOP, 0.1, sz, 0.7, "steel", 0.0)
            p.box(cx, cz, -1.1, sx - 0.6, sz + 0.4, 0.6, "hull", 0.05)
    return p


# ============================================================ rings and axle
def ring_colors(i: int, face: str) -> str:
    if face == "inner":
        return "graphite"
    if face == "side":
        return "hull_shade"
    return "ochre" if i % 12 in (2, 3) else ("hull_shade" if i % 4 == 0 else "hull")


def build_ring(index: int, x: float) -> Part:
    p = Part("Ring_Links" if x < 0 else "Ring_Rechts", "04_Ringe_Achse")
    z, y, radius, width = E["axle_z"], E["axle_y"], E["ring_radius"], E["ring_width"]
    inner = radius - 2.6
    p.torus_x(x, z, y, radius, inner, width, ring_colors)
    p.torus_x(x, z, y, inner + 0.02, inner - 0.5, width + 0.5, lambda i, face: "steel_dark", seg=36, chamfer=0.1)
    for k in range(12):                                        # rim modules with running lights
        a = math.tau * k / 12 + math.tau / 24
        rz, ry = math.sin(a), math.cos(a)                      # Blender y = -layout z
        mid = radius - 1.2
        p.cbox(x, z - rz * mid, y + ry * mid, width + 0.9, 4.6, 3.2, "graphite", (-math.degrees(a), 0, 0), 0.12)
        p.cbox(x, z - rz * (radius + 0.42), y + ry * (radius + 0.42), width + 0.3, 2.2, 0.16, "cyan" if k % 2 else "warm", (-math.degrees(a), 0, 0))
    hub_r = 3.5
    for k in range(8):                                         # radial spokes hub -> rim
        a = math.tau * k / 8 + math.tau / 16
        rz, ry = math.sin(a), math.cos(a)
        start = (x, z - rz * hub_r, y + ry * hub_r)
        end = (x, z - rz * (inner - 0.2), y + ry * (inner - 0.2))
        p.beam(start, end, 1.0, "steel")
        for s in (-1, 1):
            p.beam((x + s * 0.9, z - rz * (hub_r + 0.4), y + ry * (hub_r + 0.4)), (x + s * 0.45, z - rz * (inner - 0.6), y + ry * (inner - 0.6)), 0.34, "steel_dark")
        p.cbox(x, z - rz * (inner - 1.0), y + ry * (inner - 1.0), width + 0.1, 2.6, 1.6, "hull_shade", (-math.degrees(a), 0, 0), 0.1)
        p.cbox(x, z - rz * (hub_r + 1.3), y + ry * (hub_r + 1.3), 1.6, 1.7, 2.2, "graphite", (-math.degrees(a), 0, 0), 0.1)
    out = 1.0 if x > 0 else -1.0
    for a_deg in (30, 150, 210, 330):                          # diagonal braces from the arm to the rim
        a = math.radians(a_deg)
        rz, ry = math.sin(a), math.cos(a)
        foot = (x + out * 12.0, z - rz * 1.7, y + ry * 1.7)
        head = (x + out * (width * 0.5 + 0.3), z - rz * (inner + 0.6), y + ry * (inner + 0.6))
        p.beam(foot, head, 0.8, "steel")
        p.cbox(head[0], head[1], head[2], 1.2, 1.5, 1.5, "graphite", (-a_deg, 0, 0), 0.1)
        mid = tuple((foot[i] + head[i]) * 0.5 for i in range(3))
        p.beam(mid, (x + out * (width * 0.5 + 0.2), z - rz * (inner * 0.5), y + ry * (inner * 0.5)), 0.5, "steel_dark")
    for a_deg in (60, 120, 240, 300):                          # short inboard braces hub collar -> spokes
        a = math.radians(a_deg)
        rz, ry = math.sin(a), math.cos(a)
        p.beam((x - out * 2.8, z - rz * 3.6, y + ry * 3.6), (x - out * 0.6, z - rz * 12.0, y + ry * 12.0), 0.5, "steel_dark")
    return p


def build_axle() -> Part:
    p = Part("Achse", "04_Ringe_Achse")
    z, y, r = E["axle_z"], E["axle_y"], E["axle_radius"]
    x0, x1 = E["axle_x"]
    p.pipe((x0 + 6.0, z, y), (x1 - 6.0, z, y), r, "steel", 18)
    for rx in E["ring_x"]:
        p.pipe((rx - 3.2, z, y), (rx + 3.2, z, y), 3.5, "graphite", 20)
        for s in (-1, 1):
            p.pipe((rx + s * 2.2, z, y), (rx + s * 3.0, z, y), 3.85, "hull", 20)
            p.pipe((rx + s * 3.2, z, y), (rx + s * 4.6, z, y), 2.5, "hull_shade", 16, r2=1.9)
        p.pipe((rx - 0.5, z, y), (rx + 0.5, z, y), 3.62, "ochre", 20)
    for s in (-1, 1):
        x = 56.0
        while x < 92.0:                                        # collars and mechanical segments on the arms
            p.pipe((s * x, z, y), (s * (x + 1.0), z, y), 2.15, "graphite", 14)
            p.pipe((s * (x + 1.0), z, y), (s * (x + 1.5), z, y), 1.95, "hull", 14)
            p.pipe((s * (x + 3.5), z, y), (s * (x + 4.3), z, y), 1.78, "ochre" if int(x) % 16 == 0 else "hull_shade", 14)
            p.box(s * (x + 5.6), z, y + r - 0.2, 1.6, 1.3, 0.7, "graphite", 0.08)
            x += 8.0
        p.pipe((s * 47.0, z, y + 2.1), (s * 92.0, z, y + 2.1), 0.42, "hull_shade", 8)      # service line on top
        p.pipe((s * 54.0, z + 1.9, y - 0.6), (s * 92.0, z + 1.9, y - 0.6), 0.3, "teal", 8)
        for x in range(58, 92, 8):
            p.beam((s * x, z, y + r), (s * x, z, y + 2.1), 0.3, "steel_dark")
    return p


# ===================================================================== solar
def build_solar() -> Part:
    p = Part("Solarfluegel_Links", "05_Solarfluegel_Links")
    z_axis, y = E["axle_z"], E["axle_y"]
    for wing in E["solar_wings"]:
        cx, cz = wing["center"]
        sx, sz = wing["size"]
        side = 1.0 if cz > z_axis else -1.0
        near = cz - side * sz * 0.5
        p.box(cx, z_axis + side * 2.4, y - 1.5, 5.0, 2.6, 3.0, "graphite", 0.2)          # hinge root on the shaft
        p.pipe((cx - 2.0, z_axis + side * 3.9, y), (cx + 2.0, z_axis + side * 3.9, y), 0.9, "hull", 12)
        for s in (-1, 1):                                       # truss boom shaft -> wing
            p.beam((cx + s * 1.3, z_axis + side * 3.9, y), (cx + s * 1.3, near, y), 0.55, "steel")
        steps = int(abs(near - (z_axis + side * 3.9)) // 2.2)
        for k in range(steps + 1):
            zz = z_axis + side * (3.9 + k * 2.2)
            p.beam((cx - 1.3, zz, y), (cx + 1.3, zz, y), 0.3, "steel_dark")
            if k < steps:
                p.beam((cx - 1.3 if k % 2 else cx + 1.3, zz, y), (cx + 1.3 if k % 2 else cx - 1.3, zz + side * 2.2, y), 0.26, "steel_dark")
        for s in (-1, 1):                                       # stays to the wing corners
            p.beam((cx + s * 1.3, z_axis + side * 5.0, y), (cx + s * (sx * 0.5 - 0.6), near + side * 1.0, y), 0.36, "steel")
        p.box(cx, cz, y - 0.2, sx, sz, 0.34, "graphite", 0.08)
        p.box(cx, cz, y + 0.14, 0.8, sz, 0.3, "hull", 0.05)     # centre spar
        cols, rows = 4, 5
        cw, rw = (sx - 1.2) / cols, (sz - 0.6) / rows
        for i in range(cols):
            for j in range(rows):
                px = cx - sx * 0.5 + 0.2 + cw * (i + 0.5) + (0.4 if i >= cols // 2 else 0.0) + (0.2 if i >= cols // 2 else 0.0)
                pz = cz - sz * 0.5 + 0.3 + rw * (j + 0.5)
                p.box(px, pz, y + 0.14, cw - 0.22, rw - 0.22, 0.1, "solar", 0.0)
                for k in (-1, 0, 1):
                    p.box(px + k * (cw - 0.22) / 3.0, pz, y + 0.24, 0.04, rw - 0.26, 0.012, "solar_frame", 0.0)
                p.box(px, pz, y + 0.24, cw - 0.26, 0.04, 0.012, "solar_frame", 0.0)
        for s in (-1, 1):
            p.box(cx + s * (sx * 0.5 - 0.1), cz, y - 0.1, 0.2, sz + 0.2, 0.5, "solar_frame", 0.0)
            p.box(cx + s * (sx * 0.5 - 0.4), cz + side * (sz * 0.5 - 0.4), y + 0.3, 0.3, 0.3, 0.2, "warm", 0.0)
    return p


# ===================================================================== tanks
def build_tanks() -> Part:
    p = Part("Treibstofftanks_Rechts", "06_Treibstofftanks_Rechts")
    z_axis, y = E["axle_z"], E["axle_y"]
    for tank in E["fuel_tanks"]:
        cx, cz = tank["center"]
        length, r = tank["length"], tank["radius"]
        side = 1.0 if cz > z_axis else -1.0
        body = length - 4.2
        p.pipe((cx - body / 2, cz, y), (cx + body / 2, cz, y), r, "tank", 20)
        for s in (-1, 1):                                       # domed ends from two tapers
            p.pipe((cx + s * body / 2, cz, y), (cx + s * (body / 2 + 1.5), cz, y), r, "tank", 20, r2=r * 0.66)
            p.pipe((cx + s * (body / 2 + 1.5), cz, y), (cx + s * (body / 2 + 2.1), cz, y), r * 0.66, "hull_shade", 20, r2=r * 0.28)
            p.pipe((cx + s * (body / 2 - 0.5), cz, y), (cx + s * (body / 2 + 0.1), cz, y), r + 0.14, "graphite", 20)
        p.pipe((cx - 0.3, cz, y), (cx + 0.3, cz, y), r + 0.14, "graphite", 20)
        p.pipe((cx - body / 2 + 1.0, cz, y), (cx - body / 2 + 2.3, cz, y), r + 0.06, "ochre", 20)
        for dx in (-body / 2 + 0.2, body / 2 - 0.2):            # cradle frames to the shaft
            inner_z = cz - side * (r - 0.3)
            p.box(cx + dx, (inner_z + z_axis + side * 1.4) * 0.5, y - 1.3, 0.9, abs(inner_z - z_axis - side * 1.4) + 0.4, 2.6, "graphite", 0.1)
            p.beam((cx + dx, z_axis + side * 1.2, y + 1.4), (cx + dx, cz - side * 1.2, y + r - 0.2), 0.45, "steel")
            p.beam((cx + dx, z_axis + side * 1.2, y - 1.4), (cx + dx, cz - side * 1.2, y - r + 0.2), 0.45, "steel")
            p.box(cx + dx, cz, y - r - 0.25, 1.1, r * 1.5, 0.5, "steel_dark", 0.08)
        # feed pipe: tank crown -> elbow -> shaft manifold
        p.pipe((cx + 1.2, cz, y + r), (cx + 1.2, cz, y + r + 0.9), 0.3, "teal", 8)
        p.pipe((cx + 1.2, cz, y + r + 0.9), (cx + 1.2, z_axis + side * 0.6, y + r + 0.9), 0.3, "teal", 8)
        p.pipe((cx + 1.2, z_axis + side * 0.6, y + r + 0.9), (cx + 1.2, z_axis + side * 0.6, y + 1.2), 0.3, "teal", 8)
        p.sphere(cx + 1.2, cz, y + r + 0.9, 0.36, "teal", 8)
        p.box(cx - 1.6, cz, y + r - 0.1, 0.9, 0.9, 0.5, "graphite", 0.06)                   # valve block
        p.box(cx - 1.6, cz, y + r + 0.4, 0.3, 0.3, 0.14, "warm", 0.0)
    xs = sorted({t["center"][0] for t in E["fuel_tanks"]})
    for x in xs:                                                # manifold on the shaft
        p.box(x + 1.2, z_axis, y + 0.9, 2.4, 3.6, 1.3, "graphite", 0.12)
    for dz in (-1, 1):
        zc = z_axis + dz * abs(E["fuel_tanks"][0]["center"][1] - z_axis)
        p.pipe((xs[0] + 6.6, zc, y), (xs[1] - 6.6, zc, y), 0.5, "teal", 10)   # cross-feed between the pair
    return p


# ===================================================================== docks
def build_docks() -> Part:
    p = Part("Grossschiff_Docks", "07_Grossschiff_Docks")
    y = E["axle_y"]
    for port in E["outer_ports"]:
        cx, cz = port["center"]
        out = float(port["facing"][0])
        p.box(cx, cz, y - 2.9, 8.4, 7.0, 5.8, "hull", 0.5)                       # pressurised dock head
        p.box(cx, cz, y + 2.9, 6.0, 5.0, 0.5, "hull_shade", 0.12)
        p.box(cx - out * 1.0, cz, y + 3.4, 2.4, 2.0, 0.7, "graphite", 0.1)
        p.box(cx, cz + 3.56, y - 0.9, 5.6, 0.14, 1.5, "graphite", 0.0)           # label plate, front
        p.box(cx, cz + 3.6, y - 1.9, 6.4, 0.1, 0.3, "ochre", 0.0)
        for s in (-1, 1):
            p.box(cx, cz + s * 3.56, y + 1.3, 5.8, 0.12, 0.5, "glass", 0.0)      # gallery windows
        # gangway from the last arm segment into the head
        p.box(cx - out * 7.0, cz, y - 1.4, 6.0, 3.0, 2.8, "hull_shade", 0.25)
        p.box(cx - out * 7.0, cz + 1.53, y - 0.2, 4.8, 0.08, 0.6, "glass", 0.0)
        for k in range(3):
            p.box(cx - out * (4.8 + k * 2.2), cz, y - 1.6, 0.4, 3.3, 3.2, "graphite", 0.06)
        # collar facing outwards along the axle
        p.pipe((cx + out * 4.0, cz, y), (cx + out * 5.3, cz, y), 3.9, "hull", 24)
        p.pipe((cx + out * 5.3, cz, y), (cx + out * 5.9, cz, y), 3.9, "graphite", 24, r2=3.3)
        p.pipe((cx + out * 5.6, cz, y), (cx + out * 6.0, cz, y), 2.5, "steel_dark", 20)
        p.pipe((cx + out * 5.95, cz, y), (cx + out * 6.08, cz, y), 1.5, "deck_inset", 16)   # sealed hatch
        for k in range(12):
            a = math.tau * k / 12
            p.cbox(cx + out * 5.95, cz - math.sin(a) * 3.05, y + math.cos(a) * 3.05, 0.14, 0.9, 0.3, "cyan" if k % 3 else "warm", (-math.degrees(a), 0, 0))
        for a_deg in (45, 135, 225, 315):                                        # clamps
            a = math.radians(a_deg)
            sy, cyv = math.sin(a), math.cos(a)
            base = (cx + out * 4.6, cz - sy * 3.7, y + cyv * 3.7)
            tip = (cx + out * 7.6, cz - sy * 4.5, y + cyv * 4.5)
            p.beam(base, tip, 1.0, "graphite")
            p.cbox(tip[0], tip[1], tip[2], 1.3, 1.4, 1.2, "ochre", (-a_deg, 0, 0), 0.1)
            p.beam(tip, (cx + out * 7.9, cz - sy * 3.5, y + cyv * 3.5), 0.6, "steel")
        for s in (-1, 1):                                                        # approach lights
            p.box(cx + out * 4.3, cz + s * 3.3, y + 2.5, 0.3, 0.3, 0.3, "warm", 0.0)
    return p


# ================================================== technical modules / rear
def build_module(p: Part, spec: dict, dim: bool) -> None:
    d = "_dim" if dim else ""
    (cx, cz), (sx, sz) = centre(spec["rect"]), size(spec["rect"])
    h, kind = float(spec["height"]), spec["kind"]
    base = -3.0 if dim else DECK_TOP
    p.box(cx, cz, base, sx, sz, h - base, "hull" + d, 0.3)
    p.box(cx, cz, h, sx - 1.4, sz - 1.4, 0.3, "hull_shade" + d, 0.1)
    p.box(cx, cz + sz * 0.5 + 0.02, max(base, DECK_TOP) + 0.5, sx - 1.2, 0.08, 0.5, "teal" + d, 0.0)
    for s in (-1, 1):
        p.box(cx + s * (sx * 0.5 - 0.6), cz + sz * 0.5 + 0.03, h - 0.7, 0.5, 0.06, 0.2, "warm", 0.0)
    if kind in ("plant", "sign"):
        for k in range(3):
            p.box(cx - sx * 0.28 + k * sx * 0.28, cz - sz * 0.12, h + 0.3, sx * 0.2, sz * 0.5, 0.7, "graphite" + d, 0.08)
            p.box(cx - sx * 0.28 + k * sx * 0.28, cz - sz * 0.12, h + 1.0, sx * 0.16, sz * 0.44, 0.08, "steel" + d, 0.0)
        p.pipe((cx - sx * 0.4, cz + sz * 0.3, h + 0.6), (cx + sx * 0.4, cz + sz * 0.3, h + 0.6), 0.3, "teal" + d, 8)
    if kind == "tank":
        for s in (-1, 1):
            if sx >= sz:
                p.pipe((cx - sx * 0.36, cz + s * sz * 0.2, h + 1.3), (cx + sx * 0.36, cz + s * sz * 0.2, h + 1.3), min(1.5, sz * 0.17), "tank" + d, 14)
            else:
                p.cyl(cx, cz + s * sz * 0.24, h + 0.3, 2.4, min(2.0, sx * 0.3), "tank" + d, 16, bevel=0.3)
                p.cyl(cx, cz + s * sz * 0.24, h + 1.4, 0.3, min(2.0, sx * 0.3) + 0.08, "graphite" + d, 16)
        p.box(cx, cz, h + 0.3, sx * 0.3, sz * 0.12, 0.8, "graphite" + d, 0.06)
    if kind == "vent":
        r = min(sx, sz) * 0.3
        p.cyl(cx, cz, h + 0.3, 0.7, r, "graphite" + d, 18, bevel=0.1)
        p.cyl(cx, cz, h + 1.0, 0.1, r * 0.82, "steel" + d, 18)
        for k in range(6):
            p.box(cx, cz, h + 1.1, r * 1.56, 0.12, 0.05, "hull_shade" + d, 0.0, yaw=k * 30)
        p.cyl(cx, cz, h + 1.1, 0.14, r * 0.2, "ochre" + d, 10)
    if kind == "reactor":
        n = max(3, int(max(sx, sz) / 1.6))
        for k in range(n):
            t = (k + 0.5) / n - 0.5
            if sx >= sz:
                p.box(cx + t * (sx - 1.6), cz, h + 0.3, 0.3, sz - 2.2, 1.0, "steel" + d, 0.0)
            else:
                p.box(cx, cz + t * (sz - 1.6), h + 0.3, sx - 2.2, 0.3, 1.0, "steel" + d, 0.0)
        p.box(cx, cz, h + 0.3, min(sx, sz) * 0.36, min(sx, sz) * 0.36, 1.5, "graphite" + d, 0.1)
        p.box(cx, cz, h + 1.8, 0.5, 0.5, 0.16, "cyan" if not dim else "warm", 0.0)
    if kind == "sign":                                          # the station name board, read from the front
        p.box(cx, cz + sz * 0.5 + 0.2, h - 2.4, sx * 0.8, 0.4, 2.4, "graphite" + d, 0.08)
        p.box(cx + sx * 0.3, cz + sz * 0.5 + 0.42, h - 1.9, 1.6, 0.06, 1.4, "ochre", 0.0)
        for s in (-1, 1):
            p.cyl(cx + s * sx * 0.42, cz - sz * 0.3, h + 0.3, 5.0, 0.16, "steel" + d, 6)
            p.box(cx + s * sx * 0.42, cz - sz * 0.3, h + 5.3, 0.3, 0.3, 0.3, "warm", 0.0)


def build_technical() -> Part:
    p = Part("Technik_Seiten", "08_Technik_Seiten")
    for spec in L["technical_modules"]:
        build_module(p, spec, False)
    return p


def build_rear() -> Part:
    p = Part("Heck_Dekoration", "09_Heck_Dekoration_nicht_begehbar")
    edge = L["map_boundary_local_z"]
    p.box(0, edge - 10.6, -4.6, 96.0, 20.0, 4.2, "hull_dim", 0.5)             # rear hull band
    p.box(0, edge - 22.0, -3.8, 70.0, 6.0, 3.0, "hull_shade_dim", 0.4)
    for spec in L["rear_decoration"]:
        build_module(p, spec, True)
    for x in (-40, -27, -14, 14, 27, 40):                                    # truss ties and pipe runs
        p.beam((x, edge - 1.0, 1.4), (x, edge - 9.0, 3.2), 0.5, "steel_dim")
    p.pipe((-44, edge - 4.0, 4.6), (44, edge - 4.0, 4.6), 0.5, "teal_dim", 8)
    p.pipe((-44, edge - 15.0, 4.0), (44, edge - 15.0, 4.0), 0.7, "steel_dim", 8)
    for x in (-30, 30):
        p.pipe((x, edge - 27.0, 0.6), (x + 9.0, edge - 27.0, 0.6), 3.0, "tank_dim", 16)
        p.pipe((x + 2.0, edge - 27.0, 0.6), (x + 2.6, edge - 27.0, 0.6), 3.1, "graphite_dim", 16)
    return p


# ============================================================== draft helpers
def build_helpers() -> Part:
    """Draft aids only: not exported, no gameplay facts."""
    p = Part("Hilfen_Entwurf", "10_Hilfen_Entwurf_nicht_exportiert")
    edge = L["map_boundary_local_z"]
    p.box(0, edge, 0.0, 300.0, 0.25, 0.05, "ochre", 0.0)                       # map boundary
    for port in E["outer_ports"]:
        r = port["approach_rect"]
        (cx, cz), (sx, sz) = centre(r), size(r)
        p.box(cx, cz, E["axle_y"] - 4.5, sx, sz, 9.0, "glass", 0.0)            # free approach volume
    sq3 = math.sqrt(3.0)
    for fx, fz, cells in ((-52.0, 62.0, 1), (-44.0, 66.0, 1), (0.0, 70.0, 2)):  # light / medium fighter, Cutlass
        for k in range(cells):
            pts = [(fx + k + math.cos(math.radians(30 + 60 * i)) / sq3, fz + math.sin(math.radians(30 + 60 * i)) / sq3) for i in range(6)]
            p.prism(pts, 0.0, 0.06, "cyan")
        p.box(fx + (cells - 1) * 0.5, fz, 0.06, 0.8 * cells, 0.6, 0.3, "hull", 0.05)
    return p


def measure(obj) -> dict:
    """Bounding box of an object in layout terms: centre and extent on (z, up)."""
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return {"x": [round(min(xs), 4), round(max(xs), 4)],
            "centre_layout_z": round(-(min(ys) + max(ys)) * 0.5, 4), "centre_up": round((min(zs) + max(zs)) * 0.5, 4),
            "extent_layout_z": round(max(ys) - min(ys), 4), "extent_up": round(max(zs) - min(zs), 4)}


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    OUT.mkdir(parents=True, exist_ok=True)
    parts = [build_structure(), build_roofs(), build_pads(), build_ring(0, E["ring_x"][0]), build_ring(1, E["ring_x"][1]),
             build_axle(), build_solar(), build_tanks(), build_docks(), build_technical(), build_rear(), build_helpers()]
    report, objects = {}, {}
    for part in parts:
        obj, tris = part.finish()
        objects[obj.name] = obj
        report[obj.name] = {"collection": part.collection, "triangles": tris, "materials": len(obj.data.materials)}
    # Ring rims only (without braces): centre must equal the axle line.
    axis = {"layout_z": E["axle_z"], "up": E["axle_y"]}
    rims = {}
    for name in ("Ring_Links", "Ring_Rechts"):
        obj = objects[name]
        radius = E["ring_radius"]
        ys = [v.co.y for v in obj.data.vertices]
        zs = [v.co.z for v in obj.data.vertices]
        rims[name] = {"centre_layout_z": round(-(min(ys) + max(ys)) * 0.5, 4), "centre_up": round((min(zs) + max(zs)) * 0.5, 4),
                      "outer_diameter_z": round(max(ys) - min(ys), 4), "outer_diameter_up": round(max(zs) - min(zs), 4),
                      "plane_x": round(sum(v.co.x for v in obj.data.vertices if abs(math.hypot(v.co.y + E["axle_z"], v.co.z - E["axle_y"]) - radius) < 0.01)
                                       / max(1, sum(1 for v in obj.data.vertices if abs(math.hypot(v.co.y + E["axle_z"], v.co.z - E["axle_y"]) - radius) < 0.01)), 4)}
    shaft = objects["Achse"]
    # shaft skin only: the two end loops of the one straight shaft cylinder
    line = [v for v in shaft.data.vertices if abs(abs(v.co.x) - (E["axle_x"][1] - 6.0)) < 1e-3
            and abs(math.hypot(v.co.y + E["axle_z"], v.co.z - E["axle_y"]) - E["axle_radius"]) < 0.005]
    shaft_centre = {"layout_z": round(-sum(v.co.y for v in line) / len(line), 4),
                    "up": round(sum(v.co.z for v in line) / len(line), 4)}
    hidden = bpy.data.collections["10_Hilfen_Entwurf_nicht_exportiert"]
    blend = ART / "blender" / "polisar_r09.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend), compress=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.name not in hidden.objects:
            obj.select_set(True)
    glb = OUT / "polisar_station.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
    exported = sum(v["triangles"] for k, v in report.items() if k != "Hilfen_Entwurf")
    manifest = {
        "schema": "polisar_model_manifest.v1", "revision": L["revision"],
        "units": "1 Blender unit = 1 map plane unit (hex centre step); no metres claimed",
        "axes": "layout (x, z, up) -> Blender (x, -z, up); glTF Y-up export -> Godot (x, up, z); pivot = layout origin on the deck plane; scale 1",
        "objects": report, "exported_triangles": exported, "materials": len(bpy.data.materials),
        "axis_check": {"axle_authored": axis, "axle_measured": shaft_centre, "rings_measured": rims,
                       "ring_centres_on_axle": all(abs(r["centre_layout_z"] - shaft_centre["layout_z"]) < 1e-3 and abs(r["centre_up"] - shaft_centre["up"]) < 1e-3 for r in rims.values())},
        "sha256": {"layout.json": hashlib.sha256((ART / "layout.json").read_bytes()).hexdigest(),
                   "polisar_station.glb": hashlib.sha256(glb.read_bytes()).hexdigest(),
                   "polisar_r09.blend": hashlib.sha256(blend.read_bytes()).hexdigest()},
    }
    (ART / "model_manifest.json").write_text(json.dumps(manifest, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"exported_triangles": exported, "axis_check": manifest["axis_check"], "objects": {k: v["triangles"] for k, v in report.items()}}, indent=1))


if __name__ == "__main__":
    main()
