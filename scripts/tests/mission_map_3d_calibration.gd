extends "res://scripts/tests/mission_map_3d_render_spike.gd"

const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const NPC_REFERENCE_MODEL_PATH: String = "res://Assets/kenney_space-kit/Models/GLTF format/astronautA.glb"
const NPC_REFERENCE_GRID: Vector2i = Vector2i(12, 6)
const NPC_REFERENCE_HEIGHT: float = 0.88

const CALIBRATION_OBJECTS: Array[Dictionary] = [
	{"grid": Vector2i(1, 1), "type_id": "deko_barrel_se", "category": "small_prop"},
	{"grid": Vector2i(3, 1), "type_id": "deko_barrels_nw", "category": "small_prop"},
	{"grid": Vector2i(5, 1), "type_id": "technik_generator_se", "category": "cover_prop"},
	{"grid": Vector2i(7, 1), "type_id": "technik_satellite_large_sw", "category": "tall_prop", "footprint_size": Vector2(1.0, 1.0)},
	{"grid": Vector2i(9, 1), "type_id": "wall_straight_se", "category": "wall", "footprint_size": Vector2(1.0, 1.0)},
	{"grid": Vector2i(11, 1), "type_id": "gebaeude_structure_closed_se", "category": "building", "footprint_size": Vector2(1.0, 1.0)},
	{"grid": Vector2i(1, 4), "type_id": "gebaeude_hangar_small_b_sw", "category": "building", "footprint_size": Vector2(3.0, 3.0)},
	{"grid": Vector2i(3, 4), "type_id": "plattform_center_se", "category": "platform"},
	{"grid": Vector2i(5, 4), "type_id": "pipe_straight_ne", "category": "flat_route", "footprint_size": Vector2(1.0, 1.0)},
	{"grid": Vector2i(7, 4), "type_id": "rail_sw", "category": "flat_route"},
	{"grid": Vector2i(9, 4), "type_id": "crater_small_se", "category": "flat_decal"},
	{"grid": Vector2i(11, 4), "type_id": "fahrzeug_speeder_b_se", "category": "vehicle", "footprint_size": Vector2(4.0, 4.0)},
]

@export var calibration_labels_enabled: bool = true
@export var calibration_footprints_enabled: bool = true
@export var calibration_pivots_enabled: bool = true
@export var calibration_label_height: float = 1.15
@export var calibration_label_font_size: int = 28
@export var npc_reference_enabled: bool = true

var calibration_snapshot: Dictionary = {}


func render_map() -> Dictionary:
	var map_data = _build_calibration_map()
	var map_root := get_node_or_null("MapRoot") as Node3D
	if map_root == null:
		map_root = Node3D.new()
		map_root.name = "MapRoot"
		add_child(map_root)
	_renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	var debug_grid_enabled: bool = bool(get("show_debug_grid"))
	render_result = _renderer.call("render_map", map_data, map_root, {"show_debug_grid": debug_grid_enabled})
	_picker.call("configure_grid", float(_renderer.call("get_grid_cell_size")), float(_renderer.call("get_grid_height_step")))
	_build_calibration_helpers(map_data, _renderer, map_root)
	return render_result


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_G:
				set_debug_grid_enabled(not bool(get("show_debug_grid")))
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_L:
				set_calibration_labels_enabled(not calibration_labels_enabled)
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_F:
				set_calibration_footprints_enabled(not calibration_footprints_enabled)
				get_viewport().set_input_as_handled()
				return
	super._unhandled_input(event)


func set_calibration_labels_enabled(is_enabled: bool) -> void:
	calibration_labels_enabled = is_enabled
	render_map()
	_frame_camera_on_objects()


func set_calibration_footprints_enabled(is_enabled: bool) -> void:
	calibration_footprints_enabled = is_enabled
	calibration_pivots_enabled = is_enabled
	render_map()
	_frame_camera_on_objects()


func get_calibration_snapshot() -> Dictionary:
	return calibration_snapshot.duplicate(true)


func _build_calibration_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_134_3d_calibration", Vector2i(14, 8), Vector2.ZERO)
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	for item in CALIBRATION_OBJECTS:
		var grid_position: Vector2i = item.get("grid", Vector2i.ZERO)
		var tile_data = map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			continue
		var type_id: String = String(item.get("type_id", ""))
		if catalog != null and catalog.has_method("apply_type_to_tile") and catalog.call("apply_type_to_tile", tile_data, type_id):
			continue
		tile_data.object_type_id = type_id
	return map_data


