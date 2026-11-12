extends Node
## Scene lifecycle adapter. Gameplay values live in SimulationRoot-bound owners;
## transport phases/payload remain in MetaLayerFlow's existing per-craft path.

const SIM = preload("res://scripts/core/simulation_root.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")

var _base_personnel: Node
var _flow: Node
var _screen: Control
var _simulation: Node
var _campaign: RefCounted
var _supply: RefCounted
var _onboarding: RefCounted
var _travel: RefCounted
var _ship_equipment: RefCounted
var _space_encounter: RefCounted
var _skirmish_economy: RefCounted
var _recruit_candidate_signature := ""
var _recruit_candidates: Array = []
var _resource_owners: Dictionary = {}
var _campaign_mode := false
var _space_route_requested := false
var _local_warp_arrival_enabled := false
var _warp_arrival_feedback: Dictionary = {}
var _request_session := str(Time.get_unix_time_from_system()) + ":" + str(randi())
var _sequence: int = 0
var _pad_by_craft: Dictionary = {}
var _departure_token_by_craft: Dictionary = {}
var _space_operation_requests: Dictionary = {}
const HOME_PADS := ["homebase_pad_01", "homebase_pad_02"]

func configure(flow: Node, screen: Control) -> void:
	_flow = flow
	_screen = screen
	_campaign = CAMPAIGN.new()
	_supply = SUPPLY.new()
	_travel = TRAVEL.new()
	_travel.configure()
	_space_encounter = load("res://scripts/core/campaign_space_encounter.gd").new()
	_campaign_mode = bool(_flow.call("is_campaign_start"))
	if _campaign_mode:
		_onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
		_onboarding.configure()
	var campaign_result: Dictionary = _campaign.configure({}, {}, _campaign_mode)
	var supply_result: Dictionary = _supply.configure(Array(_flow.get("_homebase_aircraft_definitions")))
	if not campaign_result.get("ok", false) or not supply_result.get("ok", false):
		push_error("Singleplayer definitions could not be configured")
		return
	_simulation = SIM.new()
	_simulation.name = "CampaignSimulationRoot"
	add_child(_simulation)
	# Synchronous meta commands have no movement/combat tick workload.
	_simulation.set_physics_process(false)
	_simulation.configure_singleplayer_owners(_campaign, _supply, _onboarding, _travel)
	_simulation.configure_departure_adapter(self)
	_ship_equipment = load("res://scripts/core/singleplayer_ship_equipment_state.gd").new()
	_ship_equipment.configure(Array(_flow.get("_homebase_aircraft_definitions")))
	_simulation.call("configure_ship_equipment", _ship_equipment)
	if _flow.has_meta("skirmish_points_budget"):
		_skirmish_economy = load("res://scripts/core/skirmish_economy_state.gd").new()
		_skirmish_economy.configure(int(_flow.get_meta("skirmish_points_budget")))
		_simulation.configure_skirmish_economy(_skirmish_economy, _apply_skirmish_transaction)
	_screen.call("bind_personnel_loadout_simulation", _simulation, Array(_flow.get("_all_team_units")))

	_simulation.call("configure_space_encounter",_space_encounter)
	_simulation.call("configure_space_runtime_tick", Callable(self, "advance_space_travel"))
	if _campaign_mode:
		var checkpoint: Dictionary = Dictionary(_flow.get("_campaign_start").get("checkpoint"))
		if not checkpoint.is_empty():
			_campaign.restore_state(checkpoint.campaign)
			_supply.restore_state(checkpoint.supply)
			_onboarding.restore_state(checkpoint.onboarding)
			if checkpoint.has("ship_equipment"):
				var equipment_restore: Dictionary = _ship_equipment.restore_state(checkpoint.ship_equipment, Array(_flow.get("_homebase_aircraft_definitions")), checkpoint.supply.requests, checkpoint.supply.get("inventory", {}))
				if not equipment_restore.get("ok", false):
					push_error("Invalid Warp equipment checkpoint")
					return
	if _campaign_mode or _flow.has_meta("skirmish_preset_id"):
		_base_personnel = load("res://scripts/core/base_personnel_runtime.gd").new()
		_base_personnel.name = "BasePersonnelRuntime"
		add_child(_base_personnel)
		_base_personnel.configure(_flow, _screen, _simulation, Dictionary(_flow.get("_campaign_start").get("checkpoint")) if _campaign_mode else {})
		_screen.call("configure_base_personnel_bridge", _base_personnel)
	var inventory_units: Array = []
	var inventory_crafts: Array = []
	for unit in Array(_flow.get("_all_team_units")): inventory_units.append(String(unit.get("unit_id","")))
	for craft in Array(_flow.get("_homebase_aircraft_definitions")): inventory_crafts.append(String(craft.get("craft_id","")))
	_supply.configure_inventory(inventory_units, inventory_crafts, _campaign_mode or _skirmish_economy != null)
	if _campaign_mode and Dictionary(_flow.get("_campaign_start").get("checkpoint")).is_empty():
		_supply.call("configure_start_inventory","campaign")
	if _flow.has_meta("skirmish_preset_id") and not _flow.has_meta("skirmish_restore_payload"):
		var count := inventory_units.size()
		var stock := {"armor_heavy":maxi(2,count/2),"armor_medium":maxi(2,count/2),"rifle":count,"pistol":count,"medictool":maxi(2,count/4),"mining_tool":2,"salvage_tool":2}
		if _flow.get_meta("skirmish_preset_id") == "points":
			stock = {}
		_supply.call("configure_preset_supply", {"credits": int(_flow.get_meta("skirmish_start_credits", 1000)), "stock": stock})
	sync_crafts()
	if _screen.has_method("configure_singleplayer_bridge"):
		_screen.call("configure_singleplayer_bridge", get_snapshot, request_operation)
	var catalog: Array = [] if _campaign_mode else Array(_flow.get("_mission_catalog")).duplicate(true)
	for entry in [
		{"mission_id": "satellite_recovery", "mission_name": "Satellitenbergung", "map_file_path": "res://maps/satellite_crash_site.json", "scenario_file_path": "res://data/mission_scenarios/satellite_recovery.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
		{"mission_id": "polisa_visit", "mission_name": "Polisa besuchen", "map_file_path": "res://maps/polisa_station.json", "scenario_file_path": "res://data/mission_scenarios/polisa_visit.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
		{"mission_id": "trade_outpost_visit", "mission_name": "Handelsaußenposten besuchen", "map_file_path": "res://maps/trade_outpost.json", "scenario_file_path": "res://data/mission_scenarios/trade_outpost_visit.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"}]:
		catalog.append(entry)
	for job: Dictionary in Dictionary(_campaign.get_campaign_snapshot().jobs).values():
		var found := false
		for item: Dictionary in catalog:
			found = found or String(item.get("mission_id","")) == String(job.scenario_id)
		if found: continue
		var place: Dictionary = _campaign.get_campaign_snapshot().locations[job.location_id]
		catalog.append({"mission_id":job.scenario_id,"mission_name":job.title,"map_file_path":place.map_file_path,"scenario_file_path":"res://data/mission_scenarios/"+String(job.scenario_id)+".json","slot_count":4,"time_limit_seconds":1200.0,"win_condition":"objective_capture"})
	_flow.set("_mission_catalog", catalog)
	if _flow.has_meta("skirmish_preset_id"):
		for item: Dictionary in catalog: item["slot_count"] = maxi(int(item.get("slot_count",4)),inventory_units.size())
	if _skirmish_economy != null:
		_screen.set("_operations_mode", "base")

func _request_id(prefix: String, payload: Dictionary) -> String:
	var supplied: String = String(payload.get("request_id", "")).strip_edges()
	if not supplied.is_empty():
		return supplied
	_sequence += 1
	return "%s:%s:%d" % [prefix, _request_session, _sequence]

func _commit(category: String, operation: String, payload: Dictionary, request_id: String, context: Dictionary = {}) -> Dictionary:
	return _simulation.request_singleplayer_command({"contract_category": category, "operation": operation, "payload": payload, "request_id": request_id}, context)

func get_snapshot() -> Dictionary:
	if _simulation == null:
		return {}
	var campaign: Dictionary = _campaign.get_campaign_snapshot()
	var travel: Dictionary = get_space_travel_snapshot()
	var economy: Dictionary = _skirmish_economy.get_snapshot() if _skirmish_economy != null else {}
	if not economy.is_empty(): economy["recruits"] = _get_skirmish_recruits(economy)
	var crafts: Array = []
	var service_contexts: Dictionary = {}
	var launch_readiness: Dictionary = {}
	for definition in Array(_flow.get("_homebase_aircraft_definitions")):
		var id: String = String(definition.get("craft_id", ""))
		var departure: Dictionary = _craft_visit_binding(id)
		var transfer: Dictionary = _flow.call("_find_pending_mission_craft_transfer", id)
		var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(id, "homebase"))
		var projected: Dictionary = definition.duplicate(true)
		projected.merge({"craft_id": id, "landing_pad_id": _home_pad_for(id), "location_id": String(departure.get("destination_location_id", "")) if location == "mission" else location, "busy": not transfer.is_empty() or (String(Dictionary(Dictionary(travel.get("routes",{})).get(id,{})).get("phase","grounded")) in ["orbit", "quantum", "stopped", "approach"]), "departure": departure, "visible_on_pad": location == "homebase" and transfer.is_empty() and not _home_pad_for(id).is_empty()}, true)
		var pad_visual: Dictionary = {}
		var transfer_phase := String(transfer.get("phase",""))
		if (transfer_phase=="to_mission" and location=="homebase") or transfer_phase=="to_homebase":
			var duration := maxf(float(transfer.get("duration_seconds",1.0)),.001)
			pad_visual={"phase":"departing" if transfer_phase=="to_mission" else "inbound","progress":clampf(float(transfer.get("elapsed_seconds",0.0))/duration,0.0,1.0),"duration_seconds":duration}
		projected["pad_visual"]=pad_visual
		crafts.append(projected)
		launch_readiness[id] = validate_space_launch(id, false)
		var context: Dictionary = _service_context(id)
		if not context.is_empty():
			service_contexts[id] = context
	return {"space_wings": _simulation.get_space_wing_snapshot(), "ship_equipment": _ship_equipment.get_snapshot() if _ship_equipment != null else {}, "location_view": _flow.call("get_location_view_snapshot") if _flow.has_method("get_location_view_snapshot") else {}, "home_services": _home_services_snapshot(), "skirmish_economy": economy, "campaign": campaign, "supply": _supply.get_supply_snapshot(), "crafts": crafts, "service_contexts_by_craft_id": service_contexts, "runtime_authority": "SimulationRoot", "mode": "campaign" if _campaign_mode else "skirmish", "base_personnel": _base_personnel.get_snapshot() if _base_personnel != null else {}, "onboarding": _onboarding.get_snapshot() if _onboarding != null else {}, "space_travel": travel, "space_encounter":_space_encounter.get_snapshot(), "space_launch_readiness_by_craft_id": launch_readiness,"location_runtimes":_flow.call("get_location_runtime_snapshot"),"checkpoint_guard":get_world_checkpoint_guard()}

func sync_crafts() -> void:
	# Lifecycle event only, called when real craft definitions change. Read paths
	# neither allocate a pad nor initialize fuel. Existing assignments never move.
	if _flow == null or _supply == null:
		return
	if _campaign_mode:
		_flow.set_meta("campaign_pad2_built",bool(_campaign.get_campaign_snapshot().progress.second_pad_built))
	if _campaign_mode and _supply.get_station_home_pads() > 2:
		_flow.set_meta("skirmish_infrastructure", {"pads":_supply.get_station_home_pads()})
		if _base_personnel != null: _base_personnel.call("_refresh_capacity")
	var actual: Dictionary = {}
	for definition in Array(_flow.get("_homebase_aircraft_definitions")):
		if _ship_equipment != null: _ship_equipment.register_craft(definition)
		var craft_id: String = String(definition.get("craft_id", ""))
		if not craft_id.is_empty():
			actual[craft_id] = true
	for craft_id in _pad_by_craft.keys():
		if not actual.has(craft_id):
			_pad_by_craft.erase(craft_id)
			_departure_token_by_craft.erase(craft_id)
	var inventory_units: Array=[]
	for unit in Array(_flow.get("_all_team_units")): inventory_units.append(String(unit.get("unit_id","")))
	_supply.configure_inventory(inventory_units, actual.keys(), _campaign_mode or _skirmish_economy != null)
	for craft_id in actual:
		_supply.register_craft(String(craft_id))
		_travel.register_craft(String(craft_id))
		if _pad_by_craft.has(craft_id):
			continue
		var pads: Array = HOME_PADS.duplicate()
		if (_flow.has_meta("skirmish_preset_id") or _campaign_mode) and _base_personnel != null:
			pads.clear()
			for actual_pad: Dictionary in Array(_base_personnel.get_snapshot().get("layout",{}).get("landing_pads",[])):
				pads.append(String(actual_pad.get("id","")))
		for pad in pads:
			if _campaign_mode and pad == "homebase_pad_02" and not bool(_campaign.get_campaign_snapshot().progress.second_pad_built): continue
			if not _pad_by_craft.values().has(pad):
				_pad_by_craft[craft_id] = pad
				break

	if _base_personnel != null: _base_personnel.call("_refresh_capacity")
	sync_space_wings()

func _home_pad_for(craft_id: String) -> String:
	return String(_pad_by_craft.get(craft_id, ""))

func get_base_personnel_runtime() -> Node:
	return _base_personnel

func sync_space_wings() -> Dictionary:
	if _simulation == null or not is_instance_valid(_flow):
		return _reject("runtime_unavailable", "Rottenverwaltung ist nicht bereit")
	var definitions: Variant = _flow.get("_homebase_aircraft_definitions")
	var pilots: Variant = _flow.get("_assigned_aircraft_pilot_by_craft")
	if typeof(definitions) != TYPE_ARRAY or typeof(pilots) != TYPE_DICTIONARY:
		return _reject("pilot_state_unavailable", "Pilotenzuordnung ist nicht verfuegbar")
	var craft_ids: Array = []
	for definition in definitions:
		if typeof(definition) == TYPE_DICTIONARY and typeof(definition.get("craft_id")) == TYPE_STRING:
			craft_ids.append(definition.craft_id)
	return _simulation.reconcile_space_wings(craft_ids, pilots, {"runtime_authorized":true})

func request_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
	if operation == "space_move":
		if _simulation == null: return _reject("runtime_unavailable", "Weltraumsimulation ist nicht bereit")
		return _simulation.request_singleplayer_space_move(payload.duplicate(true))
	if operation == "space_wing_command":
		if typeof(payload.get("command")) != TYPE_DICTIONARY:
			return _reject("invalid_command", "Rottenauftrag ist ungueltig")
		return _request_space_wing_command(payload.command)
	if operation == "select_location_view_craft":
		return _flow.call("select_location_view_craft", String(payload.get("location_id", "")), String(payload.get("craft_id", "")))
	if payload.has("service_location_id") and operation in ["buy", "sell", "refuel", "inventory_transfer", "inventory_equip", "return_homebase", "station_buy_ship", "station_build_home_pad", "station_install_ship_component", "station_deploy_crew", "station_handoff_crew", "station_board_crew"]:
		var live_context := _service_context(String(payload.get("craft_id", "")))
		if String(payload.service_location_id).is_empty() or String(live_context.get("location_id", "")) != String(payload.service_location_id):
			return _reject("service_location_changed", "Schiff ist nicht mehr am gewählten Versorgungsort")
	if operation.begins_with("skirmish_"):
		var data := payload.duplicate(true)
		var request_id := _request_id(operation, data)
		data.erase("request_id")
		var result: Dictionary = _simulation.request_skirmish_command({"operation": operation.trim_prefix("skirmish_"), "payload": data, "request_id": request_id})
		if bool(result.get("ok", false)):
			_flow.call("_refresh_homebase_screen")
		return result
	if operation.begins_with("base_"):
		return _base_personnel.request_operation(operation, payload) if _base_personnel != null else _reject("base_unavailable", "Basisaktion nur in Kampagne")
	if _simulation == null:
		return _reject("runtime_unavailable", "Kampagne noch nicht bereit")
	if operation in ["station_deploy_crew", "station_handoff_crew", "station_board_crew"]:
		var target := String(payload.get("craft_id", ""))
		if String(_service_context(target).get("location_id", "")) != "polisa": return _reject("station_service_required", "Schiff zuerst auf Polisa bereitstellen")
		if operation == "station_board_crew":
			return _flow.call("board_polisa_craft_crew", target) if _flow.has_method("board_polisa_craft_crew") else _reject("crew_boarding_unavailable", "Einsteigen nicht verfügbar")
		if operation == "station_deploy_crew":
			return _flow.call("deploy_polisa_craft_crew", target) if _flow.has_method("deploy_polisa_craft_crew") else _reject("crew_handoff_unavailable", "Besatzungsübergabe nicht verfügbar")
		if String(payload.get("target_craft_id", "")) != target or typeof(payload.get("unit_ids")) != TYPE_ARRAY: return _reject("invalid_crew_handoff", "Besatzungsauswahl ungültig")
		return _flow.call("handoff_polisa_station_crew", String(payload.get("source_craft_id", "")), target, PackedStringArray(payload.unit_ids), String(payload.get("pilot_id", "")), _request_id("station-handoff", payload)) if _flow.has_method("handoff_polisa_station_crew") else _reject("crew_handoff_unavailable", "Besatzungsübergabe nicht verfügbar")
	if operation == "buy" and _campaign_mode and String(payload.get("offer_id","")) == "mining_tool_supply" and not Array(_supply.get_supply_snapshot().get("blueprints",[])).has("mining_tool"):
		return _reject("blueprint_locked","Miningwerkzeug nach dem Blueprint aus Mission 3 verfügbar")
	var data: Dictionary = payload.duplicate(true)
	var request_id: String = _request_id(operation, data)
	data.erase("request_id")
	if operation in ["campaign_space_engage","campaign_space_rescue","campaign_space_retreat"]:
		var op := String(operation).trim_prefix("campaign_space_")
		var result := _commit("campaign_space",op,data,request_id)
		_finish_space_encounter_result()
		return result
	if operation in ["campaign_upload","campaign_recruit","campaign_load_crate","campaign_deliver","campaign_build_pad","campaign_fabricate","campaign_research"]:
		return _request_campaign_action(operation,data,request_id)
	if operation=="focus_location":
		return _flow.call("focus_location",String(data.get("location_id","")))
	if operation=="space_focus_craft":
		return {"ok":_travel.focus_craft(String(data.get("craft_id","")))}
	if operation.begins_with("space_"):
		return _request_space_operation(operation, data, request_id)
	if _campaign_mode:
		var gate: Dictionary = _campaign_operation_gate(operation, data)
		if not bool(gate.get("ok", false)):
			return gate
		if operation == "accept_job" and String(Dictionary(_campaign.get_campaign_snapshot().jobs.get(String(data.get("job_id", "")), {})).get("status", "")) == "failed":
			if _flow.get("_active_mission") != null or _has_active_transit():
				return _reject("retry_requires_home", "Erst zur Basis zurueckkehren, dann Auftrag erneut annehmen")
			for location in Dictionary(_flow.get("_aircraft_location_by_craft")).values():
				if String(location) != "homebase":
					return _reject("retry_requires_home", "Erst zur Basis zurueckkehren, dann Auftrag erneut annehmen")
	if operation in ["accept_job", "select_destination", "abandon_job"]:
		if operation == "select_destination" and not Dictionary(_flow.call("_find_pending_mission_craft_transfer",String(data.get("craft_id",_travel.get_snapshot().craft_id)))).is_empty():
			return _reject("craft_in_transit", "Zielwechsel erst nach dem laufenden Flug")
		if operation == "select_destination":
			var travel: Dictionary = _travel.get_snapshot(String(data.get("craft_id", "")))
			if String(travel.phase) != "grounded" and not _in_destination_orbit(travel, String(data.get("location_id", ""))):
				return _reject("destination_orbit_required", "Erst den Orbit des Zielorts erreichen.")

		var campaign_operation: String = "fail_job" if operation == "abandon_job" else operation
		if _campaign_mode and operation == "accept_job" and String(Dictionary(_campaign.get_campaign_snapshot().jobs.get(String(data.get("job_id", "")), {})).get("status", "")) == "failed":
			campaign_operation = "retry_failed_job"
		var result: Dictionary = _commit("singleplayer_campaign", campaign_operation, data, request_id, {"mission_aborted": operation == "abandon_job"})
		if result.get("ok", false) and operation == "select_destination":
			var location_id: String = String(data.get("location_id", ""))
			if location_id != "homebase":
				var snap: Dictionary = _campaign.get_campaign_snapshot()
				var selected_job: Dictionary = Dictionary(snap.jobs.get(String(snap.selected_job_id),{}))
				var scenario := String(selected_job.get("scenario_id",String(snap.locations[location_id].scenario_file_path).get_file().get_basename()))
				_flow.call("_on_homebase_mission_selection_changed",scenario)
		return result
	if operation in ["station_buy_ship", "station_build_home_pad", "station_install_ship_component"]:
		var craft_id := String(data.get("craft_id", ""))
		var context := _service_context(craft_id)
		if String(context.get("location_id", "")) != "polisa": return _reject("station_service_required", "Zuerst am Stationsschalter anmelden")
		context["station_service_verified"] = true
		context["station_ship_fulfillment"] = _fulfill_polisa_ship
		context["station_local_ship_fulfillment"] = _fulfill_polisa_local_ship
		context["station_pad_builder"] = _build_polisa_home_pad
		context["second_pad_built"] = _campaign_mode and bool(_campaign.get_campaign_snapshot().progress.second_pad_built)
		var result := _commit("singleplayer_supply", operation, data, request_id, context)
		if result.get("ok", false):
			if operation == "station_buy_ship" and String(data.get("delivery_mode", "homebase")) == "local" and not bool(result.get("replayed", false)): _flow.call("finalize_polisa_local_ship_purchase", String(result.get("craft_id", "")))
			_flow.call("_refresh_homebase_screen")
		return result
	if operation in ["inventory_transfer","inventory_equip"]:
		var unit_id := String(data.get("unit_id",""))
		var context := _inventory_context(unit_id,String(data.get("craft_id","")))
		if context.is_empty(): return _reject("inventory_access","Person muss an der Basis verfuegbar sein")
		var result := _commit("singleplayer_supply",operation,data,request_id,context)
		if bool(result.get("ok",false)) and operation=="inventory_equip" and not bool(result.get("replayed",false)):
			if _base_personnel!=null and not bool(context.get("station_context", false)): _base_personnel.call("claim_manual_control",unit_id)
			if bool(context.get("station_context", false)): _project_polisa_loadout(unit_id, String(data.get("craft_id", "")), Dictionary(result.get("loadout", {})))
			_screen.call("_refresh_personnel_loadout_projection")
			_screen.call("_emit_homebase_fireteam_context_changed")
		return result
	if operation in ["buy", "refuel", "sell"]:
		if _campaign_mode and operation == "buy":
			var offer: Dictionary = Dictionary(_supply.get_supply_snapshot().offers).get(String(data.get("offer_id","")),{})
			var item := String(offer.get("item_id",""))
			var needed := "mining_tool" if item == "mining_tool" else ("assault_rifle" if item == "rifle" else "")
			if not needed.is_empty() and not Array(_supply.get_supply_snapshot().get("blueprints",[])).has(needed): return _reject("blueprint_locked","Zuerst den passenden Blueprint im Kampagnenauftrag freischalten")
		var craft_id: String = String(data.get("craft_id", ""))
		var context: Dictionary = _service_context(craft_id)
		if context.is_empty():
			return _reject("service_unavailable", "Schiff und Trupp muessen am Serviceort bereit sein")
		context["craft_id"]=craft_id
		context["require_blueprints"]=_campaign_mode
		context["ship_component_model_id"] = String(_ship_equipment.get_snapshot(craft_id).get("model_id", "")) if _ship_equipment != null else ""
		var result: Dictionary = _commit("singleplayer_supply", operation, data, request_id, context)
		if result.get("ok", false) and _campaign_mode and String(context.get("location_id", "")) == "trade_outpost":
			_observe({"trade_used": true, "bought": operation == "buy", "refueled": operation == "refuel"})
		return result
	if operation == "prepare_departure":
		if not is_campaign_mission():
			return {"ok": true}
		return validate_space_launch(String(data.get("craft_id", "")))
	if operation == "return_homebase":
		if not _flow.has_method("_request_singleplayer_return"):
			return _reject("return_unavailable", "Rueckflug noch nicht verfuegbar")
		return _flow.call("_request_singleplayer_return", String(data.get("craft_id", "")))
	return _reject("unknown_operation", "Kampagnenaktion nicht verfuegbar")


func _apply_skirmish_transaction(operation: String, payload: Dictionary) -> Dictionary:
	match operation:
		"build":
			var result: Dictionary = _base_personnel.build_infrastructure(String(payload.item_id), payload.infrastructure)
			if bool(result.get("ok", false)): sync_crafts()
			return result
		"equipment":
			return _supply.receive_skirmish_equipment(String(payload.item_id))
		"person":
			var candidates: Array = _get_skirmish_recruits(_skirmish_economy.get_snapshot())
			var index: Variant = payload.get("candidate_index", 0)
			if typeof(index) != TYPE_INT or index < 0 or index >= candidates.size():
				return _reject("unknown_candidate", "Personenvorschlag bitte erneut auswählen")
			var setup = load("res://scripts/meta/skirmish_start_configuration.gd").new()
			var person: Dictionary = candidates[index].profile.duplicate(true)
			person.unit_id = String(payload.unit_id)
			setup._apply_points_profile(person, payload, payload.role == "pilot", false)
			var result: Dictionary = _flow.call("register_campaign_recruit", person)
			if bool(result.get("ok", false)):
				_simulation.request_personnel_loadout_command("configure_roster", {"roster": [person]})
				_simulation.request_personnel_loadout_command("set_loadout", {"unit_id": person.unit_id,
					"loadout": {"armor": person.armor, "weapon_1": person.weapon_1, "weapon_2": person.weapon_2}})
				result["message"] = "%s rekrutiert" % String(person.display_name)
			return result
		"dismiss":
			var id := String(payload.unit_id)
			var check: Dictionary = _base_personnel.validate_dismiss(id)
			if not bool(check.get("ok", false)): return check
			var returned: Dictionary = _supply.return_skirmish_person_equipment(id, _simulation.get_personnel_loadout_state().get_loadout(id))
			if not bool(returned.get("ok", false)): return returned
			_simulation.request_base_personnel_command("base_cancel", {"unit_id": id})
			_screen.call("request_operation", "remove", {"unit_id": id})
			_base_personnel.remove_person(id)
			_simulation.get_personnel_loadout_state().remove_unit(id)
			_flow.call("remove_skirmish_person", id)
			return {"ok": true, "message": "Personalpreis erstattet · Ausrüstung im Basislager"}
		"ship":
			var snapshot: Dictionary = _skirmish_economy.get_snapshot()
			if Array(_flow.get("_homebase_aircraft_definitions")).size() >= int(snapshot.infrastructure.pads):
				return _reject("no_free_pad", "Zuerst einen freien Landeplatz bauen")
			var entry: Dictionary = load("res://scripts/meta/skirmish_points_catalog.gd").SHIPS[payload.item_id]
			var craft: Dictionary = _flow.call("_build_homebase_aircraft_definition", String(entry.type), 1)
			craft.merge({"craft_id": payload.craft_id, "model_id": payload.item_id, "display_name": entry.name}, true)
			var definitions: Array = _flow.get("_homebase_aircraft_definitions")
			definitions.append(craft)
			var locations: Dictionary = _flow.get("_aircraft_location_by_craft")
			locations[payload.craft_id] = "homebase"
			sync_crafts()
			return {"ok": true, "craft_id": payload.craft_id, "message": "%s auf dem Landeplatz bereit" % entry.name}
		"return_ship":
			var id := String(payload.craft_id)
			if _ship_equipment != null:
				var equipment_return: Dictionary = _ship_equipment.validate_craft_return(id)
				if not equipment_return.get("ok", false): return equipment_return
			if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", id)).is_empty() or String(_flow.get("_aircraft_location_by_craft").get(id, "")) != "homebase" or String(get_space_travel_snapshot(id).get("phase", "grounded")) != "grounded":
				return _reject("craft_away", "Schiff zuerst an der Basis landen")
			if Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).has(id):
				return _reject("craft_occupied", "Pilotenzuweisung zuerst lösen")
			if bool(_flow.call("_has_active_homebase_pilot_transfer", id)) or bool(_flow.call("_has_active_homebase_cargo_load", id)) or Dictionary(_flow.get("_loaded_aircraft_cargo_by_craft")).has(id):
				return _reject("craft_loaded", "Schiff zuerst vollständig entladen")
			for person: Dictionary in _base_personnel.get_snapshot().units:
				if String(person.get("craft_id", "")) == id: return _reject("craft_occupied", "Schiff zuerst vollständig räumen")
			var inventory: Dictionary = _supply.get_supply_snapshot().get("inventory", {})
			if not Dictionary(inventory.get("craft:" + id, {}).get("items", {})).is_empty():
				return _reject("craft_loaded", "Schiffsfracht zuerst entladen")
			if _ship_equipment != null:
				var equipment_removed: Dictionary = _ship_equipment.unregister_unmodified_craft(id)
				if not equipment_removed.get("ok", false): return equipment_removed
			_flow.call("remove_skirmish_craft", id)
			_supply.remove_skirmish_craft(id)
			_travel.unregister_craft(id)
			sync_crafts()
			return {"ok": true, "message": "Schiff zurückgegeben"}
	return _reject("unknown_operation", "Punkteaktion fehlt")


