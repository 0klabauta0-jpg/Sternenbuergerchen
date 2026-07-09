class_name ReleaseFirstDecisionLoopTwoPlayerLoopNextMicroObjective
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_next_micro_objective.v1"
const TASK_ID: String = "TASK_990"
const SOURCE_TASK_ID: String = "TASK_989"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_playability_slice.v1"
const NEXT_TASK: String = "TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring"
const SOURCE_TASK: String = "TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice"


static func build_snapshot(source_outcome_playability: Dictionary, context: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_outcome_playability)
	var active: bool = blockers.is_empty()
	var cards: Array = _build_micro_objective_cards(source_outcome_playability) if active else []
	var recommended_id: String = _select_recommended_objective_id(cards, context) if active else ""
	var recommended: Dictionary = _find_card(cards, recommended_id)
	var line: String = _build_next_micro_objective_line(recommended) if active else ""
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_outcome_playability.get("schema", "")),
		"source_status": String(source_outcome_playability.get("status", "")),
		"source_gate": String(source_outcome_playability.get("gate", "")),
		"source_outcome_playability_line": String(source_outcome_playability.get("outcome_playability_line", "")),
		"source_answered_player_questions": Array(source_outcome_playability.get("answered_player_questions", [])).duplicate(true),
		"context_preferred_objective_id": String(context.get("preferred_objective_id", "")),
		"context_pressure_window_open": bool(context.get("pressure_window_open", false)),
		"active": active,
		"status": "next_micro_objective_ready" if active else "blocked",
		"gate": "next_micro_objective_ready" if active else "next_micro_objective_blocked",
		"micro_objective_cards": cards,
		"micro_objective_card_count": cards.size(),
		"recommended_micro_objective_id": recommended_id,
		"recommended_micro_objective": recommended,
		"next_micro_objective_line": line,
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else SOURCE_TASK,
		"recommended_direction": "wire_micro_objective_to_hud" if active else "pass_outcome_playability_slice",
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


static func _build_blockers(source_outcome_playability: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_outcome_playability.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_989-Source-Schema fehlt oder passt nicht."))
	if String(source_outcome_playability.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_989."))
	if String(source_outcome_playability.get("status", "")) != "outcome_playability_slice_passed" or not bool(source_outcome_playability.get("outcome_playability_slice_passed", false)):
		blockers.append(_issue("source_not_passed", "TASK_989-Outcome-Playability-Slice ist nicht bestanden."))
	if not _snapshot_is_read_only(source_outcome_playability):
		blockers.append(_issue("source_not_read_only", "TASK_989-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_micro_objective_cards(source_outcome_playability: Dictionary) -> Array:
	var outcome_line: String = String(source_outcome_playability.get("outcome_playability_line", "")).strip_edges()
	return [
		_micro_objective_card(
			"secure_gained_ground",
			"SICHERN",
			"defend",
			"OBJ SICHERN: Zielstand halten, Winkel ordnen, Kontaktlage lesen.",
			"Nach dem Outcome ist der neue Stand wertvoller als ein hektischer Anschluss.",
			outcome_line
		),
		_micro_objective_card(
			"press_next_contact",
			"DRUECKEN",
			"move",
			"OBJ DRUECKEN: gedeckt nachsetzen und naechsten Kontakt erzwingen.",
			"Wenn das Zeitfenster offen ist, wird aus Druck ein Folgegriff.",
			outcome_line
		),
		_micro_objective_card(
			"regroup_fireteam",
			"SAMMELN",
			"hold",
			"OBJ SAMMELN: Feuerteam ordnen, Risiko senken, naechsten Befehl sauber vorbereiten.",
			"Wenn Lesbarkeit oder Druck kippt, ist Kontrolle besser als Tempo.",
			outcome_line
		),
	]


static func _micro_objective_card(objective_id: String, label: String, command_intent: String, player_line: String, why_line: String, source_line: String) -> Dictionary:
	return {
		"objective_id": objective_id,
		"label": label,
		"command_intent": command_intent,
		"player_line": player_line,
		"why_line": why_line,
		"source_outcome_hint": _compact_text(source_line, 72),
		"confirm_action": "_issue_command",
		"execute_action": "execute_selected_fireteam_orders",
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _select_recommended_objective_id(cards: Array, context: Dictionary) -> String:
	var preferred: String = String(context.get("preferred_objective_id", "")).strip_edges()
	if not preferred.is_empty() and not _find_card(cards, preferred).is_empty():
		return preferred
	if bool(context.get("pressure_window_open", false)):
		return "press_next_contact"
	return "secure_gained_ground"


static func _find_card(cards: Array, objective_id: String) -> Dictionary:
	for card_variant in cards:
		var card := Dictionary(card_variant)
		if String(card.get("objective_id", "")) == objective_id:
			return card.duplicate(true)
	return {}


static func _build_next_micro_objective_line(recommended: Dictionary) -> String:
	if recommended.is_empty():
		return ""
	return "NEXT OBJ %s: %s | GO separat" % [
		String(recommended.get("label", "")),
		_compact_text(String(recommended.get("player_line", "")), 72),
	]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


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
