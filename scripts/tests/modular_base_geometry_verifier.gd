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
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var base: Node = flow.get("_singleplayer_runtime").get_base_personnel_runtime()
	var room := {"id":"test_room", "type":"sleep", "x":0, "y":0, "rotation":0}
	var candidate := {"rooms":[room], "beds":[]}
	var off_map := {"rooms":[{"id":"outside", "type":"sleep", "x":8, "y":8, "rotation":0}], "beds":[]}
	var rejected: Dictionary = base.validate_modular_base(off_map)
	check(not rejected.get("ok", false), "construction outside visible map is rejected")
	var result: Dictionary = base.validate_modular_base(candidate)
	check(result.get("ok", false), "real base accepts first empty sleep room: " + str(result))
	if not result.get("ok", false): flow.queue_free(); await process_frame; quit(1); return
	base.sync_modular_base(candidate)
	var beds_before: int = base.get_recruitment_bed_capacity().beds
	candidate.beds.append({"id":"test_bed", "room_id":"test_room", "slot":0})
	result = base.validate_modular_base(candidate)
	check(result.get("ok", false), "bed construction reaches proposed room: " + str(result))
	if result.get("ok", false):
		base.sync_modular_base(candidate)
		check(base.get_recruitment_bed_capacity().beds == beds_before + 1, "only placed bed expands actual capacity")
		result = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":"test_bed"})
		check(result.get("ok", false), "actual actor starts walking to modular bed: " + str(result))
		var sim: Node = base.get_simulation_root(); sim.set_physics_process(false)
		for i in range(6000):
			sim.call("_physics_process", 0.05)
			if base.get_snapshot().units[0].status == "sleeping": break
		check(base.get_snapshot().units[0].status == "sleeping", "actor reaches room and sleeps")
	check(GEO.wall_blocks(room, GEO.center(room) + Vector2(2.9, 1.5)), "room wall blocks")
	check(not GEO.wall_blocks(room, GEO.center(room) + Vector2(2.9, 0.0)), "doorway remains open")
	flow.queue_free(); await process_frame
	if failed == 0: print("MODULAR_BASE_GEOMETRY_PASS")
	quit(0 if failed == 0 else 1)
