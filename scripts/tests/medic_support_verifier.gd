extends SceneTree

const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const FOB_SCREEN_SCRIPT: GDScript = preload("res://scripts/meta/fob_screen.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Medic Support Verifier ===")
	_test_heal_effect_revives_before_bleedout()
	_test_fob_loadout_dropdown_includes_medictool()
	_test_combat_medic_requires_medictool_for_support()
	_test_medic_support_reaches_exactly_two_tiles()
	_test_combat_loop_enqueues_medic_support_for_downed_ally()
	_test_medictool_in_primary_slot_keeps_rifle_active()
	_test_medic_support_moves_toward_downed_ally_out_of_range()
	_test_medic_support_prioritizes_most_wounded_ally()
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


func _test_fob_loadout_dropdown_includes_medictool() -> void:
	var fob_screen = FOB_SCREEN_SCRIPT.new()
	var option_button := OptionButton.new()
	fob_screen.call("_populate_weapon_option_button", option_button, "medictool")
	_assert(option_button.item_count == 2, "FOB loadout dropdown offers SMG and medictool")
	_assert(option_button.get_item_text(1) == "Medictool", "FOB loadout dropdown labels medictool visibly")
	_assert(option_button.get_selected_id() == 1, "FOB loadout dropdown can preselect medictool")
	fob_screen.queue_free()
	option_button.queue_free()


func _test_combat_medic_requires_medictool_for_support() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var medic = _make_unit("medic", "team_alpha", "Combat Medic", Vector2.ZERO, "rifle", "rifle")
	var patient = _make_unit("patient", "team_alpha", "Operator", Vector2(24.0, 0.0))
	context["scene"].add_child(medic)
	context["scene"].add_child(patient)
	unit_registry.register_unit(medic.get_unit_id(), medic)
	unit_registry.register_unit(patient.get_unit_id(), patient)
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(simulation_root.effects_queue.is_empty(), "Combat medic without medictool does not enqueue heal support")
	_assert(simulation_root.command_queue.is_empty(), "Combat medic without medictool does not auto-run as healer")
	_cleanup_context(context, [medic, patient])


func _test_medic_support_reaches_exactly_two_tiles() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_tiles", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var patient_in_range = _make_unit("patient_two_tiles", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(2, 0)))
	var patient_out_of_range = _make_unit("patient_three_tiles", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(3, 0)))
	context["scene"].add_child(medic)
	context["scene"].add_child(patient_in_range)
	context["scene"].add_child(patient_out_of_range)
	unit_registry.register_unit(medic.get_unit_id(), medic)
	unit_registry.register_unit(patient_in_range.get_unit_id(), patient_in_range)
	unit_registry.register_unit(patient_out_of_range.get_unit_id(), patient_out_of_range)
	patient_in_range.apply_damage(patient_in_range.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient_in_range], {})
	_assert(simulation_root.effects_queue.size() == 1, "Medic heal reaches a target exactly two tiles away")
	simulation_root.clear_queues()
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	driver.call("_advance_medic_support_cooldowns")
	patient_out_of_range.apply_damage(patient_out_of_range.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient_out_of_range], {})
	_assert(simulation_root.effects_queue.is_empty(), "Medic heal does not reach a target three tiles away")
	_assert(simulation_root.command_queue.size() == 1, "Medic starts moving when the target is beyond two tiles")
	_cleanup_context(context, [medic, patient_in_range, patient_out_of_range])


func _test_combat_loop_enqueues_medic_support_for_downed_ally() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var patient = _make_unit("patient", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(1, 0)))
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
		_assert(String(effect.get("support_resource", "")) == "medictool", "Queued support effect records medictool as required support resource")
	_cleanup_context(context, [medic, patient])


func _test_medictool_in_primary_slot_keeps_rifle_active() -> void:
	var medic = _make_unit("medic_primary", "team_alpha", "Combat Medic", Vector2.ZERO, "medictool", "rifle")
	_assert(medic.has_medic_tool(), "Medictool counts as equipped loadout item in a weapon slot")
	_assert(medic.get_active_weapon_id() == "rifle", "Medictool in primary slot still leaves rifle as active combat weapon")
	medic.queue_free()


func _test_medic_support_moves_toward_downed_ally_out_of_range() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_runner", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var patient = _make_unit("patient_far", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(3, 0)))
	context["scene"].add_child(medic)
	context["scene"].add_child(patient)
	unit_registry.register_unit(medic.get_unit_id(), medic)
	unit_registry.register_unit(patient.get_unit_id(), patient)
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(simulation_root.effects_queue.is_empty(), "Out-of-range downed ally does not receive an instant heal effect")
	_assert(simulation_root.command_queue.size() == 1, "Medic enqueues a move command toward an out-of-range downed ally")
	if not simulation_root.command_queue.is_empty():
		var command: Dictionary = simulation_root.command_queue[0]
		var target_position: Vector2 = Vector2(command.get("target_position", Vector2.ZERO))
		_assert(String(command.get("command_type", "")) == "move_to_position", "Medic move command uses move_to_position")
		_assert(String(command.get("unit_id", "")) == medic.get_unit_id(), "Medic move command is addressed to the medic")
		_assert(target_position.distance_to(patient.global_position) < medic.global_position.distance_to(patient.global_position), "Medic move command closes distance to the patient")
	_cleanup_context(context, [medic, patient])


func _test_medic_support_prioritizes_most_wounded_ally() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_priority", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var lightly_wounded = _make_unit("patient_light", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(1, 0)))
	var heavily_wounded = _make_unit("patient_heavy", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(2, 0)))
	context["scene"].add_child(medic)
	context["scene"].add_child(lightly_wounded)
	context["scene"].add_child(heavily_wounded)
	unit_registry.register_unit(medic.get_unit_id(), medic)
	unit_registry.register_unit(lightly_wounded.get_unit_id(), lightly_wounded)
	unit_registry.register_unit(heavily_wounded.get_unit_id(), heavily_wounded)
	lightly_wounded.apply_damage(50)
	heavily_wounded.apply_damage(80)
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, lightly_wounded, heavily_wounded], {})
	_assert(simulation_root.effects_queue.size() == 1, "Medic support picks one wounded ally when multiple are in range")
	if not simulation_root.effects_queue.is_empty():
		var effect: Dictionary = simulation_root.effects_queue[0]
		_assert(String(effect.get("unit_id", "")) == heavily_wounded.get_unit_id(), "Medic prioritizes the most wounded fit ally in range")
	_cleanup_context(context, [medic, lightly_wounded, heavily_wounded])


func _test_medic_support_cooldown_blocks_immediate_repeat() -> void:
	var context: Dictionary = _make_scene_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var patient = _make_unit("patient", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(1, 0)))
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
	var terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	terrain_registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	scene.add_child(terrain_registry)
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
	driver.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(driver)
	return {
		"scene": scene,
		"simulation_root": simulation_root,
		"unit_registry": unit_registry,
		"driver": driver,
		"terrain_registry": terrain_registry,
	}


func _make_unit(unit_id: String, team_id: String, role_name: String, position_value: Vector2, weapon_1_id: String = "rifle", weapon_2_id: String = "rifle") -> Node:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id.capitalize()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.role_name = role_name
	unit.weapon_1_id = weapon_1_id
	unit.weapon_2_id = weapon_2_id
	unit.position = position_value
	return unit


func _cleanup_context(context: Dictionary, units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()


func _grid_to_world(terrain_registry, grid_position: Vector2i) -> Vector2:
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return Vector2.ZERO
	return Vector2(terrain_registry.call("grid_to_world", grid_position))


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
