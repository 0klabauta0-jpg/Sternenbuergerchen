class_name ReleaseFirstExchangeFireVisualRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_visual_recapture.v1"
const TASK_ID: String = "TASK_881"
const SOURCE_TASK_ID: String = "TASK_880"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_877"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const EXPECTED_FIRE_VISUAL_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_visual_polish.v1"
const EXPECTED_FIRE_VISUAL_STYLE_ID: String = "task_880_release_first_exchange_fire_visual_polish_v1"
const EXPECTED_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const EXPECTED_VISIBLE_STATUS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
const EXPECTED_VISIBLE_STATUS_STYLE_ID: String = "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
const NEXT_TASK_IF_REVIEW_NEEDED: String = "TASK_882 - Release First Exchange Fire Visual Findings"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"

const REQUIRED_RECAPTURE_CHECKS: PackedStringArray = [
	"release_exe_started_with_first_go_firefight_arg",
	"task_880_fire_visual_polish_expected",
	"task_879_status_source_trace_expected",
	"task_877_window_handle_recapture_source_expected",
	"task_876_visible_status_source_expected",
	"window_handle_capture_trusted",
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"contact_fire_visible_in_event_log",
	"fire_trace_visible",
	"impact_visible",
	"target_focus_visible",
	"short_fire_status_label_visible",
	"command_surfaces_still_usable",
	"no_stale_no_los_or_contact_pressure_only_message",
	"manual_visual_review_done",
]


