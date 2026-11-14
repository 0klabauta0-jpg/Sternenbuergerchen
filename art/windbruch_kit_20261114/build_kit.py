"""Windbruch kit (Grafikpass R3, 14.11.2026): original low-poly outpost pieces.

A settlement patched together from ship parts on top of an old mining depot.
Style rules (claude/Stilrecherche-Star-Citizen-Aussenposten.md): chamfered
boxes, bodies on feet, cream hull + petrol frames + one orange house colour,
readable function, oversized details. All shapes are our own design.

Units: 1 Blender unit = 1 map cell. The game's person models are about 0.6 tall.
People, ships and the depot buildings are NOT part of this kit: the map uses
the project's existing models for those. Front faces -Y
(glTF +Z, towards the default iso camera). Pivot: footprint centre on the ground.

Run:  python3 art/windbruch_kit_20261114/build_kit.py   (needs the bpy module)
Writes GLB files to Assets/curated/windbruch_kit_20261114/ and kit_manifest.json.
"""
import json
import math
import os
from pathlib import Path

import bpy  # must come first: it makes bmesh and mathutils importable
import bmesh
from mathutils import Euler, Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Assets" / "curated" / "windbruch_kit_20261114"

PALETTE = {
    "cream": "c6b78f", "cream_dark": "a3966f", "cream_light": "d8cba6",
    "petrol": "37707a", "petrol_dark": "27505a", "petrol_light": "5a949c",
    "steel": "73807e", "steel_dark": "4a5557", "dark": "2c3436",
    "rust": "a4502c", "rust_light": "c46f38", "orange": "dd8a27", "yellow": "dcb23c",
    "glass": "86c0cc", "concrete": "a09a8b", "concrete_dark": "7d786c",
    "tarp_red": "b4513a", "tarp_sand": "cfae72", "lamp": "ffe2a0", "red": "c8452f",
    "solar": "23405e",
}
EMISSIVE = {"lamp": 2.2, "glass": 0.25}


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


