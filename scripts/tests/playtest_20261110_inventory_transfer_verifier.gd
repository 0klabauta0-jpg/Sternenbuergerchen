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
	print("INVENTORY failures=",failures)
	quit(1 if failures else 0)
