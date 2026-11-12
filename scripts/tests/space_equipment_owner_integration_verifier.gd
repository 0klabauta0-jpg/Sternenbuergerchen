extends SceneTree
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")

func _initialize() -> void:
	var defs := [{"craft_id":"ship", "model_id":"cutlass"}]
	var owner = EQUIPMENT.new()
	assert(owner.configure(defs).ok)
	var snapshot: Dictionary = owner.export_state()
	assert(snapshot.schema_version == 2 and snapshot.space_loadouts.ship == CATALOG.default_loadout("cutlass"))
	var stats: Dictionary = owner.get_space_combat_stats("ship")
	var flight: Dictionary = owner.get_space_flight_profile("ship")
	assert(stats.ok and flight.ok and flight.mass == stats.mass and flight.mass > 1.0 and stats.weapons.size() == 4)
	var legacy := snapshot.duplicate(true)
	legacy.schema_version = 1; legacy.erase("space_catalog_version"); legacy.erase("space_loadouts")
	var restored = EQUIPMENT.new()
	assert(restored.restore_state(legacy, defs, {}, {}).ok and restored.export_state() == snapshot)
	var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	var roundtrip_result: Dictionary = restored.restore_state(roundtrip, defs, {}, {})
	if not roundtrip_result.ok: print("RESTORE_DIAGNOSTIC: ", roundtrip_result)
	assert(roundtrip_result.ok)
	var before: Dictionary = restored.export_state()
	var forged := roundtrip.duplicate(true); forged.space_loadouts.ship.weapon_1 = "repeater_s5"
	assert(not restored.restore_state(forged, defs, {}, {}).ok and restored.export_state() == before)
	assert(not restored.get_space_combat_stats("unknown").ok)
	print("SPACE_EQUIPMENT_OWNER passed: v1 migration, v2 restore, fixed loadout and flight consumer")
	quit(0)
