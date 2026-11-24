extends Node
## Scene lifecycle adapter. Gameplay values live in SimulationRoot-bound owners;
## transport phases/payload remain in MetaLayerFlow's existing per-craft path.

const SIM = preload("res://scripts/core/simulation_root.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ORBIT_SURFACES = preload("res://scripts/mission/orbit_surface_locations.gd")
const TANKER_SERVICE = preload("res://scripts/core/emergency_tanker_service.gd")

# Disposable future-input projection, not a live UI/gameplay owner. Actual Root,
# BasePersonnel, BaseActors, terrain and registry perform all candidate validation.
class HexCheckpointReadContext extends Node:
	var _all_team_units: Array = []
	var _aircraft_location_by_craft: Dictionary = {}
	var _last_mission_result: Dictionary = {}
	var definitions: Array = []
	var _homebase_aircraft_definitions: Array:
		get: return definitions
	var pilots: Dictionary = {}
	var payload_teams: Dictionary = {}
	var member_reader: Control
	func is_campaign_start() -> bool: return true
	func _find_homebase_aircraft_definition(id: String) -> Dictionary:
		for definition: Dictionary in definitions:
			if definition.get("craft_id") == id: return definition.duplicate(true)
		return {}
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {}
	func get_space_travel_snapshot(id: String = "") -> Dictionary:
		return {"phase":"grounded"} if id.is_empty() or _aircraft_location_by_craft.has(id) else {}
	func _get_assigned_pilot_id(id: String) -> String: return String(pilots.get(id, ""))
	func _get_homebase_direct_payload_fireteam_ids_for_craft_raw(id: String) -> PackedStringArray:
		return PackedStringArray(payload_teams.get(id, []))
	func _get_member_unit_ids_for_fireteam(id: String) -> PackedStringArray:
		return member_reader.call("_get_member_unit_ids_for_fireteam", id)

static func preflight_campaign_hex_checkpoint(flow: Node, payload: Dictionary) -> Dictionary:
	var store = load("res://scripts/meta/campaign_checkpoint_store.gd")
	var shape: Dictionary = store.validate_payload(payload)
	if not shape.get("ok", false): return shape
	if not payload.has("hex_tactical"): return {"ok":true,"legacy":true}
	if not is_instance_valid(flow) or flow.is_queued_for_deletion() or not flow.is_inside_tree(): return {"ok":false,"reason":"checkpoint_candidate_tree_unavailable"}
	var navigation = load("res://scripts/meta/base_interior_navigation.gd")
	var map = navigation.load_map("res://maps/campaign_intro_base.json")
	# Only the authored, already opted-in navigation map can authorize Hex loading.
	if map == null or map.get_grid_topology() != "hex_axial_v1" or String(map.get_tactical_grid_rules()).is_empty():
		return {"ok":false,"reason":"checkpoint_base_not_hex_enabled"}
	var candidate := HexCheckpointReadContext.new()
	candidate.name = "HexCheckpointCandidate"
	candidate._all_team_units = Array(payload.roster).duplicate(true)
	var fleet: Array = payload.get("fleet", [{"definition":payload.craft.definition,"pilot_id":payload.craft.pilot_id,"location":"homebase"}])
	for ship: Dictionary in fleet:
		var id := String(ship.definition.craft_id)
		candidate.definitions.append(ship.definition.duplicate(true))
		candidate.pilots[id] = String(ship.get("pilot_id", ""))
		candidate._aircraft_location_by_craft[id] = String(ship.get("location", "homebase"))
	for id in payload.hex_tactical.transport:
		candidate.payload_teams[id] = Dictionary(payload.hex_tactical.transport[id].teams).keys()
	candidate.member_reader = load("res://scripts/meta/homebase_screen.gd").new()
	candidate.member_reader.set("_fireteam_definitions", Array(payload.craft.get("fireteam_definitions", [])).duplicate(true))
	candidate.set_meta("campaign_pad2_built", bool(payload.campaign.get("progress", {}).get("second_pad_built", false)))
	var supply = SUPPLY.new()
	var restored: Dictionary = supply.restore_state(payload.supply)
	if not restored.get("ok", false):
		candidate.member_reader.free(); candidate.free()
		return restored
	supply.set_housing_site_limit(load("res://scripts/meta/base_capacity_layout.gd").hex_container_site_count())
	candidate.set_meta("campaign_built_beds", supply.get_campaign_bed_count())
	candidate.set_meta("campaign_built_housing", supply.get_campaign_housing_count())
	candidate.set_meta("campaign_built_housing_beds", supply.get_campaign_housing_beds())
	if supply.get_station_home_pads() > 2: candidate.set_meta("skirmish_infrastructure", {"pads":supply.get_station_home_pads()})
	# No main scene or live Flow configure. The new isolated subtree is freed
	# synchronously, without a tick, whether candidate preparation succeeds or fails.
	flow.get_tree().root.add_child(candidate)
	# Use the existing adapter's real pad allocation in this disposable subtree.
	# A facade with no pad owner cannot validate physical craft clearance.
	var adapter: Node = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	candidate.add_child(adapter)
	adapter._flow = candidate
	adapter._campaign_mode = true
	adapter._campaign = CAMPAIGN.new()
	var campaign_restored: Dictionary = adapter._campaign.restore_state(payload.campaign)
	if not campaign_restored.get("ok",false):
		candidate.member_reader.free(); candidate.free()
		return campaign_restored
	adapter._supply = supply
	adapter._travel = TRAVEL.new()
	adapter._travel.configure()
	var simulation: Node = SIM.new()
	adapter.add_child(simulation)
	adapter._simulation = simulation
	simulation.set_physics_process(false)
	var base: Node = load("res://scripts/core/base_personnel_runtime.gd").new()
	adapter.add_child(base)
	adapter._base_personnel = base
	if base.has_method("set_initial_modular_base"):
		base.call("set_initial_modular_base", Dictionary(supply.get_supply_snapshot().get("modular_base", {})))
	base.configure(candidate, candidate, simulation, {})
	simulation.set_physics_process(false)
	adapter.sync_crafts()
	base._refresh_home_craft_blockers()
	var result: Dictionary
	if not simulation.has_method("prepare_hex_checkpoint_restore"):
		result = {"ok":false,"reason":"hex_checkpoint_api_unavailable"}
	else:
		result = simulation.call("prepare_hex_checkpoint_restore", payload.hex_tactical)
		if result.get("ok", false): result = simulation.call("validate_prepared_hex_checkpoint_restore", result.prepared)
	candidate.member_reader.free()
	candidate.free()
	return result


var _base_personnel: Node
var _fallen: Array = []
var _flow: Node
var _screen: Control
var _simulation: Node
var _campaign: RefCounted
var _supply: RefCounted
var _onboarding: RefCounted
var _travel: RefCounted
var _polisa_shuttle: RefCounted
var _polisa_shuttle_dispatcher: RefCounted
var _polisa_shuttle_home: RefCounted
## Nottankdienst (T2): Zustaende und Restzeit der offenen Auftraege; Geld, Treibstoff und Belege liegen im Versorgungsbesitzer.
var _tanker: RefCounted = TANKER_SERVICE.new()
var _cargo_transfer = preload("res://scripts/core/automatic_cargo_transfer.gd").new()
var _service_pad_reservation: Dictionary = {}
var _ground_cargo_visual_signature := ""
var _ground_cargo_visual_refresh_msec := 0
var _shuttle_return_poll := 0.0
var _shuttle_home_retry := 0.0
var _polisa_market = preload("res://scripts/meta/polisa_recruitment_market.gd").new()
var _polisa_recruit_pending: Dictionary = {}
var _polisa_resident_retry_msec := 0
var _ship_equipment: RefCounted
var _space_encounter: RefCounted
var _encounter_entry_delay := 0.0
var _encounter_entry_feedback: Dictionary = {}
var _skirmish_economy: RefCounted
var _recruit_candidate_signature := ""
var _recruit_candidates: Array = []
var _resource_owners: Dictionary = {}
var _campaign_mode := false
## M6b (B3): offenes Skirmish (Preset-Start). Es teilt mit der Kampagne den Magazinvorrat in der Versorgung (Fach, Startausstattung, Drag and Drop).
var _skirmish_mode := false
var _space_route_requested := false
var _local_warp_arrival_enabled := false
## Enabled only after the local-flight checkpoint join supports safe resume.
var _surface_orbit_path_enabled := false
var _surface_orbit_intents: Dictionary = {}
var _surface_orbit_auto_disabled: Dictionary = {}
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
	_cargo_transfer.configure(Callable(self,"_validate_cargo_transfer"),Callable(self,"_cargo_inventory"),Callable(self,"_transfer_cargo_item"))
	_travel = TRAVEL.new()
	_travel.configure()
	_space_encounter = load("res://scripts/core/campaign_space_encounter.gd").new()
	_campaign_mode = bool(_flow.call("is_campaign_start"))
	_skirmish_mode = not _campaign_mode and _flow.has_meta("skirmish_preset_id")
	_supply.set_campaign_magazine_mode(_campaign_mode or _skirmish_mode)  # M4c/M6b: Magazinvorrat der Person zaehlt in Kampagne und Skirmish
	if _campaign_mode:
		_onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
		_onboarding.configure()
	var campaign_result: Dictionary = _campaign.configure({}, {}, _campaign_mode)
	var supply_result: Dictionary = _supply.configure(Array(_flow.get("_homebase_aircraft_definitions")))
	if not campaign_result.get("ok", false) or not supply_result.get("ok", false):
		push_error("Singleplayer definitions could not be configured")
		return
	# Dauerauftraege (H3): nur in der Kampagne; Namen kommen aus den vorhandenen Anzeige-Katalogen (nur Darstellung).
	_setup_standing_orders()
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
			# Nottankdienst: der Dienstzustand wird gegen die Bestellbelege des Versorgungsstands geprueft (kein stilles Reparieren).
			# Fehlt der Schluessel (alter Stand), gilt "kein Auftrag".
			var tanker_restore: Dictionary = restore_emergency_tanker(checkpoint)
			if not tanker_restore.get("ok", false):
				push_error("Invalid emergency tanker checkpoint: " + String(tanker_restore.get("reason", "")))
				return
			_onboarding.restore_state(checkpoint.onboarding)
			restore_fallen_from_checkpoint(checkpoint)
			if checkpoint.has("polisa_recruitment_market") and not _polisa_market.restore_state(checkpoint.polisa_recruitment_market).get("ok", false):
				push_error("Invalid Polisa recruitment market checkpoint")
				return
			if checkpoint.has("ship_equipment"):
				# LC2e B1: Verlorene Schiffe mit Umbauten bleiben in der Ausruestungsverwaltung (Verlustbeleg traegt die Definition).
				var equipment_definitions: Array = Array(_flow.get("_homebase_aircraft_definitions")).duplicate()
				for lost: Variant in Array(checkpoint.get("lost_craft", [])):
					if typeof(lost) == TYPE_DICTIONARY and bool(lost.get("equipment_kept", false)) and typeof(lost.get("definition")) == TYPE_DICTIONARY: equipment_definitions.append(lost.definition)
				var equipment_restore: Dictionary = _ship_equipment.restore_state(checkpoint.ship_equipment, equipment_definitions, checkpoint.supply.requests, checkpoint.supply.get("inventory", {}))
				if not equipment_restore.get("ok", false):
					push_error("Invalid Warp equipment checkpoint")
					return
	if _campaign_mode:
		# Heimatbasis auf Hex-Boden (die Kampagnenbasis ist immer Hex-Boden, auch bei einem Altstand ohne hex_tactical):
		# Betten der Versorgung auf die echten Stellplaetze begrenzen.
		_supply.set_housing_site_limit(load("res://scripts/meta/base_capacity_layout.gd").hex_container_site_count())
		_flow.set_meta("campaign_built_beds", _supply.get_campaign_bed_count())
		_flow.set_meta("campaign_built_housing", _supply.get_campaign_housing_count())
		_flow.set_meta("campaign_built_housing_beds", _supply.get_campaign_housing_beds())
	if _campaign_mode or _flow.has_meta("skirmish_preset_id"):
		_base_personnel = load("res://scripts/core/base_personnel_runtime.gd").new()
		_base_personnel.name = "BasePersonnelRuntime"
		add_child(_base_personnel)
		if _campaign_mode and _base_personnel.has_method("set_initial_modular_base"):
			_base_personnel.call("set_initial_modular_base", Dictionary(_supply.get_supply_snapshot().get("modular_base", {})))
		var base_checkpoint: Dictionary = Dictionary(_flow.get("_campaign_start").get("checkpoint")) if _campaign_mode else {}
		_base_personnel.configure(_flow, _screen, _simulation, {} if base_checkpoint.has("hex_tactical") else base_checkpoint)
		if base_checkpoint.has("hex_tactical") or (_campaign_mode and bool(_flow.get("_campaign_start").get("active_restore_in_progress"))): _simulation.set_physics_process(false)
		if _campaign_mode and not base_checkpoint.has("hex_tactical") and _base_personnel.has_method("sync_modular_base"):
			_base_personnel.call("sync_modular_base", Dictionary(_supply.get_supply_snapshot().get("modular_base", {})))
		_screen.call("configure_base_personnel_bridge", _base_personnel)
		if _campaign_mode: _configure_polisa_shuttle()
	var inventory_units: Array = []
	var inventory_crafts: Array = []
	for unit in Array(_flow.get("_all_team_units")): inventory_units.append(String(unit.get("unit_id","")))
	for craft in Array(_flow.get("_homebase_aircraft_definitions")): inventory_crafts.append(String(craft.get("craft_id","")))
	_supply.configure_inventory(inventory_units, inventory_crafts, _campaign_mode or _skirmish_mode or _skirmish_economy != null, _skirmish_bag_capacity())
	if _campaign_mode and Dictionary(_flow.get("_campaign_start").get("checkpoint")).is_empty():
		_supply.call("configure_start_inventory","campaign")
	if _flow.has_meta("skirmish_preset_id") and not _flow.has_meta("skirmish_restore_payload"):
		var count := inventory_units.size()
		var stock := {"armor_heavy":maxi(2,count/2),"armor_medium":maxi(2,count/2),"rifle":count,"pistol":count,"medictool":maxi(2,count/4),"mining_tool":2,"salvage_tool":2}
		if _flow.get_meta("skirmish_preset_id") == "points":
			stock = {}
		_supply.call("configure_preset_supply", {"credits": int(_flow.get_meta("skirmish_start_credits", 1000)), "stock": stock})
	sync_crafts()
	if _campaign_mode:
		var checkpoint: Dictionary = Dictionary(_flow.get("_campaign_start").get("checkpoint"))
		if checkpoint.has("hex_tactical"):
			var continue_context := _capture_hex_continue_context(checkpoint)
			var loaded_hex: Dictionary = _restore_campaign_hex_checkpoint(checkpoint)
			if not _hex_continue_context_current(continue_context, bool(loaded_hex.get("committed", false))) or loaded_hex.get("context_changed", false): return
			if not loaded_hex.get("ok", false):
				_flow.get("_campaign_start").set("error_message", "Hex-Kampagnenstand konnte nicht wiederhergestellt werden: " + String(loaded_hex.get("reason", "checkpoint_invalid")))
				_simulation.set_physics_process(false)
				_flow.call_deferred("_campaign_load_failed")
				return
			_simulation.set_physics_process(not bool(_flow.get("_campaign_start").get("active_restore_in_progress")))
	if _campaign_mode and is_instance_valid(_base_personnel):
		_base_personnel.reconcile_restored_ship_overlap(Dictionary(_flow.get("_campaign_start").get("checkpoint")))
		_base_personnel.reconcile_restored_hex_footprint()
	if _screen.has_method("configure_singleplayer_bridge"):
		_screen.call("configure_singleplayer_bridge", get_snapshot, request_operation)
	var catalog: Array = [] if _campaign_mode else Array(_flow.get("_mission_catalog")).duplicate(true)
	for entry in [
		{"mission_id": "satellite_recovery", "mission_name": "Satellitenbergung", "map_file_path": "res://maps/satellite_crash_site.json", "scenario_file_path": "res://data/mission_scenarios/satellite_recovery.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
		{"mission_id": "polisa_visit", "mission_name": "Polisa besuchen", "map_file_path": "res://maps/polisa_station.json", "scenario_file_path": "res://data/mission_scenarios/polisa_visit.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
		{"mission_id": "trade_outpost_visit", "mission_name": "Handelsaußenposten besuchen", "map_file_path": "res://maps/trade_outpost.json", "scenario_file_path": "res://data/mission_scenarios/trade_outpost_visit.json", "slot_count": 4, "time_limit_seconds": 1200.0, "win_condition": "objective_capture"},
		{"mission_id": "satellite_crash_visit", "mission_name": "Absturzstelle besuchen", "map_file_path": "res://maps/satellite_crash_site.json", "scenario_file_path": "res://data/mission_scenarios/satellite_crash_visit.json", "slot_count": 4, "time_limit_seconds": 0.0, "win_condition": "objective_capture"}]:
		catalog.append(entry)
	# Handel-Nachbesserung W3: friedlicher Besuch des Handelsaussenpostens in der Kampagne ohne Zeitlimit (0 = keins); das Skirmish-Szenario trade_outpost_visit bleibt.
	if _campaign_mode:
		catalog.append({"mission_id": "trade_outpost_open_visit", "mission_name": "Handelsaußenposten besuchen", "map_file_path": "res://maps/trade_outpost.json", "scenario_file_path": "res://data/mission_scenarios/trade_outpost_open_visit.json", "slot_count": 4, "time_limit_seconds": 0.0, "win_condition": "objective_capture"})
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

func _restore_campaign_hex_checkpoint(checkpoint: Dictionary) -> Dictionary:
	if not _simulation.has_method("prepare_hex_checkpoint_restore") or _base_personnel == null:
		return {"ok":false,"reason":"hex_checkpoint_api_unavailable"}
	# Restore the existing transport owner from the validated future roster first.
	# No new payload owner: all changes use HomebaseScreen's existing methods.
	var craft: Dictionary = checkpoint.craft
	var context := _capture_hex_continue_context(checkpoint)
	_screen.call("setup_roster", Array(_flow.get("_all_team_units")), PackedStringArray(craft.get("staged_unit_ids", [])))
	if not _hex_continue_context_current(context): return {"ok":false,"reason":"checkpoint_bootstrap_changed"}
	_screen.call("set_fireteam_context", PackedStringArray(craft.get("staged_fireteam_ids", [])), Array(craft.get("fireteam_definitions", [])), false)
	if not _hex_continue_context_current(context): return {"ok":false,"reason":"checkpoint_bootstrap_changed"}
	_screen.call("set_transport_state", Array(_flow.get("_homebase_aircraft_definitions")), Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")), [], [], Dictionary(_flow.get("_aircraft_location_by_craft")), Dictionary(_flow.get("_selected_aircraft_cargo_by_craft")), Dictionary(_flow.get("_loaded_aircraft_cargo_by_craft")), [])
	if not _hex_continue_context_current(context): return {"ok":false,"reason":"checkpoint_bootstrap_changed"}
	for definition: Dictionary in craft.get("fireteam_definitions", []):
		_screen.call("_remove_homebase_direct_payload_fireteam", String(definition.id))
	var state: Dictionary = checkpoint.hex_tactical
	for craft_id in state.transport:
		for team in state.transport[craft_id].teams:
			var all_aboard: bool = not Array(state.transport[craft_id].teams[team]).is_empty()
			for id in state.transport[craft_id].teams[team]:
				var person: Dictionary = state.base_personnel.units.get(id, {})
				all_aboard = all_aboard and person.get("status") == "aboard" and person.get("craft_id") == craft_id
			if all_aboard:
				_screen.call("seed_homebase_direct_launch_payload", String(craft_id), PackedStringArray([team]), true)
			else:
				_screen.call("_add_homebase_direct_payload_fireteam_to_craft", String(team), String(craft_id))
			if not _hex_continue_context_current(context): return {"ok":false,"reason":"checkpoint_bootstrap_changed"}
	var prepared: Dictionary = _simulation.call("prepare_hex_checkpoint_restore", state)
	if not prepared.get("ok", false): return prepared
	var checked: Dictionary = _simulation.call("validate_prepared_hex_checkpoint_restore", prepared.prepared)
	if not checked.get("ok", false): return checked
	# Root coordinates all silent owner tails and guards final model publication.
	return _simulation.call("commit_hex_checkpoint_restore", prepared.prepared)

func _capture_hex_continue_context(checkpoint: Dictionary) -> Dictionary:
	return {"adapter":weakref(self),"flow":weakref(_flow),"screen":weakref(_screen),"simulation":weakref(_simulation),"base":weakref(_base_personnel),"root_context":_simulation.get_hex_ground_context_revision(),"start":_flow.get("_campaign_start"),"checkpoint":JSON.stringify(checkpoint,"",true)}

func _hex_continue_context_current(context: Dictionary, published: bool = false) -> bool:
	var adapter = context.adapter.get_ref()
	if not is_instance_valid(adapter) or adapter.is_queued_for_deletion(): return false
	for name in ["flow","screen","simulation","base"]:
		var node = context[name].get_ref()
		if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree() or adapter.get("_" + ("base_personnel" if name == "base" else name)) != node: return false
	return adapter._flow.get("_campaign_start") == context.start and JSON.stringify(context.start.get("checkpoint"),"",true) == context.checkpoint and adapter._simulation.get("_base_personnel_owner") == adapter._base_personnel and adapter._simulation.get_hex_ground_context_revision() == int(context.root_context) + (1 if published else 0)

func _request_id(prefix: String, payload: Dictionary) -> String:
	var supplied: String = String(payload.get("request_id", "")).strip_edges()
	if not supplied.is_empty():
		return supplied
	_sequence += 1
	return "%s:%s:%d" % [prefix, _request_session, _sequence]

func _commit(category: String, operation: String, payload: Dictionary, request_id: String, context: Dictionary = {}) -> Dictionary:
	return _simulation.request_singleplayer_command({"contract_category": category, "operation": operation, "payload": payload, "request_id": request_id}, context)

## Erreichbarkeit je Ziel (Regel 8 / Auftrag 21.11.): "ok" = die naechste Etappe ist bezahlbar (keine Rueckflugreserve);
## "route_ok" = der Treibstoff reicht fuer den ganzen Hinweg ab dem jetzigen Stand des Schiffs.
func _fuel_reachability(craft_id: String, locations: Dictionary) -> Dictionary:
	var result := {}
	if _supply == null or craft_id.is_empty(): return result
	var travel: Dictionary = _travel.get_snapshot(craft_id) if _travel != null else {}
	for id in locations:
		if String(id) == "homebase": continue
		result[id] = _outbound_fuel_check(craft_id, String(id), travel)
	return result

static func _location_for_orbit(location_orbits: Dictionary, orbit_id: String, preferred: String = "") -> String:
	if orbit_id.is_empty(): return ""
	if not preferred.is_empty() and String(location_orbits.get(preferred, "")) == orbit_id: return preferred
	var ids: Array = []
	for id in location_orbits:
		if String(location_orbits[id]) == orbit_id: ids.append(String(id))
	ids.sort()
	return "" if ids.is_empty() else String(ids[0])

## Etappen, die einem Schiff bis zum Ziel noch bevorstehen: [{leg, origin, destination}].
func _remaining_outbound_legs(travel: Dictionary, location_id: String) -> Array:
	var phase := String(travel.get("phase", "grounded"))
	var orbit := String(travel.get("orbit_id", ""))
	var location_orbits: Dictionary = Dictionary(travel.get("location_orbits", {}))
	var approach := {"leg":"approach", "origin":"homebase", "destination":location_id}
	if phase in ["quantum", "stopped"]: return [approach]
	# Am Ort (Fix-Runde 1, Klein 4): offen sind Ortsabflug (wie nach Hause), Sprung dieser Strecke und Anflug. Im Anflug ist nichts mehr offen.
	if phase == "surface":
		var here := String(travel.get("location_id", ""))
		if here.is_empty() or here == location_id: return []
		return [{"leg":"surface_exit", "origin":here, "destination":"homebase"}, {"leg":"jump", "origin":here, "destination":location_id}, approach]
	if phase == "approach": return []
	if phase == "orbit":
		if not String(location_orbits.get(location_id, "")).is_empty() and orbit == String(location_orbits.get(location_id, "")): return [approach]
		return [{"leg":"jump", "origin":_location_for_orbit(location_orbits, orbit), "destination":location_id}, approach]
	return [{"leg":"launch", "origin":"homebase", "destination":""}, {"leg":"jump", "origin":"homebase", "destination":location_id}, approach]

func _outbound_fuel_check(craft_id: String, location_id: String, travel: Dictionary) -> Dictionary:
	var legs: Array = _remaining_outbound_legs(travel, location_id)
	if legs.is_empty():
		var fuel_now: float = _supply.get_fuel(craft_id)
		return {"ok":true, "next_leg":"", "needed_next":0.0, "needed_total":0.0, "available":fuel_now, "route_ok":true}
	var needed_total := 0.0
	for entry: Dictionary in legs:
		var cost: float = _supply.get_leg_fuel_cost(String(entry.origin), String(entry.destination), String(entry.leg))
		if cost < 0.0: return {"ok":false, "reason":"unknown_route", "message":"Ortsverbindung unbekannt"}
		needed_total += cost
	var first: Dictionary = legs[0]
	var gate: Dictionary = _supply.preview_leg_fuel({"craft_id":craft_id, "leg":first.leg, "origin_location_id":first.origin, "destination_location_id":first.destination}, {"departure_authorized":true})
	var result: Dictionary = {"ok":bool(gate.get("ok", false))}
	if not bool(result.ok):
		for key: String in ["reason", "message", "leg", "needed"]:
			if gate.has(key): result[key] = gate[key]
	var available: float = _supply.get_fuel(craft_id)
	result["next_leg"] = String(first.leg)
	result["needed_next"] = _supply.get_leg_fuel_cost(String(first.origin), String(first.destination), String(first.leg))
	result["needed_total"] = needed_total
	result["available"] = available
	result["route_ok"] = available + 0.00001 >= needed_total
	return result

## Abgeleiteter Zustand "liegen geblieben" (nicht gespeichert): das Schiff ist nicht daheim, keine einzige Folgeetappe ist
## bezahlbar und hier gibt es keinen Tankservice. Die kostenlose Heimlandung zaehlt als bezahlbare Folgeetappe.
## credits_override (nur Pleite-Pruefung, Abschnitt P): rechnet "Tanken bezahlbar" mit einem erreichbaren Kontostand statt dem Guthaben.
func get_fuel_status(craft_id: String, credits_override: Variant = null) -> Dictionary:
	if _supply == null or _travel == null or not _supply.has_fuel_account(craft_id): return {}
	var travel: Dictionary = _travel.get_snapshot(craft_id)
	var phase := String(travel.get("phase", "grounded"))
	var orbit := String(travel.get("orbit_id", ""))
	var location_id := String(travel.get("location_id", ""))
	var location_orbits: Dictionary = Dictionary(travel.get("location_orbits", {}))
	var preferred := String(_campaign.get_campaign_snapshot().get("selected_location_id", "")) if _campaign != null else ""
	var raw_legs: Array = []
	match phase:
		"grounded":
			raw_legs = [{"leg":"launch", "origin":"homebase", "destination":""}]
		"orbit":
			if orbit == "moon_orbit":
				raw_legs.append({"leg":"landing", "origin":"", "destination":"homebase"})
				if not preferred.is_empty() and preferred != "homebase": raw_legs.append({"leg":"jump", "origin":"homebase", "destination":preferred})
			else:
				var here := _location_for_orbit(location_orbits, orbit, preferred)
				raw_legs.append({"leg":"approach", "origin":"homebase", "destination":here})
				raw_legs.append({"leg":"jump", "origin":here, "destination":"homebase"})
		"stopped":
			# Der bezahlte, noch nicht vollendete Sprung wird fortgesetzt und kostet nichts.
			raw_legs = [{"leg":"jump", "origin":"", "destination":"", "free":true}]
		"surface":
			raw_legs = [{"leg":"surface_exit", "origin":location_id, "destination":"homebase"}]
		"approach":
			# Eine abgeschlossene Weltraumbegegnung (zum Beispiel distress_orbit) laesst das Schiff im Anflug haengen, bis der Rueckweg
			# bezahlt ist (commit_campaign_space_return bzw. _finish_space_encounter_result): das ist die Lage eines Ortsabflugs.
			if _encounter_return_pending(craft_id):
				raw_legs = [{"leg":"surface_exit", "origin":"distress_orbit", "destination":"homebase"}]
	var fuel: float = _supply.get_fuel(craft_id)
	var next_legs: Array = []
	var any_affordable := false
	for entry: Dictionary in raw_legs:
		var cost: float = 0.0 if bool(entry.get("free", false)) else _supply.get_leg_fuel_cost(String(entry.origin), String(entry.destination), String(entry.leg))
		if cost < 0.0: continue
		var affordable: bool = fuel + 0.00001 >= cost
		any_affordable = any_affordable or affordable
		next_legs.append({"leg":String(entry.leg), "cost":cost, "affordable":affordable})
	var services: Array = Array(_service_context(craft_id).get("services", [])) if _flow != null else []
	var refuel_here: bool = phase == "grounded" or services.has("refuel")
	# Tanken hilft nur, wenn die Credits fuer mindestens die billigste Folgeetappe hier reichen (ein Tankservice ohne Geld rettet nicht).
	var cheapest_missing := -1.0
	for next_leg: Dictionary in next_legs:
		var missing: float = maxf(float(next_leg.cost) - fuel, 0.0)
		if cheapest_missing < 0.0 or missing < cheapest_missing: cheapest_missing = missing
	var refuel_affordable: bool = refuel_here and not next_legs.is_empty() and (cheapest_missing <= 0.0 or float(_supply.get_credits() if credits_override == null else int(credits_override)) + 0.00001 >= ceil(cheapest_missing * _supply.get_fuel_price_per_unit()))
	var in_transit: bool = phase == "quantum" or (phase == "approach" and raw_legs.is_empty())
	var stranded: bool = phase != "grounded" and not in_transit and not any_affordable and not refuel_affordable
	var strand_place := "none"
	if stranded: strand_place = "surface" if phase == "surface" else ("space" if phase in ["stopped", "approach"] else "orbit")
	# Treibstoffproblem (T2, Nottankdienst): die naechste noetige Etappe ist nicht gedeckt, auch wenn das Schiff noch eine kostenlose
	# Folgeetappe haette (zum Beispiel die Heimlandung aus dem Mondorbit). "stranded" ist strenger: dort ist gar nichts mehr bezahlbar.
	var fuel_problem := false
	if phase != "grounded" and not in_transit:
		for next_leg: Dictionary in next_legs:
			if float(next_leg.cost) > 0.0 and not bool(next_leg.affordable): fuel_problem = true
	return {"craft_id":craft_id, "fuel":fuel, "capacity":_supply.get_fuel_capacity(), "phase":phase, "location_id":location_id, "orbit_id":orbit, "next_legs":next_legs, "stranded":stranded, "strand_place":strand_place, "refuel_here":refuel_here, "refuel_affordable":refuel_affordable, "fuel_problem":fuel_problem}

## Die Begegnung dieses Schiffs ist entschieden und wartet auf den bezahlten Rueckweg.
func _encounter_return_pending(craft_id: String) -> bool:
	if _space_encounter == null: return false
	var pending: Dictionary = _space_encounter.peek_completed_result()
	return not pending.is_empty() and String(pending.get("craft_id", "")) == craft_id

# --- Nottankdienst (T2 des Tanker-Auftrags, 21.11.2026) ------------------------------------------------
# Regeln, Geld, Treibstoff und Belege: SingleplayerSupplyState (Befehle emergency_tanker_order / _deliver / _cancel).
# Zustaende und Restzeit: scripts/core/emergency_tanker_service.gd (hier getickt, in advance_space_travel).
# Diese Stelle liefert nur die Tatsachen (Schiff vorhanden, Tankservice, Treibstoffproblem) und verbindet beide Besitzer.

## Ein Schiff gilt als erreichbar, solange es in der Flotte steht, ein Treibstoffkonto hat und der Reisebesitzer es kennt.
## Wird es waehrenddessen zerstoert oder aus der Flotte entfernt, verfaellt sein Auftrag (_advance_emergency_tanker).
func _tanker_craft_alive(craft_id: String) -> bool:
	if _flow == null or _supply == null or _travel == null or craft_id.is_empty(): return false
	if Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty(): return false
	return _supply.has_fuel_account(craft_id) and _travel.get_flight_state(craft_id) != null

func _tanker_context(craft_id: String) -> Dictionary:
	var status: Dictionary = get_fuel_status(craft_id)
	return {"emergency_tanker_authorized": true, "craft_available": not status.is_empty() and _tanker_craft_alive(craft_id), "at_service_point": bool(status.get("refuel_here", true)), "fuel_problem": bool(status.get("fuel_problem", false))}

## Reine Auskunft vor der Bestellung (T3 zeigt sie an): Menge, Preis, Wartezeit oder der Grund der Sperre samt deutschem Satz.
## Bucht nichts und aendert den Versorgungsstand nicht.
func preview_emergency_tanker(craft_id: String) -> Dictionary:
	if _supply == null or _tanker == null: return _reject("runtime_unavailable", "Tankerdienst noch nicht bereit")
	var result: Dictionary = _supply.preview_emergency_tanker({"craft_id": craft_id}, _tanker_context(craft_id))
	var order: Dictionary = _tanker.get_order(craft_id)
	if not order.is_empty(): result["order"] = Dictionary(_tanker.get_snapshot().orders.get(craft_id, {}))
	return result

func get_emergency_tanker_snapshot() -> Dictionary:
	return _tanker.get_snapshot() if _tanker != null else {"orders": {}, "finished": {}}

## Wie lange nach dem Ende eines Tankerauftrags sein Ergebnis noch angezeigt wird (nur Anzeige, keine Regel).
const TANKER_RESULT_SHOW_SECONDS := 12.0

## Fertige Auskunft fuer die Anzeige (T3): ein Schiff, ein Dictionary, nur lesend. Die Oberflaeche rechnet nichts nach.
## visible: Treibstoffproblem, offener Auftrag oder ein eben beendeter Auftrag. offer: die reine Vorschau (preview_emergency_tanker) samt
## Folgeetappen mit der Menge; order / finished: der Dienstzustand mit Restzeit; free_home_landing: Heimlandung aus dem Mondorbit ist frei.
func get_emergency_tanker_view(craft_id: String) -> Dictionary:
	var view := {"craft_id": craft_id, "visible": false, "fuel_problem": false, "offer": {}, "order": {}, "finished": {}, "free_home_landing": false}
	if _supply == null or _tanker == null or craft_id.is_empty(): return view
	var status: Dictionary = get_fuel_status(craft_id)
	if status.is_empty(): return view
	var snapshot: Dictionary = _tanker.get_snapshot()
	var order: Dictionary = Dictionary(Dictionary(snapshot.orders).get(craft_id, {}))
	var finished: Dictionary = Dictionary(Dictionary(snapshot.finished).get(craft_id, {}))
	var recent: bool = not finished.is_empty() and float(finished.get("age_seconds", 1.0e9)) <= TANKER_RESULT_SHOW_SECONDS
	var problem: bool = bool(status.get("fuel_problem", false))
	view["fuel_problem"] = problem
	view["order"] = order
	view["finished"] = finished if recent else {}
	view["visible"] = problem or not order.is_empty() or recent
	if not view.visible: return view
	var offer: Dictionary = _supply.preview_emergency_tanker({"craft_id": craft_id}, _tanker_context(craft_id))
	if bool(offer.get("ok", false)):
		var fuel_after: float = minf(float(status.get("fuel", 0.0)) + float(offer.quantity), float(status.get("capacity", 0.0)))
		var reach: Array = []
		for next_leg: Dictionary in Array(status.get("next_legs", [])):
			reach.append({"leg": String(next_leg.get("leg", "")), "cost": float(next_leg.get("cost", 0.0)), "reachable": fuel_after + 0.00001 >= float(next_leg.get("cost", 0.0))})
		offer["fuel_after"] = fuel_after
		offer["capacity"] = float(status.get("capacity", 0.0))
		offer["reach"] = reach
	view["offer"] = offer
	if String(status.get("phase", "")) == "orbit" and String(status.get("orbit_id", "")) == "moon_orbit":
		for next_leg: Dictionary in Array(status.get("next_legs", [])):
			if String(next_leg.get("leg", "")) == "landing" and float(next_leg.get("cost", 1.0)) <= 0.0: view["free_home_landing"] = true
	return view

## Bestellen und Stornieren ueber den vorhandenen Befehlsweg (request_operation). Die Lieferung bucht nur der Tick.
func _request_emergency_tanker(operation: String, payload: Dictionary) -> Dictionary:
	if _tanker == null or _supply == null: return _reject("runtime_unavailable", "Tankerdienst noch nicht bereit")
	var craft_id := String(payload.get("craft_id", ""))
	if craft_id.is_empty(): return _reject("invalid_command", TANKER_SERVICE.message_for("invalid_command"))
	if operation == "emergency_tanker_order":
		var request_id: String = _request_id("tanker-order", payload)
		var result: Dictionary = _commit("singleplayer_supply", "emergency_tanker_order", {"craft_id": craft_id}, request_id, _tanker_context(craft_id))
		if bool(result.get("ok", false)) and not bool(result.get("replayed", false)):
			var opened: Dictionary = _tanker.open_order(result)
			if not opened.get("ok", false):
				# Darf nach der Pruefung im Versorgungsbesitzer nicht vorkommen; wenn doch, wird die Buchung sofort voll zurueckgegeben.
				push_error("Tankerauftrag konnte nicht eroeffnet werden: " + String(opened.get("reason", "")))
				_tanker_close(String(result.order_id), "expired", "requested")
				return _reject("tanker_order_failed", "Tankerauftrag konnte nicht eroeffnet werden; Credits erstattet.")
		return result
	# emergency_tanker_cancel
	var order: Dictionary = _tanker.get_order(craft_id)
	if order.is_empty():
		# Zweiter Klick nach einem Storno: derselbe Beleg, keine zweite Erstattung (der Versorgungsbesitzer liefert replayed).
		var finished: Dictionary = _tanker.get_finished(craft_id)
		if String(finished.get("state", "")) == "cancelled":
			return _commit("singleplayer_supply", "emergency_tanker_cancel", {"order_id": String(finished.order_id), "reason": "player"}, String(finished.order_id) + ":cancel", {"emergency_tanker_authorized": true})
		return {"ok": false, "reason": "no_open_order", "message": TANKER_SERVICE.message_for("no_open_order")}
	if String(order.state) in ["at_ship", "refuelling"]:
		return {"ok": false, "reason": "tanker_already_arrived", "message": TANKER_SERVICE.message_for("tanker_already_arrived")}
	var cancelled: Dictionary = _commit("singleplayer_supply", "emergency_tanker_cancel", {"order_id": String(order.order_id), "reason": "player"}, String(order.order_id) + ":cancel", {"emergency_tanker_authorized": true, "emergency_tanker_state": String(order.state)})
	if bool(cancelled.get("ok", false)) and not bool(cancelled.get("replayed", false)):
		_tanker.close_order(String(order.order_id), "cancelled", int(cancelled.get("refund", 0)))
	return cancelled

## Verfall (Schiff zerstoert oder aus der Flotte entfernt): volle Rueckerstattung in jedem Zustand, genau einmal.
func _tanker_close(order_id: String, end_state: String, state: String, why: String = "") -> void:
	var cancelled: Dictionary = _commit("singleplayer_supply", "emergency_tanker_cancel", {"order_id": order_id, "reason": "expired"}, order_id + ":cancel", {"emergency_tanker_authorized": true, "emergency_tanker_state": state})
	if bool(cancelled.get("ok", false)): _tanker.close_order(order_id, end_state, int(cancelled.get("refund", 0)), why)
	else: push_error("Tankerauftrag %s konnte nicht erstattet werden: %s" % [order_id, String(cancelled.get("reason", "?"))])

## Zeit des Nottankdienstes. Der Tick aendert den Versorgungsstand nicht (keine Revision); nur Lieferung und Verfall buchen.
func _advance_emergency_tanker(delta: float) -> void:
	if _tanker == null or _supply == null or not _tanker.has_open_orders(): return
	for order: Dictionary in _tanker.open_orders():
		if not _tanker_craft_alive(String(order.craft_id)): _tanker_close(String(order.order_id), "expired", String(order.state))
	for due: Dictionary in _tanker.advance(delta):
		var delivered: Dictionary = _commit("singleplayer_supply", "emergency_tanker_deliver", {"order_id": String(due.order_id)}, String(due.order_id) + ":deliver", {"emergency_tanker_authorized": true})
		if bool(delivered.get("ok", false)): _tanker.complete(String(due.order_id), int(delivered.get("amount", 0)), int(delivered.get("refund", 0)))
		elif String(delivered.get("reason", "")) in ["craft_unavailable", "unknown_order", "order_closed"]: _tanker_close(String(due.order_id), "expired", String(due.state), String(delivered.get("reason", "")))
		elif _tanker.note_delivery_failure(String(due.order_id), String(delivered.get("reason", "")), delta):
			# Jeder andere Grund: der Dienst versucht es weiter, hoechstens delivery_retry_seconds (Daten). Danach verfaellt der Auftrag mit voller
			# Erstattung, das Schiff ist wieder frei; der Grund steht im Ergebnis (get_finished -> reason) und im Protokoll.
			push_error("Tankerlieferung %s nicht buchbar (%s), Auftrag verfaellt mit voller Erstattung" % [String(due.order_id), String(delivered.get("reason", "?"))])
			_tanker_close(String(due.order_id), "expired", String(due.state), String(delivered.get("reason", "unknown")))

## Beim Laden: Dienstzustand (Schluessel emergency_tanker) gegen die Bestellbelege des Versorgungsstands pruefen und uebernehmen.
## Fehlt der Schluessel, gilt "kein Auftrag" (alter Stand); ein offener Beleg ohne Auftrag oder ein Auftrag ohne Beleg lehnt den Stand ab.
func restore_emergency_tanker(checkpoint: Dictionary) -> Dictionary:
	var state: Dictionary = Dictionary(checkpoint.get("emergency_tanker", {})) if typeof(checkpoint.get("emergency_tanker", {})) == TYPE_DICTIONARY else {"invalid": true}
	var checked: Dictionary = TANKER_SERVICE.validate_against_receipts(state, _supply.get_open_tanker_orders())
	if not checked.get("ok", false): return checked
	if state.is_empty(): _tanker.clear()
	else: _tanker.restore_state(state)
	return {"ok": true}

func get_snapshot() -> Dictionary:
	if _simulation == null:
		return {}
	var campaign: Dictionary = _campaign.get_campaign_snapshot()
	var retry_allowed := _campaign_mode and bool(_retry_failed_home_gate().ok)
	campaign["job_availability"] = _campaign.get_job_availability(retry_allowed)
	_attach_standing_orders(campaign)
	var location_availability := {}
	for location_id: String in campaign.locations:
		location_availability[location_id] = _campaign.validate_location_visit(location_id, retry_allowed)
	campaign["location_availability"] = location_availability
	var travel: Dictionary = get_space_travel_snapshot()
	travel["fuel_reachability"] = _fuel_reachability(String(travel.get("craft_id", "")), Dictionary(campaign.get("locations", {})))
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
	return {"space_wings": _simulation.get_space_wing_snapshot(), "ship_equipment": _ship_equipment.get_snapshot() if _ship_equipment != null else {}, "location_view": _flow.call("get_location_view_snapshot") if _flow.has_method("get_location_view_snapshot") else {}, "home_services": _home_services_snapshot(), "skirmish_economy": economy, "campaign": campaign, "supply": _supply.get_supply_snapshot(), "housing_offer": _housing_offer(), "emergency_tanker": _tanker.get_snapshot(), "crafts": crafts, "service_contexts_by_craft_id": service_contexts, "runtime_authority": "SimulationRoot", "mode": "campaign" if _campaign_mode else "skirmish", "base_personnel": _base_personnel.get_snapshot() if _base_personnel != null else {}, "onboarding": _onboarding.get_snapshot() if _onboarding != null else {}, "space_travel": travel, "space_encounter":_space_encounter.get_snapshot(), "space_launch_readiness_by_craft_id": launch_readiness,"location_runtimes":_flow.call("get_location_runtime_snapshot"),"checkpoint_guard":get_world_checkpoint_guard()}

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
	_supply.configure_inventory(inventory_units, actual.keys(), _campaign_mode or _skirmish_mode or _skirmish_economy != null, _skirmish_bag_capacity())
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
			if not _pad_by_craft.values().has(pad) and String(_service_pad_reservation.get("pad_id", "")) != pad:
				_pad_by_craft[craft_id] = pad
				break

	if _base_personnel != null: _base_personnel.call("_refresh_capacity")
	sync_space_wings()

## LC2e B1: Ein durch Absturz verlorenes Schiff verlaesst alle Besitzer: Reisezustand, Landeplatz, Treibstoff/Schiffslager, Ausruestung.
## Die Flotte (Definition, Pilot, Ort) raeumt der Aufrufer (MetaLayerFlow) vorher. Danach meldet all_grounded() wieder wahr, wenn kein anderes Schiff unterwegs ist.
## equipment_kept: das Schiff hat Umbauten (Belege), die Ausruestungsverwaltung behaelt seinen Eintrag, damit der Komponentenverlauf stimmt.
func retire_lost_craft(craft_id: String) -> Dictionary:
	if _supply == null or craft_id.is_empty(): return {"ok": false, "reason": "supply_unavailable"}
	# LC2i I5: Lag die Auftragsfracht (C-Benit-Kiste) im Schiffslager, steht sie nach dem Verlust wieder am Ladeort bereit: der Lade-Merker geht zurueck.
	var cargo_lost: Array = lost_craft_cargo_names(craft_id)
	_travel.unregister_craft(craft_id)
	_pad_by_craft.erase(craft_id)
	_departure_token_by_craft.erase(craft_id)
	var equipment_kept := false
	if _ship_equipment != null:
		equipment_kept = not bool(_ship_equipment.unregister_unmodified_craft(craft_id).get("ok", false))
	_supply.retire_lost_craft(craft_id, equipment_kept)
	if _campaign_mode and cargo_lost.has("C-Benit-Kiste"):
		_commit("singleplayer_campaign", "unload_crate", {}, "unload:" + craft_id, {"runtime_authorized": true})
	sync_crafts()
	return {"ok": true, "equipment_kept": equipment_kept, "cargo_lost": cargo_lost}

## LC2i I5: Namen der Auftragsfracht, die im Schiffslager von craft_id liegt (heute nur die C-Benit-Kiste, solange sie geladen und nicht geliefert ist).
func lost_craft_cargo_names(craft_id: String) -> Array:
	var names: Array = []
	if _supply == null or not _campaign_mode or craft_id.is_empty(): return names
	var progress: Dictionary = Dictionary(Dictionary(_campaign.call("get_campaign_snapshot")).get("progress", {})) if _campaign != null else {}
	var container: Dictionary = Dictionary(Dictionary(_supply.get_supply_snapshot().inventory).get("craft:" + craft_id, {}))
	if bool(progress.get("crate_loaded", false)) and not bool(progress.get("crate_delivered", false)) and int(Dictionary(container.get("items", {})).get("c_benit_crate", 0)) >= 1:
		names.append("C-Benit-Kiste")
	# Dauerauftrag Fracht: die Frachtkisten gehen mit dem Schiff verloren, der Auftrag bleibt offen (Aufgeben im Haendlerfenster).
	var freight: int = int(Dictionary(container.get("items", {})).get("cargo_crate", 0))
	if freight >= 1:
		names.append("1 Frachtkiste" if freight == 1 else "%d Frachtkisten" % freight)
	return names

func _home_pad_for(craft_id: String) -> String:
	return String(_pad_by_craft.get(craft_id, ""))

func get_base_personnel_runtime() -> Node:
	return _base_personnel

func bind_mission_air_support(mission: Node) -> Dictionary:
	if not is_instance_valid(_flow) or not is_instance_valid(mission) or _flow.call("get_active_mission") != mission or not _flow.is_ancestor_of(mission): return {"ok":false, "reason":"mission_context_changed"}
	var mission_root: Node = mission.get_node_or_null("SimulationRoot")
	if mission_root == null or _simulation == null: return {"ok":false, "reason":"runtime_unavailable"}
	# M4e: nur in der Kampagne zaehlt der Magazinvorrat der Person auch im Einsatz (schmaler Verweis, kein Besitzerwechsel).
	if (_campaign_mode or _skirmish_mode) and _supply != null and mission_root.has_method("bind_mission_magazine_supply"): mission_root.call("bind_mission_magazine_supply", _supply)
	return mission_root.bind_air_support_source(_simulation, self, String(mission.get_meta("location_id", "")))

func get_campaign_entry_feedback() -> Dictionary:
	return _encounter_entry_feedback.duplicate(true)

func get_space_encounter_snapshot() -> Dictionary:
	return _space_encounter.get_snapshot() if _space_encounter != null else {}

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
	if operation == "space_set_orbit_automatic":
		if not _surface_orbit_path_enabled: return _reject("orbit_transit_unavailable", "Orbitdurchflug ist noch nicht verfügbar")
		if payload.size() != 2 or typeof(payload.get("craft_id")) != TYPE_STRING or typeof(payload.get("enabled")) != TYPE_BOOL or _travel == null or _travel.get_flight_state(String(payload.craft_id)) == null: return _reject("invalid_command", "Schiff oder Automatik fehlt")
		var id := String(payload.craft_id)
		if payload.enabled:
			_surface_orbit_auto_disabled.erase(id)
			var current: Dictionary = _surface_orbit_intents.get(id, {})
			if current.get("status") == "manual" and _simulation != null:
				var restart: Dictionary = _simulation.start_singleplayer_orbit_transit(self, id, String(current.get("location_id", "")), String(current.get("direction", "inbound")), _request_id("orbit-transit", {"craft_id":id}))
				if restart.get("ok", false): current["status"] = "flying"; current.erase("reason")
		else:
			_surface_orbit_auto_disabled[id] = true
			var current: Dictionary = _surface_orbit_intents.get(id, {})
			current.erase("pending_approach")
			current.erase("pending_warp")
			if current.get("status") == "starting": current["status"] = "manual"; current["reason"] = "automatic_disabled"
			if _simulation != null: _simulation.stop_singleplayer_orbit_transit(self, id)
		return {"ok":true, "enabled":payload.enabled}
	if operation == "cargo_transfer_cancel":return _cargo_transfer.cancel()
	if operation == "cargo_transfer_all":
		var source:=String(payload.get("source_container_id",""));var target:=String(payload.get("destination_container_id",""))
		var id:=_request_id("cargo-transfer",payload)
		var started:Dictionary=_cargo_transfer.start(id,source,target)
		if not started.get("ok",false) or started.get("replayed",false):return started
		var receipt:Dictionary=_commit("singleplayer_supply","cargo_transfer_start",{"source":source,"target":target},"cargo-order:"+id,{"cargo_transfer_authorized":true})
		if not receipt.get("ok",false) or receipt.get("replayed",false):
			_cargo_transfer.cancel()
			return receipt
		return started
	if operation == "station_shuttle_cancel": return cancel_polisa_service_departure(String(payload.get("craft_id", "")))
	if operation == "station_recruit_open": return _open_polisa_recruitment(payload)
	if operation == "station_recruit_hire": return _request_polisa_recruitment(payload)
	if operation == "station_claim_resident":
		var craft_id := String(payload.get("craft_id", ""))
		var unit_id := String(payload.get("unit_id", ""))
		if String(_service_context(craft_id).get("location_id", "")) != "polisa" or _base_personnel == null: return _reject("station_service_required", "Eigenes Schiff zuerst auf Polisa bereitstellen")
		var states: Dictionary = _base_personnel.get("_states")
		# R4c: Neben der Kennung polisa_recruit_ ist auch eine Person uebernehmbar, die auf Abholung wartet (awaiting_pickup).
		if not _base_personnel.polisa_visit_eligible_by_id(unit_id) or String(Dictionary(states.get(unit_id, {})).get("status", "")) != "station": return _reject("resident_unavailable", "Person ist nicht auf Polisa verfügbar")
		var controller := get_polisa_globe_controller()
		if controller == null or not controller.has_method("claim_polisa_resident"): return _reject("resident_unavailable", "Personalübernahme nicht verfügbar")
		return controller.call("claim_polisa_resident", unit_id, craft_id)
	if operation == "air_support_move":
		if not is_instance_valid(_flow) or not _flow.has_method("get_active_mission"): return _reject("runtime_unavailable", "Keine aktive Bodenmission")
		var mission: Node = _flow.call("get_active_mission")
		var mission_root: Node = mission.get_node_or_null("SimulationRoot") if is_instance_valid(mission) else null
		if mission_root == null: return _reject("runtime_unavailable", "Bodenmission ist nicht bereit")
		var move_command := payload.duplicate(true)
		move_command["request_id"] = _request_id("air-support-move", payload)
		return mission_root.request_air_support_move(move_command)
	if operation in ["air_support_circle", "air_support_role_clear"]:
		if not is_instance_valid(_flow) or not _flow.has_method("get_active_mission"): return _reject("runtime_unavailable", "Keine aktive Bodenmission")
		var mission: Node = _flow.call("get_active_mission")
		var mission_root: Node = mission.get_node_or_null("SimulationRoot") if is_instance_valid(mission) else null
		if mission_root == null: return _reject("runtime_unavailable", "Bodenmission ist nicht bereit")
		if operation == "air_support_circle": return mission_root.request_air_support_circle(payload)
		return mission_root.request_air_support_role_clear(String(payload.get("craft_id", "")), String(payload.get("request_id", "")))
	if operation in ["air_support_takeoff", "air_support_landing"]:
		if payload.size() != 1 or typeof(payload.get("craft_id")) != TYPE_STRING: return _reject("invalid_command", "Schiff fehlt")
		var mission: Node = _flow.call("get_active_mission") if is_instance_valid(_flow) else null
		var mission_root: Node = mission.get_node_or_null("SimulationRoot") if is_instance_valid(mission) else null
		if mission_root == null: return _reject("runtime_unavailable", "Bodenmission ist nicht bereit")
		return mission_root.request_air_support_takeoff(payload.craft_id) if operation == "air_support_takeoff" else mission_root.request_air_support_landing(payload.craft_id)
	if operation == "air_support_attack_order":
		if not is_instance_valid(_flow) or not _flow.has_method("get_active_mission"): return _reject("runtime_unavailable", "Keine aktive Bodenmission")
		var mission: Node = _flow.call("get_active_mission")
		var mission_root: Node = mission.get_node_or_null("SimulationRoot") if is_instance_valid(mission) else null
		if mission_root == null: return _reject("runtime_unavailable", "Bodenmission ist nicht bereit")
		var order_command := payload.duplicate(true)
		order_command["request_id"] = _request_id("air-support-order", payload)
		return mission_root.request_air_support_attack_order(order_command)
	if operation == "air_support_ground_fire":
		if not is_instance_valid(_flow) or not _flow.has_method("get_active_mission"): return _reject("runtime_unavailable", "Keine aktive Bodenmission")
		var mission: Node = _flow.call("get_active_mission")
		var mission_root: Node = mission.get_node_or_null("SimulationRoot") if is_instance_valid(mission) else null
		if mission_root == null: return _reject("runtime_unavailable", "Bodenmission ist nicht bereit")
		var fire_command := payload.duplicate(true)
		fire_command["request_id"] = _request_id("air-support-fire", payload)
		return mission_root.request_air_support_ground_fire(fire_command)
	if operation == "space_fire":
		if _simulation == null: return _reject("runtime_unavailable", "Weltraumsimulation ist nicht bereit")
		return _simulation.request_singleplayer_space_fire(payload.duplicate(true), {"runtime_authorized":true, "actor_id":"singleplayer"})
	if operation == "space_move":
		if _simulation == null: return _reject("runtime_unavailable", "Weltraumsimulation ist nicht bereit")
		return _simulation.request_singleplayer_space_move(payload.duplicate(true))
	if operation == "space_wing_command":
		if typeof(payload.get("command")) != TYPE_DICTIONARY:
			return _reject("invalid_command", "Rottenauftrag ist ungueltig")
		return _request_space_wing_command(payload.command)
	if operation == "select_location_view_craft":
		return _flow.call("select_location_view_craft", String(payload.get("location_id", "")), String(payload.get("craft_id", "")))
	if payload.has("service_location_id") and operation in ["buy", "sell", "standing_accept", "standing_deliver", "refuel", "repair", "inventory_transfer", "inventory_equip", "return_homebase", "station_buy_ship", "station_build_home_pad", "station_install_ship_component", "station_deploy_crew", "station_handoff_crew", "station_board_crew"]:
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
	if operation in ["emergency_tanker_order", "emergency_tanker_cancel"]:
		return _request_emergency_tanker(operation, payload)
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
		return _reject("blueprint_locked","Miningwerkzeug nach der Erwerbserlaubnis aus Mission 3 verfügbar")
	var data: Dictionary = payload.duplicate(true)
	var request_id: String = _request_id(operation, data)
	data.erase("request_id")
	if operation in ["campaign_space_engage","campaign_space_rescue","campaign_space_retreat"]:
		var op := String(operation).trim_prefix("campaign_space_")
		if op == "retreat" and _space_encounter != null and _space_encounter.get_snapshot().get("phase") == "entering":
			var canceled: Dictionary = _simulation.cancel_campaign_space_entry(self, String(_space_encounter.get_snapshot().get("craft_id", "")))
			if not canceled.get("ok", false): return canceled
		if op == "engage" and _space_encounter != null and _space_encounter.get("_combat_owner") != null:
			if String(data.get("target_id", "cutlass")) != "cutlass": return _reject("invalid_hostile_target", "Nur die feindliche Cutlass kann angegriffen werden")
			var ordered: Dictionary = _simulation.request_campaign_space_engage(String(_space_encounter.get_snapshot().get("craft_id", "")), {"runtime_authorized":true})
			if not ordered.get("ok", false): return ordered
		var result := _commit("campaign_space",op,data,request_id)
		_finish_space_encounter_result()
		return result
	if operation in ["campaign_upload","campaign_recruit","campaign_load_crate","campaign_deliver","campaign_build_pad","campaign_build_bed","campaign_build_housing","campaign_build_room","campaign_place_room_bed","campaign_set_room_door","campaign_fabricate","campaign_research"]:
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
			var retry_gate := _retry_failed_home_gate()
			if not retry_gate.ok: return retry_gate
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
				var scenario := _destination_scenario_id(snap, location_id, selected_job)
				_flow.call("_on_homebase_mission_selection_changed",scenario)
		return result
	if operation in ["station_buy_ship", "station_build_home_pad", "station_install_ship_component"]:
		if operation == "station_install_ship_component" and load("res://scripts/mission/space_component_catalog.gd").known(String(data.get("item_id", ""))):
			return _reject("component_not_available", "Diese Schiffskomponente ist noch nicht verfügbar")
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
		if context.is_empty():
			# Person an Bord, Schiff nicht gelandet an der Heimatbasis: sagt, was fehlt.
			if not _aboard_status_craft(unit_id).is_empty(): return _reject("inventory_access","Schiff muss an der Heimatbasis gelandet sein")
			return _reject("inventory_access","Person muss an der Basis verfuegbar sein")
		var result := _commit("singleplayer_supply",operation,data,request_id,context)
		if bool(result.get("ok",false)) and operation=="inventory_equip" and not bool(result.get("replayed",false)):
			if _base_personnel!=null and not bool(context.get("station_context", false)): _base_personnel.call("claim_manual_control",unit_id)
			if bool(context.get("station_context", false)): _project_polisa_loadout(unit_id, String(data.get("craft_id", "")), Dictionary(result.get("loadout", {})))
			_screen.call("_refresh_personnel_loadout_projection")
			_screen.call("_emit_homebase_fireteam_context_changed")
		return result
	if operation == "repair":
		var context:=_service_context(String(data.get("craft_id","")))
		if not bool(context.get("ground_service_verified",false)) or not Array(context.get("services",[])).has("repair"):
			return _reject("repair_service_required","Reparatur nur am lokalen freigegebenen Servicepad")
		return _commit("singleplayer_supply","repair",data,request_id,context)
	if operation in ["standing_accept", "standing_deliver", "standing_abandon"]:
		return _request_standing(operation, data, request_id)
	if operation in ["buy", "refuel", "sell"]:
		if operation == "buy":
			var offered: Dictionary = Dictionary(_supply.get_supply_snapshot().offers).get(String(data.get("offer_id", "")), {})
			var component_catalog = load("res://scripts/mission/space_component_catalog.gd")
			var component_id := String(offered.get("item_id", ""))
			if component_catalog.known(component_id):
				return _reject("component_not_available", "Diese Schiffskomponente ist noch nicht verfügbar")
		if _campaign_mode and operation == "buy":
			var offer: Dictionary = Dictionary(_supply.get_supply_snapshot().offers).get(String(data.get("offer_id","")),{})
			var item := String(offer.get("item_id",""))
			var needed := "mining_tool" if item == "mining_tool" else ("assault_rifle" if item == "rifle" else "")
			if not needed.is_empty() and not Array(_supply.get_supply_snapshot().get("blueprints",[])).has(needed): return _reject("blueprint_locked","Zuerst die passende Erwerbserlaubnis im Kampagnenauftrag freischalten")
		var craft_id: String = String(data.get("craft_id", ""))
		var context: Dictionary = _service_context(craft_id)
		if context.is_empty():
			return _reject("service_unavailable", "Schiff und Trupp muessen am Serviceort bereit sein")
		context["craft_id"]=craft_id
		context["require_blueprints"]=_campaign_mode
		var capability:="trade" if operation in ["buy","sell"] else "refuel"
		if String(context.get("location_id","")) in ["trade_outpost","satellite_crash"] and (not Array(context.get("services",[])).has(capability) or (capability=="refuel" and not bool(context.get("ground_service_verified",false)))):
			return _reject("local_service_required","Schiff muss am freigegebenen lokalen Handels- oder Servicepunkt stehen")
		context["cargo_lift_delivery"]=_campaign_mode and not String(context.get("cargo_lift_container_id","")).is_empty()
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
		if _cargo_transfer.blocks_craft(String(data.get("craft_id",""))):return _reject("cargo_transfer_active","Frachttransfer zuerst abschließen oder abbrechen")
		if not _flow.has_method("_request_singleplayer_return"):
			return _reject("return_unavailable", "Rueckflug noch nicht verfuegbar")
		if _polisa_shuttle_dispatcher != null:
			var service: Dictionary = request_polisa_service_departure(String(data.get("craft_id", "")))
			if not service.get("ok", false) or service.get("handled", false): return service
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
				# W3: wie die Startleute - einmaliges volles Fach (nur wenn die Startausstattung des Standes gewaehrt ist).
				_supply.configure_inventory([String(person.unit_id)], [], true, _skirmish_bag_capacity())
				_supply.provision_new_person(String(person.unit_id))
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

func _validate_cargo_transfer(source:String,target:String)->Dictionary:
	if not _campaign_mode or source==target:return _reject("cargo_invalid_route","Frachtweg ungültig")
	var craft_count:=0
	var location:=""
	var contexts: Array[Dictionary]=[]
	for container:String in [source,target]:
		if container in ["station:polisa:lift","station:trade_outpost:lift"]:continue
		if not container.begins_with("craft:"):return _reject("cargo_invalid_route","Nur lokale Schiffe und Frachtaufzug")
		var context:=_service_context(container.trim_prefix("craft:"))
		var place:=String(context.get("location_id",""))
		if place not in ["polisa","trade_outpost"] or not bool(context.get("ground_service_verified",false)) or not Array(context.get("services",[])).has("cargo"):
			return _reject("cargo_ship_unavailable","Schiff muss am lokalen Frachtpad stehen")
		if not location.is_empty() and location!=place:return _reject("cargo_different_location","Schiffe müssen am selben Frachtservice stehen")
		location=place;contexts.append(context);craft_count+=1
	if craft_count<1:return _reject("cargo_invalid_route","Schiff auswählen")
	for container:String in [source,target]:
		if container.begins_with("station:") and container!="station:"+location+":lift":return _reject("cargo_different_location","Frachtaufzug ist nicht am Schiffsort")
	return {"ok":true}

func _cargo_inventory()->Dictionary:
	return Dictionary(_supply.get_supply_snapshot().get("inventory",{})) if _supply!=null else {}

func _transfer_cargo_item(source:String,target:String,item:String,quantity:int,id:String)->Dictionary:
	return _commit("singleplayer_supply","inventory_transfer",{"source_container_id":source,"destination_container_id":target,"item_id":item,"amount":quantity},"cargo-step:"+id,{"accessible_containers":[source,target],"cargo_transfer_authorized":true})

func has_active_cargo_transfer(craft_id:String)->bool:
	return _cargo_transfer.blocks_craft(craft_id)

func _service_context(craft_id: String) -> Dictionary:
	if not _ground_service_craft_owned(craft_id): return {}
	if craft_id.is_empty() or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty():
		return {}
	if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty():
		return {}
	var location: String = String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, ""))
	if location == "homebase":
		if _home_pad_for(craft_id).is_empty() or not _craft_grounded_at_home(craft_id):
			return {}
		return {"location_id": "homebase", "craft_busy": false, "ground_service_verified":true, "services":["trade","refuel","repair"]}
	var routes: Dictionary = _travel.get_snapshot(craft_id).get("routes", {})
	if routes.has(craft_id) and String(Dictionary(routes[craft_id]).get("phase", "")) not in ["grounded", "surface"]: return {}
	var departure: Dictionary = _craft_visit_binding(craft_id)
	var place_id := String(departure.get("destination_location_id",""))
	if location == "mission" and place_id == "polisa":
		var mission: Node = _flow.call("get_mission_for_craft", craft_id)
		var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
		if controller == null or not bool(controller.call("_is_parked_campaign_dropship", craft_id)): return {}
		# Station-wide service menu after actual docking; walking to the counter is optional.
		return {"location_id":"polisa", "craft_busy":false, "station_service_verified":true, "ground_service_verified":true, "services":["trade","cargo","refuel","repair"], "cargo_lift_container_id":"station:polisa:lift"}
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
			var setup: Node = mission.get_node_or_null("MissionSetup")
			var map = setup.get("_loaded_terrain_map_data") if setup != null else null
			var registry: Node = mission.get_node_or_null("TerrainRegistry")
			var local: Dictionary = load("res://scripts/mission/ground_service_access.gd").at_position(map,registry,controller.call("_campaign_landed_craft_position",craft_id),true)
			if place_id=="satellite_crash" and map!=null and map.has_marker("trade_service") and Vector2(controller.call("_campaign_landed_craft_position",craft_id)).distance_to(map.get_marker_position("trade_service"))<=256.0:
				local["services"]=["trade"]
			local.merge({"location_id":place_id,"craft_busy":false},true)
			return local

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
	var expected_id := _destination_scenario_id(selected, destination, selected_job_definition)
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
	# Regel 8 / Auftrag 21.11.: Aus dem Zielorbit zaehlt nur der Anflug, vom Pad (Direktstart, nur in Tests) die ganze Strecke. Keine Rueckflugreserve.
	var fuel_payload: Dictionary = departure.duplicate(true)
	var fuel_gate: Dictionary
	if in_destination_orbit:
		fuel_payload["leg"] = "approach"
		fuel_gate = _supply.preview_leg_fuel(fuel_payload, {"departure_authorized": true})
	else:
		fuel_gate = _supply.preview_route_fuel(fuel_payload, {"departure_authorized": true, "require_return_reserve": false})
	if not fuel_gate.get("ok", false):
		return fuel_gate
	return {"ok": true, "departure": departure}

func _craft_is_grounded_at_home(craft_id: String) -> bool:
	# Same condition BasePersonnelRuntime._unit_is_home uses for a craft.
	if _flow == null: return false
	if String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id, "")) != "homebase": return false
	if not Dictionary(_flow.call("_find_pending_mission_craft_transfer", craft_id)).is_empty(): return false
	return String(get_space_travel_snapshot(craft_id).get("phase", "grounded")) == "grounded"

