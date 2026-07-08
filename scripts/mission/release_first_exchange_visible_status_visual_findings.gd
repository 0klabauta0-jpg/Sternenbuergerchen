class_name ReleaseFirstExchangeVisibleStatusVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_visual_findings.v1"
const TASK_ID: String = "TASK_878"
const SOURCE_TASK_ID: String = "TASK_877"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_874"
const SOURCE_READABILITY_TASK_ID: String = "TASK_873"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_recapture.v1"
const EXPECTED_VISIBLE_STATUS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
const EXPECTED_VISIBLE_STATUS_STYLE_ID: String = "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_879 - Release First Exchange Exported Status Source Trace"


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var capture_schema: String = String(capture_manifest.get("schema", "")).strip_edges()
	var capture_task_id: String = String(capture_manifest.get("task_id", "")).strip_edges()
	var source_task_id: String = String(capture_manifest.get("source_task_id", "")).strip_edges()
	var source_recapture_task_id: String = String(capture_manifest.get("source_recapture_task_id", "")).strip_edges()
	var source_readability_task_id: String = String(capture_manifest.get("source_readability_task_id", "")).strip_edges()
	var capture_gate: String = String(capture_manifest.get("gate", "")).strip_edges()
	var launch_argument: String = String(capture_manifest.get("launch_argument", "")).strip_edges()
	var expected_schema: String = String(capture_manifest.get("expected_visible_status_schema", "")).strip_edges()
	var expected_style_id: String = String(capture_manifest.get("expected_visible_status_style_id", "")).strip_edges()
	var window_screenshot_written: bool = bool(capture_manifest.get("window_screenshot_written", false))
	var window_capture_method: String = String(capture_manifest.get("window_capture_method", "")).strip_edges()
	var window_capture_trusted: bool = bool(capture_manifest.get("window_capture_trusted", false))
	var window_handle_capture_succeeded: bool = bool(capture_manifest.get("window_handle_capture_succeeded", false))
	var hard_failures: Array = Array(capture_manifest.get("hard_failures", []))
	var manual_notes_present: bool = not review_notes.is_empty()
	var manual_visual_review_done: bool = bool(review_notes.get("manual_visual_review_done", manual_notes_present))
	var correct_window_content_confirmed: bool = bool(review_notes.get("correct_window_content_confirmed", false))
	var command_surfaces_usable: bool = bool(review_notes.get("command_surfaces_still_usable", false))
	var blockers: Array = _build_blockers(
		capture_schema,
		capture_task_id,
		source_task_id,
		source_recapture_task_id,
		source_readability_task_id,
		capture_gate,
		launch_argument,
		expected_schema,
		expected_style_id,
		window_screenshot_written,
		window_capture_method,
		window_capture_trusted,
		window_handle_capture_succeeded,
		hard_failures,
		manual_notes_present,
		correct_window_content_confirmed
	)
	var positives: Array = _build_positive_findings(
		capture_manifest,
		window_screenshot_written,
		window_capture_method,
		window_capture_trusted,
		window_handle_capture_succeeded,
		correct_window_content_confirmed,
		command_surfaces_usable
	)
	var issues: Array = _build_issue_findings(review_notes)
	var status: String = "blocked" if not blockers.is_empty() else "needs_manual_review"
	if status != "blocked" and manual_visual_review_done:
		status = "ready_for_exported_status_source_trace"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_readability_task_id": SOURCE_READABILITY_TASK_ID,
		"capture_schema": capture_schema,
		"capture_schema_ok": capture_schema == EXPECTED_RECAPTURE_SCHEMA,
		"capture_task_id": capture_task_id,
		"capture_gate": capture_gate,
		"capture_reviewable": capture_gate == "review_ready" or capture_gate == "manual_open",
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": launch_argument,
		"launch_argument_ok": launch_argument == FIRST_GO_ARG,
		"expected_visible_status_schema": expected_schema,
		"expected_visible_status_style_id": expected_style_id,
		"visible_status_schema_ok": expected_schema == EXPECTED_VISIBLE_STATUS_SCHEMA,
		"visible_status_style_id_ok": expected_style_id == EXPECTED_VISIBLE_STATUS_STYLE_ID,
		"window_screenshot_written": window_screenshot_written,
		"window_screenshot_path": String(capture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("desktop_screenshot_path", "")),
		"window_capture_method": window_capture_method,
		"window_capture_trusted": window_capture_trusted,
		"window_handle_capture_succeeded": window_handle_capture_succeeded,
		"foreground_matches_selected_process": bool(capture_manifest.get("foreground_matches_selected_process", false)),
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
		"command_surfaces_still_usable": command_surfaces_usable,
		"expected_window_content": "Sternenbuergerchen first exchange with CONTACT FIRE in #17/#18/#19 after TASK_876",
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "trace_exported_runtime_status_source_activation_and_hud_refresh_override",
		"avoid_next_action": "do_not_add_more_contact_fire_text_until_exported_runtime_source_is_traced",
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


