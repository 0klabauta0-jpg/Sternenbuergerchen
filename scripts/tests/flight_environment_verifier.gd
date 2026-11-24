extends SceneTree
const FLIGHT = preload("res://scripts/tactical/space_flight_resolver.gd")
const GUIDANCE = preload("res://scripts/tactical/space_guidance_resolver.gd")
const ENV = preload("res://scripts/tactical/flight_environment.gd")

var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FLIGHT_ENVIRONMENT FAIL: ", label)

func _hull() -> Dictionary:
	return {"main_thrust":2.0, "reverse_thrust":1.0, "side_thrust":1.2, "turn_acceleration":0.6}

func _fixed_poses() -> Array:
	return [
		{"position_plane":Vector2(0, 0), "velocity_plane":Vector2(0, 0), "heading_rad":0.0, "angular_velocity":0.0, "target":Vector2(30, 10)},
		{"position_plane":Vector2(3.5, -2.25), "velocity_plane":Vector2(1.5, 0.75), "heading_rad":0.7, "angular_velocity":0.1, "target":Vector2(-20, 15)},
		{"position_plane":Vector2(-10, 4), "velocity_plane":Vector2(-0.3, 2.2), "heading_rad":-1.9, "angular_velocity":-0.2, "target":Vector2(-10.5, 4.25)},
		{"position_plane":Vector2(50, 50), "velocity_plane":Vector2(3.9, -1.1), "heading_rad":3.0, "angular_velocity":0.0, "target":Vector2(0, 0)},
		{"position_plane":Vector2(1, 1), "velocity_plane":Vector2(0.05, 0.0), "heading_rad":2.2, "angular_velocity":0.4, "target":Vector2(2, 1.5)},
	]

func _pose_hash(pose: Dictionary, with_area: bool) -> String:
	var flight := {"position_plane":pose.position_plane, "velocity_plane":pose.velocity_plane, "mass":1.0, "heading_rad":pose.heading_rad, "angular_velocity":pose.angular_velocity, "assist_mode":"decoupled"}
	if with_area:
		flight["space_area_id"] = "orbit_approach:moon"
	var power := {"thrust_fraction":1.0}
	var guided: Dictionary = GUIDANCE.resolve(flight, {"target_plane":pose.target}, _hull(), power)
	var stepped: Dictionary = FLIGHT.step(flight, guided.get("intent", {}), _hull(), power, 0.1)
	check(guided.ok and float(guided.intent.turn) == 0.0, "space turn is 0.0")
	return var_to_bytes([guided, stepped]).hex_encode().sha256_text()

## Hashes captured from the unchanged space code before the atmosphere branch existed.
const SPACE_POSE_HASHES := [
	"e0d2b8d694f83f7a64ebc87e867fbcd17cf858828441fd8f62bd0b6056d41d38",
	"a095980d0d0c5ef66b6e3d3ddd528124e88b5790c506d9d3f78f940a8cd60477",
	"4a57ac9d2b16abc99034eef8479c33a96e2be42849bbdcce1f78f448662d7c5a",
	"37296186f4513ac572488b0599f5a557f8006b1f1436e275d6a1d72f1bbdc300",
	"947946b36576654e8134887e0779069efe0b9000da838f405b206b53f8b695e6",
]

func _fly_to_far_target(area_id: String) -> float:
	var environment: String = ENV.environment_for_area(area_id)
	var flight := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2.ZERO, "mass":1.0, "heading_rad":0.0, "angular_velocity":0.0, "space_area_id":area_id}
	var power := {"thrust_fraction":1.0}
	var top := 0.0
	for i in 600:
		var guided: Dictionary = GUIDANCE.resolve(flight, {"target_plane":Vector2(100, 0)}, _hull(), power)
		if not guided.ok:
			return -1.0
		var stepped: Dictionary = FLIGHT.step(flight, guided.intent, _hull(), power, 0.1, environment)
		if not stepped.ok:
			return -2.0
		for key in ["position_plane", "velocity_plane", "heading_rad", "angular_velocity"]:
			flight[key] = stepped[key]
		top = maxf(top, flight.velocity_plane.length())
	return top