func authorize_departure(craft_id: String, approach_request_id: String = "", station_dock: bool = false) -> Dictionary:
	# Wounded persons only block a departure from the home base; later legs may carry them.
	if is_instance_valid(_base_personnel) and _base_personnel.has_method("get_departure_block") and _craft_is_grounded_at_home(craft_id):
		var wounded_block: Dictionary = _base_personnel.call("get_departure_block", craft_id)
		if not wounded_block.is_empty(): return wounded_block
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
	# Regel 8 / Auftrag 21.11.: Der Ortsabflug bucht nur seinen Anteil (Sprung und Landung folgen und buchen selbst), auch nach einem
	# alten Beleg consume_route_fuel oder einem Direktstart ohne Orbit (Fix-Runde 1, Klein 2: kein Sonderfall "ganze Strecke" mehr).
	var exit_leg: Dictionary = Dictionary(preview.route).duplicate(true)
	exit_leg["leg"] = "surface_exit"
	var result: Dictionary = _commit("singleplayer_supply", "consume_leg_fuel", exit_leg, "return:" + String(preview.outward_token) + ":fuel", {"departure_authorized": true})
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
		if _campaign_mode and operation == "complete_job":
			# Optional gear crates: only booked after the mandatory cargo, never able to block the completion.
			var loot_items: Array = _grant_used_interaction_loot(craft_id, scenario_id, _completed_interaction_states(craft_id))
			if not loot_items.is_empty():
				result["loot_items"] = loot_items
	var receipt: Dictionary = committed.get("completion_receipt", {})
	if not receipt.is_empty():
		_commit("singleplayer_supply", "apply_reward", {"completion_id": receipt.completion_id}, "reward:" + String(receipt.completion_id), {"completion_receipt": receipt})

