extends RefCounted
## Read-only collection of independently validated owner snapshots for a narrow
## stable single-craft, no-enemy legacy surface mission. This is NOT a complete
## world checkpoint: Root receipts and staged scene restoration remain required.
const HOME_STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const ACTORS = preload("res://scripts/mission/mission_actor_checkpoint_batch.gd")
const LIFECYCLE = preload("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd")
const ROOT_RECEIPTS = preload("res://scripts/mission/root_receipt_checkpoint.gd")
const ORBIT = preload("res://scripts/mission/orbit_intent_checkpoint.gd")

static func capture_components(flow: Node, runtime: Node) -> Dictionary:
	if not is_instance_valid(flow) or not is_instance_valid(runtime) or not flow.has_method("is_campaign_start") or not flow.is_campaign_start() or runtime.get("_flow") != flow: return _reject("campaign_unavailable")
	var world_guard: Dictionary = runtime.get_world_checkpoint_guard()
	if not world_guard.get("ok",false) and world_guard.get("reason") != "world_active": return world_guard
	# The home hex owner has independent occupancy/movement/base state. The
	# generic world guard stops at travel first, so it cannot establish that
	# these participants are captured by this surface-only checkpoint.
	var encounter: RefCounted = runtime.get("_space_encounter")
	if encounter == null or not Dictionary(encounter.get("_state")).is_empty() or not Dictionary(runtime.get("_service_pad_reservation")).is_empty(): return _reject("world_service_unsupported")
	var home_sim: Node = runtime.get("_simulation")
	if not is_instance_valid(home_sim): return _reject("home_owner_unavailable")
	var home_hex: Dictionary = {}
	if home_sim.is_hex_ground_runtime_required():
		var exported_home: Dictionary = home_sim.export_hex_checkpoint_state()
		if not exported_home.get("ok",false): return exported_home
		home_hex = exported_home.state
	for resource in Dictionary(runtime.get("_resource_owners")).values():
		if not is_instance_valid(resource) or not Dictionary(resource.get("_active")).is_empty() or not Dictionary(resource.get("_pending")).is_empty(): return _reject("resource_activity_unsupported")
	var mission: Node = flow.get("_active_mission")
	if not is_instance_valid(mission) or mission.is_queued_for_deletion(): return _reject("mission_unavailable")
	var locations: Array = flow.get_location_runtime_snapshot()
	if locations.size() != 1: return _reject("multiple_locations_unsupported")
	var identity: Variant = mission.get_meta("singleplayer_mission_identity", {})
	if not identity is Dictionary or identity.is_empty() or identity != flow.get("_active_singleplayer_identity"): return _reject("mission_identity_mismatch")
	for key in ["craft_id", "location_id", "scenario_id", "job_id", "departure_token"]:
		if typeof(identity.get(key)) != TYPE_STRING or String(identity[key]).is_empty(): return _reject("mission_identity_mismatch")
	var craft_id: String = identity.craft_id
	if locations[0].get("location_id") != identity.location_id or Array(locations[0].get("craft_ids",[])) != [craft_id] or Dictionary(flow.get("_aircraft_location_by_craft")).get(craft_id) != "mission": return _reject("mission_location_mismatch")
	var definitions: Array = flow.get("_homebase_aircraft_definitions")
	if definitions.size() != 1 or not definitions[0] is Dictionary or definitions[0].get("craft_id") != craft_id: return _reject("mission_fleet_unsupported")
	var travel: RefCounted = runtime.get("_travel")
	var travel_state: Dictionary = travel.get_craft_snapshot(craft_id) if travel != null else {}
	if travel_state.get("phase") != "surface" or travel_state.get("location_id") != identity.location_id: return _reject("mission_travel_mismatch")
	var pilot := String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(craft_id,""))
	if pilot.is_empty() or mission.get_meta("campaign_ground_pilot_id", "") != pilot: return _reject("mission_pilot_mismatch")
	var sim: Node = mission.get_node_or_null("SimulationRoot")
	var terrain: Node = mission.get_node_or_null("TerrainRegistry")
	var controller: Node = mission.get_node_or_null("TacticalController")
	var driver: Node = mission.get_node_or_null("CombatLoopDriver")
	var setup: Node = mission.get_node_or_null("MissionSetup")
	if not is_instance_valid(sim) or not is_instance_valid(terrain) or not is_instance_valid(controller) or not is_instance_valid(driver) or not is_instance_valid(setup): return _reject("mission_owner_unavailable")
	var deployed: Variant = controller.get("_deployed_unit_ids")
	if not deployed is Dictionary or deployed.is_empty(): return _reject("mission_crew_not_deployed")
	var active_ids: Array = deployed.keys()
	active_ids.sort()
	var registry: Node = sim.get_unit_registry()
	if not is_instance_valid(registry) or registry.get_all_units().size() != active_ids.size(): return _reject("mission_crew_unsupported")
	for id in active_ids:
		if typeof(id) != TYPE_STRING or deployed[id] != true or not is_instance_valid(registry.get_unit(id)): return _reject("mission_crew_unsupported")
	if not active_ids.has(pilot): return _reject("mission_crew_unsupported")
	var home: Dictionary = HOME_STORE.load_checkpoint()
	if not home.get("ok",false): return home
	var start = flow.get("_campaign_start")
	if start == null: return _reject("campaign_owner_unavailable")
	var identity_home: Dictionary = home.payload.duplicate(true)
	start.get_script()._migrate_known_main_starter(identity_home)
	var run: Dictionary = start.get_script().resolve_checkpoint_run_id(identity_home,false)
	if not run.get("ok",false) or run.id != String(start.get("campaign_run_id")): return _reject("campaign_run_mismatch")
	var home_digest := FileAccess.get_sha256(HOME_STORE.DEFAULT_PATH)
	var roster: Array = Array(flow.get("_all_team_units")).duplicate(true)
	var roster_ids: Array = []
	for person in roster:
		if not person is Dictionary or typeof(person.get("unit_id")) != TYPE_STRING or roster_ids.has(person.unit_id): return _reject("invalid_campaign_roster")
		roster_ids.append(person.unit_id)
	var home_ids: Array = []
	for person in home.payload.roster: home_ids.append(person.unit_id)
	roster_ids.sort(); home_ids.sort()
	if roster_ids != home_ids or home.payload.craft.definition.get("craft_id") != craft_id: return _reject("home_checkpoint_mismatch")
	# Scene setup must not reconstruct older equipment or team definitions.
	var home_craft: Dictionary = home.payload.craft
	var current_loadouts: Dictionary = setup.get("member_loadouts")
	var saved_loadouts: Dictionary = home_craft.get("member_loadouts", {})
	for id in active_ids:
		if current_loadouts.get(id) != saved_loadouts.get(id) or not current_loadouts.has(id): return _reject("mission_loadout_changed")
	if JSON.stringify(setup.get("selected_fireteam_definitions"),"",true) != JSON.stringify(home_craft.get("fireteam_definitions",[]),"",true): return _reject("mission_fireteams_changed")
	var base: Node = runtime.get("_base_personnel")
	if not is_instance_valid(base) or not base.has_method("export_state"): return _reject("home_personnel_unavailable")
	var base_states: Dictionary = base.get("_states")
	if base_states.size()!=active_ids.size(): return _reject("home_personnel_unsupported")
	for id in active_ids:
		var person: Variant = base_states.get(id)
		if not person is Dictionary or person.get("status")!="aboard" or person.get("craft_id")!=craft_id or not Dictionary(person.get("action",{})).is_empty(): return _reject("home_personnel_unsupported")
	var base_state: Dictionary = base.export_state()
	if base_state.get("version")!=1 or not base_state.get("units") is Dictionary or base_state.units.size()!=active_ids.size(): return _reject("home_personnel_unsupported")
	if not home_hex.is_empty():
		var checked_home: Dictionary = preload("res://scripts/mission/campaign_hex_home_checkpoint.gd").validate(home_hex, base_state, craft_id)
		if not checked_home.get("ok",false): return checked_home
	var campaign: RefCounted = runtime.get("_campaign")
	var supply: RefCounted = runtime.get("_supply")
	var onboarding: RefCounted = runtime.get("_onboarding")
	var equipment: RefCounted = runtime.get("_ship_equipment")
	var market: RefCounted = runtime.get("_polisa_market")
	if campaign == null or supply == null or onboarding == null or equipment == null or market == null: return _reject("campaign_owner_unavailable")
	var pad_bindings: Dictionary = runtime.get("_pad_by_craft")
	var token_bindings: Dictionary = runtime.get("_departure_token_by_craft")
	if pad_bindings.size()!=1 or token_bindings.size()!=1 or typeof(pad_bindings.get(craft_id))!=TYPE_STRING or String(pad_bindings[craft_id]).is_empty() or token_bindings.get(craft_id)!=identity.departure_token: return _reject("mission_route_binding_mismatch")
	var campaign_state: Dictionary = campaign.export_state()
	var route: Dictionary = campaign_state.get("departures_by_craft_id",{}).get(craft_id,{})
	if route.get("landing_pad_id") != pad_bindings[craft_id] or not runtime._built_home_pad_ids().has(pad_bindings[craft_id]): return _reject("mission_route_binding_mismatch")
	var job: Dictionary = campaign_state.get("jobs",{}).get(identity.job_id,{})
	var place: Dictionary = campaign_state.get("locations",{}).get(identity.location_id,{})
	if job.get("status") != "active" or job.get("scenario_id") != identity.scenario_id or job.get("location_id") != identity.location_id or String(setup.get("map_file_path")) != String(place.get("map_file_path","")) or String(setup.get("scenario_file_path")) != "res://data/mission_scenarios/" + String(identity.scenario_id) + ".json": return _reject("mission_scenario_mismatch")
	var campaign_candidate = campaign.get_script().new()
	var checked: Dictionary = campaign_candidate.restore_state(campaign_state)
	if not checked.get("ok",false): return checked
	var supply_state: Dictionary = supply.export_state()
	var supply_candidate = supply.get_script().new()
	checked = supply_candidate.restore_state(supply_state)
	if not checked.get("ok",false): return checked
	var onboarding_state: Dictionary = onboarding.export_state()
	var onboarding_candidate = onboarding.get_script().new()
	checked = onboarding_candidate.restore_state(onboarding_state)
	if not checked.get("ok",false): return checked
	var equipment_state: Dictionary = equipment.export_state()
	var equipment_candidate = equipment.get_script().new()
	checked = equipment_candidate.configure(definitions)
	if not checked.get("ok",false): return checked
	checked = equipment_candidate.restore_state(equipment_state,definitions,supply_state.requests,supply_state.get("inventory",{}))
	if not checked.get("ok",false): return checked
	var market_state: Dictionary = market.export_state()
	var market_candidate = market.get_script().new()
	checked = market_candidate.restore_state(market_state)
	if not checked.get("ok",false): return checked
	var actors := ACTORS.new()
	var actor_state: Dictionary = actors.export_actors(sim)
	if not actor_state.get("ok",false): return actor_state
	if not sim.is_hex_ground_runtime_active(): return _reject("hex_ground_inactive")
	var exported: Dictionary = sim.export_hex_checkpoint_state()
	if not exported.get("ok",false): return exported
	var ground_state := {"ok":true,"schema":"hex_mission_ground.v1","checkpoint":exported.state}
	var selected: Dictionary = flow.call("_get_selected_mission_definition")
	var mission_config := {"time_limit_seconds":float(driver.get("mission_time_limit_seconds")),"win_condition":String(driver.get("win_condition"))}
	var scenario: Variant = setup.get("_mission_scenario")
	if scenario == null: return _reject("mission_configuration_mismatch")
	var scenario_limit := float(scenario.get("time_limit_seconds"))
	var expected_limit := scenario_limit if scenario_limit>0.0 else float(selected.get("time_limit_seconds",1200.0))
	var scenario_win := String(scenario.get("win_condition")).strip_edges().to_lower()
	var expected_win := scenario_win if not scenario_win.is_empty() else String(selected.get("win_condition",""))
	if selected.get("mission_id")!=identity.scenario_id or expected_limit!=mission_config.time_limit_seconds or expected_win!=mission_config.win_condition: return _reject("mission_configuration_mismatch")
	var lifecycle := LIFECYCLE.new()
	var lifecycle_state: Dictionary = lifecycle.export_state(sim,driver)
	if not lifecycle_state.get("ok",false): return lifecycle_state
	var transport: Dictionary = controller.export_transport_checkpoint()
	if transport.get("schema") != "mission_transport_checkpoint.v1": return transport if transport.get("ok",true) == false else _reject("transport_checkpoint_unavailable")
	var fleet_state: Dictionary = travel.export_checkpoint_state()
	if fleet_state.get("schema") != "space_fleet_checkpoint.v1": return fleet_state if fleet_state.get("ok",true) == false else _reject("fleet_checkpoint_unavailable")
	var root: Node = runtime.get("_simulation")
	if not is_instance_valid(root): return _reject("space_owner_unavailable")
	var space: RefCounted = root.get("_space_combat_state")
	var wing: RefCounted = root.get("_space_wing_state")
	if space == null or wing == null: return _reject("space_owner_unavailable")
	var navigation: Dictionary = space.export_navigation_checkpoint()
	var systems: Dictionary = space.export_systems_checkpoint()
	var wings: Dictionary = wing.export_checkpoint_state()
	for pair in [[navigation,"space_navigation_checkpoint.v1"],[systems,"space_systems_checkpoint.v1"],[wings,"space_wing_checkpoint.v1"]]:
		if pair[0].get("schema") != pair[1]: return pair[0] if pair[0].get("ok",true)==false else _reject("space_checkpoint_unavailable")
	var receipt_bindings := {"fleet":travel,"supply":supply,"campaign":campaign,"equipment":equipment,"adapter":runtime}
	var root_receipts: Dictionary = ROOT_RECEIPTS.capture(root,receipt_bindings)
	if root_receipts.get("schema") != "root_receipt_checkpoint.v1": return root_receipts if root_receipts.get("ok",true)==false else _reject("root_receipt_checkpoint_unavailable")
	var requests := CODEC.encode_value(Dictionary(runtime.get("_space_operation_requests")))
	if not requests.ok: return requests
	var orbit_bindings := {"simulation_root":root,"fleet":travel,"combat":space,"campaign":campaign,"space_operation_requests":Dictionary(runtime.get("_space_operation_requests"))}
	var orbit: Dictionary = ORBIT.capture(runtime,orbit_bindings)
	if orbit.get("schema")!="orbit_intent_checkpoint.v1": return orbit if orbit.get("ok",true)==false else _reject("orbit_checkpoint_unavailable")
	var components := {"home_sha256":home_digest,"campaign_run_id":run.id,"identity":identity.duplicate(true),"pilot_id":pilot,"active_ids":active_ids,"roster":roster,"campaign":campaign_state,"supply":supply_state,"onboarding":onboarding_state,"equipment":equipment_state,"market":market_state,"fleet":fleet_state,"navigation":navigation,"systems":systems,"wings":wings,"actors":actor_state,"ground":ground_state,"lifecycle":lifecycle_state,"transport":transport,"root_receipts":root_receipts,"space_requests":requests.value,"route_bindings":{"pad":pad_bindings[craft_id],"departure_token":token_bindings[craft_id]},"base_personnel":base_state,"mission_config":mission_config,"orbit_intent":orbit}
	if not home_hex.is_empty(): components["home_hex_tactical"] = home_hex
	return {"ok":true,"complete":false,"missing":["world_transaction","restore_scene"],"components":components}

static func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
