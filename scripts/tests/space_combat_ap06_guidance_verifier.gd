extends SceneTree
const GUIDANCE = preload("res://scripts/tactical/space_guidance_resolver.gd")
const FLIGHT = preload("res://scripts/tactical/space_flight_resolver.gd")

func _initialize() -> void:
	var hull := {"main_thrust":2.0, "reverse_thrust":2.0, "side_thrust":2.0, "turn_acceleration":1.0}
	var flight := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2.ZERO, "heading_rad":0.0, "angular_velocity":0.0, "mass":1.0, "revision":0}
	var goal := {"target_plane":Vector2(10, 0), "arrival_radius":0.25}
	var failed := 0
	var initial: Dictionary = GUIDANCE.resolve(flight, goal, hull, {})
	if not initial.get("ok", false) or initial.intent.forward <= 0.0: failed += 1
	for i in range(1200):
		var guidance: Dictionary = GUIDANCE.resolve(flight, goal, hull, {})
		var proposal: Dictionary = FLIGHT.step(flight, guidance.intent, hull, {}, 1.0 / 60.0)
		flight.merge(proposal, true)
	if flight.position_plane.distance_to(goal.target_plane) > 0.25 or flight.velocity_plane.length() > 0.1:
		printerr("guidance arrival ", flight.position_plane, " velocity ", flight.velocity_plane)
		failed += 1
	flight.position_plane = Vector2(9, 0)
	flight.velocity_plane = Vector2(8, 0)
	var braking: Dictionary = GUIDANCE.resolve(flight, goal, hull, {})
	if braking.intent.forward >= 0.0: failed += 1
	flight.heading_rad = PI / 2.0
	flight.position_plane = Vector2.ZERO
	flight.velocity_plane = Vector2.ZERO
	var sideways: Dictionary = GUIDANCE.resolve(flight, goal, hull, {})
	if sideways.intent.lateral <= 0.0:
		printerr("guidance sideways ", sideways)
		failed += 1
	hull.side_thrust = 0.0
	if GUIDANCE.resolve(flight, goal, hull, {}).get("reason") != "insufficient_thrust": failed += 1
	print("SPACE_COMBAT_AP06_GUIDANCE passed=", 5 - failed, " failed=", failed)
	quit(1 if failed else 0)