## Interaction runtime states of the live mission of this craft ({} when the mission is already gone).
func _completed_interaction_states(craft_id: String) -> Dictionary:
	var mission: Node = _flow.call("get_mission_for_craft", craft_id) if _flow != null and _flow.has_method("get_mission_for_craft") else null
	var driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	if driver == null or not driver.has_method("get_mission_interaction_runtime_states"):
		return {}
	return Dictionary(driver.call("get_mission_interaction_runtime_states"))

## Books the grants_items of every optional interaction point that was completed in the mission into the ship cargo.
## One receipt per piece, so a repeated delivery books nothing twice. A piece that does not fit is left behind and
## reported; this never rejects or delays the job completion. Returns [{item_id, quantity, left_behind}].
func _grant_used_interaction_loot(craft_id: String, scenario_id: String, states: Dictionary) -> Array:
	var report: Array = []
	var scenario = load("res://scripts/mission/mission_scenario_data.gd").load_from_file("res://data/mission_scenarios/" + scenario_id + ".json")
	if scenario == null:
		return report
	for point_variant in Array(Dictionary(scenario.call("get_vertical_slice")).get("interaction_points", [])):
		var interaction_id: String = String(Dictionary(point_variant).get("interaction_id", ""))
		if interaction_id.is_empty() or not bool(Dictionary(states.get(interaction_id, {})).get("complete", false)):
			continue
		for entry: Dictionary in scenario.call("get_interaction_grants", interaction_id):
			var booked: int = 0
			var left_behind: int = 0
			for piece in range(int(entry.quantity)):
				var cargo: Dictionary = _campaign_cargo(craft_id, String(entry.item_id), 1, "loot:%s:%s:%s:%d" % [scenario_id, interaction_id, String(entry.item_id), piece])
				if bool(cargo.get("ok", false)): booked += 1
				else: left_behind += 1
			report.append({"item_id": String(entry.item_id), "quantity": booked, "left_behind": left_behind})
	return report

