extends "res://scripts/tests/campaign_chapter_one_sortie_verifier.gd"
## Complete actual first sortie with the pilot retained in FT1, no synthetic mission results.
func _prepare_initial_base() -> bool:
	if not await super._prepare_initial_base(): return false
	var people:Node=_runtime.get_base_personnel_runtime()
	var craft:Dictionary=_screen.get_operations_snapshot().selected_craft
	var pilot:String=String(craft.pilot_id)
	var result:Dictionary=people.request_operation("base_unboard",{"unit_id":pilot,"craft_id":_craft_id})
	if not _check(result.get("ok",false),"dual-role sortie pilot physically exits first"):return false
	result=_screen.request_operation("assign",{"unit_id":pilot,"fireteam_id":_team_id})
	if not _check(result.get("ok",false),"dual-role sortie pilot joins Anja in existing boarded FT1"):return false
	if not _check(String(_screen.call("_get_fireteam_id_for_unit",pilot))==_team_id,"real pilot membership before flight"):return false
	return await _board_actual_base_crew()

func _run() -> void:
	Engine.time_scale=4.0
	_configure_entry() # seeds the menu-built Skirmish team for the inherited _finish check
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
	var presenter:Node=_screen.get("_operations_presenter")
	presenter.call("_open_base_management","data")
	var terminal:Node=presenter.get("_services_view")
	var upload:Button=terminal.get("_campaign_buttons").campaign_upload.button
	_check(upload.is_visible_in_tree() and not upload.disabled,"direct base data terminal exposes real pending upload")
	upload.pressed.emit()
	var result:Dictionary={"ok":String(_campaign().jobs.satellite_recovery.status)=="completed"}
	print("UPLOAD_RESULT ",result)
	_check(bool(result.get("ok",false)),"real home upload accepted")
	_check(String(_campaign().jobs.satellite_recovery.status)=="completed","upload completes first mission")
	_check(int(_supply().credits)==int(before.credits)+150,"one exact reward")
	presenter.call("_open_base_management","workshop")
	var armor_before:int=int(_supply().inventory["base:homebase"].items.get("armor_light",0))
	var credits_before:int=int(_supply().credits)
	var fabricate:Button=terminal.get("_campaign_buttons").campaign_fabricatelight_armor.button
	_check(not fabricate.disabled,"earned blueprint enables actual workshop control")
	fabricate.pressed.emit()
	_check(int(_supply().inventory["base:homebase"].items.get("armor_light",0))==armor_before+1,"workshop button adds one real armor item to finite base stock")
	_check(int(_supply().credits)==credits_before-20,"workshop charges existing authoritative recipe once")
	var save:Dictionary=_flow.get("_campaign_start").call("save_home_checkpoint",_flow,_runtime)
	print("SAVE_RESULT ",save.get("reason","ok"))
	_check(save.get("ok",false),"real home checkpoint saves new campaign")
	_check(STORE.load_checkpoint().get("ok",false),"new checkpoint loads")
	await _finish()

func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	if not await super._launch_and_land(scenario_id,map_path):return false
	var mission:Node=_flow.get("_active_mission")
	var controller:Node=mission.get_node("TacticalController")
	var result:Dictionary=controller.request_campaign_crew_boarding(_craft_id)
	if not _check(result.get("ok",false) or String(result.get("reason",""))=="pilot_boarding_pending","landed crew may reboard before testing absetzen"):return false
	if not await _wait(func():return bool(controller.get_campaign_pilot_flight_guard(_craft_id).get("ok",false)),8000,"real landed pilot is aboard again"):return false
	controller.call("_update_ui")
	var drop:Button=mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Actions/drop")
	_check(drop.is_visible_in_tree() and not drop.disabled and drop.text=="Trupp absetzen","landed craft exposes clearly named Trupp absetzen")
	drop.pressed.emit()
	if not await _wait(func():return controller.get("_deployed_unit_ids").size()==2,8000,"actual existing deploy effects put both crew members on ground"):return false
	_check(controller.get("_embarked_unit_ids").is_empty(),"absetzen leaves no duplicate embarked people")
	return await _wait(func():return controller.get("_runtime_activation_pending_fireteam_ids").is_empty() and controller.get("_post_drop_security_pending_fireteam_ids").is_empty(),8000,"real insertion effects and security finish after repeated absetzen")
