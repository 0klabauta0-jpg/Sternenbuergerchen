extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_615_host_client_real_run_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const LAUNCH_TOOL_PATH: String = "res://scripts/tools/launch_host_client_two_window_review.ps1"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const LAUNCH_PLAN_PATH: String = "res://tmp/host_client_two_window_launch_plan.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_615 Host Client Real Run Findings ===")
	_test_docs_report_and_contract()
	_test_tooling_guards()
	_test_manifest_fields_if_present()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_615: FAILED")
		quit(1)
		return
	print("TASK_615: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_615 task file exists")
	_assert(task_text.contains("Host Client Real Run Findings"), "TASK_615 task file names the task")
	_assert(task_text.contains("godot_console.exe"), "TASK_615 documents the console-binary finding")
	_assert(task_text.contains("visible_godot_bin"), "TASK_615 documents visible binary manifest field")
	_assert(status_text.contains("TASK_615 - Host Client Real Run Findings"), "Implementation status tracks TASK_615")
	_assert(status_text.contains("TASK_616 - Host Client Visible UI Real Run Review"), "Implementation status names TASK_616 follow-up")
	_assert(roadmap_text.contains("TASK_615 - Host Client Real Run Findings (implementiert)"), "Roadmap marks TASK_615 implemented")
	_assert(roadmap_text.contains("TASK_616 - Host Client Visible UI Real Run Review"), "Roadmap names TASK_616 follow-up")
	_assert(contract_text.contains("Host-Client-Real-Run-Findings"), "Mission feedback contract documents TASK_615")
	_assert(report_text.contains("TASK_615 Host Client Real Run Findings"), "Review workbench tracks TASK_615")
	_assert(report_text.contains("TASK_616 - Host Client Visible UI Real Run Review"), "Review workbench recommends TASK_616 next")
	_test_report_export_fields(report_text)


func _test_report_export_fields(report_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_real_run_findings.finding_id",
		"host_client_real_run_findings.planned_godot_bin",
		"host_client_real_run_findings.visible_godot_bin",
		"host_client_real_run_findings.visible_godot_bin_source",
		"host_client_real_run_findings.console_binary_replaced",
		"host_client_real_run_findings.window_focus_attempted",
		"host_client_real_run_findings.window_position_attempted",
		"host_client_real_run_findings.recommended_next_task",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_real_run_findings"'), "Report exports free TASK_615 findings note")
	_assert(report_text.contains('"TASK_615 - Host Client Real Run Findings"'), "JSON payload keeps TASK_615 in completed tasks")
	_assert(report_text.contains('"TASK_616 - Host Client Visible UI Real Run Review"'), "JSON payload keeps TASK_616 in completed chain")
	_assert(report_text.contains('latest_completed_task: "TASK_617 - Host Client Standard Window Layout Hardening"'), "JSON payload advances latest completed task to TASK_617")


func _test_tooling_guards() -> void:
	_assert(FileAccess.file_exists(LAUNCH_TOOL_PATH), "TASK_611 launch helper exists")
	_assert(FileAccess.file_exists(CAPTURE_TOOL_PATH), "TASK_614 capture helper exists")
	var launch_text: String = _read_text(LAUNCH_TOOL_PATH)
	var capture_text: String = _read_text(CAPTURE_TOOL_PATH)
	_assert(launch_text.contains('foreach ($commandName in @("godot.exe", "godot_console.exe"))'), "Launch helper prefers GUI Godot before console")
	var required_capture_terms: Array[String] = [
		"Resolve-VisibleGodotBinary",
		"godot_console.exe",
		"sibling_gui_binary",
		"console_binary_replaced",
		"planned_godot_bin",
		"visible_godot_bin",
		"visible_godot_bin_source",
		"Focus-ReviewWindow",
		"SetForegroundWindow",
		"MoveWindow",
		"window_focus_attempted",
		"window_position_attempted",
		"recommended_next_visible_review_task",
	]
	for term in required_capture_terms:
		_assert(capture_text.contains(term), "Capture helper contains %s" % term)


func _test_manifest_fields_if_present() -> void:
	_assert(FileAccess.file_exists(LAUNCH_PLAN_PATH), "Launch plan exists for TASK_615 verification")
	_assert(FileAccess.file_exists(MANIFEST_PATH), "Real-run review manifest exists for TASK_615 verification")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(manifest.has("planned_godot_bin"), "Manifest records planned Godot binary")
	_assert(manifest.has("visible_godot_bin"), "Manifest records visible Godot binary")
	_assert(manifest.has("visible_godot_bin_source"), "Manifest records visible binary source")
	_assert(manifest.has("console_binary_replaced"), "Manifest records console replacement flag")
	_assert(manifest.has("window_focus_attempted"), "Manifest records window focus attempt")
	_assert(manifest.has("window_position_attempted"), "Manifest records window position attempt")
	_assert(manifest.has("host_window_status"), "Manifest records host window status")
	_assert(manifest.has("client_window_status"), "Manifest records client window status")
	_assert(String(manifest.get("recommended_next_visible_review_task", "")) == "TASK_616 - Host Client Visible UI Real Run Review", "Manifest recommends TASK_616 visible review")
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
