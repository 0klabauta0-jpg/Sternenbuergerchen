extends SceneTree
## Small Supply/3D lifetime check; a native station view is still required.
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const LIFT = preload("res://scripts/terrain/polisa_cargo_lift_visual.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var supply = SUPPLY.new()
	assert(supply.configure(["ship"]).ok)
	supply.configure_inventory([], ["ship"], false)
	supply.configure_preset_supply({"credits":3000,"stock":{}})
	var command: Dictionary = COMMAND.build_command("buy", {"craft_id":"ship","offer_id":"polisa_pistol","quantity":1}, "lift-buy")
	var context := {"location_id":"polisa","craft_id":"ship","craft_busy":false,"station_service_verified":true}
	var bought: Dictionary = supply.apply_command(command, context)
	assert(bought.get("ok", false) and bought.get("container_id") == "craft:ship")
	var receipt: Dictionary = supply.get_purchase_receipt("lift-buy")
	assert(receipt.get("item_id") == bought.item_id and receipt.get("container_id") == "craft:ship")
	var before: Dictionary = supply.get_supply_snapshot()
	assert(supply.apply_command(command, context).get("replayed", false) and supply.get_supply_snapshot() == before)
	receipt["container_id"] = "forged"
	assert(supply.get_purchase_receipt("lift-buy").container_id == "craft:ship")
	assert(supply.get_purchase_receipt("unknown").is_empty())
	var lift = LIFT.new(); root.add_child(lift); lift.play_delivery()
	var carrier: Node3D = lift.get("_carrier")
	assert(carrier != null and carrier.position.y < 0.0)
	await create_timer(1.8).timeout
	assert(is_instance_valid(lift) and carrier.position.y > 0.9)
	await create_timer(2.0).timeout
	assert(not is_instance_valid(lift))
	print("POLISA_CARGO_LIFT owner receipt, replay and 3D lifetime passed")
	quit(0)
