extends SceneTree

const MISSION_TEST_SETUP_SCRIPT: GDScript = preload("res://scripts/tests/mission_test_setup.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_729_station_scenario_visible_playtest_run_packet.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const LAUNCH_HELPER_PATH: String = "res://scripts/tools/launch_host_client_two_window_review.ps1"
const RUN_PACKET_TOOL_PATH: String = "res://scripts/tools/prepare_station_scenario_visible_playtest_run.ps1"
const PACKET_PATH: String = "res://tmp/station_scenario_visible_playtest_run_packet.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_729 Station Scenario Visible Playtest Run Packet ===")
	_test_docs()
	_test_cmdline_scenario_override()
	_test_launch_helper_supports_scenario_arg()
	_test_run_packet_tool()
	_test_packet_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_729: FAILED")
		quit(1)
		return
	print("TASK_729: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_729 task file exists")
	_assert(task_text.contains("Station Scenario Visible Playtest Run Packet"), "Task documents visible playtest run packet")
	_assert(contract_text.contains("Station Scenario Visible Playtest Run Packet"), "Interaction contract documents TASK_729")
	_assert(status_text.contains("TASK_729 - Station Scenario Visible Playtest Run Packet"), "Implementation status tracks TASK_729")
	_assert(roadmap_text.contains("TASK_729 - Station Scenario Visible Playtest Run Packet (implementiert)"), "Roadmap marks TASK_729 implemented")
	_assert(handbook_text.contains("TASK_729 - Station Scenario Visible Playtest Run Packet"), "Current handbook references TASK_729")
	_assert(handbook_text.contains('data-export-key="station_scenario_visible_playtest_run_packet.manifest_path"'), "Current handbook exports TASK_729 packet path")


func _test_cmdline_scenario_override() -> void:
	var setup: Node = MISSION_TEST_SETUP_SCRIPT.new()
	var result: Dictionary = Dictionary(setup.call("apply_cmdline_scenario_override", ["--scenario-file=%s" % SCENARIO_PATH]))
	_assert(bool(result.get("override_applied", false)), "MissionTestSetup applies --scenario-file override")
	_assert(String(result.get("scenario_file_path", "")) == SCENARIO_PATH, "MissionTestSetup records scenario override")
	_assert(String(setup.get("scenario_file_path")) == SCENARIO_PATH, "MissionTestSetup property receives scenario override")
	var alternate: Dictionary = Dictionary(setup.call("apply_cmdline_scenario_override", ["--mission-scenario=res://data/mission_scenarios/example.json"]))
	_assert(bool(alternate.get("override_applied", false)), "MissionTestSetup applies --mission-scenario alias")
	setup.free()


func _test_launch_helper_supports_scenario_arg() -> void:
	var text: String = _read_text(LAUNCH_HELPER_PATH)
	_assert(FileAccess.file_exists(LAUNCH_HELPER_PATH), "Launch helper exists")
	_assert(text.contains("[string]$ScenarioPath"), "Launch helper exposes ScenarioPath parameter")
	_assert(text.contains("--scenario-file=$ScenarioPath"), "Launch helper forwards scenario-file arg")
	_assert(text.contains("scenario_path = $ScenarioPath"), "Launch plan records scenario path")
	_assert(text.contains("scenario_arg_included"), "Launch plan records scenario arg inclusion")


func _test_run_packet_tool() -> void:
	var text: String = _read_text(RUN_PACKET_TOOL_PATH)
	_assert(FileAccess.file_exists(RUN_PACKET_TOOL_PATH), "TASK_729 run packet tool exists")
	var required_terms: Array[String] = [
		"sternenbuergerchen.station_scenario_visible_playtest_run_packet.v1",
		"TASK_729",
		"station_route_one_screen_multiplayer_drill.json",
		"station_scenario_f6_host_client_playtest_notes_2026_07_01.html",
		"station_scenario_visible_playtest_run_packet.json",
		"--scenario-file=$ScenarioPath",
		"ready_to_run_visible_playtest",
		"read_only",
		"ui_sets_gameplay_truth",
	]
	for term in required_terms:
		_assert(text.contains(term), "Run packet tool contains %s" % term)


func _test_packet_if_present() -> void:
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_729 dry-run packet exists")
	if not FileAccess.file_exists(PACKET_PATH):
		return
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_scenario_visible_playtest_run_packet.v1", "Run packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_729", "Run packet records TASK_729")
	_assert(String(packet.get("scenario_path", "")) == SCENARIO_PATH, "Run packet records station scenario path")
	_assert(String(packet.get("scenario_arg", "")) == "--scenario-file=%s" % SCENARIO_PATH, "Run packet records scenario CLI arg")
	_assert(bool(packet.get("read_only", false)), "Run packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Run packet does not set gameplay truth")
	_assert(String(packet.get("status", "")) == "ready_to_run_visible_playtest", "Run packet is ready for visible playtest")
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("-ScenarioPath"), "Run packet launch command includes ScenarioPath")
	_assert(String(commands.get("open_workbench", "")).begins_with("file:///"), "Run packet exposes workbench file URI")


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
