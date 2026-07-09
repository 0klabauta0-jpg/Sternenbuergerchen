class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveChoiceHook
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_choice_hook.v1"
const TASK_ID: String = "TASK_992"
const SOURCE_TASK_ID: String = "TASK_991"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.v1"
const NEXT_TASK: String = "TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons"
const SOURCE_TASK: String = "TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring"


static func build_snapshot(source_hud_wiring: Dictionary, selected_objective_id: String = "") -> Dictionary:
	var blockers: Array = _build_source_blockers(source_hud_wiring)
	var chips: Array = Array(source_hud_wiring.get("hud_micro_objective_chips", []))
	var resolved_objective_id: String = selected_objective_id.strip_edges()
	if resolved_objective_id.is_empty():
		resolved_objective_id = String(source_hud_wiring.get("focused_micro_objective_id", "")).strip_edges()
	if resolved_objective_id.is_empty():
		resolved_objective_id = String(source_hud_wiring.get("recommended_micro_objective_id", "")).strip_edges()
	if resolved_objective_id.is_empty() and not chips.is_empty():
		resolved_objective_id = String(Dictionary(chips[0]).get("objective_id", "")).strip_edges()
	var selected_chip: Dictionary = _find_chip(chips, resolved_objective_id)
	if selected_chip.is_empty():
		blockers.append(_issue("selected_micro_objective_missing", "Ausgewaehlter TASK_991-Micro-Objective-Chip fehlt."))
	var active: bool = blockers.is_empty()
	var command_type: String = String(selected_chip.get("command_intent", "")).strip_edges() if active else ""
	var command_label: String = _command_label_for_chip(selected_chip, command_type) if active else ""
	var command_draft: Dictionary = _build_command_draft(resolved_objective_id, selected_chip, command_type, command_label) if active else {}
	var hook_line: String = _build_hook_line(selected_chip, command_label) if active else ""
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_hud_wiring.get("schema", "")),
		"source_status": String(source_hud_wiring.get("status", "")),
		"source_gate": String(source_hud_wiring.get("gate", "")),
		"source_active": bool(source_hud_wiring.get("active", false)),
		"active": active,
		"status": "micro_objective_choice_hook_ready" if active else "blocked",
		"gate": "micro_objective_choice_hook_ready" if active else "micro_objective_choice_hook_blocked",
		"selected_micro_objective_id": resolved_objective_id if active else selected_objective_id.strip_edges(),
		"selected_micro_objective_label": String(selected_chip.get("label", "")) if active else "",
		"selected_command_type": command_type,
		"selected_command_label": command_label,
		"micro_objective_command_draft": command_draft,
		"confirm_action": String(command_draft.get("confirm_action", "")),
		"execute_action": String(command_draft.get("execute_action", "")),
		"micro_objective_choice_hook_line": hook_line,
		"requires_existing_go_path": active,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"recommended_next_task": NEXT_TASK if active else SOURCE_TASK,
		"recommended_direction": "wire_micro_objective_runtime_buttons_after_read_only_hook" if active else "complete_micro_objective_hud_wiring_source",
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


static func _build_source_blockers(source_hud_wiring: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_hud_wiring.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_991-Source-Schema fehlt oder passt nicht."))
	if String(source_hud_wiring.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_991."))
	if String(source_hud_wiring.get("status", "")) != "micro_objective_hud_wiring_ready" or not bool(source_hud_wiring.get("hud_wiring_ready", false)):
		blockers.append(_issue("source_not_ready", "TASK_991-HUD-Wiring ist nicht bereit."))
	if int(source_hud_wiring.get("hud_micro_objective_chip_count", 0)) < 3:
		blockers.append(_issue("source_micro_objective_chips_missing", "TASK_991 liefert nicht alle Micro-Objective-Chips."))
	if not _snapshot_is_read_only(source_hud_wiring):
		blockers.append(_issue("source_not_read_only", "TASK_991-Source verletzt die read-only-Grenze."))
	return blockers


static func _find_chip(chips: Array, selected_objective_id: String) -> Dictionary:
	for chip_variant in chips:
		if typeof(chip_variant) != TYPE_DICTIONARY:
			continue
		var chip := Dictionary(chip_variant)
		if String(chip.get("objective_id", "")) == selected_objective_id:
			return chip
	return {}


static func _command_label_for_chip(chip: Dictionary, command_type: String) -> String:
	var label: String = String(chip.get("label", "")).strip_edges()
	if label.is_empty():
		label = command_type.to_upper()
	return "%s %s" % [label, command_type.capitalize()]


static func _build_command_draft(objective_id: String, chip: Dictionary, command_type: String, command_label: String) -> Dictionary:
	return {
		"micro_objective_id": objective_id,
		"micro_objective_label": String(chip.get("label", "")),
		"command_type": command_type,
		"command_label": command_label,
		"player_line": String(chip.get("player_line", "")),
		"why_line": String(chip.get("why_line", "")),
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


static func _build_hook_line(chip: Dictionary, command_label: String) -> String:
	return "MICRO OBJ %s -> %s vorbereiten | GO separat" % [
		String(chip.get("label", "")),
		command_label,
	]


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
