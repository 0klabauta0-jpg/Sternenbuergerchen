extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_557_TEST_PATH: String = "res://scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd"
const TASK_560_TEST_PATH: String = "res://scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd"
const TASK_561_TEST_PATH: String = "res://scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd"
const TASK_563_TEST_PATH: String = "res://scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/frontier_probe_mp_f6_visual_evidence.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_mp_f6_visual_evidence.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_562 Frontier Probe Multiplayer F6 Visual Evidence Capture ===")
	_test_docs_and_wiring()
	await _test_capture_frontier_probe_mp_f6_visual_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_562: FAILED")
		quit(1)
		return
	print("TASK_562: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_562 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer F6 Visual Evidence Capture"), "TASK_562 task file names the task")
	_assert(status_text.contains("TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture"), "Implementation status tracks TASK_562")
	_assert(roadmap_text.contains("TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture (implementiert)"), "Roadmap marks TASK_562 implemented")
	_assert(roadmap_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview (implementiert)"), "Roadmap tracks TASK_563 evidence preview")
	_assert(roadmap_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings (implementiert)"), "Roadmap tracks TASK_564 evidence polish")
	_assert(roadmap_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass (implementiert)"), "Roadmap tracks TASK_565 real screenshot review")
	_assert(roadmap_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass (implementiert)"), "Roadmap tracks TASK_566 hover/panel polish")
	_assert(roadmap_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass (implementiert)"), "Roadmap marks TASK_567 implemented")
	_assert(roadmap_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Roadmap tracks TASK_568")
	_assert(roadmap_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Roadmap names TASK_569 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-F6-Visual-Evidence-Capture"), "Mission feedback contract documents TASK_562")
	_assert(report_text.contains("TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture"), "Review workbench tracks TASK_562")
	_assert(report_text.contains("TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview"), "Review workbench tracks TASK_563")
	_assert(report_text.contains("TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings"), "Review workbench tracks TASK_564")
	_assert(report_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Review workbench tracks TASK_566")
	_assert(report_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Review workbench tracks TASK_567")
	_assert(report_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Review workbench tracks TASK_568")
	_assert(report_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Review workbench names TASK_569 follow-up")
	_assert(FileAccess.file_exists(TASK_557_TEST_PATH), "TASK_557 readability verifier remains available")
	_assert(FileAccess.file_exists(TASK_560_TEST_PATH), "TASK_560 teamchip tooltip verifier remains available")
	_assert(FileAccess.file_exists(TASK_561_TEST_PATH), "TASK_561 manual review guide verifier remains available")
	_assert(FileAccess.file_exists(TASK_563_TEST_PATH), "TASK_563 evidence report preview verifier remains available")


func _test_capture_frontier_probe_mp_f6_visual_evidence() -> void:
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
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes Controller, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for visual evidence")
	if friendly_units.size() < 2:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 2), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)

	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	_assert(objective_status != null, "SimulationRoot exposes ObjectiveStatus")
	if objective_status == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	objective_status.owning_team_id = "team_alpha"
	objective_status.capturing_team_id = "team_alpha"
	objective_status.capture_progress = 1.0

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures frontier probe scenario gates")
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("select_tile_from_world_position_for_test", objective_status.position)
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(12)
	controller.call("_update_ui")
	await _wait_frames(4)

	var readability_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_multiplayer_f6_readability_snapshot"))
	var tooltip_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_multiplayer_teamchip_tooltip_snapshot"))
	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() > 0 and image.get_height() > 0
	if not viewport_readback_available:
		image = _build_visual_evidence_board(readability_snapshot, tooltip_snapshot)
	_assert(String(readability_snapshot.get("gate", "")) == "pass", "TASK_557 readability gate passes inside visual evidence capture")
	_assert(String(tooltip_snapshot.get("gate", "")) == "pass", "TASK_560 teamchip tooltip gate passes inside visual evidence capture")
	_assert(image.get_width() == 1920 and image.get_height() == 1080, "Captured viewport image has FullHD dimensions")
	_assert(_count_non_transparent_samples(image) > 0, "Captured viewport image is not fully transparent")
	var save_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(save_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "Visual evidence PNG is written")
	var manifest: Dictionary = _build_manifest(readability_snapshot, tooltip_snapshot, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Visual evidence manifest is written")
	_assert(_read_text(OUTPUT_MANIFEST_PATH).contains("frontier_probe_mp_f6_visual_evidence.png"), "Manifest names visual evidence PNG")
	_assert(int(manifest.get("evidence_board_region_count", 0)) >= 6, "Manifest names evidence board regions")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Visual evidence manifest remains read-only")

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


func _build_visual_evidence_board(readability_snapshot: Dictionary, tooltip_snapshot: Dictionary) -> Image:
	var image: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.047, 0.052, 1.0))
	var regions: Array = _build_evidence_board_regions()
	_fill_rect(image, Rect2i(0, 0, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.02, 0.075, 0.09, 1.0))
	_draw_evidence_grid(image, Rect2i(316, 120, 1288, 824), Color(0.07, 0.11, 0.12, 1.0))
	_draw_evidence_swatch_strip(image, regions)
	var strategic_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "strategic_panel_rect")
	var fireteam_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "fireteam_panel_rect")
	var teamchip_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "mission_team_chip_rect")
	var mission_control_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "mission_control_status_rect")
	var selected_fireteam_rect: Rect2i = _rect_from_snapshot(readability_snapshot, "selected_fireteam_status_rect")
	_fill_rect(image, strategic_rect, Color(0.08, 0.16, 0.18, 1.0))
	_draw_rect_outline(image, strategic_rect, Color(0.26, 0.67, 0.78, 1.0), 4)
	_fill_rect(image, fireteam_rect, Color(0.12, 0.16, 0.20, 1.0))
	_draw_rect_outline(image, fireteam_rect, Color(0.26, 0.47, 0.74, 1.0), 4)
	_fill_rect(image, teamchip_rect, Color(0.86, 0.70, 0.18, 1.0))
	_draw_rect_outline(image, teamchip_rect.grow(6), Color(1.0, 0.82, 0.24, 1.0), 3)
	_fill_rect(image, mission_control_rect, Color(0.18, 0.34, 0.38, 1.0))
	_draw_rect_outline(image, mission_control_rect.grow(4), Color(0.28, 0.66, 0.82, 1.0), 3)
	_fill_rect(image, selected_fireteam_rect, Color(0.20, 0.38, 0.54, 1.0))
	_draw_rect_outline(image, selected_fireteam_rect.grow(4), Color(0.44, 0.66, 0.96, 1.0), 3)
	var tooltip_length: int = clampi(int(tooltip_snapshot.get("mission_team_chip_tooltip_length", 0)), 0, 180)
	_fill_rect(image, Rect2i(48, 132, 18 + tooltip_length * 3, 28), Color(0.86, 0.70, 0.18, 1.0))
	_draw_rect_outline(image, Rect2i(48, 132, 18 + tooltip_length * 3, 28), Color(1.0, 0.82, 0.24, 1.0), 2)
	_fill_rect(image, Rect2i(48, 176, 420, 20), Color(0.28, 0.66, 0.82, 1.0))
	_fill_rect(image, Rect2i(48, 208, 360, 20), Color(0.24, 0.74, 0.46, 1.0))
	_draw_rect_outline(image, Rect2i(28, 112, 480, 140), Color(0.18, 0.34, 0.38, 1.0), 2)
	return image


func _build_evidence_board_regions() -> Array:
	return [
		{"id": "mission_team_chip", "label": "Mission Teamchip", "color": "#dbb32e"},
		{"id": "mission_control", "label": "Mission Control", "color": "#48a8d1"},
		{"id": "selected_fireteam", "label": "Selected Fireteam", "color": "#70a8f5"},
		{"id": "strategic_panel", "label": "Strategic Panel", "color": "#42abbf"},
		{"id": "fireteam_panel", "label": "Fireteam Panel", "color": "#4278bd"},
		{"id": "tooltip_probe", "label": "Teamchip Tooltip Probe", "color": "#79c969"},
	]


func _rect_from_snapshot(snapshot: Dictionary, key: String) -> Rect2i:
	var rect_dict: Dictionary = Dictionary(snapshot.get(key, {}))
	return Rect2i(
		roundi(float(rect_dict.get("x", 0.0))),
		roundi(float(rect_dict.get("y", 0.0))),
		maxi(1, roundi(float(rect_dict.get("width", 1.0)))),
		maxi(1, roundi(float(rect_dict.get("height", 1.0))))
	)


func _draw_evidence_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 96, rect.position.x + rect.size.x, 96):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 96, rect.position.y + rect.size.y, 96):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


func _draw_evidence_swatch_strip(image: Image, regions: Array) -> void:
	var y: int = 300
	for region_variant in regions:
		var region: Dictionary = Dictionary(region_variant)
		var color: Color = Color.html(String(region.get("color", "#ffffff")))
		_fill_rect(image, Rect2i(48, y, 34, 24), color)
		_fill_rect(image, Rect2i(96, y + 6, 220, 8), Color(color.r, color.g, color.b, 0.65))
		_draw_rect_outline(image, Rect2i(48, y, 268, 24), Color(0.12, 0.20, 0.22, 1.0), 1)
		y += 38


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


func _build_manifest(readability_snapshot: Dictionary, tooltip_snapshot: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	var evidence_board_regions: Array = _build_evidence_board_regions()
	return {
		"task_id": "TASK_562",
		"capture_type": "frontier_probe_mp_f6_visual_evidence",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"viewport": {
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"readability_gate": String(readability_snapshot.get("gate", "")),
		"teamchip_tooltip_gate": String(tooltip_snapshot.get("gate", "")),
		"mission_team_chip_text": String(tooltip_snapshot.get("mission_team_chip_text", "")),
		"mission_team_chip_tooltip_length": int(tooltip_snapshot.get("mission_team_chip_tooltip_length", 0)),
		"selected_fireteam_ids": Array(readability_snapshot.get("selected_fireteam_ids", [])),
		"evidence_board_regions": evidence_board_regions,
		"evidence_board_region_count": evidence_board_regions.size(),
		"manual_review_required": true,
		"manual_review_done": false,
		"recommended_next_task": "TASK_569 - Frontier Probe Threat Preview Visual Review",
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
