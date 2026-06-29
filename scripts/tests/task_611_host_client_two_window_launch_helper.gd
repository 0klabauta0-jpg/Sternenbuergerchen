extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_611_host_client_two_window_launch_helper.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HTML_CONTRACT_PATH: String = "res://docs/dev/html_report_workbench_contract.md"
const TOOL_PATH: String = "res://scripts/tools/launch_host_client_two_window_review.ps1"
const PLAN_PATH: String = "res://tmp/host_client_two_window_launch_plan.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_611 Host Client Two Window Launch Helper ===")
	_test_docs_report_and_contract()
	_test_launch_helper_script()
	_test_launch_plan_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_611: FAILED")
		quit(1)
		return
	print("TASK_611: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var html_contract_text: String = _read_text(HTML_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_611 task file exists")
	_assert(task_text.contains("Host Client Two Window Launch Helper"), "TASK_611 task names launch helper")
	_assert(task_text.contains("tmp/host_client_two_window_launch_plan.json"), "TASK_611 task names launch plan")
	_assert(status_text.contains("TASK_611 - Host Client Two Window Launch Helper"), "Implementation status tracks TASK_611")
	_assert(status_text.contains("TASK_612 - Host Client Two Window Screenshot Review"), "Implementation status names TASK_612 follow-up")
	_assert(roadmap_text.contains("TASK_611 - Host Client Two Window Launch Helper (implementiert)"), "Roadmap marks TASK_611 implemented")
	_assert(roadmap_text.contains("TASK_612 - Host Client Two Window Screenshot Review"), "Roadmap names TASK_612 follow-up")
	_assert(contract_text.contains("Host-Client-Two-Window-Launch-Helper"), "Mission feedback contract documents TASK_611")
	_assert(html_contract_text.contains("JSON exportieren"), "HTML workbench contract still requires JSON export")
	_assert(report_text.contains("TASK_611 Host Client Two Window Launch Helper"), "Review workbench tracks TASK_611")
	_assert(report_text.contains("TASK_612 - Host Client Two Window Screenshot Review"), "Review workbench recommends TASK_612 next")
	_assert(report_text.contains("JSON exportieren"), "Review workbench still exposes JSON export")


func _test_launch_helper_script() -> void:
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_611 launch helper script exists")
	var tool_text: String = _read_text(TOOL_PATH)
	var required_terms: Array[String] = [
		"TASK_611",
		"host_client_two_window_launch_plan.json",
		"Launch",
		"Start-Process",
		"read_only",
		"ui_sets_gameplay_truth",
		"TASK_612 - Host Client Two Window Screenshot Review",
		"godot_bin_found",
		"--review-role=$Role",
		"--peer-id=$PeerId",
	]
	for term in required_terms:
		_assert(tool_text.contains(term), "Launch helper contains %s" % term)
	_assert(tool_text.contains("Dry run only"), "Launch helper defaults to dry-run messaging")


func _test_launch_plan_if_present() -> void:
	_assert(FileAccess.file_exists(PLAN_PATH), "TASK_611 dry-run launch plan exists")
	if not FileAccess.file_exists(PLAN_PATH):
		return
	var plan: Dictionary = _read_json(PLAN_PATH)
	_assert(String(plan.get("schema", "")) == "sternenbuergerchen.host_client_two_window_launch_helper.v1", "Launch plan schema is stable")
	_assert(String(plan.get("task_id", "")) == "TASK_611", "Launch plan records TASK_611")
	_assert(String(plan.get("launch_mode", "")) == "dry_run", "Launch plan defaults to dry-run")
	_assert(not bool(plan.get("launch_requested", true)), "Launch plan did not request window launch")
	_assert(bool(plan.get("read_only", false)), "Launch plan stays read-only")
	_assert(not bool(plan.get("ui_sets_gameplay_truth", true)), "Launch plan does not set gameplay truth")
	_assert(String(plan.get("scene", "")) == "res://scenes/tests/mission_reactivity_test.tscn", "Launch plan records default scene")
	_assert(String(plan.get("recommended_next_task", "")) == "TASK_612 - Host Client Two Window Screenshot Review", "Launch plan recommends TASK_612")
	_assert(plan.has("requested_window_layout"), "Launch plan records requested window layout")
	_assert(plan.has("window_layout_auto_fit"), "Launch plan records auto-fit metadata")
	var host: Dictionary = Dictionary(plan.get("host", {}))
	var client: Dictionary = Dictionary(plan.get("client", {}))
	_assert(String(host.get("role", "")) == "host", "Launch plan includes host role")
	_assert(int(host.get("peer_id", 0)) == 1, "Launch plan includes host peer id")
	_assert(String(client.get("role", "")) == "client", "Launch plan includes client role")
	_assert(int(client.get("peer_id", 0)) == 2, "Launch plan includes client peer id")
	_assert(Array(host.get("command_args", [])).has("--review-role=host"), "Launch plan includes host review arg")
	_assert(Array(client.get("command_args", [])).has("--review-role=client"), "Launch plan includes client review arg")
	var auto_fit: Dictionary = Dictionary(plan.get("window_layout_auto_fit", {}))
	var screen: Dictionary = Dictionary(auto_fit.get("screen", {}))
	if bool(screen.get("available", false)):
		var screen_width: int = int(screen.get("width", 0))
		var client_window: Dictionary = Dictionary(client.get("window", {}))
		_assert(int(client_window.get("x", 0)) + int(client_window.get("width", 0)) <= screen_width, "Launch plan keeps client window inside primary work area width")


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
