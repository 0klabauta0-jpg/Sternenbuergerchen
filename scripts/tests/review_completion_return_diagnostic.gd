extends "res://scripts/tests/review_completion_authentic_legacy_continue.gd"
## Diagnostic only: exact preserved private ActiveContinue pair, normal Continue,
## normal Move and authoritative runtime observations. No actor/owner injection.
func _run()->void:
	if not LEGACY_GUARD.require_isolated_user_data():return
	var source:=OS.get_environment("APPDATA")+"/Godot/app_userdata/SB-Codex-Review2-f067bcb6fff1471cb1dd3cec1705eb62/campaigns/introduction/"
	for item in [["checkpoint_v1.json",STORE.DEFAULT_PATH,"c346f73b218552e5851efdc35468a259f6a06d8ebd247d75ca5d810492e675cd"],["active_checkpoint_v1.json",LEGACY_ACTIVE.DEFAULT_PATH,"d6e7af966ae8e5da08858e0874c3775505c05cd007c029471f0c0b8ffa295181"]]:
		if not _check(FileAccess.get_sha256(source+item[0])==item[2],"exact preserved actual source "+item[0]):await _finish();return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(item[1]).get_base_dir())
		var file:=FileAccess.open(item[1],FileAccess.WRITE);file.store_buffer(FileAccess.get_file_as_bytes(source+item[0]));file.close()
	var active:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEGACY_ACTIVE.DEFAULT_PATH))
	_craft_id=active.components.identity.craft_id
	_crew_ids.assign(active.components.active_ids)
	if not await _continue_from_files("actual saved Hex pair"):await _finish();return
	var mission:Node=_flow.get("_active_mission")
	var controller:Node=mission.get_node("TacticalController")
	var simulation:Node=mission.get_node("SimulationRoot")
	var registry:Node=mission.get_node("UnitRegistry")
	_team_id=String(registry.get_unit(_crew_ids[0]).get_fireteam_id())
	controller._set_selected_fireteams(PackedStringArray([_team_id]),false)
	var target:Vector2=controller._campaign_landed_craft_position(_craft_id)
	var terrain:Node=mission.get_node("TerrainRegistry")
	var target_grid:Vector2i=terrain.world_to_grid(target)
	print("RETURN_TARGET ",{"position":target,"grid":target_grid,"walkable":terrain.is_walkable(target_grid),"mask":controller.get_ground_ship_blocked_cells()})
	controller._create_waypoints_for_selected_fireteams(target,true)
	_check(controller.execute_selected_fireteam_orders(),"actual return Move GO accepts")
	_flow.process_mode=Node.PROCESS_MODE_INHERIT
	simulation.set_physics_process(true);mission.get_node("CombatLoopDriver").set_physics_process(true);_runtime.get("_simulation").set_physics_process(true)
	for index in range(7):
		_trace_active_interaction("return approach %d" % index)
		print("RETURN_MOVEMENT_AUDIT ",simulation.get_hex_movement_audit_snapshot())
		await create_timer(5.0).timeout
	await _finish()

func _finish()->void:
	if is_instance_valid(_flow):_flow.queue_free()
	await process_frame
	print("REVIEW_RETURN_DIAGNOSTIC passed=%d failed=%d" % [_passed,_failed])
	quit(1 if _failed else 0)
