extends SceneTree

const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const SMOKE_SCENARIO_PATH: String = "res://data/mission_scenarios/editor_validation_smoke.json"
const SMOKE_MAP_PATH: String = "res://maps/task_157_editor_mvp_map.json"
const LIVE_SCENARIO_PATH: String = "user://task_158_editor_live_smoke.json"
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_158 Editor-to-Live Mission Validation Verifier ===")
	await _test_editor_saved_scenario_reaches_live_mission()
	_cleanup_user_file(LIVE_SCENARIO_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_editor_saved_scenario_reaches_live_mission() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SMOKE_SCENARIO_PATH)
	var validation: Dictionary = Dictionary(scenario.call("validate")) if scenario != null else {}
	_assert(scenario != null and bool(validation.get("valid", false)), "Smoke scenario validates before editor load")
	if scenario != null and not bool(validation.get("valid", false)):
		print("TASK_158 scenario validation errors: %s" % "; ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_assert(scenario != null and not _has_key_recursive(Dictionary(scenario.call("to_dict")), "lz"), "Smoke scenario contains no stored LZ fields")

	var editor: Node = await _create_editor()
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return

	_assert(bool(editor.call("load_mission_scenario_for_editor", SMOKE_SCENARIO_PATH)), "Editor loads the TASK_158 smoke scenario")
	await _wait_frames(5)
	var editor_data: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	_assert(String(editor_data.get("map_file_path", "")) == SMOKE_MAP_PATH, "Editor scenario references the expected map")
	_assert(not _has_key_recursive(editor_data, "lz") and not _has_key_recursive(editor_data, "landing_zone"), "Editor authoring data still has no LZ")
	_assert(editor.call("save_mission_scenario_from_editor", LIVE_SCENARIO_PATH) == OK, "Editor saves the live-test scenario scratch file")

	var live_scene := editor.call("create_live_test_scene_from_current_scenario") as Node
	_assert(live_scene != null, "Editor creates the live mission scene")
	editor.queue_free()
	await _wait_frames(2)
	if live_scene == null:
		return

	_configure_live_scene_for_insertion_smoke(live_scene)
	root.add_child(live_scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	_assert(_verify_live_setup(live_scene), "Live mission receives scenario map/objective/waves/patrols without LZ")
	await _verify_enemy_waves_arrive(live_scene)
	await _verify_player_lz_and_dropship(live_scene)
	await _verify_tactical_area_contact_objective_and_visuals(live_scene)

	live_scene.queue_free()
	await _wait_frames(2)


func _configure_live_scene_for_insertion_smoke(live_scene: Node) -> void:
	var mission_setup := live_scene.get_node_or_null("MissionSetup")
	if mission_setup == null:
		return
	mission_setup.set("defer_friendly_runtime_activation", true)
	mission_setup.set("allow_full_roster_when_selection_empty", false)
	mission_setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"]))
	mission_setup.set("selected_team_fireteam_ids", PackedStringArray(["blue", "blue", "blue", "blue"]))
	mission_setup.set(
		"selected_fireteam_definitions",
		[
			{
				"id": "blue",
				"label": "BLUE",
				"lead_unit_id": "unit_alpha",
				"respawn_enabled": false,
				"loadout": "medium",
			}
		]
	)


func _verify_live_setup(live_scene: Node) -> bool:
	var ok: bool = true
	var mission_setup := live_scene.get_node_or_null("MissionSetup")
	ok = _assert_and_return(mission_setup != null and String(mission_setup.get("scenario_file_path")) == LIVE_SCENARIO_PATH, "Live mission receives the editor-saved scenario path") and ok

	var simulation_root := live_scene.get_node_or_null("SimulationRoot")
	var objective_status = simulation_root.call("get_objective_status") if simulation_root != null and simulation_root.has_method("get_objective_status") else null
	ok = _assert_and_return(objective_status != null and absf(float(objective_status.capture_radius) - 64.0) <= 0.01, "Scenario objective radius reaches SimulationRoot") and ok
	ok = _assert_and_return(objective_status != null and _coerce_vector2(objective_status.position, Vector2.ZERO).distance_to(Vector2(448.0, 285.0)) <= 0.5, "Scenario objective marker reaches SimulationRoot") and ok

	var wave_controller := live_scene.get_node_or_null("EnemyWaveController")
	ok = _assert_and_return(wave_controller != null and int(wave_controller.get("wave_count")) == 2 and int(wave_controller.get("units_per_wave")) == 1, "Scenario wave count and wave size reach EnemyWaveController") and ok
	ok = _assert_and_return(wave_controller != null and absf(float(wave_controller.get("wave_delay_seconds")) - 1.0) <= 0.01, "Scenario wave delay reaches EnemyWaveController") and ok
	var delta_patrol: Array = Array(wave_controller.call("get_patrol_path_for_unit", "enemy_delta")) if wave_controller != null and wave_controller.has_method("get_patrol_path_for_unit") else []
	var echo_patrol: Array = Array(wave_controller.call("get_patrol_path_for_unit", "enemy_echo")) if wave_controller != null and wave_controller.has_method("get_patrol_path_for_unit") else []
	ok = _assert_and_return(delta_patrol.size() == 2 and _coerce_vector2(delta_patrol[0], Vector2.ZERO).distance_to(Vector2(512.0, 221.0)) <= 0.5, "Delta patrol binding reaches EnemyWaveController") and ok
	ok = _assert_and_return(echo_patrol.size() == 2 and _coerce_vector2(echo_patrol[1], Vector2.ZERO).distance_to(Vector2(464.0, 245.0)) <= 0.5, "Echo patrol binding reaches EnemyWaveController") and ok
	ok = _assert_and_return(_scene_has_no_player_lz(live_scene), "Live mission starts without stored/visible player LZ") and ok
	return ok


func _verify_enemy_waves_arrive(live_scene: Node) -> void:
	var wave_controller := live_scene.get_node_or_null("EnemyWaveController")
	_assert(wave_controller != null and int(wave_controller.call("get_current_wave_number")) >= 1, "First enemy wave starts from scenario config")
	if wave_controller != null:
		wave_controller.call("_process", 1.1)
	await _wait_frames(2)
	var delta := live_scene.get_node_or_null("EnemyDelta") as CanvasItem
	var echo := live_scene.get_node_or_null("EnemyEcho") as CanvasItem
	_assert(wave_controller != null and int(wave_controller.call("get_current_wave_number")) >= 2, "Second scenario wave can arrive through EnemyWaveController")
	_assert(delta != null and delta.visible and echo != null and echo.visible, "Scenario enemies are visible after their waves arrive")


func _verify_player_lz_and_dropship(live_scene: Node) -> void:
	var controller := live_scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Live mission has TacticalController for LZ/drop smoke")
	if controller == null:
		return

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = "task_158_dropship"
	planning_state["mission_drop_display_name"] = "TASK 158 Dropship"
	planning_state["mission_drop_title_text"] = "TASK 158 Dropship"
	planning_state["mission_drop_texture_path"] = "res://Assets/kenney_space-kit/Side/craft_speederB.png"
	planning_state["mission_drop_status_line"] = "Holding on mission map"
	planning_state["mission_drop_progress"] = 100.0
	planning_state["mission_drop_passenger_count"] = 4
	planning_state["drop_ship_requested"] = false
	planning_state["drop_ship_staged"] = false
	planning_state["has_lz_position"] = false
	planning_state["embarked_unit_ids"] = []
	planning_state["deployed_unit_ids"] = []
	planning_state["selected_fireteam"] = "BLUE"
	planning_state["selected_fireteams"] = ["blue"]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(4)
	_assert(_scene_has_no_player_lz(live_scene), "Waiting dropship state does not create an LZ by itself")
	_assert(_primary_3d_dropship_texture_visible(live_scene), "Waiting dropship is mirrored as an authored 2.5D craft texture without auto LZ")

	var lz_position := Vector2(448.0, 285.0)
	_assert(_place_lz_via_player_path(controller, lz_position), "Player/controller LZ path sets the mission LZ")
	await _wait_frames(2)
	var lz_marker := live_scene.get_node_or_null("LZMarker") as CanvasItem
	var placed_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var lz_visible_in_primary_3d: bool = _primary_3d_lz_visible(live_scene)
	var lz_visible_in_legacy_2d: bool = lz_marker != null and lz_marker.visible
	_assert(bool(placed_state.get("has_lz_position", false)) and (lz_visible_in_primary_3d or lz_visible_in_legacy_2d), "LZ becomes visible only after player path placement")

	controller.call("_on_call_dropship_pressed")
	await _wait_frames(2)
	_assert(String(controller.get("_drop_sequence_phase")) == "inbound", "Calling dropship starts the inbound live sequence")
	controller.call("_update_drop_sequence", 10.0)
	await _wait_physics_frames(8)
	await _wait_frames(4)
	var drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var deployed_ids: Array = Array(drop_state.get("deployed_unit_ids", []))
	deployed_ids.sort()
	_assert(String(controller.get("_drop_sequence_phase")) == "outbound", "Dropship deploys and switches to outbound after reaching LZ")
	_assert(deployed_ids == ["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"], "Selected fireteam deploys through dropship state")
	_assert(_collect_visible_friendly_unit_ids(live_scene) == deployed_ids, "Deployed fireteam becomes visible on the live mission map")


func _verify_tactical_area_contact_objective_and_visuals(live_scene: Node) -> void:
	var controller := live_scene.get_node_or_null("TacticalController")
	var combat_driver := live_scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := live_scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Live tactical systems are present for smoke execution")
	if controller == null or combat_driver == null or simulation_root == null:
		return

	_position_friendly_for_objective_progress(controller, Vector2(448.0, 285.0))
	_move_enemies_away_from_objective(controller)
	await _wait_physics_frames(10)
	var objective_status = simulation_root.call("get_objective_status")
	var progress_value: float = float(objective_status.capture_progress) if objective_status != null else -1.0
	_assert(progress_value > 0.0 and String(objective_status.capturing_team_id) == "team_alpha", "Objective reports live friendly capture progress")

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var area_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(360.0, 150.0), Vector2(540.0, 250.0), "engage"))
	_assert(area_refs.size() == 1, "Live mission creates an Attack Area from editor-started scenario")
	var visualized_area_orders: Array = Array(controller.call("get_visualized_area_orders_snapshot"))
	_assert(visualized_area_orders.size() == 1, "Area Order visual bridge exposes the created Attack Area")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "GO executes the created Attack Area")
	_assert(Array(controller.call("get_active_area_attack_snapshot")).size() == 1, "Tactical controller tracks active Attack Area execution")

	var friendly_units: Array = Array(controller.call("_get_all_friendly_units", false))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if not friendly_units.is_empty() and not enemy_units.is_empty():
		var friendly = friendly_units[0]
		var enemy = enemy_units[0]
		if friendly is Node2D and enemy is Node2D:
			(enemy as Node2D).global_position = (friendly as Node2D).global_position + Vector2(58.0, 0.0)
	combat_driver.call("_update_contact_tracking")
	combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")
	controller.call("refresh_contact_overlay")
	await _wait_frames(8)

	var tactical_contacts: Array = Array(controller.call("get_contact_snapshot"))
	var overlay := live_scene.get_node_or_null("ContactMapOverlay")
	var visible_contacts: Array = Array(overlay.call("get_visible_contacts")) if overlay != null and overlay.has_method("get_visible_contacts") else []
	_assert(not tactical_contacts.is_empty(), "Live contact system exposes scenario enemy contacts")
	_assert(not visible_contacts.is_empty(), "Contact overlay visual bridge shows live contacts")
	_assert(_visual_node_is_visible(live_scene, "UnitAlpha") and _visual_node_is_visible(live_scene, "EnemyDelta"), "Friendly and enemy live visuals are visible")
	_assert(live_scene.get_node_or_null("FireteamOrderVisualizer") != null, "FireteamOrderVisualizer bridge node is attached")
	_assert(overlay != null, "ContactMapOverlay bridge node is attached")


