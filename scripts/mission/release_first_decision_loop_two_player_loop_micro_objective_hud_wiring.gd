class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveHudWiring
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.v1"
const TASK_ID: String = "TASK_991"
const SOURCE_TASK_ID: String = "TASK_990"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_next_micro_objective.v1"
const NEXT_TASK: String = "TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook"
const SOURCE_TASK: String = "TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective"


static func build_snapshot(source_next_micro_objective: Dictionary, context: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_next_micro_objective)
	var active: bool = blockers.is_empty()
	var cards: Array = Array(source_next_micro_objective.get("micro_objective_cards", [])).duplicate(true) if active else []
	var recommended_id: String = String(source_next_micro_objective.get("recommended_micro_objective_id", "")).strip_edges() if active else ""
	var focused_id: String = _select_focused_objective_id(cards, recommended_id, context) if active else ""
	var focused_card: Dictionary = _find_card(cards, focused_id)
	var chips: Array = _build_hud_micro_objective_chips(cards, focused_id, recommended_id) if active else []
	var chip_line: String = _build_chip_line(chips) if active else ""
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_next_micro_objective.get("schema", "")),
		"source_status": String(source_next_micro_objective.get("status", "")),
		"source_gate": String(source_next_micro_objective.get("gate", "")),
		"source_next_micro_objective_line": String(source_next_micro_objective.get("next_micro_objective_line", "")),
		"context_focused_objective_id": String(context.get("focused_objective_id", "")),
		"active": active,
		"status": "micro_objective_hud_wiring_ready" if active else "blocked",
		"gate": "micro_objective_hud_wiring_ready" if active else "micro_objective_hud_wiring_blocked",
		"hud_wiring_ready": active,
		"hud_micro_objective_chips": chips,
		"hud_micro_objective_chip_count": chips.size(),
		"focused_micro_objective_id": focused_id,
		"focused_micro_objective": focused_card,
		"recommended_micro_objective_id": recommended_id,
		"selected_fireteam_line": _build_selected_fireteam_line(focused_card) if active else "",
		"mission_control_line": _build_mission_control_line(chips, recommended_id) if active else "",
		"command_feedback_line": _build_command_feedback_line(focused_card) if active else "",
		"chip_line": chip_line,
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else SOURCE_TASK,
		"recommended_direction": "wire_micro_objective_choice_hook" if active else "build_next_micro_objective",
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


static func _build_blockers(source_next_micro_objective: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_next_micro_objective.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_990-Source-Schema fehlt oder passt nicht."))
	if String(source_next_micro_objective.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_990."))
	if String(source_next_micro_objective.get("status", "")) != "next_micro_objective_ready" or not bool(source_next_micro_objective.get("active", false)):
		blockers.append(_issue("source_not_ready", "TASK_990-Next-Micro-Objective ist nicht bereit."))
	var cards: Array = Array(source_next_micro_objective.get("micro_objective_cards", []))
	if int(source_next_micro_objective.get("micro_objective_card_count", cards.size())) < 3 or cards.size() < 3:
		blockers.append(_issue("source_cards_incomplete", "TASK_990 liefert nicht alle drei Micro-Objective-Karten."))
	var recommended_id: String = String(source_next_micro_objective.get("recommended_micro_objective_id", "")).strip_edges()
	if recommended_id.is_empty() or _find_card(cards, recommended_id).is_empty():
		blockers.append(_issue("source_recommendation_missing", "TASK_990 liefert keine passende Empfehlung."))
	if not _snapshot_is_read_only(source_next_micro_objective):
		blockers.append(_issue("source_not_read_only", "TASK_990-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_hud_micro_objective_chips(cards: Array, focused_id: String, recommended_id: String) -> Array:
	var chips: Array = []
	for index in cards.size():
		var card := Dictionary(cards[index])
		var objective_id: String = String(card.get("objective_id", ""))
		var label: String = String(card.get("label", ""))
		var command_intent: String = String(card.get("command_intent", ""))
		chips.append({
			"chip_id": "MicroObjectiveChip%02d" % [index + 1],
			"slot_id": "MicroObjectiveSlot%02d" % [index + 1],
			"objective_id": objective_id,
			"label": label,
			"command_intent": command_intent,
			"display_text": "%s | %s" % [label, command_intent.to_upper()],
			"tooltip_text": "%s | GO separat" % _compact_text(String(card.get("why_line", "")), 96),
			"player_line": String(card.get("player_line", "")),
			"why_line": String(card.get("why_line", "")),
			"focused": objective_id == focused_id,
			"recommended": objective_id == recommended_id,
			"confirm_action": String(card.get("confirm_action", "_issue_command")),
			"execute_action": String(card.get("execute_action", "execute_selected_fireteam_orders")),
			"requires_existing_go_path": true,
			"separate_go_required": true,
			"auto_confirms": false,
			"auto_executes_go": false,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		})
	return chips


static func _select_focused_objective_id(cards: Array, recommended_id: String, context: Dictionary) -> String:
	var focused: String = String(context.get("focused_objective_id", "")).strip_edges()
	if not focused.is_empty() and not _find_card(cards, focused).is_empty():
		return focused
	if not recommended_id.is_empty() and not _find_card(cards, recommended_id).is_empty():
		return recommended_id
	return String(Dictionary(cards[0]).get("objective_id", "")) if not cards.is_empty() else ""


static func _find_card(cards: Array, objective_id: String) -> Dictionary:
	for card_variant in cards:
		var card := Dictionary(card_variant)
		if String(card.get("objective_id", "")) == objective_id:
			return card.duplicate(true)
	return {}


static func _build_selected_fireteam_line(focused_card: Dictionary) -> String:
	if focused_card.is_empty():
		return ""
	return "NEXT OBJ %s | %s | GO separat" % [
		String(focused_card.get("label", "")),
		_compact_text(String(focused_card.get("player_line", "")), 72),
	]


static func _build_mission_control_line(chips: Array, recommended_id: String) -> String:
	var labels: Array = []
	var recommended_label: String = ""
	for chip_variant in chips:
		var chip := Dictionary(chip_variant)
		labels.append(String(chip.get("label", "")))
		if String(chip.get("objective_id", "")) == recommended_id:
			recommended_label = String(chip.get("label", ""))
	return "OBJ %s | Empfehlung %s" % [
		" / ".join(labels),
		recommended_label,
	]


static func _build_command_feedback_line(focused_card: Dictionary) -> String:
	if focused_card.is_empty():
		return ""
	return "MICRO OBJ: %s fokussiert | GO separat" % String(focused_card.get("label", ""))


static func _build_chip_line(chips: Array) -> String:
	var labels: Array = []
	for chip_variant in chips:
		labels.append(String(Dictionary(chip_variant).get("label", "")))
	return " | ".join(labels)


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
