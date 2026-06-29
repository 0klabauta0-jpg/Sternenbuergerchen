extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_610_host_client_two_window_playtest_notes.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_607_TEST_PATH: String = "res://scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd"
const TASK_608_TEST_PATH: String = "res://scripts/tests/task_608_host_client_runtime_visual_capture.gd"
const TASK_609_TEST_PATH: String = "res://scripts/tests/task_609_host_client_runtime_visual_polish_findings.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_610 Host Client Two Window Playtest Notes ===")
	_test_docs_and_report_wiring()
	_test_two_window_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_610: FAILED")
		quit(1)
		return
	print("TASK_610: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_610 task file exists")
	_assert(task_text.contains("Host Client Two Window Playtest Notes"), "TASK_610 task file names the task")
	_assert(task_text.contains("notes.host_client_two_window_manual_review"), "TASK_610 task names the manual note key")
	_assert(status_text.contains("TASK_610 - Host Client Two Window Playtest Notes"), "Implementation status tracks TASK_610")
	_assert(status_text.contains("TASK_611 - Host Client Two Window Launch Helper"), "Implementation status names TASK_611 follow-up")
	_assert(roadmap_text.contains("TASK_610 - Host Client Two Window Playtest Notes (implementiert)"), "Roadmap marks TASK_610 implemented")
	_assert(roadmap_text.contains("TASK_611 - Host Client Two Window Launch Helper"), "Roadmap names TASK_611 follow-up")
	_assert(contract_text.contains("Host-Client-Two-Window-Playtest-Notes"), "Mission feedback contract documents TASK_610")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_610 Host Client Two Window Playtest Notes"), "Review workbench tracks TASK_610")
	_assert(report_text.contains("TASK_611 - Host Client Two Window Launch Helper"), "Review workbench recommends TASK_611 next")
	_assert(FileAccess.file_exists(TASK_607_TEST_PATH), "TASK_607 runtime smoke remains available")
	_assert(FileAccess.file_exists(TASK_608_TEST_PATH), "TASK_608 runtime capture remains available")
	_assert(FileAccess.file_exists(TASK_609_TEST_PATH), "TASK_609 visual polish verifier remains available")


func _test_two_window_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	var required_export_keys: Array[String] = [
		"host_client_two_window_manual.host_screenshot_done",
		"host_client_two_window_manual.client_screenshot_done",
		"host_client_two_window_manual.both_windows_visible_checked",
		"host_client_two_window_manual.local_connection_checked",
		"host_client_two_window_manual.host_authority_checked",
		"host_client_two_window_manual.client_read_only_checked",
		"host_client_two_window_manual.peer2_bravo_command_checked",
		"host_client_two_window_manual.peer2_alpha_reject_checked",
		"host_client_two_window_manual.snapshot_sync_checked",
		"host_client_two_window_manual.f6_readability_checked",
		"host_client_two_window_manual.performance_checked",
		"host_client_two_window_manual.host_screenshot_path",
		"host_client_two_window_manual.client_screenshot_path",
		"host_client_two_window_manual.viewport",
		"host_client_two_window_manual.connection_mode",
		"host_client_two_window_manual.scenario",
		"host_client_two_window_manual.host_identity_notes",
		"host_client_two_window_manual.client_identity_notes",
		"host_client_two_window_manual.command_authority_notes",
		"host_client_two_window_manual.snapshot_sync_notes",
		"host_client_two_window_manual.performance_notes",
		"host_client_two_window_manual.visual_readability_notes",
		"host_client_two_window_manual.followup",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	var required_choice_groups: Array[String] = [
		"host_client_two_window_manual.result",
		"host_client_two_window_manual.connection_rating",
		"host_client_two_window_manual.authority_rating",
		"host_client_two_window_manual.sync_rating",
		"host_client_two_window_manual.readability_rating",
		"host_client_two_window_manual.performance_rating",
		"host_client_two_window_manual.next_priority",
	]
	for choice_group in required_choice_groups:
		_assert(report_text.contains('data-choice-group="%s"' % choice_group), "Report exports choice group %s" % choice_group)
	_assert(report_text.contains('data-note-key="notes.host_client_two_window_manual_review"'), "Report exports free Host/Client two-window notes")
	_assert(report_text.contains('"TASK_610 - Host Client Two Window Playtest Notes"'), "JSON metadata lists TASK_610 as completed")
	_assert(report_text.contains('current_focus: "TASK_611 - Host Client Two Window Launch Helper"'), "JSON payload sets current focus to TASK_611")
	_assert(report_text.contains('latest_completed_task: "TASK_610 - Host Client Two Window Playtest Notes"'), "JSON payload lists TASK_610 as latest completed task")
	_assert(not report_text.contains('data-export-key="host_client_two_window_manual.host_screenshot_done" checked'), "Host screenshot is not pre-marked done")
	_assert(not report_text.contains('data-export-key="host_client_two_window_manual.client_screenshot_done" checked'), "Client screenshot is not pre-marked done")


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