func _get_skirmish_recruits(economy: Dictionary) -> Array:
	var used := {}
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		used[String(unit.get("portrait_id", ""))] = true
	var signature := JSON.stringify([economy.next_person_id, used.keys()])
	if signature != _recruit_candidate_signature:
		_recruit_candidate_signature = signature
		_recruit_candidates.clear()
		var packages := [
			{"role": "operator", "experience": "junior", "armor": "light", "weapon": "rifle"},
			{"role": "medic", "experience": "trained", "armor": "light", "weapon": "rifle"},
			{"role": "pilot", "experience": "junior", "armor": "light", "weapon": "pistol"}]
		var setup = load("res://scripts/meta/skirmish_start_configuration.gd").new()
		for index in range(packages.size()):
			var profile: Dictionary = setup.build_points_person(packages[index], "%s_offer_%d" % [economy.next_person_id, index], used)
			used[String(profile.portrait_id)] = true
			_recruit_candidates.append({"profile": profile, "configuration": packages[index]})
	return _recruit_candidates.duplicate(true)

func _has_active_transit() -> bool:
	return not Array(_flow.get("_pending_mission_craft_transfers")).is_empty()

func _service_context(craft_id: String) -> Dictionary:
	if craft_id.is_empty() or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty():
		return {}
	if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty():
		return {}
	var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, ""))
	if location == "homebase":
		if _home_pad_for(craft_id).is_empty() or not _craft_grounded_at_home(craft_id):
			return {}
		return {"location_id": "homebase", "craft_busy": false}
	var routes: Dictionary = _travel.get_snapshot(craft_id).get("routes", {})
	if routes.has(craft_id) and String(Dictionary(routes[craft_id]).get("phase", "")) not in ["grounded", "surface"]: return {}
	var departure: Dictionary = _craft_visit_binding(craft_id)
	var place_id := String(departure.get("destination_location_id",""))
	if location == "mission" and place_id == "polisa":
		var mission: Node = _flow.call("get_mission_for_craft", craft_id)
		var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
		if controller == null or not bool(controller.call("_is_parked_campaign_dropship", craft_id)): return {}
		# Station-wide service menu after actual docking; walking to the counter is optional.
		return {"location_id":"polisa", "craft_busy":false, "station_service_verified":true}
	if location == "mission" and place_id in ["trade_outpost","satellite_crash"]:
		var card: Dictionary = _flow.call("_find_mission_drop_card_in_planning_state",craft_id)
		if String(card.get("state",card.get("mission_drop_state",""))) not in ["landed","unloading","complete"]: return {}
		var mission: Node = _flow.call("get_mission_for_craft",craft_id)
		var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
		if controller == null or not bool(controller.call("_is_parked_campaign_dropship", craft_id)): return {}
		var driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
		if driver == null or not driver.has_method("get_mission_interaction_runtime_states"): return {}
		var states: Dictionary = driver.call("get_mission_interaction_runtime_states")
		if bool(Dictionary(states.get("trade_service",{})).get("complete",false)) or bool(Dictionary(states.get("deliver_benit",{})).get("complete",false)):
			return {"location_id":place_id,"craft_busy":false}

	return {}

