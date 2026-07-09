extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1012_release_first_decision_loop_two_player_loop_scenario_stitch.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_stitch.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_stitch.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_stitch.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.v1"
const NEXT_TASK := "TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1012 Release First Decision Loop Two Player Loop Scenario Stitch ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_accepted_round_loop_without_stitch_trace_needs_trace()
	_test_failed_stitch_trace_reports_regression()
	_test_good_stitch_trace_builds_scenario_contract()
	_test_controller_exports_scenario_stitch()
	_test_scenario_stitch_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1012_release_first_decision_loop_two_player_loop_scenario_stitch: FAILED")
		quit(1)
		return
	print("TASK_1012_release_first_decision_loop_two_player_loop_scenario_stitch: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1012 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1012 scenario stitch service exists")
	_assert(task_text.contains("TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch"), "Task names TASK_1012")
	_assert(task_text.contains(NEXT_TASK), "Task names runtime hook follow-up")
	_assert(status_text.contains("TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch"), "Implementation status tracks TASK_1012")
	_assert(roadmap_text.contains("TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch (implementiert"), "Roadmap marks TASK_1012 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Stitch (TASK_1012)"), "Mission feedback contract documents TASK_1012")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Stitch (TASK_1012)"), "Decision clarity contract documents TASK_1012")
	_assert(service_text.contains(SCHEMA), "Scenario stitch service exposes stable TASK_1012 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1012\""), "Scenario stitch service writes TASK_1012 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1011\""), "Scenario stitch service links TASK_1011")
	_assert(service_text.contains("REQUIRED_STITCH_CHECKS"), "Scenario stitch service defines required checks")
	_assert(service_text.contains("\"scenario_beats\""), "Scenario stitch exposes scenario beats")
	_assert(service_text.contains("\"two_player_roles\""), "Scenario stitch exposes two-player roles")
	_assert(service_text.contains("\"scenario_stitch_ready\""), "Scenario stitch exposes readiness flag")
	_assert(service_text.contains("\"creates_command\": false"), "Scenario stitch creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Scenario stitch creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_STITCH_SCRIPT"), "Controller preloads TASK_1012 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_stitch_snapshot"), "Controller exposes TASK_1012 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_stitch_line"), "Command feedback exports TASK_1012 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_stitch_status"), "Command feedback exports TASK_1012 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1012")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_accepted"), "Missing source reports source not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Blocked scenario stitch snapshot remains read-only")


