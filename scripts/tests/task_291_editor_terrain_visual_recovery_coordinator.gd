extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const CONTRACT_PATH: String = "res://docs/dev/editor_terrain_visual_recovery_contract.md"
const REFERENCE_MAP_PATH: String = "res://maps/editor_terrain_visual_recovery_reference.json"
const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_291 Editor Terrain Visual Recovery Coordinator ===")
	_test_contract_doc()
	_test_reference_map()
	_test_mapping_canon()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_doc() -> void:
	_assert(FileAccess.file_exists(CONTRACT_PATH), "Visual recovery contract exists")
	var text: String = _read_text(CONTRACT_PATH)
	for required_text in ["Diagnosis", "Visual Height Canon", "height_step", "Reference Fixture", "TASK_298"]:
		_assert(text.contains(required_text), "Contract covers %s" % required_text)


func _test_reference_map() -> void:
	_assert(FileAccess.file_exists(REFERENCE_MAP_PATH), "Reference map exists")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", REFERENCE_MAP_PATH)
	_assert(map_data != null, "Reference map loads")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(6, 6), "Reference map has compact 6x6 size")
	_assert(_map_has_height(map_data, 0) and _map_has_height(map_data, 1) and _map_has_height(map_data, 2), "Reference map covers H0/H1/H2")
	for object_type_id in ["wall_straight_se", "nature_rock_cover", "nature_cactus_cover", "nature_bush_cover", "nature_tree_blocker", "station_computer"]:
		_assert(_map_has_object(map_data, object_type_id), "Reference map has object: %s" % object_type_id)
	_assert(_map_has_edge(map_data, "cliff") and _map_has_edge(map_data, "slope"), "Reference map covers cliff and slope edges")


func _test_mapping_canon() -> void:
	var mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	_assert(not mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(float(Dictionary(mapping.get("grid", {})).get("height_step", 0.0)) == 0.5, "Height step canon is 0.5")
	_assert(String(Dictionary(mapping.get("nature_kit", {})).get("active_height_edge_theme", "")) == "legacy_space", "Active height edge reference uses legacy Space Kit")


func _map_has_height(map_data, height_level: int) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and int(tile_data.height_level) == height_level:
			return true
	return false


func _map_has_object(map_data, object_type_id: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.object_type_id) == object_type_id:
			return true
	return false


func _map_has_edge(map_data, edge_type: String) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.edge_type) == edge_type:
			return true
	return false


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