func _in_destination_orbit(travel: Dictionary, location_id: String) -> bool:
	var orbit := String(Dictionary(travel.get("location_orbits", {})).get(location_id, ""))
	return not orbit.is_empty() and location_id != "homebase" and String(travel.get("phase", "")) == "orbit" and String(travel.get("orbit_id", "")) == orbit

func validate_departure(craft_id: String) -> Dictionary:
	return _validate_departure_gates(craft_id, true)

func preview_departure(craft_id: String) -> Dictionary:
	# Preparation must not recover chips or publish onboarding commands.
	# This is a read projection, not a transferable authorization receipt.
	return _validate_departure_gates(craft_id, false)

func preview_reapproach(craft_id: String) -> Dictionary:
	return _validate_departure_gates(craft_id, false, true)

func _validate_departure_gates(craft_id: String, observe_progress: bool, reuse_departure: bool = false) -> Dictionary:
	if _base_personnel != null and not _base_personnel.is_pilot_aboard(craft_id):
		return _reject("pilot_not_aboard", "Zugewiesener Pilot muss tatsaechlich im Schiff sein")
	var travel: Dictionary = get_space_travel_snapshot(craft_id)

	if _campaign_mode:
		if observe_progress:
			observe_campaign_progress()
		var stage: int = int(_onboarding.get_snapshot().stage_index)
		if stage == 0 and not _selected_destination_is_free_visit():
			return _reject("preparation_incomplete", "Zuerst Satellitenauftrag annehmen, Ziel waehlen und Boarding abschliessen")
	var selected: Dictionary = _campaign.get_campaign_snapshot()
	var destination: String = String(selected.selected_location_id)
	var in_destination_orbit := String(travel.get("craft_id", "")) == craft_id and _in_destination_orbit(travel, destination)
	if _campaign_mode:
		var gate: Dictionary = _campaign_operation_gate("select_destination", {"location_id": destination})
		if not gate.ok:
			return gate
	if destination == "homebase":
		return _reject("destination_missing", "Zielort auf der Regionalkarte waehlen")
	var selected_job_definition: Dictionary = Dictionary(selected.jobs.get(String(selected.selected_job_id),{}))
	if _campaign_mode and String(selected_job_definition.get("id","")) == "benit_delivery":
		var container: Dictionary = Dictionary(_supply.get_supply_snapshot().inventory).get("craft:"+craft_id,{})
		if int(Dictionary(container.get("items",{})).get("c_benit_crate",0)) < 1: return _reject("missing_delivery_cargo","C-Benit-Kiste muss im gewählten Schiff geladen sein")
	var expected_id := String(selected_job_definition.get("scenario_id",String(selected.locations[destination].scenario_file_path).get_file().get_basename()))
	var mission_definition: Dictionary = _flow.call("_get_selected_mission_definition")
	var selected_location: Dictionary = selected.locations[destination]
	if String(_flow.get("_selected_mission_id")) != expected_id or String(mission_definition.get("map_file_path", "")) != String(selected_location.map_file_path) or String(mission_definition.get("scenario_file_path", "")) != "res://data/mission_scenarios/"+expected_id+".json":
		return _reject("destination_map_mismatch", "Zielort auf der Sternkarte erneut auswählen; Karte und Auftrag stimmen nicht überein")
	var pad: String = _home_pad_for(craft_id)
	if pad.is_empty():
		return _reject("pad_unavailable", "Kein reales Startpad fuer dieses Schiff")
	if not FileAccess.file_exists(String(selected.locations[destination].map_file_path)) or not FileAccess.file_exists(String(selected.locations[destination].scenario_file_path)):
		return _reject("destination_unavailable", "Karte oder Szenario fuer diesen Zielort fehlt")
	if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty():
		return _reject("craft_busy", "Schiff ist bereits unterwegs")
	if not in_destination_orbit and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "homebase":
		return _reject("craft_unavailable", "Schiff steht nicht auf seinem Startpad")
	if _screen == null or (not in_destination_orbit and not bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id))) or String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get(craft_id, "")).is_empty():
		return _reject("launch_payload_missing", "Pilot, Trupp und abgeschlossenes Boarding fehlen")
	var definition: Dictionary = _flow.call("_find_homebase_aircraft_definition", craft_id)
	if definition.is_empty() or (not in_destination_orbit and not bool(_screen.call("_can_send_craft", definition, craft_id))) or (in_destination_orbit and not bool(_flow.call("_has_mission_start_payload"))):
		return _reject("launch_payload_invalid", "Schiff und Payload sind nicht startbereit")
	var selected_job:=String(selected.selected_job_id)
	for binding: Dictionary in Dictionary(selected.get("departures_by_craft_id",{})).values():
		if String(binding.get("job_id",""))==selected_job and String(binding.get("craft_id",""))!=craft_id: selected_job=""
	var departure: Dictionary = {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": destination, "landing_pad_id": pad, "job_id": selected_job}
	if reuse_departure:
		var existing: Dictionary = Dictionary(selected.get("departures_by_craft_id", {})).get(craft_id, {})
		if existing != departure: return _reject("departure_changed", "Abflugbindung passt nicht mehr zum Ziel")
		if not selected_job.is_empty() and (selected_job_definition.get("status") != "active" or selected_job_definition.get("craft_id") != craft_id): return _reject("job_changed", "Auftrag ist nicht mehr diesem Schiff zugeordnet")
		return {"ok":true, "departure":departure}
	var campaign_gate: Dictionary = _campaign.validate_departure(departure, {"departure_authorized": true, "built_home_pad_ids":_built_home_pad_ids()})
	if not campaign_gate.get("ok", false):
		return campaign_gate
	var fuel_gate: Dictionary = _supply.preview_route_fuel(departure, {"departure_authorized": true, "require_return_reserve": true})
	if not fuel_gate.get("ok", false):
		return fuel_gate
	return {"ok": true, "departure": departure}

func authorize_departure(craft_id: String, approach_request_id: String = "", station_dock: bool = false) -> Dictionary:
	if _simulation == null: return _reject("runtime_unavailable", "Simulation ist nicht bereit")
	var binding: Dictionary = _simulation.configure_departure_adapter(self)
	if not binding.get("ok", false): return binding
	var token: String = "departure:%s:%s:%d" % [_request_session, craft_id, int(_flow.get("_transfer_sequence")) + 1]
	var previous := String(_departure_token_by_craft.get(craft_id, ""))
	if not approach_request_id.is_empty() and _simulation.has_confirmed_cancelled_departure(self, craft_id, previous): token = previous
	var result: Dictionary = _simulation.commit_singleplayer_departure(self, craft_id, token, approach_request_id, station_dock)
	if not result.get("ok", false): return result
	_departure_token_by_craft[craft_id] = token
	if approach_request_id.is_empty():
		_simulation.publish_singleplayer_departure_events(self, token)
		if _campaign_mode and not result.get("replayed", false): observe_campaign_progress()
	return result

func preview_return(craft_id: String) -> Dictionary:
	# Read-only live visit and pilot check; no fuel or transfer mutation.
	if Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty() or _home_pad_for(craft_id).is_empty():
		return _reject("unknown_craft", "Kein reales Schiff mit Rueckkehrpad")
	var binding: Dictionary = _craft_visit_binding(craft_id)
	if binding.is_empty():
		return _reject("no_campaign_departure", "Kein ortsgebundener Abflug fuer dieses Schiff")
	var transfer: Dictionary = _flow.call("_find_pending_mission_craft_transfer", craft_id)
	var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, ""))
	# An explicit abort may reverse the existing outbound transfer; it retains
	# the same fixed-route cost model instead of inventing distance-based fuel.
	if location != "mission" and String(transfer.get("phase", "")) != "to_mission":
		return _reject("craft_not_remote", "Schiff ist nicht im Ausflug")
	if (_campaign_mode or bool(binding.get("local_origin", false))) and location == "mission":
		var mission: Node = _flow.call("get_mission_for_craft",craft_id)
		var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
		if controller == null:
			return _reject("pilot_presence_unknown", "Pilotanwesenheit ist nicht bestaetigt")
		var pilot_guard: Dictionary = controller.call("get_campaign_pilot_flight_guard", craft_id)
		if not bool(pilot_guard.get("ok", false)):
			return pilot_guard
	var route := {"craft_id": craft_id, "origin_location_id": String(binding.destination_location_id), "destination_location_id": "homebase"}
	var outward_token: String = "local-purchase:"+String(binding.get("origin_receipt_id", "")) if bool(binding.get("local_origin", false)) else String(_departure_token_by_craft.get(craft_id, ""))
	if outward_token.is_empty():
		return _reject("no_departure_receipt", "Bestaetigter Abflugbeleg fehlt")
	return {"ok":true, "route":route, "outward_token":outward_token}

