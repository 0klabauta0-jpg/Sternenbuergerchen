"""Read-only matched asset renders; run with Blender -b -P this.py -- --help.

The .blend/.glb is never saved. Cameras use explicit target length rather than
per-model fitting, so proportion and pivot differences remain visible.
"""
import argparse
import colorsys
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


VIEWS = {
    "front": (-38.0, 31.0),
    "rear": (-142.0, 31.0),
    "side": (-90.0, 4.0),
    "top": (0.0, 90.0),
    "game": (-38.0, 48.0),
    "front_ortho": (0.0, 0.0),
    "rear_ortho": (180.0, 0.0),
}


def cli():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input", required=True)
    p.add_argument("--collection", default="LOW", help="Blend mesh collection; use ALL for all scene meshes")
    p.add_argument("--output-dir", required=True)
    p.add_argument("--target-length", type=float, required=True)
    p.add_argument("--views", default="front,rear,side,top,game")
    p.add_argument("--modes", default="material", help="Comma-separated material,clay,random,wire")
    p.add_argument("--width", type=int, default=1200)
    p.add_argument("--height", type=int, default=900)
    p.add_argument("--samples", type=int, default=48)
    p.add_argument("--engine", choices=["EEVEE", "CYCLES"], default="EEVEE")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--no-floor", action="store_true")
    p.add_argument("--target-z-factor", type=float, default=0.15)
    p.add_argument("--ortho-factor", type=float, default=1.65)
    p.add_argument("--game-ortho-factor", type=float, default=4.5)
    p.add_argument("--front-az", type=float, default=None)
    p.add_argument("--front-el", type=float, default=None)
    p.add_argument("--rear-az", type=float, default=None)
    p.add_argument("--rear-el", type=float, default=None)
    p.add_argument("--game-az", type=float, default=None)
    p.add_argument("--game-el", type=float, default=None)
    args = p.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if args.target_length <= 0:
        p.error("target-length must be positive")
    return args


def make_mat(name, rgb, roughness=0.65):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1.0)
    m.use_nodes = True
    node = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    node.inputs["Base Color"].default_value = (*rgb, 1)
    node.inputs["Roughness"].default_value = roughness
    return m


def face(ob, target):
    ob.rotation_euler = (Vector(target) - ob.location).to_track_quat("-Z", "Y").to_euler()


