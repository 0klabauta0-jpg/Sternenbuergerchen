class_name ReleaseFirstDecisionLoopTwoPlaytest
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_playtest.v1"
const TASK_ID: String = "TASK_964"
const SOURCE_TASK_ID: String = "TASK_963"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_next_playable_loop.v1"
const NEXT_TASK: String = "TASK_965 - Release First Decision Loop Two Polish"


static func build_snapshot(next_loop: Dictionary, surfaces: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var loop_line: String = _resolve_loop_line(next_loop, surfaces)
	var selected_text: String = String(surfaces.get("selected_fireteam_status_text", "")).strip_edges()
	var mission_text: String = String(surfaces.get("mission_control_status_text", "")).strip_edges()
	var command_feedback_line: String = String(surfaces.get("command_feedback_line", "")).strip_edges()
	var selected_shows: bool = not loop_line.is_empty() and selected_text.contains(loop_line)
	var mission_shows: bool = not loop_line.is_empty() and mission_text.contains(loop_line)
	var command_exports: bool = not loop_line.is_empty() and command_feedback_line.contains(loop_line)
	var tokens_visible: bool = _line_contains_second_choice_tokens(loop_line) \
		or _choices_contain_second_choice_tokens(Array(next_loop.get("second_decision_choices", [])))
	var manual_state_visible: bool = bool(next_loop.get("manual_acceptance_required", false)) \
		and (next_loop.has("accepted_for_next_loop") or next_loop.has("source_live_preview")) \
		and not String(next_loop.get("status", "")).strip_edges().is_empty()
	var blockers: Array = _build_blockers(
		next_loop,
		loop_line,
		selected_shows,
		mission_shows,
		command_exports,
		tokens_visible,
		manual_state_visible
	)
	var active: bool = blockers.is_empty()
	var gate: String = "loop_two_playtest_passed" if active else "loop_two_playtest_regression_found"
	if _source_identity_blocked(next_loop):
		gate = "blocked"
	var status: String = "visible_loop_two_ready" if active else "needs_loop_two_polish"
	if gate == "blocked":
		status = "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(next_loop.get("schema", "")),
		"source_status": String(next_loop.get("status", "")),
		"source_active": bool(next_loop.get("active", false)),
		"source_live_preview": bool(next_loop.get("source_live_preview", false)),
		"accepted_for_next_loop": bool(next_loop.get("accepted_for_next_loop", false)),
		"manual_acceptance_required": bool(next_loop.get("manual_acceptance_required", false)),
		"manual_acceptance_state_visible": manual_state_visible,
		"active": active,
		"status": status,
		"gate": gate,
		"loop_line": loop_line,
		"line_within_limit": loop_line.length() > 0 and loop_line.length() <= int(context.get("line_char_limit", 128)),
		"selected_fireteam_shows_loop_line": selected_shows,
		"mission_control_shows_loop_line": mission_shows,
		"command_feedback_exports_loop_line": command_exports,
		"hold_advance_back_visible": tokens_visible,
		"selected_fireteam_status_text": selected_text,
		"mission_control_status_text": mission_text,
		"command_feedback_line": command_feedback_line,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "polish_or_execute_second_decision_loop" if active else "fix_loop_two_visibility",
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


static func _build_blockers(
	next_loop: Dictionary,
	loop_line: String,
	selected_shows: bool,
	mission_shows: bool,
	command_exports: bool,
	tokens_visible: bool,
	manual_state_visible: bool
) -> Array:
	var blockers: Array = []
	if String(next_loop.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_963-Source-Schema fehlt oder passt nicht."))
	if String(next_loop.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_963."))
	if not bool(next_loop.get("active", false)):
		blockers.append(_issue("source_not_active", "TASK_963-Loop ist nicht aktiv."))
	if not _snapshot_is_read_only(next_loop):
		blockers.append(_issue("source_not_read_only", "TASK_963-Source verletzt die read-only-Grenze."))
	if loop_line.is_empty():
		blockers.append(_issue("loop_line_missing", "TASK_963 liefert keine sichtbare zweite Entscheidungszeile."))
	elif loop_line.length() > 128:
		blockers.append(_issue("loop_line_too_long", "Zweite Entscheidungszeile ist zu lang fuer die HUD-Flaechen."))
	if not selected_shows:
		blockers.append(_issue("selected_fireteam_missing_loop_line", "Selected-Fireteam-HUD zeigt die zweite Entscheidungszeile nicht."))
	if not mission_shows:
		blockers.append(_issue("mission_control_missing_loop_line", "Mission-Control-HUD zeigt die zweite Entscheidungszeile nicht."))
	if not command_exports:
		blockers.append(_issue("command_feedback_missing_loop_line", "Command-Feedback exportiert die zweite Entscheidungszeile nicht."))
	if not tokens_visible:
		blockers.append(_issue("hold_advance_back_missing", "HOLD/ADV/BACK sind nicht zusammen lesbar."))
	if not manual_state_visible:
		blockers.append(_issue("manual_acceptance_state_missing", "Preview-/Akzeptanzstatus des zweiten Loops ist nicht sichtbar."))
	return blockers


static func _resolve_loop_line(next_loop: Dictionary, surfaces: Dictionary) -> String:
	var line: String = String(surfaces.get("command_feedback_line", "")).strip_edges()
	if line.is_empty():
		line = String(next_loop.get("visible_loop_line", "")).strip_edges()
	if line.is_empty():
		line = String(next_loop.get("primary_line", "")).strip_edges()
	return line


static func _line_contains_second_choice_tokens(line: String) -> bool:
	var upper_line: String = line.to_upper()
	return upper_line.contains("HOLD") and upper_line.contains("ADV") and upper_line.contains("BACK")


static func _choices_contain_second_choice_tokens(choices: Array) -> bool:
	var joined: String = ""
	for choice_variant in choices:
		if typeof(choice_variant) == TYPE_DICTIONARY:
			joined += " %s" % String(Dictionary(choice_variant).get("label", "")).to_upper()
	return joined.contains("HOLD") and joined.contains("ADV") and joined.contains("BACK")


static func _source_identity_blocked(next_loop: Dictionary) -> bool:
	return String(next_loop.get("schema", "")) != SOURCE_SCHEMA or String(next_loop.get("task_id", "")) != SOURCE_TASK_ID


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
