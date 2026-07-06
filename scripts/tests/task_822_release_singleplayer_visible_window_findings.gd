extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_822_release_singleplayer_visible_window_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const TOOL_PATH: String = "res://scripts/tools/capture_release_singleplayer_visible_window.ps1"
const MANIFEST_PATH: String = "res://tmp/release_singleplayer_visible_window_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_822 Release Singleplayer Visible Window Findings ===")
	_test_docs_and_tool_boundaries()
	_test_optional_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_822: FAILED")
		quit(1)
		return
	print("TASK_822: ALL PASSED")
	quit(0)


func _test_docs_and_tool_boundaries() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_822 task file exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_822 capture tool exists")
	_assert(task_text.contains("Release Singleplayer Visible Window Findings"), "Task names visible window findings")
	_assert(task_text.contains("read-only"), "Task declares read-only scope")
	_assert(status_text.contains("TASK_822 - Release Singleplayer Visible Window Findings"), "Implementation status tracks TASK_822")
	_assert(roadmap_text.contains("TASK_822 - Release Singleplayer Visible Window Findings (implementiert)"), "Roadmap marks TASK_822 implemented")
	_assert(tool_text.contains("sternenbuergerchen.release_singleplayer_visible_window_findings.v1"), "Tool writes stable schema")
	_assert(tool_text.contains("manual_review_done = $false"), "Tool keeps manual review open")
	_assert(tool_text.contains("starts_processes = $false"), "Tool declares no process starts")
	_assert(tool_text.contains("kills_processes = $false"), "Tool declares no process kills")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Tool declares no shortcut updates")
	_assert(tool_text.contains("ui_sets_gameplay_truth = $false"), "Tool declares no gameplay truth mutation")
	_assert(not tool_text.contains("Start-Process"), "Tool does not launch processes")
	_assert(not tool_text.contains("Stop-Process"), "Tool does not terminate processes")


func _test_optional_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "TASK_822 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.release_singleplayer_visible_window_findings.v1", "Manifest schema matches TASK_822")
	_assert(String(manifest.get("task_id", "")) == "TASK_822", "Manifest task id matches TASK_822")
	_assert(bool(manifest.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(manifest.get("starts_processes", true)), "Manifest records no process starts")
	_assert(not bool(manifest.get("kills_processes", true)), "Manifest records no process kills")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "Manifest records no shortcut updates")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest records no gameplay truth mutation")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest keeps manual review not done")
	_assert(_has_required_check(manifest, "singleplayer_clicked"), "Manifest asks to check Singleplayer click")
	_assert(_has_required_check(manifest, "homebase_cta_visible"), "Manifest asks to check Homebase CTA")
	_assert(_has_required_check(manifest, "firefight_hud_readable"), "Manifest asks to check firefight HUD")


func _has_required_check(manifest: Dictionary, check_id: String) -> bool:
	for check_variant in Array(manifest.get("required_checks", [])):
		if String(check_variant) == check_id:
			return true
	return false


func _read_json_dict(path: String) -> Dictionary:
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
