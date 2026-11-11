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
	await _finish()

func _wait_homebase() -> bool:
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == _sortie_orbit, 35000, "Actual surface exit returns original craft to the location orbit"):
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