func _retry_failed_home_gate() -> Dictionary:
	if _flow == null or _flow.get("_active_mission") != null or _has_active_transit():
		return _reject("retry_requires_home", "Erst zur Basis zurückkehren, dann Auftrag erneut annehmen")
	for location in Dictionary(_flow.get("_aircraft_location_by_craft")).values():
		if String(location) != "homebase":
			return _reject("retry_requires_home", "Erst zur Basis zurückkehren, dann Auftrag erneut annehmen")
	return {"ok":true}

## Nach einem Rückzug ist der Auftrag zu Hause ohne Klick wieder offen. Gleiche Heimat-Bedingung wie "Erneut annehmen";
## sonst bleibt der Auftrag failed mit gesetztem Merker. Mehrfacher Aufruf ändert nichts weiter.
func reopen_retreated_jobs() -> Dictionary:
	var reopened := PackedStringArray()
	if _campaign == null or _simulation == null or not bool(_retry_failed_home_gate().get("ok", false)):
		return {"ok": true, "reopened_job_ids": reopened}
	var jobs: Dictionary = _campaign.get_campaign_snapshot().jobs
	var ids: Array = jobs.keys()
	ids.sort()
	for job_id: String in ids:
		var job: Dictionary = Dictionary(jobs[job_id])
		if String(job.get("status", "")) != "failed" or not bool(job.get("reopen_at_home", false)):
			continue
		# Eigene Anfrage-ID je Rückzug: ein zweiter Rückzug nach dem Wiederöffnen ist kein Replay des ersten.
		var committed: Dictionary = _commit("singleplayer_campaign", "reopen_retreated_job", {"job_id": job_id}, "reopen:%s:%d" % [job_id, int(job.get("retreat_count", 0))])
		if bool(committed.get("ok", false)):
			reopened.append(job_id)
	return {"ok": true, "reopened_job_ids": reopened}

func _campaign_operation_gate(operation: String, payload: Dictionary) -> Dictionary:
	if operation == "select_destination":
		return _campaign.validate_location_visit(String(payload.get("location_id", "")), bool(_retry_failed_home_gate().ok))
	return {"ok":true}

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
	var transit_id := String(snapshot.get("craft_id", ""))
	snapshot["orbit_transit_available"] = _surface_orbit_path_enabled
	snapshot["orbit_transit_automatic"] = not _surface_orbit_auto_disabled.has(transit_id)
	if _surface_orbit_intents.has(transit_id): snapshot["orbit_transit"] = Dictionary(_surface_orbit_intents[transit_id]).duplicate(true)
	var service := _service_shuttle_snapshot()
	if not service.is_empty(): snapshot["service_shuttle"] = service
	if _polisa_shuttle_dispatcher != null:
		var dispatch: Dictionary = _polisa_shuttle_dispatcher.get_snapshot()
		dispatch["waiting_for_pad"] = String(dispatch.get("phase", "")) in ["pilot_pending", "walk_pending", "approaching", "taking_off"] and _service_pad_reservation.is_empty()
		snapshot["service_shuttle_dispatch"] = dispatch
	if _polisa_shuttle_home != null: snapshot["service_shuttle_home"] = _polisa_shuttle_home.get_snapshot()
	if _warp_arrival_feedback.has(String(snapshot.get("craft_id", ""))): snapshot["arrival_feedback"] = Dictionary(_warp_arrival_feedback[snapshot.craft_id]).duplicate(true)
	snapshot["enabled"] = is_campaign_mission() or String(snapshot.phase) != "grounded"
	snapshot["result_summary"] = String(Dictionary(_flow.get("_last_mission_result")).get("result", ""))
	return snapshot

func _service_shuttle_snapshot() -> Dictionary:
	return _polisa_shuttle.get_snapshot() if _polisa_shuttle != null else {}

func request_polisa_service_departure(craft_id: String) -> Dictionary:
	if _cargo_transfer.blocks_craft(craft_id):return _reject("cargo_transfer_active","Frachttransfer zuerst abschließen oder abbrechen")
	if _polisa_shuttle_dispatcher == null: return {"ok":true,"handled":false}
	var state: Dictionary = _polisa_shuttle_dispatcher.get_snapshot()
	if String(state.get("source_craft_id", "")) == craft_id and String(state.get("phase", "")) == "player_departure_pending":
		return {"ok":true,"handled":false}
	var request: Dictionary = _polisa_shuttle_dispatcher.request_departure(craft_id)
	if request.get("ok", false) and request.get("handled", false):
		var shuttle_id := String(_polisa_shuttle_dispatcher.get_snapshot().get("craft_id", ""))
		if not shuttle_id.is_empty():
			var pad: Dictionary = _reserve_service_home_pad(shuttle_id)
			if not pad.get("ok", false): request["message"] = "Shuttle wartet auf einen freien Heimatlandeplatz"
	return request

func cancel_polisa_service_departure(craft_id: String) -> Dictionary:
	if _polisa_shuttle_dispatcher == null: return _reject("shuttle_unavailable", "Keine Shuttlefahrt in Vorbereitung")
	var before: Dictionary = _polisa_shuttle_dispatcher.get_snapshot()
	if String(before.get("source_craft_id", "")) != craft_id: return _reject("shuttle_context_changed", "Das vorbereitende Schiff stimmt nicht überein")
	var result: Dictionary = _polisa_shuttle_dispatcher.cancel_before_transfer()
	if result.get("ok", false) and not result.get("pending", false):
		_release_service_home_pad(String(before.get("craft_id", "")), String(_service_pad_reservation.get("pad_id", "")))
		if _polisa_shuttle_dispatcher.has_method("ack_cancelled"): _polisa_shuttle_dispatcher.ack_cancelled()
		result["message"] = "Shuttlefahrt abgebrochen"
	elif result.get("ok", false):
		result["message"] = "Shuttlefahrt wird sicher abgebrochen"
	else:
		result["message"] = "Shuttlefahrt kann in diesem Zustand nicht sicher abgebrochen werden"
	return result

func _configure_polisa_shuttle() -> Dictionary:
	if _polisa_shuttle_dispatcher != null: return {"ok":true}
	var home = load("res://scripts/core/polisa_shuttle_home_lifecycle.gd").new()
	var home_result: Dictionary = home.configure(_reserve_service_home_pad, _validate_service_home_pad, _release_service_home_pad)
	if not home_result.get("ok", false): return home_result
	var owner = load("res://scripts/core/polisa_shuttle_service.gd").new()
	var dispatcher = load("res://scripts/mission/polisa_shuttle_dispatcher.gd").new()
	var result: Dictionary = dispatcher.configure(_flow, _base_personnel, owner, _verify_polisa_service_evidence)
	if not result.get("ok", false): return result
	_polisa_shuttle_home = home
	_polisa_shuttle = owner
	_polisa_shuttle_dispatcher = dispatcher
	return {"ok":true}

func _verify_polisa_service_evidence(kind: String, person_id: String, craft_id: String, receipt: Dictionary) -> bool:
	if kind == "landing_home" and _polisa_shuttle_home != null:
		return _polisa_shuttle_home.verify_landing(craft_id, receipt)
	if kind == "disembark_home" and _polisa_shuttle_home != null:
		return _polisa_shuttle_home.verify_passenger_exit(craft_id, person_id, receipt)
	if kind == "shuttle_retired_home" and _polisa_shuttle_home != null:
		var controller := get_polisa_globe_controller()
		return _polisa_shuttle_home.verify_departure(craft_id, Dictionary(receipt.get("departure", {}))) and is_instance_valid(controller) and controller.has_method("verify_polisa_service_home_cleanup") and bool(controller.call("verify_polisa_service_home_cleanup", person_id, craft_id, Dictionary(receipt.get("station_cleanup", {}))))
	if kind == "boarding_home" and _polisa_shuttle_home != null and _base_personnel != null:
		return _polisa_shuttle_home.verify_departure(craft_id, Dictionary(receipt.get("departure", {}))) and _base_personnel.verify_polisa_shuttle_return_board_receipt(Dictionary(receipt.get("boarding", {})))
	if kind in ["landing_polisa", "disembark_polisa"]:
		var controller := get_polisa_globe_controller()
		return is_instance_valid(controller) and controller.has_method("verify_polisa_service_arrival") and bool(controller.call("verify_polisa_service_arrival", kind, person_id, craft_id, receipt))
	if kind == "shuttle_retired_polisa" and _base_personnel != null:
		var states: Dictionary = _base_personnel.get("_states")
		var controller := get_polisa_globe_controller()
		return String(Dictionary(states.get(person_id, {})).get("status", "")) == "station" and is_instance_valid(controller) and controller.has_method("verify_polisa_service_retirement") and bool(controller.call("verify_polisa_service_retirement", person_id, craft_id, receipt))
	return false

