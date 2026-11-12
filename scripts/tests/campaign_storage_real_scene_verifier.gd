extends SceneTree
## Uses a real campaign scene, adapter, supply owner and campaign checkpoint.
const START = preload("res://scripts/meta/game_start_contract.gd")
var failed := 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
func run() -> void:
	START.request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var supply = adapter.get("_supply")
	var before: Dictionary = supply.get_supply_snapshot()
	var result: Dictionary = adapter.request_operation("campaign_build_room",{"request_id":"storage-real-1","type":"storage","x":0,"y":0,"rotation":0})
	check(result.get("ok",false),"real adapter builds storage room: "+str(result))
	if not result.get("ok",false):
		flow.queue_free(); await process_frame; quit(1); return
	var after: Dictionary = supply.get_supply_snapshot()
	check(int(after.credits)==int(before.credits)-300 and int(after.inventory["base:homebase"].capacity)==int(before.inventory["base:homebase"].capacity)+100,"room charges once and expands actual base container")
	var replay: Dictionary = adapter.request_operation("campaign_build_room",{"request_id":"storage-real-1","type":"storage","x":0,"y":0,"rotation":0})
	check(replay.get("ok",false) and replay.get("replayed",false) and supply.get_supply_snapshot().credits==after.credits,"replayed build has no second charge")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint",flow,adapter)
	check(saved.get("ok",false),"real checkpoint saves storage")
	flow.queue_free(); await process_frame
	START.request_start(self,"campaign","continue")
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow); await process_frame
	adapter = flow.get("_singleplayer_runtime"); supply = adapter.get("_supply")
	var restored: Dictionary = supply.get_supply_snapshot()
	check(int(restored.inventory["base:homebase"].capacity)==int(after.inventory["base:homebase"].capacity),"expanded real inventory persists after continue")
	check(Array(restored.modular_base.rooms).size()==1 and String(restored.modular_base.rooms[0].type)=="storage","storage plan persists after continue")
	flow.queue_free(); await process_frame
	if failed==0: print("CAMPAIGN_STORAGE_REAL_SCENE_PASS")
	quit(0 if failed==0 else 1)
