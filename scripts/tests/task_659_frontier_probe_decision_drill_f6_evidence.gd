extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_659_frontier_probe_decision_drill_f6_evidence.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_decision_drill_f6_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_decision_drill_f6_evidence.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_659 Frontier Probe Decision Drill F6 Evidence ===")
	_test_docs_and_report()
	await _test_decision_drill_f6_evidence_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_659: FAILED")
		quit(1)
		return
	print("TASK_659: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_659 task file exists")
	_assert(task_text.contains("Frontier Probe Decision Drill F6 Evidence"), "TASK_659 task names decision drill F6 evidence")
	_assert(status_text.contains("TASK_659 - Frontier Probe Decision Drill F6 Evidence"), "Implementation status tracks TASK_659")
	_assert(roadmap_text.contains("TASK_659 - Frontier Probe Decision Drill F6 Evidence (implementiert)"), "Roadmap marks TASK_659 implemented")
	_assert(contract_text.contains("Frontier-Probe-Decision-Drill-F6-Evidence"), "Mission feedback contract documents TASK_659")
	_assert(report_text.contains("TASK_659 - Frontier Probe Decision Drill F6 Evidence"), "Current handbook report tracks TASK_659")
	_assert(report_text.contains('latest_completed_task: "TASK_659 - Frontier Probe Decision Drill F6 Evidence"'), "Current handbook export records TASK_659 latest")
	_assert(report_text.contains('recommended_next_task: "TASK_660 - Decision Drill Snapshot Performance Budget"'), "Current handbook recommends TASK_660")
	_assert(report_text.contains('data-export-key="status.task_659_done"'), "Current handbook exports TASK_659 done status")
	_assert(report_text.contains('data-export-key="decision_drill_f6_evidence.png_written"'), "Current handbook exports TASK_659 PNG status")
	_assert(report_text.contains('data-note-key="notes.decision_drill_f6_evidence"'), "Current handbook exports TASK_659 notes")
	_assert(controller_text.contains("get_frontier_probe_one_screen_player_decision_drill_snapshot"), "Controller keeps TASK_658 drill snapshot")


