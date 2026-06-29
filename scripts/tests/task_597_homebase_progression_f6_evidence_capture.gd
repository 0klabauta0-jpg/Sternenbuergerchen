extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")

const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const TASK_PATH: String = "res://docs/tasks/TASK_597_homebase_progression_f6_evidence_capture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HOMEBASE_SCREEN_PATH: String = "res://scripts/meta/homebase_screen.gd"
const TASK_596_TEST_PATH: String = "res://scripts/tests/task_596_homebase_progression_player_review_notes.gd"
const TASK_595_TEST_PATH: String = "res://scripts/tests/task_595_homebase_progression_visual_polish.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/homebase_progression_f6_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/homebase_progression_f6_evidence.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_597 Homebase Progression F6 Evidence Capture ===")
	_test_docs_and_wiring()
	await _test_capture_homebase_progression_f6_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_597: FAILED")
		quit(1)
		return
	print("TASK_597: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var homebase_text: String = _read_text(HOMEBASE_SCREEN_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_597 task file exists")
	_assert(task_text.contains("Homebase Progression F6 Evidence Capture"), "TASK_597 task file names the task")
	_assert(status_text.contains("TASK_597 - Homebase Progression F6 Evidence Capture"), "Implementation status tracks TASK_597")
	_assert(status_text.contains("TASK_598 - Homebase Progression Evidence Polish Findings"), "Implementation status names TASK_598 follow-up")
	_assert(roadmap_text.contains("TASK_597 - Homebase Progression F6 Evidence Capture (implementiert)"), "Roadmap marks TASK_597 implemented")
	_assert(roadmap_text.contains("TASK_598 - Homebase Progression Evidence Polish Findings"), "Roadmap names TASK_598 follow-up")
	_assert(report_text.contains("TASK_597 - Homebase Progression F6 Evidence Capture"), "Review workbench tracks TASK_597")
	_assert(report_text.contains("homebase_progression_f6_evidence.png"), "Review workbench names Homebase Progression evidence PNG")
	_assert(report_text.contains("homebase_progression_f6_evidence.json"), "Review workbench names Homebase Progression evidence manifest")
	_assert(contract_text.contains("Homebase-Progression-F6-Evidence"), "Mission feedback contract documents TASK_597")
	_assert(homebase_text.contains("get_homebase_progression_f6_evidence_snapshot"), "Homebase exposes TASK_597 snapshot")
	_assert(FileAccess.file_exists(TASK_596_TEST_PATH), "TASK_596 review notes verifier remains available")
	_assert(FileAccess.file_exists(TASK_595_TEST_PATH), "TASK_595 visual polish verifier remains available")


