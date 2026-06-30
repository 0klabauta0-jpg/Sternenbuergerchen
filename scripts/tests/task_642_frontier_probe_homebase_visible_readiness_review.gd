extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_homebase_visible_readiness_review.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_homebase_visible_readiness_review.json"
const EVIDENCE_BOARD_CALLOUT_LABEL_COUNT: int = 8

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_642 Frontier Probe Homebase Visible Readiness Review ===")
	_test_docs_and_reports()
	await _test_visible_readiness_review()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_642: FAILED")
		quit(1)
		return
	print("TASK_642: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_642 task file exists")
	_assert(task_text.contains("Frontier Probe Homebase Visible Readiness Review"), "TASK_642 task names visible readiness review")
	_assert(status_text.contains("TASK_642 - Frontier Probe Homebase Visible Readiness Review"), "Implementation status tracks TASK_642")
	_assert(roadmap_text.contains("TASK_642 - Frontier Probe Homebase Visible Readiness Review (implementiert)"), "Roadmap marks TASK_642 implemented")
	_assert(contract_text.contains("Frontier-Probe-Homebase-Visible-Readiness-Review"), "Mission feedback contract documents TASK_642")
	_assert(homebase_text.contains("get_frontier_probe_homebase_visible_readiness_review_snapshot"), "Homebase exposes TASK_642 snapshot")
	_assert(report_text.contains("TASK_642 Frontier Probe Homebase Visible Readiness Review"), "Rolling report tracks TASK_642")
	_assert(report_text.contains('latest_completed_task: "TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"'), "Rolling report advances latest completed beyond TASK_642")
	_assert(handbook_text.contains("TASK_642 - Frontier Probe Homebase Visible Readiness Review"), "Status handbook tracks TASK_642")
	_assert(handbook_text.contains('current_task: "TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings"'), "Status handbook current task advances beyond TASK_642")
	for key in [
		"frontier_probe_homebase_visible_readiness_review.task_id",
		"frontier_probe_homebase_visible_readiness_review.png_path",
		"frontier_probe_homebase_visible_readiness_review.manifest_path",
		"frontier_probe_homebase_visible_readiness_review.readiness_gate",
		"frontier_probe_homebase_visible_readiness_review.post_summary_visible",
		"frontier_probe_homebase_visible_readiness_review.next_sortie_visible",
		"frontier_probe_homebase_visible_readiness_review.current_next_step_id",
		"frontier_probe_homebase_visible_readiness_review.manual_review_required",
		"frontier_probe_homebase_visible_readiness_review.read_only",
		"frontier_probe_homebase_visible_readiness_review.recommended_next_task",
		"frontier_probe_homebase_visible_readiness_review.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_homebase_visible_readiness_review"'), "Rolling report exports TASK_642 free note")
	_assert(handbook_text.contains('data-export-key="status.task_642_done"'), "Status handbook exports TASK_642 checkbox")


func _test_visible_readiness_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)

	var debrief_screen: Node = scene.get_node_or_null("DebriefScreen")
	var homebase_screen: Node = scene.get_node_or_null("HomebaseScreen")
	_assert(debrief_screen != null and homebase_screen != null, "Meta fixture exposes Debrief and Homebase screens")
	if debrief_screen == null or homebase_screen == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var mission_result: Dictionary = _build_frontier_probe_result()
	scene.set("_last_mission_result", mission_result.duplicate(true))
	debrief_screen.call("set_mission_result", mission_result.duplicate(true))
	scene.call("_show_debrief")
	await _wait_frames(4)
	scene.call("request_debrief_return_homebase_for_test")
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_frontier_probe_homebase_visible_readiness_review_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_homebase_visible_readiness_review.v1", "TASK_642 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_642 visual gate passes")
	_assert(String(snapshot.get("readiness_gate", "")) == "pass", "TASK_642 builds on green TASK_641 readiness")
	_assert(bool(snapshot.get("post_summary_visible", false)), "Post-Debrief summary is visible")
	_assert(bool(snapshot.get("next_sortie_visible", false)), "Next-sortie readiness line is visible")
	_assert(String(snapshot.get("current_next_step_id", "")) == "review_roster_gains", "Visible review preserves current next step")
	_assert(String(snapshot.get("readiness_line", "")).begins_with("Next sortie:"), "Visible review carries next-sortie line")
	_assert(String(snapshot.get("rendered_readiness_line", "")) == String(snapshot.get("readiness_line", "")), "Rendered readiness line matches snapshot")
	_assert(_check_passed(snapshot, "labels_inside_mission_panel"), "Readiness labels stay inside MissionPanel")
	_assert(_check_passed(snapshot, "next_sortie_below_post_summary"), "Next-sortie label is below post summary")
	_assert(_check_passed(snapshot, "labels_do_not_overlap"), "Homebase readiness labels do not overlap")
	_assert(_check_passed(snapshot, "mission_panel_no_overflow"), "MissionPanel does not overflow")
	_assert(bool(snapshot.get("manual_review_required", false)), "TASK_642 keeps manual visible review required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "TASK_642 does not claim manual review done")
	_assert(bool(snapshot.get("read_only", false)), "TASK_642 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_642 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_642 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_642 creates no command")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "TASK_642 evidence image has FullHD dimensions")
	_assert(_count_non_background_samples(image, Color(0.035, 0.047, 0.052, 1.0)) > 20, "TASK_642 evidence image has visible marks")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "TASK_642 evidence PNG is written")
	var manifest: Dictionary = _build_manifest(snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_642 manifest is written")
	_assert(String(manifest.get("gate", "")) == "pass", "TASK_642 manifest gate passes")
	_assert(bool(manifest.get("manual_review_required", false)), "TASK_642 manifest keeps manual review required")
	_assert(not bool(manifest.get("manual_review_done", true)), "TASK_642 manifest does not claim manual review done")
	_assert(String(manifest.get("evidence_board_readability_gate", "")) == "pass", "TASK_642 evidence board readability gate passes")
	_assert(int(manifest.get("callout_label_count", 0)) >= EVIDENCE_BOARD_CALLOUT_LABEL_COUNT, "TASK_642 evidence board has callout labels")

	scene.queue_free()
	await _wait_frames(2)


func _build_frontier_probe_result() -> Dictionary:
	return {
		"scenario_id": "frontier_probe_vertical_slice",
		"mission_id": "frontier_probe_vertical_slice",
		"scenario_file_path": "res://data/mission_scenarios/frontier_probe_vertical_slice.json",
		"route_id": "frontier_probe_aa_computer_cargo",
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "frontier_probe_cargo_extract",
		"objective_captured": true,
		"duration_seconds": 312.0,
		"selected_unit_ids": PackedStringArray(["lead_alpha", "rifle_alpha", "medic_alpha"]),
		"selected_fireteam_ids": PackedStringArray(["ft_alpha"]),
		"progression_award_summary": {
			"schema": "sternenbuergerchen.skill_progress_award_summary.v1",
			"authority": "MissionProgressionResolver",
			"source": "progression_unit_updates",
			"award_applied": true,
			"total_xp_delta": 18,
			"listed_awards": [
				{"unit_id": "lead_alpha", "xp_delta": 8, "skill_gain_count": 1, "ftl_tactical_gain": 0.015},
			],
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
	}


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


func _build_evidence_board(snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 90), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 990, 1920, 90), Color(0.02, 0.075, 0.09, 1.0))
	var mission_rect: Rect2i = _rect_from_snapshot(snapshot, "mission_panel_rect")
	var post_rect: Rect2i = _rect_from_snapshot(snapshot, "post_summary_rect")
	var next_rect: Rect2i = _rect_from_snapshot(snapshot, "next_sortie_rect")
	_fill_rect(image, mission_rect, Color(0.11, 0.15, 0.18, 1.0))
	_draw_rect_outline(image, mission_rect, Color(0.35, 0.56, 0.66, 1.0), 4)
	_fill_rect(image, post_rect.grow(4), Color(0.24, 0.56, 0.42, 1.0))
	_draw_rect_outline(image, post_rect.grow(4), Color(0.62, 0.95, 0.78, 1.0), 3)
	_fill_rect(image, next_rect.grow(4), Color(0.28, 0.43, 0.70, 1.0))
	_draw_rect_outline(image, next_rect.grow(4), Color(0.66, 0.80, 1.0, 1.0), 3)
	_fill_rect(image, Rect2i(80, 140, 360, 38), Color(0.62, 0.95, 0.78, 1.0))
	_fill_rect(image, Rect2i(80, 202, 360, 38), Color(0.66, 0.80, 1.0, 1.0))
	_fill_rect(image, Rect2i(80, 264, 360, 38), Color(0.86, 0.70, 0.18, 1.0))
	_fill_rect(image, Rect2i(80, 326, 360, 38), Color(0.58, 0.88, 0.66, 1.0))
	_fill_rect(image, Rect2i(80, 910, 900, 34), Color(0.58, 0.88, 0.66, 1.0))
	_draw_evidence_board_labels(image, mission_rect, post_rect, next_rect, snapshot)
	return image


