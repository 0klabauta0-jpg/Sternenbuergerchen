class_name FirstDecisionRealPlaythroughVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.first_decision_real_playthrough_visual_findings.v1"
const TASK_ID: String = "TASK_958"
const SOURCE_TASK_ID: String = "TASK_957"
const SOURCE_MICRO_TASK_ID: String = "TASK_956"
const SOURCE_SCHEMA: String = "sternenbuergerchen.first_decision_real_playthrough_capture.v1"
const SOURCE_MICRO_SCHEMA: String = "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const NEXT_REVIEW_TASK: String = "TASK_958 - First Decision Real Playthrough Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_959 - First Decision Real Playthrough Polish Followup"
const NEXT_SMOKE_TASK: String = "TASK_959 - First Decision Playability Smoke"


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
			issues.append(_issue("manual_visual_review_open", "Der echte First-Decision-Fensterblick ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_manual_first_decision_window_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_first_decision_playability_smoke"
			recommended_next_task = NEXT_SMOKE_TASK
			recommended_direction = "run_first_decision_playability_smoke"
		elif manual_review_done:
			status = "ready_for_first_decision_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_first_decision_window_readability_before_smoke"
		else:
			status = "needs_manual_review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_micro_task_id": SOURCE_MICRO_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_review_ready": bool(source_snapshot.get("review_ready", false)),
		"source_accepted": bool(source_snapshot.get("accepted", false)),
		"source_micro_schema": String(source_snapshot.get("source_schema", "")),
		"source_micro_gate": String(source_snapshot.get("source_gate", "")),
		"source_micro_status": String(source_snapshot.get("source_status", "")),
		"window_screenshot_path": String(source_snapshot.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("desktop_screenshot_path", "")),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_957-Source-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_957."))
	var source_status: String = String(source_snapshot.get("status", ""))
	if not bool(source_snapshot.get("review_ready", false)) and source_status not in ["review_ready", "accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_957-Source ist nicht review-ready."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_MICRO_TASK_ID:
		blockers.append(_issue("source_micro_task_mismatch", "TASK_957-Source nennt nicht TASK_956 als Micro-Scenario-Quelle."))
	if String(source_snapshot.get("source_schema", "")) != SOURCE_MICRO_SCHEMA:
		blockers.append(_issue("source_micro_schema_mismatch", "TASK_956-Micro-Scenario-Schema fehlt oder passt nicht."))
	if not bool(source_snapshot.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_957-Fenster-Capture ist nicht trusted."))
	if not bool(source_snapshot.get("window_screenshot_written", false)):
		blockers.append(_issue("source_window_screenshot_missing", "TASK_957-Fenster-Screenshot fehlt."))
	if not bool(source_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_957-Source ist nicht read-only."))
	if bool(source_snapshot.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_957-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht."))
	if not bool(review_notes.get("next_line_visible", false)):
		issues.append(_issue("next_line_not_visible", "Die NEXT-Zeile ist im echten Fenster nicht klar sichtbar."))
	if not bool(review_notes.get("why_line_visible", false)):
		issues.append(_issue("why_line_not_visible", "Die WHY-Zeile ist im echten Fenster nicht klar sichtbar."))
	if not bool(review_notes.get("choice_rows_visible", false)):
		issues.append(_issue("choice_rows_not_visible", "Die Choice-Zeilen sind im echten Fenster nicht klar sichtbar."))
	if not bool(review_notes.get("recommendation_obvious", false)):
		issues.append(_issue("recommendation_not_obvious", "Die empfohlene erste Entscheidung ist nicht sofort erkennbar."))
	if not bool(review_notes.get("preview_boundary_clear", false)):
		issues.append(_issue("preview_boundary_unclear", "Die Grenze zwischen Preview und GO-Commit ist nicht klar genug."))
	if not bool(review_notes.get("go_surface_usable", false)):
		issues.append(_issue("go_surface_not_usable", "GO oder die passende Command-Flaeche ist im echten Fenster nicht gut bedienbar."))
	if not bool(review_notes.get("no_command_before_go_confirmed", false)):
		issues.append(_issue("pre_go_command_boundary_not_confirmed", "Der Sichtbefund bestaetigt nicht, dass vor GO kein Command committed wird."))
	if not bool(review_notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt die read-only-HUD-Grenze nicht."))
	if not bool(review_notes.get("player_readability_ok", false)):
		issues.append(_issue("player_readability_not_ok", "Der erste Decision-Blick liest sich noch nicht ruhig genug."))
	return issues


static func _build_positive_findings(review_notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, review_notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, review_notes, "next_line_visible", "NEXT-Zeile ist sichtbar.")
	_append_positive(positive, review_notes, "why_line_visible", "WHY-Zeile ist sichtbar.")
	_append_positive(positive, review_notes, "choice_rows_visible", "Choice-Zeilen sind sichtbar.")
	_append_positive(positive, review_notes, "recommendation_obvious", "Empfohlener erster Griff ist erkennbar.")
	_append_positive(positive, review_notes, "preview_boundary_clear", "Preview-vor-GO-Grenze ist klar.")
	_append_positive(positive, review_notes, "go_surface_usable", "GO-/Command-Flaeche bleibt bedienbar.")
	_append_positive(positive, review_notes, "no_command_before_go_confirmed", "Vor GO wird kein Command committed.")
	_append_positive(positive, review_notes, "no_new_hud_gameplay_truth", "Read-only HUD-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "player_readability_ok", "Spielerblick ist ruhig genug fuer den Smoke.")
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
