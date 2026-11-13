extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Actual five-sortie chapter at 4x simulation speed; no fabricated results.
func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	if label.ends_with("actual mission instance exists"):
		var deadline := Time.get_ticks_msec() + maxi(milliseconds, 60000)
		var expected_scenario := label.trim_suffix(" actual mission instance exists")
		var expected_location := String(_campaign().get("selected_location_id", ""))
		var expected_departure := String(Dictionary(_runtime.get("_departure_token_by_craft")).get(_craft_id, ""))
		while Time.get_ticks_msec() < deadline:
			var mission: Node = _flow.call("get_mission_for_craft", _craft_id)
			if is_instance_valid(mission) and not mission.is_queued_for_deletion():
				var identity: Dictionary = mission.get_meta("singleplayer_mission_identity", {})
				var visits: Dictionary = mission.get_meta("singleplayer_visit_identities", {})
				var visit: Dictionary = visits.get(_craft_id, {})
				var setup: Node = mission.get_node_or_null("MissionSetup")
				var controller: Node = mission.get_node_or_null("TacticalController")
				var current_visit := String(identity.get("scenario_id", "")) == expected_scenario and String(visit.get("scenario_id", "")) == expected_scenario and String(visit.get("craft_id", "")) == _craft_id and not expected_departure.is_empty() and String(visit.get("departure_token", "")) == expected_departure and String(mission.get_meta("location_id", "")) == expected_location
				if current_visit and is_instance_valid(setup) and is_instance_valid(controller) and not controller.is_queued_for_deletion() and String(setup.get("scenario_file_path")).get_file().get_basename() == expected_scenario:
					# A completed previous job can still own this place while its
					# replacement is prepared. Select only the actual new visit.
					_flow.call("focus_location", expected_location)
					return _check(true, label)
			await physics_frame
		print("FIVE_SURFACE_PREPARATION ", _flow.call("get_surface_preparation_snapshot", _craft_id), " locations=", _flow.call("get_location_runtime_snapshot"), " travel=", _space())
		return _check(false, "TIMEOUT " + label)
	if label == "actual combat defeats outpost guards":
		var deadline := Time.get_ticks_msec() + milliseconds
		var next_trace := 0
		while Time.get_ticks_msec() < deadline:
			if bool(predicate.call()): return _check(true, label)
			if Time.get_ticks_msec() >= next_trace:
				_trace_actual_combat(label)
				next_trace = Time.get_ticks_msec() + 5000
			await physics_frame
		_trace_actual_combat("TIMEOUT " + label)
		return _check(false, "TIMEOUT " + label)
	if label.ends_with("becomes usable after real simulated approach"):
		var started := Time.get_ticks_msec()
		var deadline := started + milliseconds
		var next_trace := 0
		var extended := false
		var progress: Dictionary = {}
		var latest: Dictionary = {}
		while Time.get_ticks_msec() < deadline:
			if bool(predicate.call()): return _check(true, label)
			var now := Time.get_ticks_msec()
			if now >= next_trace:
				latest = _trace_actual_approach(label)
				for actor: Dictionary in latest.get("actors", []):
					var id := String(actor.id)
					var previous: Dictionary = progress.get(id, {})
					var moved := not previous.is_empty() and Vector2(previous.position).distance_squared_to(actor.position) > 1.0
					progress[id] = {"position":actor.position,"last_progress_msec":now if moved else int(previous.get("last_progress_msec", started)),"route_nodes":maxi(int(previous.get("route_nodes",0)), int(actor.movement.get("cached_route_nodes",0)))}
				next_trace = now + 5000
				if extended and not _long_approach_is_progressing(latest, progress, now):
					return _check(false, "STALLED extended actual approach " + label)
			await physics_frame
			# The real 512x256 trader return has a 129-cell path. The measured
			# original 45s run still moved normally with seven cells remaining.
			# Extend only a proved long, still advancing owner route; short Uses,
			# blocked/stationary routes and hold timers keep their original limit.
			if Time.get_ticks_msec() >= deadline and not extended and _long_approach_is_progressing(latest, progress, Time.get_ticks_msec()):
				extended = true
				deadline = started + maxi(milliseconds, 90000)
				print("FIVE_PROVEN_LONG_APPROACH ", label, " progress=", progress, " maximum_ms=", deadline-started)
		_trace_actual_approach("TIMEOUT " + label)
		return _check(false, "TIMEOUT " + label)
	return await super._wait(predicate, milliseconds, label)

