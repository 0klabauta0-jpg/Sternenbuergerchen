extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_475_fireteam_pathfinding_avoidance_stability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class CollapseFirstTwoTerrainStub:
	extends RefCounted
	const CELL_SIZE: float = 32.0
	var resolve_calls: int = 0

	func resolve_walkable_target(world_pos: Vector2) -> Dictionary:
		resolve_calls += 1
		if resolve_calls <= 2:
			return _make_resolution(world_pos, Vector2.ZERO, false, "test_collapsed_target_slot")
		return _make_resolution(world_pos, world_pos, true, "")

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		return Vector2i(roundi(world_pos.x / CELL_SIZE), roundi(world_pos.y / CELL_SIZE))

	func grid_to_world(grid_pos: Vector2i) -> Vector2:
		return Vector2(float(grid_pos.x) * CELL_SIZE, float(grid_pos.y) * CELL_SIZE)

	func is_walkable(_grid_pos: Vector2i) -> bool:
		return true

	func _make_resolution(original: Vector2, replacement: Vector2, walkable: bool, reason: String) -> Dictionary:
		return {
			"original_position": original,
			"original_grid": world_to_grid(original),
			"target_walkable": walkable,
			"replacement_grid": world_to_grid(replacement),
			"replacement_position": replacement,
			"blocked_grid": world_to_grid(original) if not walkable else null,
			"blocked_position": original if not walkable else null,
			"blocker_reason": reason,
		}


class WalkableTerrainStub:
	extends RefCounted

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		return Vector2i(roundi(world_pos.x / 32.0), roundi(world_pos.y / 32.0))

	func is_walkable(_grid_pos: Vector2i) -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_475 Fireteam Pathfinding Avoidance Stability Pass ===")
	_test_collapsed_walkable_targets_are_spread_before_commands()
	_test_local_avoidance_deadlock_requests_path_recompute()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_collapsed_walkable_targets_are_spread_before_commands() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var terrain = CollapseFirstTwoTerrainStub.new()
	var units: Array = _make_fireteam_units("task475")
	var result: Dictionary = Dictionary(controller.call(
		"start_execution",
		"drill",
		"move",
		1,
		Vector2(420.0, 0.0),
		_make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL),
		units,
		units[0],
		simulation,
		terrain
	))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))
	var targets: Dictionary = Dictionary(state.get("current_target_positions", {}))

	_assert(bool(result.get("started", false)), "Move execution starts with collapsing walkable resolver")
	_assert(simulation.commands.size() == 4, "Move issues four member commands")
	_assert(int(state.get("current_target_spacing_conflict_count", 0)) >= 1, "Movement state records collapsed target-slot conflict")
	_assert(int(state.get("current_target_spacing_adjustment_count", 0)) >= 1, "Movement state records target-slot spacing repair")
	_assert(float(state.get("current_target_spacing_min_distance", 0.0)) >= 48.0, "Resolved target slots keep runtime minimum spacing")
	_assert(Array(state.get("current_target_spacing_debug", [])).size() >= 1, "Movement state exposes target-spacing diagnostics")
	_assert(_all_commands_match_resolved_targets(simulation.commands, targets), "UnitCommands use the stabilized target slots")
	_assert(_target_grids_are_unique(targets, terrain), "Resolved movement targets do not collapse to the same grid")
	_cleanup_units(units)


func _test_local_avoidance_deadlock_requests_path_recompute() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var unit = _make_unit("task475_alpha", "team_alpha", "drill", true, Vector2.ZERO)
	var terrain = WalkableTerrainStub.new()
	var cmd: Dictionary = {
		"unit_id": unit.get_unit_id(),
		"local_avoidance_deadlock": true,
		"local_avoidance_repath_requested": true,
		"requeue_until_target": true,
	}
	var existing_path: Array = [Vector2(32.0, 0.0), Vector2(64.0, 0.0)]
	var should_recompute: bool = bool(simulation_root.call("_should_recompute_move_path", cmd, unit, existing_path, Vector2.ZERO, Vector2(128.0, 0.0), terrain))

	_assert(should_recompute, "Local-avoidance deadlock requests a terrain-path rebuild")
	_assert(not bool(cmd.get("local_avoidance_repath_requested", false)), "Repath flag is consumed after scheduling recompute")
	_assert(not bool(cmd.get("local_avoidance_deadlock", false)), "Deadlock flag is cleared after scheduling recompute")
	unit.free()
	simulation_root.free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var simulation_text: String = _read_text(SIMULATION_ROOT_PATH)
	_assert(task_text.contains("TASK_475 - Fireteam Pathfinding Avoidance Stability Pass"), "TASK_475 task file exists")
	_assert(status_text.contains("TASK_475 - Fireteam Pathfinding Avoidance Stability Pass"), "Implementation status documents TASK_475")
	_assert(roadmap_text.contains("TASK_475 - Fireteam Pathfinding Avoidance Stability Pass"), "Roadmap lists TASK_475")
	_assert(contract_text.contains("TASK_475 Pathfinding-/Avoidance-Stability-Pass"), "Behavior contract documents TASK_475")
	_assert(movement_text.contains("current_target_spacing_adjustment_count"), "Movement controller exposes target-slot spacing debug")
	_assert(simulation_text.contains("local_avoidance_repath_requested"), "SimulationRoot consumes local-avoidance repath requests")


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


func _all_commands_match_resolved_targets(commands: Array, target_positions: Dictionary) -> bool:
	if commands.is_empty() or target_positions.is_empty():
		return false
	for command_variant in commands:
		if typeof(command_variant) != TYPE_DICTIONARY:
			return false
		var command: Dictionary = Dictionary(command_variant)
		var unit_id: String = String(command.get("unit_id", ""))
		if not target_positions.has(unit_id):
			return false
		var target_variant: Variant = command.get("target_position", null)
		if typeof(target_variant) != TYPE_VECTOR2:
			return false
		if Vector2(target_variant).distance_to(Vector2(target_positions.get(unit_id))) > 0.01:
			return false
	return true


func _target_grids_are_unique(target_positions: Dictionary, terrain) -> bool:
	var seen_grids: Dictionary = {}
	for unit_id_variant in target_positions.keys():
		var grid: Vector2i = Vector2i(terrain.call("world_to_grid", Vector2(target_positions.get(unit_id_variant, Vector2.ZERO))))
		if seen_grids.has(grid):
			return false
		seen_grids[grid] = true
	return true


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
