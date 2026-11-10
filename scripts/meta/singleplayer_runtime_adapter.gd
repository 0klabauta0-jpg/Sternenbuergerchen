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
var _space_encounter: RefCounted
var _resource_owners: Dictionary = {}
var _campaign_mode := false
var _space_route_requested := false
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
	_screen.call("bind_personnel_loadout_simulation", _simulation, Array(_flow.get("_all_team_units")))

	_simulation.call("configure_space_encounter",_space_encounter)
	if _campaign_mode:
		var checkpoint: Dictionary = Dictionary(_flow.get("_campaign_start").get("checkpoint"))
		if not checkpoint.is_empty():
			_campaign.restore_state(checkpoint.campaign)
			_supply.restore_state(checkpoint.supply)
			_onboarding.restore_state(checkpoint.onboarding)
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
	_supply.configure_inventory(inventory_units,inventory_crafts)
	if _campaign_mode and Dictionary(_flow.get("_campaign_start").get("checkpoint")).is_empty():
		_supply.call("configure_start_inventory","campaign")
	if _flow.has_meta("skirmish_preset_id") and not _flow.has_meta("skirmish_restore_payload"):
		var count := inventory_units.size()
		_supply.call("configure_preset_supply",{"credits":int(_flow.get_meta("skirmish_start_credits",1000)),"stock":{"armor_heavy":maxi(2,count/2),"armor_medium":maxi(2,count/2),"rifle":count,"pistol":count,"medictool":maxi(2,count/4),"mining_tool":2,"salvage_tool":2}})
	sync_crafts()
	if _screen.has_method("configure_singleplayer_bridge"):
		_screen.call("configure_singleplayer_bridge", get_snapshot, request_operation)
	var catalog: Array = [] if _campaign_mode else Array(_flow.get("_mission_catalog")).duplicate(true)
	for entry in [
		{"mission_id": "satellite_recovery", "mission_name": "Satellitenbergung", "map_file_path": "res://maps/satellite_crash_site.json", "scenario_file_path": "res://data/mission_scenarios/satellite_recovery.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
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
	var crafts: Array = []
	var service_contexts: Dictionary = {}
	var launch_readiness: Dictionary = {}
	for definition in Array(_flow.get("_homebase_aircraft_definitions")):
		var id: String = String(definition.get("craft_id", ""))
		var departure: Dictionary = Dictionary(campaign.departures_by_craft_id.get(id, {}))
		var transfer: Dictionary = _flow.call("_find_pending_mission_craft_transfer", id)
		var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(id, "homebase"))
		var projected: Dictionary = definition.duplicate(true)
		projected.merge({"craft_id": id, "landing_pad_id": _home_pad_for(id), "location_id": String(departure.get("destination_location_id", "")) if location == "mission" else location, "busy": not transfer.is_empty() or (String(Dictionary(Dictionary(travel.get("routes",{})).get(id,{})).get("phase","grounded")) in ["orbit", "quantum", "stopped", "approach"]), "departure": departure, "visible_on_pad": location == "homebase" and transfer.is_empty() and not _home_pad_for(id).is_empty()}, true)
		crafts.append(projected)
		launch_readiness[id] = validate_space_launch(id, false)
		var context: Dictionary = _service_context(id)
		if not context.is_empty():
			service_contexts[id] = context
	return {"campaign": campaign, "supply": _supply.get_supply_snapshot(), "crafts": crafts, "service_contexts_by_craft_id": service_contexts, "runtime_authority": "SimulationRoot", "mode": "campaign" if _campaign_mode else "skirmish", "base_personnel": _base_personnel.get_snapshot() if _base_personnel != null else {}, "onboarding": _onboarding.get_snapshot() if _onboarding != null else {}, "space_travel": travel, "space_encounter":_space_encounter.get_snapshot(), "space_launch_readiness_by_craft_id": launch_readiness,"location_runtimes":_flow.call("get_location_runtime_snapshot"),"checkpoint_guard":get_world_checkpoint_guard()}

func sync_crafts() -> void:
	# Lifecycle event only, called when real craft definitions change. Read paths
	# neither allocate a pad nor initialize fuel. Existing assignments never move.
	if _flow == null or _supply == null:
		return
	if _campaign_mode:
		_flow.set_meta("campaign_pad2_built",bool(_campaign.get_campaign_snapshot().progress.second_pad_built))
	var actual: Dictionary = {}
	for definition in Array(_flow.get("_homebase_aircraft_definitions")):
		var craft_id: String = String(definition.get("craft_id", ""))
		if not craft_id.is_empty():
			actual[craft_id] = true
	for craft_id in _pad_by_craft.keys():
		if not actual.has(craft_id):
			_pad_by_craft.erase(craft_id)
			_departure_token_by_craft.erase(craft_id)
	var inventory_units: Array=[]
	for unit in Array(_flow.get("_all_team_units")): inventory_units.append(String(unit.get("unit_id","")))
	_supply.configure_inventory(inventory_units,actual.keys())
	for craft_id in actual:
		_supply.register_craft(String(craft_id))
		_travel.register_craft(String(craft_id))
		if _pad_by_craft.has(craft_id):
			continue
		var pads: Array = HOME_PADS.duplicate()
		if _flow.has_meta("skirmish_preset_id") and _base_personnel != null:
			pads.clear()
			for actual_pad: Dictionary in Array(_base_personnel.get_snapshot().get("layout",{}).get("landing_pads",[])):
				pads.append(String(actual_pad.get("id","")))
		for pad in pads:
			if _campaign_mode and pad == "homebase_pad_02" and not bool(_campaign.get_campaign_snapshot().progress.second_pad_built): continue
			if not _pad_by_craft.values().has(pad):
				_pad_by_craft[craft_id] = pad
				break

	if _base_personnel != null: _base_personnel.call("_refresh_capacity")

func _home_pad_for(craft_id: String) -> String:
	return String(_pad_by_craft.get(craft_id, ""))

func get_base_personnel_runtime() -> Node:
	return _base_personnel

func request_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
	if operation.begins_with("base_"):
		return _base_personnel.request_operation(operation, payload) if _base_personnel != null else _reject("base_unavailable", "Basisaktion nur in Kampagne")
	if _simulation == null:
		return _reject("runtime_unavailable", "Kampagne noch nicht bereit")
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
	if operation in ["campaign_upload","campaign_recruit","campaign_load_crate","campaign_deliver","campaign_build_pad","campaign_fabricate"]:
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
			var travel: Dictionary = _travel.get_snapshot()
			if String(travel.phase) != "grounded" and not (String(travel.phase) == "orbit" and String(travel.orbit_id) == "planet_orbit"):
				return _reject("planet_orbit_required", "Zielort erst im Planetenorbit waehlen; laufenden Anflug oder Ortsbesuch zuerst beenden")

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
	if operation in ["inventory_transfer","inventory_equip"]:
		var unit_id := String(data.get("unit_id",""))
		var context := _inventory_context(unit_id,String(data.get("craft_id","")))
		if context.is_empty(): return _reject("inventory_access","Person muss an der Basis verfuegbar sein")
		var result := _commit("singleplayer_supply",operation,data,request_id,context)
		if bool(result.get("ok",false)) and operation=="inventory_equip" and not bool(result.get("replayed",false)):
			if _base_personnel!=null: _base_personnel.call("claim_manual_control",unit_id)
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

func _has_active_transit() -> bool:
	return not Array(_flow.get("_pending_mission_craft_transfers")).is_empty()

func _service_context(craft_id: String) -> Dictionary:
	if craft_id.is_empty() or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty():
		return {}
	if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty():
		return {}
	var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, ""))
	if location == "homebase":
		if _home_pad_for(craft_id).is_empty():
			return {}
		return {"location_id": "homebase", "craft_busy": false}
	var departure: Dictionary = Dictionary(_campaign.get_campaign_snapshot().departures_by_craft_id.get(craft_id, {}))
	var place_id := String(departure.get("destination_location_id",""))
	if location == "mission" and place_id in ["trade_outpost","satellite_crash"]:
		var card: Dictionary = _flow.call("_find_mission_drop_card_in_planning_state",craft_id)
		if String(card.get("state",card.get("mission_drop_state",""))) not in ["landed","unloading","complete"]: return {}
		var mission: Node = _flow.call("get_mission_for_craft",craft_id)
		var driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
		if driver == null or not driver.has_method("get_mission_interaction_runtime_states"): return {}
		var states: Dictionary = driver.call("get_mission_interaction_runtime_states")
		if bool(Dictionary(states.get("trade_service",{})).get("complete",false)) or bool(Dictionary(states.get("deliver_benit",{})).get("complete",false)):
			return {"location_id":place_id,"craft_busy":false}

	return {}

