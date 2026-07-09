extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_948_tactical_decision_clarity_scenario_return.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/tactical_decision_clarity_scenario_return.gd"
const TASK_947_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.v1"
const SCHEMA := "sternenbuergerchen.tactical_decision_clarity_scenario_return.v1"
const NEXT_TASK := "TASK_949 - Order Preview Threat Overlay Playtest Scenario"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_948 Tactical Decision Clarity Scenario Return ===")
	_test_docs_and_static_hooks()
	_test_missing_or_wrong_source_blocks()
	_test_task_947_return_source_arms_playability_slice()
	_test_accepted_first_exchange_source_routes_to_smoke_not_return()
	_test_playability_capabilities_are_concrete_and_read_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_948_tactical_decision_clarity_scenario_return: FAILED")
		quit(1)
		return
	print("TASK_948_tactical_decision_clarity_scenario_return: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_948 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_948 service exists")
	_assert(task_text.contains("TASK_948 - Tactical Decision Clarity Scenario Return"), "Task names scenario return")
	_assert(task_text.contains(NEXT_TASK), "Task points to concrete TASK_949 playtest slice")
	_assert(status_text.contains("TASK_948 - Tactical Decision Clarity Scenario Return"), "Implementation status tracks TASK_948")
	_assert(roadmap_text.contains("TASK_948 - Tactical Decision Clarity Scenario Return (implementiert"), "Roadmap marks TASK_948 implemented")
	_assert(command_contract_text.contains("Tactical-Decision-Clarity-Scenario-Return (TASK_948)"), "Command feedback contract documents TASK_948")
	_assert(clarity_contract_text.contains("Scenario Return (TASK_948)"), "Decision clarity contract documents TASK_948")
	_assert(service_text.contains(SCHEMA), "Service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_948\""), "Service writes TASK_948 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_947\""), "Service links TASK_947")
	_assert(service_text.contains("NEXT_TASK"), "Service declares next concrete playtest task")
	_assert(service_text.contains("\"read_only\": true"), "Service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Service creates no movement")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Service creates no fire event")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Service sets no multiplayer truth")


func _test_missing_or_wrong_source_blocks() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_948 service can be loaded")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", {}, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_947 source blocks return gate")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_947 mismatch")
	_assert(blocker_ids.has("source_not_tactical_return"), "Missing source reports missing return route")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_task_947_return_source_arms_playability_slice() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_948 service can be loaded for valid route")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _task_947_return_source(), _current_capability_context()))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Scenario return snapshot schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_948", "Scenario return snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_947", "Scenario return links TASK_947")
	_assert(String(snapshot.get("status", "")) == "ready_for_order_preview_threat_overlay_playtest", "Valid return source arms playtest slice")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Return recommends concrete TASK_949")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_small_decision_before_commit_scenario", "Return direction is playability scenario")
	_assert(bool(snapshot.get("stop_first_exchange_polish_loop", false)), "Return stops first exchange polish loop")
	_assert(String(snapshot.get("playability_focus", "")) == "decision_before_commit", "Return focuses decision before commit")
	_assert(_snapshot_is_read_only(snapshot), "Valid return snapshot remains read-only")


func _test_accepted_first_exchange_source_routes_to_smoke_not_return() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_948 service can be loaded for smoke route")
		return
	var source: Dictionary = _task_947_return_source()
	source["status"] = "accepted_for_first_exchange_playability_smoke"
	source["recommended_next_task"] = "TASK_948 - Release First Exchange Playability Smoke"
	source["recommended_direction"] = "move_to_playability_smoke"
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", source, _current_capability_context()))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Accepted smoke source does not enter scenario-return gate")
	_assert(blocker_ids.has("source_not_tactical_return"), "Smoke source reports wrong route")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_948 - Release First Exchange Playability Smoke", "Smoke source preserves original route")
	_assert(_snapshot_is_read_only(snapshot), "Smoke-route block remains read-only")


func _test_playability_capabilities_are_concrete_and_read_only() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_948 service can be loaded for capability check")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _task_947_return_source(), _current_capability_context()))
	var capability_ids: PackedStringArray = _capability_ids(Array(snapshot.get("capabilities", [])))
	for expected in [
		"order_preview_ghost",
		"path_preview",
		"threat_exposure_levels",
		"line_of_fire_planner",
		"contact_report_awareness",
		"ai_intent_debug_visibility",
		"small_playtest_fixture",
	]:
		_assert(capability_ids.has(expected), "Capability declared: %s" % expected)
	var player_questions: PackedStringArray = _string_array(snapshot.get("required_player_questions", []))
	_assert(player_questions.has("where_will_the_fireteam_go"), "Player question covers future position")
	_assert(player_questions.has("who_can_see_the_destination"), "Player question covers enemy LOS")
	_assert(player_questions.has("why_is_the_move_safe_risky_or_suicidal"), "Player question covers risk reason")
	_assert(player_questions.has("what_happens_only_after_go"), "Player question separates preview from commit")
	_assert(not bool(snapshot.get("creates_command", true)), "Capability snapshot does not create commands")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Capability snapshot does not create navigation")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Capability snapshot does not create damage")


func _task_947_return_source() -> Dictionary:
	return {
		"schema": TASK_947_SCHEMA,
		"task_id": "TASK_947",
		"status": "ready_for_tactical_decision_clarity_return",
		"recommended_next_task": "TASK_948 - Tactical Decision Clarity Scenario Return",
		"recommended_direction": "stop_first_exchange_polish_loop_and_return_to_playable_scenario",
		"avoid_next_action": "do_not_start_another_fire_lane_value_polish_without_new_playtest_goal",
		"final_source_contact_fire": true,
		"issues": [{"id": "second_fire_lane_not_first_world_movement"}],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _current_capability_context() -> Dictionary:
	return {
		"implemented_capabilities": [
			"order_preview_ghost",
			"path_preview",
			"threat_exposure_levels",
			"line_of_fire_planner",
			"contact_report_awareness",
			"ai_intent_debug_visibility",
		],
		"candidate_fixture": "frontier_probe_first_move",
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _capability_ids(capabilities: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for item in capabilities:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var id: String = String(Dictionary(item).get("id", "")).strip_edges()
		if not id.is_empty() and not result.has(id):
			result.append(id)
	return result


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
