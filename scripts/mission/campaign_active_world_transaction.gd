extends RefCounted
## Prepared cross-owner world and mission transaction. All owners validate
## immediately before the synchronous publication tail.
const WORLD = preload("res://scripts/mission/campaign_active_restore_preflight.gd")
const SCENE = preload("res://scripts/mission/campaign_active_scene_preflight.gd")
const RECEIPTS = preload("res://scripts/mission/root_receipt_checkpoint.gd")
const ORBIT = preload("res://scripts/mission/orbit_intent_checkpoint.gd")

static func prepare(data: Dictionary, adapter: Node, scene: Node) -> Dictionary:
	if not is_instance_valid(adapter): return _bad("campaign_unavailable")
	var root: Node = adapter.get("_simulation")
	if not is_instance_valid(root): return _bad("campaign_unavailable")
	var adapter_stamp := _stamp_adapter(adapter)
	if adapter_stamp.is_empty(): return _bad("campaign_unavailable")
	var world: Dictionary = WORLD.prepare(data,adapter,root)
	if not world.get("ok",false): return world
	var mission: Dictionary = SCENE.prepare(scene,data)
	if not mission.get("ok",false): return mission
	var prepared := {"ok":true,"adapter":adapter,"root":root,"adapter_stamp":adapter_stamp,"world":world,"scene":mission,"campaign":world.campaign.export_state(),"supply":world.supply.export_state(),"onboarding":world.onboarding.export_state(),"equipment":world.equipment.export_state(),"market":world.market.export_state(),"wings":world.wing.export_checkpoint_state(),"systems":world.space.export_systems_checkpoint()}
	var checked := validate(prepared)
	return prepared if checked.get("ok",false) else checked

static func validate(candidate: Dictionary) -> Dictionary:
	var adapter: Node = candidate.get("adapter")
	var root: Node = candidate.get("root")
	if not is_instance_valid(adapter) or not is_instance_valid(root) or adapter.get("_simulation") != root or candidate.get("adapter_stamp") != _stamp_adapter(adapter): return _bad("campaign_candidate_stale")
	var world: Dictionary = candidate.get("world",{})
	if world.is_empty() or world.campaign.export_state()!=candidate.campaign or world.supply.export_state()!=candidate.supply or world.onboarding.export_state()!=candidate.onboarding or world.equipment.export_state()!=candidate.equipment or world.market.export_state()!=candidate.market or world.wing.export_checkpoint_state()!=candidate.wings or world.space.export_systems_checkpoint()!=candidate.systems: return _bad("campaign_candidate_stale")
	var checked: Dictionary = ORBIT.validate(adapter,world.orbit_candidate,world.orbit_bindings)
	if not checked.get("ok",false): return checked
	checked = RECEIPTS.validate_prebinding(root,world.receipt_candidate,world.bindings)
	if not checked.get("ok",false): return checked
	checked = world.space.validate_navigation_checkpoint_candidate(world.navigation,world.control_bindings)
	if not checked.get("ok",false): return checked
	return SCENE.validate(candidate.scene)

