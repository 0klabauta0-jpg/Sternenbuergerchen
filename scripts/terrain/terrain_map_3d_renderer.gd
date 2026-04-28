class_name TerrainMap3DRenderer
extends RefCounted

const DEFAULT_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _mapping: Dictionary = {}
var _model_cache: Dictionary = {}
var _ground_mesh: BoxMesh = null
var _ground_material: StandardMaterial3D = null
var _ground_material_alt: StandardMaterial3D = null
var _show_debug_grid: bool = true


func _init(mapping_path: String = DEFAULT_MAPPING_PATH) -> void:
	_mapping = load_mapping(mapping_path)
	_prepare_ground_resources()


static func load_mapping(path: String = DEFAULT_MAPPING_PATH) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func render_map(terrain_map_data, map_root: Node3D, options: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"terrain": {},
		"objects": {},
		"stats": {
			"terrain_count": 0,
			"object_count": 0,
			"missing_models": [],
			"object_focus": Vector3.ZERO,
		},
	}
	if terrain_map_data == null or map_root == null:
		return result
	_show_debug_grid = bool(options.get("show_debug_grid", true))
	_prepare_ground_resources()

	var terrain_container := _ensure_container(map_root, "Terrain3D")
	var object_container := _ensure_container(map_root, "Object3D")
	_clear_children(terrain_container)
	_clear_children(object_container)

	var object_focus_sum := Vector3.ZERO
	var object_focus_count: int = 0
	for tile_data in terrain_map_data.call("get_tiles"):
		var terrain_node := _create_ground_tile(tile_data)
		terrain_container.add_child(terrain_node)
		result["terrain"][tile_data.grid_position] = terrain_node
		result["stats"]["terrain_count"] = int(result["stats"].get("terrain_count", 0)) + 1

		var object_type_id: String = get_tile_object_type_id(tile_data)
		if object_type_id.is_empty():
			continue
		var object_node := _instantiate_model_for_type(object_type_id)
		if object_node == null:
			var missing_models: Array = Array(result["stats"].get("missing_models", []))
			if not missing_models.has(object_type_id):
				missing_models.append(object_type_id)
			result["stats"]["missing_models"] = missing_models
			continue
		object_node.name = "Object_%s_%d_%d" % [object_type_id, tile_data.grid_position.x, tile_data.grid_position.y]
		var object_position: Vector3 = grid_to_world_3d_floor(tile_data.grid_position, float(tile_data.floor_height)) + Vector3(0.0, _get_object_y_offset() + get_model_y_offset_for_type(object_type_id), 0.0)
		object_node.position = object_position
		object_node.rotation.y = deg_to_rad(get_rotation_degrees_for_type(object_type_id) + get_model_rotation_offset_degrees_for_type(object_type_id))
		var object_scale: float = get_model_scale_for_type(object_type_id)
		object_node.scale = Vector3.ONE * object_scale
		object_container.add_child(object_node)
		result["objects"][tile_data.grid_position] = object_node
		result["stats"]["object_count"] = int(result["stats"].get("object_count", 0)) + 1
		object_focus_sum += object_position
		object_focus_count += 1

	if object_focus_count > 0:
		result["stats"]["object_focus"] = object_focus_sum / float(object_focus_count)

	return result


func grid_to_world_3d(grid_position: Vector2i, height_level: int = 0) -> Vector3:
	var cell_size: float = _get_grid_number("cell_size", 2.0)
	var height_step: float = _get_grid_number("height_step", 0.35)
	return Vector3(float(grid_position.x) * cell_size, float(height_level) * height_step, float(grid_position.y) * cell_size)


func grid_to_world_3d_floor(grid_position: Vector2i, floor_height: float = 0.0) -> Vector3:
	var cell_size: float = _get_grid_number("cell_size", 2.0)
	var height_step: float = _get_grid_number("height_step", 0.35)
	return Vector3(float(grid_position.x) * cell_size, floor_height * height_step, float(grid_position.y) * cell_size)


func world_3d_to_grid(world_position: Vector3) -> Vector2i:
	var cell_size: float = _get_grid_number("cell_size", 2.0)
	return Vector2i(roundi(world_position.x / cell_size), roundi(world_position.z / cell_size))


func get_grid_cell_size() -> float:
	return _get_grid_number("cell_size", 2.0)


func get_grid_height_step() -> float:
	return _get_grid_number("height_step", 0.35)


func get_tile_object_type_id(tile_data) -> String:
	if tile_data == null:
		return ""
	var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	if not object_type_id.is_empty():
		return object_type_id
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	return type_id if _is_mapped_object_type(type_id) else ""


func get_model_entry_for_type(type_id: String) -> Dictionary:
	var model_key: String = get_model_key_for_type(type_id)
	if model_key.is_empty():
		return {}
	return Dictionary(Dictionary(_mapping.get("models", {})).get(model_key, {}))


