extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_550_combat_hud_manual_screenshot_notes_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_549_TEST_PATH: String = "res://scripts/tests/task_549_combat_hud_f6_visual_audit.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_550 Combat HUD Manual Screenshot Notes Pass ===")
	_test_docs_and_report_wiring()
	_test_manual_review_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_550: FAILED")
		quit(1)
		return
	print("TASK_550: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_550 task file exists")
	_assert(task_text.contains("Combat HUD Manual Screenshot Notes Pass"), "TASK_550 task file names the task")
	_assert(status_text.contains("TASK_550 - Combat HUD Manual Screenshot Notes Pass"), "Implementation status tracks TASK_550")
	_assert(roadmap_text.contains("TASK_550 - Combat HUD Manual Screenshot Notes Pass (implementiert)"), "Roadmap marks TASK_550 implemented")
	_assert(roadmap_text.contains("TASK_551 - Combat HUD Tooltip Style Polish"), "Roadmap names TASK_551 follow-up")
	_assert(contract_text.contains("Combat-HUD-Manual-Screenshot-Notes"), "Mission feedback contract documents TASK_550")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_550 - Combat HUD Manual Screenshot Notes Pass"), "Review workbench tracks TASK_550")
	_assert(report_text.contains("TASK_551 - Combat HUD Tooltip Style Polish"), "Review workbench names TASK_551 follow-up")
	_assert(FileAccess.file_exists(TASK_549_TEST_PATH), "TASK_549 F6 visual audit smoke remains available")


func _test_manual_review_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("TASK_550 Combat-HUD Screenshot-/Hover-Review"), "Report exposes TASK_550 manual review block")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.screenshot_done\""), "Report exports manual screenshot completion flag")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.hover_selected_done\""), "Report exports Selected Fireteam hover flag")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.hover_mission_done\""), "Report exports Mission Control hover flag")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.screenshot_path\""), "Report exports screenshot path")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.viewport\""), "Report exports viewport note")
	_assert(report_text.contains("data-choice-group=\"combat_hud_manual.result\""), "Report exports manual review result choice")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.hover_notes\""), "Report exports hover notes")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.style_notes\""), "Report exports style notes")
	_assert(report_text.contains("data-export-key=\"combat_hud_manual.followup\""), "Report exports concrete follow-up notes")
	_assert(report_text.contains("data-note-key=\"notes.combat_hud_manual_review\""), "Report exports free-form Combat HUD review note")
	_assert(report_text.contains("\"TASK_550 - Combat HUD Manual Screenshot Notes Pass\""), "JSON metadata lists TASK_550 as completed")
	_assert(report_text.contains("current_focus: \"TASK_551 - Combat HUD Tooltip Style Polish\""), "JSON metadata points current focus to TASK_551")
	_assert(not report_text.contains("data-export-key=\"combat_hud_manual.screenshot_done\" checked"), "Manual screenshot is not pre-marked as done")


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
