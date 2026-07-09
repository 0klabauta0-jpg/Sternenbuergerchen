class_name ReleaseFirstDecisionLoopTwoPlayerLoopChoiceHook
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_hook.v1"
const TASK_ID: String = "TASK_978"
const SOURCE_TASK_ID: String = "TASK_977"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_hud_wiring.v1"
const NEXT_TASK: String = "TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons"
const REVIEW_TASK: String = "TASK_978 - Release First Decision Loop Two Player Loop Choice Hook"


static func build_snapshot(source_hud_wiring: Dictionary, selected_choice_id: String = "") -> Dictionary:
	var blockers: Array = _build_source_blockers(source_hud_wiring)
	var choices: Array = Array(source_hud_wiring.get("hud_choice_chips", []))
	var resolved_choice_id: String = selected_choice_id.strip_edges()
	if resolved_choice_id.is_empty():
		resolved_choice_id = String(source_hud_wiring.get("source_recommended_choice_id", "")).strip_edges()
	if resolved_choice_id.is_empty() and not choices.is_empty():
		resolved_choice_id = String(Dictionary(choices[0]).get("choice_id", "")).strip_edges()
	var selected_choice: Dictionary = _find_choice(choices, resolved_choice_id)
	if selected_choice.is_empty():
		blockers.append(_issue("selected_choice_missing", "Ausgewaehlter TASK_977-Choice-Chip fehlt."))
	var active: bool = blockers.is_empty()
	var command_type: String = _command_type_for_choice_id(resolved_choice_id) if active else ""
	var command_label: String = _command_label_for_choice(selected_choice, command_type) if active else ""
	var command_draft: Dictionary = _build_command_draft(resolved_choice_id, selected_choice, command_type, command_label) if active else {}
	var hook_line: String = _build_hook_line(selected_choice, command_label) if active else ""
	var status: String = "choice_hook_ready" if active else "blocked"
	var gate: String = "choice_hook_ready" if active else "choice_hook_blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_hud_wiring.get("schema", "")),
		"source_status": String(source_hud_wiring.get("status", "")),
		"source_gate": String(source_hud_wiring.get("gate", "")),
		"source_active": bool(source_hud_wiring.get("active", false)),
		"active": active,
		"status": status,
		"gate": gate,
		"selected_choice_id": resolved_choice_id if active else selected_choice_id.strip_edges(),
		"selected_choice_token": String(selected_choice.get("token", "")) if active else "",
		"selected_choice_label": String(selected_choice.get("label", "")) if active else "",
		"selected_command_type": command_type,
		"selected_command_label": command_label,
		"command_draft": command_draft,
		"confirm_action": String(command_draft.get("confirm_action", "")),
		"execute_action": String(command_draft.get("execute_action", "")),
		"choice_hook_line": hook_line,
		"requires_existing_go_path": active,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"recommended_next_task": NEXT_TASK if active else REVIEW_TASK,
		"recommended_direction": "wire_runtime_choice_buttons_after_read_only_hook" if active else "complete_player_loop_hud_wiring_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_977-Source-Schema fehlt oder passt nicht."))
	if String(source_hud_wiring.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_977."))
	if not bool(source_hud_wiring.get("active", false)) or String(source_hud_wiring.get("gate", "")) != "player_loop_hud_wiring_ready":
		blockers.append(_issue("source_not_ready", "TASK_977-HUD-Wiring ist nicht bereit."))
	if int(source_hud_wiring.get("hud_choice_chip_count", 0)) < 4:
		blockers.append(_issue("source_choice_chips_missing", "TASK_977 liefert nicht alle Choice-Chips."))
	if not _snapshot_is_read_only(source_hud_wiring):
		blockers.append(_issue("source_not_read_only", "TASK_977-Source verletzt die read-only-Grenze."))
	return blockers


static func _find_choice(choices: Array, selected_choice_id: String) -> Dictionary:
	for choice_variant in choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		var choice := Dictionary(choice_variant)
		if String(choice.get("choice_id", "")) == selected_choice_id:
			return choice
	return {}


static func _command_type_for_choice_id(choice_id: String) -> String:
	match choice_id:
		"secure_area":
			return "defend"
		"push_objective":
			return "move"
		"flank_pressure":
			return "flank"
		"reset_spacing":
			return "move"
		_:
			return ""


static func _command_label_for_choice(choice: Dictionary, command_type: String) -> String:
	var token: String = String(choice.get("token", "")).strip_edges()
	if token.is_empty():
		token = command_type.to_upper()
	return "%s %s" % [token, command_type.capitalize()]


static func _build_command_draft(choice_id: String, choice: Dictionary, command_type: String, command_label: String) -> Dictionary:
	return {
		"choice_id": choice_id,
		"choice_label": String(choice.get("label", "")),
		"command_hint": String(choice.get("command_hint", "")),
		"command_type": command_type,
		"command_label": command_label,
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


static func _build_hook_line(choice: Dictionary, command_label: String) -> String:
	var token: String = String(choice.get("token", "")).strip_edges()
	if token.is_empty():
		token = command_label
	return "CHOICE %s -> %s vorbereiten | GO separat" % [token, command_label]


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
