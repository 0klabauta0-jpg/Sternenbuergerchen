extends SceneTree

const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const BUDGET_PATH: String = "res://data/performance_budget_contract.json"
const NATURE_CATALOG_PATH: String = "res://data/nature_kit_asset_catalog.json"
const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const SURFACE_THEME_CATALOG_PATH: String = "res://data/terrain_surface_visual_theme_catalog.json"
const OBJECT_CATALOG_PATH: String = "res://data/terrain_object_catalog.json"
const REPORT_PATH: String = "res://docs/reports/nature_kit_hill_playability_visual_performance_smoke.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/nature_kit_hill_playability_visual_checklist.md"
const TEMP_FIXTURE_PATH: String = "user://task_255_nature_hill_fixture.json"

const FIXTURE_SIZE: Vector2i = Vector2i(32, 32)
const REQUIRED_PROP_IDS: Array = [
	"nature_tree_blocker",
	"nature_rock_cover",
	"nature_bush_cover",
	"nature_cactus_cover",
	"nature_deco_logs",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_255 Nature Kit Hill Playability Visual Performance Smoke ===")
	var nature_catalog: Dictionary = _load_json(NATURE_CATALOG_PATH)
	var terrain_mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var surface_catalog: Dictionary = _load_json(SURFACE_THEME_CATALOG_PATH)
	var object_catalog: Dictionary = _load_json(OBJECT_CATALOG_PATH)
	var budget: Dictionary = _load_json(BUDGET_PATH)
	_test_import_locality_gate(nature_catalog, terrain_mapping, surface_catalog, object_catalog)
	var fixture_map = _build_nature_fixture_map()
	_test_editor_fixture_roundtrip(fixture_map)
	_test_gameplay_contract(fixture_map)
	await _test_mission_visual_and_performance_smoke(fixture_map, budget)
	_test_report_and_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_import_locality_gate(nature_catalog: Dictionary, terrain_mapping: Dictionary, surface_catalog: Dictionary, object_catalog: Dictionary) -> void:
	_assert(not nature_catalog.is_empty(), "Nature Kit catalog parses")
	_assert(not terrain_mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(not surface_catalog.is_empty(), "Surface visual catalog parses")
	_assert(not object_catalog.is_empty(), "Terrain object catalog parses")
	_assert(int(Dictionary(nature_catalog.get("source_audit", {})).get("selected_model_count", 0)) == 25, "Nature Kit subset stays curated")
	for category in ["cliffs", "ground", "rocks", "vegetation", "props"]:
		_assert(Dictionary(nature_catalog.get("categories", {})).has(category), "Nature catalog includes category: %s" % category)
	var asset_count: int = 0
	for asset_variant in Array(nature_catalog.get("assets", [])):
		var asset: Dictionary = Dictionary(asset_variant)
		var path: String = String(asset.get("project_path", "")).strip_edges()
		var bin_path: String = String(asset.get("bin_path", "")).strip_edges()
		asset_count += 1
		_assert(_is_nature_project_path(path), "Nature asset path is project-local: %s" % String(asset.get("asset_id", "")))
		_assert(FileAccess.file_exists(path), "Nature glTF file exists: %s" % String(asset.get("asset_id", "")))
		_assert(bin_path.is_empty() or FileAccess.file_exists(bin_path), "Nature adjacent bin exists: %s" % String(asset.get("asset_id", "")))
		_assert(ResourceLoader.exists(path), "Nature glTF resource loads: %s" % String(asset.get("asset_id", "")))
	_assert(asset_count >= 25, "Nature catalog covers curated imported asset set")
	var model_entries: Dictionary = Dictionary(terrain_mapping.get("models", {}))
	for active_edge_model in ["cliff_straight", "slope"]:
		var edge_entry: Dictionary = Dictionary(model_entries.get(active_edge_model, {}))
		_assert(String(edge_entry.get("source_id", "")) == "kenney_space_kit", "Active height-edge model uses legacy Space Kit: %s" % active_edge_model)
		_assert(ResourceLoader.exists(String(edge_entry.get("model_path", ""))), "Active height-edge model loads: %s" % active_edge_model)
	for nature_alias in ["nature_cliff_brown_straight", "nature_slope_brown_steps", "nature_cliff_grey_straight", "nature_slope_grey_steps"]:
		var alias_entry: Dictionary = Dictionary(model_entries.get(nature_alias, {}))
		_assert(String(alias_entry.get("source_id", "")) == "kenney_nature_kit_classic", "Nature candidate edge alias uses Nature Kit: %s" % nature_alias)
		_assert(ResourceLoader.exists(String(alias_entry.get("model_path", ""))), "Nature candidate edge alias loads: %s" % nature_alias)
	for required_model in ["nature_ground_dirt"] + REQUIRED_PROP_IDS:
		var entry: Dictionary = Dictionary(model_entries.get(required_model, {}))
		_assert(String(entry.get("source_id", "")) == "kenney_nature_kit_classic", "Required Nature model mapping uses Nature Kit: %s" % required_model)
		_assert(ResourceLoader.exists(String(entry.get("model_path", ""))), "Required Nature model mapping loads: %s" % required_model)


func _test_editor_fixture_roundtrip(fixture_map) -> void:
	_assert(fixture_map != null, "Nature 32x32 fixture map builds")
	if fixture_map == null:
		return
	_assert(Vector2i(fixture_map.call("get_grid_size")) == FIXTURE_SIZE, "Fixture is 32x32")
	_assert(fixture_map.call("save_to_file", TEMP_FIXTURE_PATH) == OK, "Nature fixture map saves")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", TEMP_FIXTURE_PATH)
	_assert(reloaded != null, "Nature fixture map reloads")
	if reloaded == null:
		return
	for prop_id in REQUIRED_PROP_IDS:
		_assert(_map_contains_object_type(reloaded, prop_id), "Roundtrip preserves fixture prop: %s" % prop_id)
	_assert(_map_contains_edge_type(reloaded, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF), "Roundtrip preserves cliff edge types")
	_assert(_map_contains_edge_type(reloaded, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE), "Roundtrip preserves slope edge types")
	_assert(_map_contains_surface_type(reloaded, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND), "Roundtrip preserves sand surface")
	_assert(_map_contains_surface_type(reloaded, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK), "Roundtrip preserves rock surface")


func _test_gameplay_contract(fixture_map) -> void:
	var registry = _make_registry_from_map(fixture_map)
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var los_system = LINE_OF_SIGHT_SCRIPT.new()
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(9, 9), Vector2i(10, 9), registry)), "Tree prop blocks direct movement")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(12, 9), Vector2i(13, 9), registry)), "Rock prop blocks direct movement")
	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(9, 13), Vector2i(10, 13), registry)), "Bush prop remains walkable")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(8, 12), Vector2i(9, 12), registry)), "Cactus prop blocks direct movement")
	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(12, 13), Vector2i(13, 13), registry)), "Deco prop remains walkable")
	_assert(not bool(los_system.call("has_line_of_sight_with_terrain", registry.call("grid_to_world", Vector2i(9, 9)), registry.call("grid_to_world", Vector2i(11, 9)), registry, 1000.0)), "Tree prop blocks LOS")
	_assert(bool(los_system.call("has_line_of_sight_with_terrain", registry.call("grid_to_world", Vector2i(9, 13)), registry.call("grid_to_world", Vector2i(11, 13)), registry, 1000.0)), "Bush/deco lane does not block LOS")
	_assert(int(registry.call("get_cover_at", Vector2i(10, 9))) == 65, "Tree cover comes from TerrainRegistry")
	_assert(int(registry.call("get_cover_at", Vector2i(13, 9))) == 55, "Rock cover comes from TerrainRegistry")
	_assert(int(registry.call("get_cover_at", Vector2i(10, 13))) == 25, "Bush cover comes from TerrainRegistry")
	_assert(int(registry.call("get_cover_at", Vector2i(13, 13))) == 0, "Deco prop stays no-cover")
	var route: Array = pathfinder.call("find_path", Vector2i(8, 8), Vector2i(15, 15), registry)
	_assert(not route.is_empty(), "Pathfinder finds route through Nature hill fixture")
	_assert(not route.has(Vector2i(10, 9)) and not route.has(Vector2i(13, 9)), "Pathfinder route avoids blocking Nature props")
	registry.free()


