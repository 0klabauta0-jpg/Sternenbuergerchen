class_name ReleaseFireExchangeRealWindowContactFireRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_real_window_contact_fire_recapture.v1"
const TASK_ID: String = "TASK_860"
const SOURCE_TASK_ID: String = "TASK_859"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_857"
const SOURCE_PRIMARY_HUD_TASK_ID: String = "TASK_856"
const SOURCE_AFTER_READABILITY_RECAPTURE_TASK_ID: String = "TASK_854"
const SOURCE_READABILITY_TASK_ID: String = "TASK_853"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_TASK_ID: String = "TASK_837"
const EXPECTED_SOURCE_BINDING_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_source_binding_polish.v1"
const EXPECTED_SOURCE_BINDING_STYLE_ID: String = "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
const EXPECTED_PRIMARY_HUD_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_polish.v1"
const EXPECTED_PRIMARY_HUD_STYLE_ID: String = "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
const EXPECTED_READABILITY_STYLE_ID: String = "task_853_release_fire_exchange_engagement_readability_v1"
const EXPECTED_FOCUS_STYLE_ID: String = "task_850_release_fire_exchange_focused_visual_polish_v1"
const MIN_CAPTURE_SAFE_DURATION_MSEC: int = 42000
const NEXT_TASK_IF_REVIEW_NEEDED: String = "TASK_861 - Release Fire Exchange Real Window Contact-Fire Visual Findings"

const REQUIRED_RECAPTURE_CHECKS: PackedStringArray = [
	"release_exe_started_with_first_go_firefight_arg",
	"task_859_source_binding_expected",
	"task_856_primary_hud_expected",
	"contact_fire_first_reading_visible_in_selected_fireteam",
	"contact_fire_first_reading_visible_in_mission_control",
	"primary_hud_no_debug_no_fire_before_contact_fire",
	"event_log_contact_fire_visible",
	"fire_trace_or_impact_target_focus_visible",
	"command_surfaces_still_usable",
	"manual_visual_review_done",
]


