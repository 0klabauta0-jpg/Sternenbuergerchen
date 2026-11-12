extends SceneTree
const LOCATIONS = preload("res://scripts/mission/orbit_surface_locations.gd")

func _initialize() -> void:
	var system: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	for location: String in ["satellite_crash", "trade_outpost", "fortified_outpost"]:
		assert(LOCATIONS.contains(system.bodies.planet, location))
		assert(system.location_orbits[location] == "planet_orbit")
	assert(LOCATIONS.contains(system.bodies.moon, "homebase"))
	assert(not LOCATIONS.contains(system.bodies.planet, "distress_orbit"))
	assert(not LOCATIONS.contains(system.bodies.polisa, "polisa"))
	assert(not LOCATIONS.contains(system.bodies.moon, "satellite_crash"))
	print("ORBIT_SURFACE_LOCATIONS passed")
	quit()
