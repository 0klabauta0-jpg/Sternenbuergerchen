extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_688_mission_interaction_fullhd_evidence.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/mission_interaction_fullhd_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_interaction_fullhd_evidence.json"
const TARGET_VIEWPORT: Vector2i = Vector2i(1920, 1080)
const VISUAL_BUDGET_LIMIT: int = 32

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_688 Mission Interaction FullHD Evidence ===")
	_test_docs()
	await _test_mission_interaction_fullhd_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_688: FAILED")
		quit(1)
		return
	print("TASK_688: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_688 task file exists")
	_assert(task_text.contains("Mission Interaction FullHD Evidence"), "Task documents FullHD evidence")
	_assert(contract_text.contains("Mission FullHD Evidence"), "Interaction contract documents mission FullHD evidence")
	_assert(status_text.contains("TASK_688 - Mission Interaction FullHD Evidence"), "Implementation status tracks TASK_688")
	_assert(roadmap_text.contains("TASK_688 - Mission Interaction FullHD Evidence (implementiert)"), "Roadmap marks TASK_688 implemented")
	_assert(handbook_text.contains("TASK_688 - Mission Interaction FullHD Evidence"), "Current handbook references TASK_688")
	_assert(handbook_text.contains('data-export-key="mission_interaction_fullhd_evidence.png_path"'), "Current handbook exports TASK_688 PNG path")


func _test_mission_interaction_fullhd_evidence() -> void:
	_ensure_output_dir()
	root.size = TARGET_VIEWPORT
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, combat driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "station_computer",
		"state": "operating",
		"complete": false,
		"progress": 0.5,
		"hold_seconds": 9.0,
		"duration_seconds": 18.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "occupy_station_computer",
		"required_state": "computer_controlled",
		"interaction_type": "computer",
		"command_type": "take",
	})
	await _wait_frames(4)
	controller.call("_sync_primary_3d_mission_status_visuals")
	await _wait_frames(4)

	var visual_state: Dictionary = Dictionary(controller.call("get_mission_interaction_visual_state_snapshot"))
	var object_reaction: Dictionary = Dictionary(controller.call("get_mission_interaction_object_reaction_snapshot"))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var primary_view: Node = controller.call("_get_primary_3d_view")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Primary 3D view exposes render snapshot")
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var visual_budget: int = int(render_snapshot.get("mission_interaction_visual_state_count", 0)) + int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0)) + int(render_snapshot.get("route_callout_visual_count", 0))

	_assert(_snapshot_is_read_only(visual_state), "Visual state remains read-only")
	_assert(_snapshot_is_read_only(object_reaction), "Object reaction remains read-only")
	_assert(int(render_snapshot.get("mission_interaction_visual_state_count", 0)) >= 3, "Render snapshot contains interaction visual states")
	_assert(int(render_snapshot.get("mission_interaction_object_reaction_count", 0)) >= 3, "Render snapshot contains object reactions")
	_assert(int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0)) >= int(render_snapshot.get("mission_interaction_object_reaction_count", 0)), "Object reactions have visible proxy budget")
	_assert(String(command_feedback.get("mission_interaction_visual_state_summary", "")).contains("COM"), "Command feedback summary points at active computer")
	_assert(visual_budget > 0 and visual_budget <= VISUAL_BUDGET_LIMIT, "Mission interaction visual budget stays conservative")

	var viewport_image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = viewport_image != null and viewport_image.get_width() == TARGET_VIEWPORT.x and viewport_image.get_height() == TARGET_VIEWPORT.y
	var image: Image = viewport_image if viewport_readback_available else _build_review_board(render_snapshot, visual_state, object_reaction, command_feedback, visual_budget)
	_assert(image.get_width() == TARGET_VIEWPORT.x and image.get_height() == TARGET_VIEWPORT.y, "Evidence PNG image has FullHD dimensions")
	_assert(_count_visible_samples(image) > 0, "Evidence PNG image has visible pixels")
	var png_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(png_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Mission interaction evidence PNG is written")

	var manifest: Dictionary = _build_manifest(render_snapshot, visual_state, object_reaction, command_feedback, image, viewport_readback_available, visual_budget)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Mission interaction evidence manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.mission_interaction_fullhd_evidence.v1", "Evidence manifest schema is stable")
	_assert(String(parsed.get("task_id", "")) == "TASK_688", "Evidence manifest records TASK_688")
	_assert(bool(parsed.get("manual_fullhd_review_required", false)), "Evidence keeps manual FullHD review required")
	_assert(not bool(parsed.get("manual_fullhd_review_done", true)), "Evidence does not claim manual FullHD review done")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Evidence does not set gameplay truth")
	_assert(bool(parsed.get("within_visual_budget", false)), "Evidence manifest records visual budget within limit")

	scene.queue_free()
	await _wait_frames(2)


func _build_manifest(render_snapshot: Dictionary, visual_state: Dictionary, object_reaction: Dictionary, command_feedback: Dictionary, image: Image, viewport_readback_available: bool, visual_budget: int) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_interaction_fullhd_evidence.v1",
		"task_id": "TASK_688",
		"source_task_ids": ["TASK_686", "TASK_687"],
		"display_server": DisplayServer.get_name(),
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"visual_state_schema": String(visual_state.get("schema", "")),
		"object_reaction_schema": String(object_reaction.get("schema", "")),
		"render_visual_state_count": int(render_snapshot.get("mission_interaction_visual_state_count", 0)),
		"render_object_reaction_count": int(render_snapshot.get("mission_interaction_object_reaction_count", 0)),
		"render_object_reaction_visual_count": int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0)),
		"render_route_callout_visual_count": int(render_snapshot.get("route_callout_visual_count", 0)),
		"visual_budget": visual_budget,
		"visual_budget_limit": VISUAL_BUDGET_LIMIT,
		"within_visual_budget": visual_budget > 0 and visual_budget <= VISUAL_BUDGET_LIMIT,
		"visual_state_summary": String(visual_state.get("summary", "")),
		"object_reaction_summary": String(object_reaction.get("summary", "")),
		"command_feedback_visual_summary": String(command_feedback.get("mission_interaction_visual_state_summary", "")),
		"command_feedback_object_summary": String(command_feedback.get("mission_interaction_object_reaction_summary", "")),
		"render_snapshot_keys": render_snapshot.keys(),
		"manual_checks": [
			{"id": "real_window_launched", "label": "Mission in real FullHD window launched", "done": false},
			{"id": "labels_readable", "label": "AA/COM/CARGO labels readable at default camera", "done": false},
			{"id": "object_proxies_helpful", "label": "Object reaction proxies help instead of cluttering", "done": false},
			{"id": "hud_not_blocked", "label": "HUD panels do not hide important mission objects", "done": false}
		],
		"manual_fullhd_review_required": true,
		"manual_fullhd_review_done": false,
		"read_only_evidence": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_689 - Mission Interaction FullHD Visual Polish Findings",
	}


