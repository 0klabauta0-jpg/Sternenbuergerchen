extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_840_release_firefight_world_label_real_window_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const TOOL_PATH := "res://scripts/tools/capture_release_firefight_world_label_real_window.ps1"
const SOURCE_TOOL_PATH := "res://scripts/tools/capture_release_first_go_firefight_real_window.ps1"
const MANIFEST_PATH := "res://tmp/release_firefight_world_label_real_window_recapture.json"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_firefight_world_label_real_window_recapture.v1"
const STYLE_ID := "task_839_release_firefight_world_label_declutter_v1"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_840 Release Firefight World Label Real Window Recapture ===")
	_test_docs_and_tool_contract()
	_test_optional_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_840_release_firefight_world_label_real_window_recapture: FAILED")
		quit(1)
		return
	print("TASK_840_release_firefight_world_label_real_window_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_tool_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_840 task file exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_840 capture wrapper exists")
	_assert(FileAccess.file_exists(SOURCE_TOOL_PATH), "TASK_837 source capture tool remains available")
	_assert(task_text.contains("Release Firefight World Label Real Window Recapture"), "Task names world-label real-window recapture")
	_assert(status_text.contains("TASK_840 - Release Firefight World Label Real Window Recapture"), "Implementation status tracks TASK_840")
	_assert(roadmap_text.contains("TASK_840 - Release Firefight World Label Real Window Recapture (implementiert)"), "Roadmap marks TASK_840 implemented")
	_assert(roadmap_text.contains("TASK_841 - Release Firefight World Label Visual Findings"), "Roadmap names TASK_841 follow-up")
	_assert(contract_text.contains("Release-Firefight-World-Label-Real-Window-Recapture"), "Contract documents TASK_840")
	_assert(tool_text.contains(SCHEMA), "Tool writes stable TASK_840 schema")
	_assert(tool_text.contains("task_id = \"TASK_840\""), "Tool writes TASK_840 id")
	_assert(tool_text.contains("source_task_id = \"TASK_839\""), "Tool links TASK_839 source")
	_assert(tool_text.contains("source_capture_task_id = \"TASK_837\""), "Tool links TASK_837 source capture")
	_assert(tool_text.contains("capture_release_first_go_firefight_real_window.ps1"), "Tool reuses TASK_837 source capture")
	_assert(tool_text.contains(FIRST_GO_ARG), "Tool uses the first GO/firefight deep-link argument")
	_assert(tool_text.contains(DENSITY_MODE), "Tool records release-firefight declutter density mode")
	_assert(tool_text.contains(STYLE_ID), "Tool records TASK_839 style id")
	_assert(tool_text.contains("release_firefight_world_label_real_window_recapture.json"), "Tool writes TASK_840 manifest")
	_assert(tool_text.contains("release_firefight_world_label_real_window.png"), "Tool writes task-specific window screenshot path")
	_assert(tool_text.contains("world_labels_less_dense_than_task_837"), "Tool requires lower world-label density review")
	_assert(tool_text.contains("fire_vfx_trace_and_impact_visible"), "Tool requires preserved fire VFX review")
	_assert(tool_text.contains("friendly_fire_warning_preserved"), "Tool requires preserved friendly-fire warning review")
	_assert(tool_text.contains("critical_unit_state_badges_preserved"), "Tool requires preserved critical state review")
	_assert(tool_text.contains("manual_review_done = $false"), "Tool keeps manual review open")
	_assert(tool_text.contains("ui_sets_gameplay_truth = $false"), "Tool declares no gameplay truth mutation")
	_assert(tool_text.contains("creates_command = $false"), "Tool declares no command creation")
	_assert(tool_text.contains("creates_fire_event = $false"), "Tool declares no fire-event creation")
	_assert(tool_text.contains("creates_damage_event = $false"), "Tool declares no damage-event creation")
	_assert(tool_text.contains("sets_multiplayer_truth = $false"), "Tool declares no multiplayer truth mutation")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Tool declares no shortcut updates")
	_assert(tool_text.contains("starts_processes = [bool]$Launch"), "Tool starts processes only when requested")
	_assert(tool_text.contains("kills_processes = [bool]$StopRunningReleaseProcess"), "Tool kills processes only with explicit switch")


func _test_optional_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "TASK_840 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == SCHEMA, "Manifest schema matches TASK_840")
	_assert(String(manifest.get("task_id", "")) == "TASK_840", "Manifest task id matches TASK_840")
	_assert(String(manifest.get("source_task_id", "")) == "TASK_839", "Manifest links TASK_839")
	_assert(String(manifest.get("source_capture_task_id", "")) == "TASK_837", "Manifest links TASK_837")
	_assert(String(manifest.get("launch_argument", "")) == FIRST_GO_ARG, "Manifest records first GO/firefight argument")
	_assert(String(manifest.get("expected_world_label_density_mode", "")) == DENSITY_MODE, "Manifest records declutter density mode")
	_assert(String(manifest.get("expected_world_label_declutter_style_id", "")) == STYLE_ID, "Manifest records TASK_839 style id")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest keeps manual review not done")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest records no gameplay truth mutation")
	_assert(not bool(manifest.get("creates_command", true)), "Manifest records no command creation")
	_assert(not bool(manifest.get("creates_fire_event", true)), "Manifest records no fire-event creation")
	_assert(not bool(manifest.get("creates_damage_event", true)), "Manifest records no damage-event creation")
	_assert(not bool(manifest.get("sets_multiplayer_truth", true)), "Manifest records no multiplayer truth mutation")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "Manifest records no shortcut updates")
	_assert(String(manifest.get("window_screenshot_path", "")).ends_with("release_firefight_world_label_real_window.png"), "Manifest records task-specific window screenshot")
	_assert(_has_required_check(manifest, "world_labels_less_dense_than_task_837"), "Manifest requires lower world-label density review")
	_assert(_has_required_check(manifest, "fire_vfx_trace_and_impact_visible"), "Manifest requires fire VFX review")
	_assert(_has_required_check(manifest, "friendly_fire_warning_preserved"), "Manifest requires friendly-fire warning review")
	_assert(_has_required_check(manifest, "critical_unit_state_badges_preserved"), "Manifest requires critical state review")


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