static func build_snapshot(capture_manifest: Dictionary, fire_visual_snapshot: Dictionary = {}, review_notes: Dictionary = {}) -> Dictionary:
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
	var expected_fire_schema: String = String(capture_manifest.get("expected_fire_visual_schema", fire_visual_snapshot.get("schema", ""))).strip_edges()
	var expected_fire_style_id: String = String(capture_manifest.get("expected_fire_visual_style_id", fire_visual_snapshot.get("style_id", ""))).strip_edges()
	var expected_trace_schema: String = String(capture_manifest.get("expected_trace_schema", "")).strip_edges()
	var expected_visible_schema: String = String(capture_manifest.get("expected_visible_status_schema", "")).strip_edges()
	var expected_visible_style_id: String = String(capture_manifest.get("expected_visible_status_style_id", "")).strip_edges()
	var fire_task_id: String = String(fire_visual_snapshot.get("task_id", "")).strip_edges()
	var fire_gate: String = String(fire_visual_snapshot.get("gate", fire_visual_snapshot.get("status", ""))).strip_edges()
	var fire_read_only: bool = bool(fire_visual_snapshot.get("read_only", capture_manifest.get("read_only_capture", true)))
	var runtime_trace_written: bool = bool(capture_manifest.get("runtime_trace_written", false))
	var runtime_trace_activation_observed: bool = bool(capture_manifest.get("runtime_trace_activation_observed", false))
	var runtime_trace_final_stale_status: bool = bool(capture_manifest.get("runtime_trace_final_no_los_or_contact_pressure_observed", false))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", capture_manifest.get("manual_review_done", false)))
	var review_ready: bool = gate == "review_ready" or gate == "review" or gate == "manual_open"

	var blockers: Array = _build_blockers(
		review_ready,
		hard_failures,
		window_screenshot_written,
		String(capture_manifest.get("schema", "")),
		String(capture_manifest.get("task_id", "")),
		String(capture_manifest.get("source_task_id", "")),
		String(capture_manifest.get("source_trace_task_id", "")),
		String(capture_manifest.get("source_visible_status_task_id", "")),
		String(capture_manifest.get("source_recapture_task_id", "")),
		String(capture_manifest.get("source_focus_task_id", "")),
		String(capture_manifest.get("source_exchange_task_id", "")),
		String(capture_manifest.get("launch_argument", "")),
		expected_fire_schema,
		expected_fire_style_id,
		expected_trace_schema,
		expected_visible_schema,
		expected_visible_style_id,
		window_capture_method,
		window_capture_trusted,
		window_handle_capture_succeeded,
		runtime_trace_written,
		runtime_trace_activation_observed,
		fire_task_id,
		fire_gate,
		fire_read_only,
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
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_focus_task_id": SOURCE_FOCUS_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"capture_gate": gate,
		"capture_review_ready": review_ready,
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"launch_argument_ok": String(capture_manifest.get("launch_argument", "")) == FIRST_GO_ARG,
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
		"expected_fire_visual_schema": expected_fire_schema,
		"expected_fire_visual_style_id": expected_fire_style_id,
		"fire_visual_schema_ok": expected_fire_schema == EXPECTED_FIRE_VISUAL_SCHEMA,
		"fire_visual_style_id_ok": expected_fire_style_id == EXPECTED_FIRE_VISUAL_STYLE_ID,
		"fire_visual_task_id": fire_task_id,
		"fire_visual_gate": fire_gate,
		"fire_visual_snapshot_read_only": fire_read_only,
		"expected_trace_schema": expected_trace_schema,
		"trace_schema_ok": expected_trace_schema == EXPECTED_TRACE_SCHEMA,
		"expected_visible_status_schema": expected_visible_schema,
		"expected_visible_status_style_id": expected_visible_style_id,
		"visible_status_schema_ok": expected_visible_schema == EXPECTED_VISIBLE_STATUS_SCHEMA,
		"visible_status_style_id_ok": expected_visible_style_id == EXPECTED_VISIBLE_STATUS_STYLE_ID,
		"runtime_trace_written": runtime_trace_written,
		"runtime_trace_sample_count": int(capture_manifest.get("runtime_trace_sample_count", 0)),
		"runtime_trace_activation_observed": runtime_trace_activation_observed,
		"runtime_trace_final_no_los_or_contact_pressure_observed": runtime_trace_final_stale_status,
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
	source_trace_task_id: String,
	source_visible_status_task_id: String,
	source_recapture_task_id: String,
	source_focus_task_id: String,
	source_exchange_task_id: String,
	launch_argument: String,
	expected_fire_schema: String,
	expected_fire_style_id: String,
	expected_trace_schema: String,
	expected_visible_schema: String,
	expected_visible_style_id: String,
	window_capture_method: String,
	window_capture_trusted: bool,
	window_handle_capture_succeeded: bool,
	runtime_trace_written: bool,
	runtime_trace_activation_observed: bool,
	fire_task_id: String,
	fire_gate: String,
	fire_read_only: bool,
	missing_checks: Array
) -> Array:
	var blockers: Array = []
	if schema != SCHEMA:
		blockers.append(_issue("recapture_schema_mismatch", "TASK_881-Recapture-Schema fehlt oder passt nicht."))
	if task_id != TASK_ID:
		blockers.append(_issue("recapture_task_mismatch", "Manifest nennt nicht TASK_881."))
	if source_task_id != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_880 als Fire-Visual-Quelle."))
	if source_trace_task_id != SOURCE_TRACE_TASK_ID:
		blockers.append(_issue("source_trace_mismatch", "Manifest nennt nicht TASK_879 als Trace-Quelle."))
	if source_visible_status_task_id != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append(_issue("source_visible_status_mismatch", "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."))
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_mismatch", "Manifest nennt nicht TASK_877 als Window-Recapture-Quelle."))
	if source_focus_task_id != SOURCE_FOCUS_TASK_ID:
		blockers.append(_issue("source_focus_mismatch", "Manifest nennt nicht TASK_850 als Focus-Visual-Quelle."))
	if source_exchange_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append(_issue("source_exchange_mismatch", "Manifest nennt nicht TASK_844 als Exchange-Quelle."))
	if launch_argument != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if not review_ready:
		blockers.append(_issue("capture_not_review_ready", "TASK_881-Capture ist weder review_ready, review noch manual_open."))
	if not hard_failures.is_empty():
		blockers.append(_issue("capture_hard_failures", "TASK_881-Capture meldet Hard-Failures."))
	if not window_screenshot_written:
		blockers.append(_issue("window_screenshot_missing", "Fenster-Screenshot fehlt."))
	if expected_fire_schema != EXPECTED_FIRE_VISUAL_SCHEMA:
		blockers.append(_issue("fire_visual_schema_mismatch", "Manifest nennt nicht das erwartete TASK_880-Schema."))
	if expected_fire_style_id != EXPECTED_FIRE_VISUAL_STYLE_ID:
		blockers.append(_issue("fire_visual_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_880-Style-ID."))
	if expected_trace_schema != EXPECTED_TRACE_SCHEMA:
		blockers.append(_issue("trace_schema_mismatch", "Manifest nennt nicht das erwartete TASK_879-Trace-Schema."))
	if expected_visible_schema != EXPECTED_VISIBLE_STATUS_SCHEMA:
		blockers.append(_issue("visible_status_schema_mismatch", "Manifest nennt nicht das erwartete TASK_876-Schema."))
	if expected_visible_style_id != EXPECTED_VISIBLE_STATUS_STYLE_ID:
		blockers.append(_issue("visible_status_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_876-Style-ID."))
	if window_capture_method != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht den direkten Window-Handle-Pfad."))
	if not window_capture_trusted:
		blockers.append(_issue("window_capture_not_trusted", "Window-Handle-Capture ist nicht vertrauenswuerdig."))
	if not window_handle_capture_succeeded:
		blockers.append(_issue("window_handle_capture_failed", "Window-Handle-Capture ist fehlgeschlagen."))
	if not runtime_trace_written:
		blockers.append(_issue("runtime_trace_missing", "TASK_879 Runtime-Trace fehlt."))
	if not runtime_trace_activation_observed:
		blockers.append(_issue("status_source_activation_missing", "TASK_876-Aktivierung wurde im Trace nicht beobachtet."))
	if fire_task_id != "" and fire_task_id != SOURCE_TASK_ID:
		blockers.append(_issue("fire_visual_task_mismatch", "Fire-Visual-Snapshot nennt nicht TASK_880."))
	if fire_gate != "" and fire_gate != "pass":
		blockers.append(_issue("fire_visual_snapshot_not_pass", "TASK_880-Fire-Visual-Snapshot ist nicht pass."))
	if not fire_read_only:
		blockers.append(_issue("fire_visual_snapshot_not_read_only", "TASK_880-Fire-Visual-Snapshot ist nicht read-only."))
	if not missing_checks.is_empty():
		blockers.append(_issue("required_recapture_checks_missing", "TASK_881-Recapture-Pflichtchecks fehlen."))
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


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
