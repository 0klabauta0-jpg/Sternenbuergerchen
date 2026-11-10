class_name MapBuilderSceneImporter
extends RefCounted

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const BUILDINGS = preload("res://scripts/editor/building_layout_authoring.gd")

const DEFAULT_MAP_NAME: String = "map_builder_import"
const DEFAULT_GRID_SIZE: Vector2i = Vector2i(8, 8)
const DEFAULT_GRID_ORIGIN: Vector2 = Vector2.ZERO
const DEFAULT_HALF_TILE_WIDTH: float = 64.0
const DEFAULT_HALF_TILE_HEIGHT: float = 32.0

const META_TYPE_KEYS: PackedStringArray = [
	"sb_type_id",
	"terrain_type_id",
	"type_id",
]
const META_GRID_KEYS: PackedStringArray = [
	"sb_grid_position",
	"grid_position",
	"grid",
]
const META_ROTATION_KEYS: PackedStringArray = [
	"sb_rotation_degrees",
	"object_rotation_degrees",
	"rotation_degrees",
	"rotation_y_degrees",
]
const META_SCALE_KEYS: PackedStringArray = [
	"sb_object_scale",
	"object_scale",
	"placement_scale",
	"scale",
]


func build_map_from_authoring(authoring: Dictionary) -> Dictionary:
	var catalog = _get_catalog(authoring)
	var placements: Array = _normalize_placements(Array(authoring.get("placements", [])))
	var grid_size: Vector2i = _coerce_grid_size(authoring.get("grid_size", Vector2i.ZERO), placements)
	var map_name: String = String(authoring.get("map_name", DEFAULT_MAP_NAME)).strip_edges()
	if map_name.is_empty():
		map_name = DEFAULT_MAP_NAME
	var grid_origin: Vector2 = _coerce_vector2(authoring.get("grid_origin", DEFAULT_GRID_ORIGIN))
	var half_tile_width: float = maxf(float(authoring.get("half_tile_width", DEFAULT_HALF_TILE_WIDTH)), 0.001)
	var half_tile_height: float = maxf(float(authoring.get("half_tile_height", DEFAULT_HALF_TILE_HEIGHT)), 0.001)
	var mission_slot_count: int = maxi(int(authoring.get("mission_slot_count", 3)), 1)
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call(
		"create_empty",
		map_name,
		grid_size,
		grid_origin,
		half_tile_width,
		half_tile_height,
		mission_slot_count
	)
	if map_data == null:
		return _make_result(false, null, ["Could not create TerrainMapData"], [], {})
	var theme_id: String = String(authoring.get("terrain_visual_theme_id", "")).strip_edges()
	if not theme_id.is_empty() and map_data.has_method("set_terrain_visual_theme_id"):
		map_data.call("set_terrain_visual_theme_id", theme_id)

	return _apply_placements_to_map(map_data, placements, catalog)


func build_map_from_nodes(root: Node, options: Dictionary = {}) -> Dictionary:
	if root == null:
		return _make_result(false, null, ["Missing authoring root node"], [], {})
	var placements: Array = []
	_collect_node_placements(root, placements)
	var authoring: Dictionary = options.duplicate(true)
	authoring["placements"] = placements
	return build_map_from_authoring(authoring)


func build_map_from_scene_authoring(grid_map: GridMap, item_type_map: Dictionary, node_root: Node, options: Dictionary = {}) -> Dictionary:
	var placements: Array = []
	if grid_map != null:
		placements.append_array(_collect_grid_map_placements(grid_map, item_type_map, options))
	if node_root != null:
		_collect_node_placements(node_root, placements)
	var authoring: Dictionary = options.duplicate(true)
	authoring["placements"] = placements
	return build_map_from_authoring(authoring)


func build_map_from_grid_map(grid_map: GridMap, item_type_map: Dictionary, options: Dictionary = {}) -> Dictionary:
	if grid_map == null:
		return _make_result(false, null, ["Missing GridMap node"], [], {})
	var placements: Array = []
	placements.append_array(_collect_grid_map_placements(grid_map, item_type_map, options))
	var authoring: Dictionary = options.duplicate(true)
	authoring["placements"] = placements
	return build_map_from_authoring(authoring)