class Asset:
    def __init__(self, name: str):
        self.name = name
        self.bm = bmesh.new()
        self.materials: list[str] = []
        self.scratch = bpy.data.meshes.new("scratch")

    def slot(self, color: str) -> int:
        if color not in self.materials:
            self.materials.append(color)
        return self.materials.index(color)

    def merge(self, part: bmesh.types.BMesh, color: str, loc, rot=(0.0, 0.0, 0.0)) -> None:
        matrix = Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot)).to_matrix().to_4x4()
        bmesh.ops.transform(part, matrix=matrix, verts=part.verts)
        index = self.slot(color)
        for face in part.faces:
            face.material_index = index
        part.to_mesh(self.scratch)
        part.free()
        self.bm.from_mesh(self.scratch)

    # ------------------------------------------------------------ primitives
    def box(self, size, loc, color, bevel=0.03, rot=(0, 0, 0), seg=1, taper=1.0):
        part = bmesh.new()
        bmesh.ops.create_cube(part, size=1.0)
        for v in part.verts:
            k = taper if v.co.z > 0 else 1.0
            v.co = Vector((v.co.x * size[0] * k, v.co.y * size[1] * k, v.co.z * size[2]))
        limit = min(size) * 0.45
        if bevel > 0.0:
            bmesh.ops.bevel(part, geom=list(part.edges), offset=min(bevel, limit), segments=seg, affect="EDGES", profile=0.5)
        self.merge(part, color, loc, rot)

    def cyl(self, r1, depth, loc, color, r2=None, seg=14, rot=(0, 0, 0), bevel=0.0):
        part = bmesh.new()
        bmesh.ops.create_cone(part, cap_ends=True, cap_tris=False, segments=seg, radius1=r1,
                              radius2=r1 if r2 is None else r2, depth=depth)
        if bevel > 0.0:
            rim = [e for e in part.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-6]
            bmesh.ops.bevel(part, geom=rim, offset=bevel, segments=1, affect="EDGES", profile=0.5)
        self.merge(part, color, loc, rot)

    def pipe(self, a, b, radius, color, seg=8):
        a, b = Vector(a), Vector(b)
        axis = b - a
        part = bmesh.new()
        bmesh.ops.create_cone(part, cap_ends=True, cap_tris=False, segments=seg, radius1=radius, radius2=radius, depth=axis.length)
        quat = Vector((0, 0, 1)).rotation_difference(axis.normalized())
        bmesh.ops.transform(part, matrix=quat.to_matrix().to_4x4(), verts=part.verts)
        self.merge(part, color, (a + b) * 0.5)

    def tarp(self, size, loc, color, sag=0.08, rot=(0, 0, 0)):
        part = bmesh.new()
        bmesh.ops.create_grid(part, x_segments=4, y_segments=3, size=0.5)
        for v in part.verts:
            u, w = v.co.x + 0.5, v.co.y + 0.5
            v.co = Vector((v.co.x * size[0], v.co.y * size[1], -sag * math.sin(math.pi * u) * math.sin(math.pi * w)))
        geom = bmesh.ops.extrude_face_region(part, geom=list(part.faces))
        for v in [g for g in geom["geom"] if isinstance(g, bmesh.types.BMVert)]:
            v.co.z -= 0.018
        bmesh.ops.recalc_face_normals(part, faces=list(part.faces))
        self.merge(part, color, loc, rot)

    # ------------------------------------------------------- shared details
    def feet(self, w, d, h=0.16, size=0.2, color="steel_dark"):
        for sx in (-1, 1):
            for sy in (-1, 1):
                self.box((size, size, h), (sx * (w * 0.5 - size * 0.7), sy * (d * 0.5 - size * 0.7), h * 0.5), color, 0.03)
                self.box((size * 1.5, size * 1.5, 0.04), (sx * (w * 0.5 - size * 0.7), sy * (d * 0.5 - size * 0.7), 0.02), "concrete_dark", 0.012)

    def door(self, x, y, z, w=0.36, h=0.72, color="petrol", frame="petrol_dark"):
        self.box((w + 0.12, 0.07, h + 0.09), (x, y, z + h * 0.5 + 0.02), frame, 0.02)
        self.box((w, 0.05, h), (x, y - 0.035, z + h * 0.5), color, 0.015)
        self.box((w * 0.5, 0.03, h * 0.22), (x, y - 0.065, z + h * 0.72), "glass", 0.008)
        self.box((0.07, 0.035, 0.05), (x + w * 0.5 + 0.11, y - 0.02, z + h * 0.62), "lamp", 0.008)

    def steps(self, x, y, z, w=0.5, count=2, rise=0.075, run=0.13):
        for i in range(count):
            self.box((w, run, rise), (x, y - run * (i + 0.5), z - rise * (i + 0.5)), "steel", 0.012)

    def porthole(self, x, y, z, r=0.13, axis="y"):
        rot = (90, 0, 0) if axis == "y" else (0, 90, 0)
        self.cyl(r + 0.035, 0.06, (x, y, z), "petrol_dark", seg=12, rot=rot)
        offset = (0, -0.02, 0) if axis == "y" else (0.02 * (1 if x > 0 else -1), 0, 0)
        self.cyl(r, 0.06, (x + offset[0], y + offset[1], z), "glass", seg=12, rot=rot)

    def ladder(self, x, y, z0, z1, w=0.22):
        for sx in (-1, 1):
            self.box((0.03, 0.03, z1 - z0), (x + sx * w * 0.5, y, (z0 + z1) * 0.5), "steel_dark", 0.0)
        steps = max(2, int((z1 - z0) / 0.16))
        for i in range(steps):
            self.box((w, 0.025, 0.025), (x, y, z0 + (i + 0.5) * (z1 - z0) / steps), "steel_dark", 0.0)

    def lamp_head(self, x, y, z):
        self.box((0.16, 0.12, 0.05), (x, y, z), "steel_dark", 0.012)
        self.box((0.12, 0.09, 0.025), (x, y, z - 0.035), "lamp", 0.006)

    def crate(self, x, y, z, s=0.36, color="cream_dark", rot=0.0):
        self.box((s, s, s * 0.85), (x, y, z + s * 0.425), color, 0.025, (0, 0, rot))
        self.box((s * 1.03, s * 0.16, s * 0.88), (x, y, z + s * 0.43), "steel_dark", 0.01, (0, 0, rot))

    def barrel(self, x, y, z, r=0.13, h=0.38, color="orange"):
        self.cyl(r, h, (x, y, z + h * 0.5), color, seg=10, bevel=0.02)
        self.cyl(r * 1.06, 0.035, (x, y, z + h * 0.72), "steel_dark", seg=10)
        self.cyl(r * 1.06, 0.035, (x, y, z + h * 0.28), "steel_dark", seg=10)

    def container(self, x, y, z, color="orange", rot=0.0, length=2.0, w=0.85, h=0.85):
        self.box((length, w, h), (x, y, z + h * 0.5), color, 0.035, (0, 0, rot))
        c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        for i in range(-3, 4):                      # corrugation ribs on both long sides
            for side in (-1, 1):
                lx, ly = i * length * 0.125, side * (w * 0.5 + 0.004)
                self.box((0.05, 0.03, h * 0.78), (x + lx * c - ly * s, y + lx * s + ly * c, z + h * 0.5), "steel_dark" if i == 0 else color, 0.008, (0, 0, rot))
        for end in (-1, 1):                         # corner posts and door bars
            lx = end * (length * 0.5 + 0.004)
            self.box((0.035, w * 0.92, h * 0.92), (x + lx * c, y + lx * s, z + h * 0.5), "steel_dark", 0.01, (0, 0, rot))
            self.box((0.05, w * 0.42, h * 0.8), (x + lx * c * 1.008, y + lx * s * 1.008, z + h * 0.5), color, 0.01, (0, 0, rot))

    # ---------------------------------------------------------------- export
    def export(self) -> dict:
        mesh = bpy.data.meshes.new(self.name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=0.0005)
        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        self.bm.to_mesh(mesh)
        tris = sum(len(f.verts) - 2 for f in self.bm.faces)
        lo = Vector((min(v.co.x for v in self.bm.verts), min(v.co.y for v in self.bm.verts), min(v.co.z for v in self.bm.verts)))
        hi = Vector((max(v.co.x for v in self.bm.verts), max(v.co.y for v in self.bm.verts), max(v.co.z for v in self.bm.verts)))
        self.bm.free()
        for color in self.materials:
            mat = bpy.data.materials.get("wb_" + color)
            if mat is None:
                mat = bpy.data.materials.new("wb_" + color)
                mat.use_nodes = True
                bsdf = mat.node_tree.nodes.get("Principled BSDF")
                rgb = [srgb_to_linear(int(PALETTE[color][i:i + 2], 16) / 255.0) for i in (0, 2, 4)]
                bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
                bsdf.inputs["Roughness"].default_value = 0.55 if color in ("glass", "solar") else 0.9
                bsdf.inputs["Metallic"].default_value = 0.0
                if color in EMISSIVE:
                    bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
                    bsdf.inputs["Emission Strength"].default_value = EMISSIVE[color]
            mesh.materials.append(mat)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        path = OUT / (self.name + ".glb")
        bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
        bpy.data.objects.remove(obj)
        return {"file": path.name, "triangles": tris,
                "size_x": round(hi.x - lo.x, 3), "size_z_depth": round(hi.y - lo.y, 3), "height": round(hi.z, 3)}


