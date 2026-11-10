extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1000_release_first_decision_loop_two_player_loop_micro_objective_playability_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_playability_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_playability_slice_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_playability_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_visual_polish.v1"
const NEXT_TASK := "TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1000 Release First Decision Loop Two Player Loop Micro Objective Playability Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_micro_objective_playability_slice()
	_test_controller_exports_micro_objective_playability_slice()
	_test_micro_objective_playability_slice_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1000_release_first_decision_loop_two_player_loop_micro_objective_playability_slice: FAILED")
		quit(1)
		return
	print("TASK_1000_release_first_decision_loop_two_player_loop_micro_objective_playability_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1000 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1000 micro objective playability service exists")
	_assert(task_text.contains("TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice"), "Task names TASK_1000")
	_assert(task_text.contains(NEXT_TASK), "Task names round-trip follow-up")
	_assert(status_text.contains("TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice"), "Implementation status tracks TASK_1000")
	_assert(roadmap_text.contains("TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice (implementiert"), "Roadmap marks TASK_1000 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Playability Slice (TASK_1000)"), "Mission feedback contract documents TASK_1000")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Playability Slice (TASK_1000)"), "Decision clarity contract documents TASK_1000")
	_assert(service_text.contains(SCHEMA), "Micro objective playability service exposes stable TASK_1000 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1000\""), "Micro objective playability service writes TASK_1000 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_999\""), "Micro objective playability service links TASK_999")
	_assert(service_text.contains("\"micro_objective_playability_slice_passed\""), "Micro objective playability service exposes pass flag")
	_assert(service_text.contains("\"answered_player_questions\""), "Micro objective playability service exposes answered player questions")
	_assert(service_text.contains("\"creates_command\": false"), "Micro objective playability creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Micro objective playability creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_PLAYABILITY_SLICE_SCRIPT"), "Controller preloads TASK_1000 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_playability_slice_snapshot"), "Controller exposes TASK_1000 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_playability_slice_line"), "Command feedback exports TASK_1000 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_playability_slice_gate"), "Command feedback exports TASK_1000 gate")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1000")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked micro objective playability snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1000")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1000", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_999", "Snapshot links TASK_999")
	_assert(String(snapshot.get("source_status", "")) == "micro_objective_visual_polish_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_micro_objective_playability_trace", "Ready source without trace needs trace")
	_assert(String(snapshot.get("gate", "")) == "needs_micro_objective_playability_trace", "Gate asks for trace")
	_assert(issue_ids.has("micro_objective_playability_trace_missing"), "Missing trace is explicit")
	_assert(not bool(snapshot.get("micro_objective_playability_slice_passed", true)), "Missing trace does not pass slice")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_playability_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "micro_objective_playability_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_playability_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("player_understands_next_grip"), "Failed trace records missing next-grip understanding")
	_assert(missing_checks.has("multiplayer_boundary_preserved"), "Failed trace records missing multiplayer boundary")
	_assert(issue_ids.has("player_understands_next_grip_missing"), "Missing next-grip issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish", "Regression routes back to polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_micro_objective_playability_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "micro_objective_playability_slice_passed", "Good trace passes micro objective playability")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_playability_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("micro_objective_playability_slice_passed", false)), "Pass flag is true")
	_assert(String(snapshot.get("micro_objective_playability_line", "")).contains("OUTCOME"), "Playability line names outcome")
	_assert(String(snapshot.get("micro_objective_playability_line", "")).contains("NEXT"), "Playability line names next")
	_assert(answered_questions.has("what_happened"), "Slice answers what happened")
	_assert(answered_questions.has("what_changed"), "Slice answers what changed")
	_assert(answered_questions.has("what_next"), "Slice answers what next")
	_assert(answered_questions.has("who_owns_truth"), "Slice answers ownership boundary")
	_assert(answered_questions.has("what_requires_go"), "Slice answers GO boundary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed slice recommends round-trip smoke")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_micro_objective_playability_slice() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_playability_slice_snapshot(_source_visual_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1000 schema matches")
	_assert(String(snapshot.get("status", "")) == "micro_objective_playability_slice_passed", "Controller TASK_1000 passes with trace")
	_assert(String(snapshot.get("micro_objective_playability_line", "")).contains("OBJ"), "Controller TASK_1000 line names objective")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1000 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_playability_slice"), "Command feedback embeds TASK_1000")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_playability_slice_line"), "Command feedback exports TASK_1000 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_playability_slice_status"), "Command feedback exports TASK_1000 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_playability_slice_gate"), "Command feedback exports TASK_1000 gate")
	controller.queue_free()


func _test_micro_objective_playability_slice_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1000 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1000", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_999", "Roundtrip keeps TASK_999 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_visual_polish: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1000 service is loadable")
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
		_assert(false, "TASK_1000 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_visual_polish, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1000 service returns dictionary")
	return {}


func _source_visual_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_999",
		"source_task_id": "TASK_998",
		"status": "micro_objective_visual_polish_ready",
		"active": true,
		"micro_objective_surface_specs": [
			_surface_spec("micro_objective_outcome_surface", "micro_objective_result", "OUTCOME", "SICHERN: Fireteam haelt den Innenhof."),
			_surface_spec("mini_objective_surface", "objective_state", "OBJ", "Gelaende gesichert 1/1"),
			_surface_spec("next_step_surface", "next_action", "NEXT", "Naechster Griff: zweite Entscheidung waehlen."),
		],
		"micro_objective_surface_spec_count": 3,
		"micro_objective_outcome_surface": _surface_spec("micro_objective_outcome_surface", "micro_objective_result", "OUTCOME", "SICHERN: Fireteam haelt den Innenhof."),
		"mini_objective_surface": _surface_spec("mini_objective_surface", "objective_state", "OBJ", "Gelaende gesichert 1/1"),
		"next_step_surface": _surface_spec("next_step_surface", "next_action", "NEXT", "Naechster Griff: zweite Entscheidung waehlen."),
		"micro_objective_polish_line": "OUTCOME SICHERN: Fireteam haelt den Innenhof | OBJ Gelaende gesichert 1/1 | NEXT zweite Entscheidung",
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


func _surface_spec(surface_id: String, role: String, label: String, text: String) -> Dictionary:
	return {
		"surface_id": surface_id,
		"role": role,
		"label": label,
		"text": text,
		"display_text": "%s: %s" % [label, text],
		"style_id": "micro_objective_%s" % role,
		"accent": "gold" if role == "micro_objective_result" else "mint",
		"min_height": 28.0,
		"max_lines": 2,
		"autowrap": true,
		"clip_text": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _good_trace() -> Dictionary:
	return {
		"trace_available": true,
		"selected_micro_objective_id": "secure_ground",
		"micro_objective_outcome_visible": true,
		"mini_objective_state_visible": true,
		"next_step_visible": true,
		"player_understands_micro_objective_result": true,
		"player_understands_next_grip": true,
		"post_micro_objective_feedback_visible": true,
		"go_boundary_preserved": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"no_extra_command_created": true,
		"surface_specs_reused": true,
		"performance_hotpath_ok": true,
		"post_micro_objective_feedback_line": "OUTCOME/OBJ/NEXT lesbar.",
		"player_next_grip_line": "Naechster Griff: zweite Entscheidung oder Team umsetzen.",
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["player_understands_next_grip"] = false
	trace["multiplayer_boundary_preserved"] = false
	trace["post_micro_objective_feedback_line"] = ""
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
