class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopIntegratedPlaytest
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.v1"
const TASK_ID: String = "TASK_1008"
const SOURCE_TASK_ID: String = "TASK_1007"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.v1"
const NEXT_TASK: String = "TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings"
const PLAYABILITY_TASK: String = "TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"

const REQUIRED_INTEGRATED_CHECKS: Array[String] = [
	"release_mission_context_reached",
	"command_feedback_embeds_playability_slice",
	"round_surface_read_in_context",
	"next_decision_selected_in_context",
	"confirm_path_reused",
	"go_path_reused",
	"go_separation_observed",
	"post_go_feedback_observed",
	"feedback_returns_to_next",
	"no_command_before_confirm",
	"no_auto_go",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
	"performance_budget_ok",
]


static func build_snapshot(source_playability_slice: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_playability_slice)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_integrated_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "round_loop_integrated_playtest_blocked"
	var passed: bool = false
	var recommended_next_task: String = PLAYABILITY_TASK
	if source_ready:
		if not trace_available:
			status = "needs_round_loop_integrated_playtest_trace"
			gate = "needs_round_loop_integrated_playtest_trace"
			issues.append(_issue("round_loop_integrated_playtest_trace_missing", "Integrated-Playtest braucht einen Trace aus Release-/Mission-Kontext, Command Feedback, GO und FEEDBACK."))
			recommended_next_task = "TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest"
		elif not missing_checks.is_empty():
			status = "round_loop_integrated_playtest_regression_found"
			gate = "round_loop_integrated_playtest_regression"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = PLAYABILITY_TASK
		else:
			status = "round_loop_integrated_playtest_passed"
			gate = "round_loop_integrated_playtest_passed"
			passed = true
			recommended_next_task = NEXT_TASK
	var completed_checks: Array = _completed_integrated_checks(trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_playability_slice.get("schema", "")),
		"source_status": String(source_playability_slice.get("status", "")),
		"source_gate": String(source_playability_slice.get("gate", "")),
		"source_ready_for_integrated_playtest": bool(source_playability_slice.get("ready_for_integrated_playtest", false)),
		"source_round_loop_playability_line": String(source_playability_slice.get("round_loop_playability_line", "")),
		"trace_available": trace_available,
		"trace_id": String(trace.get("trace_id", "")),
		"required_integrated_checks": REQUIRED_INTEGRATED_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_integrated_checks": missing_checks,
		"entry_line": String(trace.get("entry_line", "")),
		"post_go_line": String(trace.get("post_go_line", "")),
		"observed_frame_budget_ms": float(trace.get("observed_frame_budget_ms", 0.0)),
		"answered_player_questions": _answered_player_questions() if passed else [],
		"integrated_playtest_line": _build_integrated_line(source_playability_slice, trace) if passed else "",
		"round_loop_integrated_playtest_passed": passed,
		"ready_for_player_feel_findings": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "collect_round_loop_player_feel_findings" if passed else ("collect_round_loop_integrated_playtest_trace" if source_ready and not trace_available else "fix_round_loop_integrated_playtest_path"),
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


static func _build_blockers(source_playability_slice: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_playability_slice.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1007-Source-Schema fehlt oder passt nicht."))
	if String(source_playability_slice.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1007."))
	if String(source_playability_slice.get("status", "")) != "round_loop_playability_slice_passed":
		blockers.append(_issue("source_not_passed", "TASK_1007-Source ist nicht round_loop_playability_slice_passed."))
	if not bool(source_playability_slice.get("round_loop_playability_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1007-Pass-Flag fehlt."))
	if not bool(source_playability_slice.get("ready_for_integrated_playtest", false)):
		blockers.append(_issue("source_not_ready_for_integrated_playtest", "TASK_1007 ist nicht fuer den integrierten Playtest freigegeben."))
	if String(source_playability_slice.get("round_loop_playability_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_playability_line_missing", "TASK_1007-Playability-Zeile fehlt."))
	if not _snapshot_is_read_only(source_playability_slice):
		blockers.append(_issue("source_not_read_only", "TASK_1007-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_integrated_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_INTEGRATED_CHECKS:
		if not bool(trace.get(check_id, false)):
			missing.append(check_id)
	return missing


static func _completed_integrated_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_INTEGRATED_CHECKS:
		if bool(trace.get(check_id, false)):
			completed.append(check_id)
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		var issue_id: String = _issue_id_for_missing_check(check_id)
		issues.append(_issue(issue_id, "Round-Loop-Integrated-Playtest-Check fehlt: %s" % check_id))
	return issues


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"release_mission_context_reached":
			return "release_mission_context_missing"
		"post_go_feedback_observed":
			return "post_go_feedback_missing"
		"performance_budget_ok":
			return "performance_budget_exceeded"
		_:
			return "%s_missing" % check_id


static func _answered_player_questions() -> Array:
	return [
		"where_did_player_start",
		"what_was_confirmed",
		"what_happened_after_go",
		"did_it_return_to_next",
		"were_boundaries_preserved",
	]


static func _build_integrated_line(source_playability_slice: Dictionary, trace: Dictionary) -> String:
	var source_line: String = String(source_playability_slice.get("round_loop_playability_line", "")).strip_edges()
	var entry_line: String = String(trace.get("entry_line", "")).strip_edges()
	var post_go_line: String = String(trace.get("post_go_line", "")).strip_edges()
	var compact_source: String = _compact_text(source_line if not source_line.is_empty() else "ROUND | NEXT | GO | FEEDBACK", 78)
	var compact_entry: String = _compact_text(entry_line if not entry_line.is_empty() else "ENTRY Mission", 32)
	var compact_feedback: String = _compact_text(post_go_line if not post_go_line.is_empty() else "FEEDBACK NEXT bereit", 38)
	return "ENTRY %s | %s | FEEDBACK %s" % [
		compact_entry,
		compact_source,
		compact_feedback,
	]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


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
