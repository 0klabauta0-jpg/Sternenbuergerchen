class_name ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
const TASK_ID: String = "TASK_944"
const SOURCE_TASK_ID: String = "TASK_943"
const SOURCE_FOLLOWUP_FIX_TASK_ID: String = "TASK_942"
const SOURCE_GATE_TASK_ID: String = "TASK_941"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_940"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_939"
const BASE_FINAL_TUNING_TASK_ID: String = "TASK_938"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.v1"
const EXPECTED_FOLLOWUP_FIX_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const EXPECTED_FOLLOWUP_FIX_STYLE_ID: String = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const EXPECTED_GATE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_tuning_playability_smoke_gate.v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.v1"
const EXPECTED_SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_recapture.v1"
const EXPECTED_BASE_FINAL_TUNING_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning.v1"
const EXPECTED_BASE_FINAL_TUNING_STYLE_ID: String = "task_938_release_first_exchange_followup_fix_player_polish_final_tuning_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK: String = "TASK_945 - Release First Exchange Playability Smoke"
const NEXT_FIX_TASK: String = "TASK_945 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Fix"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var final_source: Dictionary = Dictionary(source_snapshot.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(source_snapshot.get("followup_world_read_render_review", {}))
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
			status = "ready_for_followup_fix_player_polish_final_tuning_followup_second_fix"
	var recommended_next: String = NEXT_SMOKE_TASK if accepted else NEXT_FIX_TASK
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_followup_fix_task_id": SOURCE_FOLLOWUP_FIX_TASK_ID,
		"source_gate_task_id": SOURCE_GATE_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"base_final_tuning_task_id": BASE_FINAL_TUNING_TASK_ID,
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
		"expected_gate_schema": String(source_snapshot.get("expected_gate_schema", "")),
		"expected_findings_schema": String(source_snapshot.get("expected_findings_schema", "")),
		"source_recapture_schema": String(source_snapshot.get("source_recapture_schema", "")),
		"expected_base_final_tuning_schema": String(source_snapshot.get("expected_base_final_tuning_schema", "")),
		"expected_base_final_tuning_style_id": String(source_snapshot.get("expected_base_final_tuning_style_id", "")),
		"source_recapture_gate": String(source_snapshot.get("source_recapture_gate", "")),
		"window_screenshot_path": String(source_snapshot.get("followup_window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_snapshot.get("followup_desktop_screenshot_path", "")),
		"window_capture_method": _capture_method(source_snapshot),
		"window_capture_trusted": bool(source_snapshot.get("followup_window_capture_trusted", false)),
		"followup_capture_after_deeplink_final": bool(source_snapshot.get("followup_capture_after_deeplink_final", false)),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"source_followup_fix_snapshot": Dictionary(source_snapshot.get("source_followup_fix_snapshot", {})),
		"source_gate_snapshot": Dictionary(source_snapshot.get("source_gate_snapshot", {})),
		"source_findings_snapshot": Dictionary(source_snapshot.get("source_findings_snapshot", {})),
		"source_recapture_review": Dictionary(source_snapshot.get("source_recapture_review", {})),
		"source_base_final_tuning_snapshot": Dictionary(source_snapshot.get("source_base_final_tuning_snapshot", {})),
		"followup_world_read_render_review": render_review,
		"manual_visual_review_done": manual_review_done,
		"correct_window_content_confirmed": correct_window_confirmed,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"review_screenshot_path": String(review_notes.get("review_screenshot_path", source_snapshot.get("followup_window_screenshot_path", ""))),
		"player_readability_ok": accepted,
		"contact_fire_hud_surfaces_present": bool(review_notes.get("contact_fire_hud_surfaces_present", false)),
		"event_log_contact_fire_visible": bool(review_notes.get("event_log_contact_fire_visible", false)),
		"followup_visible": bool(review_notes.get("followup_visible", false)),
		"followup_fire_lane_is_first_world_movement": bool(review_notes.get("followup_fire_lane_is_first_world_movement", false)),
		"followup_lane_reads_before_fire_contact_text": bool(review_notes.get("followup_lane_reads_before_fire_contact_text", false)),
		"followup_source_target_anchors_carry_direction": bool(review_notes.get("followup_source_target_anchors_carry_direction", false)),
		"followup_anchors_do_not_read_as_discs": bool(review_notes.get("followup_anchors_do_not_read_as_discs", false)),
		"followup_world_fire_label_stays_behind_lane": bool(review_notes.get("followup_world_fire_label_stays_behind_lane", false)),
		"followup_target_halo_stays_behind_lane": bool(review_notes.get("followup_target_halo_stays_behind_lane", false)),
		"followup_grid_world_noise_not_competing": bool(review_notes.get("followup_grid_world_noise_not_competing", false)),
		"command_surfaces_still_usable": bool(review_notes.get("command_surfaces_still_usable", false)),
		"positive_findings": _build_positive_findings(source_snapshot, review_notes, final_contact_fire),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": recommended_next,
		"recommended_direction": "move_to_playability_smoke_if_accepted_else_followup_second_fix",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_943-Snapshot/Manifest-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Quelle nennt nicht TASK_943."))
	if String(source_snapshot.get("source_task_id", "")) != SOURCE_FOLLOWUP_FIX_TASK_ID:
		blockers.append(_issue("source_followup_fix_task_mismatch", "Quelle nennt nicht TASK_942 als Followup-Fix."))
	if String(source_snapshot.get("source_gate_task_id", "")) != SOURCE_GATE_TASK_ID:
		blockers.append(_issue("source_gate_task_mismatch", "Quelle nennt nicht TASK_941 als Gate."))
	if String(source_snapshot.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Quelle nennt nicht TASK_940 als Findings-Basis."))
	if String(source_snapshot.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Quelle nennt nicht TASK_939 als Recapture-Basis."))
	if String(source_snapshot.get("base_final_tuning_task_id", "")) != BASE_FINAL_TUNING_TASK_ID:
		blockers.append(_issue("base_final_tuning_task_mismatch", "Quelle nennt nicht TASK_938 als Final-Tuning-Basis."))
	if String(source_snapshot.get("expected_followup_fix_schema", "")) != EXPECTED_FOLLOWUP_FIX_SCHEMA:
		blockers.append(_issue("followup_fix_schema_mismatch", "TASK_942-Followup-Fix-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_followup_fix_style_id", "")) != EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		blockers.append(_issue("followup_fix_style_mismatch", "TASK_942-Followup-Fix-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_gate_schema", "")) != EXPECTED_GATE_SCHEMA:
		blockers.append(_issue("gate_schema_mismatch", "TASK_941-Gate-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_findings_schema", "")) != EXPECTED_FINDINGS_SCHEMA:
		blockers.append(_issue("findings_schema_mismatch", "TASK_940-Findings-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("source_recapture_schema", "")) != EXPECTED_SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_939-Recapture-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_base_final_tuning_schema", "")) != EXPECTED_BASE_FINAL_TUNING_SCHEMA:
		blockers.append(_issue("base_final_tuning_schema_mismatch", "TASK_938-Final-Tuning-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("expected_base_final_tuning_style_id", "")) != EXPECTED_BASE_FINAL_TUNING_STYLE_ID:
		blockers.append(_issue("base_final_tuning_style_mismatch", "TASK_938-Final-Tuning-Style fehlt oder passt nicht."))
	if String(source_snapshot.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Quelle nutzt nicht den First-GO-Firefight-Deep-Link."))
	var source_status: String = String(source_snapshot.get("status", source_snapshot.get("gate", "")))
	if not source_status in ["review_ready", "accepted", "review"]:
		blockers.append(_issue("source_not_review_ready", "TASK_943-Quelle ist nicht review-ready."))
	if not bool(source_snapshot.get("followup_capture_after_deeplink_final", false)):
		blockers.append(_issue("followup_capture_not_after_trace", "Followup-Capture wurde nicht nach deeplink_final markiert."))
	if _capture_method(source_snapshot) != "window_handle_print":
		blockers.append(_issue("followup_capture_method_not_handle_print", "Capture nutzt nicht Window-Handle-Print."))
	if not bool(source_snapshot.get("followup_window_capture_trusted", false)):
		blockers.append(_issue("followup_window_capture_not_trusted", "Window-Capture ist nicht trusted."))
	if String(source_snapshot.get("followup_window_screenshot_path", "")) == "":
		blockers.append(_issue("window_screenshot_path_missing", "TASK_943-Window-Screenshotpfad fehlt."))
	return blockers


static func _build_positive_findings(source_snapshot: Dictionary, review_notes: Dictionary, final_contact_fire: bool) -> Array:
	var positives: Array = []
	if final_contact_fire:
		positives.append({"id": "final_source_contact_fire_clean", "text": "Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 ohne CONTACT PRESSURE."})
	if _capture_method(source_snapshot) == "window_handle_print" and bool(source_snapshot.get("followup_window_capture_trusted", false)):
		positives.append({"id": "trusted_window_handle_capture", "text": "Der TASK_943-Screenshot kommt vom Ziel-Window-Handle."})
	if String(source_snapshot.get("expected_followup_fix_style_id", "")) == EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		positives.append({"id": "task_942_followup_fix_style_present", "text": "Der TASK_942-Followup-Fix-Style ist als erwartete Weltbildquelle belegt."})
	if String(source_snapshot.get("expected_gate_schema", "")) == EXPECTED_GATE_SCHEMA:
		positives.append({"id": "task_941_gate_present", "text": "Das TASK_941-Smoke-Gate bleibt als Quelle nachvollziehbar."})
	if String(source_snapshot.get("expected_findings_schema", "")) == EXPECTED_FINDINGS_SCHEMA:
		positives.append({"id": "task_940_findings_present", "text": "Der TASK_940-Findings-Schnitt bleibt als Ausloeser dokumentiert."})
	if String(source_snapshot.get("expected_base_final_tuning_style_id", "")) == EXPECTED_BASE_FINAL_TUNING_STYLE_ID:
		positives.append({"id": "task_938_base_final_tuning_style_present", "text": "Die TASK_938-Final-Tuning-Basis bleibt im Snapshot nachvollziehbar."})
	if bool(review_notes.get("contact_fire_hud_surfaces_present", false)):
		positives.append({"id": "contact_fire_hud_surfaces_present", "text": "#17 Selected Fireteam, #18 Mission Control und #19 Event Log zeigen CONTACT FIRE im Spielerblick."})
	if bool(review_notes.get("event_log_contact_fire_visible", false)):
		positives.append({"id": "event_log_contact_fire_visible", "text": "#19 Event Log bestaetigt CONTACT FIRE ohne den Review zu blockieren."})
	if bool(review_notes.get("followup_visible", false)):
		positives.append({"id": "followup_visible", "text": "Der TASK_942-Followup-Style ist im echten Fenster sichtbar."})
	if bool(review_notes.get("followup_fire_lane_is_first_world_movement", false)):
		positives.append({"id": "followup_fire_lane_is_first_world_movement", "text": "Die Followup-Fire-Lane liest sich als erste Weltbewegung im Feuerwechsel."})
	if bool(review_notes.get("followup_lane_reads_before_fire_contact_text", false)):
		positives.append({"id": "followup_lane_reads_before_fire_contact_text", "text": "Die Followup-Lane wird vor FIRE/CONTACT-Text und Zielcluster gelesen."})
	if bool(review_notes.get("followup_source_target_anchors_carry_direction", false)):
		positives.append({"id": "followup_source_target_anchors_carry_direction", "text": "Followup-Source-/Target-Anker tragen die Schussrichtung."})
	if bool(review_notes.get("followup_anchors_do_not_read_as_discs", false)):
		positives.append({"id": "followup_anchors_do_not_read_as_discs", "text": "Followup-Anker tragen Richtung ohne scheibenhaft zu wirken."})
	if bool(review_notes.get("followup_world_fire_label_stays_behind_lane", false)):
		positives.append({"id": "followup_world_fire_label_stays_behind_lane", "text": "Das Welt-Fire-Label bleibt hinter der Followup-Lane."})
	if bool(review_notes.get("followup_target_halo_stays_behind_lane", false)):
		positives.append({"id": "followup_target_halo_stays_behind_lane", "text": "Der Target-Halo bleibt hinter der Followup-Lane."})
	if bool(review_notes.get("followup_grid_world_noise_not_competing", false)):
		positives.append({"id": "followup_grid_world_noise_not_competing", "text": "Raster-/Welt-Rauschen konkurriert nicht als primaerer Blickfang."})
	if bool(review_notes.get("command_surfaces_still_usable", false)):
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 bleiben sichtbar und bedienbar genug fuer den naechsten Smoke."})
	return positives


static func _build_issues(review_notes: Dictionary, final_contact_fire: bool, manual_review_done: bool, correct_window_confirmed: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_followup_visual_review_missing", "TASK_944 braucht einen Sichtbefund zum TASK_943-PNG/Snapshot."))
		return issues
	if not correct_window_confirmed:
		issues.append(_issue("correct_window_content_not_confirmed", "Sternenbuergerchen-Missionsfenster wurde nicht bestaetigt."))
	if _review_flag(review_notes, "followup_fire_lane_not_first_world_movement", true):
		issues.append(_issue("followup_fire_lane_not_first_world_movement", "Die Followup-Fire-Lane ist noch nicht sicher die erste Weltbewegung."))
	if _review_flag(review_notes, "followup_lane_not_before_fire_contact_text", true):
		issues.append(_issue("followup_lane_not_before_fire_contact_text", "FIRE/CONTACT-Text oder Zielcluster ziehen noch vor der Followup-Lane."))
	if _review_flag(review_notes, "followup_source_target_anchors_still_weak", false):
		issues.append(_issue("followup_source_target_anchors_still_weak", "Followup-Source-/Target-Anker tragen die Richtung noch nicht sicher genug."))
	if _review_flag(review_notes, "followup_anchors_read_as_discs", false):
		issues.append(_issue("followup_anchors_read_as_discs", "Followup-Anker wirken zu scheibenhaft statt richtungsfuehrend."))
	if _review_flag(review_notes, "followup_label_halo_still_competes", true):
		issues.append(_issue("followup_label_halo_still_competes", "Welt-Fire-Label oder Target-Halo konkurrieren weiterhin mit der Followup-Lane."))
	if _review_flag(review_notes, "followup_grid_world_noise_still_competes", false):
		issues.append(_issue("followup_grid_world_noise_still_competes", "Raster-/Weltlinien konkurrieren noch mit dem Feuerblick."))
	if _review_flag(review_notes, "bottom_hud_still_dense_for_first_fire_read", false):
		issues.append(_issue("bottom_hud_still_dense_for_first_fire_read", "#17/#18/#19 sind korrekt, aber Bottom-HUD bleibt fuer den ersten Feuerblick dicht."))
	return issues


static func _capture_method(source_snapshot: Dictionary) -> String:
	return String(source_snapshot.get("followup_capture_method", source_snapshot.get("followup_window_capture_method", "")))


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	return bool(review_notes.get(key, default_value))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
