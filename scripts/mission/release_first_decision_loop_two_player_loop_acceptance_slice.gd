class_name ReleaseFirstDecisionLoopTwoPlayerLoopAcceptanceSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_acceptance_slice.v1"
const TASK_ID: String = "TASK_984"
const SOURCE_TASK_ID: String = "TASK_983"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_polish.v1"
const REVIEW_TASK: String = "TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice"
const POLISH_TASK: String = "TASK_983 - Release First Decision Loop Two Player Loop Visual Polish"
const NEXT_TASK: String = "TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"four_choices_visible",
	"four_choices_readable",
	"choice_tooltips_explain_go",
	"choice_confirm_feedback_visible",
	"go_button_still_separate",
	"choice_does_not_auto_execute_go",
	"selected_choice_prepares_order",
	"player_readability_answered",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_visual_polish: Dictionary, acceptance_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_visual_polish)
	var trace_available: bool = bool(acceptance_trace.get("trace_available", false)) or not acceptance_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("player_loop_acceptance_trace_missing", "TASK_984-Acceptance-Trace fuer den Vier-Choice-Loop fehlt."))
		else:
			issues = _build_trace_issues(acceptance_trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_player_loop_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "player_loop_acceptance_slice_passed"
			gate = "player_loop_acceptance_slice_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "build_scenario_outcome_slice"
		elif trace_available:
			status = "player_loop_acceptance_regression_found"
			gate = "player_loop_acceptance_regression_found"
			recommended_next_task = POLISH_TASK
			recommended_direction = "tighten_player_loop_visual_readability"
		else:
			status = "needs_player_loop_acceptance_trace"
			gate = "needs_player_loop_acceptance_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_player_loop_acceptance_trace"
	var answered_questions: Array = Array(acceptance_trace.get("answered_player_questions", [])).duplicate(true)
	var labels: Array = _choice_labels(source_visual_polish)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_visual_polish.get("schema", "")),
		"source_status": String(source_visual_polish.get("status", "")),
		"source_active": bool(source_visual_polish.get("active", false)),
		"source_button_visual_spec_count": int(source_visual_polish.get("button_visual_spec_count", 0)),
		"source_choice_group_line": String(source_visual_polish.get("choice_group_line", "")),
		"source_choice_feedback_line": String(source_visual_polish.get("choice_feedback_line", "")),
		"source_go_separation_line": String(source_visual_polish.get("go_separation_line", "")),
		"choice_labels": labels,
		"choice_label_count": labels.size(),
		"trace_available": trace_available,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"completed_checks": Array(acceptance_trace.get("completed_checks", [])).duplicate(true),
		"missing_acceptance_checks": _missing_checks(Array(acceptance_trace.get("completed_checks", []))),
		"four_choices_visible": bool(acceptance_trace.get("four_choices_visible", false)),
		"four_choices_readable": bool(acceptance_trace.get("four_choices_readable", false)),
		"choice_tooltips_explain_go": bool(acceptance_trace.get("choice_tooltips_explain_go", false)),
		"choice_confirm_feedback_visible": bool(acceptance_trace.get("choice_confirm_feedback_visible", false)),
		"go_button_still_separate": bool(acceptance_trace.get("go_button_still_separate", false)),
		"choice_does_not_auto_execute_go": bool(acceptance_trace.get("choice_does_not_auto_execute_go", false)),
		"selected_choice_prepares_order": bool(acceptance_trace.get("selected_choice_prepares_order", false)),
		"selected_choice_id": String(acceptance_trace.get("selected_choice_id", "")),
		"player_readability_answered": bool(acceptance_trace.get("player_readability_answered", false)),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"no_new_hud_gameplay_truth": bool(acceptance_trace.get("no_new_hud_gameplay_truth", false)),
		"multiplayer_boundary_preserved": bool(acceptance_trace.get("multiplayer_boundary_preserved", false)),
		"acceptance_line": _build_acceptance_line(source_visual_polish, labels, passed, trace_available),
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


