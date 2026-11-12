extends RefCounted
## Immutable static visual resources for one explicit map lifetime.
## No Nodes, FoW, actors or gameplay state are retained. Restores stay hidden.
const CONTEXT_FIELDS := ["map_id", "terrain_revision", "art_revision", "grid_revision"]
const RENDER_METADATA := ["visual_family", "replaces_legacy_visual", "frontier_geology_kind", "erosion_channel_count", "relief_outer_local_y"]
# Inspected build-only geology creates meshes and has no runtime callbacks.
# The script itself is never copied to restored nodes.
const STATIC_BUILD_ONLY_SCRIPTS := ["res://scripts/terrain/frontier_art_geology.gd"]
const GEOMETRY_PROPERTIES := ["material_override", "material_overlay", "cast_shadow", "gi_mode", "layers", "transparency", "extra_cull_margin", "custom_aabb", "ignore_occlusion_culling", "lod_bias", "visibility_range_begin", "visibility_range_end", "visibility_range_begin_margin", "visibility_range_end_margin", "visibility_range_fade_mode", "sorting_offset", "sorting_use_aabb_center"]
var _context: Dictionary = {}
var _context_fingerprint := ""
var _expected: Dictionary = {}
var _chunks: Dictionary = {}
var _resources: Dictionary = {}
var _budget_bytes := 0
var _geometry_bytes := 0
var _descriptor_bytes := 0
var _last_rejection := ""

func begin_map(context: Dictionary, expected_chunks: Array, max_payload_bytes: int) -> Dictionary:
	if context.size() != CONTEXT_FIELDS.size(): return _reject("invalid_map_context")
	for field: String in CONTEXT_FIELDS:
		if not context.get(field) is String or String(context[field]).is_empty():
			return _reject("invalid_map_context")
	if max_payload_bytes <= 0 or expected_chunks.is_empty(): return _reject("invalid_cache_budget_or_chunk_set")
	var expected := {}
	for chunk: Variant in expected_chunks:
		if not chunk is Vector2i or expected.has(chunk): return _reject("invalid_chunk_set")
		expected[chunk] = true
	var signature := JSON.stringify(context, "", true).sha256_text()
	if signature == _context_fingerprint and expected == _expected and max_payload_bytes == _budget_bytes:
		return {"ok": true, "unchanged": true}
	clear()
	_context = context.duplicate(true)
	_context_fingerprint = signature
	_expected = expected
	_budget_bytes = max_payload_bytes
	return {"ok": true, "unchanged": false}

func clear() -> void:
	_context.clear()
	_context_fingerprint = ""
	_expected.clear()
	_chunks.clear()
	_resources.clear()
	_budget_bytes = 0
	_geometry_bytes = 0
	_descriptor_bytes = 0
	_last_rejection = ""

func is_ready() -> bool:
	return not _expected.is_empty() and _chunks.size() == _expected.size()

func capture_chunk(chunk_id: Vector2i, source: Node3D, render_counts: Vector3i = Vector3i.ZERO) -> Dictionary:
	if _context_fingerprint.is_empty() or not _expected.has(chunk_id): return _reject("chunk_outside_map_lifetime")
	if _chunks.has(chunk_id): return {"ok": true, "unchanged": true}
	if not is_instance_valid(source): return _reject("missing_static_chunk")
	var description := _describe(source, true)
	if not description.ok: return _reject(description.reason)
	var descriptor: Dictionary = description.descriptor
	var additions := {}
	_collect_geometry_resources(descriptor, additions)
	if additions.is_empty(): return _reject("empty_static_chunk")
	var new_geometry := 0
	for id: int in additions:
		if not _resources.has(id): new_geometry += _resource_payload_bytes(additions[id])
	var packed := var_to_bytes(_fingerprint_values(descriptor))
	var new_descriptor := packed.size()
	if _geometry_bytes + _descriptor_bytes + new_geometry + new_descriptor > _budget_bytes:
		return _reject("resource_payload_budget_exceeded")
	for id: int in additions:
		if not _resources.has(id): _resources[id] = additions[id]
	_geometry_bytes += new_geometry
	_descriptor_bytes += new_descriptor
	_chunks[chunk_id] = {"descriptor": descriptor, "fingerprint": packed.hex_encode().sha256_text(), "render_counts": render_counts}
	_last_rejection = ""
	return {"ok": true, "unchanged": false, "geometry_payload_bytes_added": new_geometry, "descriptor_payload_bytes_added": new_descriptor}

func instantiate_chunk(chunk_id: Vector2i) -> Node3D:
	if not _chunks.has(chunk_id): return null
	var result := _instantiate(Dictionary(_chunks[chunk_id].descriptor))
	# The existing view alone decides when a chunk has valid FoW and may show.
	result.hide()
	return result

func get_chunk_render_counts(chunk_id: Vector2i) -> Vector3i:
	return _chunks.get(chunk_id, {}).get("render_counts", Vector3i.ZERO)

func has_chunk(chunk_id: Vector2i) -> bool:
	return _chunks.has(chunk_id)

func get_chunk_descriptor(chunk_id: Vector2i) -> Dictionary:
	return Dictionary(_chunks.get(chunk_id, {}).get("descriptor", {})).duplicate(true)

func static_fingerprint(source: Node3D) -> String:
	if not is_instance_valid(source): return ""
	var result := _describe(source, true)
	if not result.ok: return ""
	return var_to_bytes(_fingerprint_values(result.descriptor)).hex_encode().sha256_text()

