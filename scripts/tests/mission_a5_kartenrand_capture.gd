extends "res://scripts/tests/frontier_main_startup_verifier.gd"
## Same real normal-start route. Edge movement adds real commands only after GO.
const QA_NAMESPACE := "SternenBuergerchen_Mission_A5_Edge_Normal_QA"
const HEX := preload("res://scripts/terrain/hex_grid.gd")
const EDGE_GRID := Vector2i(-8, 12) # Plane x=-2, z=10.3923; outside old x>=0.


func _initialize() -> void:
	var data_path := OS.get_user_data_dir()
	if data_path.replace("\\", "/").trim_suffix("/").get_file() != QA_NAMESPACE:
		push_error("A5 map-edge capture requires its exact isolated QA user-data directory.")
		quit(2)
		return
	_facts["ui_test_user_data_dir"] = data_path
	_facts["isolated_user_data"] = true
	super._initialize()


func _frames(count: int) -> void:
	await super._frames(count)
	if _finished:
		# This runs only after parent _finish has freed the actual game scene.
		await create_timer(0.35, true, false, true).timeout


func _visual_snapshot(view: Node) -> Dictionary:
	var snapshot := super._visual_snapshot(view)
	var render := _snapshot(view, "get_render_snapshot")
	for key in ["authored_visual_layout_id", "authored_visual_layout_active", "authored_visual_owned_tile_count", "authored_visual_assets", "hex_grid_visible", "hex_grid_edge_style", "hex_grid_width_world", "tile_grid_line_count", "fog_of_war_mode", "fow_overlay_tile_count", "fow_known_dim_tile_count", "fow_unknown_tile_count", "authored_ground_cell_count", "authored_ground_vertex_count", "authored_ground_plane_bounds", "ground_matches_saved_hex_coverage"]:
		if render.has(key):
			snapshot[key] = render[key]
	return snapshot


func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	var dimensions := _argument("--ui-size", "1920x1080").split("x")
	var requested := Vector2i(int(dimensions[0]), int(dimensions[1]))
	root.size = requested
	root.content_scale_size = requested
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if view != null:
		var waited := 0
		while bool(view.get("_fow_overlay_full_rebuild_pending")) and waited < 48:
			await _frames(1)
			waited += 1
		_check(not bool(view.get("_fow_overlay_full_rebuild_pending")), "Capture %s waits for the actual batched FoW overlay" % id)
		if not _facts.has("capture_fow_wait_frames"):
			_facts["capture_fow_wait_frames"] = {}
		_facts["capture_fow_wait_frames"][id] = waited
	await super._capture(id, view, settle_frames)
	if view != null and not _captures.is_empty():
		_captures.back()["render_observation"] = _visual_snapshot(view)
		var bounds := _snapshot(view, "get_map_visual_bounds_snapshot")
		_captures.back()["bounds_observation"] = _keep(bounds, ["grid_size", "cell_size", "footprint_min", "footprint_max", "outside_map_bounds_count", "read_only", "hotpath"])
	if id == "03_default_mission":
		await _capture_transport_details(view)
	elif id == "05_deployed":
		await _capture_character_details(view)
	if id != "06_go_movement" or view == null:
		return
	# Matched existing camera views; never write actors, fog or mission time.
	view.call("frame_world_positions", [Vector2(0, 192), Vector2(512, 1152), Vector2(-512, 768)], 8.0, 26.0, 32.0)
	await _capture("07_outpost_overview", view, 8)
	view.call("frame_world_positions", [Vector2(320, 1312), Vector2(704, 2400)], 8.0, 28.0, 36.0)
	await _capture("08_eastern_supply", view, 8)
	view.call("frame_world_positions", [Vector2.ZERO, Vector2(512, 2752)], 8.0, 48.0, 56.0)
	await _capture("09_expanded_map", view, 8)
	if requested.x == 1920:
		_frame_all_saved_hexes(view)
		await _capture("10_all_saved_hexes", view, 8)
	var mode := _argument("--edge-walk", "auto")
	var edge_requested := mode == "on" or (mode == "auto" and requested.x == 1920)
	_facts["edge_walk_probe"] = {"requested": edge_requested, "resolution": requested, "scope": "Additional physical movement after the original normal start; 1280 defaults to HUD-only normal route."}
	if edge_requested:
		await _walk_old_western_edge(view)


