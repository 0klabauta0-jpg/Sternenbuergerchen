class_name ReleaseFireExchangeFocusedVisualRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_focused_visual_recapture.v1"
const TASK_ID: String = "TASK_851"
const SOURCE_TASK_ID: String = "TASK_850"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_845"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_TASK_ID: String = "TASK_837"
const EXPECTED_FOCUS_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1"
const EXPECTED_FOCUS_STYLE_ID: String = "task_850_release_fire_exchange_focused_visual_polish_v1"
const EXPECTED_EXCHANGE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const EXPECTED_EXCHANGE_STYLE_ID: String = "task_844_release_first_exchange_tension_tuning_v1"
const NEXT_TASK_IF_REVIEW_NEEDED: String = "TASK_852 - Release Fire Exchange Focused Visual Findings"

const REQUIRED_RECAPTURE_CHECKS: PackedStringArray = [
	"release_exe_started_with_first_go_firefight_arg",
	"task_850_focus_visual_expected",
	"contact_fire_or_fire_exchange_visible",
	"fire_trace_or_impact_visible",
	"target_focus_visible",
	"world_lines_dimmer_than_fire_vfx",
	"selected_fireteam_next_why_mentions_contact_or_fire",
	"mission_control_next_why_mentions_contact_or_fire",
	"event_log_contact_fire_or_exchange_detail_visible",
	"command_matrix_controls_remain_usable",
	"no_stale_contact_pressure_only_message",
	"manual_visual_review_done",
]


static func build_snapshot(capture_manifest: Dictionary, focus_snapshot: Dictionary = {}, review_notes: Dictionary = {}) -> Dictionary:
	var gate: String = String(capture_manifest.get("gate", "")).strip_edges()
	var hard_failures: Array = Array(capture_manifest.get("hard_failures", []))
	var warnings: Array = Array(capture_manifest.get("warnings", []))
	var required_checks: Array = Array(capture_manifest.get("required_checks", []))
	var missing_checks: Array = _missing_required_checks(required_checks)
	var window_screenshot_written: bool = bool(capture_manifest.get("window_screenshot_written", false))
	var desktop_screenshot_written: bool = bool(capture_manifest.get("desktop_screenshot_written", false))
	var source_task_id: String = String(capture_manifest.get("source_task_id", "")).strip_edges()
	var source_recapture_task_id: String = String(capture_manifest.get("source_recapture_task_id", "")).strip_edges()
	var source_capture_task_id: String = String(capture_manifest.get("source_capture_task_id", "")).strip_edges()
	var expected_focus_schema: String = String(capture_manifest.get("expected_focus_schema", focus_snapshot.get("schema", ""))).strip_edges()
	var expected_focus_style_id: String = String(capture_manifest.get("expected_focus_style_id", focus_snapshot.get("style_id", ""))).strip_edges()
	var expected_exchange_schema: String = String(capture_manifest.get("expected_exchange_schema", "")).strip_edges()
	var expected_exchange_style_id: String = String(capture_manifest.get("expected_exchange_style_id", "")).strip_edges()
	var focus_task_id: String = String(focus_snapshot.get("task_id", "")).strip_edges()
	var focus_status: String = String(focus_snapshot.get("status", capture_manifest.get("focus_snapshot_status", ""))).strip_edges()
	var focus_read_only: bool = bool(focus_snapshot.get("read_only", capture_manifest.get("focus_read_only", true)))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", capture_manifest.get("manual_review_done", false)))
	var review_ready: bool = gate == "review_ready" or gate == "manual_open"

	var blockers: Array = _build_blockers(
		review_ready,
		hard_failures,
		window_screenshot_written,
		source_task_id,
		source_recapture_task_id,
		source_capture_task_id,
		expected_focus_schema,
		expected_focus_style_id,
		expected_exchange_schema,
		expected_exchange_style_id,
		focus_task_id,
		focus_status,
		focus_read_only,
		missing_checks
	)
	var manual_findings: Array = _build_manual_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_manual_review"
	if status != "blocked" and manual_review_done:
		status = "manual_review_recorded"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"source_capture_task_id": SOURCE_CAPTURE_TASK_ID,
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
		"expected_focus_schema": expected_focus_schema,
		"expected_focus_style_id": expected_focus_style_id,
		"focus_schema_ok": expected_focus_schema == EXPECTED_FOCUS_SCHEMA,
		"focus_style_id_ok": expected_focus_style_id == EXPECTED_FOCUS_STYLE_ID,
		"focus_task_id": focus_task_id,
		"focus_status": focus_status,
		"focus_snapshot_read_only": focus_read_only,
		"expected_exchange_schema": expected_exchange_schema,
		"expected_exchange_style_id": expected_exchange_style_id,
		"exchange_schema_ok": expected_exchange_schema == EXPECTED_EXCHANGE_SCHEMA,
		"exchange_style_id_ok": expected_exchange_style_id == EXPECTED_EXCHANGE_STYLE_ID,
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
	source_task_id: String,
	source_recapture_task_id: String,
	source_capture_task_id: String,
	expected_focus_schema: String,
	expected_focus_style_id: String,
	expected_exchange_schema: String,
	expected_exchange_style_id: String,
	focus_task_id: String,
	focus_status: String,
	focus_read_only: bool,
	missing_checks: Array
) -> Array:
	var blockers: Array = []
	if not review_ready:
		blockers.append({"id": "capture_not_review_ready", "text": "Focused recapture ist weder review_ready noch manual_open."})
	if not hard_failures.is_empty():
		blockers.append({"id": "capture_hard_failures", "text": "Focused recapture meldet Hard-Failures."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if source_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "source_task_mismatch", "text": "Manifest nennt nicht TASK_850 als Focus-Quelle."})
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append({"id": "source_recapture_mismatch", "text": "Manifest nennt nicht TASK_845 als Recapture-Quelle."})
	if source_capture_task_id != SOURCE_CAPTURE_TASK_ID:
		blockers.append({"id": "source_capture_mismatch", "text": "Manifest nennt nicht TASK_837 als Capture-Quelle."})
	if expected_focus_schema != EXPECTED_FOCUS_SCHEMA:
		blockers.append({"id": "focus_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_850-Focus-Schema."})
	if expected_focus_style_id != EXPECTED_FOCUS_STYLE_ID:
		blockers.append({"id": "focus_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_850-Style-ID."})
	if expected_exchange_schema != EXPECTED_EXCHANGE_SCHEMA:
		blockers.append({"id": "exchange_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_844-Exchange-Schema."})
	if expected_exchange_style_id != EXPECTED_EXCHANGE_STYLE_ID:
		blockers.append({"id": "exchange_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_844-Exchange-Style-ID."})
	if focus_task_id != "" and focus_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "focus_task_mismatch", "text": "Focus-Snapshot nennt nicht TASK_850."})
	if focus_status != "" and focus_status != "pass":
		blockers.append({"id": "focus_snapshot_not_pass", "text": "TASK_850-Focus-Snapshot ist nicht pass."})
	if not focus_read_only:
		blockers.append({"id": "focus_snapshot_not_read_only", "text": "TASK_850-Focus-Snapshot ist nicht read-only."})
	if not missing_checks.is_empty():
		blockers.append({"id": "required_recapture_checks_missing", "text": "Focused-Recapture-Pflichtchecks fehlen."})
	return blockers


static func _build_manual_findings(review_notes: Dictionary) -> Array:
	var findings: Array = []
	for key in REQUIRED_RECAPTURE_CHECKS:
		var id: String = String(key)
		if review_notes.has(id):
			findings.append({
				"id": id,
				"passed": bool(review_notes.get(id)),
			})
	return findings
