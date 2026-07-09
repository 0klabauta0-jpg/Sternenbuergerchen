class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visual_findings.v1"
const TASK_ID: String = "TASK_1019"
const SOURCE_TASK_ID: String = "TASK_1018"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_real_window_capture.v1"
const REVIEW_TASK: String = "TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish"
const NEXT_ACCEPTANCE_TASK: String = "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_snapshot.duplicate(true)
	var notes: Dictionary = review_notes.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var manual_review_done: bool = bool(notes.get("manual_visual_review_done", false))
	var issues: Array = []
	var positive_findings: Array = []
	if blockers.is_empty():
		if manual_review_done:
			issues = _build_visual_issues(notes)
			positive_findings = _build_positive_findings(notes)
		else:
			issues.append(_issue("manual_scenario_visual_review_open", "Der echte TASK_1019-Szenario-Fensterblick ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "complete_manual_scenario_window_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_scenario_acceptance_slice"
			recommended_next_task = NEXT_ACCEPTANCE_TASK
			recommended_direction = "build_scenario_acceptance_slice"
		elif manual_review_done:
			status = "ready_for_scenario_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_scenario_readability"
		else:
			status = "needs_manual_review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_gate": String(source.get("gate", "")),
		"source_review_ready": bool(source.get("review_ready", false)),
		"source_accepted": bool(source.get("accepted", false)),
		"source_scenario_task_id": String(source.get("source_task_id", "")),
		"source_scenario_schema": String(source.get("source_schema", "")),
		"source_scenario_status": String(source.get("source_status", "")),
		"source_scenario_gate": String(source.get("source_gate", "")),
		"source_scenario_playability_line": String(source.get("source_scenario_playability_line", "")),
		"source_scenario_playability_slice_passed": bool(source.get("source_scenario_playability_slice_passed", false)),
		"manifest_available": bool(source.get("manifest_available", false)),
		"launch_argument": String(source.get("launch_argument", "")),
		"window_capture_method": String(source.get("window_capture_method", "")),
		"window_capture_trusted": bool(source.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(source.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(source.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(source.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(source.get("desktop_screenshot_path", "")),
		"review_notes": notes,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
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


static func _build_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1018-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1018."))
	var source_status: String = String(source.get("status", ""))
	var source_gate: String = String(source.get("gate", ""))
	if not bool(source.get("review_ready", false)) and source_status not in ["review_ready", "accepted"] and source_gate not in ["scenario_real_window_capture_review_ready", "scenario_real_window_capture_accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_1018-Source ist nicht review-ready."))
	if not bool(source.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_1018-Fenster-Capture ist nicht trusted."))
	if not bool(source.get("window_screenshot_written", false)):
		blockers.append(_issue("source_window_screenshot_missing", "TASK_1018-Fenster-Screenshot fehlt."))
	if String(source.get("source_task_id", "")) != "TASK_1017":
		blockers.append(_issue("source_scenario_task_mismatch", "TASK_1018-Source nennt nicht TASK_1017 als Scenario-Playability-Quelle."))
	if String(source.get("source_schema", "")) != "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_playability_slice.v1":
		blockers.append(_issue("source_scenario_schema_mismatch", "TASK_1018-Source-Schema zur Scenario-Playability passt nicht."))
	if String(source.get("source_gate", "")) != "scenario_playability_passed":
		blockers.append(_issue("source_scenario_gate_mismatch", "TASK_1018-Source-Gate ist nicht scenario_playability_passed."))
	if not bool(source.get("source_scenario_playability_slice_passed", false)):
		blockers.append(_issue("source_scenario_playability_not_passed", "TASK_1018-Source bestaetigt den Scenario-Playability-Slice nicht."))
	var playability_line: String = String(source.get("source_scenario_playability_line", "")).strip_edges()
	if playability_line.is_empty():
		blockers.append(_issue("source_scenario_playability_line_missing", "TASK_1018-Source enthaelt keine Scenario-Playability-Zeile."))
	if not playability_line.contains("FOB") or not playability_line.contains("NEXT") or not playability_line.contains("GO") or not playability_line.contains("FEEDBACK"):
		blockers.append(_issue("source_scenario_playability_line_incomplete", "Die Scenario-Playability-Zeile muss FOB, NEXT, GO und FEEDBACK nennen."))
	if not bool(source.get("read_only", false)) or not bool(source.get("read_only_capture", false)):
		blockers.append(_issue("source_not_read_only", "TASK_1018-Source ist nicht read-only/read-only-capture."))
	if bool(source.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_1018-Source darf keine UI-Gameplay-Wahrheit setzen."))
	if bool(source.get("creates_command", true)) or bool(source.get("creates_movement", true)):
		blockers.append(_issue("source_mutates_command_or_movement", "TASK_1018-Source darf keine Commands oder Movement erzeugen."))
	if bool(source.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_1018-Source darf keine Multiplayer-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(notes: Dictionary) -> Array:
	var issues: Array = []
	_append_false_issue(issues, notes, "correct_window_content_confirmed", "correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht.")
	_append_false_issue(issues, notes, "fob_entry_surface_visible", "fob_entry_surface_not_visible", "Die FOB-Entry-Flaeche ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "fob_entry_surface_readable", "fob_entry_surface_not_readable", "Die FOB-Entry-Flaeche ist im echten Fenster nicht lesbar.")
	_append_false_issue(issues, notes, "objective_surface_visible", "objective_surface_not_visible", "Die Objective-Flaeche ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "objective_surface_readable", "objective_surface_not_readable", "Die Objective-Flaeche ist im echten Fenster nicht lesbar.")
	_append_false_issue(issues, notes, "roles_surface_visible", "roles_surface_not_visible", "Die Alpha-/Bravo-Rollenflaeche ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "roles_surface_readable", "roles_surface_not_readable", "Die Alpha-/Bravo-Rollenflaeche ist im echten Fenster nicht lesbar.")
	_append_false_issue(issues, notes, "next_confirm_go_flow_visible", "next_confirm_go_flow_not_visible", "Der NEXT/CONFIRM/GO-Ablauf ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "next_confirm_go_flow_readable", "next_confirm_go_flow_not_readable", "Der NEXT/CONFIRM/GO-Ablauf ist im echten Fenster nicht lesbar.")
	_append_false_issue(issues, notes, "go_boundary_visible", "go_boundary_not_visible", "Die GO-separat-Grenze ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "feedback_line_visible", "feedback_line_not_visible", "Die Feedback-Zeile ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "feedback_line_readable", "feedback_line_not_readable", "Die Feedback-Zeile ist im echten Fenster nicht lesbar.")
	_append_false_issue(issues, notes, "calm_hud_guidance_visible", "calm_hud_guidance_not_visible", "Die ruhige HUD-Fuehrung ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "scenario_playability_line_visible", "scenario_playability_line_not_visible", "Die Scenario-Playability-Zeile ist im echten Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "no_new_hud_gameplay_truth", "hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt nicht, dass das HUD keine neue Gameplay-Wahrheit setzt.")
	_append_false_issue(issues, notes, "multiplayer_boundary_preserved", "multiplayer_boundary_risk", "Der Sichtbefund bestaetigt die Multiplayer-Grenze nicht.")
	_append_false_issue(issues, notes, "player_readability_ok", "player_readability_not_ok", "Der Szenario-Griff liest sich fuer den Spieler noch nicht eindeutig genug.")
	return issues


static func _build_positive_findings(notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, notes, "fob_entry_surface_visible", "FOB-Entry-Flaeche ist sichtbar.")
	_append_positive(positive, notes, "fob_entry_surface_readable", "FOB-Entry-Flaeche ist lesbar.")
	_append_positive(positive, notes, "objective_surface_visible", "Objective-Flaeche ist sichtbar.")
	_append_positive(positive, notes, "objective_surface_readable", "Objective-Flaeche ist lesbar.")
	_append_positive(positive, notes, "roles_surface_visible", "Alpha-/Bravo-Rollen sind sichtbar.")
	_append_positive(positive, notes, "roles_surface_readable", "Alpha-/Bravo-Rollen sind lesbar.")
	_append_positive(positive, notes, "next_confirm_go_flow_visible", "NEXT/CONFIRM/GO-Ablauf ist sichtbar.")
	_append_positive(positive, notes, "next_confirm_go_flow_readable", "NEXT/CONFIRM/GO-Ablauf ist lesbar.")
	_append_positive(positive, notes, "go_boundary_visible", "GO-separat-Grenze ist sichtbar.")
	_append_positive(positive, notes, "feedback_line_visible", "Feedback-Zeile ist sichtbar.")
	_append_positive(positive, notes, "feedback_line_readable", "Feedback-Zeile ist lesbar.")
	_append_positive(positive, notes, "calm_hud_guidance_visible", "HUD-Fuehrung bleibt ruhig sichtbar.")
	_append_positive(positive, notes, "scenario_playability_line_visible", "Scenario-Playability-Zeile ist sichtbar.")
	_append_positive(positive, notes, "no_new_hud_gameplay_truth", "HUD erzeugt keine neue Gameplay-Wahrheit.")
	_append_positive(positive, notes, "multiplayer_boundary_preserved", "Multiplayer-Grenze bleibt bestaetigt.")
	_append_positive(positive, notes, "player_readability_ok", "Szenario-Griff ist fuer Spieler lesbar.")
	return positive


static func _append_false_issue(issues: Array, notes: Dictionary, note_id: String, issue_id: String, text: String) -> void:
	if not bool(notes.get(note_id, false)):
		issues.append(_issue(issue_id, text))


static func _append_positive(positive: Array, notes: Dictionary, note_id: String, text: String) -> void:
	if bool(notes.get(note_id, false)):
		positive.append({
			"id": note_id,
			"text": text,
		})


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
