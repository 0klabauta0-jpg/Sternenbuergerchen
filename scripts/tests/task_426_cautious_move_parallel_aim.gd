extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_426_cautious_move_parallel_aim.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const RESOLVER_PATH: String = "res://scripts/tactical/fireteam_behavior_resolver.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_426 Cautious Move Parallel Aim ===")
	_test_resolver_keeps_cautious_move_as_group_travel()
	_test_runtime_cautious_move_issues_all_members_aimed()
	await _test_drill_cautious_move_uses_parallel_aim()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_resolver_keeps_cautious_move_as_group_travel() -> void:
	FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("clear_caches")
	var leader = _make_unit("resolver_lead", "drill", true, Vector2.ZERO)
	leader.skill_toughness = 0.72
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call(
		"resolve_profile",
		"drill",
		[leader],
		leader,
		"move",
		Vector2(240.0, 0.0),
		null,
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS
	)
	_assert(String(profile.advance_style) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "Resolver maps cautious Move to group travel/rush")
	_assert(String(profile.tactical_stance) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, "Resolver keeps cautious stance on the profile")
	leader.queue_free()


func _test_runtime_cautious_move_issues_all_members_aimed() -> void:
	FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("clear_caches")
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("runtime")
	var leader = units[0]
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call(
		"resolve_profile",
		"runtime",
		units,
		leader,
		"move",
		Vector2(280.0, 0.0),
		null,
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS
	)
	var result: Dictionary = Dictionary(controller.call("start_execution", "runtime", "move", 1, Vector2(280.0, 0.0), profile, units, leader, simulation))
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(bool(result.get("started", false)), "Runtime starts cautious Move")
	_assert(String(movement_state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "Runtime cautious Move uses rush effective style")
	_assert(PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray())).size() == units.size(), "Runtime cautious Move marks all members moving")
	_assert(PackedStringArray(movement_state.get("current_covering_unit_ids", PackedStringArray())).is_empty(), "Runtime cautious Move has no HOLD covering group")
	_assert(_all_commands_are_cautious_move(simulation.commands, units.size()), "Runtime cautious Move issues only aimed move commands")
	_cleanup_units(units)


func _test_drill_cautious_move_uses_parallel_aim() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var stance_applied: bool = bool(controller.call("set_selected_fireteams_tactical_stance", "cautious"))
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(stance_applied and units.size() == 4 and leader is Node2D, "Drill setup applies C stance to a four-member fireteam")
	if not stance_applied or units.size() != 4 or not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	var target_position: Vector2 = (leader as Node2D).global_position + Vector2(260.0, -80.0)
	var profile = controller.call("_resolve_fireteam_behavior_profile", "drill", "move", target_position)
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "wp_cautious_parallel"
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	waypoint.target_position = target_position
	controller.call("_set_active_behavior_profile", "drill", profile)
	var issued: bool = bool(controller.call("_issue_waypoint_for_fireteam", "drill", waypoint, 1, profile))
	await _wait_frames(2)

	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(issued and String(movement_state.get("effective_style", "")) == "rush", "Drill cautious Move starts as parallel group travel")
	_assert(PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray())).size() == units.size(), "Drill cautious Move marks every member moving")
	_assert(PackedStringArray(movement_state.get("current_covering_unit_ids", PackedStringArray())).is_empty(), "Drill cautious Move has no covering HOLD members")
	_assert(_all_units_have_cautious_move_command(units), "Drill cautious Move gives every member aimed move runtime")

	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var resolver_text: String = _read_text(RESOLVER_PATH)
	_assert(task_text.contains("TASK_426 - Cautious Move Parallel Aim"), "TASK_426 task file exists")
	_assert(status_text.contains("TASK_426 - Cautious Move Parallel Aim"), "Implementation status documents TASK_426")
	_assert(roadmap_text.contains("TASK_426 - Cautious Move Parallel Aim"), "Roadmap lists TASK_426")
	_assert(resolver_text.contains("Move is the direct all-members travel order"), "Resolver documents cautious Move as posture, not bound grouping")


func _make_fireteam_units(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-24.0, 0.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(18.0, -10.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 20.0)),
	]


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _all_commands_are_cautious_move(commands: Array, expected_count: int) -> bool:
	if commands.size() != expected_count:
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("command_type", "")) != UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION:
			return false
		if String(command.get("source_command_type", "")) != "move":
			return false
		if String(command.get("movement_posture", "")) != "engage":
			return false
		if String(command.get("weapon_posture", "")) != "aimed":
			return false
		if not is_equal_approx(float(command.get("sight_range_factor", 0.0)), 1.2):
			return false
	return true


func _all_units_have_cautious_move_command(units: Array) -> bool:
	for unit in units:
		if unit == null or not unit.has_method("get_current_unit_command") or not unit.has_method("get_runtime_status"):
			return false
		var command = unit.call("get_current_unit_command")
		if command == null or not command.has_method("to_dict"):
			return false
		var command_dict: Dictionary = Dictionary(command.to_dict())
		if String(command_dict.get("command_type", "")) != UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION:
			return false
		var runtime_dict: Dictionary = Dictionary(unit.call("get_runtime_status").to_dict())
		if String(runtime_dict.get("movement_posture", "")) != "engage":
			return false
		if String(runtime_dict.get("weapon_posture", "")) != "aimed":
			return false
	return true


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
