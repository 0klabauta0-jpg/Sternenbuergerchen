extends SceneTree
var failures := 0
var seq := 0
var owner: RefCounted
var context := {"accessible_containers":["base:homebase","craft:c1","unit:u1:backpack"],"unit_id":"u1","loadout":{"armor":"medium","weapon_1":"rifle","weapon_2":"none"}}
func _init() -> void: call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
func _cmd(op: String, data: Dictionary, request: String = "") -> Dictionary:
	seq += 1
	return owner.apply_command(load("res://scripts/mission/singleplayer_supply_command_contract.gd").build_command(op,data,request if not request.is_empty() else "test:"+str(seq)),context)
func _run() -> void:
	owner = load("res://scripts/core/singleplayer_supply_state.gd").new()
	owner.configure(["c1"])
	if not owner.has_method("configure_inventory"):
		_check(false,"inventory owner exposes finite containers")
		quit(1)
		return
	owner.configure_inventory(["u1"],["c1"])
	var move := {"item_id":"rifle","amount":1,"source_container_id":"base:homebase","destination_container_id":"unit:u1:backpack"}
	_check(_cmd("inventory_transfer",move,"move").get("ok",false),"base to backpack confirmed")
	var state: Dictionary = owner.export_state()
	_check(_cmd("inventory_transfer",move,"move").get("replayed",false) and owner.export_state()==state,"replay changes nothing")
	var changed := move.duplicate(); changed.amount=2
	_check(not _cmd("inventory_transfer",changed,"move").get("ok",false),"request signature conflict rejected")
	for amount in [0,-1,0.5,100000]:
		var bad := move.duplicate(); bad.amount=amount
		_check(not _cmd("inventory_transfer",bad).get("ok",false) and owner.export_state()==state,"invalid amount leaves inventory unchanged")
	for target in ["craft:remote","unit:other:backpack","unknown"]:
		var bad := move.duplicate(); bad.destination_container_id=target
		_check(not _cmd("inventory_transfer",bad).get("ok",false) and owner.export_state()==state,"remote or foreign container rejected")
	var bad := move.duplicate(); bad.item_id="invented"
	_check(not _cmd("inventory_transfer",bad).get("ok",false),"unknown item rejected")
	var equip := {"unit_id":"u1","source_container_id":"base:homebase","slot":"armor","item_id":"rifle"}
	_check(not _cmd("inventory_equip",equip).get("ok",false),"weapon cannot equip armor slot")
	equip.item_id="armor_heavy"
	var result := _cmd("inventory_equip",equip)
	_check(result.get("ok",false) and result.get("loadout",{}).get("armor")=="heavy","armor swap returns confirmed loadout")
	var inv: Dictionary = owner.get_supply_snapshot().inventory
	_check(inv["base:homebase"].items.armor_medium==3 and inv["base:homebase"].items.armor_heavy==1,"old equipped armor returned atomically")
	# Pack all remaining stock into a deliberately bounded container.
	owner._inventory["unit:u1:backpack"].capacity=1
	state=owner.export_state()
	_check(not _cmd("inventory_transfer",move).get("ok",false) and owner.export_state()==state,"full backpack does not consume source")
	var restored = owner.get_script().new()
	_check(restored.restore_state(state).get("ok",false),"checkpoint restores container state")
	_check(restored.get_supply_snapshot().inventory==owner.get_supply_snapshot().inventory,"checkpoint preserves exact quantities")
	_check_campaign_storage()
	_check_legacy_campaign_storage()
	print("INVENTORY failures=",failures)
	quit(1 if failures else 0)


