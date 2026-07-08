extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_837_release_first_go_firefight_real_window_review.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const TOOL_PATH := "res://scripts/tools/capture_release_first_go_firefight_real_window.ps1"
const TASK_822_TOOL_PATH := "res://scripts/tools/capture_release_singleplayer_visible_window.ps1"
const LAUNCHER_TOOL_PATH := "res://scripts/tools/start_release_runtime_checked.ps1"
const MANIFEST_PATH := "res://tmp/release_first_go_firefight_real_window_review.json"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_go_firefight_real_window_review.v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_837 Release First GO Firefight Real Window Review ===")
	_test_docs_and_tool_contract()
	_test_optional_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_837_release_first_go_firefight_real_window_review: FAILED")
		quit(1)
		return
	print("TASK_837_release_first_go_firefight_real_window_review: ALL PASSED")
	quit(0)


func _test_docs_and_tool_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_837 task file exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_837 capture wrapper exists")
	_assert(FileAccess.file_exists(TASK_822_TOOL_PATH), "Existing TASK_822 capture tool remains available")
	_assert(FileAccess.file_exists(LAUNCHER_TOOL_PATH), "Existing checked release launcher remains available")
	_assert(task_text.contains("Release First GO Firefight Real Window Review"), "Task names first GO firefight real-window review")
	_assert(status_text.contains("TASK_837 - Release First GO Firefight Real Window Review"), "Implementation status tracks TASK_837")
	_assert(roadmap_text.contains("TASK_837 - Release First GO Firefight Real Window Review (implementiert)"), "Roadmap marks TASK_837 implemented")
	_assert(tool_text.contains(SCHEMA), "Tool writes stable TASK_837 schema")
	_assert(tool_text.contains(FIRST_GO_ARG), "Tool launches the first GO/firefight deep-link argument")
	_assert(tool_text.contains("start_release_runtime_checked.ps1"), "Tool reuses the checked release launcher")
	_assert(tool_text.contains("capture_release_singleplayer_visible_window.ps1"), "Tool reuses the existing visible-window capture")
	_assert(tool_text.contains("release_first_go_firefight_real_window_review.json"), "Tool writes TASK_837 manifest")
	_assert(tool_text.contains("release_first_go_firefight_real_window.png"), "Tool writes task-specific window screenshot path")
	_assert(tool_text.contains("[int]$WaitSeconds = 30"), "Tool waits long enough for deployed first-firefight state by default")
	_assert(tool_text.contains("manual_review_done = $false"), "Tool keeps manual review open")
	_assert(tool_text.contains("ui_sets_gameplay_truth = $false"), "Tool declares no gameplay truth mutation")
	_assert(tool_text.contains("creates_command = $false"), "Tool declares no command creation")
	_assert(tool_text.contains("creates_fire_event = $false"), "Tool declares no fire-event creation")
	_assert(tool_text.contains("creates_damage_event = $false"), "Tool declares no damage-event creation")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Tool declares no shortcut updates")
	_assert(tool_text.contains("starts_processes = [bool]$Launch"), "Tool starts processes only when launch is requested")
	_assert(tool_text.contains("kills_processes = [bool]$StopRunningReleaseProcess"), "Tool kills processes only with explicit switch")


func _test_optional_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "TASK_837 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == SCHEMA, "Manifest schema matches TASK_837")
	_assert(String(manifest.get("task_id", "")) == "TASK_837", "Manifest task id matches TASK_837")
	_assert(String(manifest.get("launch_argument", "")) == FIRST_GO_ARG, "Manifest records first GO/firefight argument")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest keeps manual review not done")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest records no gameplay truth mutation")
	_assert(not bool(manifest.get("creates_command", true)), "Manifest records no command creation")
	_assert(not bool(manifest.get("creates_fire_event", true)), "Manifest records no fire-event creation")
	_assert(not bool(manifest.get("creates_damage_event", true)), "Manifest records no damage-event creation")
	_assert(not bool(manifest.get("sets_multiplayer_truth", true)), "Manifest records no multiplayer truth mutation")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "Manifest records no shortcut updates")
	_assert(String(manifest.get("window_screenshot_path", "")).ends_with("release_first_go_firefight_real_window.png"), "Manifest records task-specific window screenshot")
	_assert(_has_required_check(manifest, "command_matrix_go_prominent"), "Manifest requires GO prominence review")
	_assert(_has_required_check(manifest, "active_fire_rule_visible"), "Manifest requires active Fire-Rule review")
	_assert(_has_required_check(manifest, "engagement_feedback_visible"), "Manifest requires engagement feedback review")


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
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
