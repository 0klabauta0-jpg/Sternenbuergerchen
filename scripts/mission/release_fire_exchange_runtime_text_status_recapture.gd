class_name ReleaseFireExchangeRuntimeTextStatusRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_runtime_text_status_recapture.v1"
const TASK_ID: String = "TASK_866"
const SOURCE_TASK_ID: String = "TASK_865"
const SOURCE_RUNTIME_TEXT_TASK_ID: String = "TASK_862"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_863"
const SOURCE_PRIOR_RECAPTURE_TASK_ID: String = "TASK_860"
const SOURCE_BINDING_TASK_ID: String = "TASK_859"
const SOURCE_PRIMARY_HUD_TASK_ID: String = "TASK_856"
const SOURCE_READABILITY_TASK_ID: String = "TASK_853"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const SOURCE_CAPTURE_TASK_ID: String = "TASK_837"
const EXPECTED_RUNTIME_TEXT_SCHEMA: String = "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_runtime_text_polish.v1"
const EXPECTED_RUNTIME_TEXT_STYLE_ID: String = "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
const EXPECTED_SOURCE_BINDING_STYLE_ID: String = "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
const EXPECTED_PRIMARY_HUD_STYLE_ID: String = "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
const EXPECTED_READABILITY_STYLE_ID: String = "task_853_release_fire_exchange_engagement_readability_v1"
const EXPECTED_FOCUS_STYLE_ID: String = "task_850_release_fire_exchange_focused_visual_polish_v1"
const MIN_CAPTURE_SAFE_DURATION_MSEC: int = 42000
const NEXT_TASK_IF_REVIEW_NEEDED: String = "TASK_867 - Release Fire Exchange Runtime Text Status Visual Findings"

