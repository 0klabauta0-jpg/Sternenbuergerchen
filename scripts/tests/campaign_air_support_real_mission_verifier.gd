extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Background probe: actual campaign route, crew, mission and card buttons.

func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if "--orbit-opt-in" in OS.get_cmdline_user_args(): _runtime.set("_surface_orbit_path_enabled", true)
	if not await _prepare_initial_base(): await _finish(); return
	var craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
	var payload: Array = craft.get("payload_fireteam_ids", [])
	if not _check(not _craft_id.is_empty() and not payload.is_empty(), "actual craft and team are available"): await _finish(); return
	_team_id = String(payload[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
		if String(team.get("id", "")) == _team_id:
			for member: Dictionary in Array(team.get("members", [])): _crew_ids.append(String(member.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery", "request_id":"air-probe:accept"}).get("ok", false), "regular mission accepted"): await _finish(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery", "request_id":"air-probe:destination"}).get("ok", false), "regular destination selected"): await _finish(); return
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var root_owner: Node = mission.get_node("SimulationRoot")
	var checkpoint: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
	_check(not checkpoint.get("ok", false), "campaign checkpoint is rejected during real deployed mission")
	var before: Dictionary = _runtime.get("_travel").get_flight_state(_craft_id).get_snapshot()
	controller.call("_refresh_mission_dropship_panel")
	var details: Button = mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton")
	if not _check(details != null and not details.disabled, "actual dropship details control is available"): await _finish(); return
	details.pressed.emit()
	await process_frame
	var pilot_button: Button = _air_button(mission, "air_pilot_board")
	if not _check(pilot_button != null and pilot_button.is_visible_in_tree() and not pilot_button.disabled, "actual pilot boarding button available"): await _finish(); return
	pilot_button.pressed.emit()
	if not await _wait(func(): return controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false), 8000, "actual pilot completes boarding"): await _finish(); return
	var leader: Node = controller.call("_get_campaign_sortie_unit", "campaign_leader")
	if not _check(is_instance_valid(leader) and not bool(leader.get_meta("dropship_embarked", true)), "ground team remains deployed while pilot boards"): await _finish(); return
	var start_button: Button
	for candidate in mission.find_children("*", "Button", true, false):
		if candidate.get_meta("mission_dropship_card_command", "") == "air_start" and candidate.get_meta("mission_dropship_craft_id", "") == _craft_id:
			start_button = candidate
			break
	var popup: PopupPanel = mission.get_node_or_null("TacticalUI/A5DropshipDetailsPopup")
	print("AIR_PROBE_UI button=", start_button, " popup_visible=", popup.visible if popup != null else false, " tactical_visible=", controller.get("_tactical_ui_visible"), " source=", root_owner.get("_air_support_source"))
	var panel: Node = mission.get_node_or_null("TacticalUI/A5DropshipDetailsPopup/Contents/Scroll/A5DropshipFullPanel")
	print("AIR_PROBE_UI_PANEL children=", panel.get_child_count() if panel != null else -1, " cards=", controller.call("_get_mission_dropship_card_entries"), " location=", mission.get_meta("location_id", ""))
	if not _check(start_button != null and not start_button.disabled and start_button.is_visible_in_tree(), "real air-start button is visible and enabled"): await _finish(); return
	start_button.pressed.emit()
	var airborne: bool = root_owner.call("is_air_support_craft_airborne", _craft_id)
	_check(airborne, "actual dropship card starts the fleet flight")
	print("AIR_PROBE_START airborne=", airborne, " feedback=", controller.get("_last_command_text"), " before=", before)
	if not airborne: await _finish(); return
	var radar_button: Button = _air_button(mission, "air_radar")
	if not _check(radar_button != null and radar_button.is_visible_in_tree() and not radar_button.disabled, "actual air radar control available"): await _finish(); return
	radar_button.pressed.emit()
	_check(String(controller.get("_last_command_text")) == "Luftradar: keine Kontakte", "air radar reports no aircraft in the regular mission")
	var flight: RefCounted = _runtime.get("_travel").get_flight_state(_craft_id)
	var origin: Vector2 = flight.get_snapshot().position_plane
	var terrain: Node = controller.call("_get_terrain_registry")
	var landed: Vector2 = controller.call("_campaign_landed_craft_position", _craft_id)
	var origin_grid: Vector2i = terrain.call("world_to_grid", landed)
	var next_grid := origin_grid + Vector2i(1, 0)
	var view: Node = mission.get_node("Primary3DView")
	var next_world: Vector2 = terrain.call("grid_to_world", next_grid)
	view.call("focus_world_position", next_world)
	if not _check(controller.call("_select_tile_from_screen_position", view.call("world_to_screen_position", next_world)), "actual map selection chooses flight target"): await _finish(); return
	print("AIR_MOVE_SELECTION desired=", next_grid, " selected=", controller.call("get_selected_tile_snapshot"))
	var move_button: Button = _air_button(mission, "air_move")
	if not _check(move_button != null and move_button.is_visible_in_tree() and not move_button.disabled, "actual flight button available"): await _finish(); return
	move_button.pressed.emit()
	if not await _wait(func(): return flight.get_snapshot().position_plane.distance_to(origin) > 0.15, 15000, "actual flight moves away from landed position"):
		var source: Node = root_owner.get("_air_support_source").get_ref()
		print("AIR_MOVE_FEEDBACK ", controller.get("_last_command_text"), " selected=", controller.call("get_selected_tile_snapshot"), " origin_grid=", origin_grid, " pose=", flight.get_snapshot(), " flight_status=", source.call("get_space_flight_status", _craft_id), " controls=", source.get("_space_combat_state").get_flight_controls(), " source_tick=", source.get("tick_counter"), " physics=", source.is_physics_processing()); await _finish(); return
	view.call("focus_world_position", landed)
	if not _check(controller.call("_select_tile_from_screen_position", view.call("world_to_screen_position", landed)), "actual map selection chooses return position"): await _finish(); return
	move_button = _air_button(mission, "air_move")
	if not _check(move_button != null, "actual return flight button available"): await _finish(); return
	move_button.pressed.emit()
	if not await _wait(func(): return flight.get_snapshot().position_plane.distance_to(origin) < 0.14 and flight.get_snapshot().velocity_plane.length() < 0.1, 20000, "actual flight returns and brakes"):
		print("AIR_RETURN_FEEDBACK ", controller.get("_last_command_text")); await _finish(); return
	var land_button: Button = _air_button(mission, "air_land")
	if not _check(land_button != null and land_button.is_visible_in_tree(), "actual landing button available"): await _finish(); return
	land_button.pressed.emit()
	_check(not root_owner.call("is_air_support_craft_airborne", _craft_id) and controller.call("_is_parked_campaign_dropship", _craft_id), "actual landing restores parked transport")
	print("AIR_LANDING_FEEDBACK ", controller.get("_last_command_text"))
	var boarded: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	if not _check(boarded.get("ok", false) or boarded.get("reason") == "pilot_boarding_pending", "actual ground team begins boarding after landing"): await _finish(); return
	if not await _wait(func(): return controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false), 8000, "actual crew completes boarding after air sortie"): await _finish(); return
	await _finish()

