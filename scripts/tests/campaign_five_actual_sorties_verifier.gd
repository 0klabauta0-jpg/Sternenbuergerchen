extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Actual chapter sorties through the regular travel and tactical owners.
const RAMP_HEX = preload("res://scripts/terrain/hex_grid.gd")
const REGIONAL_PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
var _return_orbit: String = ""

func _run() -> void:
	Engine.time_scale = 1.0 if OS.get_cmdline_user_args().has("1x") else 4.0
	print("CAMPAIGN_TEST_PROFILE ", ProjectSettings.globalize_path("user://"), " scale=", Engine.time_scale)
	var continuing := OS.get_cmdline_user_args().has("continue-chapter")
	START.request_start(self, "campaign", "continue" if continuing else "new")
	_flow=FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen=_flow.get_node("HomebaseScreen"); _runtime=_flow.get("_singleplayer_runtime")
	if not continuing and not await _prepare_initial_base(): await _finish(); return
	var operations: Dictionary=_screen.call("get_operations_snapshot")
	var craft: Dictionary=operations.selected_craft
	_craft_id=String(craft.id); _pilot_id=String(craft.pilot_id)
	_team_id=String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id)==_team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	if continuing:
		if _check(String(_campaign().jobs.satellite_recovery.status) == "completed", "Continue resumes a completed first sortie"):
			await _remaining_missions()
		await _finish()
		return
	var before: Dictionary=_supply()
	_check(_screen.call("request_operation","accept_job",{"job_id":"satellite_recovery"}).get("ok",false),"first accepted")
	_check(_screen.call("request_operation","select_destination",{"location_id":"satellite_crash","job_id":"satellite_recovery"}).get("ok",false),"first destination selected")
	if not await _launch_and_land("satellite_recovery","res://maps/satellite_crash_site.json"): await _finish(); return
	if OS.get_cmdline_user_args().has("land-only"):
		await _finish()
		return
	var mission: Node=_flow.get("_active_mission")
	var controller: Node=mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
	if OS.get_cmdline_user_args().has("ramp-probe") and not await _verify_actual_ramp_walk(controller):
		await _finish()
		return
	if not await _move_and_use(mission,"satellite_data","secure_satellite","res://maps/satellite_crash_site.json"): await _finish(); return
	if not await _move_and_use(mission,"ship_return","return_to_ship","res://maps/satellite_crash_site.json"): await _finish(); return
	_check(await _wait(func(): return String(_campaign().jobs.satellite_recovery.status)=="pending_upload",10000,"real chip recovered awaits upload"),"pending status")
	_check(int(_supply().credits)==int(before.credits),"no reward before physical home upload")
	if not await _wait_homebase(): await _finish(); return
	_flow.call("_show_homebase")
	var result: Dictionary=_runtime.call("request_operation","campaign_upload",{"job_id":"satellite_recovery"})
	print("UPLOAD_RESULT ",result)
	_check(bool(result.get("ok",false)),"real home upload accepted")
	_check(String(_campaign().jobs.satellite_recovery.status)=="completed","upload completes first mission")
	_check(int(_supply().credits)==int(before.credits)+150,"one exact reward")
	var save:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime)
	print("SAVE_RESULT ",save.get("reason","ok"))
	_check(save.get("ok",false),"real home checkpoint saves new campaign")
	_check(STORE.load_checkpoint().get("ok",false),"new checkpoint loads")
	if not OS.get_cmdline_user_args().has("first-only"):
		await _remaining_missions()
	await _finish()