def run(a):
    inp = Path(a.input).resolve()
    out = Path(a.output_dir).resolve()
    out.mkdir(parents=True, exist_ok=True)
    if inp.suffix.lower() == ".blend":
        bpy.ops.wm.open_mainfile(filepath=str(inp))
        if a.collection == "ALL":
            source = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        else:
            col = bpy.data.collections.get(a.collection)
            if col is None:
                raise RuntimeError(f"Missing requested collection {a.collection!r}; available: {list(bpy.data.collections.keys())}")
            source = [o for o in col.all_objects if o.type == "MESH"]
    elif inp.suffix.lower() in [".glb", ".gltf"]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(inp))
        source = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    else:
        raise ValueError("input must be a .blend, .glb or .gltf")
    if not source:
        raise RuntimeError("No source mesh objects")
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    copies = []
    bounds = []
    for ob in sorted(source, key=lambda ob: ob.name):
        ev = ob.evaluated_get(dg)
        mesh = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=dg)
        cp = bpy.data.objects.new("Review_" + ob.name, mesh)
        cp.matrix_world = ob.matrix_world.copy()
        bounds.extend([cp.matrix_world @ v.co for v in mesh.vertices])
        copies.append(cp)
    scene = bpy.data.scenes.new("MATCHED_REVIEW")
    bpy.context.window.scene = scene
    for cp in copies:
        scene.collection.objects.link(cp)
    scene.render.engine = "BLENDER_EEVEE" if a.engine == "EEVEE" else "CYCLES"
    if a.engine == "CYCLES":
        scene.cycles.samples = a.samples
        scene.cycles.use_denoising = True
    elif hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = a.samples
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA" if a.transparent else "RGB"
    scene.render.film_transparent = a.transparent
    scene.view_settings.view_transform = "Khronos PBR Neutral"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.world = bpy.data.worlds.new("REVIEW_World")
    scene.world.use_nodes = True
    bg = next(n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.66, 0.70, 0.73, 1)
    bg.inputs["Strength"].default_value = 0.6
    L = a.target_length
    target = Vector((0, 0, a.target_z_factor * L))
    light_specs = [
        ("Key", (-0.65, -0.9, 1.5), 12.0, 1.0, (1, 0.94, 0.84)),
        ("Fill", (1.0, -0.1, 0.8), 5.0, 1.1, (0.82, 0.9, 1)),
        ("Rim", (0.3, 1.0, 1.1), 8.0, 0.8, (1, 0.98, 0.9)),
    ]
    for name, location, power, size, color in light_specs:
        ld = bpy.data.lights.new("REVIEW_" + name, "AREA")
        ld.energy, ld.size, ld.color = power * L * L, size * L, color
        lo = bpy.data.objects.new(ld.name, ld)
        scene.collection.objects.link(lo)
        lo.location = Vector(location) * L
        face(lo, target)
    if not a.no_floor and not a.transparent:
        floor_mesh = bpy.data.meshes.new("REVIEW_Ground")
        # Large floor avoids a finite plane edge in the shallow side camera.
        s = L * 100
        floor_mesh.from_pydata([(-s,-s,-0.002*L),(s,-s,-0.002*L),(s,s,-0.002*L),(-s,s,-0.002*L)], [], [(0,1,2,3)])
        floor = bpy.data.objects.new("REVIEW_Ground", floor_mesh)
        scene.collection.objects.link(floor)
        floor_mesh.materials.append(make_mat("REVIEW_GroundMaterial", (0.58,0.59,0.58), 0.95))
    camera_data = bpy.data.cameras.new("REVIEW_Camera")
    camera = bpy.data.objects.new("REVIEW_Camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.type = "ORTHO"
    camera_data.clip_start, camera_data.clip_end = L * .001, L * 200
    original_mats = {ob.name: list(ob.data.materials) for ob in copies}
    original_indices = {ob.name: [p.material_index for p in ob.data.polygons] for ob in copies}
    clay = make_mat("REVIEW_Clay", (0.42,0.45,0.47))
    wire = make_mat("REVIEW_Wire", (0.012,0.018,0.022))
    views = dict(VIEWS)
    for key in ["front", "rear", "game"]:
        az, el = views[key]
        custom_az, custom_el = getattr(a, key + "_az"), getattr(a, key + "_el")
        views[key] = (custom_az if custom_az is not None else az, custom_el if custom_el is not None else el)
    metadata = {
        "input": str(inp), "input_sha256": hashlib.sha256(inp.read_bytes()).hexdigest(),
        "collection": a.collection if inp.suffix == ".blend" else "GLB_ALL_MESHES",
        "source_mesh_count": len(source), "evaluated_mesh_count": len(copies),
        "target_length": L, "target": list(target), "engine": scene.render.engine, "samples": a.samples,
        "blender_version": bpy.app.version_string, "color_management": "Khronos PBR Neutral; exposure 0; gamma 1",
        "camera_policy": "Fixed world target and ortho scale derived only from target-length, never fitted to model bounds. Azimuth 0 looks from Blender -Y; positive rotates toward +X.",
        "bounds_min": [min(v[i] for v in bounds) for i in range(3)],
        "bounds_max": [max(v[i] for v in bounds) for i in range(3)],
        "lights": [{"name": n, "position_factor": p, "watts_factor_L_squared": e, "size_factor_L": s, "color": c} for n,p,e,s,c in light_specs],
        "floor": not a.no_floor and not a.transparent, "transparent": a.transparent,
        "shots": []
    }
    for mode in a.modes.split(","):
        if mode not in {"material", "clay", "random", "wire"}:
            raise ValueError(f"Unknown mode {mode}")
        for ob in copies:
            ob.data.materials.clear()
            for m in original_mats[ob.name]:
                ob.data.materials.append(m)
            for p, idx in zip(ob.data.polygons, original_indices[ob.name]):
                p.material_index = idx
            for mod in [m for m in ob.modifiers if m.name == "REVIEW_Wireframe"]:
                ob.modifiers.remove(mod)
            if mode != "material":
                if mode == "random":
                    hue = int(hashlib.sha256(ob.name.encode()).hexdigest()[:8], 16) / 0xffffffff
                    mat = make_mat("REVIEW_Random_" + ob.name, colorsys.hsv_to_rgb(hue, .52, .65))
                else:
                    mat = clay
                for j in range(max(1, len(ob.data.materials))):
                    if j < len(ob.data.materials):
                        ob.data.materials[j] = mat
                    else:
                        ob.data.materials.append(mat)
                if mode == "wire":
                    idx = len(ob.data.materials)
                    ob.data.materials.append(wire)
                    mod = ob.modifiers.new("REVIEW_Wireframe", "WIREFRAME")
                    mod.thickness = .0012 * L
                    mod.use_replace = False
                    # Constant thickness avoids unbounded miter spikes on skinny
                    # GLB triangles; this is a render overlay, never exported.
                    mod.use_even_offset = False
                    mod.offset = 1.0
                    mod.material_offset = idx
        for v in a.views.split(","):
            if v not in views:
                raise ValueError(f"Unknown view {v}; choose {list(views)}")
            az, el = views[v]
            ar, er = math.radians(az), math.radians(el)
            direction = Vector((math.sin(ar)*math.cos(er), -math.cos(ar)*math.cos(er), math.sin(er)))
            # Keep shallow-view orthographic ray origins above the floor. A near
            # camera can start the bottom scanlines below the plane even though
            # the asset is framed correctly, producing a false background band.
            distance_factor = 40 if 0 < abs(el) < 10 else 4
            camera.location = target + direction * L * distance_factor
            face(camera, target)
            isgame = v == "game"
            camera_data.ortho_scale = L * (a.game_ortho_factor if isgame else a.ortho_factor)
            scene.render.resolution_x = 512 if isgame else a.width
            scene.render.resolution_y = 512 if isgame else a.height
            dest = out / f"{mode}_{v}.png"
            scene.render.filepath = str(dest)
            bpy.context.view_layer.update()
            bpy.ops.render.render(write_still=True)
            shot = {"view": v, "mode": mode, "file": str(dest), "azimuth": az, "elevation": el, "location": list(camera.location), "rotation_euler": list(camera.rotation_euler), "ortho_scale": camera_data.ortho_scale, "resolution": [scene.render.resolution_x, scene.render.resolution_y], "sha256": hashlib.sha256(dest.read_bytes()).hexdigest()}
            metadata["shots"].append(shot)
            print("REVIEW_SHOT " + json.dumps(shot), flush=True)
    (out / "render_manifest.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print("REVIEW_DONE " + str(out / "render_manifest.json"), flush=True)


if __name__ == "__main__":
    run(cli())
