extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_557_TEST_PATH: String = "res://scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_558 Frontier Probe Multiplayer Manual Screenshot Notes Pass ===")
	_test_docs_and_report_wiring()
	_test_manual_review_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_558: FAILED")
		quit(1)
		return
	print("TASK_558: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_558 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer Manual Screenshot Notes Pass"), "TASK_558 task file names the task")
	_assert(status_text.contains("TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass"), "Implementation status tracks TASK_558")
	_assert(roadmap_text.contains("TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass (implementiert)"), "Roadmap marks TASK_558 implemented")
	_assert(roadmap_text.contains("TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide (implementiert)"), "Roadmap tracks TASK_561 review guide")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-Manual-Screenshot-Notes"), "Mission feedback contract documents TASK_558")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass"), "Review workbench tracks TASK_558")
	_assert(report_text.contains("TASK_563 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Review workbench names TASK_563 follow-up")
	_assert(FileAccess.file_exists(TASK_557_TEST_PATH), "TASK_557 F6 readability smoke remains available")


func _test_manual_review_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("TASK_558 Frontier-Probe MP-F6 Screenshot-/Hover-Review"), "Report exposes TASK_558 manual review block")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.screenshot_done\""), "Report exports MP-F6 manual screenshot completion flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.host_client_context_checked\""), "Report exports Host/Client context check flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.team_chip_checked\""), "Report exports Teamchip check flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.objective_cargo_checked\""), "Report exports Objective/Cargo check flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.selected_fireteam_checked\""), "Report exports Selected Fireteam check flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.panel_overlap_checked\""), "Report exports panel overlap check flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.screenshot_path\""), "Report exports screenshot path")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.viewport\""), "Report exports viewport note")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.host_client_context\""), "Report exports Host/Client context note")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.result\""), "Report exports manual review result choice")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.team_chip_notes\""), "Report exports Teamchip notes")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.objective_cargo_notes\""), "Report exports Objective/Cargo notes")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.panel_hover_notes\""), "Report exports panel and hover notes")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.followup\""), "Report exports concrete follow-up notes")
	_assert(report_text.contains("data-note-key=\"notes.mp_f6_manual_review\""), "Report exports free-form MP-F6 review note")
	_assert(report_text.contains("\"TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass\""), "JSON metadata lists TASK_558 as completed")
	_assert(report_text.contains("current_focus: \"TASK_563 - Frontier Probe Multiplayer Apply Visual Polish Findings\""), "JSON metadata points current focus to TASK_563")
	_assert(not report_text.contains("data-export-key=\"mp_f6_manual.screenshot_done\" checked"), "Manual MP-F6 screenshot is not pre-marked as done")


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
