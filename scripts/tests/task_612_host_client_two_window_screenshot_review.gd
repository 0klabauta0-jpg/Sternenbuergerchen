extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_612_host_client_two_window_screenshot_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_611_PATH: String = "res://docs/tasks/TASK_611_host_client_two_window_launch_helper.md"
const TASK_611_TEST_PATH: String = "res://scripts/tests/task_611_host_client_two_window_launch_helper.gd"
const LAUNCH_PLAN_PATH: String = "res://tmp/host_client_two_window_launch_plan.json"
const OUTPUT_BOARD_PATH: String = "res://tmp/host_client_two_window_screenshot_review_board.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/host_client_two_window_screenshot_review.json"
const HOST_SCREENSHOT_PATH: String = "tmp/host_client_two_window_host_review.png"
const CLIENT_SCREENSHOT_PATH: String = "tmp/host_client_two_window_client_review.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_612 Host Client Two Window Screenshot Review ===")
	_test_docs_report_and_contract()
	_test_review_packet_from_launch_plan()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_612: FAILED")
		quit(1)
		return
	print("TASK_612: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_612 task file exists")
	_assert(task_text.contains("Host Client Two Window Screenshot Review"), "TASK_612 task file names the task")
	_assert(task_text.contains("host_client_two_window_screenshot_review.json"), "TASK_612 task names review manifest")
	_assert(FileAccess.file_exists(TASK_611_PATH), "TASK_611 task file remains available")
	_assert(FileAccess.file_exists(TASK_611_TEST_PATH), "TASK_611 verifier remains available")
	_assert(status_text.contains("TASK_612 - Host Client Two Window Screenshot Review"), "Implementation status tracks TASK_612")
	_assert(status_text.contains("TASK_613 - Host Client Two Window Visual Polish Findings"), "Implementation status names TASK_613 follow-up")
	_assert(roadmap_text.contains("TASK_612 - Host Client Two Window Screenshot Review (implementiert)"), "Roadmap marks TASK_612 implemented")
	_assert(roadmap_text.contains("TASK_613 - Host Client Two Window Visual Polish Findings"), "Roadmap names TASK_613 follow-up")
	_assert(contract_text.contains("Host-Client-Two-Window-Screenshot-Review"), "Mission feedback contract documents TASK_612")
	_assert(report_text.contains("TASK_612 Host Client Two Window Screenshot Review"), "Review workbench tracks TASK_612")
	_assert(report_text.contains("TASK_613 - Host Client Two Window Visual Polish Findings"), "Review workbench recommends TASK_613 next")
	_assert(report_text.contains("JSON exportieren"), "Review workbench still exposes JSON export")
	_test_report_export_fields(report_text)


