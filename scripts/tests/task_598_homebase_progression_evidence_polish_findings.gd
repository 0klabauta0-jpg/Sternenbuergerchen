extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_598_homebase_progression_evidence_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const TASK_597_TEST_PATH: String = "res://scripts/tests/task_597_homebase_progression_f6_evidence_capture.gd"
const OUTPUT_PNG_PATH: String = "res://tmp/homebase_progression_f6_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/homebase_progression_f6_evidence.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_598 Homebase Progression Evidence Polish Findings ===")
	_test_docs_report_and_wiring()
	_test_latest_manifest_and_png()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_598: FAILED")
		quit(1)
		return
	print("TASK_598: ALL PASSED")
	quit(0)


func _test_docs_report_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var task_597_text: String = _read_text(TASK_597_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_598 task file exists")
	_assert(task_text.contains("Homebase Progression Evidence Polish Findings"), "TASK_598 task names evidence polish")
	_assert(task_text.contains("region_legend_present"), "TASK_598 task defines legend manifest field")
	_assert(status_text.contains("TASK_598 - Homebase Progression Evidence Polish Findings"), "Implementation status tracks TASK_598")
	_assert(status_text.contains("TASK_599 - Integrated Core Loop Playtest Evidence Pass"), "Implementation status names TASK_599 follow-up")
	_assert(roadmap_text.contains("TASK_598 - Homebase Progression Evidence Polish Findings (implementiert)"), "Roadmap marks TASK_598 implemented")
	_assert(roadmap_text.contains("TASK_599 - Integrated Core Loop Playtest Evidence Pass"), "Roadmap names TASK_599 follow-up")
	_assert(report_text.contains("TASK_598 - Homebase Progression Evidence Polish Findings"), "Review workbench tracks TASK_598")
	_assert(report_text.contains("homebase_progression_evidence.region_legend_present"), "Review workbench exports legend presence")
	_assert(report_text.contains("homebase_progression_evidence.callout_label_count"), "Review workbench exports callout label count")
	_assert(report_text.contains("homebase_progression_evidence.evidence_board_readability_gate"), "Review workbench exports board readability gate")
	_assert(report_text.contains("TASK_599 - Integrated Core Loop Playtest Evidence Pass"), "Review workbench keeps TASK_599 evidence block")
	_assert(report_text.contains("TASK_600 - Integrated Core Loop Flow Polish Findings"), "Review workbench keeps TASK_600 flow findings")
	_assert(report_text.contains("TASK_601 - Core Loop Manual FullHD Playtest Capture"), "Review workbench keeps TASK_601 capture block")
	_assert(report_text.contains("TASK_602 - Core Loop Transition Pacing Polish"), "Review workbench keeps TASK_602 pacing block")
	_assert(report_text.contains("TASK_603 - Mission HUD Density Interaction Polish"), "Review workbench keeps TASK_603 HUD density block")
	_assert(report_text.contains("TASK_604 - Core Loop Host Client Feel Smoke"), "Review workbench keeps TASK_604 host/client feel block")
	_assert(report_text.contains("TASK_605 - Host Client F6 Visual Review Pass"), "Review workbench keeps TASK_605 visual review block")
	_assert(report_text.contains("TASK_606 - Host Client F6 Visual Polish Findings"), "Review workbench keeps TASK_606 polish block")
	_assert(report_text.contains("TASK_607 - Two Instance Host Client Runtime Smoke"), "Review workbench keeps TASK_607 runtime block")
	_assert(report_text.contains("TASK_608 - Host Client Runtime Visual Capture"), "Review workbench keeps TASK_608 runtime capture block")
	_assert(report_text.contains("TASK_609 - Host Client Runtime Visual Polish Findings"), "Review workbench recommends TASK_609 next")
	_assert(task_597_text.contains("_draw_pixel_text"), "TASK_597 evidence board draws pixel labels")
	_assert(task_597_text.contains("EVIDENCE_BOARD_CALLOUT_LABEL_COUNT"), "TASK_597 evidence board declares callout count")
	_assert(task_597_text.contains("evidence_polish_task_id"), "TASK_597 manifest carries TASK_598 polish id")


func _test_latest_manifest_and_png() -> void:
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Homebase progression evidence manifest exists")
	_assert(FileAccess.file_exists(OUTPUT_PNG_PATH), "Homebase progression evidence PNG exists")
	var manifest: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(manifest.get("evidence_polish_task_id", "")) == "TASK_598", "Manifest records TASK_598 polish id")
	_assert(bool(manifest.get("region_legend_present", false)), "Manifest reports region legend present")
	_assert(int(manifest.get("callout_label_count", 0)) >= 7, "Manifest reports enough callout labels")
	_assert(String(manifest.get("evidence_board_readability_gate", "")) == "pass", "Manifest reports evidence board readability gate")
	_assert(bool(manifest.get("read_only", false)), "Manifest stays read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	var image: Image = Image.load_from_file(OUTPUT_PNG_PATH)
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080, "Evidence PNG remains FullHD")
	if image == null:
		return
	_assert(_count_non_background_pixels(image, Rect2i(48, 24, 760, 88), Color(0.035, 0.047, 0.052, 1.0)) > 80, "Evidence PNG has visible header labels")
	_assert(_count_non_background_pixels(image, Rect2i(48, 300, 360, 150), Color(0.035, 0.047, 0.052, 1.0)) > 120, "Evidence PNG has visible legend labels")


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
