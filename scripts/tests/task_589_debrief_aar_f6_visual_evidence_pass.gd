extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_589_debrief_aar_f6_visual_evidence_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DEBRIEF_SCREEN_PATH: String = "res://scripts/meta/debrief_screen.gd"
const TASK_588_TEST_PATH: String = "res://scripts/tests/task_588_debrief_aar_data_bridge.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/debrief_aar_f6_visual_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/debrief_aar_f6_visual_evidence.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_589 Debrief AAR F6 Visual Evidence Pass ===")
	_test_docs_and_wiring()
	await _test_capture_debrief_aar_visual_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_589: FAILED")
		quit(1)
		return
	print("TASK_589: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var debrief_text: String = _read_text(DEBRIEF_SCREEN_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_589 task file exists")
	_assert(task_text.contains("Debrief AAR F6 Visual Evidence Pass"), "TASK_589 task file names the task")
	_assert(status_text.contains("TASK_589 - Debrief AAR F6 Visual Evidence Pass"), "Implementation status tracks TASK_589")
	_assert(roadmap_text.contains("TASK_589 - Debrief AAR F6 Visual Evidence Pass (implementiert)"), "Roadmap marks TASK_589 implemented")
	_assert(roadmap_text.contains("TASK_590 - Debrief AAR Layout Polish Findings"), "Roadmap names TASK_590 follow-up")
	_assert(report_text.contains("TASK_589 - Debrief AAR F6 Visual Evidence Pass"), "Review workbench tracks TASK_589")
	_assert(report_text.contains("debrief_aar_f6_visual_evidence.png"), "Review workbench names Debrief AAR visual evidence PNG")
	_assert(report_text.contains("debrief_aar_f6_visual_evidence.json"), "Review workbench names Debrief AAR visual evidence manifest")
	_assert(contract_text.contains("Debrief-AAR-F6-Visual-Evidence"), "Mission feedback contract documents TASK_589")
	_assert(debrief_text.contains("get_debrief_aar_visual_evidence_snapshot"), "Debrief screen exposes TASK_589 snapshot")
	_assert(FileAccess.file_exists(TASK_588_TEST_PATH), "TASK_588 data bridge verifier remains available")


