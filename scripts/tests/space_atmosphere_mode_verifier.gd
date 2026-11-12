extends SceneTree
const FLIGHT = preload("res://scripts/tactical/space_flight_resolver.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLIGHT_STATE = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

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
	var sim = ROOT.new()
	var actor = FLIGHT_STATE.new()
	var cell := Vector2i(10, 10)
	assert(actor.configure("space_fixture_air", {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical", "coordinate_frame":"local", "space_area_id":"atmosphere:test", "assist_mode":"coupled"}).ok)
	var combat: RefCounted = sim.get("_space_combat_state")
	assert(combat.admit_actor({"craft_id":"space_fixture_air", "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, actor, true).ok)
	var before: Dictionary = actor.get_snapshot()
	var rejected: Dictionary = sim.set_space_flight_control("space_fixture_air", decoupled, hull, power, {"runtime_authorized":true})
	assert(rejected.reason == "atmosphere_requires_coupled" and actor.get_snapshot() == before)
	assert(sim.set_space_flight_control("space_fixture_air", input, hull, power, {"runtime_authorized":true}).ok)
	var proposals: Array[Dictionary] = [{"craft_id":"space_fixture_air", "expected_revision":before.revision, "position_plane":before.position_plane, "assist_mode":"decoupled"}]
	var blocked: Dictionary = sim.commit_space_fleet_motion(proposals, 1, {"coordinate_frame":"local", "space_area_id":"atmosphere:test"}, {"runtime_authorized":true, "fixture":true})
	assert(blocked.reason == "atmosphere_requires_coupled" and actor.get_snapshot() == before)
	sim.free()
	print("SPACE_ATMOSPHERE_MODE passed: coupled atmosphere, decoupled space, rejection without mutation")
	quit(0)
