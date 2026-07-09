class_name DecisionOverlayRealWindowRecapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.decision_overlay_real_window_recapture.v1"
const TASK_ID: String = "TASK_953"
const SOURCE_TASK_ID: String = "TASK_952"
const SOURCE_SCHEMA: String = "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"
const SOURCE_STYLE_ID: String = "task_952_decision_overlay_compact_badges_v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_TASK: String = "TASK_954 - Decision Overlay Real Window Visual Findings"

const REQUIRED_RECAPTURE_CHECKS: PackedStringArray = [
	"decision_overlay_badges_visible",
	"safe_risky_suicidal_order_visible",
	"badge_colors_do_not_fight_fire_lane",
	"mission_control_line_still_readable",
	"command_surfaces_still_usable",
	"manual_visual_review_done",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(recapture_manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(recapture_manifest)
	var required_checks: Array = Array(recapture_manifest.get("required_checks", []))
	var completed_checks: Array = Array(recapture_manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var manual_review_done: bool = bool(recapture_manifest.get("manual_review_done", false))
	var review_ready: bool = blockers.is_empty() and String(recapture_manifest.get("gate", "")) in ["review_ready", "accepted", "review"]
	var accepted: bool = review_ready and manual_review_done and missing_checks.is_empty()
	var issues: Array = _build_issues(recapture_manifest, missing_checks, manual_review_done)
	if not blockers.is_empty():
		issues = []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"manifest_schema": String(recapture_manifest.get("schema", "")),
		"manifest_task_id": String(recapture_manifest.get("task_id", "")),
		"source_schema": String(recapture_manifest.get("source_schema", "")),
		"source_style_id": String(recapture_manifest.get("source_style_id", "")),
		"source_gate": String(recapture_manifest.get("source_gate", "")),
		"branch": String(recapture_manifest.get("branch", "")),
		"git_head": String(recapture_manifest.get("git_head", "")),
		"launch_argument": String(recapture_manifest.get("launch_argument", "")),
		"selected_process_id": int(recapture_manifest.get("selected_process_id", 0)),
		"capture_process_id": int(recapture_manifest.get("capture_process_id", 0)),
		"capture_after_deeplink_final": bool(recapture_manifest.get("capture_after_deeplink_final", false)),
		"window_capture_method": String(recapture_manifest.get("window_capture_method", "")),
		"window_capture_trusted": bool(recapture_manifest.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(recapture_manifest.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(recapture_manifest.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(recapture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(recapture_manifest.get("desktop_screenshot_path", "")),
		"source_polish_snapshot": Dictionary(recapture_manifest.get("source_polish_snapshot", {})),
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
		"status": "blocked" if not blockers.is_empty() else ("accepted" if accepted else "review_ready"),
		"recommended_next_task": NEXT_TASK,
		"recommended_direction": "cut_visual_findings_from_decision_overlay_real_window_recapture",
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
		blockers.append(_issue("manifest_schema_mismatch", "TASK_953-Manifest-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_953."))
	if String(recapture_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_952 als Quelle."))
	if String(recapture_manifest.get("source_schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_952-Source-Schema fehlt oder passt nicht."))
	if String(recapture_manifest.get("source_style_id", "")) != SOURCE_STYLE_ID:
		blockers.append(_issue("source_style_mismatch", "TASK_952-Style fehlt oder passt nicht."))
	if String(recapture_manifest.get("source_gate", "")) != "pass":
		blockers.append(_issue("source_gate_not_pass", "TASK_952-Source-Gate ist nicht pass."))
	if String(recapture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."))
	if String(recapture_manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_953-Capture-Gate ist fail."))
	if not Array(recapture_manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_953-Manifest enthaelt Hard-Failures."))
	if not bool(recapture_manifest.get("capture_after_deeplink_final", false)):
		blockers.append(_issue("capture_not_after_trace", "Decision-Overlay-Capture wurde nicht nach deeplink_final markiert."))
	if int(recapture_manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(recapture_manifest.get("capture_process_id", 0)) != int(recapture_manifest.get("selected_process_id", 0)):
		blockers.append(_issue("capture_process_mismatch", "Decision-Overlay-Capture nutzt nicht denselben Release-Prozess."))
	if String(recapture_manifest.get("window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("capture_method_not_handle_print", "Decision-Overlay-Capture nutzt nicht Window-Handle-Print."))
	if not bool(recapture_manifest.get("window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "Decision-Overlay-Window-Capture ist nicht trusted."))
	if not bool(recapture_manifest.get("window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "Decision-Overlay-Window-Screenshot fehlt."))
	var missing_required: Array = _missing_required_check_ids(Array(recapture_manifest.get("required_checks", [])))
	if not missing_required.is_empty():
		blockers.append(_issue("required_checks_missing", "TASK_953-Manifest enthaelt nicht alle Pflichtchecks."))
	return blockers


static func _build_issues(recapture_manifest: Dictionary, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not manual_review_done:
		issues.append(_issue("manual_decision_overlay_review_open", "Der echte TASK_953-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_decision_overlay_checks_missing", "Nicht alle TASK_953-Pflichtchecks sind als erledigt markiert."))
	if not bool(recapture_manifest.get("window_screenshot_written", false)):
		issues.append(_issue("window_screenshot_missing", "Der TASK_953-Window-Screenshot fehlt."))
	return issues


static func _missing_required_check_ids(required_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_RECAPTURE_CHECKS:
		if not required_checks.has(String(check_id)):
			missing.append(String(check_id))
	return missing


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
