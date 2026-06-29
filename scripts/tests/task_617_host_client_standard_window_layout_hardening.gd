extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_617_host_client_standard_window_layout_hardening.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TOOL_PATH: String = "res://scripts/tools/launch_host_client_two_window_review.ps1"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const PLAN_PATH: String = "res://tmp/host_client_two_window_launch_plan.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_617 Host Client Standard Window Layout Hardening ===")
	_test_docs_report_and_contract()
	_test_launch_helper_layout_autofit_script()
	_test_launch_plan_layout_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_617: FAILED")
		quit(1)
		return
	print("TASK_617: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_617 task file exists")
	_assert(task_text.contains("Standard Window Layout Hardening"), "TASK_617 task names layout hardening")
	_assert(status_text.contains("TASK_617 - Host Client Standard Window Layout Hardening"), "Implementation status tracks TASK_617")
	_assert(roadmap_text.contains("TASK_617 - Host Client Standard Window Layout Hardening (implementiert)"), "Roadmap marks TASK_617 implemented")
	_assert(contract_text.contains("Host-Client-Standard-Window-Layout-Hardening"), "Mission feedback contract documents TASK_617")
	_assert(report_text.contains("TASK_617 Host Client Standard Window Layout Hardening"), "Review workbench tracks TASK_617")
	_assert(report_text.contains('data-export-key="host_client_standard_window_layout.auto_fit_applied"'), "Report exports TASK_617 auto-fit field")
	_assert(report_text.contains('"TASK_617 - Host Client Standard Window Layout Hardening"'), "JSON payload keeps TASK_617 in completed chain")
	_assert(report_text.contains('latest_completed_task: "TASK_620 - Host Client Badge Re-Capture Review"'), "JSON payload advances latest completed task to TASK_620")


func _test_launch_helper_layout_autofit_script() -> void:
	var tool_text: String = _read_text(TOOL_PATH)
	var required_terms: Array[String] = [
		"Resolve-PrimaryScreenBounds",
		"Resolve-WindowLayout",
		"DisableAutoFitLayout",
		"requested_window_layout",
		"window_layout_auto_fit",
		"requested_layout_exceeded_primary_work_area",
		"System.Windows.Forms.Screen",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Launch helper contains %s" % term)
	var capture_text: String = _read_text(CAPTURE_TOOL_PATH)
	_assert(capture_text.contains("SetWindowPos"), "Capture helper can raise review windows")
	_assert(capture_text.contains("window_raise_attempted"), "Capture helper records raise attempt")
	_assert(capture_text.contains("Release-ReviewWindowTopmost"), "Capture helper releases topmost review windows after capture")


func _test_launch_plan_layout_if_present() -> void:
	_assert(FileAccess.file_exists(PLAN_PATH), "Launch plan exists for TASK_617 verification")
	if not FileAccess.file_exists(PLAN_PATH):
		return
	var plan: Dictionary = _read_json(PLAN_PATH)
	var requested: Dictionary = Dictionary(plan.get("requested_window_layout", {}))
	var auto_fit: Dictionary = Dictionary(plan.get("window_layout_auto_fit", {}))
	var layout: Dictionary = Dictionary(plan.get("window_layout", {}))
	var host: Dictionary = Dictionary(plan.get("host", {}))
	var client: Dictionary = Dictionary(plan.get("client", {}))
	_assert(not requested.is_empty(), "Launch plan records requested window layout")
	_assert(not auto_fit.is_empty(), "Launch plan records auto-fit metadata")
	_assert(not layout.is_empty(), "Launch plan records effective window layout")
	_assert(host.has("window") and client.has("window"), "Launch plan records host and client windows")
	var screen: Dictionary = Dictionary(auto_fit.get("screen", {}))
	if bool(screen.get("available", false)):
		var screen_width: int = int(screen.get("width", 0))
		var screen_height: int = int(screen.get("height", 0))
		var host_window: Dictionary = Dictionary(host.get("window", {}))
		var client_window: Dictionary = Dictionary(client.get("window", {}))
		_assert(int(host_window.get("x", 0)) + int(host_window.get("width", 0)) <= screen_width, "Host window fits primary work area width")
		_assert(int(client_window.get("x", 0)) + int(client_window.get("width", 0)) <= screen_width, "Client window fits primary work area width")
		_assert(int(host_window.get("y", 0)) + int(host_window.get("height", 0)) <= screen_height, "Host window fits primary work area height")
		_assert(int(client_window.get("y", 0)) + int(client_window.get("height", 0)) <= screen_height, "Client window fits primary work area height")
	_assert(bool(plan.get("read_only", false)), "Launch plan remains read-only")
	_assert(not bool(plan.get("ui_sets_gameplay_truth", true)), "Launch plan does not set gameplay truth")


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
