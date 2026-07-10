extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const FRIENDLY_IDS: PackedStringArray = ["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"]

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== FRONTIER PROBE 192x192 PLAYTEST PERFORMANCE ===")
	root.size = Vector2i(1920, 1080)
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", LARGE_MAP_PATH)
	_check(map_data != null and not bool(map_data.call("has_load_issue")), "Large frontier map loads without issue")
	if map_data == null:
		_finish()
		return

	var scene_started_usec: int = Time.get_ticks_usec()
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"))
	root.add_child(scene)
	await _wait_frames(24)
	await _wait_physics_frames(6)
	var scene_ready_msec: int = int((Time.get_ticks_usec() - scene_started_usec) / 1000)

	var controller := scene.get_node_or_null("TacticalController")
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_check(controller != null and combat_driver != null and simulation_root != null and primary_view != null, "Mission scene exposes tactical spine")
	if controller == null or combat_driver == null or simulation_root == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		_finish()
		return

	var initial_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_print_snapshot("initial", scene_ready_msec, initial_snapshot)
	_check(int(initial_snapshot.get("total_tile_count", 0)) == 36864, "Initial view has full 192x192 map truth")
	_check(bool(initial_snapshot.get("visual_streaming_active", false)), "Initial view uses visual streaming")
	_check(int(initial_snapshot.get("rendered_tile_count", 0)) < int(initial_snapshot.get("total_tile_count", 0)), "Initial render does not draw the full map")
	_check(int(initial_snapshot.get("map_render_duration_msec", 999999)) < 2500, "Initial render duration stays below 2500 ms smoke budget")

	await _exercise_streaming_camera(primary_view, map_data)

	var objective_position := _get_objective_position(simulation_root, Vector2(4672.0, 6208.0))
	primary_view.call("focus_world_position", objective_position)
	await _wait_frames(6)
	_check(_place_lz_via_player_path(controller, primary_view, objective_position), "Player path places LZ on the large map")
	controller.call("_on_call_dropship_pressed")
	await _wait_frames(2)
	await _drive_drop_until_outbound(controller)
	_check(String(controller.get("_drop_sequence_phase")) == "outbound", "Dropship deploys and enters outbound state")
	if String(controller.get("_drop_sequence_phase")) != "outbound":
		var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		print("[PLAYTEST][drop_debug] phase=%s drop_state=%s requested=%s staged=%s has_lz=%s deployed=%s embarked=%s" % [
			String(controller.get("_drop_sequence_phase")),
			String(planning_state.get("mission_drop_state", "")),
			str(planning_state.get("drop_ship_requested", "")),
			str(planning_state.get("drop_ship_staged", "")),
			str(planning_state.get("has_lz_position", "")),
			str(planning_state.get("deployed_unit_ids", [])),
			str(planning_state.get("embarked_unit_ids", [])),
		])
	await _wait_frames(8)
	await _wait_physics_frames(4)
	controller.call("refresh_fireteam_security_state")
	var drop_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_print_snapshot("post_drop", -1, drop_snapshot)
	_check(bool(drop_snapshot.get("has_lz", false)), "LZ remains visible after drop")
	_check(int(drop_snapshot.get("lz_tile_marker_count", 0)) == 1, "LZ terrain marker count stays stable")
	_check(_active_fireteam_is_ready(controller, "blue"), "Dropped fireteam is active and in 360 security")

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var move_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-64.0, -32.0)))
	controller.call("_set_waypoint_command_for_targets", move_refs, "move")
	var defend_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-32.0, -9.0)))
	controller.call("_set_waypoint_command_for_targets", defend_refs, "defend")
	var take_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position))
	controller.call("_set_waypoint_command_for_targets", take_refs, "take")
	var attack_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", objective_position + Vector2(-96.0, -90.0), objective_position + Vector2(96.0, -24.0), "engage"))
	var defend_area_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", objective_position + Vector2(-64.0, -24.0), objective_position + Vector2(64.0, 72.0), "defend"))
	await _wait_frames(6)
	var order_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_print_snapshot("orders", -1, order_snapshot)
	_check(move_refs.size() == 1 and defend_refs.size() == 1 and take_refs.size() == 1, "Move, Defend and Take waypoints author on large map")
	_check(attack_refs.size() == 1 and defend_area_refs.size() == 1, "Area orders author on large map")
	_check(int(order_snapshot.get("waypoint_tile_marker_count", 0)) >= 3, "Waypoint terrain markers render")
	_check(int(order_snapshot.get("area_order_tile_marker_count", 0)) >= 2, "Area order terrain markers render")

	_force_contact(controller, combat_driver)
	await _wait_frames(10)
	var contact_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_print_snapshot("contact", -1, contact_snapshot)
	_check(int(contact_snapshot.get("contact_count", 0)) > 0, "Live contact markers appear")

	_position_friendlies_on_objective(controller, objective_position)
	_move_enemies_away(controller)
	await _wait_physics_frames(128)
	await _wait_frames(24)
	var objective_status = simulation_root.call("get_objective_status")
	var mission_result: Dictionary = Dictionary(combat_driver.call("get_mission_result"))
	var final_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_print_snapshot("final", -1, final_snapshot)
	_check(objective_status != null and float(objective_status.capture_progress) >= 1.0 and String(objective_status.owning_team_id) == "team_alpha", "Friendly fireteam captures the objective")
	_check(String(mission_result.get("result", "")) == "victory", "Mission resolves as victory")
	_check(bool(final_snapshot.get("mission_result_visible", false)), "Mission result is visible")
	_check(not bool(final_snapshot.get("world_label_declutter_active", true)), "Mission victory releases firefight world-label declutter")
	_check(int(final_snapshot.get("unit_status_badge_count", 0)) > 0, "Unit tactical badges remain visible")
	_check(int(final_snapshot.get("rendered_tile_count", 0)) < int(final_snapshot.get("total_tile_count", 0)), "Final view still uses chunked rendering")

	scene.queue_free()
	await _wait_frames(2)
	_finish()


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", "")
		mission_setup.set("defer_friendly_runtime_activation", true)
		mission_setup.set("allow_full_roster_when_selection_empty", false)
		mission_setup.set("selected_team_unit_ids", FRIENDLY_IDS)
		mission_setup.set("selected_team_fireteam_ids", PackedStringArray(["blue", "blue", "blue", "blue"]))
		mission_setup.set("selected_fireteam_definitions", [{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}])
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _stage_waiting_dropship(controller: Node) -> void:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = "frontier_probe_playtest_dropship"
	planning_state["mission_drop_display_name"] = "Frontier Probe Dropship"
	planning_state["mission_drop_title_text"] = "Frontier Probe Dropship"
	planning_state["mission_drop_texture_path"] = "res://Assets/kenney_space-kit/Side/craft_speederB.png"
	planning_state["mission_drop_status_line"] = "Holding off-map"
	planning_state["mission_drop_progress"] = 100.0
	planning_state["mission_drop_passenger_count"] = FRIENDLY_IDS.size()
	planning_state["selected_fireteam"] = "BLUE"
	planning_state["selected_fireteams"] = ["blue"]
	planning_state["embarked_unit_ids"] = Array(FRIENDLY_IDS)
	planning_state["deployed_unit_ids"] = []
	planning_state["drop_ship_requested"] = false
	planning_state["drop_ship_staged"] = false
	planning_state["has_lz_position"] = false
	controller.call("set_planning_state", planning_state)


