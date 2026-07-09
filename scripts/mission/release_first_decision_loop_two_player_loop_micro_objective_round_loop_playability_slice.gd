class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopPlayabilitySlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.v1"
const TASK_ID: String = "TASK_1007"
const SOURCE_TASK_ID: String = "TASK_1006"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.v1"
const NEXT_TASK: String = "TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest"
const POLISH_TASK: String = "TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish"

const REQUIRED_PLAYABILITY_CHECKS: Array[String] = [
	"round_surface_readable",
	"next_surface_readable",
	"go_surface_readable",
	"runtime_lines_readable",
	"next_decision_understood",
	"confirm_available",
	"go_separation_preserved",
	"feedback_returns_to_next",
	"no_command_before_confirm",
	"no_auto_go",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_visual_polish: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_visual_polish)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_playability_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "round_loop_playability_blocked"
	var passed: bool = false
	var recommended_next_task: String = POLISH_TASK
	if source_ready:
		if not trace_available:
			status = "needs_round_loop_playability_trace"
			gate = "needs_round_loop_playability_trace"
			issues.append(_issue("round_loop_playability_trace_missing", "Round-Loop-Playability braucht einen Trace mit ROUND/NEXT/GO/FEEDBACK-Lesung."))
			recommended_next_task = "TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"
		elif not missing_checks.is_empty():
			status = "round_loop_playability_regression_found"
			gate = "round_loop_playability_regression"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = POLISH_TASK
		else:
			status = "round_loop_playability_slice_passed"
			gate = "round_loop_playability_passed"
			passed = true
			recommended_next_task = NEXT_TASK
	var completed_checks: Array = _completed_playability_checks(trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_visual_polish.get("schema", "")),
		"source_status": String(source_visual_polish.get("status", "")),
		"source_active": bool(source_visual_polish.get("active", false)),
		"source_surface_spec_count": int(source_visual_polish.get("round_loop_surface_spec_count", 0)),
		"source_round_loop_polish_line": String(source_visual_polish.get("round_loop_polish_line", "")),
		"round_loop_surface_specs": Array(source_visual_polish.get("round_loop_surface_specs", [])).duplicate(true),
		"round_surface": Dictionary(source_visual_polish.get("round_surface", {})).duplicate(true),
		"next_surface": Dictionary(source_visual_polish.get("next_surface", {})).duplicate(true),
		"go_surface": Dictionary(source_visual_polish.get("go_surface", {})).duplicate(true),
		"trace_available": trace_available,
		"trace_id": String(trace.get("trace_id", "")),
		"completed_round_count": int(trace.get("completed_round_count", 0)),
		"required_playability_checks": REQUIRED_PLAYABILITY_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_playability_checks": missing_checks,
		"round_loop_feedback_line": String(trace.get("round_loop_feedback_line", "")),
		"player_next_decision_line": String(trace.get("player_next_decision_line", "")),
		"answered_player_questions": _answered_player_questions() if passed else [],
		"round_loop_playability_line": _build_playability_line(source_visual_polish, trace) if passed else "",
		"round_loop_playability_slice_passed": passed,
		"ready_for_integrated_playtest": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_round_loop_integrated_playtest" if passed else ("collect_round_loop_playability_trace" if source_ready and not trace_available else "fix_round_loop_readability"),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1006-Source-Schema fehlt oder passt nicht."))
	if String(source_visual_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1006."))
	if String(source_visual_polish.get("status", "")) != "round_loop_visual_polish_ready":
		blockers.append(_issue("source_not_ready", "TASK_1006-Source ist nicht round_loop_visual_polish_ready."))
	if not bool(source_visual_polish.get("active", false)):
		blockers.append(_issue("source_inactive", "TASK_1006-Source ist nicht aktiv."))
	if int(source_visual_polish.get("round_loop_surface_spec_count", 0)) < 6:
		blockers.append(_issue("round_loop_surface_specs_missing", "TASK_1006 liefert nicht alle sechs Round-Loop-Surfaces."))
	var polish_line: String = String(source_visual_polish.get("round_loop_polish_line", "")).strip_edges()
	if polish_line.is_empty():
		blockers.append(_issue("round_loop_polish_line_missing", "TASK_1006-Polish-Zeile fehlt."))
	if not polish_line.contains("ROUND") or not polish_line.contains("NEXT") or not polish_line.contains("GO"):
		blockers.append(_issue("round_loop_polish_line_incomplete", "TASK_1006-Polish-Zeile muss ROUND, NEXT und GO nennen."))
	if not _snapshot_is_read_only(source_visual_polish):
		blockers.append(_issue("source_not_read_only", "TASK_1006-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_playability_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_PLAYABILITY_CHECKS:
		if not bool(trace.get(check_id, false)):
			missing.append(check_id)
	return missing


static func _completed_playability_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_PLAYABILITY_CHECKS:
		if bool(trace.get(check_id, false)):
			completed.append(check_id)
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		var issue_id: String = _issue_id_for_missing_check(check_id)
		issues.append(_issue(issue_id, "Round-Loop-Playability-Check fehlt: %s" % check_id))
	return issues


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"next_decision_understood":
			return "next_decision_not_understood"
		"go_separation_preserved":
			return "go_separation_lost"
		"feedback_returns_to_next":
			return "feedback_does_not_return_to_next"
		_:
			return "%s_missing" % check_id


static func _answered_player_questions() -> Array:
	return [
		"what_round_finished",
		"what_next_decision",
		"what_requires_go",
		"what_feedback_changed",
		"who_owns_truth",
	]


static func _build_playability_line(source_visual_polish: Dictionary, trace: Dictionary) -> String:
	var polish_line: String = String(source_visual_polish.get("round_loop_polish_line", "")).strip_edges()
	var feedback_line: String = String(trace.get("round_loop_feedback_line", "")).strip_edges()
	var base_line: String = polish_line if not polish_line.is_empty() else "ROUND gelesen | NEXT bereit | GO separat"
	var suffix: String = feedback_line if not feedback_line.is_empty() else "FEEDBACK zurueck zu NEXT"
	return "ROUND LOOP PASS: %s | FEEDBACK %s" % [
		_compact_text(base_line, 96),
		_compact_text(suffix, 42),
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
