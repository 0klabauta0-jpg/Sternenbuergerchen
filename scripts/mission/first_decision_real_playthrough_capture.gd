class_name FirstDecisionRealPlaythroughCapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.first_decision_real_playthrough_capture.v1"
const TASK_ID: String = "TASK_957"
const SOURCE_TASK_ID: String = "TASK_956"
const SOURCE_SCHEMA: String = "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const FIRST_DECISION_ARG: String = "--release-singleplayer-lz-drop-preview"
const NEXT_TASK: String = "TASK_958 - First Decision Real Playthrough Visual Findings"

const REQUIRED_CAPTURE_CHECKS: PackedStringArray = [
	"first_decision_next_line_visible",
	"why_line_visible",
	"choice_rows_visible",
	"preview_boundary_visible",
	"go_button_or_command_surface_usable",
	"no_command_before_go",
	"manual_visual_review_done",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(manifest: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(manifest)
	var required_checks: Array = Array(manifest.get("required_checks", []))
	var completed_checks: Array = Array(manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var manual_review_done: bool = bool(manifest.get("manual_review_done", false))
	var review_ready: bool = blockers.is_empty() and String(manifest.get("gate", "")) in ["review_ready", "accepted", "review"]
	var accepted: bool = review_ready and manual_review_done and missing_checks.is_empty()
	var issues: Array = _build_issues(manifest, missing_checks, manual_review_done)
	if not blockers.is_empty():
		issues = []
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"manifest_schema": String(manifest.get("schema", "")),
		"manifest_task_id": String(manifest.get("task_id", "")),
		"source_schema": String(manifest.get("source_schema", "")),
		"source_gate": String(manifest.get("source_gate", "")),
		"source_status": String(manifest.get("source_status", "")),
		"branch": String(manifest.get("branch", "")),
		"git_head": String(manifest.get("git_head", "")),
		"launch_argument": String(manifest.get("launch_argument", "")),
		"selected_process_id": int(manifest.get("selected_process_id", 0)),
		"capture_process_id": int(manifest.get("capture_process_id", 0)),
		"capture_after_deeplink_final": bool(manifest.get("capture_after_deeplink_final", false)),
		"window_capture_method": String(manifest.get("window_capture_method", "")),
		"window_capture_trusted": bool(manifest.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(manifest.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(manifest.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(manifest.get("desktop_screenshot_path", "")),
		"source_micro_scenario_snapshot": Dictionary(manifest.get("source_micro_scenario_snapshot", {})),
		"manual_review_required": bool(manifest.get("manual_review_required", true)),
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
		"recommended_direction": "cut_first_decision_visual_findings_from_real_playthrough_capture",
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


static func _build_blockers(manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "TASK_957-Manifest-Schema fehlt oder passt nicht."))
	if String(manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_957."))
	if String(manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Manifest nennt nicht TASK_956 als Quelle."))
	if String(manifest.get("source_schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_956-Source-Schema fehlt oder passt nicht."))
	if String(manifest.get("source_gate", "")) != "pass":
		blockers.append(_issue("source_gate_not_pass", "TASK_956-Source-Gate ist nicht pass."))
	if String(manifest.get("source_status", "")) != "ready_for_first_decision_micro_scenario":
		blockers.append(_issue("source_status_not_ready", "TASK_956-Source ist nicht bereit fuer den ersten Decision-Playthrough."))
	if String(manifest.get("launch_argument", "")) != FIRST_DECISION_ARG:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den First-Decision-LZ-Drop-Preview-Deep-Link."))
	if String(manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_957-Capture-Gate ist fail."))
	if not Array(manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_957-Manifest enthaelt Hard-Failures."))
	if not bool(manifest.get("capture_after_deeplink_final", false)):
		blockers.append(_issue("capture_not_after_trace", "First-Decision-Capture wurde nicht nach deeplink_final markiert."))
	if int(manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(manifest.get("capture_process_id", 0)) != int(manifest.get("selected_process_id", 0)):
		blockers.append(_issue("capture_process_mismatch", "First-Decision-Capture nutzt nicht denselben Release-Prozess."))
	if String(manifest.get("window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("capture_method_not_handle_print", "First-Decision-Capture nutzt nicht Window-Handle-Print."))
	if not bool(manifest.get("window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "First-Decision-Window-Capture ist nicht trusted."))
	if not bool(manifest.get("window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "First-Decision-Window-Screenshot fehlt."))
	var missing_required: Array = _missing_required_check_ids(Array(manifest.get("required_checks", [])))
	if not missing_required.is_empty():
		blockers.append(_issue("required_checks_missing", "TASK_957-Manifest enthaelt nicht alle Pflichtchecks."))
	return blockers


static func _build_issues(manifest: Dictionary, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not manual_review_done:
		issues.append(_issue("manual_first_decision_review_open", "Der echte TASK_957-First-Decision-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_first_decision_checks_missing", "Nicht alle TASK_957-Pflichtchecks sind als erledigt markiert."))
	if not bool(manifest.get("desktop_screenshot_written", false)):
		issues.append(_issue("desktop_screenshot_missing", "Der TASK_957-Desktop-Screenshot fehlt."))
	return issues


static func _missing_required_check_ids(required_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_CAPTURE_CHECKS:
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