## Runs resolve+step in the atmosphere; returns {flight, turn (last intent), heading_at_40}.
func _air_run(steps: int, goal: Dictionary, mass: float = 1.0, torque: float = 0.6, omega: float = 0.0, start: Dictionary = {}) -> Dictionary:
	var hull := _hull()
	hull["turn_acceleration"] = torque
	var power := {"thrust_fraction":1.0}
	var air := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2.ZERO, "mass":mass, "heading_rad":0.0, "angular_velocity":omega, "space_area_id":"atmosphere:x"}
	if not start.is_empty():
		air = start.duplicate()
	var last_turn := 0.0
	var heading_at_40 := 0.0
	for i in steps:
		var g: Dictionary = goal.duplicate()
		if not g.has("target_plane"):
			g["target_plane"] = air.position_plane
		var guided: Dictionary = GUIDANCE.resolve(air, g, hull, power)
		last_turn = float(guided.intent.turn)
		var stepped: Dictionary = FLIGHT.step(air, guided.intent, hull, power, 0.05, "atmosphere")
		for key in ["position_plane", "velocity_plane", "heading_rad", "angular_velocity"]:
			air[key] = stepped[key]
		if i == 39:
			heading_at_40 = air.heading_rad
	return {"flight":air, "turn":last_turn, "heading_at_40":heading_at_40}

