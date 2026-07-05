class_name StationReentryFirefightMultiplayerPlayableSliceCandidate
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_slice_candidate.v1"
const EXPECTED_ACCEPTANCE_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_acceptance.v1"
const EXPECTED_ACCEPTANCE_TASK_ID: String = "TASK_796"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_decision_playtest_acceptance.json"
const DEFAULT_CANDIDATE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_playable_slice_candidate.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const DEFAULT_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const DEFAULT_WORKBENCH_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const DEFAULT_WINDOW_WIDTH: int = 1450
const DEFAULT_WINDOW_HEIGHT: int = 817
const DEFAULT_CAPTURE_WAIT_SECONDS: int = 14

const PLAYER_FLOW_CHECKPOINTS: Array[Dictionary] = [
	{"id": "singleplayer_homebase_not_blocked", "label": "Einzelspieler/Homebase startet nicht in STOP Team/Dropship/Pilot/Boarding fest"},
	{"id": "host_client_windows_open", "label": "Host und Client laufen nebeneinander sichtbar"},
	{"id": "fireteams_visible_and_distinct", "label": "Fireteams links und in Dropships bleiben unterscheidbar"},
	{"id": "dropship_payload_not_mixed", "label": "Dropship-Payload mischt keine Fireteams/Peers"},
	{"id": "mission_insertion_visible", "label": "Mission, Drop und Ausstieg sind sichtbar nachvollziehbar"},
	{"id": "move_preview_before_go", "label": "Move/Decision-Preview ist vor GO lesbar"},
	{"id": "decision_card_actionable", "label": "Decision-Card nennt naechsten Griff, Alternativen, Warum und Guard"},
	{"id": "first_firefight_response_fast", "label": "Erster Feuerwechsel reagiert schnell genug"},
	{"id": "no_auto_command_commit", "label": "Preview/Decision fuehrt keine Commands automatisch aus"},
	{"id": "exit_or_debrief_path_visible", "label": "Exit/Debrief- oder naechster Handgriff bleibt sichtbar"},
	{"id": "no_hud_overlap_blocker", "label": "HUD verdeckt keine zwingende Aktion"},
]


