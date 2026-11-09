extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen = flow.get_node("HomebaseScreen")
	_check(screen.request_operation("navigate", {"mode": "jobs"}).get("ok", false), "Smart Mobile is a usable regular navigation target")
	var jobs = screen.find_child("JobBoard", true, false)
	_check(jobs != null and jobs.is_visible_in_tree(), "Job board renders in Operations")
	if jobs != null:
		var accept = jobs.find_child("AcceptJob", true, false)
		_check(accept != null, "Job board exposes real accept action")
		if accept != null:
			accept.pressed.emit()
		_check(flow.get_singleplayer_snapshot().campaign.accepted_job_ids.has("satellite_recovery"), "Accept button commits authoritative job acceptance")
		_check(flow.get("_active_mission") == null, "Accept button starts no flight")
		var show_map = jobs.find_child("ShowOnMap", true, false)
		if show_map != null:
			show_map.pressed.emit()
		_check(flow.get_singleplayer_snapshot().campaign.selected_location_id == "satellite_crash", "Show-on-map keeps job/location identity")
	_check(screen.request_operation("navigate", {"mode": "map"}).get("ok", false), "Region map is independently reachable")
	var region = screen.find_child("RegionMap", true, false)
	_check(region != null and region.is_visible_in_tree(), "Separate regional view renders")
	if region != null:
		var trade = region.find_child("TradeDestination", true, false)
		_check(trade != null, "Trade has an independent location target")
		if trade != null:
			_check(trade.disabled, "Grounded preview postpones destination selection until planet orbit")
		var craft: Dictionary = screen.get_operations_snapshot().get("selected_craft", {})
		var craft_id: String = String(craft.get("id", ""))
		screen.call("_debug_advance_homebase_direct_boarding", 30.0)
		var launch: Dictionary = screen.request_operation("start", {"craft_id": craft_id})
		_check(bool(launch.get("ok", false)), "Actual Flightdeck start reaches moon orbit")
		var jump: Dictionary = screen.request_operation("space_start_quantum", {"craft_id": craft_id, "target_orbit_id": "planet_orbit"})
		_check(bool(jump.get("ok", false)), "Actual quantum starts toward planet orbit")
		var deadline := Time.get_ticks_msec() + 5000
		while String(flow.get_singleplayer_snapshot().space_travel.orbit_id) != "planet_orbit" and Time.get_ticks_msec() < deadline:
			await process_frame
		_check(String(flow.get_singleplayer_snapshot().space_travel.orbit_id) == "planet_orbit", "Actual quantum reaches planet without loading an Ortskarte")
		var star_map: Control = flow.get("_star_map_screen")
		star_map.call("refresh")
		trade = star_map.find_child("TradeDestination", true, false)
		_check(trade != null and not trade.disabled, "Trade target becomes usable at planet orbit")
		if trade != null and not trade.disabled:
			trade.pressed.emit()
		var snap: Dictionary = flow.get_singleplayer_snapshot().campaign
		_check(snap.selected_location_id == "trade_outpost" and snap.selected_job_id == "", "Trade target clears combat job and causes no flight")
		_check(flow.get("_active_mission") == null, "Planet location selection waits for explicit approach")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_VIEWS failed=", failures)
	quit(0 if failures == 0 else 1)
