extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const SURFACE_THEME_CATALOG_PATH: String = "res://data/terrain_surface_visual_theme_catalog.json"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/nature_ground_surface_editor_checklist.md"
const TEMP_ROUNDTRIP_PATH: String = "user://task_253_nature_ground_surface_roundtrip.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_253 Nature Ground Surface Editor Palette Pass ===")
	var terrain_mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var surface_catalog: Dictionary = _load_json(SURFACE_THEME_CATALOG_PATH)
	_test_surface_visual_catalog(terrain_mapping, surface_catalog)
	_test_editor_palette_contract()
	_test_save_load_and_surface_gameplay_contract()
	await _test_runtime_surface_visuals()
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_surface_visual_catalog(terrain_mapping: Dictionary, surface_catalog: Dictionary) -> void:
	_assert(not terrain_mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(not surface_catalog.is_empty(), "Surface visual theme catalog parses")
	_assert(String(Dictionary(terrain_mapping.get("nature_kit", {})).get("surface_visual_theme_catalog", "")) == SURFACE_THEME_CATALOG_PATH, "Terrain mapping links surface visual theme catalog")
	_assert(bool(Dictionary(surface_catalog.get("runtime_contract", {})).get("no_new_surface_types", false)), "Surface visual catalog forbids new gameplay surface types")
	_assert(bool(Dictionary(surface_catalog.get("runtime_contract", {})).get("surface_type_remains_gameplay_truth", false)), "Surface type remains gameplay truth")
	var surface_model_by_surface: Dictionary = Dictionary(surface_catalog.get("surface_model_by_surface", {}))
	for surface_type in [
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND,
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK,
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD,
	]:
		_assert(String(surface_model_by_surface.get(surface_type, "")) == "ground_flat", "Surface keeps Space Kit ground base: %s" % surface_type)
	var detail_by_type: Dictionary = Dictionary(surface_catalog.get("surface_detail_by_tile_type", {}))
	for type_id in ["nature_ground_dirt", "nature_ground_sand_dirt", "nature_ground_rock_dirt", "nature_ground_grass_patch"]:
		_assert(String(detail_by_type.get(type_id, "")).is_empty(), "Nature Boden no longer maps to an offset detail visual: %s" % type_id)
	var type_overrides: Dictionary = Dictionary(surface_catalog.get("tile_type_overrides", {}))
	for type_id in ["nature_ground_dirt", "nature_ground_sand_dirt", "nature_ground_rock_dirt", "nature_ground_grass_patch"]:
		_assert(not String(type_overrides.get(type_id, "")).is_empty(), "Nature Boden maps to flush ground visual: %s" % type_id)
	var models: Dictionary = Dictionary(terrain_mapping.get("models", {}))
	for model_key in ["nature_ground_dirt", "nature_ground_grass_patch", "nature_ground_dirt_river_tile"]:
		var entry: Dictionary = Dictionary(models.get(model_key, {}))
		_assert(String(entry.get("source_id", "")) == "kenney_nature_kit_classic", "Surface model key uses Nature Kit: %s" % model_key)
		_assert(_is_project_loadable(String(entry.get("model_path", ""))), "Surface model resource loads: %s" % model_key)
	for visual_variant in Array(surface_catalog.get("visuals", [])):
		var visual: Dictionary = Dictionary(visual_variant)
		_assert(bool(visual.get("visual_only", false)), "Surface visual is visual-only: %s" % String(visual.get("visual_id", "")))
		_assert(_is_project_loadable(String(visual.get("model_path", ""))), "Surface visual path loads: %s" % String(visual.get("visual_id", "")))


func _test_editor_palette_contract() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain tile catalog loads")
	if catalog == null:
		return
	_assert(_catalog_has_palette_group(catalog, "nature_ground"), "Editor catalog exposes Nature Boden palette group")
	for type_id in ["nature_ground_dirt", "nature_ground_sand_dirt", "nature_ground_rock_dirt", "nature_ground_grass_patch"]:
		_assert(bool(catalog.call("has_type", type_id)), "Catalog has Nature surface type: %s" % type_id)
		_assert(bool(catalog.call("preserves_hill_fields_when_applied", type_id)), "Nature surface type preserves hill fields: %s" % type_id)

	var hill_tile = _make_hill_tile(Vector2i.ZERO)
	hill_tile.object_type_id = "technik_generator_se"
	hill_tile.cover_value = 45
	hill_tile.blocks_los = true
	hill_tile.walkable = false
	_assert(bool(catalog.call("apply_type_to_tile", hill_tile, "nature_ground_sand_dirt")), "Catalog applies Nature sand/dirt surface")
	_assert(String(hill_tile.type_id) == "nature_ground_sand_dirt", "Nature surface palette writes visual type_id")
	_assert(String(hill_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND, "Nature surface palette writes selected surface_type")
	_assert(int(hill_tile.height_level) == 2, "Nature surface palette preserves height_level")
	_assert(String(hill_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, "Nature surface palette preserves edge_type")
	_assert(String(hill_tile.object_type_id) == "technik_generator_se", "Nature surface palette preserves object_type_id")
	_assert(int(hill_tile.cover_value) == 45 and bool(hill_tile.blocks_los) and not bool(hill_tile.walkable), "Nature surface palette preserves cover, LOS and walkable state")

	var legacy_rock_tile = _make_hill_tile(Vector2i(1, 0))
	legacy_rock_tile.type_id = "rock_large"
	legacy_rock_tile.object_height = 2
	legacy_rock_tile.cover_value = 40
	legacy_rock_tile.blocks_los = true
	legacy_rock_tile.walkable = false
	_assert(bool(catalog.call("apply_type_to_tile", legacy_rock_tile, "ground_flat")), "Ground brush applies under a legacy rock")
	_assert(String(legacy_rock_tile.type_id) == "rock_large", "Ground brush preserves legacy rock type_id")
	_assert(String(legacy_rock_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, "Ground brush still sets ground surface")
	_assert(int(legacy_rock_tile.object_height) == 2 and int(legacy_rock_tile.cover_value) == 40 and bool(legacy_rock_tile.blocks_los) and not bool(legacy_rock_tile.walkable), "Ground brush preserves rock gameplay fields")
	_assert(bool(catalog.call("apply_type_to_tile", legacy_rock_tile, "nature_ground_sand_dirt")), "Nature surface brush applies under a legacy rock")
	_assert(String(legacy_rock_tile.type_id) == "rock_large", "Nature surface brush preserves legacy rock type_id")
	_assert(String(legacy_rock_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND, "Nature surface brush changes only the surface under the rock")


func _test_save_load_and_surface_gameplay_contract() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_253_nature_surface_roundtrip", Vector2i(3, 2), Vector2.ZERO, 64.0, 32.0, 3)
	_assert(catalog != null and map_data != null, "Roundtrip catalog and map instantiate")
	if catalog == null or map_data == null:
		return
	var sand_hill = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	_configure_hill_tile(sand_hill, 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)
	_assert(bool(catalog.call("apply_type_to_tile", sand_hill, "nature_ground_sand_dirt")), "Roundtrip applies Nature sand surface to hill")
	var rock_hill = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	_configure_hill_tile(rock_hill, 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)
	_assert(bool(catalog.call("apply_type_to_tile", rock_hill, "nature_ground_rock_dirt")), "Roundtrip applies Nature rock surface to hill")

	_assert(map_data.call("save_to_file", TEMP_ROUNDTRIP_PATH) == OK, "Nature surface map saves")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", TEMP_ROUNDTRIP_PATH)
	var reloaded_sand = reloaded.call("get_tile_at_grid", Vector2i(0, 0)) if reloaded != null else null
	var reloaded_rock = reloaded.call("get_tile_at_grid", Vector2i(1, 0)) if reloaded != null else null
	_assert(_tile_has_fields(reloaded_sand, "nature_ground_sand_dirt", TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND, 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE), "Nature sand surface survives Save/Load")
	_assert(_tile_has_fields(reloaded_rock, "nature_ground_rock_dirt", TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK, 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF), "Nature rock surface survives Save/Load")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND) > TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND), "Sand gameplay movement cost stays slower than ground")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD) < TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND), "Road gameplay movement cost stays faster than ground")


