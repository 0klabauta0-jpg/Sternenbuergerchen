extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_579_suppress_fire_manual_f6_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_578_TEST_PATH: String = "res://scripts/tests/task_578_suppress_fire_visual_polish_findings.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_579 Suppress Fire Manual F6 Review ===")
	_test_docs_and_report_wiring()
	_test_manual_review_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_579: FAILED")
		quit(1)
		return
	print("TASK_579: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_579 task file exists")
	_assert(task_text.contains("Suppress Fire Manual F6 Review"), "TASK_579 task file names the task")
	_assert(status_text.contains("TASK_579 - Suppress Fire Manual F6 Review"), "Implementation status tracks TASK_579")
	_assert(roadmap_text.contains("TASK_579 - Suppress Fire Manual F6 Review (implementiert)"), "Roadmap marks TASK_579 implemented")
	_assert(roadmap_text.contains("TASK_580 - Suppress Fire Visual Tuning Findings"), "Roadmap names TASK_580 follow-up")
	_assert(report_text.contains("TASK_579 - Suppress Fire Manual F6 Review"), "Review workbench tracks TASK_579")
	_assert(report_text.contains("TASK_580 - Suppress Fire Visual Tuning Findings"), "Review workbench names TASK_580 follow-up")
	_assert(contract_text.contains("Suppress-Fire-Manual-F6-Review"), "Mission feedback contract documents TASK_579")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(FileAccess.file_exists(TASK_578_TEST_PATH), "TASK_578 SUP visual polish verifier remains available")


func _test_manual_review_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("TASK_579 Suppress-Fire F6 Sichtreview"), "Report exposes TASK_579 manual review block")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.screenshot_done\""), "Report exports SUP screenshot completion flag")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.sup_rule_selected\""), "Report exports SUP rule selected flag")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.move_preview_visible\""), "Report exports move preview visible flag")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.area_visible\""), "Report exports SUP area visible flag")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.no_go_committed\""), "Report exports no-GO preview flag")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.screenshot_path\""), "Report exports SUP screenshot path")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.viewport\""), "Report exports viewport note")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.visual_key\""), "Report exports SUP visual key")
	_assert(report_text.contains("data-choice-group=\"suppress_fire_manual.area_color\""), "Report exports color/alpha rating")
	_assert(report_text.contains("data-choice-group=\"suppress_fire_manual.area_size\""), "Report exports area size rating")
	_assert(report_text.contains("data-choice-group=\"suppress_fire_manual.status_clarity\""), "Report exports status clarity rating")
	_assert(report_text.contains("data-choice-group=\"suppress_fire_manual.next_priority\""), "Report exports next priority")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.color_alpha_notes\""), "Report exports color/alpha notes")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.size_overlap_notes\""), "Report exports size/overlap notes")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.status_language_notes\""), "Report exports status language notes")
	_assert(report_text.contains("data-export-key=\"suppress_fire_manual.followup\""), "Report exports TASK_580 follow-up notes")
	_assert(report_text.contains("data-note-key=\"notes.suppress_fire_manual_review\""), "Report exports free-form SUP review note")
	_assert(report_text.contains("\"TASK_579 - Suppress Fire Manual F6 Review\""), "JSON metadata lists TASK_579 as completed")
	_assert(report_text.contains("\"TASK_580 - Suppress Fire Visual Tuning Findings\""), "JSON metadata lists TASK_580 as next task")
	_assert(not report_text.contains("data-export-key=\"suppress_fire_manual.screenshot_done\" checked"), "Manual SUP screenshot is not pre-marked as done")
	_assert(report_text.contains("suppress_area_v1"), "Report keeps stable suppress area visual key")
	_assert(report_text.contains("Kein <code>GO</code>") or report_text.contains("keinen <code>GO</code>"), "Report names read-only no-GO boundary")


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
