extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_649_current_state_handbook_report.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _failed: bool = false


func _init() -> void:
	print("=== TASK_649 Current State Handbook Report ===")
	_run()
	if _failed:
		print("TASK_649: FAILED")
		quit(1)
		return
	print("TASK_649: ALL PASSED")
	quit(0)


func _run() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_649 task file exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_649 current state handbook report exists")

	var task_text := _read(TASK_PATH)
	var report_text := _read(REPORT_PATH)
	var status_text := _read(STATUS_PATH)
	var roadmap_text := _read(ROADMAP_PATH)

	_assert(task_text.contains("Current State Handbook Report"), "Task names current-state handbook report")
	_assert(task_text.contains("JSON-Export"), "Task documents JSON export")
	_assert(report_text.contains("SternenBuergerchen Aktueller Stand + Handbuch"), "Report title is present")
	_assert(report_text.contains('data-report-schema="sternenbuergerchen.html_workbench.v1"'), "Report uses workbench schema")
	_assert(report_text.contains("JSON exportieren"), "Report exposes JSON export button")
	_assert(report_text.contains('data-tab-target="overview"'), "Report has overview tab")
	_assert(report_text.contains('data-tab-target="handbook"'), "Report has handbook tab")
	_assert(report_text.contains('data-tab-target="friction"'), "Report has friction tab")
	_assert(report_text.contains('data-tab-target="playtest"'), "Report has playtest tab")
	_assert(report_text.contains('data-tab-target="next"'), "Report has next-step tab")
	_assert(report_text.contains("latest_completed_task:"), "Report anchors latest completed task")
	_assert(report_text.contains("recommended_next_task:"), "Report recommends next gameplay slice")
	_assert(report_text.contains("SimulationRoot/Runtime/Contracts"), "Report keeps gameplay truth boundary visible")
	_assert(report_text.contains("report_is_gameplay_truth: false"), "Report export states it is not gameplay truth")
	_assert(report_text.contains('data-export-key="playtest.host_client_reject_clear"'), "Report exports host/client reject clarity check")
	_assert(report_text.contains('data-note-key="notes.worklog"'), "Report exports worklog note")
	_assert(status_text.contains("TASK_649 - Current State Handbook Report"), "Implementation status tracks TASK_649")
	_assert(roadmap_text.contains("TASK_649 - Current State Handbook Report (implementiert)"), "Roadmap marks TASK_649 implemented")


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		_assert(false, "Missing file: %s" % path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_assert(false, "Can open file: %s" % path)
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
