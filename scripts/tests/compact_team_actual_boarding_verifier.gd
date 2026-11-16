extends "res://scripts/tests/flugdeck_pilot_actual_sortie_verifier.gd"
func _wait_homebase()->bool:
	if not await super._wait_homebase():return false
	var people:Node=_runtime.get_base_personnel_runtime()
	var seen:Dictionary={}
	for id:String in _crew_ids:
		if seen.has(id):continue
		seen[id]=true
		var aboard:bool=false
		for person:Dictionary in people.get_snapshot().units:
			if String(person.unit_id)==id:aboard=String(person.status) in ["aboard","boarding"]
		if not aboard:continue # Absetzen of a non-pilot also disembarks his whole FT.
		var result:Dictionary=people.request_operation("base_unboard",{"unit_id":id,"craft_id":_craft_id})
		_check(result.get("ok",false),"home crew physically disembarks before resting")
	var state:Dictionary=people.get_snapshot()
	var beds:Array=state.layout.beds
	var leader:String=_crew_ids[0]
	var sleep:Dictionary=people.request_operation("base_sleep",{"unit_id":leader,"bed_id":beds[0].id})
	_check(sleep.get("ok",false),"recovered-chip carrier can request sleep at home")
	var sim:Node=people.get_simulation_root()
	for i in 3000:
		sim.call("_physics_process",0.05)
		if String(people.get_snapshot().units[0].status)=="sleeping":break
	_check(String(people.get_snapshot().units[0].status)=="sleeping","real bed arrival before testing upload")
	_check(String(_campaign().jobs.satellite_recovery.status)=="pending_upload","sleep preserves physically recovered mission data")
	var saved:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime)
	_check(saved.get("ok",false),"sleeping crew and unuploaded chip checkpoint saves")
	return true

func _launch_and_land(scenario_id:String,map_path:String)->bool:
	if not await super._launch_and_land(scenario_id,map_path):return false
	var mission:Node=_flow.get("_active_mission")
	var controller:Node=mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
	controller.call("_update_ui")
	var panel:Node=mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel")
	var button:Button=panel.get_node("A5TeamBoard")
	if not _check(button.is_visible_in_tree() and not button.disabled,"Aufsitzen is available on selected actual troop"):return false
	button.pressed.emit()
	if not await _wait(func():return String(controller.get_selected_team_boarding_snapshot().message)=="Trupp an Bord",15000,"selected troop really walks and boards from its own card"):return false
	_check(String(controller.get("_campaign_extraction_craft_id")).is_empty(),"troop boarding does not invoke global extraction selection")
	_check(controller.call("_is_parked_campaign_dropship",_craft_id),"Aufsitzen does not fly away")
	_check(controller.get("_selected_fireteam_ids")==PackedStringArray([_team_id]),"boarding retains selected troop")
	controller.call("_update_ui")
	_check(button.disabled and panel.get_node("A5BoardStatus").text=="Trupp an Bord","combined card confirms actual completed boarding")
	var ship_board:Button=mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Actions/board")
	_check(not ship_board.is_visible_in_tree(),"boarding action is no longer duplicated at ship")
	var deploy:Dictionary=controller.request_campaign_crew_deployment(_craft_id)
	if not _check(deploy.get("ok",false),"existing Trupp absetzen remains available"):return false
	# GO is deliberately held ("WAIT FOR INSERTION", mission_tactical_sandbox_controller.gd:1590) until the team is runtime-active again; empty pending lists alone are true before the drop starts.
	return await _wait(func():return _all_crew_deployed(controller) and bool(controller.call("_is_fireteam_runtime_active",_team_id.to_lower())) and controller.get("_runtime_activation_pending_fireteam_ids").is_empty() and controller.get("_post_drop_security_pending_fireteam_ids").is_empty(),60000,"actual insertion guard finishes after boarding roundtrip")
