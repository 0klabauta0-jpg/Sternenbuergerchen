extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")

const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const NATURE_CATALOG_PATH: String = "res://data/nature_kit_asset_catalog.json"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/nature_cliff_hill_edge_visual_checklist.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_252 Nature Cliff Hill Edge Visual Mapping ===")
	var terrain_mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var nature_catalog: Dictionary = _load_json(NATURE_CATALOG_PATH)
	_test_mapping_contract(terrain_mapping, nature_catalog)
	await _test_runtime_nature_edge_visuals()
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_mapping_contract(terrain_mapping: Dictionary, nature_catalog: Dictionary) -> void:
	_assert(not terrain_mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(not nature_catalog.is_empty(), "Nature Kit catalog parses")
	var nature_section: Dictionary = Dictionary(terrain_mapping.get("nature_kit", {}))
	_assert(String(nature_section.get("source_id", "")) == "kenney_nature_kit_classic", "Terrain mapping references Nature Kit source")
	_assert(String(nature_section.get("asset_catalog", "")) == NATURE_CATALOG_PATH, "Terrain mapping links Nature Kit asset catalog")
	_assert(String(nature_section.get("active_height_edge_theme", "")) == "legacy_space", "Active V1 height-edge theme is documented")
	_assert(String(Dictionary(nature_section.get("surface_theme_candidates", {})).get("rock", "")) == "grey", "Grey candidate theme is documented for rock")
	var models: Dictionary = Dictionary(terrain_mapping.get("models", {}))
	for active_key in ["cliff_straight", "cliff_corner", "slope"]:
		var entry: Dictionary = Dictionary(models.get(active_key, {}))
		_assert(String(entry.get("source_id", "")) == "kenney_space_kit", "Active edge key uses legacy Space Kit: %s" % active_key)
		_assert(_is_project_loadable(String(entry.get("model_path", ""))), "Active edge model loads: %s" % active_key)
	_assert(String(Dictionary(models.get("slope", {})).get("edge_role", "")) == "slope_steps", "Active slope key maps to steps role")
	_assert(String(Dictionary(models.get("slope", {})).get("model_path", "")).contains("terrain_rampLarge"), "Active slope uses the older ramp model")
	_assert(String(Dictionary(models.get("cliff_straight", {})).get("model_path", "")).contains("terrain_sideCliff"), "Active cliff straight uses the older cliff model")
	_assert(String(Dictionary(models.get("cliff_corner", {})).get("model_path", "")).contains("terrain_sideCorner"), "Active cliff corner uses the older cliff corner model")
	for alias_key in [
		"nature_cliff_brown_straight",
		"nature_cliff_brown_outer_corner",
		"nature_cliff_brown_inner_corner",
		"nature_slope_brown_steps",
		"nature_cliff_grey_straight",
		"nature_cliff_grey_outer_corner",
		"nature_cliff_grey_inner_corner",
		"nature_slope_grey_steps",
	]:
		var alias_entry: Dictionary = Dictionary(models.get(alias_key, {}))
		_assert(String(alias_entry.get("source_id", "")) == "kenney_nature_kit_classic", "Nature alias maps to Nature Kit: %s" % alias_key)
		_assert(_is_project_loadable(String(alias_entry.get("model_path", ""))), "Nature alias resource loads: %s" % alias_key)
	var catalog_assets: Dictionary = _catalog_assets_by_id(nature_catalog)
	for required_id in [
		"nature_cliff_brown_straight",
		"nature_cliff_brown_outer_corner",
		"nature_cliff_brown_inner_corner",
		"nature_cliff_brown_steps",
		"nature_cliff_grey_straight",
		"nature_cliff_grey_outer_corner",
		"nature_cliff_grey_inner_corner",
		"nature_cliff_grey_steps",
	]:
		_assert(catalog_assets.has(required_id), "Nature catalog keeps candidate asset ID: %s" % required_id)


func _test_runtime_nature_edge_visuals() -> void:
	var map_data = _build_edge_fixture_map()
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("height_edge_visual_entries", []))
	_assert(int(snapshot.get("height_edge_model_count", 0)) > 0, "Runtime renders height edge models")
	_assert(_entries_use_active_edge_source(entries, "kenney_space_kit"), "Runtime uses the active legacy Space Kit edge source")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 0)) == 0, "Nature edge fixture has no missing mappings")
	_assert(_entries_include_role(entries, "cliff_straight"), "Runtime has straight cliff edge entries")
	_assert(_entries_include_role(entries, "cliff_outer_corner"), "Runtime has cliff outer-corner entries")
	_assert(_entries_include_role(entries, "slope_steps"), "Runtime has slope step entries")
	_assert(_slope_steps_only_on_slope(entries), "Step visuals are used only for slope edges")
	_assert(_cliffs_never_use_ramp_models(entries), "Hard cliff edges never use ramp models")
	_assert(_height_edges_anchor_to_lower_neighbor(entries), "Height edges anchor between lower neighbor and upper surface")
	_assert(_plateau_interior_has_no_edge(primary_view, Vector2i(2, 2)), "Plateau interior stays free of false edge models")
	_assert(_pathfinder_keeps_cliff_and_slope_rules(map_data), "Visual remap does not alter TASK_182 movement semantics")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Nature cliff manual visual checklist exists")
	var checklist_text: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Cliff", "Slope", "Theme", "Walkability", "Missing-Mapping"]:
		_assert(checklist_text.contains(required_text), "Manual checklist covers %s" % required_text)


