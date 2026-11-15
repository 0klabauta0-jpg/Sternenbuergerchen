"""Heavy armour R08 (15.11.2026): editable source for the heavy armour parts.

Target: the confirmed reference sheet 01_Ruestungen/03_Schwer_Mehransichten.png
(dome helmet with brow ridge, visor slit, breathing mask, ear discs; thick dark
collar; stacked sand shoulder plates; sand shield chest plate on a dark breast;
belt with pouches; three hexagonal back plates; segmented dark upper arms; sand
forearm guards; large light-grey gloves; sand thigh plates; large knee plates;
dark shin blocks; chunky boots with grey toe caps).

Drop-in contract with scripts/terrain/personnel_armor_visual.gd (same as the
R07 GLBs these files replace):
- Same file names as the R07 heavy parts, one mesh object per file, origin in
  the middle of the part, no object transform.
- Axes (Blender): front = -Y (glTF +Z), Z = along the bone towards its parent
  joint (Godot +Y), X = sideways. Limb parts are used unmirrored on both sides,
  so every part is symmetric in X.
- torso, pelvis, forearm, thigh, shin and knee are fitted as the unit box
  [-0.5, 0.5]^3: geometry outside that box sticks out proportionally.
  All other parts are fitted by their own bounding box.
- torso: each connected piece is bound by its centre height (Blender Z):
  Z >= -0.07 Chest, -0.39 <= Z < -0.07 Spine, below Hips.
- Material names M_Armor_Ceramic (sand), M_Armor_Graphite (dark grey),
  M_Armor_Titanium (light grey, also the gloves), M_Armor_Amber, M_Armor_Visor.
  The runtime bakes and tints by these names.

Low-poly, single-segment chamfers, flat colours, bold shapes: the figure is
only about 60 px tall in play. Whole heavy outfit must stay <= 9000 triangles.

Run:  python3 art/ruestung_schwer_r08_20261115/build_parts.py [output_dir]
Default output: Assets/curated/personnel/armor_r08_schwer_20261115/ plus parts_manifest.json.
"""
import json
import math
import sys
from pathlib import Path

import bpy  # must come first: it makes bmesh and mathutils importable
import bmesh
from mathutils import Euler, Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "Assets" / "curated" / "personnel" / "armor_r08_schwer_20261115"

# Linear base colours. The unit renderer (ambient light 0.75 + weak key light,
# linear tonemap) shows albedo at roughly 0.75x, so these are the sRGB target
# colours of the reference converted to linear and divided by ~0.75:
#   graphite -> about (66,66,70) on screen, titanium -> about (112,112,118),
#   ceramic (sand) -> about (168,154,142), amber -> about (224,160,40).
MATERIALS = {
    "M_Armor_Graphite": ((0.072, 0.072, 0.082), 0.0, 0.90),
    "M_Armor_Titanium": ((0.215, 0.218, 0.245), 0.0, 0.80),
    "M_Armor_Ceramic": ((0.52, 0.43, 0.36), 0.0, 0.85),
    "M_Armor_Amber": ((0.98, 0.47, 0.03), 0.0, 0.60),
    "M_Armor_Visor": ((0.010, 0.012, 0.016), 0.0, 0.90),
}
G, T, C, A, V = "M_Armor_Graphite", "M_Armor_Titanium", "M_Armor_Ceramic", "M_Armor_Amber", "M_Armor_Visor"