func validate_departure(craft_id: String) -> Dictionary:
	if _base_personnel != null and not _base_personnel.is_pilot_aboard(craft_id):
		return _reject("pilot_not_aboard", "Zugewiesener Pilot muss tatsaechlich im Schiff sein")
	var travel: Dictionary = get_space_travel_snapshot(craft_id)
	var in_planet_orbit := String(travel.get("craft_id", "")) == craft_id and String(travel.get("phase", "")) == "orbit" and String(travel.get("orbit_id", "")) == "planet_orbit"
	if _campaign_mode:
		observe_campaign_progress()
		var stage: int = int(_onboarding.get_snapshot().stage_index)
		if stage == 0:
			return _reject("preparation_incomplete", "Zuerst Satellitenauftrag annehmen, Ziel waehlen und Boarding abschliessen")
	var selected: Dictionary = _campaign.get_campaign_snapshot()
	var destination: String = String(selected.selected_location_id)
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
	if not in_planet_orbit and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "homebase":
		return _reject("craft_unavailable", "Schiff steht nicht auf seinem Startpad")
	if _screen == null or (not in_planet_orbit and not bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id))) or String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get(craft_id, "")).is_empty():
		return _reject("launch_payload_missing", "Pilot, Trupp und abgeschlossenes Boarding fehlen")
	var definition: Dictionary = _flow.call("_find_homebase_aircraft_definition", craft_id)
	if definition.is_empty() or (not in_planet_orbit and not bool(_screen.call("_can_send_craft", definition, craft_id))) or (in_planet_orbit and not bool(_flow.call("_has_mission_start_payload"))):
		return _reject("launch_payload_invalid", "Schiff und Payload sind nicht startbereit")
	var selected_job:=String(selected.selected_job_id)
	for binding: Dictionary in Dictionary(selected.get("departures_by_craft_id",{})).values():
		if String(binding.get("job_id",""))==selected_job and String(binding.get("craft_id",""))!=craft_id: selected_job=""
	var departure: Dictionary = {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": destination, "landing_pad_id": pad, "job_id": selected_job}
	var campaign_gate: Dictionary = _campaign.validate_departure(departure, {"departure_authorized": true})
	if not campaign_gate.get("ok", false):
		return campaign_gate
	var fuel_gate: Dictionary = _supply.preview_route_fuel(departure, {"departure_authorized": true, "require_return_reserve": true})
	if not fuel_gate.get("ok", false):
		return fuel_gate
	return {"ok": true, "departure": departure}

func authorize_departure(craft_id: String) -> Dictionary:
	var validation: Dictionary = validate_departure(craft_id)
	if not validation.get("ok", false):
		return validation
	var departure: Dictionary = validation.departure
	var token: String = "departure:%s:%s:%d" % [_request_session, craft_id, int(_flow.get("_transfer_sequence")) + 1]
	var fuel: Dictionary = _commit("singleplayer_supply", "consume_route_fuel", departure, token + ":fuel", {"departure_authorized": true, "require_return_reserve": true})
	if not fuel.get("ok", false):
		return fuel
	var bound: Dictionary = _commit("singleplayer_campaign", "bind_departure", departure, token, {"departure_authorized": true})
	if not bound.get("ok", false):
		return bound
	if not String(departure.job_id).is_empty():
		var activated: Dictionary = _commit("singleplayer_campaign", "activate_job", {"job_id": departure.job_id, "craft_id": craft_id}, token + ":active", {"departure_authorized": true})
		if not activated.get("ok", false):
			return activated
	_departure_token_by_craft[craft_id] = token
	return {"ok": true, "departure": departure}

func authorize_return(craft_id: String, request_id: String = "") -> Dictionary:
	if Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty() or _home_pad_for(craft_id).is_empty():
		return _reject("unknown_craft", "Kein reales Schiff mit Rueckkehrpad")
	var binding: Dictionary = Dictionary(_campaign.get_campaign_snapshot().departures_by_craft_id.get(craft_id, {}))
	if binding.is_empty():
		return _reject("no_campaign_departure", "Kein ortsgebundener Abflug fuer dieses Schiff")
	var transfer: Dictionary = _flow.call("_find_pending_mission_craft_transfer", craft_id)
	var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, ""))
	# An explicit abort may reverse the existing outbound transfer; it retains
	# the same fixed-route cost model instead of inventing distance-based fuel.
	if location != "mission" and String(transfer.get("phase", "")) != "to_mission":
		return _reject("craft_not_remote", "Schiff ist nicht im Ausflug")
	if _campaign_mode and location == "mission":
		var mission: Node = _flow.call("get_mission_for_craft",craft_id)
		var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
		if controller == null:
			return _reject("pilot_presence_unknown", "Pilotanwesenheit ist nicht bestaetigt")
		var pilot_guard: Dictionary = controller.call("get_campaign_pilot_flight_guard", craft_id)
		if not bool(pilot_guard.get("ok", false)):
			return pilot_guard
	var route := {"craft_id": craft_id, "origin_location_id": String(binding.destination_location_id), "destination_location_id": "homebase"}
	var outward_token: String = String(_departure_token_by_craft.get(craft_id, ""))
	if outward_token.is_empty():
		return _reject("no_departure_receipt", "Bestaetigter Abflugbeleg fehlt")
	# One return per accepted outward trip, regardless of whether the request
	# came from a UI retry, automatic debrief, or the transport hook itself.
	# Owner replay occurs before fuel validation, so a repeated success remains
	# valid even if its original debit left less than another route's cost.
	var result: Dictionary = _commit("singleplayer_supply", "consume_route_fuel", route, "return:" + outward_token + ":fuel", {"departure_authorized": true})
	if not request_id.is_empty():
		result["return_request_id"] = request_id
	return result

