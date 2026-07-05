class_name StationReentryFirefightMultiplayerReleaseCandidatePacket
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_release_candidate_packet.v1"
const EXPECTED_ACCEPTANCE_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_acceptance.v1"
const EXPECTED_ACCEPTANCE_TASK_ID: String = "TASK_799"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_playable_candidate_acceptance.json"
const DEFAULT_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_release_candidate_packet.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const DEFAULT_RELEASE_DIR: String = "C:/dev/Sternenbuergerchen_rel"
const DEFAULT_EXE_PATH: String = "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe"
const DEFAULT_CONSOLE_EXE_PATH: String = "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.console.exe"
const DEFAULT_PCK_PATH: String = "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.pck"

const REQUIRED_RELEASE_FILES: Array[String] = [
	"Sternenbuergerchen_rel.exe",
	"Sternenbuergerchen_rel.pck",
	"liblimboai.windows.template_release.x86_64.dll",
	"libterrain.windows.release.x86_64.dll",
]

const RELEASE_PLAYTEST_CHECKS: Array[Dictionary] = [
	{"id": "singleplayer_homebase_not_blocked", "label": "Einzelspieler startet in einen handlungsfaehigen Homebase-/FOB-Zustand"},
	{"id": "host_client_windows_open", "label": "Host und Client koennen nebeneinander gestartet werden"},
	{"id": "fireteams_visible_and_distinct", "label": "Fireteams bleiben links und in Dropships unterscheidbar"},
	{"id": "dropship_payload_not_mixed", "label": "Dropship-Payload mischt keine Fireteams oder Peer-Rollen"},
	{"id": "mission_insertion_visible", "label": "Drop, Ausstieg und erster Missionsgriff sind sichtbar"},
	{"id": "move_preview_before_go", "label": "Move/Decision-Preview bleibt vor GO lesbar"},
	{"id": "decision_card_actionable", "label": "Decision-Card nennt Griff, Alternativen, Warum und Guard"},
	{"id": "first_firefight_response_fast", "label": "Erster Feuerwechsel fuehlt sich zuegig an"},
	{"id": "exit_or_debrief_path_visible", "label": "Exit/Debrief oder naechster Handgriff ist sichtbar"},
	{"id": "no_hud_overlap_blocker", "label": "HUD verdeckt keine zwingende Aktion"},
	{"id": "runtime_export_is_fresh", "label": "Getestet wird der aktuelle Release-Export, kein alter tmp/export_check-Build"},
]


