extends SceneTree

const SYNC_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_host_client_next_order_sync.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_771_station_reentry_visible_host_client_playtest_export.md"
const TASK_770_PATH: String = "res://docs/tasks/TASK_770_station_reentry_host_client_next_order_sync.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_host_client_playtest_export.ps1"
const SYNC_MANIFEST_PATH: String = "res://tmp/station_reentry_host_client_next_order_sync.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_visible_host_client_playtest_export.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_771 Station Reentry Visible Host Client Playtest Export ===")
	_test_docs_contract_and_report()
	_test_tool_declares_export_packet()
	_write_sync_manifest()
	_run_tool()
	_test_export_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_771: FAILED")
		quit(1)
		return
	print("TASK_771: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_771 task file exists")
	_assert(task_text.contains("Station Reentry Visible Host Client Playtest Export"), "TASK_771 task names visible host/client export")
	_assert(FileAccess.file_exists(TASK_770_PATH), "TASK_770 task remains available")
	_assert(status_text.contains("TASK_771 - Station Reentry Visible Host Client Playtest Export"), "Implementation status tracks TASK_771")
	_assert(roadmap_text.contains("TASK_771 - Station Reentry Visible Host Client Playtest Export (implementiert)"), "Roadmap marks TASK_771 implemented")
	_assert(contract_text.contains("Station-Reentry-Visible-Host-Client-Playtest-Export"), "Mission command feedback contract documents TASK_771")
	_assert(report_text.contains("TASK_771") and report_text.contains("Aktueller Griff: TASK_781"), "Reentry handbook preserves TASK_771 context and current TASK_781 follow-up")
	_assert(report_text.contains('data-export-key="reentry_host_client_export.ready_to_capture"'), "Reentry handbook exports TASK_771 ready check")
	_assert(report_text.contains("station_reentry_visible_host_client_playtest_export.json"), "Reentry handbook names TASK_771 export manifest")


func _test_tool_declares_export_packet() -> void:
	var text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_771 prepare tool exists")
	for term in [
		"sternenbuergerchen.station_reentry_visible_host_client_playtest_export.v1",
		"TASK_771",
		"TASK_770",
		"station_reentry_visible_host_client_playtest_export.json",
		"ready_to_capture_station_reentry_host_client",
		"host_client_same_next_order_visible",
		"manual_review_done = $false",
	]:
		_assert(text.contains(term), "Prepare tool contains %s" % term)


func _write_sync_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var manifest: Dictionary = Dictionary(SYNC_SCRIPT.call("build_snapshot", _build_peer_snapshot("host", 1, "team_alpha"), _build_peer_snapshot("client", 2, "team_bravo"), {}))
	var file := FileAccess.open(SYNC_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_770 sync manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(SYNC_MANIFEST_PATH), "TASK_770 sync manifest exists for TASK_771")


func _run_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_771 prepare tool exits 0")
	if exit_code != 0:
		for line in output:
			print(line)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_771 export manifest exists after prepare")


func _test_export_packet() -> void:
	var packet: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_reentry_visible_host_client_playtest_export.v1", "Export packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_771", "Export packet records TASK_771")
	_assert(String(packet.get("source_task_id", "")) == "TASK_770", "Export packet records TASK_770 source")
	_assert(String(packet.get("status", "")) == "ready_to_capture_station_reentry_host_client", "Export packet is ready to capture")
	_assert(String(packet.get("sync_gate", "")) == "pass", "Export packet reads green TASK_770 sync gate")
	_assert(bool(packet.get("sync_manifest_exists", false)), "Export packet sees TASK_770 manifest")
	_assert(bool(packet.get("scenario_exists", false)), "Export packet sees scenario file")
	_assert(bool(packet.get("workbench_exists", false)), "Export packet sees workbench file")
	_assert(String(packet.get("workbench_file_uri", "")).begins_with("file:///"), "Export packet exposes workbench file URI")
	_assert(bool(packet.get("read_only", false)), "Export packet stays read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Export packet does not set gameplay truth")
	_assert(not bool(packet.get("creates_command", true)), "Export packet does not create commands")
	_assert(bool(packet.get("manual_review_required", false)), "Export packet requires manual review")
	_assert(not bool(packet.get("manual_review_done", true)), "Export packet does not claim manual review done")
	_assert(String(packet.get("expected_host_next_order_text", "")).contains("PREVIEW"), "Export packet carries expected host next order")
	_assert(String(packet.get("expected_client_next_order_text", "")).contains("PREVIEW"), "Export packet carries expected client next order")
	_assert(bool(packet.get("expected_same_next_order", false)), "Export packet carries same-next-order expectation")
	_assert(bool(packet.get("expected_same_route_line", false)), "Export packet carries same-route expectation")
	_assert(bool(packet.get("expected_same_cue_line", false)), "Export packet carries same-cue expectation")
	_assert(bool(packet.get("expected_peer_context_distinct", false)), "Export packet carries peer-context expectation")
	_assert(_array_contains(packet.get("required_manual_checks", []), "host_client_same_next_order_visible"), "Manual checks include same next order")
	_assert(_array_contains(packet.get("required_manual_checks", []), "export_json_saved"), "Manual checks include JSON export")
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Export packet launch command is present")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Export packet capture command is present")
	_assert(String(commands.get("rerun_sync_verifier", "")).contains("task_770_station_reentry_host_client_next_order_sync.gd"), "Export packet exposes TASK_770 verifier")
	_assert(String(commands.get("rerun_export_verifier", "")).contains("task_771_station_reentry_visible_host_client_playtest_export.gd"), "Export packet exposes TASK_771 verifier")
	_assert(String(packet.get("recommended_next_task", "")) == "TASK_772 - Station Reentry Host Client Export Findings", "Export packet routes to TASK_772")


func _build_peer_snapshot(role: String, peer_id: int, team_id: String) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_performance_feel_pass.v1",
		"task_id": "TASK_769",
		"performance_gate": "pass",
		"ready_for_visible_playtest": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"peer_role": role,
		"peer_id": peer_id,
		"team_id": team_id,
		"next_order_text": "WP 1/1 MOVE | WARTET AUF GO | Ziel 544,288 | PREVIEW Dist 120m | ETA~2s | RISK ? no intel",
		"station_route_line": "ROUTE AA > DOOR > COM > CARGO | NEXT AA",
		"station_cue_line": "CUE AA: BLUE naeher ran | 3.9km",
	}


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
