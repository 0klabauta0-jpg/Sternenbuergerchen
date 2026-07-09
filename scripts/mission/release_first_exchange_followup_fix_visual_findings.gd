class_name ReleaseFirstExchangeFollowupFixVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_visual_findings.v1"
const TASK_ID: String = "TASK_934"
const SOURCE_TASK_ID: String = "TASK_933"
const SOURCE_FOLLOWUP_FIX_TASK_ID: String = "TASK_932"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_931"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_930"
const SOURCE_FINAL_READABILITY_TASK_ID: String = "TASK_929"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_recapture.v1"
const EXPECTED_FOLLOWUP_FIX_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_readability_followup_fix.v1"
const EXPECTED_FOLLOWUP_FIX_STYLE_ID: String = "task_932_release_first_exchange_final_readability_followup_v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_readability_visual_findings.v1"
const EXPECTED_FINAL_READABILITY_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning_final_readability_polish.v1"
const EXPECTED_FINAL_READABILITY_STYLE_ID: String = "task_929_release_first_exchange_followup_player_polish_tuning_final_readability_v1"
const EXPECTED_SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_readability_recapture.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK: String = "TASK_935 - Release First Exchange Playability Smoke"
const NEXT_FIX_TASK: String = "TASK_935 - Release First Exchange Followup Fix Player Polish"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var final_source: Dictionary = Dictionary(source_snapshot.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(source_snapshot.get("followup_fix_world_read_render_review", {}))
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
			status = "ready_for_followup_fix_player_polish"
	var recommended_next: String = NEXT_SMOKE_TASK if accepted else NEXT_FIX_TASK
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_followup_fix_task_id": SOURCE_FOLLOWUP_FIX_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_final_readability_task_id": SOURCE_FINAL_READABILITY_TASK_ID,
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
		"expected_followup_fix_schema": String(source_snapshot.get("expected_followup_fix_schema", "")),
		"expected_followup_fix_style_id": String(source_snapshot.get("expected_followup_fix_style_id", "")),
		"expected_findings_schema": String(source_snapshot.get("expected_findings_schema", "")),
		"expected_final_readability_schema": String(source_snapshot.get("expected_final_readability_schema", "")),
		"expected_final_readability_style_id": String(source_snapshot.get("expected_final_readability_style_id", "")),
		"source_recapture_schema": String(source_snapshot.get("source_recapture_schema", "")),
		"source_recapture_gate": String(source_snapshot.get("source_recapture_gate", "")),
		"window_screenshot_path": String(source_snapshot.get("followup_fix_window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("followup_fix_desktop_screenshot_path", "")),
		"window_capture_method": String(source_snapshot.get("followup_fix_capture_method", source_snapshot.get("followup_fix_window_capture_method", ""))),
		"window_capture_trusted": bool(source_snapshot.get("followup_fix_window_capture_trusted", false)),
		"followup_fix_capture_after_deeplink_final": bool(source_snapshot.get("followup_fix_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"source_followup_fix_snapshot": Dictionary(source_snapshot.get("source_followup_fix_snapshot", {})),
		"source_final_readability_findings_snapshot": Dictionary(source_snapshot.get("source_final_readability_findings_snapshot", {})),
		"source_final_readability_recapture_review": Dictionary(source_snapshot.get("source_final_readability_recapture_review", {})),
		"followup_fix_world_read_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"correct_window_content_confirmed": correct_window_confirmed,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", source_snapshot.get("followup_fix_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"followup_fix_visible": bool(review_notes.get("followup_fix_visible", false)),
		"followup_fix_fire_lane_is_first_world_movement": bool(review_notes.get("followup_fix_fire_lane_is_first_world_movement", false)),
		"followup_fix_lane_reads_before_fire_contact_text": bool(review_notes.get("followup_fix_lane_reads_before_fire_contact_text", false)),
		"followup_fix_source_target_anchors_carry_direction": bool(review_notes.get("followup_fix_source_target_anchors_carry_direction", false)),
		"followup_fix_anchors_do_not_read_as_discs": bool(review_notes.get("followup_fix_anchors_do_not_read_as_discs", false)),
		"followup_fix_world_fire_label_stays_behind_lane": bool(review_notes.get("followup_fix_world_fire_label_stays_behind_lane", false)),
		"followup_fix_target_halo_stays_behind_lane": bool(review_notes.get("followup_fix_target_halo_stays_behind_lane", false)),
		"followup_fix_grid_world_noise_not_competing": bool(review_notes.get("followup_fix_grid_world_noise_not_competing", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"positive_findings": _build_positive_findings(source_snapshot, review_notes, final_contact_fire),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": recommended_next,
		"recommended_direction": "move_to_playability_smoke_if_accepted_else_followup_fix_player_polish",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_933-Snapshot/Manifest-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_933."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_FOLLOWUP_FIX_TASK_ID:
		blockers.append(_issue("source_followup_fix_task_mismatch", "Quelle nennt nicht TASK_932 als Follow-up-Fix."))
	if String(source_snapshot.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Quelle nennt nicht TASK_931 als Findings-Basis."))
	if String(source_snapshot.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Quelle nennt nicht TASK_930 als Recapture-Basis."))
	if String(source_snapshot.get("source_final_readability_task_id", "")) != SOURCE_FINAL_READABILITY_TASK_ID:
		blockers.append(_issue("source_final_readability_task_mismatch", "Quelle nennt nicht TASK_929 als Final-Readability-Basis."))
	if String(source_snapshot.get("expected_followup_fix_schema", "")) != EXPECTED_FOLLOWUP_FIX_SCHEMA:
		blockers.append(_issue("followup_fix_schema_mismatch", "TASK_932-Follow-up-Fix-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_followup_fix_style_id", "")) != EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		blockers.append(_issue("followup_fix_style_mismatch", "TASK_932-Follow-up-Fix-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_findings_schema", "")) != EXPECTED_FINDINGS_SCHEMA:
		blockers.append(_issue("findings_schema_mismatch", "TASK_931-Findings-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_final_readability_schema", "")) != EXPECTED_FINAL_READABILITY_SCHEMA:
		blockers.append(_issue("final_readability_schema_mismatch", "TASK_929-Final-Readability-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_final_readability_style_id", "")) != EXPECTED_FINAL_READABILITY_STYLE_ID:
		blockers.append(_issue("final_readability_style_mismatch", "TASK_929-Final-Readability-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("source_recapture_schema", "")) != EXPECTED_SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_930-Recapture-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Quelle nutzt nicht den First-GO-Firefight-Deep-Link."))
	var source_status: String = String(source_snapshot.get("status", source_snapshot.get("gate", "")))
	if not source_status in ["review_ready", "accepted", "review"]:
		blockers.append(_issue("source_not_review_ready", "TASK_933-Quelle ist nicht review-ready."))
	if not bool(source_snapshot.get("followup_fix_capture_after_deeplink_final", false)):
		blockers.append(_issue("followup_fix_capture_not_after_trace", "Follow-up-Fix-Capture wurde nicht nach deeplink_final markiert."))
	var capture_method: String = String(source_snapshot.get("followup_fix_capture_method", source_snapshot.get("followup_fix_window_capture_method", "")))
	if capture_method != "window_handle_print":
		blockers.append(_issue("window_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(source_snapshot.get("followup_fix_window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if String(source_snapshot.get("followup_fix_window_screenshot_path", "")) == "":
		blockers.append(_issue("window_screenshot_path_missing", "TASK_933-Window-Screenshotpfad fehlt."))
	return blockers


static func _build_positive_findings(source_snapshot: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	var capture_method: String = String(source_snapshot.get("followup_fix_capture_method", source_snapshot.get("followup_fix_window_capture_method", "")))
	if capture_method == "window_handle_print" and bool(source_snapshot.get("followup_fix_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der TASK_933-Screenshot kommt vom Ziel-Window-Handle."})
	if String(source_snapshot.get("expected_followup_fix_style_id", "")) == EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		positives.append({"id": "task_932_followup_fix_style_present", "text": "Der TASK_932-Follow-up-Fix-Style ist als erwartete Weltbildquelle belegt."})
	if String(source_snapshot.get("expected_final_readability_style_id", "")) == EXPECTED_FINAL_READABILITY_STYLE_ID:
		positives.append({"id": "task_929_final_readability_style_present", "text": "Die TASK_929-Final-Readability-Basis bleibt im Snapshot nachvollziehbar."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log bestaetigt CONTACT FIRE ohne den Review zu blockieren."})
	if bool(review_notes.get("followup_fix_visible", false)):
		positives.append({"id": "followup_fix_visible", "text": "Der TASK_932-Follow-up-Fix-Style ist im echten Fenster sichtbar."})
	if bool(review_notes.get("followup_fix_fire_lane_is_first_world_movement", false)):
		positives.append({"id": "followup_fix_fire_lane_is_first_world_movement", "text": "Die Follow-up-Fix-Fire-Lane liest sich als erste Weltbewegung im Feuerwechsel."})
	if bool(review_notes.get("followup_fix_lane_reads_before_fire_contact_text", false)):
		positives.append({"id": "followup_fix_lane_reads_before_fire_contact_text", "text": "Die Follow-up-Fix-Lane wird vor FIRE/CONTACT-Text und Zielcluster gelesen."})
	if bool(review_notes.get("followup_fix_source_target_anchors_carry_direction", false)):
		positives.append({"id": "followup_fix_source_target_anchors_carry_direction", "text": "Follow-up-Fix-Source-/Target-Anker tragen die Schussrichtung."})
	if bool(review_notes.get("followup_fix_anchors_do_not_read_as_discs", false)):
		positives.append({"id": "followup_fix_anchors_do_not_read_as_discs", "text": "Follow-up-Fix-Anker tragen Richtung ohne scheibenhaft zu wirken."})
	if bool(review_notes.get("followup_fix_world_fire_label_stays_behind_lane", false)):
		positives.append({"id": "followup_fix_world_fire_label_stays_behind_lane", "text": "Das Welt-Fire-Label bleibt hinter der Follow-up-Fix-Lane."})
	if bool(review_notes.get("followup_fix_target_halo_stays_behind_lane", false)):
		positives.append({"id": "followup_fix_target_halo_stays_behind_lane", "text": "Der Target-Halo bleibt hinter der Follow-up-Fix-Lane."})
	if bool(review_notes.get("followup_fix_grid_world_noise_not_competing", false)):
		positives.append({"id": "followup_fix_grid_world_noise_not_competing", "text": "Raster-/Welt-Rauschen konkurriert nicht als primaerer Blickfang."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den naechsten Smoke."})
	return positives


static func _build_issues(review_notes: Dictionary, final_contact_fire: bool, manual_review_done: bool, correct_window_confirmed: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_visual_review_missing", "TASK_934 braucht einen Sichtbefund zum TASK_933-PNG/Snapshot."))
		return issues
	if not correct_window_confirmed:
		issues.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	if _review_flag(review_notes, "followup_fix_fire_lane_not_first_world_movement", true):
		issues.append(_issue("followup_fix_fire_lane_not_first_world_movement", "Die Follow-up-Fix-Fire-Lane ist noch nicht sicher die erste Weltbewegung."))
	if _review_flag(review_notes, "followup_fix_lane_not_before_fire_contact_text", true):
		issues.append(_issue("followup_fix_lane_not_before_fire_contact_text", "FIRE/CONTACT-Text oder Zielcluster ziehen noch vor der Follow-up-Fix-Lane."))
	if _review_flag(review_notes, "followup_fix_source_target_anchors_still_weak", false):
		issues.append(_issue("followup_fix_source_target_anchors_still_weak", "Follow-up-Fix-Source-/Target-Anker tragen die Richtung noch nicht sicher genug."))
	if _review_flag(review_notes, "followup_fix_anchors_read_as_discs", false):
		issues.append(_issue("followup_fix_anchors_read_as_discs", "Follow-up-Fix-Anker wirken zu scheibenhaft statt richtungsfuehrend."))
	if _review_flag(review_notes, "followup_fix_label_halo_still_competes", true):
		issues.append(_issue("followup_fix_label_halo_still_competes", "Welt-Fire-Label oder Target-Halo konkurrieren weiterhin mit der Follow-up-Fix-Lane."))
	if _review_flag(review_notes, "followup_fix_grid_world_noise_still_competes", false):
		issues.append(_issue("followup_fix_grid_world_noise_still_competes", "Raster-/Weltlinien konkurrieren noch mit dem Feuerblick."))
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", false):
		issues.append(_issue("bottom_hud_still_dense_for_first_fire_read", "#17/#18/#19 sind korrekt, aber Bottom-HUD bleibt fuer den ersten Feuerblick dicht."))
	return issues


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	return bool(review_notes.get(key, default_value))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
