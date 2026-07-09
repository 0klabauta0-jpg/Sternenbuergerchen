extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1013_release_first_decision_loop_two_player_loop_scenario_runtime_hook.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_runtime_hook.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_runtime_hook.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_hook.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_stitch.v1"
const NEXT_TASK := "TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1013 Release First Decision Loop Two Player Loop Scenario Runtime Hook ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_stitch_without_context_builds_default_runtime_hook()
	_test_runtime_context_selects_current_beat_and_choice()
	_test_invalid_runtime_context_reports_review_issue()
	_test_controller_exports_runtime_hook()
	_test_runtime_hook_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1013_release_first_decision_loop_two_player_loop_scenario_runtime_hook: FAILED")
		quit(1)
		return
	print("TASK_1013_release_first_decision_loop_two_player_loop_scenario_runtime_hook: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1013 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1013 scenario runtime hook service exists")
	_assert(task_text.contains("TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook"), "Task names TASK_1013")
	_assert(task_text.contains(NEXT_TASK), "Task names runtime smoke follow-up")
	_assert(status_text.contains("TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook"), "Implementation status tracks TASK_1013")
	_assert(roadmap_text.contains("TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook (implementiert"), "Roadmap marks TASK_1013 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Runtime Hook (TASK_1013)"), "Mission feedback contract documents TASK_1013")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Runtime Hook (TASK_1013)"), "Decision clarity contract documents TASK_1013")
	_assert(service_text.contains(SCHEMA), "Scenario runtime hook service exposes stable TASK_1013 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1013\""), "Scenario runtime hook service writes TASK_1013 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1012\""), "Scenario runtime hook service links TASK_1012")
	_assert(service_text.contains("\"runtime_hook_ready\""), "Scenario runtime hook exposes ready gate")
	_assert(service_text.contains("\"scenario_runtime_steps\""), "Scenario runtime hook exposes runtime steps")
	_assert(service_text.contains("\"mission_control_runtime_line\""), "Scenario runtime hook exposes Mission Control line")
	_assert(service_text.contains("\"selected_fireteam_runtime_line\""), "Scenario runtime hook exposes Selected Fireteam line")
	_assert(service_text.contains("\"command_matrix_runtime_hooks\""), "Scenario runtime hook exposes command matrix hooks")
	_assert(service_text.contains("\"creates_command\": false"), "Scenario runtime hook creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Scenario runtime hook creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_RUNTIME_HOOK_SCRIPT"), "Controller preloads TASK_1013 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_runtime_hook_snapshot"), "Controller exposes TASK_1013 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_runtime_hook_line"), "Command feedback exports TASK_1013 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_runtime_hook_status"), "Command feedback exports TASK_1013 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1013")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked runtime hook snapshot remains read-only")


