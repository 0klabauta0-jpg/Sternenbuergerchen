extends SceneTree

const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TILE_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_SW.png")

const MAP_PATH: String = "res://maps/hill_mechanics_16x16_testmap.json"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/hill_mechanics_16x16_testmap_checklist.md"
const SPACE_KIT_TERRAIN_TOP_SAMPLE: Vector2i = Vector2i(256, 315)
const SPACE_KIT_TERRAIN_TOP_COLOR_FALLBACK: Color = Color(1.0, 0.6235, 0.4667, 1.0)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Hill Mechanics 16x16 Testmap Verifier ===")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_test_map_contract(map_data)
	if map_data != null:
		_test_path_los_and_cost_contract(map_data)
		await _test_render_snapshot(map_data)
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_map_contract(map_data) -> void:
	_assert(map_data != null, "Hill mechanics testmap loads")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(16, 16), "Map grid is exactly 16x16")
	_assert(Array(map_data.call("get_tiles")).size() == 256, "Map has 256 authored tiles")
	for marker_id in ["spawn_alpha", "spawn_bravo", "objective_point", "ramp_probe", "cliff_probe", "diagonal_probe"]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Map has marker: %s" % marker_id)
	for marker_id in ["corner_north", "corner_south", "corner_west", "corner_east"]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Map has corner marker: %s" % marker_id)
	_assert(_marker_name_equals(map_data, "corner_north", "N"), "North compass marker is the N letter")
	_assert(_marker_name_equals(map_data, "corner_south", "S"), "South compass marker is the S letter")
	_assert(_marker_name_equals(map_data, "corner_west", "W"), "West compass marker is the W letter")
	_assert(_marker_name_equals(map_data, "corner_east", "E"), "East compass marker is the E letter")
	_assert(_marker_is_outside_map_edge(map_data, "corner_north", "north"), "North compass marker sits outside the map")
	_assert(_marker_is_outside_map_edge(map_data, "corner_east", "east"), "East compass marker sits outside the map")
	_assert(_marker_is_outside_map_edge(map_data, "corner_west", "west"), "West compass marker sits outside the map")
	_assert(_marker_is_outside_map_edge(map_data, "corner_south", "south"), "South compass marker sits outside the map")

	_assert(_tile_has_height(map_data, Vector2i(1, 1), 0), "Alpha spawn starts on H0")
	_assert(_tile_has_height(map_data, Vector2i(6, 5), 0), "Ramp probe sits on the lower H0 ramp opening")
	_assert(_tile_has_height(map_data, Vector2i(5, 6), 1), "Objective sits on the H1 plateau")
	_assert(_tile_has_edge(map_data, Vector2i(6, 6), TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE), "North ramp upper tile is a slope")
	_assert(_tile_has_edge(map_data, Vector2i(6, 8), TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE), "South ramp upper tile is a slope")
	_assert(_tile_has_type(map_data, Vector2i(4, 7), "cliff_straight_se"), "West rim uses an explicit lower-neighbor cliff tile")
	_assert(_tile_is_blocking_cliff_visual(map_data, Vector2i(4, 7)), "Explicit cliff side blocks movement and LOS")
	_assert(_explicit_cliff_corners_match_reference(map_data), "Explicit cliff corner tiles cover north/south/east/west corner variants")
	_assert(_tile_has_surface(map_data, Vector2i(14, 4), TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD), "Bravo route has road surface")
	_assert(_tile_has_surface(map_data, Vector2i(2, 12), TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND), "South basin has sand surface")
	_assert(_tile_has_surface(map_data, Vector2i(5, 6), TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND), "Plateau ground color matches the cliff kit")
	_assert(_standard_floor_uses_space_kit_ground(map_data), "Standard floor uses Space Kit ground_flat tiles")
	_assert(not _map_contains_type(map_data, "nature_ground_sand_dirt") and not _map_contains_type(map_data, "nature_ground_rock_dirt"), "Hill map does not generate Nature Sand/Rock raised floor detail tiles")

	var heights: Dictionary = _count_heights(map_data)
	var edges: Dictionary = _count_edges(map_data)
	var surfaces: Dictionary = _count_surfaces(map_data)
	_assert(int(heights.get(0, 0)) > 0 and int(heights.get(1, 0)) > 0, "Map covers H0/H1 hill construction")
	_assert(int(edges.get(TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, 0)) >= 2, "Map has two slope/ramp openings")
	_assert(_count_type_prefix(map_data, "cliff_") >= 12, "Map has explicit cliff visual tiles on lower neighbors")
	for surface_id in [TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND]:
		_assert(int(surfaces.get(surface_id, 0)) > 0, "Map contains surface: %s" % surface_id)

	for object_id in ["nature_tree_blocker", "nature_rock_cover", "nature_bush_cover", "nature_cactus_cover", "nature_deco_logs", "station_container_wide"]:
		_assert(_map_contains_object_type(map_data, object_id), "Map contains object: %s" % object_id)


