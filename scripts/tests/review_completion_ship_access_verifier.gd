extends "res://scripts/tests/review_completion_authentic_legacy_continue.gd"
## Exact real new-game/landing save produced by ActiveContinue f067. Commands,
## original crew, blocked hull, movement and boarding all use actual owners.
func _run()->void:
	if not LEGACY_GUARD.require_isolated_user_data():return
	var source:="res://docs/qa/review_completion_20261113/return_source_pair/"
	for item in [["checkpoint_v1.json",STORE.DEFAULT_PATH,"c346f73b218552e5851efdc35468a259f6a06d8ebd247d75ca5d810492e675cd"],["active_checkpoint_v1.json",LEGACY_ACTIVE.DEFAULT_PATH,"d6e7af966ae8e5da08858e0874c3775505c05cd007c029471f0c0b8ffa295181"]]:
		if not _check(FileAccess.get_sha256(source+item[0])==item[2],"exact actual source "+item[0]):await _finish();return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(item[1]).get_base_dir())
		var file:=FileAccess.open(item[1],FileAccess.WRITE);file.store_buffer(FileAccess.get_file_as_bytes(source+item[0]));file.close()
	var active:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEGACY_ACTIVE.DEFAULT_PATH))
	_craft_id=active.components.identity.craft_id;_crew_ids.assign(active.components.active_ids)
	if not await _continue_from_files("actual saved Hex pair"):await _finish();return
	var mission:Node=_flow.get("_active_mission")
	var controller:Node=mission.get_node("TacticalController")
	var simulation:Node=mission.get_node("SimulationRoot")
	var registry:Node=mission.get_node("UnitRegistry")
	var terrain:Node=mission.get_node("TerrainRegistry")
	_team_id=String(registry.get_unit(_crew_ids[0]).get_fireteam_id())
	controller._set_selected_fireteams(PackedStringArray([_team_id]),false)
	var center:Vector2=controller._campaign_landed_craft_position(_craft_id)
	var mask:Dictionary=controller.get_ground_ship_blocked_cells()
	_check(mask.ok and mask.blocked_cells.has(terrain.world_to_grid(center)),"actual craft center is blocked by its physical hull")
	var access:Dictionary=controller.get_campaign_ground_ship_access(_craft_id)
	if not _check(access.get("ok",false) and not mask.blocked_cells.has(access.grid) and terrain.is_walkable(access.grid),"same existing exit geometry exposes a real walkable access outside hull"):
		print("SHIP_ACCESS_DIAGNOSTIC ",access);await _finish();return
	var before:Dictionary=simulation.get_hex_ground_planning_snapshot()
	var rng:Dictionary=simulation.export_gameplay_rng_state()
	var command_count:int=simulation.command_queue.size()
	for index in range(8):
		_check(controller.get_campaign_ground_ship_access(_craft_id)==access,"repeated access read is stable %d" % index)
	_check(simulation.get_hex_ground_planning_snapshot()==before and simulation.export_gameplay_rng_state()==rng and simulation.command_queue.size()==command_count,"access reads leave occupancy RNG commands and clock unchanged")
	var plan:Dictionary=simulation.plan_hex_ground_actor_approach(PackedStringArray(_crew_ids),access.position,96.0)
	if not _check(plan.get("ok",false),"Root plans actual admitted crew without another admission"):
		print("SHIP_APPROACH_DIAGNOSTIC ",plan);await _finish();return
	var distinct:Dictionary={}
	var legal:=true
	for id in plan.targets:
		var grid:Vector2i=terrain.world_to_grid(plan.targets[id])
		legal=legal and not mask.blocked_cells.has(grid) and not distinct.has(grid) and plan.targets[id].distance_to(access.position)<=96.0
		distinct[grid]=true
	_check(legal and distinct.size()==_crew_ids.size(),"all planned targets are distinct clear cells within unchanged Use96")
	_check(simulation.get_hex_ground_planning_snapshot()==before and simulation.command_queue.size()==command_count,"approach plan is read-only and does not place actors")
	_check(not simulation.plan_hex_ground_actor_approach(PackedStringArray(["foreign"]),access.position,96.0).ok,"unknown actor cannot obtain a mission approach")
	_check(not simulation.plan_hex_ground_actor_approach(PackedStringArray(_crew_ids),center,96.0).ok,"blocked center remains rejected instead of ignoring the hull")
	var marker:Dictionary=_find_interaction(controller.get_mission_interaction_runtime_use_state_snapshot(),"ship_return")
	_check(marker.marker_position==access.position and marker.radius_world==96.0,"UI Return marker uses same physical access and original radius")
	_check(controller._campaign_unit_near_boarding_ship(_craft_id,access.position+Vector2(128,0),center) and not controller._campaign_unit_near_boarding_ship(_craft_id,access.position+Vector2(128.1,0),center),"boarding preserves exact128 boundary around same access")
	# Isolated negative owner inputs while the actual reconstructed scene is
	# frozen. A rejected new boarding intent must never execute an older plan.
	controller._create_waypoints_for_selected_fireteams(registry.get_unit(_crew_ids[0]).global_position,true)
	var old_plan:Variant=controller._serialize_order_plans()
	var old_queue:int=simulation.command_queue.size()
	var landing:Dictionary=controller._field_landing_by_craft[_craft_id]
	var profile:Dictionary=landing.ground_body_profile.duplicate(true)
	landing.erase("ground_body_profile")
	_check(not controller.get_campaign_ground_ship_access(_craft_id).get("ok",false),"missing bound body profile rejects access even after cached valid read")
	_check(not controller.request_campaign_extraction(_craft_id).get("ok",false) and not controller.request_selected_team_boarding().get("ok",false),"both public boarding entry points reject missing access")
	_check(controller._serialize_order_plans()==old_plan and simulation.command_queue.size()==old_queue,"rejected boarding leaves pending old plan and command queue untouched")
	_check(not controller.get_selected_team_boarding_snapshot().can_board,"boarding UI reports blocked access honestly")
	landing.ground_body_profile=profile.duplicate(true);landing.ground_body_profile.craft_id="different_craft"
	_check(not controller.get_campaign_ground_ship_access(_craft_id).get("ok",false),"profile belonging to another craft cannot reuse cached access")
	landing.ground_body_profile=profile
	var prior_phase:String=controller._drop_sequence_phase
	var prior_sequences:Dictionary=controller._parallel_drop_sequences_by_craft.duplicate(true)
	controller._drop_sequence_phase="outbound"
	if controller._parallel_drop_sequences_by_craft.has(_craft_id):controller._parallel_drop_sequences_by_craft[_craft_id].phase="outbound"
	_check(not controller.get_campaign_ground_ship_access(_craft_id).get("ok",false),"departed ship cannot expose previous cached access")
	controller._drop_sequence_phase=prior_phase;controller._parallel_drop_sequences_by_craft=prior_sequences
	_check(controller.get_campaign_ground_ship_access(_craft_id)==access,"restored actual profile and parked phase reproduce identical access")
	controller._create_waypoints_for_selected_fireteams(center,true)
	if not _check(controller.execute_selected_fireteam_orders(),"ordinary actual Move to ship resolves to accessible approach"):await _finish();return
	_flow.process_mode=Node.PROCESS_MODE_INHERIT
	simulation.set_physics_process(true);mission.get_node("CombatLoopDriver").set_physics_process(true);_runtime.get("_simulation").set_physics_process(true)
	var deadline:=Time.get_ticks_msec()+60000
	var arrived:=false
	var touched_hull:=false
	while Time.get_ticks_msec()<deadline:
		arrived=true
		for id in _crew_ids:
			var ground:Dictionary=simulation.get_hex_unit_state(id)
			if ground.is_empty():arrived=false;continue
			touched_hull=touched_hull or mask.blocked_cells.has(ground.grid)
			arrived=arrived and not ground.movement_state.moving and not ground.route_state.has_commitments and terrain.grid_to_world(ground.grid).distance_to(access.position)<=96.0
		if arrived:break
		await physics_frame
	if not _check(arrived,"real crew physically walks to clear access without teleport"):
		_trace_active_interaction("ship access timeout")
	_check(not touched_hull and controller.get_ground_ship_blocked_cells().blocked_cells==mask.blocked_cells,"actual walk never occupies the preserved ship footprint")
	if arrived:
		var boarding:Dictionary=controller.request_selected_team_boarding()
		_check(boarding.get("ok",false),"actual selected-team boarding UI command accepts at same access")
		var boarded:=await _wait(func():return controller.get_campaign_air_support_pilot_guard(_craft_id).get("ok",false),15000,"actual Root boarding completes for real pilot and team")
		if boarded:
			_check(_crew_ids.all(func(id):return simulation.get_hex_unit_state(id).is_empty()),"boarding releases actual ground ownership rather than hiding occupied cells")
	await _finish()

func _finish()->void:
	if is_instance_valid(_flow):_flow.queue_free()
	await process_frame
	print("REVIEW_SHIP_ACCESS passed=%d failed=%d" % [_passed,_failed])
	quit(1 if _failed else 0)
