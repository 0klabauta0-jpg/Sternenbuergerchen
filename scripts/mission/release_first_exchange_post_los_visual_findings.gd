class_name ReleaseFirstExchangePostLosVisualFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_post_los_visual_findings.v1"
const TASK_ID: String = "TASK_870"
const SOURCE_TASK_ID: String = "TASK_869"
const SOURCE_LOS_SETUP_TASK_ID: String = "TASK_868"
const SOURCE_STATUS_RECAPTURE_TASK_ID: String = "TASK_866"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const EXPECTED_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_los_setup_real_window_recapture.v1"
const EXPECTED_LOS_SETUP_STYLE_ID: String = "task_868_release_first_exchange_los_setup_polish_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_871 - Release Window Identity Capture Target Fix"


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
	var window_crop_trusted: bool = bool(recapture_manifest.get("window_crop_trusted", false))
	var window_focus_succeeded: bool = bool(recapture_manifest.get("window_focus_succeeded", false))
	var foreground_matches_selected_process: bool = bool(recapture_manifest.get("foreground_matches_selected_process", false))
	var expected_los_setup_style_id: String = String(recapture_manifest.get("expected_los_setup_style_id", "")).strip_edges()
	var manual_notes_present: bool = not review_notes.is_empty()
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
		expected_los_setup_style_id
	)
	var positives: Array = _build_positive_findings(
		recapture_manifest,
		window_screenshot_written,
		window_crop_trusted,
		window_focus_succeeded,
		foreground_matches_selected_process
	)
	var issues: Array = _build_issue_findings(review_notes, window_crop_trusted)
	var status: String = "blocked" if not blockers.is_empty() else "needs_manual_review"
	if status != "blocked" and manual_notes_present:
		status = "ready_for_capture_target_fix"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
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
		"window_crop_trusted": window_crop_trusted,
		"window_focus_succeeded": window_focus_succeeded,
		"foreground_process_id": int(recapture_manifest.get("foreground_process_id", 0)),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"foreground_matches_selected_process": foreground_matches_selected_process,
		"manual_review_required": true,
		"manual_visual_review_done": manual_visual_review_done,
		"manual_notes_present": manual_notes_present,
		"observed_window_state": String(review_notes.get("observed_window_state", "unknown")),
		"observed_foreign_content": String(review_notes.get("observed_foreign_content", "")),
		"expected_window_content": "Sternenbuergerchen mission fireteam CONTACT FIRE / first exchange",
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "fix_release_window_identity_or_capture_target_before_more_hud_polish",
		"avoid_next_action": "do_not_accept_contact_fire_readability_from_wrong_window_content",
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
	window_crop_trusted: bool,
	window_focus_succeeded: bool,
	foreground_matches_selected_process: bool
) -> Array:
	var positives: Array = []
	if String(recapture_manifest.get("source_task_id", "")) == SOURCE_LOS_SETUP_TASK_ID:
		positives.append({
			"id": "task_868_los_setup_source_recorded",
			"text": "TASK_869 haelt TASK_868 als LOS-Setup-Quelle fest.",
		})
	if String(recapture_manifest.get("launch_argument", "")) == FIRST_GO_ARG:
		positives.append({
			"id": "first_go_firefight_deeplink_recorded",
			"text": "Das Manifest bestaetigt den First-GO-Firefight-Deep-Link.",
		})
	if window_screenshot_written:
		positives.append({
			"id": "window_screenshot_written",
			"text": "Ein Fenster-Screenshot wurde geschrieben.",
		})
	if window_crop_trusted:
		positives.append({
			"id": "window_crop_trusted_by_manifest",
			"text": "Das Manifest meldet einen vertrauenswuerdigen Fenster-Crop.",
		})
	if window_focus_succeeded and foreground_matches_selected_process:
		positives.append({
			"id": "foreground_process_matches_release_process",
			"text": "Fokus- und Foreground-Evidence zeigen auf den ausgewaehlten Release-Prozess.",
		})
	return positives


static func _build_issue_findings(review_notes: Dictionary, window_crop_trusted: bool) -> Array:
	var issues: Array = []
	if _review_flag(review_notes, "trusted_capture_content_not_sternenbuergerchen", true):
		issues.append({
			"id": "trusted_capture_content_not_sternenbuergerchen",
			"severity": "release_blocker",
			"text": "Der Capture ist technisch trusted, zeigt aber nicht die erwartete Sternenbuergerchen-Mission.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "foreign_triplea_or_world_at_war_map_visible", true):
		issues.append({
			"id": "foreign_triplea_or_world_at_war_map_visible",
			"severity": "qa_evidence_invalid",
			"text": "Der Screenshot zeigt eine World-at-War/TripleA-Karte statt #17/#18/#19 Mission-HUD.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "contact_fire_visibility_not_reviewable", true):
		issues.append({
			"id": "contact_fire_visibility_not_reviewable",
			"severity": "release_readability_unknown",
			"text": "CONTACT-FIRE-Lesbarkeit kann aus diesem PNG nicht bewertet werden, weil der Spielinhalt falsch ist.",
			"recommended_task": NEXT_TASK,
		})
	if _review_flag(review_notes, "needs_release_window_identity_or_capture_target_fix", true):
		issues.append({
			"id": "needs_release_window_identity_or_capture_target_fix",
			"severity": "tooling_or_launch_path",
			"text": "Vor weiterem HUD-/Combat-Polish muss geklaert werden, warum Release-Prozess, Fensteridentitaet und sichtbarer Inhalt auseinanderlaufen.",
			"recommended_task": NEXT_TASK,
		})
	if not window_crop_trusted:
		issues.append({
			"id": "window_crop_not_trusted",
			"severity": "qa_evidence_invalid",
			"text": "Das Manifest meldet den Fenster-Crop nicht als vertrauenswuerdig.",
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
	expected_los_setup_style_id: String
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
	if expected_los_setup_style_id != EXPECTED_LOS_SETUP_STYLE_ID:
		blockers.append({"id": "los_setup_style_id_mismatch", "text": "Manifest nennt nicht die erwartete TASK_868-Style-ID."})
	return blockers


static func _review_flag(review_notes: Dictionary, key: String, default_value: bool) -> bool:
	if review_notes.has(key):
		return bool(review_notes.get(key))
	return default_value
