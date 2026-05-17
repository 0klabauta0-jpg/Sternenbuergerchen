extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_442_fireteam_engage_behavior_control.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const COMBAT_DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"

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
	print("=== TASK_442 Fireteam Engage Behavior Control ===")
	_test_engage_cautious_uses_short_buddy_bounds()
	_test_engage_normal_uses_buddy_bounding()
	_test_engage_aggressive_uses_fireline_rush()
	_test_engage_target_priority_uses_weapon_range_area_policy()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_engage_cautious_uses_short_buddy_bounds() -> void:
	var cautious_result: Dictionary = _execute_engage_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS)
	var normal_result: Dictionary = _execute_engage_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)
	var state: Dictionary = Dictionary(cautious_result.get("state", {}))
	var commands: Array = Array(cautious_result.get("commands", []))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING, "Cautious Engage uses buddy bounding instead of direct rush")
	_assert(PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())).size() == 2, "Cautious Engage moves one buddy pair")
	_assert(PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())).size() == 2, "Cautious Engage keeps one buddy pair covering")
	_assert(float(state.get("bound_distance", 9999.0)) < float(Dictionary(normal_result.get("state", {})).get("bound_distance", 0.0)), "Cautious Engage uses shorter bounds than normal Engage")
	_assert(_all_commands_are_engage_ready(commands, "cautious_buddy_bounds"), "Cautious Engage commands are aimed, fire-at-will and diagnosed")
	_cleanup_units(Array(cautious_result.get("units", [])))
	_cleanup_units(Array(normal_result.get("units", [])))


func _test_engage_normal_uses_buddy_bounding() -> void:
	var result: Dictionary = _execute_engage_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)
	var state: Dictionary = Dictionary(result.get("state", {}))
	var commands: Array = Array(result.get("commands", []))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING, "Normal Engage uses bounding")
	_assert(PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())).size() == 2, "Normal Engage moves one buddy pair")
	_assert(PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())).size() == 2, "Normal Engage keeps one buddy pair covering")
	_assert(_all_commands_are_engage_ready(commands, "normal_bounding"), "Normal Engage commands carry normal bounding doctrine")
	_cleanup_units(Array(result.get("units", [])))


func _test_engage_aggressive_uses_fireline_rush() -> void:
	var result: Dictionary = _execute_engage_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE)
	var state: Dictionary = Dictionary(result.get("state", {}))
	var commands: Array = Array(result.get("commands", []))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "Aggressive Engage uses fireline rush")
	_assert(PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())).size() == 4, "Aggressive Engage moves all members together")
	_assert(PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())).is_empty(), "Aggressive Engage has no static covering subgroup")
	_assert(_all_commands_are_engage_ready(commands, "aggressive_fireline"), "Aggressive Engage commands carry fireline doctrine")
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		_assert(String(command.get("movement_posture", "")) == UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_RUN, "Aggressive Engage uses run posture")
	_cleanup_units(Array(result.get("units", [])))


func _test_engage_target_priority_uses_weapon_range_area_policy() -> void:
	var attacker := _make_unit("engage_attacker", "drill", true, Vector2.ZERO)
	var outside_target := _make_unit("outside_contact", "red", false, Vector2(32.0, 0.0), "team_bravo")
	var inside_target := _make_unit("inside_contact", "red", false, Vector2(260.0, 0.0), "team_bravo")
	attacker.call(
		"set_runtime_status",
		"engaging",
		UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		12,
		UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
		"engage",
		1.0,
		0.0,
		0.0,
		1,
		Vector2.ZERO,
		UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE,
		UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED,
		"fireteam_behavior",
		1.0
	)
	var target_area: Dictionary = {
		"area_order_id": "task442_area",
		"fireteam_id": "drill",
		"command_type": "engage",
		"center_position": Vector2(260.0, 0.0),
		"area_radius": 48.0,
		"world_polygon": PackedVector2Array([
			Vector2(220.0, -40.0),
			Vector2(300.0, -40.0),
			Vector2(300.0, 40.0),
			Vector2(220.0, 40.0),
		]),
	}
	var context: Dictionary = {
		"friendly_team_id": "team_alpha",
		"contact_range": 48.0,
		"los_system": LosRangeGate.new(),
		"terrain_registry": null,
		"get_effective_range": func(_target): return 48.0,
		"get_weapon_attack_range": func(_attacker, _target): return 320.0,
		"attack_area_by_fireteam": {
			"drill": target_area,
		},
	}
	var picked = COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("pick_target_from_units", attacker, [outside_target, inside_target], context)
	_assert(picked == inside_target, "Engage target policy can pick an in-area target at weapon range over a closer outside contact")
	_cleanup_units([attacker, outside_target, inside_target])


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var combat_text: String = _read_text(COMBAT_DRIVER_PATH)
	_assert(task_text.contains("TASK_442 - Fireteam Engage Behavior Control"), "TASK_442 task file exists")
	_assert(status_text.contains("TASK_442 - Fireteam Engage Behavior Control"), "Implementation status documents TASK_442")
	_assert(roadmap_text.contains("TASK_442 - Fireteam Engage Behavior Control"), "Roadmap lists TASK_442")
	_assert(contract_text.contains("Engage Doctrine V1"), "Behavior contract documents Engage Doctrine V1")
	_assert(movement_text.contains("ENGAGE_DOCTRINE_ID"), "Movement controller exposes Engage doctrine metadata")
	_assert(combat_text.contains("_uses_weapon_range_for_contact_detection"), "Combat loop documents Engage weapon-range contact detection")


func _execute_engage_stance(tactical_stance: String) -> Dictionary:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("engage_%s" % tactical_stance)
	var profile := {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH,
		"tactical_stance": tactical_stance,
		"cover_priority": 0.55,
		"cohesion_threshold": 120.0,
		"order_fidelity": 1.0,
		"execution_cohesion": 0.65,
		"initiative": 0.5,
	}
	var result: Dictionary = Dictionary(controller.call("start_execution", "drill", "engage", 1, Vector2(520.0, 0.0), profile, units, units[0], simulation))
	_assert(bool(result.get("started", false)), "%s Engage execution starts" % tactical_stance)
	return {
		"state": Dictionary(result.get("movement_state", {})),
		"commands": simulation.commands.duplicate(true),
		"units": units,
	}


func _all_commands_are_engage_ready(commands: Array, expected_advance_mode: String) -> bool:
	if commands.size() != 4:
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("source_command_type", "")) != "engage":
			return false
		if String(command.get("fire_status", "")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
		if String(command.get("weapon_posture", "")) != UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED:
			return false
		if String(command.get("engage_doctrine_id", "")) != "engage_control_v1":
			return false
		if String(command.get("engage_advance_mode", "")) != expected_advance_mode:
			return false
		if String(command.get("engage_target_policy", "")) != "weapon_range_area_priority":
			return false
		if not bool(command.get("engage_fire_on_weapon_range", false)):
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
