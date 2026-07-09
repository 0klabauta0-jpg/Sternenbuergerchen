class_name ReleaseFirstDecisionLoopTwoPlayerLoopOutcomeVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_visual_findings.v1"
const TASK_ID: String = "TASK_987"
const SOURCE_TASK_ID: String = "TASK_986"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_real_window_capture.v1"
const NEXT_REVIEW_TASK: String = "TASK_987 - Release First Decision Loop Two Player Loop Outcome Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish"
const NEXT_ACCEPTANCE_TASK: String = "TASK_988 - Release First Decision Loop Two Player Loop Outcome Playability Slice"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var manual_review_done: bool = bool(review_notes.get("manual_outcome_visual_review_done", false))
	var issues: Array = []
	var positive_findings: Array = []
	if blockers.is_empty():
		if manual_review_done:
			issues = _build_visual_issues(review_notes)
			positive_findings = _build_positive_findings(review_notes)
		else:
			issues.append(_issue("manual_outcome_visual_review_open", "Der echte TASK_987-Outcome-Fensterblick ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_manual_outcome_window_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_outcome_playability_slice"
			recommended_next_task = NEXT_ACCEPTANCE_TASK
			recommended_direction = "build_outcome_playability_slice"
		elif manual_review_done:
			status = "ready_for_outcome_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_outcome_window_readability"
		else:
			status = "needs_manual_review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_gate": String(source_snapshot.get("gate", "")),
		"source_review_ready": bool(source_snapshot.get("review_ready", false)),
		"source_accepted": bool(source_snapshot.get("accepted", false)),
		"source_scenario_task_id": String(source_snapshot.get("source_task_id", "")),
		"source_scenario_schema": String(source_snapshot.get("source_schema", "")),
		"source_scenario_gate": String(source_snapshot.get("source_gate", "")),
		"source_scenario_status": String(source_snapshot.get("source_status", "")),
		"source_selected_choice_id": String(source_snapshot.get("source_selected_choice_id", "")),
		"source_selected_choice_label": String(source_snapshot.get("source_selected_choice_label", "")),
		"source_outcome_line": String(source_snapshot.get("source_outcome_line", "")),
		"source_result_tag": String(source_snapshot.get("source_result_tag", "")),
		"source_mini_objective_state": String(source_snapshot.get("source_mini_objective_state", "")),
		"source_next_step_line": String(source_snapshot.get("source_next_step_line", "")),
		"window_screenshot_path": String(source_snapshot.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("desktop_screenshot_path", "")),
		"source_missing_manual_check_count": int(source_snapshot.get("missing_manual_check_count", 0)),
		"review_notes": review_notes.duplicate(true),
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"accepted": accepted,
		"status": status,
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


static func _build_blockers(source_snapshot: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_snapshot.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_986-Source-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_986."))
	var source_status: String = String(source_snapshot.get("status", ""))
	var source_gate: String = String(source_snapshot.get("gate", ""))
	if not bool(source_snapshot.get("review_ready", false)) and source_status not in ["review_ready", "accepted"] and source_gate not in ["outcome_real_window_capture_review_ready", "outcome_real_window_capture_accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_986-Source ist nicht review-ready."))
	if not bool(source_snapshot.get("manifest_available", false)):
		blockers.append(_issue("source_manifest_missing", "TASK_986-Source enthaelt kein Capture-Manifest."))
	if not bool(source_snapshot.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_986-Fenster-Capture ist nicht trusted."))
	if not bool(source_snapshot.get("window_screenshot_written", false)):
		blockers.append(_issue("source_window_screenshot_missing", "TASK_986-Fenster-Screenshot fehlt."))
	if String(source_snapshot.get("source_task_id", "")) != "TASK_985":
		blockers.append(_issue("source_scenario_task_mismatch", "TASK_986-Source nennt nicht TASK_985 als Outcome-Quelle."))
	if String(source_snapshot.get("source_outcome_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_outcome_line_missing", "TASK_986-Source enthaelt keine Outcome-Zeile."))
	if String(source_snapshot.get("source_mini_objective_state", "")).strip_edges().is_empty():
		blockers.append(_issue("source_mini_objective_missing", "TASK_986-Source enthaelt keinen Mini-Zielzustand."))
	if String(source_snapshot.get("source_next_step_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_next_step_missing", "TASK_986-Source enthaelt keine Next-Step-Zeile."))
	if not bool(source_snapshot.get("read_only", false)) or not bool(source_snapshot.get("read_only_capture", false)):
		blockers.append(_issue("source_not_read_only", "TASK_986-Source ist nicht read-only/read-only-capture."))
	if bool(source_snapshot.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_986-Source darf keine UI-Gameplay-Wahrheit setzen."))
	if bool(source_snapshot.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_986-Source darf keine Multiplayer-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht."))
	if not bool(review_notes.get("outcome_line_visible", false)):
		issues.append(_issue("outcome_line_not_visible", "Die Outcome-Zeile ist im echten Fenster nicht sichtbar."))
	if not bool(review_notes.get("mini_objective_state_visible", false)):
		issues.append(_issue("mini_objective_state_not_visible", "Der Mini-Zielzustand ist im echten Fenster nicht sichtbar."))
	if not bool(review_notes.get("next_step_line_visible", false)):
		issues.append(_issue("next_step_line_not_visible", "Die Next-Step-Zeile ist im echten Fenster nicht sichtbar."))
	if not bool(review_notes.get("player_result_readable", false)):
		issues.append(_issue("player_result_not_readable", "Das Ergebnis liest sich fuer den Spieler noch nicht eindeutig genug."))
	if not bool(review_notes.get("hud_read_only_boundary_ok", false)):
		issues.append(_issue("hud_read_only_boundary_risk", "Der Sichtbefund bestaetigt die HUD-read-only-Grenze nicht."))
	if not bool(review_notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt nicht, dass das HUD keine neue Gameplay-Wahrheit setzt."))
	if not bool(review_notes.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Sichtbefund bestaetigt die Multiplayer-Grenze nicht."))
	return issues


static func _build_positive_findings(review_notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, review_notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, review_notes, "outcome_line_visible", "Outcome-Zeile ist sichtbar.")
	_append_positive(positive, review_notes, "mini_objective_state_visible", "Mini-Zielzustand ist sichtbar.")
	_append_positive(positive, review_notes, "next_step_line_visible", "Next-Step-Zeile ist sichtbar.")
	_append_positive(positive, review_notes, "player_result_readable", "Ergebnis ist fuer Spieler lesbar.")
	_append_positive(positive, review_notes, "hud_read_only_boundary_ok", "HUD-read-only-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "no_new_hud_gameplay_truth", "HUD erzeugt keine neue Gameplay-Wahrheit.")
	_append_positive(positive, review_notes, "multiplayer_boundary_preserved", "Multiplayer-Grenze bleibt bestaetigt.")
	return positive


static func _append_positive(positive: Array, review_notes: Dictionary, note_id: String, text: String) -> void:
	if bool(review_notes.get(note_id, false)):
		positive.append({
			"id": note_id,
			"text": text,
		})


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
