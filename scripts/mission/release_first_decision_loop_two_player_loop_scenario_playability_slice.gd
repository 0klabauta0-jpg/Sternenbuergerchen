class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioPlayabilitySlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_playability_slice.v1"
const TASK_ID: String = "TASK_1017"
const SOURCE_TASK_ID: String = "TASK_1016"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_player_feel_polish.v1"
const NEXT_TASK: String = "TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture"
const POLISH_TASK: String = "TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish"
const REVIEW_TASK: String = "TASK_1017 - Release First Decision Loop Two Player Loop Scenario Playability Slice"

const REQUIRED_PLAYABILITY_CHECKS: Array[String] = [
	"fob_entry_readable",
	"objective_readable",
	"two_player_roles_readable",
	"next_confirm_go_flow_readable",
	"go_stays_separate",
	"feedback_returns_to_next",
	"hud_stays_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_preserved",
	"no_gameplay_truth_mutation",
]


static func build_snapshot(source_player_feel_polish: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_player_feel_polish)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_playability_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "scenario_playability_blocked"
	var passed: bool = false
	var recommended_next_task: String = POLISH_TASK
	if source_ready:
		if not trace_available:
			status = "needs_scenario_playability_trace"
			gate = "needs_scenario_playability_trace"
			issues.append(_issue("scenario_playability_trace_missing", "Scenario-Playability braucht einen Trace fuer FOB, Rollen, NEXT, GO und Feedback."))
			recommended_next_task = REVIEW_TASK
		elif not missing_checks.is_empty():
			status = "scenario_playability_regression_found"
			gate = "scenario_playability_regression"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = POLISH_TASK
		else:
			status = "scenario_playability_slice_passed"
			gate = "scenario_playability_passed"
			passed = true
			recommended_next_task = NEXT_TASK
	var completed_checks: Array = _completed_playability_checks(trace) if trace_available else []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_player_feel_polish.get("schema", "")),
		"source_status": String(source_player_feel_polish.get("status", "")),
		"source_active": bool(source_player_feel_polish.get("active", false)),
		"source_surface_spec_count": int(source_player_feel_polish.get("scenario_player_feel_surface_spec_count", 0)),
		"source_scenario_player_feel_polish_line": String(source_player_feel_polish.get("scenario_player_feel_polish_line", "")),
		"source_scenario_next_grip_line": String(source_player_feel_polish.get("scenario_next_grip_line", "")),
		"source_scenario_go_boundary_microcopy": String(source_player_feel_polish.get("scenario_go_boundary_microcopy", "")),
		"source_scenario_calm_hud_guidance": String(source_player_feel_polish.get("scenario_calm_hud_guidance", "")),
		"source_scenario_performance_feedback_hint": String(source_player_feel_polish.get("scenario_performance_feedback_hint", "")),
		"scenario_player_feel_surface_specs": Array(source_player_feel_polish.get("scenario_player_feel_surface_specs", [])).duplicate(true),
		"trace_available": trace_available,
		"trace_id": String(trace.get("trace_id", "")),
		"required_playability_checks": REQUIRED_PLAYABILITY_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_playability_checks": missing_checks,
		"scenario_feedback_line": String(trace.get("scenario_feedback_line", "")),
		"player_next_grip_line": String(trace.get("player_next_grip_line", "")),
		"answered_player_questions": _answered_player_questions() if passed else [],
		"scenario_playability_line": _build_playability_line(source_player_feel_polish, trace) if passed else "",
		"scenario_playability_slice_passed": passed,
		"ready_for_real_window_capture": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_scenario_real_window_capture" if passed else ("collect_scenario_playability_trace" if source_ready and not trace_available else "fix_scenario_playability"),
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


static func _build_blockers(source_player_feel_polish: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_player_feel_polish.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1016-Source-Schema fehlt oder passt nicht."))
	if String(source_player_feel_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1016."))
	if String(source_player_feel_polish.get("status", "")) != "scenario_player_feel_polish_ready":
		blockers.append(_issue("source_not_ready", "TASK_1016-Source ist nicht scenario_player_feel_polish_ready."))
	if not bool(source_player_feel_polish.get("active", false)):
		blockers.append(_issue("source_inactive", "TASK_1016-Source ist nicht aktiv."))
	if int(source_player_feel_polish.get("scenario_player_feel_surface_spec_count", 0)) < 7:
		blockers.append(_issue("scenario_player_feel_surfaces_missing", "TASK_1016 liefert nicht alle sieben Scenario-Surfaces."))
	var polish_line: String = String(source_player_feel_polish.get("scenario_player_feel_polish_line", "")).strip_edges()
	if polish_line.is_empty():
		blockers.append(_issue("scenario_player_feel_polish_line_missing", "TASK_1016-Polish-Zeile fehlt."))
	if not polish_line.contains("FOB") or not polish_line.contains("NEXT") or not polish_line.contains("GO"):
		blockers.append(_issue("scenario_player_feel_polish_line_incomplete", "TASK_1016-Polish-Zeile muss FOB, NEXT und GO nennen."))
	if not _snapshot_is_read_only(source_player_feel_polish):
		blockers.append(_issue("source_not_read_only", "TASK_1016-Source verletzt die read-only-Grenze."))
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
		issues.append(_issue(_issue_id_for_missing_check(check_id), "Scenario-Playability-Check fehlt: %s" % check_id))
	return issues


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"feedback_returns_to_next":
			return "feedback_does_not_return_to_next"
		"go_stays_separate":
			return "go_boundary_lost"
		"performance_feels_responsive":
			return "scenario_performance_not_responsive"
		"multiplayer_boundary_preserved":
			return "multiplayer_boundary_lost"
		"no_gameplay_truth_mutation":
			return "gameplay_truth_mutated"
		_:
			return "%s_missing" % check_id


static func _answered_player_questions() -> Array:
	return [
		"where_am_i",
		"what_is_objective",
		"what_do_alpha_bravo_do",
		"what_happens_only_after_go",
		"what_is_next_after_feedback",
		"who_owns_truth",
	]


static func _build_playability_line(source_player_feel_polish: Dictionary, trace: Dictionary) -> String:
	var polish_line: String = String(source_player_feel_polish.get("scenario_player_feel_polish_line", "")).strip_edges()
	var feedback_line: String = String(trace.get("scenario_feedback_line", "")).strip_edges()
	var base_line: String = polish_line if not polish_line.is_empty() else "FOB gelesen | NEXT bereit | GO separat"
	var suffix: String = feedback_line if not feedback_line.is_empty() else "FEEDBACK zurueck zu NEXT"
	return "SCENARIO PASS: %s | FEEDBACK %s" % [
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
