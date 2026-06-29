extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_561_frontier_probe_multiplayer_manual_visual_review_guide.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_558_TEST_PATH: String = "res://scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd"
const TASK_560_TEST_PATH: String = "res://scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd"
const TASK_562_TEST_PATH: String = "res://scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd"
const TASK_563_TEST_PATH: String = "res://scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_561 Frontier Probe Multiplayer Manual Visual Review Guide ===")
	_test_docs_and_report_wiring()
	_test_manual_review_guide_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_561: FAILED")
		quit(1)
		return
	print("TASK_561: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_561 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer Manual Visual Review Guide"), "TASK_561 task file names the task")
	_assert(status_text.contains("TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide"), "Implementation status tracks TASK_561")
	_assert(roadmap_text.contains("TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide (implementiert)"), "Roadmap marks TASK_561 implemented")
	_assert(roadmap_text.contains("TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture (implementiert)"), "Roadmap tracks TASK_562 evidence capture")
	_assert(roadmap_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview (implementiert)"), "Roadmap tracks TASK_563 evidence preview")
	_assert(roadmap_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings (implementiert)"), "Roadmap tracks TASK_564 evidence polish")
	_assert(roadmap_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass (implementiert)"), "Roadmap tracks TASK_565 real screenshot review")
	_assert(roadmap_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass (implementiert)"), "Roadmap tracks TASK_566 hover/panel polish")
	_assert(roadmap_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass (implementiert)"), "Roadmap marks TASK_567 implemented")
	_assert(roadmap_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Roadmap names TASK_568 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-Manual-Visual-Review-Guide"), "Mission feedback contract documents TASK_561")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide"), "Review workbench tracks TASK_561")
	_assert(report_text.contains("TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture"), "Review workbench tracks TASK_562")
	_assert(report_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview"), "Review workbench tracks TASK_563")
	_assert(report_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Review workbench tracks TASK_564")
	_assert(report_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Review workbench tracks TASK_566")
	_assert(report_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Review workbench tracks TASK_567")
	_assert(report_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Review workbench names TASK_568 follow-up")
	_assert(FileAccess.file_exists(TASK_558_TEST_PATH), "TASK_558 manual screenshot verifier remains available")
	_assert(FileAccess.file_exists(TASK_560_TEST_PATH), "TASK_560 teamchip tooltip verifier remains available")
	_assert(FileAccess.file_exists(TASK_562_TEST_PATH), "TASK_562 visual evidence verifier remains available")
	_assert(FileAccess.file_exists(TASK_563_TEST_PATH), "TASK_563 evidence preview verifier remains available")


func _test_manual_review_guide_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("TASK_558 Frontier-Probe MP-F6 Screenshot-/Hover-Review"), "Report keeps MP-F6 manual review block")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.team_chip_hover_checked\""), "Report exports teamchip hover check")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.team_chip_tooltip_owner_spawn_checked\""), "Report exports teamchip tooltip owner/spawn check")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.dropship_cards_checked\""), "Report exports dropship cards check")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.world_objective_visibility_checked\""), "Report exports world/objective visibility check")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.team_chip_rating\""), "Report exports teamchip rating")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.objective_cargo_rating\""), "Report exports objective/cargo rating")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.selected_fireteam_rating\""), "Report exports selected fireteam rating")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.panel_density_rating\""), "Report exports panel density rating")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.world_occlusion_rating\""), "Report exports world occlusion rating")
	_assert(report_text.contains("data-choice-group=\"mp_f6_manual.next_polish_priority\""), "Report exports next polish priority")
	_assert(report_text.contains("data-export-key=\"mp_f6_manual.selected_fireteam_dropship_notes\""), "Report exports selected fireteam/dropship notes")
	_assert(report_text.contains("Teamchip-Hover"), "Report names Teamchip hover review criterion")
	_assert(report_text.contains("Objective/Cargo"), "Report names objective/cargo review criterion")
	_assert(report_text.contains("Weltverdeckung"), "Report names world occlusion review criterion")
	_assert(report_text.contains("\"TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide\""), "JSON metadata lists TASK_561 as completed")
	_assert(report_text.contains("\"TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture\""), "JSON metadata lists TASK_562 as completed")
	_assert(report_text.contains("\"TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview\""), "JSON metadata lists TASK_563 as completed")
	_assert(report_text.contains("\"TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings\""), "JSON metadata lists TASK_564 as completed")
	_assert(report_text.contains("current_focus: \"TASK_568 - Frontier Probe Risky Contact Preview Fixture\""), "JSON metadata points current focus to TASK_568")
	_assert(not report_text.contains("data-export-key=\"mp_f6_manual.screenshot_done\" checked"), "Manual MP-F6 screenshot is still not pre-marked as done")


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
