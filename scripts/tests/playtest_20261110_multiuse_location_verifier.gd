extends SceneTree
var failed:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var supply=load("res://scripts/core/singleplayer_supply_state.gd").new(); supply.configure(["c"])
	supply.configure_inventory(["u"], ["c"], true)
	if not supply.has_method("get_location_resources"):
		check(false,"shared resource owner exists"); quit(1); return
	var source: RefCounted=supply.get_location_resources("satellite_crash")
	source.discover("iron_ridge_01"); source.discover("freighter_wreck_01")
	var context: Dictionary={"resource_authorized":true,"unit_id":"u","location_id":"satellite_crash","use_complete":true,"within_radius":true}
	var payload: Dictionary={"unit_id":"u","location_id":"satellite_crash","site_id":"iron_ridge_01"}
	var contract=load("res://scripts/mission/singleplayer_supply_command_contract.gd")
	var command: Dictionary=contract.build_command("collect_resource",payload,"harvest:ore")
	var before: Dictionary=supply.export_state()
	check(not supply.apply_command(command,context).get("ok",false) and supply.export_state()==before,"missing real backpack tool consumes no source")
	var purchase: Dictionary = supply.apply_command(
		contract.build_command("buy", {"offer_id": "backpack_supply", "quantity": 1}, "buy:pack"),
		{"location_id": "trade_outpost", "craft_id": "c", "craft_busy": false}
	)
	check(purchase.get("ok", false), "mining crew buys an optional backpack at the trade outpost")
	var access: Dictionary = {"accessible_containers": ["base:homebase", "craft:c", "unit:u:backpack"], "unit_id": "u", "loadout": {"armor": "light"}}
	var equipped: Dictionary = supply.apply_command(
		contract.build_command("inventory_equip", {"source_container_id": "craft:c", "slot": "backpack", "unit_id": "u", "item_id": "backpack"}, "equip:pack"),
		access
	)
	check(equipped.get("ok", false), "mining crew equips the purchased backpack")
	for item in ["mining_tool","salvage_tool"]:
		var moved: Dictionary=supply.apply_command(contract.build_command("inventory_transfer",{"source_container_id":"base:homebase","destination_container_id":"unit:u:backpack","item_id":item,"amount":1},"pack:"+item),access)
		check(moved.get("ok",false),"finite tool packs "+item)
	var mined: Dictionary = supply.apply_command(command, context)
	check(mined.get("ok", false), "timed authorized mining yields finite ore")
	before=supply.export_state()
	check(supply.apply_command(command,context).get("replayed",false) and supply.export_state()==before,"mining retry cannot duplicate ore")
	check(source.get_site_snapshot("iron_ridge_01").remaining==0,"shared ore source exhausted")
	payload.site_id="freighter_wreck_01"
	var salvage: Dictionary=contract.build_command("collect_resource",payload,"harvest:wreck")
	check(not supply.apply_command(salvage,context).get("ok",false) and source.get_site_snapshot("freighter_wreck_01").remaining==8,"full backpack preserves wreck")
	check(supply.apply_command(contract.build_command("inventory_transfer",{"source_container_id":"unit:u:backpack","destination_container_id":"base:homebase","item_id":mined.get("item_id", ""),"amount":mined.get("quantity", 0)},"unpack"),access).get("ok",false),"ore can be unloaded normally")
	check(supply.apply_command(salvage,context).get("ok",false),"independent salvage yields once after space is freed")
	var campaign=load("res://scripts/core/singleplayer_campaign_state.gd").new(); campaign.configure()
	check(campaign.get_campaign_snapshot().jobs.satellite_recovery.status=="offered","resources do not manufacture satellite mission completion")
	var restored=supply.get_script().new()
	check(restored.restore_state(supply.export_state()).get("ok",false),"checkpoint restores resources with containers")
	check(restored.get_location_resources("satellite_crash").get_site_snapshot("freighter_wreck_01").remaining==0,"continue cannot refill harvested wreck")
	var legacy: Dictionary=supply.export_state()
	legacy.erase("location_resources")
	for id in ["mining_tool_supply","salvage_tool_supply","backpack_supply"]:
		legacy.definitions.offers.erase(id); legacy.stock_by_offer_id.erase(id)
	var migrated=supply.get_script().new()
	check(migrated.restore_state(legacy).get("ok",false),"older unchanged supply definitions accept additive tool offers")
	check(migrated.get_supply_snapshot().inventory==supply.get_supply_snapshot().inventory,"offer migration leaves real containers untouched")
	legacy.definitions.offers.erase("medictool_supply"); legacy.stock_by_offer_id.erase("medictool_supply")
	check(not migrated.restore_state(legacy).get("ok",false),"migration cannot remove an existing original offer")
	check(source==supply.get_location_resources("satellite_crash"),"second reader shares same authoritative place stock")
	print("MULTIUSE_LOCATION failed=",failed); quit(1 if failed else 0)
