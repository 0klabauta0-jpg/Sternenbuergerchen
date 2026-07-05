extends SceneTree

const CANDIDATE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_playable_slice_candidate.gd")
const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_decision_playtest_acceptance.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_797_station_reentry_firefight_multiplayer_playable_slice_candidate.md"
const TASK_796_PATH: String = "res://docs/tasks/TASK_796_station_reentry_firefight_multiplayer_decision_playtest_acceptance.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_playable_slice_candidate.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_797 Station Reentry Firefight Multiplayer Playable Slice Candidate ===")
	_test_docs_contract_and_report()
	_test_missing_acceptance_blocks()
	_test_unaccepted_acceptance_blocks()
	_test_clean_acceptance_builds_candidate()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_797: FAILED")
		quit(1)
		return
	print("TASK_797: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_797 task file exists")
	_assert(FileAccess.file_exists(TASK_796_PATH), "TASK_796 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Multiplayer Playable Slice Candidate"), "TASK_797 task names playable candidate")
	_assert(status_text.contains("TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate"), "Implementation status tracks TASK_797")
	_assert(roadmap_text.contains("TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate (implementiert)"), "Roadmap marks TASK_797 implemented")
	_assert(roadmap_text.contains("TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings"), "Roadmap advances to TASK_798")
	_assert(contract_text.contains("Station-Reentry-Firefight-Multiplayer-Playable-Slice-Candidate"), "Mission command feedback contract documents TASK_797")
	_assert(report_text.contains("Aktueller Griff: TASK_797"), "Reentry handbook marks TASK_797 current")
	_assert(report_text.contains("station_reentry_firefight_multiplayer_playable_slice_candidate.json"), "Reentry handbook names TASK_797 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_multiplayer_playable_slice_candidate.candidate_ready"'), "Reentry handbook exports TASK_797 candidate-ready check")


func _test_missing_acceptance_blocks() -> void:
	var snapshot: Dictionary = Dictionary(CANDIDATE_SCRIPT.call("build_snapshot", {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_slice_candidate.v1", "TASK_797 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_multiplayer_decision_playtest_acceptance", "Missing TASK_796 acceptance blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_796"), "Missing acceptance recommends TASK_796")
	_assert(not bool(snapshot.get("candidate_ready", true)), "Missing acceptance is not ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-acceptance candidate remains read-only")


func _test_unaccepted_acceptance_blocks() -> void:
	var source: Dictionary = _acceptance(false)
	source["status"] = "needs_visible_multiplayer_decision_playtest_review"
	source["recommended_next_task"] = "TASK_794 - run visible multiplayer decision playtest"
	var snapshot: Dictionary = Dictionary(CANDIDATE_SCRIPT.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_multiplayer_decision_playtest_acceptance", "Unaccepted TASK_796 acceptance blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_794"), "Unaccepted acceptance keeps upstream recommendation")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Unaccepted acceptance creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Unaccepted candidate remains read-only")


func _test_clean_acceptance_builds_candidate() -> void:
	var snapshot: Dictionary = Dictionary(CANDIDATE_SCRIPT.call("build_snapshot", _acceptance(true), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_multiplayer_playable_slice_candidate", "Accepted TASK_796 builds candidate")
	_assert(bool(snapshot.get("candidate_ready", false)), "Candidate ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_798"), "Candidate routes to TASK_798")
	_assert(int(snapshot.get("player_flow_checkpoint_count", 0)) >= 10, "Candidate has concrete player-flow checkpoints")
	_assert(_has_checkpoint(snapshot, "dropship_payload_not_mixed"), "Candidate checks dropship fireteam consistency")
	_assert(_has_checkpoint(snapshot, "move_preview_before_go"), "Candidate checks decision preview before GO")
	_assert(_has_checkpoint(snapshot, "first_firefight_response_fast"), "Candidate checks firefight response feel")
	var commands: Dictionary = Dictionary(snapshot.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Candidate has launch command")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Candidate has capture command")
	_assert(String(commands.get("runtime_release_export", "")).contains("export_runtime_release.ps1"), "Candidate names runtime export command")
	_assert(_snapshot_is_read_only(snapshot), "Accepted candidate remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(CANDIDATE_SCRIPT.call("build_snapshot", _acceptance(true), {
		"manifest_path": "tmp/station_reentry_firefight_multiplayer_playable_slice_candidate.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_797 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_797 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_797", "Manifest records TASK_797")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_796", "Manifest records TASK_796 source")
	_assert(String(parsed.get("status", "")) == "ready_for_multiplayer_playable_slice_candidate", "Manifest preserves candidate status")
	_assert(String(parsed.get("scenario_path", "")).contains("station_route_one_screen_multiplayer_drill"), "Manifest keeps scenario path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _acceptance(accepted: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_acceptance.v1",
		"task_id": "TASK_796",
		"source_task_id": "TASK_795",
		"status": "accepted_for_multiplayer_decision_playtest_slice" if accepted else "blocked_until_multiplayer_decision_playtest_acceptance_gates_green",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"accepted_for_multiplayer_decision_playtest_slice": accepted,
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_reason_line": "WHY FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_confirm_control": "existing command buttons / GO",
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"scenario_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"recommended_next_task": "TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate",
	}


func _has_checkpoint(snapshot: Dictionary, id: String) -> bool:
	for checkpoint_variant in Array(snapshot.get("player_flow_checkpoints", [])):
		if typeof(checkpoint_variant) == TYPE_DICTIONARY and String(Dictionary(checkpoint_variant).get("id", "")) == id:
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