func _test_ready_stitch_without_context_builds_default_runtime_hook() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_stitch(), {})
	var steps: Array = Array(snapshot.get("scenario_runtime_steps", []))
	var hooks: Array = Array(snapshot.get("command_matrix_runtime_hooks", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1013")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1013", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1012", "Snapshot links TASK_1012")
	_assert(String(snapshot.get("status", "")) == "runtime_hook_ready", "Ready stitch builds runtime hook")
	_assert(String(snapshot.get("gate", "")) == "runtime_hook_ready", "Ready stitch gate is runtime hook ready")
	_assert(bool(snapshot.get("runtime_hook_ready", false)), "Ready stitch sets runtime hook flag")
	_assert(steps.size() >= 5, "Runtime hook has at least five steps")
	_assert(String(Dictionary(steps[0]).get("step_id", "")) == "entry" if not steps.is_empty() else false, "First runtime step mirrors entry")
	_assert(String(snapshot.get("current_step_id", "")) == "entry", "Default current step is entry")
	_assert(String(snapshot.get("mission_control_runtime_line", "")).contains("FOB"), "Mission Control runtime line names FOB")
	_assert(String(snapshot.get("mission_control_runtime_line", "")).contains("NEXT"), "Mission Control runtime line names NEXT")
	_assert(String(snapshot.get("selected_fireteam_runtime_line", "")).contains("Alpha"), "Selected Fireteam runtime line names Alpha")
	_assert(hooks.size() >= 3, "Command Matrix exposes runtime hooks")
	_assert(_hook_ids(hooks).has("next"), "Command Matrix exposes NEXT hook")
	_assert(_hook_ids(hooks).has("confirm"), "Command Matrix exposes CONFIRM hook")
	_assert(_hook_ids(hooks).has("go"), "Command Matrix exposes GO hook")
	_assert(not bool(snapshot.get("auto_executes_go", true)), "Runtime hook does not auto-execute GO")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Runtime hook recommends runtime smoke")
	_assert(_snapshot_is_read_only(snapshot), "Runtime hook remains read-only")


func _test_runtime_context_selects_current_beat_and_choice() -> void:
	var context: Dictionary = {
		"current_step_id": "decision",
		"selected_role_id": "bravo_commander",
		"selected_runtime_choice_id": "secure_relay",
	}
	var snapshot: Dictionary = _build_snapshot(_ready_stitch(), context)
	var selected_choice: Dictionary = Dictionary(snapshot.get("selected_runtime_choice", {}))
	_assert(String(snapshot.get("current_step_id", "")) == "decision", "Context selects decision step")
	_assert(String(snapshot.get("selected_role_id", "")) == "bravo_commander", "Context selects bravo role")
	_assert(String(selected_choice.get("choice_id", "")) == "secure_relay", "Context selects secure relay choice")
	_assert(String(snapshot.get("selected_fireteam_runtime_line", "")).contains("Bravo"), "Selected Fireteam runtime line names Bravo")
	_assert(String(snapshot.get("mission_control_runtime_line", "")).contains("Relais"), "Mission Control line keeps objective")
	_assert(_snapshot_is_read_only(snapshot), "Context-selected runtime hook remains read-only")


func _test_invalid_runtime_context_reports_review_issue() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_stitch(), {"current_step_id": "missing_step", "selected_runtime_choice_id": "missing_choice"})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_runtime_hook_review", "Invalid context requires runtime hook review")
	_assert(String(snapshot.get("gate", "")) == "runtime_hook_review", "Invalid context gate asks review")
	_assert(blocker_ids.has("current_step_missing"), "Invalid context reports missing current step")
	_assert(blocker_ids.has("selected_runtime_choice_missing"), "Invalid context reports missing selected runtime choice")
	_assert(not bool(snapshot.get("runtime_hook_ready", true)), "Invalid context does not set runtime hook ready")
	_assert(_snapshot_is_read_only(snapshot), "Invalid context snapshot remains read-only")


func _test_controller_exports_runtime_hook() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_runtime_hook_snapshot"):
		_assert(false, "Controller exposes TASK_1013 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_runtime_hook_snapshot(_ready_stitch(), {"current_step_id": "feedback"})
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1013 schema matches")
	_assert(String(snapshot.get("status", "")) == "runtime_hook_ready", "Controller TASK_1013 can build ready hook")
	_assert(String(snapshot.get("mission_control_runtime_line", "")).contains("NEXT"), "Controller TASK_1013 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1013 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_runtime_hook"), "Command feedback embeds TASK_1013")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_runtime_hook_line"), "Command feedback exports TASK_1013 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_runtime_hook_status"), "Command feedback exports TASK_1013 status")
	controller.queue_free()


func _test_runtime_hook_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_stitch(), {"current_step_id": "decision"})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1013 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1013", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1012", "Roundtrip keeps TASK_1012 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_stitch: Dictionary, runtime_context: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1013 service is loadable")
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
		_assert(false, "TASK_1013 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_stitch, runtime_context)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1013 service returns dictionary")
	return {}


func _ready_stitch() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1012",
		"source_task_id": "TASK_1011",
		"status": "scenario_stitch_ready",
		"gate": "scenario_stitch_ready",
		"scenario_stitch_ready": true,
		"scenario_id": "fob_relay_probe",
		"scenario_title": "FOB Relay Probe",
		"mission_objective_line": "Relais sichern, Kontakt druecken, Fireteam sammeln.",
		"scenario_stitch_line": "FOB Relay Probe | FOB | FEEL/NEXT/GO | GO separat | NEXT: Runtime Hook",
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
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _hook_ids(hooks: Array) -> Array:
	var result: Array = []
	for hook_variant in hooks:
		if typeof(hook_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(hook_variant).get("hook_id", "")))
	return result


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