func get_model_key_for_type(type_id: String) -> String:
	var normalized: String = type_id.strip_edges()
	if normalized.is_empty():
		return ""
	var models: Dictionary = Dictionary(_mapping.get("models", {}))
	if models.has(normalized):
		return normalized
	var without_direction: String = _strip_direction_suffix(normalized)
	if models.has(without_direction):
		return without_direction
	return ""


func get_rotation_degrees_for_type(type_id: String) -> float:
	match _extract_direction_suffix(type_id):
		"ne":
			return 0.0
		"se":
			return 90.0
		"sw":
			return 180.0
		"nw":
			return 270.0
		_:
			return 0.0


func get_model_scale_for_type(type_id: String) -> float:
	var entry: Dictionary = get_model_entry_for_type(type_id)
	return float(entry.get("scale", _get_grid_number("default_object_scale", 1.0)))


func get_model_y_offset_for_type(type_id: String) -> float:
	var entry: Dictionary = get_model_entry_for_type(type_id)
	return float(entry.get("y_offset", 0.0))


func get_model_rotation_offset_degrees_for_type(type_id: String) -> float:
	var entry: Dictionary = get_model_entry_for_type(type_id)
	return float(entry.get("rotation_degrees_offset", 0.0))


func get_mapping_summary() -> Dictionary:
	var models: Dictionary = Dictionary(_mapping.get("models", {}))
	var existing_model_count: int = 0
	var missing_model_paths: Array[String] = []
	for model_key in models.keys():
		var model_path: String = String(Dictionary(models.get(model_key, {})).get("model_path", ""))
		if not model_path.is_empty() and ResourceLoader.exists(model_path):
			existing_model_count += 1
		else:
			missing_model_paths.append("%s -> %s" % [model_key, model_path])
	return {
		"model_count": models.size(),
		"existing_model_count": existing_model_count,
		"missing_model_paths": missing_model_paths,
		"source": Dictionary(_mapping.get("source", {})),
	}


func _create_ground_tile(tile_data) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Ground_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
	node.mesh = _ground_mesh
	node.material_override = _ground_material if not _show_debug_grid or (tile_data.grid_position.x + tile_data.grid_position.y) % 2 == 0 else _ground_material_alt
	node.position = grid_to_world_3d_floor(tile_data.grid_position, float(tile_data.floor_height))
	return node


func _instantiate_model_for_type(type_id: String) -> Node3D:
	var entry: Dictionary = get_model_entry_for_type(type_id)
	var model_path: String = String(entry.get("model_path", ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return null
	var scene: PackedScene = _model_cache.get(model_path, null) as PackedScene
	if scene == null:
		scene = load(model_path) as PackedScene
		if scene == null:
			return null
		_model_cache[model_path] = scene
	var node := scene.instantiate() as Node3D
	return node


func _is_mapped_object_type(type_id: String) -> bool:
	var entry: Dictionary = get_model_entry_for_type(type_id)
	var layer: String = String(entry.get("layer", "")).strip_edges().to_lower()
	return layer == "object" or layer == "terrain_object"


func _ensure_container(map_root: Node3D, node_name: String) -> Node3D:
	var container := map_root.get_node_or_null(node_name) as Node3D
	if container != null:
		return container
	container = Node3D.new()
	container.name = node_name
	map_root.add_child(container)
	return container


func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


func _prepare_ground_resources() -> void:
	_ground_mesh = BoxMesh.new()
	var cell_size: float = _get_grid_number("cell_size", 2.0)
	var ground_fill_key: String = "ground_fill" if _show_debug_grid else "ground_fill_no_grid"
	var ground_fill: float = clampf(_get_grid_number(ground_fill_key, 0.92), 0.1, 1.0)
	var ground_thickness: float = _get_grid_number("ground_thickness", 0.08)
	_ground_mesh.size = Vector3(cell_size * ground_fill, ground_thickness, cell_size * ground_fill)
	_ground_material = StandardMaterial3D.new()
	_ground_material.albedo_color = Color(0.28, 0.33, 0.37, 1.0)
	_ground_material.roughness = 0.85
	_ground_material_alt = StandardMaterial3D.new()
	_ground_material_alt.albedo_color = Color(0.33, 0.38, 0.42, 1.0)
	_ground_material_alt.roughness = 0.85


func _get_grid_number(key: String, fallback: float) -> float:
	return float(Dictionary(_mapping.get("grid", {})).get(key, fallback))


func _get_object_y_offset() -> float:
	return _get_grid_number("object_y_offset", 0.08)


func _strip_direction_suffix(type_id: String) -> String:
	var direction: String = _extract_direction_suffix(type_id)
	if direction.is_empty():
		return type_id
	return type_id.substr(0, type_id.length() - direction.length() - 1)


func _extract_direction_suffix(type_id: String) -> String:
	for direction in ["ne", "nw", "se", "sw"]:
		if type_id.ends_with("_%s" % direction):
			return direction
	return ""
