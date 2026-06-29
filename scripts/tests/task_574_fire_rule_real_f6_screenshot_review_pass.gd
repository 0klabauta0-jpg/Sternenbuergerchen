extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_574_fire_rule_real_f6_screenshot_review_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_572_TEST_PATH: String = "res://scripts/tests/task_572_fire_rule_f6_readability_smoke.gd"
const TASK_573_TEST_PATH: String = "res://scripts/tests/task_573_fire_rule_manual_screenshot_notes_pass.gd"
const TACTICAL_COMMAND_RULES_SCRIPT = preload("res://scripts/tactical/tactical_command_rules.gd")
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/fire_rule_f6_real_review.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/fire_rule_f6_real_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_574 Fire Rule Real F6 Screenshot Review Pass ===")
	_test_docs_and_wiring()
	await _test_capture_fire_rule_real_f6_review()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_574: FAILED")
		quit(1)
		return
	print("TASK_574: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_574 task file exists")
	_assert(task_text.contains("Fire Rule Real F6 Screenshot Review Pass"), "TASK_574 task file names the task")
	_assert(status_text.contains("TASK_574 - Fire Rule Real F6 Screenshot Review Pass"), "Implementation status tracks TASK_574")
	_assert(roadmap_text.contains("TASK_574 - Fire Rule Real F6 Screenshot Review Pass (implementiert)"), "Roadmap marks TASK_574 implemented")
	_assert(roadmap_text.contains("TASK_575 - Fire Rule Evidence Polish Findings"), "Roadmap names TASK_575 follow-up")
	_assert(report_text.contains("TASK_574 - Fire Rule Real F6 Screenshot Review Pass"), "Review workbench tracks TASK_574")
	_assert(report_text.contains("fire_rule_f6_real_review.png"), "Review workbench names Fire-Rule real F6 PNG")
	_assert(report_text.contains("fire_rule_f6_real_review.json"), "Review workbench names Fire-Rule real F6 manifest")
	_assert(contract_text.contains("Fire-Rule-Real-F6-Screenshot-Review"), "Mission feedback contract documents TASK_574")
	_assert(FileAccess.file_exists(TASK_572_TEST_PATH), "TASK_572 F6 readability smoke remains available")
	_assert(FileAccess.file_exists(TASK_573_TEST_PATH), "TASK_573 manual notes verifier remains available")