func _test_decision_drill_f6_evidence_packet() -> void:
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
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for TASK_659")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	_prepare_frontier_probe_scene(controller, simulation_root)
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "TASK_659 can plan the first Move through the existing right-click path")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var before_go: Dictionary = Dictionary(controller.call("get_frontier_probe_one_screen_player_decision_drill_snapshot")).duplicate(true)
	_assert(String(before_go.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_player_decision_drill.v1", "TASK_659 reads TASK_658 drill snapshot")
	_assert(String(before_go.get("gate", "")) == "pass", "Decision drill gate passes before GO")
	_assert(String(before_go.get("decision_stage", "")) == "preview", "Evidence records preview stage")
	_assert(String(before_go.get("next_token", "")) == "AA", "Evidence records NEXT AA")
	_assert(bool(before_go.get("go_ready", false)), "Evidence records GO readiness")
	_assert(_check_passed(before_go, "move_preview_before_go_readable"), "Move and risk preview are readable before GO")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "TASK_659 can confirm the planned move with GO")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(12)
	await _wait_physics_frames(3)

	var after_go: Dictionary = Dictionary(controller.call("get_frontier_probe_one_screen_player_decision_drill_snapshot")).duplicate(true)
	var execution_feedback: Dictionary = Dictionary(after_go.get("execution_feedback_snapshot", {}))
	_assert(String(after_go.get("gate", "")) == "pass", "Decision drill gate passes after GO")
	_assert(String(after_go.get("decision_stage", "")) == "execution", "Evidence records execution stage")
	_assert(bool(after_go.get("execution_active", false)), "Evidence records active execution")
	_assert(String(execution_feedback.get("gate", "")) == "pass", "Existing execution feedback gate passes")
	_assert(_check_passed(after_go, "execution_feedback_visible_after_go"), "Execution feedback is visible after GO")
	_assert(_check_passed(after_go, "read_only"), "Decision drill snapshot remains read-only")
	_assert(not bool(after_go.get("ui_sets_gameplay_truth", true)), "Decision drill snapshot does not set gameplay truth")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(before_go, after_go)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "TASK_659 evidence image has FullHD dimensions")
	_assert(_count_visible_samples(image) > 0, "TASK_659 evidence image has visible pixels")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "TASK_659 PNG is written")
	var manifest: Dictionary = _build_manifest(before_go, after_go, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_659 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_decision_drill_f6_evidence.v1", "Manifest uses TASK_659 schema")
	_assert(bool(manifest.get("before_go_ready", false)), "Manifest records pre-GO readiness")
	_assert(bool(manifest.get("after_go_execution_active", false)), "Manifest records post-GO execution")
	_assert(bool(manifest.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		_assert(viewport_readback_available, "Non-headless run captured a real viewport readback")

	scene.queue_free()
	await _wait_frames(2)


func _build_manifest(before_go: Dictionary, after_go: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	var manual_checks: Array = [
		{"id": "real_f6_window_reviewed", "label": "Real F6 window reviewed", "done": false},
		{"id": "preview_is_readable", "label": "Preview path, risk and GO readiness are readable", "done": false},
		{"id": "go_feedback_is_obvious", "label": "Execution feedback after GO is obvious", "done": false},
		{"id": "hud_density_ok", "label": "HUD density feels calm during the drill", "done": false},
		{"id": "performance_feels_fast", "label": "Decision drill feels fast enough", "done": false},
	]
	return {
		"schema": "sternenbuergerchen.frontier_probe_decision_drill_f6_evidence.v1",
		"task_id": "TASK_659",
		"source_task_id": "TASK_658",
		"source_task_ids": PackedStringArray(["TASK_540", "TASK_541", "TASK_567", "TASK_657", "TASK_658"]),
		"capture_type": "frontier_probe_decision_drill_f6_evidence",
		"display_server": DisplayServer.get_name(),
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"viewport": {
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"before_go_stage": String(before_go.get("decision_stage", "")),
		"after_go_stage": String(after_go.get("decision_stage", "")),
		"next_token": String(before_go.get("next_token", "")),
		"recommended_plan": Dictionary(before_go.get("recommended_plan", {})),
		"before_go_ready": bool(before_go.get("go_ready", false)),
		"after_go_execution_active": bool(after_go.get("execution_active", false)),
		"execution_feedback_gate": String(Dictionary(after_go.get("execution_feedback_snapshot", {})).get("gate", "")),
		"before_checks": Array(before_go.get("checks", [])),
		"after_checks": Array(after_go.get("checks", [])),
		"manual_checks": manual_checks,
		"manual_check_count": manual_checks.size(),
		"manual_review_required": true,
		"manual_review_done": false,
		"real_window_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_660 - Decision Drill Snapshot Performance Budget",
	}


func _build_evidence_board(before_go: Dictionary, after_go: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.045, 0.047, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 116), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(0, 964, 1920, 116), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(80, 160, 460, 720), Color(0.075, 0.105, 0.115, 1.0))
	_draw_rect_outline(image, Rect2i(80, 160, 460, 720), Color(0.20, 0.42, 0.48, 1.0), 3)
	_fill_rect(image, Rect2i(1380, 160, 460, 720), Color(0.075, 0.105, 0.115, 1.0))
	_draw_rect_outline(image, Rect2i(1380, 160, 460, 720), Color(0.20, 0.42, 0.48, 1.0), 3)
	_draw_grid(image, Rect2i(590, 175, 740, 650), Color(0.072, 0.116, 0.120, 1.0))
	_draw_route(image)
	var preview_width: int = 340 if bool(before_go.get("go_ready", false)) else 120
	var execution_width: int = 340 if bool(after_go.get("execution_active", false)) else 120
	_fill_rect(image, Rect2i(130, 230, preview_width, 34), Color(0.46, 0.85, 0.58, 1.0))
	_fill_rect(image, Rect2i(130, 300, 310 if String(before_go.get("next_token", "")) == "AA" else 90, 34), Color(1.0, 0.50, 0.42, 1.0))
	_fill_rect(image, Rect2i(130, 370, 320 if _check_passed(before_go, "move_preview_before_go_readable") else 90, 34), Color(0.86, 0.70, 0.18, 1.0))
	_fill_rect(image, Rect2i(1430, 230, execution_width, 34), Color(0.62, 0.84, 1.0, 1.0))
	_fill_rect(image, Rect2i(1430, 300, 320 if _check_passed(after_go, "execution_feedback_visible_after_go") else 90, 34), Color(0.46, 0.85, 0.58, 1.0))
	_fill_rect(image, Rect2i(1430, 370, 330 if _check_passed(after_go, "read_only") else 90, 34), Color(0.86, 0.70, 0.18, 1.0))
	return image


func _draw_route(image: Image) -> void:
	var points: Array[Vector2i] = [
		Vector2i(650, 675),
		Vector2i(850, 480),
		Vector2i(1080, 380),
		Vector2i(1260, 600),
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
		var rect := Rect2i(point.x - 50, point.y - 36, 100, 72)
		_fill_rect(image, rect, Color(color.r * 0.30, color.g * 0.30, color.b * 0.30, 1.0))
		_draw_rect_outline(image, rect, color, 5)
		_fill_rect(image, Rect2i(point.x - 18, point.y - 18, 36, 36), color)


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


func _prepare_frontier_probe_scene(controller: Node, simulation_root: Node) -> void:
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	var combat_driver := controller.get_node_or_null("../CombatLoopDriver")
	if combat_driver != null:
		combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
		combat_driver.call("set_mission_cargo_touchdown_state", "blocked")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")


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


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")).strip_edges() == check_id:
			return bool(check.get("passed", false))
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_659 manifest for writing")
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
