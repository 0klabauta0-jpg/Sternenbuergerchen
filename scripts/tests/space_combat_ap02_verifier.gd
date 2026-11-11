extends SceneTree
const RESOLVER = preload("res://scripts/tactical/space_flight_resolver.gd")

func _initialize() -> void:
	var failed := 0
	var flight := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2(2,0), "heading_rad":0.0, "angular_velocity":0.0, "mass":1.0, "revision":0, "assist_mode":"decoupled"}
	var hull := {"main_thrust":2.0, "reverse_thrust":2.0, "side_thrust":2.0, "turn_acceleration":1.0}
	var coast: Dictionary = RESOLVER.step(flight, {}, hull, {}, 1.0)
	if not coast.ok or not coast.position_plane.is_equal_approx(Vector2(2,0)): failed += 1
	var turning: Dictionary = RESOLVER.step(flight, {"turn":1.0}, hull, {}, 1.0)
	if not turning.velocity_plane.is_equal_approx(Vector2(2,0)) or is_zero_approx(turning.heading_rad): failed += 1
	var light: Dictionary = RESOLVER.step(flight, {"forward":1.0}, hull, {}, 1.0)
	var heavy := flight.duplicate(true)
	heavy.mass = 2.0
	var heavy_result: Dictionary = RESOLVER.step(heavy, {"forward":1.0}, hull, {}, 1.0)
	if not is_equal_approx(light.velocity_plane.x - 2.0, 2.0 * (heavy_result.velocity_plane.x - 2.0)): failed += 1
	var diagonal: Dictionary = RESOLVER.step(flight, {"forward":1.0,"lateral":1.0}, hull, {}, 1.0)
	if (diagonal.velocity_plane - flight.velocity_plane).length() > 2.00001: failed += 1
	var drift := flight.duplicate(true)
	drift.velocity_plane = Vector2(2,1)
	var coupled: Dictionary = RESOLVER.step(drift, {"assist_mode":"coupled"}, hull, {}, 1.0)
	if absf(coupled.velocity_plane.y) >= 1.0: failed += 1
	print("SPACE_COMBAT_AP02 passed=", 5-failed, " failed=", failed)
	quit(1 if failed else 0)