class Asset:
    def __init__(self, name: str):
        self.name = name
        self.bm = bmesh.new()
        self.materials: list[str] = []
        self.scratch = bpy.data.meshes.new("scratch_" + name)

    def slot(self, material: str) -> int:
        if material not in self.materials:
            self.materials.append(material)
        return self.materials.index(material)

    def merge(self, part: bmesh.types.BMesh, material: str, loc=(0, 0, 0), rot=(0.0, 0.0, 0.0)) -> None:
        matrix = Matrix.Translation(Vector(loc)) @ Euler(tuple(math.radians(a) for a in rot)).to_matrix().to_4x4()
        bmesh.ops.transform(part, matrix=matrix, verts=part.verts)
        index = self.slot(material)
        for face in part.faces:
            face.material_index = index
        part.to_mesh(self.scratch)
        part.free()
        self.bm.from_mesh(self.scratch)

    # ------------------------------------------------------------ primitives
    def box(self, size, loc, material, bevel=0.03, rot=(0, 0, 0), taper=1.0, taper_axis="z"):
        """Chamfered box. taper scales the +taper_axis end of the box."""
        part = bmesh.new()
        bmesh.ops.create_cube(part, size=1.0)
        axis = "xyz".index(taper_axis)
        for v in part.verts:
            k = taper if v.co[axis] > 0 else 1.0
            co = [v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]]
            for i in range(3):
                if i != axis:
                    co[i] *= k
            v.co = Vector(co)
        if bevel > 0.0:
            bmesh.ops.bevel(part, geom=list(part.edges), offset=min(bevel, min(size) * 0.45), segments=1,
                            affect="EDGES", profile=0.5)
        self.merge(part, material, loc, rot)

    def cyl(self, r1, depth, loc, material, r2=None, seg=8, rot=(0, 0, 0), bevel=0.0, scale=(1, 1, 1), spin=None):
        """Prism along Z (before rot). spin turns it so a flat face points to -Y."""
        part = bmesh.new()
        bmesh.ops.create_cone(part, cap_ends=True, cap_tris=False, segments=seg, radius1=r1,
                              radius2=r1 if r2 is None else r2, depth=depth)
        turn = math.pi / seg if spin is None else spin
        bmesh.ops.rotate(part, verts=part.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(turn, 3, "Z"))
        bmesh.ops.scale(part, vec=Vector(scale), verts=part.verts)
        if bevel > 0.0:
            rim = [e for e in part.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-6]
            bmesh.ops.bevel(part, geom=rim, offset=bevel, segments=1, affect="EDGES", profile=0.5)
        self.merge(part, material, loc, rot)

    def prism(self, outline, depth, loc, material, bevel=0.02):
        """Flat plate from an XZ outline (counter-clockwise seen from -Y), extruded along +Y."""
        part = bmesh.new()
        verts = [part.verts.new((x, -depth * 0.5, z)) for x, z in outline]
        face = part.faces.new(verts)
        ext = bmesh.ops.extrude_face_region(part, geom=[face])
        moved = [g for g in ext["geom"] if isinstance(g, bmesh.types.BMVert)]
        bmesh.ops.translate(part, vec=(0, depth, 0), verts=moved)
        bmesh.ops.recalc_face_normals(part, faces=list(part.faces))
        if bevel > 0.0:
            front = [e for e in part.edges if all(abs(v.co.y + depth * 0.5) < 1e-6 for v in e.verts)]
            bmesh.ops.bevel(part, geom=front, offset=bevel, segments=1, affect="EDGES", profile=0.5)
        self.merge(part, material, loc)

    def lathe(self, profile, material, seg=12, depth_scale=1.0, loc=(0, 0, 0)):
        """Closed body of revolution around Z from (z, radius) pairs, bottom to top."""
        part = bmesh.new()
        rings = []
        for z, r in profile:
            ring = []
            for i in range(seg):
                a = 2 * math.pi * (i + 0.5) / seg - math.pi / 2
                ring.append(part.verts.new((r * math.cos(a), r * math.sin(a) * depth_scale, z)))
            rings.append(ring)
        for lower, upper in zip(rings, rings[1:]):
            for i in range(seg):
                j = (i + 1) % seg
                part.faces.new((lower[i], lower[j], upper[j], upper[i]))
        part.faces.new(list(reversed(rings[0])))
        part.faces.new(rings[-1])
        bmesh.ops.recalc_face_normals(part, faces=list(part.faces))
        self.merge(part, material, loc)

    # ---------------------------------------------------------------- export
    def export(self) -> dict:
        mesh = bpy.data.meshes.new(self.name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=0.0002)
        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        self.bm.to_mesh(mesh)
        mesh.uv_layers.new(name="UVMap")  # the runtime baker reads TEX_UV for every part
        tris = sum(len(f.verts) - 2 for f in self.bm.faces)
        lo = [min(v.co[i] for v in self.bm.verts) for i in range(3)]
        hi = [max(v.co[i] for v in self.bm.verts) for i in range(3)]
        self.bm.free()
        for name in self.materials:
            mat = bpy.data.materials.get(name)
            if mat is None:
                rgb, metallic, roughness = MATERIALS[name]
                mat = bpy.data.materials.new(name)
                mat.use_nodes = True
                bsdf = mat.node_tree.nodes.get("Principled BSDF")
                bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
                bsdf.inputs["Metallic"].default_value = metallic
                bsdf.inputs["Roughness"].default_value = roughness
            mesh.materials.append(mat)
        for poly in mesh.polygons:
            poly.use_smooth = False
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        path = OUT / (self.name + ".glb")
        bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                                  export_apply=True, export_extras=False)
        bpy.data.objects.remove(obj)
        return {"file": path.name, "triangles": tris, "materials": self.materials,
                "bounds_min": [round(x, 3) for x in lo], "bounds_max": [round(x, 3) for x in hi]}


