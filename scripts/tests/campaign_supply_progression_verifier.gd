extends SceneTree
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
var failures := 0
func _initialize() -> void:
	var supply = SUPPLY.new()
	check(supply.configure([{"craft_id":"dropship_1"}]).get("ok",false),"configure")
	supply.configure_inventory(["campaign_leader"],["dropship_1"])
	supply.configure_start_inventory("campaign")
	var initial: Dictionary = supply.get_supply_snapshot()
	check(not initial.item_quantities.has("rifle") and not initial.item_quantities.has("armor_heavy"),"campaign has no late equipment")
	check(int(initial.item_quantities.get("pistol",0))>=2,"campaign pistols exist")
	var cmd := {"contract_category":"singleplayer_supply","operation":"campaign_cargo","payload":{"container_id":"craft:dropship_1","item_id":"satellite_chip","amount":1},"request_id":"chip1"}
	check(not supply.apply_command(cmd).get("ok",false),"UI cannot grant quest cargo")
	check(supply.apply_command(cmd,{"campaign_authorized":true}).get("ok",false),"trusted actual recovery grants chip")
	check(supply.apply_command(cmd,{"campaign_authorized":true}).get("replayed",false),"repeat recovery idempotent")
	check(int(supply.get_supply_snapshot().inventory["craft:dropship_1"].items.satellite_chip)==1,"one chip")
	cmd.request_id="consume1"; cmd.payload.amount=-1
	check(supply.apply_command(cmd,{"campaign_authorized":true}).get("ok",false),"upload consumes physical cargo")
	cmd.request_id="consume2"
	check(not supply.apply_command(cmd,{"campaign_authorized":true}).get("ok",false),"cannot consume nonexistent chip")
	var fill := {"contract_category":"singleplayer_supply","operation":"campaign_cargo","payload":{"container_id":"craft:dropship_1","item_id":"a_benit","amount":48},"request_id":"full-hold"}
	check(supply.apply_command(fill,{"campaign_authorized":true}).get("ok",false),"fill normal freight hold")
	cmd.request_id="reserved-chip"; cmd.payload.amount=1
	check(supply.apply_command(cmd,{"campaign_authorized":true}).get("ok",false),"full hold retains one reserved physical quest slot")
	cmd.request_id="duplicate-chip"
	check(not supply.apply_command(cmd,{"campaign_authorized":true}).get("ok",false),"reserved slot cannot duplicate chip")
	var restored = SUPPLY.new()
	check(restored.restore_state(supply.export_state()).get("ok",false),"quest inventory roundtrip")
	print("CAMPAIGN_SUPPLY failures=",failures)
	quit(1 if failures else 0)
func check(value: bool, label: String) -> void:
	if not value: failures+=1; push_error(label)
