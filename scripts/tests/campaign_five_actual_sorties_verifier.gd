extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Actual first chapter sortie at 4x simulation speed; no fabricated objective results.
func _run() -> void:
	Engine.time_scale=4.0
	START.request_start(self,"campaign","new")
	_flow=FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen=_flow.get_node("HomebaseScreen"); _runtime=_flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _finish(); return
	var operations: Dictionary=_screen.call("get_operations_snapshot")
	var craft: Dictionary=operations.selected_craft
	_craft_id=String(craft.id); _pilot_id=String(craft.pilot_id)
	_team_id=String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id)==_team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	var before: Dictionary=_supply()
	_check(_screen.call("request_operation","accept_job",{"job_id":"satellite_recovery"}).get("ok",false),"first accepted")
	_check(_screen.call("request_operation","select_destination",{"location_id":"satellite_crash","job_id":"satellite_recovery"}).get("ok",false),"first destination selected")
	if not await _launch_and_land("satellite_recovery","res://maps/satellite_crash_site.json"): await _finish(); return
	var mission: Node=_flow.get("_active_mission")
	var controller: Node=mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
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
	await _remaining_missions()
	await _finish()

func _wait_homebase() -> bool:
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "planet_orbit", 35000, "Actual surface exit returns original craft to planet orbit"):
		_dump("return_to_planet_orbit")
		return false
	_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase", "Planet orbit is not physical home arrival")
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
		if not await _launch_and_land(job,map_path):return
		var mission:Node=_flow.get("_active_mission")
		var controller:Node=mission.get_node("TacticalController")
		controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
		if job!="benit_delivery":
			_check(bool(controller.call("set_selected_fireteams_fire_rule","free")),"commander orders weapons free")
			var enemy_target:Vector2=MAP.load_from_file(map_path).get_marker_position("spawn_enemy_defense")
			controller.call("_create_waypoints_for_selected_fireteams",enemy_target,true)
			_check(bool(controller.call("execute_selected_fireteam_orders")),"approach actual outpost guard")
			if not await _wait(func():return PackedStringArray(mission.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids",[])).has("clear_outpost"),60000,"actual combat defeats outpost guards"):
				_dump("outpost_combat");return
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
		if not await _wait(func():return String(_space().phase)=="orbit" and String(_space().orbit_id)=="planet_orbit",10000,"arrive at distress orbit"):return
		_check(_runtime.call("request_operation","space_begin_approach",{"craft_id":_craft_id,"location_id":"distress_orbit"}).get("ok",false),"arrive encounter")
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
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": "planet_orbit", "request_id": "loop:jump:" + scenario_id})
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
	var restart: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": "planet_orbit", "request_id": "loop:restart:" + scenario_id})
	if not _check(bool(restart.get("ok", false)) and Array(_space().get("origin_position", [])) == stopped_position, "Restart begins at the actual stopped position"):
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "planet_orbit", 5000, scenario_id + " short real quantum reaches planet orbit"):
		_dump("planet_orbit")
		return false
	_check(_flow.get("_active_mission") == null and int(_flow.get("_active_mission_started_at_msec")) == 0, "Quantum arrival still loads no mission and starts no timer")
	_check(String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == before_launch_job_status and Dictionary(_supply().get("fuel_by_craft_id", {})) == before_launch_fuel, "Quantum, abort and restart activate no job and debit no route fuel")
	var approach: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": String(_campaign().selected_location_id), "request_id": "loop:approach:" + scenario_id})
	if not _check(bool(approach.get("ok", false)), scenario_id + " explicit approach accepts from planet orbit"):
		print("APPROACH_RESULT:", approach)
		_dump("approach")
		return false
	_check(_flow.get("_active_mission") == null and String(_space().get("phase", "")) == "approach", "Explicit approach shows departure from star map before map instantiation")
	if not await _wait(func(): return _flow.get("_active_mission") != null, 12000, scenario_id + " actual mission instance exists"):
		_dump("mission_creation")
		return false
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not await _wait(func(): return String(Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).get("state", "")) == "waiting", 30000, scenario_id + " actual outbound transit reaches waiting craft"):
		_dump("outbound_transit")
		return false
	var map = MAP.load_from_file(map_path)
	var view: Node = mission.get_node("Primary3DView")
	var lz: Vector2 = _landing_target(map)
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
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + " actual move GO accepts"):
		_dump("move_go")
		return false
	if not await _wait(func():
		if not is_instance_valid(controller):
			return false
		var entry: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction)
		return String(entry.get("runtime_use_status", "")) == "usable", 45000, interaction + " becomes usable after real simulated approach"):
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


func _base_crew_ready() -> bool:
	var personnel:Node=_runtime.call("get_base_personnel_runtime")
	if personnel==null or not bool(personnel.call("is_pilot_aboard",_craft_id)):return false
	var expected:Array=Array(_screen.call("_get_member_unit_ids_for_fireteam",_team_id))
	if not expected.has(_pilot_id):expected.append(_pilot_id)
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
