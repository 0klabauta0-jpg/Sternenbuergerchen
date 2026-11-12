extends SceneTree
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")

func _initialize() -> void:
	var definitions := [{"craft_id":"ship", "model_id":"cutlass", "craft_type":"dropship"}]
	var equipment = EQUIPMENT.new(); assert(equipment.configure(definitions).ok)
	var supply = SUPPLY.new(); assert(supply.configure(definitions).ok); supply.configure_inventory([], ["ship"], false)
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	var root_owner = ROOT.new(); root_owner.configure_singleplayer_owners(null, supply, null, fleet); root_owner.configure_ship_equipment(equipment)
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new(); adapter._simulation = root_owner; adapter._supply = supply
	assert(adapter.request_operation("buy", {"craft_id":"ship", "offer_id":"polisa_component_power_s2_plus", "quantity":1}).reason == "component_not_available")
	assert(adapter.request_operation("station_install_ship_component", {"craft_id":"ship", "slot_id":"power", "item_id":"power_s2_plus"}).reason == "component_not_available")
	var context := {"location_id":"polisa", "craft_id":"ship", "craft_busy":false, "station_service_verified":true, "ship_component_model_id":"cutlass", "runtime_authorized":true}
	var buy := {"contract_category":"singleplayer_supply", "operation":"buy", "payload":{"craft_id":"ship", "offer_id":"polisa_component_power_s2_plus", "quantity":1}, "request_id":"buy-power"}
	var bought: Dictionary = root_owner.request_singleplayer_command(buy, context)
	assert(bought.ok and supply.get_supply_snapshot().inventory["craft:ship"].items.power_s2_plus == 1)
	var args := {"craft_id":"ship", "slot_id":"power", "item_id":"power_s2_plus", "source_container_id":"craft:ship", "expected_equipment_revision":0}
	var install := {"contract_category":"singleplayer_supply", "operation":"station_install_ship_component", "payload":args, "request_id":"fit-power"}
	var blocked_context := context.duplicate(true); blocked_context.craft_busy = true
	var before_block := JSON.stringify([supply.export_state(), equipment.export_state()], "", true)
	assert(not root_owner.request_singleplayer_command(install, blocked_context).ok and JSON.stringify([supply.export_state(), equipment.export_state()], "", true) == before_block)
	var wrong: Dictionary = install.duplicate(true); wrong.request_id = "wrong-slot"; wrong.payload.slot_id = "shield"
	assert(not root_owner.request_singleplayer_command(wrong, context).ok and JSON.stringify([supply.export_state(), equipment.export_state()], "", true) == before_block)
	var old_mass: float = equipment.get_space_flight_profile("ship").mass
	var installed: Dictionary = root_owner.request_singleplayer_command(install, context)
	assert(installed.ok and equipment.get_snapshot("ship").space_loadout.power == "power_s2_plus")
	assert(equipment.get_space_flight_profile("ship").mass > old_mass and supply.get_supply_snapshot().inventory["craft:ship"].items.power_s2 == 1)
	var before := JSON.stringify([supply.export_state(), equipment.export_state()], "", true)
	assert(root_owner.request_singleplayer_command(install, context).replayed)
	assert(JSON.stringify([supply.export_state(), equipment.export_state()], "", true) == before)
	var restored_supply = SUPPLY.new(); assert(restored_supply.restore_state(JSON.parse_string(JSON.stringify(supply.export_state()))).ok)
	var restored_equipment = EQUIPMENT.new()
	var loaded: Dictionary = restored_equipment.restore_state(JSON.parse_string(JSON.stringify(equipment.export_state())), definitions, restored_supply.export_state().requests, restored_supply.export_state().inventory)
	if not loaded.ok: print("RESTORE_DIAGNOSTIC: ", loaded)
	assert(loaded.ok and restored_equipment.get_snapshot("ship").space_loadout.power == "power_s2_plus")
	var forged: Dictionary = JSON.parse_string(JSON.stringify(equipment.export_state()))
	forged.space_loadouts.ship.power = "power_s2"
	assert(not restored_equipment.restore_state(forged, definitions, restored_supply.export_state().requests, restored_supply.export_state().inventory).ok)
	var roster: Array = load("res://scripts/meta/campaign_start_configuration.gd").new()._initial_roster()
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new(); campaign.configure({}, {}, true)
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new(); onboarding.configure()
	var payload := {"schema_version":1, "roster":roster, "craft":{"definition":definitions[0],"pilot_id":roster[1].unit_id}, "fleet":[{"definition":definitions[0],"pilot_id":roster[1].unit_id,"location":"homebase"}], "campaign":campaign.export_state(), "supply":supply.export_state(), "onboarding":onboarding.export_state(), "ship_equipment":equipment.export_state()}
	var saved: Dictionary = load("res://scripts/meta/campaign_checkpoint_store.gd").validate_payload(JSON.parse_string(JSON.stringify(payload)))
	if not saved.ok: print("CHECKPOINT_DIAGNOSTIC: ", saved)
	assert(saved.ok)
	adapter.free(); root_owner.free()
	print("SPACE_COMPONENT_INSTALL passed: real Root/Supply/Equipment transaction, replay, save and conservation")
	quit(0)
