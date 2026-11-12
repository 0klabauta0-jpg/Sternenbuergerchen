extends SceneTree
const FLIGHT = preload("res://scripts/tactical/space_flight_resolver.gd")

func _initialize() -> void:
	var flight := {"position_plane":Vector2.ZERO,"velocity_plane":Vector2(1,1),"mass":1.0,"heading_rad":0.0,"angular_velocity":0.0,"assist_mode":"coupled"}
	var hull := {"main_thrust":2.0,"reverse_thrust":1.0,"side_thrust":1.0,"turn_acceleration":1.0}
	var power := {"thrust_fraction":1.0}
	var input := {"forward":0.0,"lateral":0.0,"turn":0.0}
	var initial := flight.duplicate(true)
	var coupled := FLIGHT.step(flight, input, hull, power, 0.1, "atmosphere")
	assert(coupled.ok and coupled.assist_mode == "coupled" and coupled.velocity_plane.y < flight.velocity_plane.y)
	var decoupled := input.duplicate(); decoupled["assist_mode"] = "decoupled"
	assert(FLIGHT.step(flight, decoupled, hull, power, 0.1).ok)
	assert(FLIGHT.step(flight, decoupled, hull, power, 0.1, "atmosphere").reason == "atmosphere_requires_coupled")
	assert(not FLIGHT.step(flight, input, hull, power, 0.1, "unknown").ok)
	assert(flight == initial)
	print("SPACE_ATMOSPHERE_MODE passed: coupled atmosphere, decoupled space, rejection without mutation")
	quit(0)
