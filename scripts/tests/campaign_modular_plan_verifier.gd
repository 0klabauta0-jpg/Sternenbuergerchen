extends SceneTree
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var failed := 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
func valid(_candidate: Dictionary) -> Dictionary: return {"ok":true}
func invalid(_candidate: Dictionary) -> Dictionary: return {"ok":false,"reason":"site_blocked"}
func command(supply: RefCounted, op: String, payload: Dictionary, id: String, ctx: Dictionary) -> Dictionary:
	return supply.apply_command(COMMANDS.build_command(op,payload,id),ctx)
func run() -> void:
	var supply = SUPPLY.new(); supply.configure(); supply.configure_inventory([],[]); supply._credits=3000
	var ctx := {"at_home":true,"campaign_authorized":true,"modular_room_validator":Callable(self,"valid"),"modular_bed_validator":Callable(self,"valid")}
	var base := {"type":"sleep","x":0,"y":0,"rotation":0}
	var missing := {"at_home":true,"campaign_authorized":true}
	check(not command(supply,"campaign_build_room",base,"missing",missing).get("ok",false),"missing site validator cannot debit")
	var rejected := ctx.duplicate(); rejected.modular_room_validator=Callable(self,"invalid")
	check(not command(supply,"campaign_build_room",base,"blocked",rejected).get("ok",false) and supply.get_supply_snapshot().credits==3000,"blocked site leaves credits and plan unchanged")
	check(command(supply,"campaign_build_room",base,"room1",ctx).get("ok",false),"anchor sleeping room built")
	check(not command(supply,"campaign_build_room",{"type":"storage","x":3,"y":0,"rotation":0},"far",ctx).get("ok",false),"disconnected room rejected")
	check(not command(supply,"campaign_build_room",base,"overlap",ctx).get("ok",false),"occupied module rejected")
	check(command(supply,"campaign_build_room",{"type":"corridor","x":1,"y":0,"rotation":0},"hall",ctx).get("ok",false),"corridor connects")
	check(command(supply,"campaign_build_room",{"type":"storage","x":2,"y":0,"rotation":1},"store",ctx).get("ok",false),"storage connects through corridor")
	check(command(supply,"campaign_place_room_bed",{"room_id":"room_0001","slot":0},"bed1",ctx).get("ok",false),"first bed purchased separately")
	check(not command(supply,"campaign_place_room_bed",{"room_id":"room_0001","slot":0},"dup",ctx).get("ok",false),"occupied bed slot rejected")
	check(not command(supply,"campaign_place_room_bed",{"room_id":"room_0003","slot":0},"storage-bed",ctx).get("ok",false),"bed rejected outside sleeping room")
	var after := supply.get_supply_snapshot(); var credits: int = after.credits
	check(command(supply,"campaign_place_room_bed",{"room_id":"room_0001","slot":0},"bed1",ctx).get("replayed",false) and supply.get_supply_snapshot().credits==credits,"same request replays without payment")
	var saved: Dictionary = supply.export_state(); var restored = SUPPLY.new()
	check(restored.restore_state(saved).get("ok",false) and restored.get_supply_snapshot().modular_base==after.modular_base,"room and bed plan restores")
	var old_save := saved.duplicate(true)
	for entry: Dictionary in old_save.requests.values():
		if entry.result.get("operation", "") == "campaign_build_room": entry.result.erase("door_schema")
	var old_restored = SUPPLY.new()
	var old_ok: Dictionary = old_restored.restore_state(old_save)
	check(old_ok.get("ok", false) and old_restored.get_supply_snapshot().modular_base.rooms[0].doors == [true,true,true,true], "legacy modular rooms restore all previous openings")
	var modified := saved.duplicate(true); modified.requests.bed1.result.bed_id="forged"
	check(not SUPPLY.new().restore_state(modified).get("ok",false),"forged bed receipt rejected")
	if failed==0: print("CAMPAIGN_MODULAR_PLAN_PASS")
	quit(0 if failed==0 else 1)