func _create_editor() -> Node:
	var packed_scene: PackedScene = load(MAP_EDITOR_SCENE_PATH)
	if packed_scene == null:
		return null
	var editor := packed_scene.instantiate()
	root.add_child(editor)
	await _wait_frames(5)
	return editor


func _place_lz_via_player_path(controller: Node, world_position: Vector2) -> bool:
	if controller == null:
		return false
	controller.call("_on_set_lz_pressed")
	var primary_view = _get_primary_3d_view(controller.get_parent())
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", world_position) if primary_view != null and primary_view.has_method("world_to_screen_position") else controller.get_viewport().get_canvas_transform() * world_position
	return bool(controller.call("_place_lz_from_screen_position", screen_position))


func _position_friendly_for_objective_progress(controller: Node, objective_position: Vector2) -> void:
	var friendly_units: Array = Array(controller.call("_get_all_friendly_units", false)) if controller != null else []
	for index in range(friendly_units.size()):
		var friendly = friendly_units[index]
		if friendly is Node2D:
			(friendly as Node2D).global_position = objective_position + Vector2(12.0 * float(index), 0.0)


func _move_enemies_away_from_objective(controller: Node) -> void:
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false)) if controller != null else []
	for index in range(enemy_units.size()):
		var enemy = enemy_units[index]
		if enemy is Node2D:
			(enemy as Node2D).global_position = Vector2(700.0 + 32.0 * float(index), 160.0)