func summarize_tooling_recommendation() -> Dictionary:
	return {
		"recommended_path": "gridmap_meshlibrary_plus_asset_placer_style_nodes",
		"grid_authoring": "Use Godot GridMap/MeshLibrary for modular terrain, roads, water, walls and doors.",
		"prop_authoring": "Use an Asset-Placer-style workflow for buildings, vehicles, props and decoration.",
		"gameplay_truth": "Compile authoring placements into TerrainMapData; do not read plugin scene state at runtime.",
		"plugin_candidate": "Godot Asset Placer 1.4.0, MIT, Godot 4.3+, installed in TASK_487 for editor authoring only.",
		"workbench": "TASK_488 provides a small GridMap/MeshLibrary workbench scene plus Asset-Placer-compatible prop metadata.",
		"known_limitation": "TerrainTileData currently stores one rotation and one scale per tile, so layered floor/object transforms cannot be independent yet.",
	}


func _apply_placements_to_map(map_data, placements: Array, catalog) -> Dictionary:
	var issues: Array[String] = []
	var warnings: Array[String] = []
	var stats: Dictionary = {
		"placement_count": placements.size(),
		"applied_count": 0,
		"skipped_count": 0,
		"terrain_count": 0,
		"structure_count": 0,
		"object_count": 0,
		"warning_count": 0,
	}
	var transform_owner_by_grid: Dictionary = {}
	var building_placements: Array=[]
	placements.sort_custom(_sort_placements)
	for placement_variant in placements:
		var placement: Dictionary = Dictionary(placement_variant)
		var type_id: String = _normalize_type_id(String(placement.get("type_id", "")))
		if type_id.is_empty():
			if placement.has("missing_item_id"):
				issues.append("GridMap item %d has no type_id mapping" % int(placement.get("missing_item_id", -1)))
			else:
				issues.append("Placement is missing type_id")
			stats["skipped_count"] = int(stats.get("skipped_count", 0)) + 1
			continue
		if catalog == null or not catalog.has_method("has_type") or not bool(catalog.call("has_type", type_id)):
			issues.append("Unknown map builder type_id: %s" % type_id)
			stats["skipped_count"] = int(stats.get("skipped_count", 0)) + 1
			continue
		if not bool(Dictionary(catalog.get_type(type_id)).get("palette_visible", true)):
			issues.append("Building %s requires multi-cell layout authoring; single-cell compilation is unavailable." % type_id)
			stats["skipped_count"] = int(stats.get("skipped_count", 0)) + 1
			continue
		if BUILDINGS.supported(type_id):
			building_placements.append(placement)
			continue
		var grid_position: Vector2i = _coerce_grid_position(placement.get("grid_position", Vector2i(-1, -1)))
		var tile_data = map_data.call("get_tile_at_grid", grid_position) if map_data != null else null
		if tile_data == null:
			issues.append("Placement %s is outside the map at %d,%d" % [type_id, grid_position.x, grid_position.y])
			stats["skipped_count"] = int(stats.get("skipped_count", 0)) + 1
			continue
		if not bool(catalog.call("apply_type_to_tile", tile_data, type_id)):
			issues.append("Could not apply map builder type_id: %s" % type_id)
			stats["skipped_count"] = int(stats.get("skipped_count", 0)) + 1
			continue
		_apply_authoring_overrides(tile_data, placement, type_id, transform_owner_by_grid, warnings)
		_increment_layer_stat(stats, type_id, catalog)
		stats["applied_count"] = int(stats.get("applied_count", 0)) + 1
	for placement in building_placements:
		var request: Dictionary=BUILDINGS.plan(map_data,"place",{"asset_id":String(placement.type_id),"grid":Vector2i(placement.grid_position),"scale":_normalize_object_scale(_coerce_scale_value(placement.get("object_scale",placement.get("scale",1.0)))),"rotation_degrees":placement.get("rotation_degrees",placement.get("object_rotation_degrees",0.0))})
		if not bool(request.get("ok",false)):
			issues.append(String(request.get("error","Building placement rejected")))
			stats.skipped_count+=1
			continue
		BUILDINGS.apply(map_data,request)
		stats.applied_count+=1; stats.object_count+=1
	stats["warning_count"] = warnings.size()
	return _make_result(issues.is_empty(), map_data, issues, warnings, stats)