# ==================================================================== assets
def hull_hab_long() -> Asset:
    """Fuselage section turned into living quarters. Footprint 3.6 x 1.9."""
    a = Asset("wb_hull_hab_long")
    L, W, H, z0 = 3.3, 1.5, 1.15, 0.16
    # Solid plinth down to the ground: nothing to see through, nothing floats.
    a.box((L - 0.25, W - 0.3, z0 + 0.06), (0, 0, (z0 + 0.06) * 0.5), "steel_dark", 0.03)
    a.box((L + 0.1, W + 0.1, 0.06), (0, 0, 0.03), "concrete_dark", 0.02)
    a.box((L, W, H), (0, 0, z0 + H * 0.5), "cream", 0.34, seg=3)                                # rounded hull
    a.box((L * 0.985, W * 1.012, 0.2), (0, 0, z0 + 0.42), "orange", 0.03)                       # house colour band
    a.box((L * 0.4, W * 0.72, 0.07), (-0.55, 0, z0 + H + 0.005), "petrol", 0.025)               # roof spine
    a.box((0.07, W * 1.01, H * 0.96), (L * 0.5 - 0.5, 0, z0 + H * 0.5), "cream_dark", 0.02)     # hull ring seams
    a.box((0.07, W * 1.01, H * 0.96), (-L * 0.5 + 0.9, 0, z0 + H * 0.5), "cream_dark", 0.02)
    # cut end, closed with salvaged plates
    a.box((0.08, W * 0.86, H * 0.84), (L * 0.5 + 0.005, 0, z0 + H * 0.5), "steel_dark", 0.03)
    a.box((0.06, W * 0.42, H * 0.5), (L * 0.5 + 0.045, -0.26, z0 + H * 0.58), "rust_light", 0.02)
    a.box((0.06, W * 0.36, H * 0.36), (L * 0.5 + 0.045, 0.3, z0 + H * 0.36), "petrol_light", 0.02)
    a.box((0.06, W * 0.3, H * 0.26), (L * 0.5 + 0.05, 0.22, z0 + H * 0.74), "cream_light", 0.02)
    # airlock porch on the front, with steps
    a.box((0.86, 0.5, 0.94), (-0.35, -W * 0.5 - 0.17, z0 + 0.47), "cream_light", 0.07)
    a.box((0.92, 0.56, 0.07), (-0.35, -W * 0.5 - 0.17, z0 + 0.96), "petrol", 0.025)
    a.door(-0.35, -W * 0.5 - 0.43, z0 + 0.03)
    a.steps(-0.35, -W * 0.5 - 0.45, z0 + 0.03, 0.56, 3)
    for x in (0.55, 1.05, -1.15):
        a.porthole(x, -W * 0.5 - 0.005, z0 + 0.78)
    for x in (-0.9, 0.0, 0.9):
        a.porthole(x, W * 0.5 + 0.005, z0 + 0.78)
    # roof clutter: air unit, vent, antenna
    a.box((0.56, 0.46, 0.24), (0.75, 0.12, z0 + H + 0.11), "steel", 0.04)
    a.box((0.42, 0.34, 0.04), (0.75, 0.12, z0 + H + 0.245), "steel_dark", 0.012)
    a.cyl(0.09, 0.3, (1.3, -0.3, z0 + H + 0.12), "steel_dark", seg=8)
    a.box((0.09, 0.09, 0.42), (-1.25, 0.25, z0 + H + 0.2), "steel_dark", 0.02)                 # stub mast
    a.box((0.12, 0.12, 0.08), (-1.25, 0.25, z0 + H + 0.44), "red", 0.02)
    # awning on two poles and a patched panel
    a.tarp((1.25, 0.8), (0.95, -W * 0.5 - 0.42, z0 + 0.9), "tarp_red", 0.07, (-12, 0, 0))
    for x in (0.38, 1.52):
        a.box((0.09, 0.09, z0 + 0.84), (x, -W * 0.5 - 0.8, (z0 + 0.84) * 0.5), "steel_dark", 0.02)
        a.box((0.2, 0.2, 0.06), (x, -W * 0.5 - 0.8, 0.03), "concrete_dark", 0.015)
    a.box((0.62, 0.035, 0.42), (-1.2, -W * 0.5 + 0.03, z0 + 0.62), "rust_light", 0.015, (14, 0, 0))
    a.crate(1.1, -W * 0.5 - 0.5, 0.0, 0.3, "cream_dark", 12)
    a.barrel(1.5, -W * 0.5 - 0.45, 0.0, 0.11, 0.32, "petrol_light")
    return a


