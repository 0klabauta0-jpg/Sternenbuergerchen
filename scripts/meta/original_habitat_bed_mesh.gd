extends RefCounted
## Exact triangle/material derivation of the first bed from the authored,
## furnished habitat. The original GLB remains unchanged. The bed's own
## triangles occupy this measured local-space box; its floor and wall do not.
const SOURCE := "res://Assets/curated/base_access_20261109/habitat_cutaway_01.glb"
const SOURCE_BOX := AABB(Vector3(-3.04, 0.20, -2.95), Vector3(1.10, 0.74, 1.95))
const SOURCE_CENTER := Vector3(-2.48, 0.0, -1.95)
const SOURCE_SCALE := 0.55
static var _mesh: ArrayMesh

static func mesh() -> ArrayMesh:
	if _mesh != null: return _mesh
	var scene: PackedScene = load(SOURCE)
	if scene == null: return null
	var root: Node = scene.instantiate()
	var original: MeshInstance3D = root.get_child(0) as MeshInstance3D
	if original == null or original.mesh == null:
		root.free(); return null
	var output := ArrayMesh.new()
	for surface in range(original.mesh.get_surface_count()):
		var arrays: Array = original.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty(): continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var accepted := 0
		for i in range(0, indices.size(), 3):
			var a := int(indices[i]); var b := int(indices[i + 1]); var c := int(indices[i + 2])
			if not SOURCE_BOX.has_point(vertices[a]) or not SOURCE_BOX.has_point(vertices[b]) or not SOURCE_BOX.has_point(vertices[c]): continue
			for vertex_index in [a, b, c]:
				if normals.size() == vertices.size(): st.set_normal(normals[vertex_index])
				if uvs.size() == vertices.size(): st.set_uv(uvs[vertex_index])
				st.add_vertex((vertices[vertex_index] - SOURCE_CENTER) * SOURCE_SCALE)
			accepted += 1
		if accepted == 0: continue
		st.set_material(original.mesh.surface_get_material(surface))
		st.commit(output)
	root.free()
	if output.get_surface_count() == 0: return null
	_mesh = output
	return _mesh
