extends SceneTree
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")

func _initialize() -> void:
	var owner = EQUIPMENT.new()
	assert(owner.configure([{"craft_id":"ship", "model_id":"cutlass"}, {"craft_id":"fighter", "model_id":"buccaneer"}, {"craft_id":"unknown_model", "model_id":"unsupported"}]).ok)
	var before: Dictionary = owner.export_state()
	var profile: Dictionary = owner.get_space_flight_profile("ship")
	assert(profile.ok and profile.mass > 0.0 and profile.hull.main_thrust > profile.hull.reverse_thrust and profile.power.thrust_fraction == 1.0)
	assert(owner.get_space_flight_profile("fighter").hull.side_thrust > profile.hull.side_thrust)
	profile.hull.main_thrust = 0.0
	assert(owner.get_space_flight_profile("ship").hull.main_thrust > 0.0)
	assert(owner.get_space_flight_profile("unknown_model").reason == "flight_profile_unavailable")
	assert(owner.get_space_flight_profile("missing").reason == "unknown_craft")
	assert(owner.export_state() == before)
	print("SPACE_EQUIPMENT_FLIGHT_PROFILE passed")
	quit(0)
