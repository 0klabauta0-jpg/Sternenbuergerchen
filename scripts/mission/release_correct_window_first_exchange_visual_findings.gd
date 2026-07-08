class_name ReleaseCorrectWindowFirstExchangeVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_correct_window_first_exchange_visual_findings.v1"
const TASK_ID: String = "TASK_872"
const SOURCE_TASK_ID: String = "TASK_869"
const SOURCE_CAPTURE_FIX_TASK_ID: String = "TASK_871"
const SOURCE_LOS_SETUP_TASK_ID: String = "TASK_868"
const SOURCE_STATUS_RECAPTURE_TASK_ID: String = "TASK_866"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_los_setup_real_window_recapture.v1"
const EXPECTED_LOS_SETUP_STYLE_ID: String = "task_868_release_first_exchange_los_setup_polish_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_873 - Release First Exchange CONTACT-FIRE Readability Fix"


static func build_snapshot(recapture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var recapture_schema: String = String(recapture_manifest.get("schema", "")).strip_edges()
	var recapture_task_id: String = String(recapture_manifest.get("task_id", "")).strip_edges()
	var source_task_id: String = String(recapture_manifest.get("source_task_id", "")).strip_edges()
	var source_status_recapture_task_id: String = String(recapture_manifest.get("source_status_recapture_task_id", "")).strip_edges()
	var source_exchange_task_id: String = String(recapture_manifest.get("source_exchange_task_id", "")).strip_edges()
	var launch_argument: String = String(recapture_manifest.get("launch_argument", "")).strip_edges()
	var capture_gate: String = String(recapture_manifest.get("gate", "")).strip_edges()
	var visible_window_gate: String = String(recapture_manifest.get("visible_window_gate", "")).strip_edges()
	var window_screenshot_written: bool = bool(recapture_manifest.get("window_screenshot_written", false))
	var window_capture_method: String = String(recapture_manifest.get("window_capture_method", "")).strip_edges()
	var window_capture_trusted: bool = bool(recapture_manifest.get("window_capture_trusted", false))
	var window_handle_capture_succeeded: bool = bool(recapture_manifest.get("window_handle_capture_succeeded", false))
	var window_crop_trusted: bool = bool(recapture_manifest.get("window_crop_trusted", false))
	var window_focus_succeeded: bool = bool(recapture_manifest.get("window_focus_succeeded", false))
	var foreground_matches_selected_process: bool = bool(recapture_manifest.get("foreground_matches_selected_process", false))
	var expected_los_setup_style_id: String = String(recapture_manifest.get("expected_los_setup_style_id", "")).strip_edges()
	var manual_notes_present: bool = not review_notes.is_empty()
	var correct_window_content_confirmed: bool = bool(review_notes.get("correct_window_content_confirmed", false))
	var manual_visual_review_done: bool = bool(review_notes.get("manual_visual_review_done", manual_notes_present))
	var blockers: Array = _build_blockers(
		recapture_schema,
		recapture_task_id,
		source_task_id,
		source_status_recapture_task_id,
		source_exchange_task_id,
		launch_argument,
		capture_gate,
		visible_window_gate,
		window_screenshot_written,
		window_capture_trusted,
		expected_los_setup_style_id,
		manual_notes_present,
		correct_window_content_confirmed
	)
	var positives: Array = _build_positive_findings(
		recapture_manifest,
		window_screenshot_written,
		window_capture_method,
		window_capture_trusted,
		window_handle_capture_succeeded,
		window_crop_trusted,
		window_focus_succeeded,
		foreground_matches_selected_process,
		correct_window_content_confirmed
	)
	var issues: Array = _build_issue_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "needs_manual_review"
	if status != "blocked" and manual_notes_present:
		status = "ready_for_contact_fire_readability_fix"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_capture_fix_task_id": SOURCE_CAPTURE_FIX_TASK_ID,
		"source_los_setup_task_id": SOURCE_LOS_SETUP_TASK_ID,
		"source_status_recapture_task_id": SOURCE_STATUS_RECAPTURE_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"recapture_schema": recapture_schema,
		"recapture_schema_ok": recapture_schema == EXPECTED_RECAPTURE_SCHEMA,
		"recapture_task_id": recapture_task_id,
		"capture_gate": capture_gate,
		"capture_reviewable": capture_gate == "review_ready" or capture_gate == "manual_open",
		"visible_window_gate": visible_window_gate,
		"visible_window_reviewable": visible_window_gate == "review_ready" or visible_window_gate == "manual_open",
		"launch_argument": launch_argument,
		"launch_argument_ok": launch_argument == FIRST_GO_ARG,
		"expected_los_setup_style_id": expected_los_setup_style_id,
		"los_setup_style_id_ok": expected_los_setup_style_id == EXPECTED_LOS_SETUP_STYLE_ID,
		"window_screenshot_written": window_screenshot_written,
		"window_screenshot_path": String(recapture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(recapture_manifest.get("desktop_screenshot_path", "")),
		"window_capture_method": window_capture_method,
		"window_capture_trusted": window_capture_trusted,
		"window_handle_capture_succeeded": window_handle_capture_succeeded,
		"window_crop_trusted": window_crop_trusted,
		"window_focus_succeeded": window_focus_succeeded,
		"foreground_process_id": int(recapture_manifest.get("foreground_process_id", 0)),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"foreground_matches_selected_process": foreground_matches_selected_process,
		"manual_review_required": true,
		"manual_visual_review_done": manual_visual_review_done,
		"manual_notes_present": manual_notes_present,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"correct_window_content_confirmed": correct_window_content_confirmed,
		"selected_fireteam_primary_reading": String(review_notes.get("selected_fireteam_primary_reading", "")),
		"mission_control_primary_reading": String(review_notes.get("mission_control_primary_reading", "")),
		"event_log_primary_reading": String(review_notes.get("event_log_primary_reading", "")),
		"contact_fire_readability_ok": bool(review_notes.get("contact_fire_readability_ok", false)),
		"fire_trace_or_impact_visible": bool(review_notes.get("fire_trace_or_impact_visible", false)),
		"expected_window_content": "Sternenbuergerchen mission first exchange with player-readable CONTACT FIRE or clear blocked-fire reason",
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "fix_first_exchange_contact_fire_readability_on_correct_release_window",
		"avoid_next_action": "do_not_mask_no_los_with_contact_fire_text_without_runtime_evidence",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_positive_findings(
	recapture_manifest: Dictionary,
	window_screenshot_written: bool,
	window_capture_method: String,
	window_capture_trusted: bool,
	window_handle_capture_succeeded: bool,
	window_crop_trusted: bool,
	window_focus_succeeded: bool,
	foreground_matches_selected_process: bool,
	correct_window_content_confirmed: bool
) -> Array:
	var positives: Array = []
	if String(recapture_manifest.get("source_task_id", "")) == SOURCE_LOS_SETUP_TASK_ID:
		positives.append({"id": "task_868_los_setup_source_recorded", "text": "TASK_869 haelt TASK_868 als LOS-Setup-Quelle fest."})
	if String(recapture_manifest.get("launch_argument", "")) == FIRST_GO_ARG:
		positives.append({"id": "first_go_firefight_deeplink_recorded", "text": "Das Manifest bestaetigt den First-GO-Firefight-Deep-Link."})
	if window_screenshot_written:
		positives.append({"id": "window_screenshot_written", "text": "Ein Fenster-Screenshot wurde geschrieben."})
	if window_capture_method == "window_handle_print" and window_capture_trusted and window_handle_capture_succeeded:
		positives.append({"id": "window_handle_capture_trusted", "text": "Der Fensterbeweis kommt vom Ziel-Window-Handle und ist trusted."})
	elif window_crop_trusted:
		positives.append({"id": "desktop_crop_fallback_trusted", "text": "Der Desktop-Crop-Fallback ist als trusted markiert."})
	if window_focus_succeeded and foreground_matches_selected_process:
		positives.append({"id": "foreground_process_matches_release_process", "text": "Fokus- und Foreground-Evidence zeigen auf den ausgewaehlten Release-Prozess."})
	if correct_window_content_confirmed:
		positives.append({"id": "sternenbuergerchen_mission_window_confirmed", "text": "Der manuelle Sichtblick bestaetigt das Sternenbuergerchen-Missionsfenster."})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "correct_window_first_exchange_still_no_los", true):
		issues.append({
			"id": "correct_window_first_exchange_still_no_los",
			"severity": "release_readability_blocker",
			"text": "Im korrekten Sternenbuergerchen-Fenster dominiert weiter NO_FIRE/NO_LOS statt eine klare First-Exchange-Lesung.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_contact_pressure_still_dominates", true):
		issues.append({
			"id": "event_log_contact_pressure_still_dominates",
			"severity": "player_feedback_confusing",
			"text": "Das Event-Log liest weiterhin CONTACT PRESSURE / Position korrigieren statt CONTACT FIRE oder einer klaren Blockade-Erklaerung.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "contact_fire_not_yet_player_readable", true):
		issues.append({
			"id": "contact_fire_not_yet_player_readable",
			"severity": "release_readability_blocker",
			"text": "Der erste Feuerkontakt ist im echten Fenster noch nicht als CONTACT FIRE / FireTrace / Impact lesbar.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "fire_trace_or_impact_not_visible", true):
		issues.append({
			"id": "fire_trace_or_impact_not_visible",
			"severity": "visual_feedback_gap",
			"text": "FireTrace, Impact oder Target-Fokus sind im sichtbaren First-Exchange nicht ausreichend belegbar.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _build_blockers(
	recapture_schema: String,
	recapture_task_id: String,
	source_task_id: String,
	source_status_recapture_task_id: String,
	source_exchange_task_id: String,
	launch_argument: String,
	capture_gate: String,
	visible_window_gate: String,
	window_screenshot_written: bool,
	window_capture_trusted: bool,
	expected_los_setup_style_id: String,
	manual_notes_present: bool,
	correct_window_content_confirmed: bool
) -> Array:
	var blockers: Array = []
	if recapture_schema != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append({"id": "recapture_schema_mismatch", "text": "TASK_869-Recapture-Schema fehlt oder passt nicht."})
	if recapture_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "recapture_task_mismatch", "text": "Manifest nennt nicht TASK_869 als Quelle."})
	if source_task_id != SOURCE_LOS_SETUP_TASK_ID:
		blockers.append({"id": "source_los_setup_mismatch", "text": "Manifest nennt nicht TASK_868 als LOS-Setup-Quelle."})
	if source_status_recapture_task_id != SOURCE_STATUS_RECAPTURE_TASK_ID:
		blockers.append({"id": "source_status_recapture_mismatch", "text": "Manifest nennt nicht TASK_866 als Status-Recapture-Quelle."})
	if source_exchange_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append({"id": "source_exchange_mismatch", "text": "Manifest nennt nicht TASK_844 als Exchange-Quelle."})
	if launch_argument != FIRST_GO_ARG:
		blockers.append({"id": "launch_argument_mismatch", "text": "Manifest nennt nicht den First-GO-Firefight-Deep-Link."})
	if capture_gate != "review_ready" and capture_gate != "manual_open":
		blockers.append({"id": "capture_not_review_ready", "text": "TASK_869-Capture ist nicht review_ready/manual_open."})
	if visible_window_gate != "review_ready" and visible_window_gate != "manual_open":
		blockers.append({"id": "visible_window_not_review_ready", "text": "Visible-Window-Capture ist nicht review_ready/manual_open."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if not window_capture_trusted:
		blockers.append({"id": "window_capture_not_trusted", "text": "Der Fensterbeweis ist nach TASK_871 nicht trusted."})
	if expected_los_setup_style_id != EXPECTED_LOS_SETUP_STYLE_ID:
		blockers.append({"id": "los_setup_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_868-Style-ID."})
	if manual_notes_present and not correct_window_content_confirmed:
		blockers.append({"id": "correct_window_content_not_confirmed", "text": "Der manuelle Sichtblick bestaetigt kein Sternenbuergerchen-Missionsfenster."})
	return blockers


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value
