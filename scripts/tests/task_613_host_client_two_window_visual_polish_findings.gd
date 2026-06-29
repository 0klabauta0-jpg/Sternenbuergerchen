extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_613_host_client_two_window_visual_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_612_TEST_PATH: String = "res://scripts/tests/task_612_host_client_two_window_screenshot_review.gd"
const OUTPUT_BOARD_PATH: String = "res://tmp/host_client_two_window_screenshot_review_board.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/host_client_two_window_screenshot_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_613 Host Client Two Window Visual Polish Findings ===")
	_test_docs_report_and_wiring()
	_test_manifest_and_board_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_613: FAILED")
		quit(1)
		return
	print("TASK_613: ALL PASSED")
	quit(0)


func _test_docs_report_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var task_612_text: String = _read_text(TASK_612_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_613 task file exists")
	_assert(task_text.contains("Host Client Two Window Visual Polish Findings"), "TASK_613 task file names the task")
	_assert(task_text.contains("evidence_board_readability_gate"), "TASK_613 task defines readability manifest field")
	_assert(status_text.contains("TASK_613 - Host Client Two Window Visual Polish Findings"), "Implementation status tracks TASK_613")
	_assert(status_text.contains("TASK_614 - Host Client Two Window Real Run Review"), "Implementation status names TASK_614 follow-up")
	_assert(roadmap_text.contains("TASK_613 - Host Client Two Window Visual Polish Findings (implementiert)"), "Roadmap marks TASK_613 implemented")
	_assert(roadmap_text.contains("TASK_614 - Host Client Two Window Real Run Review"), "Roadmap names TASK_614 follow-up")
	_assert(contract_text.contains("Host-Client-Two-Window-Visual-Polish-Findings"), "Mission feedback contract documents TASK_613")
	_assert(report_text.contains("TASK_613 Host Client Two Window Visual Polish Findings"), "Review workbench tracks TASK_613")
	_assert(report_text.contains("TASK_614 - Host Client Two Window Real Run Review"), "Review workbench recommends TASK_614 next")
	_assert(report_text.contains("host_client_two_window_screenshot.visual_polish_task_id"), "Report exports TASK_613 visual polish id")
	_assert(report_text.contains("host_client_two_window_screenshot.region_legend_present"), "Report exports legend presence")
	_assert(report_text.contains("host_client_two_window_screenshot.callout_label_count"), "Report exports callout count")
	_assert(report_text.contains("host_client_two_window_screenshot.evidence_board_readability_gate"), "Report exports board readability gate")
	_assert(task_612_text.contains("_draw_pixel_text"), "TASK_612 board draws pixel text")
	_assert(task_612_text.contains("BOARD_CALLOUT_LABEL_COUNT"), "TASK_612 board declares callout count")
	_assert(task_612_text.contains("visual_polish_task_id"), "TASK_612 manifest carries visual polish id")


func _test_manifest_and_board_polish() -> void:
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_612/613 review manifest exists")
	_assert(FileAccess.file_exists(OUTPUT_BOARD_PATH), "TASK_612/613 review board exists")
	var manifest: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(manifest.get("task_id", "")) == "TASK_612", "Manifest keeps TASK_612 source task")
	_assert(String(manifest.get("visual_polish_task_id", "")) == "TASK_613", "Manifest records TASK_613 visual polish id")
	_assert(bool(manifest.get("region_legend_present", false)), "Manifest reports region legend present")
	_assert(int(manifest.get("callout_label_count", 0)) >= 10, "Manifest reports enough callout labels")
	_assert(String(manifest.get("evidence_board_readability_gate", "")) == "pass", "Manifest reports board readability gate")
	_assert(String(manifest.get("visible_followup_candidate", "")) == "host_client_two_window_window_run_review", "Manifest reports visible follow-up candidate")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_614 - Host Client Two Window Real Run Review", "Manifest recommends TASK_614")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	var image: Image = Image.load_from_file(OUTPUT_BOARD_PATH)
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080, "Review board remains FullHD")
	if image == null:
		return
	var background := Color(0.035, 0.047, 0.052, 1.0)
	_assert(_count_non_background_pixels(image, Rect2i(48, 24, 920, 80), background) > 120, "Review board has visible title labels")
	_assert(_count_non_background_pixels(image, Rect2i(80, 170, 760, 120), background) > 160, "Review board has visible host labels")
	_assert(_count_non_background_pixels(image, Rect2i(1060, 170, 760, 120), background) > 160, "Review board has visible client labels")
	_assert(_count_non_background_pixels(image, Rect2i(90, 820, 1740, 64), background) > 220, "Review board has visible status legend")
	_assert(_count_non_background_pixels(image, Rect2i(56, 1000, 1300, 60), background) > 100, "Review board has visible footer follow-up label")


func _count_non_background_pixels(image: Image, rect: Rect2i, background: Color) -> int:
	var count: int = 0
	var x0: int = clampi(rect.position.x, 0, image.get_width())
	var y0: int = clampi(rect.position.y, 0, image.get_height())
	var x1: int = clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var y1: int = clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y0, y1, 3):
		for x in range(x0, x1, 3):
			var pixel: Color = image.get_pixel(x, y)
			if absf(pixel.r - background.r) > 0.03 or absf(pixel.g - background.g) > 0.03 or absf(pixel.b - background.b) > 0.03:
				count += 1
	return count


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
