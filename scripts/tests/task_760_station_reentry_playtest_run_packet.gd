extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_760_station_reentry_playtest_run_packet.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_playtest_run.ps1"
const PACKET_PATH: String = "res://tmp/station_reentry_playtest_run_packet.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_760 Station Reentry Playtest Run Packet ===")
	_test_docs_contract_and_reports()
	_test_tool_declares_reentry_packet()
	_run_tool()
	_test_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_760: FAILED")
		quit(1)
		return
	print("TASK_760: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_760 task file exists")
	_assert(task_text.contains("Station Reentry Playtest Run Packet"), "TASK_760 task names run packet")
	_assert(contract_text.contains("Station-Reentry-Playtest-Run-Packet (TASK_760)"), "Contract documents TASK_760")
	_assert(status_text.contains("TASK_760 - Station Reentry Playtest Run Packet"), "Implementation status tracks TASK_760")
	_assert(roadmap_text.contains("TASK_760 - Station Reentry Playtest Run Packet (implementiert)"), "Roadmap marks TASK_760 implemented")
	_assert(roadmap_text.contains("TASK_761 - Station Reentry Visible Playtest Findings"), "Roadmap routes to TASK_761")
	_assert(handbook_text.contains("TASK_760 - Station Reentry Playtest Run Packet"), "Current handbook references TASK_760")
	_assert(handbook_text.contains('data-export-key="status.task_760_done"'), "Current handbook exports TASK_760 checkbox")
	_assert(handbook_text.contains("station_reentry_run_packet"), "Current handbook exports TASK_760 fields")
	_assert(workbench_text.contains("Run Packet: TASK_760"), "Workbench shows TASK_760 badge")
	_assert(workbench_text.contains("station_scenario_playtest.reentry_packet.task_id"), "Workbench exports TASK_760 task id")


func _test_tool_declares_reentry_packet() -> void:
	var text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_760 prepare tool exists")
	for term in [
		"sternenbuergerchen.station_reentry_playtest_run_packet.v1",
		"TASK_760",
		"TASK_759",
		"station_reentry_playtest",
		"station_reentry_playtest_run_packet.json",
		"ready_to_run_station_reentry_playtest",
		"Homebase-Return-Panel lesen",
		"Fireteam bereitstellen",
		"Dropship beladen",
		"Host und Client sehen denselben naechsten Auftrag",
		"manual_review_done = $false",
	]:
		_assert(text.contains(term), "Prepare tool contains %s" % term)


func _run_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_760 prepare tool exits 0")
	if exit_code != 0:
		for line in output:
			print(line)
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_760 packet exists after prepare")


func _test_packet() -> void:
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_reentry_playtest_run_packet.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_760", "Packet records TASK_760")
	_assert(String(packet.get("source_task_id", "")) == "TASK_759", "Packet records TASK_759 source")
	_assert(String(packet.get("target_id", "")) == "station_reentry_playtest", "Packet records reentry target")
	_assert(String(packet.get("target_title", "")) == "Homebase -> naechste Station-Sortie", "Packet records player-facing title")
	_assert(String(packet.get("status", "")) == "ready_to_run_station_reentry_playtest", "Packet is ready to run")
	_assert(String(packet.get("scenario_path", "")) == SCENARIO_PATH, "Packet records scenario path")
	_assert(String(packet.get("scenario_arg", "")) == "--scenario-file=%s" % SCENARIO_PATH, "Packet records scenario arg")
	_assert(bool(packet.get("scenario_exists", false)), "Packet sees scenario file")
	_assert(bool(packet.get("workbench_exists", false)), "Packet sees workbench file")
	_assert(String(packet.get("workbench_file_uri", "")).begins_with("file:///"), "Packet exposes workbench file URI")
	_assert(bool(packet.get("read_only", false)), "Packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(not bool(packet.get("creates_command", true)), "Packet does not create commands")
	_assert(bool(packet.get("manual_review_required", false)), "Packet requires manual review")
	_assert(not bool(packet.get("manual_review_done", true)), "Packet does not claim manual review done")
	_assert(_array_contains(packet.get("runbook_steps", []), "Fireteam bereitstellen"), "Packet runbook includes staging fireteam")
	_assert(_array_contains(packet.get("runbook_steps", []), "Loadout pruefen"), "Packet runbook includes loadout")
	_assert(_array_contains(packet.get("runbook_steps", []), "Dropship beladen"), "Packet runbook includes dropship")
	_assert(_array_contains(packet.get("runbook_steps", []), "erste Mission-Entscheidung mit Preview treffen"), "Packet runbook includes first preview decision")
	_assert(_array_contains(packet.get("multiplayer_checks", []), "Fireteam-Zuordnung bleibt im Dropship konsistent"), "Packet MP checks include dropship/fireteam consistency")
	_assert(_array_contains(packet.get("required_manual_checks", []), "first_mission_preview_visible"), "Packet requires first preview visibility")
	_assert(_array_contains(packet.get("required_manual_checks", []), "workbench_notes_exported"), "Packet requires workbench export")
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("-ScenarioPath"), "Packet launch command includes ScenarioPath")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Packet capture command is present")
	_assert(String(commands.get("open_workbench", "")).begins_with("file:///"), "Packet open_workbench is file URI")
	_assert(String(commands.get("rerun_packet_verifier", "")).contains("task_760_station_reentry_playtest_run_packet.gd"), "Packet exposes TASK_760 verifier command")
	_assert(String(packet.get("recommended_next_task", "")) == "TASK_761 - Station Reentry Visible Playtest Findings", "Packet routes to TASK_761")


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
