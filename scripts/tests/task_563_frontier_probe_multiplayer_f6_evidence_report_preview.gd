extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_563_frontier_probe_multiplayer_f6_evidence_report_preview.md"
const TASK_562_PATH: String = "res://docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TASK_562_TEST_PATH: String = "res://scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_563 Frontier Probe Multiplayer F6 Evidence Report Preview ===")
	_test_docs_and_report_wiring()
	_test_evidence_preview_export_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_563: FAILED")
		quit(1)
		return
	print("TASK_563: ALL PASSED")
	quit(0)


func _test_docs_and_report_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_562_text: String = _read_text(TASK_562_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_563 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer F6 Evidence Report Preview"), "TASK_563 task file names the task")
	_assert(task_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "TASK_563 task file names TASK_564 follow-up")
	_assert(task_562_text.contains("TASK_564"), "TASK_562 task file points apply step to TASK_564")
	_assert(status_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview"), "Implementation status tracks TASK_563")
	_assert(status_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Implementation status names TASK_564 follow-up")
	_assert(roadmap_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview (implementiert)"), "Roadmap marks TASK_563 implemented")
	_assert(roadmap_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Roadmap names TASK_564 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-F6-Evidence-Report-Preview"), "Mission feedback contract documents TASK_563")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview"), "Review workbench tracks TASK_563")
	_assert(report_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Review workbench names TASK_564 follow-up")
	_assert(FileAccess.file_exists(TASK_562_TEST_PATH), "TASK_562 visual evidence capture remains available")


func _test_evidence_preview_export_fields() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("TASK_562 Frontier-Probe MP-F6 Evidence Preview"), "Report exposes TASK_562 evidence preview block")
	_assert(report_text.contains("src=\"../../tmp/frontier_probe_mp_f6_visual_evidence.png\""), "Report embeds local TASK_562 PNG path")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.png_path\""), "Report exports evidence PNG path")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.manifest_path\""), "Report exports evidence manifest path")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.viewport\""), "Report exports evidence viewport")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.readability_gate\""), "Report exports TASK_557 readability gate")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.teamchip_tooltip_gate\""), "Report exports TASK_560 teamchip tooltip gate")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.viewport_readback_available\""), "Report exports viewport readback flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.generated_evidence_board\""), "Report exports evidence board flag")
	_assert(report_text.contains("data-export-key=\"mp_f6_evidence.manual_review_status\""), "Report exports manual review status")
	_assert(report_text.contains("\"TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview\""), "JSON metadata lists TASK_563 as completed")
	_assert(report_text.contains("current_focus: \"TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings\""), "JSON metadata points current focus to TASK_564")
	_assert(report_text.contains("latest_completed_task: \"TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview\""), "JSON metadata marks TASK_563 as latest completed")
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
