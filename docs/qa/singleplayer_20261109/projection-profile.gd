extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen = flow.get_node("HomebaseScreen")
	var ops = screen.get_node("OperationsRoot")
	screen.request_operation("navigate", {"mode": "base"})
	await process_frame
	screen.request_operation("navigate", {"mode": "mission"})
	await process_frame
	var explorer = ops.get("_base")
	var viewport_id: int = explorer.get("_viewport").get_instance_id()
	var rows: int = int(ops.get("_row_create_count"))
	var samples: Array[int] = []
	for index in range(100):
		var start: int = Time.get_ticks_usec()
		ops.refresh()
		samples.append(Time.get_ticks_usec()-start)
	var total: int = 0
	for value in samples:
		total += value
	samples.sort()
	var stable: bool = int(ops.get("_row_create_count")) == rows and explorer.get("_viewport").get_instance_id() == viewport_id
	screen.request_operation("navigate", {"mode": "personnel"})
	var inactive: bool = not bool(explorer.get_exploration_snapshot().active) and explorer.get("_viewport").render_target_update_mode == SubViewport.UPDATE_DISABLED
	var report := {"scope":"Headless synchronous warmed Operations refresh sample, current machine load; not native frame/FPS acceptance", "samples":samples.size(),"mean_usec":float(total)/samples.size(),"p95_usec":samples[94],"maximum_usec":samples[-1],"new_roster_rows":int(ops.get("_row_create_count"))-rows,"shared_viewport_preserved":stable,"hidden_world_rendering_disabled":inactive}
	var f=FileAccess.open("res://docs/qa/singleplayer_20261109/projection-profile.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	print("PROJECTION_PROFILE ",JSON.stringify(report))
	flow.queue_free()
	await process_frame
	quit(0 if stable and inactive else 1)
