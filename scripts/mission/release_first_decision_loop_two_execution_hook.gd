class_name ReleaseFirstDecisionLoopTwoExecutionHook
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_execution_hook.v1"
const TASK_ID: String = "TASK_966"
const SOURCE_TASK_ID: String = "TASK_965"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_polish.v1"
const NEXT_TASK: String = "TASK_967 - Release First Decision Loop Two GO Smoke"


static func build_snapshot(loop_two_polish: Dictionary, context: Dictionary = {}) -> Dictionary:
	var selected_choice_id: String = String(context.get("selected_choice_id", loop_two_polish.get("recommended_choice_id", ""))).strip_edges()
	if selected_choice_id.is_empty():
		selected_choice_id = "hold_angle"
	var selected_intent: Dictionary = _find_intent(Array(loop_two_polish.get("second_decision_intents", [])), selected_choice_id)
	var command_draft: Dictionary = _build_command_draft(selected_intent, context)
	var blockers: Array = _build_blockers(loop_two_polish, selected_choice_id, selected_intent, command_draft)
	var active: bool = blockers.is_empty()
	var gate: String = "execution_hook_ready" if active else "execution_hook_review"
	if _source_identity_blocked(loop_two_polish):
		gate = "blocked"
	var status: String = "ready_for_loop_two_go_smoke" if active else "needs_execution_hook_review"
	if gate == "blocked":
		status = "blocked"
	var selected_command_type: String = String(selected_intent.get("command_type", command_draft.get("command_type", ""))).strip_edges().to_lower()
	var execution_line: String = _build_execution_line(selected_intent, command_draft) if active else ""
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(loop_two_polish.get("schema", "")),
		"source_gate": String(loop_two_polish.get("gate", "")),
		"source_status": String(loop_two_polish.get("status", "")),
		"active": active,
		"status": status,
		"gate": gate,
		"selected_choice_id": selected_choice_id,
		"selected_command_type": selected_command_type,
		"command_draft": command_draft,
		"execution_line": execution_line,
		"requires_existing_go_path": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_966 - Release First Decision Loop Two Execution Hook",
		"recommended_direction": "run_loop_two_go_smoke" if active else "fix_loop_two_execution_hook",
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


static func _build_blockers(loop_two_polish: Dictionary, selected_choice_id: String, selected_intent: Dictionary, command_draft: Dictionary) -> Array:
	var blockers: Array = []
	if String(loop_two_polish.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_965-Source-Schema fehlt oder passt nicht."))
	if String(loop_two_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_965."))
	if String(loop_two_polish.get("gate", "")) != "loop_two_polish_passed":
		blockers.append(_issue("source_gate_not_passed", "TASK_965-Polish ist nicht bestanden."))
	if not bool(loop_two_polish.get("active", false)):
		blockers.append(_issue("source_not_active", "TASK_965-Polish ist nicht aktiv."))
	if not _snapshot_is_read_only(loop_two_polish):
		blockers.append(_issue("source_not_read_only", "TASK_965-Source verletzt die read-only-Grenze."))
	if selected_intent.is_empty():
		blockers.append(_issue("selected_intent_missing", "Ausgewaehlter zweiter Intent fehlt: %s." % selected_choice_id))
	elif not _snapshot_is_read_only(selected_intent):
		blockers.append(_issue("selected_intent_not_read_only", "Ausgewaehlter zweiter Intent verletzt die read-only-Grenze."))
	if command_draft.is_empty():
		blockers.append(_issue("command_draft_missing", "Command-Draft fuer zweiten Intent fehlt."))
	elif bool(command_draft.get("auto_execute", true)):
		blockers.append(_issue("command_draft_auto_executes", "Command-Draft wuerde automatisch ausfuehren."))
	return blockers


static func _find_intent(intents: Array, selected_choice_id: String) -> Dictionary:
	for intent_variant in intents:
		if typeof(intent_variant) != TYPE_DICTIONARY:
			continue
		var intent: Dictionary = Dictionary(intent_variant)
		if String(intent.get("choice_id", "")) == selected_choice_id:
			return intent.duplicate(true)
	return {}


static func _build_command_draft(intent: Dictionary, context: Dictionary) -> Dictionary:
	if intent.is_empty():
		return {}
	var command_type: String = String(intent.get("command_type", "")).strip_edges().to_lower()
	var confirm_action: String = "_issue_command"
	var requires_selected_tile: bool = command_type in ["move", "defend", "flank", "take"]
	if command_type == "return":
		confirm_action = "return_selected_fireteams_to_plan"
		requires_selected_tile = false
	return {
		"choice_id": String(intent.get("choice_id", "")),
		"fireteam_id": String(context.get("fireteam_id", "")).strip_edges().to_lower(),
		"command_type": command_type,
		"command_label": String(intent.get("command_label", command_type.capitalize())),
		"confirm_action": confirm_action,
		"execute_action": "execute_selected_fireteam_orders",
		"requires_selected_tile": requires_selected_tile,
		"requires_go": true,
		"auto_execute": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


static func _build_execution_line(intent: Dictionary, command_draft: Dictionary) -> String:
	var label: String = String(intent.get("label", "")).strip_edges()
	var command_label: String = String(command_draft.get("command_label", "")).strip_edges()
	if label.is_empty():
		label = String(intent.get("choice_id", "")).strip_edges().to_upper()
	return "HOOK %s %s | GO bestaetigt" % [label, command_label]


static func _source_identity_blocked(loop_two_polish: Dictionary) -> bool:
	return String(loop_two_polish.get("schema", "")) != SOURCE_SCHEMA or String(loop_two_polish.get("task_id", "")) != SOURCE_TASK_ID


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
