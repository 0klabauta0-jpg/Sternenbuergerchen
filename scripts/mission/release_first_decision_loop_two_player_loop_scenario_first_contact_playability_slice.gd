class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactPlayabilitySlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.v1"
const TASK_ID: String = "TASK_1037"
const SOURCE_TASK_ID: String = "TASK_1036"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.v1"
const NEXT_TASK: String = "TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture"
const POLISH_TASK: String = "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish"
const REVIEW_TASK: String = "TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"

const REQUIRED_FIRST_CONTACT_PLAYABILITY_CHECKS: Array[String] = [
	"contact_line_readable",
	"why_actionable",
	"next_grip_readable",
	"fire_wait_choice_readable",
	"go_stays_separate",
	"feedback_returns_to_next",
	"hud_stays_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_preserved",
	"no_gameplay_truth_mutation",
	"first_contact_feels_tactical",
]


static func build_snapshot(source_player_feel_polish: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_player_feel_polish)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(trace.get("trace_available", false))
	var missing_checks: Array = _missing_playability_checks(trace) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "first_contact_playability_blocked"
	var passed: bool = false
	var recommended_next_task: String = POLISH_TASK
	if source_ready:
		if not trace_available:
			status = "needs_first_contact_playability_trace"
			gate = "needs_first_contact_playability_trace"
			issues.append(_issue("first_contact_playability_trace_missing", "First-Contact-Playability braucht einen Trace fuer CONTACT, WHY, FIRE/WAIT, NEXT, GO und Feedback."))
			recommended_next_task = REVIEW_TASK
		elif not missing_checks.is_empty():
			status = "first_contact_playability_regression_found"
			gate = "first_contact_playability_regression"
			issues = _issues_for_missing_checks(missing_checks)
			recommended_next_task = POLISH_TASK
		else:
			status = "first_contact_playability_slice_passed"
			gate = "first_contact_playability_passed"
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
		"source_surface_spec_count": int(source_player_feel_polish.get("first_contact_player_feel_surface_spec_count", 0)),
		"source_first_contact_player_feel_polish_line": String(source_player_feel_polish.get("first_contact_player_feel_polish_line", "")),
		"source_first_contact_next_grip_line": String(source_player_feel_polish.get("first_contact_next_grip_line", "")),
		"source_first_contact_go_boundary_microcopy": String(source_player_feel_polish.get("first_contact_go_boundary_microcopy", "")),
		"source_first_contact_calm_hud_guidance": String(source_player_feel_polish.get("first_contact_calm_hud_guidance", "")),
		"source_first_contact_performance_feedback_hint": String(source_player_feel_polish.get("first_contact_performance_feedback_hint", "")),
		"first_contact_player_feel_surface_specs": Array(source_player_feel_polish.get("first_contact_player_feel_surface_specs", [])).duplicate(true),
		"trace_available": trace_available,
		"trace_id": String(trace.get("trace_id", "")),
		"required_playability_checks": REQUIRED_FIRST_CONTACT_PLAYABILITY_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_playability_checks": missing_checks,
		"first_contact_feedback_line": String(trace.get("first_contact_feedback_line", "")),
		"player_next_grip_line": String(trace.get("player_next_grip_line", "")),
		"answered_player_questions": _answered_player_questions() if passed else [],
		"first_contact_playability_line": _build_playability_line(source_player_feel_polish, trace) if passed else "",
		"first_contact_playability_slice_passed": passed,
		"ready_for_first_contact_real_window_capture": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_first_contact_real_window_capture" if passed else ("collect_first_contact_playability_trace" if source_ready and not trace_available else "fix_first_contact_playability"),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1036-Source-Schema fehlt oder passt nicht."))
	if String(source_player_feel_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1036."))
	if String(source_player_feel_polish.get("status", "")) != "first_contact_player_feel_polish_ready":
		blockers.append(_issue("source_not_ready", "TASK_1036-Source ist nicht first_contact_player_feel_polish_ready."))
	if not bool(source_player_feel_polish.get("active", false)):
		blockers.append(_issue("source_inactive", "TASK_1036-Source ist nicht aktiv."))
	if int(source_player_feel_polish.get("first_contact_player_feel_surface_spec_count", 0)) < 6:
		blockers.append(_issue("first_contact_player_feel_surfaces_missing", "TASK_1036 liefert nicht alle sechs First-Contact-Surfaces."))
	var polish_line: String = String(source_player_feel_polish.get("first_contact_player_feel_polish_line", "")).strip_edges()
	if polish_line.is_empty():
		blockers.append(_issue("first_contact_player_feel_polish_line_missing", "TASK_1036-Polish-Zeile fehlt."))
	if not polish_line.contains("CONTACT") or not polish_line.contains("WHY") or not polish_line.contains("NEXT") or not polish_line.contains("GO"):
		blockers.append(_issue("first_contact_player_feel_polish_line_incomplete", "TASK_1036-Polish-Zeile muss CONTACT, WHY, NEXT und GO nennen."))
	if not _snapshot_is_read_only(source_player_feel_polish):
		blockers.append(_issue("source_not_read_only", "TASK_1036-Source verletzt die read-only-Grenze."))
	return blockers


static func _missing_playability_checks(trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_FIRST_CONTACT_PLAYABILITY_CHECKS:
		if not bool(trace.get(check_id, false)):
			missing.append(check_id)
	return missing


static func _completed_playability_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_FIRST_CONTACT_PLAYABILITY_CHECKS:
		if bool(trace.get(check_id, false)):
			completed.append(check_id)
	return completed


static func _issues_for_missing_checks(missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		issues.append(_issue(_issue_id_for_missing_check(check_id), "First-Contact-Playability-Check fehlt: %s" % check_id))
	return issues


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"fire_wait_choice_readable":
			return "fire_wait_choice_missing"
		"feedback_returns_to_next":
			return "feedback_does_not_return_to_next"
		"go_stays_separate":
			return "go_boundary_lost"
		"performance_feels_responsive":
			return "first_contact_performance_not_responsive"
		"multiplayer_boundary_preserved":
			return "multiplayer_boundary_lost"
		"no_gameplay_truth_mutation":
			return "gameplay_truth_mutated"
		_:
			return "%s_missing" % check_id


static func _answered_player_questions() -> Array:
	return [
		"who_has_contact",
		"why_this_move_matters",
		"fire_or_wait_choice",
		"what_happens_only_after_go",
		"what_is_next_after_feedback",
		"who_owns_truth",
	]


static func _build_playability_line(source_player_feel_polish: Dictionary, trace: Dictionary) -> String:
	var polish_line: String = String(source_player_feel_polish.get("first_contact_player_feel_polish_line", "")).strip_edges()
	var feedback_line: String = String(trace.get("first_contact_feedback_line", "")).strip_edges()
	var base_line: String = polish_line if not polish_line.is_empty() else "CONTACT | WHY | NEXT | GO separat"
	var suffix: String = feedback_line if not feedback_line.is_empty() else "FEEDBACK zurueck zu NEXT"
	return "FIRST CONTACT PASS: %s | FIRE/WAIT lesbar | FEEDBACK %s" % [
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
