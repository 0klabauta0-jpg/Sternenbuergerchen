extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const REFERENCE_MAP_PATH: String = "res://maps/editor_terrain_visual_recovery_reference.json"
const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const OBJECT_CATALOG_PATH: String = "res://data/terrain_object_catalog.json"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/nature_prop_scale_cover_visibility_checklist.md"

const REQUIRED_PROPS: Dictionary = {
	"nature_tree_blocker": {"min_scale": 1.0, "cover": 65, "blocks_los": true, "walkable": false},
	"nature_rock_cover": {"min_scale": 0.9, "cover": 55, "blocks_los": true, "walkable": false},
	"nature_bush_cover": {"min_scale": 0.85, "cover": 25, "blocks_los": false, "walkable": true},
	"nature_cactus_cover": {"min_scale": 0.84, "cover": 30, "blocks_los": false, "walkable": false},
	"nature_deco_logs": {"min_scale": 0.72, "cover": 0, "blocks_los": false, "walkable": true},
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_294 Nature Prop Scale Cover Visibility Repair ===")
	_test_mapping_and_catalog_contract()
	await _test_runtime_prop_snapshot()
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_mapping_and_catalog_contract() -> void:
	var mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var object_catalog: Dictionary = _load_json(OBJECT_CATALOG_PATH)
	_assert(not mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(not object_catalog.is_empty(), "Terrain object catalog parses")
	var models: Dictionary = Dictionary(mapping.get("models", {}))
	for prop_id in REQUIRED_PROPS.keys():
		var entry: Dictionary = Dictionary(models.get(prop_id, {}))
		var expected: Dictionary = Dictionary(REQUIRED_PROPS.get(prop_id, {}))
		_assert(String(entry.get("source_id", "")) == "kenney_nature_kit_classic", "Prop uses Nature Kit source: %s" % prop_id)
		_assert(ResourceLoader.exists(String(entry.get("model_path", ""))), "Prop resource loads: %s" % prop_id)
		_assert(float(entry.get("scale", 0.0)) >= float(expected.get("min_scale", 0.0)), "Prop has minimum readable scale: %s" % prop_id)
		_assert(_object_catalog_has_gameplay_fields(object_catalog, prop_id, expected), "Object catalog gameplay fields stay truthful: %s" % prop_id)


func _test_runtime_prop_snapshot() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", REFERENCE_MAP_PATH)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("nature_prop_visual_entries", []))
	_assert(entries.size() >= REQUIRED_PROPS.size(), "Runtime snapshot exposes Nature prop visuals")
	for prop_id in REQUIRED_PROPS.keys():
		var entry: Dictionary = _find_entry(entries, prop_id)
		var expected: Dictionary = Dictionary(REQUIRED_PROPS.get(prop_id, {}))
		_assert(not entry.is_empty(), "Runtime renders prop: %s" % prop_id)
		_assert(float(entry.get("scale", 0.0)) >= float(expected.get("min_scale", 0.0)), "Runtime prop scale is readable: %s" % prop_id)
		_assert(float(entry.get("world_y", -INF)) >= float(entry.get("surface_y", INF)), "Runtime prop sits on tile top: %s" % prop_id)
		_assert(int(entry.get("cover_value", -1)) == int(expected.get("cover", -2)), "Runtime prop cover remains catalog truth: %s" % prop_id)
	_assert(bool(Dictionary(snapshot.get("editor_visual_recovery", {})).get("grid_depth_tested", false)), "Grid remains depth-tested around props")
	view.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Nature prop manual checklist exists")
	var text: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Tree", "Rock", "Bush", "Cactus", "Logs"]:
		_assert(text.contains(required_text), "Nature prop checklist covers %s" % required_text)


func _object_catalog_has_gameplay_fields(catalog: Dictionary, prop_id: String, expected: Dictionary) -> bool:
	for entry_variant in Array(catalog.get("object_types", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("type_id", "")) != prop_id:
			continue
		return int(entry.get("cover_value", -1)) == int(expected.get("cover", -2)) \
			and bool(entry.get("blocks_los", false)) == bool(expected.get("blocks_los", false)) \
			and bool(entry.get("walkable", true)) == bool(expected.get("walkable", true))
	return false


func _find_entry(entries: Array, prop_id: String) -> Dictionary:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("object_type_id", "")) == prop_id or String(entry.get("visual_type_id", "")) == prop_id:
			return entry
	return {}


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