func _initialize() -> void:
	var power := {"thrust_fraction":1.0}
	# 1: one second of full forward thrust from rest.
	var rest := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2.ZERO, "mass":1.0, "heading_rad":0.0, "angular_velocity":0.0}
	var push := {"forward":1.0, "lateral":0.0, "turn":0.0}
	var s1: Dictionary = FLIGHT.step(rest, push, _hull(), power, 1.0, "space")
	var a1: Dictionary = FLIGHT.step(rest, push, _hull(), power, 1.0, "atmosphere")
	check(is_equal_approx(s1.velocity_plane.x, 2.0), "case1 space speed 2.0")
	check(is_equal_approx(a1.velocity_plane.x, 1.4), "case1 atmosphere speed 1.4")
	# 2: top speed under guidance towards a target 100 fields away.
	var top_space := _fly_to_far_target("orbit_approach:moon")
	var top_air := _fly_to_far_target("atmosphere:x")
	check(absf(top_space - 4.0) <= 0.05, "case2 space top speed 4.0, got %s" % top_space)
	check(absf(top_air - 2.4) <= 0.05, "case2 atmosphere top speed 2.4, got %s" % top_air)
	# 3: space stays bit-identical on five fixed poses, turn stays 0.0.
	var poses := _fixed_poses()
	for i in poses.size():
		check(_pose_hash(poses[i], false) == SPACE_POSE_HASHES[i], "case3 pose %d without area" % i)
		check(_pose_hash(poses[i], true) == SPACE_POSE_HASHES[i], "case3 pose %d with space area" % i)
	# 4: atmosphere nose turns towards face_plane (0,5) relative, i.e. +PI/2.
	var air := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2.ZERO, "mass":1.0, "heading_rad":0.0, "angular_velocity":0.0, "space_area_id":"atmosphere:x"}
	for i in 200:
		var guided: Dictionary = GUIDANCE.resolve(air, {"target_plane":air.position_plane, "face_plane":Vector2(0, 5)}, _hull(), power)
		var stepped: Dictionary = FLIGHT.step(air, guided.intent, _hull(), power, 0.05, "atmosphere")
		for key in ["position_plane", "velocity_plane", "heading_rad", "angular_velocity"]:
			air[key] = stepped[key]
	check(absf(wrapf(air.heading_rad - PI / 2.0, -PI, PI)) < deg_to_rad(10.0), "case4 nose within 10 degrees, heading %s" % air.heading_rad)
	# 5: weapon range.
	check(is_equal_approx(ENV.weapon_range(10.0, "atmosphere:x"), 8.0), "case5 atmosphere range 8.0")
	check(is_equal_approx(ENV.weapon_range(10.0, "orbit_approach:moon"), 10.0), "case5 space range 10.0")
	# 6: unknown environment falls back to 1.0 everywhere.
	var fallback: Dictionary = ENV.factors("unbekannt")
	check(fallback.get("speed_factor") == 1.0 and fallback.get("acceleration_factor") == 1.0 and fallback.get("weapon_range_factor") == 1.0, "case6 unknown environment is 1.0")
	var atmosphere: Dictionary = ENV.factors("atmosphere")
	check(atmosphere.get("speed_factor") == 0.6 and atmosphere.get("acceleration_factor") == 0.7 and atmosphere.get("weapon_range_factor") == 0.8, "case6 atmosphere factors from file")
	# 7 (W1): atmosphere without face_plane never turns the nose by itself, even when flying sideways.
	var cross: Dictionary = _air_run(200, {"target_plane":Vector2(0, 50)})
	check(cross.flight.position_plane.y > 5.0, "case7 ship actually flew")
	check(cross.flight.heading_rad == 0.0 and cross.flight.angular_velocity == 0.0, "case7 nose stays 0, heading %s" % cross.flight.heading_rad)
	# 7b: a running spin is braked to a stop and the nose stays put afterwards.
	var spin: Dictionary = _air_run(200, {}, 1.0, 0.6, 1.0)
	check(absf(spin.flight.angular_velocity) < 0.001, "case7b spin decays, omega %s" % spin.flight.angular_velocity)
	var heading_stopped: float = spin.flight.heading_rad
	var after: Dictionary = _air_run(100, {}, 1.0, 0.6, 0.0, spin.flight)
	check(absf(after.flight.heading_rad - heading_stopped) < 0.001, "case7b nose stays after braking")
	# 8 (K1): dead zone after aiming, nose stays within 2 degrees and turn ends at exactly 0.0.
	var aimed: Dictionary = _air_run(200, {"face_plane":Vector2(0, 5)})
	var held: Dictionary = _air_run(200, {"face_plane":Vector2(0, 5)}, 1.0, 0.6, 0.0, aimed.flight)
	check(absf(wrapf(held.flight.heading_rad - PI / 2.0, -PI, PI)) < deg_to_rad(2.0), "case8 nose holds within 2 degrees, heading %s" % held.flight.heading_rad)
	check(held.turn == 0.0, "case8 turn is 0.0 at the end, got %s" % held.turn)
	# 9 (K3): torque 0, mass 2.0, goal on own position.
	var no_torque: Dictionary = _air_run(50, {"face_plane":Vector2(0, 5)}, 1.0, 0.0)
	check(no_torque.turn == 0.0 and no_torque.flight.heading_rad == 0.0, "case9 torque 0 gives turn 0.0")
	var heavy: Dictionary = _air_run(400, {"face_plane":Vector2(0, 5)}, 2.0)
	var light: Dictionary = _air_run(400, {"face_plane":Vector2(0, 5)}, 1.0)
	check(absf(wrapf(heavy.flight.heading_rad - PI / 2.0, -PI, PI)) < deg_to_rad(10.0), "case9 mass 2.0 reaches the nose, heading %s" % heavy.flight.heading_rad)
	check(heavy.heading_at_40 < light.heading_at_40, "case9 heavier ship turns slower")
	var self_goal: Dictionary = _air_run(20, {"face_plane":Vector2.ZERO})
	check(self_goal.turn == 0.0 and not is_nan(self_goal.flight.heading_rad) and not is_nan(self_goal.turn), "case9 goal on own position, turn 0.0, no NaN")
	print("FLIGHT_ENVIRONMENT passed=", passed, " failed=", failed)
	quit(0 if failed == 0 else 1)
