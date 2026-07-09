class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioSmallGameAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.v1"
const TASK_ID: String = "TASK_1023"
const SOURCE_TASK_ID: String = "TASK_1022"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.v1"
const REVIEW_TASK: String = "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice"
const POLISH_TASK: String = "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish"
const NEXT_TASK: String = "TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest"

const REQUIRED_ACCEPTANCE_CHECKS: Array[String] = [
	"entry_fob_next_visible",
	"objective_and_roles_clear",
	"next_confirm_go_boundary_clear",
	"go_stays_separate",
	"post_go_feedback_returns_to_next",
	"hud_calm",
	"performance_feels_responsive",
	"two_player_context_clear",
	"multiplayer_boundary_preserved",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(source_findings: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_findings)
	var source_ready: bool = blockers.is_empty()
	var trace_available: bool = bool(acceptance_trace.get("trace_available", false)) or not acceptance_trace.is_empty()
	var completed_checks: Array = Array(acceptance_trace.get("completed_checks", []))
	var missing_checks: Array = _missing_checks(completed_checks)
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_integrated_player_feel_findings"
	var passed: bool = false
	var ready_for_release_candidate: bool = false
	if source_ready:
		if not trace_available:
			status = "needs_small_game_acceptance_trace"
			gate = "needs_small_game_acceptance_trace"
			issues.append(_issue("small_game_acceptance_trace_missing", "Small-Game-Acceptance-Trace fuer TASK_1023 fehlt."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "collect_small_game_acceptance_trace"
		else:
			issues = _build_trace_issues(acceptance_trace, missing_checks)
			if issues.is_empty():
				status = "small_game_acceptance_slice_passed"
				gate = "small_game_acceptance_slice_passed"
				passed = true
				ready_for_release_candidate = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "run_release_candidate_playtest"
			else:
				status = "small_game_acceptance_regression_found"
				gate = "small_game_acceptance_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_small_game_regressions"
	var answered_questions: Array = Array(acceptance_trace.get("answered_player_questions", []))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_gate": String(source_findings.get("gate", "")),
		"source_player_feel_summary_line": String(source_findings.get("scenario_integrated_player_feel_summary_line", "")),
		"source_ready_for_small_game_acceptance_slice": bool(source_findings.get("ready_for_small_game_acceptance_slice", false)),
		"trace_available": trace_available,
		"required_acceptance_checks": REQUIRED_ACCEPTANCE_CHECKS.duplicate(),
		"completed_checks": completed_checks,
		"missing_acceptance_checks": missing_checks,
		"entry_fob_next_visible": bool(acceptance_trace.get("entry_fob_next_visible", false)),
		"objective_and_roles_clear": bool(acceptance_trace.get("objective_and_roles_clear", false)),
		"next_confirm_go_boundary_clear": bool(acceptance_trace.get("next_confirm_go_boundary_clear", false)),
		"go_stays_separate": bool(acceptance_trace.get("go_stays_separate", false)),
		"post_go_feedback_returns_to_next": bool(acceptance_trace.get("post_go_feedback_returns_to_next", false)),
		"hud_calm": bool(acceptance_trace.get("hud_calm", false)),
		"performance_feels_responsive": bool(acceptance_trace.get("performance_feels_responsive", false)),
		"two_player_context_clear": bool(acceptance_trace.get("two_player_context_clear", false)),
		"multiplayer_boundary_preserved": bool(acceptance_trace.get("multiplayer_boundary_preserved", false)),
		"no_new_hud_gameplay_truth": bool(acceptance_trace.get("no_new_hud_gameplay_truth", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"small_game_acceptance_line": _build_acceptance_line(source_findings, passed, trace_available),
		"small_game_acceptance_slice_passed": passed,
		"ready_for_release_candidate_playtest": ready_for_release_candidate,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
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


static func _build_blockers(source_findings: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1022-Source-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1022."))
	if String(source_findings.get("status", "")) != "accepted_for_small_game_acceptance_slice":
		blockers.append(_issue("source_not_accepted_for_small_game", "TASK_1022-Source ist nicht accepted_for_small_game_acceptance_slice."))
	if not bool(source_findings.get("ready_for_small_game_acceptance_slice", false)):
		blockers.append(_issue("source_ready_flag_missing", "TASK_1022 ist nicht fuer Small-Game-Acceptance freigegeben."))
	var summary_line: String = String(source_findings.get("scenario_integrated_player_feel_summary_line", "")).strip_edges()
	if summary_line.is_empty():
		blockers.append(_issue("source_summary_line_missing", "TASK_1022-Player-Feel-Summary fehlt."))
	elif not (summary_line.contains("FOB") and summary_line.contains("NEXT") and summary_line.contains("GO") and summary_line.contains("FEEDBACK")):
		blockers.append(_issue("source_small_game_line_missing", "TASK_1022-Summary nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source_findings):
		blockers.append(_issue("source_not_read_only", "TASK_1022-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary, missing_checks: Array) -> Array:
	var issues: Array = []
	var issue_by_check: Dictionary = {
		"entry_fob_next_visible": "entry_fob_next_not_visible",
		"objective_and_roles_clear": "objective_roles_unclear",
		"next_confirm_go_boundary_clear": "next_confirm_go_boundary_unclear",
		"go_stays_separate": "go_not_separate",
		"post_go_feedback_returns_to_next": "post_go_feedback_does_not_return_to_next",
		"hud_calm": "hud_not_calm",
		"performance_feels_responsive": "performance_feels_sluggish",
		"two_player_context_clear": "two_player_context_unclear",
		"multiplayer_boundary_preserved": "multiplayer_boundary_risk",
		"no_new_hud_gameplay_truth": "hud_gameplay_truth_risk",
	}
	for check_id in REQUIRED_ACCEPTANCE_CHECKS:
		if missing_checks.has(check_id) or not bool(trace.get(check_id, false)):
			issues.append(_issue(String(issue_by_check.get(check_id, "%s_missing" % check_id)), "Small-Game-Acceptance-Check `%s` fehlt oder ist negativ." % check_id))
	if Array(trace.get("answered_player_questions", [])).size() < 7:
		issues.append(_issue("player_question_coverage_too_low", "Zu wenige Spielerfragen sind im Acceptance-Trace beantwortet."))
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("trace_ui_gameplay_truth_risk", "Trace deutet UI-Gameplay-Wahrheit an."))
	if bool(trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Acceptance-Trace darf keinen Command erzeugen."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Acceptance-Trace darf keine Bewegung erzeugen."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Acceptance-Trace darf keine Multiplayer-Wahrheit setzen."))
	return issues


static func _missing_checks(completed_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_ACCEPTANCE_CHECKS:
		if not completed_checks.has(check_id):
			missing.append(check_id)
	return missing


static func _build_acceptance_line(source_findings: Dictionary, passed: bool, trace_available: bool) -> String:
	var source_line: String = String(source_findings.get("scenario_integrated_player_feel_summary_line", "")).strip_edges()
	var state: String = "PASS" if passed else "CHECK" if trace_available else "Trace offen"
	if source_line.is_empty():
		source_line = "FOB, NEXT, GO separat und FEEDBACK brauchen Small-Game-Acceptance."
	return "SMALL GAME ACCEPTANCE %s: FOB | NEXT | GO separat | FEEDBACK | %s" % [state, _compact_text(source_line, 104)]


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
