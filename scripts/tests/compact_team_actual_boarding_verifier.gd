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
	# Einsatzanzeige nach dem Aufsitzen (Paket A, 27.11.): Truppkarte bleibt, Schiffskarte sagt "An Bord", Belegungszeile steht.
	for i in 3:
		await process_frame
		controller.call("_update_ui")
	var occupancy:Dictionary=controller.call("get_campaign_craft_occupancy",_craft_id)
	_check(bool(occupancy.get("known",false)) and int(occupancy.get("outside",1))==0 and int(occupancy.get("aboard",0))>0 and String(occupancy.get("status",""))=="An Bord","A(2): Belegung bekannt, alle an Bord ("+str(occupancy)+")")
	var ship_card:Node=mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard")
	var ship_state:Label=ship_card.get_node_or_null("Contents/Header/Identity/A5TransportState") as Label
	_check(ship_state!=null and ship_state.text.contains("An Bord") and not ship_state.text.contains("Abgesetzt"),"A(2): Statuszeile der Schiffskarte sagt An Bord, nicht abgesetzt ("+("fehlt" if ship_state==null else ship_state.text)+")")
	var occupancy_label:Label=ship_card.get_node_or_null("Contents/A5TransportOccupancy") as Label
	_check(occupancy_label!=null and occupancy_label.is_visible_in_tree() and occupancy_label.text==String(occupancy.get("line","")) and occupancy_label.text.begins_with("Pilot ") and occupancy_label.text.contains("Passagiere"),"A(3): Belegungszeile auf der Schiffskarte ("+("fehlt" if occupancy_label==null else occupancy_label.text)+")")
	var ship_feedback:Label=ship_card.get_node_or_null("Contents/MissionDropshipCardFeedbackLabel") as Label
	_check(ship_feedback==null or not ship_feedback.visible or not ship_feedback.text.contains("abgesetzt"),"A(2): keine Meldung 'Trupp abgesetzt', wenn alle an Bord sind")
	var mini_team:Node=mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_"+_team_id.to_lower().capitalize())
	var strip:Node=mini_team.get_node_or_null("Margin/VBox/FireteamMemberPortraitStrip") if mini_team!=null else null
	var aboard_portraits:=0
	var all_portraits:=0
	if strip!=null:
		for portrait in strip.get_children():
			all_portraits+=1
			if bool(portrait.get_meta("mission_fireteam_member_aboard",false)):aboard_portraits+=1
	_check(mini_team!=null and all_portraits>0 and aboard_portraits==all_portraits,"A(1): Truppkarte links bleibt mit allen Mitgliedern, alle als an Bord gekennzeichnet (%d von %d)"%[aboard_portraits,all_portraits])
	var mini_status:Label=mini_team.get_node_or_null("Margin/VBox/StageLabel") as Label if mini_team!=null else null
	_check(mini_status!=null and mini_status.text=="An Bord","A(1): Statuszeile der Truppkarte sagt An Bord ("+("fehlt" if mini_status==null else mini_status.text)+")")
	_check(panel.get_node("A5TeamPortraits").get_child_count()==all_portraits and all_portraits>0,"A(1): die verbundene Truppkarte zeigt die Portraits weiter (%d)"%panel.get_node("A5TeamPortraits").get_child_count())
	var deploy:Dictionary=controller.request_campaign_crew_deployment(_craft_id)
	if not _check(deploy.get("ok",false),"existing Trupp absetzen remains available"):return false
	# GO is deliberately held ("WAIT FOR INSERTION", mission_tactical_sandbox_controller.gd:1590) until the team is runtime-active again; empty pending lists alone are true before the drop starts.
	# Observe the hold right now, while the drop is running (observing it inside the wait predicate only happens after the hold is gone).
	controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
	var held_go:bool=controller.call("execute_selected_fireteam_orders")
	_check(not held_go and String(controller.get("_last_command_text")).begins_with("WAIT FOR INSERTION"),"GO is held while the boarded troop is still being set down")
	_insertion_guard_checked=true
	return await _wait(func():return _all_crew_deployed(controller) and bool(controller.call("_is_fireteam_runtime_active",_team_id.to_lower())) and controller.get("_runtime_activation_pending_fireteam_ids").is_empty() and controller.get("_post_drop_security_pending_fireteam_ids").is_empty(),60000,"actual insertion guard finishes after boarding roundtrip")
