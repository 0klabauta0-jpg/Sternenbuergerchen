extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1007_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.v1"
const NEXT_TASK := "TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1007 Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_round_loop_playability_slice()
	_test_controller_exports_round_loop_playability_slice()
	_test_round_loop_playability_slice_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1007_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice: FAILED")
		quit(1)
		return
	print("TASK_1007_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1007 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1007 round-loop playability service exists")
	_assert(task_text.contains("TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"), "Task names TASK_1007")
	_assert(task_text.contains(NEXT_TASK), "Task names integrated playtest follow-up")
	_assert(status_text.contains("TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"), "Implementation status tracks TASK_1007")
	_assert(roadmap_text.contains("TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice (implementiert"), "Roadmap marks TASK_1007 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice (TASK_1007)"), "Mission feedback contract documents TASK_1007")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice (TASK_1007)"), "Decision clarity contract documents TASK_1007")
	_assert(service_text.contains(SCHEMA), "Round-loop playability service exposes stable TASK_1007 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1007\""), "Round-loop playability service writes TASK_1007 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1006\""), "Round-loop playability service links TASK_1006")
	_assert(service_text.contains("REQUIRED_PLAYABILITY_CHECKS"), "Round-loop playability service defines required checks")
	_assert(service_text.contains("\"round_loop_playability_slice_passed\""), "Round-loop playability service exposes pass flag")
	_assert(service_text.contains("\"ready_for_integrated_playtest\""), "Round-loop playability service exposes integrated playtest readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Round-loop playability creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-loop playability creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_PLAYABILITY_SLICE_SCRIPT"), "Controller preloads TASK_1007 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_snapshot"), "Controller exposes TASK_1007 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_line"), "Command feedback exports TASK_1007 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_status"), "Command feedback exports TASK_1007 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1007")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked round-loop playability snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1007")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1007", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1006", "Snapshot links TASK_1006")
	_assert(String(snapshot.get("source_status", "")) == "round_loop_visual_polish_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_round_loop_playability_trace", "Ready source without trace needs trace")
	_assert(String(snapshot.get("gate", "")) == "needs_round_loop_playability_trace", "Gate asks for trace")
	_assert(issue_ids.has("round_loop_playability_trace_missing"), "Missing trace is explicit")
	_assert(not bool(snapshot.get("round_loop_playability_slice_passed", true)), "Missing trace does not pass slice")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_playability_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "round_loop_playability_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "round_loop_playability_regression", "Failed trace gate reports regression")
	_assert(missing_checks.has("next_decision_understood"), "Failed trace records missing next-decision understanding")
	_assert(missing_checks.has("go_separation_preserved"), "Failed trace records missing GO separation")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-next")
	_assert(issue_ids.has("next_decision_not_understood"), "Missing next-decision issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish", "Regression routes back to polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_round_loop_playability_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "round_loop_playability_slice_passed", "Good trace passes round-loop playability")
	_assert(String(snapshot.get("gate", "")) == "round_loop_playability_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("round_loop_playability_slice_passed", false)), "Pass flag is true")
	_assert(bool(snapshot.get("ready_for_integrated_playtest", false)), "Passed slice is ready for integrated playtest")
	_assert(String(snapshot.get("round_loop_playability_line", "")).contains("ROUND"), "Playability line names ROUND")
	_assert(String(snapshot.get("round_loop_playability_line", "")).contains("NEXT"), "Playability line names NEXT")
	_assert(String(snapshot.get("round_loop_playability_line", "")).contains("GO"), "Playability line names GO")
	_assert(String(snapshot.get("round_loop_playability_line", "")).contains("FEEDBACK"), "Playability line names FEEDBACK")
	_assert(answered_questions.has("what_round_finished"), "Slice answers finished round")
	_assert(answered_questions.has("what_next_decision"), "Slice answers next decision")
	_assert(answered_questions.has("what_requires_go"), "Slice answers GO boundary")
	_assert(answered_questions.has("who_owns_truth"), "Slice answers ownership boundary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed slice recommends integrated playtest")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_round_loop_playability_slice() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_snapshot(_source_visual_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1007 schema matches")
	_assert(String(snapshot.get("status", "")) == "round_loop_playability_slice_passed", "Controller TASK_1007 passes with trace")
	_assert(String(snapshot.get("round_loop_playability_line", "")).contains("FEEDBACK"), "Controller TASK_1007 line names feedback")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1007 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice"), "Command feedback embeds TASK_1007")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_line"), "Command feedback exports TASK_1007 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_status"), "Command feedback exports TASK_1007 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice_gate"), "Command feedback exports TASK_1007 gate")
	controller.queue_free()


