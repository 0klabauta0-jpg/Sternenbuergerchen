class_name ReleaseFirstExchangePlayerReadabilityPolishReview
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_player_readability_polish_review.v1"
const TASK_ID: String = "TASK_888"
const SOURCE_TASK_ID: String = "TASK_887"
const SOURCE_RENDER_TRACE_TASK_ID: String = "TASK_886"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_render_frame_sync_fix.v1"
const EXPECTED_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const EXPECTED_RUNTIME_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_889 - Release First Exchange HUD Density And Fire Visual Polish"


static func build_snapshot(sync_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(sync_manifest)
	var final_source: Dictionary = Dictionary(sync_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(sync_manifest.get("post_final_render_frame_review", {}))
	var source_contact_fire: bool = bool(final_source.get("selected_starts_contact_fire", false)) \
		and bool(final_source.get("mission_starts_contact_fire", false)) \
		and bool(final_source.get("event_log_contains_contact_fire", false)) \
		and not bool(final_source.get("event_log_contains_contact_pressure", true))
	var rendered_contact_fire: bool = bool(render_review.get("selected_fireteam_contact_fire_first", false)) \
		and bool(render_review.get("mission_control_contact_fire_first", false)) \
		and bool(render_review.get("event_log_contact_fire_first", false)) \
		and not bool(render_review.get("rendered_no_fire_or_contact_pressure_first", true))
	var technical_frame_ok: bool = blockers.is_empty() and source_contact_fire and rendered_contact_fire \
		and bool(sync_manifest.get("post_final_capture_after_deeplink_final", false))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", false))
	var issues: Array = _build_readability_issues(review_notes)
	var positives: Array = _build_positive_findings(sync_manifest, review_notes, source_contact_fire, rendered_contact_fire)
	var player_readability_ok: bool = technical_frame_ok and manual_review_done and issues.is_empty() \
		and bool(review_notes.get("player_readability_ok", false))
	var status: String = "blocked"
	if blockers.is_empty():
		if not manual_review_done:
			status = "needs_manual_review"
		elif player_readability_ok:
			status = "accepted_for_next_release_smoke"
		else:
			status = "ready_for_visual_polish"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_render_trace_task_id": SOURCE_RENDER_TRACE_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_hud_sync_task_id": SOURCE_HUD_SYNC_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"source_schema": String(sync_manifest.get("schema", "")),
		"source_manifest_task_id": String(sync_manifest.get("task_id", "")),
		"source_gate": String(sync_manifest.get("gate", "")),
		"source_branch": String(sync_manifest.get("branch", "")),
		"source_git_head": String(sync_manifest.get("git_head", "")),
		"launch_argument": String(sync_manifest.get("launch_argument", "")),
		"trace_manifest_schema": String(sync_manifest.get("source_trace_schema", "")),
		"runtime_trace_schema": String(sync_manifest.get("source_runtime_trace_schema", "")),
		"runtime_trace_sample_count": int(sync_manifest.get("runtime_trace_sample_count", 0)),
		"runtime_trace_latest_stage": String(final_source.get("stage", "")),
		"post_final_capture_after_deeplink_final": bool(sync_manifest.get("post_final_capture_after_deeplink_final", false)),
		"post_final_capture_method": String(sync_manifest.get("post_final_window_capture_method", "")),
		"post_final_window_capture_trusted": bool(sync_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_window_screenshot_path": String(sync_manifest.get("post_final_window_screenshot_path", "")),
		"post_final_desktop_screenshot_path": String(sync_manifest.get("post_final_desktop_screenshot_path", "")),
		"final_source_contact_fire": source_contact_fire,
		"post_final_render_contact_fire": rendered_contact_fire,
		"technical_contact_fire_frame_ok": technical_frame_ok,
		"manual_visual_review_done": manual_review_done,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", sync_manifest.get("post_final_window_screenshot_path", ""))),
		"player_readability_ok": player_readability_ok,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", rendered_contact_fire)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"world_fire_contact_labels_present": bool(review_notes.get("world_fire_contact_labels_present", false)),
		"fire_trace_or_impact_visible": bool(review_notes.get("fire_trace_or_impact_visible", false)),
		"target_focus_visible": bool(review_notes.get("target_focus_visible", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"readability_goal": "first_exchange_contact_fire_is_true_and_comfortable_to_read_without_reopening_combat_truth",
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK if technical_frame_ok else "TASK_887 - rerun post-final render-frame sync fix",
		"recommended_direction": "polish_hud_density_event_log_and_fire_visual_hierarchy" if technical_frame_ok else "restore_contact_fire_frame_sync_before_visual_polish",
		"avoid_next_action": "do_not_reopen_combat_truth_or_add_new_hud_state",
		"read_only": true,
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
	if String(sync_manifest.get("schema", "")) != EXPECTED_SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_887-Manifest-Schema fehlt oder passt nicht."))
	if String(sync_manifest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_887."))
	if String(sync_manifest.get("source_task_id", "")) != SOURCE_RENDER_TRACE_TASK_ID:
		blockers.append(_issue("source_render_trace_task_mismatch", "Manifest nennt nicht TASK_886 als Render-Trace-Quelle."))
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
		blockers.append(_issue("source_gate_failed", "TASK_887-Capture-Gate ist fail."))
	if not Array(sync_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_887-Manifest enthaelt Hard-Failures."))
	if not bool(sync_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture ist nicht an deeplink_final gebunden."))
	if String(sync_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("post_final_capture_method_not_handle_print", "Post-Final-Capture nutzt nicht Window-Handle-Print."))
	if not bool(sync_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("post_final_window_capture_not_trusted", "Post-Final-Window-Capture ist nicht trusted."))
	if not bool(sync_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("post_final_window_screenshot_missing", "Post-Final-Window-Screenshot fehlt."))
	var final_source: Dictionary = Dictionary(sync_manifest.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	var render_review: Dictionary = Dictionary(sync_manifest.get("post_final_render_frame_review", {}))
	if not bool(render_review.get("rendered_texts_collected", false)):
		blockers.append(_issue("post_final_render_texts_missing", "Post-Final-Readback-Texte fehlen."))
	return blockers


static func _build_positive_findings(sync_manifest: Dictionary, review_notes: Dictionary, source_contact_fire: bool, rendered_contact_fire: bool) -> Array:
	var positives: Array = []
	if source_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if rendered_contact_fire:
		positives.append({"id": "post_final_window_contact_fire_visible", "text": "Der Post-Final-Fensterframe liest CONTACT FIRE in #17/#18/#19."})
	if bool(sync_manifest.get("post_final_capture_after_deeplink_final", false)):
		positives.append({"id": "capture_bound_to_deeplink_final", "text": "Der Fenster-Capture ist an den finalen Runtime-Trace-Zeitpunkt gebunden."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log zeigt den Feuerwechsel an."})
	if bool(review_notes.get("world_fire_contact_labels_present", false)):
		positives.append({"id": "world_fire_contact_labels_present", "text": "Weltlabels fuer FIRE/CONTACT sind im Kontaktbereich vorhanden."})
	if bool(review_notes.get("fire_trace_or_impact_visible", false)):
		positives.append({"id": "fire_trace_or_impact_visible", "text": "FireTrace oder Impact ist im Fenster sichtbar."})
	if bool(review_notes.get("target_focus_visible", false)):
		positives.append({"id": "target_focus_visible", "text": "Der Zielbezug ist im Kampfbereich erkennbar."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den Review."})
	return positives


static func _build_readability_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "bottom_hud_density_high", false):
		issues.append({
			"id": "bottom_hud_density_high",
			"severity": "player_readability_polish",
			"text": "Bottom-HUD, Statuszeilen und Member-Cards konkurrieren im ersten Feuerwechsel zu stark um Aufmerksamkeit.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "mission_control_text_clipped", false):
		issues.append({
			"id": "mission_control_text_clipped",
			"severity": "player_readability_polish",
			"text": "#18 Mission Control zeigt CONTACT-FIRE-Zeilen, aber Text laeuft dicht und teils abgeschnitten in den Rand.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_overlay_too_small", false):
		issues.append({
			"id": "event_log_overlay_too_small",
			"severity": "player_readability_polish",
			"text": "#19 Event Log ist sichtbar, aber als Kartenoverlay zu klein/transparent fuer die erste Spielerlesung.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "world_fire_trace_too_subtle", false):
		issues.append({
			"id": "world_fire_trace_too_subtle",
			"severity": "visual_hierarchy_polish",
			"text": "FireTrace, Impact und FIRE/CONTACT-Weltlabels sind vorhanden, gehen aber im Kartenbild noch zu leicht unter.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "selected_fireteam_member_cards_crowd_status", false):
		issues.append({
			"id": "selected_fireteam_member_cards_crowd_status",
			"severity": "player_readability_polish",
			"text": "#17 Member-Cards nehmen viel visuelle Prioritaet, waehrend der eigentliche CONTACT-FIRE-Status klein bleibt.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "next_grip_competes_with_combat_text", false):
		issues.append({
			"id": "next_grip_competes_with_combat_text",
			"severity": "decision_clarity_polish",
			"text": "Der naechste Griff ist vorhanden, konkurriert aber mit mehreren CONTACT-FIRE-/Kampfzeilen.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	return bool(review_notes.get(key, default_value))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