func authorize_return(craft_id: String, request_id: String = "") -> Dictionary:
	var preview: Dictionary = preview_return(craft_id)
	if not preview.get("ok", false): return preview
	var flight: RefCounted = _travel.get_flight_state(craft_id) if _travel != null else null
	if flight != null and flight.get_snapshot().get("coordinate_frame") == "local" and flight.get_snapshot().get("motion_mode") == "inactive" and _travel.get_craft_snapshot(craft_id).get("phase") == "surface":
		return _simulation.preview_singleplayer_local_return_fuel(self, craft_id)
	if flight != null and flight.get_snapshot().get("coordinate_frame") == "strategic" and _travel.get_craft_snapshot(craft_id).get("phase") == "surface" and _travel.get_craft_snapshot(craft_id).get("location_id") == "polisa":
		return _simulation.preview_singleplayer_local_return_fuel(self, craft_id)
	# One return per accepted outward trip, regardless of whether the request
	# came from a UI retry, automatic debrief, or the transport hook itself.
	# Owner replay occurs before fuel validation, so a repeated success remains
	# valid even if its original debit left less than another route's cost.
	var result: Dictionary = _commit("singleplayer_supply", "consume_route_fuel", preview.route, "return:" + String(preview.outward_token) + ":fuel", {"departure_authorized": true})
	if not request_id.is_empty():
		result["return_request_id"] = request_id
	return result

func is_campaign_mission() -> bool:
	return _campaign_mode or _space_route_requested or String(_flow.get("_selected_mission_id")) in ["satellite_recovery", "trade_outpost_visit"]

func record_mission_result(result: Dictionary, authoritative_mission_identity: Dictionary = {}) -> void:
	_recover_secured_campaign_chips()
	var selected: Dictionary = _campaign.get_campaign_snapshot()
	var craft_id: String = String(authoritative_mission_identity.get("craft_id", ""))
	var binding: Dictionary = Dictionary(selected.departures_by_craft_id.get(craft_id, {}))
	var job_id: String = String(authoritative_mission_identity.get("job_id", binding.get("job_id", "")))
	var scenario_id: String = String(authoritative_mission_identity.get("scenario_id", ""))
	var job: Dictionary = Dictionary(selected.jobs.get(job_id, {}))
	if craft_id.is_empty() or job.is_empty() or String(job.get("status", "")) != "active" or String(binding.get("job_id", "")) != job_id or String(job.get("craft_id", "")) != craft_id or scenario_id != String(job.get("scenario_id", "")):
		return
	var evidence: Dictionary = result.duplicate(true)
	evidence["scenario_id"] = scenario_id
	var operation: String = "complete_job" if String(result.get("result", "")) == "victory" else "fail_job"
	if _campaign_mode and operation == "complete_job":
		var gates: Dictionary = result.get("mission_scenario_runtime_gates",{})
		if not bool(gates.get("all_gates_complete",false)): return
		for step in Array(job.required_step_ids):
			if not Array(gates.get("completed_step_ids",[])).has(step): return
		if bool(job.get("home_upload",false)):
			var item_id:String="satellite_chip" if job_id=="satellite_recovery" else "outpost_chip"
			if _find_campaign_chip_container(item_id, craft_id).is_empty():
				# Live objectives must produce a carried chip first. Preserve the
				# legacy result-only handoff when no live mission exists.
				if _flow.call("get_mission_for_craft", craft_id) != null:
					return
				var granted := _campaign_cargo(craft_id, item_id, 1, "chip:" + job_id)
				if not bool(granted.get("ok", false)):
					return
		if job_id == "outpost_recovery":
			var granted := _campaign_cargo(craft_id,"c_benit_crate",1,"load:"+job_id)
			if not bool(granted.get("ok",false)): return
	if _campaign_mode and operation == "complete_job" and job_id == "benit_delivery":
		var gates: Dictionary = result.get("mission_scenario_runtime_gates",{})
		if not bool(gates.get("all_gates_complete",false)) or not Array(gates.get("completed_step_ids",[])).has("deliver_benit"): return
		var cargo := _campaign_cargo(craft_id,"c_benit_crate",-1,"delivery:"+job_id)
		if not bool(cargo.get("ok",false)): return
		_commit("singleplayer_campaign","deliver_crate",{},"deliver:"+job_id,{"runtime_authorized":true})
	var committed: Dictionary = _commit("singleplayer_campaign", operation, {"job_id": job_id, "craft_id": craft_id}, "result:" + String(job_id) + ":" + String(_departure_token_by_craft.get(craft_id, "")), {"runtime_evidence": evidence})
	if bool(committed.get("ok",false)):
		if _campaign_mode and job_id == "outpost_recovery" and operation == "complete_job":
			_commit("singleplayer_campaign","load_crate",{},"load:"+job_id,{"runtime_authorized":true})
	var receipt: Dictionary = committed.get("completion_receipt", {})
	if not receipt.is_empty():
		_commit("singleplayer_supply", "apply_reward", {"completion_id": receipt.completion_id}, "reward:" + String(receipt.completion_id), {"completion_receipt": receipt})

func _campaign_operation_gate(operation: String, payload: Dictionary) -> Dictionary:
	if operation == "select_destination":
		var location: String = String(payload.get("location_id", ""))
		var jobs: Dictionary = _campaign.get_campaign_snapshot().jobs
		if location == "homebase": return {"ok":true}
		if bool(Dictionary(_campaign.get_campaign_snapshot().locations.get(location, {})).get("free_visit", false)): return {"ok":true}
		for job: Dictionary in jobs.values():
			if String(job.location_id) == location and not bool(job.get("locked",false)):
				return {"ok":true}
		return _reject("tutorial_locked","Zuerst den vorherigen Kampagnenauftrag abschließen und Chips zuhause hochladen")
	return {"ok": true}

func _observe(evidence: Dictionary) -> void:
	if _onboarding != null:
		_commit("campaign_onboarding", "observe", {}, "", {"runtime_evidence": evidence})

func observe_campaign_progress() -> void:
	if not _campaign_mode:
		return
	_recover_secured_campaign_chips()
	# One fresh progress projection after recovery; never retain it across calls.
	var campaign: Dictionary = _campaign.get_campaign_snapshot()
	var jobs: Dictionary = campaign.jobs
	var at_home := _flow.get("_active_mission") == null and not _has_active_transit()
	for location in Dictionary(_flow.get("_aircraft_location_by_craft")).values():
		at_home = at_home and String(location) == "homebase"
	var job: Dictionary = Dictionary(jobs.get("satellite_recovery", {}))
	var ready := false
	# This full UI projection is only needed when base_ready can become true.
	if at_home and String(job.get("status", "")) == "accepted":
		var selected_craft: Dictionary = _screen.call("get_operations_snapshot", false).get("selected_craft", {})
		var craft_id: String = String(selected_craft.get("id", ""))
		ready = not craft_id.is_empty() and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id)) and not String(_screen.call("_get_assigned_pilot_id", craft_id)).is_empty()
		ready = ready and (_base_personnel == null or (_base_personnel.is_pilot_aboard(craft_id) and bool(_base_personnel.get_payload_presence(craft_id).all_aboard)))
	var progress: Dictionary = campaign.get("progress", {})
	_observe({
		"base_ready": ready,
		"satellite_uploaded": String(job.get("status", "")) == "completed",
		"outpost_completed": String(Dictionary(jobs.get("outpost_recovery", {})).get("status", "")) == "completed",
		"outpost_recruited": bool(progress.get("recruited_outpost", false)),
		"crate_loaded": bool(progress.get("crate_loaded", false)),
		"delivery_completed": String(Dictionary(jobs.get("benit_delivery", {})).get("status", "")) == "completed",
		"outpost_chip_uploaded": String(Dictionary(jobs.get("outpost_chip_recovery", {})).get("status", "")) == "completed",
		"rescue_completed": String(Dictionary(jobs.get("buccaneer_rescue", {})).get("status", "")) == "completed",
		"pilot_recruited": bool(progress.get("recruited_pilot", false)),
		"second_pad_built": bool(progress.get("second_pad_built", false))})

func get_space_travel_snapshot(craft_id: String = "") -> Dictionary:
	if _travel == null:
		return {}
	var snapshot: Dictionary = _travel.get_snapshot(craft_id)
	if _warp_arrival_feedback.has(String(snapshot.get("craft_id", ""))): snapshot["arrival_feedback"] = Dictionary(_warp_arrival_feedback[snapshot.craft_id]).duplicate(true)
	snapshot["enabled"] = is_campaign_mission() or String(snapshot.phase) != "grounded"
	snapshot["result_summary"] = String(Dictionary(_flow.get("_last_mission_result")).get("result", ""))
	return snapshot