func _test_round_loop_playability_slice_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_visual_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1007 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1007", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1006", "Roundtrip keeps TASK_1006 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_visual_polish: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1007 service is loadable")
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
		_assert(false, "TASK_1007 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_visual_polish, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1007 service returns dictionary")
	return {}


func _source_visual_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1006",
		"source_task_id": "TASK_1005",
		"status": "round_loop_visual_polish_ready",
		"active": true,
		"round_loop_surface_specs": [
			_surface_spec("round_surface", "round_status", "ROUND", "ROUND 2 abgeschlossen"),
			_surface_spec("next_surface", "next_decision", "NEXT", "NEXT Micro-Ziel waehlen"),
			_surface_spec("go_surface", "go_boundary", "GO", "GO separat bestaetigen"),
			_surface_spec("selected_fireteam_runtime_surface", "selected_fireteam_runtime", "FT", "ROUND 2 stabil | NEXT bereit"),
			_surface_spec("mission_control_runtime_surface", "mission_control_runtime", "MC", "NEXT Micro-Ziel waehlen | GO separat"),
			_surface_spec("command_feedback_runtime_surface", "command_feedback_runtime", "CF", "ROUND LOOP: Feedback gelesen | GO separat bleibt"),
		],
		"round_loop_surface_spec_count": 6,
		"round_surface": _surface_spec("round_surface", "round_status", "ROUND", "ROUND 2 abgeschlossen"),
		"next_surface": _surface_spec("next_surface", "next_decision", "NEXT", "NEXT Micro-Ziel waehlen"),
		"go_surface": _surface_spec("go_surface", "go_boundary", "GO", "GO separat bestaetigen"),
		"selected_fireteam_runtime_surface": _surface_spec("selected_fireteam_runtime_surface", "selected_fireteam_runtime", "FT", "ROUND 2 stabil | NEXT bereit"),
		"mission_control_runtime_surface": _surface_spec("mission_control_runtime_surface", "mission_control_runtime", "MC", "NEXT Micro-Ziel waehlen | GO separat"),
		"command_feedback_runtime_surface": _surface_spec("command_feedback_runtime_surface", "command_feedback_runtime", "CF", "ROUND LOOP: Feedback gelesen | GO separat bleibt"),
		"round_loop_polish_line": "ROUND ROUND 2 abgeschlossen | NEXT NEXT Micro-Ziel waehlen | GO GO separat bestaetigen",
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
		"style_id": "round_loop_%s" % role,
		"accent": "gold" if role == "round_status" else "mint",
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
		"trace_id": "round_loop_playability_fixture",
		"completed_round_count": 2,
		"round_surface_readable": true,
		"next_surface_readable": true,
		"go_surface_readable": true,
		"runtime_lines_readable": true,
		"next_decision_understood": true,
		"confirm_available": true,
		"go_separation_preserved": true,
		"feedback_returns_to_next": true,
		"no_command_before_confirm": true,
		"no_auto_go": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"round_loop_feedback_line": "FEEDBACK gelesen, NEXT wieder bereit.",
		"player_next_decision_line": "Naechster Griff: Micro-Ziel waehlen, dann GO separat.",
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["next_decision_understood"] = false
	trace["go_separation_preserved"] = false
	trace["feedback_returns_to_next"] = false
	trace["round_loop_feedback_line"] = ""
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