func _exercise_streaming_camera(primary_view: Node, map_data) -> void:
	var focus_grids: Array[Vector2i] = [Vector2i(24, 24), Vector2i(96, 96), Vector2i(168, 34), Vector2i(34, 168)]
	for grid in focus_grids:
		var focus_position: Vector2 = _world_at_grid(map_data, grid)
		primary_view.call("focus_world_position", focus_position)
		await _wait_frames(4)
		var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		_print_snapshot("focus_%d_%d" % [grid.x, grid.y], -1, snapshot)
		_check(bool(snapshot.get("visual_streaming_active", false)), "Streaming remains active after camera focus %s" % [grid])
		_check(int(snapshot.get("rendered_tile_count", 0)) < int(snapshot.get("total_tile_count", 0)), "Camera focus %s stays chunked" % [grid])


func _place_lz_via_player_path(controller: Node, primary_view: Node, world_position: Vector2) -> bool:
	controller.call("_on_set_lz_pressed")
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", world_position)
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
			(enemy as Node2D).global_position = Vector2(9000.0 + 60.0 * float(index), 9000.0)


func _active_fireteam_is_ready(controller: Node, fireteam_id: String) -> bool:
	var profile: Dictionary = Dictionary(controller.call("get_active_behavior_profile", fireteam_id))
	var metadata: Dictionary = Dictionary(profile.get("metadata", {}))
	for state_variant in Array(controller.call("get_fireteam_security_snapshot")):
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if String(state.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return String(state.get("security_mode", "")) == "360" and String(metadata.get("origin", "")) == "post_drop_360_security"
	return false


func _get_objective_position(simulation_root: Node, fallback: Vector2) -> Vector2:
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return fallback
	var objective_status = simulation_root.call("get_objective_status")
	if objective_status == null:
		return fallback
	return Vector2(objective_status.position)


func _world_at_grid(map_data, grid: Vector2i) -> Vector2:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return Vector2(tile_data.world_position) if tile_data != null else Vector2.ZERO


func _print_snapshot(label: String, scene_ready_msec: int, snapshot: Dictionary) -> void:
	var prefix: String = "[PLAYTEST][%s]" % label
	var fields: Array[String] = [
		"total=%d" % int(snapshot.get("total_tile_count", 0)),
		"rendered=%d" % int(snapshot.get("rendered_tile_count", 0)),
		"skipped=%d" % int(snapshot.get("visual_streaming_skipped_tile_count", 0)),
		"chunks=%d" % int(snapshot.get("visual_streaming_active_chunk_count", 0)),
		"refresh=%d" % int(snapshot.get("visual_streaming_refresh_count", 0)),
		"render_ms=%d" % int(snapshot.get("map_render_duration_msec", -1)),
		"assets=%d" % int(snapshot.get("asset_model_count", 0)),
		"nodes=%d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	]
	if scene_ready_msec >= 0:
		fields.append("scene_ready_ms=%d" % scene_ready_msec)
	print("%s %s" % [prefix, " ".join(fields)])


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	print("FAIL: %s" % message)


func _finish() -> void:
	print("=== FRONTIER PLAYTEST RESULT: %s ===" % ("FAIL" if _failed > 0 else "PASS"))
	quit(1 if _failed > 0 else 0)
