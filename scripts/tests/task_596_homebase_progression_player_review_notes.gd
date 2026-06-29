extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_596_homebase_progression_player_review_notes.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_595_TEST_PATH: String = "res://scripts/tests/task_595_homebase_progression_visual_polish.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_596 Homebase Progression Player Review Notes ===")
	_test_docs_and_report_wiring()
	_test_report_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_596: FAILED")
		quit(1)
		return
	print("TASK_596: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_596 task file exists")
	_assert(task_text.contains("Homebase Progression Player Review Notes"), "TASK_596 task file names the task")
	_assert(status_text.contains("TASK_596 - Homebase Progression Player Review Notes"), "Implementation status tracks TASK_596")
	_assert(status_text.contains("TASK_597 - Homebase Progression F6 Evidence Capture"), "Implementation status names TASK_597 follow-up")
	_assert(roadmap_text.contains("TASK_596 - Homebase Progression Player Review Notes (implementiert)"), "Roadmap marks TASK_596 implemented")
	_assert(roadmap_text.contains("TASK_597 - Homebase Progression F6 Evidence Capture"), "Roadmap names TASK_597 follow-up")
	_assert(contract_text.contains("Homebase-Progression-Player-Review-Notes"), "Mission feedback contract documents TASK_596")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_596 Homebase-Progression Player-Review"), "Review workbench contains TASK_596 block")
	_assert(report_text.contains("TASK_597 - Homebase Progression F6 Evidence Capture"), "Review workbench names TASK_597 follow-up")
	_assert(report_text.contains("JSON exportieren"), "Review workbench still exposes JSON export")
	_assert(FileAccess.file_exists(TASK_595_TEST_PATH), "TASK_595 visual polish verifier remains available")


func _test_report_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	var required_export_keys: Array[String] = [
		"homebase_progression_manual.screenshot_done",
		"homebase_progression_manual.return_flow_checked",
		"homebase_progression_manual.character_sheet_open_checked",
		"homebase_progression_manual.mission_gain_badge_checked",
		"homebase_progression_manual.xp_delta_checked",
		"homebase_progression_manual.style_contrast_checked",
		"homebase_progression_manual.read_only_source_checked",
		"homebase_progression_manual.next_step_checked",
		"homebase_progression_manual.screenshot_path",
		"homebase_progression_manual.viewport",
		"homebase_progression_manual.highlighted_unit",
		"homebase_progression_manual.style_id",
		"homebase_progression_manual.badge_text",
		"homebase_progression_manual.badge_notes",
		"homebase_progression_manual.contrast_notes",
		"homebase_progression_manual.placement_notes",
		"homebase_progression_manual.return_flow_notes",
		"homebase_progression_manual.followup",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	var required_choice_groups: Array[String] = [
		"homebase_progression_manual.result",
		"homebase_progression_manual.badge_rating",
		"homebase_progression_manual.contrast_rating",
		"homebase_progression_manual.placement_rating",
		"homebase_progression_manual.return_flow_rating",
		"homebase_progression_manual.next_polish_priority",
	]
	for choice_group in required_choice_groups:
		_assert(report_text.contains('data-choice-group="%s"' % choice_group), "Report exports choice group %s" % choice_group)
	_assert(report_text.contains('data-note-key="notes.homebase_progression_manual_review"'), "Report exports free Homebase Progression review notes")
	_assert(report_text.contains("homebase_progression_delta_v1"), "Report references TASK_595 style id")
	_assert(report_text.contains("MISSION GAIN"), "Report references visible mission gain badge")
	_assert(report_text.contains("task_596_homebase_progression_player_review_notes.gd"), "Report lists TASK_596 verifier")
	_assert(report_text.contains('"TASK_596 - Homebase Progression Player Review Notes"'), "JSON payload lists TASK_596 as recently completed")
	_assert(report_text.contains('"TASK_597 - Homebase Progression F6 Evidence Capture"'), "JSON payload keeps TASK_597 in completed chain")
	_assert(report_text.contains('latest_completed_task: "TASK_613 - Host Client Two Window Visual Polish Findings"'), "JSON payload lists TASK_613 as latest completed task")
	_assert(report_text.contains('current_focus: "TASK_614 - Host Client Two Window Real Run Review"'), "JSON payload sets current focus to TASK_614")
	_assert(not report_text.contains("TASK_596 Player-Review offen"), "Report no longer marks TASK_596 open in header")


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