def container_hall() -> Asset:
    """Storage hall: container walls under a salvaged wing. Footprint 5.2 x 3.6."""
    a = Asset("wb_container_hall")
    L, D = 4.6, 3.0
    a.box((L + 0.3, D + 0.3, 0.1), (0, 0, 0.05), "concrete", 0.03)                     # slab
    for sy, colors in ((1, ("petrol", "cream_dark", "orange", "petrol_light")), (-1, ("cream_dark", "orange", "petrol", "rust"))):
        y = sy * (D * 0.5 - 0.42)
        a.container(-1.15, y, 0.1, colors[0])
        a.container(1.15, y, 0.1, colors[1])
        a.container(-1.05, y, 0.95, colors[2])
        a.container(1.2, y, 0.95, colors[3])
    a.box((0.2, D - 1.7, 1.7), (L * 0.5 - 0.1, 0, 0.95), "cream_dark", 0.03)            # back wall panels
    a.box((0.22, 0.9, 0.7), (L * 0.5 - 0.09, 0.2, 1.25), "rust_light", 0.025)
    # roll door in the front gap, half open
    a.box((0.16, D - 1.72, 1.74), (-L * 0.5 + 0.1, 0, 0.97), "steel_dark", 0.03)
    for i in range(5):
        a.box((0.06, D - 1.9, 0.17), (-L * 0.5 + 0.02, 0, 1.08 + i * 0.18), "steel", 0.02)
    a.box((0.07, D - 1.9, 0.07), (-L * 0.5 + 0.0, 0, 0.98), "yellow", 0.015)
    # wing roof, slightly tilted, with petrol leading edge and ribs
    a.box((L + 0.7, D + 0.5, 0.2), (0.05, 0, 1.98), "cream", 0.07, seg=2, rot=(0, -4, 0))
    a.box((L + 0.72, 0.3, 0.22), (0.05, -D * 0.5 - 0.12, 1.98), "petrol", 0.07, seg=2, rot=(0, -4, 0))
    for x in (-1.6, -0.5, 0.6, 1.7):
        a.box((0.09, D + 0.2, 0.05), (x, 0, 2.105 + x * 0.07), "cream_dark", 0.015, rot=(0, -4, 0))
    a.box((1.3, 0.9, 0.05), (1.0, 0.5, 2.19), "rust_light", 0.015, rot=(0, -4, 0))    # roof patch
    a.box((0.7, 0.55, 0.3), (-1.2, 0.6, 2.2), "steel", 0.05, rot=(0, -4, 0))          # roof fan
    a.cyl(0.2, 0.05, (-1.2, 0.6, 2.37), "steel_dark", seg=10, rot=(0, -4, 0))
    a.box((1.1, 0.06, 0.34), (-1.3, -D * 0.5 - 0.02, 1.52), "orange", 0.02)            # sign board
    a.box((0.75, 0.07, 0.07), (-1.3, -D * 0.5 - 0.035, 1.52), "cream_light", 0.01)
    a.lamp_head(-L * 0.5 - 0.02, -0.8, 1.86)
    a.lamp_head(-L * 0.5 - 0.02, 0.8, 1.86)
    # lean-to with crates
    a.tarp((1.5, 0.95), (0.4, -D * 0.5 - 0.52, 0.98), "tarp_sand", 0.08, (-16, 0, 0))
    for x in (-0.3, 1.1):
        a.box((0.1, 0.1, 0.88), (x, -D * 0.5 - 0.95, 0.44), "steel_dark", 0.02)
        a.box((0.22, 0.22, 0.06), (x, -D * 0.5 - 0.95, 0.03), "concrete_dark", 0.015)
    a.crate(0.1, -D * 0.5 - 0.5, 0.0, 0.4, "cream_dark", 8)
    a.crate(0.55, -D * 0.5 - 0.55, 0.0, 0.34, "petrol_light", -15)
    a.crate(0.3, -D * 0.5 - 0.5, 0.36, 0.3, "orange", 20)
    a.barrel(0.95, -D * 0.5 - 0.45, 0.0)
    return a


