class_name ReleaseFirstExchangeCombatMarkerScaleVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_marker_scale_visual_findings.v1"
const TASK_ID: String = "TASK_903"
const SOURCE_TASK_ID: String = "TASK_902"
const SOURCE_MARKER_SCALE_TASK_ID: String = "TASK_901"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_900"
const SOURCE_ELEGANCE_RECAPTURE_TASK_ID: String = "TASK_899"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_marker_scale_real_window_recapture.v1"
const EXPECTED_MARKER_SCALE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
const EXPECTED_MARKER_SCALE_STYLE_ID: String = "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
const EXPECTED_ELEGANCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_focal_elegance_real_window_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_904 - Release First Exchange Fire Lane Readability Polish"


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(capture_manifest, review_notes)
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(capture_manifest.get("post_final_combat_marker_scale_render_review", {}))
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
			status = "ready_for_fire_lane_readability_polish"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_marker_scale_task_id": SOURCE_MARKER_SCALE_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_elegance_recapture_task_id": SOURCE_ELEGANCE_RECAPTURE_TASK_ID,
		"capture_schema": String(capture_manifest.get("schema", "")),
		"capture_task_id": String(capture_manifest.get("task_id", "")),
		"capture_gate": String(capture_manifest.get("gate", "")),
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"expected_marker_scale_schema": String(capture_manifest.get("expected_marker_scale_schema", "")),
		"expected_marker_scale_style_id": String(capture_manifest.get("expected_marker_scale_style_id", "")),
		"source_elegance_recapture_schema": String(capture_manifest.get("source_elegance_recapture_schema", "")),
		"source_elegance_recapture_gate": String(capture_manifest.get("source_elegance_recapture_gate", "")),
		"window_screenshot_path": String(capture_manifest.get("post_final_window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("post_final_desktop_screenshot_path", "")),
		"window_capture_method": String(capture_manifest.get("post_final_window_capture_method", "")),
		"window_capture_trusted": bool(capture_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_capture_after_deeplink_final": bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_final_combat_marker_scale_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", capture_manifest.get("post_final_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"marker_scale_polish_visible": bool(review_notes.get("marker_scale_polish_visible", false)),
		"target_halo_less_marker_disc": bool(review_notes.get("target_halo_less_marker_disc", false)),
		"grid_world_noise_quieter": bool(review_notes.get("grid_world_noise_quieter", false)),
		"source_to_target_lane_visible": bool(review_notes.get("source_to_target_lane_visible", false)),
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
		"recommended_direction": "polish_fire_lane_readability_without_reopening_combat_truth",
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
		blockers.append(_issue("capture_schema_mismatch", "TASK_902-Manifest-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("capture_task_mismatch", "Manifest nennt nicht TASK_902."))
	if String(capture_manifest.get("source_task_id", "")) != SOURCE_MARKER_SCALE_TASK_ID:
		blockers.append(_issue("source_marker_scale_task_mismatch", "Manifest nennt nicht TASK_901 als Marker-Scale-Quelle."))
	if String(capture_manifest.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Manifest nennt nicht TASK_900 als Findings-Quelle."))
	if String(capture_manifest.get("source_elegance_recapture_task_id", "")) != SOURCE_ELEGANCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_elegance_recapture_task_mismatch", "Manifest nennt nicht TASK_899 als Recapture-Basis."))
	if String(capture_manifest.get("expected_marker_scale_schema", "")) != EXPECTED_MARKER_SCALE_SCHEMA:
		blockers.append(_issue("marker_scale_schema_mismatch", "TASK_901-Marker-Scale-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_marker_scale_style_id", "")) != EXPECTED_MARKER_SCALE_STYLE_ID:
		blockers.append(_issue("marker_scale_style_mismatch", "TASK_901-Marker-Scale-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("source_elegance_recapture_schema", "")) != EXPECTED_ELEGANCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_elegance_recapture_schema_mismatch", "TASK_899-Recapture-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(capture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_902-Capture-Gate ist fail."))
	if not Array(capture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_902-Manifest enthaelt Hard-Failures."))
	if not bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture ist nicht an deeplink_final gebunden."))
	if String(capture_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if not bool(capture_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_902-Window-Screenshot fehlt."))
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	if not bool(review_notes.get("manual_visual_review_done", false)):
		blockers.append(_issue("manual_visual_review_missing", "TASK_903 braucht einen Sichtbefund zum TASK_902-PNG."))
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		blockers.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	return blockers


static func _build_positive_findings(capture_manifest: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		positives.append({"id": "capture_bound_to_deeplink_final", "text": "Der TASK_902-Capture haengt am finalen Runtime-Trace-Zeitpunkt."})
	if String(capture_manifest.get("post_final_window_capture_method", "")) == "window_handle_print" and bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der Screenshot kommt vom Ziel-Window-Handle."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log zeigt CONTACT FIRE als lesbaren ersten Feuerwechsel."})
	if bool(review_notes.get("marker_scale_polish_visible", false)):
		positives.append({"id": "marker_scale_polish_visible", "text": "Der TASK_901-Marker-/World-Noise-Polish ist im Fenster sichtbar."})
	if bool(review_notes.get("target_halo_less_marker_disc", false)):
		positives.append({"id": "target_halo_less_marker_disc", "text": "Der Target-Halo liest kleiner und weniger scheibenhaft als vor TASK_901."})
	if bool(review_notes.get("grid_world_noise_quieter", false)):
		positives.append({"id": "grid_world_noise_quieter", "text": "Grid-/World-Noise wirkt ruhiger und dominiert den ersten Feuerblick weniger."})
	if bool(review_notes.get("source_to_target_lane_visible", false)):
		positives.append({"id": "source_to_target_lane_visible", "text": "Die Source-to-target-Lane ist als Fire-Bezug vorhanden."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den Review."})
	return positives


static func _build_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "fire_lane_still_too_subtle", true):
		issues.append({
			"id": "fire_lane_still_too_subtle",
			"severity": "world_visual_readability_polish",
			"text": "Die Schussbahn ist vorhanden, aber noch nicht die erste intuitive Weltlesung des Feuerwechsels.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "contact_marker_cluster_still_attention_heavy", true):
		issues.append({
			"id": "contact_marker_cluster_still_attention_heavy",
			"severity": "world_visual_elegance_polish",
			"text": "FIRE/CONTACT-Text und kleine Marker sitzen dicht beieinander und ziehen Aufmerksamkeit eher als Marker-Cluster statt als Kampfbewegung.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", true):
		issues.append({
			"id": "bottom_hud_still_dense_for_first_fire_read",
			"severity": "player_readability_polish",
			"text": "#17/#18 sind korrekt, aber Bottom-HUD und Member-Cards bleiben fuer den ersten Feuerblick visuell schwer.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_over_world_competes_left_flank", false):
		issues.append({
			"id": "event_log_over_world_competes_left_flank",
			"severity": "hud_density_polish",
			"text": "Das Event Log bleibt lesbar, verdeckt aber im linken Weltbereich weiterhin Karteninformation.",
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
