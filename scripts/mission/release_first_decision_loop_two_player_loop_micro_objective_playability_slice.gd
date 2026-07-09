class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectivePlayabilitySlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_playability_slice.v1"
const TASK_ID: String = "TASK_1000"
const SOURCE_TASK_ID: String = "TASK_999"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_visual_polish.v1"
const NEXT_TASK: String = "TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke"
const POLISH_TASK: String = "TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish"

const REQUIRED_TRACE_CHECKS: Array[String] = [
	"micro_objective_outcome_visible",
	"mini_objective_state_visible",
	"next_step_visible",
	"player_understands_micro_objective_result",
	"player_understands_next_grip",
	"post_micro_objective_feedback_visible",
	"go_boundary_preserved",
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
	var gate: String = "micro_objective_playability_blocked"
	var passed: bool = false
	var recommended_next_task: String = POLISH_TASK
	if source_ready:
		if not trace_available:
			status = "needs_micro_objective_playability_trace"
			gate = "needs_micro_objective_playability_trace"
			issues.append(_issue("micro_objective_playability_trace_missing", "Micro-Objective-Playability braucht einen Trace mit OUTCOME/OBJ/NEXT-Lesung."))
			recommended_next_task = "TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice"
		elif not missing_checks.is_empty():
			status = "micro_objective_playability_regression_found"
			gate = "micro_objective_playability_regression_found"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = POLISH_TASK
		else:
			status = "micro_objective_playability_slice_passed"
			gate = "micro_objective_playability_slice_passed"
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
		"source_surface_spec_count": int(source_visual_polish.get("micro_objective_surface_spec_count", 0)),
		"source_micro_objective_polish_line": String(source_visual_polish.get("micro_objective_polish_line", "")),
		"micro_objective_surface_specs": Array(source_visual_polish.get("micro_objective_surface_specs", [])).duplicate(true),
		"micro_objective_outcome_surface": Dictionary(source_visual_polish.get("micro_objective_outcome_surface", {})).duplicate(true),
		"mini_objective_surface": Dictionary(source_visual_polish.get("mini_objective_surface", {})).duplicate(true),
		"next_step_surface": Dictionary(source_visual_polish.get("next_step_surface", {})).duplicate(true),
		"trace_available": trace_available,
		"selected_micro_objective_id": String(trace.get("selected_micro_objective_id", "")),
		"required_playability_checks": REQUIRED_TRACE_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_playability_checks": missing_checks,
		"post_micro_objective_feedback_line": String(trace.get("post_micro_objective_feedback_line", "")),
		"player_next_grip_line": String(trace.get("player_next_grip_line", "")),
		"answered_player_questions": _answered_player_questions() if passed else [],
		"micro_objective_playability_line": _build_playability_line(source_visual_polish) if passed else "",
		"micro_objective_playability_slice_passed": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_micro_objective_round_trip_smoke" if passed else ("collect_micro_objective_playability_trace" if source_ready and not trace_available else "fix_micro_objective_readability"),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_999-Source-Schema fehlt oder passt nicht."))
	if String(source_visual_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_999."))
	if String(source_visual_polish.get("status", "")) != "micro_objective_visual_polish_ready":
		blockers.append(_issue("source_not_ready", "TASK_999-Source ist nicht micro_objective_visual_polish_ready."))
	if not bool(source_visual_polish.get("active", false)):
		blockers.append(_issue("source_inactive", "TASK_999-Source ist nicht aktiv."))
	if int(source_visual_polish.get("micro_objective_surface_spec_count", 0)) < 3:
		blockers.append(_issue("surface_specs_missing", "TASK_999 liefert nicht alle drei Micro-Objective-Surfaces."))
	if String(source_visual_polish.get("micro_objective_polish_line", "")).strip_edges().is_empty():
		blockers.append(_issue("micro_objective_polish_line_missing", "TASK_999-Polish-Zeile fehlt."))
	if not _snapshot_is_read_only(source_visual_polish):
		blockers.append(_issue("source_not_read_only", "TASK_999-Source verletzt die read-only-Grenze."))
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
		issues.append(_issue("%s_missing" % check_id, "Micro-Objective-Playability-Check fehlt: %s" % check_id))
	return issues


static func _answered_player_questions() -> Array:
	return [
		"what_happened",
		"what_changed",
		"what_next",
		"who_owns_truth",
		"what_requires_go",
	]


static func _build_playability_line(source_visual_polish: Dictionary) -> String:
	var polish_line: String = String(source_visual_polish.get("micro_objective_polish_line", "")).strip_edges()
	if polish_line.is_empty():
		return "MICRO PASS: OUTCOME/OBJ/NEXT lesbar | naechster Griff bereit"
	return "MICRO PASS: %s" % _compact_text(polish_line, 112)


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
