"""Re-open both saved meshes and verify the cleanup contract at face corners."""
import hashlib
import json
from collections import Counter
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]


def load_snapshot(filename):
    path = ROOT / "editable" / filename
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    parts = {}
    counts = {}
    points = []
    for ob in bpy.context.scene.objects:
        if ob.type != "MESH":
            continue
        mesh = ob.data
        world = [tuple(ob.matrix_world @ vertex.co) for vertex in mesh.vertices]
        points.extend(world)
        faces = Counter()
        for polygon in mesh.polygons:
            corners = tuple(sorted((world[mesh.loops[index].vertex_index],
                                    tuple(tuple(layer.uv[index].vector) for layer in mesh.uv_layers))
                                   for index in polygon.loop_indices))
            faces[(polygon.material_index, polygon.use_smooth, corners)] += 1
        parts[ob.name] = ([mat.name for mat in mesh.materials],
                          [layer.name for layer in mesh.uv_layers], faces)
        counts[ob.name] = len(mesh.vertices)
    textures = {image.name: hashlib.sha256(image.packed_file.data).hexdigest()
                for image in bpy.data.images if image.packed_file}
    bounds = [[fn(point[i] for point in points) for i in range(3)] for fn in (min, max)]
    return parts, counts, textures, bounds, hashlib.sha256(path.read_bytes()).hexdigest()


before = load_snapshot("tanker_102m_segmented.blend")
after = load_snapshot("tanker_102m_clean_segmented.blend")
old_parts, old_counts, old_textures, old_bounds, original_hash = before
new_parts, new_counts, new_textures, new_bounds, clean_hash = after
assert old_parts.keys() == new_parts.keys() and len(new_parts) == 82
assert old_bounds == new_bounds and old_textures == new_textures

removed = {}
for name, (materials, layers, faces) in new_parts.items():
    old_materials, old_layers, old_faces = old_parts[name]
    assert materials == old_materials and layers == old_layers
    assert not (faces - old_faces), name
    difference = (old_faces - faces).total()
    if difference:
        removed[name] = difference
assert removed == {"tripo_part_52": 4, "tripo_part_74": 1}

report = {
    "prepared_blend_sha256": original_hash,
    "clean_blend_sha256": clean_hash,
    "retained_world_coordinates_uv_and_material_slots_exact": True,
    "mesh_count": len(new_parts),
    "clean_triangle_count": sum(faces.total() for _, _, faces in new_parts.values()),
    "unchanged_packed_textures": len(new_textures),
    "bounds_world": new_bounds,
    "dimensions_xyz": [hi - lo for lo, hi in zip(*new_bounds)],
    "removed_triangles_by_part": removed,
    "vertex_count_changes": {name: count - old_counts[name] for name, count in new_counts.items()
                             if count != old_counts[name]},
}
assert report["clean_triangle_count"] == 15097
(ROOT / "qa/geometry_diagnosis_readback.json").write_text(
    json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report))