func _test_report_export_fields(report_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_two_window_screenshot.host_screenshot_done",
		"host_client_two_window_screenshot.client_screenshot_done",
		"host_client_two_window_screenshot.both_windows_visible_checked",
		"host_client_two_window_screenshot.host_role_readable_checked",
		"host_client_two_window_screenshot.client_role_readable_checked",
		"host_client_two_window_screenshot.authority_feedback_checked",
		"host_client_two_window_screenshot.snapshot_sync_checked",
		"host_client_two_window_screenshot.f6_readability_checked",
		"host_client_two_window_screenshot.performance_checked",
		"host_client_two_window_screenshot.no_gameplay_truth_checked",
		"host_client_two_window_screenshot.host_screenshot_path",
		"host_client_two_window_screenshot.client_screenshot_path",
		"host_client_two_window_screenshot.review_board_path",
		"host_client_two_window_screenshot.review_manifest_path",
		"host_client_two_window_screenshot.launch_plan_path",
		"host_client_two_window_screenshot.recommended_next_task",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Report exports %s" % export_key)
	var required_choice_groups: Array[String] = [
		"host_client_two_window_screenshot.result",
		"host_client_two_window_screenshot.authority_rating",
		"host_client_two_window_screenshot.sync_rating",
		"host_client_two_window_screenshot.readability_rating",
		"host_client_two_window_screenshot.performance_rating",
		"host_client_two_window_screenshot.next_priority",
	]
	for choice_group in required_choice_groups:
		_assert(report_text.contains('data-choice-group="%s"' % choice_group), "Report exports choice group %s" % choice_group)
	_assert(report_text.contains('data-note-key="notes.host_client_two_window_screenshot_review"'), "Report exports free TASK_612 screenshot review note")
	_assert(report_text.contains('latest_completed_task: "TASK_612 - Host Client Two Window Screenshot Review"'), "JSON payload lists TASK_612 as latest completed task")
	_assert(report_text.contains('current_focus: "TASK_613 - Host Client Two Window Visual Polish Findings"'), "JSON payload sets current focus to TASK_613")
	_assert(not report_text.contains('data-export-key="host_client_two_window_screenshot.host_screenshot_done" checked'), "Host screenshot is not pre-marked done")
	_assert(not report_text.contains('data-export-key="host_client_two_window_screenshot.client_screenshot_done" checked'), "Client screenshot is not pre-marked done")


func _test_review_packet_from_launch_plan() -> void:
	_assert(FileAccess.file_exists(LAUNCH_PLAN_PATH), "TASK_611 launch plan exists for TASK_612 review packet")
	if not FileAccess.file_exists(LAUNCH_PLAN_PATH):
		return
	var launch_plan: Dictionary = _read_json(LAUNCH_PLAN_PATH)
	_assert(String(launch_plan.get("task_id", "")) == "TASK_611", "Review packet reads TASK_611 launch plan")
	_assert(bool(launch_plan.get("read_only", false)), "Launch plan is read-only")
	_assert(not bool(launch_plan.get("ui_sets_gameplay_truth", true)), "Launch plan does not set gameplay truth")
	var board: Image = _build_review_board(launch_plan)
	var board_error: Error = board.save_png(OUTPUT_BOARD_PATH)
	_assert(board_error == OK and FileAccess.file_exists(OUTPUT_BOARD_PATH), "TASK_612 review board PNG is written")
	var manifest: Dictionary = _build_manifest(launch_plan)
	_write_json(OUTPUT_MANIFEST_PATH, manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_612 review manifest is written")
	_assert(_read_text(OUTPUT_MANIFEST_PATH).contains("host_client_two_window_screenshot_review_board.png"), "Manifest names review board")
	_assert(String(manifest.get("task_id", "")) == "TASK_612", "Manifest records TASK_612")
	_assert(String(manifest.get("source_plan_task_id", "")) == "TASK_611", "Manifest records TASK_611 source plan")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)), "Manifest stays read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_613 - Host Client Two Window Visual Polish Findings", "Manifest recommends TASK_613")
	var image: Image = Image.load_from_file(OUTPUT_BOARD_PATH)
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080, "Review board remains FullHD")
	_assert(_count_non_background_pixels(image, Color(0.035, 0.047, 0.052, 1.0)) > 300, "Review board has visible non-background content")


