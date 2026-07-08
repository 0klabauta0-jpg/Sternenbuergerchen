class_name ReleaseFirstExchangeFireDirectionImpactVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_direction_impact_visual_findings.v1"
const TASK_ID: String = "TASK_894"
const SOURCE_TASK_ID: String = "TASK_893"
const SOURCE_DIRECTION_TASK_ID: String = "TASK_892"
const SOURCE_HUD_DENSITY_TASK_ID: String = "TASK_889"
const SOURCE_HUD_DENSITY_RECAPTURE_TASK_ID: String = "TASK_890"
const SOURCE_RENDER_SYNC_TASK_ID: String = "TASK_887"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_direction_impact_real_window_recapture.v1"
const EXPECTED_DIRECTION_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_direction_impact_clarity_polish.v1"
const EXPECTED_DIRECTION_STYLE_ID: String = "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
const EXPECTED_HUD_DENSITY_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_fire_visual_polish.v1"
const EXPECTED_HUD_DENSITY_STYLE_ID: String = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_895 - Release First Exchange World Combat Focal Hierarchy Polish"


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(capture_manifest, review_notes)
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	var final_contact_fire: bool = bool(final_source.get("selected_starts_contact_fire", false)) \
		and bool(final_source.get("mission_starts_contact_fire", false)) \
		and bool(final_source.get("event_log_contains_contact_fire", false)) \
		and not bool(final_source.get("event_log_contains_contact_pressure", true))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", false))
	var positives: Array = _build_positive_findings(capture_manifest, review_notes, final_contact_fire)
	var issues: Array = _build_issues(review_notes)
	var accepted: bool = blockers.is_empty() and manual_review_done and bool(review_notes.get("player_readability_ok", false)) and issues.is_empty()
	var status: String = "blocked"
	if blockers.is_empty():
		if not manual_review_done:
			status = "needs_manual_review"
		elif accepted:
			status = "accepted_for_release_smoke"
		else:
			status = "ready_for_world_combat_focal_polish"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_direction_task_id": SOURCE_DIRECTION_TASK_ID,
		"source_hud_density_task_id": SOURCE_HUD_DENSITY_TASK_ID,
		"source_hud_density_recapture_task_id": SOURCE_HUD_DENSITY_RECAPTURE_TASK_ID,
		"source_render_sync_task_id": SOURCE_RENDER_SYNC_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_hud_sync_task_id": SOURCE_HUD_SYNC_TASK_ID,
		"source_fire_visual_task_id": SOURCE_FIRE_VISUAL_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"capture_schema": String(capture_manifest.get("schema", "")),
		"capture_task_id": String(capture_manifest.get("task_id", "")),
		"capture_gate": String(capture_manifest.get("gate", "")),
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"expected_direction_schema": String(capture_manifest.get("expected_direction_schema", "")),
		"expected_direction_style_id": String(capture_manifest.get("expected_direction_style_id", "")),
		"expected_hud_density_schema": String(capture_manifest.get("expected_hud_density_schema", "")),
		"expected_hud_density_style_id": String(capture_manifest.get("expected_hud_density_style_id", "")),
		"window_screenshot_path": String(capture_manifest.get("post_final_window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("post_final_desktop_screenshot_path", "")),
		"window_capture_method": String(capture_manifest.get("post_final_window_capture_method", "")),
		"window_capture_trusted": bool(capture_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_capture_after_deeplink_final": bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"manual_visual_review_done": manual_review_done,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", capture_manifest.get("post_final_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"world_fire_label_visible": bool(review_notes.get("world_fire_label_visible", false)),
		"impact_or_hit_marker_visible": bool(review_notes.get("impact_or_hit_marker_visible", false)),
		"target_focus_visible": bool(review_notes.get("target_focus_visible", false)),
		"source_to_target_relationship_obvious": bool(review_notes.get("source_to_target_relationship_obvious", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "polish_world_combat_focal_hierarchy_without_reopening_combat_truth",
		"avoid_next_action": "do_not_add_more_contact_fire_text_or_reopen_damage_logic",
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


static func _build_blockers(capture_manifest: Dictionary, review_notes: Dictionary) -> Array:
	var blockers: Array = []
	if String(capture_manifest.get("schema", "")) != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append(_issue("capture_schema_mismatch", "TASK_893-Manifest-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("capture_task_mismatch", "Manifest nennt nicht TASK_893."))
	if String(capture_manifest.get("source_task_id", "")) != SOURCE_DIRECTION_TASK_ID:
		blockers.append(_issue("source_direction_task_mismatch", "Manifest nennt nicht TASK_892 als Quelle."))
	if String(capture_manifest.get("source_hud_density_task_id", "")) != SOURCE_HUD_DENSITY_TASK_ID:
		blockers.append(_issue("source_hud_density_task_mismatch", "Manifest nennt nicht TASK_889 als HUD-Density-Quelle."))
	if String(capture_manifest.get("source_hud_density_recapture_task_id", "")) != SOURCE_HUD_DENSITY_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_hud_density_recapture_task_mismatch", "Manifest nennt nicht TASK_890 als Recapture-Quelle."))
	if String(capture_manifest.get("source_render_sync_task_id", "")) != SOURCE_RENDER_SYNC_TASK_ID:
		blockers.append(_issue("source_render_sync_task_mismatch", "Manifest nennt nicht TASK_887 als Render-Sync-Quelle."))
	if String(capture_manifest.get("source_trace_task_id", "")) != SOURCE_TRACE_TASK_ID:
		blockers.append(_issue("source_trace_task_mismatch", "Manifest nennt nicht TASK_879 als Trace-Quelle."))
	if String(capture_manifest.get("source_hud_sync_task_id", "")) != SOURCE_HUD_SYNC_TASK_ID:
		blockers.append(_issue("source_hud_sync_task_mismatch", "Manifest nennt nicht TASK_883 als HUD-Sync-Quelle."))
	if String(capture_manifest.get("source_fire_visual_task_id", "")) != SOURCE_FIRE_VISUAL_TASK_ID:
		blockers.append(_issue("source_fire_visual_task_mismatch", "Manifest nennt nicht TASK_880 als Fire-Visual-Quelle."))
	if String(capture_manifest.get("source_visible_status_task_id", "")) != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append(_issue("source_visible_status_task_mismatch", "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."))
	if String(capture_manifest.get("expected_direction_schema", "")) != EXPECTED_DIRECTION_SCHEMA:
		blockers.append(_issue("direction_schema_mismatch", "TASK_892-Direction-/Impact-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_direction_style_id", "")) != EXPECTED_DIRECTION_STYLE_ID:
		blockers.append(_issue("direction_style_mismatch", "TASK_892-Direction-/Impact-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_hud_density_schema", "")) != EXPECTED_HUD_DENSITY_SCHEMA:
		blockers.append(_issue("hud_density_schema_mismatch", "TASK_889-HUD-Density-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_hud_density_style_id", "")) != EXPECTED_HUD_DENSITY_STYLE_ID:
		blockers.append(_issue("hud_density_style_mismatch", "TASK_889-HUD-Density-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(capture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_893-Capture-Gate ist fail."))
	if not Array(capture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_893-Manifest enthaelt Hard-Failures."))
	if not bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture ist nicht an deeplink_final gebunden."))
	if String(capture_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if not bool(capture_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_893-Window-Screenshot fehlt."))
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	if not bool(review_notes.get("manual_visual_review_done", false)):
		blockers.append(_issue("manual_visual_review_missing", "TASK_894 braucht einen Sichtbefund zum TASK_893-PNG."))
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		blockers.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	return blockers


static func _build_positive_findings(capture_manifest: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		positives.append({"id": "capture_bound_to_deeplink_final", "text": "Der TASK_893-Capture haengt am finalen Runtime-Trace-Zeitpunkt."})
	if String(capture_manifest.get("post_final_window_capture_method", "")) == "window_handle_print" and bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der Screenshot kommt vom Ziel-Window-Handle."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log zeigt CONTACT FIRE als lesbaren ersten Feuerwechsel."})
	if bool(review_notes.get("world_fire_label_visible", false)):
		positives.append({"id": "world_fire_label_visible", "text": "Ein FIRE-Weltlabel ist im Kontaktbereich sichtbar."})
	if bool(review_notes.get("impact_or_hit_marker_visible", false)):
		positives.append({"id": "impact_or_hit_marker_visible", "text": "Impact-/Hit-Signal ist im Weltbild sichtbar."})
	if bool(review_notes.get("target_focus_visible", false)):
		positives.append({"id": "target_focus_visible", "text": "Target-Fokus ist im Weltbild sichtbar."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den Review."})
	return positives


static func _build_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "source_to_target_trace_not_obvious", true):
		issues.append({
			"id": "source_to_target_trace_not_obvious",
			"severity": "world_visual_hierarchy_polish",
			"text": "CONTACT FIRE und Impact sind sichtbar, aber die Linie Schuetze -> Ziel liest sich noch nicht sofort als eine zusammenhaengende Kampfaktion.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "world_grid_noise_competes_with_fire", true):
		issues.append({
			"id": "world_grid_noise_competes_with_fire",
			"severity": "world_visual_hierarchy_polish",
			"text": "Raster, Tiles und Stations-/Gebaeudekanten konkurrieren im Feuerbereich noch stark mit Trace, Impact und Target-Fokus.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "impact_target_focus_not_release_elegant", true):
		issues.append({
			"id": "impact_target_focus_not_release_elegant",
			"severity": "world_visual_hierarchy_polish",
			"text": "Impact und Target-Fokus sind vorhanden, wirken aber noch mehr wie Debug-/Signalformen als wie ein schicker Release-Kampfmoment.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "bottom_hud_member_cards_still_dense", true):
		issues.append({
			"id": "bottom_hud_member_cards_still_dense",
			"severity": "player_readability_polish",
			"text": "#17 ist funktional, aber Member-Cards und CONTACT-FIRE-Status konkurrieren weiterhin um Aufmerksamkeit.",
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
