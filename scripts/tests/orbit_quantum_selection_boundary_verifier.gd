extends SceneTree
## A destination change during the visible approach may not replace the map
## whose departure/fuel/job binding has already been authorized.

var _flow: Node
var _screen: Control
var _runtime: Node
var _craft_id: String
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: ", label)

func _request(operation: String, data: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = data.duplicate(true)
	payload["craft_id"] = _craft_id
	return _screen.call("request_operation", operation, payload)

func _snapshot() -> Dictionary:
	return _runtime.call("get_snapshot")

func _space() -> Dictionary:
	return Dictionary(_snapshot().get("space_travel", {}))

func _wait(predicate: Callable, milliseconds: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await physics_frame
	return false

func _run() -> void:
	_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_craft_id = String(Dictionary(_screen.call("get_operations_snapshot").get("selected_craft", {})).get("id", ""))
	_check(_snapshot().mode == "skirmish", "Race exercises ordinary Skirmish visits without tutorial locks")
	_check(_request("accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Actual satellite job accepted")
	_check(_request("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Grounded destination selection stays compatible")
	_screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var launch_craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	var payload_before: Array = Array(launch_craft.get("payload_fireteam_ids", [])).duplicate()
	var pilot_before: String = String(launch_craft.get("pilot_id", ""))
	_check(not bool(launch_craft.get("busy", true)) and not payload_before.is_empty() and not pilot_before.is_empty(), "Grounded screen exposes the ready actual boarded craft")
	if not _request("start").get("ok", false):
		_check(false, "Boarded craft launches")
		await _finish()
		return
	var orbital_craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_check(bool(orbital_craft.get("busy", false)), "Immediately after takeoff the existing homebase craft snapshot is busy")
	var unboard: Dictionary = _request("unboard", {"fireteam_id": String(payload_before[0])})
	var clear_pilot: Dictionary = _request("pilot", {"unit_id": ""})
	_check(not bool(unboard.get("ok", false)), "Stale homebase command cannot unboard a crew already in orbit")
	_check(not bool(clear_pilot.get("ok", false)), "Stale homebase command cannot clear an airborne pilot")
	var locked_craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_check(Array(locked_craft.get("payload_fireteam_ids", [])) == payload_before and String(locked_craft.get("pilot_id", "")) == pilot_before, "Airborne payload and pilot retain their real prelaunch identities")
	if bool(unboard.get("ok", false)) or bool(clear_pilot.get("ok", false)):
		await _finish()
		return
	_check(not _request("select_destination", {"location_id": "trade_outpost"}).get("ok", false), "Surface destination selection is blocked in moon orbit")
	_request("space_start_quantum", {"target_orbit_id": "planet_orbit"})
	_check(not _request("select_destination", {"location_id": "trade_outpost"}).get("ok", false), "Surface destination selection is blocked during quantum")
	if not await _wait(func(): return _space().phase == "orbit" and _space().orbit_id == "planet_orbit", 5000):
		_check(false, "Normal runtime reaches planet orbit")
		await _finish()
		return
	# Reassert the original destination so the race is exercised even on the
	# red baseline where the earlier airborne selections were still accepted.
	_check(_request("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Planet orbit permits actual target selection")
	_request("mission", {"mission_id": "trade_outpost_visit"})
	var fuel_before_drift: Dictionary = Dictionary(_snapshot().supply.fuel_by_craft_id).duplicate(true)
	var drifted: Dictionary = _request("space_begin_approach", {"location_id": "satellite_crash"})
	_check(not bool(drifted.get("ok", false)), "Mismatched legacy mission selection cannot authorize a different location")
	_check(_snapshot().supply.fuel_by_craft_id == fuel_before_drift and _flow.get("_active_mission") == null, "Mismatched selection rejection has no fuel or map side effects")
	if bool(drifted.get("ok", false)):
		await _finish()
		return
	_request("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	var before_fuel: float = float(_snapshot().supply.fuel_by_craft_id[_craft_id])
	var approach: Dictionary = _request("space_begin_approach", {"location_id": "satellite_crash"})
	_check(bool(approach.get("ok", false)) and _flow.get("_active_mission") == null, "Actual authorized approach opens its visible pending window")
	var attempted: Dictionary = _request("select_destination", {"location_id": "trade_outpost"})
	_check(not bool(attempted.get("ok", false)), "Changing location is rejected throughout pending approach")
	_check(String(_snapshot().campaign.selected_location_id) == "satellite_crash", "Pending approach retains authorized location ID")
	_request("mission", {"mission_id": "trade_outpost_visit"})
	_check(String(_flow.get("_selected_mission_id")) == "satellite_recovery", "Raw legacy mission-selection callback cannot replace pending approach")
	var departure: Dictionary = _snapshot().campaign.departures_by_craft_id.get(_craft_id, {})
	_check(String(departure.get("destination_location_id", "")) == "satellite_crash" and String(departure.get("job_id", "")) == "satellite_recovery", "Departure remains bound to exact authorized location and job")
	_check(is_equal_approx(float(_snapshot().supply.fuel_by_craft_id[_craft_id]), before_fuel - 12.0), "Race consumes exactly the satellite route fuel once")
	if await _wait(func(): return _flow.get("_active_mission") != null, 12000):
		var setup: Node = _flow.get("_active_mission").get_node("MissionSetup")
		_check(String(setup.get("map_file_path")) == "res://maps/satellite_crash_site.json", "Loaded map matches immutable authorized satellite departure")
		_check(String(setup.get("scenario_file_path")) == "res://data/mission_scenarios/satellite_recovery.json", "Loaded scenario matches immutable authorized satellite job")
	else:
		_check(false, "Actual authorized map eventually loads")
	await _finish()

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("ORBIT_QUANTUM_SELECTION_BOUNDARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)
