extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_949_order_preview_threat_overlay_playtest_scenario.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/order_preview_threat_overlay_playtest_scenario.gd"
const TASK_948_SERVICE_PATH := "res://scripts/mission/tactical_decision_clarity_scenario_return.gd"
const SCHEMA := "sternenbuergerchen.order_preview_threat_overlay_playtest_scenario.v1"
const TASK_948_SCHEMA := "sternenbuergerchen.tactical_decision_clarity_scenario_return.v1"
const NEXT_TASK := "TASK_950 - Wire Decision Scenario Into F6 Mission HUD"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_949 Order Preview Threat Overlay Playtest Scenario ===")
	_test_docs_and_static_hooks()
	_test_missing_task_948_source_blocks()
	_test_scenario_builds_three_readable_move_choices()
	_test_overlay_summary_and_recommended_choice()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_949_order_preview_threat_overlay_playtest_scenario: FAILED")
		quit(1)
		return
	print("TASK_949_order_preview_threat_overlay_playtest_scenario: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_949 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_949 service exists")
	_assert(task_text.contains("TASK_949 - Order Preview Threat Overlay Playtest Scenario"), "Task names TASK_949")
	_assert(task_text.contains(NEXT_TASK), "Task names concrete TASK_950 follow-up")
	_assert(status_text.contains("TASK_949 - Order Preview Threat Overlay Playtest Scenario"), "Implementation status tracks TASK_949")
	_assert(roadmap_text.contains("TASK_949 - Order Preview Threat Overlay Playtest Scenario (implementiert"), "Roadmap marks TASK_949 implemented")
	_assert(command_contract_text.contains("Order-Preview-Threat-Overlay-Playtest-Scenario (TASK_949)"), "Mission feedback contract documents TASK_949")
	_assert(clarity_contract_text.contains("Playtest Scenario (TASK_949)"), "Decision clarity contract documents TASK_949")
	_assert(service_text.contains(SCHEMA), "Service exposes stable TASK_949 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_949\""), "Service writes TASK_949 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_948\""), "Service links TASK_948")
	_assert(service_text.contains("WaypointIntentPreviewResolver"), "Service reuses waypoint preview resolver")
	_assert(service_text.contains("TacticalDecisionThreatAnalyzer"), "Service reuses threat analyzer")
	_assert(service_text.contains("\"creates_command\": false"), "Service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Service creates no movement")


func _test_missing_task_948_source_blocks() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_949 service can be loaded")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", {}, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_948 source blocks scenario")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_948 mismatch")
	_assert(blocker_ids.has("source_not_ready_for_playtest"), "Missing source reports readiness mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_scenario_builds_three_readable_move_choices() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_949 service can be loaded for scenario")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _task_948_source(), {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Scenario snapshot schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_949", "Scenario snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_948", "Scenario links TASK_948")
	_assert(String(snapshot.get("status", "")) == "ready_for_f6_hud_wiring", "Scenario is ready for F6 HUD wiring")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Scenario recommends TASK_950")
	_assert(String(snapshot.get("player_prompt", "")).contains("Choose"), "Scenario gives a short player prompt")
	var choices: Array = Array(snapshot.get("move_choices", []))
	_assert(choices.size() == 3, "Scenario contains three move choices")
	var by_id: Dictionary = _choices_by_id(choices)
	_assert(by_id.has("covered_push"), "Scenario has safe covered push choice")
	_assert(by_id.has("exposed_crossing"), "Scenario has risky exposed crossing choice")
	_assert(by_id.has("kill_zone_dash"), "Scenario has suicidal kill-zone dash choice")
	_assert(_choice_has_risk(Dictionary(by_id.get("covered_push", {})), "safe", 0), "Covered push is safe")
	_assert(_choice_has_risk(Dictionary(by_id.get("exposed_crossing", {})), "risky", 1), "Exposed crossing is risky")
	_assert(_choice_has_risk(Dictionary(by_id.get("kill_zone_dash", {})), "suicidal", 3), "Kill-zone dash is suicidal")
	for choice in choices:
		_assert(_choice_has_preview_shape(Dictionary(choice)), "Choice has ghost/path/ETA/preview shape")
	_assert(_snapshot_is_read_only(snapshot), "Scenario snapshot remains read-only")


func _test_overlay_summary_and_recommended_choice() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_949 service can be loaded for overlay summary")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _task_948_source(), {}))
	var overlay: Dictionary = Dictionary(snapshot.get("overlay_summary", {}))
	var color_keys: PackedStringArray = _string_array(overlay.get("color_keys", []))
	var player_questions: PackedStringArray = _string_array(snapshot.get("answered_player_questions", []))
	_assert(int(overlay.get("ghost_count", 0)) == 3, "Overlay summary counts three ghosts")
	_assert(int(overlay.get("path_line_count", 0)) >= 3, "Overlay summary counts path lines")
	_assert(int(overlay.get("threat_line_count", 0)) >= 4, "Overlay summary counts threat lines")
	_assert(color_keys.has("green") and color_keys.has("yellow") and color_keys.has("red"), "Overlay summary exposes green/yellow/red risk colors")
	_assert(String(snapshot.get("recommended_choice_id", "")) == "covered_push", "Scenario recommends the safe first read")
	_assert(player_questions.has("where_will_the_fireteam_go"), "Scenario answers future-position question")
	_assert(player_questions.has("who_can_see_the_destination"), "Scenario answers enemy-LOS question")
	_assert(player_questions.has("why_is_the_move_safe_risky_or_suicidal"), "Scenario answers risk-reason question")
	_assert(player_questions.has("what_happens_only_after_go"), "Scenario answers GO-boundary question")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Scenario creates no fire event")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Scenario creates no multiplayer truth")


