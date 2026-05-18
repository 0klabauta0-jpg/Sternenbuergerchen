extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_477_fireteam_contact_cover_decision_v1.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class CoverTerrainStub:
	extends RefCounted
	const CELL_SIZE: float = 32.0
	var cover_by_grid: Dictionary = {}

	func add_cover(world_position: Vector2, cover_value: int) -> void:
		cover_by_grid[world_to_grid(world_position)] = cover_value

	func get_walkable_cover_tiles_in_radius(world_center: Vector2, radius: float) -> Array:
		var radius_sq: float = radius * radius
		var result: Array = []
		for grid_variant in cover_by_grid.keys():
			var grid_position: Vector2i = Vector2i(grid_variant)
			var world_position: Vector2 = grid_to_world(grid_position)
			if world_center.distance_squared_to(world_position) > radius_sq:
				continue
			result.append({
				"world_position": world_position,
				"grid_position": grid_position,
				"cover_value": int(cover_by_grid.get(grid_position, 0)),
				"walkable": true,
			})
		return result

	func get_cover_at_world(world_position: Vector2) -> int:
		return int(cover_by_grid.get(world_to_grid(world_position), 0))

	func resolve_walkable_target(world_position: Vector2) -> Dictionary:
		var grid_position: Vector2i = world_to_grid(world_position)
		return {
			"original_position": world_position,
			"original_grid": grid_position,
			"target_walkable": true,
			"replacement_grid": grid_position,
			"replacement_position": grid_to_world(grid_position),
			"blocked_grid": null,
			"blocked_position": null,
			"blocker_reason": "",
		}

	func world_to_grid(world_position: Vector2) -> Vector2i:
		return Vector2i(roundi(world_position.x / CELL_SIZE), roundi(world_position.y / CELL_SIZE))

	func grid_to_world(grid_position: Vector2i) -> Vector2:
		return Vector2(float(grid_position.x) * CELL_SIZE, float(grid_position.y) * CELL_SIZE)

	func is_walkable(_grid_position: Vector2i) -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_477 Fireteam Contact Cover Decision V1 ===")
	_test_cautious_contact_halt_moves_to_near_cover()
	_test_aggressive_contact_halt_prefers_fire_now_for_moderate_cover()
	_test_sufficient_current_cover_does_not_reposition()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_cautious_contact_halt_moves_to_near_cover() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var terrain = CoverTerrainStub.new()
	var units: Array = _make_fireteam_units("task477_c")
	var leader = units[0]
	for cover_position in [Vector2(64.0, -64.0), Vector2(64.0, 0.0), Vector2(64.0, 64.0), Vector2(96.0, 96.0)]:
		terrain.add_cover(cover_position, 82)
	var start_result: Dictionary = Dictionary(controller.call(
		"start_execution",
		"drill",
		"engage",
		1,
		Vector2(420.0, 0.0),
		_make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS),
		units,
		leader,
		simulation,
		terrain
	))
	_assert(bool(start_result.get("started", false)), "Cautious Engage starts before contact cover check")
	simulation.commands.clear()
	var result: Dictionary = Dictionary(controller.call(
		"update_execution",
		"drill",
		units,
		leader,
		simulation,
		terrain,
		_make_contact_context(Vector2(220.0, 0.0), 260.0, 512.0)
	))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(bool(result.get("contact_halt", false)), "Cautious Engage enters contact halt")
	_assert(int(state.get("contact_cover_assignment_count", 0)) > 0, "Cautious contact halt assigns at least one member to cover")
	_assert(_has_take_cover_move_command(simulation.commands), "Cautious contact halt emits move-to-cover with fire-at-will")
	_cleanup_units(units)


func _test_aggressive_contact_halt_prefers_fire_now_for_moderate_cover() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var terrain = CoverTerrainStub.new()
	var units: Array = _make_fireteam_units("task477_a")
	var leader = units[0]
	for cover_position in [Vector2(64.0, -32.0), Vector2(64.0, 32.0), Vector2(96.0, -32.0), Vector2(96.0, 32.0)]:
		terrain.add_cover(cover_position, 60)
	_assert(bool(Dictionary(controller.call(
		"start_execution",
		"drill",
		"engage",
		1,
		Vector2(420.0, 0.0),
		_make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE),
		units,
		leader,
		simulation,
		terrain
	)).get("started", false)), "Aggressive Engage starts before contact cover check")
	simulation.commands.clear()
	var result: Dictionary = Dictionary(controller.call(
		"update_execution",
		"drill",
		units,
		leader,
		simulation,
		terrain,
		_make_contact_context(Vector2(180.0, 0.0), 180.0, 512.0)
	))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(bool(result.get("contact_halt", false)), "Aggressive Engage still enters contact halt")
	_assert(int(state.get("contact_cover_assignment_count", -1)) == 0, "Aggressive contact halt does not chase moderate cover")
	_assert(_all_contact_commands_hold_fire_now(simulation.commands), "Aggressive contact halt keeps hold/fire-now commands")
	_cleanup_units(units)