func _normalize_placements(raw_placements: Array) -> Array:
	var placements: Array = []
	for placement_variant in raw_placements:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = Dictionary(placement_variant).duplicate(true)
		placement["type_id"] = _normalize_type_id(String(placement.get("type_id", "")))
		placement["grid_position"] = _coerce_grid_position(placement.get("grid_position", Vector2i.ZERO))
		placement["_layer_order"] = _get_layer_order_for_type_id(String(placement.get("type_id", "")))
		placements.append(placement)
	return placements


func _collect_node_placements(node: Node, placements: Array) -> void:
	var type_id: String = _read_string_meta(node, META_TYPE_KEYS)
	if not type_id.is_empty():
		var placement: Dictionary = {
			"type_id": type_id,
			"grid_position": _read_grid_meta(node),
		}
		var rotation_value: Variant = _read_first_meta(node, META_ROTATION_KEYS)
		if rotation_value != null:
			placement["rotation_degrees"] = float(rotation_value)
		elif node is Node3D:
			placement["rotation_degrees"] = (node as Node3D).rotation_degrees.y
		var scale_value: Variant = _read_first_meta(node, META_SCALE_KEYS)
		if scale_value != null:
			placement["object_scale"] = _coerce_scale_value(scale_value)
		elif node is Node3D:
			placement["object_scale"] = _coerce_scale_value((node as Node3D).scale)
		placements.append(placement)
	for child in node.get_children():
		_collect_node_placements(child, placements)


func _collect_grid_map_placements(grid_map: GridMap, item_type_map: Dictionary, options: Dictionary) -> Array:
	var placements: Array = []
	var use_cell_y_as_height: bool = bool(options.get("use_cell_y_as_height", true))
	for cell_variant in grid_map.get_used_cells():
		var cell: Vector3i = Vector3i(cell_variant)
		var item_id: int = int(grid_map.get_cell_item(cell))
		if item_id < 0:
			continue
		var item_mapping: Variant = item_type_map.get(item_id, "")
		var placement: Dictionary = _placement_from_grid_item(cell, item_id, item_mapping)
		if placement.is_empty():
			placement = {
				"grid_position": Vector2i(cell.x, cell.z),
				"missing_item_id": item_id,
			}
		if use_cell_y_as_height and not placement.has("height_level"):
			placement["height_level"] = cell.y
		var orientation: int = int(grid_map.get_cell_item_orientation(cell))
		if orientation != 0:
			placement["gridmap_orientation"] = orientation
			if not placement.has("rotation_degrees"):
				placement["rotation_degrees"] = _rotation_degrees_from_grid_map_orientation(grid_map, orientation)
		placements.append(placement)
	return placements


func _placement_from_grid_item(cell: Vector3i, item_id: int, item_mapping: Variant) -> Dictionary:
	var placement: Dictionary = {
		"grid_position": Vector2i(cell.x, cell.z),
		"source_item_id": item_id,
	}
	if item_mapping is String or item_mapping is StringName:
		placement["type_id"] = _normalize_type_id(String(item_mapping))
		return placement
	if typeof(item_mapping) != TYPE_DICTIONARY:
		return {}
	var mapping: Dictionary = Dictionary(item_mapping)
	placement["type_id"] = _normalize_type_id(String(mapping.get("type_id", "")))
	for key in ["rotation_degrees", "object_scale", "surface_type", "height_level", "edge_type"]:
		if mapping.has(key):
			placement[key] = mapping.get(key)
	return placement


func _rotation_degrees_from_grid_map_orientation(grid_map: GridMap, orientation: int) -> float:
	if grid_map == null or not grid_map.has_method("get_basis_with_orthogonal_index"):
		return 0.0
	var basis: Basis = grid_map.call("get_basis_with_orthogonal_index", orientation)
	var euler: Vector3 = basis.get_euler()
	return _normalize_rotation_degrees(rad_to_deg(euler.y))


