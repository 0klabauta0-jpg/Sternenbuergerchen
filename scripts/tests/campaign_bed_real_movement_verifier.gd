extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var failed := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failed += 1
func run() -> void:
	START.request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var base: Node = adapter.get_base_personnel_runtime()
	if base == null: check(false,"base runtime exists"); quit(1); return
	var sim: Node = base.get_simulation_root(); sim.set_physics_process(false)
	check(not base._requires_hex_ground(), "ordinary campaign supports bed construction")
	var result: Dictionary = adapter.request_operation("campaign_build_bed", {"request_id":"geometry-bed-1"})
	check(result.get("ok",false), "actual campaign command builds bed: " + str(result))
	if not result.get("ok",false): flow.queue_free(); await process_frame; quit(1); return
	var bed: Dictionary = base.get_snapshot().layout.beds[2]
	result = base.request_operation("base_sleep", {"unit_id":"campaign_leader","bed_id":bed.id})
	check(result.get("ok",false), "actual actor starts path to paid bed")
	var blocked_build: Dictionary = adapter.request_operation("campaign_build_bed", {"request_id":"geometry-bed-moving"})
	check(not blocked_build.get("ok",false) and blocked_build.get("reason", "") == "bed_site_busy", "active path blocks construction")
	for i in range(4000):
		sim.call("_physics_process",0.05)
		if base.get_snapshot().units[0].status == "sleeping": break
	check(base.get_snapshot().units[0].status == "sleeping", "actor arrives and sleeps at paid bed")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint",flow,adapter)
	check(saved.get("ok",false), "paid bed and occupant save")
	flow.queue_free(); await process_frame
	START.request_start(self,"campaign","continue")
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime"); base = adapter.get_base_personnel_runtime()
	sim = base.get_simulation_root(); sim.set_physics_process(false)
	check(base.get_recruitment_bed_capacity().beds == 3 and base.get_snapshot().bed_occupants.get(bed.id) == "campaign_leader", "paid bed and sleeper restored")
	check(base.request_operation("base_wake", {"unit_id":"campaign_leader"}).get("ok",false), "restored actor wakes")
	result = base.request_operation("base_sleep", {"unit_id":"campaign_pilot","bed_id":bed.id})
	check(result.get("ok",false), "another actor finds path after restore")
	for i in range(4000):
		sim.call("_physics_process",0.05)
		if base.get_snapshot().units[1].status == "sleeping": break
	check(base.get_snapshot().units[1].status == "sleeping", "second actor reaches restored bed")
	flow.queue_free(); await process_frame
	if failed == 0: print("CAMPAIGN_BED_REAL_MOVEMENT_PASS")
	quit(0 if failed == 0 else 1)
