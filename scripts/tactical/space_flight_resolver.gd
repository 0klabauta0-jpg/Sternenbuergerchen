extends RefCounted
## Pure planar thrust proposal; all strengths are fixture/catalog inputs.
const FLIGHT_ENV = preload("res://scripts/tactical/flight_environment.gd")

## environment comes from the authoritative caller, never a client command.
## Existing five-argument callers remain in space until ground integration.
static func step(flight: Dictionary, intent: Dictionary, hull: Dictionary, power: Dictionary, dt: float, environment: String = "space") -> Dictionary:
	if environment not in ["space", "atmosphere"]:
		return {"ok": false, "reason": "invalid_flight_environment"}
	if not is_finite(dt) or dt < 0.0 or typeof(flight.get("position_plane")) != TYPE_VECTOR2 or typeof(flight.get("velocity_plane")) != TYPE_VECTOR2:
		return {"ok": false, "reason": "invalid_state"}
	if not flight.position_plane.is_finite() or not flight.velocity_plane.is_finite():
		return {"ok": false, "reason": "invalid_state"}
	for pair in [[flight, "mass"], [flight, "heading_rad"], [flight, "angular_velocity"], [hull, "main_thrust"], [hull, "reverse_thrust"], [hull, "side_thrust"], [hull, "turn_acceleration"], [power, "thrust_fraction"], [intent, "forward"], [intent, "lateral"], [intent, "turn"]]:
		if pair[0].has(pair[1]) and typeof(pair[0][pair[1]]) not in [TYPE_INT, TYPE_FLOAT]:
			return {"ok": false, "reason": "invalid_parameters"}
	var mass: float = float(flight.get("mass", 0.0))
	var heading: float = float(flight.get("heading_rad", 0.0))
	var main: float = float(hull.get("main_thrust", 0.0))
	var reverse: float = float(hull.get("reverse_thrust", 0.0))
	var side: float = float(hull.get("side_thrust", 0.0))
	var torque: float = float(hull.get("turn_acceleration", 0.0))
	var budget: float = float(power.get("thrust_fraction", 1.0))
	if not is_finite(mass) or mass <= 0.0 or not is_finite(heading) or not is_finite(main) or not is_finite(reverse) or not is_finite(side) or not is_finite(torque) or not is_finite(budget) or minf(main, minf(reverse, minf(side, torque))) < 0.0:
		return {"ok": false, "reason": "invalid_parameters"}
	var forward: float = float(intent.get("forward", 0.0))
	var lateral: float = float(intent.get("lateral", 0.0))
	var turn: float = float(intent.get("turn", 0.0))
	if not is_finite(forward) or not is_finite(lateral) or not is_finite(turn):
		return {"ok": false, "reason": "invalid_intent"}
	forward = clampf(forward, -1.0, 1.0)
	lateral = clampf(lateral, -1.0, 1.0)
	turn = clampf(turn, -1.0, 1.0)
	var assist: String = String(intent.get("assist_mode", flight.get("assist_mode", "coupled")))
	if assist not in ["coupled", "decoupled"]:
		return {"ok": false, "reason": "invalid_assist_mode"}
	if environment == "atmosphere" and assist != "coupled":
		return {"ok": false, "reason": "atmosphere_requires_coupled"}
	var velocity: Vector2 = flight.velocity_plane
	var axis := Vector2.from_angle(heading)
	var axis_side := axis.orthogonal()
	if assist == "coupled" and is_zero_approx(lateral) and dt > 0.0 and side > 0.0:
		lateral = clampf(-velocity.dot(axis_side) * mass / (side * dt), -1.0, 1.0)
	var controls := Vector3(forward, lateral, turn)
	if controls.length() > 1.0: controls = controls.normalized()
	var thrust: Vector2 = axis * controls.x * (main if controls.x >= 0.0 else reverse) + axis_side * controls.y * side
	thrust *= clampf(budget, 0.0, 1.0)
	if environment == "atmosphere":
		thrust *= float(FLIGHT_ENV.factors("atmosphere").acceleration_factor)
	var angular_velocity: float = float(flight.get("angular_velocity", 0.0))
	if not is_finite(angular_velocity):
		return {"ok": false, "reason": "invalid_state"}
	var next_velocity := velocity + thrust / mass * dt
	return {"ok": true, "expected_revision": int(flight.get("revision", 0)),
		"position_plane": flight.position_plane + (velocity + next_velocity) * 0.5 * dt,
		"velocity_plane": next_velocity,
		"heading_rad": heading + (angular_velocity + controls.z * torque * clampf(budget, 0.0, 1.0) / mass * dt * 0.5) * dt,
		"angular_velocity": angular_velocity + controls.z * torque * clampf(budget, 0.0, 1.0) / mass * dt,
		"assist_mode": assist, "thrust_forward": controls.x * clampf(budget, 0.0, 1.0),
		"thrust_lateral": controls.y * clampf(budget, 0.0, 1.0)}