func _apply_authoring_overrides(tile_data, placement: Dictionary, type_id: String, transform_owner_by_grid: Dictionary, warnings: Array[String]) -> void:
	if placement.has("height_level"):
		tile_data.height_level = clampi(int(placement.get("height_level", tile_data.height_level)), 0, 2)
	if placement.has("edge_type"):
		tile_data.edge_type = String(placement.get("edge_type", tile_data.edge_type)).strip_edges().to_lower()
	if placement.has("surface_type"):
		tile_data.surface_type = String(placement.get("surface_type", tile_data.surface_type)).strip_edges().to_lower()

	var has_rotation: bool = placement.has("rotation_degrees") or placement.has("object_rotation_degrees")
	var has_scale: bool = placement.has("object_scale") or placement.has("scale")
	if has_rotation or has_scale:
		_warn_if_transform_is_layered(tile_data.grid_position, type_id, transform_owner_by_grid, warnings)
	if has_rotation:
		tile_data.object_rotation_degrees = _normalize_rotation_degrees(float(placement.get("object_rotation_degrees", placement.get("rotation_degrees", 0.0))))
	if has_scale:
		tile_data.object_scale = _normalize_object_scale(_coerce_scale_value(placement.get("object_scale", placement.get("scale", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_OBJECT_SCALE))))


func _warn_if_transform_is_layered(grid_position: Vector2i, type_id: String, transform_owner_by_grid: Dictionary, warnings: Array[String]) -> void:
	var key: String = "%d,%d" % [grid_position.x, grid_position.y]
	var previous_type_id: String = String(transform_owner_by_grid.get(key, ""))
	if previous_type_id.is_empty():
		transform_owner_by_grid[key] = type_id
		return
	if previous_type_id == type_id:
		return
	warnings.append("Tile %s has layered transform placements (%s then %s); TerrainTileData stores one rotation/scale per tile." % [key, previous_type_id, type_id])
	transform_owner_by_grid[key] = type_id


func _increment_layer_stat(stats: Dictionary, type_id: String, catalog) -> void:
	if catalog != null and catalog.has_method("is_object_layer_type") and bool(catalog.call("is_object_layer_type", type_id)):
		stats["object_count"] = int(stats.get("object_count", 0)) + 1
		return
	if catalog != null and catalog.has_method("is_structure_layer_type") and bool(catalog.call("is_structure_layer_type", type_id)):
		stats["structure_count"] = int(stats.get("structure_count", 0)) + 1
		return
	stats["terrain_count"] = int(stats.get("terrain_count", 0)) + 1


func _sort_placements(a: Dictionary, b: Dictionary) -> bool:
	var a_grid: Vector2i = Vector2i(a.get("grid_position", Vector2i.ZERO))
	var b_grid: Vector2i = Vector2i(b.get("grid_position", Vector2i.ZERO))
	if a_grid.x != b_grid.x:
		return a_grid.x < b_grid.x
	if a_grid.y != b_grid.y:
		return a_grid.y < b_grid.y
	var a_order: int = int(a.get("_layer_order", 0))
	var b_order: int = int(b.get("_layer_order", 0))
	if a_order != b_order:
		return a_order < b_order
	return String(a.get("type_id", "")) < String(b.get("type_id", ""))


func _get_layer_order_for_type_id(type_id: String) -> int:
	var normalized: String = _normalize_type_id(type_id)
	if normalized.is_empty():
		return 99
	if normalized.begins_with("wall_") or normalized.begins_with("modular_wall") or normalized.begins_with("modular_gate") or normalized.begins_with("station_wall"):
		return 1
	if normalized.begins_with("factory_") or normalized.begins_with("fahrzeug_") or normalized.begins_with("technik_"):
		return 2
	return 0


func _get_catalog(authoring: Dictionary):
	var catalog_variant: Variant = authoring.get("tile_catalog", null)
	if catalog_variant != null:
		return catalog_variant
	return TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")


func _make_result(ok: bool, map_data, issues: Array, warnings: Array, stats: Dictionary) -> Dictionary:
	return {
		"ok": ok,
		"map_data": map_data,
		"issues": issues,
		"warnings": warnings,
		"stats": stats,
	}


