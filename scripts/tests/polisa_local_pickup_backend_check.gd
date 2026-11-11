extends SceneTree
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
class Controller extends Node:
	var pilot_ready := false
	func _is_parked_campaign_dropship(_id: String) -> bool: return true
	func get_campaign_pilot_flight_guard(_id: String) -> Dictionary: return {"ok":pilot_ready,"reason":"pilot_not_aboard"}
class SetupFlow extends Node:
	var _homebase_aircraft_definitions: Array = [{"craft_id":"visitor","craft_type":"dropship","model_id":"cutlass"}]
	var _aircraft_location_by_craft := {"visitor":"mission"}
	var _all_team_units: Array = []
	var _selected_mission_id := ""
	var _last_mission_result := {}
	var _pending_mission_craft_transfers: Array = []
	var mission: Node
	var adapter: Node
	var fail_prepare := false
	var fail_commit := false
	var commits := 0
	var finalizes := 0
	var published_after_receipt := false
	var admitted := {}
	var crew_calls: Array = []
	func _find_homebase_aircraft_definition(id: String) -> Dictionary:
		for craft: Dictionary in _homebase_aircraft_definitions:
			if craft.craft_id == id: return craft
		return {}
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {}
	func _build_homebase_aircraft_definition(kind: String, _index: int) -> Dictionary: return {"craft_type":kind,"craft_id":"unused"}
	func _refresh_homebase_screen() -> void: pass
	func get_mission_for_craft(id: String) -> Node: return mission if _aircraft_location_by_craft.get(id) == "mission" else null
	func prepare_polisa_local_ship_purchase(craft: Dictionary, request: String, pad: String) -> Dictionary:
		if fail_prepare: return {"ok":false,"reason":"pad_full"}
		var normalized := craft.duplicate(true)
		normalized.merge({"crew_capacity":8,"seat_capacity":8},true)
		return {"ok":true,"craft_definition":normalized,"request_id":request,"acquisition_pad_id":"polisa_pad_03" if pad.is_empty() else pad,"pad_position":Vector2(1,2),"visit_identity":{"craft_id":craft.craft_id,"location_id":"polisa","job_id":""}}
	func commit_polisa_local_ship_purchase(prepared: Dictionary) -> Dictionary:
		if fail_commit: return {"ok":false,"reason":"pad_changed"}
		commits += 1
		admitted[prepared.craft_definition.craft_id] = prepared.acquisition_pad_id
		return {"ok":true,"acquisition_pad_id":prepared.acquisition_pad_id}
	func board_polisa_craft_crew(target: String) -> Dictionary:
		crew_calls.append(["board",target])
		return {"ok":true}
	func deploy_polisa_craft_crew(source: String) -> Dictionary:
		crew_calls.append(["deploy",source])
		return {"ok":true}
	func handoff_polisa_station_crew(source: String,target: String,units: PackedStringArray,pilot: String,request: String) -> Dictionary:
		crew_calls.append(["handoff",source,target,Array(units),pilot,request])
		return {"ok":true}
	func finalize_polisa_local_ship_purchase(id: String) -> void:
		finalizes += 1
		published_after_receipt = adapter.get_station_ship_purchase(id).get("origin_kind") == "local_station_purchase"
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func fingerprint(adapter, flow) -> String:
	return JSON.stringify([adapter._supply.export_state(),adapter._ship_equipment.export_state(),adapter._travel.get_snapshot(),adapter._pad_by_craft,flow._homebase_aircraft_definitions,flow._aircraft_location_by_craft,flow.admitted,flow.commits],"",true)
