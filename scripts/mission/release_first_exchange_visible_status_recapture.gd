class_name ReleaseFirstExchangeVisibleStatusRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_recapture.v1"
const TASK_ID: String = "TASK_877"
const SOURCE_TASK_ID: String = "TASK_876"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_874"
const SOURCE_READABILITY_TASK_ID: String = "TASK_873"
const SOURCE_LOS_RECAPTURE_TASK_ID: String = "TASK_869"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_FIX_TASK_ID: String = "TASK_871"
const EXPECTED_VISIBLE_STATUS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
const EXPECTED_VISIBLE_STATUS_STYLE_ID: String = "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
const EXPECTED_CONTACT_FIRE_READABILITY_SCHEMA: String = "sternenbuergerchen.release_first_exchange_contact_fire_readability_fix.v1"
const EXPECTED_CONTACT_FIRE_READABILITY_STYLE_ID: String = "task_873_release_first_exchange_contact_fire_readability_fix_v1"
const NEXT_TASK_IF_REVIEW_NEEDED: String = "TASK_878 - Release First Exchange Visible Status Visual Findings"

const REQUIRED_RECAPTURE_CHECKS: PackedStringArray = [
	"release_exe_started_with_first_go_firefight_arg",
	"task_876_visible_status_source_expected",
	"task_874_contact_fire_real_window_recapture_source_expected",
	"task_873_contact_fire_readability_fix_expected",
	"task_869_real_window_recapture_source_expected",
	"task_844_first_exchange_expected",
	"window_handle_capture_trusted",
	"selected_fireteam_contact_fire_first_visible",
	"mission_control_contact_fire_first_visible",
	"event_log_contact_fire_visible",
	"fire_trace_or_impact_target_focus_visible",
	"no_stale_no_los_or_contact_pressure_only_message",
	"command_surfaces_still_usable",
	"manual_visual_review_done",
]


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var gate: String = String(capture_manifest.get("gate", "")).strip_edges()
	var hard_failures: Array = Array(capture_manifest.get("hard_failures", []))
	var warnings: Array = Array(capture_manifest.get("warnings", []))
	var required_checks: Array = Array(capture_manifest.get("required_checks", []))
	var missing_checks: Array = _missing_required_checks(required_checks)
	var window_screenshot_written: bool = bool(capture_manifest.get("window_screenshot_written", false))
	var desktop_screenshot_written: bool = bool(capture_manifest.get("desktop_screenshot_written", false))
	var window_capture_method: String = String(capture_manifest.get("window_capture_method", "")).strip_edges()
	var window_capture_trusted: bool = bool(capture_manifest.get("window_capture_trusted", false))
	var window_handle_capture_succeeded: bool = bool(capture_manifest.get("window_handle_capture_succeeded", false))
	var expected_visible_schema: String = String(capture_manifest.get("expected_visible_status_schema", "")).strip_edges()
	var expected_visible_style_id: String = String(capture_manifest.get("expected_visible_status_style_id", "")).strip_edges()
	var expected_readability_schema: String = String(capture_manifest.get("expected_contact_fire_readability_schema", "")).strip_edges()
	var expected_readability_style_id: String = String(capture_manifest.get("expected_contact_fire_readability_style_id", "")).strip_edges()
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", capture_manifest.get("manual_review_done", false)))
	var review_ready: bool = gate == "review_ready" or gate == "manual_open"
	var blockers: Array = _build_blockers(
		review_ready,
		hard_failures,
		window_screenshot_written,
		String(capture_manifest.get("schema", "")),
		String(capture_manifest.get("task_id", "")),
		String(capture_manifest.get("source_task_id", "")),
		String(capture_manifest.get("source_recapture_task_id", "")),
		String(capture_manifest.get("source_readability_task_id", "")),
		String(capture_manifest.get("source_los_recapture_task_id", "")),
		String(capture_manifest.get("source_exchange_task_id", "")),
		String(capture_manifest.get("source_capture_fix_task_id", "")),
		expected_visible_schema,
		expected_visible_style_id,
		expected_readability_schema,
		expected_readability_style_id,
		window_capture_method,
		window_capture_trusted,
		window_handle_capture_succeeded,
		missing_checks
	)
	var manual_findings: Array = _build_manual_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_manual_acceptance"
	if status != "blocked" and manual_review_done:
		status = "manual_review_recorded"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_readability_task_id": SOURCE_READABILITY_TASK_ID,
		"source_los_recapture_task_id": SOURCE_LOS_RECAPTURE_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"source_capture_fix_task_id": SOURCE_CAPTURE_FIX_TASK_ID,
		"capture_gate": gate,
		"capture_review_ready": review_ready,
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"wait_seconds": int(capture_manifest.get("wait_seconds", 0)),
		"window_screenshot_written": window_screenshot_written,
		"desktop_screenshot_written": desktop_screenshot_written,
		"window_screenshot_path": String(capture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("desktop_screenshot_path", "")),
		"window_screenshot_full_path": String(capture_manifest.get("window_screenshot_full_path", "")),
		"desktop_screenshot_full_path": String(capture_manifest.get("desktop_screenshot_full_path", "")),
		"window_capture_method": window_capture_method,
		"window_capture_trusted": window_capture_trusted,
		"window_handle_capture_succeeded": window_handle_capture_succeeded,
		"foreground_matches_selected_process": bool(capture_manifest.get("foreground_matches_selected_process", false)),
		"expected_visible_status_schema": expected_visible_schema,
		"expected_visible_status_style_id": expected_visible_style_id,
		"visible_status_schema_ok": expected_visible_schema == EXPECTED_VISIBLE_STATUS_SCHEMA,
		"visible_status_style_id_ok": expected_visible_style_id == EXPECTED_VISIBLE_STATUS_STYLE_ID,
		"expected_contact_fire_readability_schema": expected_readability_schema,
		"expected_contact_fire_readability_style_id": expected_readability_style_id,
		"contact_fire_readability_schema_ok": expected_readability_schema == EXPECTED_CONTACT_FIRE_READABILITY_SCHEMA,
		"contact_fire_readability_style_id_ok": expected_readability_style_id == EXPECTED_CONTACT_FIRE_READABILITY_STYLE_ID,
		"required_checks": required_checks,
		"required_recapture_checks": Array(REQUIRED_RECAPTURE_CHECKS),
		"missing_recapture_checks": missing_checks,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"manual_findings": manual_findings,
		"manual_finding_count": manual_findings.size(),
		"warnings": warnings,
		"warning_count": warnings.size(),
		"hard_failures": hard_failures,
		"hard_failure_count": hard_failures.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK_IF_REVIEW_NEEDED,
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