# ======================================================================= parts
def helmet_heavy() -> Asset:
    """Faceted dome, brow ridge, visor slit, mask with breathing slits, chin block, ear discs."""
    a = Asset("helmet_heavy")
    a.lathe([(-0.50, 0.39), (-0.30, 0.43), (-0.06, 0.44), (0.16, 0.43), (0.32, 0.37), (0.43, 0.26), (0.50, 0.10)], T, seg=12)
    # Brow ridge over the visor.
    a.box((0.72, 0.30, 0.10), (0, -0.33, 0.19), T, 0.03, taper=0.9, taper_axis="y")
    # Visor slit (near black), slightly recessed under the brow.
    a.box((0.64, 0.26, 0.12), (0, -0.33, 0.075), V, 0.02)
    # Mask: wedge-shaped face plate with two horizontal breathing slits per cheek.
    a.box((0.70, 0.34, 0.28), (0, -0.30, -0.15), T, 0.04, taper=1.15, taper_axis="z")
    for x in (-0.17, 0.17):
        for z in (-0.10, -0.17):
            a.box((0.15, 0.04, 0.03), (x, -0.47, z), V, 0.0)
    a.box((0.26, 0.26, 0.13), (0, -0.37, -0.38), T, 0.03)  # chin block
    a.box((0.30, 0.03, 0.03), (0, -0.47, -0.30), V, 0.0)  # seam above the chin
    # Round ear discs: light rim with a dark core.
    for x in (-0.455, 0.455):
        a.cyl(0.13, 0.08, (x, 0.03, 0.05), T, seg=10, rot=(0, 90, 0), bevel=0.015)
        a.cyl(0.07, 0.04, (x * 1.09, 0.03, 0.05), G, seg=8, rot=(0, 90, 0))
    return a


def collar() -> Asset:
    """Thick dark neck ring with a rolled top and small amber marks front and back."""
    a = Asset("collar")
    a.cyl(0.50, 0.58, (0, 0, -0.21), G, r2=0.47, seg=8, bevel=0.04)
    a.cyl(0.47, 0.30, (0, 0, 0.23), G, r2=0.36, seg=8)
    a.cyl(0.36, 0.06, (0, 0, 0.40), T, seg=8)  # light rim the helmet sits on
    for x in (-0.24, 0.24):
        for dz in (0.0, 0.07):
            a.box((0.12, 0.04, 0.035), (x, -0.47, -0.28 + dz), A, 0.0)
            a.box((0.12, 0.04, 0.035), (x * 0.9, 0.46, 0.02 + dz), A, 0.0)
    return a


def torso_heavy() -> Asset:
    """Dark breast block with a sand shield plate in a dark frame; three hex plates on the back."""
    a = Asset("torso_heavy")
    a.box((0.94, 0.88, 0.56), (0, 0, 0.22), G, 0.08, taper=0.92, taper_axis="z")  # chest (Chest bone)
    a.box((0.84, 0.80, 0.34), (0, 0, -0.23), G, 0.06)                              # belly (Spine bone)
    a.box((0.74, 0.70, 0.18), (0, 0, -0.43), G, 0.04)                              # waist (Hips bone)
    # Chest: frame + shield plate, both clearly protruding in front.
    frame = [(-0.35, 0.45), (0.35, 0.45), (0.35, 0.0), (0.14, -0.25), (-0.14, -0.25), (-0.35, 0.0)]
    shield = [(-0.27, 0.39), (0.27, 0.39), (0.27, 0.03), (0.10, -0.18), (-0.10, -0.18), (-0.27, 0.03)]
    a.prism(frame, 0.14, (0, -0.46, 0.0), T, 0.03)
    a.prism(shield, 0.10, (0, -0.56, 0.0), C, 0.035)
    for x in (-0.20, 0.20):  # two strap blocks above the plate
        a.box((0.10, 0.10, 0.09), (x, -0.50, 0.47), C, 0.02)
    a.box((0.09, 0.03, 0.03), (0.21, -0.56, 0.42), A, 0.0)
    # Side ribs (segmented flanks).
    for z in (0.26, 0.08, -0.12):
        for x in (-0.47, 0.47):
            a.box((0.06, 0.62, 0.09), (x, 0.02, z), T, 0.015)
    # Back: dark frame with two shoulder straps and three hexagonal sand plates.
    a.box((0.40, 0.10, 0.72), (0, 0.46, 0.10), G, 0.03)
    for x in (-1, 1):
        a.box((0.10, 0.10, 0.30), (x * 0.20, 0.46, 0.40), G, 0.02, rot=(0, x * 30, 0))
    for z in (0.30, 0.02, -0.26):
        a.cyl(0.155, 0.08, (0, 0.53, z), C, seg=6, rot=(90, 0, 0), spin=0.0, bevel=0.02)
    return a


