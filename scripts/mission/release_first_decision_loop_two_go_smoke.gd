class_name ReleaseFirstDecisionLoopTwoGoSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_go_smoke.v1"
const TASK_ID: String = "TASK_967"
const SOURCE_TASK_ID: String = "TASK_966"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_execution_hook.v1"
const NEXT_TASK: String = "TASK_968 - Release First Decision Loop Two Runtime Button"


static func build_snapshot(execution_hook: Dictionary, smoke_trace: Dictionary = {}) -> Dictionary:
	var command_draft: Dictionary = Dictionary(execution_hook.get("command_draft", {}))
	var blockers: Array = _build_blockers(execution_hook, command_draft, smoke_trace)
	var source_blocked: bool = _source_identity_blocked(execution_hook)
	var run_missing_only: bool = _has_only_run_missing_blockers(blockers)
	var active: bool = blockers.is_empty()
	var gate: String = "loop_two_go_smoke_passed" if active else "go_smoke_review"
	if source_blocked:
		gate = "blocked"
	elif run_missing_only:
		gate = "needs_go_smoke_run"
	var status: String = "ready_for_runtime_button" if active else "needs_go_smoke_review"
	if gate == "blocked":
		status = "blocked"
	elif gate == "needs_go_smoke_run":
		status = "needs_loop_two_go_smoke"
	var selected_choice_id: String = String(execution_hook.get("selected_choice_id", command_draft.get("choice_id", ""))).strip_edges()
	var selected_command_type: String = String(execution_hook.get("selected_command_type", command_draft.get("command_type", ""))).strip_edges().to_lower()
	var smoke_line: String = _build_smoke_line(command_draft, smoke_trace, active)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(execution_hook.get("schema", "")),
		"source_gate": String(execution_hook.get("gate", "")),
		"source_status": String(execution_hook.get("status", "")),
		"active": active,
		"status": status,
		"gate": gate,
		"selected_choice_id": selected_choice_id,
		"selected_command_type": selected_command_type,
		"confirm_action": String(command_draft.get("confirm_action", "")),
		"execute_action": String(command_draft.get("execute_action", "")),
		"smoke_trace": smoke_trace.duplicate(true),
		"smoke_line": smoke_line,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_967 - Release First Decision Loop Two GO Smoke",
		"recommended_direction": "wire_loop_two_runtime_button" if active else "run_loop_two_go_smoke",
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


static func _build_blockers(execution_hook: Dictionary, command_draft: Dictionary, smoke_trace: Dictionary) -> Array:
	var blockers: Array = []
	if String(execution_hook.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_966-Source-Schema fehlt oder passt nicht."))
	if String(execution_hook.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_966."))
	if String(execution_hook.get("gate", "")) != "execution_hook_ready":
		blockers.append(_issue("source_gate_not_ready", "TASK_966-Execution-Hook ist nicht bereit."))
	if not bool(execution_hook.get("active", false)):
		blockers.append(_issue("source_not_active", "TASK_966-Execution-Hook ist nicht aktiv."))
	if not _snapshot_is_read_only(execution_hook):
		blockers.append(_issue("source_not_read_only", "TASK_966-Source verletzt die read-only-Grenze."))
	if command_draft.is_empty():
		blockers.append(_issue("command_draft_missing", "Command-Draft fuer zweiten Intent fehlt."))
	else:
		if not bool(command_draft.get("requires_go", false)):
			blockers.append(_issue("command_draft_missing_go_boundary", "Command-Draft haelt die GO-Grenze nicht."))
		if bool(command_draft.get("auto_execute", true)):
			blockers.append(_issue("command_draft_auto_executes", "Command-Draft wuerde automatisch ausfuehren."))
		if not bool(command_draft.get("read_only", false)):
			blockers.append(_issue("command_draft_not_read_only", "Command-Draft ist nicht read-only."))
	if smoke_trace.is_empty():
		blockers.append(_issue("confirm_not_run", "Confirm-Pfad wurde im Smoke nicht ausgefuehrt."))
		blockers.append(_issue("go_not_run", "GO-Pfad wurde im Smoke nicht ausgefuehrt."))
		return blockers
	if not bool(smoke_trace.get("confirm_action_exists", false)):
		blockers.append(_issue("confirm_path_missing", "Confirm-Pfad existiert im Controller nicht."))
	if not bool(smoke_trace.get("execute_action_exists", false)):
		blockers.append(_issue("go_path_missing", "GO-Pfad existiert im Controller nicht."))
	if not bool(smoke_trace.get("confirm_action_called", false)):
		blockers.append(_issue("confirm_not_run", "Confirm-Pfad wurde im Smoke nicht ausgefuehrt."))
	if not bool(smoke_trace.get("execute_action_called", false)):
		blockers.append(_issue("go_not_run", "GO-Pfad wurde im Smoke nicht ausgefuehrt."))
	if bool(smoke_trace.get("confirm_action_called", false)) and not bool(smoke_trace.get("confirm_action_result", false)):
		blockers.append(_issue("confirm_result_failed", "Confirm-Pfad meldet keinen Erfolg."))
	if bool(smoke_trace.get("execute_action_called", false)) and not bool(smoke_trace.get("execute_action_result", false)):
		blockers.append(_issue("go_result_failed", "GO-Pfad meldet keinen Erfolg."))
	if not bool(smoke_trace.get("confirm_and_go_are_separate_steps", false)):
		blockers.append(_issue("confirm_go_not_separate", "Confirm und GO sind nicht als getrennte Schritte belegt."))
	if bool(smoke_trace.get("execute_action_called", false)) and not bool(smoke_trace.get("post_go_feedback_visible", false)):
		blockers.append(_issue("post_go_feedback_missing", "Nach GO ist kein Spielerfeedback sichtbar."))
	if bool(smoke_trace.get("ui_sets_gameplay_truth", false)):
		blockers.append(_issue("ui_sets_gameplay_truth", "Smoke-Trace meldet UI-Gameplay-Wahrheit."))
	if bool(smoke_trace.get("sets_multiplayer_truth", false)):
		blockers.append(_issue("sets_multiplayer_truth", "Smoke-Trace meldet Multiplayer-Wahrheit im UI-Pfad."))
	return blockers


static func _build_smoke_line(command_draft: Dictionary, smoke_trace: Dictionary, active: bool) -> String:
	var confirm_action: String = String(command_draft.get("confirm_action", "")).strip_edges()
	var execute_action: String = String(command_draft.get("execute_action", "")).strip_edges()
	var result_label: String = "PASS" if active else "PENDING"
	var feedback_line: String = String(smoke_trace.get("post_go_feedback_line", "")).strip_edges()
	var line: String = "GO-SMOKE %s | CONFIRM %s | GO %s" % [result_label, confirm_action, execute_action]
	if not feedback_line.is_empty():
		line += " | %s" % feedback_line
	return line


static func _has_only_run_missing_blockers(blockers: Array) -> bool:
	if blockers.is_empty():
		return false
	for issue_variant in blockers:
		if typeof(issue_variant) != TYPE_DICTIONARY:
			return false
		var issue_id: String = String(Dictionary(issue_variant).get("id", ""))
		if not ["confirm_not_run", "go_not_run", "post_go_feedback_missing"].has(issue_id):
			return false
	return true


static func _source_identity_blocked(execution_hook: Dictionary) -> bool:
	return String(execution_hook.get("schema", "")) != SOURCE_SCHEMA or String(execution_hook.get("task_id", "")) != SOURCE_TASK_ID


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
