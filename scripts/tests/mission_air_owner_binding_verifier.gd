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
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
class Flow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {"ship":"moon_site"}
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	func get_active_mission() -> Node: return _active_mission
class Person extends Node2D:
	var unit_id := ""
	var health := 100
	var team := "blue"
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team
	func get_health() -> int: return health
	func get_character_profile_bundle() -> Dictionary: return {"platform_values":{"dropship_piloting":1.0}}
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool: health -= amount; return true
class Vision extends Node:
	var visible := true
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray:
		return PackedStringArray(["enemy", "local_enemy"]) if visible else PackedStringArray()
class Transport extends Node:
	var boarded := true
	var landing_clear := true
	var landing_position := Vector2.ZERO
	func get_campaign_air_support_pilot_guard(_craft_id: String) -> Dictionary:
		return {"ok":true, "pilot_unit_id":"pilot"} if boarded else {"ok":false, "reason":"pilot_boarding_pending"}
	func _is_parked_campaign_dropship(_craft_id: String) -> bool: return true
	func _campaign_landed_craft_position(_craft_id: String) -> Vector2: return landing_position
	func _ground_ship_touchdown_ready(_id: String, _position: Vector2, _visual: bool) -> bool: return landing_clear

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
	terrain.register_tile(TILE.new({"tile_id":"enemy", "grid_position":Vector2i(3,0), "explicit_hex_ramps":true}))
	var enemy = Person.new(); enemy.unit_id = "enemy"; enemy.team = "red"; mission.add_child(enemy); units.register_unit("enemy", enemy); mission_root.register_known_unit("enemy", enemy)
	var enemy_placements: Array[Dictionary] = [{"unit_id":"enemy", "grid":Vector2i(3,0)}]; assert(mission_root.admit_hex_ground_units(enemy_placements).ok)
	var vision = Vision.new(); vision.name = "CombatLoopDriver"; mission.add_child(vision)
	var transport = Transport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 16):
		for r in range(5, 16): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q,r], "grid_position":Vector2i(q,r), "explicit_hex_ramps":true}))
	transport.landing_position = terrain.grid_to_world(Vector2i(10,10))
	var grounded_fire := {"craft_id":"ship", "target_unit_id":"enemy", "weapon_slot":"weapon_1"}
	assert(not mission_root.is_air_support_craft_airborne("ship"))
	assert(mission_root.preview_air_support_ground_fire(grounded_fire).reason == "aircraft_not_flying")
	var attack := {"craft_id":"ship", "target_unit_id":"enemy", "request_id":"air-order"}
	assert(adapter.request_operation("air_support_attack_order", attack).reason == "aircraft_not_flying")
	var flight: RefCounted = fleet.get_flight_state("ship")
	var initial_pose: Dictionary = flight.get_snapshot()
	source.tick_counter = 50
	transport.boarded = false
	assert(not adapter.request_operation("air_support_takeoff", {"craft_id":"ship"}).ok and flight.get_snapshot() == initial_pose)
	transport.boarded = true
	assert(adapter.request_operation("air_support_takeoff", {"craft_id":"ship"}).ok)
	assert(flight.get_snapshot().tick == source.tick_counter)
	assert(mission_root.is_air_support_craft_airborne("ship"))
	# Isolated sensor fixture: a registered airborne enemy, not a ground unit.
	var radar_target = FLIGHT.new(); assert(radar_target.configure("radar_enemy", {"position_plane":Vector2.ZERO}).ok)
	var radar_pose := {"expected_revision":radar_target.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"atmosphere:moon_site", "position_plane":GRID.HEX.axial_to_plane(Vector2(13,12)), "motion_mode":"tactical", "assist_mode":"coupled"}
	var radar_transition: Dictionary = radar_target.validate_area_transition(radar_pose, 1)
	var radar_combat: RefCounted = source.get("_space_combat_state")
	var radar_admission: Dictionary = radar_combat.validate_new_local_admission({"craft_id":"radar_enemy", "faction_id":"red", "control_domain":"enemy", "footprint_hexes":[Vector2i.ZERO]}, radar_target, radar_pose, 1)
	assert(radar_transition.ok and radar_admission.ok)
	radar_target._publish_area_transition(radar_transition); radar_combat._publish_new_local_admission(radar_admission)
	var radar: Dictionary = mission_root.get_air_support_radar_contacts("ship")
	assert(radar.ok and radar.contacts == ["radar_enemy"] and radar.projections.size() == 1 and radar.projections[0].position.is_equal_approx(terrain.grid_to_world(Vector2i(13,12))))
	var local_enemy = Person.new(); local_enemy.unit_id = "local_enemy"; local_enemy.team = "red"; mission.add_child(local_enemy); units.register_unit("local_enemy", local_enemy); mission_root.register_known_unit("local_enemy", local_enemy)
	var local_placements: Array[Dictionary] = [{"unit_id":"local_enemy", "grid":Vector2i(13,10)}]; assert(mission_root.admit_hex_ground_units(local_placements).ok)
	vision.visible = false
	assert(not adapter.request_operation("air_support_attack_order", {"craft_id":"ship", "target_unit_id":"local_enemy"}).ok)
	vision.visible = true
	assert(adapter.request_operation("air_support_attack_order", {"craft_id":"ship", "target_unit_id":"local_enemy"}).ok)
	var energy_before_auto: float = source.get("_space_combat_state").get_ship_systems("ship").state.weapon_energy
	mission_root.tick_counter += 1
	mission_root._advance_air_support_orders(0.2)
	assert(source.get("_space_combat_state").get_ship_systems("ship").state.weapon_energy < energy_before_auto)
	assert(mission_root.request_air_support_cease_fire("ship", "cease-test").ok)
	var energy_after_stop: float = source.get("_space_combat_state").get_ship_systems("ship").state.weapon_energy
	mission_root.tick_counter += 1; mission_root._advance_air_support_orders(0.2)
	assert(source.get("_space_combat_state").get_ship_systems("ship").state.weapon_energy == energy_after_stop)
	var origin: Vector2 = flight.get_snapshot().position_plane
	assert(not adapter.request_operation("air_support_move", {"craft_id":"ship", "target_hex":Vector2i(300,300)}).ok)
	assert(adapter.request_operation("air_support_move", {"craft_id":"ship", "target_hex":Vector2i(11,10)}).ok)
	for t in range(1, 31): source._advance_space_flights(0.1, flight.get_snapshot().tick + 1)
	assert(flight.get_snapshot().position_plane.distance_to(origin) > 0.01)
	assert(Vector2(mission_root.get_air_support_world_pose("ship").position).distance_to(transport.landing_position) > 0.01)
	assert(not adapter.request_operation("air_support_landing", {"craft_id":"ship"}).ok)
	assert(adapter.request_operation("air_support_move", {"craft_id":"ship", "target_hex":Vector2i(10,10)}).ok)
	for t in range(1, 1001):
		source._advance_space_flights(0.05, flight.get_snapshot().tick + 1)
		if flight.get_snapshot().position_plane.distance_to(origin) < 0.1 and flight.get_snapshot().velocity_plane.length() < 0.1: break
	var airborne_pose: Dictionary = flight.get_snapshot()
	transport.landing_clear = false
	assert(not adapter.request_operation("air_support_landing", {"craft_id":"ship"}).ok and flight.get_snapshot() == airborne_pose)
	transport.landing_clear = true
	assert(adapter.request_operation("air_support_landing", {"craft_id":"ship"}).ok)
	assert(not mission_root.is_air_support_craft_airborne("ship") and flight.get_snapshot().motion_mode == initial_pose.motion_mode and flight.get_snapshot().position_plane == initial_pose.position_plane)
	var proposal := {"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"atmosphere:moon_site", "position_plane":GRID.HEX.axial_to_plane(Vector2.ZERO), "motion_mode":"tactical", "heading_rad":0.0, "assist_mode":"coupled"}
	var transition_tick: int = flight.get_snapshot().tick + 1
	var transition: Dictionary = flight.validate_area_transition(proposal, transition_tick)
	var combat: RefCounted = source.get("_space_combat_state")
	var admission: Dictionary = combat.validate_new_local_admission({"craft_id":"ship", "faction_id":"player", "control_domain":"player", "footprint_hexes":[Vector2i.ZERO]}, flight, proposal, transition_tick)
	assert(transition.ok and admission.ok); flight._publish_area_transition(transition); combat._publish_new_local_admission(admission)
	assert(mission_root.is_air_support_craft_airborne("ship"))
	var stats: Dictionary = equipment.get_space_combat_stats("ship"); assert(combat.ensure_ship_systems("ship", stats).ok)
	var fire := {"craft_id":"ship", "target_unit_id":"enemy", "weapon_slot":"weapon_1"}
	assert(mission_root.preview_air_support_ground_fire(fire).reason == "attack_order_required")
	var wings: RefCounted = source.get("_space_wing_state"); var wing_id: String = wings.get_craft_wing("ship", "singleplayer")
	vision.visible = false
	assert(adapter.request_operation("air_support_attack_order", attack).reason == "target_not_visible")
	vision.visible = true
	transport.boarded = false
	assert(adapter.request_operation("air_support_attack_order", attack).reason == "pilot_boarding_pending")
	transport.boarded = true
	assert(adapter.request_operation("air_support_attack_order", attack).ok)
	assert(adapter.request_operation("air_support_attack_order", attack).replayed)
	var conflicting_attack := attack.duplicate(); conflicting_attack.target_unit_id = "target"
	assert(adapter.request_operation("air_support_attack_order", conflicting_attack).reason == "request_id_conflict")
	assert(wings.get_snapshot().wings[wing_id].order.target_id == "enemy")
	var snapshot_before: Dictionary = combat.get_ship_systems("ship")
	assert(mission_root.preview_air_support_ground_fire(fire).ok and combat.get_ship_systems("ship") == snapshot_before)
	transport.boarded = false; assert(mission_root.preview_air_support_ground_fire(fire).reason == "pilot_boarding_pending"); transport.boarded = true
	flow._assigned_aircraft_pilot_by_craft.ship = "someone_else"
	assert(mission_root.preview_air_support_ground_fire(fire).reason == "pilot_assignment_changed")
	flow._assigned_aircraft_pilot_by_craft.ship = "pilot"
	pilot.set_meta("dropship_embarked", false); assert(mission_root.preview_air_support_ground_fire(fire).reason == "pilot_not_aboard"); pilot.set_meta("dropship_embarked", true)
	vision.visible = false; assert(mission_root.preview_air_support_ground_fire(fire).reason == "target_not_visible"); vision.visible = true
	var wrong_slot := fire.duplicate(); wrong_slot.weapon_slot = "invalid"
	assert(mission_root.preview_air_support_ground_fire(wrong_slot).reason == "weapon_unavailable")
	combat.get("_ship_systems").ship.cooldowns.weapon_1 = 1.0
	assert(mission_root.preview_air_support_ground_fire(fire).reason == "weapon_unavailable")
	combat.get("_ship_systems").ship.cooldowns.weapon_1 = 0.0
	enemy.team = "blue"; assert(mission_root.preview_air_support_ground_fire(fire).reason == "not_hostile"); enemy.team = "red"
	var fire_seed := -1
	for candidate in range(100):
		var next_seed: int = (candidate * 1103515245 + 12345) & 0x7fffffff
		if DISPERSION.resolve(Vector2i(3,0), 1.0, next_seed).impact_hex == Vector2i(3,0): fire_seed = candidate; break
	assert(fire_seed >= 0); mission_root.set("_air_ground_rng_state", fire_seed)
	var events: Array = []; mission_root.air_support_ground_fired.connect(func(value: Dictionary): events.append(value))
	var shot := fire.duplicate(); shot.request_id = "air-shot-1"
	var energy_before: float = combat.get_ship_systems("ship").state.weapon_energy
	vision.visible = false
	assert(adapter.request_operation("air_support_ground_fire", shot).reason == "target_not_visible" and enemy.health == 100 and combat.get_ship_systems("ship").state.weapon_energy == energy_before and events.is_empty())
	vision.visible = true
	var shot_result: Dictionary = adapter.request_operation("air_support_ground_fire", shot)
	assert(shot_result.ok and enemy.health < 100 and combat.get_ship_systems("ship").state.weapon_energy == energy_before - 1.0 and events.size() == 1)
	assert(events[0].attacker_position is Vector2 and events[0].target_position is Vector2 and events[0].aim_position is Vector2)
	var enemy_after: int = enemy.health
	assert(adapter.request_operation("air_support_ground_fire", shot).replayed and enemy.health == enemy_after and events.size() == 1)
	var conflict := shot.duplicate(); conflict.weapon_slot = "weapon_2"
	assert(adapter.request_operation("air_support_ground_fire", conflict).reason == "request_id_conflict")
	combat.get("_ship_systems").ship.cooldowns.weapon_1 = 0.0
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "heading_rad":PI}, flight.get_snapshot().tick + 1).ok)
	assert(mission_root.preview_air_support_ground_fire(fire).reason == "outside_fire_arc")
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