func get_space_area_projection(craft_id: String) -> Dictionary:
	if craft_id.strip_edges().is_empty() or _simulation == null or _travel == null: return {"ok":false, "reason":"unknown_craft"}
	var flight: RefCounted = _travel.get_flight_state(craft_id)
	if flight == null or _simulation.get_space_actor(craft_id) != flight: return {"ok":false, "reason":"unknown_craft"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.get("coordinate_frame") != "local" or snapshot.get("motion_mode") != "tactical" or String(snapshot.get("space_area_id", "")).is_empty(): return {"ok":false, "reason":"not_active_local"}
	var projection: Dictionary = _simulation.get_space_area_snapshot(snapshot.space_area_id, "singleplayer")
	if not projection.get("ok", false): return projection
	for actor: Dictionary in projection.actors:
		if actor.get("craft_id") == craft_id: return projection
	return {"ok":false, "reason":"not_owned"}

func preview_space_warp_entry(craft_id: String) -> Dictionary:
	if not is_instance_valid(_flow) or _travel == null or _base_personnel == null or not _base_personnel.is_pilot_aboard(craft_id): return _reject("pilot_not_aboard", "Pilotanwesenheit ist nicht bestaetigt")
	var pilots: Variant = _flow.get("_assigned_aircraft_pilot_by_craft")
	if typeof(pilots) != TYPE_DICTIONARY or typeof(pilots.get(craft_id)) != TYPE_STRING or String(pilots[craft_id]).is_empty(): return _reject("pilot_state_unavailable", "Pilotenzuordnung ist nicht verfuegbar")
	var routes: Dictionary = _travel.get_snapshot().get("routes", {})
	if not routes.has(craft_id): return _reject("unknown_craft", "Schiff ist nicht in der eigenen Flotte")
	return {"ok":true, "owned_crafts":routes.keys(), "craft_pilots":pilots.duplicate(true)}

func advance_space_travel(delta: float) -> void:
	if _travel != null and _travel.is_quantum_active():
		var step := minf(delta, 60.0)
		if not _local_warp_arrival_enabled or step <= 0.0:
			_commit("singleplayer_space_travel", "advance", {"delta_seconds":step}, "", {"runtime_authorized":true})
		else:
			for progress: Dictionary in _travel.get_active_quantum_progress():
				var craft_id := String(progress.craft_id)
				var completing: bool = _simulation.is_singleplayer_warp_entry_pending(craft_id) or float(progress.elapsed_seconds) + step >= float(progress.duration_seconds)
				if not completing:
					_commit("singleplayer_space_travel", "advance", {"craft_id":craft_id, "delta_seconds":step}, "", {"runtime_authorized":true})
				else:
					var arrival: Dictionary = _simulation.advance_singleplayer_warp_entry(self, craft_id, step)
					if arrival.get("ok", false) and arrival.get("status") == "complete":
						_warp_arrival_feedback.erase(craft_id)
						if not arrival.get("replayed", false): call_deferred("_publish_warp_entry_event", String(arrival.receipt_id))
					else:
						_warp_arrival_feedback[craft_id] = {"status":"searching" if arrival.get("ok", false) else "waiting", "reason":String(arrival.get("reason", ""))}
	if _space_encounter != null and String(_space_encounter.get_snapshot().get("phase","")) == "combat":
		_commit("campaign_space","advance",{"delta_seconds":minf(delta,1.0)},"",{"runtime_authorized":true})
		_finish_space_encounter_result()

func _request_space_wing_command(command: Dictionary) -> Dictionary:
	if _simulation == null or _travel == null or not is_instance_valid(_flow):
		return _reject("runtime_unavailable", "Rottenverwaltung ist nicht bereit")
	if command.get("contract_category") != "space_combat" or typeof(command.get("payload")) != TYPE_DICTIONARY:
		return _reject("invalid_command", "Rottenauftrag ist ungueltig")
	var operation := String(command.get("operation", ""))
	if operation not in ["wing_create", "wing_assign", "wing_remove", "wing_rename", "wing_leader_set"]:
		return _reject("unsupported_operation", "Dieser Rottenauftrag ist noch nicht verfuegbar")
	var prior: Dictionary = _simulation.check_space_wing_replay(command, "singleplayer")
	if prior.get("found", false):
		return prior.result
	var routes: Dictionary = _travel.get_snapshot().get("routes", {})
	var pilots: Variant = _flow.get("_assigned_aircraft_pilot_by_craft")
	if typeof(pilots) != TYPE_DICTIONARY:
		return _reject("pilot_state_unavailable", "Pilotenzuordnung ist nicht verfuegbar")
	var payload: Dictionary = command.payload
	var wing_id: String = String(payload.get("wing_id", ""))
	var wings: Dictionary = _simulation.get_space_wing_snapshot().get("wings", {})
	var affected: Dictionary = {}
	if wings.has(wing_id):
		for id in wings[wing_id].craft_ids: affected[id] = true
	for key in ["craft_id", "leader_craft_id"]:
		if typeof(payload.get(key)) == TYPE_STRING and not String(payload[key]).is_empty():
			affected[payload[key]] = true
	var phase := "grounded"
	for id in affected:
		if not routes.has(id): return _reject("unknown_craft", "Schiff ist nicht in der eigenen Flotte")
		var craft_phase: String = String(_travel.get_snapshot(id).get("phase", ""))
		var flight: RefCounted = _travel.get_flight_state(id)
		if flight != null and flight.get_snapshot().motion_mode == "tactical":
			phase = "tactical"
		elif craft_phase in ["orbit", "stopped"] and phase != "tactical":
			phase = "orbit"
		elif craft_phase != "grounded":
			return _reject("craft_busy", "Schiff ist auf einem nicht unterbrechbaren Flug oder Anflug")
	var context := {"authorized":true, "actor_id":"singleplayer", "phase":phase,
		"owned_crafts":routes.keys(), "craft_pilots":pilots.duplicate(true)}
	return _simulation.request_singleplayer_command(command.duplicate(true), context)

func validate_space_launch(craft_id: String, observe_progress: bool = true) -> Dictionary:
	if String(_travel.get_snapshot(craft_id).phase) != "grounded":
		return _reject("trip_active", "Den laufenden Ausflug zuerst beenden")
	if _base_personnel != null and not _base_personnel.is_pilot_aboard(craft_id):
		return _reject("pilot_not_aboard", "Zugewiesene Person muss tatsächlich am Pilotenplatz an Bord sein")
	if _base_personnel != null and not bool(_base_personnel.get_payload_presence(craft_id).all_aboard):
		return _reject("crew_not_aboard", "Alle zugewiesenen Truppmitglieder müssen tatsächlich an Bord sein")
	if _home_pad_for(craft_id).is_empty() or String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "homebase" or not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty():
		return _reject("craft_unavailable", "Schiff muss auf seinem Startpad bereitstehen")
	var definition: Dictionary = _flow.call("_find_homebase_aircraft_definition", craft_id)
	if _screen == null or definition.is_empty() or not bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id)) or String(_screen.call("_get_assigned_pilot_id", craft_id)).is_empty() or not bool(_screen.call("_can_send_craft", definition, craft_id)):
		return _reject("launch_payload_missing", "Pilot, Trupp und abgeschlossenes Boarding fehlen")
	if _campaign_mode:
		if observe_progress:
			observe_campaign_progress()
		if int(_onboarding.get_snapshot().stage_index) == 0 and not _selected_destination_is_free_visit() and String(Dictionary(_campaign.get_campaign_snapshot().jobs.get("satellite_recovery", {})).get("status", "")) != "accepted":
			return _reject("job_required", "Satellitenauftrag im Mobilgerät annehmen")
	return {"ok": true}

func launch_to_moon_orbit(craft_id: String) -> Dictionary:
	var request_id := _request_id("orbit-launch", {})
	var result: Dictionary = _simulation.commit_singleplayer_space_launch(self, craft_id, request_id)
	if result.get("ok", false):
		_flow.get("_aircraft_location_by_craft")[craft_id] = "starmap"
		# Publish the lifecycle change before any stale preparation callback can
		# edit pilot or payload using the old homebase transport projection.
		_flow.call("_refresh_homebase_screen")
		if not result.get("replayed", false): call_deferred("_publish_space_launch_event", request_id)
		return result.travel_result
	return result

func _publish_space_launch_event(request_id: String) -> void:
	if _simulation != null: _simulation.publish_singleplayer_space_launch_event(self, request_id)

func finish_space_approach(craft_id: String) -> Dictionary:
	return _commit("singleplayer_space_travel", "finish_approach", {"craft_id": craft_id}, _request_id("approach-finish", {}), {"runtime_authorized": true})

func enter_purchased_station_local_orbit(craft_id: String) -> Dictionary:
	# Explicit owner path, deliberately not selected by the legacy UI route.
	if _simulation == null: return _reject("runtime_unavailable", "Simulation ist nicht bereit")
	var binding: Dictionary = _simulation.configure_departure_adapter(self)
	if not binding.get("ok", false): return binding
	var result: Dictionary = _simulation.commit_station_purchase_local_admission(self, craft_id)
	if result.get("ok", false) and not result.get("replayed", false): call_deferred("_publish_space_launch_event", String(result.receipt_id))
	return result

func enter_space_orbit(craft_id: String) -> Dictionary:
	var flight: RefCounted = _travel.get_flight_state(craft_id) if _travel != null else null
	if flight != null and flight.get_snapshot().get("coordinate_frame") == "local" and ((flight.get_snapshot().get("motion_mode") == "inactive" and _travel.get_craft_snapshot(craft_id).get("phase") in ["surface", "approach"]) or (flight.get_snapshot().get("motion_mode") == "tactical" and _travel.get_craft_snapshot(craft_id).get("phase") == "orbit")):
		var result: Dictionary = _simulation.commit_singleplayer_local_return(self, craft_id)
		if result.get("ok", false) and not result.get("replayed", false): call_deferred("_publish_local_return_events", String(result.receipt_id))
		return result
	if flight != null and flight.get_snapshot().get("coordinate_frame") == "strategic" and _travel.get_craft_snapshot(craft_id).get("phase") == "surface" and _travel.get_craft_snapshot(craft_id).get("location_id") == "polisa":
		var purchase: Dictionary = get_station_ship_purchase(craft_id)
		if _local_warp_arrival_enabled and purchase.get("origin_kind") == "local_station_purchase":
			return enter_purchased_station_local_orbit(craft_id)
		var request_id := _request_id("station-orbit", {})
		var result: Dictionary = _simulation.commit_singleplayer_station_orbit(self, craft_id, request_id)
		if result.get("ok", false) and not result.get("replayed", false): call_deferred("_publish_space_launch_event", request_id)
		return result.travel_result if result.get("ok", false) else result
	return _commit("singleplayer_space_travel", "enter_orbit", {"craft_id": craft_id}, _request_id("orbit-return", {}), {"runtime_authorized": true})

func preview_station_orbit_departure(craft_id: String) -> Dictionary:
	var visit: Dictionary = preview_return(craft_id)
	if not visit.get("ok", false): return visit
	if visit.route.get("origin_location_id") != "polisa": return _reject("station_visit_required", "Schiff ist nicht bei Polisa")
	var mission: Node = _flow.call("get_mission_for_craft", craft_id)
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	if controller == null or not controller.has_method("get_campaign_pilot_flight_guard"): return _reject("pilot_presence_unknown", "Pilotanwesenheit ist nicht bestaetigt")
	var pilot: Dictionary = controller.call("get_campaign_pilot_flight_guard", craft_id)
	if not pilot.get("ok", false): return pilot
	var pilot_id := String(pilot.get("pilot_unit_id", ""))
	var pilots: Variant = _flow.get("_assigned_aircraft_pilot_by_craft")
	if pilot_id.is_empty() or typeof(pilots) != TYPE_DICTIONARY: return _reject("pilot_state_unavailable", "Pilotenzuordnung ist nicht verfuegbar")
	var actual: Dictionary = pilots.duplicate(true); actual[craft_id] = pilot_id
	return {"ok":true, "owned_crafts":Dictionary(_travel.get_snapshot().routes).keys(), "craft_pilots":actual, "route":visit.route.duplicate(true), "outward_token":visit.outward_token}

func preview_space_home_landing(craft_id: String) -> Dictionary:
	if not is_instance_valid(_flow) or _base_personnel == null or not _base_personnel.is_pilot_aboard(craft_id): return _reject("pilot_not_aboard", "Pilotanwesenheit ist nicht bestaetigt")
	if _home_pad_for(craft_id).is_empty() or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty(): return _reject("pad_unavailable", "Heimatpad ist nicht verfuegbar")
	return {"ok":true}

func preview_local_surface_return(craft_id: String) -> Dictionary:
	var preview: Dictionary = preview_return(craft_id)
	if not preview.get("ok", false): return preview
	var mission: Node = _flow.call("get_mission_for_craft", craft_id)
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	if controller == null or not controller.has_method("get_campaign_pilot_flight_guard"): return _reject("pilot_presence_unknown", "Pilotanwesenheit ist nicht bestaetigt")
	var pilot: Dictionary = controller.call("get_campaign_pilot_flight_guard", craft_id)
	if not pilot.get("ok", false): return pilot
	return preview

func preview_local_approach_cancel(craft_id: String) -> Dictionary:
	if not is_instance_valid(_flow) or _travel == null or _base_personnel == null or not _base_personnel.is_pilot_aboard(craft_id): return _reject("pilot_not_aboard", "Pilotanwesenheit ist nicht bestaetigt")
	var approaches: Variant = _flow.get("_space_approaches")
	var travel: Dictionary = _travel.get_craft_snapshot(craft_id)
	if typeof(approaches) != TYPE_DICTIONARY or not approaches.has(craft_id) or travel.get("phase") != "approach": return _reject("approach_not_active", "Kein aktiver Anflug")
	var entry: Variant = approaches[craft_id]
	if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("identity")) != TYPE_DICTIONARY or entry.identity.get("craft_id") != craft_id or entry.identity.get("location_id") != travel.get("location_id"): return _reject("approach_context_changed", "Anflug passt nicht zum Schiff und Ziel")
	var token := String(_departure_token_by_craft.get(craft_id, ""))
	if token.is_empty(): return _reject("no_departure_receipt", "Bestaetigter Abflugbeleg fehlt")
	if entry.identity.get("departure_token") != token: return _reject("approach_context_changed", "Abflugbeleg passt nicht zum Anflug")
	return {"ok":true, "route":{"craft_id":craft_id, "origin_location_id":String(travel.location_id), "destination_location_id":"homebase"}, "outward_token":token}

func _publish_local_return_events(receipt_id: String) -> void:
	if _simulation != null: _simulation.publish_singleplayer_local_return_events(self, receipt_id)