func _task_948_source() -> Dictionary:
	var task_948_resource: Resource = load(TASK_948_SERVICE_PATH)
	if task_948_resource == null:
		return {}
	var task_947_source := {
		"schema": "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.v1",
		"task_id": "TASK_947",
		"status": "ready_for_tactical_decision_clarity_return",
		"recommended_next_task": "TASK_948 - Tactical Decision Clarity Scenario Return",
		"recommended_direction": "stop_first_exchange_polish_loop_and_return_to_playable_scenario",
	}
	return Dictionary(task_948_resource.call("build_snapshot", task_947_source, {
		"implemented_capabilities": [
			"order_preview_ghost",
			"path_preview",
			"threat_exposure_levels",
			"line_of_fire_planner",
			"contact_report_awareness",
			"ai_intent_debug_visibility",
		],
		"candidate_fixture": "frontier_probe_first_move",
	}))


func _choices_by_id(choices: Array) -> Dictionary:
	var result: Dictionary = {}
	for choice_variant in choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = Dictionary(choice_variant)
		result[String(choice.get("choice_id", ""))] = choice
	return result


func _choice_has_risk(choice: Dictionary, expected_risk: String, minimum_threat_lines: int) -> bool:
	if String(choice.get("risk_state", "")).strip_edges().to_lower() != expected_risk:
		return false
	if int(choice.get("line_of_fire_entry_count", 0)) < minimum_threat_lines:
		return false
	var preview: Dictionary = Dictionary(choice.get("preview_entry", {}))
	return String(preview.get("risk_state", "")).strip_edges().to_lower() == expected_risk


func _choice_has_preview_shape(choice: Dictionary) -> bool:
	var preview: Dictionary = Dictionary(choice.get("preview_entry", {}))
	return bool(choice.get("visible_before_go", false)) \
		and typeof(preview.get("ghost_ftl_position", null)) == TYPE_VECTOR2 \
		and Array(preview.get("ghost_path_points", [])).size() >= 2 \
		and float(preview.get("distance_world", 0.0)) > 0.0 \
		and float(preview.get("eta_seconds_estimate", 0.0)) > 0.0 \
		and bool(preview.get("read_only", false)) \
		and not bool(preview.get("ui_sets_gameplay_truth", true))


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
	for issue in issues:
		if typeof(issue) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue).get("id", "")).strip_edges())
	return result


func _string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for item in Array(value):
		var text: String = String(item).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
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
