class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopRealWindowCapture
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.v1"
const TASK_ID: String = "TASK_1004"
const SOURCE_TASK_ID: String = "TASK_1003"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.v1"
const SOURCE_READY_STATUS: String = "micro_objective_round_loop_runtime_polish_ready"
const LAUNCH_ARGUMENT: String = "--release-singleplayer-lz-drop-preview"
const REVIEW_TASK: String = "TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture"
const NEXT_TASK: String = "TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings"
const REQUIRED_CAPTURE_CHECKS: PackedStringArray = [
	"real_window_launched",
	"correct_window_content_confirmed",
	"window_capture_trusted",
	"window_screenshot_written",
	"round_surface_visible",
	"next_surface_visible",
	"go_separation_visible",
	"selected_fireteam_runtime_line_visible",
	"mission_control_runtime_line_visible",
	"command_feedback_runtime_line_visible",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
	"manual_visual_review_done",
]


static func build_snapshot(source_runtime_polish: Dictionary, manifest: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_runtime_polish.duplicate(true)
	var capture_manifest: Dictionary = manifest.duplicate(true)
	var blocking_issues: Array = _build_source_blockers(source)
	var source_ready: bool = blocking_issues.is_empty()
	var issues: Array = []
	var missing_manual_checks: Array = []
	var status: String = "blocked"
	var gate: String = "source_blocked"
	var review_ready: bool = false
	var accepted: bool = false
	var recommended_next_task: String = REVIEW_TASK
	if source_ready and capture_manifest.is_empty():
		status = "needs_round_loop_real_window_capture"
		gate = "needs_round_loop_real_window_capture_run"
		issues.append(_issue("round_loop_real_window_capture_manifest_missing", "Echter Fenster-Capture fehlt noch."))
	elif source_ready:
		var manifest_blockers: Array = _build_manifest_blockers(capture_manifest)
		blocking_issues.append_array(manifest_blockers)
		missing_manual_checks = _missing_required_checks(capture_manifest)
		if blocking_issues.is_empty():
			review_ready = true
			if bool(capture_manifest.get("manual_review_done", false)) and missing_manual_checks.is_empty():
				status = "accepted"
				gate = "round_loop_real_window_capture_accepted"
				accepted = true
				recommended_next_task = NEXT_TASK
			else:
				status = "review_ready"
				gate = "round_loop_real_window_capture_review_ready"
				issues.append(_issue("manual_round_loop_review_open", "Technischer Capture ist da, manueller Sichtcheck bleibt offen."))
				recommended_next_task = NEXT_TASK
				if not missing_manual_checks.is_empty():
					issues.append(_issue("round_loop_real_window_capture_checks_missing", "Mindestens ein Pflichtcheck fehlt noch."))
		else:
			status = "blocked"
			gate = "manifest_blocked"
	else:
		recommended_next_task = REVIEW_TASK
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_gate": String(source.get("gate", "")),
		"source_runtime_surface_spec_count": int(source.get("round_loop_runtime_surface_spec_count", 0)),
		"source_runtime_surface_specs": Array(source.get("round_loop_runtime_surface_specs", [])).duplicate(true),
		"source_selected_fireteam_runtime_line": String(source.get("selected_fireteam_runtime_line", "")),
		"source_mission_control_runtime_line": String(source.get("mission_control_runtime_line", "")),
		"source_command_feedback_runtime_line": String(source.get("command_feedback_runtime_line", "")),
		"source_runtime_lines_within_limit": bool(source.get("runtime_lines_within_limit", false)),
		"source_go_separation_visible": bool(source.get("go_separation_visible", false)),
		"source_next_decision_visible": bool(source.get("next_decision_visible", false)),
		"manifest_schema": String(capture_manifest.get("schema", "")),
		"manifest_gate": String(capture_manifest.get("gate", "")),
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", LAUNCH_ARGUMENT)),
		"selected_process_id": int(capture_manifest.get("selected_process_id", 0)),
		"capture_process_id": int(capture_manifest.get("capture_process_id", 0)),
		"capture_after_round_loop_runtime_polish_ready": bool(capture_manifest.get("capture_after_round_loop_runtime_polish_ready", false)),
		"window_capture_method": String(capture_manifest.get("window_capture_method", "")),
		"window_capture_trusted": bool(capture_manifest.get("window_capture_trusted", false)),
		"window_screenshot_written": bool(capture_manifest.get("window_screenshot_written", false)),
		"desktop_screenshot_written": bool(capture_manifest.get("desktop_screenshot_written", false)),
		"window_screenshot_path": String(capture_manifest.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(capture_manifest.get("desktop_screenshot_path", "")),
		"source_runtime_polish_snapshot": Dictionary(capture_manifest.get("source_runtime_polish_snapshot", source)).duplicate(true),
		"manual_review_required": bool(capture_manifest.get("manual_review_required", true)),
		"manual_review_done": bool(capture_manifest.get("manual_review_done", false)),
		"required_checks": Array(capture_manifest.get("required_checks", Array(REQUIRED_CAPTURE_CHECKS))).duplicate(true),
		"completed_manual_checks": Array(capture_manifest.get("completed_manual_checks", [])).duplicate(true),
		"missing_manual_checks": missing_manual_checks,
		"review_ready": review_ready,
		"accepted": accepted,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blocking_issues,
		"blocking_issue_count": blocking_issues.size(),
		"primary_issue_id": String(Dictionary(blocking_issues[0]).get("id", "")) if not blocking_issues.is_empty() else String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "review_round_loop_real_window_visuals" if accepted else "capture_or_review_round_loop_real_window",
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


static func _build_source_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1003-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1003."))
	if String(source.get("status", "")) != SOURCE_READY_STATUS:
		blockers.append(_issue("source_not_ready", "TASK_1003-Source ist noch nicht runtime-polish-ready."))
	if int(source.get("round_loop_runtime_surface_spec_count", 0)) < 3:
		blockers.append(_issue("source_surface_specs_missing", "TASK_1003 liefert nicht alle ROUND/NEXT/GO-Surfaces."))
	if String(source.get("selected_fireteam_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_selected_line_missing", "Selected-Fireteam-Runtime-Zeile fehlt."))
	if String(source.get("mission_control_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_mission_line_missing", "Mission-Control-Runtime-Zeile fehlt."))
	if String(source.get("command_feedback_runtime_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_feedback_line_missing", "Command-Feedback-Runtime-Zeile fehlt."))
	if not bool(source.get("runtime_lines_within_limit", false)):
		blockers.append(_issue("source_runtime_lines_too_long", "TASK_1003 meldet zu lange Runtime-Zeilen."))
	if not bool(source.get("go_separation_visible", false)):
		blockers.append(_issue("source_go_separation_missing", "GO-separat-Grenze ist nicht sichtbar."))
	if not bool(source.get("next_decision_visible", false)):
		blockers.append(_issue("source_next_decision_missing", "NEXT-Entscheidung ist nicht sichtbar."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1003-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_manifest_blockers(manifest: Dictionary) -> Array:
	var blockers: Array = []
	if String(manifest.get("schema", "")) != SCHEMA:
		blockers.append(_issue("manifest_schema_mismatch", "Capture-Manifest nennt nicht TASK_1004-Schema."))
	if String(manifest.get("task_id", "")) != TASK_ID:
		blockers.append(_issue("manifest_task_mismatch", "Capture-Manifest nennt nicht TASK_1004."))
	if String(manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("manifest_source_task_mismatch", "Capture-Manifest zeigt nicht auf TASK_1003."))
	if String(manifest.get("source_schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("manifest_source_schema_mismatch", "Capture-Manifest nennt falsches TASK_1003-Schema."))
	if String(manifest.get("source_status", "")) != SOURCE_READY_STATUS:
		blockers.append(_issue("manifest_source_status_mismatch", "Capture-Manifest wurde nicht nach bereitem TASK_1003 erstellt."))
	if String(manifest.get("launch_argument", "")) != LAUNCH_ARGUMENT:
		blockers.append(_issue("manifest_launch_argument_mismatch", "Capture wurde nicht mit dem Release-Preview-Argument gestartet."))
	if int(manifest.get("selected_process_id", 0)) <= 0:
		blockers.append(_issue("manifest_process_missing", "Ausgewaehlter Godot-Prozess fehlt."))
	if int(manifest.get("capture_process_id", 0)) != int(manifest.get("selected_process_id", -1)):
		blockers.append(_issue("manifest_process_mismatch", "Capture-Prozess entspricht nicht dem ausgewaehlten Fenster."))
	if not bool(manifest.get("capture_after_round_loop_runtime_polish_ready", false)):
		blockers.append(_issue("manifest_capture_timing_invalid", "Capture wurde nicht nach TASK_1003-Ready erstellt."))
	if String(manifest.get("window_capture_method", "")) != "window_handle_print":
		blockers.append(_issue("manifest_capture_method_untrusted", "Capture nutzt nicht den erwarteten Window-Handle-Pfad."))
	if not bool(manifest.get("window_capture_trusted", false)):
		blockers.append(_issue("manifest_window_capture_untrusted", "Window-Capture ist nicht als trusted markiert."))
	if not bool(manifest.get("window_screenshot_written", false)):
		blockers.append(_issue("manifest_window_screenshot_missing", "Window-Screenshot wurde nicht geschrieben."))
	if not String(manifest.get("window_screenshot_path", "")).ends_with(".png"):
		blockers.append(_issue("manifest_window_screenshot_path_invalid", "Window-Screenshot-Pfad ist kein PNG."))
	if Array(manifest.get("hard_failures", [])).size() > 0:
		blockers.append(_issue("manifest_hard_failures", "Capture-Manifest enthaelt harte Fehler."))
	var manifest_checks: Array = Array(manifest.get("required_checks", []))
	for check_id in REQUIRED_CAPTURE_CHECKS:
		if not manifest_checks.has(check_id):
			blockers.append(_issue("manifest_required_check_missing", "Pflichtcheck fehlt im Manifest: %s" % check_id))
	return blockers


static func _missing_required_checks(manifest: Dictionary) -> Array:
	var completed: Array = Array(manifest.get("completed_manual_checks", []))
	var missing: Array = []
	for check_id in REQUIRED_CAPTURE_CHECKS:
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