func _test_mission_visual_and_performance_smoke(fixture_map, budget: Dictionary) -> void:
	var render_budget: Dictionary = Dictionary(Dictionary(budget.get("project_budget", {})).get("render", {}))
	var ui_budget: Dictionary = Dictionary(Dictionary(budget.get("project_budget", {})).get("ui", {}))
	var target_world: Vector2 = fixture_map.call("get_tile_at_grid", Vector2i(12, 12)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", fixture_map)
	primary_view.call("set_selected_grid_positions", [Vector2i(12, 12)])
	primary_view.call("set_mission_drop_visual_state", {
		"has_lz_position": true,
		"lz_position": fixture_map.call("get_tile_at_grid", Vector2i(9, 12)).world_position,
	})
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"plan_dicts": [{
			"fireteam_id": "blue",
			"phase": 1,
			"waypoints": [{"target_position": target_world, "command_type": "move"}],
		}],
		"area_order_dicts": [{
			"area_order_id": "task255_nature_area",
			"command_type": "defend",
			"tile_world_positions": [target_world],
		}],
	})
	primary_view.call("set_fog_of_war_state", {
		"mode": "known_terrain",
		"team_id": "team_alpha",
		"terrain_knowledge": {
			"visible_tile_ids": PackedStringArray(["tile_12_12", "tile_9_12"]),
			"explored_tile_ids": PackedStringArray(["tile_12_12", "tile_9_12", "tile_10_9", "tile_13_9"]),
		},
		"current_visibility": {
			"visible_target_ids": PackedStringArray(),
			"visible_event_ids": PackedStringArray(),
		},
	})
	await _wait_frames(12)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("tile_count", 0)) == FIXTURE_SIZE.x * FIXTURE_SIZE.y, "Mission fixture renders all 32x32 tiles")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == int(snapshot.get("tile_count", -1)), "Ground mesh count matches tile count")
	_assert(int(snapshot.get("nature_surface_ground_model_count", -1)) == int(snapshot.get("tile_count", -1)), "Nature ground covers all fixture tiles as flush terrain")
	_assert(int(snapshot.get("nature_surface_detail_model_count", 0)) == 0, "Nature ground no longer uses raised offset detail layers")
	_assert(int(snapshot.get("height_edge_model_count", 0)) > 0, "Mission fixture renders height edge models")
	_assert(int(snapshot.get("cliff_edge_model_count", 0)) > 0, "Mission fixture renders active cliff models")
	_assert(int(snapshot.get("slope_edge_model_count", 0)) > 0, "Mission fixture renders active slope/ramp models")
	var height_edge_entries: Array = Array(snapshot.get("height_edge_visual_entries", []))
	_assert(_entries_use_active_edge_source(height_edge_entries, "kenney_space_kit"), "Mission fixture uses active legacy Space Kit height edges")
	_assert(_cliffs_never_use_ramp_models(height_edge_entries), "Mission fixture keeps ramp models off hard cliffs")
	_assert(int(snapshot.get("nature_prop_model_count", 0)) >= REQUIRED_PROP_IDS.size(), "Mission fixture renders Nature props")
	_assert(int(snapshot.get("surface_tint_count", 0)) > 0, "Mission fixture keeps surface tints")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1, "Selection overlay remains visible")
	_assert(int(snapshot.get("marker_count", 0)) >= 1, "Map marker remains visible")
	_assert(int(snapshot.get("lz_tile_marker_count", 0)) == 1, "LZ marker remains visible")
	_assert(int(snapshot.get("waypoint_tile_marker_count", 0)) >= 1, "Waypoint marker remains visible")
	_assert(int(snapshot.get("area_order_tile_marker_count", 0)) >= 1, "Area order marker remains visible")
	_assert(int(snapshot.get("fow_overlay_tile_count", 0)) > 0, "FoW overlay remains active on Nature fixture")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) <= int(render_budget.get("max_missing_asset_mapping_count", 0)), "Nature fixture has no missing map asset mappings")
	_assert(int(snapshot.get("asset_texture_count", 99)) <= int(render_budget.get("max_texture_fallback_count", 0)), "Strict Nature fixture has no texture fallback assets")
	_assert(int(snapshot.get("map_render_duration_msec", 999999)) <= int(render_budget.get("max_map_render_duration_msec", 8000)), "Nature fixture render duration stays inside project render budget")
	var render_totals: Dictionary = Dictionary(snapshot.get("render_budget_totals", {}))
	_assert(int(render_totals.get("node_count", 0)) <= int(ui_budget.get("max_screen_node_count", 20000)), "Nature fixture node count stays inside broad UI node budget")
	_assert(int(snapshot.get("nature_prop_model_count", 0)) <= 12, "Nature smoke keeps individual prop count bounded")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_report_and_manual_checklist() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Nature Kit smoke report exists")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Nature Kit manual checklist exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Covered Assets", "Performance Gate", "Open Manual Items"]:
		_assert(report.contains(required_text), "Report covers %s" % required_text)
	var checklist: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Fixture", "Visual Readability", "Tactical Overlays", "Gameplay", "Performance"]:
		_assert(checklist.contains(required_text), "Manual checklist covers %s" % required_text)


