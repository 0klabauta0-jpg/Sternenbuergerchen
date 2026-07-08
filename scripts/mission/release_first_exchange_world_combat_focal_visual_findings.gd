class_name ReleaseFirstExchangeWorldCombatFocalVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_world_combat_focal_visual_findings.v1"
const TASK_ID: String = "TASK_897"
const SOURCE_TASK_ID: String = "TASK_896"
const SOURCE_FOCAL_TASK_ID: String = "TASK_895"
const SOURCE_DIRECTION_TASK_ID: String = "TASK_892"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_894"
const SOURCE_DIRECTION_RECAPTURE_TASK_ID: String = "TASK_893"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_world_combat_focal_real_window_recapture.v1"
const EXPECTED_FOCAL_SCHEMA: String = "sternenbuergerchen.release_first_exchange_world_combat_focal_hierarchy_polish.v1"
const EXPECTED_FOCAL_STYLE_ID: String = "task_895_release_first_exchange_world_combat_focal_hierarchy_v1"
const EXPECTED_DIRECTION_STYLE_ID: String = "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
const EXPECTED_DIRECTION_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_direction_impact_real_window_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_898 - Release First Exchange Combat Focal Elegance Polish"


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(capture_manifest, review_notes)
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(capture_manifest.get("post_final_world_combat_focal_render_review", {}))
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
			status = "ready_for_focal_elegance_polish"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_focal_task_id": SOURCE_FOCAL_TASK_ID,
		"source_direction_task_id": SOURCE_DIRECTION_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_direction_recapture_task_id": SOURCE_DIRECTION_RECAPTURE_TASK_ID,
		"capture_schema": String(capture_manifest.get("schema", "")),
		"capture_task_id": String(capture_manifest.get("task_id", "")),
		"capture_gate": String(capture_manifest.get("gate", "")),
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"expected_focal_schema": String(capture_manifest.get("expected_focal_schema", "")),
		"expected_focal_style_id": String(capture_manifest.get("expected_focal_style_id", "")),
		"expected_direction_style_id": String(capture_manifest.get("expected_direction_style_id", "")),
		"source_direction_recapture_schema": String(capture_manifest.get("source_direction_recapture_schema", "")),
		"source_direction_recapture_gate": String(capture_manifest.get("source_direction_recapture_gate", "")),
		"window_screenshot_path": String(capture_manifest.get("post_final_window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("post_final_desktop_screenshot_path", "")),
		"window_capture_method": String(capture_manifest.get("post_final_window_capture_method", "")),
		"window_capture_trusted": bool(capture_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_capture_after_deeplink_final": bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_final_world_combat_focal_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", capture_manifest.get("post_final_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"world_fire_label_visible": bool(review_notes.get("world_fire_label_visible", false)),
		"world_combat_focal_lane_visible": bool(review_notes.get("world_combat_focal_lane_visible", false)),
		"source_glow_visible": bool(review_notes.get("source_glow_visible", false)),
		"target_halo_visible": bool(review_notes.get("target_halo_visible", false)),
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
		"recommended_direction": "polish_world_combat_focal_elegance_without_reopening_combat_truth",
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
		blockers.append(_issue("capture_schema_mismatch", "TASK_896-Manifest-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("capture_task_mismatch", "Manifest nennt nicht TASK_896."))
	if String(capture_manifest.get("source_task_id", "")) != SOURCE_FOCAL_TASK_ID:
		blockers.append(_issue("source_focal_task_mismatch", "Manifest nennt nicht TASK_895 als Focal-Quelle."))
	if String(capture_manifest.get("source_direction_task_id", "")) != SOURCE_DIRECTION_TASK_ID:
		blockers.append(_issue("source_direction_task_mismatch", "Manifest nennt nicht TASK_892 als Direction-/Impact-Quelle."))
	if String(capture_manifest.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Manifest nennt nicht TASK_894 als Findings-Quelle."))
	if String(capture_manifest.get("source_direction_recapture_task_id", "")) != SOURCE_DIRECTION_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_direction_recapture_task_mismatch", "Manifest nennt nicht TASK_893 als Recapture-Quelle."))
	if String(capture_manifest.get("expected_focal_schema", "")) != EXPECTED_FOCAL_SCHEMA:
		blockers.append(_issue("focal_schema_mismatch", "TASK_895-Focal-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_focal_style_id", "")) != EXPECTED_FOCAL_STYLE_ID:
		blockers.append(_issue("focal_style_mismatch", "TASK_895-Focal-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_direction_style_id", "")) != EXPECTED_DIRECTION_STYLE_ID:
		blockers.append(_issue("direction_style_mismatch", "TASK_892-Direction-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("source_direction_recapture_schema", "")) != EXPECTED_DIRECTION_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_direction_recapture_schema_mismatch", "TASK_893-Recapture-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(capture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_896-Capture-Gate ist fail."))
	if not Array(capture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_896-Manifest enthaelt Hard-Failures."))
	if not bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture ist nicht an deeplink_final gebunden."))
	if String(capture_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if not bool(capture_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_896-Window-Screenshot fehlt."))
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	if not bool(review_notes.get("manual_visual_review_done", false)):
		blockers.append(_issue("manual_visual_review_missing", "TASK_897 braucht einen Sichtbefund zum TASK_896-PNG."))
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		blockers.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	return blockers


static func _build_positive_findings(capture_manifest: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		positives.append({"id": "capture_bound_to_deeplink_final", "text": "Der TASK_896-Capture haengt am finalen Runtime-Trace-Zeitpunkt."})
	if String(capture_manifest.get("post_final_window_capture_method", "")) == "window_handle_print" and bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der Screenshot kommt vom Ziel-Window-Handle."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log zeigt CONTACT FIRE als lesbaren ersten Feuerwechsel."})
	if bool(review_notes.get("world_fire_label_visible", false)):
		positives.append({"id": "world_fire_label_visible", "text": "Ein FIRE-Weltlabel ist im Kontaktbereich sichtbar."})
	if bool(review_notes.get("world_combat_focal_lane_visible", false)):
		positives.append({"id": "world_combat_focal_lane_visible", "text": "Die TASK_895-Focal-Lane ist im Weltbild sichtbar."})
	if bool(review_notes.get("source_glow_visible", false)):
		positives.append({"id": "source_glow_visible", "text": "Der Source-Glow ist im Feuerbereich sichtbar."})
	if bool(review_notes.get("target_halo_visible", false)):
		positives.append({"id": "target_halo_visible", "text": "Der Target-Halo ist im Feuerbereich sichtbar."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den Review."})
	return positives


static func _build_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "focal_signal_reads_debuggy", true):
		issues.append({
			"id": "focal_signal_reads_debuggy",
			"severity": "world_visual_elegance_polish",
			"text": "Source-Glow/Target-Halo sind sichtbar, wirken aber noch wie technische Signalformen statt wie ein schicker Kampfakzent.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "source_to_target_lane_not_elegant", true):
		issues.append({
			"id": "source_to_target_lane_not_elegant",
			"severity": "world_visual_elegance_polish",
			"text": "Die Quelle-Ziel-Beziehung ist besser sichtbar, liest sich aber noch nicht sofort als natuerliche Schussbahn.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "target_halo_too_large_or_flat", true):
		issues.append({
			"id": "target_halo_too_large_or_flat",
			"severity": "world_visual_elegance_polish",
			"text": "Der Target-Halo ist praesent, aber noch zu flach/gross und konkurriert mit FIRE-Label und Tile-Raster.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "bottom_hud_still_competes_with_world_combat", true):
		issues.append({
			"id": "bottom_hud_still_competes_with_world_combat",
			"severity": "player_readability_polish",
			"text": "#17/#18 sind korrekt, aber Bottom-HUD und Member-Cards ziehen im Feuerwechsel weiter viel Aufmerksamkeit.",
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