func _scene_has_no_player_lz(scene: Node) -> bool:
	var lz_marker := scene.get_node_or_null("LZMarker") as CanvasItem
	if lz_marker != null and lz_marker.visible:
		return false
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("get_planning_state"):
		return true
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	return not bool(planning_state.get("has_lz_position", false))


func _collect_visible_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	if mission_root == null:
		return result
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		result.append(String(child.call("get_unit_id")).strip_edges())
	result.sort()
	return result


func _visual_node_is_visible(scene: Node, unit_node_name: String) -> bool:
	var unit := scene.get_node_or_null(unit_node_name) as CanvasItem
	var visual := scene.get_node_or_null("%s/Visual" % unit_node_name) as Sprite2D
	if unit == null or not unit.visible:
		return false
	var primary_view = _get_primary_3d_view(scene)
	if primary_view != null and primary_view.has_method("get_render_snapshot"):
		var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		return int(snapshot.get("unit_proxy_count", 0)) > 0
	return visual != null and visual.visible and visual.texture != null


func _primary_3d_lz_visible(scene: Node) -> bool:
	var primary_view = _get_primary_3d_view(scene)
	if primary_view == null or not primary_view.has_method("get_render_snapshot"):
		return false
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	return bool(snapshot.get("has_lz", false))


func _primary_3d_dropship_texture_visible(scene: Node) -> bool:
	var primary_view = _get_primary_3d_view(scene)
	if primary_view == null or not primary_view.has_method("get_render_snapshot"):
		return false
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	return bool(snapshot.get("dropship_texture_visible", false)) or bool(snapshot.get("dropship_model_visible", false))


func _get_primary_3d_view(scene: Node):
	if scene == null:
		return null
	return scene.get_node_or_null("Primary3DView")


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _has_key_recursive(value: Variant, key_needle: String) -> bool:
	var normalized_needle: String = key_needle.strip_edges().to_lower()
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			if key_text == normalized_needle or key_text.contains(normalized_needle):
				return true
			if _has_key_recursive(value_dict.get(key_variant), normalized_needle):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item_variant in Array(value):
			if _has_key_recursive(item_variant, normalized_needle):
				return true
	return false


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


func _cleanup_user_file(path: String) -> void:
	if path.is_empty():
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func _assert_and_return(condition: bool, message: String) -> bool:
	_assert(condition, message)
	return condition


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
