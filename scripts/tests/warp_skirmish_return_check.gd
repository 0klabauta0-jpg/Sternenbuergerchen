extends SceneTree
## Actual Adapter -> Root -> SkirmishEconomy -> Adapter transaction callback.
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ECONOMY = preload("res://scripts/core/skirmish_economy_state.gd")
class SetupFlow extends Node:
	var _homebase_aircraft_definitions: Array = []
	var _aircraft_location_by_craft := {}
	var _assigned_aircraft_pilot_by_craft := {}
	var _loaded_aircraft_cargo_by_craft := {}
	var _all_team_units: Array = []
	var _last_mission_result := {}
	var _selected_mission_id := ""
	var removals := 0
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {}
	func _has_active_homebase_pilot_transfer(_id: String) -> bool: return false
	func _has_active_homebase_cargo_load(_id: String) -> bool: return false
	func remove_skirmish_craft(id: String) -> void:
		removals += 1
		_homebase_aircraft_definitions = _homebase_aircraft_definitions.filter(func(craft: Dictionary): return craft.craft_id != id)
		_aircraft_location_by_craft.erase(id)
	func _refresh_homebase_screen() -> void: pass
class SetupBase extends Node:
	func get_snapshot() -> Dictionary: return {"units":[],"layout":{"landing_pads":[]}}
	func _refresh_capacity() -> void: pass
var checks := 0
var failures := 0
var sequence := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS: " if ok else "FAIL: ", label)
func supply_command(adapter, op: String, payload: Dictionary, extra: Dictionary = {}) -> Dictionary:
	sequence += 1
	var context := {"location_id":"polisa","craft_busy":false,"station_service_verified":true,"ship_component_model_id":"cutlass","craft_id":String(payload.get("craft_id", ""))}
	context.merge(extra,true)
	return adapter._simulation.request_singleplayer_command({"contract_category":"singleplayer_supply","operation":op,"payload":payload,"request_id":"return-fixture:"+str(sequence)}, context)
func fingerprint(adapter, flow: Node) -> String:
	return JSON.stringify([adapter._supply.export_state(),adapter._ship_equipment.export_state(),adapter._travel.get_snapshot(),adapter._skirmish_economy.get_snapshot(),flow._homebase_aircraft_definitions,flow._aircraft_location_by_craft,flow.removals],"",true)
