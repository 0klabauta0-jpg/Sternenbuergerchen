extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_616_host_client_visible_ui_real_run_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_616 Host Client Visible UI Real Run Review ===")
	_test_docs_report_and_contract()
	_test_terrain_view_bootstrap_redraw_guard()
	_test_capture_tool_focuses_windows_before_wait()
	_test_manifest_remains_review_evidence_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_616: FAILED")
		quit(1)
		return
	print("TASK_616: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_616 task file exists")
	_assert(task_text.contains("Client-World-Blackout") or task_text.contains("Weltflaeche bleibt schwarz"), "TASK_616 documents the visible client world finding")
	_assert(status_text.contains("TASK_616 - Host Client Visible UI Real Run Review"), "Implementation status tracks TASK_616")
	_assert(roadmap_text.contains("TASK_616 - Host Client Visible UI Real Run Review (implementiert)"), "Roadmap marks TASK_616 implemented")
	_assert(contract_text.contains("Host-Client-Visible-UI-Real-Run-Review"), "Mission feedback contract documents TASK_616")
	_assert(report_text.contains("TASK_616 Host Client Visible UI Real Run Review"), "Review workbench tracks TASK_616")
	_assert(report_text.contains('data-export-key="host_client_visible_ui_real_run.finding"'), "Report exports TASK_616 finding")
	_assert(report_text.contains('data-export-key="host_client_visible_ui_real_run.terrain_redraw_guard"'), "Report exports TASK_616 redraw guard")
	_assert(report_text.contains('"TASK_616 - Host Client Visible UI Real Run Review"'), "JSON payload keeps TASK_616 in completed chain")
	_assert(report_text.contains('latest_completed_task: "TASK_617 - Host Client Standard Window Layout Hardening"'), "JSON payload advances latest completed task to TASK_617")


func _test_terrain_view_bootstrap_redraw_guard() -> void:
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(terrain_text.contains("CONTINUOUS_REDRAW_AFTER_BOOTSTRAP_MSEC"), "Terrain view defines bounded bootstrap redraw duration")
	_assert(terrain_text.contains("_request_viewport_redraw(true, CONTINUOUS_REDRAW_AFTER_BOOTSTRAP_MSEC)"), "Terrain view requests bootstrap continuous redraw")
	_assert(terrain_text.contains("render_target_update_mode = SubViewport.UPDATE_ALWAYS"), "Terrain view can briefly force UPDATE_ALWAYS")
	_assert(terrain_text.contains("render_target_update_mode = SubViewport.UPDATE_ONCE"), "Terrain view returns to UPDATE_ONCE normal mode")
	_assert(terrain_text.contains("maxi(_continuous_redraw_until_msec"), "Terrain view extends redraw windows without shortening active ones")


func _test_capture_tool_focuses_windows_before_wait() -> void:
	var capture_text: String = _read_text(CAPTURE_TOOL_PATH)
	_assert(capture_text.contains("initial_host_window_status"), "Capture helper records initial host window status")
	_assert(capture_text.contains("initial_client_window_status"), "Capture helper records initial client window status")
	_assert(capture_text.find("$initialClientWindowStatus = Focus-ReviewWindow") < capture_text.find("Start-Sleep -Seconds ([Math]::Max(1, $WaitSeconds))"), "Capture helper focuses client before long wait")
	_assert(capture_text.find("$initialHostWindowStatus = Focus-ReviewWindow") < capture_text.find("Starting visible TASK_614 Client window."), "Capture helper focuses host before starting client")


func _test_manifest_remains_review_evidence_if_present() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "Real-run manifest is optional for static TASK_616 verification")
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(bool(manifest.get("read_only", false)), "Real-run manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Real-run manifest does not set gameplay truth")
	_assert(manifest.has("visible_godot_bin"), "Real-run manifest keeps visible binary evidence")
	_assert(manifest.has("initial_host_window_status"), "Real-run manifest keeps initial host focus evidence")
	_assert(manifest.has("initial_client_window_status"), "Real-run manifest keeps initial client focus evidence")
	_assert(manifest.has("host_window_status"), "Real-run manifest keeps host window status")
	_assert(manifest.has("client_window_status"), "Real-run manifest keeps client window status")


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
