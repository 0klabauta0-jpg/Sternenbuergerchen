class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.v1"
const TASK_ID: String = "TASK_1039"
const SOURCE_TASK_ID: String = "TASK_1038"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.v1"
const REVIEW_TASK: String = "TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish"
const NEXT_ACCEPTANCE_TASK: String = "TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"


static func build_snapshot(source_capture: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_capture.duplicate(true)
	var notes: Dictionary = review_notes.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var review_available: bool = bool(notes.get("review_available", false))
	var issues: Array = []
	var positive_findings: Array = []
	if blockers.is_empty():
		if review_available:
			issues = _build_visual_issues(notes)
			positive_findings = _build_positive_findings(notes)
		else:
			issues.append(_issue("first_contact_visual_review_missing", "Der TASK_1039-First-Contact-Sichtbefund fehlt noch."))
	var accepted: bool = blockers.is_empty() and review_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "first_contact_visual_blocked"
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "complete_first_contact_visual_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_first_contact_acceptance_slice"
			gate = "first_contact_visual_accepted"
			recommended_next_task = NEXT_ACCEPTANCE_TASK
			recommended_direction = "build_first_contact_acceptance_slice"
		elif review_available:
			status = "ready_for_first_contact_visual_polish"
			gate = "first_contact_visual_polish_needed"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "polish_first_contact_visuals"
		else:
			status = "needs_first_contact_visual_review"
			gate = "needs_first_contact_visual_review"
	var summary_line: String = _build_summary_line(status, source, notes, issues, blockers)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_gate": String(source.get("gate", "")),
		"source_accepted": bool(source.get("accepted", false)),
		"source_review_ready": bool(source.get("review_ready", false)),
		"source_first_contact_task_id": String(source.get("source_task_id", "")),
		"source_first_contact_schema": String(source.get("source_schema", "")),
		"source_first_contact_status": String(source.get("source_status", "")),
		"source_first_contact_gate": String(source.get("source_gate", "")),
		"source_first_contact_playability_line": String(source.get("source_first_contact_playability_line", "")),
		"source_first_contact_feedback_line": String(source.get("source_first_contact_feedback_line", "")),
		"source_first_contact_playability_slice_passed": bool(source.get("source_first_contact_playability_slice_passed", false)),
		"manifest_available": bool(source.get("manifest_available", false)),
		"launch_argument": String(source.get("launch_argument", "")),
		"window_capture_method": String(source.get("window_capture_method", "")),
		"window_capture_trusted": bool(source.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(source.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(source.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(source.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(source.get("desktop_screenshot_path", "")),
		"review_notes": notes,
		"review_available": review_available,
		"manual_review_required": true,
		"manual_review_done": review_available,
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"first_contact_visual_findings_summary_line": summary_line,
		"ready_for_first_contact_acceptance_slice": accepted,
		"accepted": accepted,
		"status": status,
		"gate": gate,
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1038-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1038."))
	if String(source.get("status", "")) != "accepted" or String(source.get("gate", "")) != "first_contact_real_window_capture_accepted" or not bool(source.get("accepted", false)):
		blockers.append(_issue("source_not_accepted", "TASK_1038-First-Contact-Window-Capture ist nicht akzeptiert."))
	if String(source.get("source_task_id", "")) != "TASK_1037":
		blockers.append(_issue("source_first_contact_task_mismatch", "TASK_1038-Source nennt nicht TASK_1037 als Playability-Quelle."))
	if String(source.get("source_schema", "")) != "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.v1":
		blockers.append(_issue("source_first_contact_schema_mismatch", "TASK_1038-Playability-Source-Schema passt nicht."))
	if String(source.get("source_gate", "")) != "first_contact_playability_passed":
		blockers.append(_issue("source_first_contact_gate_mismatch", "TASK_1038-Playability-Source-Gate ist nicht first_contact_playability_passed."))
	if not bool(source.get("source_first_contact_playability_slice_passed", false)):
		blockers.append(_issue("source_first_contact_playability_not_passed", "TASK_1038 bestaetigt den First-Contact-Playability-Slice nicht."))
	var playability_line: String = String(source.get("source_first_contact_playability_line", "")).strip_edges()
	if playability_line.is_empty():
		blockers.append(_issue("source_first_contact_playability_line_missing", "TASK_1038-Source enthaelt keine First-Contact-Playability-Zeile."))
	if not playability_line.contains("CONTACT") or not playability_line.contains("WHY") or not playability_line.contains("NEXT") or not playability_line.contains("GO") or not playability_line.contains("FIRE/WAIT"):
		blockers.append(_issue("source_first_contact_playability_line_incomplete", "Die First-Contact-Playability-Zeile muss CONTACT, WHY, NEXT, GO und FIRE/WAIT nennen."))
	if not bool(source.get("window_capture_trusted", false)):
		blockers.append(_issue("source_window_capture_not_trusted", "TASK_1038-Fenster-Capture ist nicht trusted."))
	if not bool(source.get("window_screenshot_written", false)) or String(source.get("window_screenshot_path", "")).strip_edges().is_empty():
		blockers.append(_issue("source_window_screenshot_missing", "TASK_1038-Fenster-Screenshot fehlt."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1038-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_visual_issues(notes: Dictionary) -> Array:
	var issues: Array = []
	_append_false_issue(issues, notes, "contact_surface_visible", "contact_surface_not_visible", "CONTACT ist im echten First-Contact-Fenster nicht sichtbar.")
	_append_false_issue(issues, notes, "why_surface_actionable", "why_surface_not_actionable", "WHY erklaert die Gefahr noch nicht handlungsfaehig.")
	_append_false_issue(issues, notes, "next_surface_visible", "next_surface_not_visible", "NEXT ist nach dem Kontakt nicht sichtbar.")
	_append_false_issue(issues, notes, "fire_wait_choice_visible", "fire_wait_choice_not_visible", "FIRE/WAIT ist nicht als echte Wahl sichtbar.")
	_append_false_issue(issues, notes, "go_boundary_visible", "go_boundary_not_visible", "Die GO-separat-Grenze ist nicht klar sichtbar.")
	_append_false_issue(issues, notes, "feedback_line_visible", "feedback_line_not_visible", "Die Feedback-Zeile ist nicht sichtbar.")
	_append_false_issue(issues, notes, "hud_stays_calm", "hud_too_noisy", "Das HUD wirkt fuer den First-Contact-Griff zu laut.")
	_append_false_issue(issues, notes, "multiplayer_boundary_clear", "multiplayer_boundary_unclear", "Die Multiplayer-/Wahrheitsgrenze ist visuell nicht klar.")
	_append_false_issue(issues, notes, "first_contact_feels_visual", "first_contact_does_not_feel_visual", "Der erste Kontakt liest sich noch nicht wie ein sichtbarer Entscheidungsmoment.")
	return issues


static func _build_positive_findings(notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, notes, "contact_surface_visible", "CONTACT ist sichtbar.")
	_append_positive(positive, notes, "why_surface_actionable", "WHY macht die Gefahr handlungsfaehig.")
	_append_positive(positive, notes, "next_surface_visible", "NEXT bleibt sichtbar.")
	_append_positive(positive, notes, "fire_wait_choice_visible", "FIRE/WAIT ist sichtbar.")
	_append_positive(positive, notes, "go_boundary_visible", "GO separat ist sichtbar.")
	_append_positive(positive, notes, "feedback_line_visible", "Feedback ist sichtbar.")
	_append_positive(positive, notes, "hud_stays_calm", "HUD bleibt ruhig.")
	_append_positive(positive, notes, "multiplayer_boundary_clear", "Multiplayer-Grenze bleibt klar.")
	_append_positive(positive, notes, "first_contact_feels_visual", "First Contact fuehlt sich als visueller Entscheidungsmoment an.")
	return positive


static func _build_summary_line(status: String, source: Dictionary, notes: Dictionary, issues: Array, blockers: Array) -> String:
	if not blockers.is_empty():
		return "FIRST CONTACT VISUAL BLOCKED: %s" % String(Dictionary(blockers[0]).get("text", "Source blockiert."))
	if status == "accepted_for_first_contact_acceptance_slice":
		var note_summary: String = String(notes.get("summary", "")).strip_edges()
		if note_summary.is_empty():
			note_summary = "CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und GO sind sichtbar."
		return "FIRST CONTACT VISUAL PASS: CONTACT | WHY | NEXT | FIRE/WAIT | FEEDBACK | GO separat - %s" % note_summary
	if status == "ready_for_first_contact_visual_polish" and not issues.is_empty():
		return "FIRST CONTACT VISUAL POLISH: %s" % String(Dictionary(issues[0]).get("text", "Sichtreibung vorhanden."))
	return "FIRST CONTACT VISUAL REVIEW: %s" % String(source.get("source_first_contact_playability_line", "CONTACT/WHY/NEXT/FIRE/WAIT/GO pruefen."))


static func _append_false_issue(issues: Array, notes: Dictionary, note_id: String, issue_id: String, text: String) -> void:
	if not bool(notes.get(note_id, false)):
		issues.append(_issue(issue_id, text))


static func _append_positive(positive: Array, notes: Dictionary, note_id: String, text: String) -> void:
	if bool(notes.get(note_id, false)):
		positive.append({
			"id": note_id,
			"text": text,
		})


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and bool(snapshot.get("read_only_capture", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
