class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundTripSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.v1"
const TASK_ID: String = "TASK_1001"
const SOURCE_TASK_ID: String = "TASK_1000"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_playability_slice.v1"
const NEXT_TASK: String = "TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice"
const PLAYABILITY_TASK: String = "TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice"

const REQUIRED_ROUND_TRIP_CHECKS: Array[String] = [
	"next_micro_objective_options_visible",
	"selected_next_micro_objective_confirmed",
	"confirm_feedback_visible",
	"go_still_separate",
	"no_auto_go_after_confirm",
	"go_executed_after_confirm",
	"post_round_trip_feedback_visible",
	"round_trip_returns_to_decision_state",
	"command_path_reused",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_playability: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_playability)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_trace_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "micro_objective_round_trip_blocked"
	var passed: bool = false
	var recommended_next_task: String = PLAYABILITY_TASK
	if source_ready:
		if not trace_available:
			status = "needs_micro_objective_round_trip_trace"
			gate = "needs_micro_objective_round_trip_trace"
			issues.append(_issue("micro_objective_round_trip_trace_missing", "Round-Trip-Trace fuer NEXT -> CONFIRM -> GO -> FEEDBACK fehlt."))
			recommended_next_task = "TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke"
		elif not missing_checks.is_empty():
			status = "micro_objective_round_trip_regression_found"
			gate = "micro_objective_round_trip_regression_found"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = PLAYABILITY_TASK
		else:
			status = "micro_objective_round_trip_smoke_passed"
			gate = "micro_objective_round_trip_smoke_passed"
			passed = true
			recommended_next_task = NEXT_TASK
	var completed_checks: Array = _completed_trace_checks(trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_playability.get("schema", "")),
		"source_status": String(source_playability.get("status", "")),
		"source_gate": String(source_playability.get("gate", "")),
		"source_passed": bool(source_playability.get("micro_objective_playability_slice_passed", false)),
		"source_micro_objective_playability_line": String(source_playability.get("micro_objective_playability_line", "")),
		"trace_available": trace_available,
		"selected_micro_objective_id": String(trace.get("selected_micro_objective_id", "")),
		"required_round_trip_checks": REQUIRED_ROUND_TRIP_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_round_trip_checks": missing_checks,
		"next_micro_objective_options_visible": bool(trace.get("next_micro_objective_options_visible", false)),
		"selected_next_micro_objective_confirmed": bool(trace.get("selected_next_micro_objective_confirmed", false)),
		"confirm_feedback_visible": bool(trace.get("confirm_feedback_visible", false)),
		"go_still_separate": bool(trace.get("go_still_separate", false)),
		"no_auto_go_after_confirm": bool(trace.get("no_auto_go_after_confirm", false)),
		"go_executed_after_confirm": bool(trace.get("go_executed_after_confirm", false)),
		"post_round_trip_feedback_visible": bool(trace.get("post_round_trip_feedback_visible", false)),
		"round_trip_returns_to_decision_state": bool(trace.get("round_trip_returns_to_decision_state", false)),
		"command_path_reused": bool(trace.get("command_path_reused", false)),
		"post_round_trip_feedback_line": String(trace.get("post_round_trip_feedback_line", "")),
		"round_trip_line": _build_round_trip_line(trace, passed, trace_available),
		"micro_objective_round_trip_smoke_passed": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_micro_objective_round_loop_playtest_slice" if passed else ("collect_micro_objective_round_trip_trace" if source_ready and not trace_available else "fix_micro_objective_round_trip"),
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


static func _build_blockers(source_playability: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_playability.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1000-Source-Schema fehlt oder passt nicht."))
	if String(source_playability.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1000."))
	if String(source_playability.get("status", "")) != "micro_objective_playability_slice_passed":
		blockers.append(_issue("source_not_passed", "TASK_1000-Source ist nicht bestanden."))
	if not bool(source_playability.get("micro_objective_playability_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1000-Source setzt den Pass-Flag nicht."))
	if String(source_playability.get("micro_objective_playability_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_playability_line_missing", "TASK_1000-Playability-Zeile fehlt."))
	if not _snapshot_is_read_only(source_playability):
		blockers.append(_issue("source_not_read_only", "TASK_1000-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_trace_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_ROUND_TRIP_CHECKS:
		if not bool(trace.get(check_id, false)):
			missing.append(check_id)
	return missing


static func _completed_trace_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_ROUND_TRIP_CHECKS:
		if bool(trace.get(check_id, false)):
			completed.append(check_id)
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		issues.append(_issue("%s_missing" % check_id, "Round-Trip-Check fehlt: %s" % check_id))
	return issues


static func _build_round_trip_line(trace: Dictionary, passed: bool, trace_available: bool) -> String:
	if not trace_available:
		return "NEXT -> CONFIRM -> GO -> FEEDBACK | Smoke offen"
	var result_text: String = "PASS" if passed else "CHECK"
	var feedback_line: String = String(trace.get("post_round_trip_feedback_line", "")).strip_edges()
	var line: String = "NEXT -> CONFIRM -> GO -> FEEDBACK %s" % result_text
	if not feedback_line.is_empty():
		line += " | %s" % feedback_line
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
