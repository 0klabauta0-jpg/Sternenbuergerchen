extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_654_frontier_probe_one_screen_f6_playtest_notes.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_one_screen_f6_playtest_notes.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_one_screen_f6_playtest_notes.json"
const EXPECTED_LINE: String = "PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_654 Frontier Probe One-Screen F6 Playtest Notes ===")
	_test_docs_and_report()
	await _test_f6_playtest_notes_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_654: FAILED")
		quit(1)
		return
	print("TASK_654: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_654 task file exists")
	_assert(task_text.contains("Frontier Probe One-Screen F6 Playtest Notes"), "TASK_654 task names F6 playtest notes")
	_assert(status_text.contains("TASK_654 - Frontier Probe One-Screen F6 Playtest Notes"), "Implementation status tracks TASK_654")
	_assert(roadmap_text.contains("TASK_654 - Frontier Probe One-Screen F6 Playtest Notes (implementiert)"), "Roadmap marks TASK_654 implemented")
	_assert(contract_text.contains("Frontier-Probe-One-Screen-F6-Playtest-Notes"), "Mission feedback contract documents TASK_654")
	_assert(report_text.contains("TASK_654 - Frontier Probe One-Screen F6 Playtest Notes"), "Current handbook report tracks TASK_654")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook export records latest task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook recommends a follow-up task")
	_assert(report_text.contains('data-export-key="status.task_654_done"'), "Current handbook exports TASK_654 done status")
	_assert(report_text.contains('data-export-key="one_screen_f6.line_readable"'), "Current handbook exports TASK_654 line check")
	_assert(report_text.contains('data-note-key="notes.one_screen_f6_playtest"'), "Current handbook exports TASK_654 notes")


func _test_f6_playtest_notes_packet() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes controller, combat driver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_frontier_probe_scene(scene, controller, combat_driver, simulation_root)
	var snapshot: Dictionary = await _capture_one_screen_snapshot(controller)
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_playtest_notes_board(snapshot)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_playability.v1", "TASK_654 reads TASK_653 snapshot")
	_assert(String(snapshot.get("gate", "")) == "pass", "One-screen playability gate passes in F6 notes setup")
	_assert(String(snapshot.get("one_screen_line", "")) == EXPECTED_LINE, "Snapshot exposes expected start line")
	_assert(String(snapshot.get("mission_control_status_text", "")).contains(EXPECTED_LINE), "Mission Control contains one-screen line")
	_assert(String(command_feedback.get("frontier_probe_one_screen_line", "")) == EXPECTED_LINE, "Command feedback exports same one-screen line")
	_assert(int(snapshot.get("valid_plan_count", 0)) >= 2, "F6 notes setup exposes at least two plan options")
	_assert(bool(snapshot.get("manual_review_required", false)), "Source snapshot requires manual review")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Source snapshot keeps manual review open")
	_assert(bool(snapshot.get("read_only", false)), "Source snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Source snapshot does not set gameplay truth")
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "F6 notes image has FullHD dimensions")
	_assert(_count_visible_samples(image) > 0, "F6 notes image has visible pixels")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "F6 playtest notes PNG is written")
	var manifest: Dictionary = _build_manifest(snapshot, command_feedback, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "F6 playtest notes manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_f6_playtest_notes.v1", "Manifest uses TASK_654 schema")
	_assert(String(manifest.get("one_screen_line", "")) == EXPECTED_LINE, "Manifest records expected line")
	_assert(bool(manifest.get("mission_control_contains_one_screen_line", false)), "Manifest records Mission Control line match")
	_assert(bool(manifest.get("command_feedback_exports_one_screen_line", false)), "Manifest records command feedback line match")
	_assert(String(manifest.get("playtest_gate", "")) == "ready_for_manual_review", "Manifest gate is ready for manual review")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_655 - Frontier Probe One-Screen Visual Tuning Findings", "Manifest recommends TASK_655")

	scene.queue_free()
	await _wait_frames(2)


