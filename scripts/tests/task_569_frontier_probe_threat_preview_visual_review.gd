extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_569_frontier_probe_threat_preview_visual_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TACTICAL_CLARITY_CONTRACT_PATH: String = "res://docs/dev/tactical_decision_clarity_contract.md"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const ORDER_VISUALIZER_PATH: String = "res://scripts/tactical/visuals/fireteam_order_visualizer.gd"
const TASK_568_TEST_PATH: String = "res://scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd"

var _passed: int = 0
var _failed: int = 0
var _contact_fixture_tick: int = 180


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_569 Frontier Probe Threat Preview Visual Review ===")
	_test_docs_and_wiring()
	await _test_threat_preview_visual_language()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_569: FAILED")
		quit(1)
		return
	print("TASK_569: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var tactical_contract_text: String = _read_text(TACTICAL_CLARITY_CONTRACT_PATH)
	var terrain_view_text: String = _read_text(TERRAIN_VIEW_PATH)
	var visualizer_text: String = _read_text(ORDER_VISUALIZER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_569 task file exists")
	_assert(task_text.contains("Frontier Probe Threat Preview Visual Review"), "TASK_569 task file names the task")
	_assert(status_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Implementation status tracks TASK_569")
	_assert(roadmap_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review (implementiert)"), "Roadmap marks TASK_569 implemented")
	_assert(roadmap_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Roadmap names TASK_570 follow-up")
	_assert(report_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Review workbench tracks TASK_569")
	_assert(report_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Review workbench names TASK_570 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Threat-Preview-Visual-Review"), "Mission command feedback contract documents TASK_569")
	_assert(tactical_contract_text.contains("Gelb") and tactical_contract_text.contains("Rot"), "Tactical clarity contract keeps color language")
	_assert(terrain_view_text.contains("waypoint_intent_preview_line_color_key_counts"), "Primary3D exposes threat preview color-key counters")
	_assert(terrain_view_text.contains("waypoint_intent_preview_line_role_counts"), "Primary3D exposes threat preview line-role counters")
	_assert(visualizer_text.contains("_get_preview_line_color_key") and visualizer_text.contains("risk_state"), "2D visualizer tints threat lines by risk state")
	_assert(FileAccess.file_exists(TASK_568_TEST_PATH), "TASK_568 risky contact fixture remains available")


func _test_threat_preview_visual_language() -> void:
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
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission fixture exposes Controller, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	var enemy_units: Array = _collect_team_units(scene, "team_bravo")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for visual review")
	_assert(enemy_units.size() >= 3, "Mission fixture exposes Bravo enemies for visual review")
	if friendly_units.size() < 3 or enemy_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(4)

	var anchor: Vector2 = (friendly_units[0] as Node2D).global_position
	var risky_target: Vector2 = anchor + Vector2(112.0, 0.0)
	_prepare_contact_fixture(controller, combat_driver, enemy_units, "blue", risky_target, 1)
	_assert(bool(controller.call("issue_right_click_command_for_test", risky_target, "move", false)), "Risky move can be planned before GO")
	_refresh_preview(controller)
	await _wait_frames(6)
	var risky_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_first_move_threat_preview_readability_snapshot"))
	var risky_render: Dictionary = _get_render_snapshot(scene)
	_assert(String(risky_snapshot.get("risk_state", "")).strip_edges().to_lower() == "risky", "Risky visual fixture keeps RISKY state")
	_assert(_count_from(risky_render, "waypoint_intent_preview_risk_state_counts", "risky") >= 1, "Primary3D counts risky preview risk color key")
	_assert(_count_from(risky_render, "waypoint_intent_preview_line_color_key_counts", "risky") >= 1, "Risky threat line is tinted yellow/risky")
	_assert(_count_from(risky_render, "waypoint_intent_preview_line_role_counts", "clear_friendly_shot") >= 1, "Risky threat line keeps clear-shot role diagnostic")
	_assert(int(risky_render.get("waypoint_intent_preview_threat_line_count", 0)) == int(risky_snapshot.get("line_of_fire_entry_count", 0)), "Risky render threat-line count mirrors preview entries")
	_assert(_first_render_preview_has_color_key(risky_render, "risky"), "Risky render entry exposes risky color key")

	var suicidal_target: Vector2 = anchor + Vector2(144.0, 64.0)
	_prepare_contact_fixture(controller, combat_driver, enemy_units, "blue", suicidal_target, 3)
	_assert(bool(controller.call("issue_right_click_command_for_test", suicidal_target, "move", false)), "Suicidal move can be planned before GO")
	_refresh_preview(controller)
	await _wait_frames(6)
	var suicidal_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_first_move_threat_preview_readability_snapshot"))
	var suicidal_render: Dictionary = _get_render_snapshot(scene)
	_assert(String(suicidal_snapshot.get("risk_state", "")).strip_edges().to_lower() == "suicidal", "Suicidal visual fixture keeps SUICIDAL state")
	_assert(_count_from(suicidal_render, "waypoint_intent_preview_risk_state_counts", "suicidal") >= 1, "Primary3D counts suicidal preview risk color key")
	_assert(_count_from(suicidal_render, "waypoint_intent_preview_line_color_key_counts", "suicidal") >= 3, "Suicidal threat lines are tinted red/suicidal")
	_assert(_count_from(suicidal_render, "waypoint_intent_preview_line_role_counts", "clear_friendly_shot") >= 3, "Suicidal threat lines keep clear-shot role diagnostics")
	_assert(int(suicidal_render.get("waypoint_intent_preview_threat_line_count", 0)) == int(suicidal_snapshot.get("line_of_fire_entry_count", 0)), "Suicidal render threat-line count mirrors preview entries")
	_assert(_first_render_preview_has_color_key(suicidal_render, "suicidal"), "Suicidal render entry exposes suicidal color key")
	_assert(not bool(suicidal_snapshot.get("ui_sets_gameplay_truth", true)), "Visual review snapshot remains read-only")

	scene.queue_free()
	await _wait_frames(2)


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


func _prepare_contact_fixture(controller: Node, combat_driver: Node, enemy_units: Array, fireteam_id: String, target_position: Vector2, exposed_enemy_count: int) -> void:
	_reset_contact_state(combat_driver)
	_move_enemies_away(enemy_units)
	var offsets: Array[Vector2] = [
		Vector2(128.0, 0.0),
		Vector2(0.0, 128.0),
		Vector2(-128.0, 0.0),
		Vector2(0.0, -128.0),
	]
	var max_count: int = mini(exposed_enemy_count, enemy_units.size())
	for index in range(max_count):
		var enemy := enemy_units[index] as Node2D
		if enemy == null:
			continue
		enemy.visible = true
		enemy.global_position = target_position + offsets[index % offsets.size()]
		enemy.set_meta("overwatch_ready", false)
	_seed_contact_tracker(combat_driver, enemy_units, fireteam_id, max_count)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")


func _reset_contact_state(combat_driver: Node) -> void:
	var tracker = combat_driver.get("_contact_tracker")
	if tracker != null and tracker.has_method("reset_all"):
		tracker.call("reset_all")
	combat_driver.set("_detection_progress", {})
	_contact_fixture_tick += 10
	combat_driver.set("_current_tick", _contact_fixture_tick)


func _seed_contact_tracker(combat_driver: Node, enemy_units: Array, fireteam_id: String, contact_count: int) -> void:
	var tracker = combat_driver.get("_contact_tracker")
	if tracker == null or not tracker.has_method("update"):
		return
	var observations: Array = []
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for index in range(mini(contact_count, enemy_units.size())):
		var enemy := enemy_units[index] as Node2D
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue
		observations.append({
			"fireteam_id": normalized_fireteam_id,
			"unit_id": String(enemy.call("get_unit_id")).strip_edges(),
			"team_id": String(enemy.call("get_team_id")) if enemy.has_method("get_team_id") else "team_bravo",
			"enemy_type": "rifleman",
			"position": enemy.global_position,
			"last_known_position": enemy.global_position,
			"detection_complete": true,
		})
	tracker.call("update", _contact_fixture_tick, observations, [normalized_fireteam_id], {normalized_fireteam_id: 1.0})
	_contact_fixture_tick += 1
	combat_driver.set("_current_tick", _contact_fixture_tick)
	tracker.call("update", _contact_fixture_tick, observations, [normalized_fireteam_id], {normalized_fireteam_id: 1.0})


func _refresh_preview(controller: Node) -> void:
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")


func _get_render_snapshot(scene: Node) -> Dictionary:
	var primary_3d_view := scene.get_node_or_null("Primary3DView")
	if primary_3d_view == null or not primary_3d_view.has_method("get_render_snapshot"):
		return {}
	return Dictionary(primary_3d_view.call("get_render_snapshot"))


func _count_from(snapshot: Dictionary, field_name: String, key: String) -> int:
	return int(Dictionary(snapshot.get(field_name, {})).get(key, 0))


func _first_render_preview_has_color_key(render_snapshot: Dictionary, expected_key: String) -> bool:
	for entry_variant in Array(render_snapshot.get("waypoint_intent_preview_entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("risk_color_key", "")).strip_edges().to_lower() == expected_key:
			if int(Dictionary(entry.get("threat_line_color_key_counts", {})).get(expected_key, 0)) > 0:
				return true
	return false


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


func _move_enemies_away(enemy_units: Array) -> void:
	for index in range(enemy_units.size()):
		var enemy := enemy_units[index] as Node2D
		if enemy == null:
			continue
		enemy.visible = false
		enemy.global_position = Vector2(12000.0 + 80.0 * float(index), 12000.0)


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


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
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
