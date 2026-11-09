extends SceneTree
## Catches premature mission creation, wrong abort position, and homecoming before landing.
var _passed := 0
var _failed := 0
var _flow: Node
var _screen: Control
var _runtime: Node
var _craft_id := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	var craft: Dictionary = _screen.call("get_operations_snapshot").selected_craft
	_craft_id = String(craft.id)
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Real campaign accepts satellite job before departure")
	_screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var before: Dictionary = _runtime.call("get_snapshot")
	var launch: Dictionary = _screen.call("request_operation", "start", {"craft_id": _craft_id})
	if not _check(bool(launch.get("ok", false)), "Boarded craft can lift off without a selected planetary location"):
		print("LAUNCH_RESULT:", launch)
		await _finish()
		return
	var space: Dictionary = _space()
	if not _check(String(space.get("orbit_id", "")) == "moon_orbit", "Actual launch reaches moon orbit"):
		await _finish()
		return
	_check(_flow.get("_active_mission") == null and int(_flow.get("_active_mission_started_at_msec")) == 0, "Liftoff starts neither mission scene nor timer")
	_check(String(_runtime.call("get_snapshot").campaign.jobs.satellite_recovery.status) == "accepted", "Liftoff does not activate accepted job")
	_check(_runtime.call("get_snapshot").supply.fuel_by_craft_id == before.supply.fuel_by_craft_id, "Orbit departure does not charge an unselected route")
	_check(not _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime).get("ok", false), "Orbit cannot write a home checkpoint")
	_check(_op("space_start_quantum", {"target_orbit_id": "planet_orbit"}).get("ok", false), "Planet click starts actual quantum")
	if not await _wait(func(): return float(_space().get("progress", 0.0)) >= 0.2, 4000):
		_check(false, "Real-time quantum advances")
		await _finish()
		return
	_check(_op("space_abort_quantum").get("ok", false), "Actual quantum abort accepts")
	var stopped: Array = _space().position
	await create_timer(0.2).timeout
	_check(_space().position == stopped and String(_space().phase) == "stopped", "Abort keeps reached position while real frames continue")
	_check(not _op("space_begin_approach", {"location_id": "satellite_crash"}).get("ok", false), "Midflight position cannot enter an orbital location")
	_check(_op("space_start_quantum", {"target_orbit_id": "planet_orbit"}).get("ok", false), "Same target restarts from stopped position")
	_check(_space().origin_position == stopped, "Restart origin equals actual abort position")
	_check(await _wait(func(): return String(_space().get("orbit_id", "")) == "planet_orbit", 5000), "Short restarted jump arrives in planet orbit")
	_check(not _op("space_begin_approach", {"location_id": "trade_outpost"}).get("ok", false), "Tutorial trade lock is enforced at planetary approach")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Orbit permits selection of accepted satellite location")
	_check(_flow.get("_active_mission") == null, "Location selection alone does not load its map")
	_check(_op("space_begin_approach", {"location_id": "satellite_crash"}).get("ok", false), "Explicit approach authorizes real location")
	_check(_flow.get("_active_mission") == null and String(_space().phase) == "approach", "Visible approach phase precedes map instantiation")
	_check(not _op("space_begin_approach", {"location_id": "satellite_crash"}).get("ok", false), "Repeated approach cannot launch twice")
	_check(await _wait(func(): return _flow.get("_active_mission") != null, 10000), "Approach eventually loads actual mission")
	if _flow.get("_active_mission") != null:
		var setup: Node = _flow.get("_active_mission").get_node("MissionSetup")
		_check(String(setup.get("map_file_path")) == "res://maps/satellite_crash_site.json", "Approach uses the exact existing satellite map")
		_check(String(setup.get("scenario_file_path")) == "res://data/mission_scenarios/satellite_recovery.json", "Approach retains existing recovery scenario")
		var fuel_after: Dictionary = _runtime.call("get_snapshot").supply.fuel_by_craft_id
		_check(is_equal_approx(float(fuel_after[_craft_id]), float(before.supply.fuel_by_craft_id[_craft_id]) - 12.0), "Repeated approach charges outbound route exactly once")
		_check(await _wait(func(): return Array(_flow.get("_pending_mission_craft_transfers")).is_empty(), 5000), "Actual orbital map handoff completes")
		var arrived_craft: Dictionary = {}
		for entry: Dictionary in Array(_runtime.call("get_snapshot").crafts):
			if String(entry.get("craft_id", "")) == _craft_id:
				arrived_craft = entry
		_check(not bool(arrived_craft.get("busy", true)), "Completed local handoff does not leave a surface craft locked as Quantum-busy")
	await _finish()

func _op(operation: String, payload: Dictionary = {}) -> Dictionary:
	var data := payload.duplicate(true)
	data["craft_id"] = _craft_id
	return _screen.call("request_operation", operation, data)

func _space() -> Dictionary:
	return _runtime.call("get_snapshot").get("space_travel", {})

func _wait(predicate: Callable, timeout_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await process_frame
	return false

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value

func _finish() -> void:
	_flow.queue_free()
	await process_frame
	await process_frame
	print("ORBIT_QUANTUM_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