func _trace_actual_approach(label: String) -> Dictionary:
	var mission: Node = _flow.get("_active_mission")
	if not is_instance_valid(mission): return {}
	var simulation: Node = mission.get_node("SimulationRoot")
	var controller: Node = mission.get_node("TacticalController")
	var actors: Array = []
	var deployed_ids: Array = Dictionary(controller.get("_deployed_unit_ids")).keys()
	deployed_ids.sort()
	for id: String in deployed_ids:
		var actor: Node = mission.get_node("UnitRegistry").get_unit(id)
		if not is_instance_valid(actor): continue
		var command = actor.call("get_current_unit_command")
		actors.append({"id":id,"position":actor.global_position,"ground":simulation.call("get_hex_unit_state",id),"movement":simulation.call("get_hex_movement_readout",id),"vital":actor.call("get_vital_state"),"command":command.to_dict() if command != null and command.has_method("to_dict") else str(command)})
	var observation := {"label":label,"msec":Time.get_ticks_msec(),"tick":simulation.call("get_tick"),"actors":actors,"ship_mask":controller.call("get_ground_ship_blocked_cells"),"use":controller.call("get_mission_interaction_runtime_use_state_snapshot"),"audit":simulation.call("get_hex_movement_audit_snapshot")}
	print("FIVE_APPROACH_TRACE ", var_to_str(observation))
	return observation

func _trace_actual_combat(label: String) -> void:
	var approach: Dictionary = _trace_actual_approach(label)
	var mission: Node = _flow.get("_active_mission")
	if not is_instance_valid(mission): return
	var simulation: Node = mission.get_node("SimulationRoot")
	var others: Array = []
	var own_team := ""
	if not _crew_ids.is_empty():
		var leader: Node = mission.get_node("UnitRegistry").get_unit(_crew_ids[0])
		if is_instance_valid(leader): own_team = String(leader.get_team_id())
	for actor: Node in mission.get_node("UnitRegistry").get_all_units():
		if not is_instance_valid(actor) or not actor.has_method("get_team_id") or String(actor.get_team_id()) == own_team: continue
		var id := String(actor.get_unit_id())
		others.append({"id":id,"team":actor.get_team_id(),"position":actor.global_position,"vital":actor.get_vital_state(),"hp":actor.get_health(),"ground":simulation.get_hex_unit_state(id)})
	print("FIVE_COMBAT_TRACE ",var_to_str({"label":label,"msec":Time.get_ticks_msec(),"tick":simulation.get_tick(),"own_team":own_team,"other_actors":others,"scenario":mission.get_node("CombatLoopDriver").get_mission_scenario_runtime_gate_snapshot(),"own_actor_count":Array(approach.get("actors",[])).size()}))

func _long_approach_is_progressing(observation: Dictionary, progress: Dictionary, now: int) -> bool:
	var has_long_live_route := false
	var actors: Array = observation.get("actors", [])
	if actors.is_empty(): return false
	for actor: Dictionary in actors:
		if String(actor.vital) != "fit": return false
		var movement: Dictionary = actor.movement
		var status := String(movement.get("status", ""))
		if status == "arrived": continue
		if status not in ["active", "waiting_reservation"]: return false
		var record: Dictionary = progress.get(String(actor.id), {})
		if record.is_empty() or now - int(record.last_progress_msec) > 15000: return false
		has_long_live_route = has_long_live_route or int(record.route_nodes) >= 96
	return has_long_live_route

