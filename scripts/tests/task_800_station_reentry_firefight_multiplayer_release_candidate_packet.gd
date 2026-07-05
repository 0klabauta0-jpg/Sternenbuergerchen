extends SceneTree

const PACKET_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_release_candidate_packet.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_800_station_reentry_firefight_multiplayer_release_candidate_packet.md"
const TASK_799_PATH: String = "res://docs/tasks/TASK_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_release_candidate_packet.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_800 Station Reentry Firefight Multiplayer Release Candidate Packet ===")
	_test_docs_contract_and_report()
	_test_missing_acceptance_blocks()
	_test_unaccepted_acceptance_blocks()
	_test_missing_runtime_files_routes_to_export_refresh()
	_test_clean_acceptance_builds_release_candidate_packet()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_800: FAILED")
		quit(1)
		return
	print("TASK_800: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_800 task file exists")
	_assert(FileAccess.file_exists(TASK_799_PATH), "TASK_799 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Multiplayer Release Candidate Packet"), "TASK_800 task names release candidate packet")
	_assert(status_text.contains("TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet"), "Implementation status tracks TASK_800")
	_assert(roadmap_text.contains("TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet (implementiert)"), "Roadmap marks TASK_800 implemented")
	_assert(roadmap_text.contains("TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings"), "Roadmap advances to TASK_801")
	_assert(contract_text.contains("Station-Reentry-Firefight-Multiplayer-Release-Candidate-Packet"), "Mission command feedback contract documents TASK_800")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_multiplayer_release_candidate_packet.json"), "Reentry handbook names TASK_800 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_multiplayer_release_candidate_packet.release_candidate_packet_ready"'), "Reentry handbook exports TASK_800 ready check")


func _test_missing_acceptance_blocks() -> void:
	var snapshot: Dictionary = Dictionary(PACKET_SCRIPT.call("build_snapshot", {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_multiplayer_release_candidate_packet.v1", "TASK_800 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_multiplayer_playable_candidate_acceptance", "Missing TASK_799 acceptance blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_799"), "Missing acceptance recommends TASK_799")
	_assert(not bool(snapshot.get("release_candidate_packet_ready", true)), "Missing acceptance is not packet-ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-acceptance packet remains read-only")


func _test_unaccepted_acceptance_blocks() -> void:
	var source: Dictionary = _acceptance(false)
	source["status"] = "needs_targeted_multiplayer_playable_candidate_polish"
	source["recommended_next_task"] = "TASK_769 - Station Reentry Performance Feel Pass"
	var snapshot: Dictionary = Dictionary(PACKET_SCRIPT.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_multiplayer_playable_candidate_accepted", "Unaccepted TASK_799 acceptance blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_769"), "Unaccepted acceptance keeps upstream recommendation")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Unaccepted acceptance creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Unaccepted packet remains read-only")


func _test_missing_runtime_files_routes_to_export_refresh() -> void:
	var snapshot: Dictionary = Dictionary(PACKET_SCRIPT.call("build_snapshot", _acceptance(true), {
		"release_files_present": ["Sternenbuergerchen_rel.exe"],
	}))
	_assert(String(snapshot.get("status", "")) == "needs_runtime_release_export_refresh", "Missing runtime files route to export refresh")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("export_runtime_release.ps1"), "Missing runtime files recommend export refresh")
	_assert(Array(snapshot.get("missing_release_files", [])).has("Sternenbuergerchen_rel.pck"), "Missing PCK is reported")
	_assert(not bool(snapshot.get("release_candidate_packet_ready", true)), "Incomplete runtime file list is not ready")
	_assert(_snapshot_is_read_only(snapshot), "Export-refresh packet remains read-only")


func _test_clean_acceptance_builds_release_candidate_packet() -> void:
	var snapshot: Dictionary = Dictionary(PACKET_SCRIPT.call("build_snapshot", _acceptance(true), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_candidate_playtest", "Accepted TASK_799 builds release candidate packet")
	_assert(bool(snapshot.get("release_candidate_packet_ready", false)), "Release candidate packet ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_801"), "Packet routes to TASK_801")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Packet names release EXE")
	_assert(String(snapshot.get("pck_path", "")).ends_with("Sternenbuergerchen_rel.pck"), "Packet names release PCK")
	_assert(Array(snapshot.get("required_release_files", [])).has("liblimboai.windows.template_release.x86_64.dll"), "Packet names LimboAI runtime DLL")
	_assert(int(snapshot.get("release_playtest_check_count", 0)) >= 10, "Packet has concrete release-playtest checks")
	_assert(_has_release_check(snapshot, "singleplayer_homebase_not_blocked"), "Packet checks singleplayer startup")
	_assert(_has_release_check(snapshot, "dropship_payload_not_mixed"), "Packet checks dropship payload consistency")
	_assert(_has_release_check(snapshot, "runtime_export_is_fresh"), "Packet checks stale export risk")
	var commands: Dictionary = Dictionary(snapshot.get("commands", {}))
	_assert(String(commands.get("run_release_exe", "")).contains("Sternenbuergerchen_rel.exe"), "Packet has release EXE command")
	_assert(String(commands.get("runtime_release_export", "")).contains("export_runtime_release.ps1"), "Packet preserves runtime export command")
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Packet preserves Host/Client launch command")
	_assert(_snapshot_is_read_only(snapshot), "Ready packet remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(PACKET_SCRIPT.call("build_snapshot", _acceptance(true), {
		"manifest_path": "tmp/station_reentry_firefight_multiplayer_release_candidate_packet.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_800 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_800 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_800", "Manifest records TASK_800")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_799", "Manifest records TASK_799 source")
	_assert(String(parsed.get("status", "")) == "ready_for_release_candidate_playtest", "Manifest preserves packet status")
	_assert(String(parsed.get("release_dir", "")).contains("Sternenbuergerchen_rel"), "Manifest keeps release dir")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _acceptance(accepted: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_acceptance.v1",
		"task_id": "TASK_799",
		"source_task_id": "TASK_798",
		"status": "accepted_for_multiplayer_playable_candidate" if accepted else "needs_targeted_multiplayer_playable_candidate_polish",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"accepted_for_multiplayer_playable_candidate": accepted,
		"scenario_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"commands": {
			"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch",
			"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14",
			"runtime_release_export": "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1",
		},
		"recommended_next_task": "TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet",
	}


func _has_release_check(snapshot: Dictionary, id: String) -> bool:
	for check_variant in Array(snapshot.get("release_playtest_checks", [])):
		if typeof(check_variant) == TYPE_DICTIONARY and String(Dictionary(check_variant).get("id", "")) == id:
			return true
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
