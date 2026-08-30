extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const OVERWATCH_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/overwatch_controller.gd")

var _passed: int = 0
var _failed: int = 0


class LosAlways:
	extends RefCounted

	func has_line_of_sight_between_nodes(_attacker, _target, _range: float, _terrain_registry = null) -> bool:
		return true


class SimulationSpy:
	extends RefCounted
	var effects: Array = []

	func enqueue_effect(effect: Dictionary) -> void:
		effects.append(effect.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_119 Seeded Combat RNG Verifier ===")
	_test_same_seed_replays_same_damage_result()
	_test_different_seeds_can_change_damage_result()
	_test_roll_override_remains_explicit_test_payload()
	_test_live_fire_decision_payload_omits_roll_override()
	_test_overwatch_payload_omits_roll_override()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_same_seed_replays_same_damage_result() -> void:
	var first: int = _run_seeded_damage_once(5, 0.5)
	var second: int = _run_seeded_damage_once(5, 0.5)
	_assert(first == second, "Same combat RNG seed replays the same damage result")


func _test_different_seeds_can_change_damage_result() -> void:
	var baseline: int = _run_seeded_damage_once(5, 0.5)
	var found_difference := false
	for seed_value in range(6, 80):
		if _run_seeded_damage_once(seed_value, 0.5) != baseline:
			found_difference = true
			break
	_assert(found_difference, "Different combat RNG seeds can change a probabilistic damage result")


func _test_roll_override_remains_explicit_test_payload() -> void:
	var miss_damage: int = _run_seeded_damage_once(5, 0.95, 1.0)
	var hit_damage: int = _run_seeded_damage_once(5, 0.05, 0.0)
	_assert(miss_damage == 0, "Explicit test roll_override can force a miss")
	_assert(hit_damage > 0, "Explicit test roll_override can force a hit")


func _test_live_fire_decision_payload_omits_roll_override() -> void:
	var attacker := _make_unit("rng_attacker", "team_alpha", "blue", Vector2.ZERO)
	var target := _make_unit("rng_target", "team_bravo", "red", Vector2(24.0, 0.0))
	attacker.call("set_runtime_status", "engaging")
	var decision: Dictionary = Dictionary(
		COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call(
			"build_damage_effect",
			{
				"attacker": attacker,
				"target": target,
				"attacker_id": attacker.get_unit_id(),
				"target_id": target.get_unit_id(),
				"contact_state": "confirmed",
			},
			{
				"friendly_team_id": "team_alpha",
				"base_damage_multiplier": 1.0,
				"spotted_contact_hit_chance_malus": -0.15,
				"check_misidentification": Callable(self, "_empty_misidentification"),
				"resolve_flank_attack": Callable(self, "_empty_flank"),
			}
		)
	)
	var effect: Dictionary = Dictionary(decision.get("effect", {}))
	_assert(not effect.has("roll_override"), "Live fire decision payload does not set roll_override")
	attacker.free()
	target.free()


func _test_overwatch_payload_omits_roll_override() -> void:
	var simulation := SimulationSpy.new()
	var controller = OVERWATCH_CONTROLLER_SCRIPT.new()
	var member := _make_unit("rng_overwatch", "team_alpha", "blue", Vector2.ZERO)
	var enemy := _make_unit("rng_enemy", "team_bravo", "red", Vector2(40.0, 0.0))
	controller.call("update", null, [], {}, [enemy], null, 180.0, 1)
	enemy.global_position = Vector2(70.0, 0.0)
	var shots: Array = Array(
		controller.call(
			"update",
			simulation,
			[
				{
					"fireteam_id": "blue",
					"overwatch_ready": true,
					"anchor_position": Vector2.ZERO,
					"member_assignments": [{"unit_id": member.get_unit_id(), "center_angle": 0.0, "arc_width": TAU}],
				}
			],
			{"blue": [member]},
			[enemy],
			null,
			180.0,
			2
		)
	)
	_assert(shots.size() == 1, "Overwatch test setup triggers one shot")
	_assert(simulation.effects.size() == 1 and not Dictionary(simulation.effects[0]).has("roll_override"), "Overwatch damage payload does not set roll_override")
	member.free()
	enemy.free()


func _run_seeded_damage_once(seed_value: int, hit_chance: float, roll_override: float = -1.0) -> int:
	var root := Node.new()
	get_root().add_child(root)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	root.add_child(registry)
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	root.add_child(simulation)
	simulation.call("set_combat_rng_seed", seed_value)
	var attacker := _make_unit("seed_attacker", "team_alpha", "blue", Vector2.ZERO)
	var target := _make_unit("seed_target", "team_bravo", "red", Vector2(24.0, 0.0))
	root.add_child(attacker)
	root.add_child(target)
	registry.call("register_unit", attacker.get_unit_id(), attacker)
	registry.call("register_unit", target.get_unit_id(), target)
	var effect: Dictionary = {
		"effect_type": "damage",
		"unit_id": target.get_unit_id(),
		"attacker_unit_id": attacker.get_unit_id(),
		"attacker_team_id": attacker.get_team_id(),
		"damage": 30,
		"hit_chance": hit_chance,
		"damage_multiplier": 1.0,
		"target_cover_override": 0.0,
	}
	if roll_override >= 0.0:
		effect["roll_override"] = roll_override
	simulation.call("_apply_damage_effect", effect)
	var damage_taken: int = target.get_max_health_points() - target.get_health()
	root.free()
	return damage_taken


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	return unit


func _empty_misidentification(_attacker, _attacker_id: String) -> Dictionary:
	return {}


func _empty_flank(_attacker, _target) -> Dictionary:
	return {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