func get_debug_snapshot() -> Dictionary:
	return {"context_fingerprint": _context_fingerprint, "expected_chunks": _expected.size(), "cached_chunks": _chunks.size(), "ready": is_ready(), "progress": float(_chunks.size()) / maxi(_expected.size(), 1), "retained_payload_bytes": _geometry_bytes + _descriptor_bytes, "geometry_payload_bytes": _geometry_bytes, "descriptor_payload_bytes": _descriptor_bytes, "max_payload_bytes": _budget_bytes, "geometry_resource_count": _resources.size(), "retained_scene_nodes": 0, "last_rejection": _last_rejection, "payload_is_total_ram_or_vram": false, "multimesh_byte_basis": "configured_buffer_capacity; headless readback unavailable"}

func _reject(reason: String) -> Dictionary:
	_last_rejection = reason
	return {"ok": false, "reason": reason}

func _describe(node: Node, is_root: bool) -> Dictionary:
	if not node is Node3D: return {"ok": false, "reason": "unsupported_static_node"}
	if node.get_script() != null:
		var script := node.get_script() as Script
		if script.resource_path not in STATIC_BUILD_ONLY_SCRIPTS or node.is_processing() or node.is_physics_processing() or node.is_processing_input():
			return {"ok": false, "reason": "scripted_content_not_static"}
	var metadata := {}
	for key: StringName in node.get_meta_list():
		if String(key) not in RENDER_METADATA or typeof(node.get_meta(key)) not in [TYPE_STRING, TYPE_INT, TYPE_FLOAT]:
			return {"ok": false, "reason": "unsupported_static_metadata:" + String(key)}
		metadata[String(key)] = node.get_meta(key)
	var lower := String(node.name).to_lower()
	for dynamic_name in ["fog", "fow", "unitvisual", "interaction", "contactmarker"]:
		if lower.contains(dynamic_name): return {"ok": false, "reason": "dynamic_projection_not_static"}
	if node.top_level or not node.visibility_parent.is_empty(): return {"ok": false, "reason": "external_transform_or_visibility_owner"}
	var kind := String(node.get_class())
	if kind not in ["Node3D", "MeshInstance3D", "MultiMeshInstance3D"]:
		return {"ok": false, "reason": "unsupported_static_node"}
	var record := {"kind": kind, "name": String(node.name).validate_node_name(), "transform": node.transform, "visible": false if is_root else node.visible, "children": [], "render_metadata": metadata}
	if node is MeshInstance3D:
		if node.skin != null: return {"ok": false, "reason": "skinned_content_not_static"}
		record.mesh = node.mesh
		record.surface_overrides = []
		if node.mesh != null:
			for surface in node.mesh.get_surface_count():
				var arrays: Array = node.mesh.surface_get_arrays(surface)
				if arrays[Mesh.ARRAY_BONES] != null and arrays[Mesh.ARRAY_BONES].size() > 0:
					return {"ok": false, "reason": "skinned_content_not_static"}
				record.surface_overrides.append(node.get_surface_override_material(surface))
	elif node is MultiMeshInstance3D:
		record.multimesh = node.multimesh
	if node is GeometryInstance3D:
		var available := {}
		for property: Dictionary in node.get_property_list(): available[String(property.name)] = true
		var flags := {}
		for property: String in GEOMETRY_PROPERTIES:
			if available.has(property): flags[property] = node.get(property)
		record.flags = flags
	for child: Node in node.get_children():
		var result := _describe(child, false)
		if not result.ok: return result
		record.children.append(result.descriptor)
	return {"ok": true, "descriptor": record}

func _instantiate(record: Dictionary) -> Node3D:
	var node: Node3D
	match record.kind:
		"MeshInstance3D":
			node = MeshInstance3D.new()
			node.mesh = record.mesh
			for index in record.surface_overrides.size(): node.set_surface_override_material(index, record.surface_overrides[index])
		"MultiMeshInstance3D":
			node = MultiMeshInstance3D.new()
			node.multimesh = record.multimesh
		_: node = Node3D.new()
	node.name = record.name
	node.transform = record.transform
	node.visible = record.visible
	for key: String in record.render_metadata: node.set_meta(key, record.render_metadata[key])
	for property: String in Dictionary(record.get("flags", {})): node.set(property, record.flags[property])
	for child: Dictionary in record.children: node.add_child(_instantiate(child))
	return node

func _collect_geometry_resources(record: Dictionary, result: Dictionary) -> void:
	var mesh := record.get("mesh") as Mesh
	if mesh != null: result[mesh.get_instance_id()] = mesh
	var multimesh := record.get("multimesh") as MultiMesh
	if multimesh != null:
		result[multimesh.get_instance_id()] = multimesh
		if multimesh.mesh != null: result[multimesh.mesh.get_instance_id()] = multimesh.mesh
	for child: Dictionary in record.children: _collect_geometry_resources(child, result)

func _resource_payload_bytes(resource: Resource) -> int:
	if resource is MultiMesh:
		# Configured packed buffer capacity, not total engine/driver allocation.
		var floats := 12 if resource.transform_format == MultiMesh.TRANSFORM_3D else 8
		floats += 4 if resource.use_colors else 0
		floats += 4 if resource.use_custom_data else 0
		return resource.instance_count * floats * 4
	if resource is Mesh:
		var total := 0
		for surface in resource.get_surface_count(): total += var_to_bytes(resource.surface_get_arrays(surface)).size()
		return total
	return 0

func _fingerprint_values(value: Variant) -> Variant:
	# Resource identity is deliberate: restores reuse buffers, not serialization.
	if value is Resource: return {"resource_id": value.get_instance_id(), "kind": value.get_class()}
	if value is Dictionary:
		var result := {}
		for key: Variant in value: result[key] = _fingerprint_values(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_fingerprint_values(item))
		return result
	return value
