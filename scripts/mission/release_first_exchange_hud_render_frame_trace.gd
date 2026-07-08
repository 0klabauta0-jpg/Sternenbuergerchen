class_name ReleaseFirstExchangeHudRenderFrameTrace
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_render_frame_trace.v1"
const TASK_ID: String = "TASK_886"
const SOURCE_TASK_ID: String = "TASK_885"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_884"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_source_sync_recapture.v1"
const EXPECTED_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const EXPECTED_RUNTIME_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix"


static func build_snapshot(trace_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(trace_manifest)
	var render_review: Dictionary = Dictionary(trace_manifest.get("render_frame_review", {}))
	var source_snapshot: Dictionary = Dictionary(trace_manifest.get("final_source_snapshot", {}))
	var rendered_state: String = String(render_review.get("screenshot_observed_state", "unknown"))
	var source_state: String = String(source_snapshot.get("source_observed_state", "unknown"))
	var source_contact_fire: bool = bool(source_snapshot.get("selected_starts_contact_fire", false)) and bool(source_snapshot.get("mission_starts_contact_fire", false)) and bool(source_snapshot.get("event_log_contains_contact_fire", false))
	var rendered_no_fire: bool = rendered_state.contains("NO_FIRE") or rendered_state.contains("NO_LOS") or rendered_state.contains("CONTACT_PRESSURE")
	var frame_differs: bool = source_contact_fire and rendered_no_fire
	var issues: Array = _build_issues(frame_differs, render_review, source_snapshot)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_render_sync_fix"
	if not blockers.is_empty():
		issues = []

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_hud_sync_task_id": SOURCE_HUD_SYNC_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_fire_visual_task_id": SOURCE_FIRE_VISUAL_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"trace_manifest_schema": String(trace_manifest.get("schema", "")),
		"trace_manifest_task_id": String(trace_manifest.get("task_id", "")),
		"trace_manifest_gate": String(trace_manifest.get("gate", "")),
		"source_recapture_schema": String(trace_manifest.get("source_recapture_schema", "")),
		"source_trace_schema": String(trace_manifest.get("source_trace_schema", "")),
		"source_runtime_trace_schema": String(trace_manifest.get("source_runtime_trace_schema", "")),
		"branch": String(trace_manifest.get("branch", "")),
		"git_head": String(trace_manifest.get("git_head", "")),
		"launch_argument": String(trace_manifest.get("launch_argument", "")),
		"wait_seconds": int(trace_manifest.get("wait_seconds", 0)),
		"window_capture_method": String(trace_manifest.get("window_capture_method", "")),
		"window_capture_trusted": bool(trace_manifest.get("window_capture_trusted", false)),
		"window_handle_capture_succeeded": bool(trace_manifest.get("window_handle_capture_succeeded", false)),
		"window_screenshot_path": String(trace_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(trace_manifest.get("desktop_screenshot_path", "")),
		"window_screenshot_written": bool(trace_manifest.get("window_screenshot_written", false)),
		"runtime_trace_written": bool(trace_manifest.get("runtime_trace_written", false)),
		"runtime_trace_sample_count": int(trace_manifest.get("runtime_trace_sample_count", 0)),
		"runtime_trace_latest_stage": String(source_snapshot.get("stage", "")),
		"runtime_trace_latest_timestamp_msec": int(source_snapshot.get("timestamp_msec", 0)),
		"render_frame_trace_method": String(render_review.get("frame_trace_method", "")),
		"rendered_texts_collected": bool(render_review.get("rendered_texts_collected", false)),
		"rendered_screenshot_observed_state": rendered_state,
		"final_source_observed_state": source_state,
		"source_selected_starts_contact_fire": bool(source_snapshot.get("selected_starts_contact_fire", false)),
		"source_mission_starts_contact_fire": bool(source_snapshot.get("mission_starts_contact_fire", false)),
		"source_event_log_contains_contact_fire": bool(source_snapshot.get("event_log_contains_contact_fire", false)),
		"source_event_log_contains_contact_pressure": bool(source_snapshot.get("event_log_contains_contact_pressure", true)),
		"rendered_selected_fireteam_text": String(render_review.get("rendered_selected_fireteam_text", "")),
		"rendered_mission_control_text": String(render_review.get("rendered_mission_control_text", "")),
		"rendered_event_log_text": String(render_review.get("rendered_event_log_text", "")),
		"source_selected_fireteam_status_text": String(source_snapshot.get("selected_fireteam_status_text", "")),
		"source_mission_control_status_text": String(source_snapshot.get("mission_control_status_text", "")),
		"source_event_log_short_text": String(source_snapshot.get("event_log_short_text", "")),
		"render_frame_differs_from_final_trace": frame_differs,
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "bind_capture_frame_to_final_hud_source_or_trace_late_surface_overwrite",
		"avoid_next_action": "do_not_add_more_contact_fire_text_before_render_frame_sync",
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


static func _build_blockers(trace_manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(trace_manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("trace_schema_mismatch", "TASK_886-Manifest-Schema fehlt oder passt nicht."))
	if String(trace_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("trace_task_mismatch", "Manifest nennt nicht TASK_886."))
	if String(trace_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_findings_mismatch", "Manifest nennt nicht TASK_885 als Findings-Quelle."))
	if String(trace_manifest.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_mismatch", "Manifest nennt nicht TASK_884 als Recapture-Quelle."))
	if String(trace_manifest.get("source_hud_sync_task_id", "")) != SOURCE_HUD_SYNC_TASK_ID:
		blockers.append(_issue("source_hud_sync_mismatch", "Manifest nennt nicht TASK_883 als HUD-Sync-Quelle."))
	if String(trace_manifest.get("source_trace_task_id", "")) != SOURCE_TRACE_TASK_ID:
		blockers.append(_issue("source_trace_mismatch", "Manifest nennt nicht TASK_879 als Trace-Quelle."))
	if String(trace_manifest.get("source_fire_visual_task_id", "")) != SOURCE_FIRE_VISUAL_TASK_ID:
		blockers.append(_issue("source_fire_visual_mismatch", "Manifest nennt nicht TASK_880 als Fire-Visual-Quelle."))
	if String(trace_manifest.get("source_visible_status_task_id", "")) != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append(_issue("source_visible_status_mismatch", "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."))
	if String(trace_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(trace_manifest.get("source_recapture_schema", "")) != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_884-Recapture-Schema fehlt oder passt nicht."))
	if String(trace_manifest.get("source_trace_schema", "")) != EXPECTED_TRACE_SCHEMA:
		blockers.append(_issue("source_trace_schema_mismatch", "TASK_879-Trace-Schema fehlt oder passt nicht."))
	if String(trace_manifest.get("source_runtime_trace_schema", "")) != EXPECTED_RUNTIME_TRACE_SCHEMA:
		blockers.append(_issue("source_runtime_trace_schema_mismatch", "TASK_879-Runtime-Trace-Schema fehlt oder passt nicht."))
	if String(trace_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_886-Capture-Gate ist fail."))
	if not Array(trace_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_886-Manifest enthaelt Hard-Failures."))
	if not bool(trace_manifest.get("window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "Fenster-Screenshot fehlt."))
	if String(trace_manifest.get("window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht den Window-Handle-Pfad."))
	if not bool(trace_manifest.get("window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Handle-Capture ist nicht trusted."))
	if not bool(trace_manifest.get("runtime_trace_written", false)):
		blockers.append(_issue("runtime_trace_missing", "Runtime-Trace fehlt."))
	var render_review: Dictionary = Dictionary(trace_manifest.get("render_frame_review", {}))
	if not bool(render_review.get("rendered_texts_collected", false)):
		blockers.append(_issue("rendered_texts_missing", "Gerenderte #17/#18/#19-Texte fehlen."))
	var source_snapshot: Dictionary = Dictionary(trace_manifest.get("final_source_snapshot", {}))
	if String(source_snapshot.get("stage", "")) == "":
		blockers.append(_issue("final_source_snapshot_missing", "Finaler Source-Snapshot fehlt."))
	return blockers


static func _build_issues(frame_differs: bool, render_review: Dictionary, source_snapshot: Dictionary) -> Array:
	var issues: Array = []
	if frame_differs:
		issues.append({
			"id": "render_frame_differs_from_final_trace",
			"severity": "release_readability_blocker",
			"text": "Der echte Screenshot liest NO_FIRE/NO_LOS/CONTACT_PRESSURE, waehrend der finale Source-Snapshot CONTACT FIRE in #17/#18/#19 meldet.",
			"recommended_task": NEXT_TASK,
		})
	if bool(render_review.get("capture_frame_not_bound_to_final_source", false)):
		issues.append({
			"id": "capture_frame_not_bound_to_final_source",
			"severity": "evidence_mismatch",
			"text": "Der Capture-Frame ist nicht als derselbe Zustand belegbar wie der finale CONTACT-FIRE-Source-Snapshot.",
			"recommended_task": NEXT_TASK,
		})
	if String(render_review.get("rendered_selected_fireteam_text", "")).contains("NO FIRE"):
		issues.append({
			"id": "rendered_selected_fireteam_still_no_fire",
			"severity": "player_feedback_confusing",
			"text": "#17 liest im Screenshot weiter NO FIRE / NO_LOS.",
			"recommended_task": NEXT_TASK,
		})
	if String(render_review.get("rendered_event_log_text", "")).contains("CONTACT PRESSURE"):
		issues.append({
			"id": "rendered_event_log_still_contact_pressure",
			"severity": "player_feedback_confusing",
			"text": "#19 liest im Screenshot weiter CONTACT PRESSURE.",
			"recommended_task": NEXT_TASK,
		})
	if not bool(source_snapshot.get("event_log_contains_contact_pressure", true)) and String(render_review.get("rendered_event_log_text", "")).contains("CONTACT PRESSURE"):
		issues.append({
			"id": "event_log_render_differs_from_source",
			"severity": "surface_source_mismatch",
			"text": "Der finale Source-Snapshot enthaelt kein CONTACT PRESSURE, das gerenderte Event-Log aber schon.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