func _request_space_operation(operation: String, data: Dictionary, request_id: String) -> Dictionary:
	var snapshot := get_space_travel_snapshot(String(data.get("craft_id","")))
	var craft_id := String(data.get("craft_id", snapshot.get("craft_id", "")))
	data = data.duplicate(true)
	data["craft_id"] = craft_id
	var signature := JSON.stringify({"operation": operation, "payload": data}, "", true)
	# Replay the complete operation before fuel, phase gates or scene side
	# effects. Domain replay alone cannot undo an adapter-side fuel transaction.
	if _space_operation_requests.has(request_id):
		var receipt: Dictionary = _space_operation_requests[request_id]
		if String(receipt.signature) != signature:
			return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
		var replay: Dictionary = Dictionary(receipt.result).duplicate(true)
		replay["replayed"] = true
		return replay
	# Public IDs cannot collide with trusted lifecycle IDs in the same owner.
	var owner_request_id := "space-operation:" + request_id
	if operation == "space_open_operations":
		if String(snapshot.get("phase", "")) not in ["orbit", "quantum", "stopped"]:
			return _reject("operations_unavailable", "Operationsansicht erst nach dem Anflugwechsel oeffnen")
		_flow.call("_show_homebase", true)
		_screen.call("request_operation", "navigate", {"mode": "squad"})
		return _remember_space_operation(request_id, signature, {"ok": true})
	if operation in ["space_close_map", "space_prepare_launch"]:
		if String(snapshot.get("phase", "")) != "grounded":
			return _reject("trip_active", "Zum Landen zuerst den Mondorbit erreichen")
		if operation == "space_prepare_launch":
			_space_route_requested = true
		_flow.call("_show_homebase")
		_screen.call("request_operation", "navigate", {"mode": "mission"})
		return _remember_space_operation(request_id, signature, {"ok": true})
	if craft_id != String(snapshot.get("craft_id", "")) or craft_id.is_empty():
		return _reject("craft_mismatch", "Schiff gehoert nicht zur aktiven Reise")
	if operation in ["space_start_quantum", "space_abort_quantum"]:
		var flight: RefCounted = _travel.get_flight_state(craft_id)
		if operation == "space_start_quantum" and flight != null and flight.get_snapshot().get("coordinate_frame") == "local":
			var warp_command := data.duplicate(true); warp_command["request_id"] = owner_request_id
			var departure: Dictionary = _simulation.commit_singleplayer_warp_departure(self, warp_command)
			if not departure.get("ok", false): return departure
			var warp_result: Dictionary = departure.travel_result.duplicate(true)
			if departure.get("replayed", false): warp_result["replayed"] = true
			_remember_space_operation(request_id, signature, warp_result)
			if not departure.get("replayed", false): call_deferred("_publish_warp_departure_event", String(departure.receipt_id))
			return warp_result
		var result := _commit("singleplayer_space_travel", "start_quantum" if operation == "space_start_quantum" else "abort_quantum", data, owner_request_id)
		return _remember_space_operation(request_id, signature, result)
	if operation in ["space_begin_approach", "space_begin_station_dock"]:
		var location_id := String(data.get("location_id", ""))
		var station_dock := operation == "space_begin_station_dock"
		if station_dock and (location_id != "polisa" or data.get("target_id") != "polisa_station_dock" or data.get("layout_revision") != "polisa_glut2_dock_v1"): return _reject("station_layout_changed", "Stationsziel passt nicht")
		if not _in_destination_orbit(snapshot, location_id):
			return _reject("destination_orbit_required", "Erst den Orbit des Zielorts erreichen.")
		if _campaign_mode:
			var tutorial_gate := _campaign_operation_gate("select_destination", data)
			if not tutorial_gate.get("ok", false):
				return tutorial_gate
		if location_id != String(_campaign.get_campaign_snapshot().selected_location_id) or not Dictionary(_campaign.get_campaign_snapshot().locations).has(location_id) or location_id == "homebase":
			return _reject("destination_mismatch", "Den gewünschten Ort im zugehörigen Orbit auswählen")
		if String(Dictionary(snapshot.get("location_orbits",{})).get(location_id,"")) != String(snapshot.orbit_id):
			return _reject("destination_orbit_mismatch","Zielort gehört nicht zum aktuellen Orbit; kein Treibstoff verbraucht")
		var departure := authorize_departure(craft_id, ("station-dock:" + owner_request_id) if station_dock else owner_request_id, station_dock)
		if not departure.get("ok", false):
			return departure
		var result: Dictionary = departure.travel_result
		_remember_space_operation(request_id, signature, result)
		if not station_dock: _simulation.publish_singleplayer_departure_events(self, String(_departure_token_by_craft.get(craft_id, "")))
		if _campaign_mode and not station_dock and not departure.get("replayed", false): observe_campaign_progress()
		if result.get("ok", false) and not bool(result.get("replayed", false)):
			if location_id == "distress_orbit":
				_space_encounter.start_encounter(craft_id)
				_flow.call("_refresh_homebase_screen")
			else:
				_flow.call("_begin_space_approach", craft_id, departure.departure)
		if _campaign_mode and station_dock and not departure.get("replayed", false): observe_campaign_progress()
		if station_dock: _simulation.publish_singleplayer_departure_events(self, String(_departure_token_by_craft.get(craft_id, "")))
		return result
	if operation == "space_land_homebase":
		var flight: RefCounted = _travel.get_flight_state(craft_id)
		if flight != null and flight.get_snapshot().get("coordinate_frame") == "local":
			var landing: Dictionary = _simulation.commit_singleplayer_home_landing(self, craft_id, owner_request_id)
			if not landing.get("ok", false): return landing
			var landing_result: Dictionary = landing.travel_result.duplicate(true)
			if landing.get("replayed", false): landing_result["replayed"] = true
			_remember_space_operation(request_id, signature, landing_result)
			if not landing.get("replayed", false):
				_space_route_requested = false
				_flow.call("_finish_space_home_landing", craft_id)
				call_deferred("_publish_space_launch_event", String(landing.receipt_id))
			return landing_result
		var result := _commit("singleplayer_space_travel", "land_homebase", {"craft_id": craft_id}, owner_request_id, {"runtime_authorized": true})
		_remember_space_operation(request_id, signature, result)
		if result.get("ok", false) and not bool(result.get("replayed", false)):
			_space_route_requested = false
			_flow.call("_finish_space_home_landing", craft_id)
		return result
	return _reject("unknown_operation", "Reiseaktion nicht verfuegbar")

func _remember_space_operation(request_id: String, signature: String, result: Dictionary) -> Dictionary:
	if bool(result.get("ok", false)):
		_space_operation_requests[request_id] = {"signature": signature, "result": result.duplicate(true)}
	return result

func _publish_warp_departure_event(receipt_id: String) -> void:
	if _simulation != null: _simulation.publish_singleplayer_warp_departure_event(self, receipt_id)

func _publish_warp_entry_event(receipt_id: String) -> void:
	if _simulation != null: _simulation.publish_singleplayer_warp_entry_event(self, receipt_id)

func export_campaign_checkpoint() -> Dictionary:
	if not _campaign_mode or not _travel.all_grounded():
		return {}
	var state: Dictionary = _campaign.export_state()
	state["departures_by_craft_id"] = {}
	state["selected_location_id"] = "homebase"
	state["selected_job_id"] = ""
	var resources: Dictionary = {}
	for id in _supply.get("_location_resources"):
		resources[id] = {"version":1,"location_id":id,"sites":_supply.call("get_location_resources",id).export_state()}
	for id in _resource_owners:
		if is_instance_valid(_resource_owners[id]): resources[id] = _resource_owners[id].call("export_state")
	return {"schema_version": 1, "campaign": state, "supply": _supply.export_state(), "onboarding": _onboarding.export_state(), "base_personnel": _base_personnel.export_state() if _base_personnel != null else {},"location_resources":resources,"ship_equipment":_ship_equipment.export_state()}

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

func _inventory_context(unit_id: String, craft_id: String) -> Dictionary:
	var field:=_field_inventory_context(unit_id,craft_id)
	if not field.is_empty(): return field
	var snapshot: Dictionary = _screen.call("get_operations_snapshot",false)
	var unit: Dictionary = {}
	for entry in Array(snapshot.get("roster",[])):
		if String(entry.id)==unit_id: unit=entry
	if unit.is_empty() or (bool(unit.get("busy",true)) and not bool(unit.get("can_edit",false))): return {}
	if _base_personnel!=null:
		var found := false
		for actor in Array(_base_personnel.get_snapshot().get("units",[])):
			if String(actor.get("unit_id",""))==unit_id:
				found=String(actor.get("status","")) in ["outside","idle","sleeping"] or (String(actor.get("status",""))=="moving" and String(Dictionary(actor.get("action",{})).get("type",""))=="sleep")
		if not found: return {}
	var access: Array = ["base:homebase","unit:"+unit_id+":backpack"]
	if not craft_id.is_empty() and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id,""))=="homebase" and not _service_context(craft_id).is_empty(): access.append("craft:"+craft_id)
	return {"accessible_containers":access,"unit_id":unit_id}

func get_world_checkpoint_guard() -> Dictionary:
	if not _travel.all_grounded(): return _reject("world_active","Speichern gesperrt: mindestens ein Schiff ist noch unterwegs oder an einem anderen Ort")
	return {"ok":true}

func _field_inventory_context(unit_id: String,craft_id: String) -> Dictionary:
	if String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id,""))!="mission": return {}
	var mission: Node=_flow.call("get_mission_for_craft",craft_id)
	if mission==null: return {}
	var controller: Node=mission.get_node("TacticalController")
	if not Dictionary(controller.get("_deployed_unit_ids")).has(unit_id): return {}
	var card: Dictionary=controller.call("_find_mission_dropship_card_entry",craft_id)
	var team:=String(controller.call("_get_deployed_unit_fireteam_id",unit_id))
	if not Array(card.get("queued_fireteam_ids",[])).has(team) and not Array(card.get("boarded_fireteam_ids",[])).has(team) and not Array(card.get("embarked_unit_ids",[])).has(unit_id):
		# Once disembarked, the original card retains its assigned fireteams.
		var members: Array=Array(_flow.call("_find_mission_drop_card_in_planning_state",craft_id).get("embarked_unit_ids",[]))
		if not members.has(unit_id): return {}
	var unit: Node=controller.call("_find_friendly_unit_by_id",unit_id)
	if unit==null or (unit.has_method("get_vital_state") and unit.get_vital_state()!="fit"): return {}
	var access: Array=["unit:"+unit_id+":backpack"]
	if controller.call("_is_parked_campaign_dropship",craft_id) and unit.position.distance_to(controller.call("_campaign_landed_craft_position",craft_id))<=128.0: access.append("craft:"+craft_id)
	if String(_service_context(craft_id).get("location_id", "")) == "polisa":
		var service_position: Vector2 = controller.get_node("../TerrainRegistry").call("grid_to_world", Vector2i.ZERO) if controller.get_node_or_null("../TerrainRegistry") != null else Vector2.ZERO
		var near_ship: bool = controller.call("_is_parked_campaign_dropship", craft_id) and unit.position.distance_to(controller.call("_campaign_landed_craft_position", craft_id)) <= 128.0
		if near_ship or unit.position.distance_to(service_position) <= 128.0:
			if not access.has("craft:"+craft_id): access.append("craft:"+craft_id)
			return {"accessible_containers":access, "unit_id":unit_id, "equipment_allowed":true, "station_context":true}
	return {"accessible_containers":access,"unit_id":unit_id,"equipment_allowed":false}
func get_inventory_context(unit_id: String,craft_id: String) -> Dictionary:
	return _inventory_context(unit_id,craft_id).duplicate(true)

func _job_complete(id: String) -> bool:
	return String(Dictionary(_campaign.get_campaign_snapshot().jobs.get(id,{})).get("status","")) == "completed"

func register_location_resources(mission: Node, location_id: String) -> void:
	if _resource_owners.has(location_id) and is_instance_valid(_resource_owners[location_id]): return
	var owner: Node = load("res://scripts/core/location_resource_runtime.gd").new()
	owner.name = "LocationResources"
	mission.add_child(owner)
	var configured: Dictionary = owner.call("configure",mission,self,location_id,{})
	if not bool(configured.get("ok",false)):
		owner.queue_free()
		return
	_resource_owners[location_id] = owner
	if ResourceLoader.exists("res://scripts/meta/location_resource_presenter.gd"):
		var presenter: Node = load("res://scripts/meta/location_resource_presenter.gd").new()
		var layer := CanvasLayer.new()
		layer.layer = 75
		mission.add_child(layer)
		layer.add_child(presenter)
		presenter.call("configure",owner)

func release_location_resources(location_id: String) -> void:
	_resource_owners.erase(location_id)

func grant_resource_result(owner: Node, receipt: Dictionary) -> Dictionary:
	var location := String(receipt.get("location_id",""))
	if _resource_owners.get(location) != owner: return _reject("unknown_resource_owner","Unbestätigte Rohstoffquelle")
	if not owner.has_method("get_pending_receipt") or owner.call("get_pending_receipt") != receipt: return _reject("unverified_resource_receipt","Bestätigter Abbaubeleg fehlt")
	return collect_location_resource(owner,location,String(receipt.get("site_id","")),String(receipt.get("unit_id","")))

func _finish_space_encounter_result() -> void:
	var result: Dictionary = _space_encounter.get_completed_result()
	if result.is_empty(): return
	var craft_id := String(result.craft_id)
	record_mission_result(result,{"craft_id":craft_id,"job_id":"buccaneer_rescue","scenario_id":"buccaneer_rescue"})
	var outward_token := String(_departure_token_by_craft.get(craft_id,""))
	_commit("singleplayer_supply","consume_route_fuel",{"craft_id":craft_id,"origin_location_id":"distress_orbit","destination_location_id":"homebase"},"return:"+outward_token+":fuel",{"departure_authorized":true})
	# Space encounter never fabricates a ground mission or landing.
	_commit("singleplayer_space_travel","finish_approach",{"craft_id":craft_id},_request_id("encounter-finish",{}),{"runtime_authorized":true})
	_commit("singleplayer_space_travel","enter_orbit",{"craft_id":craft_id},_request_id("encounter-orbit",{}),{"runtime_authorized":true})
	if String(result.result) == "victory":
		_request_campaign_action("campaign_recruit",{"craft_id":craft_id,"kind":"pilot"},_request_id("rescue-recruit",{}))
	_flow.call("_refresh_homebase_screen")

func _campaign_cargo(craft_id: String, item_id: String, amount: int, receipt_id: String) -> Dictionary:
	return _commit("singleplayer_supply","campaign_cargo",{"container_id":"craft:"+craft_id,"item_id":item_id,"amount":amount},"campaign-cargo:"+receipt_id,{"campaign_authorized":true})

