extends SceneTree
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")
const FLIGHT = preload("res://scripts/tactical/space_flight_resolver.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")

func _initialize() -> void:
	var light := CATALOG.default_loadout("buccaneer")
	var initial := light.duplicate(true)
	assert(CATALOG.validate_loadout("buccaneer", light).ok)
	assert(CATALOG.validate_loadout("cutlass", CATALOG.default_loadout("cutlass")).ok)
	var base: Dictionary = CATALOG.effective_stats("buccaneer", light)
	assert(base.ok and base.weapons.size() == 2 and base.shield.capacity > 0.0)
	var smaller := light.duplicate(true); smaller.weapon_1 = "repeater_s1"
	var light_stats: Dictionary = CATALOG.effective_stats("buccaneer", smaller)
	assert(light_stats.ok and light_stats.mass < base.mass)
	var heavy_inputs: Dictionary = CATALOG.flight_inputs("buccaneer", light)
	var light_inputs: Dictionary = CATALOG.flight_inputs("buccaneer", smaller)
	var flight := {"position_plane":Vector2.ZERO,"velocity_plane":Vector2.ZERO,"heading_rad":0.0,"angular_velocity":0.0,"mass":heavy_inputs.mass}
	var thrust := {"forward":1.0,"lateral":0.0,"turn":0.0}
	var heavy_step: Dictionary = FLIGHT.step(flight, thrust, heavy_inputs.hull, heavy_inputs.power, 1.0)
	flight.mass = light_inputs.mass
	var light_step: Dictionary = FLIGHT.step(flight, thrust, light_inputs.hull, light_inputs.power, 1.0)
	assert(heavy_step.ok and light_step.ok and light_step.velocity_plane.x > heavy_step.velocity_plane.x)
	var oversize := light.duplicate(true); oversize.weapon_1 = "repeater_s4"
	assert(CATALOG.validate_loadout("buccaneer", oversize).reason == "wrong_component_size")
	var wrong := light.duplicate(true); wrong.shield = "power_s1"
	assert(CATALOG.validate_loadout("buccaneer", wrong).reason == "wrong_component_class")
	var unknown := light.duplicate(true); unknown.weapon_1 = "missing"
	assert(not CATALOG.validate_loadout("buccaneer", unknown).ok)
	assert(not CATALOG.validate_loadout("buccaneer", {}).ok)
	assert(is_equal_approx(base.power.flight_fraction, 1.0) and is_equal_approx(base.power.weapon_fraction, 1.0) and is_equal_approx(base.power.shield_fraction, 0.75))
	assert(light == initial and CATALOG.default_loadout("buccaneer") == initial)
	var state: Dictionary = SYSTEMS.initial(base, 50.0).state
	var original := state.duplicate(true)
	var hit: Dictionary = SYSTEMS.apply_hit(base, state, 30.0)
	assert(hit.ok and hit.shield_damage == 24.0 and hit.hull_damage == 6.0 and hit.state.hull == 44.0 and state == original)
	var fired: Dictionary = SYSTEMS.consume_weapon(base, hit.state, 8.0)
	assert(fired.ok and fired.state.weapon_energy == 12.0)
	assert(not SYSTEMS.consume_weapon(base, fired.state, 13.0).ok)
	var tick: Dictionary = SYSTEMS.advance(base, fired.state, 5.0)
	assert(tick.ok and is_equal_approx(tick.state.shield, 2.25) and tick.state.weapon_energy == 20.0)
	assert(not SYSTEMS.advance(base, fired.state, -1.0).ok and hit.state.weapon_energy == 20.0)
	var owner = EQUIPMENT.new()
	assert(owner.configure([{"craft_id":"pilot_ship", "model_id":"buccaneer"}]).ok)
	var saved: Dictionary = owner.export_state()
	var preview: Dictionary = owner.preview_space_components("pilot_ship", light, 0)
	assert(preview.ok and preview.preview_only and preview.model_id == "buccaneer" and preview.equipment_revision == 0)
	preview.slots.weapon_1 = "modified"
	assert(owner.export_state() == saved and light == initial)
	assert(not owner.preview_space_components("pilot_ship", light, 1).ok and not owner.preview_space_components("unknown", light, 0).ok)
	print("SPACE_COMPONENT_CATALOG passed: loadout, mass, slots, power, shield, recharge and immutable proposals")
	quit(0)