func _prepare_frontier_probe_scene(scene: Node, controller: Node, combat_driver: Node, simulation_root: Node) -> void:
	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assign_fireteam_ids(friendly_units.slice(0, mini(2, friendly_units.size())), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	combat_driver.call("set_mission_cargo_touchdown_state", "blocked")
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")


func _capture_one_screen_snapshot(controller: Node) -> Dictionary:
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(4)
	return Dictionary(controller.call("get_frontier_probe_one_screen_playability_snapshot")).duplicate(true)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", true)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _build_manifest(snapshot: Dictionary, command_feedback: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	var line: String = String(snapshot.get("one_screen_line", ""))
	var readout: Dictionary = Dictionary(snapshot.get("readout", {}))
	var manual_checks: Array = [
		{"id": "line_readable_in_f6", "label": "PLAN/NEXT line is readable in F6", "done": false},
		{"id": "route_order_clear", "label": "LZ -> AA -> COM -> CARGO order is clear", "done": false},
		{"id": "next_action_clear", "label": "NEXT AA is understandable without task history", "done": false},
		{"id": "two_plan_options_clear", "label": "Two plan options are distinguishable", "done": false},
		{"id": "hud_density_acceptable", "label": "HUD density remains acceptable", "done": false},
		{"id": "performance_feels_fast", "label": "Interaction still feels fast", "done": false},
	]
	return {
		"schema": "sternenbuergerchen.frontier_probe_one_screen_f6_playtest_notes.v1",
		"task_id": "TASK_654",
		"source_task_id": "TASK_653",
		"capture_type": "frontier_probe_one_screen_f6_playtest_notes",
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
		"playtest_gate": "ready_for_manual_review",
		"source_gate": String(snapshot.get("gate", "")),
		"one_screen_line": line,
		"one_screen_line_char_count": line.length(),
		"one_screen_line_char_limit": 96,
		"one_screen_line_within_limit": bool(readout.get("line_within_limit", false)),
		"mission_control_contains_one_screen_line": String(snapshot.get("mission_control_status_text", "")).contains(line),
		"command_feedback_exports_one_screen_line": String(command_feedback.get("frontier_probe_one_screen_line", "")) == line,
		"valid_plan_count": int(snapshot.get("valid_plan_count", 0)),
		"plan_options": Array(snapshot.get("plan_options", [])),
		"next_interaction": Dictionary(snapshot.get("next_interaction", {})),
		"readout": Dictionary(snapshot.get("readout", {})),
		"checks": Array(snapshot.get("checks", [])),
		"manual_checks": manual_checks,
		"manual_check_count": manual_checks.size(),
		"manual_review_required": true,
		"manual_review_done": false,
		"notes": "Headless runs generate an evidence board. A real F6 window pass must still judge readability and pacing.",
		"recommended_next_task": "TASK_655 - Frontier Probe One-Screen Visual Tuning Findings",
	}


func _build_playtest_notes_board(snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.045, 0.047, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 110), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(0, 970, 1920, 110), Color(0.018, 0.066, 0.080, 1.0))
	_draw_grid(image, Rect2i(390, 150, 1140, 690), Color(0.072, 0.116, 0.120, 1.0))
	_fill_rect(image, Rect2i(80, 150, 270, 690), Color(0.075, 0.105, 0.115, 1.0))
	_draw_rect_outline(image, Rect2i(80, 150, 270, 690), Color(0.20, 0.42, 0.48, 1.0), 3)
	_fill_rect(image, Rect2i(1570, 150, 270, 690), Color(0.075, 0.105, 0.115, 1.0))
	_draw_rect_outline(image, Rect2i(1570, 150, 270, 690), Color(0.20, 0.42, 0.48, 1.0), 3)
	_draw_route(image)
	_draw_status_bars(image, snapshot)
	return image


func _draw_route(image: Image) -> void:
	var points: Array[Vector2i] = [
		Vector2i(540, 660),
		Vector2i(790, 445),
		Vector2i(1100, 355),
		Vector2i(1375, 600),
	]
	for index in range(points.size() - 1):
		_draw_connection_line(image, points[index], points[index + 1], Color(0.85, 0.88, 0.88, 1.0))
	var colors: Array[Color] = [
		Color(0.43, 0.85, 0.58, 1.0),
		Color(1.0, 0.50, 0.42, 1.0),
		Color(0.58, 0.72, 1.0, 1.0),
		Color(1.0, 0.82, 0.30, 1.0),
	]
	for index in range(points.size()):
		var point: Vector2i = points[index]
		var color: Color = colors[index]
		var rect := Rect2i(point.x - 56, point.y - 40, 112, 80)
		_fill_rect(image, rect, Color(color.r * 0.30, color.g * 0.30, color.b * 0.30, 1.0))
		_draw_rect_outline(image, rect, color, 5)
		_fill_rect(image, Rect2i(point.x - 20, point.y - 20, 40, 40), color)


func _draw_status_bars(image: Image, snapshot: Dictionary) -> void:
	var line_length: int = String(snapshot.get("one_screen_line", "")).length()
	var plan_count: int = int(snapshot.get("valid_plan_count", 0))
	_fill_rect(image, Rect2i(110, 210, clampi(80 + line_length * 4, 80, 220), 28), Color(0.62, 0.84, 1.0, 1.0))
	_fill_rect(image, Rect2i(110, 260, clampi(80 + plan_count * 38, 80, 220), 28), Color(0.46, 0.85, 0.58, 1.0))
	_fill_rect(image, Rect2i(1602, 210, 190, 28), Color(0.86, 0.70, 0.18, 1.0))
	_fill_rect(image, Rect2i(1602, 260, 210, 28), Color(0.92, 0.36, 0.30, 1.0))
	_fill_rect(image, Rect2i(1602, 310, 170, 28), Color(0.46, 0.85, 0.58, 1.0))


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


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


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


func _draw_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 96, rect.position.x + rect.size.x, 96):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 96, rect.position.y + rect.size.y, 96):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


func _draw_connection_line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var steps: int = maxi(1, int(start.distance_to(end)))
	for index in range(steps + 1):
		var t: float = float(index) / float(steps)
		var x: int = roundi(lerpf(float(start.x), float(end.x), t))
		var y: int = roundi(lerpf(float(start.y), float(end.y), t))
		_fill_rect(image, Rect2i(x - 3, y - 3, 6, 6), color)


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


func _count_visible_samples(image: Image) -> int:
	var count: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return 0
	var step_y: int = maxi(1, floori(float(height) / 24.0))
	var step_x: int = maxi(1, floori(float(width) / 24.0))
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.01 and (pixel.r > 0.05 or pixel.g > 0.05 or pixel.b > 0.05):
				count += 1
	return count


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_654 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


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