func _test_runtime_surface_visuals() -> void:
	var map_data = _build_surface_fixture_map()
	var center_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(2, 2)).world_position
	var slope_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(1, 2)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_selected_grid_positions", [Vector2i(2, 2)])
	primary_view.call("set_mission_drop_visual_state", {
		"has_lz_position": true,
		"lz_position": slope_world,
	})
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"plan_dicts": [{
			"fireteam_id": "blue",
			"phase": 1,
			"waypoints": [{"target_position": center_world, "command_type": "move"}],
		}],
		"area_order_dicts": [{
			"area_order_id": "nature_surface_area",
			"command_type": "defend",
			"tile_world_positions": [center_world],
		}],
	})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("surface_visual_entries", []))
	var detail_entries: Array = Array(snapshot.get("surface_detail_visual_entries", []))
	_assert(bool(snapshot.get("surface_visual_theme_catalog_loaded", false)), "Runtime loads surface visual theme catalog")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == int(snapshot.get("tile_count", -1)), "Runtime still renders one ground mesh per tile")
	_assert(int(snapshot.get("nature_surface_ground_model_count", -1)) >= 4, "Runtime renders Nature Boden as flush ground visuals")
	_assert(int(snapshot.get("nature_surface_detail_model_count", 0)) == 0, "Runtime no longer stacks raised Nature Boden detail visuals")
	_assert(entries.size() == int(snapshot.get("tile_count", -1)), "Runtime exposes one surface visual entry per tile")
	_assert(_entries_include_surface_types(entries, [TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD]), "Runtime entries cover ground, sand, rock and road")
	_assert(_entries_include_model_key(entries, "ground_flat"), "Runtime keeps standard Boden on Space Kit ground_flat")
	_assert(_entries_include_model_key(entries, "nature_ground_grass_patch"), "Runtime renders grass patch as a Nature ground surface")
	_assert(detail_entries.is_empty(), "Runtime has no raised Nature detail leftovers")
	_assert(int(snapshot.get("surface_tint_count", 0)) >= 3, "Non-ground surface tints remain visible")
	_assert(int(snapshot.get("elevated_surface_tint_count", 0)) >= 2, "Elevated surface tints remain visible")
	_assert(int(snapshot.get("tile_grid_line_count", 0)) > 0, "Grid lines remain visible")
	_assert(int(snapshot.get("tile_grid_line_count", 0)) >= _expected_min_grid_line_count(map_data), "Grid covers the full editor map dimensions")
	_assert(_editor_grid_material_is_depth_tested(primary_view), "Grid uses depth-tested editor helper material")
	_assert(int(snapshot.get("marker_count", 0)) >= 1, "Map markers remain visible")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1, "Selection remains visible")
	_assert(int(snapshot.get("waypoint_tile_marker_count", 0)) >= 1, "Waypoint tiles remain visible")
	_assert(int(snapshot.get("area_order_tile_marker_count", 0)) >= 1, "Area-order tiles remain visible")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 0)) == 0, "Nature surface fixture has no missing mappings")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Nature ground manual visual checklist exists")
	var checklist_text: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Editor Palette", "Mission View", "Tactical Overlays", "Gameplay Boundary", "Missing-Mapping"]:
		_assert(checklist_text.contains(required_text), "Manual checklist covers %s" % required_text)


