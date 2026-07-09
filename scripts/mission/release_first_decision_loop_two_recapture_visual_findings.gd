class_name ReleaseFirstDecisionLoopTwoRecaptureVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_recapture_visual_findings.v1"
const TASK_ID: String = "TASK_974"
const SOURCE_TASK_ID: String = "TASK_973"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_real_window_recapture.v1"
const NEXT_REVIEW_TASK: String = "TASK_974 - Release First Decision Loop Two Recapture Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_975 - Release First Decision Loop Two Recapture Visual Polish"
const NEXT_ACCEPTANCE_TASK: String = "TASK_975 - Release First Decision Loop Two Acceptance Slice"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", false))
	var issues: Array = []
	var positive_findings: Array = []
	if blockers.is_empty():
		if manual_review_done:
			issues = _build_visual_issues(review_notes)
			positive_findings = _build_positive_findings(review_notes)
		else:
			issues.append(_issue("manual_loop_two_recapture_visual_review_open", "Der echte zweite Decision-Recapture ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_manual_loop_two_recapture_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_loop_two_acceptance_slice"
			recommended_next_task = NEXT_ACCEPTANCE_TASK
			recommended_direction = "build_loop_two_acceptance_slice"
		elif manual_review_done:
			status = "ready_for_loop_two_recapture_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_loop_two_recapture_readability"
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
		"source_smoke_task_id": String(source_snapshot.get("source_task_id", "")),
		"source_smoke_schema": String(source_snapshot.get("source_schema", "")),
		"source_smoke_gate": String(source_snapshot.get("source_gate", "")),
		"source_smoke_status": String(source_snapshot.get("source_status", "")),
		"source_smoke_line": String(source_snapshot.get("source_smoke_line", "")),
		"source_post_go_feedback_line": String(source_snapshot.get("source_post_go_feedback_line", "")),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_973-Source-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_973."))
	var source_status: String = String(source_snapshot.get("status", ""))
	var source_gate: String = String(source_snapshot.get("gate", ""))
	if not bool(source_snapshot.get("review_ready", false)) and source_status not in ["review_ready", "accepted"] and source_gate not in ["real_window_recapture_review_ready", "real_window_recapture_accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_973-Source ist nicht review-ready."))
	if not bool(source_snapshot.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_973-Fenster-Capture ist nicht trusted."))
	if not bool(source_snapshot.get("window_screenshot_written", false)):
		blockers.append(_issue("source_window_screenshot_missing", "TASK_973-Fenster-Screenshot fehlt."))
	if String(source_snapshot.get("source_task_id", "")) != "TASK_972":
		blockers.append(_issue("source_smoke_task_mismatch", "TASK_973-Source nennt nicht TASK_972 als Smoke-Quelle."))
	if not String(source_snapshot.get("source_smoke_line", "")).contains("2ND"):
		blockers.append(_issue("source_smoke_line_missing_2nd", "TASK_973-Source-Smoke-Zeile nennt 2ND nicht."))
	if not String(source_snapshot.get("source_smoke_line", "")).contains("GO"):
		blockers.append(_issue("source_smoke_line_missing_go", "TASK_973-Source-Smoke-Zeile nennt GO nicht."))
	if String(source_snapshot.get("source_post_go_feedback_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_post_go_feedback_missing", "TASK_973-Source enthaelt kein Post-GO-Feedback."))
	if not bool(source_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_973-Source ist nicht read-only."))
	if bool(source_snapshot.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_973-Source darf keine UI-Gameplay-Wahrheit setzen."))
	if bool(source_snapshot.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_973-Source darf keine Multiplayer-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht."))
	if not bool(review_notes.get("second_decision_button_visible", false)):
		issues.append(_issue("second_decision_button_not_visible", "Der `2ND`-Button ist im Recapture nicht klar sichtbar."))
	if not bool(review_notes.get("second_decision_confirmed", false)):
		issues.append(_issue("second_decision_not_confirmed", "Der zweite Griff wurde im Recapture nicht bestaetigt."))
	if not bool(review_notes.get("go_button_still_separate", false)):
		issues.append(_issue("go_button_separation_unclear", "`GO` wirkt im Recapture nicht klar als separater Schritt."))
	if not bool(review_notes.get("go_executed_after_confirm", false)):
		issues.append(_issue("go_execution_not_confirmed", "`GO` wurde nach dem zweiten Griff nicht bestaetigt."))
	if not bool(review_notes.get("post_go_feedback_visible", false)):
		issues.append(_issue("post_go_feedback_not_visible", "Post-GO-Feedback ist im Recapture nicht sichtbar."))
	if not bool(review_notes.get("loop_two_smoke_line_visible", false)):
		issues.append(_issue("loop_two_smoke_line_not_visible", "Die `2ND -> GO -> Feedback`-Smoke-Zeile ist im Recapture nicht sichtbar."))
	if not bool(review_notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt die read-only-HUD-Grenze nicht."))
	if not bool(review_notes.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Sichtbefund bestaetigt die Multiplayer-Grenze nicht."))
	if not bool(review_notes.get("player_readability_ok", false)):
		issues.append(_issue("player_readability_not_ok", "Der zweite Decision-Recapture liest sich noch nicht rund genug."))
	return issues


static func _build_positive_findings(review_notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, review_notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, review_notes, "second_decision_button_visible", "`2ND`-Button ist sichtbar.")
	_append_positive(positive, review_notes, "second_decision_confirmed", "Zweiter Griff wurde bestaetigt.")
	_append_positive(positive, review_notes, "go_button_still_separate", "`GO` bleibt sichtbar separater Schritt.")
	_append_positive(positive, review_notes, "go_executed_after_confirm", "`GO` wurde nach dem zweiten Griff ausgefuehrt.")
	_append_positive(positive, review_notes, "post_go_feedback_visible", "Post-GO-Feedback ist sichtbar.")
	_append_positive(positive, review_notes, "loop_two_smoke_line_visible", "`2ND -> GO -> Feedback`-Zeile ist sichtbar.")
	_append_positive(positive, review_notes, "no_new_hud_gameplay_truth", "Read-only-HUD-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "multiplayer_boundary_preserved", "Multiplayer-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "player_readability_ok", "Zweiter Decision-Recapture ist ruhig genug fuer den Acceptance-Slice.")
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
