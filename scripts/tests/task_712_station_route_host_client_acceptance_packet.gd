extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_712 Station Route Host/Client Acceptance Packet ===")
	_test_docs()
	_test_capture_tool_contract()
	_test_manifest_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_712: FAILED")
		quit(1)
		return
	print("TASK_712: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_712 task file exists")
	_assert(task_text.contains("Station Route Host/Client Acceptance Packet"), "Task documents station route host/client packet")
	_assert(contract_text.contains("Station Route Host/Client Acceptance Packet"), "Interaction contract documents TASK_712")
	_assert(status_text.contains("TASK_712 - Station Route Host/Client Acceptance Packet"), "Implementation status tracks TASK_712")
	_assert(roadmap_text.contains("TASK_712 - Station Route Host/Client Acceptance Packet (implementiert)"), "Roadmap marks TASK_712 implemented")
	_assert(report_text.contains("TASK_712 - Station Route Host/Client Acceptance Packet"), "Current report references TASK_712")
	_assert(report_text.contains('data-export-key="station_route_host_client_acceptance.manifest_path"'), "Current report exports TASK_712 manifest path")


func _test_capture_tool_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"station_route_host_client_acceptance_task_id",
		"station_route_source_visual_evidence_task_id",
		"station_route_source_window_notes_task_id",
		"station_route_source_readiness_task_id",
		"station_route_visual_evidence_manifest_path",
		"station_route_window_notes_workbench_path",
		"station_route_window_notes_manifest_path",
		"station_route_readiness_manifest_path",
		"station_route_expected_sequence",
		"station_route_expected_door_line",
		"station_route_expected_computer_line",
		"station_route_expected_cargo_line",
		"station_route_expected_wrong_team_reason",
		"station_route_expected_snapshot_sync",
		"station_route_expected_hud_surfaces",
		"station_route_host_client_acceptance_review_required",
		"station_route_host_client_acceptance_review_done",
		"station_route_host_client_acceptance_gate",
		"station_route_host_client_manual_checks",
		"recommended_next_station_route_host_client_acceptance_task",
		"recommended_next_station_route_after_acceptance_task",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_fields() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_712 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema remains stable")
	_assert(String(manifest.get("station_route_host_client_acceptance_task_id", "")) == "TASK_712", "Manifest records TASK_712")
	_assert(String(manifest.get("station_route_source_visual_evidence_task_id", "")) == "TASK_708", "Manifest records TASK_708 source")
	_assert(String(manifest.get("station_route_source_window_notes_task_id", "")) == "TASK_709", "Manifest records TASK_709 source")
	_assert(String(manifest.get("station_route_source_readiness_task_id", "")) == "TASK_710", "Manifest records TASK_710 source")
	_assert(String(manifest.get("station_route_visual_evidence_manifest_path", "")) == "tmp/station_route_visual_evidence.json", "Manifest records visual evidence path")
	_assert(String(manifest.get("station_route_window_notes_workbench_path", "")) == "docs/reports/station_route_window_playtest_notes_2026_07_01.html", "Manifest records window notes workbench")
	_assert(String(manifest.get("station_route_window_notes_manifest_path", "")) == "tmp/station_route_window_playtest_notes.json", "Manifest records window notes manifest")
	_assert(String(manifest.get("station_route_readiness_manifest_path", "")) == "tmp/station_route_polish_readiness_findings.json", "Manifest records readiness manifest")
	_assert(_array_contains(manifest.get("station_route_expected_sequence", []), "door_open"), "Manifest expects door_open")
	_assert(_array_contains(manifest.get("station_route_expected_sequence", []), "computer_controlled"), "Manifest expects computer_controlled")
	_assert(_array_contains(manifest.get("station_route_expected_sequence", []), "cargo_departed"), "Manifest expects cargo_departed")
	_assert(String(manifest.get("station_route_expected_wrong_team_reason", "")) == "peer_team_mismatch", "Manifest records wrong-team reason")
	_assert(String(manifest.get("station_route_expected_snapshot_sync", "")) == "client_snapshot_apply_accepted", "Manifest records snapshot sync expectation")
	_assert(bool(manifest.get("station_route_host_client_acceptance_review_required", false)), "Manifest requires station route acceptance review")
	_assert(not bool(manifest.get("station_route_host_client_acceptance_review_done", true)), "Manifest does not claim station route acceptance done")
	_assert(String(manifest.get("station_route_host_client_acceptance_gate", "")) in ["manual_open", "review_ready"], "Manifest records valid acceptance gate")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "host_window_launched"), "Manifest requires host window")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "client_window_launched"), "Manifest requires client window")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "door_open_visible_on_host"), "Manifest requires host door visible")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "door_open_visible_on_client"), "Manifest requires client door visible")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "computer_control_visible_after_door"), "Manifest requires computer step")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "cargo_departed_visible_after_computer"), "Manifest requires cargo step")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "wrong_team_reject_visible"), "Manifest requires wrong-team reject")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "snapshot_sync_after_each_step"), "Manifest requires snapshot sync")
	_assert(_array_contains(manifest.get("station_route_host_client_manual_checks", []), "window_notes_exported"), "Manifest requires notes export")
	_assert(_array_contains(manifest.get("review_checks", []), "station_route_door_open_host_client"), "Review checks include station route door")
	_assert(_array_contains(manifest.get("review_checks", []), "station_route_computer_control_visible"), "Review checks include station route computer")
	_assert(_array_contains(manifest.get("review_checks", []), "station_route_cargo_departed_visible"), "Review checks include station route cargo")
	_assert(String(manifest.get("recommended_next_station_route_host_client_acceptance_task", "")) == "TASK_712 - Station Route Host/Client Acceptance Packet", "Manifest records TASK_712 follow-up")
	_assert(String(manifest.get("recommended_next_station_route_after_acceptance_task", "")) == "TASK_713 - Station Route Host/Client Findings", "Manifest records TASK_713 follow-up")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")


func _array_contains(value: Variant, needle: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for item in Array(value):
		if String(item) == needle:
			return true
	return false


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