func _air_button(mission: Node, action: String) -> Button:
	for candidate in mission.find_children("*", "Button", true, false):
		if candidate.get_meta("mission_dropship_card_command", "") == action and candidate.get_meta("mission_dropship_craft_id", "") == _craft_id: return candidate
	return null

func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	if label.ends_with("actual mission instance exists"):
		# The actual coupled Cutlass now crosses the 256-row orbit on normal ticks.
		var diagnostic := "--orbit-diagnostic" in OS.get_cmdline_user_args()
		var deadline := Time.get_ticks_msec() + (25000 if diagnostic else maxi(milliseconds, 180000))
		var source: Node = _runtime.get("_simulation")
		var flight: RefCounted = _runtime.get("_travel").get_flight_state(_craft_id)
		var beginning: Dictionary = flight.get_snapshot()
		var start_tick: int = source.tick_counter
		var report_at := Time.get_ticks_msec() + 25000
		var reported := false
		while Time.get_ticks_msec() < deadline:
			var mission: Node = _flow.call("get_mission_for_craft", _craft_id)
			if is_instance_valid(mission):
				_flow.call("focus_location", String(mission.get_meta("location_id", "")))
				return _check(true, label)
			if not reported and Time.get_ticks_msec() >= report_at:
				reported = true
				print("ORBIT_REAL_MIDPOINT ", {"start_tick":start_tick,"end_tick":source.tick_counter,"start_pose":beginning,"end_pose":flight.get_snapshot(),"flight_status":source.get_space_flight_status(_craft_id),"intent":_runtime.get("_surface_orbit_intents")})
			await physics_frame
		print("ORBIT_REAL_PROGRESS ", {"start_tick":start_tick,"end_tick":source.tick_counter,"travel":_space(),"start_pose":beginning,"end_pose":flight.get_snapshot(),"flight_status":source.get_space_flight_status(_craft_id),"controls":source.get("_space_combat_state").get_flight_controls(),"intent":_runtime.get("_surface_orbit_intents"),"physics":source.is_physics_processing()})
		return _check(false, "TIMEOUT " + label)
	return await super._wait(predicate, milliseconds, label)

func _dump(stage: String) -> void:
	print("AIR_PROBE_DIAGNOSTIC ", stage, " locations=", _flow.call("get_location_runtime_snapshot"), " approach=", _flow.get("_space_approaches"), " view=", _flow.get("_current_meta_view"))

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("CAMPAIGN_AIR_SUPPORT_REAL passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
