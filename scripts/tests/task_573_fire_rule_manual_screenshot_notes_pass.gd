extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_573_fire_rule_manual_screenshot_notes_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_572_TEST_PATH: String = "res://scripts/tests/task_572_fire_rule_f6_readability_smoke.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_573 Fire Rule Manual Screenshot Notes Pass ===")
	_test_docs_and_report_wiring()
	_test_manual_review_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_573: FAILED")
		quit(1)
		return
	print("TASK_573: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_573 task file exists")
	_assert(task_text.contains("Fire Rule Manual Screenshot Notes Pass"), "TASK_573 task file names the task")
	_assert(status_text.contains("TASK_573 - Fire Rule Manual Screenshot Notes Pass"), "Implementation status tracks TASK_573")
	_assert(roadmap_text.contains("TASK_573 - Fire Rule Manual Screenshot Notes Pass (implementiert)"), "Roadmap marks TASK_573 implemented")
	_assert(roadmap_text.contains("TASK_574 - Fire Rule Real F6 Screenshot Review Pass"), "Roadmap names TASK_574 follow-up")
	_assert(report_text.contains("TASK_573 - Fire Rule Manual Screenshot Notes Pass"), "Review workbench tracks TASK_573")
	_assert(report_text.contains("TASK_574 - Fire Rule Real F6 Screenshot Review Pass"), "Review workbench names TASK_574 follow-up")
	_assert(contract_text.contains("Fire-Rule-Manual-Screenshot-Notes"), "Mission feedback contract documents TASK_573")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(FileAccess.file_exists(TASK_572_TEST_PATH), "TASK_572 F6 readability smoke remains available")


func _test_manual_review_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("TASK_573 Fire-Rule/ROE Screenshot-/Spielgefuehl-Review"), "Report exposes TASK_573 manual review block")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.screenshot_done\""), "Report exports Fire-Rule screenshot completion flag")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.buttons_checked\""), "Report exports button readability check flag")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.hover_checked\""), "Report exports hover check flag")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.command_flow_checked\""), "Report exports command-flow check flag")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.threat_preview_checked\""), "Report exports threat-preview interaction check flag")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.screenshot_path\""), "Report exports screenshot path")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.viewport\""), "Report exports viewport note")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.active_rule\""), "Report exports active rule note")
	_assert(report_text.contains("data-choice-group=\"fire_rule_manual.result\""), "Report exports manual review result choice")
	_assert(report_text.contains("data-choice-group=\"fire_rule_manual.button_readability_rating\""), "Report exports button readability rating")
	_assert(report_text.contains("data-choice-group=\"fire_rule_manual.tooltip_rating\""), "Report exports tooltip rating")
	_assert(report_text.contains("data-choice-group=\"fire_rule_manual.panel_density_rating\""), "Report exports panel density rating")
	_assert(report_text.contains("data-choice-group=\"fire_rule_manual.next_polish_priority\""), "Report exports next polish priority")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.button_notes\""), "Report exports button notes")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.hover_notes\""), "Report exports hover notes")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.preview_interaction_notes\""), "Report exports preview interaction notes")
	_assert(report_text.contains("data-export-key=\"fire_rule_manual.followup\""), "Report exports concrete follow-up notes")
	_assert(report_text.contains("data-note-key=\"notes.fire_rule_manual_review\""), "Report exports free-form Fire-Rule review note")
	_assert(report_text.contains("\"TASK_573 - Fire Rule Manual Screenshot Notes Pass\""), "JSON metadata lists TASK_573 as completed")
	_assert(report_text.contains("current_focus: \"TASK_574 - Fire Rule Real F6 Screenshot Review Pass\""), "JSON metadata points current focus to TASK_574")
	_assert(not report_text.contains("data-export-key=\"fire_rule_manual.screenshot_done\" checked"), "Manual Fire-Rule screenshot is not pre-marked as done")


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
