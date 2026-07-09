class_name ReleaseFirstExchangeFollowupPlayerPolishTuningVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning_visual_findings.v1"
const TASK_ID: String = "TASK_928"
const SOURCE_TASK_ID: String = "TASK_927"
const SOURCE_TUNING_TASK_ID: String = "TASK_926"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_925"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_924"
const SOURCE_PLAYER_POLISH_TASK_ID: String = "TASK_923"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning_recapture.v1"
const EXPECTED_TUNING_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning.v1"
const EXPECTED_TUNING_STYLE_ID: String = "task_926_release_first_exchange_followup_player_polish_tuning_v1"
const EXPECTED_PLAYER_POLISH_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_world_read_player_polish.v1"
const EXPECTED_PLAYER_POLISH_STYLE_ID: String = "task_923_release_first_exchange_followup_world_read_player_v1"
const EXPECTED_SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_player_polish_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK: String = "TASK_929 - Release First Exchange Playability Smoke"
const NEXT_POLISH_TASK: String = "TASK_929 - Release First Exchange Followup Player Polish Tuning Final Readability Polish"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var final_source: Dictionary = Dictionary(source_snapshot.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(source_snapshot.get("post_player_polish_tuning_world_read_render_review", {}))
	var final_contact_fire: bool = bool(source_snapshot.get("final_source_contact_fire", false))
	if not final_contact_fire:
		final_contact_fire = bool(final_source.get("selected_starts_contact_fire", false)) \
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
			status = "ready_for_followup_player_polish_tuning_final_readability_polish"
	var recommended_next: String = NEXT_SMOKE_TASK if accepted else NEXT_POLISH_TASK
	var capture_method: String = _capture_method(source_snapshot)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_tuning_task_id": SOURCE_TUNING_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_player_polish_task_id": SOURCE_PLAYER_POLISH_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": String(source_snapshot.get("status", "")),
		"source_review_ready": bool(source_snapshot.get("review_ready", false)),
		"source_accepted": bool(source_snapshot.get("accepted", false)),
		"source_gate": String(source_snapshot.get("gate", "")),
		"review_ready": blockers.is_empty(),
		"accepted": accepted,
		"gate": status,
		"branch": String(source_snapshot.get("branch", "")),
		"git_head": String(source_snapshot.get("git_head", "")),
		"launch_argument": String(source_snapshot.get("launch_argument", "")),
		"expected_tuning_schema": String(source_snapshot.get("expected_tuning_schema", "")),
		"expected_tuning_style_id": String(source_snapshot.get("expected_tuning_style_id", "")),
		"expected_player_polish_schema": String(source_snapshot.get("expected_player_polish_schema", "")),
		"expected_player_polish_style_id": String(source_snapshot.get("expected_player_polish_style_id", "")),
		"source_recapture_schema": String(source_snapshot.get("source_recapture_schema", "")),
		"source_recapture_gate": String(source_snapshot.get("source_recapture_gate", "")),
		"window_screenshot_path": String(source_snapshot.get("post_player_polish_tuning_window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("post_player_polish_tuning_desktop_screenshot_path", "")),
		"window_capture_method": capture_method,
		"window_capture_trusted": bool(source_snapshot.get("post_player_polish_tuning_window_capture_trusted", false)),
		"post_player_polish_tuning_capture_after_deeplink_final": bool(source_snapshot.get("post_player_polish_tuning_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_player_polish_tuning_world_read_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"correct_window_content_confirmed": correct_window_confirmed,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", source_snapshot.get("post_player_polish_tuning_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"tuning_visible": bool(review_notes.get("tuning_visible", false)),
		"tuning_fire_lane_is_first_world_movement": bool(review_notes.get("tuning_fire_lane_is_first_world_movement", false)),
		"tuning_source_target_anchors_carry_direction": bool(review_notes.get("tuning_source_target_anchors_carry_direction", false)),
		"tuning_world_fire_label_stays_behind_lane": bool(review_notes.get("tuning_world_fire_label_stays_behind_lane", false)),
		"tuning_target_halo_stays_behind_lane": bool(review_notes.get("tuning_target_halo_stays_behind_lane", false)),
		"tuning_grid_world_noise_not_competing": bool(review_notes.get("tuning_grid_world_noise_not_competing", false)),
		"tuning_lane_reads_before_fire_contact_text": bool(review_notes.get("tuning_lane_reads_before_fire_contact_text", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"positive_findings": _build_positive_findings(source_snapshot, review_notes, final_contact_fire),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": recommended_next,
		"recommended_direction": "move_to_playability_smoke_if_accepted_else_final_readability_polish",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_927-Snapshot/Manifest-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_927."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_TUNING_TASK_ID:
		blockers.append(_issue("source_tuning_task_mismatch", "Quelle nennt nicht TASK_926 als Tuning."))
	if String(source_snapshot.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Quelle nennt nicht TASK_925 als Findings-Basis."))
	if String(source_snapshot.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Quelle nennt nicht TASK_924 als Recapture-Basis."))
	if String(source_snapshot.get("source_player_polish_task_id", "")) != SOURCE_PLAYER_POLISH_TASK_ID:
		blockers.append(_issue("source_player_polish_task_mismatch", "Quelle nennt nicht TASK_923 als Player-Polish-Basis."))
	if String(source_snapshot.get("expected_tuning_schema", "")) != EXPECTED_TUNING_SCHEMA:
		blockers.append(_issue("tuning_schema_mismatch", "TASK_926-Tuning-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_tuning_style_id", "")) != EXPECTED_TUNING_STYLE_ID:
		blockers.append(_issue("tuning_style_mismatch", "TASK_926-Tuning-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_player_polish_schema", "")) != EXPECTED_PLAYER_POLISH_SCHEMA:
		blockers.append(_issue("player_polish_schema_mismatch", "TASK_923-Player-Polish-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_player_polish_style_id", "")) != EXPECTED_PLAYER_POLISH_STYLE_ID:
		blockers.append(_issue("player_polish_style_mismatch", "TASK_923-Player-Polish-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("source_recapture_schema", "")) != EXPECTED_SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_924-Recapture-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Quelle nutzt nicht den First-GO-Firefight-Deep-Link."))
	var source_status: String = String(source_snapshot.get("status", source_snapshot.get("gate", "")))
	if not source_status in ["review_ready", "accepted", "review"]:
		blockers.append(_issue("source_not_review_ready", "TASK_927-Quelle ist nicht review-ready."))
	if not bool(source_snapshot.get("post_player_polish_tuning_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_player_polish_tuning_capture_not_after_trace", "Post-Tuning-Capture wurde nicht nach deeplink_final markiert."))
	if _capture_method(source_snapshot) != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(source_snapshot.get("post_player_polish_tuning_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if String(source_snapshot.get("post_player_polish_tuning_window_screenshot_path", "")) == "":
		blockers.append(_issue("window_screenshot_path_missing", "TASK_927-Window-Screenshotpfad fehlt."))
	return blockers


static func _build_positive_findings(source_snapshot: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if _capture_method(source_snapshot) == "window_handle_print" and bool(source_snapshot.get("post_player_polish_tuning_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der TASK_927-Screenshot kommt vom Ziel-Window-Handle."})
	if String(source_snapshot.get("expected_tuning_style_id", "")) == EXPECTED_TUNING_STYLE_ID:
		positives.append({"id": "task_926_tuning_style_present", "text": "Der TASK_926-Tuning-Style ist als erwartete Weltbildquelle belegt."})
	if String(source_snapshot.get("expected_player_polish_style_id", "")) == EXPECTED_PLAYER_POLISH_STYLE_ID:
		positives.append({"id": "task_923_player_polish_style_present", "text": "Die TASK_923-Player-Polish-Basis bleibt im Snapshot nachvollziehbar."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log bestaetigt CONTACT FIRE ohne den Review zu blockieren."})
	if bool(review_notes.get("tuning_visible", false)):
		positives.append({"id": "tuning_visible", "text": "Das TASK_926-Tuning ist im echten Fenster sichtbar."})
	if bool(review_notes.get("tuning_fire_lane_is_first_world_movement", false)):
		positives.append({"id": "tuning_fire_lane_is_first_world_movement", "text": "Die Tuning-Fire-Lane liest sich als erste Weltbewegung im Feuerwechsel."})
	if bool(review_notes.get("tuning_lane_reads_before_fire_contact_text", false)):
		positives.append({"id": "tuning_lane_reads_before_fire_contact_text", "text": "Die Tuning-Lane wird vor FIRE/CONTACT-Text und Zielcluster gelesen."})
	if bool(review_notes.get("tuning_source_target_anchors_carry_direction", false)):
		positives.append({"id": "tuning_source_target_anchors_carry_direction", "text": "Tuning-Source-/Target-Anker tragen die Schussrichtung."})
	if bool(review_notes.get("tuning_world_fire_label_stays_behind_lane", false)):
		positives.append({"id": "tuning_world_fire_label_stays_behind_lane", "text": "Das Welt-Fire-Label bleibt hinter der Tuning-Lane."})
	if bool(review_notes.get("tuning_target_halo_stays_behind_lane", false)):
		positives.append({"id": "tuning_target_halo_stays_behind_lane", "text": "Der Target-Halo bleibt hinter der Tuning-Lane."})
	if bool(review_notes.get("tuning_grid_world_noise_not_competing", false)):
		positives.append({"id": "tuning_grid_world_noise_not_competing", "text": "Raster-/Welt-Rauschen konkurriert nicht als primaerer Blickfang."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den naechsten Smoke."})
	return positives


static func _build_issues(review_notes: Dictionary, final_contact_fire: bool, manual_review_done: bool, correct_window_confirmed: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_visual_review_missing", "TASK_928 braucht einen Sichtbefund zum TASK_927-PNG/Snapshot."))
		return issues
	if not correct_window_confirmed:
		issues.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	if _review_flag(review_notes, "tuning_fire_lane_not_first_world_movement", true):
		issues.append(_issue("tuning_fire_lane_not_first_world_movement", "Die Tuning-Fire-Lane ist noch nicht sicher die erste Weltbewegung."))
	if _review_flag(review_notes, "tuning_lane_not_before_fire_contact_text", true):
		issues.append(_issue("tuning_lane_not_before_fire_contact_text", "FIRE/CONTACT-Text oder Zielcluster ziehen noch vor der Tuning-Lane."))
	if _review_flag(review_notes, "tuning_source_target_anchors_still_weak", true):
		issues.append(_issue("tuning_source_target_anchors_still_weak", "Tuning-Source-/Target-Anker tragen die Richtung noch nicht sicher genug."))
	if _review_flag(review_notes, "tuning_label_halo_still_competes", true):
		issues.append(_issue("tuning_label_halo_still_competes", "Welt-Fire-Label oder Target-Halo konkurrieren weiterhin mit der Tuning-Lane."))
	if _review_flag(review_notes, "tuning_grid_world_noise_still_competes", false):
		issues.append(_issue("tuning_grid_world_noise_still_competes", "Raster-/Weltlinien konkurrieren noch mit dem Feuerblick."))
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", true):
		issues.append(_issue("bottom_hud_still_dense_for_first_fire_read", "#17/#18/#19 sind korrekt, aber Bottom-HUD bleibt fuer den ersten Feuerblick dicht."))
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	return bool(review_notes.get(key, default_value))


static func _capture_method(source_snapshot: Dictionary) -> String:
	return String(source_snapshot.get("post_player_polish_tuning_capture_method", source_snapshot.get("post_player_polish_tuning_window_capture_method", "")))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