func _check_campaign_storage() -> void:
	owner = owner.get_script().new()
	owner.configure(["c1"])
	owner.configure_inventory(["u1"], ["c1"], true)
	context.loadout.armor = "light"
	context.campaign_authorized = true
	context.location_id = "trade_outpost"
	context.craft_id = "c1"
	context.craft_busy = false
	var personal := "unit:u1:backpack"
	var cargo := "craft:c1"
	var pickup := {"container_id": personal, "item_id": "satellite_chip", "amount": 1}
	var transfer := {"item_id": "rifle", "amount": 1, "source_container_id": "base:homebase", "destination_container_id": personal}
	var bag: Dictionary = owner.get_supply_snapshot().inventory[personal]
	_check(bag.get("armor_chip_capacity") == 1 and bag.capacity == 0, "light campaign armor supplies one chip slot with no starter backpack")
	_check(not _cmd("inventory_transfer", transfer).get("ok", false), "ordinary cargo cannot use reserved suit storage")
	var crate := pickup.duplicate()
	crate.item_id = "c_benit_crate"
	_check(not _cmd("campaign_cargo", crate).get("ok", false), "Benit crate cannot fit into the armor chip slot")
	_check(_cmd("campaign_cargo", pickup, "suit-pickup").get("ok", false), "actual chip cargo command fills the starter armor slot")
	_check(_cmd("campaign_cargo", pickup, "suit-pickup").get("replayed", false), "chip pickup retries preserve one chip")
	var other_chip := pickup.duplicate()
	other_chip.item_id = "outpost_chip"
	_check(not _cmd("campaign_cargo", other_chip).get("ok", false), "second chip requires an additional slot")
	var restored: RefCounted = owner.get_script().new()
	_check(restored.restore_state(owner.export_state()).get("ok", false) and restored.get_supply_snapshot().inventory == owner.get_supply_snapshot().inventory, "checkpoint preserves the occupied suit and empty backpack slot")
	_check(_cmd("buy", {"offer_id": "backpack_supply", "quantity": 1}).get("ok", false), "backpack purchase delivers a real item to parked ship cargo")
	bag = owner.get_supply_snapshot().inventory[personal]
	_check(bag.capacity == 0, "purchase alone does not increase carried capacity")
	var equip := {"unit_id": "u1", "slot": "backpack", "item_id": "backpack", "source_container_id": cargo}
	_check(_cmd("inventory_equip", equip, "backpack-equip").get("ok", false), "equipping uses the existing inventory operation")
	var snapshot: Dictionary = owner.get_supply_snapshot()
	_check(snapshot.inventory[personal].capacity == 12 and not snapshot.inventory[cargo].items.has("backpack"), "equipping adds twelve storage slots and consumes the purchased item")
	_check(_cmd("inventory_equip", equip, "backpack-equip").get("replayed", false) and snapshot == owner.get_supply_snapshot(), "equipping replays without duplicating gear or capacity")
	_check(_cmd("inventory_transfer", transfer).get("ok", false), "equipped backpack can now carry normal items")
	var unequip := equip.duplicate()
	unequip.item_id = "none"
	_check(not _cmd("inventory_equip", unequip).get("ok", false), "backpack containing cargo cannot be removed")
	var unload := transfer.duplicate()
	unload.source_container_id = personal
	unload.destination_container_id = cargo
	_check(_cmd("inventory_transfer", unload).get("ok", false), "contents can be unloaded before removing a backpack")
	_check(_cmd("inventory_equip", unequip).get("ok", false), "empty backpack can be put back in ship cargo")
	snapshot = owner.get_supply_snapshot()
	_check(snapshot.inventory[personal].capacity == 0 and snapshot.inventory[personal].items == {"satellite_chip": 1} and snapshot.inventory[cargo].items.get("backpack", 0) == 1, "removing backpack returns the item and leaves the armor chip")
	pickup.amount = -1
	_check(_cmd("campaign_cargo", pickup).get("ok", false) and owner.get_supply_snapshot().inventory[personal].items.is_empty(), "upload consumption empties armor slot")


func _check_legacy_campaign_storage() -> void:
	owner = owner.get_script().new()
	owner.configure(["c1"])
	owner.configure_inventory(["u1"], ["c1"])
	var legacy: Dictionary = owner.export_state()
	legacy.definitions.offers.erase("backpack_supply")
	legacy.stock_by_offer_id.erase("backpack_supply")
	var personal := "unit:u1:backpack"
	var old_items := {"rifle": 12, "satellite_chip": 1, "outpost_chip": 1}
	legacy.inventory[personal].items = old_items
	_check(owner.restore_state(legacy).get("ok", false), "older checkpoint is compatible with the new backpack offer")
	owner.configure_inventory(["u1"], ["c1"], true)
	var snapshot: Dictionary = owner.get_supply_snapshot()
	_check(snapshot.inventory[personal].items == old_items and snapshot.inventory[personal].armor_chip_capacity == 1, "migration preserves all old cargo and gives a suit chip slot")
	var restored: RefCounted = owner.get_script().new()
	_check(restored.restore_state(owner.export_state()).get("ok", false) and restored.get_supply_snapshot().inventory == snapshot.inventory, "migrated full backpack checkpoint roundtrips")
