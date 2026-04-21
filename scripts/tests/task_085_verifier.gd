extends SceneTree

const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_085 Bundle Combat Runtime Verifier ===")
	_test_combat_effects_include_accuracy_multiplier()
	_test_speed_multiplier_uses_profile_pipeline()
	_test_damage_taken_multiplier_uses_profile_pipeline()
	_test_simulation_root_prefers_bundle_values()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_combat_effects_include_accuracy_multiplier() -> void:
	var unit = _make_unit({"skill_accuracy": 0.8})
	var effects: Dictionary = unit.get_combat_effects()
	var expected: float = UNIT_PROFILE_MATH_SCRIPT.accuracy_to_hit_chance_multiplier(unit.get_accuracy_skill())
	_assert(absf(float(effects.get("hit_chance_multiplier", -1.0)) - expected) < 0.001, "combat_effects expose hit_chance_multiplier")
	unit.queue_free()


func _test_speed_multiplier_uses_profile_pipeline() -> void:
	var unit = _make_unit({"skill_speed": 0.8, "skill_leadership": 0.7, "awareness": 0.6})
	var bundle: Dictionary = unit.get_character_profile_bundle()
	var core_values: Dictionary = Dictionary(bundle.get("core_values", {}))
	var behavior_axes: Dictionary = Dictionary(bundle.get("behavior_axes", {}))
	var expected: float = UNIT_PROFILE_MATH_SCRIPT.base_speed_to_speed_multiplier(float(core_values.get("speed", 0.0)))
	expected *= UNIT_PROFILE_MATH_SCRIPT.initiative_to_speed_multiplier(float(behavior_axes.get("initiative", 0.0)))
	_assert(absf(unit.get_combat_speed_multiplier() - expected) < 0.001, "speed multiplier combines base speed and initiative")
	unit.queue_free()


func _test_damage_taken_multiplier_uses_profile_pipeline() -> void:
	var unit = _make_unit({"skill_toughness": 0.75, "discipline": 0.8, "awareness": 0.7})
	var bundle: Dictionary = unit.get_character_profile_bundle()
	var core_values: Dictionary = Dictionary(bundle.get("core_values", {}))
	var behavior_axes: Dictionary = Dictionary(bundle.get("behavior_axes", {}))
	var expected: float = UNIT_PROFILE_MATH_SCRIPT.toughness_to_damage_taken_multiplier(float(core_values.get("toughness", 0.0)))
	expected *= UNIT_PROFILE_MATH_SCRIPT.contact_stability_to_damage_taken_multiplier(float(behavior_axes.get("contact_stability", 0.0)))
	_assert(absf(unit.get_combat_damage_taken_multiplier() - expected) < 0.001, "damage_taken multiplier combines toughness and contact stability")
	unit.queue_free()


func _test_simulation_root_prefers_bundle_values() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var unit = _make_unit({
		"skill_accuracy": 0.7,
		"skill_speed": 0.65,
		"skill_toughness": 0.8,
		"discipline": 0.9,
		"recognition": 0.8,
		"stealth": 0.7,
	})
	_assert(absf(float(simulation_root.call("_extract_unit_accuracy_multiplier", unit)) - unit.get_combat_hit_chance_multiplier()) < 0.001, "SimulationRoot uses bundle hit chance multiplier")
	_assert(absf(float(simulation_root.call("_extract_unit_speed_multiplier", unit)) - unit.get_combat_speed_multiplier()) < 0.001, "SimulationRoot uses bundle speed multiplier")
	_assert(absf(float(simulation_root.call("_extract_unit_hit_modifier", unit)) - unit.get_combat_hit_modifier()) < 0.001, "SimulationRoot uses bundle hit modifier")
	_assert(absf(float(simulation_root.call("_extract_unit_evasion_modifier", unit)) - unit.get_combat_evasion_modifier()) < 0.001, "SimulationRoot uses bundle evasion modifier")
	_assert(absf(float(simulation_root.call("_extract_unit_damage_taken_multiplier", unit)) - unit.get_combat_damage_taken_multiplier()) < 0.001, "SimulationRoot uses bundle damage multiplier")
	unit.queue_free()


func _make_unit(overrides: Dictionary) -> Node:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = "verify_unit_%d" % (_passed + _failed)
	unit.team_id = "team_alpha"
	for key in overrides.keys():
		unit.set(String(key), overrides[key])
	root.add_child(unit)
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)