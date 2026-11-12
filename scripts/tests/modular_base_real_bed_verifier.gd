extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const GEO = preload("res://scripts/meta/modular_base_geometry.gd")
var failed := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failed += 1
func run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var base: Node = adapter.get_base_personnel_runtime()
	var supply: RefCounted = adapter.get("_supply")
	supply.set("_credits", 5000)
	var result: Dictionary = adapter.request_operation("campaign_build_room", {"request_id":"real-room-sleep", "type":"sleep", "x":0,"y":0,"rotation":0})
	check(result.get("ok",false), "build first sleeping room: " + str(result))
	if not result.get("ok", false): flow.queue_free(); await process_frame; quit(1); return
	var room_id: String = result.room_id
	result = adapter.request_operation("campaign_build_room", {"request_id":"real-room-hall", "type":"corridor", "x":1,"y":0,"rotation":0})
	check(result.get("ok",false), "build adjacent corridor: " + str(result))
	result = adapter.request_operation("campaign_build_room", {"request_id":"real-room-storage", "type":"storage", "x":2,"y":0,"rotation":0})
	check(result.get("ok",false), "build storage beyond corridor: " + str(result))
	var credits_before: int = int(adapter.get_snapshot().supply.credits)
	result = adapter.request_operation("campaign_set_room_door", {"request_id":"door-open", "room_id":room_id, "side":2, "open":true})
	check(result.get("ok", false), "open unused southern door")
	result = adapter.request_operation("campaign_set_room_door", {"request_id":"door-open", "room_id":room_id, "side":2, "open":true})
	check(result.get("ok", false) and int(adapter.get_snapshot().supply.credits) == credits_before, "door replay is free and idempotent")
	result = adapter.request_operation("campaign_set_room_door", {"request_id":"door-close", "room_id":room_id, "side":2, "open":false})
	check(result.get("ok", false), "close secondary door")
	result = adapter.request_operation("campaign_set_room_door", {"request_id":"door-disconnect", "room_id":"room_0002", "side":3, "open":false})
	check(not result.get("ok", false) and int(adapter.get_snapshot().supply.credits) == credits_before, "cannot disconnect corridor or charge for failed door")
	var terrain: Node = base.get("_terrain")
	var nav: RefCounted = base.get("_navigation_graph")
	var first: Vector2 = GEO.center({"x":0,"y":0})
	var start_world: Vector2 = terrain.grid_to_world(GEO.plane_grid(first))
	var end_world: Vector2 = terrain.grid_to_world(GEO.plane_grid(first + Vector2(12,0)))
	var route: Array = nav.find_world_path(start_world, end_world)
	var stays_inside := not route.is_empty()
	for step: Vector2 in route:
		var p: Vector3 = load("res://scripts/meta/base_interior_navigation.gd").plane_at_grid(terrain.world_to_grid(step))
		if absf(p.z - first.y) > 2.7: stays_inside = false; break
	check(stays_inside, "walkable connection crosses the corridor indoors")
	result = adapter.request_operation("campaign_place_room_bed", {"request_id":"real-room-bed", "room_id":room_id,"slot":0})
	check(result.get("ok",false), "buy first bed separately: " + str(result))
	if not result.get("ok", false): flow.queue_free(); await process_frame; quit(1); return
	var bed_id: String = result.bed_id
	check(base.get_recruitment_bed_capacity().beds == 3, "only one added bed counts")
	result = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":bed_id})
	check(result.get("ok", false), "actual actor starts walking: " + str(result))
	var blocked: Dictionary = adapter.request_operation("campaign_set_room_door", {"request_id":"door-moving", "room_id":room_id, "side":3, "open":true})
	check(not blocked.get("ok", false) and blocked.get("reason", "") == "modular_site_busy", "door changes wait for active paths")
	var sim: Node = base.get_simulation_root(); sim.set_physics_process(false)
	for i in range(6000):
		sim.call("_physics_process", 0.05)
		if base.get_snapshot().units[0].status == "sleeping": break
	check(base.get_snapshot().units[0].status == "sleeping", "actor walks through doorway and sleeps")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint",flow,adapter)
	check(saved.get("ok", false), "save room and sleeping actor")
	flow.queue_free(); await process_frame
	START.request_start(self,"campaign","continue")
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime"); base = adapter.get_base_personnel_runtime()
	check(base.get_snapshot().bed_occupants.get(bed_id) == "campaign_leader", "sleeping occupant restored")
	check(base.get_recruitment_bed_capacity().beds == 3, "bed capacity restored")
	var plan: Dictionary = adapter.get_snapshot().supply.modular_base
	check(plan.rooms.size()==3 and plan.beds.size()==1, "room, corridor, storage and bed persisted")
	check(plan.rooms[0].doors == [true, true, false, false] and plan.rooms[1].doors == [false,true,false,true], "door states and connections persist")
	flow.queue_free(); await process_frame
	if failed == 0: print("MODULAR_BASE_REAL_BED_PASS")
	quit(0 if failed == 0 else 1)
