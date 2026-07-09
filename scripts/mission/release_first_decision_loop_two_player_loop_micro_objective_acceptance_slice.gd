class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.v1"
const TASK_ID: String = "TASK_995"
const SOURCE_TASK_ID: String = "TASK_994"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.v1"
const REVIEW_TASK: String = "TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice"
const CONFIRM_TASK: String = "TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke"
const NEXT_TASK: String = "TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"three_micro_objectives_visible",
	"three_micro_objectives_readable",
	"selected_micro_objective_confirmed",
	"confirm_feedback_visible",
	"go_button_still_separate",
	"micro_objective_does_not_auto_execute_go",
	"selected_micro_objective_prepares_order",
	"player_readability_answered",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_confirm_smoke: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_confirm_smoke)
	var trace_available: bool = bool(acceptance_trace.get("trace_available", false)) or not acceptance_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("micro_objective_acceptance_trace_missing", "TASK_995-Acceptance-Trace fuer den Micro-Objective-Loop fehlt."))
		else:
			issues = _build_trace_issues(acceptance_trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = CONFIRM_TASK
	var recommended_direction: String = "fix_micro_objective_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "micro_objective_acceptance_slice_passed"
			gate = "micro_objective_acceptance_slice_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "build_micro_objective_outcome_slice"
		elif trace_available:
			status = "micro_objective_acceptance_regression_found"
			gate = "micro_objective_acceptance_regression_found"
			recommended_next_task = CONFIRM_TASK
			recommended_direction = "tighten_micro_objective_confirm_readability"
		else:
			status = "needs_micro_objective_acceptance_trace"
			gate = "needs_micro_objective_acceptance_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_micro_objective_acceptance_trace"

	var labels: Array = _micro_objective_labels(source_confirm_smoke)
	var selected_micro_objective_id: String = String(acceptance_trace.get("selected_micro_objective_id", source_confirm_smoke.get("selected_micro_objective_id", ""))).strip_edges()
	var selected_label: String = String(source_confirm_smoke.get("selected_micro_objective_label", _label_for_objective(selected_micro_objective_id))).strip_edges()
	var answered_questions: Array = Array(acceptance_trace.get("answered_player_questions", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_confirm_smoke.get("schema", "")),
		"source_status": String(source_confirm_smoke.get("status", "")),
		"source_gate": String(source_confirm_smoke.get("gate", "")),
		"source_confirm_line": String(source_confirm_smoke.get("micro_objective_confirm_line", "")),
		"source_feedback_line": String(source_confirm_smoke.get("post_confirm_feedback_line", "")),
		"source_confirm_smoke_passed": bool(source_confirm_smoke.get("micro_objective_confirm_smoke_passed", false)),
		"micro_objective_labels": labels,
		"micro_objective_label_count": labels.size(),
		"selected_micro_objective_id": selected_micro_objective_id,
		"selected_micro_objective_label": selected_label,
		"trace_available": trace_available,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"completed_checks": Array(acceptance_trace.get("completed_checks", [])).duplicate(true),
		"missing_acceptance_checks": _missing_checks(Array(acceptance_trace.get("completed_checks", []))),
		"three_micro_objectives_visible": bool(acceptance_trace.get("three_micro_objectives_visible", false)),
		"three_micro_objectives_readable": bool(acceptance_trace.get("three_micro_objectives_readable", false)),
		"selected_micro_objective_confirmed": bool(acceptance_trace.get("selected_micro_objective_confirmed", false)),
		"confirm_feedback_visible": bool(acceptance_trace.get("confirm_feedback_visible", false)),
		"go_button_still_separate": bool(acceptance_trace.get("go_button_still_separate", false)),
		"micro_objective_does_not_auto_execute_go": bool(acceptance_trace.get("micro_objective_does_not_auto_execute_go", false)),
		"selected_micro_objective_prepares_order": bool(acceptance_trace.get("selected_micro_objective_prepares_order", false)),
		"player_readability_answered": bool(acceptance_trace.get("player_readability_answered", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"no_new_hud_gameplay_truth": bool(acceptance_trace.get("no_new_hud_gameplay_truth", false)),
		"multiplayer_boundary_preserved": bool(acceptance_trace.get("multiplayer_boundary_preserved", false)),
		"acceptance_line": _build_acceptance_line(labels, selected_label, passed, trace_available),
		"micro_objective_acceptance_slice_passed": passed,
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


static func _build_source_blockers(source_confirm_smoke: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_confirm_smoke.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_994-Source-Schema fehlt oder passt nicht."))
	if String(source_confirm_smoke.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_994."))
	if String(source_confirm_smoke.get("status", "")) != "micro_objective_confirm_smoke_passed":
		blockers.append(_issue("source_not_passed_for_acceptance", "TASK_994-Source ist nicht fuer TASK_995 bestanden."))
	if not bool(source_confirm_smoke.get("micro_objective_confirm_smoke_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_994-Source setzt micro_objective_confirm_smoke_passed nicht."))
	if not String(source_confirm_smoke.get("micro_objective_confirm_line", "")).contains("GO separat"):
		blockers.append(_issue("source_go_boundary_missing", "TASK_994-Confirm-Zeile nennt GO separat nicht."))
	if String(source_confirm_smoke.get("post_confirm_feedback_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_confirm_feedback_missing", "TASK_994-Source enthaelt keine Feedback-Zeile."))
	if bool(source_confirm_smoke.get("go_executed", false)):
		blockers.append(_issue("source_auto_go_detected", "TASK_994-Source meldet ausgefuehrtes GO waehrend Confirm."))
	if not _snapshot_is_read_only(source_confirm_smoke):
		blockers.append(_issue("source_not_read_only", "TASK_994-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(acceptance_trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(acceptance_trace.get("three_micro_objectives_visible", false)):
		issues.append(_issue("micro_objectives_not_visible", "Der Trace belegt nicht alle drei sichtbaren Micro-Objectives."))
	if not bool(acceptance_trace.get("three_micro_objectives_readable", false)):
		issues.append(_issue("micro_objectives_not_readable", "Der Trace belegt die Lesbarkeit der Micro-Objectives nicht."))
	if not bool(acceptance_trace.get("selected_micro_objective_confirmed", false)):
		issues.append(_issue("selected_micro_objective_not_confirmed", "Die ausgewaehlte Micro-Objective wurde nicht bestaetigt."))
	if not bool(acceptance_trace.get("confirm_feedback_visible", false)):
		issues.append(_issue("confirm_feedback_missing", "Micro-Objective-Confirm-Feedback war nicht sichtbar."))
	if not bool(acceptance_trace.get("go_button_still_separate", false)):
		issues.append(_issue("go_button_not_separate", "GO blieb im Micro-Objective-Loop nicht klar separat."))
	if not bool(acceptance_trace.get("micro_objective_does_not_auto_execute_go", false)):
		issues.append(_issue("micro_objective_auto_executes_go", "Eine Micro-Objective fuehrt GO automatisch aus."))
	if not bool(acceptance_trace.get("selected_micro_objective_prepares_order", false)):
		issues.append(_issue("selected_micro_objective_does_not_prepare_order", "Die ausgewaehlte Micro-Objective bereitet keine Order vor."))
	if not bool(acceptance_trace.get("player_readability_answered", false)):
		issues.append(_issue("player_readability_not_answered", "Der Trace beantwortet die Spielerlesbarkeit nicht."))
	if Array(acceptance_trace.get("answered_player_questions", [])).size() < 6:
		issues.append(_issue("player_question_coverage_too_low", "Der Trace deckt zu wenige Spielerfragen ab."))
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


static func _micro_objective_labels(source_confirm_smoke: Dictionary) -> Array:
	var labels: Array = Array(source_confirm_smoke.get("micro_objective_labels", [])).duplicate(true)
	if labels.size() >= 3:
		return labels
	return ["SICHERN", "DRUECKEN", "SAMMELN"]


static func _build_acceptance_line(labels: Array, selected_label: String, passed: bool, trace_available: bool) -> String:
	var label_line: String = " / ".join(PackedStringArray(labels))
	if label_line.is_empty():
		label_line = "SICHERN / DRUECKEN / SAMMELN"
	if not trace_available:
		return "%s | Acceptance offen | GO separat" % label_line
	var result_text: String = "PASS" if passed else "CHECK"
	var selected: String = selected_label if not selected_label.is_empty() else "MICRO OBJ"
	return "%s | %s %s | GO separat" % [label_line, selected, result_text]


static func _label_for_objective(objective_id: String) -> String:
	match objective_id:
		"secure_gained_ground":
			return "SICHERN"
		"press_next_contact":
			return "DRUECKEN"
		"regroup_fireteam":
			return "SAMMELN"
		_:
			return objective_id.to_upper()


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
