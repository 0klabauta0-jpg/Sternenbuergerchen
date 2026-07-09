class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.v1"
const TASK_ID: String = "TASK_1011"
const SOURCE_TASK_ID: String = "TASK_1010"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.v1"
const REVIEW_TASK: String = "TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"
const POLISH_TASK: String = "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish"
const NEXT_TASK: String = "TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"feel_next_go_visible",
	"start_context_clear",
	"round_next_go_rhythm_clear",
	"feedback_returns_to_next",
	"go_boundary_clear",
	"hud_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_preserved",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(source_polish: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_polish)
	var trace_available: bool = bool(acceptance_trace.get("trace_available", false)) or not acceptance_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("round_loop_acceptance_trace_missing", "TASK_1011-Acceptance-Trace fuer den Round-Loop fehlt."))
		else:
			issues = _build_trace_issues(acceptance_trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_round_loop_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "round_loop_acceptance_slice_passed"
			gate = "round_loop_acceptance_slice_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "stitch_round_loop_into_scenario"
		elif trace_available:
			status = "round_loop_acceptance_regression_found"
			gate = "round_loop_acceptance_regression_found"
			recommended_next_task = POLISH_TASK
			recommended_direction = "tighten_round_loop_player_feel_polish"
		else:
			status = "needs_round_loop_acceptance_trace"
			gate = "needs_round_loop_acceptance_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_round_loop_acceptance_trace"

	var answered_questions: Array = Array(acceptance_trace.get("answered_player_questions", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_polish.get("schema", "")),
		"source_status": String(source_polish.get("status", "")),
		"source_player_feel_polish_line": String(source_polish.get("player_feel_polish_line", "")),
		"source_next_grip_line": String(source_polish.get("next_grip_line", "")),
		"source_go_boundary_microcopy": String(source_polish.get("go_boundary_microcopy", "")),
		"source_calm_hud_guidance": String(source_polish.get("calm_hud_guidance", "")),
		"source_surface_spec_count": int(source_polish.get("player_feel_surface_spec_count", 0)),
		"trace_available": trace_available,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"completed_checks": Array(acceptance_trace.get("completed_checks", [])).duplicate(true),
		"missing_acceptance_checks": _missing_checks(Array(acceptance_trace.get("completed_checks", []))),
		"feel_next_go_visible": bool(acceptance_trace.get("feel_next_go_visible", false)),
		"start_context_clear": bool(acceptance_trace.get("start_context_clear", false)),
		"round_next_go_rhythm_clear": bool(acceptance_trace.get("round_next_go_rhythm_clear", false)),
		"feedback_returns_to_next": bool(acceptance_trace.get("feedback_returns_to_next", false)),
		"go_boundary_clear": bool(acceptance_trace.get("go_boundary_clear", false)),
		"hud_calm": bool(acceptance_trace.get("hud_calm", false)),
		"performance_feels_responsive": bool(acceptance_trace.get("performance_feels_responsive", false)),
		"multiplayer_boundary_preserved": bool(acceptance_trace.get("multiplayer_boundary_preserved", false)),
		"no_new_hud_gameplay_truth": bool(acceptance_trace.get("no_new_hud_gameplay_truth", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"round_loop_acceptance_line": _build_acceptance_line(source_polish, passed, trace_available),
		"round_loop_acceptance_slice_passed": passed,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
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


static func _build_source_blockers(source_polish: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_polish.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1010-Source-Schema fehlt oder passt nicht."))
	if String(source_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1010."))
	if String(source_polish.get("status", "")) != "round_loop_player_feel_polish_ready":
		blockers.append(_issue("source_not_ready_for_acceptance", "TASK_1010-Source ist nicht acceptance-ready."))
	if not bool(source_polish.get("ready_for_acceptance_review", false)):
		blockers.append(_issue("source_acceptance_flag_missing", "TASK_1010-Source setzt ready_for_acceptance_review nicht."))
	if int(source_polish.get("player_feel_surface_spec_count", 0)) < 6:
		blockers.append(_issue("source_surface_specs_missing", "TASK_1010-Player-Feel-Surfaces fehlen."))
	if not String(source_polish.get("player_feel_polish_line", "")).contains("FEEL"):
		blockers.append(_issue("source_feel_line_missing", "TASK_1010-Polish-Zeile nennt FEEL nicht."))
	if not String(source_polish.get("player_feel_polish_line", "")).contains("NEXT"):
		blockers.append(_issue("source_next_line_missing", "TASK_1010-Polish-Zeile nennt NEXT nicht."))
	if not String(source_polish.get("player_feel_polish_line", "")).contains("GO"):
		blockers.append(_issue("source_go_boundary_missing", "TASK_1010-Polish-Zeile nennt GO nicht."))
	if String(source_polish.get("next_grip_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_next_grip_missing", "TASK_1010-Next-Grip-Zeile fehlt."))
	if String(source_polish.get("go_boundary_microcopy", "")).strip_edges().is_empty():
		blockers.append(_issue("source_go_microcopy_missing", "TASK_1010-GO-Microcopy fehlt."))
	if not _snapshot_is_read_only(source_polish):
		blockers.append(_issue("source_not_read_only", "TASK_1010-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(trace.get("feel_next_go_visible", false)):
		issues.append(_issue("feel_next_go_not_visible", "FEEL/NEXT/GO ist im Trace nicht sichtbar."))
	if not bool(trace.get("start_context_clear", false)):
		issues.append(_issue("start_context_unclear", "Start-Kontext ist nicht klar."))
	if not bool(trace.get("round_next_go_rhythm_clear", false)):
		issues.append(_issue("round_next_go_rhythm_unclear", "ROUND/NEXT/GO-Rhythmus ist nicht klar."))
	if not bool(trace.get("feedback_returns_to_next", false)):
		issues.append(_issue("feedback_does_not_return_to_next", "Feedback fuehrt nicht sichtbar zu NEXT zurueck."))
	if not bool(trace.get("go_boundary_clear", false)):
		issues.append(_issue("go_boundary_unclear", "GO-Grenze ist nicht klar."))
	if not bool(trace.get("hud_calm", false)):
		issues.append(_issue("hud_not_calm", "HUD wirkt im Acceptance-Trace nicht ruhig."))
	if not bool(trace.get("performance_feels_responsive", false)):
		issues.append(_issue("performance_feels_sluggish", "Round-Loop fuehlt sich nicht responsiv an."))
	if not bool(trace.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Multiplayer-Grenze ist nicht belegt."))
	if not bool(trace.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "HUD-read-only-Grenze ist nicht belegt."))
	if Array(trace.get("answered_player_questions", [])).size() < 6:
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


static func _build_acceptance_line(source_polish: Dictionary, passed: bool, trace_available: bool) -> String:
	var base: String = String(source_polish.get("player_feel_polish_line", "")).strip_edges()
	if base.is_empty():
		base = "FEEL | NEXT | GO separat"
	if not trace_available:
		return "%s | Acceptance offen" % base
	var result_text: String = "PASS" if passed else "CHECK"
	if not base.contains("GO separat"):
		base = "%s | GO separat" % base
	return "%s | %s" % [base, result_text]


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
