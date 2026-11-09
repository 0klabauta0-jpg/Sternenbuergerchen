extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen = flow.get_node("HomebaseScreen")
	var craft_id: String = String(screen.get_operations_snapshot().selected_craft.id)
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	var launched: Dictionary = screen.request_operation("start", {"craft_id": craft_id})
	if not launched.get("ok", false):
		printerr("FAIL: Aborted-return fixture requires valid actual launch")
		flow.queue_free()
		await process_frame
		quit(1)
		return
	# A genuine early retreat: reach the real map, return while the ship is
	# still waiting, then perform the orbital journey and home landing.
	var runtime: Node = flow.get("_singleplayer_runtime")
	screen.request_operation("space_start_quantum", {"craft_id": craft_id, "target_orbit_id": "planet_orbit"})
	var deadline := Time.get_ticks_msec() + 5000
	while String(runtime.get_snapshot().space_travel.orbit_id) != "planet_orbit" and Time.get_ticks_msec() < deadline:
		await process_frame
	var approach: Dictionary = screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	if not approach.get("ok", false):
		printerr("FAIL: Retreat fixture needs authorized approach: ", approach)
		flow.queue_free()
		await process_frame
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var mission: Node = flow.get("_active_mission")
		if mission != null and String(Dictionary(mission.get_node("TacticalController").call("_find_mission_dropship_card_entry", craft_id)).get("state", "")) == "waiting":
			break
		await process_frame
	var retreat: Dictionary = screen.request_operation("return_homebase", {"craft_id": craft_id})
	if not retreat.get("ok", false):
		printerr("FAIL: Real waiting ship accepts retreat: ", retreat)
		flow.queue_free()
		await process_frame
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 25000
	while String(runtime.get_snapshot().space_travel.phase) != "orbit" and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	var remote := String(runtime.get_snapshot().space_travel.orbit_id) == "planet_orbit"
	screen.request_operation("space_start_quantum", {"craft_id": craft_id, "target_orbit_id": "moon_orbit"})
	deadline = Time.get_ticks_msec() + 5000
	while String(runtime.get_snapshot().space_travel.orbit_id) != "moon_orbit" and Time.get_ticks_msec() < deadline:
		await process_frame
	var landed: Dictionary = screen.request_operation("space_land_homebase", {"craft_id": craft_id})
	var snapshot: Dictionary = flow.get_singleplayer_snapshot()
	var closed: bool = flow.get("_active_mission") == null
	var failed: bool = String(snapshot.campaign.jobs.satellite_recovery.status) == "failed"
	var no_reward: bool = snapshot.campaign.completion_receipts.is_empty() and int(snapshot.supply.credits) == 500
	print("ABORTED_VISIT_RETURN closed=%s failed=%s no_reward=%s" % [closed, failed, no_reward])
	flow.queue_free()
	await process_frame
	quit(0 if remote and landed.get("ok", false) and closed and failed and no_reward else 1)
