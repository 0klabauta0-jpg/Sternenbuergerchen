class_name ReleaseFirstDecisionIntegratedPlaytest
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_integrated_playtest.v1"
const TASK_ID: String = "TASK_961"
const SOURCE_TASK_ID: String = "TASK_960"
const SOURCE_SCHEMA: String = "sternenbuergerchen.first_decision_release_playable_slice.v1"
const FIRST_DECISION_ARG: String = "--release-singleplayer-lz-drop-preview"
const NEXT_REVIEW_TASK: String = "TASK_961 - Release First Decision Integrated Playtest"
const NEXT_TASK: String = "TASK_962 - Release First Decision Playtest Findings"

const REQUIRED_PLAYTEST_CHECKS: PackedStringArray = [
	"release_exe_launched",
	"correct_window_content_confirmed",
	"window_capture_trusted",
	"window_screenshot_written",
	"homebase_to_mission_observed",
	"dropship_lz_drop_observed",
	"first_decision_preview_observed",
	"go_executed",
	"post_go_feedback_observed",
	"no_command_before_go_confirmed",
	"performance_ok",
	"no_new_hud_gameplay_truth",
	"multiplayer_snapshot_boundary_preserved",
	"manual_playtest_done",
]


static func build_snapshot(source_slice: Dictionary, manifest: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_slice)
	var manifest_available: bool = bool(manifest.get("manifest_available", false))
	var missing_checks: Array = _missing_playtest_checks(manifest)
	var issues: Array = []
	if blockers.is_empty():
		if not manifest_available:
			issues.append(_issue("integrated_playtest_manifest_missing", "Der integrierte First-Decision-Playtest wurde noch nicht als Manifest belegt."))
		else:
			issues = _build_manifest_issues(manifest, missing_checks)
	var passed: bool = blockers.is_empty() and manifest_available and issues.is_empty() and missing_checks.is_empty()
	var gate: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "run_release_first_decision_integrated_playtest"
	if blockers.is_empty():
		if passed:
			gate = "integrated_playtest_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "cut_release_first_decision_playtest_findings"
		elif manifest_available:
			gate = "integrated_playtest_regression_found"
			recommended_next_task = NEXT_TASK
			recommended_direction = "cut_release_first_decision_playtest_regression_findings"
		else:
			gate = "needs_integrated_playtest_run"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_slice.get("schema", "")),
		"source_gate": String(source_slice.get("gate", "")),
		"source_release_slice_playable": bool(source_slice.get("release_slice_playable", false)),
		"manifest_schema": String(manifest.get("schema", "")),
		"manifest_task_id": String(manifest.get("task_id", "")),
		"manifest_available": manifest_available,
		"launch_argument": String(manifest.get("launch_argument", "")),
		"selected_process_id": int(manifest.get("selected_process_id", 0)),
		"capture_process_id": int(manifest.get("capture_process_id", 0)),
		"required_playtest_checks": Array(REQUIRED_PLAYTEST_CHECKS),
		"missing_playtest_checks": missing_checks,
		"missing_playtest_check_count": missing_checks.size(),
		"observed_release_stages": _observed_release_stages(manifest) if manifest_available else [],
		"integrated_playtest_passed": passed,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
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


