class_name ReleaseFirstExchangeFireLaneWorldReadAcceptanceVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_visual_findings.v1"
const TASK_ID: String = "TASK_915"
const SOURCE_TASK_ID: String = "TASK_914"
const SOURCE_ACCEPTANCE_TASK_ID: String = "TASK_913"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_911"
const SOURCE_WORLD_READ_TASK_ID: String = "TASK_910"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_recapture.v1"
const EXPECTED_ACCEPTANCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_polish.v1"
const EXPECTED_ACCEPTANCE_STYLE_ID: String = "task_913_release_first_exchange_fire_lane_world_read_acceptance_v1"
const EXPECTED_WORLD_READ_MICRO_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_micro_polish.v1"
const EXPECTED_WORLD_READ_MICRO_STYLE_ID: String = "task_910_release_first_exchange_fire_lane_world_read_micro_v1"
const EXPECTED_SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_real_window_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK: String = "TASK_916 - Release First Exchange Playability Smoke"
const NEXT_POLISH_TASK: String = "TASK_916 - Release First Exchange Fire Lane World Read Final Polish"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var final_source: Dictionary = Dictionary(source_snapshot.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(source_snapshot.get("post_final_fire_lane_world_read_acceptance_render_review", {}))
	var final_contact_fire: bool = bool(final_source.get("selected_starts_contact_fire", false)) \
		and bool(final_source.get("mission_starts_contact_fire", false)) \
		and bool(final_source.get("event_log_contains_contact_fire", false)) \
		and not bool(final_source.get("event_log_contains_contact_pressure", true))
	var manual_review_done: bool = bool(review_notes.get("manual_visual_review_done", false))
	var correct_window_confirmed: bool = bool(review_notes.get("correct_window_content_confirmed", false))
	var issues: Array = _build_issues(review_notes, final_contact_fire, manual_review_done, correct_window_confirmed)
	if not blockers.is_empty():
		issues = []
	var accepted: bool = blockers.is_empty() \
		and manual_review_done \
		and correct_window_confirmed \
		and bool(review_notes.get("player_readability_ok", false)) \
		and issues.is_empty()
	var status: String = "blocked"
	if blockers.is_empty():
		if not manual_review_done:
			status = "needs_manual_review"
		elif accepted:
			status = "accepted_for_first_exchange_playability_smoke"
		else:
			status = "ready_for_final_world_read_polish"
	var recommended_next: String = NEXT_SMOKE_TASK if accepted else NEXT_POLISH_TASK
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_acceptance_task_id": SOURCE_ACCEPTANCE_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_world_read_task_id": SOURCE_WORLD_READ_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_review_ready": bool(source_snapshot.get("review_ready", false)),
		"source_accepted": bool(source_snapshot.get("accepted", false)),
		"source_gate": String(source_snapshot.get("gate", "")),
		"branch": String(source_snapshot.get("branch", "")),
		"git_head": String(source_snapshot.get("git_head", "")),
		"launch_argument": String(source_snapshot.get("launch_argument", "")),
		"expected_acceptance_schema": String(source_snapshot.get("expected_acceptance_schema", "")),
		"expected_acceptance_style_id": String(source_snapshot.get("expected_acceptance_style_id", "")),
		"expected_world_read_micro_schema": String(source_snapshot.get("expected_world_read_micro_schema", "")),
		"expected_world_read_micro_style_id": String(source_snapshot.get("expected_world_read_micro_style_id", "")),
		"source_recapture_schema": String(source_snapshot.get("source_recapture_schema", "")),
		"source_recapture_gate": String(source_snapshot.get("source_recapture_gate", "")),
		"window_screenshot_path": String(source_snapshot.get("post_final_window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("post_final_desktop_screenshot_path", "")),
		"window_capture_method": _window_capture_method(source_snapshot),
		"window_capture_trusted": bool(source_snapshot.get("post_final_window_capture_trusted", false)),
		"post_final_capture_after_deeplink_final": bool(source_snapshot.get("post_final_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_final_fire_lane_world_read_acceptance_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"correct_window_content_confirmed": correct_window_confirmed,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", source_snapshot.get("post_final_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"acceptance_polish_visible": bool(review_notes.get("acceptance_polish_visible", false)),
		"fire_lane_is_first_world_movement": bool(review_notes.get("fire_lane_is_first_world_movement", false)),
		"source_target_anchors_carry_direction": bool(review_notes.get("source_target_anchors_carry_direction", false)),
		"world_fire_label_stays_behind_lane": bool(review_notes.get("world_fire_label_stays_behind_lane", false)),
		"target_halo_stays_behind_lane": bool(review_notes.get("target_halo_stays_behind_lane", false)),
		"grid_world_noise_not_competing": bool(review_notes.get("grid_world_noise_not_competing", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"positive_findings": _build_positive_findings(source_snapshot, review_notes, final_contact_fire),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": recommended_next,
		"recommended_direction": "move_to_playability_smoke_if_accepted_else_final_world_read_polish",
		"avoid_next_action": "do_not_reopen_combat_truth_or_add_more_hud_text",
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


static func _build_blockers(source_snapshot: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_snapshot.get("schema", "")) != EXPECTED_SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_914-Snapshot/Manifest-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_914."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_ACCEPTANCE_TASK_ID:
		blockers.append(_issue("source_acceptance_task_mismatch", "Quelle nennt nicht TASK_913 als Acceptance-Polish."))
	if String(source_snapshot.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Quelle nennt nicht TASK_911 als Recapture-Basis."))
	if String(source_snapshot.get("source_world_read_task_id", "")) != SOURCE_WORLD_READ_TASK_ID:
		blockers.append(_issue("source_world_read_task_mismatch", "Quelle nennt nicht TASK_910 als World-Read-Basis."))
	if String(source_snapshot.get("expected_acceptance_schema", "")) != EXPECTED_ACCEPTANCE_SCHEMA:
		blockers.append(_issue("acceptance_schema_mismatch", "TASK_913-Acceptance-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_acceptance_style_id", "")) != EXPECTED_ACCEPTANCE_STYLE_ID:
		blockers.append(_issue("acceptance_style_mismatch", "TASK_913-Acceptance-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_world_read_micro_schema", "")) != EXPECTED_WORLD_READ_MICRO_SCHEMA:
		blockers.append(_issue("world_read_micro_schema_mismatch", "TASK_910-World-Read-Micro-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_world_read_micro_style_id", "")) != EXPECTED_WORLD_READ_MICRO_STYLE_ID:
		blockers.append(_issue("world_read_micro_style_mismatch", "TASK_910-World-Read-Micro-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("source_recapture_schema", "")) != EXPECTED_SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_911-Recapture-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Quelle nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(source_snapshot.get("status", "")) == "blocked" or String(source_snapshot.get("gate", "")) == "fail":
		blockers.append(_issue("source_not_review_ready", "TASK_914-Quelle ist nicht review-ready."))
	if not bool(source_snapshot.get("post_final_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_final_capture_not_after_trace", "Post-Final-Capture wurde nicht nach deeplink_final markiert."))
	if _window_capture_method(source_snapshot) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(source_snapshot.get("post_final_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if String(source_snapshot.get("post_final_window_screenshot_path", "")) == "":
		blockers.append(_issue("window_screenshot_path_missing", "TASK_914-Window-Screenshotpfad fehlt."))
	var final_source: Dictionary = Dictionary(source_snapshot.get("final_source_snapshot", {}))
	if String(final_source.get("stage", "")) != "deeplink_final":
		blockers.append(_issue("final_source_not_deeplink_final", "Finaler Source-Snapshot ist nicht deeplink_final."))
	return blockers


static func _build_positive_findings(source_snapshot: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if _window_capture_method(source_snapshot) == "window_handle_print" and bool(source_snapshot.get("post_final_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der TASK_914-Screenshot kommt vom Ziel-Window-Handle."})
	if String(source_snapshot.get("expected_acceptance_style_id", "")) == EXPECTED_ACCEPTANCE_STYLE_ID:
		positives.append({"id": "task_913_acceptance_style_present", "text": "Der TASK_913-Acceptance-Style ist als erwartete Weltbildquelle belegt."})
	if String(source_snapshot.get("expected_world_read_micro_style_id", "")) == EXPECTED_WORLD_READ_MICRO_STYLE_ID:
		positives.append({"id": "task_910_world_read_base_present", "text": "Die TASK_910-World-Read-Micro-Basis bleibt im Snapshot nachvollziehbar."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log bestaetigt CONTACT FIRE ohne den Review zu blockieren."})
	if bool(review_notes.get("acceptance_polish_visible", false)):
		positives.append({"id": "acceptance_polish_visible", "text": "Der TASK_913-Acceptance-Polish ist im echten Fenster sichtbar."})
	if bool(review_notes.get("fire_lane_is_first_world_movement", false)):
		positives.append({"id": "fire_lane_is_first_world_movement", "text": "Die Fire-Lane liest sich als erste Weltbewegung im Feuerwechsel."})
	if bool(review_notes.get("source_target_anchors_carry_direction", false)):
		positives.append({"id": "source_target_anchors_carry_direction", "text": "Source-/Target-Anker tragen die Schussrichtung."})
	if bool(review_notes.get("world_fire_label_stays_behind_lane", false)):
		positives.append({"id": "world_fire_label_stays_behind_lane", "text": "Das Welt-Fire-Label bleibt hinter der Lane."})
	if bool(review_notes.get("target_halo_stays_behind_lane", false)):
		positives.append({"id": "target_halo_stays_behind_lane", "text": "Der Target-Halo bleibt hinter der Lane."})
	if bool(review_notes.get("grid_world_noise_not_competing", false)):
		positives.append({"id": "grid_world_noise_not_competing", "text": "Raster-/Welt-Rauschen konkurriert nicht als primaerer Blickfang."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den naechsten Smoke."})
	return positives


static func _build_issues(review_notes: Dictionary, final_contact_fire: bool, manual_review_done: bool, correct_window_confirmed: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_visual_review_missing", "TASK_915 braucht einen Sichtbefund zum TASK_914-PNG/Snapshot."))
		return issues
	if not correct_window_confirmed:
		issues.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	if _review_flag(review_notes, "fire_lane_not_first_world_movement_after_acceptance_polish", true):
		issues.append(_issue("fire_lane_not_first_world_movement_after_acceptance_polish", "Die Fire-Lane ist nach TASK_913 staerker, aber noch nicht sicher die erste Weltbewegung."))
	if _review_flag(review_notes, "source_target_anchors_still_not_carrying_direction", true):
		issues.append(_issue("source_target_anchors_still_not_carrying_direction", "Source-/Target-Anker tragen die Richtung noch nicht sicher genug."))
	if _review_flag(review_notes, "label_halo_still_competes_with_lane", true):
		issues.append(_issue("label_halo_still_competes_with_lane", "Welt-Fire-Label oder Target-Halo konkurrieren weiterhin mit der Lane."))
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", true):
		issues.append(_issue("bottom_hud_still_dense_for_first_fire_read", "#17/#18/#19 sind korrekt, aber Bottom-HUD bleibt fuer den ersten Feuerblick dicht."))
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	return bool(review_notes.get(key, default_value))


static func _window_capture_method(source_snapshot: Dictionary) -> String:
	var method: String = String(source_snapshot.get("post_final_window_capture_method", ""))
	if method == "":
		method = String(source_snapshot.get("post_final_capture_method", ""))
	return method


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
