extends SceneTree
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")

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
	print("SPACE_COMPONENT_CATALOG passed: loadout, mass, slots, power, shield, recharge and immutable proposals")
	quit(0)