static func _build_blockers(source_slice: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_slice.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_960-Slice-Schema fehlt oder passt nicht."))
	if String(source_slice.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_960."))
	if String(source_slice.get("gate", "")) != "release_slice_playable" or not bool(source_slice.get("release_slice_playable", false)):
		blockers.append(_issue("source_slice_not_playable", "TASK_960-Source ist nicht als release-spielbarer Slice akzeptiert."))
	if not bool(source_slice.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_960-Source ist nicht read-only."))
	if bool(source_slice.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_960-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_manifest_issues(manifest: Dictionary, missing_checks: Array) -> Array:
	var issues: Array = []
	if String(manifest.get("schema", "")) != SCHEMA:
		issues.append(_issue("manifest_schema_mismatch", "TASK_961-Manifest-Schema fehlt oder passt nicht."))
	if String(manifest.get("task_id", "")) != TASK_ID:
		issues.append(_issue("manifest_task_mismatch", "Manifest nennt nicht TASK_961."))
	if String(manifest.get("launch_argument", "")) != FIRST_DECISION_ARG:
		issues.append(_issue("launch_argument_mismatch", "Der integrierte Playtest nutzt nicht den First-Decision-Deep-Link."))
	if int(manifest.get("selected_process_id", 0)) <= 0:
		issues.append(_issue("selected_process_missing", "Release-Prozess-ID fehlt."))
	if int(manifest.get("capture_process_id", 0)) != int(manifest.get("selected_process_id", 0)):
		issues.append(_issue("capture_process_mismatch", "Capture nutzt nicht denselben Release-Prozess."))
	if bool(manifest.get("updates_shortcuts", false)):
		issues.append(_issue("shortcut_update_risk", "Der integrierte Playtest darf keine Shortcuts aktualisieren."))
	for check_id_variant in missing_checks:
		var check_id: String = String(check_id_variant)
		issues.append(_issue(_issue_id_for_missing_check(check_id), _text_for_missing_check(check_id)))
	return issues


static func _missing_playtest_checks(manifest: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_PLAYTEST_CHECKS:
		if not bool(manifest.get(String(check_id), false)):
			missing.append(String(check_id))
	return missing


static func _observed_release_stages(manifest: Dictionary) -> Array:
	var stages: Array = []
	if bool(manifest.get("release_exe_launched", false)) and int(manifest.get("selected_process_id", 0)) > 0:
		stages.append("release_launch")
	if bool(manifest.get("homebase_to_mission_observed", false)):
		stages.append("homebase_to_mission")
	if bool(manifest.get("dropship_lz_drop_observed", false)):
		stages.append("dropship_lz_drop")
	if bool(manifest.get("first_decision_preview_observed", false)):
		stages.append("first_decision_preview")
	if bool(manifest.get("go_executed", false)) and bool(manifest.get("post_go_feedback_observed", false)):
		stages.append("go_and_post_go_feedback")
	return stages


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"post_go_feedback_observed":
			return "post_go_feedback_missing"
		"performance_ok":
			return "performance_not_ok"
		"no_new_hud_gameplay_truth":
			return "hud_gameplay_truth_risk"
		"multiplayer_snapshot_boundary_preserved":
			return "multiplayer_snapshot_boundary_risk"
		_:
			return "%s_missing" % check_id


static func _text_for_missing_check(check_id: String) -> String:
	match check_id:
		"release_exe_launched":
			return "Release-EXE wurde nicht belegt gestartet."
		"correct_window_content_confirmed":
			return "Korrektes Sternenbuergerchen-Fenster ist nicht bestaetigt."
		"window_capture_trusted":
			return "Window-Capture ist nicht trusted."
		"window_screenshot_written":
			return "Window-Screenshot fehlt."
		"homebase_to_mission_observed":
			return "Homebase-bis-Mission wurde nicht beobachtet."
		"dropship_lz_drop_observed":
			return "Dropship/LZ/Drop wurde nicht beobachtet."
		"first_decision_preview_observed":
			return "First-Decision-Preview wurde nicht beobachtet."
		"go_executed":
			return "GO wurde nicht ausgefuehrt."
		"post_go_feedback_observed":
			return "Post-GO-Feedback wurde nicht beobachtet."
		"no_command_before_go_confirmed":
			return "Kein Command vor GO wurde nicht bestaetigt."
		"performance_ok":
			return "Performance-/Hotpath-Status ist nicht ok."
		"no_new_hud_gameplay_truth":
			return "HUD-Read-only-Grenze ist nicht bestaetigt."
		"multiplayer_snapshot_boundary_preserved":
			return "Multiplayer-Snapshot-Grenze ist nicht bestaetigt."
		"manual_playtest_done":
			return "Manuelle Playtest-Abnahme fehlt."
		_:
			return "Ein Playtest-Pflichtcheck fehlt: %s." % check_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