func _all_crew_deployed(controller: Node) -> bool:
	# Hex activation can set and consume its receipt in one owner callback.
	# Exercise GO during the real, externally observable inbound/unload window
	# instead of depending on sampling that shorter internal flag interval.
	if not _insertion_guard_checked and (not bool(controller.call("_is_fireteam_runtime_active", _team_id)) or Dictionary(controller.get("_runtime_activation_pending_fireteam_ids")).has(_team_id) or Dictionary(controller.get("_post_drop_security_pending_fireteam_ids")).has(_team_id)):
		controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
		var accepted: bool = controller.call("execute_selected_fireteam_orders")
		_check(not accepted and String(controller.get("_last_command_text")).begins_with("WAIT FOR INSERTION"), "GO is blocked during the actual inbound/unloading interval")
		_insertion_guard_checked = true
	return super._all_crew_deployed(controller)

func _run() -> void:
	Engine.time_scale=4.0
	_configure_entry()
	_flow=FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen=_flow.get_node("HomebaseScreen"); _runtime=_flow.get("_singleplayer_runtime")
	var initial: Dictionary = _screen.call("get_operations_snapshot")
	_pilot_id = String(Dictionary(initial.get("selected_craft", {})).get("pilot_id", ""))
	if not _check(not _pilot_id.is_empty(), "actual assigned pilot identity is known before first boarding"):
		_dump_base_crew(); await _finish(); return
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
	var save:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime,true)
	print("SAVE_RESULT ",save.get("reason","ok"))
	if not _check(save.get("ok",false),"real manual home checkpoint saves new campaign"):
		_dump_checkpoint_export("satellite_recovery")
		await _finish(); return
	if not _verify_persisted_home("satellite_recovery"): await _finish(); return
	await _remaining_missions()
	await _finish()

