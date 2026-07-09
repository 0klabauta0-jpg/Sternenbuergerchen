class_name ReleaseFirstDecisionLoopTwoAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_acceptance_slice.v1"
const TASK_ID: String = "TASK_975"
const SOURCE_TASK_ID: String = "TASK_974"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_recapture_visual_findings.v1"
const NEXT_TASK: String = "TASK_976 - Release First Decision Loop Two Player Loop Extension"
const REVIEW_TASK: String = "TASK_975 - Release First Decision Loop Two Acceptance Slice"
const POLISH_TASK: String = "TASK_975 - Release First Decision Loop Two Recapture Visual Polish"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"homebase_to_mission_context_preserved",
	"second_decision_button_visible",
	"second_decision_confirmed",
	"go_button_still_separate",
	"go_executed_after_confirm",
	"post_go_feedback_visible",
	"loop_two_smoke_line_visible",
	"player_questions_answered",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_findings: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_findings)
	var trace_available: bool = bool(acceptance_trace.get("trace_available", false)) or not acceptance_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("acceptance_trace_missing", "TASK_975-Acceptance-Trace fuer den zweiten Griff fehlt."))
		else:
			issues = _build_trace_issues(acceptance_trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_loop_two_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "loop_two_acceptance_slice_passed"
			gate = "loop_two_acceptance_slice_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "extend_release_player_loop"
		elif trace_available:
			status = "loop_two_acceptance_regression_found"
			gate = "loop_two_acceptance_regression_found"
			recommended_next_task = POLISH_TASK
			recommended_direction = "tighten_loop_two_acceptance_readability"
		else:
			status = "needs_acceptance_slice_trace"
			gate = "needs_loop_two_acceptance_slice_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_loop_two_acceptance_slice_trace"
	var answered_questions: Array = Array(acceptance_trace.get("answered_player_questions", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_accepted": bool(source_findings.get("accepted", false)),
		"source_issue_count": int(source_findings.get("issue_count", 0)),
		"source_smoke_line": String(source_findings.get("source_smoke_line", "")),
		"source_post_go_feedback_line": String(source_findings.get("source_post_go_feedback_line", "")),
		"trace_available": trace_available,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"completed_checks": Array(acceptance_trace.get("completed_checks", [])).duplicate(true),
		"missing_acceptance_checks": _missing_checks(Array(acceptance_trace.get("completed_checks", []))),
		"homebase_to_mission_context_preserved": bool(acceptance_trace.get("homebase_to_mission_context_preserved", false)),
		"second_decision_button_visible": bool(acceptance_trace.get("second_decision_button_visible", false)),
		"second_decision_confirmed": bool(acceptance_trace.get("second_decision_confirmed", false)),
		"go_button_still_separate": bool(acceptance_trace.get("go_button_still_separate", false)),
		"go_executed_after_confirm": bool(acceptance_trace.get("go_executed_after_confirm", false)),
		"post_go_feedback_visible": bool(acceptance_trace.get("post_go_feedback_visible", false)),
		"loop_two_smoke_line_visible": bool(acceptance_trace.get("loop_two_smoke_line_visible", false)),
		"player_questions_answered": bool(acceptance_trace.get("player_questions_answered", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"no_new_hud_gameplay_truth": bool(acceptance_trace.get("no_new_hud_gameplay_truth", false)),
		"multiplayer_boundary_preserved": bool(acceptance_trace.get("multiplayer_boundary_preserved", false)),
		"acceptance_line": _build_acceptance_line(source_findings, passed, trace_available),
		"acceptance_slice_passed": passed,
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


static func _build_source_blockers(source_findings: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_974-Source-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_974."))
	if String(source_findings.get("status", "")) != "accepted_for_loop_two_acceptance_slice":
		blockers.append(_issue("source_not_accepted_for_acceptance_slice", "TASK_974-Source ist nicht fuer den Acceptance-Slice akzeptiert."))
	if not bool(source_findings.get("accepted", false)):
		blockers.append(_issue("source_accepted_flag_missing", "TASK_974-Source setzt accepted nicht."))
	if int(source_findings.get("issue_count", 0)) != 0:
		blockers.append(_issue("source_has_visual_issues", "TASK_974-Source enthaelt noch visuelle Issues."))
	if not String(source_findings.get("source_smoke_line", "")).contains("2ND"):
		blockers.append(_issue("source_smoke_line_missing_2nd", "TASK_974-Source-Smoke-Zeile nennt 2ND nicht."))
	if not String(source_findings.get("source_smoke_line", "")).contains("GO"):
		blockers.append(_issue("source_smoke_line_missing_go", "TASK_974-Source-Smoke-Zeile nennt GO nicht."))
	if String(source_findings.get("source_post_go_feedback_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_post_go_feedback_missing", "TASK_974-Source enthaelt kein Post-GO-Feedback."))
	if not _snapshot_is_read_only(source_findings):
		blockers.append(_issue("source_not_read_only", "TASK_974-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(acceptance_trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(acceptance_trace.get("homebase_to_mission_context_preserved", false)):
		issues.append(_issue("homebase_to_mission_context_missing", "Der Trace belegt den Homebase-bis-Mission-Kontext nicht."))
	if not bool(acceptance_trace.get("second_decision_button_visible", false)):
		issues.append(_issue("second_decision_button_not_visible", "2ND war im Acceptance-Slice nicht sichtbar."))
	if not bool(acceptance_trace.get("second_decision_confirmed", false)):
		issues.append(_issue("second_decision_not_confirmed", "2ND wurde im Acceptance-Slice nicht bestaetigt."))
	if not bool(acceptance_trace.get("go_button_still_separate", false)):
		issues.append(_issue("go_button_not_separate", "GO blieb im Acceptance-Slice nicht klar separat."))
	if not bool(acceptance_trace.get("go_executed_after_confirm", false)):
		issues.append(_issue("go_not_executed_after_confirm", "GO wurde nicht nach dem zweiten Griff ausgefuehrt."))
	if not bool(acceptance_trace.get("post_go_feedback_visible", false)):
		issues.append(_issue("post_go_feedback_missing", "Nach GO war kein Feedback sichtbar."))
	if not bool(acceptance_trace.get("loop_two_smoke_line_visible", false)):
		issues.append(_issue("loop_two_smoke_line_missing", "Die 2ND->GO->Feedback-Zeile war nicht sichtbar."))
	if not bool(acceptance_trace.get("player_questions_answered", false)):
		issues.append(_issue("player_questions_not_answered", "Der Acceptance-Slice beantwortet die Spielerfragen nicht."))
	if Array(acceptance_trace.get("answered_player_questions", [])).size() < 5:
		issues.append(_issue("player_question_coverage_too_low", "Der Acceptance-Slice deckt zu wenige Spielerfragen ab."))
	if not bool(acceptance_trace.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Trace bestaetigt die HUD-read-only-Grenze nicht."))
	if not bool(acceptance_trace.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Trace bestaetigt die Multiplayer-Grenze nicht."))
	if bool(acceptance_trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Trace meldet UI-Gameplay-Wahrheit."))
	if bool(acceptance_trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Trace selbst darf keinen Command erzeugen."))
	if bool(acceptance_trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Trace selbst darf kein Movement erzeugen."))
	if bool(acceptance_trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Trace selbst darf keine Multiplayer-Wahrheit setzen."))
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


static func _build_acceptance_line(source_findings: Dictionary, passed: bool, trace_available: bool) -> String:
	if not trace_available:
		return "2ND -> GO -> Feedback | Acceptance offen"
	var result_text: String = "PASS" if passed else "CHECK"
	var smoke_line: String = String(source_findings.get("source_smoke_line", "2ND -> GO -> Feedback")).strip_edges()
	var feedback_line: String = String(source_findings.get("source_post_go_feedback_line", "")).strip_edges()
	var line: String = "2ND -> GO -> Feedback %s | %s" % [result_text, smoke_line]
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