func payload() -> Dictionary: return {"craft_id":"visitor","offer_id":"polisa_ship_cutlass","delivery_mode":"local","service_location_id":"polisa","request_id":"local-buy"}
func run() -> void:
	var adapter = ADAPTER.new()
	var flow := SetupFlow.new()
	flow.adapter = adapter
	flow.mission = Node.new()
	flow.mission.set_meta("location_id","polisa")
	var controller := Controller.new()
	controller.name = "TacticalController"
	flow.mission.add_child(controller)
	adapter._flow = flow
	adapter._campaign = ADAPTER.CAMPAIGN.new()
	adapter._campaign.configure()
	adapter._supply = ADAPTER.SUPPLY.new()
	adapter._supply.configure(flow._homebase_aircraft_definitions)
	adapter._supply.configure_inventory([], ["visitor"], false)
	adapter._supply.configure_preset_supply({"credits":3000,"stock":{}})
	adapter._ship_equipment = EQUIPMENT.new()
	adapter._ship_equipment.configure(flow._homebase_aircraft_definitions)
	adapter._travel = ADAPTER.TRAVEL.new()
	adapter._travel.configure()
	var initialize := {"contract_category":"singleplayer_space_travel","operation":"initialize_surface","payload":{"craft_id":"ui","location_id":"polisa"},"request_id":"ui-init"}
	check(not adapter._travel.apply_command(initialize,{}).ok and adapter._travel.get_snapshot().routes.is_empty(),"UI cannot authorize station Surfacebirth")
	initialize.contract_category = "wrong"
	check(not adapter._travel.apply_command(initialize,{"runtime_authorized":true}).ok and adapter._travel.get_snapshot().routes.is_empty(),"Wrong contract cannot bypass Surfaceowner validation")
	check(not adapter._travel.prepare_surface_registration("bad","homebase","bad-init").ok and adapter._travel.get_snapshot().routes.is_empty(),"Unsupported stationary origin leaves index untouched")
	var origin: Dictionary = adapter._travel.prepare_surface_registration("visitor","polisa","visitor-surface")
	check(origin.ok and adapter._travel.get_snapshot().routes.is_empty(),"Prepared Surfaceowner does not publish any flight index")
	check(adapter._travel.commit_surface_registration(origin).ok,"Existing visitor fixture has real Surface/polisa travel state")
	var same_init := {"contract_category":"singleplayer_space_travel","operation":"initialize_surface","payload":{"craft_id":"visitor","location_id":"polisa"},"request_id":"visitor-surface"}
	check(adapter._travel.apply_command(same_init,{"runtime_authorized":true}).get("replayed",false),"Station Surfacebirth has normal replay semantics")
	var conflicting := same_init.duplicate(true)
	conflicting.payload.location_id = "homebase"
	check(not adapter._travel.apply_command(conflicting,{"runtime_authorized":true}).ok,"Conflicting Surfacebirth request cannot replace established identity")
	var staged: Dictionary = adapter._travel.prepare_surface_registration("staged","polisa","staged-init")
	staged.craft_id = "forged"
	check(not adapter._travel.commit_surface_registration(staged).ok and not adapter._travel.get_snapshot().routes.has("forged"),"Tampered unpublished candidate never enters travel index")
	adapter._travel.focus_craft("visitor")
	adapter._pad_by_craft = {"visitor":"homebase_pad_01"}
	adapter._simulation = SIM.new()
	adapter._simulation.configure_singleplayer_owners(adapter._campaign,adapter._supply,null,adapter._travel)
	adapter._simulation.configure_ship_equipment(adapter._ship_equipment)
	# Visitor uses a genuine existing away binding; purchased craft gets no such fake.
	adapter._campaign._departures_by_craft_id.visitor = {"destination_location_id":"polisa","job_id":""}
	var before := fingerprint(adapter,flow)
	adapter._supply._credits = 10
	before = fingerprint(adapter,flow)
	check(not adapter.request_operation("station_buy_ship",payload()).ok and fingerprint(adapter,flow) == before,"Insufficient credits rejects before any local owner mutation")
	adapter._supply._credits = 3000
	adapter._supply._stock_by_offer_id.polisa_ship_cutlass = 0
	before = fingerprint(adapter,flow)
	check(not adapter.request_operation("station_buy_ship",payload()).ok and fingerprint(adapter,flow) == before,"Exhausted stock rejects before any local owner mutation")
	adapter._supply._stock_by_offer_id.polisa_ship_cutlass = 2
	before = fingerprint(adapter,flow)
	var stale_intent := payload()
	stale_intent.service_location_id = "homebase"
	check(not adapter.request_operation("station_buy_ship",stale_intent).ok and fingerprint(adapter,flow) == before,"Stale displayed service location cannot buy at another service")
	flow.fail_prepare = true
	check(not adapter.request_operation("station_buy_ship",payload()).ok and fingerprint(adapter,flow) == before,"Full/unavailable local pad rejects with every owner unchanged")
	flow.fail_prepare = false
	flow.fail_commit = true
	check(not adapter.request_operation("station_buy_ship",payload()).ok and fingerprint(adapter,flow) == before,"Final stale admission rejects before flight/fleet/wallet publication")
	flow.fail_commit = false
	adapter._pad_by_craft.reserved = "homebase_pad_02"
	before = fingerprint(adapter,flow)
	check(not adapter.request_operation("station_buy_ship",payload()).ok and fingerprint(adapter,flow) == before,"No free built return pad rejects local purchase atomically")
	adapter._pad_by_craft.erase("reserved")
	var invalid := payload()
	invalid.requested_station_pad_id = "missing_marker"
	before = fingerprint(adapter,flow)
	check(not adapter.request_operation("station_buy_ship",invalid).ok and fingerprint(adapter,flow) == before,"Invalid acquisition marker rejects before commit")
	var bought: Dictionary = adapter.request_operation("station_buy_ship",payload())
	check(bought.ok,"Actual Adapter/Root/Supply locally purchases Cutlass")
	if not bought.ok:
		print("PURCHASE_DIAGNOSTIC ",bought)
		finish(adapter,flow)
		return
	var id := String(bought.craft_id)
	var purchase: Dictionary = adapter.get_station_ship_purchase(id)
	check(purchase.origin_kind == "local_station_purchase" and purchase.origin_receipt_id == "local-buy" and purchase.acquisition_pad_id == "polisa_pad_03" and purchase.landing_pad_id == "homebase_pad_02", "Versioned purchase separates local pad from reserved home return pad")
	var state: Dictionary = adapter._travel.get_snapshot(id)
	check(state.phase == "surface" and state.location_id == "polisa" and state.craft_id == id and state.focused_craft_id == "visitor", "New craft is truly surface/polisa without changing travel focus")
	check(adapter._supply.get_supply_snapshot().credits == 2150 and adapter._supply.get_supply_snapshot().stock_by_offer_id.polisa_ship_cutlass == 1 and adapter._supply.get_supply_snapshot().inventory.has("craft:"+id) and flow._find_homebase_aircraft_definition(id).crew_capacity == 8, "Real debit, finite stock, cargo and normalized capacity publish once")
	check(flow.commits == 1 and flow.finalizes == 1 and flow.published_after_receipt, "UI finalization occurs only after real Supplyreceipt exists")
	check(not adapter._campaign.get_campaign_snapshot().departures_by_craft_id.has(id) and not adapter._departure_token_by_craft.has(id), "Local birth fabricates neither home outbound nor foreign job binding")
	check(adapter._service_context(id).location_id == "polisa" and not adapter.get_world_checkpoint_guard().ok,"Actual local service works while checkpoint remains away-blocked")
	before = fingerprint(adapter,flow)
	check(adapter.request_operation("station_buy_ship",payload()).get("replayed",false) and fingerprint(adapter,flow) == before and flow.finalizes == 1,"Same purchase replays without duplicate craft/pad/receipt or UI event")
	invalid = payload()
	invalid.delivery_mode = "homebase"
	check(not adapter.request_operation("station_buy_ship",invalid).ok and fingerprint(adapter,flow) == before,"Conflicting delivery mode under same request is rejected")
	check(adapter.request_operation("station_deploy_crew",{"craft_id":"visitor","service_location_id":"polisa"}).ok and flow.crew_calls[0] == ["deploy","visitor"],"Deploy UI command routes exact explicit source through Flow gate")
	check(adapter.request_operation("station_handoff_crew",{"craft_id":id,"source_craft_id":"visitor","target_craft_id":id,"unit_ids":["pilot"],"pilot_id":"pilot","request_id":"crew-route","service_location_id":"polisa"}).ok and flow.crew_calls[1] == ["handoff","visitor",id,["pilot"],"pilot","crew-route"],"Handoff UI command routes explicit source/target/crew/pilot without choosing people")
	check(adapter.request_operation("station_board_crew",{"craft_id":id,"service_location_id":"polisa"}).ok and flow.crew_calls[2] == ["board",id],"Explicit boarding routes selected target to existing Flow boarding gates")
	check(not adapter.request_operation("station_handoff_crew",{"craft_id":id,"source_craft_id":"visitor","target_craft_id":"different","unit_ids":["pilot"],"pilot_id":"pilot"}).ok and flow.crew_calls.size() == 3,"Mismatched target never reaches crew mutation bridge")
	var before_preview := fingerprint(adapter, flow)
	check(not adapter.preview_return(id).ok and fingerprint(adapter, flow) == before_preview, "Unmanned return preview rejects without mutation")
	check(not adapter.authorize_return(id).ok,"Unmanned local craft cannot authorize return")
	controller.pilot_ready = true
	check(adapter.preview_return(id).ok and fingerprint(adapter, flow) == before_preview, "Boarded pilot preview does not debit fuel or mutate visit")
	var fuel_before: float = adapter._supply.get_supply_snapshot().fuel_by_craft_id[id]
	check(adapter.authorize_return(id,"first-return").ok and adapter._supply.get_supply_snapshot().fuel_by_craft_id[id] == fuel_before-10.0,"Real local-origin return uses existing Polisa fuel route")
	check(adapter.authorize_return(id,"second-return").get("replayed",false) and adapter._supply.get_supply_snapshot().fuel_by_craft_id[id] == fuel_before-10.0,"Local purchase return debit is once regardless UI request IDs")
	check(adapter._supply.export_state().requests.has("return:local-purchase:local-buy:fuel"),"Return receipt is anchored to actual local purchase, never a fake outbound")
	var travel_cmd := {"contract_category":"singleplayer_space_travel","operation":"enter_orbit","payload":{"craft_id":id},"request_id":"exit"}
	check(adapter._travel.apply_command(travel_cmd,{"runtime_authorized":true}).ok and adapter._travel.get_snapshot(id).orbit_id == "polisa_orbit", "Station-born craft enters its real Polisa body orbit")
	var trusted := {"runtime_authorized":true}
	adapter._travel.apply_command({"contract_category":"singleplayer_space_travel","operation":"start_quantum","payload":{"craft_id":id,"target_orbit_id":"moon_orbit"},"request_id":"home-jump"},trusted)
	adapter._travel.apply_command({"contract_category":"singleplayer_space_travel","operation":"advance","payload":{"craft_id":id,"delta_seconds":3.0},"request_id":""},trusted)
	check(adapter._travel.apply_command({"contract_category":"singleplayer_space_travel","operation":"land_homebase","payload":{"craft_id":id},"request_id":"land"},trusted).ok,"Existing travel owner supports real surface-exit/warp/home landing sequence")
	check(ADAPTER.SUPPLY.new().restore_state(JSON.parse_string(JSON.stringify(adapter._supply.export_state()))).ok,"Supply JSON restore accepts local-origin acquisition receipt")
	var saved: Dictionary = adapter._supply.export_state()
	for attack: String in ["origin","pad","home-pad","schema","fit-revision"]:
		var forged := saved.duplicate(true)
		match attack:
			"origin": forged.requests["local-buy"].result.origin_receipt_id = "invented-outbound"
			"pad": forged.requests["local-buy"].result.acquisition_pad_id = "homebase_pad_01"
			"home-pad": forged.requests["local-buy"].result.landing_pad_id = "polisa_pad_03"
			"schema": forged.requests["local-buy"].result.receipt_schema_version = 99
			"fit-revision": forged.requests["local-buy"].result.pad_fit_revision = 99
		check(not ADAPTER.SUPPLY.new().restore_state(forged).ok,"Manipulated local receipt rejected: "+attack)
	var home_supply = ADAPTER.SUPPLY.new()
	home_supply.configure(["visitor"])
	home_supply.configure_inventory([], ["visitor"], false)
	home_supply.configure_preset_supply({"credits":3000,"stock":{}})
	var home_result: Dictionary = home_supply.apply_command({"contract_category":"singleplayer_supply","operation":"station_buy_ship","payload":{"offer_id":"polisa_ship_cutlass"},"request_id":"old-home-delivery"},{"location_id":"polisa","craft_busy":false,"station_service_verified":true,"station_ship_fulfillment":func(_offer: Dictionary, req: String): return {"ok":true,"craft_id":"polisa_cutlass_"+req.sha256_text().substr(0,12),"delivery_location_id":"homebase","landing_pad_id":"homebase_pad_02"}})
	check(home_result.ok and not home_result.has("receipt_schema_version") and ADAPTER.SUPPLY.new().restore_state(JSON.parse_string(JSON.stringify(home_supply.export_state()))).ok,"Existing two-argument home fulfillment and old-format receipt remain valid")
	checkpoint_checks(adapter,flow)
	finish(adapter,flow)
