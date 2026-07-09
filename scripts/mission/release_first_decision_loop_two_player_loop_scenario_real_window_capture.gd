class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioRealWindowCapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_real_window_capture.v1"
const TASK_ID: String = "TASK_1018"
const SOURCE_TASK_ID: String = "TASK_1017"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_playability_slice.v1"
const LAUNCH_ARGUMENT: String = "--release-singleplayer-lz-drop-preview"
const NEXT_TASK: String = "TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings"
const REVIEW_TASK: String = "TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture"

const REQUIRED_CAPTURE_CHECKS: PackedStringArray = [
	"real_window_launched",
	"correct_window_content_confirmed",
	"window_capture_trusted",
	"window_screenshot_written",
	"fob_entry_surface_visible",
	"objective_surface_visible",
	"roles_surface_visible",
	"next_confirm_go_flow_visible",
	"go_boundary_visible",
	"feedback_line_visible",
	"calm_hud_guidance_visible",
	"scenario_playability_line_visible",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
	"manual_visual_review_done",
]


static func build_snapshot(source_scenario_playability_slice: Dictionary, manifest: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_scenario_playability_slice)
	var manifest_available: bool = not manifest.is_empty()
	var manifest_blockers: Array = _build_manifest_blockers(manifest) if blockers.is_empty() and manifest_available else []
	var required_checks: Array = Array(manifest.get("required_checks", []))
	var completed_checks: Array = Array(manifest.get("completed_manual_checks", []))
	var missing_checks: Array = _missing_checks(required_checks, completed_checks)
	var manual_review_done: bool = bool(manifest.get("manual_review_done", false))
	var issues: Array = []
	if blockers.is_empty():
		if not manifest_available:
			issues.append(_issue("scenario_real_window_capture_manifest_missing", "TASK_1018-Scenario-Real-Window-Capture-Manifest fehlt."))
		elif manifest_blockers.is_empty():
			issues = _build_manifest_issues(manifest, missing_checks, manual_review_done)
	blockers.append_array(manifest_blockers)
	var review_ready: bool = blockers.is_empty() and manifest_available and String(manifest.get("gate", "")) in ["review_ready", "accepted", "review"]
	var accepted: bool = review_ready and manual_review_done and missing_checks.is_empty() and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "run_scenario_real_window_capture"
	if blockers.is_empty():
		if accepted:
			status = "accepted"
			gate = "scenario_real_window_capture_accepted"
			recommended_next_task = NEXT_TASK
			recommended_direction = "cut_scenario_visual_findings"
		elif manifest_available:
			status = "review_ready"
			gate = "scenario_real_window_capture_review_ready"
			recommended_next_task = NEXT_TASK
			recommended_direction = "cut_scenario_visual_findings"
		else:
			status = "needs_scenario_real_window_capture"
			gate = "needs_scenario_real_window_capture_run"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_scenario_playability_slice.get("schema", "")),
		"source_gate": String(source_scenario_playability_slice.get("gate", "")),
		"source_status": String(source_scenario_playability_slice.get("status", "")),
		"source_scenario_playability_line": String(source_scenario_playability_slice.get("scenario_playability_line", "")),
		"source_scenario_playability_slice_passed": bool(source_scenario_playability_slice.get("scenario_playability_slice_passed", false)),
		"source_ready_for_real_window_capture": bool(source_scenario_playability_slice.get("ready_for_real_window_capture", false)),
		"manifest_schema": String(manifest.get("schema", "")),
		"manifest_task_id": String(manifest.get("task_id", "")),
		"manifest_available": manifest_available,
		"branch": String(manifest.get("branch", "")),
		"git_head": String(manifest.get("git_head", "")),
		"launch_argument": String(manifest.get("launch_argument", "")),
		"selected_process_id": int(manifest.get("selected_process_id", 0)),
		"capture_process_id": int(manifest.get("capture_process_id", 0)),
		"capture_after_scenario_playability_slice_passed": bool(manifest.get("capture_after_scenario_playability_slice_passed", false)),
		"window_capture_method": String(manifest.get("window_capture_method", "")),
		"window_capture_trusted": bool(manifest.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(manifest.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(manifest.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(manifest.get("desktop_screenshot_path", "")),
		"source_scenario_playability_slice_snapshot": Dictionary(manifest.get("source_scenario_playability_slice_snapshot", {})),
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


static func _build_source_blockers(source_scenario_playability_slice: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_scenario_playability_slice.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1017-Source-Schema fehlt oder passt nicht."))
	if String(source_scenario_playability_slice.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1017."))
	if String(source_scenario_playability_slice.get("gate", "")) != "scenario_playability_passed":
		blockers.append(_issue("source_scenario_playability_not_passed", "TASK_1017-Scenario-Playability-Slice ist nicht bestanden."))
	if not bool(source_scenario_playability_slice.get("scenario_playability_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1017-Source setzt scenario_playability_slice_passed nicht."))
	if not bool(source_scenario_playability_slice.get("ready_for_real_window_capture", false)):
		blockers.append(_issue("source_not_ready_for_real_window_capture", "TASK_1017-Source ist nicht ready_for_real_window_capture."))
	var playability_line: String = String(source_scenario_playability_slice.get("scenario_playability_line", "")).strip_edges()
	if playability_line.is_empty():
		blockers.append(_issue("source_scenario_playability_line_missing", "TASK_1017-Playability-Zeile fehlt."))
	if not playability_line.contains("FOB") or not playability_line.contains("NEXT") or not playability_line.contains("GO") or not playability_line.contains("FEEDBACK"):
		blockers.append(_issue("source_scenario_playability_line_incomplete", "TASK_1017-Playability-Zeile muss FOB, NEXT, GO und FEEDBACK nennen."))
	if not _snapshot_is_read_only(source_scenario_playability_slice):
		blockers.append(_issue("source_not_read_only", "TASK_1017-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_manifest_blockers(manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "TASK_1018-Manifest-Schema fehlt oder passt nicht."))
	if String(manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_1018."))
	if String(manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("manifest_source_task_mismatch", "Manifest nennt nicht TASK_1017 als Quelle."))
	if String(manifest.get("source_schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("manifest_source_schema_mismatch", "Manifest-Source-Schema passt nicht zu TASK_1017."))
	if String(manifest.get("source_gate", "")) != "scenario_playability_passed":
		blockers.append(_issue("manifest_source_gate_mismatch", "Manifest-Source-Gate ist nicht scenario_playability_passed."))
	if String(manifest.get("launch_argument", "")) != LAUNCH_ARGUMENT:
		blockers.append(_issue("launch_argument_mismatch", "Manifest nutzt nicht den Release-First-Decision-Deep-Link."))
	if String(manifest.get("gate", "")) == "fail":
		blockers.append(_issue("capture_gate_failed", "TASK_1018-Capture-Gate ist fail."))
	if not Array(manifest.get("hard_failures", [])).is_empty():
		blockers.append(_issue("hard_failures_present", "TASK_1018-Manifest enthaelt Hard-Failures."))
	if not bool(manifest.get("capture_after_scenario_playability_slice_passed", false)):
		blockers.append(_issue("capture_not_after_scenario_playability_slice", "Capture wurde nicht nach bestandenem TASK_1017-Slice markiert."))
	if int(manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(manifest.get("capture_process_id", 0)) != int(manifest.get("selected_process_id", 0)):
		blockers.append(_issue("capture_process_mismatch", "Capture nutzt nicht denselben Release-Prozess."))
	if String(manifest.get("window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("capture_method_not_handle_print", "TASK_1018-Capture nutzt nicht Window-Handle-Print."))
	if not bool(manifest.get("window_capture_trusted", false)):
		blockers.append(_issue("window_capture_not_trusted", "TASK_1018-Window-Capture ist nicht trusted."))
	if not bool(manifest.get("window_screenshot_written", false)):
		blockers.append(_issue("window_screenshot_missing", "TASK_1018-Window-Screenshot fehlt."))
	var missing_required: Array = _missing_required_check_ids(Array(manifest.get("required_checks", [])))
	if not missing_required.is_empty():
		blockers.append(_issue("required_checks_missing", "TASK_1018-Manifest enthaelt nicht alle Pflichtchecks."))
	return blockers


static func _build_manifest_issues(manifest: Dictionary, missing_checks: Array, manual_review_done: bool) -> Array:
	var issues: Array = []
	if not manual_review_done:
		issues.append(_issue("manual_scenario_review_open", "Der echte TASK_1018-Szenario-Sichtbefund ist noch nicht manuell bewertet."))
	if not missing_checks.is_empty():
		issues.append(_issue("manual_scenario_checks_missing", "Nicht alle TASK_1018-Pflichtchecks sind als erledigt markiert."))
	if not bool(manifest.get("desktop_screenshot_written", false)):
		issues.append(_issue("desktop_screenshot_missing", "Der TASK_1018-Desktop-Screenshot fehlt."))
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