static func _build_source_blockers(source_visual_polish: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_visual_polish.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_983-Source-Schema fehlt oder passt nicht."))
	if String(source_visual_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_983."))
	if String(source_visual_polish.get("status", "")) != "player_loop_visual_polish_ready":
		blockers.append(_issue("source_not_ready_for_acceptance_slice", "TASK_983-Source ist nicht bereit fuer TASK_984."))
	if not bool(source_visual_polish.get("active", false)):
		blockers.append(_issue("source_not_active", "TASK_983-Source ist nicht aktiv."))
	if int(source_visual_polish.get("button_visual_spec_count", 0)) != 4:
		blockers.append(_issue("source_missing_four_choice_specs", "TASK_983-Source liefert nicht genau vier Choice-Visual-Specs."))
	if not _contains_all_choices(String(source_visual_polish.get("choice_group_line", ""))):
		blockers.append(_issue("source_choice_group_incomplete", "TASK_983-Gruppenlinie nennt nicht alle vier Choices."))
	if not String(source_visual_polish.get("choice_group_line", "")).contains("GO separat"):
		blockers.append(_issue("source_go_boundary_missing", "TASK_983-Gruppenlinie nennt die GO-Grenze nicht."))
	if String(source_visual_polish.get("choice_feedback_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_confirm_feedback_missing", "TASK_983-Source enthaelt keine Confirm-Feedback-Zeile."))
	if not _snapshot_is_read_only(source_visual_polish):
		blockers.append(_issue("source_not_read_only", "TASK_983-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(acceptance_trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(acceptance_trace.get("four_choices_visible", false)):
		issues.append(_issue("four_choices_not_visible", "Der Trace belegt nicht alle vier sichtbaren Choices."))
	if not bool(acceptance_trace.get("four_choices_readable", false)):
		issues.append(_issue("four_choices_not_readable", "Der Trace belegt die Lesbarkeit der vier Choices nicht."))
	if not bool(acceptance_trace.get("choice_tooltips_explain_go", false)):
		issues.append(_issue("choice_tooltips_do_not_explain_go", "Die Tooltips erklaeren die GO-Grenze nicht."))
	if not bool(acceptance_trace.get("choice_confirm_feedback_visible", false)):
		issues.append(_issue("choice_confirm_feedback_missing", "Choice-Confirm-Feedback war nicht sichtbar."))
	if not bool(acceptance_trace.get("go_button_still_separate", false)):
		issues.append(_issue("go_button_not_separate", "GO blieb im Vier-Choice-Loop nicht klar separat."))
	if not bool(acceptance_trace.get("choice_does_not_auto_execute_go", false)):
		issues.append(_issue("choice_auto_executes_go", "Eine Choice fuehrt GO automatisch aus."))
	if not bool(acceptance_trace.get("selected_choice_prepares_order", false)):
		issues.append(_issue("selected_choice_does_not_prepare_order", "Die gewaehlt Choice bereitet keine Order vor."))
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


static func _choice_labels(source_visual_polish: Dictionary) -> Array:
	var labels: Array = []
	for spec_variant in Array(source_visual_polish.get("button_visual_specs", [])):
		var label: String = String(Dictionary(spec_variant).get("button_text", "")).strip_edges()
		if not label.is_empty():
			labels.append(label)
	return labels


static func _contains_all_choices(line: String) -> bool:
	return line.contains("SECURE") and line.contains("PUSH") and line.contains("FLANK") and line.contains("RESET")


static func _build_acceptance_line(source_visual_polish: Dictionary, labels: Array, passed: bool, trace_available: bool) -> String:
	if not trace_available:
		return "SECURE / PUSH / FLANK / RESET | Acceptance offen | GO separat"
	var result_text: String = "PASS" if passed else "CHECK"
	var choice_line: String = " / ".join(PackedStringArray(labels))
	if choice_line.is_empty():
		choice_line = String(source_visual_polish.get("choice_group_line", "SECURE / PUSH / FLANK / RESET"))
	return "%s | %s | GO separat" % [choice_line, result_text]


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
