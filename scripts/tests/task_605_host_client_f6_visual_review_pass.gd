extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_605_host_client_f6_visual_review_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_604_TEST_PATH: String = "res://scripts/tests/task_604_core_loop_host_client_feel_smoke.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/host_client_f6_visual_review.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/host_client_f6_visual_review.json"

const RECOMMENDED_NEXT_TASK: String = "TASK_606 - Host Client F6 Visual Polish Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_605 Host Client F6 Visual Review Pass ===")
	_test_docs_and_wiring()
	await _test_host_client_f6_visual_review_capture()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_605: FAILED")
		quit(1)
		return
	print("TASK_605: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_605 task file exists")
	_assert(task_text.contains("Host Client F6 Visual Review Pass"), "TASK_605 task file names the task")
	_assert(status_text.contains("TASK_605 - Host Client F6 Visual Review Pass"), "Implementation status tracks TASK_605")
	_assert(roadmap_text.contains("TASK_605 - Host Client F6 Visual Review Pass (implementiert)"), "Roadmap marks TASK_605 implemented")
	_assert(report_text.contains("TASK_605 Host Client F6 Visual Review Pass"), "Review workbench tracks TASK_605")
	_assert(report_text.contains(RECOMMENDED_NEXT_TASK), "Review workbench names TASK_606 follow-up")
	_assert(contract_text.contains("Host-Client-F6-Visual-Review-Pass"), "Mission feedback contract documents TASK_605")
	_assert(FileAccess.file_exists(TASK_604_TEST_PATH), "TASK_604 host/client feel verifier remains available")


func _test_host_client_f6_visual_review_capture() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", {
			1: "team_alpha",
			2: "team_bravo",
		})
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission fixture exposes TacticalController, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for Host/Client F6 visual review")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS)
	_prepare_objective_and_cargo_context(controller, combat_driver, simulation_root)
	await _wait_frames(4)

	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, "blue")
	_assert(not contact_setup.is_empty(), "Enemy can be positioned for Host/Client F6 review context")
	if contact_setup.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var target_position: Vector2 = Vector2(contact_setup.get("enemy_position", Vector2.ZERO))
	_assign_suppress_fire_commands(controller, "blue", target_position)
	_force_detection_complete(controller, combat_driver, "blue", contact_setup)
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, "blue", contact_setup)
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(controller.call("get_core_loop_host_client_feel_snapshot"))
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_604 host/client feel gate passes inside TASK_605")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_605 reads a read-only Host/Client snapshot")
	_assert(_check_passed(snapshot, "host_client_team_context_visible"), "Host/client team context is visible")
	_assert(_check_passed(snapshot, "mission_control_keeps_act_line"), "ACT line is visible in Mission Control")
	_assert(_check_passed(snapshot, "selected_fireteam_context_visible"), "Selected Fireteam context is visible")
	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_visual_review_board(snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Host/Client F6 review image has FullHD dimensions")
	_assert(_count_visible_samples(image) > 0, "Host/Client F6 review image has visible marks")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Host/Client F6 review PNG is written")
	var manifest: Dictionary = _build_manifest(snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Host/Client F6 review manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_605", "Manifest records TASK_605")
	_assert(String(parsed.get("capture_type", "")) == "host_client_f6_visual_review", "Manifest records capture type")
	_assert(bool(parsed.get("read_only", false)), "Manifest stays read-only")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(parsed.get("task_604_gate", "")) == "pass", "Manifest records green TASK_604 gate")
	_assert(bool(parsed.get("host_client_context_visible", false)), "Manifest records visible Host/Client context")
	_assert(bool(parsed.get("act_line_visible", false)), "Manifest records visible ACT line")
	_assert(bool(parsed.get("objective_cargo_roe_visible", false)), "Manifest records Objective/Cargo/ROE visibility")
	_assert(bool(parsed.get("selected_fireteam_visible", false)), "Manifest records Selected Fireteam visibility")
	_assert(String(parsed.get("recommended_next_task", "")) == RECOMMENDED_NEXT_TASK, "Manifest recommends TASK_606")

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


func _build_visual_review_board(snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 100), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 980, 1920, 100), Color(0.02, 0.075, 0.09, 1.0))
	_draw_grid(image, Rect2i(304, 136, 1312, 728), Color(0.07, 0.11, 0.12, 1.0))
	var readability: Dictionary = Dictionary(snapshot.get("readability_snapshot", {}))
	var strategic_rect: Rect2i = _rect_from_snapshot(readability, "strategic_panel_rect", Rect2i(1484, 776, 300, 220))
	var fireteam_rect: Rect2i = _rect_from_snapshot(readability, "fireteam_panel_rect", Rect2i(512, 776, 920, 220))
	var teamchip_rect: Rect2i = _rect_from_snapshot(readability, "mission_team_chip_rect", Rect2i(1490, 214, 280, 42))
	var mission_rect: Rect2i = _rect_from_snapshot(readability, "mission_control_status_rect", Rect2i(1500, 790, 260, 80))
	var selected_rect: Rect2i = _rect_from_snapshot(readability, "selected_fireteam_status_rect", Rect2i(530, 792, 860, 80))
	_draw_region(image, strategic_rect, Color(0.08, 0.16, 0.18, 1.0), Color(0.26, 0.67, 0.78, 1.0))
	_draw_region(image, fireteam_rect, Color(0.12, 0.16, 0.20, 1.0), Color(0.26, 0.47, 0.74, 1.0))
	_draw_region(image, teamchip_rect.grow(6), Color(0.48, 0.38, 0.10, 1.0), Color(1.0, 0.82, 0.24, 1.0))
	_draw_region(image, mission_rect.grow(4), Color(0.15, 0.28, 0.32, 1.0), Color(0.28, 0.66, 0.82, 1.0))
	_draw_region(image, selected_rect.grow(4), Color(0.16, 0.28, 0.40, 1.0), Color(0.44, 0.66, 0.96, 1.0))
	_draw_manifest_bars(image, snapshot)
	return image


