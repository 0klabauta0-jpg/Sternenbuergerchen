extends SceneTree

const SHIP_READINESS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_ship_readiness.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_803_station_reentry_firefight_release_candidate_ship_readiness.md"
const TASK_802_PATH: String = "res://docs/tasks/TASK_802_station_reentry_firefight_release_candidate_acceptance.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_ship_readiness.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_803 Station Reentry Firefight Release Candidate Ship Readiness ===")
	_test_docs_contract_and_report()
	_test_missing_acceptance_blocks()
	_test_unaccepted_acceptance_blocks()
	_test_missing_ship_item_routes_to_completion()
	_test_clean_acceptance_builds_ship_readiness()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_803: FAILED")
		quit(1)
		return
	print("TASK_803: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_803 task file exists")
	_assert(FileAccess.file_exists(TASK_802_PATH), "TASK_802 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Ship Readiness"), "TASK_803 task names ship readiness")
	_assert(status_text.contains("TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness"), "Implementation status tracks TASK_803")
	_assert(roadmap_text.contains("TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness (implementiert)"), "Roadmap marks TASK_803 implemented")
	_assert(roadmap_text.contains("TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke"), "Roadmap advances to TASK_804")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Ship-Readiness"), "Mission command feedback contract documents TASK_803")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_ship_readiness.json"), "Reentry handbook names TASK_803 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_ship_readiness.ship_readiness_ready"'), "Reentry handbook exports TASK_803 ready check")


func _test_missing_acceptance_blocks() -> void:
	var snapshot: Dictionary = Dictionary(SHIP_READINESS_SCRIPT.call("build_snapshot", {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_ship_readiness.v1", "TASK_803 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_release_candidate_acceptance", "Missing TASK_802 acceptance blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_802"), "Missing acceptance recommends TASK_802")
	_assert(not bool(snapshot.get("ship_readiness_ready", true)), "Missing acceptance is not ship-ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-acceptance ship readiness remains read-only")


func _test_unaccepted_acceptance_blocks() -> void:
	var source: Dictionary = _acceptance(false)
	source["status"] = "needs_targeted_release_candidate_polish"
	source["recommended_next_task"] = "TASK_769 - Station Reentry Performance Feel Pass"
	var snapshot: Dictionary = Dictionary(SHIP_READINESS_SCRIPT.call("build_snapshot", source, _ready_options()))
	_assert(String(snapshot.get("status", "")) == "blocked_until_release_candidate_accepted", "Unaccepted TASK_802 acceptance blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_769"), "Unaccepted acceptance keeps upstream recommendation")
	_assert(not bool(snapshot.get("ship_readiness_ready", true)), "Unaccepted source is not ship-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unaccepted ship readiness remains read-only")


func _test_missing_ship_item_routes_to_completion() -> void:
	var options: Dictionary = _ready_options()
	var item_statuses: Dictionary = Dictionary(options.get("item_statuses", {}))
	item_statuses["runtime_dlls_present"] = false
	options["item_statuses"] = item_statuses
	var snapshot: Dictionary = Dictionary(SHIP_READINESS_SCRIPT.call("build_snapshot", _acceptance(true), options))
	_assert(String(snapshot.get("status", "")) == "needs_ship_readiness_completion", "Missing ship item routes to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_803"), "Missing ship item recommends TASK_803 completion")
	_assert(Array(snapshot.get("missing_item_ids", [])).has("runtime_dlls_present"), "Missing runtime DLL item is reported")
	_assert(not bool(snapshot.get("ship_readiness_ready", true)), "Incomplete ship item list is not ready")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete ship readiness remains read-only")


func _test_clean_acceptance_builds_ship_readiness() -> void:
	var snapshot: Dictionary = Dictionary(SHIP_READINESS_SCRIPT.call("build_snapshot", _acceptance(true), _ready_options()))
	_assert(String(snapshot.get("status", "")) == "ready_for_ship_readiness_review", "Accepted TASK_802 builds ship readiness")
	_assert(bool(snapshot.get("ship_readiness_ready", false)), "Ship readiness ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_804"), "Ship readiness routes to TASK_804")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Ship readiness names release EXE")
	_assert(String(snapshot.get("pck_path", "")).ends_with("Sternenbuergerchen_rel.pck"), "Ship readiness names release PCK")
	_assert(int(snapshot.get("ship_readiness_item_count", 0)) >= 10, "Ship readiness has concrete checklist")
	_assert(Array(snapshot.get("missing_item_ids", [])).is_empty(), "Ready ship readiness has no missing items")
	_assert(int(snapshot.get("known_open_risk_count", 0)) >= 2, "Ship readiness carries open risks")
	var commands: Dictionary = Dictionary(snapshot.get("commands", {}))
	_assert(String(commands.get("run_release_exe", "")).contains("Sternenbuergerchen_rel.exe"), "Ship readiness has release EXE command")
	_assert(String(commands.get("runtime_release_export", "")).contains("export_runtime_release.ps1"), "Ship readiness preserves export command")
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Ship readiness preserves Host/Client launch command")
	_assert(_snapshot_is_read_only(snapshot), "Ready ship readiness remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(SHIP_READINESS_SCRIPT.call("build_snapshot", _acceptance(true), _ready_options({
		"manifest_path": "tmp/station_reentry_firefight_release_candidate_ship_readiness.json",
	})))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_803 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_803 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_803", "Manifest records TASK_803")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_802", "Manifest records TASK_802 source")
	_assert(String(parsed.get("status", "")) == "ready_for_ship_readiness_review", "Manifest preserves ship readiness status")
	_assert(String(parsed.get("recommended_next_task", "")).contains("TASK_804"), "Manifest preserves TASK_804 next step")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _acceptance(accepted: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_release_candidate_acceptance.v1",
		"task_id": "TASK_802",
		"source_task_id": "TASK_801",
		"status": "accepted_for_release_candidate" if accepted else "needs_targeted_release_candidate_polish",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"accepted_for_release_candidate": accepted,
		"source_findings_manifest_path": "tmp/station_reentry_firefight_release_candidate_playtest_findings.json",
		"release_dir": "C:/dev/Sternenbuergerchen_rel",
		"exe_path": "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe",
		"pck_path": "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.pck",
		"scenario_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"commands": {
			"run_release_exe": "\"C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe\"",
			"runtime_release_export": "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1",
			"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch",
			"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14",
		},
		"recommended_next_task": "TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness",
	}


func _ready_options(extra: Dictionary = {}) -> Dictionary:
	var options: Dictionary = {
		"acceptance_manifest_path": "tmp/station_reentry_firefight_release_candidate_acceptance.json",
		"item_statuses": {
			"release_exe_present": true,
			"release_pck_present": true,
			"runtime_dlls_present": true,
			"launch_command_available": true,
			"export_command_available": true,
			"workbench_report_available": true,
			"playtest_findings_manifest_available": true,
			"acceptance_manifest_available": true,
			"known_open_risks_listed": true,
			"next_operator_instruction_present": true,
		},
	}
	for key in extra.keys():
		options[key] = extra.get(key)
	return options


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
