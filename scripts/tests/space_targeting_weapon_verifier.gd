extends SceneTree
const TARGETING = preload("res://scripts/tactical/space_targeting_resolver.gd")
const WEAPON = preload("res://scripts/tactical/space_weapon_resolver.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

func _initialize() -> void:
	var shooter := {"id":"a", "position":HEX.axial_to_plane(Vector2(0,0)), "heading_rad":0.0, "faction_id":"blue", "area_id":"area", "sensor_range":10.0}
	var friend := {"id":"b", "position":HEX.axial_to_plane(Vector2(1,0)), "heading_rad":0.0, "faction_id":"blue", "area_id":"area", "sensor_range":10.0}
	var target := {"id":"c", "position":HEX.axial_to_plane(Vector2(3,0)), "heading_rad":0.0, "faction_id":"red", "area_id":"area", "sensor_range":10.0}
	var actors := {"a":shooter, "b":friend, "c":target}
	var world := {"actors":actors, "known_targets":["c"], "hostile_factions":["red"], "opaque_cells":[], "occupants_by_cell":{Vector2i(0,0):["a"], Vector2i(1,0):["b"], Vector2i(3,0):["c"]}}
	var weapon := {"range":10.0, "arc_degrees":60.0, "damage":4.0, "accuracy":1.0}
	assert(TARGETING.collect_contacts(world,"blue").contacts.has("c"))
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"free"},world).ok)
	var hidden := world.duplicate(true); hidden.known_targets = []
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"free"},hidden).reason == "unknown_target")
	var neutral := world.duplicate(true); neutral.hostile_factions = []
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"free"},neutral).reason == "not_hostile")
	var blocked := world.duplicate(true); blocked.opaque_cells = [Vector2i(2,0)]
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"free"},blocked).reason == "line_blocked")
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"hold"},world).reason == "fire_hold")
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"return"},world).reason == "return_fire_not_authorized")
	var retaliate := world.duplicate(true); retaliate.return_fire_authorized = true
	assert(TARGETING.evaluate_target(shooter,target,weapon,{"fire_rule":"return"},retaliate).ok)
	var facing := shooter.duplicate(true); facing.heading_rad = PI
	assert(TARGETING.evaluate_target(facing,target,weapon,{"fire_rule":"free"},world).reason == "outside_fire_arc")
	var first: Dictionary = WEAPON.resolve_shot(shooter,target,weapon,{"fire_rule":"free"},world,"event-1",42)
	assert(first.ok and first.event.hit_craft_id == "b" and first.event.destination == friend.position)
	assert(WEAPON.resolve_shot(shooter,target,weapon,{"fire_rule":"free"},world,"event-1",42) == first)
	var no_target := world.duplicate(true); no_target.occupants_by_cell.erase(Vector2i(3,0))
	assert(WEAPON.resolve_shot(shooter,target,weapon,{"fire_rule":"free"},no_target,"event-2",42).reason == "target_not_indexed")
	print("SPACE_TARGETING_WEAPON passed: contacts, hostility, LOS, arc, deterministic shots and friendly interception")
	quit(0)
