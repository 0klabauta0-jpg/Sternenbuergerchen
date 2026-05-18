extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_476_fireteam_corridor_lane_cover_navigation.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"
const PATHFINDER_PATH: String = "res://scripts/terrain/terrain_pathfinder.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class SimpleTerrainStub:
	extends RefCounted
	const CELL_SIZE: float = 32.0

	func resolve_walkable_target(world_pos: Vector2) -> Dictionary:
		return {
			"original_position": world_pos,
			"original_grid": world_to_grid(world_pos),
			"target_walkable": true,
			"replacement_grid": world_to_grid(world_pos),
			"replacement_position": world_pos,
			"blocked_grid": null,
			"blocked_position": null,
			"blocker_reason": "",
		}

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		return Vector2i(roundi(world_pos.x / CELL_SIZE), roundi(world_pos.y / CELL_SIZE))

	func grid_to_world(grid_pos: Vector2i) -> Vector2:
		return Vector2(float(grid_pos.x) * CELL_SIZE, float(grid_pos.y) * CELL_SIZE)

	func is_walkable(_grid_pos: Vector2i) -> bool:
		return true


class GridRegistryStub:
	extends RefCounted
	const CELL_SIZE: float = 32.0
	var tiles: Dictionary = {}

	func add_tile(grid_position: Vector2i, walkable: bool = true, cover_value: int = 0, blocks_los: bool = false) -> void:
		var tile = TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
			"grid_position": grid_position,
			"world_position": grid_to_world(grid_position),
			"walkable": walkable,
			"cover_value": cover_value,
			"blocks_los": blocks_los,
			"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
			"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE,
		})
		tiles[grid_position] = tile

	func get_tile_at_grid(grid_position: Vector2i):
		return tiles.get(grid_position, null)

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		return Vector2i(roundi(world_pos.x / CELL_SIZE), roundi(world_pos.y / CELL_SIZE))

	func grid_to_world(grid_pos: Vector2i) -> Vector2:
		return Vector2(float(grid_pos.x) * CELL_SIZE, float(grid_pos.y) * CELL_SIZE)


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_476 Fireteam Corridor Lane Cover Navigation ===")
	_test_fireteam_commands_export_navigation_context()
	_test_simulation_root_normalizes_navigation_context()
	_test_pathfinder_scores_lane_cover_and_blocker_weights()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_fireteam_commands_export_navigation_context() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var terrain = SimpleTerrainStub.new()
	var units: Array = _make_fireteam_units("task476")
	var result: Dictionary = Dictionary(controller.call(
		"start_execution",
		"drill",
		"move",
		1,
		Vector2(360.0, 32.0),
		_make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL),
		units,
		units[0],
		simulation,
		terrain
	))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))
	var lane_offsets: Array = []
	for command_variant in simulation.commands:
		var command: Dictionary = Dictionary(command_variant)
		_assert(bool(command.get("navigation_corridor_enabled", false)), "Moving command exports navigation corridor")
		_assert(bool(command.get("navigation_lane_enabled", false)), "Moving command exports navigation lane")
		_assert(bool(command.get("navigation_cover_aware", false)), "Moving command enables cover-aware navigation")
		_assert(command.has("navigation_blocker_clearance_weight"), "Moving command exports blocker-clearance weight")
		lane_offsets.append(float(command.get("navigation_lane_offset_world", 0.0)))
	_assert(bool(result.get("started", false)), "Move execution starts for navigation-context export")
	_assert(simulation.commands.size() == 4, "Move issues four movement commands")
	_assert(Array(state.get("current_navigation_context_debug", [])).size() == 4, "Movement state exposes per-unit navigation diagnostics")
	_assert(_has_positive_and_negative_lane_offsets(lane_offsets), "Formation lanes keep left and right offsets instead of one centerline")
	_cleanup_units(units)


func _test_simulation_root_normalizes_navigation_context() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var terrain = SimpleTerrainStub.new()
	var cmd: Dictionary = {
		"unit_id": "task476_alpha",
		"command_type": "move_to_position",
		"source_command_type": "move",
		"navigation_cover_aware": true,
		"navigation_corridor_enabled": true,
		"navigation_corridor_start_position": Vector2.ZERO,
		"navigation_corridor_end_position": Vector2(320.0, 0.0),
		"navigation_corridor_half_width_world": 96.0,
		"navigation_corridor_weight": 0.75,
		"navigation_lane_enabled": true,
		"navigation_lane_offset_world": 64.0,
		"navigation_lane_weight": 0.8,
		"navigation_blocker_clearance_weight": 0.45,
		"navigation_blocker_clearance_radius": 2,
	}
	var options: Dictionary = Dictionary(simulation_root.call("_build_navigation_cost_options", cmd, terrain))
	_assert(bool(options.get("corridor_enabled", false)), "SimulationRoot passes corridor option to navigation")
	_assert(Vector2i(options.get("corridor_from_grid", Vector2i.ONE)) == Vector2i.ZERO, "SimulationRoot normalizes corridor start to grid")
	_assert(float(options.get("corridor_half_width_grid", 0.0)) > 0.0, "SimulationRoot converts corridor width to grid distance")
	_assert(bool(options.get("lane_enabled", false)), "SimulationRoot passes lane option to navigation")
	_assert(float(options.get("lane_offset_grid", 0.0)) > 0.0, "SimulationRoot converts lane offset to grid distance")
	_assert(is_equal_approx(float(options.get("blocker_clearance_weight", 0.0)), 0.45), "SimulationRoot passes blocker-clearance weight")
	simulation_root.free()


