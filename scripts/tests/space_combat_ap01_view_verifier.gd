extends "res://scripts/tests/orbit_quantum_flow_verifier.gd"

func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	var craft: Dictionary = _screen.call("get_operations_snapshot").selected_craft
	_craft_id = String(craft.id)
	_check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery"}).get("ok", false), "Real campaign accepts satellite job")
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	if not _board_real_crew(personnel):
		await _finish()
		return
	if not _check(_screen.call("request_operation", "start", {"craft_id":_craft_id}).get("ok", false), "Real boarding allows launch"):
		await _finish()
		return
	if not _check(_op("space_start_quantum", {"target_orbit_id":"planet_orbit"}).get("ok", false), "Real warp command starts"):
		await _finish()
		return
	_check(await _wait(func(): return float(_space().get("progress", 0.0)) > 0.05, 4000), "Warp advances in star view")
	var before: float = float(_space().get("progress", 0.0))
	_check(_flow.call("open_location_view", "homebase").get("ok", false), "Actual homebase view opens")
	_check(await _wait(func(): return float(_space().get("progress", 0.0)) > before + 0.05, 4000), "Warp continues while homebase is viewed")
	_check(_flow.call("open_location_view", "star_map").get("ok", false), "Actual star view reopens")
	_check(_op("space_abort_quantum").get("ok", false), "Abort remains available after view change")
	var stopped: Array = _space().position
	await create_timer(0.15).timeout
	_check(_space().position == stopped, "Abort preserves position with ongoing physics frames")
	await _finish()
