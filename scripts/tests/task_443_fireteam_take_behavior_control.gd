extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_443_fireteam_take_behavior_control.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const UNIT_COMMAND_PATH: String = "res://scripts/npc/unit_command.gd"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class LosRangeGate:
	extends RefCounted

	func has_line_of_sight_between_nodes(attacker, target, range_world: float, _terrain_registry = null) -> bool:
		if not (attacker is Node2D) or not (target is Node2D):
			return false
		return (attacker as Node2D).global_position.distance_to((target as Node2D).global_position) <= range_world


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_443 Fireteam Take Behavior Control ===")
	_test_take_cautious_uses_short_buddy_entry()
	_test_take_normal_uses_bounding_clear()
	_test_take_aggressive_uses_assault_line()
	_test_take_range_policy_blocks_max_range_fire()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_take_cautious_uses_short_buddy_entry() -> void:
	var cautious_result: Dictionary = _execute_take_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS)
	var normal_result: Dictionary = _execute_take_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)
	var state: Dictionary = Dictionary(cautious_result.get("state", {}))
	var commands: Array = Array(cautious_result.get("commands", []))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING, "Cautious Take uses buddy entry bounds")
	_assert(PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())).size() == 2, "Cautious Take moves one buddy pair")
	_assert(PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())).size() == 2, "Cautious Take keeps one buddy pair covering")
	_assert(float(state.get("bound_distance", 9999.0)) < float(Dictionary(normal_result.get("state", {})).get("bound_distance", 0.0)), "Cautious Take uses shorter bounds than normal Take")
	_assert(_all_commands_are_take_ready(commands, "cautious_buddy_entry", 0.6), "Cautious Take commands are aimed, fire-at-will and range-limited")
	_cleanup_units(Array(cautious_result.get("units", [])))
	_cleanup_units(Array(normal_result.get("units", [])))


func _test_take_normal_uses_bounding_clear() -> void:
	var result: Dictionary = _execute_take_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)
	var state: Dictionary = Dictionary(result.get("state", {}))
	var commands: Array = Array(result.get("commands", []))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING, "Normal Take uses bounding")
	_assert(PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())).size() == 2, "Normal Take moves one buddy pair")
	_assert(PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())).size() == 2, "Normal Take keeps one buddy pair covering")
	_assert(_all_commands_are_take_ready(commands, "normal_bounding_clear", 0.7), "Normal Take commands carry bounding-clear doctrine")
	_cleanup_units(Array(result.get("units", [])))


func _test_take_aggressive_uses_assault_line() -> void:
	var result: Dictionary = _execute_take_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE)
	var state: Dictionary = Dictionary(result.get("state", {}))
	var commands: Array = Array(result.get("commands", []))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "Aggressive Take uses assault rush")
	_assert(PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())).size() == 4, "Aggressive Take moves all members together")
	_assert(PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())).is_empty(), "Aggressive Take has no static covering subgroup")
	_assert(_all_commands_are_take_ready(commands, "aggressive_assault_line", 0.85), "Aggressive Take commands carry assault-line doctrine")
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		_assert(String(command.get("movement_posture", "")) == UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_RUN, "Aggressive Take uses run posture")
	_cleanup_units(Array(result.get("units", [])))


func _test_take_range_policy_blocks_max_range_fire() -> void:
	var attacker := _make_unit("take_attacker", "drill", true, Vector2.ZERO)
	var far_target := _make_unit("far_contact", "red", false, Vector2(260.0, 0.0), "team_bravo")
	var near_target := _make_unit("near_contact", "red", false, Vector2(180.0, 0.0), "team_bravo")
	var take_command = UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"priority": 12,
		"unit_id": "take_attacker",
		"team_id": "team_alpha",
		"fire_status": UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
		"source_command_type": "take",
		"target_position": Vector2.ZERO,
		"movement_posture": UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE,
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED,
		"engagement_range_policy": "optimal_range_area_control",
		"engagement_range_factor": 0.7,
	})
	_assert(bool(take_command.call("is_valid")), "UnitCommand accepts Take engagement range policy")
	attacker.call("assign_unit_command", take_command)
	var context: Dictionary = {
		"friendly_team_id": "team_alpha",
		"los_system": LosRangeGate.new(),
		"terrain_registry": null,
		"get_weapon_attack_range": func(_attacker, _target): return 320.0,
	}
	_assert(not bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", attacker, far_target, context)), "Take does not attack beyond its optimal range factor")
	_assert(bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", attacker, near_target, context)), "Take attacks inside its optimal range factor")
	_cleanup_units([attacker, far_target, near_target])


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var command_text: String = _read_text(UNIT_COMMAND_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("TASK_443 - Fireteam Take Behavior Control"), "TASK_443 task file exists")
	_assert(status_text.contains("TASK_443 - Fireteam Take Behavior Control"), "Implementation status documents TASK_443")
	_assert(roadmap_text.contains("TASK_443 - Fireteam Take Behavior Control"), "Roadmap lists TASK_443")
	_assert(contract_text.contains("Take Doctrine V1"), "Behavior contract documents Take Doctrine V1")
	_assert(movement_text.contains("TAKE_DOCTRINE_ID"), "Movement controller exposes Take doctrine metadata")
	_assert(command_text.contains("engagement_range_factor"), "UnitCommand carries engagement range policy")
	_assert(controller_text.contains("take_doctrine_id"), "Area Take commands expose Take doctrine metadata")


func _execute_take_stance(tactical_stance: String) -> Dictionary:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("take_%s" % tactical_stance)
	var profile := {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH,
		"tactical_stance": tactical_stance,
		"cover_priority": 0.55,
		"cohesion_threshold": 120.0,
		"order_fidelity": 1.0,
		"execution_cohesion": 0.65,
		"initiative": 0.5,
	}
	var result: Dictionary = Dictionary(controller.call("start_execution", "drill", "take", 1, Vector2(520.0, 0.0), profile, units, units[0], simulation))
	_assert(bool(result.get("started", false)), "%s Take execution starts" % tactical_stance)
	return {
		"state": Dictionary(result.get("movement_state", {})),
		"commands": simulation.commands.duplicate(true),
		"units": units,
	}


func _all_commands_are_take_ready(commands: Array, expected_advance_mode: String, expected_range_factor: float) -> bool:
	if commands.size() != 4:
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("source_command_type", "")) != "take":
			return false
		if String(command.get("fire_status", "")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
		if String(command.get("weapon_posture", "")) != UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED:
			return false
		if String(command.get("take_doctrine_id", "")) != "take_control_v1":
			return false
		if String(command.get("take_advance_mode", "")) != expected_advance_mode:
			return false
		if String(command.get("take_target_policy", "")) != "optimal_range_area_control":
			return false
		if not bool(command.get("take_area_control_required", false)):
			return false
		if absf(float(command.get("engagement_range_factor", 0.0)) - expected_range_factor) > 0.001:
			return false
	return true


func _make_fireteam_units(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-24.0, 0.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(18.0, -10.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 20.0)),
	]


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2, team_id: String = "team_alpha") -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
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


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
