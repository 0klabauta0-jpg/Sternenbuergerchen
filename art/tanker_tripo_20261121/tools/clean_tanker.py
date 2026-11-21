"""Repair local source defects without moving retained vertices or UV corners."""
import json
import sys
from collections import Counter
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / "qa"
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "editable/tanker_102m_segmented.blend"),
                        load_ui=False, use_scripts=False)
bpy.context.preferences.filepaths.save_version = 0
sys.path.insert(0, r"C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts")
import qa_check

ISLANDS = {
    "tripo_part_52": (4, Vector((9.041, -11.07, 9.226))),
    "tripo_part_74": (3, Vector((-.37, -22.37, 25.686))),
}
FLIPS = {"tripo_part_43": {117, 118, 119, 120}}
SPLITS = {"tripo_part_1": 2, "tripo_part_74": 4}


def mesh_signature(faces, uv_layers):
    return Counter(tuple(sorted((tuple(loop.vert.co), tuple(tuple(loop[layer].uv) for layer in uv_layers))
                                for loop in face.loops)) for face in faces)


def remove_loose_island(ob, bm, count, center):
    unseen = set(bm.verts)
    matches = []
    while unseen:
        seed = unseen.pop()
        group = {seed}
        stack = [seed]
        while stack:
            vert = stack.pop()
            for edge in vert.link_edges:
                other = edge.other_vert(vert)
                if other in unseen:
                    unseen.remove(other)
                    group.add(other)
                    stack.append(other)
        if len(group) != count:
            continue
        world = [ob.matrix_world @ vert.co for vert in group]
        lo = Vector(tuple(min(point[i] for point in world) for i in range(3)))
        hi = Vector(tuple(max(point[i] for point in world) for i in range(3)))
        if (((lo + hi) / 2) - center).length < .01:
            matches.append((group, lo, hi))
    assert len(matches) == 1, (ob.name, len(matches))
    group, lo, hi = matches[0]
    faces = {face for vert in group for face in vert.link_faces}
    triangles = sum(len(face.verts) - 2 for face in faces)
    bmesh.ops.delete(bm, geom=list(group), context="VERTS")
    return dict(removed_vertices=count, removed_triangles=triangles, bounds_min=list(lo), bounds_max=list(hi))


def winding_seams(bm):
    seams = []
    for edge in bm.edges:
        loops = list(edge.link_loops)
        if len(loops) == 2 and loops[0].vert == loops[1].vert:
            seams.append(edge)
    return seams


changes = []
for name in sorted(ISLANDS.keys() | FLIPS.keys() | SPLITS.keys()):
    ob = bpy.data.objects[name]
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.faces.ensure_lookup_table()
    change = {"object": name}
    if name in ISLANDS:
        change.update(remove_loose_island(ob, bm, *ISLANDS[name]))
    uv_layers = list(bm.loops.layers.uv.values())
    before = mesh_signature(bm.faces, uv_layers)
    if name in FLIPS:
        faces = [bm.faces[index] for index in sorted(FLIPS[name])]
        for face in faces:
            face.normal_flip()
        change["flipped_faces"] = sorted(FLIPS[name])
    if name in SPLITS:
        seams = winding_seams(bm)
        assert len(seams) == SPLITS[name], (name, len(seams))
        vertex_count = len(bm.verts)
        change["split_winding_seams"] = [[list(ob.matrix_world @ vert.co) for vert in edge.verts] for edge in seams]
        bmesh.ops.split_edges(bm, edges=seams)
        change["added_coincident_vertices"] = len(bm.verts) - vertex_count
    assert not winding_seams(bm), name
    assert before == mesh_signature(bm.faces, uv_layers), name
    bm.to_mesh(ob.data)
    ob.data.update()
    bm.free()
    changes.append(change)

objects = [ob for ob in bpy.context.scene.objects if ob.type == "MESH"]
result = qa_check.run(objects=[ob.name for ob in objects], profile="game")
(QA / "geometry_clean.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
(QA / "geometry_changes.json").write_text(json.dumps(changes, indent=2) + "\n", encoding="utf-8")
print("CLEAN_QA " + json.dumps({key: result[key] for key in ("errors", "warnings")}))
assert result["pass"], result["errors"]
assert len(objects) == 82 and sum(obj["tris"] for obj in result["objects"].values()) == 15097
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "editable/tanker_102m_clean_segmented.blend"), compress=True)
