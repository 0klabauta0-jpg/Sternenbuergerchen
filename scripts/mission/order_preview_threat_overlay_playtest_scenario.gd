class_name OrderPreviewThreatOverlayPlaytestScenario
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.order_preview_threat_overlay_playtest_scenario.v1"
const TASK_ID: String = "TASK_949"
const SOURCE_TASK_ID: String = "TASK_948"
const SOURCE_SCHEMA: String = "sternenbuergerchen.tactical_decision_clarity_scenario_return.v1"
const EXPECTED_SOURCE_STATUS: String = "ready_for_order_preview_threat_overlay_playtest"
const NEXT_TASK: String = "TASK_950 - Wire Decision Scenario Into F6 Mission HUD"

const WaypointIntentPreviewResolver: GDScript = preload("res://scripts/tactical/waypoint_intent_preview_resolver.gd")
const TacticalDecisionThreatAnalyzer: GDScript = preload("res://scripts/tactical/tactical_decision_threat_analyzer.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")


static func build_snapshot(source_snapshot: Dictionary, context: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var choices: Array = []
	if blockers.is_empty():
		choices = _build_move_choices(context)
	var overlay_summary: Dictionary = _build_overlay_summary(choices)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_f6_hud_wiring"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"status": status,
		"gate": status,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"scenario_id": String(context.get("scenario_id", "frontier_probe_decision_preview_3v3")),
		"player_prompt": "Choose a move before GO: covered push, exposed crossing, or kill-zone dash.",
		"fireteam_id": String(context.get("fireteam_id", "blue")).strip_edges().to_lower(),
		"move_choices": choices,
		"move_choice_count": choices.size(),
		"recommended_choice_id": _recommended_choice_id(choices),
		"overlay_summary": overlay_summary,
		"answered_player_questions": [
			"where_will_the_fireteam_go",
			"who_can_see_the_destination",
			"why_is_the_move_safe_risky_or_suicidal",
			"what_happens_only_after_go",
		],
		"recommended_next_task": NEXT_TASK,
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
		blockers.append(_issue("source_schema_mismatch", "TASK_948-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_948."))
	if String(source_snapshot.get("status", "")) != EXPECTED_SOURCE_STATUS:
		blockers.append(_issue("source_not_ready_for_playtest", "TASK_948-Quelle ist nicht bereit fuer den Order-Preview-/Threat-Overlay-Playtest."))
	return blockers


static func _build_move_choices(context: Dictionary) -> Array:
	var fireteam_id: String = String(context.get("fireteam_id", "blue")).strip_edges().to_lower()
	var anchor: Vector2 = _coerce_vector2(context.get("anchor_position", Vector2(256.0, 256.0)), Vector2(256.0, 256.0))
	var choice_specs: Array = [
		{
			"choice_id": "covered_push",
			"title": "Covered push",
			"screen_text": "SAFE | covered push | clear path before GO",
			"target_position": anchor + Vector2(96.0, -32.0),
			"cover_value": 60,
			"enemy_units": [],
			"tone": "safe",
		},
		{
			"choice_id": "exposed_crossing",
			"title": "Exposed crossing",
			"screen_text": "RISKY | 1 enemy line | partial cover",
			"target_position": anchor + Vector2(128.0, 32.0),
			"cover_value": 25,
			"enemy_offsets": [Vector2(128.0, 0.0)],
			"tone": "risky",
		},
		{
			"choice_id": "kill_zone_dash",
			"title": "Kill-zone dash",
			"screen_text": "SUICIDAL | 3 enemy lines | no cover",
			"target_position": anchor + Vector2(160.0, 96.0),
			"cover_value": 0,
			"enemy_offsets": [Vector2(128.0, 0.0), Vector2(0.0, 128.0), Vector2(-128.0, 0.0)],
			"tone": "suicidal",
		},
	]
	var choices: Array = []
	for spec in choice_specs:
		choices.append(_build_choice(Dictionary(spec), fireteam_id, anchor))
	return choices


static func _build_choice(spec: Dictionary, fireteam_id: String, anchor: Vector2) -> Dictionary:
	var target: Vector2 = _coerce_vector2(spec.get("target_position", anchor), anchor)
	var enemy_units: Array = Array(spec.get("enemy_units", _enemy_units_for_offsets(target, Array(spec.get("enemy_offsets", [])))))
	var preview: Dictionary = _build_preview_entry(fireteam_id, anchor, target, enemy_units, int(spec.get("cover_value", 0)))
	var risk_state: String = String(preview.get("risk_state", "unknown")).strip_edges().to_lower()
	var line_entries: Array = Array(preview.get("line_of_fire_entries", []))
	return {
		"choice_id": String(spec.get("choice_id", "")),
		"title": String(spec.get("title", "")),
		"screen_text": String(spec.get("screen_text", "")),
		"visible_before_go": true,
		"risk_state": risk_state,
		"risk_color_key": _risk_color_key(risk_state),
		"risk_reason": String(preview.get("risk_reason", "")),
		"target_position": target,
		"distance_world": float(preview.get("distance_world", 0.0)),
		"eta_seconds_estimate": float(preview.get("eta_seconds_estimate", 0.0)),
		"line_of_fire_entry_count": line_entries.size(),
		"enemy_exposure_count": int(preview.get("enemy_exposure_count", 0)),
		"preview_entry": preview,
		"go_boundary": "preview_only_until_go",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _build_preview_entry(fireteam_id: String, anchor: Vector2, target: Vector2, enemy_units: Array, cover_value: int) -> Dictionary:
	var resolver = WaypointIntentPreviewResolver.new()
	var analyzer = TacticalDecisionThreatAnalyzer.new()
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "task_949_%s" % fireteam_id
	plan.fireteam_id = fireteam_id
	plan.phase = 0
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "task_949_%s_move" % fireteam_id
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = target
	plan.waypoints = [waypoint]
	var previews: Array = Array(resolver.call("build_preview_entries", [plan.call("to_dict")], [{"fireteam_id": fireteam_id, "position": anchor}], {
		"phase_index": 0,
		"selected_fireteam_ids": PackedStringArray([fireteam_id]),
		"speed_world_per_second_by_fireteam": {fireteam_id: 96.0},
		"threat_analyzer": analyzer,
		"threat_context_by_fireteam": {
			fireteam_id: {
				"enemy_units": enemy_units,
				"cover_value_override": cover_value,
			},
		},
	}))
	if previews.is_empty():
		return {}
	return Dictionary(previews[0]).duplicate(true)


static func _enemy_units_for_offsets(target: Vector2, offsets: Array) -> Array:
	var result: Array = []
	for index in range(offsets.size()):
		var offset: Vector2 = _coerce_vector2(offsets[index], Vector2.ZERO)
		result.append({
			"unit_id": "task_949_enemy_%d" % (index + 1),
			"enemy_type": "rifleman",
			"position": target + offset,
			"max_range": 560.0,
			"overwatch_ready": false,
		})
	return result


static func _build_overlay_summary(choices: Array) -> Dictionary:
	var ghost_count: int = 0
	var path_line_count: int = 0
	var threat_line_count: int = 0
	var color_keys: PackedStringArray = PackedStringArray()
	var risk_counts: Dictionary = {}
	for choice_variant in choices:
		var choice: Dictionary = Dictionary(choice_variant)
		var preview: Dictionary = Dictionary(choice.get("preview_entry", {}))
		if typeof(preview.get("ghost_ftl_position", null)) == TYPE_VECTOR2:
			ghost_count += 1
		path_line_count += maxi(int(preview.get("ghost_path_segment_count", 0)), 0)
		threat_line_count += Array(preview.get("line_of_fire_entries", [])).size()
		var color_key: String = String(choice.get("risk_color_key", "")).strip_edges()
		if not color_key.is_empty() and not color_keys.has(color_key):
			color_keys.append(color_key)
		var risk_state: String = String(choice.get("risk_state", "unknown")).strip_edges().to_lower()
		risk_counts[risk_state] = int(risk_counts.get(risk_state, 0)) + 1
	return {
		"ghost_count": ghost_count,
		"path_line_count": path_line_count,
		"threat_line_count": threat_line_count,
		"color_keys": color_keys,
		"risk_counts": risk_counts,
		"read_only": true,
	}


static func _recommended_choice_id(choices: Array) -> String:
	for choice_variant in choices:
		var choice: Dictionary = Dictionary(choice_variant)
		if String(choice.get("risk_state", "")) == "safe":
			return String(choice.get("choice_id", ""))
	return String(Dictionary(choices[0]).get("choice_id", "")) if not choices.is_empty() else ""


static func _risk_color_key(risk_state: String) -> String:
	match risk_state:
		"safe":
			return "green"
		"risky":
			return "yellow"
		"suicidal":
			return "red"
		_:
			return "gray"


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	return fallback


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
