class_name ReleaseFireExchangeFocusedVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_focused_visual_findings.v1"
const TASK_ID: String = "TASK_852"
const SOURCE_TASK_ID: String = "TASK_851"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_focused_visual_recapture.v1"
const EXPECTED_FOCUS_STYLE_ID: String = "task_850_release_fire_exchange_focused_visual_polish_v1"
const NEXT_TASK: String = "TASK_853 - Release Fire Exchange Engagement Readability Polish"


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var recapture_schema: String = String(recapture_manifest.get("schema", "")).strip_edges()
	var recapture_task_id: String = String(recapture_manifest.get("task_id", "")).strip_edges()
	var recapture_status: String = String(recapture_manifest.get("status", "")).strip_edges()
	var capture_gate: String = String(recapture_manifest.get("capture_gate", recapture_manifest.get("gate", ""))).strip_edges()
	var window_screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var expected_focus_style_id: String = String(recapture_manifest.get("expected_focus_style_id", "")).strip_edges()
	var manual_notes_present: bool = not review_notes.is_empty()
	var manual_visual_review_done: bool = bool(review_notes.get("manual_visual_review_done", manual_notes_present))

	var blockers: Array = _build_blockers(
		recapture_schema,
		recapture_task_id,
		recapture_status,
		capture_gate,
		window_screenshot_written,
		expected_focus_style_id
	)
	var positives: Array = _build_positive_findings(recapture_manifest, review_notes)
	var issues: Array = _build_issue_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "needs_manual_review"
	if status != "blocked" and manual_notes_present:
		status = "ready_for_polish"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_focus_task_id": SOURCE_FOCUS_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"recapture_schema": recapture_schema,
		"recapture_schema_ok": recapture_schema == EXPECTED_RECAPTURE_SCHEMA,
		"recapture_task_id": recapture_task_id,
		"recapture_status": recapture_status,
		"capture_gate": capture_gate,
		"capture_review_ready": capture_gate == "review_ready" or capture_gate == "manual_open",
		"expected_focus_style_id": expected_focus_style_id,
		"focus_style_id_ok": expected_focus_style_id == EXPECTED_FOCUS_STYLE_ID,
		"window_screenshot_written": window_screenshot_written,
		"window_screenshot_path": String(recapture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(recapture_manifest.get("desktop_screenshot_path", "")),
		"manual_review_required": true,
		"manual_visual_review_done": manual_visual_review_done,
		"manual_notes_present": manual_notes_present,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_positive_findings(recapture_manifest: Dictionary, review_notes: Dictionary) -> Array:
	var positives: Array = []
	if bool(recapture_manifest.get("window_screenshot_written", false)):
		positives.append({
			"id": "focused_real_window_capture_available",
			"text": "Der TASK_851-Fenster-Screenshot liegt vor und ist als Focus-Review-Evidenz verwendbar.",
		})
	if String(recapture_manifest.get("expected_focus_style_id", "")) == EXPECTED_FOCUS_STYLE_ID:
		positives.append({
			"id": "task_850_focus_contract_present",
			"text": "Das Manifest erwartet den TASK_850-Focus-Style und prueft damit den richtigen Visual-Slice.",
		})
	if _review_flag(review_notes, "mission_surface_readable", true):
		positives.append({
			"id": "mission_surface_readable",
			"text": "Karte, Fireteam-Karten, Mission Control und Command Matrix bleiben im Screenshot grundsaetzlich lesbar.",
		})
	if _review_flag(review_notes, "command_matrix_usable", true):
		positives.append({
			"id": "command_matrix_usable",
			"text": "Die Command Matrix bleibt bedienbar und verdeckt den Kampf nicht kritisch.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "contact_pressure_instead_of_contact_fire", true):
		issues.append({
			"id": "contact_pressure_instead_of_contact_fire",
			"severity": "release_readability",
			"text": "Der sichtbare TASK_851-Moment liest sich weiterhin als CONTACT PRESSURE / NO FIRE statt als klarer erster Feuerwechsel.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "debug_no_fire_reason_visible", true):
		issues.append({
			"id": "debug_no_fire_reason_visible",
			"severity": "release_readability",
			"text": "Der HUD-Text zeigt technische Debug-Sprache wie NO FIRE ATTACKER_NOT_ENGAGE_READY, die fuer Spieler den Kampf-Moment verschleiert.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "fire_trace_or_impact_still_not_readable", true):
		issues.append({
			"id": "fire_trace_or_impact_still_not_readable",
			"severity": "visual_readability",
			"text": "FireTrace, Impact oder Target-Focus sind im echten Fenster noch nicht stark genug, um den ersten Schusswechsel ohne Erklaertext zu lesen.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "hud_exchange_confirmation_missing", true):
		issues.append({
			"id": "hud_exchange_confirmation_missing",
			"severity": "hud_readability",
			"text": "#17/#18/#19 bestaetigen den CONTACT-FIRE-Moment im sichtbaren Fenster weiterhin nicht gemeinsam genug.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value


static func _build_blockers(
	recapture_schema: String,
	recapture_task_id: String,
	recapture_status: String,
	capture_gate: String,
	window_screenshot_written: bool,
	expected_focus_style_id: String
) -> Array:
	var blockers: Array = []
	if recapture_schema != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append({"id": "recapture_schema_mismatch", "text": "TASK_851-Recapture-Schema fehlt oder passt nicht."})
	if recapture_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "recapture_task_mismatch", "text": "Manifest nennt nicht TASK_851 als Quelle."})
	if recapture_status != "ready_for_manual_review" and recapture_status != "manual_review_recorded" and recapture_status != "":
		blockers.append({"id": "recapture_not_ready", "text": "TASK_851-Recapture ist nicht bereit fuer Findings."})
	if capture_gate != "review_ready" and capture_gate != "manual_open":
		blockers.append({"id": "capture_not_review_ready", "text": "TASK_851-Capture ist nicht review_ready/manual_open."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if expected_focus_style_id != EXPECTED_FOCUS_STYLE_ID:
		blockers.append({"id": "focus_style_id_mismatch", "text": "Manifest nennt nicht den erwarteten TASK_850-Focus-Style."})
	return blockers
