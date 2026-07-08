class_name ReleaseFirstExchangeHudDensityRealWindowRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_real_window_recapture.v1"
const TASK_ID: String = "TASK_890"
const SOURCE_TASK_ID: String = "TASK_889"
const SOURCE_RENDER_SYNC_TASK_ID: String = "TASK_887"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const EXPECTED_HUD_DENSITY_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_fire_visual_polish.v1"
const EXPECTED_HUD_DENSITY_STYLE_ID: String = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const EXPECTED_RENDER_SYNC_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_render_frame_sync_fix.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_891 - Release First Exchange HUD Density Visual Findings"


static func build_snapshot(recapture_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(recapture_manifest)
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var completed_checks: Array = Array(recapture_manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var final_source: Dictionary = Dictionary(recapture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(recapture_manifest.get("post_final_hud_density_render_review", {}))
	var final_contact_fire: bool = bool(final_source.get("selected_starts_contact_fire", false)) \
		and bool(final_source.get("mission_starts_contact_fire", false)) \
		and bool(final_source.get("event_log_contains_contact_fire", false)) \
		and not bool(final_source.get("event_log_contains_contact_pressure", true))
	var manual_review_done: bool = bool(recapture_manifest.get("manual_review_done", false))
	var review_ready: bool = blockers.is_empty() \
		and String(recapture_manifest.get("gate", "")) in ["review_ready", "accepted", "review"] \
		and final_contact_fire
	var accepted: bool = review_ready and manual_review_done and missing_checks.is_empty()
	var issues: Array = _build_issues(recapture_manifest, final_contact_fire, missing_checks, manual_review_done)
	if not blockers.is_empty():
		issues = []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_render_sync_task_id": SOURCE_RENDER_SYNC_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_hud_sync_task_id": SOURCE_HUD_SYNC_TASK_ID,
		"source_fire_visual_task_id": SOURCE_FIRE_VISUAL_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"manifest_schema": String(recapture_manifest.get("schema", "")),
		"manifest_task_id": String(recapture_manifest.get("task_id", "")),
		"gate": String(recapture_manifest.get("gate", "")),
		"branch": String(recapture_manifest.get("branch", "")),
		"git_head": String(recapture_manifest.get("git_head", "")),
		"launch_argument": String(recapture_manifest.get("launch_argument", "")),
		"expected_hud_density_schema": String(recapture_manifest.get("expected_hud_density_schema", "")),
		"expected_hud_density_style_id": String(recapture_manifest.get("expected_hud_density_style_id", "")),
		"source_render_sync_schema": String(recapture_manifest.get("source_render_sync_schema", "")),
		"source_render_sync_gate": String(recapture_manifest.get("source_render_sync_gate", "")),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"post_final_capture_process_id": int(recapture_manifest.get("post_final_capture_process_id", 0)),
		"post_final_capture_after_deeplink_final": bool(recapture_manifest.get("post_final_capture_after_deeplink_final", false)),
		"post_final_capture_method": String(recapture_manifest.get("post_final_window_capture_method", "")),
		"post_final_window_capture_trusted": bool(recapture_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_window_screenshot_path": String(recapture_manifest.get("post_final_window_screenshot_path", "")),
		"post_final_desktop_screenshot_path": String(recapture_manifest.get("post_final_desktop_screenshot_path", "")),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_final_hud_density_render_review": render_review,
		"manual_review_required": bool(recapture_manifest.get("manual_review_required", true)),
		"manual_review_done": manual_review_done,
		"required_checks": required_checks,
		"completed_manual_checks": completed_checks,
		"missing_manual_checks": missing_checks,
		"missing_manual_check_count": missing_checks.size(),
		"review_ready": review_ready,
		"accepted": accepted,
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": "blocked" if not blockers.is_empty() else ("accepted" if accepted else ("review_ready" if review_ready else "review")),
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "cut_visual_findings_from_real_window_density_recapture",
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


static func _build_blockers(recapture_manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(recapture_manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "TASK_890-Manifest-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_890."))
	if String(recapture_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_889 als Quelle."))
	if String(recapture_manifest.get("source_render_sync_task_id", "")) != SOURCE_RENDER_SYNC_TASK_ID:
		blockers.append(_issue("source_render_sync_task_mismatch", "Manifest nennt nicht TASK_887 als Render-Sync-Quelle."))
	if String(recapture_manifest.get("source_trace_task_id", "")) != SOURCE_TRACE_TASK_ID:
		blockers.append(_issue("source_trace_task_mismatch", "Manifest nennt nicht TASK_879 als Trace-Quelle."))
	if String(recapture_manifest.get("source_hud_sync_task_id", "")) != SOURCE_HUD_SYNC_TASK_ID:
		blockers.append(_issue("source_hud_sync_task_mismatch", "Manifest nennt nicht TASK_883 als HUD-Sync-Quelle."))
	if String(recapture_manifest.get("source_fire_visual_task_id", "")) != SOURCE_FIRE_VISUAL_TASK_ID:
		blockers.append(_issue("source_fire_visual_task_mismatch", "Manifest nennt nicht TASK_880 als Fire-Visual-Quelle."))
	if String(recapture_manifest.get("source_visible_status_task_id", "")) != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append(_issue("source_visible_status_task_mismatch", "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."))
	if String(recapture_manifest.get("expected_hud_density_schema", "")) != EXPECTED_HUD_DENSITY_SCHEMA:
		blockers.append(_issue("hud_density_schema_mismatch", "TASK_889-HUD-Density-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_hud_density_style_id", "")) != EXPECTED_HUD_DENSITY_STYLE_ID:
		blockers.append(_issue("hud_density_style_mismatch", "TASK_889-HUD-Density-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("source_render_sync_schema", "")) != EXPECTED_RENDER_SYNC_SCHEMA:
		blockers.append(_issue("source_render_sync_schema_mismatch", "TASK_887-Render-Sync-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(recapture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_890-Capture-Gate ist fail."))
	if not Array(recapture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_890-Manifest enthaelt Hard-Failures."))
	if not bool(recapture_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture wurde nicht nach deeplink_final markiert."))
	if int(recapture_manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(recapture_manifest.get("post_final_capture_process_id", 0)) != int(recapture_manifest.get("selected_process_id", 0)):
		blockers.append(_issue("post_final_process_mismatch", "Post-Final-Capture nutzt nicht denselben Release-Prozess."))
	if String(recapture_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("post_final_capture_method_not_handle_print", "Post-Final-Capture nutzt nicht Window-Handle-Print."))
	if not bool(recapture_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("post_final_window_capture_not_trusted", "Post-Final-Window-Capture ist nicht trusted."))
	if not bool(recapture_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("post_final_window_screenshot_missing", "Post-Final-Window-Screenshot fehlt."))
	return blockers


static func _build_issues(recapture_manifest: Dictionary, final_contact_fire: bool, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_density_review_open", "Der echte TASK_890-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_density_checks_missing", "Nicht alle TASK_890-Pflichtchecks sind als erledigt markiert."))
	if not bool(recapture_manifest.get("post_final_window_screenshot_written", false)):
		issues.append(_issue("window_screenshot_missing", "Der TASK_890-Window-Screenshot fehlt."))
	return issues


static func _missing_checks(required_checks: Array, completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_variant in required_checks:
		var check_id: String = String(check_variant)
		if not completed.has(check_id):
			missing.append(check_id)
	return missing


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
