extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var failed := 0
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failed += 1
func _init() -> void: call_deferred("run")
func run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var base: Node = adapter.get_base_personnel_runtime()
	var before: Dictionary = adapter._supply.get_supply_snapshot()
	var result: Dictionary = adapter.request_operation("campaign_build_housing", {"request_id":"test-housing-1"})
	check(result.get("ok", false), "actual campaign builds first housing: " + str(result))
	var after: Dictionary = adapter._supply.get_supply_snapshot()
	check(after.credits == before.credits - 500 and after.campaign_housing == 1 and after.campaign_beds == 4, "housing costs 500 and includes two beds")
	var snapshot: Dictionary = base.get_snapshot()
	check(Array(snapshot.layout.get("campaign_housing", [])).size() == 1 and Array(snapshot.layout.beds).size() == 4, "housing and two original beds are in layout")
	check(Array(snapshot.layout.beds).all(func(b): return String(b.get("visual_kind", "")) != "field_bunk"), "campaign contains no field bunks")
	if result.get("ok", false):
		var sim: Node = base.get_simulation_root(); sim.set_physics_process(false)
		var bed: Dictionary = snapshot.layout.beds[2]
		var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader","bed_id":bed.id})
		check(sleep.get("ok", false), "person can walk to bed in new housing")
		for i in range(6000):
			sim._physics_process(0.05)
			if base._states.campaign_leader.status == "sleeping": break
		check(base._states.campaign_leader.status == "sleeping", "person reaches and sleeps in new housing")
		var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, adapter)
		check(saved.get("ok", false), "housing and sleeper checkpoint succeeds")
		flow.queue_free(); await process_frame
		START.request_start(self, "campaign", "continue")
		flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
		await process_frame
		adapter = flow.get("_singleplayer_runtime"); base = adapter.get_base_personnel_runtime()
		check(adapter._supply.get_campaign_housing_count() == 1 and base.get_recruitment_bed_capacity().beds == 4, "housing and capacity survive continue")
		check(base.get_snapshot().bed_occupants.get(bed.id) == "campaign_leader", "sleeper restored in same bed")
		adapter._supply._credits = 10000 # Fixture only: exercise all construction plots.
		for i in range(2, 10):
			var next: Dictionary = adapter.request_operation("campaign_build_housing", {"request_id":"test-housing-%d" % i})
			check(next.get("ok", false), "housing plot %d builds: %s" % [i, str(next)])
			if not next.get("ok", false): break
	flow.queue_free(); await process_frame
	if failed == 0: print("CAMPAIGN_HOUSING_PASS")
	quit(0 if failed == 0 else 1)
