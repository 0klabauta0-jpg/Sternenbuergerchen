extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_614_host_client_two_window_real_run_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const TASK_613_TEST_PATH: String = "res://scripts/tests/task_613_host_client_two_window_visual_polish_findings.gd"
const LAUNCH_PLAN_PATH: String = "res://tmp/host_client_two_window_launch_plan.json"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_614 Host Client Two Window Real Run Review ===")
	_test_docs_report_and_contract()
	_test_capture_tool_script()
	_test_dry_run_manifest_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_614: FAILED")
		quit(1)
		return
	print("TASK_614: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_614 task file exists")
	_assert(task_text.contains("Host Client Two Window Real Run Review"), "TASK_614 task file names the task")
	_assert(task_text.contains("capture_host_client_two_window_real_run.ps1"), "TASK_614 task names real-run capture helper")
	_assert(status_text.contains("TASK_614 - Host Client Two Window Real Run Review"), "Implementation status tracks TASK_614")
	_assert(status_text.contains("TASK_615 - Host Client Real Run Findings"), "Implementation status names TASK_615 follow-up")
	_assert(roadmap_text.contains("TASK_614 - Host Client Two Window Real Run Review (implementiert)"), "Roadmap marks TASK_614 implemented")
	_assert(roadmap_text.contains("TASK_615 - Host Client Real Run Findings"), "Roadmap names TASK_615 follow-up")
	_assert(contract_text.contains("Host-Client-Two-Window-Real-Run-Review"), "Mission feedback contract documents TASK_614")
	_assert(report_text.contains("TASK_614 Host Client Two Window Real Run Review"), "Review workbench tracks TASK_614")
	_assert(report_text.contains("TASK_615 - Host Client Real Run Findings"), "Review workbench recommends TASK_615 next")
	_assert(FileAccess.file_exists(TASK_613_TEST_PATH), "TASK_613 visual polish verifier remains available")
	_assert(FileAccess.file_exists(LAUNCH_PLAN_PATH), "TASK_611 launch plan exists for TASK_614")
	_test_report_export_fields(report_text)


func _test_report_export_fields(report_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_two_window_real_run.tool_path",
		"host_client_two_window_real_run.manifest_path",
		"host_client_two_window_real_run.screenshot_path",
		"host_client_two_window_real_run.launch_command",
		"host_client_two_window_real_run.dry_run_command",
		"host_client_two_window_real_run.real_run_done",
		"host_client_two_window_real_run.manual_review_done",
		"host_client_two_window_real_run.read_only",
		"host_client_two_window_real_run.recommended_next_task",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	var required_choice_groups: Array[String] = [
		"host_client_two_window_real_run.result",
		"host_client_two_window_real_run.window_rating",
		"host_client_two_window_real_run.performance_rating",
		"host_client_two_window_real_run.next_priority",
	]
	for choice_group in required_choice_groups:
		_assert(report_text.contains('data-choice-group="%s"' % choice_group), "Report exports choice group %s" % choice_group)
	_assert(report_text.contains('data-note-key="notes.host_client_two_window_real_run_review"'), "Report exports free TASK_614 real-run review note")
	_assert(report_text.contains('"TASK_615 - Host Client Real Run Findings"'), "JSON payload keeps TASK_615 in completed tasks")
	_assert(report_text.contains('"TASK_616 - Host Client Visible UI Real Run Review"'), "JSON payload keeps TASK_616 in completed chain")
	_assert(report_text.contains('latest_completed_task: "TASK_619 - Host Client Role Peer Badge HUD"'), "JSON payload advances latest completed task to TASK_619")


func _test_capture_tool_script() -> void:
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_614 capture helper exists")
	var tool_text: String = _read_text(TOOL_PATH)
	var required_terms: Array[String] = [
		"TASK_614",
		"host_client_two_window_real_run_review.json",
		"host_client_two_window_real_run_desktop.png",
		"host_client_two_window_host_review.png",
		"host_client_two_window_client_review.png",
		"Launch",
		"CloseAfterCapture",
		"Capture-Desktop",
		"Start-Process",
		"Stop-Process",
		"manual_review_required",
		"ui_sets_gameplay_truth",
		"TASK_615 - Host Client Real Run Findings",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)
	_assert(tool_text.contains("dry run only"), "Capture helper defaults to dry-run messaging")


func _test_dry_run_manifest_if_present() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_614 dry-run manifest exists")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema is stable")
	_assert(String(manifest.get("task_id", "")) == "TASK_614", "Manifest records TASK_614")
	_assert(String(manifest.get("source_plan_task_id", "")) == "TASK_611", "Manifest records TASK_611 source plan")
	_assert(not bool(manifest.get("launch_requested", true)), "Dry-run manifest did not request launch")
	_assert(not bool(manifest.get("real_run_done", true)), "Dry-run manifest does not claim real run done")
	_assert(not bool(manifest.get("screenshot_written", true)), "Dry-run manifest does not claim screenshot written")
	_assert(not bool(manifest.get("host_screenshot_written", true)), "Dry-run manifest does not claim host screenshot written")
	_assert(not bool(manifest.get("client_screenshot_written", true)), "Dry-run manifest does not claim client screenshot written")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_615 - Host Client Real Run Findings", "Manifest recommends TASK_615")
	_assert(String(manifest.get("recommended_next_capture_task", "")) == "TASK_618 - Host Client Standard Capture Crop Review", "Manifest recommends TASK_618 capture review")


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