func _wait_homebase() -> bool:
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == _return_orbit, 35000, "Actual surface exit returns original craft to its location orbit"):
		_dump("return_to_planet_orbit")
		return false
	_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase", "Location orbit is not physical home arrival")
	var home_jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": "moon_orbit"})
	if not _check(bool(home_jump.get("ok", false)), "Real homeward target click begins moon quantum"):
		print("HOME_JUMP_RESULT:", home_jump)
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", 5000, "Real homeward quantum reaches moon orbit"):
		return false
	_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase", "Moon orbit still requires an explicit home landing")
	var home_land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
	if not _check(bool(home_land.get("ok", false)), "Explicit moonbase landing accepts after actual homeward travel"):
		print("HOME_LAND_RESULT:", home_land)
		_dump("moonbase_land")
		return false
	var ready: bool = await _wait(func():
		var current: Dictionary = _flow.call("get_singleplayer_snapshot")
		var craft: Dictionary = _craft(current)
		return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true)), 35000, "Actual reverse transit restores original craft to homebase")
	if not ready:
		_dump("homebase_return")
	return ready

func _remaining_missions() -> void:
	for spec in [["outpost_recovery","trade_outpost","res://maps/trade_outpost.json"],["benit_delivery","satellite_crash","res://maps/satellite_crash_site.json"],["outpost_chip_recovery","fortified_outpost","res://maps/fortified_outpost.json"]]:
		var job:String=spec[0]; var location:String=spec[1]; var map_path:String=spec[2]
		if String(_campaign().jobs[job].status)=="pending_upload":
			_check(_runtime.call("request_operation","campaign_upload",{"job_id":job}).get("ok",false),"resume verified pending upload")
		if String(_campaign().jobs[job].status)=="completed":continue
		print("CHAPTER_NEXT ",job)
		_flow.call("_show_homebase")
		var fuel:float=float(_supply().fuel_by_craft_id[_craft_id])
		var refuel:Dictionary=_runtime.call("request_operation","refuel",{"craft_id":_craft_id,"amount":100.0-fuel}) if fuel<100.0 else {"ok":true}
		_check(bool(refuel.get("ok",false)),"home refuel for "+job)
		var accepted:Dictionary=_runtime.call("request_operation","accept_job",{"job_id":job})
		if not _check(bool(accepted.get("ok",false)),"accept "+job): print(accepted);return
		_check(_runtime.call("request_operation","select_destination",{"location_id":location,"job_id":job}).get("ok",false),"select "+job)
		var measure_revisit := job == "benit_delivery" and OS.get_cmdline_user_args().has("native-perf-revisit")
		var previous_scale := Engine.time_scale
		if measure_revisit:
			Engine.time_scale = 1.0
		var landed := await _launch_and_land(job, map_path)
		Engine.time_scale = previous_scale
		if not landed:
			return
		var mission:Node=_flow.get("_active_mission")
		var controller:Node=mission.get_node("TacticalController")
		controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
		if job!="benit_delivery":
			controller.call("set_selected_fireteams_tactical_stance", "aggressive")
			_check(bool(controller.call("set_selected_fireteams_fire_rule","free")),"commander orders weapons free")
			var enemy_target:Vector2=MAP.load_from_file(map_path).get_marker_position("spawn_enemy_defense")
			controller.call("_create_waypoints_for_selected_fireteams",enemy_target,true)
			_check(bool(controller.call("execute_selected_fireteam_orders")),"approach actual outpost guard")
			if not await _wait(func():return PackedStringArray(mission.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids",[])).has("clear_outpost"),210000,"actual combat defeats outpost guards"):
				var sim: Node = mission.get_node_or_null("SimulationRoot")
				if sim != null:
					print("REGIONAL_TACTICAL_NAV ", sim.call("get_navigation_debug_snapshot"))
				_dump("outpost_combat")
				return
		if job=="outpost_recovery":
			if not await _move_and_use(mission,"recover_crate","recover_crate",map_path):return
			if not await _move_and_use(mission,"trade_service","trade_service",map_path):return
			var recruit:Dictionary=_runtime.call("request_operation","campaign_recruit",{"craft_id":_craft_id})
			if not _check(recruit.get("ok",false),"real trader recruit"):print(recruit);return
			_check(Array(_flow.get("_all_team_units")).size()==3,"third NPC joined")
		elif job=="benit_delivery":
			_check(String(mission.get_node("MissionSetup").get("scenario_file_path")).contains("benit_delivery"),"revisit uses new delivery scenario")
			if not await _move_and_use(mission,"trade_service","deliver_benit",map_path):return
		else:
			if not await _move_and_use(mission,"outpost_chip","secure_outpost_chip",map_path):return
		if not await _move_and_use(mission,"ship_return","return_to_ship",map_path):return
		if not await _wait_homebase():return
		_flow.call("_show_homebase")
		if job=="outpost_chip_recovery":
			var upload:Dictionary=_runtime.call("request_operation","campaign_upload",{"job_id":job})
			_check(upload.get("ok",false),"second actual chip uploaded")
		_check(String(_campaign().jobs[job].status)=="completed","real mission completed "+job)
		if not await _save_verified_milestone(job):return
	if String(_campaign().jobs.buccaneer_rescue.status)!="completed":
		print("CHAPTER_NEXT buccaneer_rescue")
		_check(_runtime.call("request_operation","accept_job",{"job_id":"buccaneer_rescue"}).get("ok",false),"accept orbital rescue")
		_check(_runtime.call("request_operation","select_destination",{"location_id":"distress_orbit","job_id":"buccaneer_rescue"}).get("ok",false),"select orbital rescue")
		if not await _prepare_sortie_base():return
		_check(_screen.call("request_operation","start",{"craft_id":_craft_id}).get("ok",false),"actual orbital departure")
		_check(_runtime.call("request_operation","space_start_quantum",{"craft_id":_craft_id,"target_orbit_id":"planet_orbit"}).get("ok",false),"fly to distress orbit")
		_return_orbit = "planet_orbit"
		if not await _wait(func():return String(_space().phase)=="orbit" and String(_space().orbit_id)==_return_orbit,10000,"arrive at distress orbit"):return
		_check(_runtime.call("request_operation","space_begin_approach",{"craft_id":_craft_id,"location_id":"distress_orbit"}).get("ok",false),"arrive encounter")
		if not await _wait(func():return String(_runtime.call("get_snapshot").space_encounter.get("phase",""))=="combat",10000,"combat actors admitted"):return
		_check(_runtime.call("request_operation","campaign_space_engage",{}).get("ok",false),"engage actual hostile Cutlass")
		if not await _wait(func():return String(_runtime.call("get_snapshot").space_encounter.get("phase",""))=="rescue_ready",20000,"actual tick combat destroys Cutlass"):return
		_check(_runtime.call("request_operation","campaign_space_rescue",{}).get("ok",false),"actual neutral rescued")
		_check(Array(_flow.get("_all_team_units")).size()==4,"fourth NPC joined")
		if not await _wait_homebase():return
	_flow.call("_show_homebase")
	_check(_runtime.call("request_operation","campaign_build_pad",{}).get("ok",false),"second pad constructed")
	if not await _save_verified_milestone("final fleet"):return
	var save:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime)
	print("FINAL_SAVE_RESULT ok=",save.get("ok",false)," reason=",save.get("reason",""))
	_check(save.get("ok",false),"final4-person fleet checkpoint saves")
	var loaded:Dictionary=STORE.load_checkpoint()
	_check(loaded.get("ok",false) and Array(loaded.get("payload",{}).get("roster",[])).size()==4 and Array(loaded.get("payload",{}).get("fleet",[])).size()==2,"final fleet checkpoint loads exact4people2ships")
	if not bool(save.get("ok",false)):return
	_flow.queue_free();await process_frame
	START.request_start(self,"campaign","continue")
	_flow=FLOW.instantiate();root.add_child(_flow);await process_frame
	_screen=_flow.get_node("HomebaseScreen");_runtime=_flow.get("_singleplayer_runtime")
	var resumed:Dictionary=_runtime.call("get_snapshot")
	_check(Array(_flow.get("_all_team_units")).size()==4 and Array(_flow.get("_homebase_aircraft_definitions")).size()==2,"actual Continue restores four people and two ships")
	_check(bool(resumed.campaign.progress.second_pad_built),"actual Continue retains constructed second pad")
	_check(Array(resumed.base_personnel.units).size()==4,"actual Continue restores four real base actors")


func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	_screen.call("request_operation", "craft", {"craft_id": _craft_id})
	_screen.call("request_operation", "focus_fireteam", {"fireteam_id": _team_id})
	var craft: Dictionary = Dictionary(_screen.call("get_operations_snapshot").get("selected_craft", {}))
	if String(craft.get("pilot_id", "")).is_empty():
		_screen.call("request_operation", "pilot", {"craft_id": _craft_id, "unit_id": _pilot_id})
	if not Array(craft.get("payload_fireteam_ids", [])).has(_team_id):
		var board: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id})
		if not _check(bool(board.get("ok", false)), scenario_id + " real boarding accepts"):
			print("BOARD_RESULT:", board)
			_dump("boarding")
			return false
	if _screen.call("get_base_personnel_runtime") != null:
		if not await _prepare_sortie_base():
			return false
	else:
		_screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var before_launch_job_status: String = String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", ""))
	var before_launch_fuel: Dictionary = Dictionary(_supply().get("fuel_by_craft_id", {})).duplicate(true)
	var launch: Dictionary = _screen.call("request_operation", "start", {"craft_id": _craft_id})
	if not _check(bool(launch.get("ok", false)), scenario_id + " launches actual boarded craft"):
		print("LAUNCH_RESULT:", launch)
		_dump("launch")
		return false
	if not _check(_flow.get("_active_mission") == null and int(_flow.get("_active_mission_started_at_msec")) == 0, scenario_id + " takeoff loads no mission and starts no mission timer"):
		return false
	_check(String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == before_launch_job_status, "Takeoff alone activates no campaign job")
	_check(Dictionary(_supply().get("fuel_by_craft_id", {})) == before_launch_fuel, "Takeoff alone debits no destination fuel")
	if not _check(String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", scenario_id + " actual takeoff reaches moon orbit"):
		_dump("moon_orbit")
		return false
	if String(_runtime.call("get_snapshot").get("mode", "")) == "campaign":
		var away_save: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
		_check(not bool(away_save.get("ok", false)), "Moon orbit cannot be saved as a home checkpoint")
	var premature: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": String(_campaign().selected_location_id)})
	_check(not bool(premature.get("ok", false)) and _flow.get("_active_mission") == null, "Planet map approach is blocked from moon orbit")
	var target_location: String = _campaign().selected_location_id
	_return_orbit = String(Dictionary(_space().location_orbits).get(target_location, ""))
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": _return_orbit, "request_id": "loop:jump:" + scenario_id})
	if not _check(bool(jump.get("ok", false)), scenario_id + " actual target click begins quantum"):
		print("JUMP_RESULT:", jump)
		_dump("quantum_start")
		return false
	if not await _wait(func(): return float(_space().get("progress", 0.0)) > 0.05, 1500, "Quantum visibly progresses through normal runtime ticks"):
		return false
	var moving_position: Array = Array(_space().get("position", [])).duplicate()
	var abort: Dictionary = _screen.call("request_operation", "space_abort_quantum", {"craft_id": _craft_id, "request_id": "loop:abort:" + scenario_id})
	_check(bool(abort.get("ok", false)) and String(_space().get("phase", "")) == "stopped" and Array(_space().get("position", [])) == moving_position, "Actual abort holds the reached midpoint without teleport")
	var stopped_position: Array = Array(_space().get("position", [])).duplicate()
	await physics_frame
	_check(Array(_space().get("position", [])) == stopped_position, "Aborted runtime trip remains still on subsequent tick")
	var restart: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": _return_orbit, "request_id": "loop:restart:" + scenario_id})
	if not _check(bool(restart.get("ok", false)) and Array(_space().get("origin_position", [])) == stopped_position, "Restart begins at the actual stopped position"):
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == _return_orbit, 8000, scenario_id + " real quantum reaches its target orbit"):
		_dump("planet_orbit")
		return false
	_check(_flow.get("_active_mission") == null and int(_flow.get("_active_mission_started_at_msec")) == 0, "Quantum arrival still loads no mission and starts no timer")
	_check(String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == before_launch_job_status and Dictionary(_supply().get("fuel_by_craft_id", {})) == before_launch_fuel, "Quantum, abort and restart activate no job and debit no route fuel")
	var approach: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": String(_campaign().selected_location_id), "request_id": "loop:approach:" + scenario_id})
	if not _check(bool(approach.get("ok", false)), scenario_id + " explicit approach accepts from its location orbit"):
		print("APPROACH_RESULT:", approach)
		_dump("approach")
		return false
	_check(_flow.get("_active_mission") == null and String(_space().get("phase", "")) == "approach", "Explicit approach shows departure from star map before map instantiation")
	var load_started := Time.get_ticks_msec()
	if not await _wait(func(): return _flow.get("_active_mission") != null, 60000, scenario_id + " actual mission instance exists"):
		_dump("mission_creation")
		return false
	print("REGIONAL_APPROACH_LOAD_MS ", scenario_id, " ", Time.get_ticks_msec() - load_started)
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not await _wait(func(): return String(Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).get("state", "")) == "waiting", 30000, scenario_id + " actual outbound transit reaches waiting craft"):
		_dump("outbound_transit")
		return false
	var map = MAP.load_from_file(map_path)
	var view: Node = mission.get_node("Primary3DView")
	var lz: Vector2 = _landing_target(map)
	# Normal selectable field LZs sit on the approach side of the two
	# outposts. The measured first sortie still uses the authored pad.
	var field_lz := {"outpost_recovery": Vector2i(44, 29), "outpost_chip_recovery": Vector2i(67, 46)}
	if field_lz.has(scenario_id):
		var field = map.get_tile_at_grid(field_lz[scenario_id])
		if field != null and field.walkable and field.object_type_id.is_empty():
			lz = field.world_position
	view.call("focus_world_position", lz)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	var placed: bool = bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", lz)))
	if not _check(placed, scenario_id + " actual map click places selected safe LZ"):
		_dump("lz_pick")
		return false
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not await _wait(func(): return _all_crew_deployed(controller) and int(mission.get_node("SimulationRoot").call("get_tick")) > 0, 30000, scenario_id + " real landing unloads all original crew into authoritative simulation"):
		_dump("actual_landing")
		return false
	_on_actual_landed(controller)
	var args := OS.get_cmdline_user_args()
	var measure_revisit := scenario_id == "benit_delivery" and args.has("native-perf-revisit")
	if DisplayServer.get_name() != "headless" and (args.has("native-perf") or measure_revisit):
		await _measure_live_camera(view, lz)
	_check(String(mission.get_node("MissionSetup").get("scenario_file_path")).get_file().get_basename() == scenario_id, "Selected location loads exact intended scenario " + scenario_id)
	return true

