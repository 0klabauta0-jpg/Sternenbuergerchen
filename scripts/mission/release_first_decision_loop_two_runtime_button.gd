class_name ReleaseFirstDecisionLoopTwoRuntimeButton
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_runtime_button.v1"
const TASK_ID: String = "TASK_968"
const SOURCE_TASK_ID: String = "TASK_967"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_go_smoke.v1"
const HOOK_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_execution_hook.v1"
const NEXT_TASK: String = "TASK_969 - Release First Decision Loop Two Real Window Capture"


static func build_snapshot(go_smoke: Dictionary, execution_hook: Dictionary = {}) -> Dictionary:
	var command_draft: Dictionary = Dictionary(execution_hook.get("command_draft", {}))
	var blockers: Array = _build_blockers(go_smoke, execution_hook, command_draft)
	var active: bool = blockers.is_empty()
	var source_gate: String = String(go_smoke.get("gate", "")).strip_edges()
	var passed_source: bool = source_gate == "loop_two_go_smoke_passed"
	var gate: String = "runtime_button_ready" if passed_source and active else "runtime_button_ready_for_manual_smoke"
	if not active:
		gate = "runtime_button_blocked"
	var status: String = "ready_for_real_window_capture" if passed_source and active else "runtime_button_ready_for_manual_confirm"
	if not active:
		status = "blocked"
	var selected_choice_id: String = String(go_smoke.get("selected_choice_id", execution_hook.get("selected_choice_id", command_draft.get("choice_id", "")))).strip_edges()
	var selected_command_type: String = String(go_smoke.get("selected_command_type", execution_hook.get("selected_command_type", command_draft.get("command_type", "")))).strip_edges().to_lower()
	var button_enabled: bool = active
	var runtime_line: String = _build_runtime_line(selected_choice_id, selected_command_type, button_enabled)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(go_smoke.get("schema", "")),
		"source_gate": source_gate,
		"source_status": String(go_smoke.get("status", "")),
		"execution_hook_schema": String(execution_hook.get("schema", "")),
		"execution_hook_gate": String(execution_hook.get("gate", "")),
		"active": active,
		"status": status,
		"gate": gate,
		"selected_choice_id": selected_choice_id,
		"selected_command_type": selected_command_type,
		"button_text": "2ND",
		"button_role": "second_decision_confirm",
		"button_slot_path": "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/CommandSlot07",
		"button_enabled": button_enabled,
		"button_tooltip": "2ND: zweiten Griff bestaetigen, danach GO separat ausfuehren." if button_enabled else "2ND blockiert: zweiter Griff braucht erst einen gueltigen Hook.",
		"press_action": "confirm_release_first_decision_loop_two_runtime_button",
		"confirm_action": String(command_draft.get("confirm_action", go_smoke.get("confirm_action", ""))),
		"execute_action": String(command_draft.get("execute_action", go_smoke.get("execute_action", ""))),
		"separate_go_required": true,
		"auto_executes_go": false,
		"runtime_line": runtime_line,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_968 - Release First Decision Loop Two Runtime Button",
		"recommended_direction": "capture_second_loop_real_window" if active else "fix_second_loop_runtime_button",
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


static func _build_blockers(go_smoke: Dictionary, execution_hook: Dictionary, command_draft: Dictionary) -> Array:
	var blockers: Array = []
	if String(go_smoke.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_967-Source-Schema fehlt oder passt nicht."))
	if String(go_smoke.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_967."))
	var source_gate: String = String(go_smoke.get("gate", "")).strip_edges()
	if not ["needs_go_smoke_run", "loop_two_go_smoke_passed"].has(source_gate):
		blockers.append(_issue("source_gate_not_usable", "TASK_967-Gate erlaubt keinen Runtime-Button."))
	if not _snapshot_is_read_only(go_smoke):
		blockers.append(_issue("source_not_read_only", "TASK_967-Source verletzt die read-only-Grenze."))
	if String(execution_hook.get("schema", "")) != HOOK_SCHEMA:
		blockers.append(_issue("execution_hook_schema_mismatch", "TASK_966-Execution-Hook-Schema fehlt oder passt nicht."))
	if String(execution_hook.get("gate", "")) != "execution_hook_ready":
		blockers.append(_issue("execution_hook_not_ready", "TASK_966-Execution-Hook ist nicht bereit."))
	if not _snapshot_is_read_only(execution_hook):
		blockers.append(_issue("execution_hook_not_read_only", "TASK_966-Execution-Hook verletzt die read-only-Grenze."))
	if command_draft.is_empty():
		blockers.append(_issue("command_draft_missing", "Command-Draft fuer Runtime-Button fehlt."))
	else:
		if bool(command_draft.get("auto_execute", true)):
			blockers.append(_issue("command_draft_auto_executes", "Command-Draft wuerde automatisch ausfuehren."))
		if not bool(command_draft.get("requires_go", false)):
			blockers.append(_issue("command_draft_missing_go_boundary", "Command-Draft haelt die GO-Grenze nicht."))
		if String(command_draft.get("confirm_action", "")).strip_edges().is_empty():
			blockers.append(_issue("confirm_action_missing", "Confirm-Action fehlt."))
		if String(command_draft.get("execute_action", "")).strip_edges() != "execute_selected_fireteam_orders":
			blockers.append(_issue("go_action_not_existing_path", "GO-Action nutzt nicht den bestehenden GO-Pfad."))
	return blockers


static func _build_runtime_line(choice_id: String, command_type: String, button_enabled: bool) -> String:
	var choice_label: String = _choice_label(choice_id)
	var command_label: String = command_type.strip_edges().capitalize()
	if command_label.is_empty():
		command_label = "?"
	var state_text: String = "bereit" if button_enabled else "blockiert"
	return "2ND %s %s | %s | GO bleibt separat" % [choice_label, command_label, state_text]


static func _choice_label(choice_id: String) -> String:
	match choice_id:
		"hold_angle":
			return "HOLD"
		"advance_cover":
			return "ADV"
		"fallback_regroup":
			return "BACK"
		_:
			return choice_id.strip_edges().to_upper()


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
