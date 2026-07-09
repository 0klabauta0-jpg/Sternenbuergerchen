class_name ReleaseFirstExchangeFireLaneWorldReadVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_visual_findings.v1"
const TASK_ID: String = "TASK_912"
const SOURCE_TASK_ID: String = "TASK_911"
const SOURCE_WORLD_READ_TASK_ID: String = "TASK_910"
const SOURCE_RECAPTURE_BASE_TASK_ID: String = "TASK_908"
const SOURCE_LABEL_CLUSTER_TASK_ID: String = "TASK_907"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_real_window_recapture.v1"
const EXPECTED_WORLD_READ_MICRO_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_micro_polish.v1"
const EXPECTED_WORLD_READ_MICRO_STYLE_ID: String = "task_910_release_first_exchange_fire_lane_world_read_micro_v1"
const EXPECTED_LABEL_CLUSTER_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_label_cluster_polish.v1"
const EXPECTED_LABEL_CLUSTER_STYLE_ID: String = "task_907_release_first_exchange_fire_lane_label_cluster_v1"
const EXPECTED_SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_label_cluster_real_window_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_913 - Release First Exchange Fire Lane World Read Acceptance Polish"


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(capture_manifest, review_notes)
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(capture_manifest.get("post_final_fire_lane_world_read_micro_render_review", {}))
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
			status = "ready_for_world_read_acceptance_polish"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_world_read_task_id": SOURCE_WORLD_READ_TASK_ID,
		"source_recapture_base_task_id": SOURCE_RECAPTURE_BASE_TASK_ID,
		"source_label_cluster_task_id": SOURCE_LABEL_CLUSTER_TASK_ID,
		"capture_schema": String(capture_manifest.get("schema", "")),
		"capture_task_id": String(capture_manifest.get("task_id", "")),
		"capture_gate": String(capture_manifest.get("gate", "")),
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"expected_world_read_micro_schema": String(capture_manifest.get("expected_world_read_micro_schema", "")),
		"expected_world_read_micro_style_id": String(capture_manifest.get("expected_world_read_micro_style_id", "")),
		"expected_label_cluster_schema": String(capture_manifest.get("expected_label_cluster_schema", "")),
		"expected_label_cluster_style_id": String(capture_manifest.get("expected_label_cluster_style_id", "")),
		"source_recapture_schema": String(capture_manifest.get("source_recapture_schema", "")),
		"source_recapture_gate": String(capture_manifest.get("source_recapture_gate", "")),
		"window_screenshot_path": String(capture_manifest.get("post_final_window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("post_final_desktop_screenshot_path", "")),
		"window_capture_method": String(capture_manifest.get("post_final_window_capture_method", "")),
		"window_capture_trusted": bool(capture_manifest.get("post_final_window_capture_trusted", false)),
		"post_final_capture_after_deeplink_final": bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_final_fire_lane_world_read_micro_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", capture_manifest.get("post_final_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"world_read_micro_polish_visible": bool(review_notes.get("world_read_micro_polish_visible", false)),
		"world_fire_label_quiet_and_displaced": bool(review_notes.get("world_fire_label_quiet_and_displaced", false)),
		"target_halo_retreats_behind_lane": bool(review_notes.get("target_halo_retreats_behind_lane", false)),
		"fire_lane_core_primary_read": bool(review_notes.get("fire_lane_core_primary_read", false)),
		"source_target_anchors_support_direction": bool(review_notes.get("source_target_anchors_support_direction", false)),
		"grid_world_noise_not_competing": bool(review_notes.get("grid_world_noise_not_competing", false)),
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
		"recommended_direction": "polish_world_read_acceptance_without_reopening_combat_truth",
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
		blockers.append(_issue("capture_schema_mismatch", "TASK_911-Manifest-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("capture_task_mismatch", "Manifest nennt nicht TASK_911."))
	if String(capture_manifest.get("source_task_id", "")) != SOURCE_WORLD_READ_TASK_ID:
		blockers.append(_issue("source_world_read_task_mismatch", "Manifest nennt nicht TASK_910 als World-Read-Quelle."))
	if String(capture_manifest.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_BASE_TASK_ID:
		blockers.append(_issue("source_recapture_base_task_mismatch", "Manifest nennt nicht TASK_908 als Recapture-Basis."))
	if String(capture_manifest.get("source_label_cluster_task_id", "")) != SOURCE_LABEL_CLUSTER_TASK_ID:
		blockers.append(_issue("source_label_cluster_task_mismatch", "Manifest nennt nicht TASK_907 als Label-Cluster-Basis."))
	if String(capture_manifest.get("expected_world_read_micro_schema", "")) != EXPECTED_WORLD_READ_MICRO_SCHEMA:
		blockers.append(_issue("world_read_micro_schema_mismatch", "TASK_910-World-Read-Micro-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_world_read_micro_style_id", "")) != EXPECTED_WORLD_READ_MICRO_STYLE_ID:
		blockers.append(_issue("world_read_micro_style_mismatch", "TASK_910-World-Read-Micro-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_label_cluster_schema", "")) != EXPECTED_LABEL_CLUSTER_SCHEMA:
		blockers.append(_issue("label_cluster_schema_mismatch", "TASK_907-Label-Cluster-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("expected_label_cluster_style_id", "")) != EXPECTED_LABEL_CLUSTER_STYLE_ID:
		blockers.append(_issue("label_cluster_style_mismatch", "TASK_907-Label-Cluster-Style fehlt oder passt nicht."))
	if String(capture_manifest.get("source_recapture_schema", "")) != EXPECTED_SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_908-Recapture-Schema fehlt oder passt nicht."))
	if String(capture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(capture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_911-Capture-Gate ist fail."))
	if not Array(capture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_911-Manifest enthaelt Hard-Failures."))
	if not bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture ist nicht an deeplink_final gebunden."))
	if String(capture_manifest.get("post_final_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if not bool(capture_manifest.get("post_final_window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_911-Window-Screenshot fehlt."))
	var final_source: Dictionary = Dictionary(capture_manifest.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	if not bool(review_notes.get("manual_visual_review_done", false)):
		blockers.append(_issue("manual_visual_review_missing", "TASK_912 braucht einen Sichtbefund zum TASK_911-PNG."))
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		blockers.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	return blockers


static func _build_positive_findings(capture_manifest: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if bool(capture_manifest.get("post_final_capture_after_deeplink_final", false)):
		positives.append({"id": "capture_bound_to_deeplink_final", "text": "Der TASK_911-Capture haengt am finalen Runtime-Trace-Zeitpunkt."})
	if String(capture_manifest.get("post_final_window_capture_method", "")) == "window_handle_print" and bool(capture_manifest.get("post_final_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der Screenshot kommt vom Ziel-Window-Handle."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log blockiert den Weltblick nicht und bestaetigt CONTACT FIRE."})
	if bool(review_notes.get("world_read_micro_polish_visible", false)):
		positives.append({"id": "world_read_micro_polish_visible", "text": "Der TASK_910-World-Read-Micro-Polish ist im echten Fenster vorhanden."})
	if bool(review_notes.get("world_fire_label_quiet_and_displaced", false)):
		positives.append({"id": "world_fire_label_quiet_and_displaced", "text": "Das Welt-Fire-Label ist leiser und weiter vom Zielcluster entfernt."})
	if bool(review_notes.get("target_halo_retreats_behind_lane", false)):
		positives.append({"id": "target_halo_retreats_behind_lane", "text": "Der Target-Halo tritt hinter die Lane zurueck."})
	if bool(review_notes.get("fire_lane_core_visible", false)):
		positives.append({"id": "fire_lane_core_visible", "text": "Der Fire-Lane-Core ist im Zielbereich sichtbar."})
	if bool(review_notes.get("source_target_anchors_support_direction", false)):
		positives.append({"id": "source_target_anchors_support_direction", "text": "Source-/Target-Anker unterstuetzen die Schussrichtung."})
	if bool(review_notes.get("grid_world_noise_not_competing", false)):
		positives.append({"id": "grid_world_noise_not_competing", "text": "Raster-/Welt-Rauschen konkurriert nicht mehr als primaerer Blickfang."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den Review."})
	return positives


static func _build_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "fire_lane_not_first_world_read_after_micro_polish", true):
		issues.append({
			"id": "fire_lane_not_first_world_read_after_micro_polish",
			"severity": "world_visual_hierarchy_polish",
			"text": "Die Fire-Lane ist nach TASK_910 sichtbarer, aber noch nicht die erste intuitive Weltbewegung.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "label_halo_marker_cluster_still_competes", true):
		issues.append({
			"id": "label_halo_marker_cluster_still_competes",
			"severity": "world_visual_readability_polish",
			"text": "Label/Halo/Marker konkurrieren weiterhin mit der Source-to-target-Lane.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "source_target_anchors_still_not_carrying_direction", true):
		issues.append({
			"id": "source_target_anchors_still_not_carrying_direction",
			"severity": "world_visual_readability_polish",
			"text": "Source-/Target-Anker sind belegt, tragen die Richtung aber noch nicht stark genug.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", true):
		issues.append({
			"id": "bottom_hud_still_dense_for_first_fire_read",
			"severity": "player_readability_polish",
			"text": "#17/#18 sind korrekt, aber Bottom-HUD und Member-Cards bleiben fuer den ersten Feuerblick visuell schwer.",
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
