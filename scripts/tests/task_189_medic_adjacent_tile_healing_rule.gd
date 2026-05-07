extends SceneTree

const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_189 Medic Adjacent Tile Healing Rule ===")
	_test_adjacent_target_receives_structured_heal_effect()
	_test_two_tile_target_gets_move_not_heal()
	_test_medictool_required_for_support()
	_test_enemy_team_target_is_ignored()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_adjacent_target_receives_structured_heal_effect() -> void:
	var context: Dictionary = _make_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_adjacent", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var patient = _make_unit("patient_adjacent", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(1, 0)))
	_attach_units(context, unit_registry, [medic, patient])
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(simulation_root.effects_queue.size() == 1, "Adjacent wounded ally receives one direct medic heal")
	_assert(simulation_root.command_queue.is_empty(), "Adjacent heal does not enqueue a move command")
	if not simulation_root.effects_queue.is_empty():
		var effect: Dictionary = simulation_root.effects_queue[0]
		_assert(String(effect.get("effect_type", "")) == "heal", "Adjacent support effect is a heal")
		_assert(String(effect.get("unit_id", "")) == patient.get_unit_id(), "Adjacent support targets the wounded ally")
		_assert(String(effect.get("healer_unit_id", "")) == medic.get_unit_id(), "Adjacent support records healer_unit_id")
		_assert(String(effect.get("healer_team_id", "")) == medic.get_team_id(), "Adjacent support records healer_team_id")
		_assert(String(effect.get("support_resource", "")) == "medictool", "Adjacent support records medictool resource")
	_cleanup_context(context)


func _test_two_tile_target_gets_move_not_heal() -> void:
	var context: Dictionary = _make_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_two_tile", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var patient = _make_unit("patient_two_tile", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(2, 0)))
	_attach_units(context, unit_registry, [medic, patient])
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(simulation_root.effects_queue.is_empty(), "Two-tile wounded ally does not receive an instant heal")
	_assert(simulation_root.command_queue.size() == 1, "Two-tile wounded ally triggers a medic move")
	if not simulation_root.command_queue.is_empty():
		var command: Dictionary = simulation_root.command_queue[0]
		var move_grid: Vector2i = _world_to_grid(terrain_registry, Vector2(command.get("target_position", Vector2.ZERO)))
		var patient_grid: Vector2i = _world_to_grid(terrain_registry, patient.global_position)
		_assert(String(command.get("command_type", "")) == "move_to_position", "Out-of-range support uses move_to_position")
		_assert(String(command.get("unit_id", "")) == medic.get_unit_id(), "Out-of-range support moves the medic")
		_assert(_grid_distance(move_grid, patient_grid) == 1, "Out-of-range support moves to a neighbor tile of the patient")
		_assert(bool(terrain_registry.call("is_walkable", move_grid)), "Out-of-range support target tile is walkable")
	_cleanup_context(context)


func _test_medictool_required_for_support() -> void:
	var context: Dictionary = _make_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_without_tool", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "rifle")
	var patient = _make_unit("patient_no_tool", "team_alpha", "Operator", _grid_to_world(terrain_registry, Vector2i(1, 0)))
	_attach_units(context, unit_registry, [medic, patient])
	patient.apply_damage(patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(simulation_root.effects_queue.is_empty(), "Combat Medic without medictool does not heal")
	_assert(simulation_root.command_queue.is_empty(), "Combat Medic without medictool does not move as support")
	_cleanup_context(context)


func _test_enemy_team_target_is_ignored() -> void:
	var context: Dictionary = _make_context()
	var simulation_root = context["simulation_root"]
	var unit_registry = context["unit_registry"]
	var driver = context["driver"]
	var terrain_registry = context["terrain_registry"]
	var medic = _make_unit("medic_team_filter", "team_alpha", "Combat Medic", _grid_to_world(terrain_registry, Vector2i.ZERO), "rifle", "medictool")
	var enemy_patient = _make_unit("enemy_patient", "team_bravo", "Operator", _grid_to_world(terrain_registry, Vector2i(1, 0)))
	_attach_units(context, unit_registry, [medic, enemy_patient])
	enemy_patient.apply_damage(enemy_patient.get_max_health_points())
	driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, enemy_patient], {})
	_assert(simulation_root.effects_queue.is_empty(), "Enemy-team target is not healed")
	_assert(simulation_root.command_queue.is_empty(), "Enemy-team target does not trigger a medic move")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var scene = Node2D.new()
	scene.name = "Task189MedicScene%d" % (_passed + _failed)
	root.add_child(scene)
	var terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	terrain_registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	_register_walkable_test_tiles(terrain_registry)
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


func _attach_units(context: Dictionary, unit_registry, units: Array) -> void:
	var scene: Node = context["scene"]
	for unit in units:
		scene.add_child(unit)
		unit_registry.register_unit(unit.get_unit_id(), unit)


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


func _register_walkable_test_tiles(terrain_registry) -> void:
	for x in range(-2, 6):
		for y in range(-2, 6):
			var grid_position := Vector2i(x, y)
			var tile_data = TERRAIN_TILE_DATA_SCRIPT.new(
				{
					"tile_id": "task189_tile_%d_%d" % [x, y],
					"type_id": "ground_flat",
					"grid_position": grid_position,
					"world_position": _grid_to_world(terrain_registry, grid_position),
					"walkable": true,
					"surface_type": "ground",
				}
			)
			terrain_registry.call("register_tile", tile_data)


func _grid_to_world(terrain_registry, grid_position: Vector2i) -> Vector2:
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return Vector2.ZERO
	return Vector2(terrain_registry.call("grid_to_world", grid_position))


func _world_to_grid(terrain_registry, world_position: Vector2) -> Vector2i:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return Vector2i.ZERO
	return Vector2i(terrain_registry.call("world_to_grid", world_position))


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	var delta: Vector2i = a - b
	return absi(delta.x) + absi(delta.y)


func _cleanup_context(context: Dictionary) -> void:
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
