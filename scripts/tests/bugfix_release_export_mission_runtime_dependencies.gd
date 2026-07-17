extends SceneTree

const CONTRACT_PATH := "res://data/export_runtime_package_contract.json"
const TASK_PATH := "res://docs/tasks/BUGFIX_release_export_mission_runtime_test_dependencies.md"
const META_LAYER_SOURCE_PATH := "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Release Export Mission Runtime Test Dependencies ===")
	_test_task_doc_exists()
	_test_export_contract_excludes_legacy_test_dependencies()
	_test_meta_layer_references_the_product_mission_scene()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("BUGFIX_release_export_mission_runtime_test_dependencies: FAILED")
		quit(1)
		return
	print("BUGFIX_release_export_mission_runtime_test_dependencies: ALL PASSED")
	quit(0)


func _test_task_doc_exists() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "Bugfix task file exists")


func _test_export_contract_excludes_legacy_test_dependencies() -> void:
	var contract: Dictionary = _read_json(CONTRACT_PATH)
	var exclude_patterns: Array = Array(contract.get("exclude_filter_patterns", []))
	_assert(exclude_patterns.has("scripts/tests/**"), "Runtime export excludes the extracted scripts/tests legacy adapters")
	_assert(Array(contract.get("runtime_script_dependency_roots", [])).is_empty(), "Runtime export no longer declares scripts/tests runtime dependencies")
	_assert(exclude_patterns.has("docs/**"), "Runtime export still excludes docs")
	_assert(exclude_patterns.has("scripts/tools/**"), "Runtime export still excludes tooling scripts")
	_assert(exclude_patterns.has("tmp/**"), "Runtime export still excludes tmp captures")


func _test_meta_layer_references_the_product_mission_scene() -> void:
	var source: String = FileAccess.get_file_as_string(META_LAYER_SOURCE_PATH)
	_assert(source.contains("res://scenes/mission/mission_runtime.tscn"), "MetaLayer depends on the canonical product mission scene")
	_assert(source.contains("MISSION_RUNTIME_SCENE"), "MetaLayer mission host uses the product mission scene constant")


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
