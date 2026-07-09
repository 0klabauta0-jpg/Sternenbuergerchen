extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_990_release_first_decision_loop_two_player_loop_next_micro_objective.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_next_micro_objective.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_next_micro_objective_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_next_micro_objective.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_playability_slice.v1"
const NEXT_TASK := "TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_990 Release First Decision Loop Two Player Loop Next Micro Objective ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_unpassed_source_blocks()
	_test_passed_source_builds_micro_objectives()
	_test_context_can_prioritize_pressure_objective()
	_test_controller_exports_next_micro_objective()
	_test_next_micro_objective_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_990_release_first_decision_loop_two_player_loop_next_micro_objective: FAILED")
		quit(1)
		return
	print("TASK_990_release_first_decision_loop_two_player_loop_next_micro_objective: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_990 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_990 next micro objective service exists")
	_assert(task_text.contains("TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective"), "Task names TASK_990")
	_assert(task_text.contains(NEXT_TASK), "Task names HUD wiring follow-up")
	_assert(status_text.contains("TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective"), "Implementation status tracks TASK_990")
	_assert(roadmap_text.contains("TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective (implementiert"), "Roadmap marks TASK_990 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Next Micro Objective (TASK_990)"), "Mission feedback contract documents TASK_990")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Next Micro Objective (TASK_990)"), "Decision clarity contract documents TASK_990")
	_assert(service_text.contains(SCHEMA), "Next micro objective service exposes stable TASK_990 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_990\""), "Next micro objective service writes TASK_990 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_989\""), "Next micro objective service links TASK_989")
	_assert(service_text.contains("\"micro_objective_cards\""), "Next micro objective exposes objective cards")
	_assert(service_text.contains("\"recommended_micro_objective_id\""), "Next micro objective exposes recommendation")
	_assert(service_text.contains("\"requires_existing_go_path\": true"), "Next micro objective keeps GO boundary")
	_assert(service_text.contains("\"creates_command\": false"), "Next micro objective creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Next micro objective creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_NEXT_MICRO_OBJECTIVE_SCRIPT"), "Controller preloads TASK_990 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_next_micro_objective_snapshot"), "Controller exposes TASK_990 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_next_micro_objective_line"), "Command feedback exports TASK_990 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_next_micro_objective_cards"), "Command feedback exports TASK_990 cards")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_990")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked next objective snapshot remains read-only")


func _test_unpassed_source_blocks() -> void:
	var source: Dictionary = _source_outcome_playability()
	source["status"] = "needs_outcome_playability_trace"
	source["outcome_playability_slice_passed"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Unpassed source blocks TASK_990")
	_assert(blocker_ids.has("source_not_passed"), "Unpassed source reports source not passed")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice", "Unpassed source routes back to TASK_989")
	_assert(_snapshot_is_read_only(snapshot), "Unpassed source snapshot remains read-only")


func _test_passed_source_builds_micro_objectives() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_outcome_playability(), {})
	var cards: Array = Array(snapshot.get("micro_objective_cards", []))
	var recommended: Dictionary = Dictionary(snapshot.get("recommended_micro_objective", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_990")
	_assert(String(snapshot.get("task_id", "")) == "TASK_990", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_989", "Snapshot links TASK_989")
	_assert(String(snapshot.get("status", "")) == "next_micro_objective_ready", "Passed source builds next micro objective")
	_assert(String(snapshot.get("gate", "")) == "next_micro_objective_ready", "Gate marks next objective ready")
	_assert(int(snapshot.get("micro_objective_card_count", 0)) == 3, "Three micro objective cards exist")
	_assert(String(snapshot.get("recommended_micro_objective_id", "")) == "secure_gained_ground", "Default recommendation secures gained ground")
	_assert(String(recommended.get("command_intent", "")) == "defend", "Recommended objective maps to defend intent")
	_assert(String(snapshot.get("next_micro_objective_line", "")).contains("SICHERN"), "Next objective line names secure objective")
	_assert(String(snapshot.get("next_micro_objective_line", "")).contains("GO separat"), "Next objective line keeps GO boundary")
	_assert(_objective_cards_are_readable(cards), "Micro objective cards are readable")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Ready objective recommends HUD wiring")
	_assert(_snapshot_is_read_only(snapshot), "Ready next objective remains read-only")


func _test_context_can_prioritize_pressure_objective() -> void:
	var context := {
		"preferred_objective_id": "press_next_contact",
		"pressure_window_open": true,
	}
	var snapshot: Dictionary = _build_snapshot(_source_outcome_playability(), context)
	var recommended: Dictionary = Dictionary(snapshot.get("recommended_micro_objective", {}))
	_assert(String(snapshot.get("recommended_micro_objective_id", "")) == "press_next_contact", "Context can recommend pressure objective")
	_assert(String(recommended.get("command_intent", "")) == "move", "Pressure objective maps to move intent")
	_assert(String(snapshot.get("next_micro_objective_line", "")).contains("DRUECKEN"), "Pressure line names push objective")
	_assert(_snapshot_is_read_only(snapshot), "Context snapshot remains read-only")


func _test_controller_exports_next_micro_objective() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_next_micro_objective_snapshot(_source_outcome_playability(), {})
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_990 schema matches")
	_assert(String(snapshot.get("status", "")) == "next_micro_objective_ready", "Controller TASK_990 can become ready")
	_assert(String(snapshot.get("next_micro_objective_line", "")).contains("OBJ"), "Controller TASK_990 line names objective")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_990 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_next_micro_objective"), "Command feedback embeds TASK_990")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_next_micro_objective_line"), "Command feedback exports TASK_990 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_next_micro_objective_status"), "Command feedback exports TASK_990 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_next_micro_objective_cards"), "Command feedback exports TASK_990 cards")
	controller.queue_free()


func _test_next_micro_objective_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_outcome_playability(), {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_990 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_990", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_989", "Roundtrip keeps TASK_989 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_outcome_playability: Dictionary, context: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_990 service is loadable")
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
		_assert(false, "TASK_990 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_outcome_playability, context)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_990 service returns dictionary")
	return {}


func _source_outcome_playability() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_989",
		"source_task_id": "TASK_988",
		"status": "outcome_playability_slice_passed",
		"gate": "outcome_playability_slice_passed",
		"outcome_playability_slice_passed": true,
		"source_outcome_polish_line": "RESULT PUSH: Ziel unter Druck | OBJ Ziel 1/2 unter Druck | NEXT Naechster Griff",
		"outcome_playability_line": "OUTCOME PASS: RESULT PUSH: Ziel unter Druck | OBJ Ziel 1/2 unter Druck | NEXT Naechster Griff",
		"answered_player_questions": [
			"what_happened",
			"what_changed",
			"what_next",
			"who_owns_truth",
		],
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


func _objective_cards_are_readable(cards: Array) -> bool:
	if cards.size() != 3:
		return false
	for card_variant in cards:
		var card := Dictionary(card_variant)
		if String(card.get("objective_id", "")).is_empty():
			return false
		if String(card.get("label", "")).is_empty():
			return false
		if String(card.get("player_line", "")).is_empty():
			return false
		if String(card.get("why_line", "")).is_empty():
			return false
		if not bool(card.get("requires_existing_go_path", false)):
			return false
		if bool(card.get("creates_command", true)):
			return false
	return true


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
