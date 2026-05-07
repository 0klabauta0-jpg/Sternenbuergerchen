extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")

const GATE_RUNNER_PATH: String = "res://scripts/tests/run_task_262_playability_gate.ps1"
const REPORT_PATH: String = "res://docs/reports/playability_regression_gate_report.md"
const MANUAL_CHECKLIST_PATH: String = "res://docs/manual_checks/playability_manual_open_items.md"
const COVERAGE_MATRIX_PATH: String = "res://docs/qa/playability_coverage_matrix.md"

const GATE_TASKS: Array = [
	{
		"id": "TASK_256",
		"script": "res://scripts/tests/task_256_automated_playability_coverage_contract.gd",
		"kind": "contract",
	},
	{
		"id": "TASK_257",
		"script": "res://scripts/tests/task_257_button_reachability_and_interaction_verifier.gd",
		"kind": "buttons",
		"report": "res://docs/reports/playability_button_reachability_report.md",
	},
	{
		"id": "TASK_258",
		"script": "res://scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd",
		"kind": "layout",
		"report": "res://docs/reports/playability_layout_clipping_scrollbar_report.md",
	},
	{
		"id": "TASK_259",
		"script": "res://scripts/tests/task_259_character_card_roster_switching_playability.gd",
		"kind": "character",
		"report": "res://docs/reports/playability_character_card_roster_switching_report.md",
	},
	{
		"id": "TASK_260",
		"script": "res://scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd",
		"kind": "loadout",
		"report": "res://docs/reports/playability_loadout_weight_report.md",
	},
	{
		"id": "TASK_261",
		"script": "res://scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd",
		"kind": "cross_screen",
		"report": "res://docs/reports/playability_cross_screen_state_loss_report.md",
	},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_262 Playability Regression Gate and Manual Open Items ===")
	_test_gate_runner_contract()
	_test_report_contract()
	_test_coverage_matrix_contract()
	_test_manual_checklist_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_gate_runner_contract() -> void:
	_assert(FileAccess.file_exists(GATE_RUNNER_PATH), "PowerShell playability gate runner exists")
	var runner_text: String = _read_text(GATE_RUNNER_PATH)
	_assert(runner_text.contains("git diff --check"), "Gate runner includes git diff --check")
	_assert(runner_text.contains("Hard failures"), "Gate runner separates hard failures in its summary")
	for task_variant in GATE_TASKS:
		var task: Dictionary = Dictionary(task_variant)
		var task_id: String = String(task.get("id", ""))
		var script_path: String = String(task.get("script", ""))
		_assert(FileAccess.file_exists(script_path), "%s script exists" % task_id)
		_assert(runner_text.contains(script_path.replace("res://", "")), "Gate runner includes %s" % task_id)
	_assert(_tasks_are_in_runner_order(runner_text), "Gate runner keeps TASK_256 through TASK_261 in order")


func _test_report_contract() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Playability regression gate report exists")
	var report_text: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Gate Tasks", "Hard Failures", "Warnings", "Manual Items", "Coverage Matrix", "Standard Command"]:
		_assert(report_text.contains(required_text), "Gate report covers %s" % required_text)
	for task_variant in GATE_TASKS:
		var task: Dictionary = Dictionary(task_variant)
		var task_id: String = String(task.get("id", ""))
		_assert(report_text.contains(task_id), "Gate report references %s" % task_id)
		var report_path: String = String(task.get("report", ""))
		if not report_path.is_empty():
			_assert(FileAccess.file_exists(report_path), "%s linked report exists" % task_id)


func _test_coverage_matrix_contract() -> void:
	_assert(FileAccess.file_exists(COVERAGE_MATRIX_PATH), "Playability coverage matrix exists")
	var matrix_text: String = _read_text(COVERAGE_MATRIX_PATH)
	for required_text in ["Gate Coverage Summary", "TASK_256", "TASK_257", "TASK_258", "TASK_259", "TASK_260", "TASK_261"]:
		_assert(matrix_text.contains(required_text), "Coverage matrix covers %s" % required_text)
	_assert(_matrix_row_has_status(matrix_text, "singleplayer_setup", "automated"), "Singleplayer setup is automated after cross-screen smoke")
	_assert(_matrix_row_has_status(matrix_text, "character_sheet", "automated"), "Character sheet is automated after roster switching smoke")
	_assert(_matrix_row_has_status(matrix_text, "debrief", "automated"), "Debrief is automated after cross-screen smoke")
	_assert(_matrix_row_has_status(matrix_text, "flow_main_to_meta_to_fob", "automated"), "Meta to FOB flow is automated")
	_assert(_matrix_row_has_status(matrix_text, "flow_fob_to_mission_to_debrief", "automated"), "FOB to mission/debrief flow is automated")
	for status in ["automated", "manual", "blocked", "not_applicable"]:
		_assert(bool(HARNESS_SCRIPT.call("coverage_status_is_valid", status)), "Harness accepts coverage status %s" % status)


func _test_manual_checklist_contract() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECKLIST_PATH), "Manual playability open-items checklist exists")
	var checklist_text: String = _read_text(MANUAL_CHECKLIST_PATH)
	for required_text in ["Audio Feel", "Visual Readability", "Drag-and-drop Feel", "Screen Transitions", "Two-client Multiplayer", "Not Repeated Here"]:
		_assert(checklist_text.contains(required_text), "Manual checklist covers %s" % required_text)
	_assert(checklist_text.split("\n").size() <= 80, "Manual checklist stays short")


func _tasks_are_in_runner_order(runner_text: String) -> bool:
	var previous_index: int = -1
	for task_variant in GATE_TASKS:
		var task: Dictionary = Dictionary(task_variant)
		var script_path: String = String(task.get("script", "")).replace("res://", "")
		var index: int = runner_text.find(script_path)
		if index < 0 or index <= previous_index:
			return false
		previous_index = index
	return true


func _matrix_row_has_status(matrix_text: String, row_id: String, status: String) -> bool:
	var row_token: String = "`%s`" % row_id
	var status_token: String = "`%s`" % status
	for line in matrix_text.split("\n"):
		if line.contains(row_token) and line.contains(status_token):
			return true
	return false


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
