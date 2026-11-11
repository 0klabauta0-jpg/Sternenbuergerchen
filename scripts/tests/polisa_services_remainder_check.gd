extends SceneTree
const SCREEN = preload("res://scripts/ui/polisa_station_screen.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
class ServiceAdapter extends Node:
	var supply: RefCounted
	var service_ready := true
	var calls := 0
	func get_polisa_snapshot() -> Dictionary:
		var state: Dictionary = supply.get_supply_snapshot()
		return {"craft_id":"test","service_ready":service_ready,"fuel_registered":true,"fuel":state.fuel_by_craft_id.test,"fuel_capacity":state.fuel_capacity,"fuel_price_per_unit":state.fuel_price_per_unit,"credits":state.credits}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		calls += 1
		return supply.apply_command(COMMAND.build_command(operation,payload,"fuel-test-%d" % calls), {"location_id":"polisa" if service_ready else "", "craft_busy":not service_ready})
var failures := 0
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print("POLISA_SERVICE ",label,": ","PASS" if value else "FAIL")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json"))
	definitions.initial_fuel = 95.0
	var supply = SUPPLY.new()
	check(supply.configure(["test"], definitions).ok, "fixture_configured")
	var context := {"location_id":"polisa","craft_busy":false}
	var before: Dictionary = supply.apply_command(COMMAND.build_refuel_command("test",10.0,"old-fixed-ten"),context)
	check(not before.ok and before.reason == "fuel_capacity" and supply.get_supply_snapshot().fuel_by_craft_id.test == 95.0, "old_fixed_ten_rejects_near_full_without_mutation")
	var adapter := ServiceAdapter.new()
	adapter.supply = supply
	root.add_child(adapter)
	var ui := SCREEN.new()
	root.add_child(ui)
	ui.configure(adapter)
	ui.refresh(adapter.get_polisa_snapshot())
	var quote := SCREEN.refuel_quote(adapter.get_polisa_snapshot())
	check(quote.allowed and quote.amount == 5.0 and quote.cost == int(ceil(5.0 * definitions.fuel_price_per_unit)), "near_full_quote_uses_owner_price")
	var credits: int = supply.get_supply_snapshot().credits
	ui.call("_request_refuel")
	var after: Dictionary = supply.get_supply_snapshot()
	check(adapter.calls == 1 and after.fuel_by_craft_id.test == 100.0 and after.credits == credits - int(quote.cost), "real_supply_command_fills_exactly_and_charges_once")
	check(ui.get("_refuel_button").disabled, "full_tank_button_disabled")
	ui.call("_request_refuel")
	check(adapter.calls == 1, "full_tank_dispatch_blocked")
	# A stale ready projection must be re-read before sending a command.
	ui.refresh({"craft_id":"test","service_ready":true,"fuel_registered":true,"fuel":95.0,"fuel_capacity":100.0,"fuel_price_per_unit":definitions.fuel_price_per_unit,"credits":500})
	adapter.service_ready = false
	ui.call("_request_refuel")
	check(adapter.calls == 1 and ui.get("_refuel_button").disabled, "lost_landed_service_blocks_stale_ui_dispatch")
	var denied := adapter.get_polisa_snapshot()
	denied.service_ready = true
	denied.fuel = 90.0
	denied.credits = 0
	check(not SCREEN.refuel_quote(denied).allowed, "insufficient_credits_disabled")
	denied.credits = 500
	denied.fuel_registered = false
	check(not SCREEN.refuel_quote(denied).allowed, "unregistered_craft_disabled")
	ui.set("_snapshot", {"craft_id":"test","inventory":{"craft:test":{"items":{"ore":3}},"craft:other":{"items":{"ore":99}}}})
	check(ui.call("_cargo","ore") == 3, "cargo_quantity_is_selected_craft_only")
	ui.set("_adapter", null)
	ui.call("_request_refuel")
	check(adapter.calls == 1 and ui.get("_refuel_button").disabled, "lost_adapter_dispatch_blocked")
	ui.free()
	adapter.free()
	print("POLISA_SERVICE RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