static func _missing_required_checks(required_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_RECAPTURE_CHECKS:
		if not required_checks.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _build_blockers(
	review_ready: bool,
	hard_failures: Array,
	window_screenshot_written: bool,
	schema: String,
	task_id: String,
	source_task_id: String,
	source_recapture_task_id: String,
	source_readability_task_id: String,
	source_los_recapture_task_id: String,
	source_exchange_task_id: String,
	source_capture_fix_task_id: String,
	expected_visible_schema: String,
	expected_visible_style_id: String,
	expected_readability_schema: String,
	expected_readability_style_id: String,
	window_capture_method: String,
	window_capture_trusted: bool,
	window_handle_capture_succeeded: bool,
	missing_checks: Array
) -> Array:
	var blockers: Array = []
	if schema != SCHEMA:
		blockers.append(_issue("recapture_schema_mismatch", "TASK_877-Recapture-Schema fehlt oder passt nicht."))
	if task_id != TASK_ID:
		blockers.append(_issue("recapture_task_mismatch", "Manifest nennt nicht TASK_877."))
	if source_task_id != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."))
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_mismatch", "Manifest nennt nicht TASK_874 als Real-Window-Quelle."))
	if source_readability_task_id != SOURCE_READABILITY_TASK_ID:
		blockers.append(_issue("source_readability_mismatch", "Manifest nennt nicht TASK_873 als CONTACT-FIRE-Readability-Quelle."))
	if source_los_recapture_task_id != SOURCE_LOS_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_los_recapture_mismatch", "Manifest nennt nicht TASK_869 als LOS-Recapture-Quelle."))
	if source_exchange_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append(_issue("source_exchange_mismatch", "Manifest nennt nicht TASK_844 als Exchange-Quelle."))
	if source_capture_fix_task_id != SOURCE_CAPTURE_FIX_TASK_ID:
		blockers.append(_issue("source_capture_fix_mismatch", "Manifest nennt nicht TASK_871 als Capture-Fix-Quelle."))
	if not review_ready:
		blockers.append(_issue("capture_not_review_ready", "TASK_877-Capture ist weder review_ready noch manual_open."))
	if not hard_failures.is_empty():
		blockers.append(_issue("capture_hard_failures", "TASK_877-Capture meldet Hard-Failures."))
	if not window_screenshot_written:
		blockers.append(_issue("window_screenshot_missing", "Fenster-Screenshot fehlt."))
	if expected_visible_schema != EXPECTED_VISIBLE_STATUS_SCHEMA:
		blockers.append(_issue("visible_status_schema_mismatch", "Manifest nennt nicht das erwartete TASK_876-Schema."))
	if expected_visible_style_id != EXPECTED_VISIBLE_STATUS_STYLE_ID:
		blockers.append(_issue("visible_status_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_876-Style-ID."))
	if expected_readability_schema != EXPECTED_CONTACT_FIRE_READABILITY_SCHEMA:
		blockers.append(_issue("contact_fire_readability_schema_mismatch", "Manifest nennt nicht das erwartete TASK_873-Schema."))
	if expected_readability_style_id != EXPECTED_CONTACT_FIRE_READABILITY_STYLE_ID:
		blockers.append(_issue("contact_fire_readability_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_873-Style-ID."))
	if window_capture_method != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht den direkten Window-Handle-Pfad."))
	if not window_capture_trusted:
		blockers.append(_issue("window_capture_not_trusted", "Window-Handle-Capture ist nicht vertrauenswuerdig."))
	if not window_handle_capture_succeeded:
		blockers.append(_issue("window_handle_capture_failed", "Window-Handle-Capture ist fehlgeschlagen."))
	if not missing_checks.is_empty():
		blockers.append(_issue("required_recapture_checks_missing", "TASK_877-Recapture-Pflichtchecks fehlen."))
	return blockers


static func _build_manual_findings(review_notes: Dictionary) -> Array:
	var findings: Array = []
	for key in REQUIRED_RECAPTURE_CHECKS:
		if not review_notes.has(String(key)):
			continue
		findings.append({
			"id": String(key),
			"passed": bool(review_notes.get(String(key), false)),
		})
	return findings


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