func _advance_polisa_shuttle_home(delta: float) -> void:
	if _polisa_shuttle == null or _polisa_shuttle_home == null: return
	var service: Dictionary = _polisa_shuttle.get_snapshot()
	var phase := String(service.get("phase", ""))
	var home: Dictionary = _polisa_shuttle_home.get_snapshot()
	_shuttle_home_retry = maxf(0.0, _shuttle_home_retry - maxf(delta, 0.0))
	if phase == "to_station" and home.get("phase") == "departed":
		_polisa_shuttle_home.release()
		return
	if phase == "home_landing_required":
		if home.get("phase") == "idle":
			if _shuttle_home_retry > 0.0: return
			_shuttle_home_retry = 0.5
			var started: Dictionary = _polisa_shuttle_home.begin(String(service.get("craft_id", "")), String(service.get("person_id", "")))
			if not started.get("ok", false): return
		_polisa_shuttle_home.advance(clampf(delta, 0.0, 60.0))
		var receipt: Dictionary = _polisa_shuttle_home.landing_receipt()
		if not receipt.is_empty(): _polisa_shuttle.confirm_landing(receipt)
	elif phase == "home_disembark_required" and _base_personnel != null:
		if _shuttle_home_retry > 0.0: return
		_shuttle_home_retry = 0.5
		var person := String(service.get("person_id", ""))
		var ticket: Dictionary = _polisa_shuttle_home.prepare_passenger_exit(person)
		var layout: Dictionary = _base_personnel.get_snapshot().get("layout", {})
		var raw: Array = layout.get("avatar_spawn_grid", [])
		for interior: Dictionary in layout.get("interiors", []):
			if String(interior.get("id", "")) == "habitat_cutaway_01" and interior.get("door_grid") is Array:
				raw = interior.door_grid
				break
		if not ticket.is_empty() and raw.size() == 2:
			_base_personnel.admit_polisa_shuttle_home(person, ticket, Vector2i(int(raw[0]), int(raw[1])))
	elif phase == "settled":
		var craft := String(service.get("craft_id", ""))
		if home.get("phase") == "landed": _polisa_shuttle_home.begin_departure(craft)
		_polisa_shuttle_home.advance(clampf(delta, 0.0, 60.0))
		var departed: Dictionary = _polisa_shuttle_home.departure_receipt()
		if not departed.is_empty():
			var controller := get_polisa_globe_controller()
			if not is_instance_valid(controller) or not controller.has_method("retire_polisa_service_after_home"): return
			var cleaned: Dictionary = controller.call("retire_polisa_service_after_home", craft, String(service.get("person_id", "")), _polisa_shuttle, _base_personnel)
			if cleaned.get("ok", false) and _polisa_shuttle.retire_home({"departure":departed,"station_cleanup":cleaned}).get("ok", false): _polisa_shuttle_home.release()
	elif phase == "return_boarding_required" and _base_personnel != null:
		var person := String(service.get("person_id", ""))
		var craft := String(service.get("craft_id", ""))
		var request_id := "polisa-service-return:" + craft
		var pad_id := String(home.get("landing_pad_id", ""))
		var layout: Dictionary = _base_personnel.get_snapshot().get("layout", {})
		var pad_grid: Array = []
		for pad: Dictionary in layout.get("landing_pads", []):
			if String(pad.get("id", "")) == pad_id: pad_grid = pad.get("interaction_grid", pad.get("grid", [])); break
		if pad_grid.size() != 2: return
		if home.get("phase") == "landed":
			_shuttle_return_poll = maxf(0.0, _shuttle_return_poll - maxf(delta, 0.0))
			if _shuttle_return_poll > 0.0: return
			_shuttle_return_poll = 0.25
			_base_personnel.request_polisa_shuttle_return_board(person, craft, Vector2i(int(pad_grid[0]), int(pad_grid[1])), request_id)
		var boarding: Dictionary = _base_personnel.get_polisa_shuttle_return_board_receipt(person, craft, request_id)
		if boarding.is_empty(): return
		if home.get("phase") == "landed": _polisa_shuttle_home.begin_departure(craft)
		_polisa_shuttle_home.advance(clampf(delta, 0.0, 60.0))
		var departed: Dictionary = _polisa_shuttle_home.departure_receipt()
		if not departed.is_empty() and _polisa_shuttle.begin_return({"boarding":boarding,"departure":departed}).get("ok", false): _polisa_shuttle_home.release()
	elif phase in ["station_landing_required", "station_disembark_required"]:
		var controller := get_polisa_globe_controller()
		if not is_instance_valid(controller) or not controller.has_method("get_polisa_service_arrival"): return
		var craft := String(service.get("craft_id", ""))
		var person := String(service.get("person_id", ""))
		if phase == "station_landing_required":
			if not controller.has_method("begin_polisa_service_return_landing"): return
			var arrival: Dictionary = controller.call("begin_polisa_service_return_landing", craft, person, _polisa_shuttle)
			if not arrival.get("ok", false): return
			var landing: Dictionary = controller.call("get_polisa_service_arrival", craft, "landing_polisa")
			if not landing.is_empty(): _polisa_shuttle.confirm_station_landing(landing)
		else:
			var exit_receipt: Dictionary = controller.call("get_polisa_service_arrival", craft, "disembark_polisa")
			if not exit_receipt.is_empty(): _polisa_shuttle.confirm_station_disembark(exit_receipt)
	elif phase == "returned":
		var controller := get_polisa_globe_controller()
		if not is_instance_valid(controller) or not controller.has_method("retire_polisa_service_ship"): return
		var craft := String(service.get("craft_id", ""))
		var person := String(service.get("person_id", ""))
		var exit_receipt: Dictionary = controller.call("get_polisa_service_arrival", craft, "disembark_polisa")
		if exit_receipt.is_empty(): return
		var retired: Dictionary = controller.call("retire_polisa_service_ship", craft, person, exit_receipt)
		if retired.get("ok", false): _polisa_shuttle.retire_station(retired)

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
	_advance_emergency_tanker(delta)
	_cargo_transfer.advance(delta)
	_project_ground_cargo_lifts()
	_advance_surface_orbit_intents()
	_advance_polisa_recruitment()
	_restore_polisa_residents()
	if _polisa_shuttle_dispatcher != null:
		var dispatch: Dictionary = _polisa_shuttle_dispatcher.get_snapshot()
		var phase := String(dispatch.get("phase", ""))
		var can_advance := true
		if phase in ["pilot_pending", "walk_pending", "approaching", "taking_off"]:
			can_advance = _reserve_service_home_pad(String(dispatch.get("craft_id", ""))).get("ok", false)
		if can_advance: _polisa_shuttle_dispatcher.advance(clampf(delta, 0.0, 60.0))
		var after: Dictionary = _polisa_shuttle_dispatcher.get_snapshot()
		if String(after.get("phase", "")) == "cancelled":
			_release_service_home_pad(String(after.get("craft_id", "")), String(_service_pad_reservation.get("pad_id", "")))
			_polisa_shuttle_dispatcher.ack_cancelled()
	if _polisa_shuttle != null:
		_polisa_shuttle.advance(clampf(delta, 0.0, 60.0))
		_advance_polisa_shuttle_home(delta)
	if _travel != null and _travel.is_quantum_active():
		var step := minf(delta, 60.0)
		var local_requested := _local_warp_arrival_enabled
		if _surface_orbit_path_enabled:
			for active: Dictionary in _travel.get_active_quantum_progress():
				var route_intent: Dictionary = _surface_orbit_intents.get(String(active.craft_id), {})
				if not route_intent.is_empty() and route_intent.get("target_orbit_id") == active.get("target_orbit_id"):
					local_requested = true; break
		if step <= 0.0 or not local_requested:
			_commit("singleplayer_space_travel", "advance", {"delta_seconds":step}, "", {"runtime_authorized":true})
		else:
			for progress: Dictionary in _travel.get_active_quantum_progress():
				var craft_id := String(progress.craft_id)
				var intent: Dictionary = _surface_orbit_intents.get(craft_id, {})
				var local_arrival: bool = _local_warp_arrival_enabled or (not intent.is_empty() and intent.get("target_orbit_id") == progress.get("target_orbit_id"))
				var completing: bool = local_arrival and _simulation != null and (_simulation.is_singleplayer_warp_entry_pending(craft_id) or float(progress.elapsed_seconds) + step >= float(progress.duration_seconds))
				if not local_arrival or not completing:
					_commit("singleplayer_space_travel", "advance", {"craft_id":craft_id, "delta_seconds":step}, "", {"runtime_authorized":true})
				else:
					var arrival: Dictionary = _simulation.advance_singleplayer_warp_entry(self, craft_id, step)
					if arrival.get("ok", false) and arrival.get("status") == "complete":
						_warp_arrival_feedback.erase(craft_id)
						if not intent.is_empty():
							intent["direction"] = "inbound"
							intent["status"] = "manual"
							if not _surface_orbit_auto_disabled.has(craft_id):
								var automatic: Dictionary = _simulation.start_singleplayer_orbit_transit(self, craft_id, String(intent.location_id), "inbound", _request_id("orbit-transit", {"craft_id":craft_id}))
								intent["status"] = "flying" if automatic.get("ok", false) else "manual"
								intent["reason"] = String(automatic.get("reason", ""))
						if not arrival.get("replayed", false): call_deferred("_publish_warp_entry_event", String(arrival.receipt_id))
					else:
						_warp_arrival_feedback[craft_id] = {"status":"searching" if arrival.get("ok", false) else "waiting", "reason":String(arrival.get("reason", ""))}
	if _space_encounter != null and String(_space_encounter.get_snapshot().get("phase", "")) == "entering":
		_encounter_entry_delay -= maxf(delta, 0.0)
		if _encounter_entry_delay <= 0.0:
			_encounter_entry_delay = 0.25
			_encounter_entry_feedback = _simulation.advance_campaign_space_entry(self, String(_space_encounter.get_snapshot().get("craft_id", "")))
	if _space_encounter != null and String(_space_encounter.get_snapshot().get("phase","")) == "combat":
		_simulation.advance_campaign_space_fire({"runtime_authorized":true})
		_commit("campaign_space","advance",{"delta_seconds":minf(delta,1.0)},"",{"runtime_authorized":true})
	# A transient transaction rejection must not strand a terminal encounter.
	if _space_encounter != null and not _space_encounter.peek_completed_result().is_empty():
		_finish_space_encounter_result()

func _advance_surface_orbit_intents() -> void:
	if _simulation == null: return
	for craft_id: String in _surface_orbit_intents.keys():
		var intent: Dictionary = _surface_orbit_intents[craft_id]
		if intent.get("status") != "flying": continue
		var status: Dictionary = _simulation.get_space_flight_status(craft_id)
		if status.get("reason") == "arrived":
			intent["status"] = "arrived"
			if intent.has("pending_approach"):
				intent["status"] = "completing"
				call_deferred("_finish_surface_orbit_approach", craft_id)
			elif intent.has("pending_warp"):
				intent["status"] = "completing"
				call_deferred("_finish_surface_orbit_warp", craft_id)
		elif status.get("reason") == "interrupted" or (status.has("ok") and not status.ok):
			intent["status"] = "manual"
			intent["reason"] = String(status.get("reason", "interrupted"))
			intent.erase("pending_approach")
			intent.erase("pending_warp")

func _finish_surface_orbit_approach(craft_id: String) -> void:
	var intent: Dictionary = _surface_orbit_intents.get(craft_id, {})
	if intent.get("status") != "completing" or typeof(intent.get("pending_approach")) != TYPE_DICTIONARY: return
	var pending: Dictionary = intent.pending_approach
	intent.erase("pending_approach")
	intent["status"] = "arrived"
	var result := _request_space_operation("space_begin_approach", {"craft_id":craft_id, "location_id":String(intent.location_id)}, String(pending.request_id))
	if not result.get("ok", false):
		intent["status"] = "manual"
		intent["reason"] = String(result.get("reason", "approach_failed"))

func _finish_surface_orbit_warp(craft_id: String) -> void:
	var intent: Dictionary = _surface_orbit_intents.get(craft_id, {})
	if intent.get("status") != "completing" or typeof(intent.get("pending_warp")) != TYPE_DICTIONARY: return
	var pending: Dictionary = intent.pending_warp
	intent.erase("pending_warp")
	intent["status"] = "arrived"
	var result := _request_space_operation("space_start_quantum", Dictionary(pending.payload), String(pending.request_id))
	if not result.get("ok", false):
		intent["status"] = "manual"
		intent["reason"] = String(result.get("reason", "warp_failed"))

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

## Speichern, erster Teil / 21.11.: Vor dem Abheben von der Heimatbasis wird einmal erzwungen gespeichert, damit das Ausruesten der
## ersten Minuten nicht an der Fuenf-Minuten-Drossel haengt. "Erzwungen" heisst nur: ohne Drossel, nicht ohne Pruefung
## (request_campaign_save laeuft ueber denselben get_home_checkpoint_guard). Wird abgelehnt, bleibt der vorige gueltige Stand
## unberuehrt und das Schiff hebt trotzdem ab; die Antwort steht in der Rueckgabe (pre_launch_save) und im Meta des Flows. Fix-Runde 1 (W1):
## der Flow zeigt dem Spieler das Ergebnis (_report_launch_save: "Gespeichert." oder "Vor dem Abheben nicht gespeichert: <Grund>").
func _save_before_launch() -> Dictionary:
	if not _campaign_mode or _flow == null or not _flow.has_method("request_campaign_save"):
		return {}
	# Nur der Heimweg: Laeuft gerade ein Einsatz an einem Ort, ist das nicht der Moment fuer einen Einsatzstand. Der Spieler erfaehrt es
	# trotzdem (statt Stille): keine Speicherung, es gilt der zuletzt gespeicherte Stand.
	if is_instance_valid(_flow.get("_active_mission")):
		var skipped := {"ok": false, "reason": "launch_during_mission", "skipped": true}
		_flow.set_meta("campaign_launch_save_result", skipped)
		return skipped
	var saved: Dictionary = Dictionary(_flow.call("request_campaign_save")).duplicate(true)
	_flow.set_meta("campaign_launch_save_result", saved)
	return saved

func launch_to_moon_orbit(craft_id: String) -> Dictionary:
	var pre_launch_save: Dictionary = _save_before_launch()
	# M4d: Mitfliegende VOR dem Abflug lesen; danach steht ihr Status auf "away" und die Bordliste ist leer.
	var ammo_crew: Array = Array(_flow.call("_aboard_unit_ids_of_craft", craft_id)).duplicate() if _flow != null else []
	var request_id := _request_id("orbit-launch", {})
	var result: Dictionary = _simulation.commit_singleplayer_space_launch(self, craft_id, request_id)
	if result.get("ok", false):
		_flow.get("_aircraft_location_by_craft")[craft_id] = "starmap"
		# Publish the lifecycle change before any stale preparation callback can
		# edit pilot or payload using the old homebase transport projection.
		_flow.call("_refresh_homebase_screen")
		if not result.get("replayed", false): call_deferred("_publish_space_launch_event", request_id)
		# M6b (B1): der Abflug ist bestaetigt -> nur melden, wie viele Faecher der Mitfliegenden leer sind (nichts wird aufgefuellt).
		var ammo_departure: Dictionary = {} if result.get("replayed", false) else departure_ammo_notice(craft_id, ammo_crew)
		var travel: Dictionary = Dictionary(result.travel_result)
		if not String(ammo_departure.get("short_message", "")).is_empty():
			travel = travel.duplicate()
			travel["ammo_message"] = String(ammo_departure.short_message)
		if not pre_launch_save.is_empty():
			travel = travel.duplicate()
			travel["pre_launch_save"] = pre_launch_save
		return travel
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
	if _local_warp_arrival_enabled and _simulation != null and _simulation.is_station_purchase_local_admission_current(craft_id):
		return enter_purchased_station_local_orbit(craft_id)
	if flight != null and flight.get_snapshot().get("coordinate_frame") == "local" and ((flight.get_snapshot().get("motion_mode") == "inactive" and _travel.get_craft_snapshot(craft_id).get("phase") in ["surface", "approach"]) or (flight.get_snapshot().get("motion_mode") == "tactical" and _travel.get_craft_snapshot(craft_id).get("phase") == "orbit")):
		var origin_location := String(_travel.get_craft_snapshot(craft_id).get("location_id", ""))
		var result: Dictionary = _simulation.commit_singleplayer_local_return(self, craft_id)
		if result.get("ok", false) and not result.get("replayed", false):
			call_deferred("_publish_local_return_events", String(result.receipt_id))
			if _surface_orbit_path_enabled and not origin_location.is_empty() and origin_location != "polisa":
				_surface_orbit_intents[craft_id] = {"location_id":origin_location, "target_orbit_id":String(_travel.get_craft_snapshot(craft_id).get("orbit_id", "")), "direction":"outbound", "status":"starting"}
				call_deferred("_start_surface_orbit_outbound", craft_id, origin_location)
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
	if _service_pad_blocks_craft(craft_id): return _reject("pad_busy", "Heimatpad ist vorübergehend vom Stationsshuttle belegt")
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

func _start_surface_orbit_outbound(craft_id: String, location_id: String) -> void:
	if not _surface_orbit_path_enabled or _simulation == null or _travel == null: return
	var travel: Dictionary = _travel.get_craft_snapshot(craft_id)
	var orbit_id := String(travel.get("orbit_id", ""))
	var intent: Dictionary = _surface_orbit_intents.get(craft_id, {})
	if intent.get("location_id") != location_id or intent.get("direction") != "outbound" or intent.get("status") != "starting": return
	intent["target_orbit_id"] = orbit_id
	intent["status"] = "manual"
	if _surface_orbit_auto_disabled.has(craft_id): intent.erase("pending_warp"); return
	var result: Dictionary = _simulation.start_singleplayer_orbit_transit(self, craft_id, location_id, "outbound", _request_id("orbit-transit", {"craft_id":craft_id}))
	intent["status"] = "flying" if result.get("ok", false) else "manual"
	intent["reason"] = String(result.get("reason", ""))
	if not result.get("ok", false): intent.erase("pending_warp")

func _record_surface_orbit_intent(craft_id: String, target_orbit_id: String) -> void:
	_surface_orbit_intents.erase(craft_id)
	if not _surface_orbit_path_enabled or _campaign == null or _travel == null: return
	# Capture the already selected campaign destination at command time, not
	# the current UI selection later when the asynchronous warp completes.
	var campaign: Dictionary = _campaign.get_campaign_snapshot()
	var location_id := String(campaign.get("selected_location_id", ""))
	if location_id.is_empty() or location_id == "polisa" or not Dictionary(campaign.get("locations", {})).has(location_id): return
	var travel: Dictionary = _travel.get_craft_snapshot(craft_id)
	if String(Dictionary(travel.get("location_orbits", {})).get(location_id, "")) != target_orbit_id: return
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(target_orbit_id, {})
	var body: Dictionary = Dictionary(travel.get("bodies", {})).get(String(orbit.get("body_id", "")), {})
	if not ORBIT_SURFACES.contains(body, location_id): return
	_surface_orbit_intents[craft_id] = {"location_id":location_id, "target_orbit_id":target_orbit_id, "status":"warp"}

func requires_surface_orbit_exit_band(craft_id: String) -> bool:
	return _surface_orbit_path_enabled and not Dictionary(_surface_orbit_intents.get(craft_id, {})).is_empty()

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
			var transit: Dictionary = _surface_orbit_intents.get(craft_id, {})
			if transit.get("status") in ["starting", "flying"] and not _surface_orbit_auto_disabled.has(craft_id):
				if transit.has("pending_approach"): return _reject("approach_pending", "Vorgemerkten Anflug zuerst abschließen oder abbrechen")
				if transit.get("direction") != "outbound": return _reject("orbit_direction_conflict", "Während des Einflugs ist kein Warp vorgemerkt")
				var target := String(data.get("target_orbit_id", ""))
				if not Dictionary(snapshot.get("orbits", {})).has(target) or target == String(snapshot.get("orbit_id", "")): return _reject("unknown_orbit", "Sprungziel passt nicht")
				var previous: Dictionary = transit.get("pending_warp", {})
				if not previous.is_empty() and String(previous.request_id) != request_id: return _reject("warp_pending", "Sprung ist bereits vorgemerkt")
				if not previous.is_empty() and String(previous.get("signature", "")) != signature: return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
				transit["pending_warp"] = {"request_id":request_id, "signature":signature, "payload":data.duplicate(true)}
				return {"ok":true, "pending":true, "message":"Orbitdurchflug läuft; Sprung folgt am Weltraumrand"}
			var warp_command := data.duplicate(true); warp_command["request_id"] = owner_request_id
			var departure: Dictionary = _simulation.commit_singleplayer_warp_departure(self, warp_command)
			if not departure.get("ok", false): return departure
			var warp_result: Dictionary = departure.travel_result.duplicate(true)
			if departure.get("replayed", false): warp_result["replayed"] = true
			if not departure.get("replayed", false): _record_surface_orbit_intent(craft_id, String(data.get("target_orbit_id", "")))
			_remember_space_operation(request_id, signature, warp_result)
			if not departure.get("replayed", false): call_deferred("_publish_warp_departure_event", String(departure.receipt_id))
			return warp_result
		var result := _commit("singleplayer_space_travel", "start_quantum" if operation == "space_start_quantum" else "abort_quantum", data, owner_request_id)
		if result.get("ok", false) and not result.get("replayed", false):
			if operation == "space_start_quantum": _record_surface_orbit_intent(craft_id, String(data.get("target_orbit_id", "")))
			else: _surface_orbit_intents.erase(craft_id)
		return _remember_space_operation(request_id, signature, result)
	if operation in ["space_begin_approach", "space_begin_station_dock"]:
		var location_id := String(data.get("location_id", ""))
		var station_dock := operation == "space_begin_station_dock"
		var approach_flight: RefCounted = _travel.get_flight_state(craft_id)
		var station_landing: bool = not station_dock and location_id == "polisa" and approach_flight != null and approach_flight.get_snapshot().get("coordinate_frame") == "local"
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
		var transit: Dictionary = _surface_orbit_intents.get(craft_id, {})
		if not station_dock and not station_landing and transit.get("status") in ["starting", "flying"] and not _surface_orbit_auto_disabled.has(craft_id):
			if transit.has("pending_warp"): return _reject("warp_pending", "Vorgemerkten Warp zuerst abschließen oder abbrechen")
			if transit.get("direction") != "inbound": return _reject("orbit_direction_conflict", "Während des Ausflugs ist kein Anflug vorgemerkt")
			if transit.get("location_id") != location_id: return _reject("destination_mismatch", "Anflugziel passt nicht zum Orbitdurchflug")
			if data.size() != 2: return _reject("invalid_command", "Anflugauftrag enthält unbekannte Angaben")
			var previous: Dictionary = transit.get("pending_approach", {})
			if not previous.is_empty() and String(previous.request_id) != request_id: return _reject("approach_pending", "Anflug ist bereits vorgemerkt")
			if not previous.is_empty() and String(previous.get("signature", "")) != signature: return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
			transit["pending_approach"] = {"request_id":request_id, "signature":signature}
			return {"ok":true, "pending":true, "message":"Orbitdurchflug läuft; Anflug folgt am Planetentor"}
		var departure := authorize_departure(craft_id, ("station-dock:" + owner_request_id) if station_dock else owner_request_id, station_dock)
		if not departure.get("ok", false):
			return departure
		var result: Dictionary = departure.travel_result
		_remember_space_operation(request_id, signature, result)
		if not station_dock and not station_landing: _simulation.publish_singleplayer_departure_events(self, String(_departure_token_by_craft.get(craft_id, "")))
		if _campaign_mode and not station_dock and not station_landing and not departure.get("replayed", false): observe_campaign_progress()
		if result.get("ok", false) and not bool(result.get("replayed", false)):
			if location_id == "distress_orbit":
				_space_encounter.start_encounter(craft_id, true)
				_encounter_entry_delay = 0.0
				_encounter_entry_feedback.clear()
				_flow.call("_refresh_homebase_screen")
			else:
				_flow.call("_begin_space_approach", craft_id, departure.departure)
		if _campaign_mode and (station_dock or station_landing) and not departure.get("replayed", false): observe_campaign_progress()
		if station_dock or station_landing: _simulation.publish_singleplayer_departure_events(self, String(_departure_token_by_craft.get(craft_id, "")))
		return result
	if operation == "space_land_homebase":
		if _service_pad_blocks_craft(craft_id): return _reject("pad_busy", "Heimatpad ist vorübergehend vom Stationsshuttle belegt")
		if is_instance_valid(_base_personnel) and _base_personnel.has_method("preview_home_craft_arrival"):
			var safe:Dictionary=_base_personnel.preview_home_craft_arrival(Dictionary(_flow.call("_find_homebase_aircraft_definition",craft_id)),_home_pad_for(craft_id))
			if not safe.get("ok",false):return _reject(String(safe.get("reason","home_pad_occupied")),"Landung wartet: Personen oder laufende Wege am Heimatlandeplatz")
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
				if is_instance_valid(_base_personnel) and _base_personnel.has_method("_refresh_home_craft_blockers"):_base_personnel.call("_refresh_home_craft_blockers")
				call_deferred("_publish_space_launch_event", String(landing.receipt_id))
			return landing_result
		var result := _commit("singleplayer_space_travel", "land_homebase", {"craft_id": craft_id}, owner_request_id, {"runtime_authorized": true})
		_remember_space_operation(request_id, signature, result)
		if result.get("ok", false) and not bool(result.get("replayed", false)):
			_space_route_requested = false
			_flow.call("_finish_space_home_landing", craft_id)
			if is_instance_valid(_base_personnel) and _base_personnel.has_method("_refresh_home_craft_blockers"):_base_personnel.call("_refresh_home_craft_blockers")
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
	var hex_checkpoint: Dictionary = {}
	if _simulation.is_hex_ground_runtime_required():
		if not _simulation.has_method("export_hex_checkpoint_state"): return {}
		var exported: Dictionary = _simulation.call("export_hex_checkpoint_state")
		if not exported.get("ok", false): return {}
		hex_checkpoint = exported.state
	var state: Dictionary = _campaign.export_state()
	state["departures_by_craft_id"] = {}
	state["selected_location_id"] = "homebase"
	state["selected_job_id"] = ""
	var resources: Dictionary = {}
	for id in _supply.get("_location_resources"):
		resources[id] = {"version":1,"location_id":id,"sites":_supply.call("get_location_resources",id).export_state()}
	for id in _resource_owners:
		if is_instance_valid(_resource_owners[id]): resources[id] = _resource_owners[id].call("export_state")
	var payload := {"schema_version": 1, "campaign": state, "supply": _supply.export_state(), "onboarding": _onboarding.export_state(), "location_resources":resources,"ship_equipment":_ship_equipment.export_state(),"polisa_recruitment_market":_polisa_market.export_state()}
	if not hex_checkpoint.is_empty(): payload["hex_tactical"] = hex_checkpoint
	else: payload["base_personnel"] = _base_personnel.export_state() if _base_personnel != null else {}
	payload["fallen"] = get_fallen()
	# Nottankdienst: nur mit offenem Auftrag (kann hier nur der Fall sein, wenn alle Schiffe stehen; der Schluessel fehlt sonst wie in
	# alten Staenden und bedeutet "kein Auftrag").
	if _tanker != null and _tanker.has_open_orders(): payload["emergency_tanker"] = _tanker.export_state()
	return payload

