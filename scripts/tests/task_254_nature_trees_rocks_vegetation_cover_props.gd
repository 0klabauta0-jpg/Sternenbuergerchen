extends SceneTree

const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const TERRAIN_OBJECT_CATALOG_PATH: String = "res://data/terrain_object_catalog.json"
const NATURE_CATALOG_PATH: String = "res://data/nature_kit_asset_catalog.json"
const RULES_DOC_PATH: String = "res://docs/dev/nature_terrain_prop_rules.md"
const TEMP_ROUNDTRIP_PATH: String = "user://task_254_nature_props_roundtrip.json"

const REQUIRED_PROPS: Array = [
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
	print("=== TASK_254 Nature Trees Rocks Vegetation Cover Props ===")
	var object_catalog: Dictionary = _load_json(TERRAIN_OBJECT_CATALOG_PATH)
	var terrain_mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var nature_catalog: Dictionary = _load_json(NATURE_CATALOG_PATH)
	_test_catalog_contract(object_catalog, terrain_mapping, nature_catalog)
	_test_editor_object_layer_contract()
	_test_save_load_roundtrip()
	_test_gameplay_contract()
	await _test_runtime_visuals()
	_test_rules_documentation()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_contract(object_catalog: Dictionary, terrain_mapping: Dictionary, nature_catalog: Dictionary) -> void:
	_assert(not object_catalog.is_empty(), "Terrain object catalog parses")
	_assert(not terrain_mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(not nature_catalog.is_empty(), "Nature Kit catalog parses")
	var runtime_contract: Dictionary = Dictionary(object_catalog.get("runtime_contract", {}))
	_assert(String(runtime_contract.get("gameplay_truth", "")).contains("TerrainTileData"), "Object catalog names TerrainTileData as gameplay truth")
	_assert(bool(runtime_contract.get("mesh_size_not_gameplay_truth", false)), "Object catalog forbids mesh-size gameplay truth")
	var object_entries: Dictionary = _object_entries_by_type(object_catalog)
	var model_entries: Dictionary = Dictionary(terrain_mapping.get("models", {}))
	for prop_id in REQUIRED_PROPS:
		var object_entry: Dictionary = Dictionary(object_entries.get(prop_id, {}))
		var model_entry: Dictionary = Dictionary(model_entries.get(prop_id, {}))
		_assert(not object_entry.is_empty(), "Object catalog has Nature prop: %s" % prop_id)
		_assert(String(model_entry.get("source_id", "")) == "kenney_nature_kit_classic", "3D mapping uses Nature Kit for prop: %s" % prop_id)
		_assert(_is_project_loadable(String(model_entry.get("model_path", ""))), "Nature prop model loads: %s" % prop_id)
		_assert(String(object_entry.get("model_key", "")) == prop_id, "Object catalog model key matches type: %s" % prop_id)
		_assert(_nature_asset_exists(nature_catalog, String(object_entry.get("source_asset_id", ""))), "Nature source asset exists for prop: %s" % prop_id)
	_assert(String(Dictionary(object_entries.get("nature_deco_logs", {})).get("gameplay_role", "")) == "visual_only_no_cover", "Deco prop is documented as no gameplay cover")


func _test_editor_object_layer_contract() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain tile catalog loads")
	if catalog == null:
		return
	_assert(_catalog_has_palette_group(catalog, "nature_props"), "Editor catalog exposes Nature Props palette group")
	for prop_id in REQUIRED_PROPS:
		_assert(bool(catalog.call("has_type", prop_id)), "Editor catalog has prop type: %s" % prop_id)
		_assert(bool(catalog.call("is_object_layer_type", prop_id)), "Nature prop is object-layer type: %s" % prop_id)

	var hill_tile = _make_hill_tile(Vector2i.ZERO)
	_assert(bool(catalog.call("apply_type_to_tile", hill_tile, "nature_tree_blocker")), "Editor catalog applies tree blocker")
	_assert(String(hill_tile.type_id) == "nature_ground_dirt", "Nature prop placement preserves base terrain type_id")
	_assert(String(hill_tile.object_type_id) == "nature_tree_blocker", "Nature prop placement writes object_type_id")
	_assert(int(hill_tile.height_level) == 2 and String(hill_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, "Nature prop placement preserves height and edge")
	_assert(String(hill_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND, "Nature prop placement preserves surface")
	_assert(not bool(hill_tile.walkable) and bool(hill_tile.blocks_los), "Tree blocker applies walkability and LOS role")
	_assert(int(hill_tile.cover_value) == 65 and int(hill_tile.object_height) == 3, "Tree blocker applies cover and object height")
	hill_tile.object_type_id = ""
	_assert(int(hill_tile.height_level) == 2 and String(hill_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND and String(hill_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, "Removing Nature prop preserves terrain fields")


func _test_save_load_roundtrip() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_254_nature_props_roundtrip", Vector2i(5, 2), Vector2.ZERO, 64.0, 32.0, 3)
	_assert(catalog != null and map_data != null, "Roundtrip catalog and map instantiate")
	if catalog == null or map_data == null:
		return
	for index in range(REQUIRED_PROPS.size()):
		var tile_data = map_data.call("get_tile_at_grid", Vector2i(index, 0))
		_configure_base_hill_tile(tile_data, index % 3, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE if index % 2 == 0 else TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND if index % 2 == 0 else TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK)
		_assert(bool(catalog.call("apply_type_to_tile", tile_data, String(REQUIRED_PROPS[index]))), "Roundtrip applies prop: %s" % String(REQUIRED_PROPS[index]))
	_assert(map_data.call("save_to_file", TEMP_ROUNDTRIP_PATH) == OK, "Nature prop map saves")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", TEMP_ROUNDTRIP_PATH)
	_assert(reloaded != null, "Nature prop map reloads")
	if reloaded == null:
		return
	for index in range(REQUIRED_PROPS.size()):
		var tile_data = reloaded.call("get_tile_at_grid", Vector2i(index, 0))
		_assert(tile_data != null and String(tile_data.object_type_id) == String(REQUIRED_PROPS[index]), "Roundtrip preserves object_type_id: %s" % String(REQUIRED_PROPS[index]))
		_assert(tile_data != null and int(tile_data.height_level) == index % 3, "Roundtrip preserves prop tile height: %s" % String(REQUIRED_PROPS[index]))


func _test_gameplay_contract() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0)
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var los_system = LINE_OF_SIGHT_SCRIPT.new()
	var prop_by_grid: Dictionary = {
		Vector2i(1, 0): "nature_tree_blocker",
		Vector2i(1, 1): "nature_bush_cover",
		Vector2i(1, 2): "nature_cactus_cover",
		Vector2i(1, 3): "nature_deco_logs",
	}
	for y in range(4):
		for x in range(3):
			var grid := Vector2i(x, y)
			var tile_data = _make_registry_tile(registry, grid)
			if prop_by_grid.has(grid):
				catalog.call("apply_type_to_tile", tile_data, String(prop_by_grid.get(grid)))
			registry.call("register_tile", tile_data)
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(1, 0), registry)), "Tree blocker blocks movement")
	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(0, 1), Vector2i(1, 1), registry)), "Bush cover stays walkable")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(0, 2), Vector2i(1, 2), registry)), "Cactus cover blocks movement")
	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(0, 3), Vector2i(1, 3), registry)), "Deco prop stays walkable")
	_assert(not bool(los_system.call("has_line_of_sight_with_terrain", registry.call("grid_to_world", Vector2i(0, 0)), registry.call("grid_to_world", Vector2i(2, 0)), registry, 1000.0)), "Tree blocker blocks LOS through TerrainTileData")
	_assert(bool(los_system.call("has_line_of_sight_with_terrain", registry.call("grid_to_world", Vector2i(0, 1)), registry.call("grid_to_world", Vector2i(2, 1)), registry, 1000.0)), "Bush cover does not block LOS")
	_assert(int(registry.call("get_cover_at", Vector2i(1, 0))) == 65, "Tree cover value comes from TerrainRegistry")
	_assert(int(registry.call("get_cover_at", Vector2i(1, 1))) == 25, "Bush cover value comes from TerrainRegistry")
	_assert(int(registry.call("get_cover_at", Vector2i(1, 3))) == 0, "Deco prop has no cover")
	registry.free()


