extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_620_host_client_badge_recapture_review.md"
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
	print("=== TASK_620 Host Client Badge Re-Capture Review ===")
	_test_docs_reports_and_contract()
	_test_capture_tool_contract()
	_test_manifest_fields_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_620: FAILED")
		quit(1)
		return
	print("TASK_620: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(STATUS_HANDBOOK_REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_620 task file exists")
	_assert(task_text.contains("Host Client Badge Re-Capture Review"), "TASK_620 task names badge recapture review")
	_assert(status_text.contains("TASK_620 - Host Client Badge Re-Capture Review"), "Implementation status tracks TASK_620")
	_assert(roadmap_text.contains("TASK_620 - Host Client Badge Re-Capture Review (implementiert)"), "Roadmap marks TASK_620 implemented")
	_assert(contract_text.contains("Host-Client-Badge-Re-Capture-Review"), "Mission feedback contract documents TASK_620")
	_assert(report_text.contains("TASK_620 Host Client Badge Re-Capture Review"), "Rolling review workbench tracks TASK_620")
	_assert(report_text.contains("TASK_621 - Host Client Multiplayer Feel Review Bundle"), "Rolling report advances to TASK_621 after TASK_620")
	_assert(handbook_text.contains("TASK_620 Re-Capture-Evidence"), "Status handbook tracks TASK_620 evidence")
	_assert(handbook_text.contains('current_task: "TASK_621 - Host Client Multiplayer Feel Review Bundle"'), "Status handbook JSON metadata advances current task")
	_assert(handbook_text.contains('latest_completed_task: "TASK_621 - Host Client Multiplayer Feel Review Bundle"'), "Status handbook JSON metadata advances latest task")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_badge_recapture.task_id",
		"host_client_badge_recapture.manifest_path",
		"host_client_badge_recapture.host_crop_path",
		"host_client_badge_recapture.client_crop_path",
		"host_client_badge_recapture.host_expected_badge_text",
		"host_client_badge_recapture.client_expected_badge_text",
		"host_client_badge_recapture.badge_expected_hud_path",
		"host_client_badge_recapture.badge_recapture_gate",
		"host_client_badge_recapture.boundary",
		"host_client_badge_recapture.recommended_next_task",
		"host_client_badge_recapture.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_badge_recapture"'), "Rolling report exports TASK_620 free note")
	_assert(handbook_text.contains('data-export-key="status.task_620_done"'), "Status handbook exports TASK_620 checkbox")
	_assert(handbook_text.contains("Host Client Multiplayer Feel Review"), "Reports recommend multiplayer feel review next")


func _test_capture_tool_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"ConvertTo-TeamBadgeLabel",
		"Build-ExpectedReviewBadgeText",
		"hostExpectedBadgeText",
		"clientExpectedBadgeText",
		"badge_recapture_task_id",
		"badge_recapture_review_required",
		"badge_recapture_review_done",
		"badge_recapture_gate",
		"host_expected_badge_text",
		"client_expected_badge_text",
		"badge_expected_style_id",
		"badge_expected_hud_path",
		"host_badge_crop_path",
		"client_badge_crop_path",
		"recommended_next_badge_review_task",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_fields_if_present() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_620 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema remains stable")
	_assert(String(manifest.get("badge_recapture_task_id", "")) == "TASK_620", "Manifest records TASK_620 badge recapture task")
	_assert(bool(manifest.get("badge_recapture_review_required", false)), "Manifest requires badge recapture review")
	_assert(String(manifest.get("host_expected_badge_text", "")) == "HOST P1 ALPHA", "Manifest records expected host badge text")
	_assert(String(manifest.get("client_expected_badge_text", "")) == "CLIENT P2 BRAVO", "Manifest records expected client badge text")
	_assert(String(manifest.get("badge_expected_style_id", "")) == "host_client_role_peer_badge_v1", "Manifest records expected badge style")
	_assert(String(manifest.get("badge_expected_hud_path", "")) == "MissionIdentityHeaderLabel", "Manifest records prominent HUD path")
	_assert(String(manifest.get("host_badge_crop_path", "")) == "tmp/host_client_two_window_host_review.png", "Manifest records host badge crop path")
	_assert(String(manifest.get("client_badge_crop_path", "")) == "tmp/host_client_two_window_client_review.png", "Manifest records client badge crop path")
	_assert(String(manifest.get("recommended_next_badge_review_task", "")) == "TASK_620 - Host Client Badge Re-Capture Review", "Manifest records TASK_620 follow-up field")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")


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