def comm_dish() -> Asset:
    """Old depot relay: hut, lattice mast and a large dish. Footprint 2.4 x 2.2."""
    a = Asset("wb_comm_dish")
    a.box((2.3, 2.0, 0.12), (0, 0, 0.06), "concrete", 0.035)
    a.box((1.2, 1.1, 0.8), (-0.42, 0.25, 0.52), "cream", 0.1, seg=2)
    a.box((1.26, 1.16, 0.09), (-0.42, 0.25, 0.94), "petrol", 0.03)
    a.box((1.205, 1.105, 0.14), (-0.42, 0.25, 0.4), "orange", 0.02)
    a.door(-0.42, -0.31, 0.12, 0.32, 0.66)
    a.box((0.4, 0.3, 0.3), (-0.75, 0.3, 1.13), "steel", 0.04)
    a.box((0.62, 0.62, 1.2), (0.62, -0.2, 0.72), "steel_dark", 0.06, taper=0.7)                 # solid pylon
    a.box((0.5, 0.5, 0.75), (0.62, -0.2, 1.68), "steel", 0.05, taper=0.8)
    a.box((0.7, 0.7, 0.08), (0.62, -0.2, 0.16), "concrete_dark", 0.02)
    a.cyl(0.2, 0.22, (0.62, -0.2, 2.12), "steel", seg=10, bevel=0.03)
    tilt = (38, 0, -28)
    a.cyl(1.12, 0.3, (0.62, -0.28, 2.42), "cream_light", r2=0.22, seg=18, rot=(180 + tilt[0], 0, tilt[2]))   # dish back
    a.cyl(1.05, 0.03, (0.56, -0.38, 2.535), "cream_dark", seg=18, rot=tilt)                                    # dish face
    a.cyl(1.13, 0.05, (0.565, -0.37, 2.525), "petrol", seg=18, rot=tilt)                                       # rim
    a.pipe((0.56, -0.38, 2.53), (0.34, -0.83, 3.1), 0.045, "steel_dark")
    a.box((0.12, 0.12, 0.12), (0.33, -0.85, 3.12), "orange", 0.025)
    a.box((0.07, 0.07, 0.06), (0.62, -0.2, 2.95), "red", 0.012)
    a.cyl(0.24, 0.2, (-0.95, -0.6, 0.36), "steel_dark", seg=10, rot=(90, 0, 0))            # cable drum
    a.cyl(0.3, 0.04, (-0.95, -0.49, 0.36), "petrol_dark", seg=10, rot=(90, 0, 0))
    a.cyl(0.3, 0.04, (-0.95, -0.71, 0.36), "petrol_dark", seg=10, rot=(90, 0, 0))
    a.pipe((-0.7, -0.6, 0.15), (0.4, -0.3, 0.15), 0.05, "dark")
    return a


