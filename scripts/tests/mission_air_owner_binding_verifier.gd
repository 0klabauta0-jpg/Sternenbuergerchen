extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DISPERSION = preload("res://scripts/mission/air_support_dispersion.gd")
class Flow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {"ship":"moon_site"}
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	func get_active_mission() -> Node: return _active_mission
class Person extends Node2D:
	var unit_id := ""
	var health := 100
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return "blue"
	func get_health() -> int: return health
	func get_character_profile_bundle() -> Dictionary: return {"platform_values":{"dropship_piloting":1.0}}
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool: health -= amount; return true

func _initialize() -> void:
	var flow = Flow.new(); root.add_child(flow)
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok)
	source.configure_singleplayer_owners(null, null, null, fleet); source.configure_ship_equipment(equipment)
	assert(source.configure_departure_adapter(adapter).ok)
	assert(source.get("_space_wing_state").ensure_flying_wings("singleplayer", ["ship"], ["ship"], {"ship":"pilot"}).ok)
	var mission = Node.new(); mission.set_meta("location_id", "moon_site"); flow.add_child(mission)
	var mission_root = ROOT.new(); mission_root.name = "SimulationRoot"; mission.add_child(mission_root); flow._active_mission = mission
	assert(adapter.bind_mission_air_support(mission).ok)
	assert(adapter.bind_mission_air_support(mission).ok)
	var binding: Dictionary = mission_root._resolve_air_support_craft("ship")
	assert(binding.ok and binding.flight == fleet.get_flight_state("ship") and binding.wings == source.get("_space_wing_state") and binding.combat == source.get("_space_combat_state") and binding.equipment == equipment)
	var terrain = TERRAIN.new(); terrain.name = "Terrain"; mission.add_child(terrain); terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"zero", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units = UNITS.new(); units.name = "Units"; mission.add_child(units)
	mission_root.unit_registry_path = mission_root.get_path_to(units); mission_root.terrain_registry_path = mission_root.get_path_to(terrain)
	var map = MAP.create_empty("moon_site", Vector2i(4,3), Vector2.ZERO, 64, 32, 3, "hex_axial_v1"); map.set_tactical_grid_rules("hex_tactical_v1")
	assert(mission_root.configure_hex_ground_runtime(map, terrain).ok)
	var target = Person.new(); target.unit_id = "target"; mission.add_child(target); units.register_unit("target", target); mission_root.register_known_unit("target", target)
	var pilot = Person.new(); pilot.unit_id = "pilot"; mission.add_child(pilot); units.register_unit("pilot", pilot); mission_root.register_known_unit("pilot", pilot)
	var placements: Array[Dictionary] = [{"unit_id":"target", "grid":Vector2i.ZERO}]; assert(mission_root.admit_hex_ground_units(placements).ok)
	var seed := -1
	for candidate in range(100):
		if DISPERSION.resolve(Vector2i.ZERO, 1.0, candidate).impact_hex == Vector2i.ZERO: seed = candidate; break
	var event := {"event_id":"shared-1", "craft_id":"ship", "pilot_id":"pilot", "team_id":"blue", "aim_hex":Vector2i.ZERO, "seed":seed, "damage":10}
	assert(mission_root._commit_piloted_air_ground_impact(event).reason == "pilot_not_aboard" and target.health == 100)
	pilot.set_meta("dropship_embarked", true)
	var hit: Dictionary = mission_root._commit_piloted_air_ground_impact(event)
	assert(hit.ok and hit.unit_id == "target" and target.health < 100)
	var after: int = target.health
	assert(mission_root._commit_piloted_air_ground_impact(event).replayed and target.health == after)
	flow._assigned_aircraft_pilot_by_craft.ship = "other_pilot"
	var wrong_pilot := event.duplicate(); wrong_pilot.event_id = "shared-2"
	assert(mission_root._commit_piloted_air_ground_impact(wrong_pilot).reason == "pilot_not_aboard" and target.health == after)
	flow._assigned_aircraft_pilot_by_craft.ship = "pilot"
	assert(not mission_root._resolve_air_support_craft("other").ok)
	flow._craft_location_runtime.ship = "other_site"
	assert(mission_root._resolve_air_support_craft("ship").reason == "craft_not_at_location")
	flow._craft_location_runtime.ship = "moon_site"
	mission.set_meta("location_id", "other_site")
	assert(mission_root._resolve_air_support_craft("ship").reason == "mission_context_changed")
	flow.free()
	print("MISSION_AIR_OWNER_BINDING passed")
	quit()
