extends SceneTree

const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Medic Support Verifier ===")
	_test_heal_effect_revives_before_bleedout()
	_test_combat_loop_enqueues_medic_support_for_downed_ally()
	_test_medic_support_cooldown_blocks_immediate_repeat()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_heal_effect_revives_before_bleedout() -> void:
	var context: Dictionary = _make_simulation_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var patient = _make_unit("patient", "team_alpha", "Operator", Vector2.ZERO)
	unit_registry.register_unit(patient.get_unit_id(), patient)
	patient.apply_damage(patient.get_max_health_points())
	simulation_root.call(
		"_process_effects",
		[
			{"effect_type": "bleedout", "priority": 20, "unit_id": patient.get_unit_id()},
			{"effect_type": "heal", "priority": 25, "unit_id": patient.get_unit_id(), "healer_unit_id": "medic", "healer_team_id": "team_alpha", "amount": 35},
		],
		0.0
	)
	_assert(patient.get_vital_state() == "fit", "Heal effect resolves before bleedout and revives the target")
	_assert(patient.get_health() == 35, "Heal effect restores positive health after revive")
	_cleanup_context(context, [patient])


func _test_combat_loop_enqueues_medic_support_for_downed_ally() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var medic = _make_unit("medic", "team_alpha", "Combat Medic", Vector2.ZERO)
	var patient = _make_unit("patient", "team_alpha", "Operator", Vector2(24.0, 0.0))
	context["scene"].add_child(medic)
	context["scene"].add_child(patient)
	unit_registry.register_unit(medic.get_unit_id(), medic)
	unit_registry.register_unit(patient.get_unit_id(), patient)
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	var queued_effects: Array = simulation_root.effects_queue
	_assert(queued_effects.size() == 1, "Combat loop enqueues one medic heal effect for a nearby downed ally")
	if not queued_effects.is_empty():
		var effect: Dictionary = queued_effects[0]
		_assert(String(effect.get("effect_type", "")) == "heal", "Queued support effect uses heal type")
		_assert(String(effect.get("unit_id", "")) == patient.get_unit_id(), "Medic targets the downed ally")
	_cleanup_context(context, [medic, patient])


func _test_medic_support_cooldown_blocks_immediate_repeat() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var medic = _make_unit("medic", "team_alpha", "Combat Medic", Vector2.ZERO)
	var patient = _make_unit("patient", "team_alpha", "Operator", Vector2(24.0, 0.0))
	context["scene"].add_child(medic)
	context["scene"].add_child(patient)
	unit_registry.register_unit(medic.get_unit_id(), medic)
	unit_registry.register_unit(patient.get_unit_id(), patient)
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	var first_queue_size: int = simulation_root.effects_queue.size()
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	var cooldown: Dictionary = driver.call("get_medic_support_cooldown")
	_assert(int(cooldown.get(medic.get_unit_id(), 0)) > 0, "Medic cooldown is set after support action")
	_assert(simulation_root.effects_queue.size() == first_queue_size, "Medic cooldown blocks immediate repeated support")
	_cleanup_context(context, [medic, patient])


func _make_simulation_context() -> Dictionary:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	simulation_root.add_child(unit_registry)
	simulation_root.unit_registry_path = NodePath("UnitRegistry")
	root.add_child(simulation_root)
	return {
		"scene": simulation_root,
		"simulation_root": simulation_root,
		"unit_registry": unit_registry,
	}


func _make_scene_context() -> Dictionary:
	var scene = Node2D.new()
	scene.name = "MedicVerifierScene%d" % (_passed + _failed)
	root.add_child(scene)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	simulation_root.add_child(unit_registry)
	simulation_root.unit_registry_path = NodePath("UnitRegistry")
	scene.add_child(simulation_root)
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "MissionCombatLoopDriver"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	scene.add_child(driver)
	return {
		"scene": scene,
		"simulation_root": simulation_root,
		"unit_registry": unit_registry,
		"driver": driver,
	}


func _make_unit(unit_id: String, team_id: String, role_name: String, position_value: Vector2) -> Node:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id.capitalize()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.role_name = role_name
	unit.position = position_value
	return unit


func _cleanup_context(context: Dictionary, units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)