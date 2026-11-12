extends SceneTree
const LOCATIONS = preload("res://scripts/mission/orbit_surface_locations.gd")

func _initialize() -> void:
	var system: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	for row: Array in [["satellite_crash", "glut_1a", "glut_1a_orbit"], ["trade_outpost", "glut_1b", "glut_1b_orbit"], ["fortified_outpost", "planet", "planet_orbit"]]:
		assert(LOCATIONS.contains(system.bodies[row[1]], row[0]))
		assert(system.location_orbits[row[0]] == row[2])
	assert(LOCATIONS.contains(system.bodies.moon, "homebase"))
	assert(not LOCATIONS.contains(system.bodies.planet, "distress_orbit"))
	assert(not LOCATIONS.contains(system.bodies.planet, "satellite_crash"))
	assert(not LOCATIONS.contains(system.bodies.planet, "trade_outpost"))
	assert(not LOCATIONS.contains(system.bodies.polisa, "polisa"))
	assert(not LOCATIONS.contains(system.bodies.moon, "satellite_crash"))
	print("ORBIT_SURFACE_LOCATIONS passed")
	quit()