func _test_capture_homebase_progression_f6_evidence() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task597_homebase_evidence", 18))
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	_assert(units.size() >= 3, "Generated roster has enough operators for Homebase evidence")
	if units.size() < 3:
		return
	var leader: Dictionary = Dictionary(units[0]).duplicate(true)
	var member: Dictionary = Dictionary(units[1]).duplicate(true)
	leader["is_fireteam_lead"] = true
	leader["display_name"] = "Evidence Delta Lead"
	member["display_name"] = "Evidence Delta Rifle"
	units[0] = leader
	units[1] = member
	roster["units"] = units
	var leader_id: String = String(leader.get("unit_id", "task597_lead"))
	var member_id: String = String(member.get("unit_id", "task597_member"))
	var fireteam_id: String = String(leader.get("fireteam_id", "ft_evidence")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		fireteam_id = "ft_evidence"
	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, _build_mission_result(leader_id, member_id, fireteam_id)))
	var award_summary: Dictionary = Dictionary(progression_result.get("award_summary", {}))
	var updated_units: Array = Array(Dictionary(progression_result.get("updated_roster", {})).get("units", []))
	_assert(String(award_summary.get("schema", "")) == "sternenbuergerchen.skill_progress_award_summary.v1", "Resolver award summary feeds Homebase evidence")

	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase instantiates for progression evidence")
	if homebase == null:
		return
	await _wait_frames(3)
	homebase.call("setup_roster", updated_units, PackedStringArray([leader_id, member_id]))
	homebase.call("set_fireteam_context", PackedStringArray([fireteam_id, fireteam_id]))
	homebase.call("set_post_mission_skill_delta_summary", award_summary)
	await _wait_frames(3)
	var roster_card := _find_npc_card(homebase, leader_id)
	_assert(roster_card != null, "Awarded operator card remains reachable")
	_assert(_open_npc_card(roster_card), "Awarded operator card opens Character Sheet")
	await _wait_frames(8)

	var bridge_snapshot: Dictionary = Dictionary(homebase.call("get_post_mission_skill_delta_snapshot"))
	var evidence_snapshot: Dictionary = Dictionary(homebase.call("get_homebase_progression_f6_evidence_snapshot"))
	_assert(String(bridge_snapshot.get("gate", "")) == "pass", "Homebase progression bridge gate passes inside evidence capture")
	_assert(String(evidence_snapshot.get("schema", "")) == "sternenbuergerchen.homebase_progression_f6_evidence.v1", "Homebase progression evidence reports stable schema")
	_assert(String(evidence_snapshot.get("gate", "")) == "pass", "Homebase progression evidence gate passes")
	_assert(bool(evidence_snapshot.get("read_only", false)), "Homebase progression evidence snapshot is read-only")
	_assert(not bool(evidence_snapshot.get("ui_sets_gameplay_truth", true)), "Homebase progression evidence does not set gameplay truth")
	_assert(String(evidence_snapshot.get("bridge_gate", "")) == "pass", "Homebase progression evidence keeps bridge gate green")
	_assert(String(evidence_snapshot.get("style_id", "")) == "homebase_progression_delta_v1", "Homebase progression evidence sees style id")
	_assert(String(evidence_snapshot.get("badge_text", "")) == "MISSION GAIN", "Homebase progression evidence sees badge")
	_assert(String(evidence_snapshot.get("award_label_text", "")).contains("MISSION GAIN"), "Homebase progression evidence reads badge label")
	_assert(String(evidence_snapshot.get("award_value_text", "")).contains("XP +"), "Homebase progression evidence reads XP delta")
	_assert(_check_passed(evidence_snapshot, "award_inside_popup"), "Award row stays inside popup")
	_assert(_check_passed(evidence_snapshot, "label_text_compact"), "Award label stays compact")
	_assert(_check_passed(evidence_snapshot, "value_text_compact"), "Award value stays compact")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(evidence_snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Homebase progression evidence image has FullHD dimensions")
	_assert(_count_non_transparent_samples(image) > 0, "Homebase progression evidence image is not fully transparent")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Homebase progression evidence PNG is written")
	var manifest: Dictionary = _build_manifest(evidence_snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Homebase progression evidence manifest is written")
	var manifest_text: String = _read_text(OUTPUT_MANIFEST_PATH)
	_assert(manifest_text.contains("homebase_progression_f6_evidence.png"), "Homebase progression manifest names PNG")
	_assert(String(manifest.get("visual_gate", "")) == "pass", "Homebase progression manifest keeps visual gate")
	_assert(bool(manifest.get("manual_review_required", false)), "Homebase progression manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Homebase progression manifest does not claim manual review done")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Homebase progression manifest remains read-only")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		_assert(viewport_readback_available, "Non-headless Homebase progression run captured a real viewport readback")

	homebase.queue_free()
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


func _build_evidence_board(evidence_snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_evidence_grid(image, Rect2i(260, 120, 1400, 820), Color(0.07, 0.11, 0.12, 1.0))
	var popup_rect: Rect2i = _rect_from_snapshot(evidence_snapshot, "popup_rect")
	var sheet_rect: Rect2i = _rect_from_snapshot(evidence_snapshot, "sheet_content_rect")
	var highlight_rect: Rect2i = _rect_from_snapshot(evidence_snapshot, "award_highlight_rect")
	var label_rect: Rect2i = _rect_from_snapshot(evidence_snapshot, "award_label_rect")
	var value_rect: Rect2i = _rect_from_snapshot(evidence_snapshot, "award_value_rect")
	_fill_rect(image, popup_rect, Color(0.11, 0.15, 0.18, 1.0))
	_draw_rect_outline(image, popup_rect, Color(0.38, 0.55, 0.64, 1.0), 4)
	_fill_rect(image, sheet_rect, Color(0.13, 0.18, 0.22, 1.0))
	_draw_rect_outline(image, sheet_rect, Color(0.36, 0.62, 0.74, 1.0), 3)
	_fill_rect(image, highlight_rect, Color(0.78, 0.62, 0.18, 1.0))
	_draw_rect_outline(image, highlight_rect.grow(6), Color(1.0, 0.82, 0.24, 1.0), 4)
	_fill_rect(image, label_rect, Color(0.98, 0.80, 0.20, 1.0))
	_fill_rect(image, value_rect, Color(0.46, 0.78, 0.56, 1.0))
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
		{"rect": Rect2i(56, 126, 160, 22), "color": Color(0.38, 0.55, 0.64, 1.0)},
		{"rect": Rect2i(56, 164, 130, 18), "color": Color(0.36, 0.62, 0.74, 1.0)},
		{"rect": Rect2i(56, 198, 130, 18), "color": Color(1.0, 0.82, 0.24, 1.0)},
		{"rect": Rect2i(56, 232, 130, 18), "color": Color(0.98, 0.80, 0.20, 1.0)},
		{"rect": Rect2i(56, 266, 130, 18), "color": Color(0.46, 0.78, 0.56, 1.0)},
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


func _build_manifest(evidence_snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"task_id": "TASK_597",
		"capture_type": "homebase_progression_f6_evidence",
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
		"visual_gate": String(evidence_snapshot.get("gate", "")),
		"bridge_gate": String(evidence_snapshot.get("bridge_gate", "")),
		"source_schema": String(evidence_snapshot.get("source_schema", "")),
		"focused_unit_id": String(evidence_snapshot.get("focused_unit_id", "")),
		"focused_delta_text": String(evidence_snapshot.get("focused_delta_text", "")),
		"style_id": String(evidence_snapshot.get("style_id", "")),
		"badge_text": String(evidence_snapshot.get("badge_text", "")),
		"award_label_text": String(evidence_snapshot.get("award_label_text", "")),
		"award_value_text": String(evidence_snapshot.get("award_value_text", "")),
		"popup_rect": Dictionary(evidence_snapshot.get("popup_rect", {})),
		"sheet_content_rect": Dictionary(evidence_snapshot.get("sheet_content_rect", {})),
		"award_highlight_rect": Dictionary(evidence_snapshot.get("award_highlight_rect", {})),
		"award_label_rect": Dictionary(evidence_snapshot.get("award_label_rect", {})),
		"award_value_rect": Dictionary(evidence_snapshot.get("award_value_rect", {})),
		"manual_review_required": true,
		"manual_review_done": false,
		"visible_followup_candidate": "homebase_progression_evidence_polish",
		"recommended_next_task": "TASK_598 - Homebase Progression Evidence Polish Findings",
	}


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _build_mission_result(leader_id: String, member_id: String, fireteam_id: String) -> Dictionary:
	return {
		"mission_id": "task597_homebase_progression_evidence",
		"mission_outcome": "success",
		"result": "success",
		"winning_team_id": "team_alpha",
		"objective_captured": true,
		"win_condition_type": "objective_capture",
		"duration_seconds": 222.0,
		"selected_unit_ids": PackedStringArray([leader_id, member_id]),
		"selected_fireteam_ids": PackedStringArray([fireteam_id, fireteam_id]),
		"team_states": [
			{"unit_id": leader_id, "display_name": "Evidence Delta Lead", "fireteam_id": fireteam_id, "vital_state": "fit", "health_points": 96},
			{"unit_id": member_id, "display_name": "Evidence Delta Rifle", "fireteam_id": fireteam_id, "vital_state": "fit", "health_points": 84},
		],
		"unit_events": {
			leader_id: {"unit_id": leader_id, "objective_participation": true, "issued_orders": true, "coordinated_plan": true, "contact_report": true, "breakout_decision": true},
			member_id: {"unit_id": member_id, "fired_weapon": true, "objective_participation": true},
		},
	}


func _open_npc_card(card: Node) -> bool:
	if card == null or not card.has_signal("card_open_requested") or not card.has_method("get_unit_id") or not card.has_method("get_profile"):
		return false
	if not HARNESS_SCRIPT.has_signal_connection(card, "card_open_requested"):
		return false
	var unit_id: String = String(card.call("get_unit_id"))
	var source_context: String = String(card.call("get_source_context")) if card.has_method("get_source_context") else ""
	card.emit_signal("card_open_requested", unit_id, card.call("get_profile"), source_context)
	return true


func _find_npc_card(root_node: Node, unit_id: String) -> Node:
	for node in _collect_nodes(root_node):
		if not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_unit_id")) == unit_id:
			return node
	return null


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


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


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame
