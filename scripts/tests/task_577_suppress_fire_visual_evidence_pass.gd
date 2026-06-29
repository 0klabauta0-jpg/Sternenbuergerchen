extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_577_suppress_fire_visual_evidence_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_576_TEST_PATH: String = "res://scripts/tests/task_576_suppress_fire_preview_readability_spike.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/suppress_fire_visual_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/suppress_fire_visual_evidence.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_577 Suppress Fire Visual Evidence Pass ===")
	_test_docs_and_wiring()
	await _test_capture_suppress_fire_visual_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_577: FAILED")
		quit(1)
		return
	print("TASK_577: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_577 task file exists")
	_assert(task_text.contains("Suppress Fire Visual Evidence Pass"), "TASK_577 task file names the task")
	_assert(status_text.contains("TASK_577 - Suppress Fire Visual Evidence Pass"), "Implementation status tracks TASK_577")
	_assert(roadmap_text.contains("TASK_577 - Suppress Fire Visual Evidence Pass (implementiert)"), "Roadmap marks TASK_577 implemented")
	_assert(roadmap_text.contains("TASK_578 - Suppress Fire Visual Polish Findings"), "Roadmap names TASK_578 follow-up")
	_assert(report_text.contains("TASK_577 - Suppress Fire Visual Evidence Pass"), "Review workbench tracks TASK_577")
	_assert(report_text.contains("suppress_fire_visual_evidence.png"), "Review workbench names SUP visual evidence PNG")
	_assert(report_text.contains("suppress_fire_visual_evidence.json"), "Review workbench names SUP visual evidence manifest")
	_assert(contract_text.contains("Suppress-Fire-Visual-Evidence"), "Mission feedback contract documents TASK_577")
	_assert(FileAccess.file_exists(TASK_576_TEST_PATH), "TASK_576 suppress preview verifier remains available")


func _test_capture_suppress_fire_visual_evidence() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission fixture exposes TacticalController, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for SUP visual evidence")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS)
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move order can be planned for SUP visual evidence before GO")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(10)

	var queue_count_before: int = _get_simulation_command_queue_count(simulation_root)
	var suppress_snapshot: Dictionary = Dictionary(controller.call("get_suppress_fire_preview_readability_snapshot"))
	var threat_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_first_move_threat_preview_readability_snapshot"))
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view.has_method("get_render_snapshot") else {}
	var queue_count_after: int = _get_simulation_command_queue_count(simulation_root)
	_assert(queue_count_before == queue_count_after, "Reading SUP visual evidence does not enqueue commands")
	_assert(String(suppress_snapshot.get("gate", "")) == "pass", "TASK_576 SUP preview gate passes in visual evidence capture")
	_assert(String(threat_snapshot.get("gate", "")) == "pass", "Threat preview gate remains green in visual evidence capture")
	_assert(String(suppress_snapshot.get("preview_text", "")).contains("SUP AREA"), "SUP AREA appears in capture snapshot")
	_assert(int(render_snapshot.get("waypoint_intent_preview_path_line_count", 0)) > 0, "Primary3D reports path line for SUP visual evidence")
	_assert(_has_preview_marker_or_ghost(render_snapshot), "Primary3D reports visual preview marker or ghost entry for SUP visual evidence")
	_assert(not bool(suppress_snapshot.get("ui_sets_gameplay_truth", true)), "SUP visual evidence snapshot remains read-only")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(suppress_snapshot, render_snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "SUP visual evidence image has FullHD dimensions")
	_assert(_count_non_transparent_samples(image) > 0, "SUP visual evidence image is not fully transparent")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "SUP visual evidence PNG is written")
	var manifest: Dictionary = _build_manifest(suppress_snapshot, threat_snapshot, render_snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "SUP visual evidence manifest is written")
	var manifest_text: String = _read_text(OUTPUT_MANIFEST_PATH)
	_assert(manifest_text.contains("suppress_fire_visual_evidence.png"), "SUP manifest names PNG")
	_assert(manifest_text.contains("SUP AREA"), "SUP manifest carries preview text")
	_assert(bool(manifest.get("manual_review_required", false)), "SUP manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "SUP manifest does not claim manual review done")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "SUP manifest remains read-only")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		_assert(viewport_readback_available, "Non-headless SUP run captured a real viewport readback")

	scene.queue_free()
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


func _build_evidence_board(suppress_snapshot: Dictionary, render_snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_evidence_grid(image, Rect2i(360, 128, 1200, 760), Color(0.07, 0.12, 0.12, 1.0))
	_fill_rect(image, Rect2i(700, 420, 520, 170), Color(0.16, 0.24, 0.28, 1.0))
	_draw_rect_outline(image, Rect2i(700, 420, 520, 170), Color(0.55, 0.80, 1.0, 1.0), 5)
	_fill_rect(image, Rect2i(922, 480, 76, 76), Color(0.92, 0.84, 0.24, 1.0))
	_draw_rect_outline(image, Rect2i(862, 420, 196, 196), Color(0.95, 0.64, 0.20, 1.0), 4)
	_fill_rect(image, Rect2i(600, 520, 320, 8), Color(0.44, 0.66, 0.96, 1.0))
	_fill_rect(image, Rect2i(1100, 356, 8, 240), Color(0.92, 0.34, 0.26, 1.0))
	_fill_rect(image, Rect2i(56, 130, 560, 26), Color(0.98, 0.80, 0.20, 1.0))
	_fill_rect(image, Rect2i(56, 172, clampi(int(render_snapshot.get("waypoint_intent_preview_visual_count", 0)) * 46, 90, 420), 20), Color(0.24, 0.74, 0.46, 1.0))
	_fill_rect(image, Rect2i(56, 210, clampi(String(suppress_snapshot.get("preview_text", "")).length() * 4, 120, 640), 20), Color(0.95, 0.64, 0.20, 1.0))
	return image


func _draw_evidence_grid(image: Image, rect: Rect2i, color: Color) -> void:
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


func _build_manifest(suppress_snapshot: Dictionary, threat_snapshot: Dictionary, render_snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"task_id": "TASK_577",
		"capture_type": "suppress_fire_visual_evidence",
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
		"suppress_preview_gate": String(suppress_snapshot.get("gate", "")),
		"threat_preview_gate": String(threat_snapshot.get("gate", "")),
		"selected_fireteam_ids": Array(suppress_snapshot.get("selected_fireteam_ids", [])),
		"selected_order_text": String(suppress_snapshot.get("selected_order_text", "")),
		"preview_text": String(suppress_snapshot.get("preview_text", "")),
		"fire_rule": String(suppress_snapshot.get("fire_rule", "")),
		"enabled": bool(suppress_snapshot.get("enabled", false)),
		"pressure_state": String(suppress_snapshot.get("pressure_state", "")),
		"radius_world": float(suppress_snapshot.get("radius_world", 0.0)),
		"command_queue_count_before_go": int(suppress_snapshot.get("command_queue_count_before_go", -1)),
		"render_preview_visual_count": int(render_snapshot.get("waypoint_intent_preview_visual_count", 0)),
		"render_preview_path_line_count": int(render_snapshot.get("waypoint_intent_preview_path_line_count", 0)),
		"render_preview_threat_line_count": int(render_snapshot.get("waypoint_intent_preview_threat_line_count", 0)),
		"render_preview_risk_state_counts": Dictionary(render_snapshot.get("waypoint_intent_preview_risk_state_counts", {})),
		"manual_review_required": true,
		"manual_review_done": false,
		"visible_followup_candidate": "suppress_area_visual_polish",
		"recommended_next_task": "TASK_578 - Suppress Fire Visual Polish Findings",
	}


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


func _mark_units_deployed(controller: Node, units: Array) -> void:
	var deployed_ids: Dictionary = {}
	var deployed_positions: Dictionary = {}
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		deployed_ids[unit_id] = true
		if unit is Node2D:
			deployed_positions[unit_id] = (unit as Node2D).global_position
	controller.set("_deployed_unit_ids", deployed_ids)
	controller.set("_deployed_unit_positions", deployed_positions)


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
			result.append(node)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _get_simulation_command_queue_count(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var command_queue_variant: Variant = simulation_root.get("command_queue")
	if typeof(command_queue_variant) != TYPE_ARRAY:
		return 0
	return Array(command_queue_variant).size()


func _has_preview_marker_or_ghost(render_snapshot: Dictionary) -> bool:
	if int(render_snapshot.get("waypoint_intent_preview_visual_count", 0)) > 0:
		return true
	for entry_variant in Array(render_snapshot.get("waypoint_intent_preview_entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var ghost_variant = entry.get("ghost_ftl_position", null)
		if typeof(ghost_variant) == TYPE_VECTOR2:
			return true
		if typeof(ghost_variant) == TYPE_STRING and not String(ghost_variant).strip_edges().is_empty():
			return true
	return false


func _count_non_transparent_samples(image: Image) -> int:
	var count: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return 0
	var step_y: int = maxi(1, floori(float(height) / 24.0))
	var step_x: int = maxi(1, floori(float(width) / 24.0))
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			if image.get_pixel(x, y).a > 0.01:
				count += 1
	return count


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


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