func _read_string_meta(node: Node, keys: PackedStringArray) -> String:
	var value: Variant = _read_first_meta(node, keys)
	return _normalize_type_id(String(value)) if value != null else ""


func _read_grid_meta(node: Node) -> Vector2i:
	var value: Variant = _read_first_meta(node, META_GRID_KEYS)
	if value != null:
		return _coerce_grid_position(value)
	if node is Node3D:
		var position: Vector3 = (node as Node3D).position
		return Vector2i(roundi(position.x), roundi(position.z))
	return Vector2i.ZERO


func _read_first_meta(node: Node, keys: PackedStringArray) -> Variant:
	for key in keys:
		if node.has_meta(key):
			return node.get_meta(key)
	return null


func _coerce_grid_size(value: Variant, placements: Array) -> Vector2i:
	var explicit_size: Vector2i = _coerce_vector2i(value)
	if explicit_size.x > 0 and explicit_size.y > 0:
		return explicit_size
	var inferred_size: Vector2i = Vector2i.ZERO
	for placement_variant in placements:
		var placement: Dictionary = Dictionary(placement_variant)
		var grid: Vector2i = _coerce_grid_position(placement.get("grid_position", Vector2i.ZERO))
		inferred_size.x = maxi(inferred_size.x, grid.x + 1)
		inferred_size.y = maxi(inferred_size.y, grid.y + 1)
	if inferred_size.x > 0 and inferred_size.y > 0:
		return inferred_size
	return DEFAULT_GRID_SIZE


func _coerce_grid_position(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vector2: Vector2 = value
		return Vector2i(roundi(vector2.x), roundi(vector2.y))
	if value is Vector3i:
		var vector3i: Vector3i = value
		return Vector2i(vector3i.x, vector3i.z)
	if value is Vector3:
		var vector3: Vector3 = value
		return Vector2i(roundi(vector3.x), roundi(vector3.z))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(roundi(float(dict.get("x", 0))), roundi(float(dict.get("y", dict.get("z", 0)))))
	if value is Array:
		var array: Array = Array(value)
		if array.size() >= 2:
			return Vector2i(roundi(float(array[0])), roundi(float(array[1])))
	return Vector2i.ZERO


func _coerce_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vector2: Vector2 = value
		return Vector2i(roundi(vector2.x), roundi(vector2.y))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(roundi(float(dict.get("x", 0))), roundi(float(dict.get("y", 0))))
	if value is Array:
		var array: Array = Array(value)
		if array.size() >= 2:
			return Vector2i(roundi(float(array[0])), roundi(float(array[1])))
	return Vector2i.ZERO


func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector2i: Vector2i = value
		return Vector2(vector2i.x, vector2i.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	if value is Array:
		var array: Array = Array(value)
		if array.size() >= 2:
			return Vector2(float(array[0]), float(array[1]))
	return Vector2.ZERO


func _coerce_scale_value(value: Variant) -> float:
	if value is Vector3:
		var vector3: Vector3 = value
		return maxf(absf(vector3.x), maxf(absf(vector3.y), absf(vector3.z)))
	if value is Vector2:
		var vector2: Vector2 = value
		return maxf(absf(vector2.x), absf(vector2.y))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return maxf(absf(float(dict.get("x", 1.0))), maxf(absf(float(dict.get("y", 1.0))), absf(float(dict.get("z", 1.0)))))
	return float(value)


func _normalize_object_scale(value: float) -> float:
	if is_nan(value) or is_inf(value):
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_OBJECT_SCALE
	return snappedf(clampf(value, TERRAIN_TILE_DATA_SCRIPT.MIN_OBJECT_SCALE, TERRAIN_TILE_DATA_SCRIPT.MAX_OBJECT_SCALE), 0.001)


func _normalize_rotation_degrees(value: float) -> float:
	var normalized: float = fposmod(value, 360.0)
	if absf(normalized - 360.0) < 0.001:
		return 0.0
	return snappedf(normalized, 0.001)


func _normalize_type_id(type_id: String) -> String:
	return type_id.strip_edges().to_lower()
