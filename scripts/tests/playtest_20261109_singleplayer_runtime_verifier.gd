extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	flow.call("_show_fob")
	var failures: int = 0
	if flow.get("_current_meta_view") == "fob":
		printerr("FAIL: Regular programmable navigation cannot enter FOB")
		failures += 1
	if not flow.has_method("get_singleplayer_snapshot"):
		printerr("FAIL: Persistent campaign runtime is connected to MetaLayerFlow")
		failures += 1
	else:
		var screen = flow.get_node("HomebaseScreen")
		var accepted: Dictionary = screen.request_operation("accept_job", {"job_id": "satellite_recovery", "request_id": "runtime-accept"})
		if not accepted.get("ok", false):
			printerr("FAIL: Real operation bridge accepts campaign command")
			failures += 1
		if not flow.get_singleplayer_snapshot().campaign.accepted_job_ids.has("satellite_recovery"):
			printerr("FAIL: Accepted job appears in durable runtime snapshot")
			failures += 1
		if flow.get("_active_mission") != null:
			printerr("FAIL: Accepting job starts no mission")
			failures += 1
		flow.call("_show_homebase")
		if not flow.get_singleplayer_snapshot().campaign.accepted_job_ids.has("satellite_recovery"):
			failures += 1
	flow.queue_free()
	await process_frame
	print("SINGLEPLAYER_RUNTIME failed=", failures)
	quit(0 if failures == 0 else 1)
