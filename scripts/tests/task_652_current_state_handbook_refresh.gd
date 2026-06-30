extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_652_current_state_handbook_refresh.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _failed: bool = false


func _init() -> void:
	print("=== TASK_652 Current State Handbook Refresh ===")
	_run()
	if _failed:
		print("TASK_652: FAILED")
		quit(1)
		return
	print("TASK_652: ALL PASSED")
	quit(0)


func _run() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_652 task file exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "Current state handbook report exists")

	var task_text: String = _read(TASK_PATH)
	var report_text: String = _read(REPORT_PATH)
	var status_text: String = _read(STATUS_PATH)
	var roadmap_text: String = _read(ROADMAP_PATH)

	_assert(task_text.contains("Current State Handbook Refresh"), "Task names handbook refresh")
	_assert(task_text.contains("TASK_653 - Frontier Probe One-Screen Playability Pass"), "Task records next gameplay recommendation")
	_assert(status_text.contains("TASK_652 - Current State Handbook Refresh"), "Implementation status tracks TASK_652")
	_assert(roadmap_text.contains("TASK_652 - Current State Handbook Refresh (implementiert)"), "Roadmap marks TASK_652 implemented")
	_assert(report_text.contains('data-report-schema="sternenbuergerchen.html_workbench.v1"'), "Report keeps workbench schema")
	_assert(report_text.contains("JSON exportieren"), "Report keeps JSON export button")
	_assert(report_text.contains("Letzter Stand: TASK_651"), "Report header names TASK_651 as latest")
	_assert(report_text.contains("Naechster Kandidat: TASK_653"), "Report header recommends TASK_653")
	_assert(report_text.contains("TASK_651 - Host Client Click Followup Evidence"), "Report explains TASK_651 state")
	_assert(report_text.contains("TASK_653 - Frontier Probe One-Screen Playability Pass"), "Report explains TASK_653 next slice")
	_assert(report_text.contains('data-export-key="status.task_651_done"'), "Report exports TASK_651 done checkbox")
	_assert(report_text.contains('data-export-key="decision.next_path"'), "Report exports next path decision")
	_assert(report_text.contains('latest_completed_task: "TASK_651 - Host Client Click Followup Evidence"'), "Report export records latest task")
	_assert(report_text.contains('recommended_next_task: "TASK_653 - Frontier Probe One-Screen Playability Pass"'), "Report export records recommended next task")
	_assert(report_text.contains('updated_for_task: "TASK_652 - Current State Handbook Refresh"'), "Report export records TASK_652 update")
	_assert(report_text.contains("report_is_gameplay_truth: false"), "Report remains non-gameplay truth")


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
