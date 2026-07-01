extends SceneTree

const FEEL_PASS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_mission_interaction_feel_pass.gd")
const ROUTE_CUE_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_route_cue_polish.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_775_station_reentry_mission_interaction_feel_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_775 Station Reentry Mission Interaction Feel Pass ===")
	_test_docs_contract_and_report()
	_test_missing_acceptance_blocks_feel_pass()
	_test_complete_interaction_feel_pass()
	_test_missing_cargo_cue_routes_to_cue_polish()
	_test_missing_command_affordance_routes_to_command_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_775: FAILED")
		quit(1)
		return
	print("TASK_775: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_775 task file exists")
	_assert(task_text.contains("Station Reentry Mission Interaction Feel Pass"), "TASK_775 task names mission interaction feel pass")
	_assert(status_text.contains("TASK_775 - Station Reentry Mission Interaction Feel Pass"), "Implementation status tracks TASK_775")
	_assert(roadmap_text.contains("TASK_775 - Station Reentry Mission Interaction Feel Pass (implementiert)"), "Roadmap marks TASK_775 implemented")
	_assert(contract_text.contains("Station-Reentry-Mission-Interaction-Feel-Pass"), "Mission command feedback contract documents TASK_775")
	_assert(report_text.contains("Aktueller Griff: TASK_786"), "Reentry handbook advances to TASK_786 current")
	_assert(report_text.contains('data-export-key="reentry_interaction_feel.ready_for_mission_interaction_playtest"'), "Reentry handbook exports TASK_775 feel gate")


func _test_missing_acceptance_blocks_feel_pass() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs.erase("acceptance")
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_mission_interaction_feel_pass.v1", "Feel-pass schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_reentry_accepted", "Missing acceptance blocks feel pass")
	_assert(not bool(snapshot.get("ready_for_mission_interaction_playtest", true)), "Missing acceptance is not ready")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("reentry_accepted"), "Missing acceptance gate is reported")
	_assert(_snapshot_is_read_only(snapshot), "Missing-acceptance snapshot remains read-only")


func _test_complete_interaction_feel_pass() -> void:
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", _complete_inputs()))
	_assert(String(snapshot.get("status", "")) == "ready_for_mission_interaction_playtest", "Complete gates are ready for interaction playtest")
	_assert(bool(snapshot.get("ready_for_mission_interaction_playtest", false)), "Ready flag is true")
	_assert(Array(snapshot.get("missing_route_tokens", [])).is_empty(), "All route tokens are present")
	_assert(Array(snapshot.get("missing_cue_tokens", [])).is_empty(), "All cue tokens are present")
	_assert(Array(snapshot.get("missing_commands", [])).is_empty(), "All command affordances are present")
	_assert(int(snapshot.get("cue_count", 0)) >= 4, "At least four cues are summarized")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_776"), "Ready feel pass routes to TASK_776")
	_assert(_snapshot_is_read_only(snapshot), "Complete feel-pass snapshot remains read-only")


func _test_missing_cargo_cue_routes_to_cue_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	var cues: Array = Array(inputs.get("cues", []))
	cues.pop_back()
	inputs["cues"] = cues
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_interaction_cue_polish", "Missing cargo cue routes to cue polish")
	_assert(Array(snapshot.get("missing_cue_tokens", [])).has("CARGO"), "Missing cargo cue is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("interaction cues"), "Cue failure recommends cue polish")


func _test_missing_command_affordance_routes_to_command_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["command_affordances"] = {
		"available_commands": ["move", "take", "breach", "go"],
		"preview_before_go": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_command_affordance_polish", "Missing command affordance routes to command polish")
	_assert(Array(snapshot.get("missing_commands", [])).has("defend"), "Missing defend command is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("command affordances"), "Command failure recommends affordance polish")


func _complete_inputs() -> Dictionary:
	return {
		"acceptance": _accepted_task_774(),
		"route_readout": _route_readout(),
		"cues": [
			_build_cue("AA", "out_of_range", "take", "blue", 3859.0),
			_build_cue("DOOR", "usable", "breach", "blue", 64.0),
			_build_cue("COM", "in_progress", "take", "blue", 24.0, "halten 8/18s"),
			_build_cue("CARGO", "usable", "defend", "blue", 72.0),
		],
		"command_affordances": {
			"available_commands": ["move", "take", "breach", "defend", "go"],
			"preview_before_go": true,
			"go_requires_confirmation": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_navigation": false,
		},
	}


func _accepted_task_774() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_next_playable_slice_acceptance.v1",
		"task_id": "TASK_774",
		"status": "accepted_for_next_playable_slice",
		"accepted_for_next_playable_slice": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}


func _route_readout() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_run_readout.v1",
		"route_tokens": ["AA", "DOOR", "COM", "CARGO"],
		"aa_token": "AA offen",
		"door_token": "DOOR offen",
		"computer_token": "COM offen",
		"cargo_token": "CARGO offen",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}


func _build_cue(token: String, runtime_status: String, action_label: String, fireteam_id: String, distance: float, progress_line: String = "") -> Dictionary:
	var objective_gate: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_objective_gate.v1",
		"next_step_id": _step_for_token(token),
		"next_interaction_id": "interaction_%s" % token.to_lower(),
		"next_action_label": action_label,
		"next_runtime_use_status": runtime_status,
		"next_interaction": {
			"nearest_fireteam_id": fireteam_id,
			"distance_world": distance,
			"runtime_use_status": runtime_status,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}
	var route_readout: Dictionary = {
		"schema": "sternenbuergerchen.station_route_run_readout.v1",
		"next_token": token,
		"next_step_id": _step_for_token(token),
		"all_gates_complete": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}
	var use_feedback: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_use_feedback.v1",
		"primary_feedback": {
			"status": runtime_status,
			"action_label": action_label,
			"nearest_fireteam_id": fireteam_id,
			"distance_world": distance,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}
	var progress: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_progress_readability.v1",
		"compact_line": progress_line,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}
	return Dictionary(ROUTE_CUE_SCRIPT.call("build_snapshot", route_readout, objective_gate, use_feedback, progress))


func _step_for_token(token: String) -> String:
	match token:
		"AA":
			return "disable_air_defense"
		"DOOR":
			return "open_station_door"
		"COM":
			return "occupy_station_computer"
		"CARGO":
			return "cargo_touchdown_extract"
	return "unknown"


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
