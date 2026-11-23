extends SceneTree
var failures := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	var runtime: Node=flow.get("_singleplayer_runtime")
	var craft: String=String(screen.call("get_operations_snapshot").selected_craft.id)
	var gear: Dictionary=screen.call("request_operation","loadout",{"unit_id":"campaign_pilot","key":"weapon_1","value":"medictool"})
	check(gear.get("ok",false),"outside pilot equips real finite medictool through original control")
	check(screen.call("_get_member_loadout","campaign_pilot").weapon_1=="medictool","original loadout owner receives confirmed gear")
	var command: Dictionary={"unit_id":"campaign_pilot","craft_id":craft,"item_id":"pistol","amount":1,"source_container_id":"base:homebase","destination_container_id":"craft:"+craft,"request_id":"runtime-transfer"}
	var moved: Dictionary=screen.call("request_operation","inventory_transfer",command)
	check(moved.get("ok",false),"visible inventory operation reaches authoritative owner: "+str(moved))
	check(screen.call("request_operation","inventory_transfer",command).get("replayed",false),"visible retry does not duplicate transfer")
	command.destination_container_id="craft:remote"; command.request_id="remote"
	check(not screen.call("request_operation","inventory_transfer",command).get("ok",false),"adapter denies remote craft access")
	var exported: Dictionary=runtime.call("export_campaign_checkpoint")
	var supply=load("res://scripts/core/singleplayer_supply_state.gd").new()
	check(supply.restore_state(exported.supply).get("ok",false),"real campaign supply checkpoint accepts containers and receipts")
	check(supply.get_supply_snapshot().inventory==runtime.call("get_snapshot").supply.inventory,"real checkpoint roundtrip preserves quantities")
	flow.queue_free(); await process_frame
	print("INVENTORY_RUNTIME failures=",failures); quit(1 if failures else 0)
