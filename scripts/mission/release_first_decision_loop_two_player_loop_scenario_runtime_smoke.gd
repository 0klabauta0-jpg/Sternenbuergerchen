class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioRuntimeSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_smoke.v1"
const TASK_ID: String = "TASK_1014"
const SOURCE_TASK_ID: String = "TASK_1013"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_hook.v1"
const HOOK_TASK: String = "TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook"
const REVIEW_TASK: String = "TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke"
const NEXT_TASK: String = "TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"

const REQUIRED_SMOKE_CHECKS: PackedStringArray = [
	"entry_visible",
	"next_visible",
	"runtime_choice_selected",
	"confirm_visible",
	"confirm_action_result",
	"go_still_separate",
	"no_auto_go_after_confirm",
	"go_executed_after_confirm",
	"post_go_feedback_visible",
	"feedback_returns_to_next",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_runtime_hook: Dictionary, smoke_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_runtime_hook)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = source_ready and (bool(smoke_trace.get("trace_available", false)) or not smoke_trace.is_empty())
	var missing_checks: Array = _missing_trace_checks(smoke_trace) if trace_available else []
	var issues: Array = []
	var passed: bool = false
	var status: String = "blocked"
	var gate: String = "scenario_runtime_smoke_blocked"
	var recommended_next_task: String = HOOK_TASK
	var recommended_direction: String = "fix_scenario_runtime_hook"
	if source_ready:
		if not trace_available:
			status = "needs_scenario_runtime_smoke_trace"
			gate = "needs_scenario_runtime_smoke_trace"
			issues.append(_issue("scenario_runtime_smoke_trace_missing", "TASK_1014-Smoke-Trace fuer ENTRY -> NEXT -> CONFIRM -> GO -> FEEDBACK fehlt."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_scenario_runtime_smoke_trace"
		elif missing_checks.is_empty() and _trace_boundaries_clean(smoke_trace):
			status = "scenario_runtime_smoke_passed"
			gate = "scenario_runtime_smoke_passed"
			passed = true
			recommended_next_task = NEXT_TASK
			recommended_direction = "collect_scenario_player_feel_findings"
		else:
			status = "scenario_runtime_smoke_regression_found"
			gate = "scenario_runtime_smoke_regression_found"
			issues = _issues_for_missing_checks(missing_checks) + _boundary_issues(smoke_trace)
			recommended_next_task = HOOK_TASK
			recommended_direction = "fix_scenario_runtime_smoke"

	var completed_checks: Array = _completed_trace_checks(smoke_trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_runtime_hook.get("schema", "")),
		"source_status": String(source_runtime_hook.get("status", "")),
		"source_gate": String(source_runtime_hook.get("gate", "")),
		"source_runtime_line": String(source_runtime_hook.get("mission_control_runtime_line", "")),
		"trace_available": trace_available,
		"required_smoke_checks": Array(REQUIRED_SMOKE_CHECKS),
		"completed_checks": completed_checks,
		"missing_smoke_checks": missing_checks,
		"selected_runtime_choice_id": String(smoke_trace.get("selected_runtime_choice_id", source_runtime_hook.get("selected_runtime_choice_id", ""))),
		"post_smoke_feedback_line": String(smoke_trace.get("post_smoke_feedback_line", "")),
		"smoke_line": _build_smoke_line(smoke_trace, passed, trace_available),
		"scenario_runtime_smoke_passed": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
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


static func _build_source_blockers(source_runtime_hook: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_runtime_hook.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1013-Source-Schema fehlt oder passt nicht."))
	if String(source_runtime_hook.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1013."))
	if String(source_runtime_hook.get("status", "")) != "runtime_hook_ready" or not bool(source_runtime_hook.get("runtime_hook_ready", false)):
		blockers.append(_issue("source_not_ready", "TASK_1013-Runtime-Hook ist nicht bereit."))
	if String(source_runtime_hook.get("mission_control_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_runtime_line_missing", "TASK_1013-Mission-Control-Runtime-Zeile fehlt."))
	if Array(source_runtime_hook.get("command_matrix_runtime_hooks", [])).size() < 3:
		blockers.append(_issue("source_command_hooks_missing", "TASK_1013-Command-Matrix-Hooks fehlen."))
	if not _snapshot_is_read_only(source_runtime_hook):
		blockers.append(_issue("source_not_read_only", "TASK_1013-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_trace_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_SMOKE_CHECKS:
		if not bool(trace.get(String(check_id), false)):
			missing.append(String(check_id))
	return missing


static func _completed_trace_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_SMOKE_CHECKS:
		if bool(trace.get(String(check_id), false)):
			completed.append(String(check_id))
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		issues.append(_issue("%s_missing" % check_id, "Scenario-Runtime-Smoke-Check fehlt: %s" % check_id))
	return issues


static func _trace_boundaries_clean(trace: Dictionary) -> bool:
	return not bool(trace.get("ui_sets_gameplay_truth", false)) \
		and not bool(trace.get("creates_command", false)) \
		and not bool(trace.get("creates_movement", false)) \
		and not bool(trace.get("sets_multiplayer_truth", false))


static func _boundary_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Smoke-Trace meldet UI-Gameplay-Wahrheit."))
	if bool(trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Smoke-Trace erzeugt selbst einen Command."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Smoke-Trace erzeugt Movement."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Smoke-Trace erzeugt Multiplayer-Wahrheit."))
	return issues


static func _build_smoke_line(trace: Dictionary, passed: bool, trace_available: bool) -> String:
	if not trace_available:
		return "ENTRY -> NEXT -> CONFIRM -> GO -> FEEDBACK | Smoke offen"
	var result_text: String = "PASS" if passed else "CHECK"
	var feedback: String = String(trace.get("post_smoke_feedback_line", "")).strip_edges()
	var line: String = "ENTRY -> NEXT -> CONFIRM -> GO -> FEEDBACK %s" % result_text
	if not feedback.is_empty():
		line += " | %s" % feedback
	return line


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
