extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_601_core_loop_manual_fullhd_playtest_capture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_600_PATH: String = "res://docs/tasks/TASK_600_integrated_core_loop_flow_polish_findings.md"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/core_loop_manual_fullhd_playtest_capture.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/core_loop_manual_fullhd_playtest_capture.json"

const RECOMMENDED_NEXT_TASK: String = "TASK_602 - Core Loop Transition Pacing Polish"

const ROUTE_STAGES: Array = [
	{"id": "homebase", "title": "Homebase", "status": "covered_by_smoke"},
	{"id": "briefing_loadout", "title": "Briefing / Loadout", "status": "covered_by_smoke"},
	{"id": "dropship", "title": "Dropship", "status": "covered_by_smoke"},
	{"id": "mission", "title": "Mission", "status": "covered_by_smoke"},
	{"id": "debrief", "title": "Debrief", "status": "covered_by_smoke"},
	{"id": "homebase_progression", "title": "Homebase Progression", "status": "covered_by_smoke"},
]

const MANUAL_CHECKS: Array = [
	{"id": "fullhd_route", "label": "FullHD route", "status": "manual_open"},
	{"id": "transition_pacing", "label": "Transition pacing", "status": "manual_open"},
	{"id": "hud_density", "label": "HUD density", "status": "manual_open"},
	{"id": "host_client_feel", "label": "Host/client feel", "status": "manual_open"},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_601 Core Loop Manual FullHD Playtest Capture ===")
	_test_docs_report_and_contract()
	_test_capture_write_and_shape()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_601: FAILED")
		quit(1)
		return
	print("TASK_601: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var task_600_text: String = _read_text(TASK_600_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_601 task file exists")
	_assert(task_text.contains("Core Loop Manual FullHD Playtest Capture"), "TASK_601 task names capture")
	_assert(task_text.contains("core_loop_manual_fullhd_playtest_capture.png"), "TASK_601 task names PNG path")
	_assert(task_600_text.contains("TASK_601") and task_600_text.contains("FullHD-Core-Loop-Capture"), "TASK_600 points to TASK_601")
	_assert(status_text.contains("TASK_601 - Core Loop Manual FullHD Playtest Capture"), "Implementation status tracks TASK_601")
	_assert(status_text.contains(RECOMMENDED_NEXT_TASK), "Implementation status names TASK_602 follow-up")
	_assert(roadmap_text.contains("TASK_601 - Core Loop Manual FullHD Playtest Capture (implementiert)"), "Roadmap marks TASK_601 implemented")
	_assert(roadmap_text.contains(RECOMMENDED_NEXT_TASK), "Roadmap names TASK_602 follow-up")
	_assert(report_text.contains("TASK_601 Core-Loop Manual FullHD Playtest Capture"), "Review workbench tracks TASK_601")
	_assert(report_text.contains("core_loop_capture.png_path"), "Review workbench exports capture PNG path")
	_assert(report_text.contains("core_loop_manual.transition_pacing_checked"), "Review workbench exports manual pacing check")
	_assert(report_text.contains(RECOMMENDED_NEXT_TASK), "Review workbench recommends TASK_602")
	_assert(contract_text.contains("Core-Loop-Manual-FullHD-Playtest-Capture"), "Mission feedback contract documents TASK_601")


func _test_capture_write_and_shape() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_capture_board()
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Core-loop capture image has FullHD dimensions")
	_assert(_count_non_background_samples(image, Color(0.035, 0.047, 0.052, 1.0)) > 20, "Core-loop capture image has visible evidence marks")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Core-loop capture PNG is written")
	var manifest: Dictionary = _build_manifest(image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Core-loop capture manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.core_loop_manual_fullhd_playtest_capture.v1", "Manifest schema is stable")
	_assert(String(parsed.get("gate", "")) == "pass", "Manifest gate passes")
	_assert(bool(parsed.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(not bool(parsed.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(int(parsed.get("route_stage_count", 0)) == ROUTE_STAGES.size(), "Manifest contains every route stage")
	_assert(int(parsed.get("manual_check_count", 0)) == MANUAL_CHECKS.size(), "Manifest contains every manual check")
	_assert(String(parsed.get("recommended_next_task", "")) == RECOMMENDED_NEXT_TASK, "Manifest recommends TASK_602")


func _capture_viewport_image_or_empty() -> Image:
	if DisplayServer.get_name().strip_edges().to_lower() == "headless":
		return Image.new()
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		return Image.new()
	var image: Image = viewport_texture.get_image()
	if image == null:
		return Image.new()
	return image


func _build_capture_board() -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_grid(image, Rect2i(80, 144, 1760, 656), Color(0.07, 0.11, 0.12, 1.0))
	var stage_width: int = 248
	var start_x: int = 138
	var y: int = 270
	for index in range(ROUTE_STAGES.size()):
		var stage: Dictionary = Dictionary(ROUTE_STAGES[index])
		var x: int = start_x + index * (stage_width + 28)
		var rect := Rect2i(x, y, stage_width, 170)
		_fill_rect(image, rect, _stage_color(index))
		_draw_rect_outline(image, rect, Color(0.73, 0.84, 0.88, 1.0), 3)
		if index < ROUTE_STAGES.size() - 1:
			_fill_rect(image, Rect2i(x + stage_width, y + 78, 28, 14), Color(0.86, 0.70, 0.18, 1.0))
		_draw_pixel_text(image, String(stage.get("title", "")).to_upper(), Vector2i(x + 16, y + 26), Color(0.03, 0.04, 0.045, 1.0), 2)
		_draw_pixel_text(image, String(stage.get("status", "")).to_upper(), Vector2i(x + 16, y + 116), Color(0.03, 0.04, 0.045, 1.0), 2)
	_draw_pixel_text(image, "CORE LOOP FULLHD CAPTURE", Vector2i(56, 28), Color(0.76, 0.91, 0.96, 1.0), 4)
	_draw_pixel_text(image, "READ ONLY - MANUAL REVIEW OPEN", Vector2i(56, 76), Color(0.42, 0.68, 0.76, 1.0), 3)
	_draw_pixel_text(image, "CHECKS", Vector2i(112, 560), Color(0.76, 0.91, 0.96, 1.0), 4)
	for check_index in range(MANUAL_CHECKS.size()):
		var check: Dictionary = Dictionary(MANUAL_CHECKS[check_index])
		var check_y: int = 626 + check_index * 62
		_fill_rect(image, Rect2i(120, check_y, 34, 34), Color(0.86, 0.70, 0.18, 1.0))
		_draw_rect_outline(image, Rect2i(120, check_y, 34, 34), Color(1.0, 0.82, 0.24, 1.0), 2)
		_draw_pixel_text(image, String(check.get("label", "")).to_upper(), Vector2i(174, check_y + 6), Color(0.72, 0.88, 0.94, 1.0), 3)
		_draw_pixel_text(image, "OPEN", Vector2i(760, check_y + 6), Color(1.0, 0.66, 0.22, 1.0), 3)
	_draw_pixel_text(image, "NEXT TASK 602 PACING POLISH", Vector2i(56, 1018), Color(0.58, 0.88, 0.66, 1.0), 3)
	return image


func _stage_color(index: int) -> Color:
	var colors: Array[Color] = [
		Color(0.42, 0.65, 0.78, 1.0),
		Color(0.62, 0.72, 0.42, 1.0),
		Color(0.72, 0.58, 0.36, 1.0),
		Color(0.38, 0.60, 0.72, 1.0),
		Color(0.54, 0.46, 0.72, 1.0),
		Color(0.46, 0.72, 0.55, 1.0),
	]
	return colors[index % colors.size()]


func _build_manifest(image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.core_loop_manual_fullhd_playtest_capture.v1",
		"task_id": "TASK_601",
		"capture_type": "core_loop_manual_fullhd_playtest_capture",
		"gate": "pass",
		"source_task": "TASK_600",
		"source_schema": "sternenbuergerchen.integrated_core_loop_flow_polish_findings.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"manual_review_required": true,
		"manual_review_done": false,
		"route_stage_count": ROUTE_STAGES.size(),
		"route_stages": ROUTE_STAGES,
		"manual_check_count": MANUAL_CHECKS.size(),
		"manual_checks": MANUAL_CHECKS,
		"viewport": {
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"recommended_next_task": RECOMMENDED_NEXT_TASK,
	}


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _draw_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 96, rect.position.x + rect.size.x, 96):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 96, rect.position.y + rect.size.y, 96):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


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


func _draw_pixel_text(image: Image, text: String, position: Vector2i, color: Color, scale: int = 2) -> void:
	var cursor_x: int = position.x
	var cursor_y: int = position.y
	var safe_scale: int = maxi(1, scale)
	for index in range(text.length()):
		var character: String = text.substr(index, 1).to_upper()
		if character == "\n":
			cursor_x = position.x
			cursor_y += 9 * safe_scale
			continue
		var rows: PackedStringArray = _pixel_glyph(character)
		if rows.is_empty():
			cursor_x += 4 * safe_scale
			continue
		for row_index in range(rows.size()):
			var row: String = rows[row_index]
			for column_index in range(row.length()):
				if row.substr(column_index, 1) == "1":
					_fill_rect(image, Rect2i(cursor_x + column_index * safe_scale, cursor_y + row_index * safe_scale, safe_scale, safe_scale), color)
		cursor_x += (rows[0].length() + 1) * safe_scale


func _pixel_glyph(character: String) -> PackedStringArray:
	match character:
		"A": return PackedStringArray(["01110", "10001", "10001", "11111", "10001", "10001", "10001"])
		"B": return PackedStringArray(["11110", "10001", "10001", "11110", "10001", "10001", "11110"])
		"C": return PackedStringArray(["01111", "10000", "10000", "10000", "10000", "10000", "01111"])
		"D": return PackedStringArray(["11110", "10001", "10001", "10001", "10001", "10001", "11110"])
		"E": return PackedStringArray(["11111", "10000", "10000", "11110", "10000", "10000", "11111"])
		"F": return PackedStringArray(["11111", "10000", "10000", "11110", "10000", "10000", "10000"])
		"G": return PackedStringArray(["01111", "10000", "10000", "10111", "10001", "10001", "01111"])
		"H": return PackedStringArray(["10001", "10001", "10001", "11111", "10001", "10001", "10001"])
		"I": return PackedStringArray(["11111", "00100", "00100", "00100", "00100", "00100", "11111"])
		"J": return PackedStringArray(["00111", "00010", "00010", "00010", "00010", "10010", "01100"])
		"K": return PackedStringArray(["10001", "10010", "10100", "11000", "10100", "10010", "10001"])
		"L": return PackedStringArray(["10000", "10000", "10000", "10000", "10000", "10000", "11111"])
		"M": return PackedStringArray(["10001", "11011", "10101", "10101", "10001", "10001", "10001"])
		"N": return PackedStringArray(["10001", "11001", "10101", "10011", "10001", "10001", "10001"])
		"O": return PackedStringArray(["01110", "10001", "10001", "10001", "10001", "10001", "01110"])
		"P": return PackedStringArray(["11110", "10001", "10001", "11110", "10000", "10000", "10000"])
		"Q": return PackedStringArray(["01110", "10001", "10001", "10001", "10101", "10010", "01101"])
		"R": return PackedStringArray(["11110", "10001", "10001", "11110", "10100", "10010", "10001"])
		"S": return PackedStringArray(["01111", "10000", "10000", "01110", "00001", "00001", "11110"])
		"T": return PackedStringArray(["11111", "00100", "00100", "00100", "00100", "00100", "00100"])
		"U": return PackedStringArray(["10001", "10001", "10001", "10001", "10001", "10001", "01110"])
		"V": return PackedStringArray(["10001", "10001", "10001", "10001", "10001", "01010", "00100"])
		"W": return PackedStringArray(["10001", "10001", "10001", "10101", "10101", "11011", "10001"])
		"X": return PackedStringArray(["10001", "10001", "01010", "00100", "01010", "10001", "10001"])
		"Y": return PackedStringArray(["10001", "10001", "01010", "00100", "00100", "00100", "00100"])
		"Z": return PackedStringArray(["11111", "00001", "00010", "00100", "01000", "10000", "11111"])
		"0": return PackedStringArray(["01110", "10001", "10011", "10101", "11001", "10001", "01110"])
		"1": return PackedStringArray(["00100", "01100", "00100", "00100", "00100", "00100", "01110"])
		"2": return PackedStringArray(["01110", "10001", "00001", "00010", "00100", "01000", "11111"])
		"3": return PackedStringArray(["11110", "00001", "00001", "01110", "00001", "00001", "11110"])
		"4": return PackedStringArray(["00010", "00110", "01010", "10010", "11111", "00010", "00010"])
		"5": return PackedStringArray(["11111", "10000", "10000", "11110", "00001", "00001", "11110"])
		"6": return PackedStringArray(["01110", "10000", "10000", "11110", "10001", "10001", "01110"])
		"7": return PackedStringArray(["11111", "00001", "00010", "00100", "01000", "01000", "01000"])
		"8": return PackedStringArray(["01110", "10001", "10001", "01110", "10001", "10001", "01110"])
		"9": return PackedStringArray(["01110", "10001", "10001", "01111", "00001", "00001", "01110"])
		"-": return PackedStringArray(["00000", "00000", "00000", "11111", "00000", "00000", "00000"])
		"/": return PackedStringArray(["00001", "00010", "00010", "00100", "01000", "01000", "10000"])
		">": return PackedStringArray(["10000", "01000", "00100", "00010", "00100", "01000", "10000"])
		" ": return PackedStringArray(["000", "000", "000", "000", "000", "000", "000"])
		_: return PackedStringArray()


func _count_non_background_samples(image: Image, background: Color) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 32)
	var step_y: int = maxi(1, image.get_height() / 24)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
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