func _build_nature_fixture_map():
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_255_nature_hill_fixture", FIXTURE_SIZE, Vector2(512.0, 256.0), 64.0, 32.0, 3)
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		tile_data.type_id = "nature_ground_dirt"
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		if int(tile_data.grid_position.x) % 7 == 0:
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
			tile_data.type_id = "nature_ground_sand_dirt"
		elif int(tile_data.grid_position.y) % 9 == 0:
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
			tile_data.type_id = "nature_ground_rock_dirt"
	for x in range(10, 16):
		for y in range(10, 16):
			var hill_tile = map_data.call("get_tile_at_grid", Vector2i(x, y))
			hill_tile.height_level = 2
			hill_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK if x >= 13 else TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
			hill_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	var plateau = map_data.call("get_tile_at_grid", Vector2i(12, 12))
	plateau.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	plateau.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
	for slope_grid in [Vector2i(9, 12), Vector2i(10, 13), Vector2i(12, 9)]:
		var slope_tile = map_data.call("get_tile_at_grid", slope_grid)
		slope_tile.height_level = 1
		slope_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
		slope_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
		slope_tile.type_id = "nature_ground_sand_dirt"
	for ramp_top_grid in [Vector2i(10, 12), Vector2i(11, 13), Vector2i(12, 10)]:
		var ramp_top_tile = map_data.call("get_tile_at_grid", ramp_top_grid)
		ramp_top_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
		ramp_top_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
		ramp_top_tile.type_id = "nature_ground_sand_dirt"
	var prop_positions: Dictionary = {
		Vector2i(10, 9): "nature_tree_blocker",
		Vector2i(13, 9): "nature_rock_cover",
		Vector2i(10, 13): "nature_bush_cover",
		Vector2i(9, 12): "nature_cactus_cover",
		Vector2i(13, 13): "nature_deco_logs",
	}
	for grid_variant in prop_positions.keys():
		var tile_data = map_data.call("get_tile_at_grid", Vector2i(grid_variant))
		catalog.call("apply_type_to_tile", tile_data, String(prop_positions.get(grid_variant)))
	map_data.call("set_marker_position", "task255_objective", map_data.call("get_tile_at_grid", Vector2i(12, 12)).world_position)
	return map_data


func _make_registry_from_map(map_data):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	return registry


func _map_contains_object_type(map_data, object_type_id: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.object_type_id) == object_type_id:
			return true
	return false


func _map_contains_edge_type(map_data, edge_type: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.edge_type) == edge_type:
			return true
	return false


func _map_contains_surface_type(map_data, surface_type: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.surface_type) == surface_type:
			return true
	return false


func _entries_use_active_edge_source(entries: Array, source_id: String) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("source_id", "")) != source_id:
			return false
	return true


func _cliffs_never_use_ramp_models(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("edge_type", "")) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF and String(entry.get("model_path", "")).contains("ramp"):
			return false
	return true


func _is_nature_project_path(path: String) -> bool:
	return path.begins_with("res://Assets/used/terrain/nature_kit_classic/") and not path.contains("C:/") and not path.contains("C:" + "\\")


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