static func _build_positive_findings(
	capture_manifest: Dictionary,
	window_screenshot_written: bool,
	window_capture_method: String,
	window_capture_trusted: bool,
	window_handle_capture_succeeded: bool,
	correct_window_content_confirmed: bool,
	command_surfaces_usable: bool
) -> Array:
	var positives: Array = []
	if String(capture_manifest.get("source_task_id", "")) == SOURCE_VISIBLE_STATUS_TASK_ID:
		positives.append({"id": "task_876_status_source_recorded", "text": "TASK_877 haelt TASK_876 als erwartete sichtbare Statusquelle fest."})
	if String(capture_manifest.get("source_recapture_task_id", "")) == SOURCE_RECAPTURE_TASK_ID:
		positives.append({"id": "task_874_real_window_source_recorded", "text": "TASK_877 baut auf dem trusted Real-Window-Capture-Pfad auf."})
	if String(capture_manifest.get("launch_argument", "")) == FIRST_GO_ARG:
		positives.append({"id": "first_go_firefight_deeplink_recorded", "text": "Das Manifest bestaetigt den First-GO-Firefight-Deep-Link."})
	if window_screenshot_written:
		positives.append({"id": "window_screenshot_written", "text": "Ein Fenster-Screenshot wurde geschrieben."})
	if window_capture_method == "window_handle_print" and window_capture_trusted and window_handle_capture_succeeded:
		positives.append({"id": "window_handle_capture_trusted", "text": "Der Fensterbeweis kommt vom Ziel-Window-Handle und ist trusted."})
	if correct_window_content_confirmed:
		positives.append({"id": "sternenbuergerchen_mission_window_confirmed", "text": "Der manuelle Sichtblick bestaetigt das Sternenbuergerchen-Missionsfenster."})
	if command_surfaces_usable:
		positives.append({"id": "command_surfaces_still_usable", "text": "#16/#17/#18/#19 sind sichtbar genug, um den Befund auszuwerten."})
	return positives


static func _build_issue_findings(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "task_876_status_source_not_real_window_first_reading", true):
		issues.append({
			"id": "task_876_status_source_not_real_window_first_reading",
			"severity": "release_readability_blocker",
			"text": "TASK_876 ist headless gruen, aber im exportierten echten Fenster landet CONTACT FIRE nicht als #17/#18/#19-Erstlesung.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "selected_fireteam_still_no_los_first", true):
		issues.append({
			"id": "selected_fireteam_still_no_los_first",
			"severity": "player_feedback_confusing",
			"text": "#17 Selected Fireteam beginnt weiter mit NEXT LOS/RANGE KORRIGIEREN und Kampf NO FIRE NO_LOS.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "mission_control_still_no_los_first", true):
		issues.append({
			"id": "mission_control_still_no_los_first",
			"severity": "player_feedback_confusing",
			"text": "#18 Mission Control spiegelt weiter NO FIRE NO_LOS statt CONTACT FIRE.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "event_log_contact_pressure_still_dominates", true):
		issues.append({
			"id": "event_log_contact_pressure_still_dominates",
			"severity": "player_feedback_confusing",
			"text": "#19 Event Log nennt CONTACT PRESSURE / Position korrigieren statt CONTACT FIRE.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "fire_trace_or_impact_not_clear", true):
		issues.append({
			"id": "fire_trace_or_impact_not_clear",
			"severity": "visual_feedback_gap",
			"text": "FireTrace, Impact oder Target-Fokus sind im First-Exchange-Fenster nicht klar belegbar.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _build_blockers(
	capture_schema: String,
	capture_task_id: String,
	source_task_id: String,
	source_recapture_task_id: String,
	source_readability_task_id: String,
	capture_gate: String,
	launch_argument: String,
	expected_schema: String,
	expected_style_id: String,
	window_screenshot_written: bool,
	window_capture_method: String,
	window_capture_trusted: bool,
	window_handle_capture_succeeded: bool,
	hard_failures: Array,
	manual_notes_present: bool,
	correct_window_content_confirmed: bool
) -> Array:
	var blockers: Array = []
	if capture_schema != EXPECTED_RECAPTURE_SCHEMA:
		blockers.append({"id": "capture_schema_mismatch", "text": "TASK_877-Capture-Schema fehlt oder passt nicht."})
	if capture_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "capture_task_mismatch", "text": "Manifest nennt nicht TASK_877 als Quelle."})
	if source_task_id != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append({"id": "source_visible_status_mismatch", "text": "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."})
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append({"id": "source_recapture_mismatch", "text": "Manifest nennt nicht TASK_874 als Recapture-Quelle."})
	if source_readability_task_id != SOURCE_READABILITY_TASK_ID:
		blockers.append({"id": "source_readability_mismatch", "text": "Manifest nennt nicht TASK_873 als Readability-Quelle."})
	if capture_gate != "review_ready" and capture_gate != "manual_open":
		blockers.append({"id": "capture_not_review_ready", "text": "TASK_877-Capture ist weder review_ready noch manual_open."})
	if launch_argument != FIRST_GO_ARG:
		blockers.append({"id": "launch_argument_mismatch", "text": "Manifest nennt nicht den First-GO-Firefight-Deep-Link."})
	if not hard_failures.is_empty():
		blockers.append({"id": "capture_hard_failures", "text": "TASK_877-Capture meldet Hard-Failures."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
	if expected_schema != EXPECTED_VISIBLE_STATUS_SCHEMA:
		blockers.append({"id": "visible_status_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_876-Schema."})
	if expected_style_id != EXPECTED_VISIBLE_STATUS_STYLE_ID:
		blockers.append({"id": "visible_status_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_876-Style-ID."})
	if window_capture_method != "window_handle_print":
		blockers.append({"id": "window_capture_method_not_handle_print", "text": "Capture nutzt nicht den direkten Window-Handle-Pfad."})
	if not window_capture_trusted:
		blockers.append({"id": "window_capture_not_trusted", "text": "Window-Handle-Capture ist nicht vertrauenswuerdig."})
	if not window_handle_capture_succeeded:
		blockers.append({"id": "window_handle_capture_failed", "text": "Window-Handle-Capture ist fehlgeschlagen."})
	if manual_notes_present and not correct_window_content_confirmed:
		blockers.append({"id": "correct_window_content_not_confirmed", "text": "Der manuelle Sichtblick bestaetigt kein Sternenbuergerchen-Missionsfenster."})
	return blockers


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value
