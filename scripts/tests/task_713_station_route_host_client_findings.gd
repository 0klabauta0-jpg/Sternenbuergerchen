extends SceneTree

const STATION_ROUTE_HOST_CLIENT_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_route_host_client_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_713_station_route_host_client_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_host_client_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_713 Station Route Host/Client Findings ===")
	_test_docs()
	_test_missing_packet_blocks()
	_test_manual_open_snapshot()
	_test_review_ready_snapshot()
	_test_done_without_evidence_blocks()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_713: FAILED")
		quit(1)
		return
	print("TASK_713: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_713 task file exists")
	_assert(task_text.contains("Station Route Host/Client Findings"), "Task documents station route host/client findings")
	_assert(contract_text.contains("Station Route Host/Client Findings"), "Interaction contract documents TASK_713")
	_assert(status_text.contains("TASK_713 - Station Route Host/Client Findings"), "Implementation status tracks TASK_713")
	_assert(roadmap_text.contains("TASK_713 - Station Route Host/Client Findings (implementiert)"), "Roadmap marks TASK_713 implemented")
	_assert(report_text.contains("TASK_713 - Station Route Host/Client Findings"), "Current report references TASK_713")
	_assert(report_text.contains('data-export-key="station_route_host_client_findings.manifest_path"'), "Current report exports TASK_713 manifest path")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_HOST_CLIENT_FINDINGS_SCRIPT.call("build_snapshot", {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing packet snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_host_client_findings.v1", "Findings schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing packet blocks findings")
	_assert(int(snapshot.get("blocking_issue_count", 0)) > 0, "Missing packet produces blockers")
	_assert(not bool(snapshot.get("technical_packet_ready", true)), "Missing packet is not technically ready")
	_assert(not bool(snapshot.get("host_client_findings_ready", true)), "Missing packet is not findings-ready")


func _test_manual_open_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_HOST_CLIENT_FINDINGS_SCRIPT.call("build_snapshot", _fake_acceptance_packet("manual_open", false, false), {}))
	_assert(_snapshot_is_read_only(snapshot), "Manual-open snapshot is read-only")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Manual-open packet has no technical blockers")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Manual-open packet records manual note")
	_assert(String(snapshot.get("status", "")) == "needs_real_run", "Manual-open packet waits for real run")
	_assert(bool(snapshot.get("technical_packet_ready", false)), "Manual-open packet is technically ready")
	_assert(bool(snapshot.get("manual_acceptance_open", false)), "Manual-open packet keeps acceptance open")
	_assert(not bool(snapshot.get("host_client_findings_ready", true)), "Manual-open packet is not findings-ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_712"), "Manual-open packet recommends TASK_712 real run")


func _test_review_ready_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_HOST_CLIENT_FINDINGS_SCRIPT.call("build_snapshot", _fake_acceptance_packet("review_ready", false, true), {}))
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Review-ready packet has no technical blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_findings_review", "Review-ready packet waits for findings decision")
	_assert(bool(snapshot.get("host_client_findings_ready", false)), "Review-ready packet is findings-ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_713"), "Review-ready packet recommends TASK_713 review")


func _test_done_without_evidence_blocks() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_HOST_CLIENT_FINDINGS_SCRIPT.call("build_snapshot", _fake_acceptance_packet("review_ready", true, false), {}))
	_assert(String(snapshot.get("status", "")) == "blocked", "Review-done without real evidence blocks")
	_assert(int(snapshot.get("blocking_issue_count", 0)) > 0, "Review-done without evidence creates blocker")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_HOST_CLIENT_FINDINGS_SCRIPT.call("build_snapshot", _fake_acceptance_packet("manual_open", false, false), {}))
	snapshot["task_id"] = "TASK_713"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Host/client findings manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_713", "Manifest records TASK_713")
	_assert(String(parsed.get("status", "")) == "needs_real_run", "Manifest records open real-run status")
	_assert(bool(parsed.get("technical_packet_ready", false)), "Manifest keeps technical packet ready")
	_assert(not bool(parsed.get("host_client_findings_ready", true)), "Manifest does not claim findings readiness while manual-open")


func _fake_acceptance_packet(gate: String, review_done: bool, evidence_ready: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
		"manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"station_route_host_client_acceptance_task_id": "TASK_712",
		"station_route_source_visual_evidence_task_id": "TASK_708",
		"station_route_source_window_notes_task_id": "TASK_709",
		"station_route_source_readiness_task_id": "TASK_710",
		"station_route_expected_sequence": ["door_open", "computer_controlled", "cargo_departed"],
		"station_route_expected_wrong_team_reason": "peer_team_mismatch",
		"station_route_expected_snapshot_sync": "client_snapshot_apply_accepted",
		"station_route_host_client_acceptance_review_required": true,
		"station_route_host_client_acceptance_review_done": review_done,
		"station_route_host_client_acceptance_gate": gate,
		"station_route_host_client_manual_checks": [
			"host_window_launched",
			"client_window_launched",
			"host_station_route_visible",
			"client_station_route_visible",
			"door_open_visible_on_host",
			"door_open_visible_on_client",
			"computer_control_visible_after_door",
			"cargo_departed_visible_after_computer",
			"wrong_team_reject_visible",
			"snapshot_sync_after_each_step",
			"hud_feedback_readable",
			"window_notes_exported",
		],
		"review_checks": [
			"station_route_door_open_host_client",
			"station_route_computer_control_visible",
			"station_route_cargo_departed_visible",
		],
		"launch_requested": evidence_ready,
		"real_run_done": evidence_ready,
		"screenshot_written": evidence_ready,
		"host_screenshot_written": evidence_ready,
		"client_screenshot_written": evidence_ready,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_713 manifest for writing")
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
