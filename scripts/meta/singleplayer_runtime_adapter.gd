extends Node
## Scene lifecycle adapter. Gameplay values live in SimulationRoot-bound owners;
## transport phases/payload remain in MetaLayerFlow's existing per-craft path.

const SIM = preload("res://scripts/core/simulation_root.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")

var _base_personnel: Node
var _flow: Node
var _screen: Control
var _simulation: Node
var _campaign: RefCounted
var _supply: RefCounted
var _onboarding: RefCounted
var _travel: RefCounted
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
	_campaign_mode = bool(_flow.call("is_campaign_start"))
	if _campaign_mode:
		_onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
		_onboarding.configure()
	var campaign_result: Dictionary = _campaign.configure()
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
	if _campaign_mode:
		var checkpoint: Dictionary = Dictionary(_flow.get("_campaign_start").get("checkpoint"))
		if not checkpoint.is_empty():
			_campaign.restore_state(checkpoint.campaign)
			_supply.restore_state(checkpoint.supply)
			_onboarding.restore_state(checkpoint.onboarding)
	if _campaign_mode:
		_base_personnel = load("res://scripts/core/base_personnel_runtime.gd").new()
		_base_personnel.name = "BasePersonnelRuntime"
		add_child(_base_personnel)
		_base_personnel.configure(_flow, _screen, _simulation, Dictionary(_flow.get("_campaign_start").get("checkpoint")))
		_screen.call("configure_base_personnel_bridge", _base_personnel)
	var inventory_units: Array = []
	var inventory_crafts: Array = []
	for unit in Array(_flow.get("_all_team_units")): inventory_units.append(String(unit.get("unit_id","")))
	for craft in Array(_flow.get("_homebase_aircraft_definitions")): inventory_crafts.append(String(craft.get("craft_id","")))
	_supply.configure_inventory(inventory_units,inventory_crafts)
	sync_crafts()
	if _screen.has_method("configure_singleplayer_bridge"):
		_screen.call("configure_singleplayer_bridge", get_snapshot, request_operation)
	var catalog: Array = [] if _campaign_mode else Array(_flow.get("_mission_catalog")).duplicate(true)
	for entry in [
		{"mission_id": "satellite_recovery", "mission_name": "Satellitenbergung", "map_file_path": "res://maps/satellite_crash_site.json", "scenario_file_path": "res://data/mission_scenarios/satellite_recovery.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
		{"mission_id": "trade_outpost_visit", "mission_name": "Handelsaußenposten besuchen", "map_file_path": "res://maps/trade_outpost.json", "scenario_file_path": "res://data/mission_scenarios/trade_outpost_visit.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"}]:
		catalog.append(entry)
	_flow.set("_mission_catalog", catalog)

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
		projected.merge({"craft_id": id, "landing_pad_id": _home_pad_for(id), "location_id": String(departure.get("destination_location_id", "")) if location == "mission" else location, "busy": not transfer.is_empty() or (String(travel.get("craft_id", "")) == id and String(travel.get("phase", "grounded")) in ["orbit", "quantum", "stopped", "approach"]), "departure": departure, "visible_on_pad": location == "homebase" and transfer.is_empty() and not _home_pad_for(id).is_empty()}, true)
		crafts.append(projected)
		launch_readiness[id] = validate_space_launch(id, false)
		var context: Dictionary = _service_context(id)
		if not context.is_empty():
			service_contexts[id] = context
	return {"campaign": campaign, "supply": _supply.get_supply_snapshot(), "crafts": crafts, "service_contexts_by_craft_id": service_contexts, "runtime_authority": "SimulationRoot", "mode": "campaign" if _campaign_mode else "skirmish", "base_personnel": _base_personnel.get_snapshot() if _base_personnel != null else {}, "onboarding": _onboarding.get_snapshot() if _onboarding != null else {}, "space_travel": travel, "space_launch_readiness_by_craft_id": launch_readiness}

func sync_crafts() -> void:
	# Lifecycle event only, called when real craft definitions change. Read paths
	# neither allocate a pad nor initialize fuel. Existing assignments never move.
	if _flow == null or _supply == null:
		return
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
		if _pad_by_craft.has(craft_id):
			continue
		for pad in HOME_PADS:
			if not _pad_by_craft.values().has(pad):
				_pad_by_craft[craft_id] = pad
				break

func _home_pad_for(craft_id: String) -> String:
	return String(_pad_by_craft.get(craft_id, ""))

func get_base_personnel_runtime() -> Node:
	return _base_personnel

func request_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
	if operation.begins_with("base_"):
		return _base_personnel.request_operation(operation, payload) if _base_personnel != null else _reject("base_unavailable", "Basisaktion nur in Kampagne")
	if _simulation == null:
		return _reject("runtime_unavailable", "Kampagne noch nicht bereit")
	var data: Dictionary = payload.duplicate(true)
	var request_id: String = _request_id(operation, data)
	data.erase("request_id")
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
		if operation == "select_destination" and _has_active_transit():
			return _reject("craft_in_transit", "Zielwechsel erst nach dem laufenden Flug")
		if operation == "select_destination":
			var travel: Dictionary = _travel.get_snapshot()
			if String(travel.phase) != "grounded" and not (String(travel.phase) == "orbit" and String(travel.orbit_id) == "planet_orbit"):
				return _reject("planet_orbit_required", "Zielort erst im Planetenorbit waehlen; laufenden Anflug oder Ortsbesuch zuerst beenden")
			var mission: Node = _flow.get("_active_mission")
			var requested_location: Dictionary = Dictionary(_campaign.get_campaign_snapshot().locations.get(String(data.get("location_id", "")), {}))
			if mission != null and not requested_location.is_empty():
				var setup: Node = mission.get_node_or_null("MissionSetup")
				if setup != null and String(setup.get("map_file_path")) != String(requested_location.map_file_path):
					return _reject("mission_location_active", "Vor dem Ortswechsel zuerst den laufenden Ausflug beenden")
		var campaign_operation: String = "fail_job" if operation == "abandon_job" else operation
		if _campaign_mode and operation == "accept_job" and String(Dictionary(_campaign.get_campaign_snapshot().jobs.get(String(data.get("job_id", "")), {})).get("status", "")) == "failed":
			campaign_operation = "retry_failed_job"
		var result: Dictionary = _commit("singleplayer_campaign", campaign_operation, data, request_id, {"mission_aborted": operation == "abandon_job"})
		if result.get("ok", false) and operation == "select_destination":
			var location_id: String = String(data.get("location_id", ""))
			if location_id != "homebase":
				_flow.call("_on_homebase_mission_selection_changed", "satellite_recovery" if location_id == "satellite_crash" else "trade_outpost_visit")
		return result
	if operation in ["inventory_transfer","inventory_equip"]:
		var unit_id := String(data.get("unit_id",""))
		var context := _inventory_context(unit_id,String(data.get("craft_id","")))
		if context.is_empty(): return _reject("inventory_access","Person muss an der Basis verfuegbar sein")
		var result := _commit("singleplayer_supply",operation,data,request_id,context)
		if bool(result.get("ok",false)) and operation=="inventory_equip" and not bool(result.get("replayed",false)):
			for key in ["armor","weapon_1","weapon_2"]:
				_screen.call("_set_homebase_member_loadout_value",unit_id,key,String(result.loadout[key]))
			_screen.call("_emit_homebase_fireteam_context_changed")
		return result
	if operation in ["buy", "refuel"]:
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
	if location == "mission" and String(departure.get("destination_location_id", "")) == "trade_outpost":
		var card: Dictionary = _flow.call("_find_mission_drop_card_in_planning_state", craft_id)
		var state: String = String(card.get("state", card.get("mission_drop_state", "")))
		if state in ["landed", "unloading", "complete"]:
			var mission: Node = _flow.get("_active_mission")
			if mission == null:
				return {}
			var setup: Node = mission.get_node_or_null("MissionSetup")
			if setup == null or String(setup.get("scenario_file_path")).get_file().get_basename() != "trade_outpost_visit":
				return {}
			if state == "complete":
				var controller: Node = mission.get_node_or_null("TacticalController")
				if controller == null or not bool(controller.call("_is_parked_campaign_dropship", craft_id)):
					return {}
			var driver: Node = mission.get_node_or_null("CombatLoopDriver")
			if driver == null or not driver.has_method("get_mission_interaction_runtime_states"):
				return {}
			var states: Dictionary = driver.call("get_mission_interaction_runtime_states")
			if bool(Dictionary(states.get("trade_service", {})).get("complete", false)):
				return {"location_id": "trade_outpost", "craft_busy": false}
	return {}

func validate_departure(craft_id: String) -> Dictionary:
	if _base_personnel != null and not _base_personnel.is_pilot_aboard(craft_id):
		return _reject("pilot_not_aboard", "Zugewiesener Pilot muss tatsaechlich im Schiff sein")
	var travel: Dictionary = get_space_travel_snapshot()
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
	var expected_id := "satellite_recovery" if destination == "satellite_crash" else "trade_outpost_visit"
	var mission_definition: Dictionary = _flow.call("_get_selected_mission_definition")
	var selected_location: Dictionary = selected.locations[destination]
	if String(_flow.get("_selected_mission_id")) != expected_id or String(mission_definition.get("map_file_path", "")) != String(selected_location.map_file_path) or String(mission_definition.get("scenario_file_path", "")) != String(selected_location.scenario_file_path):
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
	var departure: Dictionary = {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": destination, "landing_pad_id": pad, "job_id": String(selected.selected_job_id)}
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
		var mission: Node = _flow.get("_active_mission")
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
	var committed: Dictionary = _commit("singleplayer_campaign", operation, {"job_id": job_id, "craft_id": craft_id}, "result:" + String(job_id) + ":" + String(_departure_token_by_craft.get(craft_id, "")), {"runtime_evidence": evidence})
	var receipt: Dictionary = committed.get("completion_receipt", {})
	if not receipt.is_empty():
		_commit("singleplayer_supply", "apply_reward", {"completion_id": receipt.completion_id}, "reward:" + String(receipt.completion_id), {"completion_receipt": receipt})

func _campaign_operation_gate(operation: String, payload: Dictionary) -> Dictionary:
	var stage: int = int(_onboarding.get_snapshot().stage_index)
	if operation == "select_destination":
		var location: String = String(payload.get("location_id", ""))
		if stage < 2 and location == "trade_outpost":
			return _reject("tutorial_locked", "Zuerst den Satelliten bergen und zur Basis zurueckkehren")
		if stage == 2 and location == "satellite_crash":
			return _reject("tutorial_locked", "Jetzt Versorgung am Handelsposten sichern")
		if stage < 2 and location == "satellite_crash" and String(payload.get("job_id", "")) != "satellite_recovery" and String(_campaign.get_campaign_snapshot().selected_job_id) != "satellite_recovery":
			return _reject("job_required", "Zuerst den Satellitenauftrag im Smart Mobile annehmen")
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
	_observe({"base_ready": at_home and ready and String(job.get("status", "")) == "accepted", "satellite_completed": String(job.get("status", "")) == "completed", "satellite_home": at_home, "trade_departed": not at_home and String(departure.get("destination_location_id", "")) == "trade_outpost", "trade_used": String(service.get("location_id", "")) == "trade_outpost", "trade_home": at_home})

func get_space_travel_snapshot() -> Dictionary:
	if _travel == null:
		return {}
	var snapshot: Dictionary = _travel.get_snapshot()
	snapshot["enabled"] = is_campaign_mission() or String(snapshot.phase) != "grounded"
	snapshot["result_summary"] = String(Dictionary(_flow.get("_last_mission_result")).get("result", ""))
	return snapshot

func advance_space_travel(delta: float) -> void:
	if _travel != null and _travel.is_quantum_active():
		_commit("singleplayer_space_travel", "advance", {"delta_seconds": minf(delta, 60.0)}, "", {"runtime_authorized": true})

func validate_space_launch(craft_id: String, observe_progress: bool = true) -> Dictionary:
	if String(_travel.get_snapshot().phase) != "grounded" or _flow.get("_active_mission") != null:
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
	var snapshot := get_space_travel_snapshot()
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
		if location_id != String(_campaign.get_campaign_snapshot().selected_location_id) or location_id not in ["satellite_crash", "trade_outpost"]:
			return _reject("destination_mismatch", "Den gewuenschten Zielort im Planetenorbit auswaehlen")
		var departure := authorize_departure(craft_id)
		if not departure.get("ok", false):
			return departure
		var result := _commit("singleplayer_space_travel", "begin_approach", {"craft_id": craft_id, "location_id": location_id}, owner_request_id, {"runtime_authorized": true})
		_remember_space_operation(request_id, signature, result)
		if result.get("ok", false) and not bool(result.get("replayed", false)):
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
	if not _campaign_mode or String(_travel.get_snapshot().phase) != "grounded":
		return {}
	var state: Dictionary = _campaign.export_state()
	state["departures_by_craft_id"] = {}
	state["selected_location_id"] = "homebase"
	state["selected_job_id"] = ""
	return {"schema_version": 1, "campaign": state, "supply": _supply.export_state(), "onboarding": _onboarding.export_state(), "base_personnel": _base_personnel.export_state() if _base_personnel != null else {}}

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

func _inventory_context(unit_id: String, craft_id: String) -> Dictionary:
	var snapshot: Dictionary = _screen.call("get_operations_snapshot",false)
	var unit: Dictionary = {}
	for entry in Array(snapshot.get("roster",[])):
		if String(entry.id)==unit_id: unit=entry
	if unit.is_empty() or (bool(unit.get("busy",true)) and not bool(unit.get("can_edit",false))): return {}
	if _base_personnel!=null:
		var found := false
		for actor in Array(_base_personnel.get_snapshot().get("units",[])):
			if String(actor.get("unit_id",""))==unit_id:
				found=String(actor.get("status","")) in ["outside","idle"]
		if not found: return {}
	var access: Array = ["base:homebase","unit:"+unit_id+":backpack"]
	if not craft_id.is_empty() and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id,""))=="homebase" and not _service_context(craft_id).is_empty(): access.append("craft:"+craft_id)
	return {"accessible_containers":access,"unit_id":unit_id,"loadout":Dictionary(unit.get("loadout",{})).duplicate(true)}