func _build_surface_fixture_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_253_nature_surface_fixture", Vector2i(5, 5), Vector2(256.0, 128.0), 64.0, 32.0, 3)
	var ground_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	ground_tile.type_id = "nature_ground_dirt"
	ground_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
	var sand_slope = map_data.call("get_tile_at_grid", Vector2i(1, 2))
	_configure_hill_tile(sand_slope, 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND)
	sand_slope.type_id = "nature_ground_sand_dirt"
	var rock_cliff = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	_configure_hill_tile(rock_cliff, 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK)
	rock_cliff.type_id = "nature_ground_rock_dirt"
	var road_plateau = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	_configure_hill_tile(road_plateau, 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD)
	var grass_detail = map_data.call("get_tile_at_grid", Vector2i(3, 2))
	_configure_hill_tile(grass_detail, 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)
	grass_detail.type_id = "nature_ground_grass_patch"
	map_data.call("set_marker_position", "nature_surface_marker", Vector2(road_plateau.world_position))
	return map_data


func _make_hill_tile(grid_position: Vector2i):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": Vector2.ZERO,
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0,
		"height_level": 2,
		"object_height": 0,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
		"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE,
	})


func _configure_hill_tile(tile_data, height_level: int, edge_type: String, surface_type: String) -> void:
	tile_data.height_level = height_level
	tile_data.edge_type = edge_type
	tile_data.surface_type = surface_type
	tile_data.walkable = true
	tile_data.blocks_los = false
	tile_data.cover_value = 0
	tile_data.object_height = 0
	tile_data.object_type_id = ""


