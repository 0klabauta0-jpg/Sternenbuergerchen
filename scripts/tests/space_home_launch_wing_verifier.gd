extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
class FlowFixture extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	var _aircraft_location_by_craft := {"ship":"homebase"}
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {}
	func _find_homebase_aircraft_definition(id: String) -> Dictionary: return {"craft_id":id}
	func _refresh_homebase_screen() -> void: pass
class PilotFixture extends Node:
	var aboard := false
	func is_pilot_aboard(_id: String) -> bool: return aboard
	func get_payload_presence(_id: String) -> Dictionary: return {"all_aboard":aboard}
class ScreenFixture extends Control:
	func _has_homebase_direct_launch_payload_for_craft(_id: String) -> bool: return true
	func _get_assigned_pilot_id(_id: String) -> String: return "pilot"
	func _can_send_craft(_definition: Dictionary, _id: String) -> bool: return true

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var screen = ScreenFixture.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._screen = screen; adapter._base_personnel = pilot; adapter._pad_by_craft["ship"] = "homebase_pad_01"
	assert(sim.configure_departure_adapter(adapter).ok)
	var flight = fleet.get_flight_state("ship"); var before: Dictionary = flight.get_snapshot()
	assert(not adapter.launch_to_moon_orbit("ship").ok and flight.get_snapshot() == before and sim.get_space_wing_snapshot().wings.is_empty())
	pilot.aboard = true
	var result: Dictionary = adapter.launch_to_moon_orbit("ship")
	assert(result.ok and fleet.get_craft_snapshot("ship").phase == "orbit" and flow._aircraft_location_by_craft.ship == "starmap")
	assert(not sim.get("_space_wing_state").get_craft_wing("ship", "singleplayer").is_empty())
	var id: String = sim.get("_launch_receipts").keys()[0]
	var after: Dictionary = flight.get_snapshot()
	var observed := []
	sim.singleplayer_command_committed.connect(func(_command: Dictionary, _result: Dictionary): observed.append(flow._aircraft_location_by_craft.ship == "starmap" and sim.commit_singleplayer_space_launch(adapter, "ship", id).get("replayed", false)))
	sim.publish_singleplayer_space_launch_event(adapter, id); sim.publish_singleplayer_space_launch_event(adapter, id)
	assert(observed == [true] and flight.get_snapshot() == after)
	adapter.free(); screen.free(); pilot.free(); flow.free(); sim.free()
	var legacy = FLEET.new(); assert(legacy.configure().ok); legacy.register_craft("old")
	assert(legacy.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"old"}, "request_id":"old-launch"}, {"runtime_authorized":true}).ok)
	var recovered = ROOT.new(); recovered.configure_singleplayer_owners(null, null, null, legacy)
	assert(recovered.reconcile_space_wings(["old"], {"old":"old-pilot"}, {"runtime_authorized":true}).ok)
	assert(not recovered.get("_space_wing_state").get_craft_wing("old", "singleplayer").is_empty())
	recovered.free()
	print("SPACE_HOME_LAUNCH_WING passed")
	quit(0)