func _move_and_use(mission: Node, interaction: String, step: String, map_path: String) -> bool:
	if not is_instance_valid(mission):
		return _check(false, interaction + " mission still exists before command")
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var map = MAP.load_from_file(map_path)
	var target: Vector2 = map.get_marker_position(interaction)
	if interaction == "ship_return" and controller.has_method("_campaign_landed_craft_position"):
		target = controller.call("_campaign_landed_craft_position", _craft_id)
	var planned := false
	if interaction == "ship_return" and map_path.ends_with("/fortified_outpost.json"):
		planned = _plot_chip_return_waypoints(controller, target)
	if not planned:
		controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + " actual move GO accepts"):
		_dump("move_go")
		return false
	if not await _wait(func():
		if not is_instance_valid(controller):
			return false
		var entry: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction)
		return String(entry.get("runtime_use_status", "")) == "usable", 120000, interaction + " becomes usable after real simulated approach"):
		var actors := []
		for id in _crew_ids:
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", id)
			if is_instance_valid(unit):
				actors.append([id, unit.global_position, unit.global_position.distance_to(target)])
		print("REGIONAL_INTERACTION_DIAGNOSTIC ", actors, " ", _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction))
		print("REGIONAL_NAV_DIAGNOSTIC ", mission.get_node("SimulationRoot").call("get_navigation_debug_snapshot"))
		_dump("approach_" + interaction)
		return false
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", interaction)
	if not _check(bool(intent.get("accepted", false)), interaction + " real Use intent accepts"):
		print("USE_INTENT:", intent)
		_dump("use_intent")
		return false
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + " Use GO accepts"):
		_dump("use_go")
		return false
	if not await _wait(func():
		if is_instance_valid(driver):
			return PackedStringArray(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has(step) or bool(Dictionary(driver.call("get_mission_interaction_runtime_states").get(interaction,{})).get("complete",false))
		return step == "return_to_ship" and String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "completed", 45000, interaction + " actual timed Use commits required runtime step"):
		_dump("use_execution_" + interaction)
		return false
	return true


func _verify_actual_ramp_walk(controller: Node) -> bool:
	var registry: Node = controller.get_parent().get_node("TerrainRegistry")
	var lead: Node2D = controller.call("get_current_fireteam_lead_unit", _team_id)
	if not _check(is_instance_valid(lead), "Ramp test uses the deployed fireteam leader"):
		return false
	var origin: Vector2i = registry.call("world_to_grid", lead.global_position)
	var upper := Vector2i.ZERO
	var nearest := 24
	for q in range(origin.x - 18, origin.x + 19):
		for r in range(origin.y - 18, origin.y + 19):
			var cell := Vector2i(q, r)
			var distance := RAMP_HEX.distance(origin, cell)
			var tile = registry.call("get_tile_at_grid", cell)
			if distance < 8 or distance >= nearest or tile == null or tile.height_level != 1 or not tile.walkable:
				continue
			var shoulder_cells := 0
			for neighbor in RAMP_HEX.neighbors(cell):
				var adjacent = registry.call("get_tile_at_grid", neighbor)
				if adjacent != null and adjacent.height_level == 1 and adjacent.walkable:
					shoulder_cells += 1
			if shoulder_cells >= 3:
				nearest = distance
				upper = cell
	if not _check(nearest < 24, "Find a one-level terrace near the actual landing zone"):
		return false
	print("LIVE_RAMP ", origin, " -> ", upper, " -> ", origin)
	for cell in [upper, origin]:
		var target: Vector2 = registry.call("grid_to_world", cell)
		var expected_height: int = registry.call("get_tile_at_grid", cell).height_level
		controller.call("_create_waypoints_for_selected_fireteams", target, true)
		if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Regular GO accepts ramp waypoint %s" % cell):
			return false
		var reached := await _wait(func():
			var live_cell: Vector2i = registry.call("world_to_grid", lead.global_position)
			var live_tile = registry.call("get_tile_at_grid", live_cell)
			return live_tile != null and live_tile.height_level == expected_height and RAMP_HEX.distance(live_cell, cell) <= 3,
			20000, "Infantry leader walks to height %d at %s" % [expected_height, cell])
		if not reached:
			print("LIVE_RAMP_UNIT_AT ", registry.call("world_to_grid", lead.global_position), " expected ", cell)
			return false
	return true


func _plot_chip_return_waypoints(controller: Node, target: Vector2) -> bool:
	var registry: Node = controller.get_parent().get_node("TerrainRegistry")
	var lead: Node2D = controller.call("get_current_fireteam_lead_unit", _team_id)
	if not is_instance_valid(lead):
		return false
	var start: Vector2i = registry.call("world_to_grid", lead.global_position)
	var finish: Vector2i = registry.call("world_to_grid", target)
	var cells: Array = REGIONAL_PATHFINDER.new().find_path(start, finish, registry)
	if cells.size() < 2:
		return false
	var waypoint_indices: Array[int] = []
	var deck_seen := false
	for index in range(1, cells.size() - 1):
		var tile = registry.call("get_tile_at_grid", cells[index])
		if index % 14 == 0 or (not deck_seen and String(tile.object_type_id) == "glut_bridge_deck"):
			waypoint_indices.append(index)
		deck_seen = deck_seen or String(tile.object_type_id) == "glut_bridge_deck"
	waypoint_indices.append(cells.size() - 1)
	for i in range(waypoint_indices.size()):
		var position: Vector2 = registry.call("grid_to_world", cells[waypoint_indices[i]])
		controller.call("_create_waypoints_for_selected_fireteams", position, i == 0)
	print("CHIP_RETURN_WAYPOINTS ", waypoint_indices.size(), " crosses_deck=", deck_seen)
	return true


func _base_crew_ready() -> bool:
	var personnel:Node=_runtime.call("get_base_personnel_runtime")
	if personnel==null or not bool(personnel.call("is_pilot_aboard",_craft_id)):return false
	var expected:Array=Array(_screen.call("_get_member_unit_ids_for_fireteam",_team_id))
	var pilot_id: String = _pilot_id
	if pilot_id.is_empty():
		var operations: Dictionary = _screen.call("get_operations_snapshot")
		pilot_id = String(Dictionary(operations.get("selected_craft", {})).get("pilot_id", ""))
	if pilot_id.is_empty(): return false
	if not expected.has(pilot_id): expected.append(pilot_id)
	var people:Array=personnel.call("get_snapshot").get("units",[])
	for id in expected:
		var aboard:=false
		for person:Dictionary in people:
			if String(person.unit_id)==String(id):aboard=String(person.status)=="aboard" and String(person.craft_id)==_craft_id
		if not aboard:return false
	return bool(_screen.call("_has_homebase_direct_launch_payload_for_craft",_craft_id))


func _save_verified_milestone(label:String) -> bool:
	var deadline:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<deadline:
		var result:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime)
		if bool(result.get("ok",false)):return _check(true,"actual safe milestone saves "+label)
		if String(result.get("reason",""))!="preparation_in_progress":
			print("MILESTONE_SAVE_FAILURE ",label," ",result)
			return _check(false,"safe checkpoint "+label)
		await physics_frame
	return _check(false,"preparation settles before safe checkpoint "+label)


