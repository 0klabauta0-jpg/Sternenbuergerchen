class_name ReleaseFirstExchangeVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_visual_findings.v1"
const TASK_ID: String = "TASK_846"
const SOURCE_TASK_ID: String = "TASK_845"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_TASK_ID: String = "TASK_837"
const EXPECTED_EXCHANGE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const EXPECTED_EXCHANGE_STYLE_ID: String = "task_844_release_first_exchange_tension_tuning_v1"
const NEXT_TASK: String = "TASK_847 - Release Fire Exchange Visibility Persistence"


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var manifest_gate: String = String(recapture_manifest.get("gate", "")).strip_edges()
	var source_task_id: String = String(recapture_manifest.get("source_task_id", "")).strip_edges()
	var source_capture_task_id: String = String(recapture_manifest.get("source_capture_task_id", "")).strip_edges()
	var exchange_schema: String = String(recapture_manifest.get("expected_exchange_schema", "")).strip_edges()
	var exchange_style_id: String = String(recapture_manifest.get("expected_exchange_style_id", "")).strip_edges()
	var screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var manual_review_done: bool = bool(recapture_manifest.get("manual_review_done", false))
	var manual_notes_present: bool = not review_notes.is_empty()
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))

	var positives: Array = _build_positive_findings(review_notes, required_checks, screenshot_written)
	var issues: Array = _build_issue_findings(review_notes)
	var blocking_issues: Array = _build_blocking_issues(manifest_gate, source_task_id, source_capture_task_id, exchange_schema, exchange_style_id, screenshot_written)
	var warnings: Array = []
	for issue in issues:
		if String(Dictionary(issue).get("severity", "")) == "warning":
			warnings.append(issue)

	var status: String = "blocked" if not blocking_issues.is_empty() else "ready_for_polish"
	if status == "ready_for_polish" and not manual_notes_present:
		status = "needs_manual_review"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"source_capture_task_id": SOURCE_CAPTURE_TASK_ID,
		"recapture_gate": manifest_gate,
		"recapture_manifest_present": not recapture_manifest.is_empty(),
		"window_screenshot_written": screenshot_written,
		"window_screenshot_path": String(recapture_manifest.get("window_screenshot_path", "")),
		"expected_exchange_schema": exchange_schema,
		"expected_exchange_style_id": exchange_style_id,
		"exchange_schema_ok": exchange_schema == EXPECTED_EXCHANGE_SCHEMA,
		"exchange_style_id_ok": exchange_style_id == EXPECTED_EXCHANGE_STYLE_ID,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"manual_notes_present": manual_notes_present,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blocking_issues,
		"blocking_issue_count": blocking_issues.size(),
		"warning_count": warnings.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"recommended_next_task": NEXT_TASK,
		"status": status,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


static func _build_positive_findings(review_notes: Dictionary, required_checks: Array, screenshot_written: bool) -> Array:
	var positives: Array = []
	if screenshot_written or bool(review_notes.get("capture_review_ready", false)):
		positives.append({
			"id": "release_path_captureable",
			"text": "Der Release-Pfad ist als echtes Fenster bis in den ersten Kontaktmoment capturebar.",
		})
	if bool(review_notes.get("layout_still_usable", false)) or required_checks.has("command_matrix_controls_remain_usable"):
		positives.append({
			"id": "layout_still_usable",
			"text": "Fireteam-Karte, Mission Control, Dropship-Karte und Command Matrix bleiben im Fenster bedienbar.",
		})
	if bool(review_notes.get("contact_pressure_framed", false)) or required_checks.has("event_log_contact_fire_or_exchange_detail_visible"):
		positives.append({
			"id": "contact_pressure_framed",
			"text": "Der Kontakt faellt nicht ins Leere; Event Log und HUD rahmen wenigstens eine taktische Kontaktlage.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "first_exchange_not_visible_in_window", true):
		issues.append({
			"id": "first_exchange_not_visible_in_window",
			"severity": "polish",
			"text": "Der echte Fensterblick zeigt weiter `CONTACT PRESSURE` statt das erwartete `CONTACT FIRE`/Fire-Exchange-Feedback.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "hud_surfaces_stale_pressure", true):
		issues.append({
			"id": "hud_surfaces_stale_pressure",
			"severity": "polish",
			"text": "#17 Selected Fireteam und #18 Mission Control priorisieren weiter `NO FIRE`/LOS-Korrektur, obwohl TASK_844 FireEvent-Evidence erzeugt.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "fire_trace_or_impact_not_obvious", true):
		issues.append({
			"id": "fire_trace_or_impact_not_obvious",
			"severity": "warning",
			"text": "FireEvent-, Trace- oder Impact-Evidence ist im echten Fenster nicht offensichtlich genug, um den ersten Schusswechsel sofort zu lesen.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value


static func _build_blocking_issues(
	manifest_gate: String,
	source_task_id: String,
	source_capture_task_id: String,
	exchange_schema: String,
	exchange_style_id: String,
	screenshot_written: bool
) -> Array:
	var blockers: Array = []
	if manifest_gate != "review_ready":
		blockers.append({"id": "recapture_not_review_ready", "text": "TASK_845-Recapture ist nicht review_ready."})
	if not screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "TASK_845-Window-Screenshot fehlt."})
	if source_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append({"id": "source_task_mismatch", "text": "Recapture nennt nicht TASK_844 als Exchange-Quelle."})
	if source_capture_task_id != SOURCE_CAPTURE_TASK_ID:
		blockers.append({"id": "source_capture_mismatch", "text": "Recapture nennt nicht TASK_837 als Capture-Quelle."})
	if exchange_schema != EXPECTED_EXCHANGE_SCHEMA:
		blockers.append({"id": "exchange_schema_mismatch", "text": "Recapture nennt nicht das erwartete TASK_844-Exchange-Schema."})
	if exchange_style_id != EXPECTED_EXCHANGE_STYLE_ID:
		blockers.append({"id": "exchange_style_id_mismatch", "text": "Recapture nennt nicht die erwartete TASK_844-Style-ID."})
	return blockers