static func build_snapshot(acceptance_snapshot: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var acceptance_valid: bool = _acceptance_is_valid(acceptance_snapshot)
	var acceptance_read_only: bool = _source_is_read_only(acceptance_snapshot)
	var accepted_candidate: bool = bool(acceptance_snapshot.get("accepted_for_multiplayer_playable_candidate", false))
	var release_dir: String = String(options.get("release_dir", DEFAULT_RELEASE_DIR))
	var exe_path: String = String(options.get("exe_path", DEFAULT_EXE_PATH))
	var console_exe_path: String = String(options.get("console_exe_path", DEFAULT_CONSOLE_EXE_PATH))
	var pck_path: String = String(options.get("pck_path", DEFAULT_PCK_PATH))
	var required_files: Array = Array(options.get("required_release_files", REQUIRED_RELEASE_FILES)).duplicate(true)
	var release_files_present: Array = Array(options.get("release_files_present", required_files)).duplicate(true)
	var missing_release_files: Array[String] = _missing_release_files(required_files, release_files_present)
	var commands: Dictionary = _commands(acceptance_snapshot, exe_path, console_exe_path)

	if not acceptance_valid:
		findings.append(_finding("invalid_task_799_acceptance", "blocker", "TASK_799-Acceptance fehlt oder hat Schema/Task-Konflikt.", "TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"))
	if acceptance_valid and not acceptance_read_only:
		findings.append(_finding("task_799_acceptance_not_read_only", "blocker", "TASK_799-Acceptance verletzt read-only/UI-Truth-Grenzen.", "TASK_799 rerun"))
	if acceptance_valid and not accepted_candidate:
		findings.append(_finding("task_799_candidate_not_accepted", "blocker", "TASK_799 hat den Multiplayer-Playable-Candidate nicht akzeptiert.", String(acceptance_snapshot.get("recommended_next_task", "TASK_799 rerun"))))
	if release_dir.strip_edges() == "" or exe_path.strip_edges() == "" or pck_path.strip_edges() == "":
		findings.append(_finding("release_paths_incomplete", "blocker", "Release-Ordner, EXE oder PCK fehlen im Paket.", "TASK_800 repair release packet paths"))
	if not missing_release_files.is_empty():
		findings.append(_finding("release_file_manifest_incomplete", "manual", "Release-Dateiliste ist nicht vollstaendig: %s" % ", ".join(PackedStringArray(missing_release_files)), "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1"))

	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var status: String = "ready_for_release_candidate_playtest" if blocker_count == 0 and missing_release_files.is_empty() else _blocked_status(acceptance_valid, acceptance_read_only, accepted_candidate, missing_release_files)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_800",
		"source_task_id": EXPECTED_ACCEPTANCE_TASK_ID,
		"source_schema": String(acceptance_snapshot.get("schema", "")),
		"source_status": String(acceptance_snapshot.get("status", "")),
		"source_acceptance_manifest_path": String(options.get("acceptance_manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)),
		"runtime_authority": "read-only release candidate packet over TASK_799 multiplayer playable candidate acceptance",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"acceptance_valid": acceptance_valid,
		"acceptance_read_only": acceptance_read_only,
		"accepted_for_multiplayer_playable_candidate": accepted_candidate,
		"release_dir": release_dir,
		"exe_path": exe_path,
		"console_exe_path": console_exe_path,
		"pck_path": pck_path,
		"required_release_files": required_files,
		"release_files_present": release_files_present,
		"missing_release_files": missing_release_files,
		"scenario_path": String(acceptance_snapshot.get("scenario_path", "")),
		"workbench_path": String(acceptance_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(acceptance_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(acceptance_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(acceptance_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(acceptance_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(acceptance_snapshot.get("expected_guard_line", "")),
		"release_playtest_checks": RELEASE_PLAYTEST_CHECKS.duplicate(true),
		"release_playtest_check_count": RELEASE_PLAYTEST_CHECKS.size(),
		"manual_release_playtest_required": true,
		"manual_release_playtest_done": false,
		"commands": commands,
		"finding_count": findings.size(),
		"blocking_issue_count": blocker_count,
		"findings": findings,
		"status": status,
		"release_candidate_packet_ready": status == "ready_for_release_candidate_playtest",
		"summary": _summary(status, RELEASE_PLAYTEST_CHECKS.size(), release_dir),
		"recommended_next_task": _recommended_next_task(status, acceptance_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_PACKET_MANIFEST_PATH)),
	}


static func _commands(source: Dictionary, exe_path: String, console_exe_path: String) -> Dictionary:
	var source_commands: Dictionary = Dictionary(source.get("commands", {}))
	return {
		"run_release_exe": "\"%s\"" % exe_path,
		"run_release_console": "\"%s\"" % console_exe_path,
		"runtime_release_export": String(source_commands.get("runtime_release_export", "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1")),
		"launch_windows": String(source_commands.get("launch_windows", "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch")),
		"capture_windows": String(source_commands.get("capture_windows", "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14")),
		"open_workbench": String(source.get("workbench_file_uri", "")),
		"rerun_packet_verifier": "godot_console.exe --headless --path . --script scripts/tests/task_800_station_reentry_firefight_multiplayer_release_candidate_packet.gd",
		"rerun_acceptance_verifier": "godot_console.exe --headless --path . --script scripts/tests/task_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.gd",
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


static func _missing_release_files(required_files: Array, present_files: Array) -> Array[String]:
	var present: Dictionary = {}
	for item in present_files:
		present[String(item)] = true
	var missing: Array[String] = []
	for item in required_files:
		var file_name: String = String(item)
		if not present.has(file_name):
			missing.append(file_name)
	return missing


static func _blocked_status(acceptance_valid: bool, acceptance_read_only: bool, accepted_candidate: bool, missing_release_files: Array[String]) -> String:
	if not acceptance_valid or not acceptance_read_only:
		return "blocked_until_multiplayer_playable_candidate_acceptance"
	if not accepted_candidate:
		return "blocked_until_multiplayer_playable_candidate_accepted"
	if not missing_release_files.is_empty():
		return "needs_runtime_release_export_refresh"
	return "blocked_until_release_candidate_packet_complete"


static func _recommended_next_task(status: String, source: Dictionary) -> String:
	match status:
		"blocked_until_multiplayer_playable_candidate_acceptance":
			return "TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"
		"blocked_until_multiplayer_playable_candidate_accepted":
			return String(source.get("recommended_next_task", "TASK_799 - accept Station Reentry Firefight Multiplayer Playable Candidate"))
		"needs_runtime_release_export_refresh":
			return "TASK_800 - rerun scripts/tools/export_runtime_release.ps1 and refresh release packet"
		"ready_for_release_candidate_playtest":
			return "TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings"
	return "TASK_800 - repair Station Reentry Firefight Multiplayer Release Candidate Packet"


static func _summary(status: String, check_count: int, release_dir: String) -> String:
	match status:
		"blocked_until_multiplayer_playable_candidate_acceptance":
			return "Release-Candidate-Paket blockiert: TASK_799-Acceptance fehlt oder ist nicht read-only."
		"blocked_until_multiplayer_playable_candidate_accepted":
			return "Release-Candidate-Paket blockiert: Multiplayer-Playable-Candidate ist noch nicht akzeptiert."
		"needs_runtime_release_export_refresh":
			return "Release-Candidate-Paket braucht einen vollstaendigen frischen Runtime-Export."
		"ready_for_release_candidate_playtest":
			return "Release-Candidate-Paket bereit: %d Checks im Ordner %s sichtbar testen." % [check_count, release_dir]
	return "Release-Candidate-Paket ist unvollstaendig."


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