func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	return await super._wait(predicate, milliseconds * (4 if Engine.time_scale == 1.0 else 1), label)


func _measure_live_camera(view: Node, lz: Vector2) -> void:
	var before: int = view.get("_regional_chunk_build_count")
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	var center: Vector2i = view.call("world_to_grid_position", lz)
	for frame in range(240):
		if frame % 4 == 0:
			var offset := Vector2i((frame / 4) % 31 - 15, 0)
			view.call("focus_world_position", view.call("grid_to_world_position", center + offset))
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - previous) * 0.001)
		previous = now
	samples.sort()
	print("REGIONAL_LIVE_FRAME_MS ", {
		"scale": Engine.time_scale,
		"p50": samples[119], "p95": samples[227], "p99": samples[237], "max": samples[-1],
		"chunks_built": int(view.get("_regional_chunk_build_count")) - before,
		"fow": view.get("_fog_of_war_mode"), "static_bytes": OS.get_static_memory_usage(),
		"video_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)})
	view.call("focus_world_position", lz)
	for frame in range(8):
		await process_frame
	var zoom_samples: Array[float] = []
	previous = Time.get_ticks_usec()
	for frame in range(144):
		if frame % 12 == 0:
			view.call("zoom_camera", 1.0 if (frame / 12) % 2 == 0 else -1.0)
		await process_frame
		var now := Time.get_ticks_usec()
		zoom_samples.append(float(now - previous) * 0.001)
		previous = now
	zoom_samples.sort()
	print("REGIONAL_LIVE_ZOOM_MS ", {"p95": zoom_samples[136], "p99": zoom_samples[142], "max": zoom_samples[-1]})
	await RenderingServer.frame_post_draw
	var label := "A_revisit" if OS.get_cmdline_user_args().has("native-perf-revisit") else "A_landing"
	var target := "res://output/native_glut_maps/%s_live_ramps.png" % label
	print("REGIONAL_LIVE_CAPTURE ", root.get_texture().get_image().save_png(target))