func checkpoint_checks(adapter, flow: SetupFlow) -> void:
	var campaign: Dictionary = adapter._campaign.export_state()
	campaign.departures_by_craft_id = {}
	campaign.selected_location_id = "homebase"
	var roster: Array = load("res://scripts/meta/campaign_start_configuration.gd").new()._initial_roster()
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	onboarding.configure()
	var fleet: Array = []
	for craft: Dictionary in flow._homebase_aircraft_definitions: fleet.append({"definition":craft,"pilot_id":"","location":"homebase"})
	var payload := {"schema_version":1,"roster":roster,"craft":{"definition":fleet[0].definition,"pilot_id":""},"fleet":fleet,"campaign":campaign,"supply":adapter._supply.export_state(),"onboarding":onboarding.export_state(),"ship_equipment":adapter._ship_equipment.export_state()}
	var validated: Dictionary = STORE.validate_payload(JSON.parse_string(JSON.stringify(payload)))
	if not validated.ok: print("CHECKPOINT_DIAGNOSTIC ",validated)
	check(validated.ok,"Real home checkpoint validator accepts locally acquired ship after homecoming")
	payload.fleet[1].definition.model_id = "buccaneer"
	check(not STORE.validate_payload(payload).ok,"Checkpoint crosscheck rejects purchase/fleet model manipulation")
func finish(adapter,flow: SetupFlow) -> void:
	adapter._simulation.free()
	adapter.free()
	flow.mission.free()
	flow.free()
	print("POLISA_LOCAL_PICKUP_BACKEND checks=",checks," failures=",failures)
	quit(int(failures > 0))
