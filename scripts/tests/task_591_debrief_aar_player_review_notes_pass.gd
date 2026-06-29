extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_591_debrief_aar_player_review_notes_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_590_TEST_PATH: String = "res://scripts/tests/task_590_debrief_aar_layout_polish_findings.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_591 Debrief AAR Player Review Notes Pass ===")
	_test_docs_and_report_wiring()
	_test_report_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_591: FAILED")
		quit(1)
		return
	print("TASK_591: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_591 task file exists")
	_assert(task_text.contains("Debrief AAR Player Review Notes Pass"), "TASK_591 task file names the task")
	_assert(status_text.contains("TASK_591 - Debrief AAR Player Review Notes Pass"), "Implementation status tracks TASK_591")
	_assert(status_text.contains("TASK_592 - Debrief AAR Player Review Findings"), "Implementation status names TASK_592 follow-up")
	_assert(roadmap_text.contains("TASK_591 - Debrief AAR Player Review Notes Pass (implementiert)"), "Roadmap marks TASK_591 implemented")
	_assert(roadmap_text.contains("TASK_592 - Debrief AAR Player Review Findings"), "Roadmap names TASK_592 follow-up")
	_assert(contract_text.contains("Debrief-AAR-Player-Review-Notes"), "Mission feedback contract documents TASK_591")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_591 Debrief-AAR Player-Review"), "Review workbench contains TASK_591 block")
	_assert(report_text.contains("TASK_592 - Debrief AAR Player Review Findings"), "Review workbench names TASK_592 follow-up")
	_assert(report_text.contains("JSON exportieren"), "Review workbench still exposes JSON export")
	_assert(FileAccess.file_exists(TASK_590_TEST_PATH), "TASK_590 layout polish verifier remains available")


func _test_report_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	var required_export_keys: Array[String] = [
		"debrief_aar_manual.screenshot_done",
		"debrief_aar_manual.summary_prefix_checked",
		"debrief_aar_manual.chips_checked",
		"debrief_aar_manual.rows_checked",
		"debrief_aar_manual.limit_checked",
		"debrief_aar_manual.return_flow_checked",
		"debrief_aar_manual.screenshot_path",
		"debrief_aar_manual.viewport",
		"debrief_aar_manual.layout_key",
		"debrief_aar_manual.evidence_png",
		"debrief_aar_manual.summary_notes",
		"debrief_aar_manual.chip_notes",
		"debrief_aar_manual.rows_limit_notes",
		"debrief_aar_manual.return_flow_notes",
		"debrief_aar_manual.followup",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	var required_choice_groups: Array[String] = [
		"debrief_aar_manual.result",
		"debrief_aar_manual.summary_rating",
		"debrief_aar_manual.chip_rating",
		"debrief_aar_manual.rows_limit_rating",
		"debrief_aar_manual.next_polish_priority",
	]
	for choice_group in required_choice_groups:
		_assert(report_text.contains('data-choice-group="%s"' % choice_group), "Report exports choice group %s" % choice_group)
	_assert(report_text.contains('data-note-key="notes.debrief_aar_manual_review"'), "Report exports free Debrief AAR review notes")
	_assert(report_text.contains("debrief_aar_layout_polish_v1"), "Report references TASK_590 layout key")
	_assert(report_text.contains("tmp/debrief_aar_f6_visual_evidence.png"), "Report references TASK_589 evidence PNG")
	_assert(report_text.contains("task_591_debrief_aar_player_review_notes_pass.gd"), "Report lists TASK_591 verifier")
	_assert(report_text.contains('"TASK_591 - Debrief AAR Player Review Notes Pass"'), "JSON payload lists TASK_591 as recently completed")
	_assert(report_text.contains('"TASK_592 - Debrief AAR Player Review Findings"'), "JSON payload recommends TASK_592")
	_assert(report_text.contains('current_focus: "TASK_592 - Debrief AAR Player Review Findings"'), "JSON payload sets current focus to TASK_592")
	_assert(not report_text.contains("TASK_591 Player-Review offen"), "Report no longer marks TASK_591 open in header")


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