## Guthaben des Kampagnenstands (Besitzer: SingleplayerSupplyState), nur lesend.
func get_campaign_credits() -> int:
	return _supply.get_credits() if _supply != null else 0

## Abschnitt K: Rettungsgebuehr der Notrettung, voll gebucht (auch ins Minus und ueber den Kreditrahmen hinaus).
func charge_campaign_rescue_fee(amount: int) -> Dictionary:
	if _supply == null: return _reject("supply_unavailable", "Versorgungsstand ist nicht bereit")
	return _supply.charge_rescue_fee(amount)

## Abschnitt K: Zinsuhr der Schulden. Der Aufrufer (meta_layer_flow, Echtzeit-Takt) deckelt das Delta je Frame; hier laeuft nur die Uhr
## des Besitzers (SingleplayerSupplyState). Gibt die Buchungen zurueck: charges = [{amount, credits}].
func advance_debt_interest(delta: float) -> Dictionary:
	if _supply == null or not _campaign_mode: return {"ok": true, "charges": [], "credits": 0}
	return _supply.advance_debt_clock(delta)

## Dauerauftraege (H3, Fracht): Uebernehmen und Abliefern wie ein Verkauf beim Haendler (gelandetes Schiff, Handelsdienst am Ort);
## Aufgeben braucht keinen Haendler. Nur Kampagne; Zustand, Kisten und Lohn buchen allein die Befehle im Versorgungsstand.
func _request_standing(operation: String, data: Dictionary, request_id: String) -> Dictionary:
	if not _campaign_mode or _supply == null or _supply.get_standing_orders() == null:
		return _reject("standing_unavailable", "Daueraufträge gibt es nur in der Kampagne")
	if operation == "standing_abandon":
		return _commit("singleplayer_supply", operation, data, request_id)
	var craft_id: String = String(data.get("craft_id", ""))
	var context: Dictionary = _service_context(craft_id)
	if context.is_empty():
		return _reject("service_unavailable", "Schiff und Trupp müssen am Serviceort bereit sein")
	context["craft_id"] = craft_id
	if String(context.get("location_id", "")) in ["trade_outpost", "satellite_crash"] and not Array(context.get("services", [])).has("trade"):
		return _reject("local_service_required", "Schiff muss am freigegebenen lokalen Handels- oder Servicepunkt stehen")
	return _commit("singleplayer_supply", operation, data, request_id, context)

## Dauerauftraege (H3): den Besitzer nur in der Kampagne anlegen; Namen aus den vorhandenen Anzeige-Katalogen (nur Darstellung).
func _setup_standing_orders() -> void:
	if not _campaign_mode or _supply == null: return
	if _supply.enable_standing_orders():
		_supply.set_standing_orders_names(load("res://scripts/mission/campaign_display_catalog.gd").LOCATION_NAMES, load("res://scripts/ui/components/personnel_inventory_panel.gd").LABELS)

## Dauerauftraege (H3): der Schluessel steht nur im Kampagnen-Snapshot (Skirmish und alte Staende: kein Schluessel).
func _attach_standing_orders(campaign: Dictionary) -> void:
	if _campaign_mode and _supply != null: campaign["standing_orders"] = _supply.get_standing_orders_snapshot()

## Dauerauftraege (H3): durchgehende Uhr der Sperrzeiten. Der Aufrufer (meta_layer_flow) deckelt das Delta je Frame.
func advance_standing_clock(delta: float) -> void:
	if _supply != null and _campaign_mode: _supply.advance_standing_clock(delta)

## Abschnitt P: Pleite-Pruefung (nur lesend; ausserhalb der Kampagne und ohne Versorgungsstand nie pleite). Antwort: bankrupt, reason (aus der
## reinen Regel campaign_bankruptcy_rules.gd), credits (Guthaben), reachable_credits (Guthaben plus Erloes aus allem, was am Ort verkauft
## werden kann), debt_limit, debt_refused (der Nottankdienst wuerde wegen des Kreditrahmens ablehnen: Vorwarnung).
## 1. Runde mit dem echten Guthaben: kann ein Schiff so weiter, ist man nicht pleite. 2. Runde nur, wenn alle festliegen: mit dem erreichbaren
## Kontostand werden "Folgeetappe bezahlbar", "Tanken bezahlbar" und "der Nottanker wuerde liefern" (die echte Bestellpruefung,
## preview_emergency_tanker mit credits_override) neu bestimmt.
func get_bankruptcy_check() -> Dictionary:
	var result := {"bankrupt": false, "reason": "no_campaign", "credits": 0, "reachable_credits": 0, "debt_limit": 0, "debt_refused": false}
	if _supply == null or not _campaign_mode or _flow == null: return result
	var rules = load("res://scripts/core/campaign_bankruptcy_rules.gd")
	var credits: int = _supply.get_credits()
	var limit: int = _supply.get_debt_limit()
	var craft_ids: Array = []
	for definition: Variant in Array(_flow.get("_homebase_aircraft_definitions")):
		var craft_id := String(Dictionary(definition).get("craft_id", ""))
		if not craft_id.is_empty() and _supply.has_fuel_account(craft_id): craft_ids.append(craft_id)
	for craft_id: String in craft_ids:
		var forced := {"craft_available": true, "at_service_point": false, "fuel_problem": true}
		if String(_supply.preview_emergency_tanker({"craft_id": craft_id}, forced).get("reason", "")) == "debt_limit_reached":
			result["debt_refused"] = true
			break
	var ordered: Dictionary = {}
	for order: Dictionary in _supply.get_open_tanker_orders().values(): ordered[String(order.get("craft_id", ""))] = true
	var states: Array = []
	for craft_id: String in craft_ids:
		var status: Dictionary = get_fuel_status(craft_id)
		if status.is_empty(): continue
		status["tanker_order_open"] = ordered.has(craft_id)
		states.append(status)
	# LC2g: Nur eine wirklich leere Flotte ist "kein Schiff mehr" (Pleite mit cause no_craft); Schiffe ohne Treibstoffzustand zaehlen nicht als leer.
	var fleet_empty: bool = Array(_flow.get("_homebase_aircraft_definitions")).is_empty()
	var verdict: Dictionary = rules.is_bankrupt(credits, limit, states) if (not states.is_empty() or fleet_empty) else {"bankrupt": false, "reason": "no_craft"}
	var reachable := credits
	if bool(verdict.get("bankrupt", false)):
		reachable += _bankruptcy_sellable_proceeds(craft_ids)
		states.clear()
		for craft_id: String in craft_ids:
			var status: Dictionary = get_fuel_status(craft_id, reachable)
			if status.is_empty(): continue
			var tanker_context: Dictionary = _tanker_context(craft_id)
			tanker_context["credits_override"] = reachable
			status["tanker_order_open"] = ordered.has(craft_id)
			var offer: Dictionary = _supply.preview_emergency_tanker({"craft_id": craft_id}, tanker_context)
			status["tanker_available"] = bool(offer.get("ok", false))
			status["tanker_refused"] = String(offer.get("reason", "")) == "debt_limit_reached" # Grund fuer den Satz auf dem Bildschirm
			states.append(status)
		if not states.is_empty() or fleet_empty:
			verdict = rules.is_bankrupt(reachable, limit, states)
	result.merge(verdict, true)
	result["credits"] = credits
	result["reachable_credits"] = reachable
	result["debt_limit"] = limit
	return result

## Erloes aus allem, was die Schiffe an ihrem Ort ueber den vorhandenen Verkaufsweg (_sell: Schiffslager und Frachtaufzug beim Haendler)
## verkaufen koennten. Ausruestung hat heute keinen Verkaufsweg. Ein gemeinsamer Frachtaufzug zaehlt einmal.
func _bankruptcy_sellable_proceeds(craft_ids: Array) -> int:
	var total := 0
	var seen: Dictionary = {}
	for craft_id: String in craft_ids:
		var context: Dictionary = _service_context(craft_id)
		if context.is_empty(): continue
		var location := String(context.get("location_id", ""))
		var containers: Array = []
		for container: String in ["craft:" + craft_id, String(context.get("cargo_lift_container_id", ""))]:
			if container.is_empty() or seen.has(location + "|" + container): continue
			seen[location + "|" + container] = true
			containers.append(container)
		total += _supply.get_sellable_proceeds(location, containers)
	return total

## Gefallenenliste der Kampagne (Besitzer: dieser Adapter). Eintrag: unit_id, display_name, job_id, location_id.
## Seit dem Respawn zusaetzlich optional: reason ("respawn_limit"), respawns_used, respawn_limit (ganze Zahlen >= 0);
## alte Eintraege ohne diese Felder bleiben gueltig und unveraendert.
func record_fallen(entry: Dictionary) -> Dictionary:
	var clean: Dictionary = _clean_fallen_entry(entry)
	if clean.is_empty(): return {"ok": false, "reason": "invalid_fallen_entry"}
	for known: Dictionary in _fallen:
		if known.unit_id == clean.unit_id: return {"ok": true, "unchanged": true}
	_fallen.append(clean)
	return {"ok": true}

func get_fallen() -> Array:
	return _fallen.duplicate(true)

## Prueft nur, ob record_fallen den Eintrag annehmen wuerde (ohne ihn aufzunehmen).
func validate_fallen_entry(entry: Dictionary) -> Dictionary:
	if _clean_fallen_entry(entry).is_empty(): return {"ok": false, "reason": "invalid_fallen_entry"}
	return {"ok": true}

## Lesende Auskunft: Diese Person setzt die Kampagne voraus (Fortschritts-Rekruten, Schiffspilot, Anwerber des Marktes).
## Sie stirbt nicht; sie gilt als schwer verwundet gerettet.
func is_person_protected_from_death(unit_id: String) -> bool:
	if unit_id in ["campaign_outpost_recruit", "campaign_rescue_pilot"]: return true
	if is_instance_valid(_flow):
		var pilots: Variant = _flow.get("_assigned_aircraft_pilot_by_craft")
		if typeof(pilots) == TYPE_DICTIONARY and Dictionary(pilots).values().has(unit_id): return true
	return _polisa_market != null and String(_polisa_market.snapshot().get("recruiter_id", "")) == unit_id

## M4b: Startausstattung mit Magazinen (Basislager + volle Faecher), einmal je Stand; true = jetzt gewaehrt (Kampagne, neu oder alt).
func grant_ammo_start_if_missing() -> bool:
	if not (_campaign_mode or _skirmish_mode): return false
	var ids: Array = []
	for unit in Array(_flow.get("_all_team_units")): ids.append(String(Dictionary(unit).get("unit_id", "")))
	return bool(_supply.grant_ammo_start_if_missing(ids))

## Handel H1: Szenario, das beim Anflug von `location_id` geladen wird: das des gewaehlten Auftrags; ohne Auftrag in der Kampagne an einem Ort
## mit abgeschlossenem Story-Auftrag das friedliche Besuchsszenario (open_outposts.json), sonst das Ortsszenario.
func _destination_scenario_id(selected: Dictionary, location_id: String, selected_job: Dictionary) -> String:
	if selected_job.has("scenario_id"): return String(selected_job.scenario_id)
	if _campaign_mode and _campaign != null:
		var visit: String = String(_campaign.open_visit_scenario_id(location_id))
		if not visit.is_empty(): return visit
	return String(Dictionary(selected.locations[location_id]).scenario_file_path).get_file().get_basename()

## Handel H2: Ankaufspreise der Station Polisa fuer die Stationsanzeige: die Preise der Warenboerse (Benit) ueber den Handelsdaten (Erz, Bergungsgut).
func _polisa_buy_orders(supply: Dictionary) -> Dictionary:
	var orders: Dictionary = Dictionary(Dictionary(supply.get("commodity_buy_orders", {})).get("polisa", {})).duplicate()
	var market: Dictionary = Dictionary(Dictionary(supply.get("market", {})).get("polisa", {}))
	for item: Variant in market:
		if Dictionary(market[item]).has("buy_price"): orders[item] = int(market[item].buy_price)
	return orders

## Handel H2 (D4): Heimlandung eines Spielerschiffs -> Marktbestaende der Benit-Warenboerse wieder voll (Kampagne und Skirmish). Liefert die Zahl nachgefuellter Stuecke.
func replenish_market() -> int:
	if _supply == null: return 0
	return int(_supply.replenish_market_stock())

## M6b (B1): KEIN automatisches Auffuellen mehr (weder beim Abflug noch bei der Heimkehr): Magazine kommen von Hand per Drag and Drop
## ins Fach. Beim bestaetigten Abflug von der Heimatbasis nur der Hinweis, wie viele Faecher der Mitfliegenden (an Bord plus zugeteilter
## Pilot) leer sind: {"empty": n, "short_message": "Munition knapp: n Fächer leer." oder ""}. Es wird nichts bewegt.
## Aufgerufen von launch_to_moon_orbit (der einzigen verbindlichen Abflugstelle von der Heimatbasis), nie beim Oeffnen eines Dialogs.
func departure_ammo_notice(craft_id: String, crew_ids: Array = []) -> Dictionary:
	if not (_campaign_mode or _skirmish_mode) or _flow == null or _supply == null: return {"empty": 0, "short_message": ""}
	var ids: Array = crew_ids.duplicate() if not crew_ids.is_empty() else Array(_flow.call("_aboard_unit_ids_of_craft", craft_id)).duplicate()
	var pilot := String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get(craft_id, ""))
	if not pilot.is_empty() and not ids.has(pilot): ids.append(pilot)
	var empty := int(_supply.count_empty_compartments(ids))
	var text := "" if empty <= 0 else "Munition knapp: %d %s leer." % [empty, "Fach" if empty == 1 else "Fächer"]
	return {"empty": empty, "short_message": text}

## Rucksack und Ausruestung einer gefallenen Person verwerfen (Auftragsfracht siehe SingleplayerSupplyState.discard_person_equipment).
func discard_person_equipment(unit_id: String) -> Dictionary:
	if _supply == null: return _reject("supply_unavailable", "Versorgungsstand ist nicht bereit")
	var result: Dictionary = _supply.discard_person_equipment(unit_id)
	if bool(result.get("ok", false)) and _simulation != null:
		_simulation.get_personnel_loadout_state().remove_unit(unit_id)
	return result

## Respawn (R4c): Die EINE Stelle fuer die Ausruestung einer abgeholten Person; hier aendert Bjoern sie spaeter.
## Heute gleich wie bei einer frisch Angeworbenen derselben Rolle (Angebotsprofil, polisa_recruit_offers): leerer Rucksack,
## armor "suit", weapon_1 "pistol", weapon_2 "medictool" nur bei Rolle medic, sonst "none". Ausdruecklich gesetzt (nicht "falls keiner da ist"):
## was die Person vor dem Tod trug oder als Standard aus den Profilfeldern bekaeme, zaehlt nicht.
func grant_pickup_starting_equipment(unit_id: String) -> Dictionary:
	if _supply == null or _simulation == null or not is_instance_valid(_flow): return _reject("supply_unavailable", "Versorgungsstand ist nicht bereit")
	var role := ""
	var known := false
	for profile: Variant in Array(_flow.get("_all_team_units")):
		if profile is Dictionary and String((profile as Dictionary).get("unit_id", "")) == unit_id:
			role = String((profile as Dictionary).get("roster_role_category", ""))
			known = true
			break
	if not known: return _reject("unknown_unit", "Person ist nicht im Kader")
	var cleared: Dictionary = discard_person_equipment(unit_id)
	if not bool(cleared.get("ok", false)): return cleared
	_supply.configure_inventory([unit_id], [], true)
	var loadout := {"armor": "suit", "weapon_1": "pistol", "weapon_2": "medictool" if role == "medic" else "none"}
	_simulation.request_personnel_loadout_command("set_loadout", {"unit_id": unit_id, "loadout": loadout})
	# Der Besitzer meldet nichts zurueck: im Loadout-Stand nachlesen, ob die Grundausstattung wirklich steht.
	var stored: Dictionary = Dictionary(Dictionary(_simulation.get_personnel_loadout_state().call("get_snapshot")).get(unit_id, {}))
	for slot: String in loadout:
		if String(stored.get(slot, "")) != String(loadout[slot]): return _reject("loadout_not_set", "Grundausstattung konnte nicht gesetzt werden")
	return {"ok": true, "unit_id": unit_id, "loadout": loadout}

## Ersetzt die Liste durch die des Standes (leer, wenn der Stand kein Feld "fallen" hat).
func restore_fallen_from_checkpoint(checkpoint: Dictionary) -> void:
	_fallen = []
	var saved: Variant = checkpoint.get("fallen", [])
	if typeof(saved) != TYPE_ARRAY: return
	for entry in saved:
		if typeof(entry) == TYPE_DICTIONARY: record_fallen(entry)

static func _clean_fallen_entry(entry: Dictionary) -> Dictionary:
	if typeof(entry.get("unit_id")) != TYPE_STRING or String(entry.unit_id).is_empty(): return {}
	var clean := {"unit_id": String(entry.unit_id)}
	for key in ["display_name", "job_id", "location_id"]:
		var value: Variant = entry.get(key, "")
		if typeof(value) != TYPE_STRING: return {}
		clean[key] = String(value)
	# Respawn: optionale Felder eines endgueltigen Todes. Fehlen sie, bleibt der Eintrag wie er war (alte Staende);
	# hat ein Feld den falschen Typ, entfaellt nur dieses Feld, nicht der ganze Eintrag.
	if typeof(entry.get("reason")) == TYPE_STRING and not String(entry.reason).is_empty():
		clean["reason"] = String(entry.reason)
	for key in ["respawns_used", "respawn_limit"]:
		var number: Variant = entry.get(key)
		if typeof(number) == TYPE_INT and int(number) >= 0:
			clean[key] = int(number)
		elif typeof(number) == TYPE_FLOAT and is_finite(float(number)) and float(number) >= 0.0 and float(number) == floorf(float(number)):
			clean[key] = int(number)
	return clean

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

