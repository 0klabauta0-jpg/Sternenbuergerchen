extends SceneTree

const COMMAND_TRANSLATOR_SCRIPT: GDScript = preload("res://scripts/command/command_to_ftltask_translator.gd")
const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_141 2.5D Air Layer V1 Verifier ===")
	_test_command_contract_carries_air_layer()
	_test_air_unit_moves_over_ground_blocker()
	_test_air_unit_clamps_to_mission_bounds()
	_test_anti_air_gate_blocks_ground_fire_without_aa()
	_test_layered_los_ignores_ground_blocker_for_air()
	_test_air_visual_marker_is_created()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_command_contract_carries_air_layer() -> void:
	var command = COMMANDER_COMMAND_SCRIPT.new({
		"command_type": "move",
		"unit_id": "air_1",
		"team_id": "team_alpha",
		"target_position": Vector2(128.0, 64.0),
		"movement_layer": "air",
		"altitude_band": 3,
	})
	var translator = COMMAND_TRANSLATOR_SCRIPT.new()
	var task = translator.call("translate", command)
	var unit_command = UNIT_COMMAND_SCRIPT.new({
		"command_type": "move_to_position",
		"unit_id": "air_1",
		"team_id": "team_alpha",
		"target_position": Vector2(128.0, 64.0),
		"movement_layer": "air",
		"altitude_band": 3,
	})
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new({
		"status": "pending_move",
		"target_position": Vector2(128.0, 64.0),
		"movement_layer": "air",
		"altitude_band": 3,
	})
	_assert(command.is_valid() and String(command.to_dict().get("movement_layer", "")) == "air", "CommanderCommand accepts air movement layer")
	_assert(task != null and String(task.get("movement_layer")) == "air" and int(task.get("altitude_band")) == 3, "Command translator preserves air layer")
	_assert(unit_command.is_valid() and String(unit_command.to_dict().get("movement_layer", "")) == "air", "UnitCommand roundtrip carries air layer")
	_assert(runtime_status.is_valid() and int(runtime_status.to_dict().get("altitude_band", -1)) == 3, "UnitRuntimeStatus roundtrip carries altitude band")


func _test_air_unit_moves_over_ground_blocker() -> void:
	var context: Dictionary = _make_simulation_context()
	var sim: Node = context["sim"]
	var unit: Node2D = context["air_unit"]
	var registry = context["terrain_registry"]
	unit.global_position = registry.call("grid_to_world", Vector2i(0, 0))
	var target: Vector2 = registry.call("grid_to_world", Vector2i(2, 0))
	sim.call("enqueue_command", {
		"command_type": "move_to_position",
		"unit_id": "air_1",
		"target_position": target,
		"movement_layer": "air",
		"altitude_band": 2,
		"move_speed_factor": 10.0,
		"requeue_until_target": false,
	})
	sim.call("_physics_process", 1.0)
	var debug: Dictionary = Dictionary(sim.call("get_air_layer_debug_snapshot", "air_1"))
	var movement: Dictionary = Dictionary(debug.get("movement", {}))
	_assert(unit.global_position.distance_to(target) <= 0.5, "Air unit reaches target behind a non-walkable ground blocker")
	_assert(String(movement.get("movement_layer", "")) == "air" and int(movement.get("altitude_band", -1)) == 2, "Air move debug records layer and altitude")
	_cleanup_context(context)


func _test_air_unit_clamps_to_mission_bounds() -> void:
	var context: Dictionary = _make_simulation_context()
	var sim: Node = context["sim"]
	var unit: Node2D = context["air_unit"]
	var registry = context["terrain_registry"]
	unit.global_position = registry.call("grid_to_world", Vector2i(1, 0))
	var outside_target: Vector2 = Vector2(9999.0, 9999.0)
	var clamped_target: Vector2 = registry.call("grid_to_world", Vector2i(2, 2))
	sim.call("enqueue_command", {
		"command_type": "move_to_position",
		"unit_id": "air_1",
		"target_position": outside_target,
		"movement_layer": "air",
		"altitude_band": 1,
		"move_speed_factor": 100.0,
		"requeue_until_target": false,
	})
	sim.call("_physics_process", 1.0)
	var debug: Dictionary = Dictionary(sim.call("get_air_layer_debug_snapshot", "air_1"))
	var movement: Dictionary = Dictionary(debug.get("movement", {}))
	_assert(unit.global_position.distance_to(clamped_target) <= 0.5, "Air unit clamps outside target to mission map bounds")
	_assert(bool(movement.get("clamped_to_bounds", false)), "Air move debug marks bounds clamp")
	_cleanup_context(context)


