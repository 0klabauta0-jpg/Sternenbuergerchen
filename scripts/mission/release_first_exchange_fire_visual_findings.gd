class_name ReleaseFirstExchangeFireVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_visual_findings.v1"
const TASK_ID: String = "TASK_882"
const SOURCE_TASK_ID: String = "TASK_881"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const SOURCE_TRACE_TASK_ID: String = "TASK_879"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_877"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_visual_recapture.v1"
const EXPECTED_FIRE_VISUAL_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_visual_polish.v1"
const EXPECTED_FIRE_VISUAL_STYLE_ID: String = "task_880_release_first_exchange_fire_visual_polish_v1"
const EXPECTED_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const EXPECTED_VISIBLE_STATUS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
const EXPECTED_VISIBLE_STATUS_STYLE_ID: String = "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_883 - Release First Exchange Real Window HUD Source Sync Fix"


static func build_snapshot(capture_manifest: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var capture_schema: String = String(capture_manifest.get("schema", "")).strip_edges()
	var capture_task_id: String = String(capture_manifest.get("task_id", "")).strip_edges()
	var source_task_id: String = String(capture_manifest.get("source_task_id", "")).strip_edges()
	var source_trace_task_id: String = String(capture_manifest.get("source_trace_task_id", "")).strip_edges()
	var source_visible_status_task_id: String = String(capture_manifest.get("source_visible_status_task_id", "")).strip_edges()
	var source_recapture_task_id: String = String(capture_manifest.get("source_recapture_task_id", "")).strip_edges()
	var source_focus_task_id: String = String(capture_manifest.get("source_focus_task_id", "")).strip_edges()
	var source_exchange_task_id: String = String(capture_manifest.get("source_exchange_task_id", "")).strip_edges()
	var capture_gate: String = String(capture_manifest.get("gate", "")).strip_edges()
	var launch_argument: String = String(capture_manifest.get("launch_argument", "")).strip_edges()
	var expected_fire_schema: String = String(capture_manifest.get("expected_fire_visual_schema", "")).strip_edges()
	var expected_fire_style_id: String = String(capture_manifest.get("expected_fire_visual_style_id", "")).strip_edges()
	var expected_trace_schema: String = String(capture_manifest.get("expected_trace_schema", "")).strip_edges()
	var expected_visible_schema: String = String(capture_manifest.get("expected_visible_status_schema", "")).strip_edges()
	var expected_visible_style_id: String = String(capture_manifest.get("expected_visible_status_style_id", "")).strip_edges()
	var runtime_trace_written: bool = bool(capture_manifest.get("runtime_trace_written", false))
	var runtime_trace_activation_observed: bool = bool(capture_manifest.get("runtime_trace_activation_observed", false))
	var runtime_trace_final_stale: bool = bool(capture_manifest.get("runtime_trace_final_no_los_or_contact_pressure_observed", true))
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
		source_trace_task_id,
		source_visible_status_task_id,
		source_recapture_task_id,
		source_focus_task_id,
		source_exchange_task_id,
		capture_gate,
		launch_argument,
		expected_fire_schema,
		expected_fire_style_id,
		expected_trace_schema,
		expected_visible_schema,
		expected_visible_style_id,
		runtime_trace_written,
		runtime_trace_activation_observed,
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
		runtime_trace_written,
		runtime_trace_activation_observed,
		runtime_trace_final_stale,
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
		status = "ready_for_real_window_hud_source_sync_fix"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_fire_visual_task_id": SOURCE_FIRE_VISUAL_TASK_ID,
		"source_trace_task_id": SOURCE_TRACE_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_focus_task_id": SOURCE_FOCUS_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"capture_schema": capture_schema,
		"capture_schema_ok": capture_schema == EXPECTED_RECAPTURE_SCHEMA,
		"capture_task_id": capture_task_id,
		"capture_gate": capture_gate,
		"capture_reviewable": capture_gate == "review_ready" or capture_gate == "review" or capture_gate == "manual_open",
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": launch_argument,
		"launch_argument_ok": launch_argument == FIRST_GO_ARG,
		"expected_fire_visual_schema": expected_fire_schema,
		"expected_fire_visual_style_id": expected_fire_style_id,
		"fire_visual_schema_ok": expected_fire_schema == EXPECTED_FIRE_VISUAL_SCHEMA,
		"fire_visual_style_id_ok": expected_fire_style_id == EXPECTED_FIRE_VISUAL_STYLE_ID,
		"expected_trace_schema": expected_trace_schema,
		"trace_schema_ok": expected_trace_schema == EXPECTED_TRACE_SCHEMA,
		"expected_visible_status_schema": expected_visible_schema,
		"expected_visible_status_style_id": expected_visible_style_id,
		"visible_status_schema_ok": expected_visible_schema == EXPECTED_VISIBLE_STATUS_SCHEMA,
		"visible_status_style_id_ok": expected_visible_style_id == EXPECTED_VISIBLE_STATUS_STYLE_ID,
		"runtime_trace_written": runtime_trace_written,
		"runtime_trace_sample_count": int(capture_manifest.get("runtime_trace_sample_count", 0)),
		"runtime_trace_activation_observed": runtime_trace_activation_observed,
		"runtime_trace_final_no_los_or_contact_pressure_observed": runtime_trace_final_stale,
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
		"target_focus_visible": bool(review_notes.get("target_focus_visible", false)),
		"command_surfaces_still_usable": command_surfaces_usable,
		"expected_window_content": "Sternenbuergerchen first exchange with CONTACT FIRE, FireTrace, Impact and Target-Focus readable in #17/#18/#19/Primary3D after TASK_880",
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "sync_real_window_hud_and_event_log_sources_with_final_contact_fire_trace_state",
		"avoid_next_action": "do_not_tune_fire_vfx_again_before_visible_hud_source_sync",
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
	runtime_trace_written: bool,
	runtime_trace_activation_observed: bool,
	runtime_trace_final_stale: bool,
	window_screenshot_written: bool,
	window_capture_method: String,
	window_capture_trusted: bool,
	window_handle_capture_succeeded: bool,
	correct_window_content_confirmed: bool,
	command_surfaces_usable: bool
) -> Array:
	var positives: Array = []
	if String(capture_manifest.get("source_task_id", "")) == SOURCE_FIRE_VISUAL_TASK_ID:
		positives.append({"id": "task_880_fire_visual_source_recorded", "text": "TASK_881 haelt TASK_880 als erwartete Fire-Visual-Quelle fest."})
	if String(capture_manifest.get("source_trace_task_id", "")) == SOURCE_TRACE_TASK_ID:
		positives.append({"id": "task_879_trace_source_recorded", "text": "TASK_881 haelt TASK_879 als exportierte Trace-Quelle fest."})
	if String(capture_manifest.get("source_visible_status_task_id", "")) == SOURCE_VISIBLE_STATUS_TASK_ID:
		positives.append({"id": "task_876_status_source_recorded", "text": "TASK_881 haelt TASK_876 als sichtbare Statusquellen-Quelle fest."})
	if String(capture_manifest.get("launch_argument", "")) == FIRST_GO_ARG:
		positives.append({"id": "first_go_firefight_deeplink_recorded", "text": "Das Manifest bestaetigt den First-GO-Firefight-Deep-Link."})
	if runtime_trace_written:
		positives.append({"id": "runtime_trace_written", "text": "Der exportierte Runtime-Trace wurde geschrieben."})
	if runtime_trace_activation_observed:
		positives.append({"id": "runtime_trace_activation_observed", "text": "TASK_876-Aktivierung wurde im Runtime-Trace beobachtet."})
	if runtime_trace_written and runtime_trace_activation_observed and not runtime_trace_final_stale:
		positives.append({"id": "runtime_trace_final_contact_fire_clean", "text": "Der finale Trace meldet keine NO_LOS-/CONTACT_PRESSURE-Ueberschreibung."})
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
	if _review_flag(review_notes, "task_880_fire_visual_not_real_window_first_reading", true):
		issues.append({
			"id": "task_880_fire_visual_not_real_window_first_reading",
			"severity": "release_readability_blocker",
			"text": "TASK_880 hebt FireTrace/Impact/Target-Fokus an, aber im echten Fenster wird der First-Exchange weiter nicht als CONTACT FIRE zuerst gelesen.",
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
	if _review_flag(review_notes, "contact_fire_text_not_visible_in_window", true):
		issues.append({
			"id": "contact_fire_text_not_visible_in_window",
			"severity": "player_feedback_confusing",
			"text": "CONTACT FIRE ist im Fenster nicht als gleichzeitige #17/#18/#19-Erstlesung belegbar.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "fire_trace_or_impact_not_decision_clear", true):
		issues.append({
			"id": "fire_trace_or_impact_not_decision_clear",
			"severity": "visual_feedback_gap",
			"text": "FireTrace, Impact oder Target-Fokus reichen im Screenshot nicht, damit der Spieler den ersten Feuerwechsel sofort versteht.",
			"recommended_task": NEXT_TASK,
		})
	return issues


static func _build_blockers(
	capture_schema: String,
	capture_task_id: String,
	source_task_id: String,
	source_trace_task_id: String,
	source_visible_status_task_id: String,
	source_recapture_task_id: String,
	source_focus_task_id: String,
	source_exchange_task_id: String,
	capture_gate: String,
	launch_argument: String,
	expected_fire_schema: String,
	expected_fire_style_id: String,
	expected_trace_schema: String,
	expected_visible_schema: String,
	expected_visible_style_id: String,
	runtime_trace_written: bool,
	runtime_trace_activation_observed: bool,
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
		blockers.append({"id": "capture_schema_mismatch", "text": "TASK_881-Capture-Schema fehlt oder passt nicht."})
	if capture_task_id != SOURCE_TASK_ID:
		blockers.append({"id": "capture_task_mismatch", "text": "Manifest nennt nicht TASK_881 als Quelle."})
	if source_task_id != SOURCE_FIRE_VISUAL_TASK_ID:
		blockers.append({"id": "source_fire_visual_mismatch", "text": "Manifest nennt nicht TASK_880 als Fire-Visual-Quelle."})
	if source_trace_task_id != SOURCE_TRACE_TASK_ID:
		blockers.append({"id": "source_trace_mismatch", "text": "Manifest nennt nicht TASK_879 als Trace-Quelle."})
	if source_visible_status_task_id != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append({"id": "source_visible_status_mismatch", "text": "Manifest nennt nicht TASK_876 als Statusquellen-Quelle."})
	if source_recapture_task_id != SOURCE_RECAPTURE_TASK_ID:
		blockers.append({"id": "source_recapture_mismatch", "text": "Manifest nennt nicht TASK_877 als Recapture-Quelle."})
	if source_focus_task_id != SOURCE_FOCUS_TASK_ID:
		blockers.append({"id": "source_focus_mismatch", "text": "Manifest nennt nicht TASK_850 als Focus-Visual-Quelle."})
	if source_exchange_task_id != SOURCE_EXCHANGE_TASK_ID:
		blockers.append({"id": "source_exchange_mismatch", "text": "Manifest nennt nicht TASK_844 als Exchange-Quelle."})
	if capture_gate != "review_ready" and capture_gate != "review" and capture_gate != "manual_open":
		blockers.append({"id": "capture_not_review_ready", "text": "TASK_881-Capture ist weder review_ready, review noch manual_open."})
	if launch_argument != FIRST_GO_ARG:
		blockers.append({"id": "launch_argument_mismatch", "text": "Manifest nennt nicht den First-GO-Firefight-Deep-Link."})
	if not hard_failures.is_empty():
		blockers.append({"id": "capture_hard_failures", "text": "TASK_881-Capture meldet Hard-Failures."})
	if expected_fire_schema != EXPECTED_FIRE_VISUAL_SCHEMA:
		blockers.append({"id": "fire_visual_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_880-Schema."})
	if expected_fire_style_id != EXPECTED_FIRE_VISUAL_STYLE_ID:
		blockers.append({"id": "fire_visual_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_880-Style-ID."})
	if expected_trace_schema != EXPECTED_TRACE_SCHEMA:
		blockers.append({"id": "trace_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_879-Trace-Schema."})
	if expected_visible_schema != EXPECTED_VISIBLE_STATUS_SCHEMA:
		blockers.append({"id": "visible_status_schema_mismatch", "text": "Manifest nennt nicht das erwartete TASK_876-Schema."})
	if expected_visible_style_id != EXPECTED_VISIBLE_STATUS_STYLE_ID:
		blockers.append({"id": "visible_status_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_876-Style-ID."})
	if not runtime_trace_written:
		blockers.append({"id": "runtime_trace_missing", "text": "TASK_879 Runtime-Trace fehlt."})
	if not runtime_trace_activation_observed:
		blockers.append({"id": "status_source_activation_missing", "text": "TASK_876-Aktivierung wurde im Trace nicht beobachtet."})
	if not window_screenshot_written:
		blockers.append({"id": "window_screenshot_missing", "text": "Fenster-Screenshot fehlt."})
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