static func build_snapshot(capture_manifest: Dictionary, source_binding_snapshot: Dictionary = {}, review_notes: Dictionary = {}) -> Dictionary:
	var gate: String = String(capture_manifest.get("gate", "")).strip_edges()
	var hard_failures: Array = Array(capture_manifest.get("hard_failures", []))
	var warnings: Array = Array(capture_manifest.get("warnings", []))
	var required_checks: Array = Array(capture_manifest.get("required_checks", []))
	var missing_checks: Array = _missing_required_checks(required_checks)
	var window_screenshot_written: bool = bool(capture_manifest.get("window_screenshot_written", false))
	var desktop_screenshot_written: bool = bool(capture_manifest.get("desktop_screenshot_written", false))
	var expected_source_binding_schema: String = String(capture_manifest.get("expected_source_binding_schema", source_binding_snapshot.get("schema", ""))).strip_edges()
	var expected_source_binding_style_id: String = String(capture_manifest.get("expected_source_binding_style_id", source_binding_snapshot.get("style_id", ""))).strip_edges()
	var expected_primary_hud_schema: String = String(capture_manifest.get("expected_primary_hud_schema", "")).strip_edges()
	var expected_primary_hud_style_id: String = String(capture_manifest.get("expected_primary_hud_style_id", "")).strip_edges()
	var expected_readability_style_id: String = String(capture_manifest.get("expected_readability_style_id", "")).strip_edges()
	var expected_focus_style_id: String = String(capture_manifest.get("expected_focus_style_id", "")).strip_edges()
	var expected_persistence_duration_msec: int = int(capture_manifest.get("expected_persistence_duration_msec", 0))
	var source_binding_task_id: String = String(source_binding_snapshot.get("task_id", "")).strip_edges()
	var source_binding_status: String = String(source_binding_snapshot.get("status", capture_manifest.get("source_binding_snapshot_status", ""))).strip_edges()
	var source_binding_read_only: bool = bool(source_binding_snapshot.get("read_only", capture_manifest.get("source_binding_read_only", true)))
	var selected_bound: bool = bool(source_binding_snapshot.get("selected_fireteam_real_window_bound_to_contact_fire", capture_manifest.get("selected_fireteam_real_window_bound_to_contact_fire", true)))
	var mission_bound: bool = bool(source_binding_snapshot.get("mission_control_real_window_bound_to_contact_fire", capture_manifest.get("mission_control_real_window_bound_to_contact_fire", true)))
	var no_fire_before_contact: bool = bool(source_binding_snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", false))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", capture_manifest.get("manual_review_done", false)))
	var review_ready: bool = gate == "review_ready" or gate == "manual_open"
	var blockers: Array = _build_blockers(
		review_ready,
		hard_failures,
		window_screenshot_written,
		String(capture_manifest.get("source_task_id", "")),
		String(capture_manifest.get("source_recapture_task_id", "")),
		String(capture_manifest.get("source_primary_hud_task_id", "")),
		String(capture_manifest.get("source_after_readability_recapture_task_id", "")),
		String(capture_manifest.get("source_readability_task_id", "")),
		String(capture_manifest.get("source_focus_task_id", "")),
		String(capture_manifest.get("source_visibility_task_id", "")),
		String(capture_manifest.get("source_exchange_task_id", "")),
		String(capture_manifest.get("source_capture_task_id", "")),
		expected_source_binding_schema,
		expected_source_binding_style_id,
		expected_primary_hud_schema,
		expected_primary_hud_style_id,
		expected_readability_style_id,
		expected_focus_style_id,
		expected_persistence_duration_msec,
		source_binding_task_id,
		source_binding_status,
		source_binding_read_only,
		selected_bound,
		mission_bound,
		no_fire_before_contact,
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
		"source_primary_hud_task_id": SOURCE_PRIMARY_HUD_TASK_ID,
		"source_after_readability_recapture_task_id": SOURCE_AFTER_READABILITY_RECAPTURE_TASK_ID,
		"source_readability_task_id": SOURCE_READABILITY_TASK_ID,
		"source_focus_task_id": SOURCE_FOCUS_TASK_ID,
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
		"expected_source_binding_schema": expected_source_binding_schema,
		"expected_source_binding_style_id": expected_source_binding_style_id,
		"source_binding_schema_ok": expected_source_binding_schema == EXPECTED_SOURCE_BINDING_SCHEMA,
		"source_binding_style_id_ok": expected_source_binding_style_id == EXPECTED_SOURCE_BINDING_STYLE_ID,
		"source_binding_task_id": source_binding_task_id,
		"source_binding_status": source_binding_status,
		"source_binding_read_only": source_binding_read_only,
		"selected_fireteam_real_window_bound_to_contact_fire": selected_bound,
		"mission_control_real_window_bound_to_contact_fire": mission_bound,
		"primary_lines_contain_debug_no_fire_before_contact_fire": no_fire_before_contact,
		"expected_primary_hud_schema": expected_primary_hud_schema,
		"expected_primary_hud_style_id": expected_primary_hud_style_id,
		"primary_hud_schema_ok": expected_primary_hud_schema == EXPECTED_PRIMARY_HUD_SCHEMA,
		"primary_hud_style_id_ok": expected_primary_hud_style_id == EXPECTED_PRIMARY_HUD_STYLE_ID,
		"expected_readability_style_id": expected_readability_style_id,
		"readability_style_id_ok": expected_readability_style_id == EXPECTED_READABILITY_STYLE_ID,
		"expected_focus_style_id": expected_focus_style_id,
		"focus_style_id_ok": expected_focus_style_id == EXPECTED_FOCUS_STYLE_ID,
		"expected_persistence_duration_msec": expected_persistence_duration_msec,
		"persistence_window_covers_capture_delay": expected_persistence_duration_msec >= MIN_CAPTURE_SAFE_DURATION_MSEC,
		"minimum_capture_safe_duration_msec": MIN_CAPTURE_SAFE_DURATION_MSEC,
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
	source_primary_hud_task_id: String,
	source_after_readability_recapture_task_id: String,
	source_readability_task_id: String,
	source_focus_task_id: String,
	source_visibility_task_id: String,
	source_exchange_task_id: String,
	source_capture_task_id: String,
	expected_source_binding_schema: String,
	expected_source_binding_style_id: String,
	expected_primary_hud_schema: String,
	expected_primary_hud_style_id: String,
	expected_readability_style_id: String,
	expected_focus_style_id: String,
	expected_persistence_duration_msec: int,
	source_binding_task_id: String,
	source_binding_status: String,
	source_binding_read_only: bool,
	selected_bound: bool,
	mission_bound: bool,
	no_fire_before_contact: bool,
	missing_checks: Array
) -> Array:
	var blockers: Array = []
	if not review_ready:
		blockers.append(_issue("capture_not_review_ready", "Real-window contact-fire recapture ist weder review_ready noch manual_open."))
	if not hard_failures.is_empty():
		blockers.append(_issue("capture_hard_failures", "Real-window contact-fire recapture meldet Hard-Failures."))
	if not window_screenshot_written:
		blockers.append(_issue("window_screenshot_missing", "Fenster-Screenshot fehlt."))
	if source_task_id != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_859 als Source-Binding-Quelle."))
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_mismatch", "Manifest nennt nicht TASK_857 als Recapture-Quelle."))
	if source_primary_hud_task_id != SOURCE_PRIMARY_HUD_TASK_ID:
		blockers.append(_issue("source_primary_hud_mismatch", "Manifest nennt nicht TASK_856 als Primary-HUD-Quelle."))
	if source_after_readability_recapture_task_id != SOURCE_AFTER_READABILITY_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_after_readability_recapture_mismatch", "Manifest nennt nicht TASK_854 als Recapture-Quelle."))
	if source_readability_task_id != SOURCE_READABILITY_TASK_ID:
		blockers.append(_issue("source_readability_mismatch", "Manifest nennt nicht TASK_853 als Readability-Quelle."))
	if source_focus_task_id != SOURCE_FOCUS_TASK_ID:
		blockers.append(_issue("source_focus_mismatch", "Manifest nennt nicht TASK_850 als Focus-Quelle."))
	if source_visibility_task_id != SOURCE_VISIBILITY_TASK_ID:
		blockers.append(_issue("source_visibility_mismatch", "Manifest nennt nicht TASK_847 als Visibility-Quelle."))
	if source_exchange_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append(_issue("source_exchange_mismatch", "Manifest nennt nicht TASK_844 als Exchange-Quelle."))
	if source_capture_task_id != SOURCE_CAPTURE_TASK_ID:
		blockers.append(_issue("source_capture_mismatch", "Manifest nennt nicht TASK_837 als Capture-Quelle."))
	if expected_source_binding_schema != EXPECTED_SOURCE_BINDING_SCHEMA:
		blockers.append(_issue("source_binding_schema_mismatch", "Manifest nennt nicht das erwartete TASK_859-Source-Binding-Schema."))
	if expected_source_binding_style_id != EXPECTED_SOURCE_BINDING_STYLE_ID:
		blockers.append(_issue("source_binding_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_859-Style-ID."))
	if expected_primary_hud_schema != EXPECTED_PRIMARY_HUD_SCHEMA:
		blockers.append(_issue("primary_hud_schema_mismatch", "Manifest nennt nicht das erwartete TASK_856-HUD-Schema."))
	if expected_primary_hud_style_id != EXPECTED_PRIMARY_HUD_STYLE_ID:
		blockers.append(_issue("primary_hud_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_856-Style-ID."))
	if expected_readability_style_id != EXPECTED_READABILITY_STYLE_ID:
		blockers.append(_issue("readability_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_853-Style-ID."))
	if expected_focus_style_id != EXPECTED_FOCUS_STYLE_ID:
		blockers.append(_issue("focus_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_850-Style-ID."))
	if expected_persistence_duration_msec < MIN_CAPTURE_SAFE_DURATION_MSEC:
		blockers.append(_issue("persistence_window_too_short", "Fire-Exchange-Persistenz reicht nicht fuer den echten Fensterblick."))
	if source_binding_task_id != "" and source_binding_task_id != SOURCE_TASK_ID:
		blockers.append(_issue("source_binding_task_mismatch", "Source-Binding-Snapshot nennt nicht TASK_859."))
	if source_binding_status != "" and source_binding_status != "pass":
		blockers.append(_issue("source_binding_snapshot_not_pass", "TASK_859-Source-Binding-Snapshot ist nicht pass."))
	if not source_binding_read_only:
		blockers.append(_issue("source_binding_snapshot_not_read_only", "TASK_859-Source-Binding-Snapshot ist nicht read-only."))
	if not selected_bound:
		blockers.append(_issue("selected_fireteam_not_bound_to_contact_fire", "#17 ist im Source-Binding-Snapshot nicht an CONTACT FIRE gebunden."))
	if not mission_bound:
		blockers.append(_issue("mission_control_not_bound_to_contact_fire", "#18 ist im Source-Binding-Snapshot nicht an CONTACT FIRE gebunden."))
	if no_fire_before_contact:
		blockers.append(_issue("debug_no_fire_before_contact_fire", "NO FIRE steht im Source-Binding-Snapshot vor CONTACT FIRE."))
	if not missing_checks.is_empty():
		blockers.append(_issue("required_recapture_checks_missing", "TASK_860-Recapture-Pflichtchecks fehlen."))
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
