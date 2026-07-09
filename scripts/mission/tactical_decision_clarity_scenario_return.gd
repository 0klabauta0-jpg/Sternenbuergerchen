class_name TacticalDecisionClarityScenarioReturn
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.tactical_decision_clarity_scenario_return.v1"
const TASK_ID: String = "TASK_948"
const SOURCE_TASK_ID: String = "TASK_947"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.v1"
const EXPECTED_SOURCE_STATUS: String = "ready_for_tactical_decision_clarity_return"
const EXPECTED_SOURCE_NEXT_TASK: String = "TASK_948 - Tactical Decision Clarity Scenario Return"
const NEXT_TASK: String = "TASK_949 - Order Preview Threat Overlay Playtest Scenario"


static func build_snapshot(source_snapshot: Dictionary, context: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var source_next_task: String = String(source_snapshot.get("recommended_next_task", ""))
	var recommended_next: String = NEXT_TASK if blockers.is_empty() else source_next_task
	if recommended_next.is_empty():
		recommended_next = EXPECTED_SOURCE_NEXT_TASK
	var status: String = "blocked"
	if blockers.is_empty():
		status = "ready_for_order_preview_threat_overlay_playtest"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_recommended_next_task": source_next_task,
		"source_recommended_direction": String(source_snapshot.get("recommended_direction", "")),
		"source_avoid_next_action": String(source_snapshot.get("avoid_next_action", "")),
		"source_final_contact_fire": bool(source_snapshot.get("final_source_contact_fire", false)),
		"source_issue_ids": _issue_ids(Array(source_snapshot.get("issues", []))),
		"status": status,
		"gate": status,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"recommended_next_task": recommended_next,
		"recommended_direction": "build_small_decision_before_commit_scenario",
		"stop_first_exchange_polish_loop": blockers.is_empty(),
		"playability_focus": "decision_before_commit",
		"first_screen_target": "small_tactical_scenario",
		"candidate_fixture": String(context.get("candidate_fixture", "frontier_probe_first_move")),
		"required_player_questions": [
			"where_will_the_fireteam_go",
			"who_can_see_the_destination",
			"why_is_the_move_safe_risky_or_suicidal",
			"what_happens_only_after_go",
		],
		"capabilities": _build_capabilities(context),
		"implemented_capability_ids": _implemented_capability_ids(context),
		"scope": [
			"reuse_waypoint_intent_preview",
			"reuse_tactical_decision_threat_analyzer",
			"reuse_contact_report_awareness",
			"connect_preview_to_small_playtest_fixture",
		],
		"non_goals": [
			"no_more_fire_lane_value_polish_without_playtest_goal",
			"no_combat_rewrite",
			"no_new_gameplay_truth_in_ui",
			"no_multiplayer_truth_change",
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


static func _build_blockers(source_snapshot: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_snapshot.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_947-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_947."))
	var source_status: String = String(source_snapshot.get("status", ""))
	var source_next: String = String(source_snapshot.get("recommended_next_task", ""))
	var source_direction: String = String(source_snapshot.get("recommended_direction", ""))
	if source_status != EXPECTED_SOURCE_STATUS or source_next != EXPECTED_SOURCE_NEXT_TASK or source_direction != "stop_first_exchange_polish_loop_and_return_to_playable_scenario":
		blockers.append(_issue("source_not_tactical_return", "TASK_947 routet nicht in den Tactical-Decision-Clarity-Return."))
	return blockers


static func _build_capabilities(context: Dictionary) -> Array:
	var implemented: PackedStringArray = _implemented_capability_ids(context)
	return [
		_capability("order_preview_ghost", "TASK_507", "Ghost-Zielposition vor GO", implemented),
		_capability("path_preview", "TASK_507", "Pfad und ETA vor GO", implemented),
		_capability("threat_exposure_levels", "TASK_508", "safe/risky/suicidal/unknown aus ThreatAnalyzer", implemented),
		_capability("line_of_fire_planner", "TASK_508/TASK_509", "sichtbare klare, blockierte und Friendly-Fire-Linien", implemented),
		_capability("contact_report_awareness", "TASK_510", "bekannte Kontakte statt perfektem Gegnerwissen", implemented),
		_capability("ai_intent_debug_visibility", "TASK_511", "Debug-Lesbarkeit fuer KI-Absichten", implemented),
		{
			"id": "small_playtest_fixture",
			"source_task": NEXT_TASK,
			"text": "kleine 3v3-Entscheidungsszene als naechster spielbarer Griff",
			"state": "next",
		},
	]


static func _capability(capability_id: String, source_task: String, text: String, implemented: PackedStringArray) -> Dictionary:
	return {
		"id": capability_id,
		"source_task": source_task,
		"text": text,
		"state": "implemented" if implemented.has(capability_id) else "needs_verification",
	}


static func _implemented_capability_ids(context: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for item in Array(context.get("implemented_capabilities", [])):
		var text: String = String(item).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


static func _issue_ids(issues: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for issue in issues:
		if typeof(issue) != TYPE_DICTIONARY:
			continue
		var id: String = String(Dictionary(issue).get("id", "")).strip_edges()
		if not id.is_empty() and not result.has(id):
			result.append(id)
	return result


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
