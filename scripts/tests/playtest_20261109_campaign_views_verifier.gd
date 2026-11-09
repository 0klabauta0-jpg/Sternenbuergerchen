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
		var trade = region.get_node_or_null("Content/Locations/trade_outpost")
		_check(trade != null, "Trade has an independent location target")
		if trade != null:
			trade.pressed.emit()
		var snap: Dictionary = flow.get_singleplayer_snapshot().campaign
		_check(snap.selected_location_id == "trade_outpost" and snap.selected_job_id == "", "Trade target clears combat job and causes no flight")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_VIEWS failed=", failures)
	quit(0 if failures == 0 else 1)