func _active_capture_mission(view: Node) -> Node:
	# Normal menu flow keeps MetaLayerFlow as current_scene; the mission is its
	# active child, as in the parent verifier's public get_active_mission path.
	if current_scene == null or not current_scene.has_method("get_active_mission"):
		return null
	var mission: Node = current_scene.call("get_active_mission")
	return mission if mission != null and view != null and view.get_parent() == mission else null


func _capture_transport_details(view: Node) -> void:
	var mission := _active_capture_mission(view)
	var details := mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton") as Button if mission != null else null
	if not _check(details != null and details.is_visible_in_tree() and not details.disabled, "Actual compact dropship exposes its native Details button"):
		return
	details.pressed.emit()
	await _frames(3)
	var popup := mission.get_node_or_null("TacticalUI/A5DropshipDetailsPopup") as PopupPanel
	var opened := popup != null and popup.visible and not paused
	_check(opened, "Actual dropship Details callback opens its complete native popup without pausing")
	_facts["transport_details_capture"] = {"opened": opened, "input_path": "existing DetailsButton.pressed", "paused": paused}
	if not opened:
		return
	await _capture("03b_dropship_details", view, 3)
	var close := popup.get_node_or_null("Contents/CloseButton") as Button
	if not _check(close != null, "Transport details retain their real native close button"):
		return
	close.pressed.emit()
	await _frames(2)
	_check(not popup.visible, "Native close restores the normal mission route before Drop")


func _capture_character_details(view: Node) -> void:
	var mission := _active_capture_mission(view)
	var cards := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") if mission != null else null
	var portrait: Control = null
	if cards != null:
		for card in cards.get_children():
			var strip := card.get_node_or_null("Margin/VBox/FireteamMemberPortraitStrip")
			if strip == null:
				continue
			for candidate in strip.get_children():
				if candidate is TextureRect and not String(candidate.get_meta("mission_member_unit_id", "")).is_empty():
					portrait = candidate
					break
			if portrait != null:
				break
	if not _check(portrait != null and portrait.is_visible_in_tree(), "Deployed team card exposes an actual member portrait"):
		return
	var unit_id := String(portrait.get_meta("mission_member_unit_id", ""))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.double_click = true
	click.position = portrait.size * 0.5
	click.global_position = portrait.get_global_rect().get_center()
	portrait.gui_input.emit(click)
	await _frames(3)
	var overlay := mission.get_node_or_null("TacticalUI/CharacterOverlay") as Control
	var controller := mission.get_node_or_null("TacticalController")
	var opened := overlay != null and controller != null and overlay.visible and String(controller.get("_character_overlay_unit_id")) == unit_id and not paused
	_check(opened, "Actual portrait double-click opens the original unit's existing character sheet without pausing")
	_facts["character_details_capture"] = {"opened": opened, "unit_id": unit_id, "input_path": "existing portrait gui_input double_click signal", "paused": paused}
	if not opened:
		return
	await _capture("05b_character_details", view, 3)
	controller.call("_close_character_overlay")
	await _frames(2)
	_check(not overlay.visible, "Existing close restores the mission before the normal Move/GO")


func _frame_all_saved_hexes(view: Node) -> void:
	var mission := _active_capture_mission(view)
	var registry := mission.get_node_or_null("TerrainRegistry") if mission != null else null
	if registry == null:
		return
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	var count := 0
	for tile in registry.call("get_all_tiles"):
		var plane := HEX.axial_to_plane(Vector2(tile.grid_position))
		minimum = minimum.min(plane)
		maximum = maximum.max(plane)
		count += 1
	if not _check(count > 0, "Full-map camera reads actual saved Hex cells"):
		return
	var world_corners: Array = []
	for point in [minimum, Vector2(maximum.x, minimum.y), maximum, Vector2(minimum.x, maximum.y)]:
		var plane: Vector2 = point
		world_corners.append(Vector2((plane.x - plane.y) * 64.0, (plane.x + plane.y) * 32.0))
	_facts["full_map_camera"] = {"saved_cell_count": count, "minimum_plane_center": minimum, "maximum_plane_center": maximum, "camera_only": true}
	view.call("frame_world_positions", world_corners, 6.0, 90.0, 110.0)


