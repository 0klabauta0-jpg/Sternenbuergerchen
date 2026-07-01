extends SceneTree

const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_decision_polish_acceptance.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_791_station_reentry_firefight_decision_host_client_recapture.md"
const TASK_790_PATH: String = "res://docs/tasks/TASK_790_station_reentry_firefight_decision_polish_acceptance.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_decision_host_client_recapture.ps1"
const ACCEPTANCE_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_decision_polish_acceptance.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_decision_host_client_recapture.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_791 Station Reentry Firefight Decision Host Client Recapture ===")
	_test_docs_contract_and_report()
	_test_tool_declares_packet()
	_write_acceptance_manifest()
	_run_tool()
	_test_packet_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_791: FAILED")
		quit(1)
		return
	print("TASK_791: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_791 task file exists")
	_assert(FileAccess.file_exists(TASK_790_PATH), "TASK_790 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Decision Host Client Recapture"), "TASK_791 task names host/client recapture")
	_assert(status_text.contains("TASK_791 - Station Reentry Firefight Decision Host Client Recapture"), "Implementation status tracks TASK_791")
	_assert(roadmap_text.contains("TASK_791 - Station Reentry Firefight Decision Host Client Recapture (implementiert)"), "Roadmap marks TASK_791 implemented")
	_assert(roadmap_text.contains("TASK_792 - Station Reentry Firefight Decision Host Client Findings"), "Roadmap advances to TASK_792")
	_assert(contract_text.contains("Station-Reentry-Firefight-Decision-Host-Client-Recapture"), "Mission command feedback contract documents TASK_791")
	_assert(report_text.contains("Aktueller Griff: TASK_792"), "Reentry handbook marks TASK_792 current")
	_assert(report_text.contains("station_reentry_firefight_decision_host_client_recapture.json"), "Reentry handbook names TASK_791 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_decision_host_client_recapture.ready_to_capture"'), "Reentry handbook exports TASK_791 ready check")
	_assert(report_text.contains('data-export-key="reentry_firefight_decision_host_client_recapture.host_client_same_decision_line"'), "Reentry handbook exports TASK_791 sync check")


func _test_tool_declares_packet() -> void:
	var text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_791 prepare tool exists")
	for term in [
		"sternenbuergerchen.station_reentry_firefight_decision_host_client_recapture.v1",
		"TASK_791",
		"TASK_790",
		"station_reentry_firefight_decision_host_client_recapture.json",
		"ready_to_capture_firefight_decision_host_client",
		"host_client_same_decision_line",
		"manual_two_window_review_done = $false",
	]:
		_assert(text.contains(term), "Prepare tool contains %s" % term)


func _write_acceptance_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var acceptance: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings(), {
		"manifest_path": "tmp/station_reentry_firefight_decision_polish_acceptance.json",
	}))
	var file := FileAccess.open(ACCEPTANCE_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_790 acceptance manifest for TASK_791 setup")
		return
	file.store_string(JSON.stringify(acceptance, "\t"))
	file.close()
	_assert(FileAccess.file_exists(ACCEPTANCE_MANIFEST_PATH), "TASK_790 acceptance manifest is prepared")


func _run_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_791 prepare tool exits 0")
	if exit_code != 0:
		for line in output:
			print(line)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_791 manifest exists after prepare")


func _test_packet_manifest() -> void:
	var packet: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_decision_host_client_recapture.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_791", "Packet records TASK_791")
	_assert(String(packet.get("source_task_id", "")) == "TASK_790", "Packet records TASK_790 source")
	_assert(String(packet.get("status", "")) == "ready_to_capture_firefight_decision_host_client", "Packet is ready to capture host/client decision")
	_assert(bool(packet.get("scenario_exists", false)), "Packet sees scenario file")
	_assert(bool(packet.get("workbench_exists", false)), "Packet sees workbench file")
	_assert(String(packet.get("workbench_file_uri", "")).begins_with("file:///"), "Packet exposes workbench file URI")
	_assert(bool(packet.get("acceptance_manifest_exists", false)), "Packet sees TASK_790 acceptance manifest")
	_assert(String(packet.get("acceptance_status", "")) == "accepted_for_next_firefight_decision_slice", "Packet records accepted TASK_790 status")
	_assert(bool(packet.get("accepted_for_next_firefight_decision_slice", false)), "Packet requires accepted TASK_790 slice")
	_assert(String(packet.get("expected_decision_line", "")).begins_with("NEXT HOLD"), "Packet carries accepted decision line")
	_assert(String(packet.get("expected_primary_action_label", "")) == "HOLD", "Packet carries accepted primary action")
	_assert(_array_contains(packet.get("expected_quick_action_labels", []), "HOLD FIRE"), "Packet carries HOLD FIRE quick action")
	_assert(String(packet.get("expected_reason_line", "")).contains("FF HIT"), "Packet carries reason line")
	_assert(String(packet.get("expected_guard_line", "")).contains("NO AUTO CMD"), "Packet carries guard line")
	_assert(String(packet.get("expected_confirm_control", "")).contains("GO"), "Packet carries confirm control")
	_assert(bool(packet.get("expected_no_auto_command_commit", false)), "Packet expects no auto-command commit")
	_assert(bool(packet.get("expected_existing_commands_only", false)), "Packet expects existing commands only")
	_assert(bool(packet.get("expected_host_client_context_visible", false)), "Packet expects host/client context")
	_assert(String(packet.get("expected_host_role", "")) == "HOST P1 ALPHA", "Packet names expected host context")
	_assert(String(packet.get("expected_client_role", "")) == "CLIENT P2 BRAVO", "Packet names expected client context")
	_assert(_snapshot_is_read_only(packet), "Packet remains read-only")
	_assert(bool(packet.get("manual_two_window_review_required", false)), "Packet requires manual two-window review")
	_assert(not bool(packet.get("manual_two_window_review_done", true)), "Packet does not claim manual two-window review done")
	for check_id in [
		"host_window_open",
		"client_window_open",
		"host_decision_card_visible",
		"client_decision_card_visible",
		"host_client_same_decision_line",
		"host_client_same_primary_action",
		"host_client_same_quick_actions",
		"host_client_same_reason_line",
		"host_client_same_guard_line",
		"host_client_same_confirm_control",
		"no_auto_command_commit_visible",
		"existing_buttons_visible",
		"peer_team_context_distinct",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		_assert(_array_contains(packet.get("required_manual_checks", []), check_id), "Manual checks include %s" % check_id)
	var commands: Dictionary = Dictionary(packet.get("commands", {}))
	_assert(String(commands.get("launch_windows", "")).contains("launch_host_client_two_window_review.ps1"), "Packet launch command is present")
	_assert(String(commands.get("capture_windows", "")).contains("capture_host_client_two_window_real_run.ps1"), "Packet capture command is present")
	_assert(String(commands.get("open_workbench", "")).begins_with("file:///"), "Packet workbench URI command is present")
	_assert(String(commands.get("rerun_acceptance_verifier", "")).contains("task_790_station_reentry_firefight_decision_polish_acceptance.gd"), "Packet exposes TASK_790 verifier")
	_assert(String(commands.get("rerun_decision_host_client_recapture_verifier", "")).contains("task_791_station_reentry_firefight_decision_host_client_recapture.gd"), "Packet exposes TASK_791 verifier")
	_assert(String(packet.get("recommended_next_task", "")) == "TASK_792 - Station Reentry Firefight Decision Host Client Findings", "Packet routes to TASK_792")


func _findings() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_decision_evidence_findings.v1",
		"task_id": "TASK_789",
		"source_task_id": "TASK_788",
		"status": "ready_for_firefight_decision_polish_acceptance",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"manual_review_done": true,
		"visible_review_done": true,
		"missing_check_ids": [],
		"active_issue_count": 0,
		"action_items": [],
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_reason_line": "WHY FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_confirm_control": "existing command buttons / GO",
		"expected_no_auto_command_commit": true,
		"expected_existing_commands_only": true,
		"expected_host_client_context_visible": true,
	}


func _array_contains(value: Variant, expected: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for entry in Array(value):
		if String(entry) == expected:
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