# The caller holds the scene frozen and has installed it under the hidden
# mission host. The caller must have completed all bootstrap checks.
static func commit(candidate: Dictionary, data: Dictionary) -> Dictionary:
	var checked := validate(candidate)
	if not checked.get("ok",false): return checked
	var adapter: Node = candidate.adapter
	var root: Node = candidate.root
	var flow: Node = adapter.get("_flow")
	var scene: Node = candidate.scene.scene
	var base: Node = adapter.get("_base_personnel")
	var identity: Dictionary = data.identity
	var craft: String = identity.craft_id
	var location: String = identity.location_id
	if scene.get_parent()!=flow.call("_get_mission_host") or flow.get("_active_mission")!=null or not flow.get("_location_registry").location_ids().is_empty(): return _bad("active_flow_changed")
	if data.has("home_hex_tactical"):
		# Aboard people have no base Ground pose. Their hidden projection's old
		# world position is not a second authoritative transport/position truth.
		var actual_base: Dictionary = base.export_checkpoint_state()
		if not preload("res://scripts/mission/checkpoint_value_codec.gd").equal_json_values(actual_base,data.home_hex_tactical.base_personnel):
			var changed_fields: Array = []
			for field in data.home_hex_tactical.base_personnel:
				if actual_base.get(field) != data.home_hex_tactical.base_personnel[field]: changed_fields.append(field)
			return {"ok":false,"reason":"active_base_personnel_changed","base_reason":actual_base.get("reason",""),"changed_fields":changed_fields}
	elif not _base_state_matches(base.export_state(),data.base_personnel): return _bad("active_base_personnel_changed")
	var world: Dictionary = candidate.world
	# No awaits, callbacks, or emitted signals in this publication tail.
	# M4d (P1): diese frische Versorgung wird die lebende der Kampagne; der nicht gespeicherte Magazin-Schalter gehoert dann an.
	world.supply.set_campaign_magazine_mode(true)
	root.configure_singleplayer_owners(world.campaign,world.supply,world.onboarding,world.fleet)
	root.configure_ship_equipment(world.equipment)
	root.configure_departure_adapter(adapter)
	if data.has("home_hex_tactical"):
		var rng = preload("res://scripts/core/gameplay_rng_state.gd")
		rng.publish(root, data.home_hex_tactical.get("rng_streams", rng.from_legacy(data.home_hex_tactical.rng_state)))
	root.set("_space_combat_state",world.space)
	root.set("_space_wing_state",world.wing)
	adapter.set("_campaign",world.campaign)
	adapter.set("_supply",world.supply)
	adapter.set("_onboarding",world.onboarding)
	adapter.set("_travel",world.fleet)
	adapter.set("_ship_equipment",world.equipment)
	adapter.set("_polisa_market",world.market)
	adapter.set("_space_operation_requests",world.space_requests.duplicate(true))
	adapter.set("_pad_by_craft",{craft:world.route_bindings.pad})
	adapter.set("_departure_token_by_craft",{craft:world.route_bindings.departure_token})
	RECEIPTS.publish(root,world.receipt_candidate)
	ORBIT.publish(adapter,world.orbit_candidate)
	SCENE.publish(candidate.scene)
	flow.set("_active_singleplayer_identity",identity.duplicate(true))
	flow.set("_craft_location_runtime",{craft:location})
	flow.set("_aircraft_location_by_craft",{craft:"mission"})
	flow.set("_active_mission",scene)
	var setup: Node = scene.get_node("MissionSetup")
	flow.set("_selected_unit_ids",setup.get("selected_team_unit_ids").duplicate())
	flow.set("_selected_fireteam_ids",setup.get("selected_team_fireteam_ids").duplicate())
	flow.set("_selected_mission_id",identity.scenario_id)
	flow.set("_selected_mission_map_path",String(setup.get("map_file_path")))
	flow.set("_mission_planning_state",scene.get_node("TacticalController").get_planning_state())
	var registry: RefCounted = flow.get("_location_registry")
	registry.register_location(location,scene)
	# Post-publication hooks may emit signals only after all owners agree.
	var finalized: Dictionary = SCENE.finalize(candidate.scene)
	if not finalized.get("ok",false) or finalized.get("context_changed",false): return _bad("active_finalize_changed")
	flow.call("_remember_location",scene)
	adapter.call("bind_mission_air_support",scene)
	adapter.call("register_location_resources",scene,location)
	flow.call("_connect_planning_state_bridge",scene)
	flow.call("_connect_mission_end",scene)
	scene.process_mode = Node.PROCESS_MODE_INHERIT
	scene.get_node("SimulationRoot").process_mode = Node.PROCESS_MODE_INHERIT
	scene.get_node("CombatLoopDriver").process_mode = Node.PROCESS_MODE_INHERIT
	scene.show()
	root.set_physics_process(true)
	flow.call("_show_mission")
	flow.set_meta("campaign_active_restore_complete",true)
	return {"ok":true}

static func _base_state_matches(actual: Dictionary, saved: Dictionary) -> bool:
	if int(actual.get("version",0))!=1 or int(saved.get("version",0))!=1 or not actual.get("units") is Dictionary or not saved.get("units") is Dictionary or actual.units.size()!=saved.units.size(): return false
	for id in actual.units:
		var left: Variant = actual.units[id]
		var right: Variant = saved.units.get(id)
		if not left is Dictionary or not right is Dictionary or left.size()!=right.size() or not left.get("position") is Array or not right.get("position") is Array or left.position.size()!=2 or right.position.size()!=2: return false
		for field in ["status","craft_id","bed_id","auto_rest_enabled","rest_automatic"]:
			if not left.has(field) or not right.has(field) or left[field]!=right[field]: return false
		if float(left.position[0])!=float(right.position[0]) or float(left.position[1])!=float(right.position[1]): return false
	return true

static func _stamp_adapter(adapter: Node) -> Dictionary:
	var flow: Node = adapter.get("_flow")
	var base: Node = adapter.get("_base_personnel")
	var onboarding: RefCounted = adapter.get("_onboarding")
	var market: RefCounted = adapter.get("_polisa_market")
	if not is_instance_valid(flow) or not is_instance_valid(base) or onboarding==null or market==null: return {}
	return {"flow":flow,"screen":adapter.get("_screen"),"simulation":adapter.get("_simulation"),"base":base,"base_state":base.export_state(),"campaign":adapter.get("_campaign"),"supply":adapter.get("_supply"),"onboarding":onboarding,"onboarding_state":onboarding.export_state(),"fleet":adapter.get("_travel"),"equipment":adapter.get("_ship_equipment"),"market":market,"market_state":market.export_state(),"pad":Dictionary(adapter.get("_pad_by_craft")).duplicate(true),"tokens":Dictionary(adapter.get("_departure_token_by_craft")).duplicate(true),"requests":Dictionary(adapter.get("_space_operation_requests")).duplicate(true),"locations":Dictionary(flow.get("_aircraft_location_by_craft")).duplicate(true),"active_identity":Dictionary(flow.get("_active_singleplayer_identity")).duplicate(true)}

static func _bad(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
