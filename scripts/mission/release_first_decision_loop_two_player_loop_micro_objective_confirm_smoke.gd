class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveConfirmSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.v1"
const TASK_ID: String = "TASK_994"
const SOURCE_TASK_ID: String = "TASK_993"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.v1"
const CHOICE_HOOK_TASK_ID: String = "TASK_992"
const CHOICE_HOOK_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_choice_hook.v1"
const NEXT_TASK: String = "TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice"
const REVIEW_TASK: String = "TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke"
const PRESS_ACTION: String = "confirm_release_first_decision_loop_two_player_loop_micro_objective_button"
const EXECUTE_ACTION: String = "execute_selected_fireteam_orders"


static func build_snapshot(runtime_buttons: Dictionary, choice_hook: Dictionary = {}, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(runtime_buttons, choice_hook)
	var source_ready: bool = blockers.is_empty()
	var has_trace: bool = source_ready and bool(trace.get("trace_available", false))
	var issues: Array = _build_trace_issues(trace) if has_trace else []
	var completed_checks: Array = _build_completed_checks(trace) if has_trace else []
	var passed: bool = has_trace and issues.is_empty() and _missing_required_checks(completed_checks).is_empty()
	var status: String = "blocked"
	var gate: String = "micro_objective_confirm_smoke_blocked"
	var recommended_next_task: String = REVIEW_TASK
	if source_ready:
		if not has_trace:
			status = "needs_micro_objective_confirm_smoke"
			gate = "needs_micro_objective_confirm_smoke_run"
		elif passed:
			status = "micro_objective_confirm_smoke_passed"
			gate = "micro_objective_confirm_smoke_passed"
			recommended_next_task = NEXT_TASK
		else:
			status = "micro_objective_confirm_regression_found"
			gate = "micro_objective_confirm_regression_found"

	var selected_micro_objective_id: String = String(trace.get("selected_micro_objective_id", _default_micro_objective_id(runtime_buttons, choice_hook))).strip_edges()
	var selected_button: Dictionary = _find_button_spec(runtime_buttons, selected_micro_objective_id)
	var selected_label: String = String(selected_button.get("button_text", choice_hook.get("selected_micro_objective_label", selected_micro_objective_id.to_upper()))).strip_edges()
	var line: String = _build_confirm_line(status, selected_label)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(runtime_buttons.get("schema", "")),
		"source_status": String(runtime_buttons.get("status", "")),
		"source_gate": String(runtime_buttons.get("gate", "")),
		"choice_hook_task_id": String(choice_hook.get("task_id", "")),
		"choice_hook_schema": String(choice_hook.get("schema", "")),
		"active": source_ready,
		"status": status,
		"gate": gate,
		"selected_micro_objective_id": selected_micro_objective_id,
		"selected_micro_objective_label": selected_label,
		"selected_button_slot": String(selected_button.get("slot_name", trace.get("pressed_button_slot", ""))),
		"selected_command_type": String(choice_hook.get("selected_command_type", selected_button.get("command_type", ""))),
		"confirm_action": "confirm_release_first_decision_loop_two_player_loop_micro_objective_button",
		"draft_confirm_action": String(choice_hook.get("confirm_action", Dictionary(choice_hook.get("micro_objective_command_draft", {})).get("confirm_action", ""))),
		"execute_action": "execute_selected_fireteam_orders",
		"trace_available": has_trace,
		"smoke_trace": trace.duplicate(true),
		"completed_checks": completed_checks,
		"completed_check_count": completed_checks.size(),
		"missing_smoke_checks": _missing_required_checks(completed_checks) if source_ready else [],
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"micro_objective_confirm_smoke_passed": passed,
		"micro_objective_confirm_line": line,
		"post_confirm_feedback_line": String(trace.get("post_confirm_feedback_line", "")),
		"go_button_still_separate": bool(trace.get("go_button_still_separate", false)),
		"go_executed": bool(trace.get("go_executed", false)),
		"command_queue_lifecycle_observed": bool(trace.get("command_queue_lifecycle_observed", false)),
		"runtime_mutation_owner": String(trace.get("runtime_mutation_owner", "MissionTacticalSandboxController -> SimulationRoot.enqueue_command")),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "micro_objective_acceptance_slice" if passed else "run_micro_objective_confirm_smoke",
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


static func _build_blockers(runtime_buttons: Dictionary, choice_hook: Dictionary) -> Array:
	var blockers: Array = []
	if String(runtime_buttons.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_993-Source-Schema fehlt oder passt nicht."))
	if String(runtime_buttons.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_993."))
	if not bool(runtime_buttons.get("active", false)) or String(runtime_buttons.get("gate", "")) != "micro_objective_runtime_buttons_ready":
		blockers.append(_issue("runtime_buttons_not_ready", "TASK_993-Micro-Objective-Runtime-Buttons sind nicht bereit."))
	if int(runtime_buttons.get("micro_objective_button_count", 0)) < 3:
		blockers.append(_issue("runtime_button_specs_missing", "TASK_993 liefert nicht alle drei Micro-Objective-Button-Specs."))
	if String(choice_hook.get("schema", "")) != CHOICE_HOOK_SCHEMA:
		blockers.append(_issue("choice_hook_schema_mismatch", "TASK_992-Choice-Hook-Source fehlt oder passt nicht."))
	if String(choice_hook.get("task_id", "")) != CHOICE_HOOK_TASK_ID:
		blockers.append(_issue("choice_hook_task_mismatch", "Choice-Hook nennt nicht TASK_992."))
	if not bool(choice_hook.get("active", false)) or String(choice_hook.get("gate", "")) != "micro_objective_choice_hook_ready":
		blockers.append(_issue("choice_hook_not_ready", "TASK_992-Micro-Objective-Choice-Hook ist nicht bereit."))
	if not _snapshot_is_read_only(runtime_buttons) or not _snapshot_is_read_only(choice_hook):
		blockers.append(_issue("source_not_read_only", "TASK_993/TASK_992-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(trace.get("micro_objective_button_pressed", false)):
		issues.append(_issue("micro_objective_button_not_pressed", "Micro-Objective-Button wurde im Smoke nicht gedrueckt."))
	if not bool(trace.get("press_action_exists", false)):
		issues.append(_issue("press_action_missing", "Micro-Objective-Press-Action fehlt im Controller."))
	if not bool(trace.get("confirm_action_exists", false)):
		issues.append(_issue("confirm_action_missing", "Command-Confirm-Action fehlt im Controller."))
	if not bool(trace.get("execute_action_exists", false)):
		issues.append(_issue("execute_action_missing", "GO-/Execute-Action fehlt im Controller."))
	if not bool(trace.get("confirm_action_called", false)):
		issues.append(_issue("confirm_action_not_called", "Micro-Objective-Confirm wurde nicht aufgerufen."))
	if not bool(trace.get("confirm_action_result", false)):
		issues.append(_issue("confirm_action_failed", "Micro-Objective-Confirm war nicht erfolgreich."))
	if bool(trace.get("go_executed", false)):
		issues.append(_issue("go_executed_during_micro_objective_confirm", "GO wurde waehrend Micro-Objective-Confirm ausgefuehrt."))
	if not bool(trace.get("go_button_still_separate", false)):
		issues.append(_issue("go_not_separate", "GO bleibt nach Micro-Objective-Confirm nicht sichtbar getrennt."))
	if not bool(trace.get("post_confirm_feedback_visible", false)):
		issues.append(_issue("post_confirm_feedback_missing", "Nach Micro-Objective-Confirm fehlt sichtbares Feedback."))
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Smoke-Trace meldet Gameplay-Wahrheit im UI."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("movement_created_by_confirm", "Micro-Objective-Confirm erzeugt Movement."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("multiplayer_truth_created_by_confirm", "Micro-Objective-Confirm erzeugt Multiplayer-Wahrheit."))
	return issues


static func _build_completed_checks(trace: Dictionary) -> Array:
	var checks: Array = []
	for check_id in _required_checks():
		if bool(trace.get(check_id, false)):
			checks.append(check_id)
	return checks


static func _missing_required_checks(completed_checks: Array) -> Array:
	var missing: Array = []
	for check_id in _required_checks():
		if not completed_checks.has(check_id):
			missing.append(check_id)
	return missing


static func _required_checks() -> Array[String]:
	return [
		"micro_objective_button_pressed",
		"press_action_exists",
		"confirm_action_exists",
		"execute_action_exists",
		"confirm_action_called",
		"confirm_action_result",
		"go_button_still_separate",
		"post_confirm_feedback_visible",
		"command_queue_lifecycle_observed",
	]


static func _default_micro_objective_id(runtime_buttons: Dictionary, choice_hook: Dictionary) -> String:
	var hook_id: String = String(choice_hook.get("selected_micro_objective_id", "")).strip_edges()
	if not hook_id.is_empty():
		return hook_id
	var specs: Array = Array(runtime_buttons.get("micro_objective_button_specs", []))
	if specs.is_empty():
		return ""
	return String(Dictionary(specs[0]).get("micro_objective_id", "")).strip_edges()


static func _find_button_spec(runtime_buttons: Dictionary, selected_micro_objective_id: String) -> Dictionary:
	for spec_variant in Array(runtime_buttons.get("micro_objective_button_specs", [])):
		var spec := Dictionary(spec_variant)
		if String(spec.get("micro_objective_id", "")).strip_edges() == selected_micro_objective_id:
			return spec
	var specs: Array = Array(runtime_buttons.get("micro_objective_button_specs", []))
	return Dictionary(specs[0]) if not specs.is_empty() else {}


static func _build_confirm_line(status: String, selected_label: String) -> String:
	if status == "micro_objective_confirm_smoke_passed":
		return "MICRO OBJ %s -> confirmed | GO separat" % selected_label
	if status == "micro_objective_confirm_regression_found":
		return "MICRO OBJ %s -> Smoke-Reibung | GO pruefen" % selected_label
	if status == "needs_micro_objective_confirm_smoke":
		return "MICRO OBJ %s -> Smoke offen | GO separat pruefen" % selected_label
	return ""


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