func _wait_homebase() -> bool:
	# Retain physical transit checks while allowing the crew to grow beyond the
	# two-person Intro fixture. Both orbit IDs come from the actual route owner.
	var location_orbits: Dictionary = _space().get("location_orbits", {})
	var destination_orbit := String(location_orbits.get(String(_campaign().get("selected_location_id", "")), ""))
	var home_orbit := String(location_orbits.get("homebase", ""))
	if not _check(not destination_orbit.is_empty() and not home_orbit.is_empty(), "actual return and home orbits exist"): return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 35000, "Actual surface exit returns original craft to destination orbit"):
		_dump("return_to_planet_orbit")
		return false
	_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase", "Planet orbit is not physical home arrival")
	var home_jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": home_orbit})
	if not _check(bool(home_jump.get("ok", false)), "Real homeward target click begins moon quantum"):
		print("HOME_JUMP_RESULT:", home_jump)
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == home_orbit, 5000, "Real homeward quantum reaches moon orbit"):
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
	else:
		_return_number += 1
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
			# Actual 512x256 route exceeds the old compound 60s combat wait.
			# Require real proximity first; combat retains its own original budget.
			if not await _wait(func():
				var sim:Node=mission.get_node("SimulationRoot")
				for id in _crew_ids:
					var actor=sim.call("_resolve_known_unit_for_contract",String(id))
					if not is_instance_valid(actor) or actor.global_position.distance_to(enemy_target)>640.0:return false
				return true,180000,"actual squad reaches outpost combat area"):
				_dump("outpost_approach");return
			if not await _wait(func():return PackedStringArray(mission.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids",[])).has("clear_outpost"),60000,"actual combat defeats outpost guards"):
				_dump("outpost_combat");return
		if job=="outpost_recovery":
			if not await _move_and_use(mission,"recover_crate","recover_crate",map_path):return
			if not await _move_and_use(mission,"trade_service","trade_service",map_path):return
			var recruit:Dictionary=_runtime.call("request_operation","campaign_recruit",{"craft_id":_craft_id})
			if not _check(recruit.get("ok",false),"real trader recruit"):print(recruit);return
			_check(Array(_flow.get("_all_team_units")).size()==3,"third NPC joined")
			_check(PackedStringArray(_screen.call("_get_member_unit_ids_for_fireteam",_team_id)).has("campaign_outpost_recruit"),"actual hidden home payload includes recruited person before return")
			var repeated: Dictionary = _runtime.request_operation("campaign_recruit",{"craft_id":_craft_id})
			_check(repeated.get("ok",false) and not repeated.get("changed",true) and Array(_flow.get("_all_team_units")).size()==3,"actual repeated trader recruitment creates no person or reward")
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
		var distress_orbit := String(Dictionary(_space().get("location_orbits", {})).get("distress_orbit", ""))
		if not _check(not distress_orbit.is_empty(), "distress destination has its authoritative orbit"): return
		_check(_runtime.call("request_operation","space_start_quantum",{"craft_id":_craft_id,"target_orbit_id":distress_orbit}).get("ok",false),"fly to distress orbit")
		if not await _wait(func():return String(_space().phase)=="orbit" and String(_space().orbit_id)==distress_orbit,10000,"arrive at distress orbit"):return
		var approach: Dictionary = _runtime.call("request_operation","space_begin_approach",{"craft_id":_craft_id,"location_id":"distress_orbit"})
		if not _check(approach.get("ok", false), "actual encounter approach accepts, including pending orbit transit"): print("ENCOUNTER_APPROACH ", approach); return
		if not await _wait(func(): return String(_runtime.get_space_encounter_snapshot().get("phase", "")) == "combat", 35000, "actual orbit transit and Root admission finish before Engage"):
			print("ENCOUNTER_ENTRY ", _runtime.get_space_encounter_snapshot(), " TRAVEL ", _space()); return
		_check(_runtime.call("request_operation","campaign_space_engage",{}).get("ok",false),"engage actual hostile Cutlass")
		if not await _wait(func():return String(_runtime.call("get_snapshot").space_encounter.get("phase",""))=="rescue_ready",20000,"actual tick combat destroys Cutlass"):return
		_check(_runtime.call("request_operation","campaign_space_rescue",{}).get("ok",false),"actual neutral rescued")
		_check(Array(_flow.get("_all_team_units")).size()==4,"fourth NPC joined")
		if not await _wait_homebase():return
	_flow.call("_show_homebase")
	_check(_runtime.call("request_operation","campaign_build_pad",{}).get("ok",false),"second pad constructed")
	if not await _save_verified_milestone("final fleet"):return
	var save:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime,true)
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
	_check(PackedStringArray(_screen.call("_get_member_unit_ids_for_fireteam",_team_id)).has("campaign_outpost_recruit"),"actual Continue preserves recruited ground squad membership")
	_check(String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get("campaign_buccaneer_01",""))=="campaign_rescue_pilot" and not PackedStringArray(_screen.call("_get_member_unit_ids_for_fireteam",_team_id)).has("campaign_rescue_pilot"),"actual Continue keeps rescued fighter pilot separate from ground squad")
	_check(_return_number == _expected_physical_return_count(), "%d actual sorties completed their physical home return in this run" % _expected_physical_return_count())


# Launch/abort/resume/arrival use the current shared playtest helper.
# Its owner-based route lookup and pending-orbit checks must not drift here.
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
		return String(entry.get("runtime_use_status", "")) == "usable", 180000, interaction + " becomes usable after real simulated approach"):
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

func _board_actual_base_crew() -> bool:
	var ready: bool = await super._board_actual_base_crew()
	if not ready: _dump_base_crew()
	return ready

func _dump_base_crew() -> void:
	var personnel: Node = _runtime.get_base_personnel_runtime()
	print("FIVE_SORTIES_BOARDING ", {"craft_id":_craft_id, "pilot_id":_pilot_id, "team_id":_team_id, "expected_members":_screen.call("_get_member_unit_ids_for_fireteam", _team_id), "selected_craft":_screen.get_operations_snapshot().get("selected_craft", {}), "personnel":personnel.get_snapshot() if personnel != null else {}, "launch_payload_ready":_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)})


