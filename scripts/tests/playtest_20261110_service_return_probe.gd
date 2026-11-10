extends "res://scripts/tests/playtest_20261110_native_acceptance_probe.gd"
## Existing private stage-3 checkpoint, real new trade sortie, no synthetic win.
func _run() -> void:
	START.request_start(self,"campaign","continue")
	_flow=FLOW.instantiate(); root.add_child(_flow); await process_frame
	_screen=_flow.get_node("HomebaseScreen"); _runtime=_flow.get("_singleplayer_runtime")
	var operations: Dictionary=_screen.get_operations_snapshot(); var craft: Dictionary=operations.selected_craft
	_craft_id=String(craft.id); _pilot_id=String(craft.pilot_id)
	var teams: Array=craft.get("payload_fireteam_ids",[])
	if not _check(not teams.is_empty(),"real Continue retains a flight-ready trade crew"): await _finish(); return
	_team_id=String(teams[0])
	for unit in _screen.call("_get_member_unit_ids_for_fireteam",_team_id): _crew_ids.append(String(unit))
	_check(_screen.request_operation("select_destination",{"craft_id":_craft_id,"location_id":"trade_outpost","job_id":""}).get("ok",false),"continued campaign chooses another ordinary trade visit")
	if not await _launch_and_land("trade_outpost_visit","res://maps/trade_outpost.json"): await _finish(); return
	var mission: Node=_flow.get("_active_mission")
	mission.get_node("TacticalController").call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
	if not await _move_and_use(mission,"trade_service","service_visit","res://maps/trade_outpost.json"): await _finish(); return
	if not await _wait(func(): return _flow.get("_singleplayer_services").is_visible_in_tree(),3000,"actual completed trader use opens the service panel"): await _finish(); return
	if not await _prepare_visit_return(mission): await _finish(); return
	var services: Node=_flow.get("_singleplayer_services")
	if not await _wait(func(): return not services.get("_return").disabled,3000,"service takeoff becomes usable after real extraction"): await _finish(); return
	services.get("_return").pressed.emit()
	if not await _wait(func(): return _space().phase=="orbit",30000,"real service return reaches planet orbit"): await _finish(); return
	_check(_screen.request_operation("space_start_quantum",{"craft_id":_craft_id,"target_orbit_id":"moon_orbit"}).get("ok",false),"continued trade crew begins homeward quantum")
	if not await _wait(func(): return _space().get("orbit_id","")=="moon_orbit",10000,"actual quantum reaches moon"): await _finish(); return
	_check(_screen.request_operation("space_land_homebase",{"craft_id":_craft_id}).get("ok",false),"continued trade sortie lands home normally")
	_check(_craft(_runtime.get_snapshot()).get("location_id","")=="homebase","actual craft restored to original base")
	await _finish()
func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("SERVICE_RETURN_PROBE passed=",_passed," failed=",_failed); quit(1 if _failed else 0)