func _test_path_los_and_cost_contract(map_data) -> void:
	var registry = _make_registry_from_map(map_data)
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var los_system = LINE_OF_SIGHT_SCRIPT.new()

	var alpha_path: Array = pathfinder.call("find_path", Vector2i(1, 1), Vector2i(5, 6), registry)
	_assert(not alpha_path.is_empty(), "Alpha spawn can path to hilltop objective")
	_assert(_path_contains_any(alpha_path, [Vector2i(6, 5), Vector2i(6, 6)]), "Alpha route touches the north ramp opening")

	var bravo_path: Array = pathfinder.call("find_path", Vector2i(14, 14), Vector2i(5, 6), registry)
	_assert(not bravo_path.is_empty(), "Bravo spawn can path to hilltop objective through the road/south ramp")
	_assert(_path_contains_any(bravo_path, [Vector2i(6, 9), Vector2i(6, 8)]), "Bravo route touches the south ramp opening")

	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(6, 5), Vector2i(6, 6), registry)), "Slope step H0 to H1 is traversable")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(5, 6), Vector2i(4, 6), registry)), "Explicit cliff side blocks direct H1/H0 movement")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(5, 7), Vector2i(6, 7), registry)), "Blocking rock cover prevents movement")

	var sand_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 12), Vector2i(2, 12), registry))
	var road_cost: float = float(pathfinder.call("get_step_cost", Vector2i(14, 3), Vector2i(14, 4), registry))
	_assert(sand_cost > road_cost, "Sand movement cost is higher than road movement cost")

	var rock_blocked_los: bool = bool(los_system.call(
		"has_line_of_sight_with_terrain",
		registry.call("grid_to_world", Vector2i(5, 7)),
		registry.call("grid_to_world", Vector2i(9, 7)),
		registry,
		1000.0
	))
	_assert(not rock_blocked_los, "Rock cover blocks LOS across the plateau lane")

	var bush_lane_los: bool = bool(los_system.call(
		"has_line_of_sight_with_terrain",
		registry.call("grid_to_world", Vector2i(5, 6)),
		registry.call("grid_to_world", Vector2i(7, 6)),
		registry,
		1000.0
	))
	_assert(bush_lane_los, "Bush cover lane remains LOS-open")
	registry.free()


func _test_render_snapshot(map_data) -> void:
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	view.call("set_selected_grid_positions", [Vector2i(6, 5), Vector2i(5, 6), Vector2i(4, 7)])
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(snapshot.get("tile_count", 0)) == 256, "3D view renders all 16x16 tiles")
	_assert(int(snapshot.get("tile_grid_line_count", 0)) > 0, "3D view renders visible grid lines")
	_assert(int(snapshot.get("height_edge_model_count", 0)) > 0, "3D view renders height edge models")
	_assert(int(snapshot.get("slope_edge_model_count", 0)) > 0, "3D view renders slope models")
	_assert(int(snapshot.get("asset_model_count", 0)) >= _count_type_prefix(map_data, "cliff_"), "3D view renders explicit lower-neighbor cliff models")
	_assert(_height_edges_anchor_on_lower_neighbor_tiles(Array(snapshot.get("height_edge_visual_entries", []))), "3D view anchors cliff/slope models on lower neighbor tiles")
	_assert(int(snapshot.get("surface_tint_count", 0)) > 0, "3D view renders surface tint overlays")
	_assert(_surface_visuals_are_top_anchored(Array(snapshot.get("surface_visual_entries", []))), "Ground model thickness stays below gameplay surface")
	_assert(_ground_flat_visuals_use_cliff_ground_color(Array(snapshot.get("surface_visual_entries", []))), "Ground flat visuals use the Space Kit cliff-matched terrain color")
	_assert(int(snapshot.get("nature_surface_detail_model_count", 0)) == 0, "3D view does not render Nature Sand/Rock raised floor detail on the hill map")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 3, "3D view renders selected probe tiles")
	_assert(int(snapshot.get("marker_count", 0)) >= 6, "3D view renders testmap markers")
	_assert(int(snapshot.get("compass_marker_count", 0)) == 4, "3D view renders N/E/S/W compass letters outside the map")
	_assert(int(snapshot.get("nature_prop_model_count", 0)) >= 5, "3D view renders nature props")
	_assert(int(snapshot.get("space_station_textured_surface_count", 0)) > 0, "3D view applies Space Station colormap texture in the hill map")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "3D view has no missing map asset mappings")
	view.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Manual hill mechanics checklist exists")
	var text: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Alpha", "Bravo", "H0", "H1", "slope", "cliff", "sand", "road", "LOS", "N/E/S/W"]:
		_assert(text.contains(required_text), "Checklist covers %s" % required_text)


