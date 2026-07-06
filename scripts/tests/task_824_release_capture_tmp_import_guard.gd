extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_824_release_capture_tmp_import_guard.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const GDIGNORE_PATH: String = "res://tmp/.gdignore"
const GITIGNORE_PATH: String = "res://.gitignore"
const EXPORT_CONTRACT_PATH: String = "res://data/export_runtime_package_contract.json"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_release_singleplayer_visible_window.ps1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_824 Release Capture Tmp Import Guard ===")
	_test_docs_and_guard_files()
	_test_export_and_capture_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_824: FAILED")
		quit(1)
		return
	print("TASK_824: ALL PASSED")
	quit(0)


func _test_docs_and_guard_files() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var gitignore_text: String = _read_text(GITIGNORE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_824 task file exists")
	_assert(task_text.contains("Release Capture Tmp Import Guard"), "Task names tmp import guard")
	_assert(status_text.contains("TASK_824 - Release Capture Tmp Import Guard"), "Implementation status tracks TASK_824")
	_assert(roadmap_text.contains("TASK_824 - Release Capture Tmp Import Guard (implementiert)"), "Roadmap marks TASK_824 implemented")
	_assert(FileAccess.file_exists(GDIGNORE_PATH), "tmp/.gdignore exists")
	_assert(gitignore_text.contains("/tmp/"), ".gitignore keeps tmp ignored")


func _test_export_and_capture_contract() -> void:
	var contract: Dictionary = _read_json(EXPORT_CONTRACT_PATH)
	var patterns: Array = Array(contract.get("exclude_filter_patterns", []))
	var capture_text: String = _read_text(CAPTURE_TOOL_PATH)
	_assert(patterns.has("tmp/**"), "Runtime export excludes tmp")
	_assert(capture_text.contains("release_singleplayer_visible_window_desktop.png"), "Capture tool still writes desktop evidence")
	_assert(capture_text.contains("release_singleplayer_visible_window_findings.json"), "Capture tool still writes findings manifest")
	_assert(capture_text.contains("read_only = $true"), "Capture manifest remains read-only")
	_assert(capture_text.contains("ui_sets_gameplay_truth = $false"), "Capture manifest does not set gameplay truth")


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
