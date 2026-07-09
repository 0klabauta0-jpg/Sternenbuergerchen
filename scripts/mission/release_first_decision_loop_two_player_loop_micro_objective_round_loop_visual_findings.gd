class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.v1"
const TASK_ID: String = "TASK_1005"
const SOURCE_TASK_ID: String = "TASK_1004"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.v1"
const NEXT_REVIEW_TASK: String = "TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish"
const NEXT_PLAYABILITY_TASK: String = "TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_snapshot.duplicate(true)
	var notes: Dictionary = review_notes.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var manual_review_done: bool = bool(notes.get("manual_round_loop_visual_review_done", false))
	var issues: Array = []
	var positive_findings: Array = []
	if blockers.is_empty():
		if manual_review_done:
			issues = _build_visual_issues(notes)
			positive_findings = _build_positive_findings(notes)
		else:
			issues.append(_issue("manual_round_loop_visual_review_open", "Der echte TASK_1005-Round-Loop-Fensterblick ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_manual_round_loop_window_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_round_loop_playability_slice"
			recommended_next_task = NEXT_PLAYABILITY_TASK
			recommended_direction = "build_round_loop_playability_slice"
		elif manual_review_done:
			status = "ready_for_round_loop_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_round_loop_window_readability"
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
		"source_round_loop_task_id": String(source.get("source_task_id", "")),
		"source_round_loop_schema": String(source.get("source_schema", "")),
		"source_round_loop_status": String(source.get("source_status", "")),
		"source_runtime_surface_spec_count": int(source.get("source_runtime_surface_spec_count", 0)),
		"source_runtime_surface_specs": Array(source.get("source_runtime_surface_specs", [])).duplicate(true),
		"source_selected_fireteam_runtime_line": String(source.get("source_selected_fireteam_runtime_line", "")),
		"source_mission_control_runtime_line": String(source.get("source_mission_control_runtime_line", "")),
		"source_command_feedback_runtime_line": String(source.get("source_command_feedback_runtime_line", "")),
		"source_runtime_lines_within_limit": bool(source.get("source_runtime_lines_within_limit", false)),
		"source_go_separation_visible": bool(source.get("source_go_separation_visible", false)),
		"source_next_decision_visible": bool(source.get("source_next_decision_visible", false)),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1004-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1004."))
	var source_status: String = String(source.get("status", ""))
	var source_gate: String = String(source.get("gate", ""))
	if not bool(source.get("review_ready", false)) and source_status not in ["review_ready", "accepted"] and source_gate not in ["round_loop_real_window_capture_review_ready", "round_loop_real_window_capture_accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_1004-Source ist nicht review-ready."))
	if not bool(source.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_1004-Fenster-Capture ist nicht trusted."))
	if not bool(source.get("window_screenshot_written", false)):
		blockers.append(_issue("source_window_screenshot_missing", "TASK_1004-Fenster-Screenshot fehlt."))
	if String(source.get("source_task_id", "")) != "TASK_1003":
		blockers.append(_issue("source_round_loop_task_mismatch", "TASK_1004-Source nennt nicht TASK_1003 als Runtime-Polish-Quelle."))
	if int(source.get("source_runtime_surface_spec_count", 0)) < 3:
		blockers.append(_issue("source_round_loop_surfaces_missing", "TASK_1004-Source enthaelt nicht alle ROUND/NEXT/GO-Surfaces."))
	if String(source.get("source_selected_fireteam_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_selected_fireteam_line_missing", "Selected-Fireteam-Round-Loop-Zeile fehlt."))
	if String(source.get("source_mission_control_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_mission_control_line_missing", "Mission-Control-Round-Loop-Zeile fehlt."))
	if String(source.get("source_command_feedback_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_command_feedback_line_missing", "Command-Feedback-Round-Loop-Zeile fehlt."))
	if not bool(source.get("source_go_separation_visible", false)):
		blockers.append(_issue("source_go_separation_missing", "TASK_1004-Source bestaetigt die GO-Grenze nicht."))
	if not bool(source.get("source_next_decision_visible", false)):
		blockers.append(_issue("source_next_decision_missing", "TASK_1004-Source bestaetigt NEXT nicht."))
	if not bool(source.get("read_only", false)) or not bool(source.get("read_only_capture", false)):
		blockers.append(_issue("source_not_read_only", "TASK_1004-Source ist nicht read-only/read-only-capture."))
	if bool(source.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_1004-Source darf keine UI-Gameplay-Wahrheit setzen."))
	if bool(source.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_1004-Source darf keine Multiplayer-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht."))
	if not bool(notes.get("round_surface_visible", false)):
		issues.append(_issue("round_surface_not_visible", "Die ROUND-Surface ist im echten Fenster nicht sichtbar."))
	if not bool(notes.get("next_surface_visible", false)):
		issues.append(_issue("next_surface_not_visible", "Die NEXT-Surface ist im echten Fenster nicht sichtbar."))
	if not bool(notes.get("go_separation_visible", false)):
		issues.append(_issue("go_separation_not_visible", "Die GO-separat-Grenze ist im echten Fenster nicht sichtbar."))
	if not bool(notes.get("selected_fireteam_runtime_line_visible", false)):
		issues.append(_issue("selected_fireteam_runtime_line_not_visible", "Die Selected-Fireteam-Round-Loop-Zeile ist nicht sichtbar."))
	if not bool(notes.get("mission_control_runtime_line_visible", false)):
		issues.append(_issue("mission_control_runtime_line_not_visible", "Die Mission-Control-Round-Loop-Zeile ist nicht sichtbar."))
	if not bool(notes.get("command_feedback_runtime_line_visible", false)):
		issues.append(_issue("command_feedback_runtime_line_not_visible", "Die Command-Feedback-Round-Loop-Zeile ist nicht sichtbar."))
	if not bool(notes.get("player_round_loop_readable", false)):
		issues.append(_issue("player_round_loop_not_readable", "Der Round-Loop liest sich fuer den Spieler noch nicht eindeutig genug."))
	if not bool(notes.get("hud_read_only_boundary_ok", false)):
		issues.append(_issue("hud_read_only_boundary_risk", "Der Sichtbefund bestaetigt die HUD-read-only-Grenze nicht."))
	if not bool(notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt nicht, dass das HUD keine neue Gameplay-Wahrheit setzt."))
	if not bool(notes.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Sichtbefund bestaetigt die Multiplayer-Grenze nicht."))
	return issues


static func _build_positive_findings(notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, notes, "round_surface_visible", "ROUND-Surface ist sichtbar.")
	_append_positive(positive, notes, "next_surface_visible", "NEXT-Surface ist sichtbar.")
	_append_positive(positive, notes, "go_separation_visible", "GO-separat-Grenze ist sichtbar.")
	_append_positive(positive, notes, "selected_fireteam_runtime_line_visible", "Selected-Fireteam-Round-Loop-Zeile ist sichtbar.")
	_append_positive(positive, notes, "mission_control_runtime_line_visible", "Mission-Control-Round-Loop-Zeile ist sichtbar.")
	_append_positive(positive, notes, "command_feedback_runtime_line_visible", "Command-Feedback-Round-Loop-Zeile ist sichtbar.")
	_append_positive(positive, notes, "player_round_loop_readable", "Round-Loop ist fuer Spieler lesbar.")
	_append_positive(positive, notes, "hud_read_only_boundary_ok", "HUD-read-only-Grenze bleibt bestaetigt.")
	_append_positive(positive, notes, "no_new_hud_gameplay_truth", "HUD erzeugt keine neue Gameplay-Wahrheit.")
	_append_positive(positive, notes, "multiplayer_boundary_preserved", "Multiplayer-Grenze bleibt bestaetigt.")
	return positive


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