func _test_accepted_round_loop_without_stitch_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1012")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1012", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1011", "Snapshot links TASK_1011")
	_assert(String(snapshot.get("source_status", "")) == "round_loop_acceptance_slice_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_scenario_stitch_trace", "Accepted source without trace needs scenario stitch trace")
	_assert(String(snapshot.get("gate", "")) == "needs_scenario_stitch_trace", "Gate asks for stitch trace")
	_assert(issue_ids.has("scenario_stitch_trace_missing"), "Missing stitch trace is explicit")
	_assert(not bool(snapshot.get("scenario_stitch_ready", true)), "Missing trace does not set stitch ready")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_stitch_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_stitch_checks", []))
	_assert(String(snapshot.get("status", "")) == "scenario_stitch_regression_found", "Failed trace reports stitch regression")
	_assert(String(snapshot.get("gate", "")) == "scenario_stitch_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("scenario_beats_present"), "Failed trace records missing beats")
	_assert(missing_checks.has("two_player_roles_present"), "Failed trace records missing two-player roles")
	_assert(issue_ids.has("scenario_beats_missing"), "Missing beats issue is explicit")
	_assert(issue_ids.has("two_player_roles_missing"), "Missing two-player roles issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice", "Regression routes back to TASK_1011 acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_stitch_trace_builds_scenario_contract() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance(), _good_trace())
	var beats: Array = Array(snapshot.get("scenario_beats", []))
	var roles: Array = Array(snapshot.get("two_player_roles", []))
	_assert(String(snapshot.get("status", "")) == "scenario_stitch_ready", "Good trace builds scenario stitch")
	_assert(String(snapshot.get("gate", "")) == "scenario_stitch_ready", "Good trace gate is ready")
	_assert(bool(snapshot.get("scenario_stitch_ready", false)), "Good trace sets readiness flag")
	_assert(String(snapshot.get("scenario_stitch_line", "")).contains("FOB"), "Scenario line names FOB")
	_assert(String(snapshot.get("scenario_stitch_line", "")).contains("FEEL"), "Scenario line names FEEL")
	_assert(String(snapshot.get("scenario_stitch_line", "")).contains("GO separat"), "Scenario line names GO boundary")
	_assert(beats.size() >= 5, "Scenario has at least five beats")
	_assert(String(Dictionary(beats[0]).get("beat_id", "")) == "entry", "First beat is entry")
	_assert(String(Dictionary(beats[beats.size() - 1]).get("beat_id", "")) == "exit", "Last beat is exit")
	_assert(roles.size() == 2, "Scenario exposes two player roles")
	_assert(String(Dictionary(roles[0]).get("role_id", "")).contains("alpha"), "First role names alpha")
	_assert(String(Dictionary(roles[1]).get("role_id", "")).contains("bravo"), "Second role names bravo")
	_assert(String(snapshot.get("mission_objective_line", "")).contains("sichern"), "Mission objective names sichern")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Ready stitch recommends runtime hook")
	_assert(_snapshot_is_read_only(snapshot), "Ready stitch remains read-only")


func _test_controller_exports_scenario_stitch() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_stitch_snapshot"):
		_assert(false, "Controller exposes TASK_1012 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_stitch_snapshot(_source_acceptance(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1012 schema matches")
	_assert(String(snapshot.get("status", "")) == "scenario_stitch_ready", "Controller TASK_1012 can build ready stitch")
	_assert(String(snapshot.get("scenario_stitch_line", "")).contains("NEXT"), "Controller TASK_1012 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1012 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_stitch"), "Command feedback embeds TASK_1012")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_stitch_line"), "Command feedback exports TASK_1012 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_stitch_status"), "Command feedback exports TASK_1012 status")
	controller.queue_free()


func _test_scenario_stitch_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1012 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1012", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1011", "Roundtrip keeps TASK_1011 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_acceptance: Dictionary, stitch_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1012 service is loadable")
		return {
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		}
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1012 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_acceptance, stitch_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1012 service returns dictionary")
	return {}


func _source_acceptance() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1011",
		"source_task_id": "TASK_1010",
		"status": "round_loop_acceptance_slice_passed",
		"gate": "round_loop_acceptance_slice_passed",
		"round_loop_acceptance_slice_passed": true,
		"round_loop_acceptance_line": "FEEL rund | NEXT klar | GO separat | PASS",
		"answered_player_questions": [
			"what_is_the_round_state",
			"what_is_next",
			"what_requires_go",
			"what_feedback_means",
			"why_the_hud_is_quiet",
			"who_owns_truth",
		],
		"answered_player_question_count": 6,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"scenario_beats_present",
		"entry_and_exit_present",
		"mission_objective_present",
		"two_player_roles_present",
		"npc_pressure_present",
		"feel_next_go_loop_embedded",
		"feedback_next_hook_present",
		"multiplayer_boundary_preserved",
		"no_new_gameplay_truth",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"scenario_id": "fob_relay_probe",
		"scenario_title": "FOB Relay Probe",
		"mission_objective_line": "Relais sichern, Kontakt druecken, Fireteam sammeln.",
		"scenario_beats": [
			{"beat_id": "entry", "text": "FOB-Einstieg: Alpha landet, Bravo haelt Sicht."},
			{"beat_id": "first_contact", "text": "NPC-Druck am Relais, FEEL/NEXT/GO wird sichtbar."},
			{"beat_id": "decision", "text": "NEXT waehlen: sichern, druecken oder sammeln."},
			{"beat_id": "feedback", "text": "Feedback erklaert Ergebnis und fuehrt zu NEXT."},
			{"beat_id": "exit", "text": "Aussteigen oder zweite Runde starten."},
		],
		"two_player_roles": [
			{"role_id": "alpha_commander", "text": "Alpha bestaetigt GO und liest Feedback."},
			{"role_id": "bravo_commander", "text": "Bravo beobachtet Flanke und bekommt denselben NEXT-Rhythmus."},
		],
		"npc_pressure_line": "NPCs halten Relaisdeckung, ohne neue Combat-Wahrheit zu erzeugen.",
		"feel_next_go_loop_embedded": true,
		"feedback_next_hook_present": true,
		"multiplayer_boundary_preserved": true,
		"no_new_gameplay_truth": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["mission_objective_present", "feel_next_go_loop_embedded"]
	trace["scenario_beats"] = []
	trace["two_player_roles"] = []
	return trace


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
