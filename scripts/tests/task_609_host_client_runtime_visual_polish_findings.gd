extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_609_host_client_runtime_visual_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_608_TEST_PATH: String = "res://scripts/tests/task_608_host_client_runtime_visual_capture.gd"
const OUTPUT_PNG_PATH: String = "res://tmp/host_client_runtime_visual_capture.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/host_client_runtime_visual_capture.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_609 Host Client Runtime Visual Polish Findings ===")
	_test_docs_report_and_wiring()
	_test_latest_manifest_and_png()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_609: FAILED")
		quit(1)
		return
	print("TASK_609: ALL PASSED")
	quit(0)


func _test_docs_report_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var task_608_text: String = _read_text(TASK_608_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_609 task file exists")
	_assert(task_text.contains("Host Client Runtime Visual Polish Findings"), "TASK_609 task names visual polish")
	_assert(task_text.contains("callout_label_count"), "TASK_609 task defines label manifest field")
	_assert(status_text.contains("TASK_609 - Host Client Runtime Visual Polish Findings"), "Implementation status tracks TASK_609")
	_assert(status_text.contains("TASK_610 - Host Client Two Window Playtest Notes"), "Implementation status names TASK_610 follow-up")
	_assert(roadmap_text.contains("TASK_609 - Host Client Runtime Visual Polish Findings (implementiert)"), "Roadmap marks TASK_609 implemented")
	_assert(roadmap_text.contains("TASK_610 - Host Client Two Window Playtest Notes"), "Roadmap names TASK_610 follow-up")
	_assert(contract_text.contains("Host-Client-Runtime-Visual-Polish-Findings"), "Mission feedback contract documents TASK_609")
	_assert(report_text.contains("TASK_609 Host Client Runtime Visual Polish Findings"), "Review workbench tracks TASK_609")
	_assert(report_text.contains("host_client_runtime_capture.evidence_polish_task_id"), "Review workbench exports evidence polish task id")
	_assert(report_text.contains("host_client_runtime_capture.region_legend_present"), "Review workbench exports legend presence")
	_assert(report_text.contains("host_client_runtime_capture.callout_label_count"), "Review workbench exports callout label count")
	_assert(report_text.contains("host_client_runtime_capture.evidence_board_readability_gate"), "Review workbench exports evidence readability gate")
	_assert(report_text.contains("TASK_610 - Host Client Two Window Playtest Notes"), "Review workbench recommends TASK_610 next")
	_assert(task_608_text.contains("_draw_pixel_text"), "TASK_608 capture draws pixel labels")
	_assert(task_608_text.contains("HOST CLIENT RUNTIME CAPTURE"), "TASK_608 capture labels the board title")
	_assert(task_608_text.contains("RUNTIME_CAPTURE_CALLOUT_LABEL_COUNT"), "TASK_608 capture declares label count")


func _test_latest_manifest_and_png() -> void:
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Host/client runtime capture manifest exists")
	_assert(FileAccess.file_exists(OUTPUT_PNG_PATH), "Host/client runtime capture PNG exists")
	var manifest: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(manifest.get("task_id", "")) == "TASK_608", "Manifest still records TASK_608 capture origin")
	_assert(String(manifest.get("evidence_polish_task_id", "")) == "TASK_609", "Manifest records TASK_609 polish id")
	_assert(bool(manifest.get("region_legend_present", false)), "Manifest reports region legend present")
	_assert(int(manifest.get("callout_label_count", 0)) >= 16, "Manifest reports enough callout labels")
	_assert(String(manifest.get("evidence_board_readability_gate", "")) == "pass", "Manifest reports evidence board readability gate")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_610 - Host Client Two Window Playtest Notes", "Manifest recommends TASK_610")
	_assert(bool(manifest.get("read_only", false)), "Manifest stays read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	var image: Image = Image.load_from_file(OUTPUT_PNG_PATH)
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080, "Runtime capture PNG remains FullHD")
	if image == null:
		return
	var background := Color(0.032, 0.043, 0.048, 1.0)
	_assert(_count_non_background_pixels(image, Rect2i(48, 24, 920, 90), background) > 180, "Runtime capture PNG has visible header labels")
	_assert(_count_non_background_pixels(image, Rect2i(80, 170, 400, 650), background) > 300, "Runtime capture PNG has visible left gate labels")
	_assert(_count_non_background_pixels(image, Rect2i(700, 288, 500, 320), background) > 160, "Runtime capture PNG has visible center labels")
	_assert(_count_non_background_pixels(image, Rect2i(1428, 178, 410, 500), background) > 240, "Runtime capture PNG has visible right gate labels")
	_assert(_count_non_background_pixels(image, Rect2i(48, 988, 1100, 58), background) > 160, "Runtime capture PNG has visible footer labels")


func _count_non_background_pixels(image: Image, rect: Rect2i, background: Color) -> int:
	var count: int = 0
	var x0: int = clampi(rect.position.x, 0, image.get_width())
	var y0: int = clampi(rect.position.y, 0, image.get_height())
	var x1: int = clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var y1: int = clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y0, y1, 2):
		for x in range(x0, x1, 2):
			var pixel: Color = image.get_pixel(x, y)
			if absf(pixel.r - background.r) > 0.03 or absf(pixel.g - background.g) > 0.03 or absf(pixel.b - background.b) > 0.03:
				count += 1
	return count


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
