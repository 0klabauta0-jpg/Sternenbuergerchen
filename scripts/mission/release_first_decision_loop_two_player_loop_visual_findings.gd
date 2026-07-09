class_name ReleaseFirstDecisionLoopTwoPlayerLoopVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_findings.v1"
const TASK_ID: String = "TASK_982"
const SOURCE_TASK_ID: String = "TASK_981"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_real_window_capture.v1"
const NEXT_REVIEW_TASK: String = "TASK_982 - Release First Decision Loop Two Player Loop Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_983 - Release First Decision Loop Two Player Loop Visual Polish"
const NEXT_ACCEPTANCE_TASK: String = "TASK_983 - Release First Decision Loop Two Player Loop Acceptance Slice"


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
			issues.append(_issue("manual_player_loop_visual_review_open", "Der echte Player-Loop-Choice-Fensterblick ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_manual_player_loop_window_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_player_loop_acceptance_slice"
			recommended_next_task = NEXT_ACCEPTANCE_TASK
			recommended_direction = "build_player_loop_acceptance_slice"
		elif manual_review_done:
			status = "ready_for_player_loop_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_player_loop_choice_readability"
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
		"source_selected_choice_id": String(source_snapshot.get("source_selected_choice_id", "")),
		"source_selected_button_text": String(source_snapshot.get("source_selected_button_text", "")),
		"source_selected_button_slot": String(source_snapshot.get("source_selected_button_slot", "")),
		"source_smoke_line": String(source_snapshot.get("source_smoke_line", "")),
		"source_post_confirm_feedback_line": String(source_snapshot.get("source_post_confirm_feedback_line", "")),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_981-Source-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_981."))
	var source_status: String = String(source_snapshot.get("status", ""))
	var source_gate: String = String(source_snapshot.get("gate", ""))
	if not bool(source_snapshot.get("review_ready", false)) and source_status not in ["review_ready", "accepted"] and source_gate not in ["real_window_capture_review_ready", "real_window_capture_accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_981-Source ist nicht review-ready."))
	if not bool(source_snapshot.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_981-Fenster-Capture ist nicht trusted."))
	if not bool(source_snapshot.get("window_screenshot_written", false)):
		blockers.append(_issue("source_window_screenshot_missing", "TASK_981-Fenster-Screenshot fehlt."))
	if String(source_snapshot.get("source_task_id", "")) != "TASK_980":
		blockers.append(_issue("source_smoke_task_mismatch", "TASK_981-Source nennt nicht TASK_980 als Choice-Confirm-Smoke-Quelle."))
	if not String(source_snapshot.get("source_smoke_line", "")).contains("CHOICE"):
		blockers.append(_issue("source_smoke_line_missing_choice", "TASK_981-Source-Smoke-Zeile nennt CHOICE nicht."))
	if not String(source_snapshot.get("source_smoke_line", "")).contains("GO"):
		blockers.append(_issue("source_smoke_line_missing_go", "TASK_981-Source-Smoke-Zeile nennt GO nicht."))
	if String(source_snapshot.get("source_post_confirm_feedback_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_post_confirm_feedback_missing", "TASK_981-Source enthaelt kein Post-Confirm-Feedback."))
	if not bool(source_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_981-Source ist nicht read-only."))
	if bool(source_snapshot.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_981-Source darf keine UI-Gameplay-Wahrheit setzen."))
	if bool(source_snapshot.get("sets_multiplayer_truth", true)):
		blockers.append(_issue("source_sets_multiplayer_truth", "TASK_981-Source darf keine Multiplayer-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht."))
	if not bool(review_notes.get("runtime_choice_buttons_visible", false)):
		issues.append(_issue("runtime_choice_buttons_not_visible", "Die vier Runtime-Choice-Buttons sind im echten Fenster nicht klar sichtbar."))
	if not bool(review_notes.get("runtime_choice_buttons_readable", false)):
		issues.append(_issue("runtime_choice_buttons_not_readable", "Die vier Runtime-Choice-Buttons sind im echten Fenster nicht gut lesbar."))
	if not bool(review_notes.get("all_four_choice_tokens_visible", false)):
		issues.append(_issue("choice_tokens_incomplete", "`SECURE`, `PUSH`, `FLANK` und `RESET` sind nicht alle sichtbar."))
	if not bool(review_notes.get("choice_confirm_observed", false)):
		issues.append(_issue("choice_confirm_not_observed", "Der Choice-Confirm wurde im echten Fenster nicht beobachtet."))
	if not bool(review_notes.get("choice_confirm_feedback_visible", false)):
		issues.append(_issue("choice_confirm_feedback_not_visible", "Post-Confirm-Feedback ist im echten Fenster nicht sichtbar."))
	if not bool(review_notes.get("choice_confirm_feedback_readable", false)):
		issues.append(_issue("choice_confirm_feedback_not_readable", "Post-Confirm-Feedback ist im echten Fenster nicht gut lesbar."))
	if not bool(review_notes.get("go_button_still_separate", false)):
		issues.append(_issue("go_button_separation_unclear", "`GO` wirkt im echten Fenster nicht klar als separater Schritt."))
	if not bool(review_notes.get("no_go_before_go_confirmed", false)):
		issues.append(_issue("pre_go_command_boundary_not_confirmed", "Der Sichtbefund bestaetigt nicht, dass vor `GO` kein Execute passiert."))
	if not bool(review_notes.get("choice_confirm_smoke_line_visible", false)):
		issues.append(_issue("choice_confirm_smoke_line_not_visible", "Die Choice-Confirm-Smoke-Zeile ist im echten Fenster nicht sichtbar."))
	if not bool(review_notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt die read-only-HUD-Grenze nicht."))
	if not bool(review_notes.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Sichtbefund bestaetigt die Multiplayer-Grenze nicht."))
	if not bool(review_notes.get("player_readability_ok", false)):
		issues.append(_issue("player_readability_not_ok", "Der Player-Loop mit vier Choices liest sich noch nicht rund genug."))
	return issues


static func _build_positive_findings(review_notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, review_notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, review_notes, "runtime_choice_buttons_visible", "Runtime-Choice-Buttons sind sichtbar.")
	_append_positive(positive, review_notes, "runtime_choice_buttons_readable", "Runtime-Choice-Buttons sind lesbar.")
	_append_positive(positive, review_notes, "all_four_choice_tokens_visible", "`SECURE`, `PUSH`, `FLANK` und `RESET` sind sichtbar.")
	_append_positive(positive, review_notes, "choice_confirm_observed", "Choice-Confirm wurde beobachtet.")
	_append_positive(positive, review_notes, "choice_confirm_feedback_visible", "Post-Confirm-Feedback ist sichtbar.")
	_append_positive(positive, review_notes, "choice_confirm_feedback_readable", "Post-Confirm-Feedback ist lesbar.")
	_append_positive(positive, review_notes, "go_button_still_separate", "`GO` bleibt sichtbar separater Schritt.")
	_append_positive(positive, review_notes, "no_go_before_go_confirmed", "Vor `GO` wird nicht ausgefuehrt.")
	_append_positive(positive, review_notes, "choice_confirm_smoke_line_visible", "Choice-Confirm-Smoke-Zeile ist sichtbar.")
	_append_positive(positive, review_notes, "no_new_hud_gameplay_truth", "Read-only-HUD-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "multiplayer_boundary_preserved", "Multiplayer-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "player_readability_ok", "Vier-Choice-Spielerloop ist ruhig genug fuer den Acceptance-Slice.")
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