def bunker_entrance() -> Asset:
    """Sealed depot bunker set into the slope. Footprint 3.0 x 2.4, back against rock."""
    a = Asset("wb_bunker_entrance")
    a.box((2.9, 2.2, 0.14), (0, 0.05, 0.07), "concrete_dark", 0.03)
    a.box((2.5, 1.6, 1.25), (0, 0.3, 0.72), "concrete", 0.12, seg=2, taper=0.82)        # main block, battered walls
    a.box((2.6, 1.7, 0.16), (0, 0.3, 1.38), "concrete_dark", 0.05)                      # roof slab
    a.box((1.5, 0.5, 1.02), (0, -0.62, 0.62), "concrete_dark", 0.06)                    # portal
    a.box((1.02, 0.12, 0.82), (0, -0.84, 0.55), "petrol_dark", 0.03)                    # blast door
    a.box((0.07, 0.14, 0.8), (0, -0.86, 0.55), "dark", 0.01)
    for i in range(4):
        a.box((0.16, 0.05, 0.1), (-0.42 + i * 0.28, -0.9, 0.2), "yellow", 0.012, (0, 0, 0))
    a.box((1.1, 0.06, 0.12), (0, -0.88, 1.04), "orange", 0.02)
    a.lamp_head(-0.62, -0.9, 1.12)
    a.lamp_head(0.62, -0.9, 1.12)
    for sx in (-1, 1):                                                                   # wing walls
        a.box((0.22, 1.25, 0.72), (sx * 1.02, -0.85, 0.5), "concrete", 0.05, rot=(0, 0, sx * 14), taper=0.85)
    a.cyl(0.14, 0.4, (0.8, 0.5, 1.62), "steel_dark", seg=8)                              # vent
    a.cyl(0.19, 0.06, (0.8, 0.5, 1.84), "steel", seg=8)
    a.box((0.5, 0.4, 0.22), (-0.7, 0.4, 1.56), "steel", 0.04)
    a.box((0.1, 0.1, 0.5), (-0.2, 0.7, 1.7), "steel_dark", 0.02)
    a.box((0.13, 0.13, 0.09), (-0.2, 0.7, 1.98), "red", 0.02)
    return a


def container_single(color: str) -> Asset:
    a = Asset("wb_container_" + color)
    a.container(0, 0, 0.0, color)
    return a


