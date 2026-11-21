extends RefCounted

const EXPORTS := "../../art/tanker_tripo_20261121/exports/"
const SEGMENTED := "tanker_102m_clean_segmented.glb"
const ATLAS := "tanker_102m.glb"
const GAME := "tanker_game.glb"
const CUTLASS := "C:/dev/SternenBuergerchen/Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb"
const CUTLASS_SHA256 := "21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf"
const CUTLASS_SCALE := 0.22
const GAME_SCALE := 3.52 / 37.5
const LENGTH_METERS := 102.0
const CLEAN_TRIANGLES := 15097
const SIZE_METERS := Vector3(0.6738103 / 1.0010678 * LENGTH_METERS, 0.28345496 / 1.0010678 * LENGTH_METERS, LENGTH_METERS)


static func path_for(file: String) -> String:
	if file == CUTLASS:
		return file
	return ProjectSettings.globalize_path("res://" + EXPORTS + file).simplify_path()


static func load_asset(file: String) -> Dictionary:
	var path := path_for(file)
	var digest := FileAccess.get_sha256(path)
	if digest.is_empty() or (file == CUTLASS and digest != CUTLASS_SHA256):
		return {"error": "Missing file or unexpected Cutlass SHA-256: " + path}

	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var error := gltf.append_from_file(path, state)
	if error != OK:
		return {"error": "append_from_file %s: %s" % [path, error_string(error)]}

	var model := gltf.generate_scene(state) as Node3D
	if model == null:
		return {"error": "No Node3D was generated for " + path}
	var stats := {
		"file": path,
		"sha256": digest,
		"mesh_instances": 0,
		"mesh_surfaces": 0,
		"triangles": 0,
		"missing_material_slots": 0,
		"missing_surface_uv": 0,
		"missing_albedo_texture_slots": 0,
		"non_triangle_surfaces": 0,
		"bounds": AABB(),
		"bounds_has_vertex": false,
		"materials": {},
		"source_images": 0,
		"embedded_image_buffer_views": 0,
		"decoded_images": 0
	}
	var chunks: Array = state.json.get("images", [])
	stats.source_images = chunks.size()
	for chunk: Dictionary in chunks:
		if chunk.has("bufferView") and not chunk.has("uri"):
			stats.embedded_image_buffer_views += 1
	for texture: Texture2D in state.get_images():
		if texture and texture.get_width() > 0 and texture.get_height() > 0:
			stats.decoded_images += 1
	_measure_node(model, Transform3D.IDENTITY, stats)
	model.scale *= CUTLASS_SCALE if file == CUTLASS else 1.0
	var bounds: AABB = stats.bounds
	if file == CUTLASS:
		bounds = AABB(bounds.position * CUTLASS_SCALE, bounds.size * CUTLASS_SCALE)
	stats.erase("bounds")
	stats.erase("bounds_has_vertex")
	stats["bounds_min"] = _xyz(bounds.position)
	stats["bounds_size"] = _xyz(bounds.size)
	stats["bounds_max"] = _xyz(bounds.end)
	stats["materials"] = stats.materials.size()
	return {"model": model, "stats": stats}


static func _measure_node(node: Node, parent_transform: Transform3D, stats: Dictionary) -> void:
	var transform := parent_transform
	if node is Node3D:
		transform *= (node as Node3D).transform
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh := instance.mesh
		if mesh != null:
			stats.mesh_instances += 1
			for index in mesh.get_surface_count():
				_measure_surface(instance, index, transform, stats)
	for child in node.get_children():
		_measure_node(child, transform, stats)


static func _measure_surface(instance: MeshInstance3D, index: int, transform: Transform3D, stats: Dictionary) -> void:
	var mesh := instance.mesh as ArrayMesh
	stats.mesh_surfaces += 1
	if mesh == null or mesh.surface_get_primitive_type(index) != Mesh.PRIMITIVE_TRIANGLES:
		stats.non_triangle_surfaces += 1
		return

	var arrays := mesh.surface_get_arrays(index)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var point_count := indices.size() if not indices.is_empty() else vertices.size()
	stats.triangles += point_count / 3.0
	for vertex in vertices:
		var world_vertex := transform * vertex
		if stats.bounds_has_vertex:
			stats.bounds = (stats.bounds as AABB).expand(world_vertex)
		else:
			stats.bounds = AABB(world_vertex, Vector3.ZERO)
			stats.bounds_has_vertex = true

	var material := instance.get_active_material(index)
	if material == null:
		stats.missing_material_slots += 1
	else:
		stats.materials[material.get_instance_id()] = true
	var uv: Variant = arrays[Mesh.ARRAY_TEX_UV]
	if uv == null or uv.size() != vertices.size():
		stats.missing_surface_uv += 1
	var standard := material as StandardMaterial3D
	if standard == null or standard.albedo_texture == null:
		stats.missing_albedo_texture_slots += 1


static func _xyz(vector: Vector3) -> Array[float]:
	return [vector.x, vector.y, vector.z]