func _test_pathfinder_scores_lane_cover_and_blocker_weights() -> void:
	var registry = _make_grid_registry()
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var lane_options: Dictionary = {
		"corridor_enabled": true,
		"corridor_from_grid": Vector2i(0, 0),
		"corridor_to_grid": Vector2i(5, 0),
		"corridor_half_width_grid": 4.0,
		"lane_enabled": true,
		"lane_offset_grid": 1.0,
		"lane_weight": 2.0,
	}
	var lane_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, 1), registry, lane_options))
	var opposite_lane_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, -1), registry, lane_options))
	_assert(lane_cost < opposite_lane_cost, "Pathfinder favors the assigned buddy lane")

	var cover_options: Dictionary = {
		"cover_aware_enabled": true,
		"cover_weight": 1.0,
		"exposure_weight": 0.0,
	}
	var cover_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, 1), registry, cover_options))
	var open_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, -1), registry, cover_options))
	_assert(cover_cost < open_cost, "Pathfinder rewards cover tiles separately from lane score")

	var blocker_options: Dictionary = {
		"blocker_clearance_weight": 2.0,
		"blocker_clearance_radius": 1,
	}
	var near_blocker_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, 1), registry, blocker_options))
	var clear_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, -1), registry, blocker_options))
	_assert(near_blocker_cost > clear_cost, "Pathfinder penalizes blocker-adjacent steps")


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var simulation_text: String = _read_text(SIMULATION_ROOT_PATH)
	var pathfinder_text: String = _read_text(PATHFINDER_PATH)
	_assert(task_text.contains("TASK_476 - Fireteam Corridor Lane Cover Navigation"), "TASK_476 task file exists")
	_assert(status_text.contains("TASK_476 - Fireteam Corridor Lane Cover Navigation"), "Implementation status documents TASK_476")
	_assert(roadmap_text.contains("TASK_476 - Fireteam Corridor Lane Cover Navigation"), "Roadmap lists TASK_476")
	_assert(contract_text.contains("TASK_476 Wegkorridor-/Buddy-Lane-/Deckungsgewichtung"), "Behavior contract documents TASK_476")
	_assert(movement_text.contains("navigation_lane_offset_world"), "Movement controller exports lane navigation metadata")
	_assert(simulation_text.contains("_append_navigation_corridor_options"), "SimulationRoot normalizes corridor/lane navigation options")
	_assert(pathfinder_text.contains("_get_blocker_clearance_penalty"), "Pathfinder scores blocker-clearance penalty")


func _make_profile(tactical_stance: String) -> Dictionary:
	return {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH,
		"tactical_stance": tactical_stance,
		"cover_priority": 0.55,
		"cohesion_threshold": 120.0,
		"order_fidelity": 1.0,
		"execution_cohesion": 0.65,
		"initiative": 0.5,
	}


func _make_fireteam_units(prefix: String) -> Array:
	return [
		_make_unit("%s_lead" % prefix, "team_alpha", "drill", true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % prefix, "team_alpha", "drill", false, Vector2(-18.0, 4.0)),
		_make_unit("%s_b" % prefix, "team_alpha", "drill", false, Vector2(16.0, -4.0)),
		_make_unit("%s_c" % prefix, "team_alpha", "drill", false, Vector2(0.0, 18.0)),
	]


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.weapon_1_id = "rifle"
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit._ready()
	return unit


func _make_grid_registry():
	var registry = GridRegistryStub.new()
	for x in range(-1, 6):
		for y in range(-3, 4):
			registry.add_tile(Vector2i(x, y), true, 0, false)
	registry.add_tile(Vector2i(2, 1), true, 80, false)
	registry.add_tile(Vector2i(2, 2), false, 0, true)
	return registry


func _has_positive_and_negative_lane_offsets(lane_offsets: Array) -> bool:
	var has_positive: bool = false
	var has_negative: bool = false
	for value_variant in lane_offsets:
		var value: float = float(value_variant)
		if value > 0.01:
			has_positive = true
		if value < -0.01:
			has_negative = true
	return has_positive and has_negative


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit is Node:
			var node := unit as Node
			if node.is_inside_tree():
				node.queue_free()
			else:
				node.free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
		return
	_failed += 1
	push_error("[FAIL] %s" % message)
