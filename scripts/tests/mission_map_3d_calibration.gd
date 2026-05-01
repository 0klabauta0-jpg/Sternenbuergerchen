extends "res://scripts/tests/mission_map_3d_render_spike.gd"

const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const CALIBRATION_OBJECTS: Array[Dictionary] = [
	{"grid": Vector2i(1, 1), "type_id": "deko_barrel_se", "category": "small_prop"},
	{"grid": Vector2i(3, 1), "type_id": "deko_barrels_nw", "category": "small_prop"},
	{"grid": Vector2i(5, 1), "type_id": "technik_generator_se", "category": "cover_prop"},
	{"grid": Vector2i(7, 1), "type_id": "technik_satellite_large_sw", "category": "tall_prop"},
	{"grid": Vector2i(9, 1), "type_id": "wall_straight_se", "category": "wall"},
	{"grid": Vector2i(11, 1), "type_id": "gebaeude_structure_closed_se", "category": "building"},
	{"grid": Vector2i(1, 4), "type_id": "gebaeude_hangar_small_b_sw", "category": "building"},
	{"grid": Vector2i(3, 4), "type_id": "plattform_center_se", "category": "platform"},
	{"grid": Vector2i(5, 4), "type_id": "pipe_straight_ne", "category": "flat_route"},
	{"grid": Vector2i(7, 4), "type_id": "rail_sw", "category": "flat_route"},
	{"grid": Vector2i(9, 4), "type_id": "crater_small_se", "category": "flat_decal"},
	{"grid": Vector2i(11, 4), "type_id": "fahrzeug_speeder_b_se", "category": "vehicle"},
]

@export var calibration_labels_enabled: bool = true
@export var calibration_footprints_enabled: bool = true
@export var calibration_pivots_enabled: bool = true
@export var calibration_label_height: float = 1.15
@export var calibration_label_font_size: int = 28

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

	for item in CALIBRATION_OBJECTS:
		var type_id: String = String(item.get("type_id", ""))
		var grid_position: Vector2i = item.get("grid", Vector2i.ZERO)
		var category: String = String(item.get("category", "object"))
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
			_add_footprint(footprint_container, type_id, base_position, float(renderer.call("get_grid_cell_size")), category)
		if calibration_pivots_enabled:
			_add_pivot_marker(pivot_container, type_id, object_position)
		if calibration_labels_enabled:
			_add_label(label_container, type_id, label_text, object_position + Vector3(0.0, calibration_label_height, 0.0), category)

		entries.append({
			"type_id": type_id,
			"grid_position": grid_position,
			"category": category,
			"model_key": model_key,
			"model_path": model_path,
			"model_exists": model_exists,
			"scale": scale,
			"y_offset": y_offset,
			"suffix_rotation_degrees": suffix_rotation,
			"rotation_offset_degrees": rotation_offset,
			"total_rotation_degrees": total_rotation,
		})

	calibration_snapshot = {
		"object_count": entries.size(),
		"entries": entries,
		"missing_model_paths": missing_model_paths,
		"labels_enabled": calibration_labels_enabled,
		"footprints_enabled": calibration_footprints_enabled,
		"pivots_enabled": calibration_pivots_enabled,
		"label_count": label_container.get_child_count(),
		"footprint_count": footprint_container.get_child_count(),
		"pivot_count": pivot_container.get_child_count(),
		"debug_grid_enabled": bool(get("show_debug_grid")),
	}


func _add_footprint(container: Node3D, type_id: String, position: Vector3, cell_size: float, category: String) -> void:
	var node := MeshInstance3D.new()
	node.name = "Footprint_%s" % type_id
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size * 0.92, 0.018, cell_size * 0.92)
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
		_:
			return Color(1.0, 1.0, 1.0, alpha)
