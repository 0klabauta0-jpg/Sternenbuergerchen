class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_acceptance_slice.v1"
const TASK_ID: String = "TASK_1020"
const SOURCE_TASK_ID: String = "TASK_1019"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visual_findings.v1"
const REVIEW_TASK: String = "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice"
const POLISH_TASK: String = "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish"
const NEXT_TASK: String = "TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"fob_entry_readable",
	"objective_readable",
	"roles_readable",
	"next_confirm_go_loop_clear",
	"feedback_returns_to_next",
	"go_boundary_clear",
	"hud_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_preserved",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(source_findings: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_findings.duplicate(true)
	var trace: Dictionary = acceptance_trace.duplicate(true)
	var blockers: Array = _build_source_blockers(source)
	var trace_available: bool = bool(trace.get("trace_available", false)) or not trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("scenario_acceptance_trace_missing", "TASK_1020-Acceptance-Trace fuer den FOB-Szenario-Griff fehlt."))
		else:
			issues = _build_trace_issues(trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_scenario_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "scenario_acceptance_slice_passed"
			gate = "scenario_acceptance_slice_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "run_scenario_integrated_playtest"
		elif trace_available:
			status = "scenario_acceptance_regression_found"
			gate = "scenario_acceptance_regression_found"
			recommended_next_task = POLISH_TASK
			recommended_direction = "tighten_scenario_visual_polish"
		else:
			status = "needs_scenario_acceptance_trace"
			gate = "needs_scenario_acceptance_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_scenario_acceptance_trace"
	var answered_questions: Array = Array(trace.get("answered_player_questions", [])).duplicate(true)
	var completed_checks: Array = Array(trace.get("completed_checks", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_accepted": bool(source.get("accepted", false)),
		"source_issue_count": int(source.get("issue_count", -1)),
		"source_positive_finding_count": int(source.get("positive_finding_count", 0)),
		"source_scenario_playability_line": String(source.get("source_scenario_playability_line", "")),
		"source_scenario_playability_slice_passed": bool(source.get("source_scenario_playability_slice_passed", false)),
		"source_review_notes": Dictionary(source.get("review_notes", {})).duplicate(true),
		"trace_available": trace_available,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"completed_checks": completed_checks,
		"missing_acceptance_checks": _missing_checks(completed_checks),
		"fob_entry_readable": bool(trace.get("fob_entry_readable", false)),
		"objective_readable": bool(trace.get("objective_readable", false)),
		"roles_readable": bool(trace.get("roles_readable", false)),
		"next_confirm_go_loop_clear": bool(trace.get("next_confirm_go_loop_clear", false)),
		"feedback_returns_to_next": bool(trace.get("feedback_returns_to_next", false)),
		"go_boundary_clear": bool(trace.get("go_boundary_clear", false)),
		"hud_calm": bool(trace.get("hud_calm", false)),
		"performance_feels_responsive": bool(trace.get("performance_feels_responsive", false)),
		"multiplayer_boundary_preserved": bool(trace.get("multiplayer_boundary_preserved", false)),
		"no_new_hud_gameplay_truth": bool(trace.get("no_new_hud_gameplay_truth", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"scenario_acceptance_line": _build_acceptance_line(source, passed, trace_available),
		"scenario_acceptance_slice_passed": passed,
		"ready_for_integrated_playtest": passed,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_source_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1019-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1019."))
	if String(source.get("status", "")) != "accepted_for_scenario_acceptance_slice":
		blockers.append(_issue("source_not_accepted_for_scenario_acceptance", "TASK_1019-Source ist nicht fuer Scenario Acceptance akzeptiert."))
	if not bool(source.get("accepted", false)):
		blockers.append(_issue("source_accepted_flag_missing", "TASK_1019-Source setzt accepted nicht."))
	if int(source.get("issue_count", 1)) != 0:
		blockers.append(_issue("source_has_visual_issues", "TASK_1019-Source enthaelt noch Visual-Issues."))
	if int(source.get("positive_finding_count", 0)) < 12:
		blockers.append(_issue("source_positive_findings_too_low", "TASK_1019-Source enthaelt zu wenige positive Sichtbefunde."))
	var playability_line: String = String(source.get("source_scenario_playability_line", "")).strip_edges()
	if playability_line.is_empty():
		blockers.append(_issue("source_scenario_playability_line_missing", "TASK_1019-Source enthaelt keine Scenario-Playability-Zeile."))
	if not playability_line.contains("FOB") or not playability_line.contains("NEXT") or not playability_line.contains("GO") or not playability_line.contains("FEEDBACK"):
		blockers.append(_issue("source_scenario_playability_line_incomplete", "TASK_1019-Scenario-Zeile muss FOB, NEXT, GO und FEEDBACK nennen."))
	if not bool(source.get("source_scenario_playability_slice_passed", false)):
		blockers.append(_issue("source_scenario_playability_not_passed", "TASK_1019-Source bestaetigt den Scenario-Playability-Slice nicht."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1019-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(trace.get("fob_entry_readable", false)):
		issues.append(_issue("fob_entry_not_readable", "FOB-Entry ist im Acceptance-Trace nicht lesbar."))
	if not bool(trace.get("objective_readable", false)):
		issues.append(_issue("objective_not_readable", "Objective ist im Acceptance-Trace nicht lesbar."))
	if not bool(trace.get("roles_readable", false)):
		issues.append(_issue("roles_not_readable", "Alpha-/Bravo-Rollen sind im Acceptance-Trace nicht lesbar."))
	if not bool(trace.get("next_confirm_go_loop_clear", false)):
		issues.append(_issue("next_confirm_go_loop_unclear", "NEXT/CONFIRM/GO-Ablauf ist im Trace nicht klar."))
	if not bool(trace.get("feedback_returns_to_next", false)):
		issues.append(_issue("feedback_does_not_return_to_next", "Feedback fuehrt nicht sichtbar zu NEXT zurueck."))
	if not bool(trace.get("go_boundary_clear", false)):
		issues.append(_issue("go_boundary_unclear", "GO-Grenze ist im Acceptance-Trace nicht klar."))
	if not bool(trace.get("hud_calm", false)):
		issues.append(_issue("hud_not_calm", "HUD wirkt im Acceptance-Trace nicht ruhig."))
	if not bool(trace.get("performance_feels_responsive", false)):
		issues.append(_issue("performance_feels_sluggish", "Scenario-Griff fuehlt sich nicht responsiv an."))
	if not bool(trace.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Multiplayer-Grenze ist nicht belegt."))
	if not bool(trace.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "HUD-read-only-Grenze ist nicht belegt."))
	if Array(trace.get("answered_player_questions", [])).size() < 7:
		issues.append(_issue("player_question_coverage_too_low", "Zu wenige Spielerfragen sind im Trace beantwortet."))
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Trace meldet UI-Gameplay-Wahrheit."))
	if bool(trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Trace darf keinen Command erzeugen."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Trace darf kein Movement erzeugen."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Trace darf keine Multiplayer-Wahrheit setzen."))
	return issues


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_ACCEPTANCE_CHECKS:
		if not completed.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _build_acceptance_line(source: Dictionary, passed: bool, trace_available: bool) -> String:
	var base: String = String(source.get("source_scenario_playability_line", "")).strip_edges()
	if base.is_empty():
		base = "FOB | NEXT | GO separat | FEEDBACK"
	if not base.contains("FOB"):
		base = "FOB | %s" % base
	if not base.contains("NEXT"):
		base = "%s | NEXT" % base
	if not base.contains("GO"):
		base = "%s | GO separat" % base
	if not base.contains("FEEDBACK"):
		base = "%s | FEEDBACK" % base
	if not trace_available:
		return "%s | Acceptance offen" % _compact_text(base, 112)
	var result_text: String = "PASS" if passed else "CHECK"
	return "%s | %s" % [_compact_text(base, 112), result_text]


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
