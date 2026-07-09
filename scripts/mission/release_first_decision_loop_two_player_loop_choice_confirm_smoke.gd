class_name ReleaseFirstDecisionLoopTwoPlayerLoopChoiceConfirmSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_confirm_smoke.v1"
const TASK_ID: String = "TASK_980"
const SOURCE_TASK_ID: String = "TASK_979"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_runtime_choice_buttons.v1"
const CHOICE_HOOK_TASK_ID: String = "TASK_978"
const CHOICE_HOOK_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_hook.v1"
const NEXT_TASK: String = "TASK_981 - Release First Decision Loop Two Player Loop Real Window Capture"
const REVIEW_TASK: String = "TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke"


static func build_snapshot(runtime_buttons: Dictionary, choice_hook: Dictionary = {}, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(runtime_buttons, choice_hook)
	var source_ready: bool = blockers.is_empty()
	var issues: Array = _build_trace_issues(trace) if source_ready and bool(trace.get("trace_available", false)) else []
	var completed_checks: Array = _build_completed_checks(trace) if source_ready and bool(trace.get("trace_available", false)) else []
	var has_trace: bool = source_ready and bool(trace.get("trace_available", false))
	var passed: bool = has_trace and issues.is_empty() and _has_required_completed_checks(completed_checks)
	var status: String = "blocked"
	var gate: String = "choice_confirm_smoke_blocked"
	var recommended_next_task: String = REVIEW_TASK
	if source_ready:
		if not has_trace:
			status = "needs_choice_confirm_smoke"
			gate = "needs_choice_confirm_smoke_run"
		elif passed:
			status = "choice_confirm_smoke_passed"
			gate = "choice_confirm_smoke_passed"
			recommended_next_task = NEXT_TASK
		else:
			status = "choice_confirm_smoke_regression_found"
			gate = "choice_confirm_smoke_regression_found"

	var selected_choice_id: String = String(trace.get("selected_choice_id", _default_choice_id(runtime_buttons, choice_hook))).strip_edges()
	var selected_button: Dictionary = _find_button_spec(runtime_buttons, selected_choice_id)
	var selected_token: String = String(selected_button.get("button_text", selected_choice_id.to_upper())).strip_edges()
	var smoke_line: String = _build_smoke_line(status, selected_token, trace)
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
		"selected_choice_id": selected_choice_id,
		"selected_button_slot": String(selected_button.get("slot_name", trace.get("pressed_button_slot", ""))),
		"selected_button_text": selected_token,
		"press_action": String(runtime_buttons.get("press_action", "confirm_release_first_decision_loop_two_player_loop_choice_button")),
		"confirm_action": String(choice_hook.get("confirm_action", Dictionary(choice_hook.get("command_draft", {})).get("confirm_action", ""))),
		"execute_action": String(runtime_buttons.get("execute_action", choice_hook.get("execute_action", "execute_selected_fireteam_orders"))),
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
		"choice_confirm_smoke_passed": passed,
		"smoke_line": smoke_line,
		"post_confirm_feedback_line": String(trace.get("post_confirm_feedback_line", "")),
		"go_button_still_separate": bool(trace.get("go_button_still_separate", false)),
		"go_executed": bool(trace.get("go_executed", false)),
		"command_queue_lifecycle_observed": bool(trace.get("command_queue_lifecycle_observed", false)),
		"runtime_mutation_owner": String(trace.get("runtime_mutation_owner", "MissionTacticalSandboxController -> SimulationRoot.enqueue_command")),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "capture_real_window" if passed else "run_choice_confirm_smoke",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_979-Source-Schema fehlt oder passt nicht."))
	if String(runtime_buttons.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_979."))
	if not bool(runtime_buttons.get("active", false)) or String(runtime_buttons.get("gate", "")) != "runtime_choice_buttons_ready":
		blockers.append(_issue("runtime_buttons_not_ready", "TASK_979-Runtime-Choice-Buttons sind nicht bereit."))
	if int(runtime_buttons.get("button_count", 0)) < 4:
		blockers.append(_issue("runtime_button_specs_missing", "TASK_979 liefert nicht alle vier Button-Specs."))
	if String(choice_hook.get("schema", "")) != CHOICE_HOOK_SCHEMA:
		blockers.append(_issue("choice_hook_schema_mismatch", "TASK_978-Choice-Hook-Source fehlt oder passt nicht."))
	if String(choice_hook.get("task_id", "")) != CHOICE_HOOK_TASK_ID:
		blockers.append(_issue("choice_hook_task_mismatch", "Choice-Hook nennt nicht TASK_978."))
	if not bool(choice_hook.get("active", false)) or String(choice_hook.get("gate", "")) != "choice_hook_ready":
		blockers.append(_issue("choice_hook_not_ready", "TASK_978-Choice-Hook ist nicht bereit."))
	if not _snapshot_is_read_only(runtime_buttons) or not _snapshot_is_read_only(choice_hook):
		blockers.append(_issue("source_not_read_only", "TASK_979/TASK_978-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(trace.get("choice_button_pressed", false)):
		issues.append(_issue("choice_button_not_pressed", "Choice-Button wurde im Smoke nicht gedrueckt."))
	if not bool(trace.get("press_action_exists", false)):
		issues.append(_issue("press_action_missing", "Press-Action fehlt im Controller."))
	if not bool(trace.get("confirm_action_exists", false)):
		issues.append(_issue("confirm_action_missing", "Confirm-Action fehlt im Controller."))
	if not bool(trace.get("execute_action_exists", false)):
		issues.append(_issue("execute_action_missing", "GO-/Execute-Action fehlt im Controller."))
	if not bool(trace.get("confirm_action_called", false)):
		issues.append(_issue("confirm_action_not_called", "Choice-Confirm wurde nicht aufgerufen."))
	if not bool(trace.get("confirm_action_result", false)):
		issues.append(_issue("confirm_action_failed", "Choice-Confirm war nicht erfolgreich."))
	if bool(trace.get("go_executed", false)):
		issues.append(_issue("go_executed_during_choice_confirm", "GO wurde waehrend Choice-Confirm ausgefuehrt."))
	if not bool(trace.get("go_button_still_separate", false)):
		issues.append(_issue("go_not_separate", "GO bleibt nach Choice-Confirm nicht sichtbar getrennt."))
	if not bool(trace.get("post_confirm_feedback_visible", false)):
		issues.append(_issue("post_confirm_feedback_missing", "Nach Choice-Confirm fehlt sichtbares Feedback."))
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Smoke-Trace meldet Gameplay-Wahrheit im UI."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("movement_created_by_confirm", "Choice-Confirm erzeugt Movement."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("multiplayer_truth_created_by_confirm", "Choice-Confirm erzeugt Multiplayer-Wahrheit."))
	return issues


static func _build_completed_checks(trace: Dictionary) -> Array:
	var checks: Array = []
	for check_id in _required_checks():
		if bool(trace.get(check_id, false)):
			checks.append(check_id)
	return checks


static func _has_required_completed_checks(completed_checks: Array) -> bool:
	return _missing_required_checks(completed_checks).is_empty()


static func _missing_required_checks(completed_checks: Array) -> Array:
	var missing: Array = []
	for check_id in _required_checks():
		if not completed_checks.has(check_id):
			missing.append(check_id)
	return missing


static func _required_checks() -> Array[String]:
	return [
		"choice_button_pressed",
		"press_action_exists",
		"confirm_action_exists",
		"execute_action_exists",
		"confirm_action_called",
		"confirm_action_result",
		"go_button_still_separate",
		"post_confirm_feedback_visible",
		"command_queue_lifecycle_observed",
	]


static func _default_choice_id(runtime_buttons: Dictionary, choice_hook: Dictionary) -> String:
	var hook_choice_id: String = String(choice_hook.get("selected_choice_id", "")).strip_edges()
	if not hook_choice_id.is_empty():
		return hook_choice_id
	var specs: Array = Array(runtime_buttons.get("button_specs", []))
	if specs.is_empty():
		return ""
	return String(Dictionary(specs[0]).get("choice_id", "")).strip_edges()


static func _find_button_spec(runtime_buttons: Dictionary, choice_id: String) -> Dictionary:
	for spec_variant in Array(runtime_buttons.get("button_specs", [])):
		var spec := Dictionary(spec_variant)
		if String(spec.get("choice_id", "")).strip_edges() == choice_id:
			return spec
	var specs: Array = Array(runtime_buttons.get("button_specs", []))
	return Dictionary(specs[0]) if not specs.is_empty() else {}


static func _build_smoke_line(status: String, selected_token: String, trace: Dictionary) -> String:
	if status == "choice_confirm_smoke_passed":
		return "CHOICE SECURE -> confirmed | GO separat" if selected_token == "SECURE" else "CHOICE %s -> confirmed | GO separat" % selected_token
	if status == "choice_confirm_smoke_regression_found":
		return "CHOICE %s -> Smoke-Reibung | GO pruefen" % selected_token
	if status == "needs_choice_confirm_smoke":
		return "CHOICE %s -> Smoke offen | GO separat pruefen" % selected_token
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