func is_campaign_mission() -> bool:
	return _campaign_mode or _space_route_requested or String(_flow.get("_selected_mission_id")) in ["satellite_recovery", "trade_outpost_visit"]

func record_mission_result(result: Dictionary, authoritative_mission_identity: Dictionary = {}) -> void:
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
			var granted := _campaign_cargo(craft_id,"satellite_chip" if job_id == "satellite_recovery" else "outpost_chip",1,"chip:"+job_id)
			if not bool(granted.get("ok",false)): return
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
	var campaign: Dictionary = _campaign.get_campaign_snapshot()
	var at_home := _flow.get("_active_mission") == null and not _has_active_transit()
	for location in Dictionary(_flow.get("_aircraft_location_by_craft")).values():
		at_home = at_home and String(location) == "homebase"
	var selected_craft: Dictionary = _screen.call("get_operations_snapshot", false).get("selected_craft", {})
	var craft_id: String = String(selected_craft.get("id", ""))
	var ready := not craft_id.is_empty() and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id)) and not String(_screen.call("_get_assigned_pilot_id", craft_id)).is_empty()
	ready = ready and (_base_personnel == null or _base_personnel.is_pilot_aboard(craft_id))
	var job: Dictionary = Dictionary(campaign.jobs.get("satellite_recovery", {}))
	var service := _service_context(craft_id)
	var departure: Dictionary = Dictionary(campaign.departures_by_craft_id.get(craft_id, {}))
	var progress: Dictionary = campaign.get("progress",{})
	_observe({"base_ready":at_home and ready and String(job.get("status","")) == "accepted","satellite_uploaded":String(job.get("status","")) == "completed","outpost_completed":_job_complete("outpost_recovery"),"outpost_recruited":bool(progress.get("recruited_outpost",false)),"crate_loaded":bool(progress.get("crate_loaded",false)),"delivery_completed":_job_complete("benit_delivery"),"outpost_chip_uploaded":_job_complete("outpost_chip_recovery"),"rescue_completed":_job_complete("buccaneer_rescue"),"pilot_recruited":bool(progress.get("recruited_pilot",false)),"second_pad_built":bool(progress.get("second_pad_built",false))})

