extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Narrow real-owner boundary: campaign/mission completion is not fabricated.
## The full Five fixture proves the actual trader -> home file -> Continue path.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _finish(); return
	var base: Node = _runtime.get_base_personnel_runtime()
	var sim: Node = _runtime.get("_simulation")
	var pilot_before: Dictionary = Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).duplicate(true)
	var payload_before: Dictionary = Dictionary(_screen.get("_homebase_dropship_staged_fireteam_ids_by_craft")).duplicate(true)
	var original_members: PackedStringArray = _screen.call("_get_member_unit_ids_for_fireteam", _team_id)
	var recruit: Dictionary = _flow.get("_all_team_units")[0].duplicate(true)
	recruit.merge({"unit_id":"transport_probe_recruit","display_name":"Transportprobe","fireteam_id":"foreign_profile_team"},true)
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_check(not _flow.register_campaign_recruit(recruit,{},"missing_craft").get("ok",true) and _flow.get("_all_team_units")==roster_before,"unknown pickup craft rejects before roster mutation")
	_screen.hide()
	var registered: Dictionary = _flow.register_campaign_recruit(recruit,{},_craft_id)
	_check(registered.get("ok",false) and registered.get("fireteam_id")==_team_id,"actual loaded squad owns recruit rather than profile team label")
	var members: PackedStringArray = _screen.call("_get_member_unit_ids_for_fireteam",_team_id)
	_check(members.size()==original_members.size()+1 and members.has(recruit.unit_id) and Array(original_members).all(func(id):return members.has(id)),"existing squad retains original members and adds exactly the recruit")
	_check(_screen.get("_homebase_dropship_staged_fireteam_ids_by_craft")==payload_before and _flow.get("_assigned_aircraft_pilot_by_craft")==pilot_before,"recruit changes no ship payload mapping or pilot assignment")
	_check(base.mark_recruit_remote(recruit.unit_id,_craft_id).get("ok",false),"existing pickup handoff binds real recruit aboard and releases ground")
	_check(sim.get_hex_unit_state(recruit.unit_id).is_empty() and base._checkpoint_craft_member(recruit.unit_id,_craft_id),"aboard recruit has strict loaded membership and no home ground cell")
	var exported: Dictionary = sim.export_hex_checkpoint_state()
	print("RECRUIT_ROOT_EXPORT ",exported.get("reason","ok"))
	_check(exported.get("ok",false),"real Root checkpoint accepts coherent recruited transport without guard exception")
	if exported.get("ok",false):
		var prepared: Dictionary = sim.prepare_hex_checkpoint_restore(exported.state)
		_check(prepared.get("ok",false),"same actual Root prepares recruited payload checkpoint")
		if prepared.get("ok",false): _check(sim.validate_prepared_hex_checkpoint_restore(prepared.prepared).get("ok",false),"prepared recruited checkpoint validates against actual owners")
	var repeated: Dictionary = _flow.register_campaign_recruit(recruit,{},_craft_id)
	_check(repeated.get("already_registered",false) and _screen.call("_get_member_unit_ids_for_fireteam",_team_id)==members,"duplicate recruit is idempotent and leaves membership unchanged")
	var pilot: Dictionary = _flow.get("_all_team_units")[1].duplicate(true)
	pilot.merge({"unit_id":"transport_probe_pilot","display_name":"Pilotenprobe","fireteam_id":""},true)
	var before_pilot: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_check(not _flow.register_campaign_recruit(pilot,{"model_id":"buccaneer"}).get("ok",true) and _flow.get("_all_team_units")==before_pilot,"missing pilot craft identity rejects before roster mutation")
	var existing_craft: Dictionary = _flow._find_homebase_aircraft_definition(_craft_id)
	_check(not _flow.register_campaign_recruit(pilot,existing_craft).get("ok",true) and _flow.get("_assigned_aircraft_pilot_by_craft")==pilot_before,"new pilot cannot overwrite an existing craft assignment")
	var fighter: Dictionary = _flow._build_homebase_aircraft_definition("fighter",1)
	fighter.merge({"craft_id":"transport_probe_fighter","model_id":"buccaneer"},true)
	_check(_flow.register_campaign_recruit(pilot,fighter).get("ok",false),"separate fighter pilot registers through existing fleet owner")
	_flow._aircraft_location_by_craft[fighter.craft_id]="waiting_pad"
	_runtime.sync_crafts()
	_check(base.mark_recruit_remote(pilot.unit_id,fighter.craft_id).get("ok",false),"separate fighter pilot binds aboard its own real ship")
	_check(base._checkpoint_craft_member(pilot.unit_id,fighter.craft_id) and not base._checkpoint_craft_member(pilot.unit_id,_craft_id) and not base._checkpoint_craft_member(recruit.unit_id,fighter.craft_id),"strict transport rejects foreign recruit and foreign pilot on either ship")
	_check(_screen.call("_get_member_unit_ids_for_fireteam",_team_id)==members and not PackedStringArray(_flow._homebase_staged_unit_ids).has(pilot.unit_id),"fighter pilot is not silently added to the ground squad")
	_check(sim.export_hex_checkpoint_state().get("ok",false),"two real transport bindings export with waiting-pad fighter")
	var unbound: Dictionary = recruit.duplicate(true); unbound.unit_id="transport_probe_unbound"
	var before_unbound: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_check(not _flow.register_campaign_recruit(unbound,{},fighter.craft_id).get("ok",true) and _flow.get("_all_team_units")==before_unbound,"known ship without loaded ground squad cannot absorb an arbitrary recruit")
	_check(_flow.register_campaign_recruit(unbound).get("ok",false) and base.mark_recruit_remote(unbound.unit_id,_craft_id).get("ok",false),"negative fixture uses real owners to represent an unassigned aboard person")
	_check(sim.export_hex_checkpoint_state().get("reason")=="base_checkpoint_aboard_context","unchanged checkpoint guard rejects unassigned roster person despite valid craft")
	await _finish()

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("CAMPAIGN_RECRUIT_TRANSPORT passed=%d failed=%d" % [_passed,_failed])
	quit(1 if _failed else 0)
