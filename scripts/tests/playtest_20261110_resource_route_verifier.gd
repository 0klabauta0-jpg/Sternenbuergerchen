extends "res://scripts/tests/playtest_20261110_extraction_loop.gd"
var _resource_checked:=false
func _configure_base_equipment() -> void:
	super._configure_base_equipment()
	for item in ["mining_tool","salvage_tool"]:
		var result: Dictionary=_screen.call("request_operation","inventory_transfer",{"unit_id":"campaign_leader","craft_id":_craft_id,"source_container_id":"base:homebase","destination_container_id":"unit:campaign_leader:backpack","item_id":item,"amount":1})
		_check(result.get("ok",false),"actual base menu packs finite "+item)
func _move_and_use(mission: Node,interaction: String,step: String,map_path: String) -> bool:
	if interaction=="satellite_data" and not _resource_checked:
		_resource_checked=true
		if not await _resource_routes(mission): return false
	return await super._move_and_use(mission,interaction,step,map_path)
func _resource_routes(mission: Node) -> bool:
	var controller: Node=mission.get_node("TacticalController")
	var source: RefCounted=_runtime.get("_supply").get_location_resources("satellite_crash")
	_check(not source.get_site_snapshot("iron_ridge_01").discovered,"remote resource starts undiscovered")
	_check(_find_interaction(controller.get_mission_interaction_runtime_use_state_snapshot(),"iron_ridge_01").is_empty(),"undiscovered resource has no world target")
	if not await _resource_use(mission,"iron_ridge_01"): return false
	_check(String(_campaign().jobs.satellite_recovery.status)=="active","mining leaves satellite job unfinished")
	var denied: Dictionary=_screen.call("request_operation","inventory_transfer",{"unit_id":"campaign_leader","craft_id":_craft_id,"source_container_id":"unit:campaign_leader:backpack","destination_container_id":"craft:"+_craft_id,"item_id":"ore","amount":4})
	_check(not denied.get("ok",false),"distant ship cargo rejects remote unload")
	var ship: Vector2=controller.call("_campaign_landed_craft_position",_craft_id)
	controller.call("_create_waypoints_for_selected_fireteams",ship,true); controller.execute_selected_fireteam_orders()
	if not await _wait(func(): return controller.call("_find_friendly_unit_by_id","campaign_leader").position.distance_to(ship)<=96,90000,"miner walks back to actual ship"): return false
	var unloaded: Dictionary=_screen.call("request_operation","inventory_transfer",{"unit_id":"campaign_leader","craft_id":_craft_id,"source_container_id":"unit:campaign_leader:backpack","destination_container_id":"craft:"+_craft_id,"item_id":"ore","amount":4})
	_check(unloaded.get("ok",false),"normal menu unloads ore only beside own landed craft")
	if not await _resource_use(mission,"freighter_wreck_01"): return false
	_check(source.get_site_snapshot("iron_ridge_01").remaining==0 and source.get_site_snapshot("freighter_wreck_01").remaining==0,"one physical location remembers both depleted sources")
	return true
func _resource_use(mission: Node,id: String) -> bool:
	var controller: Node=mission.get_node("TacticalController")
	var supply: RefCounted=_runtime.get("_supply")
	var source: RefCounted=supply.get_location_resources("satellite_crash")
	var site: Dictionary=source.get_site_snapshot(id)
	var terrain: Node=mission.get_node("TerrainRegistry")
	var target: Vector2=terrain.grid_to_world(Vector2i(site.grid[0],site.grid[1]))
	_check(terrain.is_walkable(terrain.world_to_grid(target)),"resource use point remains walkable "+id)
	controller.call("_create_waypoints_for_selected_fireteams",target,true)
	if not _check(controller.execute_selected_fireteam_orders(),"real resource approach "+id): return false
	if not await _wait(func(): return _find_interaction(controller.get_mission_interaction_runtime_use_state_snapshot(),id).get("can_use_now",false),90000,"local discovery and real range enable "+id):
		print("RESOURCE_DEBUG ",controller.get_mission_interaction_runtime_use_state_snapshot()); return false
	var gate: Dictionary=controller.create_selected_mission_interaction_use_intent(id)
	if not _check(gate.get("accepted",false),"real timed Use accepted "+id): print(gate); return false
	_check(controller.execute_selected_fireteam_orders(),"resource Use GO "+id)
	if not await _wait(func(): return source.get_site_snapshot(id).remaining==0,45000,"actual timer awards once "+id):
		print("RESOURCE_USE_DIAGNOSTIC ",mission.get_node("LocationResources").get("last_use_diagnostic")," driver=",mission.get_node("CombatLoopDriver").get_mission_interaction_runtime_states()," intent=",gate," phase=",controller.get("_phase_execution_by_fireteam")," plan=",controller.get("_order_plans_by_key")," unit=",controller.call("_find_friendly_unit_by_id","campaign_leader").position); return false
	_check(int(supply.get_supply_snapshot().inventory["unit:campaign_leader:backpack"].items.get(site.item_id,0))==int(site.quantity),"yield reaches actual miner backpack "+id)
	if OS.get_cmdline_user_args().has("native_probe"):
		var view: Node=mission.get_node("Primary3DView"); view.call("focus_world_position",target)
		await create_timer(.35).timeout
		for frame in 12: await process_frame
		var path:=ProjectSettings.globalize_path("res://output/playtest_20261110/native-resources"); DirAccess.make_dir_recursive_absolute(path)
		root.get_texture().get_image().save_png(path+"/"+id+".png")
	return true
