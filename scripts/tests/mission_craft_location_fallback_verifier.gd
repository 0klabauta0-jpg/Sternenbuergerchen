extends SceneTree

class Flow extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready() -> void: pass

func _initialize() -> void:
	var flow = Flow.new()
	var old_mission := Node.new(); old_mission.set_meta("location_id", "satellite_crash")
	var new_mission := Node.new(); new_mission.set_meta("location_id", "trade_outpost")
	flow._active_mission = old_mission
	flow._active_singleplayer_identity = {"craft_id":"ship"}
	flow._aircraft_location_by_craft["ship"] = "starmap"
	if flow.get_mission_for_craft("ship") != null:
		printerr("FAIL: stale previous mission returned for a ship in space")
		old_mission.free(); new_mission.free(); flow.free(); quit(1); return
	flow._aircraft_location_by_craft["ship"] = "mission"
	assert(flow.get_mission_for_craft("ship") == old_mission)
	assert(flow._location_registry.register_location("trade_outpost", new_mission))
	flow._craft_location_runtime["ship"] = "trade_outpost"
	assert(flow.get_mission_for_craft("ship") == new_mission)
	old_mission.free(); new_mission.free(); flow.free()
	print("MISSION_CRAFT_LOCATION_FALLBACK passed")
	quit()
