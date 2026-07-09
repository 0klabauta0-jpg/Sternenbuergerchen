class_name ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupSecondVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.v1"
const TASK_ID: String = "TASK_947"
const SOURCE_TASK_ID: String = "TASK_946"
const SOURCE_SECOND_FIX_TASK_ID: String = "TASK_945"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_944"
const SOURCE_FOLLOWUP_FIX_TASK_ID: String = "TASK_942"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_943"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.v1"
const EXPECTED_SECOND_FIX_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1"
const EXPECTED_SECOND_FIX_STYLE_ID: String = "task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
const EXPECTED_FOLLOWUP_FIX_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const EXPECTED_FOLLOWUP_FIX_STYLE_ID: String = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const EXPECTED_SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK: String = "TASK_948 - Release First Exchange Playability Smoke"
const NEXT_RETURN_TASK: String = "TASK_948 - Tactical Decision Clarity Scenario Return"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var final_source: Dictionary = Dictionary(source_snapshot.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(source_snapshot.get("second_world_read_render_review", {}))
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
			status = "ready_for_tactical_decision_clarity_return"
	var recommended_next: String = NEXT_SMOKE_TASK if accepted else NEXT_RETURN_TASK
	var recommended_direction: String = "move_to_playability_smoke" if accepted else "stop_first_exchange_polish_loop_and_return_to_playable_scenario"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_second_fix_task_id": SOURCE_SECOND_FIX_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_followup_fix_task_id": SOURCE_FOLLOWUP_FIX_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
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
		"expected_second_fix_schema": String(source_snapshot.get("expected_second_fix_schema", "")),
		"expected_second_fix_style_id": String(source_snapshot.get("expected_second_fix_style_id", "")),
		"expected_findings_schema": String(source_snapshot.get("expected_findings_schema", "")),
		"expected_followup_fix_schema": String(source_snapshot.get("expected_followup_fix_schema", "")),
		"expected_followup_fix_style_id": String(source_snapshot.get("expected_followup_fix_style_id", "")),
		"source_recapture_schema": String(source_snapshot.get("source_recapture_schema", "")),
		"source_recapture_gate": String(source_snapshot.get("source_recapture_gate", "")),
		"window_screenshot_path": String(source_snapshot.get("second_window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("second_desktop_screenshot_path", "")),
		"window_capture_method": _capture_method(source_snapshot),
		"window_capture_trusted": bool(source_snapshot.get("second_window_capture_trusted", false)),
		"second_capture_after_deeplink_final": bool(source_snapshot.get("second_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"source_second_fix_snapshot": Dictionary(source_snapshot.get("source_second_fix_snapshot", {})),
		"source_findings_snapshot": Dictionary(source_snapshot.get("source_findings_snapshot", {})),
		"source_followup_fix_snapshot": Dictionary(source_snapshot.get("source_followup_fix_snapshot", {})),
		"source_recapture_review": Dictionary(source_snapshot.get("source_recapture_review", {})),
		"second_world_read_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"correct_window_content_confirmed": correct_window_confirmed,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", source_snapshot.get("second_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"second_visible": bool(review_notes.get("second_visible", false)),
		"second_fire_lane_is_first_world_movement": bool(review_notes.get("second_fire_lane_is_first_world_movement", false)),
		"second_lane_reads_before_fire_contact_text": bool(review_notes.get("second_lane_reads_before_fire_contact_text", false)),
		"second_source_target_anchors_carry_direction": bool(review_notes.get("second_source_target_anchors_carry_direction", false)),
		"second_anchors_do_not_read_as_discs": bool(review_notes.get("second_anchors_do_not_read_as_discs", false)),
		"second_world_fire_label_stays_behind_lane": bool(review_notes.get("second_world_fire_label_stays_behind_lane", false)),
		"second_target_halo_stays_behind_lane": bool(review_notes.get("second_target_halo_stays_behind_lane", false)),
		"second_grid_world_noise_not_competing": bool(review_notes.get("second_grid_world_noise_not_competing", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"positive_findings": _build_positive_findings(source_snapshot, review_notes, final_contact_fire),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": recommended_next,
		"recommended_direction": recommended_direction,
		"avoid_next_action": "do_not_start_another_fire_lane_value_polish_without_new_playtest_goal",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_946-Snapshot/Manifest-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_946."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_SECOND_FIX_TASK_ID:
		blockers.append(_issue("source_second_fix_task_mismatch", "Quelle nennt nicht TASK_945 als Second-Fix."))
	if String(source_snapshot.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Quelle nennt nicht TASK_944 als Findings-Basis."))
	if String(source_snapshot.get("source_followup_fix_task_id", "")) != SOURCE_FOLLOWUP_FIX_TASK_ID:
		blockers.append(_issue("source_followup_fix_task_mismatch", "Quelle nennt nicht TASK_942 als Followup-Fix-Basis."))
	if String(source_snapshot.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Quelle nennt nicht TASK_943 als Recapture-Basis."))
	if String(source_snapshot.get("expected_second_fix_schema", "")) != EXPECTED_SECOND_FIX_SCHEMA:
		blockers.append(_issue("second_fix_schema_mismatch", "TASK_945-Second-Fix-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_second_fix_style_id", "")) != EXPECTED_SECOND_FIX_STYLE_ID:
		blockers.append(_issue("second_fix_style_mismatch", "TASK_945-Second-Fix-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_findings_schema", "")) != EXPECTED_FINDINGS_SCHEMA:
		blockers.append(_issue("findings_schema_mismatch", "TASK_944-Findings-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_followup_fix_schema", "")) != EXPECTED_FOLLOWUP_FIX_SCHEMA:
		blockers.append(_issue("followup_fix_schema_mismatch", "TASK_942-Followup-Fix-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_followup_fix_style_id", "")) != EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		blockers.append(_issue("followup_fix_style_mismatch", "TASK_942-Followup-Fix-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("source_recapture_schema", "")) != EXPECTED_SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_943-Recapture-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Quelle nutzt nicht den First-GO-Firefight-Deep-Link."))
	var source_status: String = String(source_snapshot.get("status", source_snapshot.get("gate", "")))
	if not source_status in ["review_ready", "accepted", "review"]:
		blockers.append(_issue("source_not_review_ready", "TASK_946-Quelle ist nicht review-ready."))
	if not bool(source_snapshot.get("second_capture_after_deeplink_final", false)):
		blockers.append(_issue("second_capture_not_after_trace", "Second-Capture wurde nicht nach deeplink_final markiert."))
	if _capture_method(source_snapshot) != "window_handle_print":
		blockers.append(_issue("second_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(source_snapshot.get("second_window_capture_trusted", false)):
		blockers.append(_issue("second_window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if String(source_snapshot.get("second_window_screenshot_path", "")) == "":
		blockers.append(_issue("window_screenshot_path_missing", "TASK_946-Window-Screenshotpfad fehlt."))
	return blockers


static func _build_positive_findings(source_snapshot: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if _capture_method(source_snapshot) == "window_handle_print" and bool(source_snapshot.get("second_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der TASK_946-Screenshot kommt vom Ziel-Window-Handle."})
	if String(source_snapshot.get("expected_second_fix_style_id", "")) == EXPECTED_SECOND_FIX_STYLE_ID:
		positives.append({"id": "task_945_second_fix_style_present", "text": "Der TASK_945-Second-Fix-Style ist als erwartete Weltbildquelle belegt."})
	if String(source_snapshot.get("expected_followup_fix_style_id", "")) == EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		positives.append({"id": "task_942_followup_fix_style_present", "text": "Die TASK_942-Followup-Fix-Basis bleibt nachvollziehbar."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log bestaetigt CONTACT FIRE ohne den Review zu blockieren."})
	if bool(review_notes.get("second_visible", false)):
		positives.append({"id": "second_visible", "text": "Der TASK_945-Second-Fix-Style ist im echten Fenster sichtbar."})
	if bool(review_notes.get("second_fire_lane_is_first_world_movement", false)):
		positives.append({"id": "second_fire_lane_is_first_world_movement", "text": "Die TASK_945-Fire-Lane liest sich als erste Weltbewegung im Feuerwechsel."})
	if bool(review_notes.get("second_lane_reads_before_fire_contact_text", false)):
		positives.append({"id": "second_lane_reads_before_fire_contact_text", "text": "Die TASK_945-Lane wird vor FIRE/CONTACT-Text und Zielcluster gelesen."})
	if bool(review_notes.get("second_source_target_anchors_carry_direction", false)):
		positives.append({"id": "second_source_target_anchors_carry_direction", "text": "TASK_945-Source-/Target-Anker tragen die Schussrichtung."})
	if bool(review_notes.get("second_anchors_do_not_read_as_discs", false)):
		positives.append({"id": "second_anchors_do_not_read_as_discs", "text": "TASK_945-Anker tragen Richtung ohne scheibenhaft zu wirken."})
	if bool(review_notes.get("second_world_fire_label_stays_behind_lane", false)):
		positives.append({"id": "second_world_fire_label_stays_behind_lane", "text": "Das Welt-Fire-Label bleibt hinter der TASK_945-Lane."})
	if bool(review_notes.get("second_target_halo_stays_behind_lane", false)):
		positives.append({"id": "second_target_halo_stays_behind_lane", "text": "Der Target-Halo bleibt hinter der TASK_945-Lane."})
	if bool(review_notes.get("second_grid_world_noise_not_competing", false)):
		positives.append({"id": "second_grid_world_noise_not_competing", "text": "Raster-/Welt-Rauschen konkurriert nicht als primaerer Blickfang."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den naechsten Smoke."})
	return positives


static func _build_issues(review_notes: Dictionary, final_contact_fire: bool, manual_review_done: bool, correct_window_confirmed: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_second_visual_review_missing", "TASK_947 braucht einen Sichtbefund zum TASK_946-PNG/Snapshot."))
		return issues
	if not correct_window_confirmed:
		issues.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	if not bool(review_notes.get("second_fire_lane_is_first_world_movement", false)) and _review_flag(review_notes, "second_fire_lane_not_first_world_movement", true):
		issues.append(_issue("second_fire_lane_not_first_world_movement", "Die TASK_945-Fire-Lane ist noch nicht sicher die erste Weltbewegung."))
	if not bool(review_notes.get("second_lane_reads_before_fire_contact_text", false)) and _review_flag(review_notes, "second_lane_not_before_fire_contact_text", true):
		issues.append(_issue("second_lane_not_before_fire_contact_text", "FIRE/CONTACT-Text oder Zielcluster ziehen noch vor der TASK_945-Lane."))
	if _review_flag(review_notes, "second_source_target_anchors_still_weak", false):
		issues.append(_issue("second_source_target_anchors_still_weak", "TASK_945-Source-/Target-Anker tragen die Richtung noch nicht sicher genug."))
	if _review_flag(review_notes, "second_anchors_read_as_discs", false):
		issues.append(_issue("second_anchors_read_as_discs", "TASK_945-Anker wirken zu scheibenhaft statt richtungsfuehrend."))
	var label_and_halo_ok: bool = bool(review_notes.get("second_world_fire_label_stays_behind_lane", false)) and bool(review_notes.get("second_target_halo_stays_behind_lane", false))
	if not label_and_halo_ok and _review_flag(review_notes, "second_label_halo_still_competes", true):
		issues.append(_issue("second_label_halo_still_competes", "Welt-Fire-Label oder Target-Halo konkurrieren weiterhin mit der TASK_945-Lane."))
	if not bool(review_notes.get("second_grid_world_noise_not_competing", false)) and _review_flag(review_notes, "second_grid_world_noise_still_competes", false):
		issues.append(_issue("second_grid_world_noise_still_competes", "Raster-/Weltlinien konkurrieren noch mit dem Feuerblick."))
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", false):
		issues.append(_issue("bottom_hud_still_dense_for_first_fire_read", "#17/#18/#19 sind korrekt, aber Bottom-HUD bleibt fuer den ersten Feuerblick dicht."))
	return issues


static func _capture_method(source_snapshot: Dictionary) -> String:
	return String(source_snapshot.get("second_capture_method", source_snapshot.get("second_window_capture_method", "")))


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	return bool(review_notes.get(key, default_value))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
