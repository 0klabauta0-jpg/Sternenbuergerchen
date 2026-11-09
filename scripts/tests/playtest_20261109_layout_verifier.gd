extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	var screen = flow.get_node("HomebaseScreen")
	await process_frame
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(3440, 1440)]:
		root.content_scale_size = resolution
		root.size = resolution
		var deadline: int = Time.get_ticks_msec() + 5000
		while screen.size != Vector2(resolution) and Time.get_ticks_msec() < deadline:
			await process_frame
		_check(screen.size == Vector2(resolution), "Real viewport reached %s" % resolution)
		for mode in ["personnel", "squad", "jobs", "map", "mission", "services", "base"]:
			screen.request_operation("navigate", {"mode": mode})
			await process_frame
			await process_frame
			var important: Array[String] = []
			match mode:
				"mission": important = ["StartMission", "OpenBaseServices"]
				"jobs": important = ["AcceptJob", "ShowOnMap"]
				"map": important = ["homebase", "satellite_crash", "trade_outpost"]
				"squad": important = ["Neuer Trupp"]
			for node_name in important:
				var button: Control = screen.find_child(node_name, true, false)
				if button == null:
					for candidate in screen.find_children("*", "Button", true, false):
						if candidate.text == node_name:
							button = candidate
							break
				_check(button != null and button.is_visible_in_tree(), "%s/%s visible at %s" % [mode, node_name, resolution])
				if button != null and button.is_visible_in_tree():
					var rect: Rect2 = button.get_global_rect()
					_check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= resolution.x + 1 and rect.end.y <= resolution.y + 1, "%s/%s inside viewport: %s" % [mode, node_name, rect])
			var explorer = screen.find_child("ExplorableBase", true, false)
			if mode == "mission":
				_check(explorer.get_exploration_snapshot().preview_mode, "Flightdeck uses actual pad viewport")
			elif mode not in ["base", "mission"]:
				_check(not explorer.get_exploration_snapshot().active, "Hidden world inactive in %s" % mode)
	flow.queue_free()
	await process_frame
	print("LAYOUT_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
