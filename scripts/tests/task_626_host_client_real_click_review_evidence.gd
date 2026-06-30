extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_626_host_client_real_click_review_evidence.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const STATUS_HANDBOOK_REPORT_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_626 Host Client Real Click Review Evidence ===")
	_test_docs_reports_and_contract()
	_test_capture_tool_contract()
	_test_manifest_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_626: FAILED")
		quit(1)
		return
	print("TASK_626: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(STATUS_HANDBOOK_REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_626 task file exists")
	_assert(task_text.contains("Host Client Real Click Review Evidence"), "TASK_626 task names real click review evidence")
	_assert(status_text.contains("TASK_626 - Host Client Real Click Review Evidence"), "Implementation status tracks TASK_626")
	_assert(roadmap_text.contains("TASK_626 - Host Client Real Click Review Evidence (implementiert)"), "Roadmap marks TASK_626 implemented")
	_assert(contract_text.contains("Host-Client-Real-Click-Review-Evidence"), "Mission feedback contract documents TASK_626")
	_assert(report_text.contains("TASK_626 Host Client Real Click Review Evidence"), "Rolling report tracks TASK_626")
	_assert(report_text.contains('latest_completed_task: "TASK_637 - Frontier Probe Playfeel Next Interaction"'), "Rolling report advances latest completed beyond TASK_626")
	_assert(handbook_text.contains("TASK_626 - Host Client Real Click Review Evidence"), "Status handbook tracks TASK_626")
	_assert(handbook_text.contains('current_task: "TASK_637 - Frontier Probe Playfeel Next Interaction"'), "Status handbook current task advances beyond TASK_626")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_real_click_review.task_id",
		"host_client_real_click_review.manifest_path",
		"host_client_real_click_review.visible_reject_expected_text",
		"host_client_real_click_review.visible_reject_expected_authority_text",
		"host_client_real_click_review.visible_reject_expected_feedback_line",
		"host_client_real_click_review.visible_reject_expected_raw_reason",
		"host_client_real_click_review.visible_reject_expected_hud_path",
		"host_client_real_click_review.visible_reject_review_gate",
		"host_client_real_click_review.manual_review_required",
		"host_client_real_click_review.manual_review_done",
		"host_client_real_click_review.read_only",
		"host_client_real_click_review.recommended_next_task",
		"host_client_real_click_review.peer2_alpha_reject_clicked",
		"host_client_real_click_review.block_cue_visible",
		"host_client_real_click_review.raw_reason_tooltip_checked",
		"host_client_real_click_review.input_latency_noted",
		"host_client_real_click_review.snapshot_sync_after_reject_checked",
		"host_client_real_click_review.focus_recovered_checked",
		"host_client_real_click_review.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_real_click_review"'), "Rolling report exports TASK_626 free note")
	_assert(handbook_text.contains('data-export-key="status.task_626_done"'), "Status handbook exports TASK_626 checkbox")


func _test_capture_tool_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"real_click_review_task_id",
		"visible_reject_expected_text",
		"visible_reject_expected_authority_text",
		"visible_reject_expected_feedback_line",
		"visible_reject_expected_raw_reason",
		"visible_reject_expected_hud_path",
		"visible_reject_review_required",
		"visible_reject_review_done",
		"visible_reject_review_gate",
		"visible_reject_manual_checks",
		"peer2_alpha_reject_clicked",
		"block_cue_visible",
		"raw_reason_in_tooltip",
		"input_latency_noted",
		"snapshot_sync_after_reject",
		"host_client_focus_recovered",
		"recommended_next_real_click_review_task",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_fields() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_626 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema remains stable")
	_assert(String(manifest.get("real_click_review_task_id", "")) == "TASK_626", "Manifest records TASK_626 real click task")
	_assert(String(manifest.get("visible_reject_expected_text", "")) == "BLOCK P2 wrong team", "Manifest records expected visible reject text")
	_assert(String(manifest.get("visible_reject_expected_authority_text", "")) == "AUTH OK1/RJ2", "Manifest records expected AUTH text")
	_assert(String(manifest.get("visible_reject_expected_feedback_line", "")) == "AUTH BLOCKED P2: wrong team", "Manifest records expected feedback line")
	_assert(String(manifest.get("visible_reject_expected_raw_reason", "")) == "peer_team_mismatch", "Manifest records expected raw reject reason")
	_assert(String(manifest.get("visible_reject_expected_hud_path", "")) == "MissionTeamChipLabel", "Manifest records expected HUD path")
	_assert(bool(manifest.get("visible_reject_review_required", false)), "Manifest requires visible reject review")
	_assert(not bool(manifest.get("visible_reject_review_done", true)), "Manifest does not claim manual click review done")
	_assert(String(manifest.get("visible_reject_review_gate", "")) in ["manual_open", "review_ready"], "Manifest records valid review gate")
	_assert(_array_contains(manifest.get("visible_reject_manual_checks", []), "peer2_alpha_reject_clicked"), "Manifest requires Peer 2 Alpha reject click check")
	_assert(_array_contains(manifest.get("visible_reject_manual_checks", []), "raw_reason_in_tooltip"), "Manifest requires raw reason tooltip check")
	_assert(_array_contains(manifest.get("review_checks", []), "visible_reject_feedback_readable"), "Manifest review checks include visible reject readability")
	_assert(String(manifest.get("recommended_next_real_click_review_task", "")) == "TASK_626 - Host Client Real Click Review Evidence", "Manifest records TASK_626 follow-up field")
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
