class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopPlaytestSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.v1"
const TASK_ID: String = "TASK_1002"
const SOURCE_TASK_ID: String = "TASK_1001"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.v1"
const NEXT_TASK: String = "TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish"
const ROUND_TRIP_TASK: String = "TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke"

const REQUIRED_ROUND_LOOP_CHECKS: Array[String] = [
	"first_round_completed",
	"first_round_feedback_visible",
	"second_round_next_options_visible",
	"second_round_choice_confirmed",
	"second_round_go_still_separate",
	"second_round_no_auto_go",
	"second_round_go_executed",
	"second_round_feedback_visible",
	"next_decision_after_second_round_visible",
	"no_feedback_dead_end",
	"hud_surfaces_stable",
	"command_path_reused",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_round_trip: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_round_trip)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_trace_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "micro_objective_round_loop_playtest_blocked"
	var passed: bool = false
	var recommended_next_task: String = ROUND_TRIP_TASK
	var completed_round_count: int = int(trace.get("completed_round_count", 0)) if trace_available else 0
	if source_ready:
		if not trace_available:
			status = "needs_micro_objective_round_loop_playtest_trace"
			gate = "needs_micro_objective_round_loop_playtest_trace"
			issues.append(_issue("micro_objective_round_loop_playtest_trace_missing", "Round-Loop-Playtest-Trace fuer zwei Micro-Objective-Runden fehlt."))
			recommended_next_task = "TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice"
		elif completed_round_count < 2:
			status = "micro_objective_round_loop_playtest_regression_found"
			gate = "micro_objective_round_loop_playtest_regression_found"
			missing_checks.append("completed_round_count_two")
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = ROUND_TRIP_TASK
		elif not missing_checks.is_empty():
			status = "micro_objective_round_loop_playtest_regression_found"
			gate = "micro_objective_round_loop_playtest_regression_found"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = ROUND_TRIP_TASK
		else:
			status = "micro_objective_round_loop_playtest_slice_passed"
			gate = "micro_objective_round_loop_playtest_slice_passed"
			passed = true
			recommended_next_task = NEXT_TASK
	var completed_checks: Array = _completed_trace_checks(trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_round_trip.get("schema", "")),
		"source_status": String(source_round_trip.get("status", "")),
		"source_gate": String(source_round_trip.get("gate", "")),
		"source_passed": bool(source_round_trip.get("micro_objective_round_trip_smoke_passed", false)),
		"source_round_trip_line": String(source_round_trip.get("round_trip_line", "")),
		"trace_available": trace_available,
		"completed_round_count": completed_round_count,
		"required_round_loop_checks": REQUIRED_ROUND_LOOP_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_round_loop_checks": missing_checks,
		"first_round_completed": bool(trace.get("first_round_completed", false)),
		"first_round_feedback_visible": bool(trace.get("first_round_feedback_visible", false)),
		"second_round_next_options_visible": bool(trace.get("second_round_next_options_visible", false)),
		"second_round_choice_confirmed": bool(trace.get("second_round_choice_confirmed", false)),
		"second_round_go_still_separate": bool(trace.get("second_round_go_still_separate", false)),
		"second_round_no_auto_go": bool(trace.get("second_round_no_auto_go", false)),
		"second_round_go_executed": bool(trace.get("second_round_go_executed", false)),
		"second_round_feedback_visible": bool(trace.get("second_round_feedback_visible", false)),
		"next_decision_after_second_round_visible": bool(trace.get("next_decision_after_second_round_visible", false)),
		"no_feedback_dead_end": bool(trace.get("no_feedback_dead_end", false)),
		"hud_surfaces_stable": bool(trace.get("hud_surfaces_stable", false)),
		"command_path_reused": bool(trace.get("command_path_reused", false)),
		"round_loop_feedback_line": String(trace.get("round_loop_feedback_line", "")),
		"round_loop_line": _build_round_loop_line(trace, passed, trace_available, completed_round_count),
		"micro_objective_round_loop_playtest_slice_passed": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "polish_micro_objective_round_loop_runtime" if passed else ("collect_micro_objective_round_loop_playtest_trace" if source_ready and not trace_available else "fix_micro_objective_round_loop_playtest"),
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


static func _build_blockers(source_round_trip: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_round_trip.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1001-Source-Schema fehlt oder passt nicht."))
	if String(source_round_trip.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1001."))
	if String(source_round_trip.get("status", "")) != "micro_objective_round_trip_smoke_passed":
		blockers.append(_issue("source_not_passed", "TASK_1001-Source ist nicht bestanden."))
	if not bool(source_round_trip.get("micro_objective_round_trip_smoke_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1001-Source setzt den Pass-Flag nicht."))
	if String(source_round_trip.get("round_trip_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_round_trip_line_missing", "TASK_1001-Round-Trip-Zeile fehlt."))
	if not bool(source_round_trip.get("round_trip_returns_to_decision_state", false)):
		blockers.append(_issue("source_decision_return_missing", "TASK_1001 bestaetigt den Ruecksprung in den Entscheidungszustand nicht."))
	if not _snapshot_is_read_only(source_round_trip):
		blockers.append(_issue("source_not_read_only", "TASK_1001-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_trace_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_ROUND_LOOP_CHECKS:
		if not bool(trace.get(check_id, false)):
			missing.append(check_id)
	return missing


static func _completed_trace_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_ROUND_LOOP_CHECKS:
		if bool(trace.get(check_id, false)):
			completed.append(check_id)
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		issues.append(_issue("%s_missing" % check_id, "Round-Loop-Playtest-Check fehlt: %s" % check_id))
	return issues


static func _build_round_loop_line(trace: Dictionary, passed: bool, trace_available: bool, completed_round_count: int) -> String:
	if not trace_available:
		return "ROUND 1 -> ROUND 2 | Playtest-Slice offen"
	var result_text: String = "PASS" if passed else "CHECK"
	var feedback_line: String = String(trace.get("round_loop_feedback_line", "")).strip_edges()
	var line: String = "ROUND 1 FEEDBACK -> ROUND 2 NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT %s (%d Runden)" % [result_text, completed_round_count]
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