func _build_review_board(render_snapshot: Dictionary, visual_state: Dictionary, object_reaction: Dictionary, command_feedback: Dictionary, visual_budget: int) -> Image:
	var image: Image = Image.create(TARGET_VIEWPORT.x, TARGET_VIEWPORT.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.045, 0.047, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 106), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(0, 982, 1920, 98), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(44, 142, 520, 790), Color(0.070, 0.096, 0.104, 1.0))
	_draw_rect_outline(image, Rect2i(44, 142, 520, 790), Color(0.20, 0.42, 0.48, 1.0), 3)
	_fill_rect(image, Rect2i(600, 142, 720, 790), Color(0.055, 0.071, 0.070, 1.0))
	_draw_grid(image, Rect2i(640, 182, 640, 710), Color(0.11, 0.15, 0.15, 1.0))
	_fill_rect(image, Rect2i(1358, 142, 518, 790), Color(0.070, 0.096, 0.104, 1.0))
	_draw_rect_outline(image, Rect2i(1358, 142, 518, 790), Color(0.20, 0.42, 0.48, 1.0), 3)
	var visual_count: int = int(render_snapshot.get("mission_interaction_visual_state_count", 0))
	var object_count: int = int(render_snapshot.get("mission_interaction_object_reaction_count", 0))
	var object_visual_count: int = int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0))
	var route_count: int = int(render_snapshot.get("route_callout_visual_count", 0))
	_fill_rect(image, Rect2i(92, 202, clampi(visual_count * 56, 20, 420), 36), Color(0.38, 0.78, 1.0, 1.0))
	_fill_rect(image, Rect2i(92, 270, clampi(object_count * 56, 20, 420), 36), Color(0.46, 0.96, 0.62, 1.0))
	_fill_rect(image, Rect2i(92, 338, clampi(object_visual_count * 34, 20, 420), 36), Color(1.0, 0.80, 0.34, 1.0))
	_fill_rect(image, Rect2i(92, 406, clampi(route_count * 56, 20, 420), 36), Color(0.86, 0.70, 0.18, 1.0))
	var budget_color := Color(0.46, 0.96, 0.62, 1.0) if visual_budget <= VISUAL_BUDGET_LIMIT else Color(1.0, 0.38, 0.30, 1.0)
	_fill_rect(image, Rect2i(1402, 202, clampi(visual_budget * 16, 20, 420), 42), budget_color)
	if String(command_feedback.get("mission_interaction_visual_state_summary", "")).contains("COM"):
		_fill_rect(image, Rect2i(1402, 288, 360, 42), Color(0.38, 0.78, 1.0, 1.0))
	if String(object_reaction.get("summary", "")).contains("COMPUTER"):
		_fill_rect(image, Rect2i(1402, 362, 310, 42), Color(0.46, 0.96, 0.62, 1.0))
	_fill_rect(image, Rect2i(760, 426, 132, 68), Color(1.0, 0.38, 0.30, 0.92))
	_fill_rect(image, Rect2i(928, 406, 132, 88), Color(0.38, 0.78, 1.0, 0.92))
	_fill_rect(image, Rect2i(1096, 448, 132, 46), Color(1.0, 0.80, 0.34, 0.92))
	return image


func _draw_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 64, rect.position.x + rect.size.x, 64):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 64, rect.position.y + rect.size.y, 64):
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


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _select_first_available_fireteam(controller: Node, mission_setup: Node) -> String:
	var available_ids: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	var candidate_id: String = ""
	if not available_ids.is_empty():
		candidate_id = String(available_ids[0]).strip_edges().to_lower()
	else:
		var configured_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
		if not configured_ids.is_empty():
			candidate_id = String(configured_ids[0]).strip_edges().to_lower()
	if candidate_id.is_empty():
		candidate_id = "ft1"
	controller.call("_set_selected_fireteams", PackedStringArray([candidate_id]), false)
	var selected_ids: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	return String(selected_ids[0]).strip_edges().to_lower() if not selected_ids.is_empty() else ""


func _move_fireteam_units(scene: Node, fireteam_id: String, center_position: Vector2) -> void:
	var offset_index: int = 0
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var offset: Vector2 = Vector2(float(offset_index % 2) * 10.0, float(int(offset_index / 2)) * 10.0)
		(child as Node2D).global_position = center_position + offset
		offset_index += 1


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_688 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
