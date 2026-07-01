extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_737_station_scenario_visible_cue_run_packet_refresh.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const RUN_PACKET_TOOL_PATH: String = "res://scripts/tools/prepare_station_scenario_visible_playtest_run.ps1"
const PACKET_PATH: String = "res://tmp/station_scenario_visible_playtest_run_packet.json"
const EXPECTED_CUE_LINE: String = "CUE AA: BLUE naeher ran | 3.9km"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_737 Station Scenario Visible Cue Run Packet Refresh ===")
	_test_docs_contract_and_report()
	_test_run_packet_tool_declares_task_736_expectations()
	_test_packet_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_737: FAILED")
		quit(1)
		return
	print("TASK_737: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_737 task file exists")
	_assert(task_text.contains("Station Scenario Visible Cue Run Packet Refresh"), "Task documents visible cue packet refresh")
	_assert(status_text.contains("TASK_737 - Station Scenario Visible Cue Run Packet Refresh"), "Implementation status tracks TASK_737")
	_assert(roadmap_text.contains("TASK_737 - Station Scenario Visible Cue Run Packet Refresh (implementiert)"), "Roadmap marks TASK_737 implemented")
	_assert(roadmap_text.contains("TASK_740 - Scenario Harness Modernization"), "Roadmap keeps harness modernization as conditional follow-up")
	_assert(contract_text.contains("Station Scenario Visible Cue Run Packet Refresh"), "Interaction contract documents TASK_737")
	_assert(report_text.contains("TASK_737 - Station Scenario Visible Cue Run Packet Refresh"), "Current handbook references TASK_737")
	_assert(report_text.contains("station_scenario_visible_cue_run_packet_refresh"), "Current handbook exports TASK_737 fields")
	_assert(report_text.contains(EXPECTED_CUE_LINE), "Current handbook records expected polished cue")


func _test_run_packet_tool_declares_task_736_expectations() -> void:
	var text: String = _read_text(RUN_PACKET_TOOL_PATH)
	_assert(FileAccess.file_exists(RUN_PACKET_TOOL_PATH), "Run packet tool exists")
	var required_terms: Array[String] = [
		"refresh_task_id = \"TASK_737\"",
		"latest_feedback_task_id = \"TASK_736\"",
		EXPECTED_CUE_LINE,
		"station_route_player_action_cue_v2",
		"polished_aa_cue_reads_blue_naeher_ran_3_9km",
		"raw_long_meter_distance_hidden",
		"future_cargo_blocker_not_in_act_line",
		"visible_feedback_expectations",
		"rerun_command_feedback_verifier",
	]
	for term in required_terms:
		_assert(text.contains(term), "Run packet tool contains %s" % term)


func _test_packet_if_present() -> void:
	_assert(FileAccess.file_exists(PACKET_PATH), "Refreshed visible playtest packet exists")
	if not FileAccess.file_exists(PACKET_PATH):
		return
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_scenario_visible_playtest_run_packet.v1", "Packet schema stays stable")
	_assert(String(packet.get("task_id", "")) == "TASK_729", "Packet keeps original TASK_729 owner")
	_assert(String(packet.get("refresh_task_id", "")) == "TASK_737", "Packet records TASK_737 refresh")
	_assert(String(packet.get("latest_feedback_task_id", "")) == "TASK_736", "Packet records latest feedback task")
	_assert(bool(packet.get("read_only", false)), "Packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(String(packet.get("status", "")) == "ready_to_run_visible_playtest", "Packet is ready for visible playtest")
	_assert(not bool(packet.get("manual_review_done", true)), "Packet does not fake manual review")
	var checks: Array = Array(packet.get("required_manual_checks", []))
	_assert(checks.has("polished_aa_cue_reads_blue_naeher_ran_3_9km"), "Packet requires polished AA cue review")
	_assert(checks.has("raw_long_meter_distance_hidden"), "Packet requires raw meter distance to be hidden")
	_assert(checks.has("future_cargo_blocker_not_in_act_line"), "Packet requires future cargo blocker to be out of ACT line")
	var expectations: Dictionary = Dictionary(packet.get("visible_feedback_expectations", {}))
	_assert(String(expectations.get("source_task_id", "")) == "TASK_736", "Expectations point to TASK_736")
	_assert(String(expectations.get("cue_line_example", "")) == EXPECTED_CUE_LINE, "Expectations include polished cue line")
	_assert(String(expectations.get("expected_feedback_style_id", "")) == "station_route_player_action_cue_v2", "Expectations include style id")
	_assert(Array(expectations.get("required_visible_fragments", [])).has("BLUE naeher ran"), "Expectations require action language")
	_assert(Array(expectations.get("forbidden_visible_fragments", [])).has("3859m"), "Expectations forbid raw long meter distance")
	_assert(Array(expectations.get("forbidden_visible_fragments", [])).has("CARGO blockiert"), "Expectations forbid future cargo blocker in tight cue")
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("rerun_command_feedback_verifier", "")).contains("task_736_station_scenario_command_feedback_polish.gd"), "Packet exposes TASK_736 verifier command")
	_assert(String(commands.get("rerun_packet_refresh_verifier", "")).contains("task_737_station_scenario_visible_cue_run_packet_refresh.gd"), "Packet exposes TASK_737 verifier command")


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
