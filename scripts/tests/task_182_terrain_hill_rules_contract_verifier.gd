extends SceneTree

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const MAP_EDITOR_HEIGHT_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_height_tool.gd")

const RULE_DOC_PATH: String = "res://docs/dev/terrain_height_hill_rules.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_182 Terrain Hill Rules Contract Verifier ===")
	_test_rule_document_sections()
	_test_rule_document_required_cases()
	_test_terrain_tile_data_contract()
	_test_pathfinder_and_authoring_anchors()
	_test_los_and_visual_contract_anchors()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_182: FAILED")
		quit(1)
	else:
		print("TASK_182: ALL PASSED")
		quit(0)


func _test_rule_document_sections() -> void:
	var text: String = _read_text_file(RULE_DOC_PATH)
	_assert(not text.is_empty(), "Terrain hill rules document exists")
	for section in [
		"# Terrain Height and Hill Rules",
		"## Datenfelder",
		"## Zielregeln",
		"## Bewegungsregeln",
		"## LOS, Cover und Combat",
		"## Visuals",
		"## Editor-Authoring",
		"## Save/Load",
		"## Regelmatrix",
		"## Bestandskonflikte",
		"## Verifier-Strategie",
	]:
		_assert(text.contains(section), "Rules document contains section %s" % section)


func _test_rule_document_required_cases() -> void:
	var text: String = _read_text_file(RULE_DOC_PATH)
	for required_text in [
		"height_level",
		"object_height",
		"height_level + object_height",
		"surface_type",
		"edge_type",
		"edge_type = slope",
		"edge_type = cliff",
		"edge_type = none",
		"Cliffs are hard blockers",
		"object_base_height = height_level",
		"neighbor.height_level < current.height_level",
		"Sand",
		"Road",
		"Rock",
		"Wand auf Huegel",
		"Fels auf Huegel",
		"Plateau-Innenbereich",
		"TASK_183",
		"TASK_184",
		"TASK_185",
	]:
		_assert(text.contains(required_text), "Rules document contains required contract text: %s" % required_text)


func _test_terrain_tile_data_contract() -> void:
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_GROUND") == "ground", "TerrainTileData defines ground surface")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD") == "road", "TerrainTileData defines road surface")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND") == "sand", "TerrainTileData defines sand surface")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROCK") == "rock", "TerrainTileData defines rock surface")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF") == "cliff", "TerrainTileData defines cliff edge")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE") == "slope", "TerrainTileData defines slope edge")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE") == "none", "TerrainTileData defines none edge")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("DEFAULT_HEIGHT_LEVEL") == 0, "TerrainTileData default height is zero")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get("DEFAULT_OBJECT_HEIGHT") == 0, "TerrainTileData default object height is zero")

	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_speed_factor", "ground")), 1.0), "Ground speed factor is 1.0")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_speed_factor", "road")), 1.4), "Road speed factor is 1.4")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_speed_factor", "sand")), 0.6), "Sand speed factor is 0.6")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_speed_factor", "rock")), 0.8), "Rock speed factor is 0.8")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_path_cost", "ground")), 1.0), "Ground path cost is 1.0")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_path_cost", "road")), 0.7), "Road path cost is 0.7")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_path_cost", "sand")), 1.5), "Sand path cost is 1.5")
	_assert(_float_eq(float(TERRAIN_TILE_DATA_SCRIPT.call("get_surface_path_cost", "rock")), 1.3), "Rock path cost is 1.3")

	var clamped_tile = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "contract_clamp",
		"height_level": 99,
		"object_height": 99,
		"cover_value": 999,
		"edge_type": "invalid_edge",
	})
	_assert(int(clamped_tile.height_level) == 2, "height_level clamps to 0..2")
	_assert(int(clamped_tile.object_height) == 3, "object_height clamps to 0..3")
	_assert(int(clamped_tile.cover_value) == 100, "cover_value clamps to 0..100")
	_assert(String(clamped_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), "Invalid edge_type normalizes to cliff")

	var serialized: Dictionary = clamped_tile.call("to_dict")
	for field_name in [
		"tile_id",
		"type_id",
		"object_type_id",
		"grid_position",
		"world_position",
		"walkable",
		"blocks_los",
		"cover_value",
		"height_level",
		"object_height",
		"surface_type",
		"edge_type",
	]:
		_assert(serialized.has(field_name), "TerrainTileData serializes %s" % field_name)


