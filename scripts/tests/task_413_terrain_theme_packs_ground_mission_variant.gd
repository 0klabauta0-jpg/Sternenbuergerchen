extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_413_terrain_theme_packs_ground_mission_variant.md"
const SURFACE_THEME_CATALOG_PATH: String = "res://data/terrain_surface_visual_theme_catalog.json"
## The theme-pack feature keeps its original showcase map as a fixture; the playable
## GM02 was rebuilt in the frontier look (ground_mission02_relay_ridge_verifier.gd).
const MAP_PATH: String = "res://maps/Ground_Mission02_128x128_legacy_theme_fixture.json"
const PLAYABLE_MAP_PATH: String = "res://maps/Ground_Mission02_128x128.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/ground_mission02_128x128.json"
const EXPECTED_SIZE: Vector2i = Vector2i(128, 128)
const EXPECTED_THEME_ID: String = "ground_mission_mixed_v1"
const GRID_SPAWN_ALPHA: Vector2i = Vector2i(16, 104)
const GRID_SPAWN_BRAVO: Vector2i = Vector2i(109, 34)
const GRID_OBJECTIVE: Vector2i = Vector2i(84, 82)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_413 Terrain Theme Packs and Ground Mission Variant ===")
	var catalog: Dictionary = _load_json(SURFACE_THEME_CATALOG_PATH)
	_test_task_and_catalog(catalog)
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_test_map_data_contract(map_data)
	var registry = _make_registry_from_map(map_data)
	_test_navigation_contract(registry)
	_test_scenario_contract(map_data)
	await _test_render_theme_streaming(map_data)
	if registry != null:
		registry.free()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_task_and_catalog(catalog: Dictionary) -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "Task file exists")
	_assert(not catalog.is_empty(), "Surface visual theme catalog parses")
	_assert(bool(Dictionary(catalog.get("runtime_contract", {})).get("visual_only", false)), "Theme catalog is visual-only")
	_assert(bool(Dictionary(catalog.get("runtime_contract", {})).get("surface_type_remains_gameplay_truth", false)), "Surface type remains gameplay truth")
	var root_surface_models: Dictionary = Dictionary(catalog.get("surface_model_by_surface", {}))
	for surface_type in [TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD]:
		_assert(String(root_surface_models.get(surface_type, "")) == "ground_flat", "Legacy root surface model remains Space Kit: %s" % surface_type)
	var themes: Dictionary = Dictionary(catalog.get("themes", {}))
	_assert(themes.has("space_default_v1"), "Theme catalog includes compatibility pack")
	_assert(themes.has("nature_classic_dirt_v1"), "Theme catalog includes Nature dirt pack")
	_assert(themes.has(EXPECTED_THEME_ID), "Theme catalog includes Ground Mission mixed pack")
	var ground_theme: Dictionary = Dictionary(themes.get(EXPECTED_THEME_ID, {}))
	_assert(bool(ground_theme.get("visual_only", false)), "Ground Mission theme is marked visual-only")
	var ground_surface_models: Dictionary = Dictionary(ground_theme.get("surface_model_by_surface", {}))
	_assert(String(ground_surface_models.get(TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, "")) == "nature_ground_dirt", "Ground Mission theme swaps ground to Nature dirt")
	_assert(String(ground_surface_models.get(TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "")) == "ground_flat", "Ground Mission theme keeps authored roads readable")