func _build_manifest(launch_plan: Dictionary) -> Dictionary:
	var host: Dictionary = Dictionary(launch_plan.get("host", {}))
	var client: Dictionary = Dictionary(launch_plan.get("client", {}))
	return {
		"schema": "sternenbuergerchen.host_client_two_window_screenshot_review.v1",
		"task_id": "TASK_612",
		"source_plan_task_id": String(launch_plan.get("task_id", "")),
		"source_plan_path": "tmp/host_client_two_window_launch_plan.json",
		"review_board_path": "tmp/host_client_two_window_screenshot_review_board.png",
		"review_manifest_path": "tmp/host_client_two_window_screenshot_review.json",
		"host_screenshot_path": HOST_SCREENSHOT_PATH,
		"client_screenshot_path": CLIENT_SCREENSHOT_PATH,
		"host_role": String(host.get("role", "host")),
		"client_role": String(client.get("role", "client")),
		"host_peer_id": int(host.get("peer_id", 1)),
		"client_peer_id": int(client.get("peer_id", 2)),
		"manual_review_required": true,
		"manual_review_done": false,
		"host_screenshot_present": FileAccess.file_exists("res://" + HOST_SCREENSHOT_PATH),
		"client_screenshot_present": FileAccess.file_exists("res://" + CLIENT_SCREENSHOT_PATH),
		"generated_review_board": true,
		"real_window_screenshots_required": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"review_checks": [
			"both_windows_visible",
			"host_role_readable",
			"client_role_readable",
			"authority_feedback_readable",
			"snapshot_sync_readable",
			"f6_readability",
			"performance_feel",
			"no_gameplay_truth_in_report",
		],
		"recommended_next_task": "TASK_613 - Host Client Two Window Visual Polish Findings",
	}


func _build_review_board(launch_plan: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	var background := Color(0.035, 0.047, 0.052, 1.0)
	image.fill(background)
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(60, 132, 820, 560), Color(0.11, 0.15, 0.18, 1.0))
	_fill_rect(image, Rect2i(1040, 132, 820, 560), Color(0.11, 0.15, 0.18, 1.0))
	_draw_rect_outline(image, Rect2i(60, 132, 820, 560), Color(0.36, 0.64, 0.94, 1.0), 6)
	_draw_rect_outline(image, Rect2i(1040, 132, 820, 560), Color(0.96, 0.66, 0.36, 1.0), 6)
	_fill_rect(image, Rect2i(96, 176, 250, 32), Color(0.36, 0.64, 0.94, 1.0))
	_fill_rect(image, Rect2i(1076, 176, 260, 32), Color(0.96, 0.66, 0.36, 1.0))
	_fill_rect(image, Rect2i(96, 744, 1728, 54), Color(0.18, 0.24, 0.28, 1.0))
	_fill_rect(image, Rect2i(96, 826, 560, 36), Color(0.24, 0.74, 0.46, 1.0))
	_fill_rect(image, Rect2i(704, 826, 560, 36), Color(0.98, 0.80, 0.20, 1.0))
	_fill_rect(image, Rect2i(1312, 826, 512, 36), Color(0.86, 0.24, 0.24, 1.0))
	var host_window: Dictionary = Dictionary(Dictionary(launch_plan.get("host", {})).get("window", {}))
	var client_window: Dictionary = Dictionary(Dictionary(launch_plan.get("client", {})).get("window", {}))
	if int(host_window.get("width", 0)) > 0:
		_fill_rect(image, Rect2i(390, 176, 84, 32), Color(0.36, 0.64, 0.94, 1.0))
	if int(client_window.get("width", 0)) > 0:
		_fill_rect(image, Rect2i(1370, 176, 84, 32), Color(0.96, 0.66, 0.36, 1.0))
	return image


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, thickness: int = 2) -> void:
	var safe_thickness: int = maxi(1, thickness)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, rect.size.x, safe_thickness), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y + rect.size.y - safe_thickness, rect.size.x, safe_thickness), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, safe_thickness, rect.size.y), color)
	_fill_rect(image, Rect2i(rect.position.x + rect.size.x - safe_thickness, rect.position.y, safe_thickness, rect.size.y), color)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x0: int = clampi(rect.position.x, 0, image.get_width())
	var y0: int = clampi(rect.position.y, 0, image.get_height())
	var x1: int = clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var y1: int = clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)


func _count_non_background_pixels(image: Image, background: Color) -> int:
	if image == null:
		return 0
	var count: int = 0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var pixel: Color = image.get_pixel(x, y)
			if absf(pixel.r - background.r) > 0.03 or absf(pixel.g - background.g) > 0.03 or absf(pixel.b - background.b) > 0.03:
				count += 1
	return count


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


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
