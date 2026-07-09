class_name ReleaseFirstDecisionLoopTwoPlayerLoopOutcomePlayabilitySlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_playability_slice.v1"
const TASK_ID: String = "TASK_989"
const SOURCE_TASK_ID: String = "TASK_988"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_visual_polish.v1"
const NEXT_TASK: String = "TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective"
const POLISH_TASK: String = "TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish"

const REQUIRED_TRACE_CHECKS: Array[String] = [
	"outcome_result_visible",
	"mini_objective_state_visible",
	"next_step_visible",
	"player_understands_result",
	"player_understands_next_action",
	"post_choice_feedback_visible",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
	"no_extra_command_created",
	"surface_specs_reused",
]


static func build_snapshot(source_visual_polish: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_visual_polish)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_trace_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "outcome_playability_blocked"
	var passed: bool = false
	var recommended_next_task: String = POLISH_TASK
	if source_ready:
		if not trace_available:
			status = "needs_outcome_playability_trace"
			gate = "needs_outcome_playability_trace"
			issues.append(_issue("outcome_playability_trace_missing", "Outcome-Playability braucht einen Trace mit RESULT/OBJ/NEXT-Lesung."))
			recommended_next_task = "TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice"
		elif not missing_checks.is_empty():
			status = "outcome_playability_regression_found"
			gate = "outcome_playability_regression_found"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = POLISH_TASK
		else:
			status = "outcome_playability_slice_passed"
			gate = "outcome_playability_slice_passed"
			passed = true
			recommended_next_task = NEXT_TASK
	var completed_checks: Array = _completed_trace_checks(trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_visual_polish.get("schema", "")),
		"source_status": String(source_visual_polish.get("status", "")),
		"source_active": bool(source_visual_polish.get("active", false)),
		"source_surface_spec_count": int(source_visual_polish.get("outcome_surface_spec_count", 0)),
		"source_outcome_polish_line": String(source_visual_polish.get("outcome_polish_line", "")),
		"outcome_surface_specs": Array(source_visual_polish.get("outcome_surface_specs", [])).duplicate(true),
		"outcome_line_surface": Dictionary(source_visual_polish.get("outcome_line_surface", {})).duplicate(true),
		"mini_objective_surface": Dictionary(source_visual_polish.get("mini_objective_surface", {})).duplicate(true),
		"next_step_surface": Dictionary(source_visual_polish.get("next_step_surface", {})).duplicate(true),
		"trace_available": trace_available,
		"selected_choice_id": String(trace.get("selected_choice_id", "")),
		"required_playability_checks": REQUIRED_TRACE_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_playability_checks": missing_checks,
		"post_choice_feedback_line": String(trace.get("post_choice_feedback_line", "")),
		"player_next_action_line": String(trace.get("player_next_action_line", "")),
		"answered_player_questions": _answered_player_questions() if passed else [],
		"outcome_playability_line": _build_playability_line(source_visual_polish) if passed else "",
		"outcome_playability_slice_passed": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_next_micro_objective" if passed else ("collect_outcome_playability_trace" if source_ready and not trace_available else "fix_outcome_readability"),
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


static func _build_blockers(source_visual_polish: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_visual_polish.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_988-Source-Schema fehlt oder passt nicht."))
	if String(source_visual_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_988."))
	if String(source_visual_polish.get("status", "")) != "outcome_visual_polish_ready":
		blockers.append(_issue("source_not_ready", "TASK_988-Source ist nicht outcome_visual_polish_ready."))
	if not bool(source_visual_polish.get("active", false)):
		blockers.append(_issue("source_inactive", "TASK_988-Source ist nicht aktiv."))
	if int(source_visual_polish.get("outcome_surface_spec_count", 0)) < 3:
		blockers.append(_issue("surface_specs_missing", "TASK_988 liefert nicht alle drei Outcome-Surfaces."))
	if String(source_visual_polish.get("outcome_polish_line", "")).strip_edges().is_empty():
		blockers.append(_issue("outcome_polish_line_missing", "TASK_988-Polish-Zeile fehlt."))
	if not _snapshot_is_read_only(source_visual_polish):
		blockers.append(_issue("source_not_read_only", "TASK_988-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_trace_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_TRACE_CHECKS:
		if not bool(trace.get(check_id, false)):
			missing.append(check_id)
	return missing


static func _completed_trace_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_TRACE_CHECKS:
		if bool(trace.get(check_id, false)):
			completed.append(check_id)
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		issues.append(_issue("%s_missing" % check_id, "Outcome-Playability-Check fehlt: %s" % check_id))
	return issues


static func _answered_player_questions() -> Array:
	return [
		"what_happened",
		"what_changed",
		"what_next",
		"who_owns_truth",
	]


static func _build_playability_line(source_visual_polish: Dictionary) -> String:
	var polish_line: String = String(source_visual_polish.get("outcome_polish_line", "")).strip_edges()
	if polish_line.is_empty():
		return "OUTCOME PASS: RESULT/OBJ/NEXT lesbar | naechster Griff bereit"
	return "OUTCOME PASS: %s" % _compact_text(polish_line, 104)


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