func _test_map_data_contract(map_data) -> void:
	_assert(map_data != null, "Ground Mission 02 map loads")
	if map_data == null:
		return
	_assert(not bool(map_data.call("has_load_issue")), "Ground Mission 02 has no load issue")
	_assert(Vector2i(map_data.call("get_grid_size")) == EXPECTED_SIZE, "Ground Mission 02 is 128x128")
	_assert(String(map_data.call("get_terrain_visual_theme_id")) == EXPECTED_THEME_ID, "Ground Mission 02 selects the mixed terrain theme")
	_assert(int(Array(map_data.call("get_tiles")).size()) == EXPECTED_SIZE.x * EXPECTED_SIZE.y, "Ground Mission 02 keeps 16384 logical tiles")
	for marker_id in ["spawn_alpha", "spawn_bravo", "objective_point", "spawn_enemy_patrol", "spawn_enemy_defense", "spawn_enemy_air_defense"]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Ground Mission 02 marker exists: %s" % marker_id)
	_assert(not Array(map_data.call("get_patrol_path", "ground_patrol_route")).is_empty(), "Ground Mission 02 has main patrol route")
	_assert(not Array(map_data.call("get_patrol_path", "outer_probe_route")).is_empty(), "Ground Mission 02 has outer probe route")

	var counts: Dictionary = _count_map_features(map_data)
	_assert(int(counts.get("road", 0)) >= 700, "Ground Mission 02 has authored road corridors")
	_assert(int(counts.get("sand", 0)) >= 1000, "Ground Mission 02 has sand terrain")
	_assert(int(counts.get("rock", 0)) >= 400, "Ground Mission 02 has rock terrain")
	_assert(int(counts.get("height_1", 0)) > 0 and int(counts.get("height_2", 0)) > 0, "Ground Mission 02 has H1 and H2 terrain")
	_assert(int(counts.get("slope", 0)) > 0 and int(counts.get("cliff", 0)) > 0, "Ground Mission 02 has slopes and cliffs")
	_assert(int(counts.get("nature_props", 0)) >= 250, "Ground Mission 02 contains Nature cover props")
	_assert(int(counts.get("station_or_modular_tiles", 0)) >= 100, "Ground Mission 02 has Station/Modular objective floor")
	_assert(int(counts.get("air_defense_objects", 0)) >= 3, "Ground Mission 02 has Space Kit turret objects")
	_assert(_tile_is_walkable(map_data, GRID_OBJECTIVE), "Objective tile is walkable")
	_assert(_tile_is_walkable(map_data, GRID_SPAWN_ALPHA), "Spawn Alpha tile is walkable")
	_assert(_tile_is_walkable(map_data, GRID_SPAWN_BRAVO), "Spawn Bravo tile is walkable")


func _test_navigation_contract(registry) -> void:
	_assert(registry != null, "Registry builds from Ground Mission 02")
	if registry == null:
		return
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var alpha_path: Array = pathfinder.call("find_path", GRID_SPAWN_ALPHA, GRID_OBJECTIVE, registry)
	var bravo_path: Array = pathfinder.call("find_path", GRID_SPAWN_BRAVO, GRID_OBJECTIVE, registry)
	_assert(not alpha_path.is_empty(), "Pathfinder reaches objective from Spawn Alpha")
	_assert(not bravo_path.is_empty(), "Pathfinder reaches objective from Spawn Bravo")
	var hpa_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	_assert(bool(hpa_graph.call("build_from_registry", registry, 8)), "HPA graph builds for Ground Mission 02")
	var hpa_stats: Dictionary = Dictionary(hpa_graph.call("get_last_build_stats"))
	_assert(int(hpa_stats.get("tile_count", 0)) == EXPECTED_SIZE.x * EXPECTED_SIZE.y, "HPA stats report 16384 map tiles")
	_assert(int(hpa_stats.get("cluster_count", 0)) == 256, "HPA stats report 256 clusters for 128x128")
	_assert(int(hpa_stats.get("portal_count", 0)) > 0, "HPA stats report portals")


func _test_scenario_contract(map_data) -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Ground Mission 02 scenario loads")
	if scenario == null:
		return
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Ground Mission 02 scenario validates: %s" % JSON.stringify(Array(validation.get("errors", []))))
	_assert(String(scenario.scenario_id) == "ground_mission02_128x128", "Scenario id is stable")
	_assert(String(scenario.map_file_path) == PLAYABLE_MAP_PATH, "Scenario references Ground Mission 02 map")
	_assert(PackedStringArray(scenario.call("get_enemy_ids")).size() == 12, "Scenario defines twelve enemy IDs")
	_assert(Array(scenario.enemy_groups).size() == 3, "Scenario defines three enemy groups")
	var threats: Array = Array(scenario.call("get_enemy_air_asset_threats", map_data))
	_assert(threats.size() == 1, "Scenario exposes one air-asset threat group")
	_assert(String(Dictionary(threats[0]).get("air_asset_risk_profile", "")) == "watch_warning", "Air-defense group carries watch-warning risk")


