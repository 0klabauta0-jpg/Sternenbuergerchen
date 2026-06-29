extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_618_host_client_standard_capture_crop_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_618 Host Client Standard Capture Crop Review ===")
	_test_docs_report_and_contract()
	_test_capture_tool_crop_contract()
	_test_manifest_crop_fields_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_618: FAILED")
		quit(1)
		return
	print("TASK_618: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_618 task file exists")
	_assert(task_text.contains("Standard Capture Crop Review"), "TASK_618 task names crop review")
	_assert(status_text.contains("TASK_618 - Host Client Standard Capture Crop Review"), "Implementation status tracks TASK_618")
	_assert(roadmap_text.contains("TASK_618 - Host Client Standard Capture Crop Review (implementiert)"), "Roadmap marks TASK_618 implemented")
	_assert(contract_text.contains("Host-Client-Standard-Capture-Crop-Review"), "Mission feedback contract documents TASK_618")
	_assert(report_text.contains("TASK_618 Host Client Standard Capture Crop Review"), "Review workbench tracks TASK_618")
	_assert(report_text.contains('latest_completed_task: "TASK_620 - Host Client Badge Re-Capture Review"'), "JSON payload lists TASK_620 as latest completed task")
	_assert(report_text.contains("TASK_619 - Host Client Role Peer Badge HUD"), "Report recommends TASK_619 role/peer HUD follow-up")
	_test_report_export_fields(report_text)


func _test_report_export_fields(report_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_standard_capture_crop.tool_path",
		"host_client_standard_capture_crop.desktop_screenshot_path",
		"host_client_standard_capture_crop.host_screenshot_path",
		"host_client_standard_capture_crop.client_screenshot_path",
		"host_client_standard_capture_crop.host_screenshot_written",
		"host_client_standard_capture_crop.client_screenshot_written",
		"host_client_standard_capture_crop.crop_status_fields",
		"host_client_standard_capture_crop.finding",
		"host_client_standard_capture_crop.read_only",
		"host_client_standard_capture_crop.recommended_next_task",
		"host_client_standard_capture_crop.real_run_crop_written",
		"host_client_standard_capture_crop.world_visible_checked",
		"host_client_standard_capture_crop.role_peer_gap_checked",
		"host_client_standard_capture_crop.no_gameplay_truth_checked",
		"host_client_standard_capture_crop.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_standard_capture_crop"'), "Report exports free TASK_618 crop note")


func _test_capture_tool_crop_contract() -> void:
	var tool_text: String = _read_text(CAPTURE_TOOL_PATH)
	var required_terms: Array[String] = [
		"Export-DesktopCrop",
		"HostScreenshotPath",
		"ClientScreenshotPath",
		"host_client_two_window_host_review.png",
		"host_client_two_window_client_review.png",
		"host_screenshot_path",
		"client_screenshot_path",
		"host_screenshot_written",
		"client_screenshot_written",
		"host_crop_status",
		"client_crop_status",
		"recommended_next_capture_task",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_crop_fields_if_present() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_618 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Manifest schema remains stable")
	_assert(String(manifest.get("task_id", "")) == "TASK_614", "Manifest remains TASK_614 real-run evidence")
	_assert(String(manifest.get("host_screenshot_path", "")) == "tmp/host_client_two_window_host_review.png", "Manifest records host crop path")
	_assert(String(manifest.get("client_screenshot_path", "")) == "tmp/host_client_two_window_client_review.png", "Manifest records client crop path")
	_assert(manifest.has("host_screenshot_written"), "Manifest records host crop written flag")
	_assert(manifest.has("client_screenshot_written"), "Manifest records client crop written flag")
	_assert(manifest.has("host_crop_status"), "Manifest records host crop status")
	_assert(manifest.has("client_crop_status"), "Manifest records client crop status")
	_assert(String(manifest.get("recommended_next_capture_task", "")) == "TASK_618 - Host Client Standard Capture Crop Review", "Manifest recommends TASK_618 capture review")
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