func _make_registry_from_map(map_data):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	return registry


func _tile_has_height(map_data, grid: Vector2i, expected_height: int) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return tile_data != null and int(tile_data.height_level) == expected_height


func _tile_has_edge(map_data, grid: Vector2i, expected_edge: String) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return tile_data != null and String(tile_data.edge_type) == expected_edge


func _tile_has_surface(map_data, grid: Vector2i, expected_surface: String) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return tile_data != null and String(tile_data.surface_type) == expected_surface


func _tile_has_type(map_data, grid: Vector2i, expected_type_id: String) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return tile_data != null and String(tile_data.type_id) == expected_type_id


func _tile_is_blocking_cliff_visual(map_data, grid: Vector2i) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return (
		tile_data != null
		and String(tile_data.type_id).begins_with("cliff_")
		and int(tile_data.height_level) == 0
		and String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		and not bool(tile_data.walkable)
		and bool(tile_data.blocks_los)
	)


func _marker_name_equals(map_data, marker_id: String, expected_text: String) -> bool:
	if not bool(map_data.call("has_marker", marker_id)):
		return false
	return String(map_data.call("get_marker_display_name", marker_id)) == expected_text


func _marker_is_outside_map_edge(map_data, marker_id: String, edge_id: String) -> bool:
	if not bool(map_data.call("has_marker", marker_id)):
		return false
	var marker_position: Vector2 = Vector2(map_data.call("get_marker_position", marker_id, Vector2.ZERO))
	var grid_size: Vector2i = Vector2i(map_data.call("get_grid_size"))
	var north_corner = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var east_corner = map_data.call("get_tile_at_grid", Vector2i(grid_size.x - 1, 0))
	var west_corner = map_data.call("get_tile_at_grid", Vector2i(0, grid_size.y - 1))
	var south_corner = map_data.call("get_tile_at_grid", Vector2i(grid_size.x - 1, grid_size.y - 1))
	if north_corner == null or east_corner == null or west_corner == null or south_corner == null:
		return false
	match edge_id:
		"north":
			return marker_position.y < float(north_corner.world_position.y)
		"east":
			return marker_position.x > float(east_corner.world_position.x)
		"west":
			return marker_position.x < float(west_corner.world_position.x)
		"south":
			return marker_position.y > float(south_corner.world_position.y)
	return false


func _explicit_cliff_corners_match_reference(map_data) -> bool:
	return (
		_tile_has_type(map_data, Vector2i(4, 5), "cliff_corner_sw")
		and _tile_has_type(map_data, Vector2i(8, 5), "cliff_corner_se")
		and _tile_has_type(map_data, Vector2i(4, 9), "cliff_corner_nw")
		and _tile_has_type(map_data, Vector2i(8, 9), "cliff_corner_ne")
	)


func _standard_floor_uses_space_kit_ground(map_data) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var type_id: String = String(tile_data.type_id)
		if type_id.begins_with("cliff_"):
			continue
		if type_id != "ground_flat":
			return false
	return true


func _map_contains_type(map_data, type_id: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.type_id) == type_id:
			return true
	return false


func _count_heights(map_data) -> Dictionary:
	var result: Dictionary = {}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var key: int = int(tile_data.height_level)
		result[key] = int(result.get(key, 0)) + 1
	return result


func _count_edges(map_data) -> Dictionary:
	var result: Dictionary = {}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var key: String = String(tile_data.edge_type)
		result[key] = int(result.get(key, 0)) + 1
	return result


func _count_surfaces(map_data) -> Dictionary:
	var result: Dictionary = {}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var key: String = String(tile_data.surface_type)
		result[key] = int(result.get(key, 0)) + 1
	return result


