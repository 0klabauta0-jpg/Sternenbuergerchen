extends SceneTree

const Polish := preload("res://scripts/mission/first_decision_micro_scenario_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_956_first_decision_micro_scenario_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/first_decision_micro_scenario_polish.gd"
const SCHEMA := "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const SOURCE_SMOKE_SCHEMA := "sternenbuergerchen.decision_overlay_playability_smoke.v1"
const HUD_SCHEMA := "sternenbuergerchen.order_preview_threat_overlay_f6_hud.v1"
const VISUAL_SCHEMA := "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"
const NEXT_TASK := "TASK_957 - First Decision Real Playthrough Capture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_956 First Decision Micro Scenario Polish ===")
	_test_docs_and_static_hooks()
	_test_service_blocks_without_passed_smoke()
	_test_service_builds_player_readable_micro_scenario()
	await _test_controller_exports_micro_scenario_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_956_first_decision_micro_scenario_polish: FAILED")
		quit(1)
		return
	print("TASK_956_first_decision_micro_scenario_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_956 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_956 service exists")
	_assert(task_text.contains("TASK_956 - First Decision Micro Scenario Polish"), "Task names TASK_956")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_957 follow-up")
	_assert(status_text.contains("TASK_956 - First Decision Micro Scenario Polish"), "Implementation status tracks TASK_956")
	_assert(roadmap_text.contains("TASK_956 - First Decision Micro Scenario Polish (implementiert"), "Roadmap marks TASK_956 implemented")
	_assert(command_contract_text.contains("First Decision Micro Scenario Polish (TASK_956)"), "Mission feedback contract documents TASK_956")
	_assert(clarity_contract_text.contains("First Decision Micro Scenario Polish (TASK_956)"), "Decision clarity contract documents TASK_956")
	_assert(service_text.contains(SCHEMA), "Service exposes stable TASK_956 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_956\""), "Service writes TASK_956 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_955\""), "Service links TASK_955")
	_assert(controller_text.contains("FIRST_DECISION_MICRO_SCENARIO_POLISH_SCRIPT"), "Controller preloads TASK_956 service")
	_assert(controller_text.contains("DECISION_OVERLAY_PLAYABILITY_SMOKE_SCRIPT"), "Controller preloads TASK_955 smoke service")
	_assert(controller_text.contains("get_first_decision_micro_scenario_polish_snapshot"), "Controller exposes TASK_956 snapshot")
	_assert(controller_text.contains("_build_first_decision_micro_scenario_smoke_snapshot"), "Controller derives smoke trace for TASK_956")
	_assert(controller_text.contains("first_decision_micro_scenario_polish"), "Command feedback exports TASK_956 polish")
	_assert(service_text.contains("\"read_only\": true"), "Service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Service creates no multiplayer truth")


func _test_service_blocks_without_passed_smoke() -> void:
	var snapshot: Dictionary = Polish.build_snapshot({}, _hud_snapshot(), _visual_snapshot())
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing smoke blocks TASK_956")
	_assert(blocker_ids.has("source_smoke_schema_mismatch"), "Missing smoke reports schema mismatch")
	_assert(blocker_ids.has("source_smoke_not_passed"), "Missing smoke reports non-passed smoke")
	_assert(_snapshot_is_read_only(snapshot), "Blocked TASK_956 snapshot remains read-only")