func run() -> void:
	var economy = ECONOMY.new()
	economy.configure(1000)
	# Only initial ship placement is a setup stub; purchase/refund wallet is real.
	var purchase: Dictionary = economy.apply_command({"operation":"ship","payload":{"item_id":"cutlass"},"request_id":"setup-ship"},func(_op: String, payload: Dictionary): return {"ok":true,"craft_id":payload.craft_id})
	check(purchase.ok and economy.get_snapshot().remaining == 660,"Actual Economy records340-point Cutlass purchase/refund entitlement")
	var id := String(purchase.craft_id)
	var definition := {"craft_id":id,"craft_type":"dropship","model_id":"cutlass"}
	var flow := SetupFlow.new()
	flow._homebase_aircraft_definitions = [definition]
	flow._aircraft_location_by_craft[id] = "homebase"
	var adapter = ADAPTER.new()
	adapter._flow = flow
	adapter._base_personnel = SetupBase.new()
	adapter._skirmish_economy = economy
	adapter._supply = SUPPLY.new()
	adapter._supply.configure([definition])
	adapter._supply.configure_inventory([], [id], true)
	adapter._ship_equipment = EQUIPMENT.new()
	adapter._ship_equipment.configure([definition])
	adapter._travel = FLEET.new()
	adapter._travel.configure()
	adapter._travel.register_craft(id)
	adapter._simulation = ROOT.new()
	adapter._simulation.configure_singleplayer_owners(null,adapter._supply,null,adapter._travel)
	adapter._simulation.configure_ship_equipment(adapter._ship_equipment)
	adapter._simulation.configure_skirmish_economy(economy,adapter._apply_skirmish_transaction)
	check(supply_command(adapter,"buy",{"craft_id":id,"offer_id":"polisa_warp_hemera","quantity":1}).ok,"Real Supply buys paid Hemera for refundable craft")
	check(supply_command(adapter,"station_install_ship_component",{"craft_id":id,"slot_id":"quantum_drive","item_id":"warp_hemera","source_container_id":"craft:"+id,"expected_equipment_revision":0}).ok,"Real Equipment installs Hemera and returns Odyssey")
	var access := {"accessible_containers":["craft:"+id,"base:homebase"]}
	check(supply_command(adapter,"inventory_transfer",{"source_container_id":"craft:"+id,"destination_container_id":"base:homebase","item_id":"warp_odyssey","amount":1},access).ok,"Existing transfer unloads Odyssey; craft cargo is truly empty")
	var before := fingerprint(adapter,flow)
	var remaining: int = economy.get_snapshot().remaining
	var rejected: Dictionary = adapter.request_operation("skirmish_return_ship",{"craft_id":id,"request_id":"return-real"})
	check(not rejected.ok and rejected.get("reason") == "equipment_retirement_pending" and rejected.get("message") == "Nach einem Antriebsumbau ist die Schiffsrückgabe derzeit nicht verfügbar","Actual return_ship path refuses installed paid upgrade before refund")
	check(fingerprint(adapter,flow) == before and economy.get_snapshot().remaining == remaining,"Rejected return leaves Flow/Supply/Travel/Equipment/Economy byte-equivalent")
	if not rejected.ok:
		check(supply_command(adapter,"inventory_transfer",{"source_container_id":"base:homebase","destination_container_id":"craft:"+id,"item_id":"warp_odyssey","amount":1},access).ok,"Standard drive can be moved back for reinstallation")
		check(supply_command(adapter,"station_install_ship_component",{"craft_id":id,"slot_id":"quantum_drive","item_id":"warp_odyssey","source_container_id":"craft:"+id,"expected_equipment_revision":1}).ok,"Standard drive restored through real Root/Supply/Equipment")
		check(supply_command(adapter,"inventory_transfer",{"source_container_id":"craft:"+id,"destination_container_id":"base:homebase","item_id":"warp_hemera","amount":1},access).ok,"Paid upgrade safely unloaded before craft return")
		before = fingerprint(adapter,flow)
		var still_blocked: Dictionary = adapter.request_operation("skirmish_return_ship",{"craft_id":id,"request_id":"return-reverted"})
		check(not still_blocked.ok and still_blocked.get("reason") == "equipment_retirement_pending" and fingerprint(adapter,flow) == before,"Restored standard drive retains real install history; return stays explicitly blocked")
		var plain_purchase: Dictionary = economy.apply_command({"operation":"ship","payload":{"item_id":"cutlass"},"request_id":"setup-plain-ship"},func(_op: String, payload: Dictionary): return {"ok":true,"craft_id":payload.craft_id})
		var plain_id := String(plain_purchase.craft_id)
		var plain_definition := {"craft_id":plain_id,"craft_type":"dropship","model_id":"cutlass"}
		flow._homebase_aircraft_definitions.append(plain_definition)
		flow._aircraft_location_by_craft[plain_id] = "homebase"
		adapter.sync_crafts()
		var refund_before: int = economy.get_snapshot().remaining
		var accepted: Dictionary = adapter.request_operation("skirmish_return_ship",{"craft_id":plain_id,"request_id":"return-plain"})
		check(plain_purchase.ok and accepted.ok and economy.get_snapshot().remaining == refund_before+340 and flow.removals == 1,"Existing callback returns genuinely unmodified empty ship and refunds once")
		check(adapter._ship_equipment.get_snapshot(plain_id).is_empty() and not adapter._supply.get_supply_snapshot().inventory.has("craft:"+plain_id) and not adapter._travel.get_snapshot().routes.has(plain_id),"Unmodified ship is removed from Equipment, Supply and Travel without ghost")
		check(adapter._ship_equipment.get_snapshot(id).slots.quantum_drive == "warp_odyssey" and adapter._supply.get_supply_snapshot().inventory["base:homebase"].items.warp_hemera == 1,"Historical craft and paid component remain present and accessible")
		check(adapter.request_operation("skirmish_return_ship",{"craft_id":plain_id,"request_id":"return-plain"}).get("replayed",false) and economy.get_snapshot().remaining == refund_before+340 and flow.removals == 1,"Existing unmodified refund receipt remains idempotent")
	adapter._simulation.free()
	adapter._base_personnel.free()
	adapter.free()
	flow.free()
	print("WARP_SKIRMISH_RETURN checks=",checks," failures=",failures)
	quit(int(failures > 0))
