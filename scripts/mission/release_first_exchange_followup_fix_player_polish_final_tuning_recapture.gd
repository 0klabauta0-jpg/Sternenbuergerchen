class_name ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_recapture.v1"
const TASK_ID: String = "TASK_939"
const SOURCE_TASK_ID: String = "TASK_938"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_936"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_937"
const SOURCE_PLAYER_POLISH_TASK_ID: String = "TASK_935"
const SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_recapture.v1"
const EXPECTED_FINAL_TUNING_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning.v1"
const EXPECTED_FINAL_TUNING_STYLE_ID: String = "task_938_release_first_exchange_followup_fix_player_polish_final_tuning_v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_visual_findings.v1"
const EXPECTED_PLAYER_POLISH_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish.v1"
const EXPECTED_PLAYER_POLISH_STYLE_ID: String = "task_935_release_first_exchange_followup_fix_player_polish_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_940 - Release First Exchange Followup Fix Player Polish Final Tuning Visual Findings"


static func build_snapshot(recapture_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(recapture_manifest)
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var completed_checks: Array = Array(recapture_manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var final_source: Dictionary = Dictionary(recapture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(recapture_manifest.get("final_tuning_world_read_render_review", {}))
	var final_contact_fire: bool = bool(final_source.get("selected_starts_contact_fire", false)) \
		and bool(final_source.get("mission_starts_contact_fire", false)) \
		and bool(final_source.get("event_log_contains_contact_fire", false)) \
		and not bool(final_source.get("event_log_contains_contact_pressure", true))
	var manual_review_done: bool = bool(recapture_manifest.get("manual_review_done", false))
	var review_ready: bool = blockers.is_empty() \
		and String(recapture_manifest.get("gate", "")) in ["review_ready", "accepted", "review"] \
		and final_contact_fire
	var accepted: bool = review_ready and manual_review_done and missing_checks.is_empty()
	var issues: Array = _build_issues(recapture_manifest, final_contact_fire, missing_checks, manual_review_done)
	if not blockers.is_empty():
		issues = []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_player_polish_task_id": SOURCE_PLAYER_POLISH_TASK_ID,
		"manifest_schema": String(recapture_manifest.get("schema", "")),
		"manifest_task_id": String(recapture_manifest.get("task_id", "")),
		"gate": String(recapture_manifest.get("gate", "")),
		"branch": String(recapture_manifest.get("branch", "")),
		"git_head": String(recapture_manifest.get("git_head", "")),
		"launch_argument": String(recapture_manifest.get("launch_argument", "")),
		"expected_final_tuning_schema": String(recapture_manifest.get("expected_final_tuning_schema", "")),
		"expected_final_tuning_style_id": String(recapture_manifest.get("expected_final_tuning_style_id", "")),
		"expected_findings_schema": String(recapture_manifest.get("expected_findings_schema", "")),
		"expected_player_polish_schema": String(recapture_manifest.get("expected_player_polish_schema", "")),
		"expected_player_polish_style_id": String(recapture_manifest.get("expected_player_polish_style_id", "")),
		"source_recapture_schema": String(recapture_manifest.get("source_recapture_schema", "")),
		"source_recapture_gate": String(recapture_manifest.get("source_recapture_gate", "")),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"final_tuning_capture_process_id": int(recapture_manifest.get("final_tuning_capture_process_id", 0)),
		"final_tuning_capture_after_deeplink_final": bool(recapture_manifest.get("final_tuning_capture_after_deeplink_final", false)),
		"final_tuning_capture_method": String(recapture_manifest.get("final_tuning_window_capture_method", "")),
		"final_tuning_window_capture_trusted": bool(recapture_manifest.get("final_tuning_window_capture_trusted", false)),
		"final_tuning_window_screenshot_path": String(recapture_manifest.get("final_tuning_window_screenshot_path", "")),
		"final_tuning_desktop_screenshot_path": String(recapture_manifest.get("final_tuning_desktop_screenshot_path", "")),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"source_final_tuning_snapshot": Dictionary(recapture_manifest.get("source_final_tuning_snapshot", {})),
		"source_findings_snapshot": Dictionary(recapture_manifest.get("source_findings_snapshot", {})),
		"source_player_polish_snapshot": Dictionary(recapture_manifest.get("source_player_polish_snapshot", {})),
		"source_recapture_review": Dictionary(recapture_manifest.get("source_recapture_review", {})),
		"final_tuning_world_read_render_review": render_review,
		"manual_review_required": bool(recapture_manifest.get("manual_review_required", true)),
		"manual_review_done": manual_review_done,
		"required_checks": required_checks,
		"completed_manual_checks": completed_checks,
		"missing_manual_checks": missing_checks,
		"missing_manual_check_count": missing_checks.size(),
		"review_ready": review_ready,
		"accepted": accepted,
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": "blocked" if not blockers.is_empty() else ("accepted" if accepted else ("review_ready" if review_ready else "review")),
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "cut_visual_findings_from_real_window_final_tuning_recapture",
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_blockers(recapture_manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(recapture_manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "TASK_939-Manifest-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_939."))
	if String(recapture_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_938 als Quelle."))
	if String(recapture_manifest.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Manifest nennt nicht TASK_936 als Recapture-Basis."))
	if String(recapture_manifest.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Manifest nennt nicht TASK_937 als Findings-Basis."))
	if String(recapture_manifest.get("source_player_polish_task_id", "")) != SOURCE_PLAYER_POLISH_TASK_ID:
		blockers.append(_issue("source_player_polish_task_mismatch", "Manifest nennt nicht TASK_935 als Player-Polish-Basis."))
	if String(recapture_manifest.get("source_recapture_schema", "")) != SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_936-Recapture-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_final_tuning_schema", "")) != EXPECTED_FINAL_TUNING_SCHEMA:
		blockers.append(_issue("final_tuning_schema_mismatch", "TASK_938-Final-Tuning-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_final_tuning_style_id", "")) != EXPECTED_FINAL_TUNING_STYLE_ID:
		blockers.append(_issue("final_tuning_style_mismatch", "TASK_938-Final-Tuning-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_findings_schema", "")) != EXPECTED_FINDINGS_SCHEMA:
		blockers.append(_issue("findings_schema_mismatch", "TASK_937-Findings-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_player_polish_schema", "")) != EXPECTED_PLAYER_POLISH_SCHEMA:
		blockers.append(_issue("player_polish_schema_mismatch", "TASK_935-Player-Polish-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_player_polish_style_id", "")) != EXPECTED_PLAYER_POLISH_STYLE_ID:
		blockers.append(_issue("player_polish_style_mismatch", "TASK_935-Player-Polish-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(recapture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_939-Capture-Gate ist fail."))
	if not Array(recapture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_939-Manifest enthaelt Hard-Failures."))
	if not bool(recapture_manifest.get("final_tuning_capture_after_deeplink_final", false)):
		blockers.append(_issue("final_tuning_capture_not_after_trace", "Final-Tuning-Capture wurde nicht nach deeplink_final markiert."))
	if int(recapture_manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(recapture_manifest.get("final_tuning_capture_process_id", 0)) != int(recapture_manifest.get("selected_process_id", 0)):
		blockers.append(_issue("final_tuning_process_mismatch", "Final-Tuning-Capture nutzt nicht denselben Release-Prozess."))
	if String(recapture_manifest.get("final_tuning_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("final_tuning_capture_method_not_handle_print", "Final-Tuning-Capture nutzt nicht Window-Handle-Print."))
	if not bool(recapture_manifest.get("final_tuning_window_capture_trusted", false)):
		blockers.append(_issue("final_tuning_window_capture_not_trusted", "Final-Tuning-Window-Capture ist nicht trusted."))
	if not bool(recapture_manifest.get("final_tuning_window_screenshot_written", false)):
		blockers.append(_issue("final_tuning_window_screenshot_missing", "Final-Tuning-Window-Screenshot fehlt."))
	return blockers


static func _build_issues(recapture_manifest: Dictionary, final_contact_fire: bool, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_final_tuning_review_open", "Der echte TASK_939-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_final_tuning_checks_missing", "Nicht alle TASK_939-Pflichtchecks sind als erledigt markiert."))
	if not bool(recapture_manifest.get("final_tuning_window_screenshot_written", false)):
		issues.append(_issue("window_screenshot_missing", "Der TASK_939-Window-Screenshot fehlt."))
	return issues


static func _missing_checks(required_checks: Array, completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_variant in required_checks:
		var check_id: String = String(check_variant)
		if not completed.has(check_id):
			missing.append(check_id)
	return missing


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