func _build_calibration_helpers(map_data, renderer, map_root: Node3D) -> void:
	var helper_root := _ensure_container(map_root, "CalibrationHelpers3D")
	_clear_children(helper_root)

	var label_container := _ensure_container(helper_root, "Labels3D")
	var footprint_container := _ensure_container(helper_root, "Footprints3D")
	var pivot_container := _ensure_container(helper_root, "PivotMarkers3D")
	var entries: Array[Dictionary] = []
	var missing_model_paths: Array[String] = []
	var npc_reference: Dictionary = {}

	for item in CALIBRATION_OBJECTS:
		var type_id: String = String(item.get("type_id", ""))
		var grid_position: Vector2i = item.get("grid", Vector2i.ZERO)
		var category: String = String(item.get("category", "object"))
		var footprint_size: Vector2 = Vector2(item.get("footprint_size", Vector2.ONE))
		var tile_data = map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			continue
		var base_position: Vector3 = renderer.call("grid_to_world_3d_floor", grid_position, float(tile_data.floor_height))
		var object_position: Vector3 = base_position + Vector3(0.0, 0.04 + float(renderer.call("get_model_y_offset_for_type", type_id)), 0.0)
		var model_key: String = String(renderer.call("get_model_key_for_type", type_id))
		var model_entry: Dictionary = Dictionary(renderer.call("get_model_entry_for_type", type_id))
		var model_path: String = String(model_entry.get("model_path", ""))
		var model_exists: bool = not model_path.is_empty() and ResourceLoader.exists(model_path)
		if not model_exists:
			missing_model_paths.append("%s -> %s" % [type_id, model_path])

		var scale: float = float(renderer.call("get_model_scale_for_type", type_id))
		var y_offset: float = float(renderer.call("get_model_y_offset_for_type", type_id))
		var suffix_rotation: float = float(renderer.call("get_rotation_degrees_for_type", type_id))
		var rotation_offset: float = float(renderer.call("get_model_rotation_offset_degrees_for_type", type_id))
		var total_rotation: float = suffix_rotation + rotation_offset
		var label_text: String = "%s\nmodel: %s\nscale %.2f  y %.3f  rot %.0f" % [type_id, model_key, scale, y_offset, total_rotation]

		if calibration_footprints_enabled:
			_add_footprint(footprint_container, type_id, base_position, float(renderer.call("get_grid_cell_size")), category, footprint_size)
		if calibration_pivots_enabled:
			_add_pivot_marker(pivot_container, type_id, object_position)
		if calibration_labels_enabled:
			_add_label(label_container, type_id, label_text, object_position + Vector3(0.0, calibration_label_height, 0.0), category)

		entries.append({
			"type_id": type_id,
			"grid_position": grid_position,
			"category": category,
			"footprint_size": footprint_size,
			"model_key": model_key,
			"model_path": model_path,
			"model_exists": model_exists,
			"scale": scale,
			"y_offset": y_offset,
			"suffix_rotation_degrees": suffix_rotation,
			"rotation_offset_degrees": rotation_offset,
			"total_rotation_degrees": total_rotation,
		})

	if npc_reference_enabled:
		npc_reference = _add_npc_reference(helper_root, renderer)

	calibration_snapshot = {
		"object_count": entries.size(),
		"entries": entries,
		"missing_model_paths": missing_model_paths,
		"npc_reference": npc_reference,
		"npc_reference_enabled": npc_reference_enabled,
		"labels_enabled": calibration_labels_enabled,
		"footprints_enabled": calibration_footprints_enabled,
		"pivots_enabled": calibration_pivots_enabled,
		"label_count": label_container.get_child_count(),
		"footprint_count": footprint_container.get_child_count(),
		"pivot_count": pivot_container.get_child_count(),
		"debug_grid_enabled": bool(get("show_debug_grid")),
	}


func _add_npc_reference(helper_root: Node3D, renderer) -> Dictionary:
	var npc_container := _ensure_container(helper_root, "NPCReference3D")
	var reference_position: Vector3 = renderer.call("grid_to_world_3d_floor", NPC_REFERENCE_GRID, 0.0) + Vector3(0.0, 0.04, 0.0)
	var npc_node := _instantiate_npc_reference()
	var loaded_model: bool = npc_node != null
	if npc_node == null:
		npc_node = _create_fallback_npc_reference()
	npc_node.name = "NPCReference_Astronaut"
	npc_node.position = reference_position
	npc_container.add_child(npc_node)

	if calibration_footprints_enabled:
		_add_footprint(npc_container, "npc_reference", reference_position - Vector3(0.0, 0.04, 0.0), float(renderer.call("get_grid_cell_size")), "npc_reference", Vector2.ONE)
	if calibration_pivots_enabled:
		_add_pivot_marker(npc_container, "npc_reference", reference_position)
	if calibration_labels_enabled:
		_add_label(npc_container, "npc_reference", "NPC reference\nheight %.2f tile" % NPC_REFERENCE_HEIGHT, reference_position + Vector3(0.0, NPC_REFERENCE_HEIGHT + 0.35, 0.0), "npc_reference")

	return {
		"grid_position": NPC_REFERENCE_GRID,
		"model_path": NPC_REFERENCE_MODEL_PATH,
		"model_loaded": loaded_model,
		"target_height": NPC_REFERENCE_HEIGHT,
	}


func _instantiate_npc_reference() -> Node3D:
	if not ResourceLoader.exists(NPC_REFERENCE_MODEL_PATH):
		return null
	var scene := load(NPC_REFERENCE_MODEL_PATH) as PackedScene
	if scene == null:
		return null
	var model_node := scene.instantiate() as Node3D
	if model_node == null:
		return null
	var wrapper := Node3D.new()
	wrapper.add_child(model_node)
	model_node.rotation_degrees.y = 180.0
	_center_and_scale_reference_node(model_node, NPC_REFERENCE_HEIGHT)
	return wrapper