def pelvis_heavy() -> Asset:
    """Hip block, belt with four dark pouches and a buckle, front groin plate."""
    a = Asset("pelvis_heavy")
    a.box((0.90, 0.84, 0.62), (0, 0, -0.18), G, 0.06)
    a.box((1.00, 0.94, 0.26), (0, 0, 0.22), T, 0.04)  # belt
    a.box((0.22, 0.10, 0.22), (0, -0.50, 0.20), G, 0.03)  # buckle
    for x, turn in ((-0.20, 0), (0.20, 0), (-0.42, 30), (0.42, -30)):
        a.box((0.17, 0.14, 0.26), (x, -0.52 if abs(x) < 0.3 else -0.43, 0.15), G, 0.03, rot=(0, 0, turn))
        a.box((0.18, 0.15, 0.05), (x, -0.52 if abs(x) < 0.3 else -0.43, 0.29), T, 0.015, rot=(0, 0, turn))
    a.box((0.40, 0.10, 0.22), (0, 0.50, 0.15), G, 0.03)  # back pouch
    a.box((0.34, 0.12, 0.30), (0, -0.42, -0.36), G, 0.04, taper=1.25)  # groin plate
    return a


def pauldron_heavy() -> Asset:
    """Three stacked sand plates. Z = outward normal of the shoulder cap after fitting."""
    a = Asset("pauldron_heavy")
    a.box((1.00, 1.00, 0.36), (0, 0, -0.32), C, 0.07)
    a.box((0.78, 0.86, 0.32), (0, 0, 0.00), C, 0.07)
    a.box((0.54, 0.72, 0.30), (0, 0, 0.30), C, 0.07)
    a.box((0.36, 0.56, 0.12), (0, 0, 0.46), G, 0.03)  # dark cap on top
    return a


def upper_arm_heavy() -> Asset:
    """Segmented dark upper arm: three wide rings on a dark core."""
    a = Asset("upper_arm_heavy")
    a.cyl(0.40, 1.0, (0, 0, 0), G, seg=8)
    for z in (0.31, 0.0, -0.31):
        a.cyl(0.50, 0.24, (0, 0, z), G, r2=0.46, seg=8, bevel=0.03)
    for z in (0.155, -0.155):
        a.cyl(0.45, 0.06, (0, 0, z), T, seg=8)
    return a


def forearm_heavy() -> Asset:
    """Dark sleeve with a U-shaped sand guard and one amber slit."""
    a = Asset("forearm_heavy")
    a.cyl(0.40, 1.0, (0, 0, 0), G, seg=8)
    a.box((1.04, 0.66, 0.80), (0, -0.14, -0.06), C, 0.07, taper=0.75)  # narrower at the elbow
    a.box((0.06, 0.03, 0.26), (0, -0.48, -0.08), A, 0.0)
    a.cyl(0.46, 0.12, (0, 0, -0.44), G, seg=8, bevel=0.02)  # wrist cuff
    return a