func _test_runtime_visuals() -> void:
	var map_data = _build_visual_fixture_map()
	var target_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(2, 2)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_selected_grid_positions", [Vector2i(2, 2)])
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"plan_dicts": [{
			"fireteam_id": "blue",
			"phase": 1,
			"waypoints": [{"target_position": target_world, "command_type": "move"}],
		}],
	})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("nature_prop_visual_entries", []))
	_assert(int(snapshot.get("nature_prop_model_count", 0)) >= REQUIRED_PROPS.size(), "Runtime renders Nature prop models")
	_assert(_role_count(snapshot, "tree_blocker") >= 1, "Runtime counts tree blocker role")
	_assert(_role_count(snapshot, "rock_cover") >= 1, "Runtime counts rock cover role")
	_assert(_role_count(snapshot, "bush_cover") >= 1, "Runtime counts bush cover role")
	_assert(_role_count(snapshot, "cactus_cover") >= 1, "Runtime counts cactus cover role")
	_assert(_role_count(snapshot, "deco_small") >= 1, "Runtime counts deco role")
	_assert(_entries_cover_props(entries, REQUIRED_PROPS), "Runtime exposes Nature prop visual entries")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 0)) == 0, "Nature prop fixture has no missing mappings")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1 and int(snapshot.get("waypoint_tile_marker_count", 0)) >= 1, "Selection and waypoint overlays remain visible")
	for prop_id in REQUIRED_PROPS:
		var node := _find_map_node(primary_view, "Asset_%s_" % prop_id) as Node3D
		_assert(node != null and node.position.y >= _expected_min_prop_y(map_data, prop_id), "Prop anchors on terrain top: %s" % prop_id)
	primary_view.queue_free()
	await _wait_frames(2)