func get_space_travel_snapshot(craft_id: String = "") -> Dictionary:
	if _travel == null:
		return {}
	var snapshot: Dictionary = _travel.get_snapshot(craft_id)
	snapshot["enabled"] = is_campaign_mission() or String(snapshot.phase) != "grounded"
	snapshot["result_summary"] = String(Dictionary(_flow.get("_last_mission_result")).get("result", ""))
	return snapshot

func advance_space_travel(delta: float) -> void:
	if _travel != null and _travel.is_quantum_active():
		_commit("singleplayer_space_travel", "advance", {"delta_seconds": minf(delta, 60.0)}, "", {"runtime_authorized": true})
	if _space_encounter != null and String(_space_encounter.get_snapshot().get("phase","")) == "combat":
		_commit("campaign_space","advance",{"delta_seconds":minf(delta,1.0)},"",{"runtime_authorized":true})
		_finish_space_encounter_result()

func validate_space_launch(craft_id: String, observe_progress: bool = true) -> Dictionary:
	if String(_travel.get_snapshot(craft_id).phase) != "grounded":
		return _reject("trip_active", "Den laufenden Ausflug zuerst beenden")
	if _base_personnel != null and not _base_personnel.is_pilot_aboard(craft_id):
		return _reject("pilot_not_aboard", "Zugewiesene Person muss tatsächlich am Pilotenplatz an Bord sein")
	if _home_pad_for(craft_id).is_empty() or String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "homebase" or not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty():
		return _reject("craft_unavailable", "Schiff muss auf seinem Startpad bereitstehen")
	var definition: Dictionary = _flow.call("_find_homebase_aircraft_definition", craft_id)
	if _screen == null or definition.is_empty() or not bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id)) or String(_screen.call("_get_assigned_pilot_id", craft_id)).is_empty() or not bool(_screen.call("_can_send_craft", definition, craft_id)):
		return _reject("launch_payload_missing", "Pilot, Trupp und abgeschlossenes Boarding fehlen")
	if _campaign_mode:
		if observe_progress:
			observe_campaign_progress()
		if int(_onboarding.get_snapshot().stage_index) == 0 and String(Dictionary(_campaign.get_campaign_snapshot().jobs.get("satellite_recovery", {})).get("status", "")) != "accepted":
			return _reject("job_required", "Satellitenauftrag im Mobilgerät annehmen")
	return {"ok": true}