func _find_campaign_chip_container(item_id:String,craft_id:String)->String:
	var inventory:Dictionary=_supply.get_supply_snapshot().get("inventory",{})
	var preferred:String="craft:"+craft_id
	if int(Dictionary(Dictionary(inventory.get(preferred,{})).get("items",{})).get(item_id,0))>0:return preferred
	for id:String in inventory:
		if int(Dictionary(inventory[id].get("items",{})).get(item_id,0))>0:return id
	return ""

func _recover_secured_campaign_chips()->void:
	if not _campaign_mode:return
	var campaign:Dictionary=_campaign.get_campaign_snapshot()
	for spec:Array in [["satellite_recovery","satellite_data","secure_satellite","satellite_chip"],["outpost_chip_recovery","outpost_chip","secure_outpost_chip","outpost_chip"]]:
		var job:Dictionary=campaign.jobs.get(spec[0],{})
		if String(job.get("status",""))!="active":continue
		var craft_id:String=String(job.get("craft_id",""))
		if craft_id.is_empty() or not _find_campaign_chip_container(spec[3],craft_id).is_empty():continue
		var binding:Dictionary=campaign.departures_by_craft_id.get(craft_id,{})
		if String(binding.get("job_id",""))!=String(spec[0]):continue
		var mission:Node=_flow.call("get_mission_for_craft",craft_id)
		var driver:Node=mission.get_node_or_null("CombatLoopDriver") if mission!=null else null
		var controller:Node=mission.get_node_or_null("TacticalController") if mission!=null else null
		if driver==null or controller==null:continue
		var gates:Dictionary=driver.call("get_mission_scenario_runtime_gate_snapshot")
		if not Array(gates.get("completed_step_ids",[])).has(spec[2]):continue
		var state:Dictionary=Dictionary(driver.call("get_mission_interaction_runtime_states")).get(spec[1],{})
		if not bool(state.get("complete",false)) or String(state.get("step_id",""))!=String(spec[2]):continue
		var lead:Node=controller.call("get_current_fireteam_lead_unit",String(state.get("fireteam_id","")))
		if lead==null or not lead.has_method("get_unit_id"):continue
		var container:String="unit:"+String(lead.call("get_unit_id"))+":backpack"
		var token:String=String(_departure_token_by_craft.get(craft_id,""))
		if token.is_empty():continue
		_commit("singleplayer_supply","campaign_cargo",{"container_id":container,"item_id":String(spec[3]),"amount":1},"chip-pickup:"+token+":"+String(spec[0]),{"campaign_authorized":true})

func _all_at_home() -> bool:
	if not _travel.all_grounded() or _has_active_transit(): return false
	for value in Dictionary(_flow.get("_aircraft_location_by_craft")).values():
		if String(value) not in ["homebase","waiting_pad"]: return false
	return true

