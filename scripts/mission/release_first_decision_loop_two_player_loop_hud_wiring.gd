class_name ReleaseFirstDecisionLoopTwoPlayerLoopHudWiring
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_hud_wiring.v1"
const TASK_ID: String = "TASK_977"
const SOURCE_TASK_ID: String = "TASK_976"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_extension.v1"
const NEXT_TASK: String = "TASK_978 - Release First Decision Loop Two Player Loop Choice Hook"
const REVIEW_TASK: String = "TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring"
const MAX_SELECTED_LINE_LENGTH: int = 112
const MAX_MISSION_LINE_LENGTH: int = 118
const MAX_COMMAND_LINE_LENGTH: int = 132


static func build_snapshot(source_extension: Dictionary, surfaces: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_extension)
	var active: bool = blockers.is_empty()
	var chips: Array = _build_choice_chips(Array(source_extension.get("next_player_choices", []))) if active else []
	var selected_line: String = _trim_line(String(source_extension.get("primary_line", "")), MAX_SELECTED_LINE_LENGTH) if active else ""
	var mission_line: String = _trim_line(String(source_extension.get("why_line", "")), MAX_MISSION_LINE_LENGTH) if active else ""
	var choice_chip_line: String = _build_choice_chip_line(chips) if active else ""
	var command_line: String = _trim_line("%s | %s" % [selected_line, choice_chip_line], MAX_COMMAND_LINE_LENGTH) if active else ""
	var selected_surface_text: String = String(surfaces.get("selected_fireteam_status_text", "")).strip_edges()
	var mission_surface_text: String = String(surfaces.get("mission_control_status_text", "")).strip_edges()
	var command_surface_text: String = String(surfaces.get("command_feedback_text", "")).strip_edges()
	var selected_shows: bool = active and _surface_contains_selected_player_loop(selected_surface_text)
	var mission_shows: bool = active and _surface_contains_mission_player_loop(mission_surface_text)
	var command_exports: bool = active and _surface_contains_all_choice_tokens(command_surface_text)
	var status: String = "player_loop_hud_wiring_ready" if active else "blocked"
	var gate: String = "player_loop_hud_wiring_ready" if active else "player_loop_hud_wiring_blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_extension.get("schema", "")),
		"source_status": String(source_extension.get("status", "")),
		"source_active": bool(source_extension.get("active", false)),
		"source_choice_count": int(source_extension.get("next_choice_count", 0)),
		"source_recommended_choice_id": String(source_extension.get("recommended_choice_id", "")),
		"active": active,
		"status": status,
		"gate": gate,
		"selected_fireteam_line": selected_line,
		"mission_control_line": mission_line,
		"command_feedback_line": command_line,
		"choice_chip_line": choice_chip_line,
		"hud_choice_chips": chips,
		"hud_choice_chip_count": chips.size(),
		"selected_fireteam_shows_player_loop": selected_shows,
		"mission_control_shows_player_loop": mission_shows,
		"command_feedback_exports_player_loop": command_exports,
		"selected_line_within_limit": selected_line.length() <= MAX_SELECTED_LINE_LENGTH,
		"mission_line_within_limit": mission_line.length() <= MAX_MISSION_LINE_LENGTH,
		"command_line_within_limit": command_line.length() <= MAX_COMMAND_LINE_LENGTH,
		"recommended_next_task": NEXT_TASK if active else REVIEW_TASK,
		"recommended_direction": "wire_choice_hook_after_hud_readability" if active else "complete_player_loop_extension_source",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
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


static func _build_blockers(source_extension: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_extension.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_976-Source-Schema fehlt oder passt nicht."))
	if String(source_extension.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_976."))
	if not bool(source_extension.get("active", false)) or String(source_extension.get("status", "")) != "ready_for_player_loop_extension":
		blockers.append(_issue("source_not_active", "TASK_976-Player-Loop ist nicht aktiv."))
	if int(source_extension.get("next_choice_count", 0)) < 4:
		blockers.append(_issue("source_choices_missing", "TASK_976 liefert nicht alle vier Spielergriffe."))
	if String(source_extension.get("primary_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_primary_line_missing", "TASK_976 liefert keine NEXT-Zeile."))
	if String(source_extension.get("why_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_why_line_missing", "TASK_976 liefert keine WHY-Zeile."))
	if not _snapshot_is_read_only(source_extension):
		blockers.append(_issue("source_not_read_only", "TASK_976-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_choice_chips(choices: Array) -> Array:
	var chips: Array = []
	for choice_variant in choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		var choice := Dictionary(choice_variant)
		var label: String = String(choice.get("label", "")).strip_edges()
		var token: String = label.split(" ")[0] if not label.is_empty() else String(choice.get("choice_id", "")).to_upper()
		chips.append({
			"choice_id": String(choice.get("choice_id", "")),
			"token": token,
			"label": label,
			"command_hint": String(choice.get("command_hint", "")),
			"risk_label": String(choice.get("risk_label", "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		})
	return chips


static func _build_choice_chip_line(chips: Array) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	for chip_variant in chips:
		var token: String = String(Dictionary(chip_variant).get("token", "")).strip_edges()
		if not token.is_empty():
			tokens.append(token)
	return "CHOICES %s" % " / ".join(tokens)


static func _surface_contains_selected_player_loop(text: String) -> bool:
	var upper_text: String = text.to_upper()
	if upper_text.is_empty():
		return false
	return upper_text.contains("NEXT") and upper_text.contains("SECURE")


static func _surface_contains_mission_player_loop(text: String) -> bool:
	var upper_text: String = text.to_upper()
	if upper_text.is_empty():
		return false
	return upper_text.contains("WHY") and (upper_text.contains("SECURE") or upper_text.contains("PUSH") or upper_text.contains("FLANK") or upper_text.contains("RESET"))


static func _surface_contains_all_choice_tokens(text: String) -> bool:
	var upper_text: String = text.to_upper()
	if upper_text.is_empty():
		return false
	return upper_text.contains("SECURE") and upper_text.contains("PUSH") and upper_text.contains("FLANK") and upper_text.contains("RESET")


static func _trim_line(line: String, limit: int) -> String:
	var trimmed: String = line.strip_edges()
	if trimmed.length() <= limit:
		return trimmed
	if limit <= 1:
		return trimmed.left(maxi(limit, 0))
	return "%s..." % trimmed.left(limit - 3).strip_edges()


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