func launch_to_moon_orbit(craft_id: String) -> Dictionary:
	var gate := validate_space_launch(craft_id)
	if not gate.get("ok", false):
		return gate
	var result := _commit("singleplayer_space_travel", "launch_to_orbit", {"craft_id": craft_id}, _request_id("orbit-launch", {}), {"runtime_authorized": true})
	if result.get("ok", false):
		_flow.get("_aircraft_location_by_craft")[craft_id] = "starmap"
		# Publish the lifecycle change before any stale preparation callback can
		# edit pilot or payload using the old homebase transport projection.
		_flow.call("_refresh_homebase_screen")
	return result

func finish_space_approach(craft_id: String) -> Dictionary:
	return _commit("singleplayer_space_travel", "finish_approach", {"craft_id": craft_id}, _request_id("approach-finish", {}), {"runtime_authorized": true})

func enter_space_orbit(craft_id: String) -> Dictionary:
	return _commit("singleplayer_space_travel", "enter_orbit", {"craft_id": craft_id}, _request_id("orbit-return", {}), {"runtime_authorized": true})

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
		var result := _commit("singleplayer_space_travel", "start_quantum" if operation == "space_start_quantum" else "abort_quantum", data, owner_request_id)
		return _remember_space_operation(request_id, signature, result)
	if operation == "space_begin_approach":
		if String(snapshot.phase) != "orbit" or String(snapshot.orbit_id) != "planet_orbit":
			return _reject("planet_orbit_required", "Zuerst den Planetenorbit erreichen")
		var location_id := String(data.get("location_id", ""))
		if _campaign_mode:
			var tutorial_gate := _campaign_operation_gate("select_destination", data)
			if not tutorial_gate.get("ok", false):
				return tutorial_gate
		if location_id != String(_campaign.get_campaign_snapshot().selected_location_id) or not Dictionary(_campaign.get_campaign_snapshot().locations).has(location_id) or location_id == "homebase":
			return _reject("destination_mismatch", "Den gewuenschten Zielort im Planetenorbit auswaehlen")
		if String(Dictionary(snapshot.get("location_orbits",{})).get(location_id,"")) != String(snapshot.orbit_id):
			return _reject("destination_orbit_mismatch","Zielort gehört nicht zum aktuellen Orbit; kein Treibstoff verbraucht")
		var departure := authorize_departure(craft_id)
		if not departure.get("ok", false):
			return departure
		var result := _commit("singleplayer_space_travel", "begin_approach", {"craft_id": craft_id, "location_id": location_id}, owner_request_id, {"runtime_authorized": true})
		_remember_space_operation(request_id, signature, result)
		if result.get("ok", false) and not bool(result.get("replayed", false)):
			if location_id == "distress_orbit":
				_space_encounter.start_encounter(craft_id)
				_flow.call("_refresh_homebase_screen")
			else:
				_flow.call("_begin_space_approach", craft_id, departure.departure)
		return result
	if operation == "space_land_homebase":
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
	return {"schema_version": 1, "campaign": state, "supply": _supply.export_state(), "onboarding": _onboarding.export_state(), "base_personnel": _base_personnel.export_state() if _base_personnel != null else {},"location_resources":resources}

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