const REQUIRED_RECAPTURE_CHECKS: PackedStringArray = [
	"release_exe_started_with_first_go_firefight_arg",
	"task_865_status_polish_expected",
	"task_862_runtime_text_expected",
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


static func build_snapshot(capture_manifest: Dictionary, runtime_text_snapshot: Dictionary = {}, review_notes: Dictionary = {}) -> Dictionary:
	var gate: String = String(capture_manifest.get("gate", "")).strip_edges()
	var hard_failures: Array = Array(capture_manifest.get("hard_failures", []))
	var warnings: Array = Array(capture_manifest.get("warnings", []))
	var required_checks: Array = Array(capture_manifest.get("required_checks", []))
	var missing_checks: Array = _missing_required_checks(required_checks)
	var window_screenshot_written: bool = bool(capture_manifest.get("window_screenshot_written", false))
	var expected_runtime_text_schema: String = String(capture_manifest.get("expected_runtime_text_schema", runtime_text_snapshot.get("schema", ""))).strip_edges()
	var expected_runtime_text_style_id: String = String(capture_manifest.get("expected_runtime_text_style_id", runtime_text_snapshot.get("style_id", ""))).strip_edges()
	var expected_source_binding_style_id: String = String(capture_manifest.get("expected_source_binding_style_id", "")).strip_edges()
	var expected_primary_hud_style_id: String = String(capture_manifest.get("expected_primary_hud_style_id", "")).strip_edges()
	var expected_readability_style_id: String = String(capture_manifest.get("expected_readability_style_id", "")).strip_edges()
	var expected_focus_style_id: String = String(capture_manifest.get("expected_focus_style_id", "")).strip_edges()
	var expected_persistence_duration_msec: int = int(capture_manifest.get("expected_persistence_duration_msec", 0))
	var runtime_text_task_id: String = String(runtime_text_snapshot.get("task_id", "")).strip_edges()
	var runtime_text_status: String = String(runtime_text_snapshot.get("status", capture_manifest.get("runtime_text_snapshot_status", ""))).strip_edges()
	var runtime_text_read_only: bool = bool(runtime_text_snapshot.get("read_only", capture_manifest.get("runtime_text_read_only", true)))
	var selected_contact_first: bool = bool(runtime_text_snapshot.get("selected_fireteam_runtime_text_contact_fire_first", capture_manifest.get("selected_fireteam_runtime_text_contact_fire_first", true)))
	var mission_contact_first: bool = bool(runtime_text_snapshot.get("mission_control_runtime_text_contact_fire_first", capture_manifest.get("mission_control_runtime_text_contact_fire_first", true)))
	var no_fire_before_contact: bool = bool(runtime_text_snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", false))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", capture_manifest.get("manual_review_done", false)))
	var review_ready: bool = gate == "review_ready" or gate == "manual_open"
	var blockers: Array = _build_blockers(
		review_ready,
		hard_failures,
		window_screenshot_written,
		String(capture_manifest.get("source_task_id", "")),
		String(capture_manifest.get("source_runtime_text_task_id", "")),
		String(capture_manifest.get("source_recapture_task_id", "")),
		String(capture_manifest.get("source_prior_recapture_task_id", "")),
		String(capture_manifest.get("source_binding_task_id", "")),
		String(capture_manifest.get("source_primary_hud_task_id", "")),
		String(capture_manifest.get("source_readability_task_id", "")),
		String(capture_manifest.get("source_focus_task_id", "")),
		String(capture_manifest.get("source_visibility_task_id", "")),
		String(capture_manifest.get("source_exchange_task_id", "")),
		String(capture_manifest.get("source_capture_task_id", "")),
		expected_runtime_text_schema,
		expected_runtime_text_style_id,
		expected_source_binding_style_id,
		expected_primary_hud_style_id,
		expected_readability_style_id,
		expected_focus_style_id,
		expected_persistence_duration_msec,
		runtime_text_task_id,
		runtime_text_status,
		runtime_text_read_only,
		selected_contact_first,
		mission_contact_first,
		no_fire_before_contact,
		missing_checks
	)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_manual_acceptance"
	if status != "blocked" and manual_review_done:
		status = "manual_review_recorded"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_runtime_text_task_id": SOURCE_RUNTIME_TEXT_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_prior_recapture_task_id": SOURCE_PRIOR_RECAPTURE_TASK_ID,
		"source_binding_task_id": SOURCE_BINDING_TASK_ID,
		"source_primary_hud_task_id": SOURCE_PRIMARY_HUD_TASK_ID,
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
		"desktop_screenshot_written": bool(capture_manifest.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(capture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("desktop_screenshot_path", "")),
		"window_screenshot_full_path": String(capture_manifest.get("window_screenshot_full_path", "")),
		"desktop_screenshot_full_path": String(capture_manifest.get("desktop_screenshot_full_path", "")),
		"expected_runtime_text_schema": expected_runtime_text_schema,
		"expected_runtime_text_style_id": expected_runtime_text_style_id,
		"runtime_text_schema_ok": expected_runtime_text_schema == EXPECTED_RUNTIME_TEXT_SCHEMA,
		"runtime_text_style_id_ok": expected_runtime_text_style_id == EXPECTED_RUNTIME_TEXT_STYLE_ID,
		"runtime_text_task_id": runtime_text_task_id,
		"runtime_text_status": runtime_text_status,
		"runtime_text_read_only": runtime_text_read_only,
		"selected_fireteam_runtime_text_contact_fire_first": selected_contact_first,
		"mission_control_runtime_text_contact_fire_first": mission_contact_first,
		"primary_lines_contain_debug_no_fire_before_contact_fire": no_fire_before_contact,
		"expected_source_binding_style_id": expected_source_binding_style_id,
		"source_binding_style_id_ok": expected_source_binding_style_id == EXPECTED_SOURCE_BINDING_STYLE_ID,
		"expected_primary_hud_style_id": expected_primary_hud_style_id,
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
	source_runtime_text_task_id: String,
	source_recapture_task_id: String,
	source_prior_recapture_task_id: String,
	source_binding_task_id: String,
	source_primary_hud_task_id: String,
	source_readability_task_id: String,
	source_focus_task_id: String,
	source_visibility_task_id: String,
	source_exchange_task_id: String,
	source_capture_task_id: String,
	expected_runtime_text_schema: String,
	expected_runtime_text_style_id: String,
	expected_source_binding_style_id: String,
	expected_primary_hud_style_id: String,
	expected_readability_style_id: String,
	expected_focus_style_id: String,
	expected_persistence_duration_msec: int,
	runtime_text_task_id: String,
	runtime_text_status: String,
	runtime_text_read_only: bool,
	selected_contact_first: bool,
	mission_contact_first: bool,
	no_fire_before_contact: bool,
	missing_checks: Array
) -> Array:
	var blockers: Array = []
	if not review_ready:
		blockers.append(_issue("capture_not_review_ready", "Runtime-text recapture ist weder review_ready noch manual_open."))
	if not hard_failures.is_empty():
		blockers.append(_issue("capture_hard_failures", "Runtime-text recapture meldet Hard-Failures."))
	if not window_screenshot_written:
		blockers.append(_issue("window_screenshot_missing", "Fenster-Screenshot fehlt."))
	if source_task_id != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_865 als Status-Polish-Quelle."))
	if source_runtime_text_task_id != SOURCE_RUNTIME_TEXT_TASK_ID:
		blockers.append(_issue("source_runtime_text_mismatch", "Manifest nennt nicht TASK_862 als Runtime-Text-Quelle."))
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_mismatch", "Manifest nennt nicht TASK_863 als Recapture-Quelle."))
	if source_prior_recapture_task_id != SOURCE_PRIOR_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_prior_recapture_mismatch", "Manifest nennt nicht TASK_860 als vorherige Real-Window-Quelle."))
	if source_binding_task_id != SOURCE_BINDING_TASK_ID:
		blockers.append(_issue("source_binding_mismatch", "Manifest nennt nicht TASK_859 als Source-Binding-Quelle."))
	if source_primary_hud_task_id != SOURCE_PRIMARY_HUD_TASK_ID:
		blockers.append(_issue("source_primary_hud_mismatch", "Manifest nennt nicht TASK_856 als Primary-HUD-Quelle."))
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
	if expected_runtime_text_schema != EXPECTED_RUNTIME_TEXT_SCHEMA:
		blockers.append(_issue("runtime_text_schema_mismatch", "Manifest nennt nicht das erwartete TASK_862-Runtime-Text-Schema."))
	if expected_runtime_text_style_id != EXPECTED_RUNTIME_TEXT_STYLE_ID:
		blockers.append(_issue("runtime_text_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_862-Style-ID."))
	if expected_source_binding_style_id != EXPECTED_SOURCE_BINDING_STYLE_ID:
		blockers.append(_issue("source_binding_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_859-Style-ID."))
	if expected_primary_hud_style_id != EXPECTED_PRIMARY_HUD_STYLE_ID:
		blockers.append(_issue("primary_hud_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_856-Style-ID."))
	if expected_readability_style_id != EXPECTED_READABILITY_STYLE_ID:
		blockers.append(_issue("readability_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_853-Style-ID."))
	if expected_focus_style_id != EXPECTED_FOCUS_STYLE_ID:
		blockers.append(_issue("focus_style_id_mismatch", "Manifest nennt nicht die erwartete TASK_850-Style-ID."))
	if expected_persistence_duration_msec < MIN_CAPTURE_SAFE_DURATION_MSEC:
		blockers.append(_issue("persistence_window_too_short", "Fire-Exchange-Persistenz reicht nicht fuer den echten Fensterblick."))
	if runtime_text_task_id != "" and runtime_text_task_id != SOURCE_RUNTIME_TEXT_TASK_ID:
		blockers.append(_issue("runtime_text_task_mismatch", "Runtime-Text-Snapshot nennt nicht TASK_862."))
	if runtime_text_status != "" and runtime_text_status != "pass":
		blockers.append(_issue("runtime_text_snapshot_not_pass", "TASK_862-Runtime-Text-Snapshot ist nicht pass."))
	if not runtime_text_read_only:
		blockers.append(_issue("runtime_text_snapshot_not_read_only", "TASK_862-Runtime-Text-Snapshot ist nicht read-only."))
	if not selected_contact_first:
		blockers.append(_issue("selected_fireteam_runtime_text_not_contact_fire_first", "#17 Runtime-Text beginnt nicht mit CONTACT FIRE."))
	if not mission_contact_first:
		blockers.append(_issue("mission_control_runtime_text_not_contact_fire_first", "#18 Runtime-Text beginnt nicht mit CONTACT FIRE."))
	if no_fire_before_contact:
		blockers.append(_issue("debug_no_fire_before_contact_fire", "NO FIRE steht im Runtime-Text-Snapshot vor CONTACT FIRE."))
	if not missing_checks.is_empty():
		blockers.append(_issue("required_recapture_checks_missing", "TASK_866-Recapture-Pflichtchecks fehlen."))
	return blockers


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}

