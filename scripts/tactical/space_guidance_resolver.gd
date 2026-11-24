extends RefCounted
## Fixture guidance only: collision and formation are handled separately.
const FLIGHT_ENV = preload("res://scripts/tactical/flight_environment.gd")
## With face_plane: below this angle error and spin the turn command is exactly 0.0.
const AIM_DEADZONE_DEGREES := 1.0
const AIM_DEADZONE_SPIN := 0.02
## Target spin per radian of angle error close to the target (1/s).
const AIM_LINEAR_GAIN := 2.0

static func resolve(flight: Dictionary, goal: Dictionary, hull: Dictionary, power: Dictionary) -> Dictionary:
	if typeof(flight.get("position_plane")) != TYPE_VECTOR2 or typeof(flight.get("velocity_plane")) != TYPE_VECTOR2 or typeof(goal.get("target_plane")) != TYPE_VECTOR2:
		return {"ok":false, "reason":"invalid_state"}
	if not flight.position_plane.is_finite() or not flight.velocity_plane.is_finite() or not goal.target_plane.is_finite():
		return {"ok":false, "reason":"invalid_state"}
	for pair in [[flight,"mass"], [flight,"heading_rad"], [hull,"main_thrust"], [hull,"reverse_thrust"], [hull,"side_thrust"], [power,"thrust_fraction"]]:
		if pair[0].has(pair[1]) and (typeof(pair[0][pair[1]]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(pair[0][pair[1]]))):
			return {"ok":false, "reason":"invalid_parameters"}
	var mass := float(flight.get("mass", 0.0))
	var main := float(hull.get("main_thrust", 0.0))
	var reverse := float(hull.get("reverse_thrust", 0.0))
	var side := float(hull.get("side_thrust", 0.0))
	var fraction := clampf(float(power.get("thrust_fraction", 1.0)), 0.0, 1.0)
	if mass <= 0.0 or minf(main, minf(reverse, side)) <= 0.0 or fraction <= 0.0:
		return {"ok":false, "reason":"insufficient_thrust"}
	var displacement: Vector2 = goal.target_plane - flight.position_plane
	# A heavier fitted ship needs more distance to stop. Limit approach speed
	# using the weakest available translational brake, with margin for one tick
	# and diagonal steering near blocked gates.
	var braking_acceleration := minf(main, minf(reverse, side)) * fraction / mass
	var speed_cap := 5.0
	var atmosphere: bool = FLIGHT_ENV.environment_for_area(String(flight.get("space_area_id", ""))) == "atmosphere"
	var env_factors: Dictionary = {}
	if atmosphere:
		env_factors = FLIGHT_ENV.factors("atmosphere")
		braking_acceleration *= float(env_factors.acceleration_factor)
		speed_cap = 5.0 * float(env_factors.speed_factor)
	var safe_speed := sqrt(2.0 * braking_acceleration * displacement.length()) * 0.45
	var desired_velocity: Vector2 = (displacement.limit_length(speed_cap) * 0.8).limit_length(safe_speed)
	# Stronger velocity damping avoids overshooting a gate whose far edge is
	# immediately blocked by the body, including asymmetric ship thrusters.
	var desired_force: Vector2 = (desired_velocity - flight.velocity_plane) * (4.0 * mass)
	var axis := Vector2.from_angle(float(flight.get("heading_rad", 0.0)))
	var along := desired_force.dot(axis)
	var forward := along / ((main if along >= 0.0 else reverse) * fraction)
	var lateral := desired_force.dot(axis.orthogonal()) / (side * fraction)
	var controls := Vector2(forward, lateral).limit_length(1.0)
	var turn := _turn_command(flight, goal, torque_of(hull), fraction, mass, atmosphere, env_factors)
	# Atmosphere only flies coupled (step rejects decoupled there).
	return {"ok":true, "intent":{"forward":controls.x, "lateral":controls.y, "turn":turn, "assist_mode":"coupled" if atmosphere else "decoupled"}}

static func torque_of(hull: Dictionary) -> float:
	var value: Variant = hull.get("turn_acceleration", 0.0)
	return float(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0.0

## Turn command in -1..1. Space without goal.face_plane keeps turn 0.0 (nose never turns).
## Atmosphere without face_plane never aims the nose (the footprint hangs on it); it only brakes a running spin.
static func _turn_command(flight: Dictionary, goal: Dictionary, torque: float, fraction: float, mass: float, atmosphere: bool, env_factors: Dictionary) -> float:
	var face: Variant = goal.get("face_plane")
	var has_face: bool = typeof(face) == TYPE_VECTOR2 and face.is_finite()
	if not has_face and not atmosphere:
		return 0.0
	if not is_finite(torque) or torque <= 0.0:
		return 0.0
	var heading := float(flight.get("heading_rad", 0.0))
	var angular_velocity := float(flight.get("angular_velocity", 0.0))
	if not is_finite(heading) or not is_finite(angular_velocity):
		return 0.0
	var alpha := torque * fraction / mass
	if atmosphere:
		alpha *= float(env_factors.acceleration_factor)
	var w_soll := 0.0
	if has_face:
		var aim: Vector2 = face - flight.position_plane
		if aim.length_squared() > 0.000001:
			var err := wrapf(aim.angle() - heading, -PI, PI)
			# Dead zone: aimed and nearly still, so the nose does not jitter.
			if absf(err) < deg_to_rad(AIM_DEADZONE_DEGREES) and absf(angular_velocity) < AIM_DEADZONE_SPIN:
				return 0.0
			# The linear cap keeps the loop stable near zero (the square root alone rings there).
			w_soll = signf(err) * minf(minf(sqrt(2.0 * alpha * absf(err)) * 0.45, 2.0), absf(err) * AIM_LINEAR_GAIN)
	return clampf((w_soll - angular_velocity) * 4.0 * mass / (torque * fraction), -1.0, 1.0)
