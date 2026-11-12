extends SceneTree
## Exercise the existing supply owner and real inventory transfers, without UI.
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var failed := 0

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
func validate_room(_plan: Dictionary) -> Dictionary:
	return {"ok":true}
func deny_room(_plan: Dictionary) -> Dictionary:
	return {"ok":false,"reason":"space_blocked"}
func command(supply: RefCounted, operation: String, payload: Dictionary, id: String, context: Dictionary) -> Dictionary:
	return supply.apply_command(COMMANDS.build_command(operation,payload,id),context)
func run() -> void:
	var supply = SUPPLY.new()
	check(supply.configure().get("ok",false),"supply configured")
	supply.configure_inventory([], ["probe"])
	supply.configure_start_inventory("campaign")
	supply._credits = 3000
	var inventory: Dictionary = supply._inventory
	supply._item_quantities.clear()
	supply._item_quantities["pistol"] = 200
	inventory["craft:probe"].items["pistol"] = 1
	var context := {"accessible_containers":["base:homebase","craft:probe"]}
	var transfer := {"source_container_id":"craft:probe","destination_container_id":"base:homebase","item_id":"pistol","amount":1}
	var before := command(supply,"inventory_transfer",transfer,"full",context)
	check(not before.get("ok",false) and before.get("reason","")=="container_full","full original storage rejects extra item")
	var build_context := {"at_home":true,"campaign_authorized":true,"modular_room_validator":Callable(self,"validate_room")}
	var room := {"type":"storage","x":0,"y":0,"rotation":0}
	var blocked_context := build_context.duplicate()
	blocked_context.modular_room_validator = Callable(self,"deny_room")
	var credits_before := int(supply.get_supply_snapshot().credits)
	var denied := command(supply,"campaign_build_room",room,"denied",blocked_context)
	check(not denied.get("ok",false) and int(supply.get_supply_snapshot().credits)==credits_before and int(inventory["base:homebase"].capacity)==200,"blocked room changes neither credits nor capacity")
	var first := command(supply,"campaign_build_room",room,"storage-1",build_context)
	check(first.get("ok",false),"storage room accepted: "+str(first))
	check(int(inventory["base:homebase"].capacity)==300,"actual capacity grows by 100")
	var credits := int(supply.get_supply_snapshot().credits)
	var replay := command(supply,"campaign_build_room",room,"storage-1",build_context)
	check(replay.get("ok",false) and replay.get("replayed",false) and int(inventory["base:homebase"].capacity)==300 and supply.get_supply_snapshot().credits==credits,"replay cannot add capacity or charge twice")
	var moved := command(supply,"inventory_transfer",transfer,"after",context)
	check(moved.get("ok",false) and int(supply._item_quantities.pistol)==201 and inventory["craft:probe"].items.is_empty(),"existing inventory transfer uses expanded capacity")
	var saved: Dictionary = supply.export_state()
	var restored = SUPPLY.new()
	var restored_ok: Dictionary = restored.restore_state(saved)
	check(restored_ok.get("ok",false),"expanded state restores: "+str(restored_ok))
	if restored_ok.get("ok",false):
		var snap: Dictionary = restored.get_supply_snapshot()
		check(int(snap.inventory["base:homebase"].capacity)==300 and int(snap.inventory["base:homebase"].items.pistol)==201,"capacity and contents survive restore")
		check(Array(snap.modular_base.rooms).size()==1,"storage room persists with capacity")
	var bad := saved.duplicate(true)
	bad.inventory["base:homebase"].capacity = 200
	var reject = SUPPLY.new().restore_state(bad)
	check(not reject.get("ok",false),"inconsistent capacity cannot lose stored items")
	bad = saved.duplicate(true)
	bad.modular_capacity_baseline = 199
	reject = SUPPLY.new().restore_state(bad)
	check(not reject.get("ok",false),"capacity inconsistent with room receipts is rejected")
	var legacy = SUPPLY.new()
	legacy.configure(); legacy.configure_inventory([],[])
	legacy._inventory["base:homebase"].capacity = 264
	legacy._credits = 1000
	var old_save: Dictionary = legacy.export_state()
	old_save.erase("modular_capacity_baseline")
	var migrated = SUPPLY.new()
	check(migrated.restore_state(old_save).get("ok",false),"older save without modular baseline remains readable")
	var legacy_build: Dictionary = command(migrated,"campaign_build_room",room,"legacy-storage",build_context)
	check(legacy_build.get("ok",false) and int(migrated.get_supply_snapshot().inventory["base:homebase"].capacity)==364,"older enlarged base keeps its capacity plus new room")
	check(SUPPLY.new().restore_state(migrated.export_state()).get("ok",false),"migrated enlarged base restores again")
	if failed==0: print("CAMPAIGN_MODULAR_STORAGE_PASS")
	quit(0 if failed==0 else 1)
