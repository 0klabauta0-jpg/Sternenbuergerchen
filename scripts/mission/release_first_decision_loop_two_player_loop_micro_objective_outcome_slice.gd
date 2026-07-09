class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveOutcomeSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.v1"
const TASK_ID: String = "TASK_996"
const SOURCE_TASK_ID: String = "TASK_995"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.v1"
const REVIEW_TASK: String = "TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice"
const ACCEPTANCE_TASK: String = "TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice"
const NEXT_TASK: String = "TASK_997 - Release First Decision Loop Two Player Loop Micro Objective Real Window Capture"

const REQUIRED_OUTCOME_CHECKS: PackedStringArray = [
	"selected_micro_objective_has_outcome",
	"outcome_line_visible",
	"mini_objective_state_visible",
	"next_step_visible",
	"player_result_readable",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_acceptance: Dictionary, outcome_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_acceptance)
	var trace_available: bool = bool(outcome_trace.get("trace_available", false)) or not outcome_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("micro_objective_outcome_trace_missing", "TASK_996-Outcome-Trace fuer den Micro-Objective-Loop fehlt."))
		else:
			issues = _build_trace_issues(outcome_trace)
	var ready: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = ACCEPTANCE_TASK
	var recommended_direction: String = "fix_micro_objective_outcome_source"
	if blockers.is_empty():
		if ready:
			status = "micro_objective_outcome_ready"
			gate = "micro_objective_outcome_ready"
			recommended_next_task = NEXT_TASK
			recommended_direction = "capture_micro_objective_outcome_window"
		elif trace_available:
			status = "micro_objective_outcome_regression_found"
			gate = "micro_objective_outcome_regression_found"
			recommended_next_task = ACCEPTANCE_TASK
			recommended_direction = "tighten_micro_objective_outcome_readability"
		else:
			status = "needs_micro_objective_outcome_trace"
			gate = "needs_micro_objective_outcome_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_micro_objective_outcome_trace"

	var selected_micro_objective_id: String = String(outcome_trace.get("selected_micro_objective_id", source_acceptance.get("selected_micro_objective_id", ""))).strip_edges()
	var selected_label: String = String(outcome_trace.get("selected_micro_objective_label", source_acceptance.get("selected_micro_objective_label", _label_for_objective(selected_micro_objective_id)))).strip_edges()
	var outcome_line: String = _build_outcome_line(outcome_trace, selected_label, ready, trace_available)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_acceptance.get("schema", "")),
		"source_status": String(source_acceptance.get("status", "")),
		"source_gate": String(source_acceptance.get("gate", "")),
		"source_acceptance_line": String(source_acceptance.get("acceptance_line", "")),
		"source_acceptance_slice_passed": bool(source_acceptance.get("micro_objective_acceptance_slice_passed", false)),
		"source_micro_objective_labels": Array(source_acceptance.get("micro_objective_labels", [])).duplicate(true),
		"trace_available": trace_available,
		"required_outcome_checks": Array(REQUIRED_OUTCOME_CHECKS),
		"completed_checks": Array(outcome_trace.get("completed_checks", [])).duplicate(true),
		"missing_outcome_checks": _missing_checks(Array(outcome_trace.get("completed_checks", []))),
		"selected_micro_objective_id": selected_micro_objective_id,
		"selected_micro_objective_label": selected_label,
		"selected_micro_objective_has_outcome": bool(outcome_trace.get("selected_micro_objective_has_outcome", false)),
		"outcome_line_visible": bool(outcome_trace.get("outcome_line_visible", false)),
		"outcome_line": outcome_line,
		"result_tag": String(outcome_trace.get("result_tag", "")),
		"mini_objective_state_visible": bool(outcome_trace.get("mini_objective_state_visible", false)),
		"mini_objective_state": String(outcome_trace.get("mini_objective_state", "")),
		"next_step_visible": bool(outcome_trace.get("next_step_visible", false)),
		"next_step_line": String(outcome_trace.get("next_step_line", "Naechster Griff: Outcome im Fenster pruefen." if ready else "")),
		"player_result_readable": bool(outcome_trace.get("player_result_readable", false)),
		"micro_objective_outcome_ready": ready,
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


static func _build_source_blockers(source_acceptance: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_acceptance.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_995-Source-Schema fehlt oder passt nicht."))
	if String(source_acceptance.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_995."))
	if String(source_acceptance.get("status", "")) != "micro_objective_acceptance_slice_passed":
		blockers.append(_issue("source_not_passed_for_outcome", "TASK_995-Source ist nicht fuer TASK_996 bestanden."))
	if not bool(source_acceptance.get("micro_objective_acceptance_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_995-Source setzt micro_objective_acceptance_slice_passed nicht."))
	if int(source_acceptance.get("micro_objective_label_count", Array(source_acceptance.get("micro_objective_labels", [])).size())) < 3:
		blockers.append(_issue("source_micro_objective_labels_missing", "TASK_995-Source liefert nicht alle drei Micro-Objectives."))
	if not String(source_acceptance.get("acceptance_line", "")).contains("GO separat"):
		blockers.append(_issue("source_go_boundary_missing", "TASK_995-Acceptance-Zeile nennt GO separat nicht."))
	if not _snapshot_is_read_only(source_acceptance):
		blockers.append(_issue("source_not_read_only", "TASK_995-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(outcome_trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(outcome_trace.get("selected_micro_objective_has_outcome", false)):
		issues.append(_issue("selected_micro_objective_outcome_missing", "Die gewaehlte Micro-Objective hat kein sichtbares Outcome."))
	if not bool(outcome_trace.get("outcome_line_visible", false)) or String(outcome_trace.get("outcome_line", "")).strip_edges().is_empty():
		issues.append(_issue("outcome_line_missing", "Outcome-Zeile fehlt oder ist leer."))
	if not bool(outcome_trace.get("mini_objective_state_visible", false)):
		issues.append(_issue("mini_objective_state_not_visible", "Mini-Zielzustand ist nicht sichtbar."))
	if not bool(outcome_trace.get("next_step_visible", false)) or String(outcome_trace.get("next_step_line", "")).strip_edges().is_empty():
		issues.append(_issue("next_step_not_visible", "Naechster Griff ist nicht sichtbar."))
	if not bool(outcome_trace.get("player_result_readable", false)):
		issues.append(_issue("player_result_not_readable", "Der Spieler kann das Micro-Objective-Ergebnis nicht lesen."))
	if not bool(outcome_trace.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Outcome-Trace bestaetigt die HUD-read-only-Grenze nicht."))
	if not bool(outcome_trace.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Outcome-Trace bestaetigt die Multiplayer-Grenze nicht."))
	if bool(outcome_trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Trace meldet UI-Gameplay-Wahrheit."))
	if bool(outcome_trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Trace selbst darf keinen Command erzeugen."))
	if bool(outcome_trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Trace selbst darf kein Movement erzeugen."))
	if bool(outcome_trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Trace selbst darf keine Multiplayer-Wahrheit setzen."))
	return issues


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_OUTCOME_CHECKS:
		if not completed.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _build_outcome_line(outcome_trace: Dictionary, selected_label: String, ready: bool, trace_available: bool) -> String:
	var provided: String = String(outcome_trace.get("outcome_line", "")).strip_edges()
	if not provided.is_empty():
		return provided
	if not trace_available:
		return "Outcome offen: Micro-Objective akzeptiert, Ergebnis-Trace fehlt."
	var result_text: String = "bereit" if ready else "pruefen"
	var label: String = selected_label if not selected_label.is_empty() else "MICRO OBJ"
	return "%s: Micro-Objective-Outcome %s." % [label, result_text]


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