func _build_edge_fixture_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_252_nature_edge_fixture", Vector2i(5, 5), Vector2(256.0, 128.0), 64.0, 32.0, 3)
	for x in range(1, 4):
		for y in range(1, 4):
			var tile_data = map_data.call("get_tile_at_grid", Vector2i(x, y))
			tile_data.height_level = 2
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	var center = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	center.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	center.object_type_id = "wall_straight_se"
	center.object_height = 2
	center.blocks_los = true
	center.walkable = false
	var sand_slope = map_data.call("get_tile_at_grid", Vector2i(1, 2))
	sand_slope.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	sand_slope.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
	var rock_cliff = map_data.call("get_tile_at_grid", Vector2i(3, 2))
	rock_cliff.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	rock_cliff.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
	return map_data


func _pathfinder_keeps_cliff_and_slope_rules(map_data) -> bool:
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	terrain_registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		terrain_registry.call("register_tile", tile_data)
	var slope_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 2), Vector2i(0, 2), terrain_registry))
	var cliff_cost: float = float(pathfinder.call("get_step_cost", Vector2i(3, 2), Vector2i(4, 2), terrain_registry))
	terrain_registry.free()
	return slope_cost < INF and is_inf(cliff_cost)


func _entries_are_nature_kit(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("is_nature_kit", false)):
			return false
	return true


func _entries_use_active_edge_source(entries: Array, source_id: String) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("source_id", "")) != source_id:
			return false
	return true


func _entries_include_role(entries: Array, role: String) -> bool:
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("edge_role", "")) == role:
			return true
	return false


func _slope_steps_only_on_slope(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("edge_role", "")).begins_with("slope") and String(entry.get("edge_type", "")) != TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
			return false
	return true


func _cliffs_never_use_ramp_models(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("edge_type", "")) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF and String(entry.get("model_path", "")).contains("ramp"):
			return false
	return true


func _height_edges_anchor_to_lower_neighbor(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var base_y: float = float(entry.get("base_y", INF))
		var top_y: float = float(entry.get("top_y", -INF))
		var height_span: float = float(entry.get("height_span", 0.0))
		if base_y >= top_y:
			return false
		if not _float_eq(height_span, top_y - base_y):
			return false
	return true


func _plateau_interior_has_no_edge(primary_view: Node, grid_position: Vector2i) -> bool:
	var map_root = primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D") if primary_view != null else null
	if map_root == null:
		return false
	var grid_token: String = "_%d_%d_" % [grid_position.x, grid_position.y]
	for child in map_root.get_children():
		var child_name: String = String(child.name)
		if (child_name.begins_with("HeightEdge_") or child_name.begins_with("HeightCorner_")) and child_name.contains(grid_token):
			return false
	return true


func _catalog_assets_by_id(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for asset_variant in Array(catalog.get("assets", [])):
		if typeof(asset_variant) != TYPE_DICTIONARY:
			continue
		var asset: Dictionary = Dictionary(asset_variant)
		var asset_id: String = String(asset.get("asset_id", "")).strip_edges()
		if not asset_id.is_empty():
			result[asset_id] = asset
	return result


func _is_project_loadable(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	return (
		normalized_path.begins_with("res://Assets/used/terrain/nature_kit_classic/")
		or normalized_path.begins_with("res://Assets/kenney_space-kit/")
	) \
		and not normalized_path.contains("C:/") \
		and not normalized_path.contains("C:" + "\\") \
		and ResourceLoader.exists(normalized_path)


func _float_eq(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= 0.001


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
