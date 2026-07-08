class_name ReleaseFireExchangeRuntimeTextStatusVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_runtime_text_status_visual_findings.v1"
const TASK_ID: String = "TASK_867"
const SOURCE_TASK_ID: String = "TASK_866"
const SOURCE_STATUS_POLISH_TASK_ID: String = "TASK_865"
const SOURCE_RUNTIME_TEXT_TASK_ID: String = "TASK_862"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_863"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_runtime_text_status_recapture.v1"
const EXPECTED_RUNTIME_TEXT_STYLE_ID: String = "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
const NEXT_TASK: String = "TASK_868 - Release First Exchange LOS Setup Polish"


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var recapture_schema: String = String(recapture_manifest.get("schema", "")).strip_edges()
	var recapture_task_id: String = String(recapture_manifest.get("task_id", "")).strip_edges()
	var capture_gate: String = String(recapture_manifest.get("gate", recapture_manifest.get("capture_gate", ""))).strip_edges()
	var window_screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var expected_runtime_text_style_id: String = String(recapture_manifest.get("expected_runtime_text_style_id", "")).strip_edges()
	var source_task_id: String = String(recapture_manifest.get("source_task_id", "")).strip_edges()
	var source_runtime_text_task_id: String = String(recapture_manifest.get("source_runtime_text_task_id", "")).strip_edges()
	var source_recapture_task_id: String = String(recapture_manifest.get("source_recapture_task_id", "")).strip_edges()
	var manual_notes_present: bool = not review_notes.is_empty()
	var manual_visual_review_done: bool = bool(review_notes.get("manual_visual_review_done", manual_notes_present))
	var blockers: Array = _build_blockers(
		recapture_schema,
		recapture_task_id,
		capture_gate,
		window_screenshot_written,
		expected_runtime_text_style_id,
		source_task_id,
		source_runtime_text_task_id,
		source_recapture_task_id
	)
	var positives: Array = _build_positive_findings(recapture_manifest, review_notes)
	var issues: Array = _build_issue_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "needs_manual_review"
	if status != "blocked" and manual_notes_present:
		status = "ready_for_los_setup_polish"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_status_polish_task_id": SOURCE_STATUS_POLISH_TASK_ID,
		"source_runtime_text_task_id": SOURCE_RUNTIME_TEXT_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"recapture_schema": recapture_schema,
		"recapture_schema_ok": recapture_schema == EXPECTED_RECAPTURE_SCHEMA,
		"recapture_task_id": recapture_task_id,
		"capture_gate": capture_gate,
		"capture_review_ready": capture_gate == "review_ready" or capture_gate == "manual_open",
		"source_status_polish_manifest_id": source_task_id,
		"source_runtime_text_manifest_id": source_runtime_text_task_id,
		"source_recapture_manifest_id": source_recapture_task_id,
		"expected_runtime_text_style_id": expected_runtime_text_style_id,
		"runtime_text_style_id_ok": expected_runtime_text_style_id == EXPECTED_RUNTIME_TEXT_STYLE_ID,
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
		"recommended_direction": "fix_first_exchange_los_or_reframe_contact_pressure",
		"avoid_next_action": "do_not_force_contact_fire_text_without_fire_or_los_evidence",
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
			"id": "task_866_real_window_capture_available",
			"text": "Der TASK_866-Fenster-Screenshot liegt vor und ist als Real-Window-Evidenz verwendbar.",
		})
	if String(recapture_manifest.get("source_task_id", "")) == SOURCE_STATUS_POLISH_TASK_ID:
		positives.append({
			"id": "task_865_status_polish_source_recorded",
			"text": "Das Manifest haelt TASK_865 als Quelle der Zeitbasis-Korrektur fest.",
		})
	if String(recapture_manifest.get("expected_runtime_text_style_id", "")) == EXPECTED_RUNTIME_TEXT_STYLE_ID:
		positives.append({
			"id": "task_862_runtime_text_contract_still_expected",
			"text": "Der Runtime-Text-Contract ist weiter im Capture-Manifest verankert.",
		})
	if _review_flag(review_notes, "mission_surface_readable", true):
		positives.append({
			"id": "mission_surface_readable",
			"text": "Karte, Selected Fireteam, Mission Control und Dropship-Card bleiben im Screenshot grundsaetzlich lesbar.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "first_exchange_los_evidence_not_visible", true):
		issues.append({
			"id": "first_exchange_los_evidence_not_visible",
			"severity": "release_playability",
			"text": "Der echte TASK_866-Fensterblick zeigt weiter NO_LOS/Position korrigieren statt eine belastbare CONTACT-FIRE-/FireEvent-Situation.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "selected_fireteam_still_no_los_first", true):
		issues.append({
			"id": "selected_fireteam_still_no_los_first",
			"severity": "release_readability",
			"text": "#17 Selected Fireteam beginnt weiter mit NEXT LOS/RANGE KORRIGIEREN und Kampf NO FIRE NO_LOS.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "mission_control_still_no_los_first", true):
		issues.append({
			"id": "mission_control_still_no_los_first",
			"severity": "release_readability",
			"text": "#18 Mission Control beginnt weiter mit NEXT LOS/RANGE KORRIGIEREN und Kampf NO FIRE NO_LOS.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_contact_pressure_position_correct", true):
		issues.append({
			"id": "event_log_contact_pressure_position_correct",
			"severity": "hud_readability",
			"text": "#19 Event Log zeigt CONTACT PRESSURE: Position korrigieren; das bestaetigt eher einen Zwischenzustand als einen Feuerwechsel.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "contact_fire_text_would_be_misleading_without_los", true):
		issues.append({
			"id": "contact_fire_text_would_be_misleading_without_los",
			"severity": "contract_alignment",
			"text": "CONTACT FIRE als primaerer Text waere ohne FireEvent-/LOS-Evidence wahrscheinlich unehrlich. Der naechste Fix muss das Setup oder die Erwartung korrigieren.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _build_blockers(
	recapture_schema: String,
	recapture_task_id: String,
	capture_gate: String,
	window_screenshot_written: bool,
	expected_runtime_text_style_id: String,
	source_task_id: String,
	source_runtime_text_task_id: String,
	source_recapture_task_id: String
) -> Array:
	var blockers: Array = []
	if recapture_schema != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append({"id": "recapture_schema_mismatch", "text": "TASK_866-Recapture-Schema fehlt oder passt nicht."})
	if recapture_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "recapture_task_mismatch", "text": "Manifest nennt nicht TASK_866 als Quelle."})
	if capture_gate != "review_ready" and capture_gate != "manual_open":
		blockers.append({"id": "capture_not_review_ready", "text": "TASK_866-Capture ist nicht review_ready/manual_open."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if expected_runtime_text_style_id != EXPECTED_RUNTIME_TEXT_STYLE_ID:
		blockers.append({"id": "runtime_text_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_862-Runtime-Text-Style-ID."})
	if source_task_id != SOURCE_STATUS_POLISH_TASK_ID:
		blockers.append({"id": "source_status_polish_mismatch", "text": "Manifest nennt nicht TASK_865 als Status-Polish-Quelle."})
	if source_runtime_text_task_id != SOURCE_RUNTIME_TEXT_TASK_ID:
		blockers.append({"id": "source_runtime_text_mismatch", "text": "Manifest nennt nicht TASK_862 als Runtime-Text-Quelle."})
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append({"id": "source_recapture_mismatch", "text": "Manifest nennt nicht TASK_863 als Recapture-Quelle."})
	return blockers


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value
