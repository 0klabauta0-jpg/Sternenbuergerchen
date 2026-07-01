extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_778_station_reentry_firefight_visual_playtest_packet.md"
const TASK_777_PATH: String = "res://docs/tasks/TASK_777_station_reentry_firefight_tension_feel_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_visual_playtest_packet.ps1"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_visual_playtest_packet.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_778 Station Reentry Firefight Visual Playtest Packet ===")
	_test_docs_contract_and_report()
	_test_tool_declares_packet()
	_run_tool()
	_test_packet_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_778: FAILED")
		quit(1)
		return
	print("TASK_778: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_778 task file exists")
	_assert(FileAccess.file_exists(TASK_777_PATH), "TASK_777 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Visual Playtest Packet"), "TASK_778 task names visual playtest packet")
	_assert(status_text.contains("TASK_778 - Station Reentry Firefight Visual Playtest Packet"), "Implementation status tracks TASK_778")
	_assert(roadmap_text.contains("TASK_778 - Station Reentry Firefight Visual Playtest Packet (implementiert)"), "Roadmap marks TASK_778 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Visual-Playtest-Packet"), "Mission command feedback contract documents TASK_778")
	_assert(report_text.contains("Aktueller Griff: TASK_778"), "Reentry handbook marks TASK_778 current")
	_assert(report_text.contains("station_reentry_firefight_visual_playtest_packet.json"), "Reentry handbook names TASK_778 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_visual_packet.ready_to_capture"'), "Reentry handbook exports TASK_778 ready check")


func _test_tool_declares_packet() -> void:
	var text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_778 prepare tool exists")
	for term in [
		"sternenbuergerchen.station_reentry_firefight_visual_playtest_packet.v1",
		"TASK_778",
		"TASK_777",
		"station_reentry_firefight_visual_playtest_packet.json",
		"ready_to_capture_station_reentry_firefight_visual",
		"fire_trace_visible",
		"manual_review_done = $false",
	]:
		_assert(text.contains(term), "Prepare tool contains %s" % term)


func _run_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_778 prepare tool exits 0")
	if exit_code != 0:
		for line in output:
			print(line)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_778 manifest exists after prepare")


func _test_packet_manifest() -> void:
	var packet: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_visual_playtest_packet.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_778", "Packet records TASK_778")
	_assert(String(packet.get("source_task_id", "")) == "TASK_777", "Packet records TASK_777 source")
	_assert(String(packet.get("status", "")) == "ready_to_capture_station_reentry_firefight_visual", "Packet is ready to capture")
	_assert(bool(packet.get("scenario_exists", false)), "Packet sees scenario file")
	_assert(bool(packet.get("workbench_exists", false)), "Packet sees workbench file")
	_assert(String(packet.get("workbench_file_uri", "")).begins_with("file:///"), "Packet exposes workbench file URI")
	_assert(bool(packet.get("read_only", false)), "Packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(not bool(packet.get("creates_navigation", true)), "Packet does not create navigation")
	_assert(not bool(packet.get("creates_command", true)), "Packet does not create commands")
	_assert(not bool(packet.get("creates_fire_event", true)), "Packet does not create FireEvents")
	_assert(not bool(packet.get("creates_damage_event", true)), "Packet does not create DamageEvents")
	_assert(bool(packet.get("manual_review_required", false)), "Packet requires manual review")
	_assert(not bool(packet.get("manual_review_done", true)), "Packet does not claim manual review done")
	for check_id in [
		"firefight_triggered",
		"fire_trace_visible",
		"impact_focus_visible",
		"unit_badge_visible",
		"combat_hud_next_decision_visible",
		"combat_metrics_match_hud",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		_assert(_array_contains(packet.get("required_manual_checks", []), check_id), "Manual checks include %s" % check_id)
	var expectations: Dictionary = Dictionary(packet.get("expected_firefight_readability", {}))
	_assert(_array_contains(expectations.get("required_visible_fragments", []), "FIRE"), "Expectations require FIRE text")
	_assert(_array_contains(expectations.get("required_visible_fragments", []), "next:"), "Expectations require next-decision text")
	_assert(_array_contains(expectations.get("required_visuals", []), "fire_trace"), "Expectations require fire trace")
	_assert(_array_contains(expectations.get("required_visuals", []), "impact_focus"), "Expectations require impact focus")
	_assert(_array_contains(expectations.get("required_visuals", []), "unit_status_badge"), "Expectations require unit status badge")
	_assert(_array_contains(expectations.get("required_metrics", []), "friendly_fire_risk_count"), "Expectations require friendly-fire risk metric")
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Packet launch command is present")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Packet capture command is present")
	_assert(String(commands.get("open_workbench", "")).begins_with("file:///"), "Packet workbench URI command is present")
	_assert(String(commands.get("rerun_firefight_tension_verifier", "")).contains("task_777_station_reentry_firefight_tension_feel_pass.gd"), "Packet exposes TASK_777 verifier")
	_assert(String(commands.get("rerun_packet_verifier", "")).contains("task_778_station_reentry_firefight_visual_playtest_packet.gd"), "Packet exposes TASK_778 verifier")
	_assert(String(packet.get("recommended_next_task", "")) == "TASK_779 - Station Reentry Firefight Visual Findings", "Packet routes to TASK_779")


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
