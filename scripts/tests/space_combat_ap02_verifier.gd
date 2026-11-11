extends SceneTree
const RESOLVER = preload("res://scripts/tactical/space_flight_resolver.gd")

func _initialize() -> void:
	var failed := 0
	var flight := {"position_plane":Vector2.ZERO, "velocity_plane":Vector2(2,0), "heading_rad":0.0, "angular_velocity":0.0, "mass":1.0, "revision":0, "assist_mode":"decoupled"}
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/space/ship_hulls.json"))
	if typeof(catalog) != TYPE_DICTIONARY or not catalog.get("fixture_only", false) or not catalog.get("hulls", {}).has("space_fixture_light"):
		printerr("FAIL: fixture catalog unavailable")
		quit(1)
		return
	var hull: Dictionary = catalog.hulls.space_fixture_light
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
	var reverse: Dictionary = RESOLVER.step(flight, {"forward":-1.0}, hull, {}, 1.0)
	if not is_zero_approx(reverse.velocity_plane.x): failed += 1
	var rotating := flight.duplicate(true)
	rotating.angular_velocity = PI
	var turned: Dictionary = RESOLVER.step(rotating, {}, hull, {}, 1.0)
	if not is_equal_approx(turned.heading_rad, PI) or not turned.velocity_plane.is_equal_approx(flight.velocity_plane): failed += 1
	var invalid := flight.duplicate(true)
	invalid.mass = INF
	if RESOLVER.step(invalid, {}, hull, {}, 1.0).get("ok", false): failed += 1
	print("SPACE_COMBAT_AP02 passed=", 8-failed, " failed=", failed)
	quit(1 if failed else 0)