func _request_campaign_action(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	if not _campaign_mode and operation not in ["campaign_upload","campaign_fabricate"]: return _reject("campaign_only","Diese Aktion gehört zur Kampagne")
	var snapshot: Dictionary = _campaign.get_campaign_snapshot()
	var craft_id := String(payload.get("craft_id", ""))
	var at_home := _all_at_home()
	if operation == "campaign_upload":
		if not _has_live_base_owner(): return _reject("upload_requires_home","Lokales Basisterminal nicht verfügbar")
		var job_id := String(payload.get("job_id",""))
		if job_id.is_empty():
			for id in snapshot.jobs:
				if String(snapshot.jobs[id].status) == "pending_upload" and not _find_local_campaign_chip_container("satellite_chip" if String(id) == "satellite_recovery" else "outpost_chip").is_empty():
					job_id = String(id)
					break
		var job: Dictionary = snapshot.jobs.get(job_id,{})
		if String(job.get("status","")) != "pending_upload": return _reject("no_chip","Kein geborgener Chip zum Hochladen")
		craft_id = String(job.get("craft_id",craft_id))
		var item_id := "satellite_chip" if job_id == "satellite_recovery" else "outpost_chip"
		var container:String=_find_local_campaign_chip_container(item_id)
		if container.is_empty():return _reject("missing_cargo","Geborgener Datenträger fehlt bei der Person, im Schiff oder im Basislager")
		var cargo := _commit("singleplayer_supply","campaign_cargo",{"container_id":container,"item_id":item_id,"amount":-1},"campaign-cargo:upload:"+job_id,{"campaign_authorized":true})
		if not bool(cargo.get("ok",false)): return cargo
		var result := _commit("singleplayer_campaign","upload_job",{"job_id":job_id},"upload:"+job_id,{"at_home":true})
		if bool(result.get("ok",false)):
			var receipt: Dictionary = result.get("completion_receipt",{})
			_commit("singleplayer_supply","apply_reward",{"completion_id":receipt.completion_id},"reward:"+String(receipt.completion_id),{"completion_receipt":receipt})
		observe_campaign_progress()
		return result
	if operation in ["campaign_fabricate", "campaign_research"]:
		return _commit("singleplayer_supply",operation,payload,request_id,{"at_home":_home_workshop_available(),"campaign_authorized":true})
	if operation == "campaign_build_pad":
		if bool(snapshot.progress.second_pad_built): return {"ok":true,"changed":false,"message":"Zweites Landepad bereits gebaut"}
		if not at_home or not bool(snapshot.progress.recruited_pilot): return _reject("pad_not_ready","Nach der Rettung zur Heimatbasis zurückkehren")
		var paid := _commit("singleplayer_supply","campaign_build",{},"pad2:cost",{"at_home":true,"campaign_authorized":true})
		if not bool(paid.get("ok",false)): return paid
		var result := _commit("singleplayer_campaign","build_pad",{},"pad2:build",{"at_home":true,"runtime_authorized":true})
		if bool(result.get("ok",false)):
			for id in Dictionary(_flow.get("_aircraft_location_by_craft")).keys():
				if String(_flow.get("_aircraft_location_by_craft")[id]) == "waiting_pad": _flow.get("_aircraft_location_by_craft")[id] = "homebase"
			sync_crafts()
			_flow.call("_refresh_homebase_screen")
		observe_campaign_progress()
		return result
	if operation == "campaign_recruit":
		var pilot := String(payload.get("kind","outpost")) == "pilot"
		var key := "recruited_pilot" if pilot else "recruited_outpost"
		if bool(snapshot.progress.get(key,false)): return {"ok":true,"changed":false,"message":"Person bereits im Team"}
		var job_craft := String(Dictionary(snapshot.jobs.get("buccaneer_rescue" if pilot else "outpost_recovery", {})).get("craft_id", ""))
		if craft_id.is_empty() or craft_id != job_craft: return _reject("recruit_craft_required", "Das Schiff des zugehörigen Auftrags auswählen")
		if pilot and not _has_verified_pilot_rescue(craft_id): return _reject("rescue_not_here", "Bestätigte Rettung dieses Schiffs fehlt")
		var outpost_cleared := false
		if not pilot:
			var mission: Node = _flow.call("get_mission_for_craft",craft_id)
			var driver := mission.get_node_or_null("CombatLoopDriver") if mission != null else null
			if driver != null:
				var gates: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
				outpost_cleared = Array(gates.get("completed_step_ids",[])).has("clear_outpost") and String(Dictionary(snapshot.jobs.get("outpost_recovery",{})).get("status","")) == "active"
		if not _job_complete("buccaneer_rescue" if pilot else "outpost_recovery") and not outpost_cleared: return _reject("recruit_not_ready","Zuerst den zugehörigen Außenposten sichern")
		if not pilot and String(_service_context(craft_id).get("location_id","")) != "trade_outpost": return _reject("visit_trader","NPC am Handelsposten persönlich ansprechen")
		var profile: Dictionary = load("res://scripts/meta/campaign_start_configuration.gd").new()._initial_roster()[1 if pilot else 0].duplicate(true)
		profile.merge({"unit_id":"campaign_rescue_pilot" if pilot else "campaign_outpost_recruit","display_name":"Mika Brandt" if pilot else "Robin Seidel","fireteam_id":"" if pilot else "ft1","armor":"light","armor_id":"light","weapon_1":"pistol","weapon_1_id":"pistol","weapon_2":"none","weapon_2_id":"none"},true)
		var definition: Dictionary = _flow.call("_build_homebase_aircraft_definition","fighter",1) if pilot else {}
		if pilot: definition.merge({"craft_id":"campaign_buccaneer_01","display_name":"Buccaneer","model_id":"buccaneer"},true)
		var registered: Dictionary = _flow.call("register_campaign_recruit",profile,definition)
		if not bool(registered.get("ok",false)): return registered
		if _base_personnel != null and _base_personnel.has_method("mark_recruit_remote"):
			_base_personnel.call("mark_recruit_remote",String(profile.unit_id),String(definition.craft_id) if pilot else craft_id)
		var result := _commit("singleplayer_campaign","claim_recruit",{"kind":"pilot" if pilot else "outpost"},"recruit:"+key,{"runtime_authorized":true,"outpost_cleared":outpost_cleared})
		if pilot: _flow.get("_aircraft_location_by_craft")[String(definition.craft_id)] = "waiting_pad"
		sync_crafts()
		observe_campaign_progress()
		return result
	if operation == "campaign_load_crate":
		if bool(snapshot.progress.crate_loaded): return {"ok":true,"changed":false}
		if not _job_complete("outpost_recovery"): return _reject("crate_not_ready","Kiste zuerst am Außenposten bergen")
		var job_craft := String(Dictionary(snapshot.jobs.get("outpost_recovery", {})).get("craft_id", ""))
		if craft_id.is_empty() or craft_id != job_craft or String(_service_context(craft_id).get("location_id", "")) not in ["homebase", "trade_outpost"]: return _reject("crate_not_here","Auftragsschiff am gesicherten Außenposten oder nach Rückkehr auswählen")
		var cargo := _campaign_cargo(craft_id,"c_benit_crate",1,"load:outpost_recovery")
		if not bool(cargo.get("ok",false)): return cargo
		return _commit("singleplayer_campaign","load_crate",{},"load:outpost_recovery",{"runtime_authorized":true})
	return _reject("delivery_requires_use","C-Benit am Handelsposten über die Weltinteraktion abgeben")

func get_location_resource_stock(location_id: String) -> RefCounted:
	return _supply.call("get_location_resources",location_id)

func preview_resource_collection(location_id: String, site_id: String, unit_id: String) -> Dictionary:
	return _supply.call("preview_resource_collection",location_id,site_id,unit_id)

func collect_location_resource(owner: Node, location_id: String, site_id: String, unit_id: String) -> Dictionary:
	if _resource_owners.get(location_id) != owner: return _reject("unknown_resource_owner","Unbestätigte Rohstoffquelle")
	return _commit("singleplayer_supply","collect_resource",{"location_id":location_id,"site_id":site_id,"unit_id":unit_id},"resource:"+location_id+":"+site_id,{"resource_authorized":true,"unit_id":unit_id,"location_id":location_id,"use_complete":true,"within_radius":true})


func _polisa_free_home_pad() -> String:
	var pads: Array = HOME_PADS.duplicate()
	if (_skirmish_economy != null or _campaign_mode) and _base_personnel != null:
		pads.clear()
		for pad: Dictionary in _base_personnel.get_snapshot().get("layout", {}).get("landing_pads", []):
			if bool(pad.get("built", true)): pads.append(String(pad.get("id", "")))
	for pad: String in pads:
		if _campaign_mode and pad == "homebase_pad_02" and not bool(_campaign.get_campaign_snapshot().progress.second_pad_built): continue
		if not pad.is_empty() and not _pad_by_craft.values().has(pad): return pad
	return ""


func _fulfill_polisa_ship(offer: Dictionary, request_id: String) -> Dictionary:
	var kind := String(offer.get("craft_type", ""))
	var model := String(offer.get("model_id", ""))
	if kind not in ["dropship", "fighter"] or model not in ["cutlass", "buccaneer"]: return _reject("unsupported_craft", "Schiff noch nicht spielbar")
	var id := "polisa_"+model+"_"+request_id.sha256_text().substr(0,12)
	if not Dictionary(_flow.call("_find_homebase_aircraft_definition", id)).is_empty(): return _reject("craft_already_registered", "Schiffsbeleg bereits vorhanden")
	var pad := _polisa_free_home_pad()
	if pad.is_empty(): return _reject("no_free_home_pad", "Lieferung braucht ein gebautes freies Heimatpad")
	var craft: Dictionary = _flow.call("_build_homebase_aircraft_definition", kind, 1)
	craft.merge({"craft_id":id,"model_id":model,"display_name":String(offer.get("name", model))}, true)
	# All validation precedes the first fleet write. No new pad is fabricated.
	var definitions: Array = _flow.get("_homebase_aircraft_definitions")
	definitions.append(craft)
	_flow.get("_aircraft_location_by_craft")[id] = "homebase"
	_pad_by_craft[id] = pad
	sync_crafts()
	return {"ok":true,"craft_id":id,"delivery_location_id":"homebase","landing_pad_id":pad}


func _project_polisa_loadout(unit_id: String, craft_id: String, loadout: Dictionary) -> void:
	if loadout.is_empty(): return
	var mission: Node = _flow.call("get_mission_for_craft", craft_id)
	if mission == null: return
	var registry: Node = mission.get_node_or_null("UnitRegistry")
	var setup: Node = mission.get_node_or_null("MissionSetup")
	var simulation: Node = mission.get_node_or_null("SimulationRoot")
	var unit: Node = registry.call("get_unit", unit_id) if registry != null else null
	if unit == null or setup == null or simulation == null: return
	# Existing mission lifecycle bridge projects the committed owner loadout,
	# preserving actor identity, progress, transform, unit ID and current orders.
	var members: Dictionary = setup.get("member_loadouts")
	members[unit_id] = loadout.duplicate(true)
	setup.set("member_loadouts", members)
	setup.call("_apply_fob_loadout_override", unit, unit_id, String(unit.get("team_id")))
	setup.call("_build_unit_loadout_modifiers")
	setup.call("_enqueue_initial_loadout_effect", simulation, unit_id)
	var planning: Dictionary = _flow.get("_mission_planning_state")
	var planning_loadouts: Dictionary = planning.get("member_loadouts", {})
	planning_loadouts[unit_id] = loadout.duplicate(true)
	planning["member_loadouts"] = planning_loadouts


func get_polisa_snapshot(snapshot: Dictionary = {}) -> Dictionary:
	if snapshot.is_empty(): snapshot = get_snapshot()
	var view: Dictionary = snapshot.get("location_view", {})
	var craft_id := String(view.get("craft_id", "")) if String(view.get("location_id", "")) == "polisa" else ""
	var contexts: Dictionary = snapshot.get("service_contexts_by_craft_id", {})
	var local_crafts: Array = []
	for craft: Dictionary in snapshot.get("crafts", []):
		if String(Dictionary(contexts.get(String(craft.get("craft_id", "")), {})).get("location_id", "")) == "polisa":
			local_crafts.append({"craft_id":String(craft.craft_id), "name":String(craft.get("display_name", craft.craft_id))})
	if not local_crafts.any(func(craft: Dictionary): return String(craft.craft_id) == craft_id): craft_id = ""
	var supply: Dictionary = snapshot.get("supply", {})
	var offers := {}
	for id: String in supply.get("offers", {}):
		var offer: Dictionary = supply.offers[id]
		if Array(offer.get("location_ids", [])).has("polisa"): offers[id] = offer
	var people: Array = []
	var mission: Node = _flow.call("get_mission_for_craft", craft_id) if not craft_id.is_empty() else null
	var registry: Node = mission.get_node_or_null("UnitRegistry") if mission != null else null
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		var id := String(profile.get("unit_id", ""))
		if registry == null or registry.call("get_unit", id) == null: continue
		var access := _inventory_context(id, craft_id)
		people.append({"unit_id":id,"name":String(profile.get("display_name", id)),"equipment_allowed":bool(access.get("equipment_allowed", false)),"loadout":_simulation.get_personnel_loadout_state().get_loadout(id)})
	var local_capability: Dictionary = _flow.call("get_polisa_local_ship_purchase_capability") if _flow.has_method("get_polisa_local_ship_purchase_capability") else {"available":false,"message":"Lokale Ausgabe noch nicht verfügbar"}
	var crew_handoff: Dictionary = _flow.call("get_polisa_crew_handoff_snapshot", craft_id) if not craft_id.is_empty() and _flow.has_method("get_polisa_crew_handoff_snapshot") else {}
	return {"crew_handoff":crew_handoff,"local_pickup_available":bool(local_capability.get("available", false)),"local_pickup_reason":String(local_capability.get("message", "")),"equipment":_ship_equipment.get_snapshot(craft_id) if _ship_equipment != null and not craft_id.is_empty() else {},"local_crafts":local_crafts,"selection_required":craft_id.is_empty() and not local_crafts.is_empty(),"craft_id":craft_id,"craft_name":String(Dictionary(_flow.call("_find_homebase_aircraft_definition",craft_id)).get("display_name",craft_id)),"service_ready":String(Dictionary(contexts.get(craft_id, {})).get("location_id", ""))=="polisa",
		"fuel":float(Dictionary(supply.get("fuel_by_craft_id", {})).get(craft_id, 0.0)),"fuel_registered":Dictionary(supply.get("fuel_by_craft_id", {})).has(craft_id),
		"fuel_capacity":float(supply.get("fuel_capacity", 0.0)),"fuel_price_per_unit":float(supply.get("fuel_price_per_unit", 0.0)),
		"credits":int(supply.get("credits", 0)),"offers":offers,"stock":supply.get("stock_by_offer_id", {}),"inventory":supply.get("inventory", {}),
		"people":people,"blueprints":supply.get("blueprints", []),"require_blueprints":_campaign_mode,"revision":int(supply.get("revision", 0)),
		"free_home_pad":_polisa_free_home_pad(),"home_pad_count":int(supply.get("station_home_pads", 2)),"campaign_mode":_campaign_mode,"buy_orders":Dictionary(supply.get("commodity_buy_orders", {})).get("polisa", {})}


func _build_polisa_home_pad(count: int) -> Dictionary:
	if _base_personnel == null: return _reject("base_unavailable", "Heimatbasis nicht geladen")
	return _base_personnel.call("build_campaign_landing_pad", count)


func _built_home_pad_ids() -> Array:
	var pads: Array = []
	if _base_personnel == null: return HOME_PADS.duplicate()
	for pad: Dictionary in _base_personnel.get_snapshot().get("layout", {}).get("landing_pads", []):
		if bool(pad.get("built", true)): pads.append(String(pad.id))
	return pads


func _selected_destination_is_free_visit() -> bool:
	var campaign: Dictionary = _campaign.get_campaign_snapshot()
	return bool(Dictionary(campaign.locations.get(String(campaign.selected_location_id), {})).get("free_visit", false))


func _craft_grounded_at_home(craft_id: String) -> bool:
	if _flow == null or _travel == null: return false
	if String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "homebase": return false
	if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty(): return false
	var routes: Dictionary = _travel.get_snapshot(craft_id).get("routes", {})
	return routes.has(craft_id) and String(Dictionary(routes[craft_id]).get("phase", "")) == "grounded"

func _has_live_base_owner() -> bool:
	return is_instance_valid(_base_personnel) and _base_personnel.is_inside_tree() and _base_personnel.get_parent() == self and is_instance_valid(_simulation) and _simulation.get("_base_personnel_owner") == _base_personnel and String(Dictionary(_base_personnel.call("get_snapshot")).get("runtime_authority", "")) == "SimulationRoot"

func _home_workshop_available() -> bool:
	if not _has_live_base_owner():
		# Legacy non-campaign sessions never created a BasePersonnel owner.
		return not _campaign_mode and _base_personnel == null and _all_at_home()
	for asset: Dictionary in Dictionary(_base_personnel.call("get_snapshot")).get("layout", {}).get("assets", []):
		if String(asset.get("id", "")) == "freihafen_hall_01" and bool(asset.get("built", true)): return true
	return false

func _find_local_campaign_chip_container(item_id: String) -> String:
	if not _has_live_base_owner(): return ""
	var allowed: Array[String] = ["base:homebase"]
	for craft: Dictionary in Array(_flow.get("_homebase_aircraft_definitions")):
		var id := String(craft.get("craft_id", ""))
		if _craft_grounded_at_home(id): allowed.append("craft:" + id)
	for person: Dictionary in Dictionary(_base_personnel.call("get_snapshot")).get("units", []):
		var status := String(person.get("status", "away"))
		var craft_id := String(person.get("craft_id", ""))
		if status != "away" and (craft_id.is_empty() or _craft_grounded_at_home(craft_id)):
			allowed.append("unit:" + String(person.get("unit_id", "")) + ":backpack")
	var inventory: Dictionary = _supply.get_supply_snapshot().get("inventory", {})
	for container: String in allowed:
		if int(Dictionary(inventory.get(container, {})).get("items", {}).get(item_id, 0)) > 0: return container
	return ""

func _home_services_snapshot() -> Dictionary:
	var local_jobs: Array[String] = []
	for id: String in _campaign.get_campaign_snapshot().get("jobs", {}):
		var job: Dictionary = _campaign.get_campaign_snapshot().jobs[id]
		if String(job.get("status", "")) == "pending_upload" and not _find_local_campaign_chip_container("satellite_chip" if id == "satellite_recovery" else "outpost_chip").is_empty(): local_jobs.append(id)
	return {"workshop_available":_home_workshop_available(), "upload_job_ids":local_jobs, "all_at_home":_all_at_home()}

func _has_verified_pilot_rescue(craft_id: String) -> bool:
	# get_completed_result consumes its delivery flag before automatic recruitment.
	# The authoritative read-only state retains the exact victorious craft.
	if _space_encounter == null: return false
	var encounter: Dictionary = _space_encounter.get_snapshot()
	return not craft_id.is_empty() and String(encounter.get("craft_id", "")) == craft_id and String(encounter.get("phase", "")) == "victory"


func get_station_ship_purchase(craft_id: String) -> Dictionary:
	return _supply.get_station_ship_purchase(craft_id) if _supply != null else {}

func _craft_visit_binding(craft_id: String) -> Dictionary:
	var existing: Dictionary = _campaign.get_campaign_snapshot().departures_by_craft_id.get(craft_id, {})
	if not existing.is_empty(): return existing.duplicate(true)
	var purchase := get_station_ship_purchase(craft_id)
	if purchase.get("origin_kind") != "local_station_purchase" or String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "mission": return {}
	var mission: Node = _flow.call("get_mission_for_craft", craft_id)
	if mission == null or String(mission.get_meta("location_id", "")) != "polisa": return {}
	return {"local_origin":true,"craft_id":craft_id,"job_id":"","origin_location_id":"polisa","destination_location_id":"polisa","landing_pad_id":String(purchase.landing_pad_id),"origin_receipt_id":String(purchase.origin_receipt_id)}

func _fulfill_polisa_local_ship(offer: Dictionary, request_id: String, requested_pad_id: String = "") -> Dictionary:
	var kind := String(offer.get("craft_type", ""))
	var model := String(offer.get("model_id", ""))
	if kind not in ["dropship", "fighter"] or model not in ["cutlass", "buccaneer"]: return _reject("unsupported_craft", "Schiff noch nicht spielbar")
	if not _flow.has_method("prepare_polisa_local_ship_purchase") or not _flow.has_method("commit_polisa_local_ship_purchase") or not _flow.has_method("finalize_polisa_local_ship_purchase"): return _reject("local_pickup_unavailable", "Lokale Ausgabe nicht verfügbar")
	var id := "polisa_"+model+"_"+request_id.sha256_text().substr(0,12)
	if not Dictionary(_flow.call("_find_homebase_aircraft_definition", id)).is_empty(): return _reject("craft_already_registered", "Schiffsbeleg bereits vorhanden")
	var home_pad := _polisa_free_home_pad()
	if home_pad.is_empty(): return _reject("no_free_home_pad", "Ein gebautes freies Rückkehrpad an der Heimatbasis wird benötigt")
	var craft: Dictionary = _flow.call("_build_homebase_aircraft_definition", kind, 1)
	craft.merge({"craft_id":id,"model_id":model,"display_name":String(offer.get("name", model))}, true)
	var flow_candidate: Dictionary = _flow.call("prepare_polisa_local_ship_purchase", craft.duplicate(true), request_id, requested_pad_id)
	if not flow_candidate.get("ok", false): return flow_candidate
	if typeof(flow_candidate.get("craft_definition")) != TYPE_DICTIONARY: return _reject("invalid_local_craft", "Schiffsübergabe unvollständig")
	craft = Dictionary(flow_candidate.craft_definition).duplicate(true)
	if String(craft.get("craft_id", "")) != id or String(craft.get("model_id", "")) != model: return _reject("invalid_local_craft", "Schiffsidentität hat sich geändert")
	var acquisition_pad := String(flow_candidate.get("acquisition_pad_id", ""))
	if not load("res://scripts/mission/polisa_station_craft_runtime.gd").receipt_pad_compatible(model, acquisition_pad) or (not requested_pad_id.is_empty() and acquisition_pad != requested_pad_id): return _reject("invalid_local_pad", "Erwerbspad ungültig")
	var travel_candidate: Dictionary = _travel.prepare_surface_registration(id, "polisa", "local-purchase:"+request_id+":surface")
	if not travel_candidate.get("ok", false): return travel_candidate
	var travel_validation: Dictionary = _travel.validate_surface_registration(travel_candidate)
	if not travel_validation.get("ok", false): return travel_validation
	# This is the last fallible owner commit. Its contract forbids partial writes,
	# signals/await/reentry; all following publications are prepared assignments.
	var admitted: Dictionary = _flow.call("commit_polisa_local_ship_purchase", flow_candidate)
	if not admitted.get("ok", false): return admitted
	_travel.call("_publish_surface_registration", travel_candidate)
	var definitions: Array = _flow.get("_homebase_aircraft_definitions")
	definitions.append(craft)
	_flow.get("_aircraft_location_by_craft")[id] = "mission"
	_pad_by_craft[id] = home_pad
	sync_crafts()
	return {"ok":true,"receipt_schema_version":2,"craft_id":id,"delivery_location_id":"polisa","landing_pad_id":home_pad,"acquisition_pad_id":acquisition_pad,"pad_fit_revision":1,"origin_kind":"local_station_purchase","origin_location_id":"polisa","origin_receipt_id":request_id}