func _test_anti_air_gate_blocks_ground_fire_without_aa() -> void:
	var context: Dictionary = _make_simulation_context()
	var sim: Node = context["sim"]
	var air_unit = context["air_unit"]
	var ground_unit = context["ground_unit"]
	air_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, "air", 2)
	ground_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, "ground", 0)
	sim.call("register_known_unit", "ground_1", ground_unit)
	sim.call("enqueue_effect", {
		"effect_type": "damage",
		"unit_id": "air_1",
		"attacker_unit_id": "ground_1",
		"attacker_team_id": "team_alpha",
		"damage": 10,
		"hit_chance": 1.0,
		"roll_override": 0.0,
	})
	sim.call("_physics_process", 0.1)
	var blocked_debug: Dictionary = Dictionary(sim.call("get_air_layer_debug_snapshot")).get("targeting", {})
	_assert(int(air_unit.call("get_health")) == 100, "Ground fire without anti_air does not damage air unit")
	_assert(String(blocked_debug.get("reason", "")) == "anti_air_required", "Air targeting debug reports missing AA gate")
	sim.call("enqueue_effect", {
		"effect_type": "damage",
		"unit_id": "air_1",
		"attacker_unit_id": "ground_1",
		"attacker_team_id": "team_alpha",
		"damage": 10,
		"hit_chance": 1.0,
		"roll_override": 0.0,
		"anti_air": true,
	})
	sim.call("_physics_process", 0.1)
	_assert(int(air_unit.call("get_health")) < 100, "Ground fire with anti_air can damage air unit")
	_cleanup_context(context)


func _test_layered_los_ignores_ground_blocker_for_air() -> void:
	var registry = _make_air_test_registry()
	var los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var source: Vector2 = registry.call("grid_to_world", Vector2i(0, 0))
	var target: Vector2 = registry.call("grid_to_world", Vector2i(2, 0))
	var ground_snapshot: Dictionary = Dictionary(los_system.call("get_layered_line_of_sight_snapshot", source, target, "ground", "ground", registry, 999.0, 0, 0))
	var air_snapshot: Dictionary = Dictionary(los_system.call("get_layered_line_of_sight_snapshot", source, target, "ground", "air", registry, 999.0, 0, 2))
	_assert(not bool(ground_snapshot.get("has_line_of_sight", true)), "Ground LOS is blocked by terrain")
	_assert(bool(air_snapshot.get("has_line_of_sight", false)) and bool(air_snapshot.get("terrain_blockers_ignored", false)), "Air LOS ignores ground blocker but keeps range")
	registry.free()


func _test_air_visual_marker_is_created() -> void:
	var unit = TEST_UNIT_SCRIPT.new()
	get_root().add_child(unit)
	unit.call("_ready")
	var command = UNIT_COMMAND_SCRIPT.new({
		"command_type": "move_to_position",
		"unit_id": "air_visual",
		"team_id": "team_alpha",
		"target_position": Vector2(64.0, 32.0),
		"movement_layer": "air",
		"altitude_band": 4,
	})
	unit.call("assign_unit_command", command)
	var shadow = unit.get_node_or_null("AirLayerShadow")
	var marker = unit.get_node_or_null("AirLayerMarker")
	_assert(unit.call("is_air_unit") and shadow != null and marker != null, "Air unit exposes shadow and marker visuals")
	_assert(String(marker.text) == "AIR 4", "Air marker text exposes altitude band")
	unit.queue_free()


func _make_simulation_context() -> Dictionary:
	var root := Node.new()
	get_root().add_child(root)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)
	var terrain_registry = _make_air_test_registry()
	terrain_registry.name = "TerrainRegistry"
	root.add_child(terrain_registry)
	var sim = SIMULATION_ROOT_SCRIPT.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	root.add_child(sim)
	var air_unit = TEST_UNIT_SCRIPT.new()
	air_unit.unit_id = "air_1"
	air_unit.team_id = "team_bravo"
	root.add_child(air_unit)
	air_unit.call("_ready")
	var ground_unit = TEST_UNIT_SCRIPT.new()
	ground_unit.unit_id = "ground_1"
	ground_unit.team_id = "team_alpha"
	root.add_child(ground_unit)
	ground_unit.call("_ready")
	unit_registry.call("register_unit", "air_1", air_unit)
	unit_registry.call("register_unit", "ground_1", ground_unit)
	sim.call("register_known_unit", "air_1", air_unit)
	sim.call("register_known_unit", "ground_1", ground_unit)
	return {
		"root": root,
		"sim": sim,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"air_unit": air_unit,
		"ground_unit": ground_unit,
	}


func _make_air_test_registry():
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for y in range(3):
		for x in range(3):
			var grid_position := Vector2i(x, y)
			var walkable: bool = grid_position != Vector2i(1, 0)
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "tile_%d_%d" % [x, y],
				"type_id": "ground_flat" if walkable else "rock_large",
				"grid_position": grid_position,
				"world_position": registry.grid_to_world(grid_position),
				"walkable": walkable,
				"blocks_los": not walkable,
				"blocks_los_height": 4.0 if not walkable else 0.0,
				"surface_type": "ground" if walkable else "rock",
			}))
	return registry


func _cleanup_context(context: Dictionary) -> void:
	var root = context.get("root", null)
	if root != null and root is Node:
		root.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
