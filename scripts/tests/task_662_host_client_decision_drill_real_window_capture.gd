extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_662_host_client_decision_drill_real_window_capture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const SOURCE_PACKET_PATH: String = "res://tmp/host_client_decision_drill_click_evidence.json"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_662 Host Client Decision Drill Real Window Capture ===")
	_test_docs_report_and_contract()
	_test_capture_tool_contract()
	_test_manifest_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_662: FAILED")
		quit(1)
		return
	print("TASK_662: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_662 task file exists")
	_assert(task_text.contains("Host Client Decision Drill Real Window Capture"), "TASK_662 task names real window capture")
	_assert(status_text.contains("TASK_662 - Host Client Decision Drill Real Window Capture"), "Implementation status tracks TASK_662")
	_assert(roadmap_text.contains("TASK_662 - Host Client Decision Drill Real Window Capture (implementiert)"), "Roadmap marks TASK_662 implemented")
	_assert(contract_text.contains("Host-Client-Decision-Drill-Real-Window-Capture"), "Mission feedback contract documents TASK_662")
	_assert(report_text.contains("TASK_662 - Host Client Decision Drill Real Window Capture"), "Current handbook report tracks TASK_662")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook exports a latest completed task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook exports a recommended next task")
	_assert(report_text.contains("TASK_663 - Host Client Decision Drill Visual Findings"), "Current handbook tracks the TASK_662 follow-up")
	_assert(report_text.contains('data-export-key="status.task_662_done"'), "Current handbook exports TASK_662 done status")
	_assert(report_text.contains('data-export-key="host_client_decision_drill_capture.use_bravo_required"'), "Current handbook exports USE BRAVO capture check")
	_assert(report_text.contains('data-export-key="host_client_decision_drill_capture.preview_before_go_required"'), "Current handbook exports preview-before-GO capture check")
	_assert(report_text.contains('data-note-key="notes.host_client_decision_drill_capture"'), "Current handbook exports TASK_662 notes")


func _test_capture_tool_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"decision_drill_capture_task_id",
		"decision_drill_source_packet_task_id",
		"decision_drill_source_packet_path",
		"decision_drill_source_packet_present",
		"decision_drill_expected_wrong_context_reason",
		"decision_drill_expected_block_text",
		"decision_drill_expected_action_text",
		"decision_drill_expected_next_token",
		"decision_drill_expected_recommended_plan_id",
		"decision_drill_expected_correct_fireteam",
		"decision_drill_expected_confirm_control",
		"decision_drill_review_required",
		"decision_drill_review_done",
		"decision_drill_review_gate",
		"decision_drill_manual_checks",
		"use_bravo_visible",
		"bravo_context_selected",
		"next_aa_visible_after_context_switch",
		"move_preview_readable_before_go",
		"go_feedback_visible_after_confirm",
		"recommended_next_decision_drill_capture_task",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_fields() -> void:
	_assert(FileAccess.file_exists(SOURCE_PACKET_PATH), "TASK_661 source packet exists for TASK_662")
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_662 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema remains stable")
	_assert(String(manifest.get("decision_drill_capture_task_id", "")) == "TASK_662", "Manifest records TASK_662 decision drill capture")
	_assert(String(manifest.get("decision_drill_source_packet_task_id", "")) == "TASK_661", "Manifest records TASK_661 as source")
	_assert(String(manifest.get("decision_drill_source_packet_path", "")) == "tmp/host_client_decision_drill_click_evidence.json", "Manifest records source packet path")
	_assert(bool(manifest.get("decision_drill_source_packet_present", false)), "Manifest sees TASK_661 source packet")
	_assert(String(manifest.get("decision_drill_expected_wrong_context_reason", "")) == "peer_team_mismatch", "Manifest records peer-team mismatch")
	_assert(String(manifest.get("decision_drill_expected_block_text", "")) == "BLOCK P2 wrong team", "Manifest records block text")
	_assert(String(manifest.get("decision_drill_expected_action_text", "")) == "USE BRAVO", "Manifest records USE BRAVO action")
	_assert(String(manifest.get("decision_drill_expected_next_token", "")) == "AA", "Manifest records NEXT AA")
	_assert(String(manifest.get("decision_drill_expected_recommended_plan_id", "")) == "aa_first_push", "Manifest records AA-first plan")
	_assert(String(manifest.get("decision_drill_expected_correct_fireteam", "")) == "bravo", "Manifest records Bravo as correct fireteam")
	_assert(String(manifest.get("decision_drill_expected_confirm_control", "")) == "GO", "Manifest records GO confirmation")
	_assert(bool(manifest.get("decision_drill_review_required", false)), "Manifest requires decision drill review")
	_assert(not bool(manifest.get("decision_drill_review_done", true)), "Manifest does not claim review done")
	_assert(String(manifest.get("decision_drill_review_gate", "")) in ["manual_open", "review_ready"], "Manifest records valid decision drill gate")
	_assert(_array_contains(manifest.get("decision_drill_manual_checks", []), "use_bravo_visible"), "Manifest requires USE BRAVO visibility")
	_assert(_array_contains(manifest.get("decision_drill_manual_checks", []), "bravo_context_selected"), "Manifest requires Bravo context")
	_assert(_array_contains(manifest.get("decision_drill_manual_checks", []), "next_aa_visible_after_context_switch"), "Manifest requires NEXT AA after context switch")
	_assert(_array_contains(manifest.get("decision_drill_manual_checks", []), "move_preview_readable_before_go"), "Manifest requires preview before GO")
	_assert(_array_contains(manifest.get("decision_drill_manual_checks", []), "go_feedback_visible_after_confirm"), "Manifest requires GO feedback")
	_assert(_array_contains(manifest.get("review_checks", []), "decision_drill_use_bravo_visible"), "Review checks include USE BRAVO")
	_assert(_array_contains(manifest.get("review_checks", []), "decision_drill_preview_before_go"), "Review checks include preview before GO")
	_assert(String(manifest.get("recommended_next_decision_drill_capture_task", "")) == "TASK_663 - Host Client Decision Drill Visual Findings", "Manifest recommends visual findings follow-up")
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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
