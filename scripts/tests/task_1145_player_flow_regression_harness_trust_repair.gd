extends SceneTree

const HARNESS := preload("res://scripts/tests/playability/playability_test_harness.gd")
const UI_BLOCK_LABELS := preload("res://scripts/meta/ui_block_labels.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	_check(HARNESS.new().has_method("is_control_reachable_in_viewport"), "Harness exposes scroll-aware reachability")
	_check(UI_BLOCK_LABELS.MISSION_LIVE_TACTICAL_GRID == "#15 EINSATZLAGE", "Shared #15 label matches the visible HUD contract")

	var task_096_source := _read("res://scripts/tests/task_096_recovery_verifier.gd")
	_check(task_096_source.contains("quit(1 if _failed > 0 else 0)"), "TASK_096 returns a failing process exit code")
	_check(task_096_source.contains("CharacterSheetValuesColumn"), "TASK_096 targets the current two-column character sheet")

	var task_257_source := _read("res://scripts/tests/task_257_button_reachability_and_interaction_verifier.gd")
	_check(task_257_source.contains("is_control_reachable_in_viewport"), "TASK_257 uses scroll-aware reachability")
	_check(task_257_source.contains("planning controls are hidden after the compact mission-control handoff"), "TASK_257 documents contextual Mission action visibility")

	var dropship_source := _read("res://scripts/tests/bugfix_dropship_mission_flow_verifier.gd")
	_check(dropship_source.contains("SUPERSEDED_BY_TASK_1145_GATE"), "Historical Dropship monolith names its replacement gate")
	_check(dropship_source.contains("quit(1 if _failed > 0 else 0)"), "Historical Dropship verifier cannot report false-green exit")

	var gate_source := _read("res://scripts/tests/run_task_1145_player_flow_regression_gate.ps1")
	_check(not gate_source.is_empty(), "TASK_1145 isolated process gate exists")
	_check(gate_source.contains("WaitForExit"), "TASK_1145 gate enforces process completion")
	_check(gate_source.contains("Kill"), "TASK_1145 gate terminates timed-out verifier processes")
	_check(gate_source.contains("task_1118_connected_first_contact_hud_perspective_visual_evidence.gd"), "TASK_1145 gate includes multiplayer HUD perspective")

	_finish()


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TASK_1145 PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("TASK_1145 FAIL: %s" % failure)
	quit(1)
