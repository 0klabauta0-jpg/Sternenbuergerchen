extends SceneTree
const COMBAT = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const WEAPON = preload("res://scripts/tactical/space_weapon_resolver.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

func _initialize() -> void:
	var owner = COMBAT.new()
	for spec in [["a",Vector2i(0,0),"blue"], ["b",Vector2i(1,0),"blue"], ["c",Vector2i(3,0),"red"]]:
		var flight = FLIGHT.new(); assert(flight.configure(spec[0], {"position_plane":HEX.axial_to_plane(Vector2(spec[1])), "motion_mode":"tactical"}).ok)
		assert(owner.admit_actor({"craft_id":spec[0], "start_hex":spec[1], "faction_id":spec[2], "control_domain":"enemy", "footprint_hexes":[Vector2i.ZERO]}, flight).ok)
		assert(owner.bind_ship_systems(spec[0], CATALOG.effective_stats("buccaneer", CATALOG.default_loadout("buccaneer")), 50.0).ok)
	var shooter := {"id":"a", "position":HEX.axial_to_plane(Vector2(0,0)), "heading_rad":0.0, "faction_id":"blue", "area_id":""}
	var target := {"id":"c", "position":HEX.axial_to_plane(Vector2(3,0)), "faction_id":"red", "area_id":""}
	var world := {"known_targets":["c"], "hostile_factions":["red"], "opaque_cells":[], "occupants_by_cell":{Vector2i(0,0):["a"], Vector2i(1,0):["b"], Vector2i(3,0):["c"]}}
	var shot: Dictionary = WEAPON.resolve_shot(shooter,target,{"range":10.0,"arc_degrees":60.0,"damage":30.0,"accuracy":1.0},{"fire_rule":"free"},world,"shot-1",42)
	assert(shot.ok and shot.event.hit_craft_id == "b")
	var hit: Dictionary = owner._commit_ship_impact(shot.event)
	assert(hit.ok and hit.shield_damage == 24.0 and hit.hull_damage == 6.0 and owner.get_ship_systems("b").state.hull == 44.0)
	var after: Dictionary = owner.get_ship_systems("b")
	assert(owner._commit_ship_impact(shot.event).replayed and owner.get_ship_systems("b") == after)
	var forged: Dictionary = shot.event.duplicate(true); forged.damage = 31.0
	assert(not owner._commit_ship_impact(forged).ok and owner.get_ship_systems("b") == after)
	assert(owner.advance_ship_systems(5.0).ok and is_equal_approx(owner.get_ship_systems("b").state.shield, 2.25))
	assert(owner.get_ship_systems("c").state.hull == 50.0)
	print("SPACE_SHIELD_OWNER passed: first intercept, shield then hull, replay and recharge")
	quit(0)
