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
	# Narrow lifecycle fixture: exercise the real completion callback when a
	# craft returns without any objective result. This is not full-flight evidence.
	flow.set("_pending_mission_craft_transfers", [])
	flow.set("_aircraft_location_by_craft", {craft_id: "homebase"})
	flow.call("_finish_singleplayer_visit_if_returned")
	var snapshot: Dictionary = flow.get_singleplayer_snapshot()
	var closed: bool = flow.get("_active_mission") == null
	var failed: bool = String(snapshot.campaign.jobs.satellite_recovery.status) == "failed"
	var no_reward: bool = snapshot.campaign.completion_receipts.is_empty() and int(snapshot.supply.credits) == 500
	print("ABORTED_VISIT_RETURN closed=%s failed=%s no_reward=%s" % [closed, failed, no_reward])
	flow.queue_free()
	await process_frame
	quit(0 if closed and failed and no_reward else 1)