def container_stack() -> Asset:
    """Three containers, the top one askew. Footprint 2.2 x 1.9."""
    a = Asset("wb_container_stack")
    a.container(0, -0.46, 0.0, "petrol")
    a.container(0, 0.46, 0.0, "cream_dark")
    a.container(0.1, 0.05, 0.85, "orange", 9)
    a.crate(-0.75, -1.12, 0.0, 0.34, "cream_dark", 10)
    return a


def crate_cluster() -> Asset:
    a = Asset("wb_crate_cluster")
    a.crate(-0.22, 0.05, 0.0, 0.44, "cream_dark", 6)
    a.crate(0.26, -0.12, 0.0, 0.38, "petrol_light", -12)
    a.crate(0.12, 0.3, 0.0, 0.34, "orange", 22)
    a.crate(-0.18, 0.06, 0.375, 0.32, "cream_light", -9)
    a.tarp((0.5, 0.42), (0.24, -0.1, 0.36), "tarp_sand", 0.0, (0, 0, -12))
    return a


def barrel_cluster() -> Asset:
    a = Asset("wb_barrel_cluster")
    a.barrel(-0.16, 0.08, 0.0, color="orange")
    a.barrel(0.14, 0.14, 0.0, color="petrol_light")
    a.barrel(0.02, -0.18, 0.0, color="cream_dark")
    a.cyl(0.13, 0.38, (0.36, -0.14, 0.13), "rust", seg=10, rot=(90, 0, 25), bevel=0.02)
    a.box((0.5, 0.4, 0.04), (-0.35, -0.25, 0.02), "steel_dark", 0.01, (0, 0, 15))
    return a


def power_unit() -> Asset:
    """Generator with tank and cable reel. Footprint 1.9 x 1.2."""
    a = Asset("wb_power_unit")
    a.box((1.8, 1.1, 0.08), (0, 0, 0.04), "concrete", 0.02)
    a.box((0.9, 0.8, 0.72), (-0.38, 0, 0.44), "petrol", 0.07, seg=2)
    a.box((0.92, 0.5, 0.08), (-0.38, 0, 0.84), "petrol_dark", 0.02)
    for i in range(5):
        a.box((0.04, 0.5, 0.36), (-0.7 + i * 0.16, -0.41, 0.46), "steel_dark", 0.008)
    a.box((0.3, 0.035, 0.18), (-0.1, -0.415, 0.62), "yellow", 0.01)
    a.cyl(0.07, 0.42, (-0.6, 0.2, 1.04), "steel_dark", seg=8)
    a.cyl(0.3, 0.86, (0.55, 0.12, 0.5), "cream", seg=12, rot=(0, 90, 0), bevel=0.05)
    a.cyl(0.305, 0.12, (0.55, 0.12, 0.5), "orange", seg=12, rot=(0, 90, 0))
    for x in (0.25, 0.85):
        a.box((0.1, 0.56, 0.2), (x, 0.12, 0.17), "steel_dark", 0.02)
    a.pipe((0.08, 0.12, 0.5), (-0.0, 0.0, 0.5), 0.04, "steel_dark")
    a.cyl(0.2, 0.14, (0.6, -0.4, 0.28), "dark", seg=10, rot=(90, 0, 0))
    a.cyl(0.25, 0.03, (0.6, -0.32, 0.28), "steel", seg=10, rot=(90, 0, 0))
    a.cyl(0.25, 0.03, (0.6, -0.48, 0.28), "steel", seg=10, rot=(90, 0, 0))
    a.lamp_head(-0.38, -0.42, 0.92)
    return a


