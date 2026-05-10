extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_160 Tactical Mission Playability Verifier ===")
	await _test_live_tactical_loop_is_visible_in_2_5d()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_live_tactical_loop_is_visible_in_2_5d() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene_for_blue_drop(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"))
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and combat_driver != null and simulation_root != null and primary_view != null, "Live mission exposes tactical controller, combat loop, SimulationRoot and Primary3DView")
	if controller == null or combat_driver == null or simulation_root == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(_legacy_readability_overlays_are_hidden(scene), "2.5D mission suppresses legacy free-floating 2D readability overlays")
	await _wait_frames(6)
	_assert(_primary_dropship_visible(primary_view), "Waiting mission dropship is visible in the 2.5D primary view")

	var objective_position := _get_objective_position(simulation_root, Vector2(448.0, 285.0))
	var lz_position := objective_position
	_assert(_place_lz_via_player_path(controller, primary_view, lz_position), "Player LZ path places the LZ through the 2.5D picking path")
	controller.call("_on_call_dropship_pressed")
	await _wait_frames(2)
	await _drive_drop_until_outbound(controller)
	_assert(String(controller.get("_drop_sequence_phase")) == "outbound", "Dropship deploys the selected fireteam and enters outbound state")
	await _wait_frames(4)
	await _wait_physics_frames(2)
	controller.call("refresh_fireteam_security_state")
	var post_drop_profile: Dictionary = Dictionary(controller.call("get_active_behavior_profile", "blue"))
	var post_drop_security: Dictionary = _get_fireteam_security_state(controller, "blue")
	_assert(String(Dictionary(post_drop_profile.get("metadata", {})).get("origin", "")) == "post_drop_360_security", "Dropped fireteam receives the post-drop security behavior profile")
	_assert(String(post_drop_security.get("security_mode", "")) == "360", "Dropped fireteam automatically takes 360 security")
	_assert(_primary_snapshot_bool(primary_view, "has_lz") and _primary_dropship_visible(primary_view), "2.5D primary view keeps LZ and outbound dropship visible")
	_assert(int(Dictionary(primary_view.call("get_render_snapshot")).get("lz_tile_marker_count", 0)) == 1, "2.5D primary view shows the LZ as a terrain field marker")

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var move_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-64.0, -32.0)))
	controller.call("_set_waypoint_command_for_targets", move_refs, "move")
	var defend_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-32.0, -9.0)))
	controller.call("_set_waypoint_command_for_targets", defend_refs, "defend")
	var take_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position))
	controller.call("_set_waypoint_command_for_targets", take_refs, "take")
	var attack_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", objective_position + Vector2(-96.0, -90.0), objective_position + Vector2(96.0, -24.0), "engage"))
	var defend_area_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", objective_position + Vector2(-64.0, -24.0), objective_position + Vector2(64.0, 72.0), "defend"))
	await _wait_frames(4)
	var order_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(move_refs.size() == 1 and defend_refs.size() == 1 and take_refs.size() == 1, "Move, Defend and Take waypoints can be authored for the deployed fireteam")
	_assert(attack_refs.size() == 1 and defend_area_refs.size() == 1, "Attack and Defend Area Orders can be authored for the deployed fireteam")
	_assert(int(order_snapshot.get("waypoint_visual_count", 0)) >= 3, "2.5D primary view visualizes Move/Defend/Take waypoints")
	_assert(int(order_snapshot.get("waypoint_tile_marker_count", 0)) >= 3, "2.5D primary view visualizes Move/Defend/Take as terrain field markers")
	_assert(int(order_snapshot.get("area_order_count", 0)) >= 2, "2.5D primary view visualizes Attack/Defend Area Orders")
	_assert(int(order_snapshot.get("area_order_tile_marker_count", 0)) >= 2, "2.5D primary view visualizes Attack/Defend Areas as terrain field markers")

	_force_contact(controller, combat_driver)
	await _wait_frames(8)
	_assert(int(Dictionary(primary_view.call("get_render_snapshot")).get("contact_count", 0)) > 0, "2.5D primary view mirrors live contact markers")

	_position_friendlies_on_objective(controller, objective_position)
	_move_enemies_away(controller)
	await _wait_physics_frames(128)
	await _wait_frames(24)
	var objective_status = simulation_root.call("get_objective_status")
	var mission_result: Dictionary = Dictionary(combat_driver.call("get_mission_result"))
	var final_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(objective_status != null and float(objective_status.capture_progress) >= 1.0 and String(objective_status.owning_team_id) == "team_alpha", "Friendly fireteam can capture the objective to completion")
	_assert(String(mission_result.get("result", "")) == "victory" and String(mission_result.get("win_condition_type", "")) == "objective_capture", "Objective capture resolves the mission as a victory")
	_assert(bool(final_snapshot.get("objective_status_visible", false)), "2.5D primary view shows objective capture status")
	_assert(bool(final_snapshot.get("mission_result_visible", false)), "2.5D primary view shows mission victory/defeat result")
	_assert(int(final_snapshot.get("unit_status_badge_count", 0)) > 0, "2.5D unit proxies expose compact tactical state badges")
	_assert(_legacy_readability_overlays_are_hidden(scene), "Legacy 2D combat/objective/wave overlays stay hidden after live resolution")

	scene.queue_free()
	await _wait_frames(2)