func _test_sufficient_current_cover_does_not_reposition() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var terrain = CoverTerrainStub.new()
	var units: Array = _make_fireteam_units("task477_cover")
	var leader = units[0]
	for unit in units:
		terrain.add_cover((unit as Node2D).global_position, 90)
	terrain.add_cover(Vector2(64.0, 64.0), 100)
	_assert(bool(Dictionary(controller.call(
		"start_execution",
		"drill",
		"engage",
		1,
		Vector2(420.0, 0.0),
		_make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS),
		units,
		leader,
		simulation,
		terrain
	)).get("started", false)), "Covered cautious Engage starts before contact cover check")
	simulation.commands.clear()
	var result: Dictionary = Dictionary(controller.call(
		"update_execution",
		"drill",
		units,
		leader,
		simulation,
		terrain,
		_make_contact_context(Vector2(220.0, 0.0), 220.0, 512.0)
	))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(bool(result.get("contact_halt", false)), "Covered cautious Engage enters contact halt")
	_assert(int(state.get("contact_cover_assignment_count", -1)) == 0, "Units already in sufficient cover do not reposition")
	_assert(_all_contact_reasons_are(state, "already_in_cover"), "Cover decision explains current cover hold")
	_cleanup_units(units)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	_assert(task_text.contains("TASK_477 - Fireteam Contact Cover Decision V1"), "TASK_477 task file exists")
	_assert(status_text.contains("TASK_477 - Fireteam Contact Cover Decision V1"), "Implementation status documents TASK_477")
	_assert(roadmap_text.contains("TASK_477 - Fireteam Contact Cover Decision V1"), "Roadmap lists TASK_477")
	_assert(contract_text.contains("TASK_477 Contact-Deckungsentscheidung V1"), "Behavior contract documents TASK_477")
	_assert(movement_text.contains("contact_cover_decision_active"), "Movement controller exposes contact-cover diagnostics")


func _has_take_cover_move_command(commands: Array) -> bool:
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("contact_cover_decision", "")) != "take_cover":
			continue
		if String(command.get("command_type", "")) != UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION:
			continue
		if String(command.get("source_command_type", "")).strip_edges().to_lower() != "engage":
			continue
		if String(command.get("fire_status", "")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			continue
		if String(command.get("weapon_posture", "")) != UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED:
			continue
		return true
	return false


func _all_contact_commands_hold_fire_now(commands: Array) -> bool:
	if commands.is_empty():
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("contact_cover_decision", "")) != "fire_now":
			return false
		if String(command.get("command_type", "")) != UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION:
			return false
		if String(command.get("fire_status", "")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
	return true


func _all_contact_reasons_are(state: Dictionary, expected_reason: String) -> bool:
	var decisions: Array = Array(state.get("contact_cover_decisions", []))
	if decisions.is_empty():
		return false
	for decision_variant in decisions:
		var decision: Dictionary = Dictionary(decision_variant)
		if String(decision.get("reason", "")) != expected_reason:
			return false
	return true


func _make_contact_context(target_position: Vector2, distance_world: float, weapon_range_world: float) -> Dictionary:
	return {
		"should_halt": true,
		"reason": "attackable_contact",
		"target_unit_id": "enemy_delta",
		"attacker_unit_id": "task477_attacker",
		"contact_state": "spotted",
		"target_position": target_position,
		"readout": {
			"target_unit_id": "enemy_delta",
			"attacker_unit_id": "task477_attacker",
			"combat_attackable": true,
			"range_state": "in_range",
			"los_state": "clear",
			"distance_world": distance_world,
			"weapon_range_world": weapon_range_world,
			"attack_quality_label": "clear",
		},
	}


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