def solar_array() -> Asset:
    """Two tilted panels on solid wedge stands. Footprint 2.6 x 1.2."""
    a = Asset("wb_solar_array")
    a.box((2.6, 1.15, 0.07), (0, 0, 0.035), "concrete_dark", 0.02)                      # sled on the ground
    for x in (-0.66, 0.66):
        a.box((1.0, 0.2, 0.7), (x, -0.36, 0.38), "steel_dark", 0.03)                    # tall stand under the high edge
        a.box((1.0, 0.2, 0.26), (x, 0.36, 0.16), "steel_dark", 0.03)                    # low stand under the low edge
        a.box((0.16, 0.6, 0.16), (x, 0.0, 0.14), "steel_dark", 0.02)                    # spine between them
        a.box((1.2, 1.0, 0.07), (x, 0.0, 0.535), "steel_dark", 0.015, (-28, 0, 0))      # panel frame
        a.box((1.1, 0.9, 0.04), (x, -0.014, 0.565), "solar", 0.008, (-28, 0, 0))
        for i in (-1, 0, 1):
            a.box((0.035, 0.9, 0.045), (x + i * 0.275, -0.016, 0.57), "steel", 0.0, (-28, 0, 0))
    a.box((0.34, 0.3, 0.34), (0, 0.32, 0.2), "petrol", 0.04)
    return a


def wreck_wing() -> Asset:
    """Half-buried wing with exposed ribs: landmark and cover. Footprint 4.6 x 1.8."""
    a = Asset("wb_wreck_wing")
    tilt, mid = 9.0, 0.36
    def up(x):                                  # height of the wing plane at x
        return mid - x * math.sin(math.radians(tilt))
    a.box((4.3, 1.5, 0.28), (0.0, 0.0, mid), "cream", 0.1, seg=2, rot=(0, tilt, 0))
    a.box((4.32, 0.34, 0.3), (0.0, -0.62, mid), "petrol", 0.1, seg=2, rot=(0, tilt, 0))
    a.box((1.1, 1.52, 0.3), (-1.2, 0.0, up(-1.2) + 0.012), "orange", 0.05, rot=(0, tilt, 0))
    for i, x in enumerate((1.3, 1.7, 2.05)):                                             # torn tip: bare ribs
        a.box((0.1, 1.25 - i * 0.22, 0.3), (x, 0.05, max(up(x), 0.1)), "steel_dark", 0.02, rot=(0, tilt, 0))
    a.box((1.0, 0.7, 0.06), (0.3, 0.3, up(0.3) + 0.15), "rust_light", 0.015, rot=(0, tilt, 0))
    a.box((1.2, 1.15, 0.95), (-1.95, 0.0, 0.475), "cream_dark", 0.2, seg=2)             # root fairing, on the ground
    a.box((1.0, 0.9, 0.3), (-0.6, 0.1, 0.15), "steel_dark", 0.05)                       # spar stub propping the wing
    a.cyl(0.26, 0.55, (-1.5, 1.0, 0.2), "steel_dark", seg=10, rot=(90, 0, 20), bevel=0.03)
    return a


def wreck_engine() -> Asset:
    """Engine pod lying in the dirt. Footprint 2.2 x 1.2."""
    a = Asset("wb_wreck_engine")
    a.cyl(0.52, 1.5, (0.0, 0.0, 0.44), "cream", seg=14, rot=(0, 84, 0), bevel=0.06)
    a.cyl(0.535, 0.24, (-0.25, 0.0, 0.46), "orange", seg=14, rot=(0, 84, 0))
    a.cyl(0.5, 0.42, (0.92, 0.0, 0.34), "steel_dark", r2=0.34, seg=14, rot=(0, 84, 0), bevel=0.03)
    a.cyl(0.42, 0.3, (-0.86, 0.0, 0.52), "petrol", r2=0.5, seg=14, rot=(0, 84, 0))
    a.box((0.6, 0.05, 0.4), (0.2, -0.5, 0.5), "rust_light", 0.02, rot=(18, 0, 0))
    a.box((0.9, 0.12, 0.5), (0.0, 0.52, 0.3), "steel_dark", 0.03, rot=(-30, 0, 8))
    return a


BUILDERS = [
    hull_hab_long, container_hall, comm_dish, bunker_entrance,
    lambda: container_single("orange"), lambda: container_single("petrol"), container_stack,
    crate_cluster, barrel_cluster, power_unit, solar_array,
    wreck_wing, wreck_engine,
]


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {"unit": "1.0 = one hex cell; person 0.6", "front": "-Y in Blender, +Z in glTF", "assets": {}}
    for build in BUILDERS:
        asset = build()
        name = asset.name
        manifest["assets"][name] = asset.export()
    (OUT / "kit_manifest.json").write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
    for name, info in manifest["assets"].items():
        print(name, info)


if __name__ == "__main__":
    main()
