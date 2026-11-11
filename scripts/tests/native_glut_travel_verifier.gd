extends SceneTree
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _command(owner, operation: String, payload: Dictionary = {}) -> Dictionary:
	if operation != "advance":
		payload["craft_id"] = "probe"
	return owner.apply_command({"contract_category": "singleplayer_space_travel", "operation": operation, "payload": payload}, {"runtime_authorized": true})

func _run() -> void:
	var owner = TRAVEL.new()
	_check(owner.configure().ok, "native definition validates")
	var expected := {"satellite_crash": "glut_1a_orbit", "trade_outpost": "glut_1b_orbit",
		"fortified_outpost": "planet_orbit", "homebase": "moon_orbit", "distress_orbit": "planet_orbit"}
	var snapshot: Dictionary = owner.get_snapshot()
	_check(snapshot.get("system_version") == 2 and snapshot.location_orbits == expected, "v2 location-orbit mapping")
	_check(_command(owner, "launch_to_orbit").ok and owner.get_snapshot().orbit_id == "moon_orbit", "launch preserves home orbit ID")
	for location in ["satellite_crash", "trade_outpost", "fortified_outpost"]:
		var target: String = expected[location]
		_check(_command(owner, "start_quantum", {"target_orbit_id": target}).ok, "jump to " + target)
		snapshot = owner.get_snapshot()
		var route: Array = snapshot.get("route_hexes", [])
		_check(route.size() > 2, "route reports actual cells")
		for i in range(1, route.size()):
			if not HEX.are_neighbors(route[i - 1], route[i]):
				_check(false, "non-adjacent route step")
				break
		var start := GRID.pair(snapshot.origin_position)
		var control := GRID.pair(snapshot.route_control)
		var finish := GRID.pair(snapshot.route_destination)
		var previous_heading := float(snapshot.heading)
		var turn_sign := 0.0
		var smooth := true
		for index in range(12):
			_command(owner, "advance", {"delta_seconds": 1.0 / 12.0})
			var advancing: Dictionary = owner.get_snapshot()
			var expected_position := GRID.route_point(start, control, finish, float(advancing.progress))
			var turn := angle_difference(previous_heading, float(advancing.heading))
			if not is_zero_approx(turn):
				smooth = smooth and (turn_sign == 0.0 or signf(turn) == turn_sign)
				turn_sign = signf(turn)
			smooth = smooth and GRID.pair(advancing.position).is_equal_approx(expected_position)
			previous_heading = float(advancing.heading)
		_check(smooth, "route line and ship share a monotone smooth turn")
		var stopped: Array = owner.get_snapshot().position
		_check(_command(owner, "abort_quantum").ok and owner.get_snapshot().position == stopped, "abort holds the current position")
		_check(_command(owner, "start_quantum", {"target_orbit_id": target}).ok, "restart from held position")
		_command(owner, "advance", {"delta_seconds": 3.0})
		_check(owner.get_snapshot().orbit_id == target, "arrived at " + target)
		_check(_command(owner, "begin_approach", {"location_id": location}).ok, "approach uses matching orbit")
		_check(_command(owner, "finish_approach").ok and _command(owner, "enter_orbit").ok, "return through surface exit")
		_check(owner.get_snapshot().orbit_id == target, "return uses the same orbit")
	_command(owner, "start_quantum", {"target_orbit_id": "moon_orbit"})
	_command(owner, "advance", {"delta_seconds": 3.0})
	_check(_command(owner, "land_homebase").ok, "land in existing home orbit")
	quit(1 if failures else 0)