func _test_pathfinder_and_authoring_anchors() -> void:
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	_assert(pathfinder.has_method("find_path_with_options"), "TerrainPathfinder exposes option-aware pathfinding")
	_assert(pathfinder.has_method("can_traverse_step"), "TerrainPathfinder exposes step traversal contract")
	_assert(pathfinder.has_method("get_step_cost"), "TerrainPathfinder exposes step cost contract")
	_assert(pathfinder.has_method("score_path"), "TerrainPathfinder exposes path scoring contract")
	var directions: Array = pathfinder.call("get_neighbor_directions")
	_assert(directions.has(Vector2i(1, 1)) and directions.has(Vector2i(-1, -1)), "TerrainPathfinder includes diagonal directions for corner-cutting checks")

	_assert(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_RAISE") == "raise", "Height tool defines raise mode")
	_assert(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_LOWER") == "lower", "Height tool defines lower mode")
	_assert(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_SET_1") == "set_1", "Height tool defines set_1 mode")
	_assert(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_SET_2") == "set_2", "Height tool defines set_2 mode")
	_assert(int(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("get_next_height_level", 2, "raise")) == 2, "Height tool clamps raise at H=2")
	_assert(int(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("get_next_height_level", 0, "lower")) == 0, "Height tool clamps lower at H=0")
	var zero_patch: Dictionary = MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("build_height_patch", 1, "lower", "slope", "none")
	_assert(int(zero_patch.get("height_level", -1)) == 0 and String(zero_patch.get("edge_type", "")) == "none", "Height tool clears edge_type to none at H=0")
	var raised_patch: Dictionary = MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("build_height_patch", 0, "raise", "slope", "none")
	_assert(int(raised_patch.get("height_level", -1)) == 1 and String(raised_patch.get("edge_type", "")) == "slope", "Height tool applies selected edge_type above H=0")


func _test_los_and_visual_contract_anchors() -> void:
	var los_text: String = _read_text_file("res://scripts/core/los_system.gd")
	_assert(los_text.contains("height_level") and los_text.contains("object_height"), "LOS system reads height_level and object_height")
	_assert(los_text.contains("blocker_height") and los_text.contains("+ int(tile_data.object_height)"), "LOS system computes blocker height from terrain plus object height")

	var renderer_text: String = _read_text_file("res://scripts/terrain/terrain_map_renderer.gd")
	_assert(renderer_text.contains("height_level") and renderer_text.contains("edge_type"), "Legacy terrain renderer reads height and edge_type")
	_assert(renderer_text.contains("EDGE_NONE") and renderer_text.contains("EDGE_SLOPE"), "Legacy terrain renderer distinguishes none and slope edges")

	var view_text: String = _read_text_file("res://scripts/terrain/terrain_map_3d_view.gd")
	_assert(view_text.contains("height_level") and view_text.contains("top_y"), "2.5D view anchors ground visuals on height_level")
	_assert(view_text.contains("object_height") and view_text.contains("top_y +"), "2.5D view anchors object visuals above terrain top_y")
	_assert(view_text.contains("neighbor_height < my_height"), "2.5D view derives hill edges from lower neighboring heights")

	var map_data_text: String = _read_text_file("res://scripts/terrain/terrain_map_data.gd")
	_assert(map_data_text.contains("\"object_height\"") and map_data_text.contains("\"edge_type\""), "TerrainMapData roundtrips object_height and edge_type")


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _float_eq(actual: float, expected: float) -> bool:
	return absf(actual - expected) < 0.001


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("  FAIL: %s" % message)
