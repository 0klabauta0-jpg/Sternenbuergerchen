extends RefCounted
## Fixture guidance only: collision and formation are handled separately.

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
	var desired_velocity: Vector2 = displacement.limit_length(5.0) * 0.8
	var desired_force: Vector2 = (desired_velocity - flight.velocity_plane) * (2.0 * mass)
	var axis := Vector2.from_angle(float(flight.get("heading_rad", 0.0)))
	var along := desired_force.dot(axis)
	var forward := along / ((main if along >= 0.0 else reverse) * fraction)
	var lateral := desired_force.dot(axis.orthogonal()) / (side * fraction)
	var controls := Vector2(forward, lateral).limit_length(1.0)
	return {"ok":true, "intent":{"forward":controls.x, "lateral":controls.y, "turn":0.0, "assist_mode":"decoupled"}}
