extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_750_station_homebase_host_client_recapture_packet.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_homebase_host_client_recapture.ps1"
const PACKET_PATH: String = "res://tmp/station_homebase_host_client_recapture_packet.json"
const EXPECTED_LINE: String = "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_750 Station Homebase Host/Client Recapture Packet ===")
	_test_docs_contract_and_report()
	_test_tool_and_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_750: FAILED")
		quit(1)
		return
	print("TASK_750: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_750 task file exists")
	_assert(task_text.contains("Station Homebase Host/Client Recapture Packet"), "TASK_750 task names recapture packet")
	_assert(status_text.contains("TASK_750 - Station Homebase Host/Client Recapture Packet"), "Implementation status tracks TASK_750")
	_assert(roadmap_text.contains("TASK_750 - Station Homebase Host/Client Recapture Packet"), "Roadmap tracks TASK_750")
	_assert(contract_text.contains("Station-Homebase-Host-Client-Recapture-Packet"), "Mission command feedback contract documents TASK_750")
	_assert(handbook_text.contains("TASK_750 - Station Homebase Host/Client Recapture Packet"), "Current handbook references TASK_750")
	_assert(handbook_text.contains('data-export-key="status.task_750_done"'), "Current handbook exports TASK_750 checkbox")
	for key in [
		"station_homebase_host_client_recapture_packet.task_id",
		"station_homebase_host_client_recapture_packet.manifest_path",
		"station_homebase_host_client_recapture_packet.expected_homebase_readiness_line",
		"station_homebase_host_client_recapture_packet.required_manual_checks",
		"station_homebase_host_client_recapture_packet.manual_review_done",
		"station_homebase_host_client_recapture_packet.recommended_next_task",
		"station_homebase_host_client_recapture_packet.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)


func _test_tool_and_packet() -> void:
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_750 packet tool exists")
	_assert(tool_text.contains("sternenbuergerchen.station_homebase_host_client_recapture_packet.v1"), "Tool writes TASK_750 schema")
	_assert(tool_text.contains("TASK_750"), "Tool records TASK_750")
	_assert(tool_text.contains(EXPECTED_LINE), "Tool records expected TASK_749 Homebase line")
	_assert(tool_text.contains("launch_host_client_two_window_review.ps1"), "Tool points to existing launch helper")
	_assert(tool_text.contains("capture_host_client_two_window_real_run.ps1"), "Tool points to existing capture helper")
	_assert(tool_text.contains("station_route_one_screen_multiplayer_drill.json"), "Tool points to Station scenario")

	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_750 packet exists")
	if not FileAccess.file_exists(PACKET_PATH):
		return
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_homebase_host_client_recapture_packet.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_750", "Packet records TASK_750")
	_assert(String(packet.get("source_task_id", "")) == "TASK_749", "Packet points to TASK_749")
	_assert(String(packet.get("status", "")) == "ready_to_run_homebase_recapture", "Packet is ready for Homebase recapture")
	_assert(String(packet.get("expected_homebase_readiness_line", "")) == EXPECTED_LINE, "Packet preserves expected Homebase line")
	_assert(bool(packet.get("manual_review_required", false)), "Packet requires manual review")
	_assert(not bool(packet.get("manual_review_done", true)), "Packet does not claim manual review done")
	_assert(bool(packet.get("read_only", false)), "Packet is read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(not bool(packet.get("creates_navigation", true)), "Packet creates no navigation")
	_assert(not bool(packet.get("creates_command", true)), "Packet creates no command")
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("-ScenarioPath"), "Launch command includes ScenarioPath")
	_assert(String(commands.get("capture_windows", "")).contains("-CloseAfterCapture"), "Capture command closes after capture")
	var checks: Array = Array(packet.get("required_manual_checks", []))
	for check_id in [
		"cargo_end_reached",
		"debrief_visible_after_cargo",
		"return_homebase_clicked",
		"homebase_summary_mentions_station_drill",
		"homebase_next_sortie_line_matches_task_749",
		"old_debug_next_sortie_markers_absent",
		"performance_feels_fast",
		"workbench_notes_exported",
	]:
		_assert(checks.has(check_id), "Packet requires manual check %s" % check_id)
	var forbidden: Array = Array(packet.get("expected_old_debug_markers_absent", []))
	_assert(forbidden.has("Next sortie") and forbidden.has("Stage fireteam"), "Packet lists old debug markers to reject")


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