func _configure_scene_for_blue_drop(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
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
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _stage_waiting_dropship(controller: Node) -> void:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = "task_160_dropship"
	planning_state["mission_drop_display_name"] = "TASK 160 Dropship"
	planning_state["mission_drop_title_text"] = "TASK 160 Dropship"
	planning_state["mission_drop_texture_path"] = "res://Assets/kenney_space-kit/Side/craft_speederB.png"
	planning_state["mission_drop_status_line"] = "Holding on mission map"
	planning_state["mission_drop_progress"] = 100.0
	planning_state["mission_drop_passenger_count"] = 4
	planning_state["selected_fireteam"] = "BLUE"
	planning_state["selected_fireteams"] = ["blue"]
	planning_state["embarked_unit_ids"] = ["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"]
	planning_state["deployed_unit_ids"] = []
	planning_state["drop_ship_requested"] = false
	planning_state["drop_ship_staged"] = false
	planning_state["has_lz_position"] = false
	controller.call("set_planning_state", planning_state)


func _place_lz_via_player_path(controller: Node, primary_view: Node, world_position: Vector2) -> bool:
	controller.call("_on_set_lz_pressed")
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", world_position) if primary_view != null and primary_view.has_method("world_to_screen_position") else controller.get_viewport().get_canvas_transform() * world_position
	return bool(controller.call("_place_lz_from_screen_position", screen_position))


func _drive_drop_until_outbound(controller: Node) -> void:
	for _step in range(96):
		controller.call("_update_drop_sequence", 0.25)
		await physics_frame
		await process_frame
		if String(controller.get("_drop_sequence_phase")) == "outbound":
			return


func _force_contact(controller: Node, combat_driver: Node) -> void:
	var friendly_units: Array = Array(controller.call("_get_all_friendly_units", false))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return
	var friendly = friendly_units[0]
	var enemy = enemy_units[0]
	if friendly is Node2D and enemy is Node2D:
		(enemy as Node2D).visible = true
		(enemy as Node2D).global_position = (friendly as Node2D).global_position + Vector2(54.0, 0.0)
	combat_driver.call("_update_contact_tracking")
	combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")
	controller.call("refresh_contact_overlay")


func _position_friendlies_on_objective(controller: Node, objective_position: Vector2) -> void:
	var friendly_units: Array = Array(controller.call("_get_all_friendly_units", false))
	for index in range(friendly_units.size()):
		var friendly = friendly_units[index]
		if friendly is Node2D:
			(friendly as Node2D).global_position = objective_position + Vector2(10.0 * float(index), 0.0)


func _move_enemies_away(controller: Node) -> void:
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	for index in range(enemy_units.size()):
		var enemy = enemy_units[index]
		if enemy is Node2D:
			(enemy as Node2D).global_position = Vector2(760.0 + 60.0 * float(index), 140.0)


func _get_objective_position(simulation_root: Node, fallback: Vector2) -> Vector2:
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return fallback
	var objective_status = simulation_root.call("get_objective_status")
	if objective_status == null:
		return fallback
	return Vector2(objective_status.position)


func _legacy_readability_overlays_are_hidden(scene: Node) -> bool:
	for node_path in ["StatusLabel", "CombatContactLine", "CombatEventLabel", "CombatWinnerLabel", "WaveStatusLabel"]:
		var node := scene.get_node_or_null(node_path)
		if node is CanvasItem and (node as CanvasItem).visible:
			return false
	var objective_label := scene.get_node_or_null("ObjectiveStatusView/ObjectiveStatusLabel") as CanvasItem
	return objective_label == null or not objective_label.visible


func _primary_snapshot_bool(primary_view: Node, key: String) -> bool:
	if primary_view == null or not primary_view.has_method("get_render_snapshot"):
		return false
	return bool(Dictionary(primary_view.call("get_render_snapshot")).get(key, false))


func _primary_dropship_visible(primary_view: Node) -> bool:
	if primary_view == null or not primary_view.has_method("get_render_snapshot"):
		return false
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	return bool(snapshot.get("dropship_model_visible", false)) or bool(snapshot.get("dropship_texture_visible", false))


func _get_fireteam_security_state(controller: Node, fireteam_id: String) -> Dictionary:
	for state_variant in Array(controller.call("get_fireteam_security_snapshot")):
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if String(state.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			return state
	return {}


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	print("FAIL: %s" % message)
