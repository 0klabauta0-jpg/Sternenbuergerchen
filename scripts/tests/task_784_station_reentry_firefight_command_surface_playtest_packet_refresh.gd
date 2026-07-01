extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_784_station_reentry_firefight_command_surface_playtest_packet_refresh.md"
const TASK_783_PATH: String = "res://docs/tasks/TASK_783_station_reentry_firefight_command_surface_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_command_surface_playtest_packet_refresh.ps1"
const POLISH_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_polish.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_playtest_packet_refresh.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_784 Station Reentry Firefight Command Surface Playtest Packet Refresh ===")
	_test_docs_contract_and_report()
	_test_tool_declares_refresh()
	_write_polish_manifest()
	_run_tool()
	_test_refresh_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_784: FAILED")
		quit(1)
		return
	print("TASK_784: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_784 task file exists")
	_assert(FileAccess.file_exists(TASK_783_PATH), "TASK_783 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Command Surface Playtest Packet Refresh"), "TASK_784 task names packet refresh")
	_assert(status_text.contains("TASK_784 - Station Reentry Firefight Command Surface Playtest Packet Refresh"), "Implementation status tracks TASK_784")
	_assert(roadmap_text.contains("TASK_784 - Station Reentry Firefight Command Surface Playtest Packet Refresh (implementiert)"), "Roadmap marks TASK_784 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Command-Surface-Playtest-Packet-Refresh"), "Mission command feedback contract documents TASK_784")
	_assert(report_text.contains("Aktueller Griff: TASK_787"), "Reentry handbook marks TASK_787 current")
	_assert(report_text.contains("station_reentry_firefight_command_surface_playtest_packet_refresh.json"), "Reentry handbook names TASK_784 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface_playtest_packet.ready_to_capture"'), "Reentry handbook exports TASK_784 ready check")


func _test_tool_declares_refresh() -> void:
	var text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_784 prepare tool exists")
	for term in [
		"sternenbuergerchen.station_reentry_firefight_command_surface_playtest_packet_refresh.v1",
		"TASK_784",
		"TASK_783",
		"station_reentry_firefight_command_surface_playtest_packet_refresh.json",
		"ready_to_capture_polished_command_surface",
		"polished_surface_visible",
		"quick_action_rail_visible",
		"guard_line_visible",
		"manual_review_done = $false",
	]:
		_assert(text.contains(term), "Prepare tool contains %s" % term)


func _write_polish_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_reentry_firefight_command_surface_polish.v1",
		"task_id": "TASK_783",
		"source_task_ids": ["TASK_782", "TASK_780", "TASK_570", "TASK_736"],
		"status": "ready_for_command_surface_polish_review",
		"ready_for_command_surface_polish_review": true,
		"command_surface_style_id": "task_783_firefight_command_surface_v1",
		"surface_priority_order": ["interaction_line", "primary_action", "quick_action_rail", "guard_line"],
		"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"primary_action": {"id": "hold_cover", "label": "HOLD"},
		"quick_action_rail": [
			{"id": "hold_cover", "display_label": "HOLD"},
			{"id": "flank", "display_label": "FLANK"},
			{"id": "hold_fire", "display_label": "HOLD FIRE"},
			{"id": "suppress", "display_label": "SUP"},
			{"id": "move_cover", "display_label": "MOVE"},
		],
		"guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"summary_line": "NEXT HOLD | QUICK FLANK / HOLD FIRE / SUP / MOVE",
		"uses_existing_commands_only": true,
		"no_auto_command_commit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}
	var file := FileAccess.open(POLISH_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_783 manifest for TASK_784 setup")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(POLISH_MANIFEST_PATH), "TASK_783 polish manifest is prepared")


func _run_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_784 prepare tool exits 0")
	if exit_code != 0:
		for line in output:
			print(line)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_784 manifest exists after prepare")


func _test_refresh_packet() -> void:
	var packet: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_command_surface_playtest_packet_refresh.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_784", "Packet records TASK_784")
	_assert(String(packet.get("source_task_id", "")) == "TASK_783", "Packet records TASK_783 source")
	_assert(String(packet.get("status", "")) == "ready_to_capture_polished_command_surface", "Packet is ready to capture polished surface")
	_assert(bool(packet.get("scenario_exists", false)), "Packet sees scenario file")
	_assert(bool(packet.get("workbench_exists", false)), "Packet sees workbench file")
	_assert(bool(packet.get("polish_manifest_exists", false)), "Packet sees TASK_783 manifest")
	_assert(String(packet.get("polish_status", "")) == "ready_for_command_surface_polish_review", "Packet sees ready polish status")
	_assert(String(packet.get("expected_command_surface_style_id", "")) == "task_783_firefight_command_surface_v1", "Packet carries TASK_783 style id")
	_assert(_array_contains(packet.get("expected_surface_priority_order", []), "quick_action_rail"), "Packet carries surface priority order")
	_assert(String(packet.get("expected_interaction_line", "")).contains("NEXT HOLD"), "Packet carries polished interaction line")
	_assert(String(packet.get("expected_primary_action_label", "")) == "HOLD", "Packet carries primary action label")
	_assert(_array_contains(packet.get("expected_quick_action_labels", []), "HOLD FIRE"), "Packet carries HOLD FIRE quick action")
	_assert(String(packet.get("expected_guard_line", "")).contains("NO AUTO CMD"), "Packet carries no-auto-command guard")
	_assert(String(packet.get("expected_summary_line", "")).contains("QUICK"), "Packet carries summary line")
	_assert(bool(packet.get("expected_no_auto_command_commit", false)), "Packet expects no auto-command commit")
	_assert(bool(packet.get("expected_uses_existing_commands_only", false)), "Packet expects existing commands only")
	_assert(bool(packet.get("read_only", false)), "Packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(not bool(packet.get("creates_navigation", true)), "Packet does not create navigation")
	_assert(not bool(packet.get("creates_command", true)), "Packet does not create commands")
	_assert(not bool(packet.get("creates_fire_event", true)), "Packet does not create FireEvents")
	_assert(not bool(packet.get("creates_damage_event", true)), "Packet does not create DamageEvents")
	for check_id in [
		"polished_surface_visible",
		"primary_action_lane_visible",
		"quick_action_rail_visible",
		"guard_line_visible",
		"no_auto_command_commit_visible",
		"existing_buttons_visible",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		_assert(_array_contains(packet.get("required_manual_checks", []), check_id), "Manual checks include %s" % check_id)
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Packet launch command is present")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Packet capture command is present")
	_assert(String(commands.get("open_workbench", "")).begins_with("file:///"), "Packet workbench URI command is present")
	_assert(String(commands.get("rerun_command_surface_polish_verifier", "")).contains("task_783_station_reentry_firefight_command_surface_polish.gd"), "Packet exposes TASK_783 verifier")
	_assert(String(commands.get("rerun_playtest_packet_refresh_verifier", "")).contains("task_784_station_reentry_firefight_command_surface_playtest_packet_refresh.gd"), "Packet exposes TASK_784 verifier")
	_assert(String(packet.get("recommended_next_task", "")) == "TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh", "Packet routes to TASK_785")


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