func _all_at_home() -> bool:
	if not _travel.all_grounded() or _has_active_transit(): return false
	for value in Dictionary(_flow.get("_aircraft_location_by_craft")).values():
		if String(value) not in ["homebase","waiting_pad"]: return false
	return true

func _request_campaign_action(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	if not _campaign_mode and operation not in ["campaign_upload","campaign_fabricate"]: return _reject("campaign_only","Diese Aktion gehört zur Kampagne")
	var snapshot: Dictionary = _campaign.get_campaign_snapshot()
	var craft_id := String(payload.get("craft_id",get_space_travel_snapshot().get("craft_id","")))
	if craft_id.is_empty():
		var definitions: Array = _flow.get("_homebase_aircraft_definitions")
		if not definitions.is_empty(): craft_id = String(definitions[0].craft_id)
	var at_home := _all_at_home()
	if operation == "campaign_upload":
		if not at_home: return _reject("upload_requires_home","Zur Heimatbasis zurückkehren und am Terminal hochladen")
		var job_id := String(payload.get("job_id",""))
		if job_id.is_empty():
			for id in snapshot.jobs:
				if String(snapshot.jobs[id].status) == "pending_upload":
					job_id = String(id)
					break
		var job: Dictionary = snapshot.jobs.get(job_id,{})
		if String(job.get("status","")) != "pending_upload": return _reject("no_chip","Kein geborgener Chip zum Hochladen")
		craft_id = String(job.get("craft_id",craft_id))
		var item_id := "satellite_chip" if job_id == "satellite_recovery" else "outpost_chip"
		var cargo := _campaign_cargo(craft_id,item_id,-1,"upload:"+job_id)
		if not bool(cargo.get("ok",false)): return cargo
		var result := _commit("singleplayer_campaign","upload_job",{"job_id":job_id},"upload:"+job_id,{"at_home":true})
		if bool(result.get("ok",false)):
			var receipt: Dictionary = result.get("completion_receipt",{})
			_commit("singleplayer_supply","apply_reward",{"completion_id":receipt.completion_id},"reward:"+String(receipt.completion_id),{"completion_receipt":receipt})
		observe_campaign_progress()
		return result
	if operation == "campaign_fabricate":
		return _commit("singleplayer_supply","campaign_fabricate",payload,request_id,{"at_home":at_home,"campaign_authorized":true})
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
		if not at_home and String(_service_context(craft_id).get("location_id","")) != "trade_outpost": return _reject("crate_not_here","Kiste am gesicherten Außenposten oder nach Rückkehr übernehmen")
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
