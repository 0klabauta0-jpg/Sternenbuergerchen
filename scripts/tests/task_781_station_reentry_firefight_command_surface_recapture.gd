extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_781_station_reentry_firefight_command_surface_recapture.md"
const TASK_780_PATH: String = "res://docs/tasks/TASK_780_station_reentry_firefight_interaction_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_command_surface_recapture.ps1"
const INTERACTION_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_interaction_polish.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_recapture.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_781 Station Reentry Firefight Command Surface Recapture ===")
	_test_docs_contract_and_report()
	_test_tool_declares_recapture()
	_write_interaction_manifest()
	_run_tool()
	_test_recapture_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_781: FAILED")
		quit(1)
		return
	print("TASK_781: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_781 task file exists")
	_assert(FileAccess.file_exists(TASK_780_PATH), "TASK_780 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Command Surface Recapture"), "TASK_781 task names command surface recapture")
	_assert(status_text.contains("TASK_781 - Station Reentry Firefight Command Surface Recapture"), "Implementation status tracks TASK_781")
	_assert(roadmap_text.contains("TASK_781 - Station Reentry Firefight Command Surface Recapture (implementiert)"), "Roadmap marks TASK_781 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Command-Surface-Recapture"), "Mission command feedback contract documents TASK_781")
	_assert(report_text.contains("Aktueller Griff: TASK_789"), "Reentry handbook marks TASK_789 current")
	_assert(report_text.contains("station_reentry_firefight_command_surface_recapture.json"), "Reentry handbook names TASK_781 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface.interaction_line_visible"'), "Reentry handbook exports TASK_781 interaction check")


func _test_tool_declares_recapture() -> void:
	var text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_781 prepare tool exists")
	for term in [
		"sternenbuergerchen.station_reentry_firefight_command_surface_recapture.v1",
		"TASK_781",
		"TASK_780",
		"station_reentry_firefight_command_surface_recapture.json",
		"ready_to_capture_firefight_command_surface",
		"interaction_line_visible",
		"no_auto_command_commit_visible",
		"manual_review_done = $false",
	]:
		_assert(text.contains(term), "Prepare tool contains %s" % term)


func _write_interaction_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_reentry_firefight_interaction_polish.v1",
		"task_id": "TASK_780",
		"status": "ready_for_firefight_interaction_playtest",
		"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"primary_action": {"id": "hold_cover", "label": "HOLD"},
		"quick_actions": [
			{"id": "hold_cover", "label": "HOLD"},
			{"id": "flank", "label": "FLANK"},
			{"id": "hold_fire", "label": "HOLD FIRE"},
			{"id": "suppress", "label": "SUP"},
			{"id": "move_cover", "label": "MOVE"},
		],
		"uses_existing_commands_only": true,
		"no_auto_command_commit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}
	var file := FileAccess.open(INTERACTION_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_780 manifest for TASK_781 setup")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(INTERACTION_MANIFEST_PATH), "TASK_780 interaction manifest is prepared")


func _run_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_781 prepare tool exits 0")
	if exit_code != 0:
		for line in output:
			print(line)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_781 manifest exists after prepare")


func _test_recapture_manifest() -> void:
	var packet: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_command_surface_recapture.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_781", "Packet records TASK_781")
	_assert(String(packet.get("source_task_id", "")) == "TASK_780", "Packet records TASK_780 source")
	_assert(String(packet.get("status", "")) == "ready_to_capture_firefight_command_surface", "Packet is ready to capture")
	_assert(bool(packet.get("scenario_exists", false)), "Packet sees scenario file")
	_assert(bool(packet.get("workbench_exists", false)), "Packet sees workbench file")
	_assert(bool(packet.get("interaction_manifest_exists", false)), "Packet sees TASK_780 manifest")
	_assert(String(packet.get("interaction_status", "")) == "ready_for_firefight_interaction_playtest", "Packet sees ready interaction status")
	_assert(String(packet.get("expected_interaction_line", "")).contains("NEXT HOLD"), "Packet carries expected interaction line")
	_assert(String(packet.get("expected_primary_action_label", "")) == "HOLD", "Packet carries primary action label")
	_assert(_array_contains(packet.get("expected_quick_action_labels", []), "SUP"), "Packet carries SUP quick action")
	_assert(bool(packet.get("expected_no_auto_command_commit", false)), "Packet expects no auto-command commit")
	_assert(bool(packet.get("expected_uses_existing_commands_only", false)), "Packet expects existing commands only")
	_assert(bool(packet.get("read_only", false)), "Packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(not bool(packet.get("creates_navigation", true)), "Packet does not create navigation")
	_assert(not bool(packet.get("creates_command", true)), "Packet does not create commands")
	_assert(not bool(packet.get("creates_fire_event", true)), "Packet does not create FireEvents")
	_assert(not bool(packet.get("creates_damage_event", true)), "Packet does not create DamageEvents")
	for check_id in [
		"interaction_line_visible",
		"primary_action_visible",
		"quick_actions_visible",
		"hold_flank_sup_visible",
		"no_auto_command_commit_visible",
		"selected_fireteam_panel_consistent",
		"command_matrix_buttons_reachable",
		"host_client_same_surface_visible",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		_assert(_array_contains(packet.get("required_manual_checks", []), check_id), "Manual checks include %s" % check_id)
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Packet launch command is present")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Packet capture command is present")
	_assert(String(commands.get("open_workbench", "")).begins_with("file:///"), "Packet workbench URI command is present")
	_assert(String(commands.get("rerun_interaction_polish_verifier", "")).contains("task_780_station_reentry_firefight_interaction_polish.gd"), "Packet exposes TASK_780 verifier")
	_assert(String(commands.get("rerun_recapture_verifier", "")).contains("task_781_station_reentry_firefight_command_surface_recapture.gd"), "Packet exposes TASK_781 verifier")
	_assert(String(packet.get("recommended_next_task", "")) == "TASK_782 - Station Reentry Firefight Command Surface Findings", "Packet routes to TASK_782")


func _array_contains(value: Variant, expected: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for entry in Array(value):
		if String(entry) == expected:
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
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
