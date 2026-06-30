extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_651_host_client_click_followup_evidence.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const REAL_RUN_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const PLAYTEST_PACKET_PATH: String = "res://tmp/host_client_real_click_playtest_packet.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_651 Host Client Click Followup Evidence ===")
	_test_docs_and_contract()
	_test_capture_tool_contract()
	_test_real_run_manifest()
	_test_playtest_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_651: FAILED")
		quit(1)
		return
	print("TASK_651: ALL PASSED")
	quit(0)


func _test_docs_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_651 task file exists")
	_assert(task_text.contains("Host Client Click Followup Evidence"), "TASK_651 task names click followup evidence")
	_assert(task_text.contains("USE BRAVO"), "TASK_651 task records action cue")
	_assert(status_text.contains("TASK_651 - Host Client Click Followup Evidence"), "Implementation status tracks TASK_651")
	_assert(roadmap_text.contains("TASK_651 - Host Client Click Followup Evidence (implementiert)"), "Roadmap marks TASK_651 implemented")
	_assert(contract_text.contains("Host-Client-Click-Followup-Evidence"), "Mission feedback contract documents TASK_651")


func _test_capture_tool_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"visible_reject_expected_action_text",
		"visible_reject_expected_next_action_text",
		"visible_reject_expected_next_action_detail",
		"action_cue_visible",
		"visible_reject_action_cue_readable",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture tool records %s" % term)


func _test_real_run_manifest() -> void:
	_assert(FileAccess.file_exists(REAL_RUN_MANIFEST_PATH), "Real-run manifest exists")
	var manifest: Dictionary = _read_json(REAL_RUN_MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema is stable")
	_assert(String(manifest.get("visible_reject_expected_text", "")) == "BLOCK P2 wrong team", "Manifest keeps block text")
	_assert(String(manifest.get("visible_reject_expected_action_text", "")) == "USE BRAVO", "Manifest expects action cue")
	_assert(String(manifest.get("visible_reject_expected_next_action_text", "")) == "Use BRAVO fireteam.", "Manifest expects next action text")
	_assert(String(manifest.get("visible_reject_expected_next_action_detail", "")).contains("Peer 2 should command the BRAVO fireteam"), "Manifest expects next action detail")
	_assert(_array_contains(manifest.get("visible_reject_manual_checks", []), "action_cue_visible"), "Manifest manual checks include action cue")
	_assert(_array_contains(manifest.get("review_checks", []), "visible_reject_action_cue_readable"), "Manifest review checks include action cue readability")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")


func _test_playtest_packet() -> void:
	_assert(FileAccess.file_exists(PLAYTEST_PACKET_PATH), "Playtest packet exists")
	var packet: Dictionary = _read_json(PLAYTEST_PACKET_PATH)
	var feedback: Dictionary = Dictionary(packet.get("expected_visible_feedback", {}))
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.host_client_real_click_playtest_packet.v1", "Packet schema is stable")
	_assert(String(feedback.get("block_text", "")) == "BLOCK P2 wrong team", "Packet keeps block text")
	_assert(String(feedback.get("action_text", "")) == "USE BRAVO", "Packet expects action cue")
	_assert(String(feedback.get("next_action_text", "")) == "Use BRAVO fireteam.", "Packet expects next action text")
	_assert(String(feedback.get("next_action_detail", "")).contains("Peer 2 should command the BRAVO fireteam"), "Packet expects next action detail")
	_assert(_array_contains(packet.get("manual_observations", []), "action_cue_visible"), "Packet manual observations include action cue")
	_assert(bool(packet.get("read_only", false)), "Packet remains read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _array_contains(value: Variant, needle: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for item in Array(value):
		if String(item) == needle:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