func _test_rules_documentation() -> void:
	_assert(FileAccess.file_exists(RULES_DOC_PATH), "Nature prop rules documentation exists")
	var text: String = _read_text(RULES_DOC_PATH)
	for required_text in ["Gameplay Truth", "nature_tree_blocker", "nature_rock_cover", "nature_bush_cover", "nature_cactus_cover", "nature_deco_logs", "Mesh size"]:
		_assert(text.contains(required_text), "Rules documentation covers %s" % required_text)


func _build_visual_fixture_map():
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_254_nature_props_fixture", Vector2i(5, 5), Vector2(256.0, 128.0), 64.0, 32.0, 3)
	var placement: Dictionary = {
		Vector2i(1, 1): "nature_tree_blocker",
		Vector2i(2, 1): "nature_rock_cover",
		Vector2i(1, 2): "nature_bush_cover",
		Vector2i(2, 2): "nature_cactus_cover",
		Vector2i(3, 2): "nature_deco_logs",
	}
	for grid_variant in placement.keys():
		var grid := Vector2i(grid_variant)
		var tile_data = map_data.call("get_tile_at_grid", grid)
		_configure_base_hill_tile(tile_data, (grid.x + grid.y) % 3, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE if grid.x == 1 else TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND if grid.y >= 2 else TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)
		catalog.call("apply_type_to_tile", tile_data, String(placement.get(grid)))
	map_data.call("set_marker_position", "nature_prop_marker", map_data.call("get_tile_at_grid", Vector2i(2, 2)).world_position)
	return map_data


func _object_entries_by_type(object_catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in Array(object_catalog.get("object_types", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var type_id: String = String(entry.get("type_id", "")).strip_edges()
		if not type_id.is_empty():
			result[type_id] = entry
	return result


func _catalog_has_palette_group(catalog, group_id: String) -> bool:
	for group_variant in Array(catalog.call("get_palette_groups")):
		if String(Dictionary(group_variant).get("group_id", "")) == group_id:
			return true
	return false


func _nature_asset_exists(nature_catalog: Dictionary, asset_id: String) -> bool:
	if asset_id.strip_edges().is_empty():
		return false
	for entry_variant in Array(nature_catalog.get("assets", [])):
		if String(Dictionary(entry_variant).get("asset_id", "")) == asset_id:
			return true
	return false


func _entries_cover_props(entries: Array, required_props: Array) -> bool:
	for prop_id in required_props:
		var found: bool = false
		for entry_variant in entries:
			if String(Dictionary(entry_variant).get("visual_type_id", "")) == String(prop_id):
				found = true
				break
		if not found:
			return false
	return true


func _role_count(snapshot: Dictionary, role: String) -> int:
	return int(Dictionary(snapshot.get("nature_prop_role_counts", {})).get(role, 0))


func _expected_min_prop_y(map_data, prop_id: String) -> float:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.object_type_id) == prop_id:
			return float(int(tile_data.height_level)) * 0.25
	return 0.0


func _find_map_node(primary_view: Node, name_prefix: String) -> Node:
	var map_root = primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D") if primary_view != null else null
	if map_root == null:
		return null
	return _find_child_by_prefix(map_root, name_prefix)


func _find_child_by_prefix(node: Node, name_prefix: String) -> Node:
	for child in node.get_children():
		if String(child.name).begins_with(name_prefix):
			return child
		var nested := _find_child_by_prefix(child, name_prefix)
		if nested != null:
			return nested
	return null


func _make_hill_tile(grid_position: Vector2i):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "nature_ground_dirt",
		"grid_position": grid_position,
		"world_position": Vector2.ZERO,
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0,
		"height_level": 2,
		"object_height": 0,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND,
		"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE,
	})


func _make_registry_tile(registry, grid_position: Vector2i):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": registry.call("grid_to_world", grid_position),
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0,
		"height_level": 0,
		"object_height": 0,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
		"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE,
	})


func _configure_base_hill_tile(tile_data, height_level: int, edge_type: String, surface_type: String) -> void:
	tile_data.type_id = "nature_ground_dirt"
	tile_data.object_type_id = ""
	tile_data.height_level = height_level
	tile_data.edge_type = edge_type
	tile_data.surface_type = surface_type
	tile_data.walkable = true
	tile_data.blocks_los = false
	tile_data.cover_value = 0
	tile_data.object_height = 0


func _is_project_loadable(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	return normalized_path.begins_with("res://Assets/used/terrain/nature_kit_classic/") \
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