func _inventory_context(unit_id: String, craft_id: String) -> Dictionary:
	var field:=_field_inventory_context(unit_id,craft_id)
	if not field.is_empty(): return field
	# Besatzung an Bord eines Schiffs, das an der Heimatbasis gelandet steht (nicht unterwegs, nicht im Start-/Landeablauf, nicht im Einsatz):
	# fuer das Inventar-Fenster erreichbar wie eine Person an der Basis, ohne Aussteigen.
	var aboard := _aboard_status_craft(unit_id)
	if not aboard.is_empty():
		if not _craft_grounded_at_home(aboard): return {}
		var aboard_access: Array = ["base:homebase","unit:"+unit_id+":backpack"]
		if craft_id==aboard and not _service_context(craft_id).is_empty(): aboard_access.append("craft:"+craft_id)
		return {"accessible_containers":aboard_access,"unit_id":unit_id}
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

## Rucksackplaetze im Skirmish der Voreinstellungen: wie vor M6b (12); das Munitionsfach nach Ruestung kommt dazu.
## Kampagne und Punkte-Skirmish (mit Wirtschaft) behalten ihre Regel (-1 = 0 Plaetze).
func _skirmish_bag_capacity() -> int:
	if _skirmish_mode and _skirmish_economy == null: return int(load("res://scripts/mission/inventory_transfer_contract.gd").BACKPACK_CAPACITY)
	return -1

## Schiff, auf dem die Person laut Personalstand an Bord ist ("" wenn sie nicht an Bord ist).
func _aboard_status_craft(unit_id: String) -> String:
	if _base_personnel==null: return ""
	for actor in Array(_base_personnel.get_snapshot().get("units",[])):
		if String(actor.get("unit_id",""))==unit_id:
			return String(actor.get("craft_id","")) if String(actor.get("status",""))=="aboard" else ""
	return ""

func get_world_checkpoint_guard() -> Dictionary:
	if not bool(_cargo_transfer.get_snapshot().get("checkpoint_safe",true)):return _reject("cargo_transfer_active","Speichern wartet auf den Frachttransfer oder seinen Abbruch")
	if _supply != null and _supply.has_pending_recruitments(): return _reject("recruitment_pending", "Speichern wartet auf den Abschluss der Anwerbung")
	# T2: Ein offener Tankerauftrag liegt als Beleg im Versorgungsstand, sein Zustand nur hier. Der Einsatz-Speicherweg
	# (campaign_active_mission_capture) kennt diesen Dienstzustand noch nicht und wuerde einen nicht ladbaren Stand schreiben.
	if _tanker != null and _tanker.has_open_orders(): return _reject("emergency_tanker_open", "Speichern wartet auf den Tanker (Lieferung läuft)")
	if _polisa_shuttle_dispatcher != null and String(_polisa_shuttle_dispatcher.get_snapshot().get("phase", "")) not in ["idle", "complete"]:
		return _reject("shuttle_pending", "Speichern wartet auf die Vorbereitung des Shuttletransports")
	if _polisa_shuttle != null and not bool(_service_shuttle_snapshot().get("checkpoint_safe", false)):
		return _reject("shuttle_active", "Speichern wartet auf den Abschluss des Shuttletransports")
	if not _travel.all_grounded(): return _reject("world_active","Speichern gesperrt: mindestens ein Schiff ist noch unterwegs oder an einem anderen Ort")
	if _simulation != null and _simulation.is_hex_ground_runtime_required():
		if not _simulation.has_method("get_hex_checkpoint_guard"): return _reject("hex_checkpoint_api_unavailable", "Hex-Speicherowner nicht verfügbar")
		return _simulation.call("get_hex_checkpoint_guard")
	return {"ok":true}

func _field_inventory_context(unit_id: String,craft_id: String) -> Dictionary:
	if String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id,""))!="mission": return {}
	var mission: Node=_flow.call("get_mission_for_craft",craft_id)
	if mission==null: return {}
	var controller: Node=mission.get_node("TacticalController")
	if not Dictionary(controller.get("_deployed_unit_ids")).has(unit_id): return {}
	var unit: Node=controller.call("_find_friendly_unit_by_id",unit_id)
	if unit==null or (unit.has_method("get_vital_state") and unit.get_vital_state()!="fit"): return {}
	var station_local := false
	if String(_service_context(craft_id).get("location_id", "")) == "polisa":
		var visits: Dictionary = mission.get_meta("singleplayer_visit_identities", {})
		var visit: Dictionary = visits.get(craft_id, {})
		var station_simulation: Node = mission.get_node_or_null("SimulationRoot")
		var registry: Node = mission.get_node_or_null("UnitRegistry")
		station_local = Array(visit.get("unit_ids", [])).has(unit_id) and registry != null and registry.get_unit(unit_id) == unit and station_simulation != null and not Dictionary(station_simulation.get_hex_unit_state(unit_id)).is_empty()
	var card: Dictionary=controller.call("_find_mission_dropship_card_entry",craft_id)
	var team:=String(controller.call("_get_deployed_unit_fireteam_id",unit_id))
	if not station_local and not Array(card.get("queued_fireteam_ids",[])).has(team) and not Array(card.get("boarded_fireteam_ids",[])).has(team) and not Array(card.get("embarked_unit_ids",[])).has(unit_id):
		# Once disembarked, the original card retains its assigned fireteams.
		var members: Array=Array(_flow.call("_find_mission_drop_card_in_planning_state",craft_id).get("embarked_unit_ids",[]))
		if not members.has(unit_id): return {}
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
	if _space_encounter.get("_combat_owner") != null:
		var pending: Dictionary = _space_encounter.peek_completed_result()
		if pending.is_empty(): return
		var bound_craft := String(pending.craft_id)
		var token := String(_departure_token_by_craft.get(bound_craft, ""))
		var returned: Dictionary = _simulation.commit_campaign_space_return(self, bound_craft, "encounter-return:" + token)
		if not returned.get("ok", false): return
		var bound_result: Dictionary = _space_encounter.get_completed_result()
		if bound_result.is_empty(): return
		record_mission_result(bound_result,{"craft_id":bound_craft,"job_id":"buccaneer_rescue","scenario_id":"buccaneer_rescue"})
		if String(bound_result.result) == "victory":
			_request_campaign_action("campaign_recruit",{"craft_id":bound_craft,"kind":"pilot"},_request_id("rescue-recruit",{}))
		_flow.call("_refresh_homebase_screen")
		return
	# Ohne Kampfbesitzer (alter Zweig) gilt dieselbe Regel wie mit ihm (Fix-Runde 1, W2b): Das Ergebnis wird gebucht (es haengt nie am
	# Treibstoff), das Schiff bleibt aber im Anflug, bis der Rueckweg bezahlt ist. Das Ergebnis wird erst als zugestellt markiert
	# (get_completed_result), wenn der Rueckweg gebucht ist; bis dahin wiederholt der Takt den Versuch (record_mission_result ist idempotent).
	var result: Dictionary = _space_encounter.peek_completed_result()
	if result.is_empty(): return
	var craft_id := String(result.craft_id)
	record_mission_result(result,{"craft_id":craft_id,"job_id":"buccaneer_rescue","scenario_id":"buccaneer_rescue"})
	var outward_token := String(_departure_token_by_craft.get(craft_id,""))
	# Der Schiffsort bleibt der Orbit; Sprung und Landung buchen ihre Anteile selbst (Regel 8 / Auftrag 21.11.).
	var exit_booked: Dictionary = _commit("singleplayer_supply","consume_leg_fuel",{"craft_id":craft_id,"origin_location_id":"distress_orbit","destination_location_id":"homebase","leg":"surface_exit"},"return:"+outward_token+":fuel",{"departure_authorized":true})
	# Ein Schiff ohne Treibstoffkonto (zum Beispiel der Stationsshuttle) unterliegt der Regel nicht (unknown_craft).
	if not bool(exit_booked.get("ok", false)) and String(exit_booked.get("reason", "")) != "unknown_craft": return
	_space_encounter.get_completed_result()
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

## Fehlgeschlagene Chip-Aufnahmen, je Abflug einmal protokolliert (die Aufnahme wird bei jeder Beobachtung wiederholt).
var _chip_pickup_warned:Dictionary={}

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
		var picked:Dictionary=_commit("singleplayer_supply","campaign_cargo",{"container_id":container,"item_id":String(spec[3]),"amount":1},"chip-pickup:"+token+":"+String(spec[0]),{"campaign_authorized":true})
		var warn_key:String=token+":"+String(spec[0])
		if not bool(picked.get("ok",false)) and not _chip_pickup_warned.has(warn_key):
			_chip_pickup_warned[warn_key]=true
			push_warning("Chip-Aufnahme fehlgeschlagen (%s, %s): %s"%[String(spec[3]),container,String(picked.get("reason","?"))])

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
	if operation in ["campaign_build_room", "campaign_place_room_bed", "campaign_set_room_door"]:
		if not _has_live_base_owner() or not _base_personnel.has_method("validate_modular_base") or not _base_personnel.has_method("sync_modular_base"):
			return _reject("base_unavailable", "Raumbau an der Heimatbasis ist nicht verfügbar")
		var validator := Callable(_base_personnel, "validate_modular_base")
		var context := {"at_home": true, "campaign_authorized": true, "modular_room_validator": validator, "modular_bed_validator": validator, "modular_door_validator": validator}
		var result := _commit("singleplayer_supply", operation, payload, request_id, context)
		if bool(result.get("ok", false)):
			_base_personnel.call("sync_modular_base", Dictionary(_supply.get_supply_snapshot().get("modular_base", {})))
			_base_personnel.state_changed.emit()
			_flow.call("_refresh_homebase_screen")
		return result
	if operation == "campaign_build_housing":
		if not _has_live_base_owner(): return _reject("base_unavailable", "Heimatbasis nicht verfügbar")
		var housing_context := {"at_home":true,"campaign_authorized":true,"campaign_housing_builder":Callable(_base_personnel, "build_campaign_housing")}
		var housing_offer := _housing_offer()
		if bool(housing_offer.get("container", false)):
			housing_context["campaign_housing_container"] = true
			housing_context["campaign_housing_limit"] = int(housing_offer.get("sites", 0))
		var result := _commit("singleplayer_supply", operation, {}, request_id, housing_context)
		if bool(result.get("ok", false)):
			_base_personnel.state_changed.emit()
			_flow.call("_refresh_homebase_screen")
		return result
	if operation == "campaign_build_bed":
		if not _has_live_base_owner(): return _reject("base_unavailable", "Heimatbasis nicht verfügbar")
		var result := _commit("singleplayer_supply", operation, {}, request_id, {"at_home":true,"campaign_authorized":true,"campaign_bed_builder":Callable(_base_personnel, "build_campaign_bed")})
		if bool(result.get("ok", false)):
			_base_personnel.state_changed.emit()
			_flow.call("_refresh_homebase_screen")
		return result
	if operation == "campaign_upload":
		if not _has_live_base_owner(): return _reject("upload_requires_home","Lokales Basisterminal nicht verfügbar")
		var job_id := String(payload.get("job_id",""))
		if job_id.is_empty():
			for id in snapshot.jobs:
				if not _local_upload_container(String(id), snapshot.jobs[id]).is_empty():
					job_id = String(id)
					break
		var job: Dictionary = snapshot.jobs.get(job_id,{})
		var upload_status := String(job.get("status",""))
		if upload_status != "pending_upload" and not (upload_status == "active" and bool(job.get("home_upload",false))): return _reject("no_chip","Kein geborgener Chip zum Hochladen")
		craft_id = String(job.get("craft_id",craft_id))
		var item_id := "satellite_chip" if job_id == "satellite_recovery" else "outpost_chip"
		var container:String=_find_local_campaign_chip_container(item_id)
		if container.is_empty():return _reject("missing_cargo","Geborgener Datenträger fehlt bei der Person, im Schiff oder im Basislager")
		var cargo := _commit("singleplayer_supply","campaign_cargo",{"container_id":container,"item_id":item_id,"amount":-1},"campaign-cargo:upload:"+job_id,{"campaign_authorized":true})
		if not bool(cargo.get("ok",false)): return cargo
		var result := _commit("singleplayer_campaign","upload_job",{"job_id":job_id},"upload:"+job_id,{"at_home":true,"chip_at_home":true})
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
		if not _job_craft_accepts(job_craft, craft_id): return _reject("recruit_craft_required", "Ein Schiff der Flotte auswählen" if _lost_craft_ids().has(job_craft) else "Das Schiff des zugehörigen Auftrags auswählen")
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
		var registered: Dictionary = _flow.call("register_campaign_recruit",profile,definition,"" if pilot else craft_id)
		if not bool(registered.get("ok",false)): return registered
		if _base_personnel != null and _base_personnel.has_method("mark_recruit_remote"):
			var boarded: Dictionary = _base_personnel.call("mark_recruit_remote",String(profile.unit_id),String(definition.craft_id) if pilot else craft_id)
			if not boarded.get("ok",false): return boarded
		var result := _commit("singleplayer_campaign","claim_recruit",{"kind":"pilot" if pilot else "outpost"},"recruit:"+key,{"runtime_authorized":true,"outpost_cleared":outpost_cleared})
		if pilot: _flow.get("_aircraft_location_by_craft")[String(definition.craft_id)] = "waiting_pad"
		sync_crafts()
		observe_campaign_progress()
		return result
	if operation == "campaign_load_crate":
		if bool(snapshot.progress.crate_loaded): return {"ok":true,"changed":false}
		if not _job_complete("outpost_recovery"): return _reject("crate_not_ready","Kiste zuerst am Außenposten bergen")
		var job_craft := String(Dictionary(snapshot.jobs.get("outpost_recovery", {})).get("craft_id", ""))
		if not _job_craft_accepts(job_craft, craft_id) or String(_service_context(craft_id).get("location_id", "")) not in ["homebase", "trade_outpost"]: return _reject("crate_not_here","Ein Schiff am gesicherten Außenposten oder nach Rückkehr auswählen" if _lost_craft_ids().has(job_craft) else "Auftragsschiff am gesicherten Außenposten oder nach Rückkehr auswählen")
		# LC2k K1: Nach einem Verlust der Kiste ist das Laden eine eigene Buchung (Kennung mit Verlustzaehler), sonst meldet die Versorgung request_id_conflict.
		var load_id := "load:outpost_recovery" + ("" if int(_campaign.call("crate_loss_count")) == 0 else ":" + str(int(_campaign.call("crate_loss_count"))))
		var cargo := _campaign_cargo(craft_id,"c_benit_crate",1,load_id)
		if not bool(cargo.get("ok",false)): return cargo
		return _commit("singleplayer_campaign","load_crate",{},load_id,{"runtime_authorized":true})
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
		if not pad.is_empty() and not _pad_by_craft.values().has(pad) and String(_service_pad_reservation.get("pad_id", "")) != pad: return pad
	return ""

func _reserve_service_home_pad(craft_id: String) -> Dictionary:
	if craft_id.strip_edges().is_empty(): return _reject("pad_busy", "Kein freier Shuttlelandeplatz")
	if not _service_pad_reservation.is_empty():
		if String(_service_pad_reservation.get("craft_id", "")) == craft_id and _validate_service_home_pad(craft_id, String(_service_pad_reservation.get("pad_id", ""))):
			return {"ok":true,"craft_id":craft_id,"pad_id":String(_service_pad_reservation.pad_id),"replayed":true}
		return _reject("pad_busy", "Kein freier Shuttlelandeplatz")
	var pad := _polisa_free_home_pad()
	if pad.is_empty() and is_instance_valid(_flow) and _travel != null:
		for candidate: String in _built_home_pad_ids():
			if _service_can_borrow_pad(candidate): pad = candidate; break
	if pad.is_empty(): return _reject("pad_busy", "Shuttle wartet auf einen freien Landeplatz")
	if is_instance_valid(_base_personnel) and _base_personnel.has_method("preview_home_craft_arrival"):
		var checked:Dictionary=_base_personnel.preview_home_craft_arrival({"craft_id":craft_id,"model_id":"cutlass","craft_type":"dropship"},pad)
		if not checked.get("ok",false):return _reject(String(checked.get("reason","home_pad_occupied")),"Shuttle wartet: Personen oder laufende Wege am Heimatlandeplatz")
	_service_pad_reservation = {"craft_id":craft_id,"pad_id":pad}
	if is_instance_valid(_base_personnel) and _base_personnel.has_method("_refresh_home_craft_blockers"):_base_personnel.call("_refresh_home_craft_blockers")
	return {"ok":true,"craft_id":craft_id,"pad_id":pad}

func _validate_service_home_pad(craft_id: String, pad_id: String) -> bool:
	if _service_pad_reservation != {"craft_id":craft_id,"pad_id":pad_id}: return false
	if _pad_by_craft.values().has(pad_id) and not _service_can_borrow_pad(pad_id): return false
	if _base_personnel != null and not _built_home_pad_ids().has(pad_id): return false
	return not pad_id.is_empty()

func _service_can_borrow_pad(pad_id: String) -> bool:
	if not is_instance_valid(_flow) or _travel == null: return false
	for id: String in _pad_by_craft:
		if String(_pad_by_craft[id]) != pad_id: continue
		var location := String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(id, ""))
		if location not in ["mission", "starmap"] or not Dictionary(_flow.call("_find_pending_mission_craft_transfer", id)).is_empty(): return false
		if _craft_grounded_at_home(id): return false
	return true

func _service_pad_blocks_craft(craft_id: String) -> bool:
	var pad := _home_pad_for(craft_id)
	return not pad.is_empty() and pad == String(_service_pad_reservation.get("pad_id", ""))

func _release_service_home_pad(craft_id: String, pad_id: String) -> void:
	if _service_pad_reservation == {"craft_id":craft_id,"pad_id":pad_id}:
		_service_pad_reservation.clear()
		if is_instance_valid(_base_personnel) and _base_personnel.has_method("_refresh_home_craft_blockers"):_base_personnel.call("_refresh_home_craft_blockers")


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


func get_polisa_globe_controller() -> Node:
	if not is_instance_valid(_flow): return null
	var registry = _flow.get("_location_registry")
	var mission: Node = registry.get_location("polisa") if registry != null else null
	return mission.get_node_or_null("TacticalController") if is_instance_valid(mission) else null

func _restore_polisa_residents() -> void:
	if not _campaign_mode or _base_personnel == null or not _base_personnel.has_station_recruits(): return
	if _polisa_shuttle != null and String(_polisa_shuttle.get_snapshot().get("phase", "")) != "idle": return
	var now := Time.get_ticks_msec()
	if now < _polisa_resident_retry_msec: return
	_polisa_resident_retry_msec = now + 1000
	var controller: Node = get_polisa_globe_controller()
	if controller == null or not controller.has_method("get_polisa_resident_spawn_grid") or not controller.has_method("register_polisa_resident"): return
	var mission: Node = controller.get_parent()
	var setup: Node = mission.get_node_or_null("MissionSetup") if is_instance_valid(mission) else null
	var registry: Node = mission.get_node_or_null("UnitRegistry") if is_instance_valid(mission) else null
	if setup == null or registry == null or not setup.has_method("request_polisa_recruit_admission"): return
	var visits: Dictionary = mission.get_meta("singleplayer_visit_identities", {})
	var visit_ids := {}
	for visit: Dictionary in visits.values():
		for id in Array(visit.get("unit_ids", [])): visit_ids[String(id)] = true
	var states: Dictionary = _base_personnel.get("_states")
	var residents: Dictionary = mission.get_meta("singleplayer_station_personnel", {})
	var station_simulation: Node = mission.get_node_or_null("SimulationRoot")
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		var id := String(profile.get("unit_id", ""))
		# R4c: Neben der Kennung polisa_recruit_ erscheint auch, wer auf Abholung wartet (awaiting_pickup); wer noch ausfaellt (respawning) nie, auch nicht mit Kennung.
		if not _base_personnel.polisa_visit_eligible(id, profile) or String(Dictionary(states.get(id, {})).get("status", "")) != "station" or visit_ids.has(id): continue
		if residents.has(id) and is_instance_valid(registry.get_unit(id)) and station_simulation != null and not Dictionary(station_simulation.get_hex_unit_state(id)).is_empty(): continue
		var pending := false
		for item: Dictionary in _polisa_recruit_pending.values():
			if String(item.get("unit_id", "")) == id: pending = true; break
		if pending: continue
		if registry.get_unit(id) == null:
			var spawn: Dictionary = controller.call("get_polisa_resident_spawn_grid")
			if not spawn.get("ok", false) or typeof(spawn.get("spawn_grid")) != TYPE_VECTOR2I: return
			var result: Dictionary = setup.call("request_polisa_recruit_admission", profile, spawn.spawn_grid)
			if not result.get("ok", false): return
		if registry.get_unit(id) != null:
			controller.call("register_polisa_resident", id)
		return

