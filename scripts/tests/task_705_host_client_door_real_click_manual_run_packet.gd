extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_705_host_client_door_real_click_manual_run_packet.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_705 Host/Client Door Real Click Manual Run Packet ===")
	_test_docs()
	_test_capture_tool_contract()
	_test_manifest_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_705: FAILED")
		quit(1)
		return
	print("TASK_705: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_705 task file exists")
	_assert(task_text.contains("Host/Client Door Real Click Manual Run Packet"), "Task documents Door manual run packet")
	_assert(contract_text.contains("Host/Client Door Real Click Manual Run Packet"), "Interaction contract documents Door manual run packet")
	_assert(status_text.contains("TASK_705 - Host/Client Door Real Click Manual Run Packet"), "Implementation status tracks TASK_705")
	_assert(roadmap_text.contains("TASK_705 - Host/Client Door Real Click Manual Run Packet (implementiert)"), "Roadmap marks TASK_705 implemented")
	_assert(handbook_text.contains("TASK_705 - Host/Client Door Real Click Manual Run Packet"), "Current handbook references TASK_705")
	_assert(handbook_text.contains('data-export-key="host_client_door_real_click_manual_run.manifest_path"'), "Current handbook exports TASK_705 manifest path")


func _test_capture_tool_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"door_real_click_manual_run_task_id",
		"door_real_click_source_findings_task_id",
		"door_real_click_source_workbench_task_id",
		"door_real_click_workbench_path",
		"door_real_click_findings_manifest_path",
		"door_real_click_workbench_manifest_path",
		"door_real_click_expected_button",
		"door_real_click_expected_shortcut",
		"door_real_click_expected_go_control",
		"door_real_click_expected_ready_line",
		"door_real_click_expected_wrong_team_reason",
		"door_real_click_expected_open_line",
		"door_real_click_expected_hud_surface",
		"door_real_click_manual_review_required",
		"door_real_click_manual_review_done",
		"door_real_click_manual_run_gate",
		"door_real_click_manual_checks",
		"workbench_notes_exported",
		"recommended_next_door_real_click_manual_run_task",
		"recommended_next_door_real_click_after_manual_task",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_fields() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_705 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema remains stable")
	_assert(String(manifest.get("door_real_click_manual_run_task_id", "")) == "TASK_705", "Manifest records TASK_705 Door manual run task")
	_assert(String(manifest.get("door_real_click_source_findings_task_id", "")) == "TASK_704", "Manifest records TASK_704 source findings")
	_assert(String(manifest.get("door_real_click_source_workbench_task_id", "")) == "TASK_700", "Manifest records TASK_700 source workbench")
	_assert(String(manifest.get("door_real_click_workbench_path", "")) == "docs/reports/host_client_door_real_click_workbench_2026_06_30.html", "Manifest records Door workbench path")
	_assert(String(manifest.get("door_real_click_findings_manifest_path", "")) == "tmp/host_client_door_real_click_findings.json", "Manifest records Door findings path")
	_assert(String(manifest.get("door_real_click_workbench_manifest_path", "")) == "tmp/host_client_door_real_click_workbench.json", "Manifest records Door workbench manifest path")
	_assert(String(manifest.get("door_real_click_expected_button", "")) == "DoorBreachButton", "Manifest records Door button")
	_assert(String(manifest.get("door_real_click_expected_shortcut", "")) == "B", "Manifest records shortcut B")
	_assert(String(manifest.get("door_real_click_expected_go_control", "")) == "GO", "Manifest records GO control")
	_assert(_line_is_current_or_legacy(String(manifest.get("door_real_click_expected_ready_line", "")), "DOOR B->GO", "DOOR DOOR B->GO"), "Manifest records ready Door line")
	_assert(String(manifest.get("door_real_click_expected_wrong_team_reason", "")) == "peer_team_mismatch", "Manifest records wrong-team reason")
	_assert(_line_is_current_or_legacy(String(manifest.get("door_real_click_expected_open_line", "")), "DOOR OPEN", "DOOR DOOR OPEN"), "Manifest records open Door line")
	_assert(String(manifest.get("door_real_click_expected_hud_surface", "")) == "mission_interaction_door_authority_visible_line", "Manifest records Door HUD surface field")
	_assert(bool(manifest.get("door_real_click_manual_review_required", false)), "Manifest requires Door manual review")
	_assert(not bool(manifest.get("door_real_click_manual_review_done", true)), "Manifest does not claim Door manual review done")
	_assert(String(manifest.get("door_real_click_manual_run_gate", "")) in ["manual_open", "review_ready"], "Manifest records valid Door manual run gate")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "host_window_launched"), "Manifest requires host window check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "client_window_launched"), "Manifest requires client window check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "shortcut_b_triggers_hook"), "Manifest requires shortcut B check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "go_required_visible"), "Manifest requires GO check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "wrong_team_reject_visible"), "Manifest requires wrong-team reject check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "door_open_visible_on_host"), "Manifest requires host Door open check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "door_open_visible_on_client"), "Manifest requires client Door open check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "hud_feedback_readable"), "Manifest requires HUD readability check")
	_assert(_array_contains(manifest.get("door_real_click_manual_checks", []), "workbench_notes_exported"), "Manifest requires workbench export check")
	_assert(_array_contains(manifest.get("review_checks", []), "door_real_click_shortcut_b"), "Review checks include Door shortcut")
	_assert(_array_contains(manifest.get("review_checks", []), "door_real_click_open_visible_host_client"), "Review checks include Door open visibility")
	_assert(String(manifest.get("recommended_next_door_real_click_manual_run_task", "")) == "TASK_705 - Host/Client Door Real Click Manual Run Packet", "Manifest records TASK_705 follow-up field")
	_assert(String(manifest.get("recommended_next_door_real_click_after_manual_task", "")) == "TASK_706 - Mission Door Layout/Visual Polish", "Manifest records post-manual polish candidate")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")


func _array_contains(value: Variant, needle: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for item in Array(value):
		if String(item) == needle:
			return true
	return false


func _line_is_current_or_legacy(line: String, current_line: String, legacy_line: String) -> bool:
	return line == current_line or line == legacy_line


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