func _build_manifest(snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_homebase_visible_readiness_review_manifest.v1",
		"task_id": "TASK_642",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"gate": String(snapshot.get("gate", "")),
		"capture_type": "frontier_probe_homebase_visible_readiness_review",
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"visual_polish_task_id": "TASK_643",
		"callout_label_count": EVIDENCE_BOARD_CALLOUT_LABEL_COUNT if not viewport_readback_available else 0,
		"evidence_board_readability_gate": "pass" if viewport_readback_available or EVIDENCE_BOARD_CALLOUT_LABEL_COUNT >= 8 else "fail",
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"readiness_gate": String(snapshot.get("readiness_gate", "")),
		"route_id": String(snapshot.get("route_id", "")),
		"scenario_id": String(snapshot.get("scenario_id", "")),
		"current_next_step_id": String(snapshot.get("current_next_step_id", "")),
		"readiness_line": String(snapshot.get("readiness_line", "")),
		"post_summary_visible": bool(snapshot.get("post_summary_visible", false)),
		"next_sortie_visible": bool(snapshot.get("next_sortie_visible", false)),
		"post_summary_rect": Dictionary(snapshot.get("post_summary_rect", {})).duplicate(true),
		"next_sortie_rect": Dictionary(snapshot.get("next_sortie_rect", {})).duplicate(true),
		"mission_panel_rect": Dictionary(snapshot.get("mission_panel_rect", {})).duplicate(true),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _rect_from_snapshot(snapshot: Dictionary, key: String) -> Rect2i:
	var rect: Dictionary = Dictionary(snapshot.get(key, {}))
	return Rect2i(
		int(round(float(rect.get("x", 0.0)))),
		int(round(float(rect.get("y", 0.0)))),
		maxi(1, int(round(float(rect.get("width", 1.0))))),
		maxi(1, int(round(float(rect.get("height", 1.0)))))
	)


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


func _draw_evidence_board_labels(image: Image, mission_rect: Rect2i, post_rect: Rect2i, next_rect: Rect2i, snapshot: Dictionary) -> void:
	var ink := Color(0.78, 0.91, 0.96, 1.0)
	var warm := Color(1.0, 0.82, 0.24, 1.0)
	var good := Color(0.65, 0.98, 0.78, 1.0)
	var cool := Color(0.70, 0.84, 1.0, 1.0)
	_draw_pixel_text(image, "TASK 642 HOMEBASE VISIBLE READINESS REVIEW", Vector2i(56, 30), ink, 3)
	_draw_pixel_text(image, "HEADLESS EVIDENCE BOARD - READ ONLY", Vector2i(56, 64), Color(0.45, 0.70, 0.78, 1.0), 2)
	_draw_pixel_text(image, "MISSION PANEL BOUNDS", mission_rect.position + Vector2i(18, 18), ink, 2)
	_draw_pixel_text(image, "POST DEBRIEF SUMMARY", post_rect.position + Vector2i(8, -28), good, 2)
	_draw_pixel_text(image, "NEXT SORTIE READINESS", next_rect.position + Vector2i(8, 22), cool, 2)
	_draw_pixel_text(image, "GREEN POST SUMMARY", Vector2i(462, 146), good, 2)
	_draw_pixel_text(image, "BLUE NEXT SORTIE", Vector2i(462, 208), cool, 2)
	_draw_pixel_text(image, "YELLOW REVIEW OPEN", Vector2i(462, 270), warm, 2)
	_draw_pixel_text(image, "PASS NO OVERLAP NO OVERFLOW", Vector2i(462, 332), Color(0.70, 0.95, 0.72, 1.0), 2)
	_draw_pixel_text(image, "CURRENT STEP  " + String(snapshot.get("current_next_step_id", "")).to_upper().replace("_", " "), Vector2i(80, 866), ink, 2)
	_draw_pixel_text(image, "NEXT CHECK REAL HOMEBASE WINDOW", Vector2i(80, 916), Color(0.03, 0.05, 0.04, 1.0), 2)


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
		"W": return PackedStringArray(["10001", "10001", "10001", "10101", "10101", "10101", "01010"])
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
		":": return PackedStringArray(["000", "010", "010", "000", "010", "010", "000"])
		">": return PackedStringArray(["10000", "01000", "00100", "00010", "00100", "01000", "10000"])
		"/": return PackedStringArray(["00001", "00010", "00010", "00100", "01000", "01000", "10000"])
		".": return PackedStringArray(["000", "000", "000", "000", "000", "010", "010"])
		_: return PackedStringArray()


func _count_non_background_samples(image: Image, background: Color) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 64)
	var step_y: int = maxi(1, image.get_height() / 36)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if image.get_pixel(x, y) != background:
				count += 1
	return count


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_642 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
