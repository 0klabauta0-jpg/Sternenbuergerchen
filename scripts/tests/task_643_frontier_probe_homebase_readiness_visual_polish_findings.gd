extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_643_frontier_probe_homebase_readiness_visual_polish_findings.md"
const TASK_642_PATH: String = "res://docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const NEW_HANDBOOK_PATH: String = "res://docs/reports/project_state_handbook_2026_06_30.html"
const TASK_642_TEST_PATH: String = "res://scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_homebase_visible_readiness_review.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_homebase_visible_readiness_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_643 Frontier Probe Homebase Readiness Visual Polish Findings ===")
	_test_docs_and_reports()
	await _test_task_642_evidence_board_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_643: FAILED")
		quit(1)
		return
	print("TASK_643: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_642_text: String = _read_text(TASK_642_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var new_handbook_text: String = _read_text(NEW_HANDBOOK_PATH)
	var task_642_test_text: String = _read_text(TASK_642_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_643 task file exists")
	_assert(task_text.contains("Frontier Probe Homebase Readiness Visual Polish Findings"), "TASK_643 task names visual polish findings")
	_assert(task_642_text.contains("TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"), "TASK_642 points to TASK_643 follow-up")
	_assert(status_text.contains("TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"), "Implementation status tracks TASK_643")
	_assert(roadmap_text.contains("TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings (implementiert)"), "Roadmap marks TASK_643 implemented")
	_assert(contract_text.contains("Frontier-Probe-Homebase-Readiness-Visual-Polish-Findings"), "Mission feedback contract documents TASK_643")
	_assert(task_642_test_text.contains("EVIDENCE_BOARD_CALLOUT_LABEL_COUNT"), "TASK_642 verifier tracks callout label count")
	_assert(task_642_test_text.contains("visual_polish_task_id"), "TASK_642 manifest exports visual polish task id")
	_assert(task_642_test_text.contains("_draw_pixel_text"), "TASK_642 evidence board draws text labels")
	_assert(report_text.contains("TASK_643 Frontier Probe Homebase Readiness Visual Polish Findings"), "Rolling report tracks TASK_643")
	_assert(report_text.contains('latest_completed_task: "TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"'), "Rolling report marks TASK_643 latest completed")
	_assert(handbook_text.contains("TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"), "Status handbook tracks TASK_643")
	_assert(handbook_text.contains('current_task: "TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"'), "Status handbook current task is TASK_643")
	_assert(FileAccess.file_exists(NEW_HANDBOOK_PATH), "New status handbook report exists")
	_assert(new_handbook_text.contains("SternenBuergerchen Ist-Stand Handbuch"), "New status handbook names current report")
	_assert(new_handbook_text.contains('data-report-id="project_state_handbook_2026_06_30"'), "New status handbook is an HTML workbench")
	_assert(new_handbook_text.contains("JSON exportieren"), "New status handbook can export JSON")
	_assert(new_handbook_text.contains("TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"), "New status handbook tracks TASK_643")
	for key in [
		"frontier_probe_homebase_readiness_visual_polish.task_id",
		"frontier_probe_homebase_readiness_visual_polish.callout_label_count",
		"frontier_probe_homebase_readiness_visual_polish.evidence_board_readability_gate",
		"frontier_probe_homebase_readiness_visual_polish.visual_polish_task_id",
		"frontier_probe_homebase_readiness_visual_polish.read_only",
		"frontier_probe_homebase_readiness_visual_polish.recommended_next_task",
		"frontier_probe_homebase_readiness_visual_polish.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_homebase_readiness_visual_polish"'), "Rolling report exports TASK_643 free note")
	_assert(handbook_text.contains('data-export-key="status.task_643_done"'), "Status handbook exports TASK_643 checkbox")


func _test_task_642_evidence_board_polish() -> void:
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_642 manifest exists for TASK_643 verification")
	var manifest: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_homebase_visible_readiness_review_manifest.v1", "TASK_642 manifest schema remains stable")
	_assert(String(manifest.get("gate", "")) == "pass", "TASK_642 gate still passes under TASK_643")
	_assert(String(manifest.get("visual_polish_task_id", "")) == "TASK_643", "Manifest records TASK_643 as visual polish task")
	_assert(String(manifest.get("evidence_board_readability_gate", "")) == "pass", "Evidence board readability gate passes")
	_assert(int(manifest.get("callout_label_count", 0)) >= 8, "Evidence board has enough callout labels")
	_assert(bool(manifest.get("generated_evidence_board", false)), "Headless run generated evidence board")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(not bool(manifest.get("creates_navigation", true)), "Manifest creates no navigation")
	_assert(not bool(manifest.get("creates_command", true)), "Manifest creates no command")
	_assert(FileAccess.file_exists(OUTPUT_PNG_PATH), "Polished TASK_642 PNG exists")
	var image := Image.load_from_file(OUTPUT_PNG_PATH)
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080, "Polished TASK_642 PNG is FullHD")
	if image != null:
		_assert(_count_bright_samples(image) > 20, "Polished TASK_642 PNG has bright callout/text samples")


func _count_bright_samples(image: Image) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 96)
	var step_y: int = maxi(1, image.get_height() / 54)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			var color: Color = image.get_pixel(x, y)
			if color.r + color.g + color.b > 2.0:
				count += 1
	return count


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