func _catalog_has_palette_group(catalog, group_id: String) -> bool:
	for group_variant in Array(catalog.call("get_palette_groups")):
		var group: Dictionary = Dictionary(group_variant)
		if String(group.get("group_id", "")) == group_id:
			return true
	return false


func _tile_has_fields(tile_data, type_id: String, surface_type: String, height_level: int, edge_type: String) -> bool:
	if tile_data == null:
		return false
	return (
		String(tile_data.type_id) == type_id
		and String(tile_data.surface_type) == surface_type
		and int(tile_data.height_level) == height_level
		and String(tile_data.edge_type) == edge_type
	)


func _entries_include_surface_types(entries: Array, surface_types: Array) -> bool:
	for surface_type in surface_types:
		var found: bool = false
		for entry_variant in entries:
			if String(Dictionary(entry_variant).get("surface_type", "")) == String(surface_type):
				found = true
				break
		if not found:
			return false
	return true


func _entries_include_model_key(entries: Array, model_key: String) -> bool:
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("model_key", "")) == model_key:
			return true
	return false


func _entries_are_space_kit_ground(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("model_key", "")) != "ground_flat":
			return false
		if bool(entry.get("is_nature_kit", false)):
			return false
	return true


func _entries_are_nature_kit(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if not bool(Dictionary(entry_variant).get("is_nature_kit", false)):
			return false
	return true


func _expected_min_grid_line_count(map_data) -> int:
	if map_data == null:
		return 0
	var grid_size: Vector2i = Vector2i(map_data.call("get_grid_size"))
	return (grid_size.x * (grid_size.y + 1)) + (grid_size.y * (grid_size.x + 1))


func _editor_grid_material_is_depth_tested(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var grid_node := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D/TileGridLines3D") as MeshInstance3D
	if grid_node == null or grid_node.mesh == null or grid_node.mesh.get_surface_count() <= 0:
		return false
	var material := grid_node.mesh.surface_get_material(0) as StandardMaterial3D
	return material != null \
		and not material.no_depth_test \
		and material.cull_mode == BaseMaterial3D.CULL_DISABLED \
		and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED


func _is_project_loadable(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	var allowed_root: bool = normalized_path.begins_with("res://Assets/used/terrain/nature_kit_classic/") \
		or normalized_path.begins_with("res://Assets/curated/kenney/space_station/") \
		or normalized_path.begins_with("res://Assets/curated/kenney/modular_space/")
	return allowed_root \
		and not normalized_path.contains("C:/") \
		and not normalized_path.contains("C:" + "\\") \
		and ResourceLoader.exists(normalized_path)


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
