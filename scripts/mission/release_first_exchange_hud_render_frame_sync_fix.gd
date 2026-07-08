class_name ReleaseFirstExchangeHudRenderFrameSyncFix
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_render_frame_sync_fix.v1"
const TASK_ID: String = "TASK_887"
const SOURCE_TASK_ID: String = "TASK_886"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const EXPECTED_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const EXPECTED_RUNTIME_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_888 - Release First Exchange Player Readability Polish Review"


static func build_snapshot(sync_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(sync_manifest)
	var final_source: Dictionary = Dictionary(sync_manifest.get("final_source_snapshot", {}))
	var post_final_review: Dictionary = Dictionary(sync_manifest.get("post_final_render_frame_review", {}))
	var source_contact_fire: bool = bool(final_source.get("selected_starts_contact_fire", false)) \
		and bool(final_source.get("mission_starts_contact_fire", false)) \
		and bool(final_source.get("event_log_contains_contact_fire", false)) \
		and not bool(final_source.get("event_log_contains_contact_pressure", true))
	var rendered_contact_fire: bool = bool(post_final_review.get("selected_fireteam_contact_fire_first", false)) \
		and bool(post_final_review.get("mission_control_contact_fire_first", false)) \
		and bool(post_final_review.get("event_log_contact_fire_first", false)) \
		and not bool(post_final_review.get("rendered_no_fire_or_contact_pressure_first", true))
	var synced: bool = blockers.is_empty() and source_contact_fire and rendered_contact_fire \
		and bool(sync_manifest.get("post_final_capture_after_deeplink_final", false))
	var issues: Array = _build_issues(source_contact_fire, rendered_contact_fire, sync_manifest, final_source, post_final_review)
	if not blockers.is_empty():
		issues = []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_hud_sync_task_id": SOURCE_HUD_SYNC_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"manifest_schema": String(sync_manifest.get("schema", "")),
		"manifest_task_id": String(sync_manifest.get("task_id", "")),
		"gate": String(sync_manifest.get("gate", "")),
		"branch": String(sync_manifest.get("branch", "")),
		"git_head": String(sync_manifest.get("git_head", "")),
		"launch_argument": String(sync_manifest.get("launch_argument", "")),
		"trace_manifest_schema": String(sync_manifest.get("source_trace_schema", "")),
		"runtime_trace_schema": String(sync_manifest.get("source_runtime_trace_schema", "")),
		"runtime_trace_sample_count": int(sync_manifest.get("runtime_trace_sample_count", 0)),
		"runtime_trace_latest_stage": String(final_source.get("stage", "")),
		"runtime_trace_latest_timestamp_msec": int(final_source.get("timestamp_msec", 0)),
		"selected_process_id": int(sync_manifest.get("selected_process_id", 0)),
		"post_final_capture_process_id": int(sync_manifest.get("post_final_capture_process_id", 0)),
		"post_final_capture_after_deeplink_final": bool(sync_manifest.get("post_final_capture_after_deeplink_final", false)),
		"post_final_capture_method": String(sync_manifest.get("post_final_window_capture_method", "")),
		"post_final_window_capture_trusted": bool(sync_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_window_screenshot_path": String(sync_manifest.get("post_final_window_screenshot_path", "")),
		"post_final_desktop_screenshot_path": String(sync_manifest.get("post_final_desktop_screenshot_path", "")),
		"final_source_contact_fire": source_contact_fire,
		"post_final_render_contact_fire": rendered_contact_fire,
		"render_frame_synced_to_final_trace": synced,
		"final_source_snapshot": final_source,
		"post_final_render_frame_review": post_final_review,
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": "pass" if synced else ("blocked" if not blockers.is_empty() else "review"),
		"recommended_next_task": NEXT_TASK if synced else "TASK_887 - rerun post-final render-frame sync capture",
		"recommended_direction": "review_player_readability_density_and_visual_polish" if synced else "rerun_post_final_capture_or_fix_late_surface_overwrite",
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


static func _build_blockers(sync_manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(sync_manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "TASK_887-Manifest-Schema fehlt oder passt nicht."))
	if String(sync_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_887."))
	if String(sync_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_886 als Quelle."))
	if String(sync_manifest.get("source_trace_task_id", "")) != SOURCE_TRACE_TASK_ID:
		blockers.append(_issue("source_trace_task_mismatch", "Manifest nennt nicht TASK_879 als Trace-Quelle."))
	if String(sync_manifest.get("source_hud_sync_task_id", "")) != SOURCE_HUD_SYNC_TASK_ID:
		blockers.append(_issue("source_hud_sync_task_mismatch", "Manifest nennt nicht TASK_883 als HUD-Sync-Quelle."))
	if String(sync_manifest.get("source_visible_status_task_id", "")) != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append(_issue("source_visible_status_task_mismatch", "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."))
	if String(sync_manifest.get("source_trace_schema", "")) != EXPECTED_TRACE_SCHEMA:
		blockers.append(_issue("source_trace_schema_mismatch", "TASK_879-Trace-Schema fehlt oder passt nicht."))
	if String(sync_manifest.get("source_runtime_trace_schema", "")) != EXPECTED_RUNTIME_TRACE_SCHEMA:
		blockers.append(_issue("runtime_trace_schema_mismatch", "TASK_879-Runtime-Trace-Schema fehlt oder passt nicht."))
	if String(sync_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(sync_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_887-Capture-Gate ist fail."))
	if not Array(sync_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_887-Manifest enthaelt Hard-Failures."))
	if not bool(sync_manifest.get("runtime_trace_written", false)):
		blockers.append(_issue("runtime_trace_missing", "Runtime-Trace fehlt."))
	if String(Dictionary(sync_manifest.get("final_source_snapshot", {})).get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	if not bool(sync_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture wurde nicht nach deeplink_final markiert."))
	if int(sync_manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(sync_manifest.get("post_final_capture_process_id", 0)) != int(sync_manifest.get("selected_process_id", 0)):
		blockers.append(_issue("post_final_process_mismatch", "Post-Final-Capture nutzt nicht denselben Release-Prozess."))
	if String(sync_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("post_final_capture_method_not_handle_print", "Post-Final-Capture nutzt nicht Window-Handle-Print."))
	if not bool(sync_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("post_final_window_capture_not_trusted", "Post-Final-Window-Capture ist nicht trusted."))
	if not bool(sync_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("post_final_window_screenshot_missing", "Post-Final-Window-Screenshot fehlt."))
	return blockers


static func _build_issues(source_contact_fire: bool, rendered_contact_fire: bool, sync_manifest: Dictionary, final_source: Dictionary, post_final_review: Dictionary) -> Array:
	var issues: Array = []
	if not source_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not rendered_contact_fire:
		issues.append(_issue("post_final_render_not_contact_fire", "Post-Final-Fensterframe liest nicht sauber CONTACT FIRE in #17/#18/#19."))
	if bool(post_final_review.get("rendered_no_fire_or_contact_pressure_first", true)):
		issues.append(_issue("post_final_render_still_stale_first_reading", "Post-Final-Readback meldet weiter NO_FIRE oder CONTACT_PRESSURE als Erstlesung."))
	if bool(final_source.get("event_log_contains_contact_pressure", true)):
		issues.append(_issue("final_source_still_contact_pressure", "Finaler Source-Snapshot enthaelt weiter CONTACT PRESSURE."))
	if not bool(sync_manifest.get("post_final_capture_after_deeplink_final", false)):
		issues.append(_issue("capture_order_not_synced", "Capture-Reihenfolge ist nicht an deeplink_final gebunden."))
	return issues


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