static func build_snapshot(acceptance_snapshot: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var acceptance_valid: bool = _acceptance_is_valid(acceptance_snapshot)
	var acceptance_read_only: bool = _source_is_read_only(acceptance_snapshot)
	var accepted_slice: bool = bool(acceptance_snapshot.get("accepted_for_multiplayer_decision_playtest_slice", false))
	var scenario_path: String = String(options.get("scenario_path", acceptance_snapshot.get("scenario_path", DEFAULT_SCENARIO_PATH)))
	var workbench_path: String = String(options.get("workbench_path", acceptance_snapshot.get("workbench_path", DEFAULT_WORKBENCH_PATH)))
	var workbench_file_uri: String = String(options.get("workbench_file_uri", _file_uri(workbench_path)))
	var window_width: int = int(options.get("window_width", DEFAULT_WINDOW_WIDTH))
	var window_height: int = int(options.get("window_height", DEFAULT_WINDOW_HEIGHT))
	var wait_seconds: int = int(options.get("capture_wait_seconds", DEFAULT_CAPTURE_WAIT_SECONDS))

	if not acceptance_valid:
		findings.append(_finding("invalid_task_796_acceptance", "blocker", "TASK_796-Acceptance fehlt oder hat Schema/Task-Konflikt.", "TASK_796 - Station Reentry Firefight Multiplayer Decision Playtest Acceptance"))
	if acceptance_valid and not acceptance_read_only:
		findings.append(_finding("task_796_acceptance_not_read_only", "blocker", "TASK_796-Acceptance verletzt read-only/UI-Truth-Grenzen.", "TASK_796 rerun"))
	if acceptance_valid and not accepted_slice:
		findings.append(_finding("task_796_slice_not_accepted", "blocker", "TASK_796 hat den Multiplayer-Decision-Playtest-Slice nicht akzeptiert.", String(acceptance_snapshot.get("recommended_next_task", "TASK_796 rerun"))))
	if scenario_path.strip_edges() == "":
		findings.append(_finding("missing_candidate_scenario", "blocker", "Candidate hat keinen Szenario-Pfad.", "TASK_797 repair scenario path"))
	if workbench_path.strip_edges() == "":
		findings.append(_finding("missing_candidate_workbench", "blocker", "Candidate hat keinen Workbench-Pfad.", "TASK_797 repair workbench path"))

	var commands: Dictionary = _commands(scenario_path, workbench_file_uri, window_width, window_height, wait_seconds)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var status: String = "ready_for_multiplayer_playable_slice_candidate" if blocker_count == 0 else "blocked_until_multiplayer_decision_playtest_acceptance"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_797",
		"source_task_id": EXPECTED_ACCEPTANCE_TASK_ID,
		"source_schema": String(acceptance_snapshot.get("schema", "")),
		"source_status": String(acceptance_snapshot.get("status", "")),
		"source_acceptance_manifest_path": String(options.get("acceptance_manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)),
		"runtime_authority": "read-only playable slice candidate over TASK_796 multiplayer decision playtest acceptance",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"acceptance_valid": acceptance_valid,
		"acceptance_read_only": acceptance_read_only,
		"accepted_for_multiplayer_decision_playtest_slice": accepted_slice,
		"scenario_path": scenario_path,
		"workbench_path": workbench_path,
		"workbench_file_uri": workbench_file_uri,
		"window_width": window_width,
		"window_height": window_height,
		"capture_wait_seconds": wait_seconds,
		"expected_host_role": String(acceptance_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(acceptance_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(acceptance_snapshot.get("expected_decision_line", "")),
		"expected_primary_action_label": String(acceptance_snapshot.get("expected_primary_action_label", "")),
		"expected_quick_action_labels": Array(acceptance_snapshot.get("expected_quick_action_labels", [])).duplicate(true),
		"expected_reason_line": String(acceptance_snapshot.get("expected_reason_line", "")),
		"expected_guard_line": String(acceptance_snapshot.get("expected_guard_line", "")),
		"expected_confirm_control": String(acceptance_snapshot.get("expected_confirm_control", "")),
		"player_flow_checkpoints": PLAYER_FLOW_CHECKPOINTS.duplicate(true),
		"player_flow_checkpoint_count": PLAYER_FLOW_CHECKPOINTS.size(),
		"commands": commands,
		"finding_count": findings.size(),
		"blocking_issue_count": blocker_count,
		"findings": findings,
		"status": status,
		"candidate_ready": status == "ready_for_multiplayer_playable_slice_candidate",
		"summary": _summary(status, PLAYER_FLOW_CHECKPOINTS.size()),
		"recommended_next_task": _recommended_next_task(status, acceptance_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_CANDIDATE_MANIFEST_PATH)),
	}


static func _commands(scenario_path: String, workbench_file_uri: String, window_width: int, window_height: int, wait_seconds: int) -> Dictionary:
	return {
		"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath \"%s\" -WindowWidth %d -WindowHeight %d" % [scenario_path, window_width, window_height],
		"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds %d" % wait_seconds,
		"open_workbench": workbench_file_uri,
		"rerun_candidate_verifier": "godot_console.exe --headless --path . --script scripts/tests/task_797_station_reentry_firefight_multiplayer_playable_slice_candidate.gd",
		"rerun_acceptance_verifier": "godot_console.exe --headless --path . --script scripts/tests/task_796_station_reentry_firefight_multiplayer_decision_playtest_acceptance.gd",
		"runtime_release_export": "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1",
	}


static func _acceptance_is_valid(source: Dictionary) -> bool:
	return not source.is_empty() \
			and String(source.get("schema", "")) == EXPECTED_ACCEPTANCE_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_ACCEPTANCE_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _recommended_next_task(status: String, acceptance_snapshot: Dictionary) -> String:
	if status == "ready_for_multiplayer_playable_slice_candidate":
		return "TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings"
	var next: String = String(acceptance_snapshot.get("recommended_next_task", ""))
	if next.strip_edges() != "":
		return next
	return "TASK_796 - Station Reentry Firefight Multiplayer Decision Playtest Acceptance"


static func _summary(status: String, checkpoint_count: int) -> String:
	if status == "ready_for_multiplayer_playable_slice_candidate":
		return "Playable-Slice-Kandidat bereit: Host/Client starten, %d Spieler-Checkpoints pruefen, Findings in TASK_798 sammeln." % checkpoint_count
	return "Playable-Slice-Kandidat blockiert: TASK_796-Acceptance oder Kandidatenkontext ist nicht gruen."


static func _file_uri(path: String) -> String:
	if path.begins_with("file:///"):
		return path
	return "file:///%s" % ProjectSettings.globalize_path("res://%s" % path).replace("\\", "/")


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count