func _test_render_theme_streaming(map_data) -> void:
	_assert(map_data != null, "Render smoke receives map data")
	if map_data == null:
		return
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("focus_world_position", Vector2(map_data.call("get_tile_at_grid", GRID_OBJECTIVE).world_position))
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("terrain_visual_theme_active", false)), "Render snapshot marks map terrain theme active")
	_assert(String(snapshot.get("terrain_visual_theme_id", "")) == EXPECTED_THEME_ID, "Render snapshot exposes the selected terrain theme")
	_assert(int(snapshot.get("terrain_visual_theme_available_count", 0)) >= 3, "Render snapshot sees theme catalog packs")
	_assert(bool(snapshot.get("visual_streaming_active", false)), "Ground Mission 02 enables visual streaming")
	_assert(int(snapshot.get("total_tile_count", 0)) == EXPECTED_SIZE.x * EXPECTED_SIZE.y, "Render snapshot keeps full logical tile count")
	_assert(int(snapshot.get("rendered_tile_count", 0)) < int(snapshot.get("total_tile_count", 0)), "Streaming renders a smaller active window")
	_assert(int(snapshot.get("ground_multimesh_tile_count", 0)) >= int(snapshot.get("rendered_tile_count", 0)), "Streaming window ground stays batched")
	_assert(int(snapshot.get("nature_surface_ground_model_count", 0)) > 0, "Theme renders Nature ground visuals")
	_assert(int(snapshot.get("space_station_model_count", 0)) > 0, "Objective area renders Station/Space assets")
	_assert(int(snapshot.get("nature_prop_model_count", 0)) > 0, "Streaming window renders Nature props")
	_assert(int(snapshot.get("static_prop_multimesh_model_count", 0)) > 0, "Streaming window batches static Nature props")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Ground Mission 02 has no missing map asset mappings")
	primary_view.queue_free()
	await _wait_frames(2)


func _count_map_features(map_data) -> Dictionary:
	var counts: Dictionary = {
		"road": 0,
		"sand": 0,
		"rock": 0,
		"height_1": 0,
		"height_2": 0,
		"slope": 0,
		"cliff": 0,
		"nature_props": 0,
		"station_or_modular_tiles": 0,
		"air_defense_objects": 0,
	}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var surface_type: String = String(tile_data.surface_type)
		var type_id: String = String(tile_data.type_id)
		var object_type_id: String = String(tile_data.object_type_id)
		if counts.has(surface_type):
			counts[surface_type] = int(counts.get(surface_type, 0)) + 1
		var height_level: int = int(tile_data.height_level)
		if height_level == 1:
			counts["height_1"] = int(counts["height_1"]) + 1
		elif height_level == 2:
			counts["height_2"] = int(counts["height_2"]) + 1
		var edge_type: String = String(tile_data.edge_type)
		if counts.has(edge_type):
			counts[edge_type] = int(counts.get(edge_type, 0)) + 1
		if object_type_id.begins_with("nature_"):
			counts["nature_props"] = int(counts["nature_props"]) + 1
		if type_id.begins_with("station_") or type_id.begins_with("modular_"):
			counts["station_or_modular_tiles"] = int(counts["station_or_modular_tiles"]) + 1
		if object_type_id.begins_with("spacekit_turret"):
			counts["air_defense_objects"] = int(counts["air_defense_objects"]) + 1
	return counts


func _tile_is_walkable(map_data, grid: Vector2i) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return tile_data != null and bool(tile_data.walkable)


func _make_registry_from_map(map_data):
	if map_data == null:
		return null
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	return registry


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
