extends RefCounted
## Prepares a new, unpublished strategic world for a stable campaign surface
## checkpoint. Mission scene, actors, ground, transport and root publication
## must still be prepared/validated separately by the enclosing transaction.
const HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const START = preload("res://scripts/meta/campaign_start_configuration.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const ONBOARDING = preload("res://scripts/core/campaign_onboarding_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const MARKET = preload("res://scripts/meta/polisa_recruitment_market.gd")
const SPACE = preload("res://scripts/core/space_combat_state.gd")
const WINGS = preload("res://scripts/core/space_wing_state.gd")
const RECEIPTS = preload("res://scripts/mission/root_receipt_checkpoint.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const ORBIT = preload("res://scripts/mission/orbit_intent_checkpoint.gd")

static func prepare(data: Dictionary, adapter: Node, target_root: Node = null) -> Dictionary:
	var keys := ["home_sha256", "campaign_run_id", "identity", "pilot_id", "active_ids", "roster", "campaign", "supply", "onboarding", "equipment", "market", "fleet", "navigation", "systems", "wings", "actors", "ground", "lifecycle", "transport", "root_receipts", "space_requests", "route_bindings", "base_personnel", "mission_config", "orbit_intent"]
	if data.has("home_hex_tactical"): keys.append("home_hex_tactical")
	if data.size()!=keys.size() or not data.has_all(keys) or not is_instance_valid(adapter) or not adapter.has_method("preview_departure") or not adapter.has_method("_built_home_pad_ids"): return _bad("invalid_active_checkpoint")
	for key in ["identity","campaign","supply","onboarding","equipment","market","fleet","navigation","systems","wings","actors","ground","lifecycle","transport","root_receipts","orbit_intent"]:
		if not data[key] is Dictionary: return _bad("invalid_active_checkpoint")
	if typeof(data.home_sha256)!=TYPE_STRING or data.home_sha256.length()!=64 or data.home_sha256!=FileAccess.get_sha256(HOME.DEFAULT_PATH) or typeof(data.campaign_run_id)!=TYPE_STRING or not data.roster is Array or not data.active_ids is Array or typeof(data.pilot_id)!=TYPE_STRING: return _bad("active_home_mismatch")
	var home: Dictionary = HOME.load_checkpoint()
	if not home.get("ok",false): return home
	var migrated: Dictionary = home.payload.duplicate(true)
	START._migrate_known_main_starter(migrated)
	if migrated.has("hex_tactical") and not data.has("home_hex_tactical"): return _bad("active_home_hex_missing")
	var run: Dictionary = START.resolve_checkpoint_run_id(migrated,false)
	if not run.get("ok",false) or run.id!=data.campaign_run_id: return _bad("active_home_mismatch")
	var identity: Dictionary = data.identity
	for field in ["craft_id","location_id","scenario_id","job_id","departure_token"]:
		if typeof(identity.get(field))!=TYPE_STRING or identity[field].is_empty(): return _bad("invalid_active_identity")
	var craft_id: String = identity.craft_id
	var fleet_defs: Array = Array(migrated.get("fleet",[{"definition":migrated.craft.definition,"pilot_id":migrated.craft.pilot_id}]))
	if fleet_defs.size()!=1 or not fleet_defs[0] is Dictionary or not fleet_defs[0].get("definition") is Dictionary or fleet_defs[0].definition.get("craft_id")!=craft_id or fleet_defs[0].get("pilot_id")!=data.pilot_id: return _bad("active_fleet_mismatch")
	var ids: Array = []
	for person in data.roster:
		if not person is Dictionary or typeof(person.get("unit_id"))!=TYPE_STRING or person.unit_id.is_empty() or ids.has(person.unit_id): return _bad("invalid_active_roster")
		ids.append(person.unit_id)
	var old_ids: Array = []
	for person in migrated.roster: old_ids.append(person.unit_id)
	ids.sort(); old_ids.sort()
	var active: Array = data.active_ids.duplicate()
	active.sort()
	if ids!=old_ids or active!=ids or not ids.has(data.pilot_id): return _bad("active_roster_mismatch")
	var base: Variant = data.get("base_personnel")
	if data.has("home_hex_tactical"):
		var home_hex: Dictionary = preload("res://scripts/mission/campaign_hex_home_checkpoint.gd").validate(data.home_hex_tactical, base, craft_id)
		if not home_hex.get("ok",false): return home_hex
	if not base is Dictionary or base.size()!=2 or base.get("version")!=1 or not base.get("units") is Dictionary or base.units.size()!=active.size(): return _bad("active_base_personnel_invalid")
	for id in active:
		var person: Variant = base.units.get(id)
		if not person is Dictionary or person.get("status")!="aboard" or person.get("craft_id")!=craft_id or person.get("bed_id")!="" or not person.get("position") is Array or person.position.size()!=2 or typeof(person.get("auto_rest_enabled"))!=TYPE_BOOL or typeof(person.get("rest_automatic"))!=TYPE_BOOL: return _bad("active_base_personnel_invalid")
		for axis in person.position:
			if typeof(axis) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(axis)): return _bad("active_base_personnel_invalid")
	# This first narrow restore cannot yet merge a changed roster into the
	# home personnel owner. Refuse it instead of recreating stale people.
	if JSON.stringify(data.roster,"",true) != JSON.stringify(migrated.roster,"",true): return _bad("active_roster_changed")
	var campaign = CAMPAIGN.new()
	var checked: Dictionary = campaign.restore_state(data.campaign)
	if not checked.get("ok",false): return checked
	var job: Dictionary = data.campaign.get("jobs",{}).get(identity.job_id,{})
	var departure: Dictionary = data.campaign.get("departures_by_craft_id",{}).get(craft_id,{})
	if job.get("status")!="active" or job.get("scenario_id")!=identity.scenario_id or job.get("location_id")!=identity.location_id or departure.get("destination_location_id")!=identity.location_id or departure.get("job_id")!=identity.job_id: return _bad("active_campaign_mismatch")
	var mission_config: Variant = data.get("mission_config")
	if not mission_config is Dictionary or mission_config.size()!=2 or typeof(mission_config.get("time_limit_seconds")) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(mission_config.time_limit_seconds)) or typeof(mission_config.get("win_condition"))!=TYPE_STRING: return _bad("active_mission_config_invalid")
	var matching_missions := []
	for entry in Array(adapter.get("_flow").get("_mission_catalog")):
		if entry is Dictionary and entry.get("mission_id")==identity.scenario_id: matching_missions.append(entry)
	if matching_missions.size()!=1: return _bad("active_mission_config_invalid")
	var scenario_path: String = matching_missions[0].get("scenario_file_path", "")
	if scenario_path != "res://data/mission_scenarios/" + identity.scenario_id + ".json": return _bad("active_mission_config_invalid")
	var scenario = load("res://scripts/mission/mission_scenario_data.gd").load_from_file(scenario_path)
	if scenario == null: return _bad("active_mission_config_invalid")
	var scenario_limit := float(scenario.get("time_limit_seconds"))
	var expected_limit := scenario_limit if scenario_limit>0.0 else float(matching_missions[0].get("time_limit_seconds",1200.0))
	var scenario_win := String(scenario.get("win_condition")).strip_edges().to_lower()
	var expected_win := scenario_win if not scenario_win.is_empty() else String(matching_missions[0].get("win_condition",""))
	if expected_limit!=float(mission_config.time_limit_seconds) or expected_win!=mission_config.win_condition: return _bad("active_mission_config_invalid")
	var route_bindings: Variant = data.get("route_bindings")
	if not route_bindings is Dictionary or route_bindings.size()!=2 or typeof(route_bindings.get("pad"))!=TYPE_STRING or route_bindings.pad.is_empty() or route_bindings.get("departure_token")!=identity.departure_token or departure.get("landing_pad_id")!=route_bindings.pad or not adapter._built_home_pad_ids().has(route_bindings.pad): return _bad("active_route_binding_mismatch")
	var supply = SUPPLY.new()
	checked = supply.restore_state(data.supply)
	if not checked.get("ok",false): return checked
	# The current home scene is constructed from the last home checkpoint.
	# Until base reconstruction is transactional, never pair it with a
	# different set of modular rooms or paid beds/pads from the away state.
	var old_supply = SUPPLY.new()
	checked = old_supply.restore_state(migrated.get("supply", {}))
	if not checked.get("ok",false): return checked
	if old_supply.get_modular_base() != supply.get_modular_base() or old_supply.get_campaign_bed_count() != supply.get_campaign_bed_count() or old_supply.get_campaign_housing_count() != supply.get_campaign_housing_count(): return _bad("active_base_layout_changed")
	var onboarding = ONBOARDING.new()
	checked = onboarding.restore_state(data.onboarding)
	if not checked.get("ok",false): return checked
	var equipment = EQUIPMENT.new()
	var definitions := [fleet_defs[0].definition]
	checked = equipment.restore_state(data.equipment,definitions,data.supply.get("requests",{}),data.supply.get("inventory",{}))
	if not checked.get("ok",false): return checked
	var market = MARKET.new()
	checked = market.restore_state(data.market)
	if not checked.get("ok",false): return checked
	var fleet_builder = FLEET.new()
	checked = fleet_builder.configure()
	if not checked.get("ok",false): return checked
	checked = fleet_builder.prepare_checkpoint_restore(data.fleet,[craft_id])
	if not checked.get("ok",false): return checked
	var fleet: RefCounted = checked.candidate
	var travel: Dictionary = fleet.get_craft_snapshot(craft_id)
	if travel.get("phase")!="surface" or travel.get("location_id")!=identity.location_id: return _bad("active_travel_mismatch")
	var flights := {craft_id:fleet.get_flight_state(craft_id)}
	var control_bindings := {craft_id:{"equipment_owner":equipment}}
	var navigation: Dictionary = SPACE.prepare_navigation_checkpoint_candidate(data.navigation,flights,control_bindings)
	if not navigation.get("ok",false): return navigation
	var space: RefCounted = navigation.candidate
	var systems_data := CODEC.decode_value(data.systems.get("payload"))
	if not systems_data.ok or not systems_data.value is Dictionary or not systems_data.value.get("systems") is Dictionary: return _bad("invalid_systems_checkpoint")
	for id in systems_data.value.systems:
		if id!=craft_id or space.get_actor(id)==null and space.get_inactive_actor(id)==null: return _bad("active_space_actor_mismatch")
		var stats: Dictionary = equipment.get_space_combat_stats(id)
		checked = space.bind_ship_systems(id,stats,float(stats.get("hull_capacity",0.0)))
		if not checked.get("ok",false): return checked
	var systems: Dictionary = space.prepare_systems_checkpoint_restore(data.systems)
	if not systems.get("ok",false): return systems
	checked = space.validate_systems_checkpoint_restore(systems.prepared)
	if not checked.get("ok",false): return checked
	space._publish_systems_checkpoint_restore(systems.prepared)
	var wing = WINGS.new()
	var wing_prepared: Dictionary = wing.prepare_checkpoint_restore(data.wings,"singleplayer",[craft_id])
	if not wing_prepared.get("ok",false): return wing_prepared
	checked = wing.commit_checkpoint_restore(wing_prepared.prepared)
	if not checked.get("ok",false): return checked
	var requests := CODEC.decode_value(data.space_requests)
	if not requests.ok or not requests.value is Dictionary: return _bad("invalid_space_requests")
	if requests.value.size() > 4096: return _bad("invalid_space_requests")
	var operations := ["space_open_operations", "space_close_map", "space_prepare_launch", "space_start_quantum", "space_abort_quantum", "space_begin_approach", "space_begin_station_dock", "space_land_homebase"]
	for id in requests.value:
		var request: Variant = requests.value[id]
		if typeof(id)!=TYPE_STRING or id.is_empty() or not request is Dictionary or request.size()!=2 or typeof(request.get("signature"))!=TYPE_STRING or not request.get("result") is Dictionary or request.result.get("ok")!=true: return _bad("invalid_space_requests")
		var signature: Variant = JSON.parse_string(request.signature)
		if not signature is Dictionary or signature.size()!=2 or not signature.get("payload") is Dictionary or signature.get("operation") not in operations or signature.payload.get("craft_id")!=craft_id or JSON.stringify(signature,"",true)!=request.signature: return _bad("invalid_space_requests")
	var owned_root := not is_instance_valid(target_root)
	var root: Node = SIM.new() if owned_root else target_root
	if owned_root: root.set_physics_process(false)
	var bound: Dictionary = fleet.configure_space_area_transition_authority(root)
	if not bound.get("ok",false) or not supply.bind_route_fuel_preparation_authority(root) or not campaign.configure_departure_preparation_authority(root).get("ok",false):
		if owned_root: root.free()
		return _bad("active_authority_unavailable")
	var bindings := {"fleet":fleet,"supply":supply,"campaign":campaign,"equipment":equipment,"adapter":adapter}
	var receipt: Dictionary
	if owned_root:
		root.configure_singleplayer_owners(campaign,supply,onboarding,fleet)
		root.configure_ship_equipment(equipment)
		checked = root.configure_departure_adapter(adapter)
		if not checked.get("ok",false): root.free(); return checked
		root.set("_space_combat_state",space)
		root.set("_space_wing_state",wing)
		receipt = RECEIPTS.prepare(root,data.root_receipts,bindings)
	else:
		receipt = RECEIPTS.prepare_prebinding(root,data.root_receipts,bindings)
	if not receipt.get("ok",false):
		if owned_root: root.free()
		return receipt
	checked = RECEIPTS.validate(root,receipt.candidate,bindings) if owned_root else RECEIPTS.validate_prebinding(root,receipt.candidate,bindings)
	if not checked.get("ok",false):
		if owned_root: root.free()
		return checked
	var orbit_bindings := {"simulation_root":adapter.get("_simulation"),"fleet":fleet,"combat":space,"campaign":campaign,"space_operation_requests":requests.value}
	var orbit: Dictionary = ORBIT.prepare(adapter,data.orbit_intent,orbit_bindings)
	if not orbit.get("ok",false):
		if owned_root: root.free()
		return orbit
	checked = ORBIT.validate(adapter,orbit.candidate,orbit_bindings)
	if not checked.get("ok",false):
		if owned_root: root.free()
		return checked
	checked = space.validate_navigation_checkpoint_candidate(data.navigation,control_bindings)
	if not checked.get("ok",false):
		if owned_root: root.free()
		return checked
	return {"ok":true,"root":root,"owned_root":owned_root,"fleet":fleet,"campaign":campaign,"supply":supply,"onboarding":onboarding,"equipment":equipment,"market":market,"space":space,"wing":wing,"bindings":bindings,"receipt_candidate":receipt.candidate,"navigation":data.navigation,"control_bindings":control_bindings,"space_requests":requests.value,"route_bindings":route_bindings.duplicate(true),"orbit_bindings":orbit_bindings,"orbit_candidate":orbit.candidate}

static func _bad(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