func _polisa_recruit_context(craft_id: String, expected_recruiter: String) -> Dictionary:
	if not _campaign_mode or String(_service_context(craft_id).get("location_id", "")) != "polisa": return _reject("station_service_required", "Schiff zuerst auf Polisa bereitstellen")
	var controller: Node = get_polisa_globe_controller()
	if controller == null or not controller.has_method("get_polisa_globe_recruiter"): return _reject("globe_unavailable", "Globus ist nicht erreichbar")
	var interaction: Dictionary = controller.call("get_polisa_globe_recruiter")
	if not interaction.get("ok", false): return _reject(String(interaction.get("reason", "globe_unavailable")), "Eine eigene Person muss am Globus stehen")
	if not expected_recruiter.is_empty() and String(interaction.get("unit_id", "")) != expected_recruiter: return _reject("recruiter_changed", "Person am Globus erneut auswählen")
	interaction["controller"] = controller
	return interaction

func _open_polisa_recruitment(payload: Dictionary) -> Dictionary:
	var craft_id := String(payload.get("craft_id", ""))
	var context := _polisa_recruit_context(craft_id, String(payload.get("unit_id", "")))
	if not context.get("ok", false): return context
	var recruiter: Dictionary = {}
	var occupied := {}
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		occupied[String(profile.get("portrait_id", ""))] = true
		if String(profile.get("unit_id", "")) == String(context.unit_id): recruiter = profile
	if recruiter.is_empty(): return _reject("recruiter_unavailable", "Person ist nicht im eigenen Personal")
	var progress: Dictionary = _campaign.export_state().get("completion_receipts", {})
	return _polisa_market.open("campaign:" + str(progress.size()), recruiter, occupied)

func get_polisa_recruitment_snapshot() -> Dictionary:
	var market: Dictionary = _polisa_market.snapshot()
	var records: Dictionary = _supply.get_recruitment_records() if _supply != null else {}
	var offers: Array = []
	for offer: Dictionary in market.get("offers", []):
		if not records.has(String(offer.get("id", ""))): offers.append(offer.duplicate(true))
	var capacity: Dictionary = _base_personnel.get_recruitment_bed_capacity() if _base_personnel != null else {"ok":false}
	return {"offers":offers,"recruiter_id":String(market.get("recruiter_id", "")),"credits":int(_supply.get_supply_snapshot().get("credits", 0)),"beds":int(capacity.get("beds", 0)),"roster_size":int(capacity.get("roster_size", 0)),"capacity_available":bool(capacity.get("ok", false)),"pending":not _polisa_recruit_pending.is_empty()}

func _request_polisa_recruitment(payload: Dictionary) -> Dictionary:
	var craft_id := String(payload.get("craft_id", ""))
	var recruiter_id := String(payload.get("recruiter_id", ""))
	var context := _polisa_recruit_context(craft_id, recruiter_id)
	if not context.get("ok", false): return context
	if recruiter_id.is_empty() or recruiter_id != String(_polisa_market.snapshot().get("recruiter_id", "")): return _reject("market_changed", "Angebot am Globus erneut öffnen")
	var offer_id := String(payload.get("offer_id", ""))
	var quote: Dictionary = _polisa_market.quote(offer_id)
	if not quote.get("ok", false): return quote
	var mission: Node = context.controller.get_parent()
	var setup: Node = mission.get_node_or_null("MissionSetup") if is_instance_valid(mission) else null
	if setup == null or not setup.has_method("request_polisa_recruit_admission"): return _reject("recruit_unavailable", "Personenaufnahme derzeit nicht verfügbar")
	var reservation_id := "polisa-hire:" + offer_id
	var supply_context := {"location_id":"polisa","station_service_verified":true,"recruit_quote":Callable(_polisa_market,"quote")}
	var reservation := _commit("singleplayer_supply", "station_recruit_reserve", {"offer_id":offer_id}, reservation_id, supply_context)
	if not reservation.get("ok", false): return reservation
	if reservation.get("replayed", false): return _reject("recruit_already_hired", "Diese Person wurde bereits angefragt")
	_polisa_recruit_pending[reservation_id] = {"unit_id":String(quote.unit_id),"profile":quote.profile.duplicate(true),"mission":weakref(mission),"craft_id":craft_id,"spawn_grid":context.spawn_grid}
	var admission: Dictionary = setup.call("request_polisa_recruit_admission", quote.profile, context.spawn_grid)
	if not admission.get("ok", false):
		_polisa_recruit_pending[reservation_id]["admission_failed"] = true
		var cancel_context := {"recruit_cancel_verify":Callable(self,"_verify_polisa_recruit_absent").bind(weakref(mission))}
		var cancelled := _commit("singleplayer_supply", "station_recruit_cancel", {"reservation_id":reservation_id}, "cancel:"+reservation_id, cancel_context)
		if not cancelled.get("ok", false): return _reject("admission_pending", "Aufnahme wird geprüft; Credits bleiben reserviert")
		_polisa_recruit_pending.erase(reservation_id)
		return admission
	_advance_polisa_recruitment()
	return {"ok":true,"unit_id":String(quote.unit_id),"message":"Person aufgenommen" if not _polisa_recruit_pending.has(reservation_id) else "Personenaufnahme läuft"}

func _verify_polisa_recruit_absent(unit_id: String, _reservation_id: String, mission_ref: WeakRef) -> Dictionary:
	var mission: Node = mission_ref.get_ref() if mission_ref != null else null
	if not is_instance_valid(mission): return {"ok":false}
	var registry: Node = mission.get_node_or_null("UnitRegistry")
	var simulation: Node = mission.get_node_or_null("SimulationRoot")
	return {"ok":registry != null and simulation != null and registry.get_unit(unit_id) == null and not simulation._known_units_by_id.has(unit_id)}

func _verify_polisa_recruit_admitted(unit_id: String, reservation_id: String) -> Dictionary:
	if not _polisa_recruit_pending.has(reservation_id): return {"ok":false}
	var pending: Dictionary = _polisa_recruit_pending[reservation_id]
	var mission: Node = pending.mission.get_ref()
	var setup: Node = mission.get_node_or_null("MissionSetup") if is_instance_valid(mission) else null
	if setup == null or String(pending.unit_id) != unit_id: return {"ok":false}
	return setup.call("get_polisa_recruit_admission", unit_id)

func _verify_polisa_recruit_abandoned(unit_id: String, reservation_id: String) -> Dictionary:
	if not _polisa_recruit_pending.has(reservation_id) or not is_instance_valid(_flow): return {"ok":false}
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		if String(profile.get("unit_id", "")) == unit_id: return {"ok":false}
	if _base_personnel != null and Dictionary(_base_personnel.get("_states")).has(unit_id): return {"ok":false}
	var locations = _flow.get("_location_registry")
	if locations == null: return {"ok":false}
	for location_id: String in locations.location_ids():
		var location: Node = locations.get_location(location_id)
		if not is_instance_valid(location): continue
		var registry: Node = location.get_node_or_null("UnitRegistry")
		var simulation: Node = location.get_node_or_null("SimulationRoot")
		if registry == null or simulation == null: return {"ok":false}
		if registry.get_unit(unit_id) != null or simulation._known_units_by_id.has(unit_id): return {"ok":false}
	return {"ok":true}

func has_pending_polisa_recruit(craft_id: String) -> bool:
	if craft_id.is_empty(): return false
	for pending: Dictionary in _polisa_recruit_pending.values():
		if String(pending.get("craft_id", "")) == craft_id: return true
	return false

func _advance_polisa_recruitment() -> void:
	for reservation_id: String in _polisa_recruit_pending.keys():
		var pending: Dictionary = _polisa_recruit_pending[reservation_id]
		var mission: Node = pending.mission.get_ref()
		if not is_instance_valid(mission):
			var replacement: Node = _flow.call("get_mission_for_craft", String(pending.craft_id)) if is_instance_valid(_flow) and _flow.has_method("get_mission_for_craft") else null
			if is_instance_valid(replacement) and String(replacement.get_meta("location_id", "")) == "polisa":
				var replacement_setup: Node = replacement.get_node_or_null("MissionSetup")
				if replacement_setup != null and replacement_setup.has_method("request_polisa_recruit_admission") and typeof(pending.get("spawn_grid")) == TYPE_VECTOR2I:
					var recovered: Dictionary = replacement_setup.call("request_polisa_recruit_admission", pending.profile, pending.spawn_grid)
					if recovered.get("ok", false):
						pending.mission = weakref(replacement)
						continue
			var cancellation := _commit("singleplayer_supply", "station_recruit_cancel", {"reservation_id":reservation_id}, "cancel:"+reservation_id, {"recruit_cancel_verify":Callable(self,"_verify_polisa_recruit_abandoned")})
			if cancellation.get("ok", false): _polisa_recruit_pending.erase(reservation_id)
			continue
		if pending.get("admission_failed", false):
			var cancellation := _commit("singleplayer_supply", "station_recruit_cancel", {"reservation_id":reservation_id}, "cancel:"+reservation_id, {"recruit_cancel_verify":Callable(self,"_verify_polisa_recruit_absent").bind(weakref(mission))})
			if cancellation.get("ok", false): _polisa_recruit_pending.erase(reservation_id)
			continue
		var setup: Node = mission.get_node_or_null("MissionSetup")
		var controller: Node = mission.get_node_or_null("TacticalController")
		if setup == null or controller == null or not controller.has_method("register_polisa_recruit_person"): continue
		if not Dictionary(setup.call("get_polisa_recruit_admission", String(pending.unit_id))).get("ok", false):
			var status: Dictionary = setup.call("get_runtime_selection_status")
			var now := Time.get_ticks_msec()
			if status.get("historical_committed", false) and setup.has_method("retry_polisa_recruit_admission") and now >= int(pending.get("retry_after_msec", 0)):
				pending.retry_after_msec = now + 1000
				setup.call("retry_polisa_recruit_admission", String(pending.unit_id))
			continue
		var registered: Dictionary = controller.call("register_polisa_recruit_person", String(pending.unit_id), String(pending.craft_id))
		if not registered.get("ok", false): continue
		var profile: Dictionary = pending.profile.duplicate(true)
		profile["recruit_location"] = "polisa"
		var roster: Dictionary = _flow.call("register_campaign_recruit", profile)
		if not roster.get("ok", false): continue
		_supply.configure_inventory([String(pending.unit_id)], [], true)
		var already_configured: bool = _simulation.get_personnel_loadout_state().has_unit(String(pending.unit_id))
		_simulation.request_personnel_loadout_command("configure_roster", {"roster":[profile]})
		if not already_configured:
			_simulation.request_personnel_loadout_command("set_loadout", {"unit_id":String(pending.unit_id),"loadout":{"armor":profile.get("armor", "suit"),"weapon_1":profile.get("weapon_1", "pistol"),"weapon_2":profile.get("weapon_2", "none")}})
		var result := _commit("singleplayer_supply", "station_recruit_finalize", {"reservation_id":reservation_id}, "final:"+reservation_id, {"recruit_verify":Callable(self,"_verify_polisa_recruit_admitted")})
		if result.get("ok", false):
			_polisa_recruit_pending.erase(reservation_id)
			# M4b/M4c (K2): neue Person kommt mit vollem Fach (sofern die Startausstattung des Standes gewaehrt ist) - genau einmal und erst
			# nach abgeschlossener Anwerbung, nicht bei jedem Wiederholungsdurchlauf der Schleife (sonst Magazine aus dem Nichts).
			_supply.provision_new_person(String(pending.unit_id))

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
	var station_residents: Array = []
	var mission: Node = _flow.call("get_mission_for_craft", craft_id) if not craft_id.is_empty() else null
	var registry: Node = mission.get_node_or_null("UnitRegistry") if mission != null else null
	var residents: Dictionary = mission.get_meta("singleplayer_station_personnel", {}) if mission != null else {}
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		var id := String(profile.get("unit_id", ""))
		if registry == null or registry.call("get_unit", id) == null: continue
		var access := _inventory_context(id, craft_id)
		people.append({"unit_id":id,"name":String(profile.get("display_name", id)),"equipment_allowed":bool(access.get("equipment_allowed", false)),"loadout":_simulation.get_personnel_loadout_state().get_loadout(id)})
		if residents.has(id): station_residents.append({"unit_id":id,"name":String(profile.get("display_name", id))})
	var local_capability: Dictionary = _flow.call("get_polisa_local_ship_purchase_capability") if _flow.has_method("get_polisa_local_ship_purchase_capability") else {"available":false,"message":"Lokale Ausgabe noch nicht verfügbar"}
	var crew_handoff: Dictionary = _flow.call("get_polisa_crew_handoff_snapshot", craft_id) if not craft_id.is_empty() and _flow.has_method("get_polisa_crew_handoff_snapshot") else {}
	return {"service_dispatch":_polisa_shuttle_dispatcher.get_snapshot() if _polisa_shuttle_dispatcher != null else {},"crew_handoff":crew_handoff,"local_pickup_available":bool(local_capability.get("available", false)),"local_pickup_reason":String(local_capability.get("message", "")),"equipment":_ship_equipment.get_snapshot(craft_id) if _ship_equipment != null and not craft_id.is_empty() else {},"local_crafts":local_crafts,"selection_required":craft_id.is_empty() and not local_crafts.is_empty(),"craft_id":craft_id,"craft_name":String(Dictionary(_flow.call("_find_homebase_aircraft_definition",craft_id)).get("display_name",craft_id)),"service_ready":String(Dictionary(contexts.get(craft_id, {})).get("location_id", ""))=="polisa",
		"fuel":float(Dictionary(supply.get("fuel_by_craft_id", {})).get(craft_id, 0.0)),"fuel_registered":Dictionary(supply.get("fuel_by_craft_id", {})).has(craft_id),
		"fuel_capacity":float(supply.get("fuel_capacity", 0.0)),"fuel_price_per_unit":float(supply.get("fuel_price_per_unit", 0.0)),
		"credits":int(supply.get("credits", 0)),"offers":offers,"stock":supply.get("stock_by_offer_id", {}),"inventory":supply.get("inventory", {}),
		"people":people,"station_residents":station_residents,"blueprints":supply.get("blueprints", []),"require_blueprints":_campaign_mode,"revision":int(supply.get("revision", 0)),
		"cargo_transfer":_cargo_transfer.get_snapshot(),"free_home_pad":_polisa_free_home_pad(),"home_pad_count":int(supply.get("station_home_pads", 2)),"campaign_mode":_campaign_mode,"buy_orders":_polisa_buy_orders(supply)}


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

## Was die Heimatbasis fuer den Unterkunftskauf anbietet: Wohncontainer (Hex-Boden) oder alte Unterkunft.
func _housing_offer() -> Dictionary:
	if not is_instance_valid(_base_personnel) or not _base_personnel.has_method("get_housing_offer"): return {"container":false}
	return Dictionary(_base_personnel.call("get_housing_offer"))

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

func _local_upload_container(job_id: String, job: Dictionary) -> String:
	# Playtest L01: the upload follows the chip that is physically at home. The job may still
	# be "active" when the mission result never reported its last step.
	var status := String(job.get("status", ""))
	if status != "pending_upload" and not (status == "active" and bool(job.get("home_upload", false))):
		return ""
	return _find_local_campaign_chip_container("satellite_chip" if job_id == "satellite_recovery" else "outpost_chip")


func _upload_blocker_text(container: String) -> String:
	if container.begins_with("craft:"):
		return "Der Datenträger liegt im Lager eines Schiffs, das nicht an der Heimatbasis steht. Erst hier landen."
	if container.begins_with("unit:"):
		return "Der Datenträger ist bei einer Person, die nicht an der Heimatbasis ist. Erst mit ihr heimkehren."
	return ""


func _home_services_snapshot() -> Dictionary:
	var local_jobs: Array[String] = []
	var blocker := ""
	for id: String in _campaign.get_campaign_snapshot().get("jobs", {}):
		var job: Dictionary = _campaign.get_campaign_snapshot().jobs[id]
		if not _local_upload_container(id, job).is_empty(): local_jobs.append(id)
		elif blocker.is_empty() and bool(job.get("home_upload", false)) and String(job.get("status", "")) in ["pending_upload", "active"]:
			blocker = _upload_blocker_text(_find_campaign_chip_container("satellite_chip" if id == "satellite_recovery" else "outpost_chip", String(job.get("craft_id", ""))))
	return {"workshop_available":_home_workshop_available(), "upload_job_ids":local_jobs, "upload_blocker":blocker, "all_at_home":_all_at_home(), "lost_craft_ids":_lost_craft_ids()}


## LC2h H5: Kennungen der im Einsatz verlorenen Schiffe (Verlustbelege des Ablaufs).
func _lost_craft_ids() -> Array:
	var ids: Array = []
	for record: Variant in Array(_flow.get("_lost_craft_records")):
		ids.append(String(Dictionary(record).get("craft_id", "")))
	return ids


## LC2h H5: Erfuellt craft_id die Schiffsbindung eines Story-Schritts (Kiste laden, Anwerben)? Das Auftragsschiff immer; ist es verloren
## (steht im Verlustbeleg), jedes Schiff der Flotte. Ob es am richtigen Ort steht, prueft der Aufrufer wie bisher.
func _job_craft_accepts(job_craft: String, craft_id: String) -> bool:
	if craft_id.is_empty(): return false
	if craft_id == job_craft: return true
	if job_craft.is_empty() or not _lost_craft_ids().has(job_craft): return false
	return not Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty()

func _has_verified_pilot_rescue(craft_id: String) -> bool:
	# get_completed_result consumes its delivery flag before automatic recruitment.
	# The authoritative read-only state retains the exact victorious craft.
	if _space_encounter == null: return false
	var encounter: Dictionary = _space_encounter.get_snapshot()
	# LC2i I5: Ging das Schiff der Rettung inzwischen verloren, gilt die Rettung fuer jedes Schiff der Flotte (wie Kiste laden), sonst stuende die Kampagne.
	return String(encounter.get("phase", "")) == "victory" and _job_craft_accepts(String(encounter.get("craft_id", "")), craft_id)


func show_polisa_cargo_delivery(craft_id: String, request_id: String) -> bool:
	# Read the real Supply receipt and live visit; the visual does not move goods.
	if _supply == null or not is_instance_valid(_flow) or request_id.is_empty(): return false
	var receipt: Dictionary = _supply.get_purchase_receipt(request_id)
	if receipt.is_empty() or receipt.get("container_id") != "craft:" + craft_id or String(_service_context(craft_id).get("location_id", "")) != "polisa": return false
	var mission: Node = _flow.call("get_mission_for_craft", craft_id)
	var controller: Node = mission.get_node_or_null("TacticalController") if is_instance_valid(mission) else null
	if controller == null or not controller.has_method("_campaign_landed_craft_position") or not controller.has_method("_get_primary_3d_view"): return false
	var position: Variant = controller.call("_campaign_landed_craft_position", craft_id)
	var view: Variant = controller.call("_get_primary_3d_view")
	if typeof(position) != TYPE_VECTOR2 or not position.is_finite() or not is_instance_valid(view) or not view.has_method("play_polisa_cargo_lift"): return false
	return bool(view.call("play_polisa_cargo_lift", craft_id, position))

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

func get_ground_repair_context(craft_id:String)->Dictionary:
	return _service_context(craft_id).duplicate(true)

func _ground_service_craft_owned(craft_id:String)->bool:
	if _flow==null or _simulation==null: return false
	var definition:Dictionary=_flow.call("_find_homebase_aircraft_definition",craft_id)
	if definition.is_empty():return false
	var local:=String(_simulation.call("get_peer_team",multiplayer.get_unique_id()))
	if local.is_empty():local=String(_simulation.get("_multiplayer_local_team"))
	if local.is_empty() and not multiplayer.has_multiplayer_peer():local="team_alpha"
	if local.is_empty():return false
	return String(definition.get("owner_team_id",definition.get("team_id","team_alpha")))==local

func _project_ground_cargo_lifts()->void:
	if _supply==null or _flow==null:return
	var job:Dictionary=_cargo_transfer.get_snapshot()
	var signature:=str([_supply.get_revision(),job])
	if signature==_ground_cargo_visual_signature and Time.get_ticks_msec()-_ground_cargo_visual_refresh_msec<1000:return
	_ground_cargo_visual_signature=signature
	_ground_cargo_visual_refresh_msec=Time.get_ticks_msec()
	var inventory:Dictionary=_cargo_inventory()
	for definition:Dictionary in Array(_flow.get("_homebase_aircraft_definitions")):
		var craft:=String(definition.get("craft_id",""))
		var mission:Node=_flow.call("get_mission_for_craft",craft)
		if mission==null:continue
		var controller:Node=mission.get_node_or_null("TacticalController")
		var view:Node=controller.call("_get_primary_3d_view") if controller!=null else null
		if view==null or not view.has_method("set_ground_cargo_lift_state"):continue
		var local_job:Dictionary=job if "station:trade_outpost:lift" in [String(job.get("source","")),String(job.get("target",""))] else {"phase":"idle"}
		view.call("set_ground_cargo_lift_state","trade_lift",Dictionary(inventory.get("station:trade_outpost:lift",{})).get("items",{}),local_job)