func _test_service_builds_player_readable_micro_scenario() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_passed_smoke(), _hud_snapshot(), _visual_snapshot())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "TASK_956 schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_956", "TASK_956 id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_955", "TASK_956 links TASK_955")
	_assert(String(snapshot.get("hud_source_task_id", "")) == "TASK_950", "TASK_956 links HUD source")
	_assert(String(snapshot.get("visual_source_task_id", "")) == "TASK_952", "TASK_956 links visual source")
	_assert(String(snapshot.get("status", "")) == "ready_for_first_decision_micro_scenario", "Passed smoke arms micro scenario")
	_assert(String(snapshot.get("gate", "")) == "pass", "Passed smoke passes TASK_956 gate")
	_assert(String(snapshot.get("recommended_choice_id", "")) == "covered_push", "Micro scenario keeps covered push recommendation")
	_assert(_choice_order_starts_with(Array(snapshot.get("ordered_choice_ids", [])), "covered_push"), "Recommended choice appears first")
	_assert(_line_is_player_readable(String(snapshot.get("primary_cue_line", "")), ["NEXT", "GO"], 84), "Primary cue is short and actionable")
	_assert(_line_is_player_readable(String(snapshot.get("why_line", "")), ["Deckung", "Feindlinie"], 96), "Why line explains risk")
	_assert(_line_is_player_readable(String(snapshot.get("before_go_line", "")), ["Preview", "kein Befehl"], 96), "Before-GO line preserves preview boundary")
	_assert(_line_is_player_readable(String(snapshot.get("after_go_line", "")), ["Nach GO", "Feedback"], 96), "After-GO line tells what changes")
	_assert(_choice_rows_are_player_readable(Array(snapshot.get("choice_rows", []))), "Choice rows are player-readable")
	_assert(_answered_questions_complete(Array(snapshot.get("answered_player_questions", []))), "Micro scenario answers first decision questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "TASK_956 recommends real playthrough capture")
	_assert(_snapshot_is_read_only(snapshot), "TASK_956 snapshot remains read-only")


func _test_controller_exports_micro_scenario_polish() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_first_decision_micro_scenario_polish_snapshot"), "Controller has TASK_956 public snapshot")
	if not controller.has_method("get_first_decision_micro_scenario_polish_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_first_decision_micro_scenario_polish_snapshot"))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_956 schema matches")
	_assert(String(snapshot.get("gate", "")) == "pass", "Controller TASK_956 gate passes")
	_assert(String(snapshot.get("primary_cue_line", "")).contains("GO"), "Controller primary cue includes GO")
	_assert(_choice_rows_are_player_readable(Array(snapshot.get("choice_rows", []))), "Controller choice rows are readable")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(feedback.get("first_decision_micro_scenario_polish", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_956")
	_assert(String(feedback.get("first_decision_micro_scenario_gate", "")) == "pass", "Command feedback exports TASK_956 gate")
	_assert(String(feedback.get("first_decision_micro_scenario_line", "")).contains("NEXT"), "Command feedback exports TASK_956 line")
	controller.queue_free()


func _passed_smoke() -> Dictionary:
	return {
		"schema": SOURCE_SMOKE_SCHEMA,
		"task_id": "TASK_955",
		"source_task_id": "TASK_954",
		"gate": "smoke_passed",
		"smoke_passed": true,
		"recommended_choice_id": "covered_push",
		"choice_count": 3,
		"answered_player_questions": [
			"where_will_the_fireteam_go",
			"why_is_this_move_risky",
			"which_choice_is_best",
			"what_changes_only_after_go",
		],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _hud_snapshot() -> Dictionary:
	return {
		"schema": HUD_SCHEMA,
		"task_id": "TASK_950",
		"gate": "pass",
		"recommended_choice_id": "covered_push",
		"visible_choice_count": 3,
		"visible_choice_cards": [
			{
				"choice_id": "covered_push",
				"display_title": "SAFE - Gedeckter Vorstoss",
				"line_label": "Gedeckt",
				"risk_state": "safe",
				"line_of_fire_entry_count": 0,
				"enemy_exposure_count": 0,
				"distance_world": 101.0,
				"eta_seconds_estimate": 1.1,
				"visible_before_go": true,
				"go_boundary": "preview_only_until_go",
			},
			{
				"choice_id": "exposed_crossing",
				"display_title": "RISKY - Offene Querung",
				"line_label": "Querung",
				"risk_state": "risky",
				"line_of_fire_entry_count": 1,
				"enemy_exposure_count": 1,
				"distance_world": 133.0,
				"eta_seconds_estimate": 1.4,
				"visible_before_go": true,
				"go_boundary": "preview_only_until_go",
			},
			{
				"choice_id": "kill_zone_dash",
				"display_title": "SUICIDAL - Killzone",
				"line_label": "Killzone",
				"risk_state": "suicidal",
				"line_of_fire_entry_count": 3,
				"enemy_exposure_count": 3,
				"distance_world": 188.0,
				"eta_seconds_estimate": 2.0,
				"visible_before_go": true,
				"go_boundary": "preview_only_until_go",
			},
		],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _visual_snapshot() -> Dictionary:
	return {
		"schema": VISUAL_SCHEMA,
		"task_id": "TASK_952",
		"gate": "pass",
		"style_id": "task_952_decision_overlay_compact_badges_v1",
		"visual_badges": [
			{"risk_state": "safe", "marker": "OK", "label": "Gedeckt", "microcopy": "Deckung ok"},
			{"risk_state": "risky", "marker": "!", "label": "Querung", "microcopy": "1 Linie"},
			{"risk_state": "suicidal", "marker": "!!", "label": "Killzone", "microcopy": "3 Linien"},
		],
		"visual_badge_count": 3,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _choice_order_starts_with(ids: Array, expected_first: String) -> bool:
	return not ids.is_empty() and String(ids[0]) == expected_first


func _line_is_player_readable(line: String, required_tokens: Array, max_len: int) -> bool:
	if line.strip_edges().is_empty() or line.length() > max_len:
		return false
	if _contains_raw_choice_id(line):
		return false
	for token in required_tokens:
		if not line.contains(String(token)):
			return false
	return true


func _choice_rows_are_player_readable(rows: Array) -> bool:
	if rows.size() != 3:
		return false
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			return false
		var row: Dictionary = Dictionary(row_variant)
		for key in ["choice_id", "risk_token", "player_label", "reason_short", "go_hint"]:
			if String(row.get(key, "")).strip_edges().is_empty():
				return false
		if _contains_raw_choice_id(String(row.get("player_label", ""))) or _contains_raw_choice_id(String(row.get("reason_short", ""))):
			return false
	return true


func _answered_questions_complete(questions: Array) -> bool:
	return questions.has("where_will_the_fireteam_go") \
		and questions.has("why_is_this_move_risky") \
		and questions.has("which_choice_is_best") \
		and questions.has("what_changes_only_after_go")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _contains_raw_choice_id(text: String) -> bool:
	return text.contains("covered_push") or text.contains("exposed_crossing") or text.contains("kill_zone_dash")


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


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
