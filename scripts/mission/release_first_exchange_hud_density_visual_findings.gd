class_name ReleaseFirstExchangeHudDensityVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_visual_findings.v1"
const TASK_ID: String = "TASK_891"
const SOURCE_TASK_ID: String = "TASK_890"
const SOURCE_HUD_DENSITY_TASK_ID: String = "TASK_889"
const SOURCE_RENDER_SYNC_TASK_ID: String = "TASK_887"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_real_window_recapture.v1"
const EXPECTED_HUD_DENSITY_SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_fire_visual_polish.v1"
const EXPECTED_HUD_DENSITY_STYLE_ID: String = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_892 - Release First Exchange Fire Direction And Impact Clarity Polish"


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
			status = "ready_for_fire_direction_polish"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_hud_density_task_id": SOURCE_HUD_DENSITY_TASK_ID,
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
		"event_log_density_improved": bool(review_notes.get("event_log_density_improved", false)),
		"world_fire_label_visible": bool(review_notes.get("world_fire_label_visible", false)),
		"impact_or_hit_marker_visible": bool(review_notes.get("impact_or_hit_marker_visible", false)),
		"target_focus_visible": bool(review_notes.get("target_focus_visible", false)),
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
		"recommended_direction": "polish_fire_direction_impact_and_target_focus_without_reopening_combat_truth",
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
		blockers.append(_issue("capture_schema_mismatch", "TASK_890-Manifest-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("capture_task_mismatch", "Manifest nennt nicht TASK_890."))
	if String(capture_manifest.get("source_task_id", "")) != SOURCE_HUD_DENSITY_TASK_ID:
		blockers.append(_issue("source_hud_density_task_mismatch", "Manifest nennt nicht TASK_889 als Quelle."))
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
	if String(capture_manifest.get("expected_hud_density_schema", "")) != EXPECTED_HUD_DENSITY_SCHEMA:
		blockers.append(_issue("hud_density_schema_mismatch", "TASK_889-HUD-Density-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_hud_density_style_id", "")) != EXPECTED_HUD_DENSITY_STYLE_ID:
		blockers.append(_issue("hud_density_style_mismatch", "TASK_889-HUD-Density-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(capture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_890-Capture-Gate ist fail."))
	if not Array(capture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_890-Manifest enthaelt Hard-Failures."))
	if not bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture ist nicht an deeplink_final gebunden."))
	if String(capture_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if not bool(capture_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_890-Window-Screenshot fehlt."))
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	if not bool(review_notes.get("manual_visual_review_done", false)):
		blockers.append(_issue("manual_visual_review_missing", "TASK_891 braucht einen Sichtbefund zum TASK_890-PNG."))
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		blockers.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	return blockers


static func _build_positive_findings(capture_manifest: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		positives.append({"id": "capture_bound_to_deeplink_final", "text": "Der TASK_890-Capture haengt am finalen Runtime-Trace-Zeitpunkt."})
	if String(capture_manifest.get("post_final_window_capture_method", "")) == "window_handle_print" and bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der Screenshot kommt vom Ziel-Window-Handle."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_density_improved", false)):
		positives.append({"id": "event_log_density_improved", "text": "#19 Event Log ist groesser und blockiert den ersten Blick weniger stark als vor TASK_889."})
	if bool(review_notes.get("world_fire_label_visible", false)):
		positives.append({"id": "world_fire_label_visible", "text": "Ein FIRE-Weltlabel ist im Kontaktbereich sichtbar."})
	if bool(review_notes.get("impact_or_hit_marker_visible", false)):
		positives.append({"id": "impact_or_hit_marker_visible", "text": "Impact-/Hit-Signal ist im Weltbild sichtbar."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den Review."})
	return positives


static func _build_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "fire_direction_and_impact_relationship_not_obvious", true):
		issues.append({
			"id": "fire_direction_and_impact_relationship_not_obvious",
			"severity": "visual_hierarchy_polish",
			"text": "FIRE/Impact ist sichtbar, aber Schussrichtung, Ziel und Trefferbezug lesen sich noch nicht sofort als eine klare Aktion.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "target_focus_not_strong_enough", true):
		issues.append({
			"id": "target_focus_not_strong_enough",
			"severity": "visual_hierarchy_polish",
			"text": "Der Zielbezug ist vorhanden, aber noch nicht stark genug, um den Blick sicher vom HUD in die Welt zu fuehren.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "bottom_hud_member_cards_still_dense", true):
		issues.append({
			"id": "bottom_hud_member_cards_still_dense",
			"severity": "player_readability_polish",
			"text": "#17 ist funktional, aber Member-Cards und CONTACT-FIRE-Status konkurrieren weiterhin um Aufmerksamkeit.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_overlay_still_competes_with_map", false):
		issues.append({
			"id": "event_log_overlay_still_competes_with_map",
			"severity": "player_readability_polish",
			"text": "#19 ist verbessert, liegt aber noch als dunkles Kartenoverlay ueber dem Weltblick.",
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