func _test_capture_debrief_aar_visual_evidence() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var debrief: Node = DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	debrief.set("visible", true)
	await _wait_frames(8)
	var mission_result: Dictionary = _build_base_mission_result()
	mission_result["mini_aar_debrief"] = _build_mini_aar_debrief_payload()
	debrief.call("set_mission_result", mission_result)
	await _wait_frames(12)

	var bridge_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_data_bridge_snapshot"))
	var visual_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_visual_evidence_snapshot"))
	_assert(String(bridge_snapshot.get("gate", "")) == "pass", "TASK_588 AAR bridge gate passes inside visual evidence capture")
	_assert(String(visual_snapshot.get("schema", "")) == "sternenbuergerchen.debrief_aar_visual_evidence.v1", "Debrief AAR visual evidence reports stable schema")
	_assert(String(visual_snapshot.get("gate", "")) == "pass", "Debrief AAR visual evidence gate passes")
	_assert(bool(visual_snapshot.get("read_only", false)), "Debrief AAR visual evidence snapshot is read-only")
	_assert(not bool(visual_snapshot.get("ui_sets_gameplay_truth", true)), "Debrief AAR visual evidence does not set gameplay truth")
	_assert(String(visual_snapshot.get("bridge_gate", "")) == "pass", "Debrief AAR visual evidence keeps bridge gate green")
	_assert(int(visual_snapshot.get("aar_chip_count", 0)) >= 5, "Debrief AAR visual evidence sees AAR chips")
	_assert(int(visual_snapshot.get("aar_row_count", 0)) >= 4, "Debrief AAR visual evidence sees AAR rows")
	_assert(_check_passed(visual_snapshot, "aar_controls_inside_panel"), "AAR controls stay inside panel")
	_assert(_check_passed(visual_snapshot, "aar_before_buttons"), "AAR controls sit before buttons")
	_assert(_check_passed(visual_snapshot, "summary_text_compact"), "AAR summary stays compact")
	_assert(_check_passed(visual_snapshot, "rows_text_compact"), "AAR rows stay compact")
	_assert(_check_passed(visual_snapshot, "limit_text_compact"), "AAR limit text stays compact")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(visual_snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Debrief AAR visual evidence image has FullHD dimensions")
	_assert(_count_non_transparent_samples(image) > 0, "Debrief AAR visual evidence image is not fully transparent")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Debrief AAR visual evidence PNG is written")
	var manifest: Dictionary = _build_manifest(visual_snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Debrief AAR visual evidence manifest is written")
	var manifest_text: String = _read_text(OUTPUT_MANIFEST_PATH)
	_assert(manifest_text.contains("debrief_aar_f6_visual_evidence.png"), "Debrief AAR manifest names PNG")
	_assert(String(manifest.get("visual_gate", "")) == "pass", "Debrief AAR manifest keeps visual gate")
	_assert(bool(manifest.get("manual_review_required", false)), "Debrief AAR manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Debrief AAR manifest does not claim manual review done")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Debrief AAR manifest remains read-only")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		_assert(viewport_readback_available, "Non-headless Debrief AAR run captured a real viewport readback")

	debrief.queue_free()
	await _wait_frames(2)


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


func _build_evidence_board(visual_snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_evidence_grid(image, Rect2i(260, 120, 1400, 820), Color(0.07, 0.11, 0.12, 1.0))
	var panel_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "panel_rect")
	var section_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "aar_section_rect")
	var summary_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "aar_summary_rect")
	var chip_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "aar_chip_strip_rect")
	var rows_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "aar_rows_rect")
	var limit_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "aar_limit_rect")
	var button_rect: Rect2i = _rect_from_snapshot(visual_snapshot, "button_row_rect")
	_fill_rect(image, panel_rect, Color(0.12, 0.16, 0.19, 1.0))
	_draw_rect_outline(image, panel_rect, Color(0.38, 0.55, 0.64, 1.0), 4)
	_fill_rect(image, section_rect, Color(0.18, 0.30, 0.34, 1.0))
	_draw_rect_outline(image, section_rect.grow(6), Color(0.38, 0.83, 0.87, 1.0), 4)
	_fill_rect(image, summary_rect, Color(0.98, 0.80, 0.20, 1.0))
	_fill_rect(image, chip_rect, Color(0.44, 0.66, 0.96, 1.0))
	_fill_rect(image, rows_rect, Color(0.46, 0.78, 0.56, 1.0))
	_fill_rect(image, limit_rect, Color(0.86, 0.64, 0.28, 1.0))
	_draw_rect_outline(image, button_rect, Color(0.86, 0.90, 0.95, 1.0), 3)
	_draw_evidence_swatch_strip(image)
	return image


func _draw_evidence_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 96, rect.position.x + rect.size.x, 96):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 96, rect.position.y + rect.size.y, 96):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


func _draw_evidence_swatch_strip(image: Image) -> void:
	var swatches: Array = [
		{"rect": Rect2i(56, 126, 160, 22), "color": Color(0.38, 0.83, 0.87, 1.0)},
		{"rect": Rect2i(56, 164, 130, 18), "color": Color(0.98, 0.80, 0.20, 1.0)},
		{"rect": Rect2i(56, 198, 130, 18), "color": Color(0.44, 0.66, 0.96, 1.0)},
		{"rect": Rect2i(56, 232, 130, 18), "color": Color(0.46, 0.78, 0.56, 1.0)},
		{"rect": Rect2i(56, 266, 130, 18), "color": Color(0.86, 0.64, 0.28, 1.0)},
	]
	for swatch_variant in swatches:
		var swatch: Dictionary = Dictionary(swatch_variant)
		_fill_rect(image, swatch.get("rect"), swatch.get("color"))


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


func _rect_from_snapshot(snapshot: Dictionary, key: String) -> Rect2i:
	var rect_dict: Dictionary = Dictionary(snapshot.get(key, {}))
	return Rect2i(
		roundi(float(rect_dict.get("x", 0.0))),
		roundi(float(rect_dict.get("y", 0.0))),
		maxi(1, roundi(float(rect_dict.get("width", 1.0)))),
		maxi(1, roundi(float(rect_dict.get("height", 1.0))))
	)