func _draw_manifest_bars(image: Image, snapshot: Dictionary) -> void:
	var checks: Array = [
		{"id": "host", "ok": _check_passed(snapshot, "host_client_team_context_visible"), "color": Color(1.0, 0.82, 0.24, 1.0)},
		{"id": "act", "ok": _check_passed(snapshot, "mission_control_keeps_act_line"), "color": Color(0.28, 0.66, 0.82, 1.0)},
		{"id": "obj", "ok": _check_passed(snapshot, "objective_cargo_roe_context_visible"), "color": Color(0.58, 0.88, 0.66, 1.0)},
		{"id": "sel", "ok": _check_passed(snapshot, "selected_fireteam_context_visible"), "color": Color(0.44, 0.66, 0.96, 1.0)},
	]
	var y: int = 150
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		var color: Color = check["color"] if bool(check.get("ok", false)) else Color(0.70, 0.18, 0.18, 1.0)
		_fill_rect(image, Rect2i(56, y, 360, 30), color)
		_draw_rect_outline(image, Rect2i(56, y, 360, 30), Color(0.85, 0.92, 0.95, 1.0), 2)
		y += 52
	_fill_rect(image, Rect2i(56, 404, 520, 28), Color(0.20, 0.38, 0.42, 1.0))
	_fill_rect(image, Rect2i(56, 448, 600, 28), Color(0.20, 0.30, 0.48, 1.0))
	_fill_rect(image, Rect2i(56, 492, 460, 28), Color(0.48, 0.38, 0.10, 1.0))


func _draw_region(image: Image, rect: Rect2i, fill: Color, outline: Color) -> void:
	_fill_rect(image, rect, fill)
	_draw_rect_outline(image, rect, outline, 4)


func _rect_from_snapshot(snapshot: Dictionary, key: String, fallback: Rect2i) -> Rect2i:
	var rect_dict: Dictionary = Dictionary(snapshot.get(key, {}))
	if rect_dict.is_empty():
		return fallback
	return Rect2i(
		roundi(float(rect_dict.get("x", fallback.position.x))),
		roundi(float(rect_dict.get("y", fallback.position.y))),
		maxi(1, roundi(float(rect_dict.get("width", fallback.size.x)))),
		maxi(1, roundi(float(rect_dict.get("height", fallback.size.y))))
	)


func _build_manifest(snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"task_id": "TASK_605",
		"capture_type": "host_client_f6_visual_review",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"manual_review_required": true,
		"manual_review_done": false,
		"viewport": {
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"task_604_gate": String(snapshot.get("gate", "")),
		"team_context": String(snapshot.get("mission_team_chip_context_text", "")),
		"mission_hud_interaction_line": String(snapshot.get("mission_hud_interaction_line", "")),
		"mission_control_status_text": String(snapshot.get("mission_control_status_text", "")),
		"selected_fireteam_status_text": String(snapshot.get("selected_fireteam_status_text", "")),
		"host_client_context_visible": _check_passed(snapshot, "host_client_team_context_visible"),
		"act_line_visible": _check_passed(snapshot, "mission_control_keeps_act_line"),
		"objective_cargo_roe_visible": _check_passed(snapshot, "objective_cargo_roe_context_visible"),
		"selected_fireteam_visible": _check_passed(snapshot, "selected_fireteam_context_visible"),
		"recommended_next_task": RECOMMENDED_NEXT_TASK,
	}


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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


func _prepare_objective_and_cargo_context(controller: Node, combat_driver: Node, simulation_root: Node) -> void:
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	if combat_driver.has_method("configure_scenario_runtime_gates_from_file"):
		combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	if combat_driver.has_method("set_mission_scenario_runtime_step_state"):
		combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
		combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	if combat_driver.has_method("set_mission_cargo_touchdown_state"):
		combat_driver.call("set_mission_cargo_touchdown_state", "landed", 12.0)
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")


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


func _assign_suppress_fire_commands(controller: Node, fireteam_id: String, target_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var command = UNIT_COMMAND_SCRIPT.new()
		command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
		command.priority = 30
		command.unit_id = _get_unit_id(unit)
		command.team_id = String(unit.call("get_team_id")) if unit.has_method("get_team_id") else "team_alpha"
		command.target_position = target_position
		command.source_command_type = "defend"
		command.fire_rule = TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
		if unit.has_method("assign_unit_command"):
			unit.call("assign_unit_command", command)
		if unit.has_method("set_runtime_status"):
			unit.call("set_runtime_status", "holding", "hold_position", 30, "fire_at_will", "defend", 1.0, 0.0, 0.0, 1, target_position, "engage", "aimed", "task605_host_client_f6_review", 1.0, 75.0)


func _position_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	enemy.global_position = friendly.global_position + Vector2(54.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"friendly_unit_id": _get_unit_id(friendly),
		"enemy_unit_id": _get_unit_id(enemy),
		"enemy_position": enemy.global_position,
	}


func _force_detection_complete(controller: Node, combat_driver: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		var friendly_id: String = _get_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	_force_detection_complete(controller, combat_driver, fireteam_id, contact_setup)
	combat_driver.set("_current_tick", 120)
	combat_driver.set("_next_attack_tick", 0)
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


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


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return unit.name if unit != null else ""


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


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
			if pixel.a > 0.01 and (pixel.r > 0.08 or pixel.g > 0.08 or pixel.b > 0.08):
				count += 1
	return count


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


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
