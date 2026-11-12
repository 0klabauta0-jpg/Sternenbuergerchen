"""Curate one rock from each credited download. Run in a fresh Blender process."""
import json
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector

source, output, skills = (Path(arg).resolve() for arg in sys.argv[sys.argv.index("--") + 1:])
sys.path.insert(0, str(skills / "blender-asset-qa" / "scripts"))
import qa_check

bpy.ops.wm.read_factory_settings(use_empty=True)
if source.suffix == ".blend":
    with bpy.data.libraries.load(str(source)) as (available, selected):
        selected.objects = ["big_rock_04"]
    original = selected.objects[0]
    bpy.context.collection.objects.link(original)
    title = "GlutSandstone04"
else:
    bpy.ops.import_scene.fbx(filepath=str(source))
    unique = {}
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH" or obj.data.name in unique:
            continue
        obj.data.calc_loop_triangles()
        if len(obj.data.loop_triangles) in (288, 384):
            unique[obj.data.name] = obj
    original = min(unique.values(), key=lambda obj: (len(obj.data.loop_triangles), obj.name))
    title = "GlutFbxRockStudy"

bpy.context.view_layer.update()
depsgraph = bpy.context.evaluated_depsgraph_get()
evaluated = original.evaluated_get(depsgraph)
mesh = bpy.data.meshes.new_from_object(evaluated)
obj = bpy.data.objects.new(title, mesh)
bpy.context.collection.objects.link(obj)
mesh.transform(original.matrix_world.to_3x3().to_4x4())
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00002)
bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=0.00001)
# The Blend object includes scattered pebbles. Keep the single boulder
# island so the runtime footprint describes the actual mass.
pending = set(bm.verts)
islands = []
while pending:
    first = pending.pop()
    island = [first]
    for vertex in island:
        for edge in vertex.link_edges:
            neighbor = edge.other_vert(vertex)
            if neighbor in pending:
                pending.remove(neighbor)
                island.append(neighbor)
    islands.append(island)
main_island = set(max(islands, key=len))
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v not in main_island], context="VERTS")
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
bmesh.ops.triangulate(bm, faces=list(bm.faces))
bm.to_mesh(mesh)
bm.free()
low = Vector(tuple(min(v.co[i] for v in mesh.vertices) for i in range(3)))
high = Vector(tuple(max(v.co[i] for v in mesh.vertices) for i in range(3)))
pivot = Vector(((low.x + high.x) * 0.5, (low.y + high.y) * 0.5, low.z))
radius = max((v.co - pivot).xy.length for v in mesh.vertices)
scale = 0.41 / radius
z_scale = min(scale, 0.66 / (high.z - low.z))
for vertex in mesh.vertices:
    offset = vertex.co - pivot
    vertex.co = (offset.x * scale, offset.y * scale, offset.z * z_scale)
mesh.update()
original_name = original.name
for other in list(bpy.context.scene.objects):
    if other != obj:
        bpy.data.objects.remove(other, do_unlink=True)

# The blend uses a procedural source material. The curated variation uses
# two authored strata colors; the FBX study reconnects its actual atlas.
mesh.materials.clear()
for suffix, tint in [("Stone", (0.29, 0.127, 0.082, 1.0)), ("Strata", (0.41, 0.202, 0.128, 1.0))]:
    material = bpy.data.materials.new(title + suffix)
    material.diffuse_color = tint
    material.use_nodes = True
    principled = next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    principled.inputs["Base Color"].default_value = tint
    principled.inputs["Roughness"].default_value = 0.91
    if source.suffix == ".fbx":
        texture = material.node_tree.nodes.new("ShaderNodeTexImage")
        texture.image = bpy.data.images.load(str(source.parent.parent / "textures" / "Rocks.png"), check_existing=True)
        material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    mesh.materials.append(material)
for face in mesh.polygons:
    height = sum(mesh.vertices[v].co.z for v in face.vertices) / len(face.vertices)
    face.material_index = int(height > 0.25 and face.normal.z > 0.2)
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.context.view_layer.update()
mesh.calc_loop_triangles()
result = qa_check.run(objects=[obj.name], profile="game")
print("ASSET_QA", json.dumps(result, default=str))
if not result["pass"]:
    raise RuntimeError("Rock did not pass asset QA")
output.parent.mkdir(parents=True, exist_ok=True)
if source.suffix == ".blend":
    # The simplified stone colors do not consume the source's stacked UV sets.
    for layer in list(mesh.uv_layers):
        mesh.uv_layers.remove(layer)
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(output.with_suffix(".blend")), copy=True)
bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", use_selection=True, export_animations=False)
print("ROCK_EXPORT", json.dumps({"blender": bpy.app.version_string, "source_object": original_name,
    "dimensions": list(obj.dimensions), "triangles": len(mesh.loop_triangles),
    "materials": len(mesh.materials), "bytes": output.stat().st_size}))