func _build_manifest(visual_snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"task_id": "TASK_589",
		"capture_type": "debrief_aar_f6_visual_evidence",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"viewport": {
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"visual_gate": String(visual_snapshot.get("gate", "")),
		"bridge_gate": String(visual_snapshot.get("bridge_gate", "")),
		"source_schema": String(visual_snapshot.get("source_schema", "")),
		"aar_summary_text": String(visual_snapshot.get("aar_summary_text", "")),
		"aar_chip_count": int(visual_snapshot.get("aar_chip_count", 0)),
		"aar_row_count": int(visual_snapshot.get("aar_row_count", 0)),
		"button_gap": float(visual_snapshot.get("button_gap", -1.0)),
		"panel_rect": Dictionary(visual_snapshot.get("panel_rect", {})),
		"aar_section_rect": Dictionary(visual_snapshot.get("aar_section_rect", {})),
		"aar_summary_rect": Dictionary(visual_snapshot.get("aar_summary_rect", {})),
		"aar_chip_strip_rect": Dictionary(visual_snapshot.get("aar_chip_strip_rect", {})),
		"aar_rows_rect": Dictionary(visual_snapshot.get("aar_rows_rect", {})),
		"aar_limit_rect": Dictionary(visual_snapshot.get("aar_limit_rect", {})),
		"button_row_rect": Dictionary(visual_snapshot.get("button_row_rect", {})),
		"manual_review_required": true,
		"manual_review_done": false,
		"visible_followup_candidate": "debrief_aar_layout_polish",
		"recommended_next_task": "TASK_590 - Debrief AAR Layout Polish Findings",
	}


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _build_base_mission_result() -> Dictionary:
	return {
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "objective_capture",
		"objective_captured": true,
		"duration_seconds": 185.0,
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 42},
		],
		"fireteam_tactical_debrief": [
			{"fireteam_id": "ft_alpha", "reaction_delay_seconds": 0.42, "plan_quality": 0.76, "tempo_modifier": 1.08, "contact_report_count": 3, "contact_report_quality": 0.72, "morale": 0.68, "frustration": 0.22},
		],
	}


func _build_mini_aar_debrief_payload() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
		"task_id": "TASK_585",
		"source_schema": "sternenbuergerchen.mini_aar_combat_metrics.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"summary_text": "AAR | FIRE 12 | HIT 7 | FF 1/2 | SUP 3 | WOUND 1 | EXT 2",
		"rows": [
			{"id": "fire", "label": "Fire", "value_text": "FIRE 12 | HIT 7", "read_only": true},
			{"id": "friendly_fire", "label": "Friendly Fire", "value_text": "FF 1 / Risk 2", "read_only": true},
			{"id": "suppress", "label": "Suppress", "value_text": "SUP x3", "read_only": true},
			{"id": "status", "label": "Status", "value_text": "WOUND 1 | DOWN 0 | EXT 2", "read_only": true},
		],
		"chips": [
			{"id": "shots", "label": "FIRE", "value_text": "12", "style_key": "neutral", "read_only": true},
			{"id": "hits", "label": "HIT", "value_text": "7", "style_key": "good", "read_only": true},
			{"id": "ff", "label": "FF", "value_text": "1/2", "style_key": "warn", "read_only": true},
			{"id": "sup", "label": "SUP", "value_text": "3", "style_key": "accent", "read_only": true},
			{"id": "wounded", "label": "WOUND", "value_text": "1", "style_key": "warn", "read_only": true},
			{"id": "extracted", "label": "EXT", "value_text": "2", "style_key": "neutral", "read_only": true},
		],
		"limit_text": "Keine XP, keine Ammo, keine echte Suppression - nur Debrief-Vorschau aus vorhandenen Metriken.",
		"gate": "pass",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _count_non_transparent_samples(image: Image) -> int:
	var count: int = 0
	var step_x: int = maxi(1, image.get_width() / 16)
	var step_y: int = maxi(1, image.get_height() / 16)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if image.get_pixel(x, y).a > 0.01:
				count += 1
	return count


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
