class_name ReleaseFirstDecisionLoopTwoRealWindowCapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_real_window_capture.v1"
const TASK_ID: String = "TASK_969"
const SOURCE_TASK_ID: String = "TASK_968"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_runtime_button.v1"
const LAUNCH_ARGUMENT: String = "--release-singleplayer-lz-drop-preview"
const NEXT_TASK: String = "TASK_970 - Release First Decision Loop Two Visual Findings"
const REVIEW_TASK: String = "TASK_969 - Release First Decision Loop Two Real Window Capture"

const REQUIRED_CAPTURE_CHECKS: PackedStringArray = [
	"real_window_launched",
	"correct_window_content_confirmed",
	"window_capture_trusted",
	"window_screenshot_written",
	"second_decision_button_visible",
	"second_decision_button_readable",
	"second_decision_confirm_observed",
	"go_button_still_separate",
	"post_confirm_feedback_visible",
	"no_go_before_go_confirmed",
	"no_new_hud_gameplay_truth",
	"manual_visual_review_done",
]


static func build_snapshot(source_runtime_button: Dictionary, manifest: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_runtime_button)
	var manifest_available: bool = not manifest.is_empty()
	var manifest_blockers: Array = _build_manifest_blockers(manifest) if blockers.is_empty() and manifest_available else []
	var required_checks: Array = Array(manifest.get("required_checks", []))
	var completed_checks: Array = Array(manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var manual_review_done: bool = bool(manifest.get("manual_review_done", false))
	var issues: Array = []
	if blockers.is_empty():
		if not manifest_available:
			issues.append(_issue("real_window_manifest_missing", "TASK_969-Real-Window-Capture-Manifest fehlt."))
		elif manifest_blockers.is_empty():
			issues = _build_manifest_issues(manifest, missing_checks, manual_review_done)
	blockers.append_array(manifest_blockers)
	var review_ready: bool = blockers.is_empty() and manifest_available and String(manifest.get("gate", "")) in ["review_ready", "accepted", "review"]
	var accepted: bool = review_ready and manual_review_done and missing_checks.is_empty() and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "run_loop_two_real_window_capture"
	if blockers.is_empty():
		if accepted:
			status = "accepted"
			gate = "real_window_capture_accepted"
			recommended_next_task = NEXT_TASK
			recommended_direction = "cut_loop_two_visual_findings_from_real_window_capture"
		elif manifest_available:
			status = "review_ready"
			gate = "real_window_capture_review_ready"
			recommended_next_task = NEXT_TASK
			recommended_direction = "cut_loop_two_visual_findings_from_real_window_capture"
		else:
			status = "needs_real_window_capture"
			gate = "needs_real_window_capture_run"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_runtime_button.get("schema", "")),
		"source_gate": String(source_runtime_button.get("gate", "")),
		"source_status": String(source_runtime_button.get("status", "")),
		"source_button_text": String(source_runtime_button.get("button_text", "")),
		"source_button_slot_path": String(source_runtime_button.get("button_slot_path", "")),
		"source_runtime_line": String(source_runtime_button.get("runtime_line", "")),
		"manifest_schema": String(manifest.get("schema", "")),
		"manifest_task_id": String(manifest.get("task_id", "")),
		"manifest_available": manifest_available,
		"branch": String(manifest.get("branch", "")),
		"git_head": String(manifest.get("git_head", "")),
		"launch_argument": String(manifest.get("launch_argument", "")),
		"selected_process_id": int(manifest.get("selected_process_id", 0)),
		"capture_process_id": int(manifest.get("capture_process_id", 0)),
		"capture_after_runtime_button_ready": bool(manifest.get("capture_after_runtime_button_ready", false)),
		"window_capture_method": String(manifest.get("window_capture_method", "")),
		"window_capture_trusted": bool(manifest.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(manifest.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(manifest.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(manifest.get("desktop_screenshot_path", "")),
		"source_runtime_button_snapshot": Dictionary(manifest.get("source_runtime_button_snapshot", {})),
		"manual_review_required": bool(manifest.get("manual_review_required", true)),
		"manual_review_done": manual_review_done,
		"required_checks": required_checks,
		"completed_manual_checks": completed_checks,
		"missing_manual_checks": missing_checks,
		"missing_manual_check_count": missing_checks.size(),
		"review_ready": review_ready,
		"accepted": accepted,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
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


static func _build_source_blockers(source_runtime_button: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_runtime_button.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_968-Source-Schema fehlt oder passt nicht."))
	if String(source_runtime_button.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_968."))
	if String(source_runtime_button.get("gate", "")) != "runtime_button_ready":
		blockers.append(_issue("source_runtime_button_not_ready", "TASK_968-Button ist nicht bereit fuer Real-Window-Capture."))
	if not bool(source_runtime_button.get("button_enabled", false)):
		blockers.append(_issue("source_button_disabled", "TASK_968-Button ist nicht aktiv."))
	if not bool(source_runtime_button.get("separate_go_required", false)):
		blockers.append(_issue("source_go_not_separate", "TASK_968-Button haelt GO nicht separat."))
	if not _snapshot_is_read_only(source_runtime_button):
		blockers.append(_issue("source_not_read_only", "TASK_968-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_manifest_blockers(manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "TASK_969-Manifest-Schema fehlt oder passt nicht."))
	if String(manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_969."))
	if String(manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("manifest_source_task_mismatch", "Manifest nennt nicht TASK_968 als Quelle."))
	if String(manifest.get("source_schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("manifest_source_schema_mismatch", "Manifest-Source-Schema passt nicht zu TASK_968."))
	if String(manifest.get("source_gate", "")) != "runtime_button_ready":
		blockers.append(_issue("manifest_source_gate_mismatch", "Manifest-Source-Gate ist nicht runtime_button_ready."))
	if String(manifest.get("launch_argument", "")) != LAUNCH_ARGUMENT:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den Release-First-Decision-Deep-Link."))
	if String(manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_969-Capture-Gate ist fail."))
	if not Array(manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_969-Manifest enthaelt Hard-Failures."))
	if not bool(manifest.get("capture_after_runtime_button_ready", false)):
		blockers.append(_issue("capture_not_after_runtime_button", "Capture wurde nicht nach TASK_968-Runtime-Button-Bereitschaft markiert."))
	if int(manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(manifest.get("capture_process_id", 0)) != int(manifest.get("selected_process_id", 0)):
		blockers.append(_issue("capture_process_mismatch", "Capture nutzt nicht denselben Release-Prozess."))
	if String(manifest.get("window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("capture_method_not_handle_print", "TASK_969-Capture nutzt nicht Window-Handle-Print."))
	if not bool(manifest.get("window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "TASK_969-Window-Capture ist nicht trusted."))
	if not bool(manifest.get("window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_969-Window-Screenshot fehlt."))
	var missing_required: Array = _missing_required_check_ids(Array(manifest.get("required_checks", [])))
	if not missing_required.is_empty():
		blockers.append(_issue("required_checks_missing", "TASK_969-Manifest enthaelt nicht alle Pflichtchecks."))
	return blockers


static func _build_manifest_issues(manifest: Dictionary, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not manual_review_done:
		issues.append(_issue("manual_loop_two_review_open", "Der echte TASK_969-Zweitgriff-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_loop_two_checks_missing", "Nicht alle TASK_969-Pflichtchecks sind als erledigt markiert."))
	if not bool(manifest.get("desktop_screenshot_written", false)):
		issues.append(_issue("desktop_screenshot_missing", "Der TASK_969-Desktop-Screenshot fehlt."))
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


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