func _save_verified_milestone(label:String) -> bool:
	var deadline:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<deadline:
		var result:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime,true)
		if bool(result.get("ok",false)):return _verify_persisted_home(label)
		if String(result.get("reason",""))!="preparation_in_progress":
			print("MILESTONE_SAVE_FAILURE ",label," ",result)
			_dump_checkpoint_export(label)
			return _check(false,"safe checkpoint "+label)
		await physics_frame
	return _check(false,"preparation settles before safe checkpoint "+label)


func _verify_persisted_home(label: String) -> bool:
	var saved: Dictionary = STORE.load_checkpoint()
	if not _check(saved.get("ok",false),"actual manual milestone file reloads "+label): return false
	var payload: Dictionary = saved.payload
	var live: Dictionary = _campaign()
	var exact: bool = payload.roster.size() == Array(_flow.get("_all_team_units")).size() and payload.fleet.size() == Array(_flow.get("_homebase_aircraft_definitions")).size()
	for id in live.jobs:
		exact = exact and payload.campaign.jobs.has(id) and payload.campaign.jobs[id].status == live.jobs[id].status
	print("MILESTONE_FILE ",label," sha256=",FileAccess.get_sha256(STORE.DEFAULT_PATH)," tick=",payload.get("hex_tactical",{}).get("tick",-1)," statuses=",payload.campaign.jobs.keys())
	return _check(exact,"actual persisted milestone retains current job statuses, roster and fleet "+label)

func _dump_checkpoint_export(label: String) -> void:
	var sim: Node = _runtime.get("_simulation")
	var travel: RefCounted = _runtime.get("_travel")
	var base: Node = _runtime.get_base_personnel_runtime()
	var exported: Dictionary = sim.export_hex_checkpoint_state()
	var ground: Dictionary = sim.get("_hex_ground_runtime").export_state()
	var movement: Dictionary = sim.get("_hex_movement_runtime").export_state()
	var personnel: Dictionary = base.export_checkpoint_state()
	var orders: Dictionary = {}
	for id in sim.get("_hex_movement_runtime").get("_orders"):
		var order: Dictionary = sim.get("_hex_movement_runtime").get("_orders")[id]
		orders[id] = {"status":order.get("status"),"source_command_id":order.get("source_command_id"),"command_keys":order.get("command",{}).keys(),"lifecycle":order.get("command",{}).get("_hex_lifecycle",{}),"lifecycle_current":sim.call("_is_current_hex_payload",order.get("command",{})),"current_binding":sim.get_hex_actor_execution_binding(String(id))}
	var units: Dictionary = {}
	for id in base.get("_states"):
		units[id] = {"base":base.get("_states")[id],"ground":sim.get_hex_unit_state(String(id))}
	var summary: Dictionary = {"label":label,"campaign_mode":_runtime.get("_campaign_mode"),"all_grounded":travel.all_grounded(),"world_guard":_runtime.get_world_checkpoint_guard(),"root_guard":sim.get_hex_checkpoint_guard(),"root_export":_checkpoint_result_summary(exported),"ground_export":_checkpoint_result_summary(ground),"movement_export":_checkpoint_result_summary(movement),"base_export":_checkpoint_result_summary(personnel),"tick":sim.get_tick(),"context":sim.get_hex_ground_context_revision(),"commands":sim.command_queue.size(),"effects":sim.effects_queue.size(),"base_units":units,"beds":base.get("_beds"),"movement_intents":movement.get("accepted_intents",[]),"movement_orders":orders}
	print("HOME_EXPORT_DIAGNOSTIC ",JSON.stringify(summary))

func _checkpoint_result_summary(result: Dictionary) -> Dictionary:
	var summary: Dictionary = {}
	for key in ["ok","reason","schema","version","map_id","tick","field","unit_id"]:
		if result.has(key): summary[key]=result[key]
	return summary

func _expected_physical_return_count() -> int:
	return 5