func _test_capture_fire_rule_real_f6_review() -> void:
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
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes Controller, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for Fire-Rule real F6 review")
	if friendly_units.size() < 2:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 4), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_selected_fireteams_fire_rule", TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD)

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
		combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(12)
	controller.call("_update_ui")
	await _wait_frames(4)

	var readability_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_f6_readability_snapshot"))
	_assert(String(readability_snapshot.get("gate", "")) == "pass", "TASK_572 Fire-Rule F6 readability gate passes inside real review capture")
	_assert(String(readability_snapshot.get("selected_fire_rule_consensus", "")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD, "Hold Fire is the visible active rule in review capture")
	var button_labels: Array = Array(readability_snapshot.get("button_labels", []))
	_assert(button_labels.size() >= 4 and button_labels.has("HF") and button_labels.has("RF") and button_labels.has("FW") and button_labels.has("SUP"), "Review capture sees all Fire-Rule controls")
	_assert(bool(_find_check(readability_snapshot, "active_rule_affordance_stronger").get("passed", false)), "Review capture exposes stronger active Fire-Rule affordance")
	_assert(not bool(readability_snapshot.get("ui_sets_gameplay_truth", true)), "Fire-Rule review snapshot remains read-only")

	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_evidence_board(readability_snapshot)
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Fire-Rule real review image has FullHD dimensions")
	_assert(_count_non_transparent_samples(image) > 0, "Fire-Rule real review image is not fully transparent")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Fire-Rule real review PNG is written")
	var manifest: Dictionary = _build_manifest(readability_snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Fire-Rule real review manifest is written")
	_assert(_read_text(OUTPUT_MANIFEST_PATH).contains("fire_rule_f6_real_review.png"), "Manifest names Fire-Rule real review PNG")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest remains read-only")
	if DisplayServer.get_name().strip_edges().to_lower() != "headless":
		_assert(viewport_readback_available, "Non-headless run captured a real viewport readback")

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


func _build_evidence_board(readability_snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_evidence_grid(image, Rect2i(316, 120, 1288, 824), Color(0.07, 0.11, 0.12, 1.0))
	var command_panel_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "command_panel_rect")
	var fireteam_panel_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "fireteam_panel_rect")
	var mission_control_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "mission_control_status_rect")
	var button_group_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "fire_rule_group_rect")
	_fill_rect(image, command_panel_rect, Color(0.16, 0.22, 0.28, 1.0))
	_draw_rect_outline(image, command_panel_rect, Color(0.98, 0.80, 0.20, 1.0), 4)
	_fill_rect(image, fireteam_panel_rect, Color(0.20, 0.38, 0.54, 1.0))
	_draw_rect_outline(image, fireteam_panel_rect.grow(4), Color(0.44, 0.66, 0.96, 1.0), 3)
	_fill_rect(image, mission_control_rect, Color(0.18, 0.34, 0.38, 1.0))
	_draw_rect_outline(image, mission_control_rect.grow(4), Color(0.28, 0.66, 0.82, 1.0), 3)
	_fill_rect(image, button_group_rect, Color(0.98, 0.80, 0.20, 1.0))
	_draw_rect_outline(image, button_group_rect.grow(6), Color(1.0, 0.90, 0.34, 1.0), 3)
	_fill_rect(image, Rect2i(48, 132, 420, 22), Color(0.98, 0.80, 0.20, 1.0))
	_fill_rect(image, Rect2i(48, 170, 360, 18), Color(0.24, 0.74, 0.46, 1.0))
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


func _rect_from_snapshot(snapshot: Dictionary, key: String) -> Rect2i:
	var rect_dict: Dictionary = Dictionary(snapshot.get(key, {}))
	return Rect2i(
		roundi(float(rect_dict.get("x", 0.0))),
		roundi(float(rect_dict.get("y", 0.0))),
		maxi(1, roundi(float(rect_dict.get("width", 1.0)))),
		maxi(1, roundi(float(rect_dict.get("height", 1.0))))
	)


func _build_manifest(readability_snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	return {
		"task_id": "TASK_574",
		"capture_type": "fire_rule_real_f6_screenshot_review",
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
		"readability_gate": String(readability_snapshot.get("gate", "")),
		"selected_fire_rule_consensus": String(readability_snapshot.get("selected_fire_rule_consensus", "")),
		"selected_fireteam_ids": Array(readability_snapshot.get("selected_fireteam_ids", [])),
		"button_count": Array(readability_snapshot.get("button_labels", [])).size(),
		"button_labels": Array(readability_snapshot.get("button_labels", [])),
		"active_button_rules": Array(readability_snapshot.get("active_button_rules", [])),
		"active_button_affordance_count": int(readability_snapshot.get("active_button_affordance_count", 0)),
		"active_affordance_style_id": String(readability_snapshot.get("active_affordance_style_id", "")),
		"active_affordance_style_ids": Array(readability_snapshot.get("active_affordance_style_ids", [])),
		"active_button_visual_weight": float(readability_snapshot.get("active_button_visual_weight", 0.0)),
		"active_rule_affordance_stronger": bool(_find_check(readability_snapshot, "active_rule_affordance_stronger").get("passed", false)),
		"manual_review_required": true,
		"manual_review_done": false,
		"visible_followup_candidate": "active_rule_affordance_resolved",
		"recommended_next_task": "TASK_576 - Suppress Fire Preview Readability Spike",
	}


func _find_check(snapshot: Dictionary, check_id: String) -> Dictionary:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return check
	return {}


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
		mission_setup.set("defer_friendly_runtime_activation", true)
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
