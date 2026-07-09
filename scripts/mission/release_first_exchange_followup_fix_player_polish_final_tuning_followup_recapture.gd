class_name ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.v1"
const TASK_ID: String = "TASK_943"
const SOURCE_TASK_ID: String = "TASK_942"
const SOURCE_GATE_TASK_ID: String = "TASK_941"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_940"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_939"
const BASE_FINAL_TUNING_TASK_ID: String = "TASK_938"
const SOURCE_RECAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_recapture.v1"
const EXPECTED_FOLLOWUP_FIX_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const EXPECTED_FOLLOWUP_FIX_STYLE_ID: String = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const EXPECTED_GATE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_tuning_playability_smoke_gate.v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.v1"
const EXPECTED_BASE_FINAL_TUNING_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning.v1"
const EXPECTED_BASE_FINAL_TUNING_STYLE_ID: String = "task_938_release_first_exchange_followup_fix_player_polish_final_tuning_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_944 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Visual Findings"


static func build_snapshot(recapture_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(recapture_manifest)
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var completed_checks: Array = Array(recapture_manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var final_source: Dictionary = Dictionary(recapture_manifest.get("final_source_snapshot", {}))
	var render_review: Dictionary = Dictionary(recapture_manifest.get("followup_world_read_render_review", {}))
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
		"source_gate_task_id": SOURCE_GATE_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"base_final_tuning_task_id": BASE_FINAL_TUNING_TASK_ID,
		"manifest_schema": String(recapture_manifest.get("schema", "")),
		"manifest_task_id": String(recapture_manifest.get("task_id", "")),
		"gate": String(recapture_manifest.get("gate", "")),
		"branch": String(recapture_manifest.get("branch", "")),
		"git_head": String(recapture_manifest.get("git_head", "")),
		"launch_argument": String(recapture_manifest.get("launch_argument", "")),
		"expected_followup_fix_schema": String(recapture_manifest.get("expected_followup_fix_schema", "")),
		"expected_followup_fix_style_id": String(recapture_manifest.get("expected_followup_fix_style_id", "")),
		"expected_gate_schema": String(recapture_manifest.get("expected_gate_schema", "")),
		"expected_findings_schema": String(recapture_manifest.get("expected_findings_schema", "")),
		"expected_base_final_tuning_schema": String(recapture_manifest.get("expected_base_final_tuning_schema", "")),
		"expected_base_final_tuning_style_id": String(recapture_manifest.get("expected_base_final_tuning_style_id", "")),
		"source_recapture_schema": String(recapture_manifest.get("source_recapture_schema", "")),
		"source_recapture_gate": String(recapture_manifest.get("source_recapture_gate", "")),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"followup_capture_process_id": int(recapture_manifest.get("followup_capture_process_id", 0)),
		"followup_capture_after_deeplink_final": bool(recapture_manifest.get("followup_capture_after_deeplink_final", false)),
		"followup_capture_method": String(recapture_manifest.get("followup_window_capture_method", "")),
		"followup_window_capture_trusted": bool(recapture_manifest.get("followup_window_capture_trusted", false)),
		"followup_window_screenshot_path": String(recapture_manifest.get("followup_window_screenshot_path", "")),
		"followup_desktop_screenshot_path": String(recapture_manifest.get("followup_desktop_screenshot_path", "")),
		"final_source_contact_fire": final_contact_fire,
		"final_source_snapshot": final_source,
		"source_followup_fix_snapshot": Dictionary(recapture_manifest.get("source_followup_fix_snapshot", {})),
		"source_gate_snapshot": Dictionary(recapture_manifest.get("source_gate_snapshot", {})),
		"source_findings_snapshot": Dictionary(recapture_manifest.get("source_findings_snapshot", {})),
		"source_base_final_tuning_snapshot": Dictionary(recapture_manifest.get("source_base_final_tuning_snapshot", {})),
		"source_recapture_review": Dictionary(recapture_manifest.get("source_recapture_review", {})),
		"followup_world_read_render_review": render_review,
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
		"recommended_direction": "cut_visual_findings_from_real_window_followup_recapture",
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
		blockers.append(_issue("manifest_schema_mismatch", "TASK_943-Manifest-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_943."))
	if String(recapture_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_942 als Quelle."))
	if String(recapture_manifest.get("source_gate_task_id", "")) != SOURCE_GATE_TASK_ID:
		blockers.append(_issue("source_gate_task_mismatch", "Manifest nennt nicht TASK_941 als Gate-Quelle."))
	if String(recapture_manifest.get("source_findings_task_id", "")) != SOURCE_FINDINGS_TASK_ID:
		blockers.append(_issue("source_findings_task_mismatch", "Manifest nennt nicht TASK_940 als Findings-Quelle."))
	if String(recapture_manifest.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append(_issue("source_recapture_task_mismatch", "Manifest nennt nicht TASK_939 als Recapture-Basis."))
	if String(recapture_manifest.get("base_final_tuning_task_id", "")) != BASE_FINAL_TUNING_TASK_ID:
		blockers.append(_issue("base_final_tuning_task_mismatch", "Manifest nennt nicht TASK_938 als Final-Tuning-Basis."))
	if String(recapture_manifest.get("source_recapture_schema", "")) != SOURCE_RECAPTURE_SCHEMA:
		blockers.append(_issue("source_recapture_schema_mismatch", "TASK_939-Recapture-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_followup_fix_schema", "")) != EXPECTED_FOLLOWUP_FIX_SCHEMA:
		blockers.append(_issue("followup_fix_schema_mismatch", "TASK_942-Followup-Fix-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_followup_fix_style_id", "")) != EXPECTED_FOLLOWUP_FIX_STYLE_ID:
		blockers.append(_issue("followup_fix_style_mismatch", "TASK_942-Followup-Fix-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_gate_schema", "")) != EXPECTED_GATE_SCHEMA:
		blockers.append(_issue("gate_schema_mismatch", "TASK_941-Gate-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_findings_schema", "")) != EXPECTED_FINDINGS_SCHEMA:
		blockers.append(_issue("findings_schema_mismatch", "TASK_940-Findings-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_base_final_tuning_schema", "")) != EXPECTED_BASE_FINAL_TUNING_SCHEMA:
		blockers.append(_issue("base_final_tuning_schema_mismatch", "TASK_938-Final-Tuning-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("expected_base_final_tuning_style_id", "")) != EXPECTED_BASE_FINAL_TUNING_STYLE_ID:
		blockers.append(_issue("base_final_tuning_style_mismatch", "TASK_938-Final-Tuning-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(recapture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_943-Capture-Gate ist fail."))
	if not Array(recapture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_943-Manifest enthaelt Hard-Failures."))
	if not bool(recapture_manifest.get("followup_capture_after_deeplink_final", false)):
		blockers.append(_issue("followup_capture_not_after_trace", "TASK_943-Capture wurde nicht nach deeplink_final markiert."))
	if int(recapture_manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(recapture_manifest.get("followup_capture_process_id", 0)) != int(recapture_manifest.get("selected_process_id", 0)):
		blockers.append(_issue("followup_process_mismatch", "TASK_943-Capture nutzt nicht denselben Release-Prozess."))
	if String(recapture_manifest.get("followup_window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("followup_capture_method_not_handle_print", "TASK_943-Capture nutzt nicht Window-Handle-Print."))
	if not bool(recapture_manifest.get("followup_window_capture_trusted", false)):
		blockers.append(_issue("followup_window_capture_not_trusted", "TASK_943-Window-Capture ist nicht trusted."))
	if not bool(recapture_manifest.get("followup_window_screenshot_written", false)):
		blockers.append(_issue("followup_window_screenshot_missing", "TASK_943-Window-Screenshot fehlt."))
	return blockers


static func _build_issues(recapture_manifest: Dictionary, final_contact_fire: bool, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not final_contact_fire:
		issues.append(_issue("final_source_not_contact_fire", "Finaler Source-Snapshot meldet nicht sauber CONTACT FIRE in #17/#18/#19."))
	if not manual_review_done:
		issues.append(_issue("manual_followup_review_open", "Der echte TASK_943-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_followup_checks_missing", "Nicht alle TASK_943-Pflichtchecks sind als erledigt markiert."))
	if not bool(recapture_manifest.get("followup_window_screenshot_written", false)):
		issues.append(_issue("window_screenshot_missing", "Der TASK_943-Window-Screenshot fehlt."))
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
