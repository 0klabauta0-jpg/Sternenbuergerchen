extends "res://scripts/tests/mission_map_3d_render_spike.gd"

const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const CALIBRATION_OBJECTS: Array[Dictionary] = [
	{"grid": Vector2i(1, 1), "type_id": "deko_barrel_se"},
	{"grid": Vector2i(3, 1), "type_id": "deko_barrels_nw"},
	{"grid": Vector2i(5, 1), "type_id": "technik_generator_se"},
	{"grid": Vector2i(7, 1), "type_id": "technik_satellite_large_sw"},
	{"grid": Vector2i(9, 1), "type_id": "gebaeude_structure_closed_se"},
	{"grid": Vector2i(11, 1), "type_id": "gebaeude_hangar_small_b_sw"},
	{"grid": Vector2i(2, 4), "type_id": "plattform_center_se"},
	{"grid": Vector2i(4, 4), "type_id": "pipe_straight_ne"},
	{"grid": Vector2i(6, 4), "type_id": "rail_sw"},
	{"grid": Vector2i(8, 4), "type_id": "crater_small_se"},
	{"grid": Vector2i(10, 4), "type_id": "fahrzeug_speeder_b_se"},
]


func render_map() -> Dictionary:
	var map_data = _build_calibration_map()
	var map_root := get_node_or_null("MapRoot") as Node3D
	if map_root == null:
		map_root = Node3D.new()
		map_root.name = "MapRoot"
		add_child(map_root)
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	render_result = renderer.call("render_map", map_data, map_root, {"show_debug_grid": show_debug_grid})
	return render_result


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