func _plane_positions(mission: Node, ids: Array) -> Dictionary:
	var result := {}
	var actual := _positions(mission, ids)
	for id in actual:
		var world: Vector2 = actual[id]
		# Existing64/32 isometric projection, inverted without rounding positions.
		result[id] = Vector2((world.x / 64.0 + world.y / 32.0) * 0.5, (world.y / 32.0 - world.x / 64.0) * 0.5)
	return result


func _walk_old_western_edge(view: Node) -> void:
	var mission := _active_capture_mission(view)
	if not _check(mission != null, "Edge walk resolves the actual active mission through MetaFlow"):
		return
	var controller := mission.get_node_or_null("TacticalController")
	var registry := mission.get_node_or_null("TerrainRegistry")
	if not _check(controller != null and registry != null, "Edge walk uses actual mission controller and terrain registry"):
		return
	var probe: Dictionary = _facts["edge_walk_probe"]
	probe["target_grid"] = EDGE_GRID
	probe["target_plane"] = HEX.axial_to_plane(Vector2(EDGE_GRID))
	probe["old_western_boundary_plane_x"] = 0.0
	probe["walkable_target"] = bool(registry.call("is_walkable", EDGE_GRID))
	if not _check(bool(probe["walkable_target"]), "Edge walk target is a real saved walkable Hex beyond the old boundary"):
		return
	var ids: Array = _planning_snapshot(controller).get("deployed_unit_ids", [])
	probe["original_deployed_ids"] = ids.duplicate()
	probe["success_rule"] = "All original deployed IDs remain observed; at least two positions west of x=-0.05; one within2 plane units of saved target; fixed criterion with no missing-ID relaxation, bounded by60 wall seconds."
	probe["maximum_observation_wall_seconds"] = 60.0
	probe["before_world_positions"] = _positions(mission, ids)
	probe["before_plane_positions"] = _plane_positions(mission, ids)
	var simulation := mission.get_node_or_null("SimulationRoot")
	probe["simulation_tick_before"] = simulation.call("get_tick") if simulation != null else -1
	var target_world: Vector2 = view.call("grid_to_world_position", EDGE_GRID)
	probe["target_world"] = target_world
	view.call("frame_world_positions", [target_world, Vector2(0, 192), Vector2(-512, 768)], 8.0, 18.0, 28.0)
	if not _check(bool(controller.call("issue_right_click_command_for_test", target_world, "move", false)), "Existing Move accepts a target beyond the former map border"):
		return
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Existing GO commits the real border-crossing plan"):
		return
	# Only the additional probe receives this own deadline. Original transfer,
	# deployment and initial GO deadlines have already passed unchanged.
	_deadline = maxi(_deadline, Time.get_ticks_msec() + 60000)
	var started := Time.get_ticks_msec()
	probe["passed"] = await _wait_until("at least two real deployed units crossing the old west boundary", func() -> bool:
		var positions := _plane_positions(mission, ids)
		if positions.size() != ids.size():
			return false
		var west := 0
		var arrived := false
		for value in positions.values():
			var plane: Vector2 = value
			if plane.x < -0.05:
				west += 1
			arrived = arrived or plane.distance_to(Vector2(probe["target_plane"])) <= 2.0
		return west >= 2 and arrived
	, 60.0)
	probe["elapsed_wall_msec"] = Time.get_ticks_msec() - started
	probe["after_world_positions"] = _positions(mission, ids)
	probe["after_plane_positions"] = _plane_positions(mission, ids)
	probe["simulation_tick_after"] = simulation.call("get_tick") if simulation != null else -1
	probe["no_private_actor_or_timer_writes"] = true
	_check(bool(probe["passed"]), "Actual normal-time squad movement crosses the former border")
	_stage("edge_walk", probe.duplicate(true))
	await _capture("11_old_border_crossed", view, 8)
