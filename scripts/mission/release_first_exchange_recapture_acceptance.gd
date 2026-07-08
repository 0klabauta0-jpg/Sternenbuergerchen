class_name ReleaseFirstExchangeRecaptureAcceptance
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_recapture_acceptance.v1"
const TASK_ID: String = "TASK_848"
const SOURCE_TASK_ID: String = "TASK_845"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_TASK_ID: String = "TASK_837"
const EXPECTED_VISIBILITY_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1"
const EXPECTED_VISIBILITY_STYLE_ID: String = "task_847_release_fire_exchange_visibility_persistence_v1"
const EXPECTED_EXCHANGE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const EXPECTED_EXCHANGE_STYLE_ID: String = "task_844_release_first_exchange_tension_tuning_v1"
const NEXT_TASK_IF_PASS: String = "TASK_849 - Release Fire Exchange Visual Polish Findings"

const REQUIRED_ACCEPTANCE_CHECKS: PackedStringArray = [
	"contact_fire_or_fire_exchange_visible",
	"event_log_contact_fire_or_exchange_detail_visible",
	"selected_fireteam_next_why_mentions_contact_or_fire",
	"mission_control_next_why_mentions_contact_or_fire",
	"fire_event_trace_or_impact_visible",
	"no_stale_contact_pressure_only_message",
]


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var gate: String = String(recapture_manifest.get("gate", "")).strip_edges()
	var hard_failures: Array = Array(recapture_manifest.get("hard_failures", []))
	var warnings: Array = Array(recapture_manifest.get("warnings", []))
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var missing_checks: Array = _missing_required_checks(required_checks)
	var window_screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var desktop_screenshot_written: bool = bool(recapture_manifest.get("desktop_screenshot_written", false))
	var source_task_id: String = String(recapture_manifest.get("source_task_id", "")).strip_edges()
	var source_capture_task_id: String = String(recapture_manifest.get("source_capture_task_id", "")).strip_edges()
	var exchange_schema: String = String(recapture_manifest.get("expected_exchange_schema", "")).strip_edges()
	var exchange_style_id: String = String(recapture_manifest.get("expected_exchange_style_id", "")).strip_edges()
	var manual_review_done: bool = bool(review_notes.get("manual_review_done", recapture_manifest.get("manual_review_done", false)))
	var contact_fire_visible: bool = bool(review_notes.get("contact_fire_or_fire_exchange_visible", false))
	var trace_or_impact_visible: bool = bool(review_notes.get("fire_event_trace_or_impact_visible", false))
	var no_stale_pressure_only: bool = bool(review_notes.get("no_stale_contact_pressure_only_message", false))
	var review_ready: bool = gate == "review_ready" or gate == "manual_open"

	var blockers: Array = _build_blockers(
		review_ready,
		hard_failures,
		window_screenshot_written,
		source_task_id,
		source_capture_task_id,
		exchange_schema,
		exchange_style_id,
		missing_checks
	)
	var manual_findings: Array = _build_manual_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_manual_acceptance"
	if manual_review_done and contact_fire_visible and trace_or_impact_visible and no_stale_pressure_only and blockers.is_empty():
		status = "accepted"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"source_capture_task_id": SOURCE_CAPTURE_TASK_ID,
		"recapture_gate": gate,
		"recapture_review_ready": review_ready,
		"branch": String(recapture_manifest.get("branch", "")),
		"git_head": String(recapture_manifest.get("git_head", "")),
		"launch_argument": String(recapture_manifest.get("launch_argument", "")),
		"wait_seconds": int(recapture_manifest.get("wait_seconds", 0)),
		"window_screenshot_written": window_screenshot_written,
		"desktop_screenshot_written": desktop_screenshot_written,
		"window_screenshot_path": String(recapture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(recapture_manifest.get("desktop_screenshot_path", "")),
		"window_screenshot_full_path": String(recapture_manifest.get("window_screenshot_full_path", "")),
		"desktop_screenshot_full_path": String(recapture_manifest.get("desktop_screenshot_full_path", "")),
		"expected_visibility_schema": EXPECTED_VISIBILITY_SCHEMA,
		"expected_visibility_style_id": EXPECTED_VISIBILITY_STYLE_ID,
		"expected_exchange_schema": exchange_schema,
		"expected_exchange_style_id": exchange_style_id,
		"exchange_schema_ok": exchange_schema == EXPECTED_EXCHANGE_SCHEMA,
		"exchange_style_id_ok": exchange_style_id == EXPECTED_EXCHANGE_STYLE_ID,
		"required_checks": required_checks,
		"required_acceptance_checks": Array(REQUIRED_ACCEPTANCE_CHECKS),
		"missing_acceptance_checks": missing_checks,
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
		"recommended_next_task": NEXT_TASK_IF_PASS,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _missing_required_checks(required_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_ACCEPTANCE_CHECKS:
		if not required_checks.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _build_blockers(
	review_ready: bool,
	hard_failures: Array,
	window_screenshot_written: bool,
	source_task_id: String,
	source_capture_task_id: String,
	exchange_schema: String,
	exchange_style_id: String,
	missing_checks: Array
) -> Array:
	var blockers: Array = []
	if not review_ready:
		blockers.append({"id": "recapture_not_review_ready", "text": "Recapture ist weder review_ready noch manual_open."})
	if not hard_failures.is_empty():
		blockers.append({"id": "recapture_hard_failures", "text": "Recapture meldet Hard-Failures."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if source_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append({"id": "source_task_mismatch", "text": "Recapture nennt nicht TASK_844 als Exchange-Quelle."})
	if source_capture_task_id != SOURCE_CAPTURE_TASK_ID:
		blockers.append({"id": "source_capture_mismatch", "text": "Recapture nennt nicht TASK_837 als Capture-Quelle."})
	if exchange_schema != EXPECTED_EXCHANGE_SCHEMA:
		blockers.append({"id": "exchange_schema_mismatch", "text": "Recapture nennt nicht das erwartete Exchange-Schema."})
	if exchange_style_id != EXPECTED_EXCHANGE_STYLE_ID:
		blockers.append({"id": "exchange_style_id_mismatch", "text": "Recapture nennt nicht die erwartete Exchange-Style-ID."})
	if not missing_checks.is_empty():
		blockers.append({"id": "required_acceptance_checks_missing", "text": "Acceptance-Pflichtchecks fehlen."})
	return blockers


static func _build_manual_findings(review_notes: Dictionary) -> Array:
	var findings: Array = []
	for key in REQUIRED_ACCEPTANCE_CHECKS:
		var id: String = String(key)
		if review_notes.has(id):
			findings.append({
				"id": id,
				"passed": bool(review_notes.get(id)),
			})
	return findings