func _count_type_prefix(map_data, type_prefix: String) -> int:
	var result: int = 0
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		if String(tile_data.type_id).begins_with(type_prefix):
			result += 1
	return result


func _map_contains_object_type(map_data, object_type_id: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.object_type_id) == object_type_id:
			return true
	return false


func _path_contains_any(path: Array, probes: Array) -> bool:
	for probe_variant in probes:
		if path.has(Vector2i(probe_variant)):
			return true
	return false


func _surface_visuals_are_top_anchored(entries: Array) -> bool:
	if entries.is_empty():
		return false
	var saw_ground_visual: bool = false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("model_key", "")) == "ground_flat":
			saw_ground_visual = true
		var surface_y: float = float(entry.get("surface_y", 0.0))
		var top_y: float = float(entry.get("visual_top_y", surface_y))
		var bottom_y: float = float(entry.get("visual_bottom_y", surface_y))
		var expected_top_y: float = surface_y + float(entry.get("surface_top_y_offset", 0.0))
		if absf(top_y - expected_top_y) > 0.002:
			return false
		if bottom_y > surface_y + 0.001:
			return false
	return saw_ground_visual


func _ground_flat_visuals_use_cliff_ground_color(entries: Array) -> bool:
	var ground_flat_seen: bool = false
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("model_key", "")) != "ground_flat":
			continue
		ground_flat_seen = true
		if not bool(entry.get("has_material_override", false)):
			return false
		var color_variant: Variant = entry.get("material_override_color", Color.TRANSPARENT)
		if typeof(color_variant) != TYPE_COLOR:
			return false
		var color: Color = color_variant
		if not _colors_close(color, _sample_space_kit_terrain_top_color(), 0.012):
			return false
		if not bool(entry.get("material_override_unshaded", false)):
			return false
	return ground_flat_seen


func _sample_space_kit_terrain_top_color() -> Color:
	if TILE_TEXTURE == null:
		return SPACE_KIT_TERRAIN_TOP_COLOR_FALLBACK
	var image: Image = TILE_TEXTURE.get_image()
	if image == null or image.is_empty():
		return SPACE_KIT_TERRAIN_TOP_COLOR_FALLBACK
	var sample_position := Vector2i(
		clampi(SPACE_KIT_TERRAIN_TOP_SAMPLE.x, 0, image.get_width() - 1),
		clampi(SPACE_KIT_TERRAIN_TOP_SAMPLE.y, 0, image.get_height() - 1)
	)
	var sampled_color: Color = image.get_pixelv(sample_position)
	if sampled_color.a < 0.5:
		return SPACE_KIT_TERRAIN_TOP_COLOR_FALLBACK
	sampled_color.a = 1.0
	return sampled_color


func _colors_close(actual: Color, expected: Color, tolerance: float) -> bool:
	return (
		absf(actual.r - expected.r) <= tolerance
		and absf(actual.g - expected.g) <= tolerance
		and absf(actual.b - expected.b) <= tolerance
		and absf(actual.a - expected.a) <= tolerance
	)


func _height_edges_anchor_on_lower_neighbor_tiles(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var grid_position: Vector2i = Vector2i(entry.get("grid_position", Vector2i.ZERO))
		var anchor_grid_position: Vector2 = Vector2(entry.get("anchor_grid_position", Vector2(grid_position)))
		var edge_dirs: Array = Array(entry.get("edge_dirs", []))
		if edge_dirs.is_empty():
			return false
		var expected_anchor := Vector2(grid_position)
		for edge_dir_variant in edge_dirs:
			expected_anchor += Vector2(Vector2i(edge_dir_variant))
		if anchor_grid_position.distance_squared_to(expected_anchor) > 0.0001:
			return false
		if anchor_grid_position.distance_squared_to(Vector2(grid_position)) <= 0.0001:
			return false
	return true


func _height_edge_entries_cover_corner_compass(entries: Array) -> bool:
	var required_corner_ids: Dictionary = {
		"cliff_corner_ne": false,
		"cliff_corner_sw": false,
		"cliff_corner_nw": false,
		"cliff_corner_se": false,
	}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var visual_type_id: String = String(entry.get("visual_type_id", ""))
		if required_corner_ids.has(visual_type_id):
			required_corner_ids[visual_type_id] = true
	for corner_id in required_corner_ids.keys():
		if not bool(required_corner_ids.get(corner_id, false)):
			return false
	return true


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
