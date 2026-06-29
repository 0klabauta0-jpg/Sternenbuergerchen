extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_564_frontier_probe_multiplayer_apply_visual_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_562_TEST_PATH: String = "res://scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd"
const TASK_563_TEST_PATH: String = "res://scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_564 Frontier Probe Multiplayer Apply Visual Polish Findings ===")
	_test_docs_and_report_wiring()
	_test_evidence_board_polish_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_564: FAILED")
		quit(1)
		return
	print("TASK_564: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_564 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer Apply Visual Polish Findings"), "TASK_564 task file names the task")
	_assert(task_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass"), "TASK_564 task file names TASK_565 follow-up")
	_assert(status_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Implementation status tracks TASK_564")
	_assert(status_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass"), "Implementation status tracks TASK_565")
	_assert(status_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Implementation status tracks TASK_566")
	_assert(status_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Implementation status tracks TASK_567")
	_assert(status_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Implementation status tracks TASK_568")
	_assert(status_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Implementation status tracks TASK_569")
	_assert(status_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Implementation status names TASK_570 follow-up")
	_assert(roadmap_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings (implementiert)"), "Roadmap marks TASK_564 implemented")
	_assert(roadmap_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass (implementiert)"), "Roadmap tracks TASK_565 real screenshot review")
	_assert(roadmap_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass (implementiert)"), "Roadmap tracks TASK_566 hover/panel polish")
	_assert(roadmap_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass (implementiert)"), "Roadmap marks TASK_567 implemented")
	_assert(roadmap_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Roadmap tracks TASK_568")
	_assert(roadmap_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Roadmap tracks TASK_569")
	_assert(roadmap_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Roadmap names TASK_570 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-Apply-Visual-Polish-Findings"), "Mission feedback contract documents TASK_564")
	_assert(report_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Review workbench tracks TASK_564")
	_assert(report_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Review workbench tracks TASK_566")
	_assert(report_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Review workbench tracks TASK_567")
	_assert(report_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Review workbench tracks TASK_568")
	_assert(report_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Review workbench tracks TASK_569")
	_assert(report_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Review workbench names TASK_570 follow-up")
	_assert(FileAccess.file_exists(TASK_562_TEST_PATH), "TASK_562 visual evidence capture remains available")
	_assert(FileAccess.file_exists(TASK_563_TEST_PATH), "TASK_563 evidence report verifier remains available")


func _test_evidence_board_polish_contract() -> void:
	var capture_text: String = _read_text(TASK_562_TEST_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(capture_text.contains("_draw_evidence_grid"), "Capture draws an evidence grid")
	_assert(capture_text.contains("_draw_evidence_swatch_strip"), "Capture draws evidence swatches")
	_assert(capture_text.contains("_draw_rect_outline"), "Capture draws region outlines")
	_assert(capture_text.contains("evidence_board_regions"), "Capture writes evidence board regions")
	_assert(capture_text.contains("evidence_board_region_count"), "Capture writes evidence board region count")
	_assert(capture_text.contains("Mission Teamchip"), "Capture region data names Mission Teamchip")
	_assert(capture_text.contains("Mission Control"), "Capture region data names Mission Control")
	_assert(capture_text.contains("Selected Fireteam"), "Capture region data names Selected Fireteam")
	_assert(capture_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Capture manifest names TASK_570 follow-up")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.region_legend_present\""), "Report exports region legend flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.region_count\""), "Report exports region count")
	_assert(report_text.contains("swatch teamchip"), "Report shows Teamchip swatch")
	_assert(report_text.contains("swatch mission"), "Report shows Mission Control swatch")
	_assert(report_text.contains("swatch selected"), "Report shows Selected Fireteam swatch")
	_assert(report_text.contains("swatch strategic"), "Report shows Strategic Panel swatch")
	_assert(report_text.contains("swatch fireteam"), "Report shows Fireteam Panel swatch")
	_assert(report_text.contains("swatch tooltip"), "Report shows Tooltip Probe swatch")
	_assert(report_text.contains("latest_completed_task: \"TASK_569 - Frontier Probe Threat Preview Visual Review\""), "JSON metadata marks TASK_569 as latest completed")
	_assert(report_text.contains("current_focus: \"TASK_570 - Hold Fire Discipline Mission Bridge\""), "JSON metadata points current focus to TASK_570")
	_assert(not report_text.contains("data-export-key=\"mp_f6_manual.screenshot_done\" checked"), "Manual MP-F6 screenshot remains open")


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
