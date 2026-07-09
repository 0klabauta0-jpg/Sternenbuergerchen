class_name DecisionOverlayRealWindowVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.decision_overlay_real_window_visual_findings.v1"
const TASK_ID: String = "TASK_954"
const SOURCE_TASK_ID: String = "TASK_953"
const SOURCE_POLISH_TASK_ID: String = "TASK_952"
const SOURCE_SCHEMA: String = "sternenbuergerchen.decision_overlay_real_window_recapture.v1"
const SOURCE_POLISH_SCHEMA: String = "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"
const SOURCE_STYLE_ID: String = "task_952_decision_overlay_compact_badges_v1"
const NEXT_REVIEW_TASK: String = "TASK_954 - Decision Overlay Real Window Visual Findings"
const NEXT_POLISH_TASK: String = "TASK_955 - Decision Overlay Real Window Polish Followup"
const NEXT_SMOKE_TASK: String = "TASK_955 - Decision Overlay Playability Smoke"


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
			issues.append(_issue("manual_visual_review_open", "Der echte Decision-Overlay-Fensterbefund ist noch nicht manuell bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_manual_decision_overlay_window_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_decision_overlay_playability_smoke"
			recommended_next_task = NEXT_SMOKE_TASK
			recommended_direction = "run_decision_overlay_playability_smoke"
		elif manual_review_done:
			status = "ready_for_decision_overlay_visual_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_decision_overlay_visuals_before_smoke"
		else:
			status = "needs_manual_review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_polish_task_id": SOURCE_POLISH_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_review_ready": bool(source_snapshot.get("review_ready", false)),
		"source_accepted": bool(source_snapshot.get("accepted", false)),
		"source_polish_schema": String(source_snapshot.get("source_schema", "")),
		"source_style_id": String(source_snapshot.get("source_style_id", "")),
		"source_gate": String(source_snapshot.get("source_gate", "")),
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
		blockers.append(_issue("source_schema_mismatch", "TASK_953-Source-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_953."))
	var source_status: String = String(source_snapshot.get("status", ""))
	if not bool(source_snapshot.get("review_ready", false)) and source_status not in ["review_ready", "accepted"]:
		blockers.append(_issue("source_not_review_ready", "TASK_953-Source ist nicht review-ready."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_POLISH_TASK_ID:
		blockers.append(_issue("source_polish_task_mismatch", "TASK_953-Source nennt nicht TASK_952 als Polish-Quelle."))
	if String(source_snapshot.get("source_schema", "")) != SOURCE_POLISH_SCHEMA:
		blockers.append(_issue("source_polish_schema_mismatch", "TASK_952-Polish-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("source_style_id", "")) != SOURCE_STYLE_ID:
		blockers.append(_issue("source_style_mismatch", "TASK_952-Style fehlt oder passt nicht."))
	if not bool(source_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_953-Source ist nicht read-only."))
	if bool(source_snapshot.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_953-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_visual_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Sichtbefund bestaetigt das korrekte Sternenbuergerchen-Fenster nicht."))
	if not bool(review_notes.get("decision_overlay_badges_visible", false)):
		issues.append(_issue("decision_overlay_badges_not_visible", "Die Decision-Overlay-Badges sind im echten Fenster nicht klar sichtbar."))
	if not bool(review_notes.get("safe_risky_suicidal_order_visible", false)):
		issues.append(_issue("risk_order_not_readable", "Safe/Risky/Suicidal-Reihenfolge ist im echten Fenster nicht sofort lesbar."))
	if bool(review_notes.get("badge_colors_compete_with_fire_lane", false)) or not bool(review_notes.get("badge_colors_do_not_fight_fire_lane", false)):
		issues.append(_issue("badge_colors_compete_with_fire_lane", "Badge-Farben konkurrieren mit Fire-Lane-/Combat-Signalen."))
	if bool(review_notes.get("mission_control_line_too_noisy", false)) or not bool(review_notes.get("mission_control_line_still_readable", false)):
		issues.append(_issue("mission_control_line_too_noisy", "Die Mission-Control-Preview-Zeile ist noch zu laut oder schwer lesbar."))
	if bool(review_notes.get("command_surfaces_obscured", false)) or not bool(review_notes.get("command_surfaces_still_usable", false)):
		issues.append(_issue("command_surfaces_obscured", "Command-Surfaces werden vom Overlay verdeckt oder schlechter bedienbar."))
	if not bool(review_notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Sichtbefund bestaetigt die read-only-Grenze nicht."))
	if not bool(review_notes.get("player_readability_ok", false)):
		issues.append(_issue("player_readability_not_ok", "Der Spielerblick liest die Preview noch nicht ruhig genug."))
	return issues


static func _build_positive_findings(review_notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, review_notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, review_notes, "decision_overlay_badges_visible", "Decision-Overlay-Badges sind sichtbar.")
	_append_positive(positive, review_notes, "safe_risky_suicidal_order_visible", "Safe/Risky/Suicidal-Reihenfolge ist lesbar.")
	_append_positive(positive, review_notes, "badge_colors_do_not_fight_fire_lane", "Badge-Farben bleiben gegen Fire-Lanes ruhig.")
	_append_positive(positive, review_notes, "mission_control_line_still_readable", "Mission-Control-Zeile bleibt lesbar.")
	_append_positive(positive, review_notes, "command_surfaces_still_usable", "Command-Surfaces bleiben bedienbar.")
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