func _create_fallback_npc_reference() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	body.name = "FallbackNPCBody"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.13
	mesh.height = NPC_REFERENCE_HEIGHT
	body.mesh = mesh
	body.position.y = NPC_REFERENCE_HEIGHT * 0.5
	body.material_override = _make_calibration_material(Color(0.2, 0.72, 1.0, 1.0))
	root.add_child(body)
	return root


func _center_and_scale_reference_node(node: Node3D, target_height: float) -> void:
	var bounds: Dictionary = _get_local_visual_bounds(node)
	if not bool(bounds.get("valid", false)):
		return
	var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
	var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
	var center: Vector3 = (min_value + max_value) * 0.5
	var source_height: float = maxf(max_value.y - min_value.y, 0.001)
	var scale_factor: float = target_height / source_height
	node.scale = Vector3.ONE * scale_factor
	node.position = Vector3(-center.x * scale_factor, -min_value.y * scale_factor, -center.z * scale_factor)


func _get_local_visual_bounds(node: Node3D) -> Dictionary:
	var bounds: Dictionary = {
		"valid": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_local_visual_bounds(node, Transform3D.IDENTITY, bounds)
	return bounds


func _accumulate_local_visual_bounds(node: Node, parent_transform: Transform3D, bounds: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		_merge_transformed_aabb(bounds, current_transform, mesh_instance.get_aabb())
	for child in node.get_children():
		_accumulate_local_visual_bounds(child, current_transform, bounds)


func _merge_transformed_aabb(bounds: Dictionary, transform: Transform3D, aabb: AABB) -> void:
	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	for corner in corners:
		var transformed_corner: Vector3 = transform * corner
		if not bool(bounds.get("valid", false)):
			bounds["valid"] = true
			bounds["min"] = transformed_corner
			bounds["max"] = transformed_corner
			continue
		var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
		var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
		bounds["min"] = Vector3(
			minf(min_value.x, transformed_corner.x),
			minf(min_value.y, transformed_corner.y),
			minf(min_value.z, transformed_corner.z)
		)
		bounds["max"] = Vector3(
			maxf(max_value.x, transformed_corner.x),
			maxf(max_value.y, transformed_corner.y),
			maxf(max_value.z, transformed_corner.z)
		)


func _add_footprint(container: Node3D, type_id: String, position: Vector3, cell_size: float, category: String, footprint_size: Vector2 = Vector2.ONE) -> void:
	var node := MeshInstance3D.new()
	node.name = "Footprint_%s" % type_id
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size * 0.92 * footprint_size.x, 0.018, cell_size * 0.92 * footprint_size.y)
	node.mesh = mesh
	node.position = position + Vector3(0.0, 0.075, 0.0)
	node.material_override = _make_calibration_material(_get_category_color(category, 0.32))
	container.add_child(node)


func _add_pivot_marker(container: Node3D, type_id: String, position: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.name = "Pivot_%s" % type_id
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	node.mesh = mesh
	node.position = position + Vector3(0.0, 0.08, 0.0)
	node.material_override = _make_calibration_material(Color(1.0, 0.88, 0.18, 0.92))
	container.add_child(node)


func _add_label(container: Node3D, type_id: String, text: String, position: Vector3, category: String) -> void:
	var label := Label3D.new()
	label.name = "Label_%s" % type_id
	label.text = text
	label.font_size = calibration_label_font_size
	label.modulate = _get_category_color(category, 1.0)
	label.outline_size = 10
	label.outline_modulate = Color(0.02, 0.025, 0.03, 0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = position
	container.add_child(label)


func _ensure_container(parent: Node3D, node_name: String) -> Node3D:
	var container := parent.get_node_or_null(node_name) as Node3D
	if container != null:
		return container
	container = Node3D.new()
	container.name = node_name
	parent.add_child(container)
	return container


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _make_calibration_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.8
	return material


func _get_category_color(category: String, alpha: float) -> Color:
	match category:
		"small_prop":
			return Color(0.25, 0.78, 1.0, alpha)
		"cover_prop":
			return Color(0.38, 0.92, 0.55, alpha)
		"tall_prop":
			return Color(0.96, 0.72, 0.25, alpha)
		"wall":
			return Color(0.72, 0.78, 0.86, alpha)
		"building":
			return Color(0.98, 0.52, 0.42, alpha)
		"platform":
			return Color(0.62, 0.55, 1.0, alpha)
		"flat_route":
			return Color(0.58, 0.95, 0.88, alpha)
		"flat_decal":
			return Color(0.82, 0.76, 0.58, alpha)
		"vehicle":
			return Color(1.0, 0.42, 0.78, alpha)
		"npc_reference":
			return Color(0.2, 0.72, 1.0, alpha)
		_:
			return Color(1.0, 1.0, 1.0, alpha)
