class_name ReleaseFireExchangeRuntimeTextVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_runtime_text_visual_findings.v1"
const TASK_ID: String = "TASK_864"
const SOURCE_TASK_ID: String = "TASK_863"
const SOURCE_RUNTIME_TEXT_TASK_ID: String = "TASK_862"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_860"
const SOURCE_BINDING_TASK_ID: String = "TASK_859"
const SOURCE_PRIMARY_HUD_TASK_ID: String = "TASK_856"
const SOURCE_READABILITY_TASK_ID: String = "TASK_853"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_TASK_ID: String = "TASK_837"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_runtime_text_recapture.v1"
const EXPECTED_RUNTIME_TEXT_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_runtime_text_polish.v1"
const EXPECTED_RUNTIME_TEXT_STYLE_ID: String = "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
const EXPECTED_SOURCE_BINDING_STYLE_ID: String = "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
const EXPECTED_PRIMARY_HUD_STYLE_ID: String = "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
const NEXT_TASK: String = "TASK_865 - Release Fire Exchange Runtime Text Visible Status Polish"


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var recapture_schema: String = String(recapture_manifest.get("schema", "")).strip_edges()
	var recapture_task_id: String = String(recapture_manifest.get("task_id", "")).strip_edges()
	var capture_gate: String = String(recapture_manifest.get("gate", recapture_manifest.get("capture_gate", ""))).strip_edges()
	var window_screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var expected_runtime_text_schema: String = String(recapture_manifest.get("expected_runtime_text_schema", "")).strip_edges()
	var expected_runtime_text_style_id: String = String(recapture_manifest.get("expected_runtime_text_style_id", "")).strip_edges()
	var expected_source_binding_style_id: String = String(recapture_manifest.get("expected_source_binding_style_id", "")).strip_edges()
	var expected_primary_hud_style_id: String = String(recapture_manifest.get("expected_primary_hud_style_id", "")).strip_edges()
	var manual_notes_present: bool = not review_notes.is_empty()
	var manual_visual_review_done: bool = bool(review_notes.get("manual_visual_review_done", manual_notes_present))
	var blockers: Array = _build_blockers(
		recapture_schema,
		recapture_task_id,
		capture_gate,
		window_screenshot_written,
		expected_runtime_text_schema,
		expected_runtime_text_style_id,
		expected_source_binding_style_id,
		expected_primary_hud_style_id
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
		"source_runtime_text_task_id": SOURCE_RUNTIME_TEXT_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_binding_task_id": SOURCE_BINDING_TASK_ID,
		"source_primary_hud_task_id": SOURCE_PRIMARY_HUD_TASK_ID,
		"source_readability_task_id": SOURCE_READABILITY_TASK_ID,
		"source_focus_task_id": SOURCE_FOCUS_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"source_capture_task_id": SOURCE_CAPTURE_TASK_ID,
		"recapture_schema": recapture_schema,
		"recapture_schema_ok": recapture_schema == EXPECTED_RECAPTURE_SCHEMA,
		"recapture_task_id": recapture_task_id,
		"capture_gate": capture_gate,
		"capture_review_ready": capture_gate == "review_ready" or capture_gate == "manual_open",
		"expected_runtime_text_schema": expected_runtime_text_schema,
		"runtime_text_schema_ok": expected_runtime_text_schema == EXPECTED_RUNTIME_TEXT_SCHEMA,
		"expected_runtime_text_style_id": expected_runtime_text_style_id,
		"runtime_text_style_id_ok": expected_runtime_text_style_id == EXPECTED_RUNTIME_TEXT_STYLE_ID,
		"expected_source_binding_style_id": expected_source_binding_style_id,
		"source_binding_style_id_ok": expected_source_binding_style_id == EXPECTED_SOURCE_BINDING_STYLE_ID,
		"expected_primary_hud_style_id": expected_primary_hud_style_id,
		"primary_hud_style_id_ok": expected_primary_hud_style_id == EXPECTED_PRIMARY_HUD_STYLE_ID,
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
			"id": "task_863_real_window_capture_available",
			"text": "Der TASK_863-Fenster-Screenshot liegt vor und ist als Real-Window-Evidenz verwendbar.",
		})
	if String(recapture_manifest.get("expected_runtime_text_style_id", "")) == EXPECTED_RUNTIME_TEXT_STYLE_ID:
		positives.append({
			"id": "task_862_runtime_text_contract_expected",
			"text": "Das Manifest erwartet den TASK_862-Runtime-Text-Style und prueft damit den richtigen Anzeige-Slice.",
		})
	if String(recapture_manifest.get("expected_source_binding_style_id", "")) == EXPECTED_SOURCE_BINDING_STYLE_ID:
		positives.append({
			"id": "task_859_source_binding_contract_expected",
			"text": "Das Manifest haelt den TASK_859-Source-Binding-Style weiter fest.",
		})
	if _review_flag(review_notes, "mission_surface_readable", true):
		positives.append({
			"id": "mission_surface_readable",
			"text": "Karte, Selected Fireteam, Mission Control und Dropship-Card bleiben im Screenshot grundsaetzlich lesbar.",
		})
	if _review_flag(review_notes, "command_matrix_usable", true):
		positives.append({
			"id": "command_matrix_usable",
			"text": "Die Command Matrix bleibt bedienbar und ist nicht die primaere Reibung.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "runtime_text_window_still_los_no_fire_first_reading", true):
		issues.append({
			"id": "runtime_text_window_still_los_no_fire_first_reading",
			"severity": "release_readability",
			"text": "Der sichtbare TASK_863-HUD-Primaertext beginnt weiter mit NEXT LOS/RANGE KORRIGIEREN und Kampf NO FIRE NO_LOS statt CONTACT FIRE.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "selected_fireteam_status_overrides_contact_fire", true):
		issues.append({
			"id": "selected_fireteam_status_overrides_contact_fire",
			"severity": "release_readability",
			"text": "#17 Selected Fireteam liest nicht CONTACT FIRE als erste Spielerzeile, obwohl TASK_862 den Runtime-Text-Snapshot so erwartet.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "mission_control_status_overrides_contact_fire", true):
		issues.append({
			"id": "mission_control_status_overrides_contact_fire",
			"severity": "release_readability",
			"text": "#18 Mission Control liest nicht CONTACT FIRE als erste Spielerzeile, sondern den LOS-/NO-FIRE-Status.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_still_contact_pressure", true):
		issues.append({
			"id": "event_log_still_contact_pressure",
			"severity": "hud_readability",
			"text": "#19 Event Log bestaetigt im Fenster eher CONTACT PRESSURE / Position korrigieren als CONTACT FIRE.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "runtime_text_snapshot_window_gap", true):
		issues.append({
			"id": "runtime_text_snapshot_window_gap",
			"severity": "verification_gap",
			"text": "TASK_862-Runtime-Text-Verifier und TASK_863-Manifest sind gruen, aber der echte Fensterblick zeigt weiter eine andere Primaerlesung.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _build_blockers(
	recapture_schema: String,
	recapture_task_id: String,
	capture_gate: String,
	window_screenshot_written: bool,
	expected_runtime_text_schema: String,
	expected_runtime_text_style_id: String,
	expected_source_binding_style_id: String,
	expected_primary_hud_style_id: String
) -> Array:
	var blockers: Array = []
	if recapture_schema != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append({"id": "recapture_schema_mismatch", "text": "TASK_863-Recapture-Schema fehlt oder passt nicht."})
	if recapture_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "recapture_task_mismatch", "text": "Manifest nennt nicht TASK_863 als Quelle."})
	if capture_gate != "review_ready" and capture_gate != "manual_open":
		blockers.append({"id": "capture_not_review_ready", "text": "TASK_863-Capture ist nicht review_ready/manual_open."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if expected_runtime_text_schema != EXPECTED_RUNTIME_TEXT_SCHEMA:
		blockers.append({"id": "runtime_text_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_862-Runtime-Text-Schema."})
	if expected_runtime_text_style_id != EXPECTED_RUNTIME_TEXT_STYLE_ID:
		blockers.append({"id": "runtime_text_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_862-Runtime-Text-Style-ID."})
	if expected_source_binding_style_id != EXPECTED_SOURCE_BINDING_STYLE_ID:
		blockers.append({"id": "source_binding_style_id_mismatch", "text": "Manifest nennt nicht den erwarteten TASK_859-Source-Binding-Style."})
	if expected_primary_hud_style_id != EXPECTED_PRIMARY_HUD_STYLE_ID:
		blockers.append({"id": "primary_hud_style_id_mismatch", "text": "Manifest nennt nicht den erwarteten TASK_856-Primary-HUD-Style."})
	return blockers


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value
