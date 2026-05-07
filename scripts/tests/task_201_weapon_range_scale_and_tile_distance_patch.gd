extends SceneTree

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const OVERWATCH_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/overwatch_controller.gd")
const MEDIC_SUPPORT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/medic_support_resolver.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const EXPECTED_TILE_RANGES: Dictionary = {
	"smg": 10,
	"rail_gun": 20,
	"rifle": 25,
	"sniper": 40,
	"medictool": 1,
}

var _passed: int = 0
var _failed: int = 0


class RangeLOSStub:
	extends RefCounted

	var last_range: float = 0.0
	var call_count: int = 0
	var force_blocked: bool = false

	func has_line_of_sight_between_nodes(attacker, target, range_value: float, _terrain_registry = null) -> bool:
		call_count += 1
		last_range = range_value
		if force_blocked:
			return false
		if attacker is Node2D and target is Node2D:
			return (attacker as Node2D).global_position.distance_to((target as Node2D).global_position) <= range_value
		return true


class SimulationStub:
	extends RefCounted

	var effects: Array = []

	func enqueue_effect(effect_dict: Dictionary) -> void:
		effects.append(effect_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_201 Weapon Range Scale and Tile Distance Patch ===")
	_test_weapon_tile_range_contract()
	_test_combat_uses_attacker_weapon_range()
	_test_combat_respects_los_and_keeps_stealth_detection_separate()
	_test_overwatch_uses_weapon_range()
	_test_medictool_adjacent_tile_contract()
	_test_multiplayer_snapshot_carries_range_diagnostics_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_weapon_tile_range_contract() -> void:
	var terrain_registry = _make_terrain_registry()
	var world_units_per_tile: float = float(WEAPON_DATA_SCRIPT.call("get_world_units_per_tile", terrain_registry))
	_assert(world_units_per_tile > 64.0 and world_units_per_tile < 80.0, "Terrain-derived world units per tile come from iso grid spacing")
	for weapon_id_variant in EXPECTED_TILE_RANGES.keys():
		var weapon_id: String = String(weapon_id_variant)
		var expected_range: int = int(EXPECTED_TILE_RANGES[weapon_id])
		_assert(int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id)) == expected_range, "%s has expected tile range %d" % [weapon_id, expected_range])
		var world_range: float = float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", weapon_id, terrain_registry))
		_assert(absf(world_range - (float(expected_range) * world_units_per_tile)) < 0.01, "%s world range derives from tile range" % weapon_id)
	_assert(String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", "support_lmg")) == "rail_gun", "Support LMG alias resolves to the existing support weapon ID")


func _test_combat_uses_attacker_weapon_range() -> void:
	var los := RangeLOSStub.new()
	var terrain_registry = _make_terrain_registry()
	var smg_attacker = _make_unit("smg_attacker", "team_alpha", "smg", Vector2.ZERO)
	var rifle_attacker = _make_unit("rifle_attacker", "team_alpha", "rifle", Vector2.ZERO)
	var sniper_attacker = _make_unit("sniper_attacker", "team_alpha", "sniper", Vector2.ZERO)
	var target = _make_unit("target_enemy", "team_bravo", "rifle", Vector2(1000.0, 0.0))
	var context: Dictionary = _build_combat_context(los, terrain_registry)
	_assert(not bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", smg_attacker, target, context)), "SMG cannot attack at rifle-range distance")
	_assert(bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", rifle_attacker, target, context)), "Rifle can attack beyond SMG range")
	target.global_position = Vector2(2200.0, 0.0)
	_assert(not bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", rifle_attacker, target, context)), "Rifle cannot attack at sniper-only distance")
	_assert(bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", sniper_attacker, target, context)), "Sniper can attack at long tile distance")
	var decision: Dictionary = COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("build_damage_effect", {"attacker": sniper_attacker, "target": target, "attacker_id": "sniper_attacker", "target_id": "target_enemy"}, context)
	_assert(String(Dictionary(decision.get("effect", {})).get("weapon_id", "")) == "sniper", "Damage effect records authoritative active weapon")
	_assert(int(Dictionary(decision.get("effect", {})).get("weapon_tile_range", 0)) == 40, "Damage effect records authoritative weapon tile range")
	_cleanup_units([smg_attacker, rifle_attacker, sniper_attacker, target])


func _test_combat_respects_los_and_keeps_stealth_detection_separate() -> void:
	var los := RangeLOSStub.new()
	var terrain_registry = _make_terrain_registry()
	var attacker = _make_unit("rifle_probe", "team_alpha", "rifle", Vector2.ZERO)
	var target = _make_unit("stealth_target", "team_bravo", "rifle", Vector2(1000.0, 0.0))
	target.stealth = 1.0
	var context: Dictionary = _build_combat_context(los, terrain_registry)
	_assert(bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", attacker, target, context)), "Target stealth no longer shrinks active weapon attack range")
	_assert(absf(los.last_range - float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", "rifle", terrain_registry))) < 0.01, "Combat LOS receives rifle weapon range, not contact range")
	los.force_blocked = true
	_assert(not bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", attacker, target, context)), "Blocked LOS still prevents weapon-range fire")
	var stealth_detection_range: float = _legacy_detection_range(180.0, target)
	_assert(absf(stealth_detection_range - 90.0) < 0.01, "Stealth remains a contact/detection fallback, not weapon balance")
	_cleanup_units([attacker, target])


func _test_overwatch_uses_weapon_range() -> void:
	var terrain_registry = _make_terrain_registry()
	var simulation = SimulationStub.new()
	var controller = OVERWATCH_CONTROLLER_SCRIPT.new()
	var rifle_member = _make_unit("rifle_overwatch", "team_alpha", "rifle", Vector2.ZERO)
	var sniper_member = _make_unit("sniper_overwatch", "team_alpha", "sniper", Vector2.ZERO)
	var enemy = _make_unit("enemy_runner_201", "team_bravo", "rifle", Vector2(1900.0, 0.0))
	var security_state: Dictionary = {
		"fireteam_id": "blue",
		"overwatch_ready": true,
		"anchor_position": Vector2.ZERO,
		"member_assignments": [{"unit_id": "rifle_overwatch", "center_angle": 0.0, "arc_width": TAU}],
	}
	controller.call("update", simulation, [security_state], {"blue": [rifle_member]}, [enemy], terrain_registry, 9999.0, 1)
	enemy.global_position = Vector2(1950.0, 0.0)
	var rifle_shots: Array = Array(controller.call("update", simulation, [security_state], {"blue": [rifle_member]}, [enemy], terrain_registry, 9999.0, 2))
	_assert(rifle_shots.is_empty(), "Overwatch ignores base contact range and blocks rifle at sniper-only distance")

	var sniper_controller = OVERWATCH_CONTROLLER_SCRIPT.new()
	var sniper_state: Dictionary = security_state.duplicate(true)
	sniper_state["member_assignments"] = [{"unit_id": "sniper_overwatch", "center_angle": 0.0, "arc_width": TAU}]
	sniper_controller.call("update", simulation, [sniper_state], {"blue": [sniper_member]}, [enemy], terrain_registry, 9999.0, 1)
	enemy.global_position = Vector2(2000.0, 0.0)
	var sniper_shots: Array = Array(sniper_controller.call("update", simulation, [sniper_state], {"blue": [sniper_member]}, [enemy], terrain_registry, 9999.0, 2))
	_assert(sniper_shots.size() == 1, "Sniper overwatch can fire at the same long tile distance")
	if not sniper_shots.is_empty():
		var shot: Dictionary = Dictionary(sniper_shots[0])
		_assert(String(shot.get("weapon_id", "")) == "sniper", "Overwatch shot records active weapon")
		_assert(int(shot.get("weapon_tile_range", 0)) == 40, "Overwatch shot records tile range")
	_cleanup_units([rifle_member, sniper_member, enemy])


func _test_medictool_adjacent_tile_contract() -> void:
	var terrain_registry = _make_terrain_registry()
	var medic = _make_unit("medic_201", "team_alpha", "medictool", Vector2.ZERO)
	medic.role_id = "combat_medic"
	medic.role_name = "Medic"
	medic.weapon_1_id = "rifle"
	medic.weapon_2_id = "medictool"
	var adjacent = _make_unit("adjacent_patient", "team_alpha", "rifle", terrain_registry.call("grid_to_world", Vector2i(1, 0)))
	var distant = _make_unit("distant_patient", "team_alpha", "rifle", terrain_registry.call("grid_to_world", Vector2i(2, 0)))
	adjacent.call("apply_damage", 20, {})
	distant.call("apply_damage", 20, {})
	_assert(int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", "medictool")) == 1, "Medictool exposes 1-tile support range")
	_assert(bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("is_within_medic_support_range", medic, adjacent, terrain_registry)), "Medictool support accepts orthogonal adjacent tile")
	_assert(not bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("is_within_medic_support_range", medic, distant, terrain_registry)), "Medictool support rejects two-tile direct healing")
	_assert(not bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", "medictool")), "Medictool is not treated as an attack weapon")
	_cleanup_units([medic, adjacent, distant])


func _test_multiplayer_snapshot_carries_range_diagnostics_only() -> void:
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = contract.call(
		"build_state_snapshot",
		{
			"tick": 7,
			"units": [
				{
					"unit_id": "range_probe",
					"active_weapon_id": "sniper",
					"weapon_tile_range": 40,
					"weapon_range_world": 2880.0,
					"client_can_fire": true,
				}
			],
		}
	)
	var unit_snapshot: Dictionary = Dictionary(Array(snapshot.get("units", []))[0])
	_assert(String(unit_snapshot.get("active_weapon_id", "")) == "sniper", "Snapshot preserves active weapon as display/diagnostic data")
	_assert(int(unit_snapshot.get("weapon_tile_range", 0)) == 40, "Snapshot preserves tile range diagnostic")
	_assert(absf(float(unit_snapshot.get("weapon_range_world", 0.0)) - 2880.0) < 0.01, "Snapshot preserves world range diagnostic")
	_assert(not unit_snapshot.has("client_can_fire"), "Snapshot contract rejects client-side range decisions")


func _build_combat_context(los: RangeLOSStub, terrain_registry) -> Dictionary:
	return {
		"friendly_team_id": "team_alpha",
		"contact_range": 9999.0,
		"los_system": los,
		"terrain_registry": terrain_registry,
	}


func _legacy_detection_range(contact_range: float, target) -> float:
	var target_stealth: float = 0.0
	if target != null and target.has_method("get_stealth"):
		target_stealth = clampf(float(target.call("get_stealth")), 0.0, 1.0)
	return contact_range * (1.0 - target_stealth * 0.5)


func _make_terrain_registry():
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0)
	return registry


func _make_unit(unit_id: String, team_id: String, weapon_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = weapon_id
	unit.weapon_2_id = "smg"
	unit.global_position = position_value
	unit._ready()
	unit.call("set_runtime_status", "holding", "hold_position")
	root.add_child(unit)
	return unit


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
