extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_playtest_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_761_station_reentry_visible_playtest_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const PACKET_PATH: String = "res://tmp/station_reentry_playtest_run_packet.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_visible_playtest_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_761 Station Reentry Visible Playtest Findings ===")
	_test_docs_contract_and_reports()
	_test_missing_packet_blocks()
	_test_open_reentry_needs_visible_playtest()
	_test_incomplete_reentry_checks()
	_test_issue_flags_create_action_items()
	_test_clean_reentry_ready_for_next_iteration()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_761: FAILED")
		quit(1)
		return
	print("TASK_761: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_761 task file exists")
	_assert(task_text.contains("Station Reentry Visible Playtest Findings"), "Task documents Reentry findings")
	_assert(contract_text.contains("Station-Reentry-Visible-Playtest-Findings (TASK_761)"), "Contract documents TASK_761")
	_assert(status_text.contains("TASK_761 - Station Reentry Visible Playtest Findings"), "Implementation status tracks TASK_761")
	_assert(roadmap_text.contains("TASK_761 - Station Reentry Visible Playtest Findings (implementiert)"), "Roadmap marks TASK_761 implemented")
	_assert(roadmap_text.contains("TASK_762 - Station Reentry Targeted Polish"), "Roadmap names TASK_762 followup")
	_assert(handbook_text.contains("TASK_761 - Station Reentry Visible Playtest Findings"), "Current handbook references TASK_761")
	_assert(handbook_text.contains('data-export-key="station_reentry_visible_findings.manifest_path"'), "Current handbook exports TASK_761 manifest path")
	_assert(workbench_text.contains("Station Reentry Sichtchecks"), "Workbench contains Reentry checks")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.reentry.playtest_done"'), "Workbench exports Reentry playtest done")
	_assert(workbench_text.contains("needs_first_order_preview_polish"), "Workbench exports Reentry first-order issue flag")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-packet findings remain read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_visible_playtest_findings.v1", "TASK_761 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_760 packet blocks")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing packet creates blocker")


func _test_open_reentry_needs_visible_playtest() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Open Reentry findings remain read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visible_reentry_playtest", "Open Reentry notes require visible playtest")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open Reentry does not claim manual done")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_767"), "Open Reentry routes to TASK_767")


func _test_incomplete_reentry_checks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), _partial_notes()))
	_assert(_snapshot_is_read_only(snapshot), "Incomplete Reentry findings remain read-only")
	_assert(String(snapshot.get("status", "")) == "needs_reentry_completion", "Partial notes require completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 2, "Partial notes count completed checks")
	_assert(_array_contains(snapshot.get("missing_check_ids", []), "dropship_payload_consistent"), "Missing checks include dropship payload consistency")


func _test_issue_flags_create_action_items() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), _issue_notes()))
	_assert(_snapshot_is_read_only(snapshot), "Issue Reentry findings remain read-only")
	_assert(String(snapshot.get("status", "")) == "needs_targeted_reentry_polish", "Issue flags request targeted Reentry polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Issue notes count active flags")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Issue notes create action items")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_765"), "First issue routes to dropship sync fix")


func _test_clean_reentry_ready_for_next_iteration() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), _clean_notes()))
	_assert(_snapshot_is_read_only(snapshot), "Clean Reentry findings remain read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_next_station_iteration", "Clean notes are ready for next iteration")
	_assert(int(snapshot.get("missing_check_ids", []).size()) == 0, "Clean notes have no missing checks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_768"), "Clean notes route beyond TASK_767")


func _test_actual_manifest_write() -> void:
	_run_packet_tool()
	_ensure_output_dir()
	var packet: Dictionary = _read_json(PACKET_PATH)
	if packet.is_empty():
		packet = _ready_packet()
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", packet, {}, {
		"packet_path": "tmp/station_reentry_playtest_run_packet.json",
		"manifest_path": "tmp/station_reentry_visible_playtest_findings.json",
	}))
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_761 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_761", "Manifest records TASK_761")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_760", "Manifest records TASK_760 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_reentry_playtest", "Manifest preserves open Reentry status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _run_packet_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path("res://scripts/tools/prepare_station_reentry_playtest_run.ps1")], output, true, false)
	_assert(exit_code == 0, "TASK_760 packet tool exits 0 for TASK_761")


func _ready_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_playtest_run_packet.v1",
		"task_id": "TASK_760",
		"source_task_id": "TASK_759",
		"target_id": "station_reentry_playtest",
		"target_title": "Homebase -> naechste Station-Sortie",
		"status": "ready_to_run_station_reentry_playtest",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _partial_notes() -> Dictionary:
	return {
		"controls": {
			"station_scenario_playtest": {
				"reentry": {
					"manual_review_done": true,
					"playtest_done": true,
					"homebase_return_panel_readable": true,
					"fireteam_staging_readable": true,
				},
			},
		},
	}


func _issue_notes() -> Dictionary:
	var reentry: Dictionary = _complete_reentry_checks()
	reentry["manual_review_done"] = true
	reentry["playtest_done"] = true
	reentry["issues"] = {
		"needs_dropship_payload_sync_fix": true,
		"needs_first_order_preview_polish": true,
	}
	return {"controls": {"station_scenario_playtest": {"reentry": reentry}}}


func _clean_notes() -> Dictionary:
	var reentry: Dictionary = _complete_reentry_checks()
	reentry["manual_review_done"] = true
	reentry["playtest_done"] = true
	return {"controls": {"station_scenario_playtest": {"reentry": reentry}}}


func _complete_reentry_checks() -> Dictionary:
	var result: Dictionary = {}
	for id in [
		"homebase_return_panel_readable",
		"fireteam_staging_readable",
		"loadout_check_readable",
		"dropship_payload_consistent",
		"start_release_visible",
		"host_client_same_next_order",
		"first_mission_preview_visible",
		"first_mission_cue_readable",
		"performance_feels_fast",
		"workbench_notes_exported",
	]:
		result[id] = true
	return result


func _array_contains(value: Variant, expected: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for entry in Array(value):
		if String(entry) == expected:
			return true
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)) and not bool(snapshot.get("creates_command", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_761 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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
