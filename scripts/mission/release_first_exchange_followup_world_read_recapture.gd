class_name ReleaseFirstExchangeFollowupWorldReadRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_world_read_recapture.v1"
const TASK_ID: String = "TASK_921"
const SOURCE_TASK_ID: String = "TASK_920"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_917"
const SOURCE_FINAL_TASK_ID: String = "TASK_916"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_918"
const SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_world_read_recapture.v1"
const EXPECTED_FOLLOWUP_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_world_read_followup_fix.v1"
const EXPECTED_FOLLOWUP_STYLE_ID: String = "task_920_release_first_exchange_final_world_read_followup_v1"
const EXPECTED_FINAL_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
const EXPECTED_FINAL_STYLE_ID: String = "task_916_release_first_exchange_fire_lane_world_read_final_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_922 - Release First Exchange Followup World Read Visual Findings"


static func build_snapshot(recapture_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(recapture_manifest)
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var completed_checks: Array = Array(recapture_manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var final_source: Dictionary = Dictionary(recapture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(recapture_manifest.get("post_followup_world_read_render_review", {}))
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
		"source_final_task_id": SOURCE_FINAL_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"manifest_schema": String(recapture_manifest.get("schema", "")),
		"manifest_task_id": String(recapture_manifest.get("task_id", "")),
		"gate": String(recapture_manifest.get("gate", "")),
		"branch": String(recapture_manifest.get("branch", "")),
		"git_head": String(recapture_manifest.get("git_head", "")),
		"launch_argument": String(recapture_manifest.get("launch_argument", "")),
		"expected_followup_schema": String(recapture_manifest.get("expected_followup_schema", "")),
		"expected_followup_style_id": String(recapture_manifest.get("expected_followup_style_id", "")),
		"expected_final_schema": String(recapture_manifest.get("expected_final_schema", "")),
		"expected_final_style_id": String(recapture_manifest.get("expected_final_style_id", "")),
		"source_recapture_schema": String(recapture_manifest.get("source_recapture_schema", "")),
		"source_recapture_gate": String(recapture_manifest.get("source_recapture_gate", "")),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"post_followup_capture_process_id": int(recapture_manifest.get("post_followup_capture_process_id", 0)),
		"post_followup_capture_after_deeplink_final": bool(recapture_manifest.get("post_followup_capture_after_deeplink_final", false)),
		"post_followup_capture_method": String(recapture_manifest.get("post_followup_window_capture_method", "")),
		"post_followup_window_capture_trusted": bool(recapture_manifest.get("post_followup_window_capture_trusted", false)),
		"post_followup_window_screenshot_path": String(recapture_manifest.get("post_followup_window_screenshot_path", "")),
		"post_followup_desktop_screenshot_path": String(recapture_manifest.get("post_followup_desktop_screenshot_path", "")),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"post_followup_world_read_render_review": render_review,
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
		"recommended_direction": "cut_visual_findings_from_real_window_followup_world_read_recapture",
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
		blockers.append(_issue("manifest_schema_mismatch", "TASK_921-Manifest-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_921."))
	if String(recapture_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_920 als Quelle."))
	if String(recapture_manifest.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Manifest nennt nicht TASK_917 als Recapture-Basis."))
	if String(recapture_manifest.get("source_final_task_id", "")) != SOURCE_FINAL_TASK_ID:
		blockers.append(_issue("source_final_task_mismatch", "Manifest nennt nicht TASK_916 als Final-Basis."))
	if String(recapture_manifest.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Manifest nennt nicht TASK_918 als Findings-Basis."))
	if String(recapture_manifest.get("source_recapture_schema", "")) != SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_917-Recapture-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_followup_schema", "")) != EXPECTED_FOLLOWUP_SCHEMA:
		blockers.append(_issue("followup_schema_mismatch", "TASK_920-Follow-up-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_followup_style_id", "")) != EXPECTED_FOLLOWUP_STYLE_ID:
		blockers.append(_issue("followup_style_mismatch", "TASK_920-Follow-up-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_final_schema", "")) != EXPECTED_FINAL_SCHEMA:
		blockers.append(_issue("final_schema_mismatch", "TASK_916-Final-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_final_style_id", "")) != EXPECTED_FINAL_STYLE_ID:
		blockers.append(_issue("final_style_mismatch", "TASK_916-Final-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(recapture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_921-Capture-Gate ist fail."))
	if not Array(recapture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_921-Manifest enthaelt Hard-Failures."))
	if not bool(recapture_manifest.get("post_followup_capture_after_deeplink_final", false)):
		blockers.append(_issue("post_followup_capture_not_after_trace", "Post-Followup-Capture wurde nicht nach deeplink_final markiert."))
	if int(recapture_manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(recapture_manifest.get("post_followup_capture_process_id", 0)) != int(recapture_manifest.get("selected_process_id", 0)):
		blockers.append(_issue("post_followup_process_mismatch", "Post-Followup-Capture nutzt nicht denselben Release-Prozess."))
	if String(recapture_manifest.get("post_followup_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("post_followup_capture_method_not_handle_print", "Post-Followup-Capture nutzt nicht Window-Handle-Print."))
	if not bool(recapture_manifest.get("post_followup_window_capture_trusted", false)):
		blockers.append(_issue("post_followup_window_capture_not_trusted", "Post-Followup-Window-Capture ist nicht trusted."))
	if not bool(recapture_manifest.get("post_followup_window_screenshot_written", false)):
		blockers.append(_issue("post_followup_window_screenshot_missing", "Post-Followup-Window-Screenshot fehlt."))
	return blockers


static func _build_issues(recapture_manifest: Dictionary, final_contact_fire: bool, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_followup_world_read_review_open", "Der echte TASK_921-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_followup_world_read_checks_missing", "Nicht alle TASK_921-Pflichtchecks sind als erledigt markiert."))
	if not bool(recapture_manifest.get("post_followup_window_screenshot_written", false)):
		issues.append(_issue("window_screenshot_missing", "Der TASK_921-Window-Screenshot fehlt."))
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
