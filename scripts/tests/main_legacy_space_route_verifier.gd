extends SceneTree

const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var _passed: int = 0
var _failed: int = 0
var _sequence: int = 0
var _owner: RefCounted

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: ", label)

func _command(operation: String, payload: Dictionary = {}, trusted: bool = false, request_id: String = "") -> Dictionary:
	_sequence += 1
	return _owner.call("apply_command", {"contract_category": "singleplayer_space_travel", "operation": operation, "payload": payload, "request_id": request_id if not request_id.is_empty() else "travel-test:%d" % _sequence}, {"runtime_authorized": trusted})

func _snapshot() -> Dictionary:
	return _owner.call("get_snapshot")

func _point_close(actual: Array, expected: Array) -> bool:
	return is_equal_approx(float(actual[0]), float(expected[0])) and is_equal_approx(float(actual[1]), float(expected[1]))

func _run() -> void:
	var script: GDScript = load("res://scripts/core/singleplayer_space_travel_state.gd")
	if script == null:
		_check(false, "Authoritative space-travel owner exists")
		_finish()
		return
	_owner = script.new()
	_check(bool(_owner.call("configure").get("ok", false)), "System definitions configure")
	var initial: Dictionary = _snapshot()
	_check(initial.phase == "grounded" and initial.location_id == "homebase", "Initial ship is on moon homebase")
	_check(Dictionary(initial.bodies).size() == 7 and initial.bodies.has_all(["sun", "planet", "glut_1a", "glut_1b", "moon", "glut_2", "polisa"]), "The system exposes Glut, its planets, moons and Polisa")
	_check(initial.orbits.moon_orbit.position == [0.685546875, 0.54296875] and initial.orbits.planet_orbit.position == [0.755859375, 0.38671875], "Legacy default orbit positions are data-owned")
	_check(initial.location_orbits == {"homebase": "moon_orbit", "satellite_crash": "glut_1a_orbit", "trade_outpost": "glut_1b_orbit", "fortified_outpost":"planet_orbit", "distress_orbit":"planet_orbit", "polisa":"polisa_orbit"}, "Authored locations keep their canonical body association")
	_check(float(initial.duration_seconds) == 3.0, "Quantum jumps take three seconds")
	_check(not _command("start_quantum", {"craft_id": "ship", "target_orbit_id": "planet_orbit"}).ok, "Cannot quantum from ground")
	_check(not _command("launch_to_orbit", {"craft_id": "ship"}).ok, "UI cannot authorize takeoff")
	_check(not _command("launch_to_orbit", {"craft_id": ""}, true).ok, "Empty craft rejected")
	_check(_snapshot() == initial, "Rejected commands preserve entire snapshot")
	var launch: Dictionary = _command("launch_to_orbit", {"craft_id": "ship"}, true, "launch-once")
	_check(launch.ok and _snapshot().phase == "orbit" and _snapshot().orbit_id == "moon_orbit", "Trusted takeoff reaches moon orbit")
	var launched: Dictionary = _snapshot()
	_check(_command("launch_to_orbit", {"craft_id": "ship"}, true, "launch-once").get("replayed", false) and _snapshot() == launched, "Same takeoff request replays without mutation")
	_check(not _command("launch_to_orbit", {"craft_id": "other"}, true, "launch-once").ok, "Reusing request ID with other payload rejected")
	_check(not _command("launch_to_orbit", {"craft_id": "other"}, true).ok, "Second craft cannot replace active trip")
	_check(not _command("start_quantum", {"craft_id": "ship", "target_orbit_id": "moon_orbit"}).ok, "Current orbit is not a new trip")
	_check(not _command("start_quantum", {"craft_id": "ship", "target_orbit_id": "unknown"}).ok, "Unknown orbit rejected")
	_check(not _command("start_quantum", {"craft_id": "ship", "target_orbit_id": "planet_orbit_sector_01"}).ok, "Future encounter marker is not an active jump destination")
	_check(not _command("start_quantum", {"craft_id": "other", "target_orbit_id": "planet_orbit"}).ok, "Another craft cannot drive active ship")
	_check(_command("start_quantum", {"craft_id": "ship", "target_orbit_id": "planet_orbit"}, false, "first-jump").ok, "Target click begins quantum trip")
	_check(_command("start_quantum", {"craft_id": "ship", "target_orbit_id": "planet_orbit"}, false, "first-jump").get("replayed", false), "Identical jump replays once")
	_check(_command("start_quantum", {"craft_id": "ship", "target_orbit_id": "planet_orbit", "target_orbit_marker_id": "orbit_2"}, false, "first-jump").get("reason") == "request_id_conflict", "Changing a marker on a retried request is rejected")
	_check(_snapshot().phase == "quantum" and _snapshot().orbit_id == "", "Travelling ship is between orbits")
	_check(not _command("start_quantum", {"craft_id": "ship", "target_orbit_id": "moon_orbit"}).ok, "Changing target requires explicit abort")
	var moving: Dictionary = _snapshot()
	_check(not _command("advance", {"delta_seconds": 1.0}).ok and _snapshot() == moving, "UI cannot advance simulation")
	for invalid_delta in [-1.0, NAN, INF, 61.0, "1"]:
		_check(not _command("advance", {"delta_seconds": invalid_delta}, true).ok, "Invalid simulation delta rejected: %s" % str(invalid_delta))
	_check(_snapshot() == moving, "Invalid deltas do not corrupt travel")
	_check(_command("advance", {"delta_seconds": 1.0}, true, "tick-one").ok, "Trusted tick advances trip")
	var one_second: Dictionary = _snapshot()
	_check(_command("advance", {"delta_seconds": 1.0}, true, "tick-one").get("replayed", false) and _snapshot() == one_second, "Explicit tick request ID replays without advancing twice")
	_check(is_equal_approx(float(one_second.progress), 1.0 / 3.0), "Progress uses actual elapsed duration")
	var expected_position := GRID.route_point(GRID.pair(one_second.origin_position), GRID.pair(one_second.route_control), GRID.pair(one_second.route_destination), 1.0 / 3.0)
	_check(GRID.pair(one_second.position).is_equal_approx(expected_position), "Ship position is interpolated on its actual route")
	_check(_command("abort_quantum", {"craft_id": "ship"}, false, "abort-once").ok, "Quantum can be aborted")
	var stopped: Dictionary = _snapshot()
	_check(stopped.phase == "stopped" and stopped.orbit_id == "" and stopped.position == one_second.position, "Abort keeps exact reached position")
	_check(_command("abort_quantum", {"craft_id": "ship"}, false, "abort-once").get("replayed", false) and _snapshot() == stopped, "Duplicate abort is idempotent")
	_check(not _command("begin_approach", {"craft_id": "ship", "location_id": "satellite_crash"}, true).ok, "Cannot load an orbit location from midway")
	_check(_command("advance", {"delta_seconds": 2.0}, true).ok and _snapshot() == stopped, "Stopped ship remains still on later ticks")
	_check(_command("start_quantum", {"craft_id": "ship", "target_orbit_id": "moon_orbit"}).ok, "Aborted trip may choose another target")
	_check(_snapshot().origin_position == stopped.position and _snapshot().position == stopped.position and float(_snapshot().progress) == 0.0, "Restart starts at reached position without teleport")
	_check(_command("advance", {"delta_seconds": 30.0}, true).ok, "Long valid tick clamps arrival")
	_check(_snapshot().phase == "orbit" and _snapshot().orbit_id == "moon_orbit" and _point_close(_snapshot().position, initial.orbits.moon_orbit.position) and float(_snapshot().progress) == 1.0, "Exact moon arrival")
	_check(not _command("begin_approach", {"craft_id": "ship", "location_id": "trade_outpost"}, true).ok, "Planet location unavailable from moon orbit")
	_check(_command("start_quantum", {"craft_id": "ship", "target_orbit_id": "planet_orbit"}).ok, "Another jump can start after arrival")
	_check(_command("advance", {"delta_seconds": 3.0}, true).ok, "Full jump completes")
	_check(_snapshot().phase == "orbit" and _snapshot().orbit_id == "planet_orbit" and _point_close(_snapshot().position, initial.orbits.planet_orbit.position), "Exact planet arrival")
	_check(not _command("land_homebase", {"craft_id": "ship"}, true).ok, "Homebase cannot be landed at planet")
	_check(not _command("begin_approach", {"craft_id": "ship", "location_id": "fortified_outpost"}).ok, "UI cannot bypass authorized map handoff")
	_check(not _command("begin_approach", {"craft_id": "ship", "location_id": "unknown"}, true).ok, "Unknown map location rejected")
	_check(_command("begin_approach", {"craft_id": "ship", "location_id": "fortified_outpost"}, true).ok, "Explicit authorized approach enters the planetary outpost")
	_check(_snapshot().phase == "approach" and _snapshot().location_id == "fortified_outpost", "Approach remains distinct from surface")
	_check(not _command("start_quantum", {"craft_id": "ship", "target_orbit_id": "moon_orbit"}).ok, "No quantum during map handoff")
	_check(_command("finish_approach", {"craft_id": "ship"}, true).ok and _snapshot().phase == "surface", "Loaded map confirms surface phase")
	_check(not _command("enter_orbit", {"craft_id": "ship"}).ok, "UI cannot fabricate return to orbit")
	_check(_command("enter_orbit", {"craft_id": "ship"}, true).ok and _snapshot().orbit_id == "planet_orbit", "Real surface exit returns to planet orbit")
	_check(_command("begin_approach", {"craft_id": "ship", "location_id": "distress_orbit"}, true).ok, "Other planet location uses same canonical orbit")
	_check(_command("enter_orbit", {"craft_id": "ship"}, true).ok, "Failed approach may return to source orbit")
	_check(_command("start_quantum", {"craft_id": "ship", "target_orbit_id": "moon_orbit"}).ok, "Homeward quantum begins")
	_check(_command("advance", {"delta_seconds": 3.0}, true).ok, "Homeward quantum completes")
	_check(not _command("land_homebase", {"craft_id": "ship"}).ok, "Home landing requires runtime handoff")
	_check(_command("land_homebase", {"craft_id": "ship"}, true).ok, "Moon orbit permits real home landing")
	_check(_snapshot().phase == "grounded" and _snapshot().location_id == "homebase", "Round trip returns to grounded base")
	var copy: Dictionary = _snapshot()
	copy.position[0] = 999
	copy.orbits.clear()
	_check(_point_close(_snapshot().position, initial.orbits.moon_orbit.position) and not Dictionary(_snapshot().orbits).is_empty(), "Snapshots cannot mutate owner")
	for bad_command in [{}, {"contract_category": "wrong", "operation": "launch_to_orbit", "payload": {}, "request_id": "bad"}, {"contract_category": "singleplayer_space_travel", "operation": "launch_to_orbit", "payload": [], "request_id": "bad"}]:
		_check(not _owner.call("apply_command", bad_command, {"runtime_authorized": true}).ok, "Malformed command rejected")
	var sim: Node = load("res://scripts/core/simulation_root.gd").new()
	sim.call("configure_singleplayer_owners", null, null, null, _owner)
	var routed: Dictionary = sim.call("request_singleplayer_command", {"contract_category": "singleplayer_space_travel", "operation": "launch_to_orbit", "payload": {"craft_id": "ship"}, "request_id": "sim-launch"}, {"runtime_authorized": true})
	_check(routed.ok and _snapshot().phase == "orbit", "SimulationRoot routes new owner category")
	var queued: Dictionary = {"contract_category": "singleplayer_space_travel", "operation": "land_homebase", "payload": {"craft_id": "ship", "runtime_authorized": true}, "request_id": "fake-landing"}
	sim.call("_apply_command", queued, 0.016)
	_check(_snapshot().phase == "orbit", "Queued UI payload cannot forge lifecycle authority")
	sim.free()
	_finish()

func _finish() -> void:
	print("SPACE_TRAVEL_STATE passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)