def hand_guard_heavy() -> Asset:
    """Large light-grey fist. +Z = wrist, -Z = knuckles, -Y = thumb side (front)."""
    a = Asset("hand_guard_heavy")
    a.cyl(0.38, 0.22, (0, 0, 0.39), G, seg=8)                     # cuff
    a.box((0.82, 0.78, 0.46), (0, 0, 0.06), T, 0.08)              # back of hand / palm
    a.box((0.86, 0.70, 0.34), (0, 0.04, -0.30), T, 0.09)          # curled fingers
    for x in (-0.28, 0.0, 0.28):                                   # knuckle ridges
        a.box((0.22, 0.60, 0.08), (x, 0.04, -0.47), T, 0.03)
    a.box((0.30, 0.22, 0.38), (0, -0.42, -0.02), T, 0.06)         # thumb
    return a


def thigh_heavy() -> Asset:
    """Dark thigh with sand side plates angled towards the front."""
    a = Asset("thigh_heavy")
    a.cyl(0.47, 1.0, (0, 0, 0), G, seg=8, r2=0.50)
    # Side plates turned towards the front. Parts are unmirrored, so both sides carry one.
    for x in (-1, 1):
        a.box((0.12, 0.62, 0.72), (x * 0.43, -0.16, 0.04), C, 0.05, rot=(0, 0, -x * 28), taper=0.85)
    a.box((0.70, 0.10, 0.08), (0, -0.40, -0.40), T, 0.02)  # segment band
    return a


def knee_heavy() -> Asset:
    """Large octagonal sand knee plate with two slits on a dark pad (front part of the unit box)."""
    a = Asset("knee_heavy")
    a.box((0.84, 0.40, 0.82), (0, -0.16, 0), G, 0.05)
    a.cyl(0.52, 0.18, (0, -0.42, 0), C, seg=8, rot=(90, 0, 0), bevel=0.03, scale=(1.0, 0.92, 1.0))
    for z in (-0.12, 0.12):
        a.box((0.52, 0.05, 0.075), (0, -0.52, z), G, 0.0)
    return a


def shin_heavy() -> Asset:
    """Dark shin block with one amber mark."""
    a = Asset("shin_heavy")
    a.cyl(0.46, 1.0, (0, 0, 0), G, seg=8, r2=0.42)
    a.box((0.78, 0.32, 0.72), (0, -0.33, 0.05), G, 0.07, taper=0.9)
    a.box((0.20, 0.04, 0.06), (0, -0.50, 0.12), A, 0.0)
    a.cyl(0.47, 0.08, (0, 0, 0.47), T, seg=8)
    a.cyl(0.44, 0.16, (0, 0, -0.56), G, seg=8)  # skirt over the boot top
    return a


def boot_heavy() -> Asset:
    """Chunky boot: dark upper and sole, grey toe cap, amber mark. -Y = toes."""
    a = Asset("boot_heavy")
    a.box((0.98, 1.00, 0.20), (0, 0, -0.40), G, 0.04)            # sole
    a.box((0.88, 0.80, 0.70), (0, 0.08, 0.05), G, 0.07)          # heel, instep and ankle
    a.box((0.92, 0.46, 0.50), (0, -0.27, -0.12), T, 0.09, taper=0.88, taper_axis="z")  # toe cap
    a.box((0.80, 0.30, 0.20), (0, -0.20, 0.20), G, 0.05, rot=(-30, 0, 0))  # instep plate over the toe joint
    a.box((0.22, 0.04, 0.06), (0, -0.33, 0.22), A, 0.0)
    a.box((0.80, 0.56, 0.12), (0, 0.17, 0.40), G, 0.03)          # ankle cuff
    return a


PARTS = [helmet_heavy, collar, torso_heavy, pelvis_heavy, pauldron_heavy, upper_arm_heavy, forearm_heavy,
         hand_guard_heavy, thigh_heavy, knee_heavy, shin_heavy, boot_heavy]
# Instances per outfit (left/right parts appear twice).
COUNT = {"helmet_heavy": 1, "collar": 1, "torso_heavy": 1, "pelvis_heavy": 1}


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {"revision": "heavy_r08_20261115", "source": "art/ruestung_schwer_r08_20261115/build_parts.py",
                "note": "R08 heavy armour parts, drop-in for the R07 heavy parts", "parts": {}}
    total = 0
    for build in PARTS:
        info = build().export()
        manifest["parts"][build.__name__] = info
        total += info["triangles"] * COUNT.get(build.__name__, 2)
    manifest["outfit_triangles"] = total
    (OUT / "parts_manifest.json").write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
    print("heavy outfit triangles:", total)


if __name__ == "__main__":
    main()
