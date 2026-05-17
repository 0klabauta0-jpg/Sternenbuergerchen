extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_451_fireteam_workbench_runtime_import.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	print("TASK_451 Fireteam Workbench Runtime Import")
	_test_runtime_stance_profile_values()
	_test_imported_formation_slots_are_used()
	_test_unit_commands_carry_contact_and_target_support()
	_test_team_target_support_adjusts_hit_chance()
	_test_contact_initiative_adjusts_detection_delay()
	_test_docs_capture_task()
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_runtime_stance_profile_values() -> void:
	_assert_stance("move", "cautious", 0.35, 1.0, 75.0, 75.0, -0.3, 5.0)
	_assert_stance("take", "normal", 0.65, 0.8, 45.0, 30.0, 0.3, 0.0)
	_assert_stance("engage", "aggressive", 1.0, 0.5, 20.0, 35.0, 0.0, -3.0)
	_assert_stance("defend", "cautious", 0.35, 1.0, 75.0, 75.0, -0.3, 5.0)


func _test_imported_formation_slots_are_used() -> void:
	var result: Dictionary = _execute("engage", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS)
	var state: Dictionary = Dictionary(result.get("state", {}))
	var targets: Dictionary = Dictionary(state.get("current_target_positions", {}))
	_assert(String(state.get("formation_preset_key", "")) == "engage:cautious", "Engage C exposes imported preset key")
	_assert(String(state.get("formation_slot_source", "")).begins_with("fireteam_formation_tuning_2026-05-17"), "Engage C exposes _05 runtime source")
	_assert(String(state.get("formation_leader_slot", "")) == "unit_3", "Engage C keeps leader slot from _05")
	var anchor: Vector2 = Vector2(state.get("current_anchor_target_position", Vector2.ZERO))
	var forward: Vector2 = (anchor - Vector2.ZERO).normalized()
	var lateral: Vector2 = forward.orthogonal()
	_assert_slot_components(Vector2(targets.get("engage_cautious_lead", Vector2.ZERO)), anchor, lateral, forward, -9.0, 6.0, "Leader uses saved unit_3 slot")
	_assert_slot_components(Vector2(targets.get("engage_cautious_a", Vector2.ZERO)), anchor, lateral, forward, 31.0, 76.0, "Second member uses saved unit_1 slot")
	_cleanup_units(Array(result.get("units", [])))


func _test_unit_commands_carry_contact_and_target_support() -> void:
	var result: Dictionary = _execute("move", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS)
	var commands: Array = Array(result.get("commands", []))
	_assert(not commands.is_empty(), "Move C enqueues commands")
	if not commands.is_empty():
		var command: Dictionary = Dictionary(commands[0])
		_assert(absf(float(command.get("contact_initiative_seconds", 99.0)) + 0.3) < 0.001, "Command carries contact initiative")
		_assert(absf(float(command.get("team_target_support_percent", 0.0)) - 5.0) < 0.001, "Command carries team target support")
		_assert(absf(float(command.get("behavior_aim_readiness_percent", 0.0)) - 75.0) < 0.001, "Command carries aim readiness")
	_cleanup_units(Array(result.get("units", [])))


func _test_team_target_support_adjusts_hit_chance() -> void:
	var attacker = _make_unit("attacker", "alpha", true, Vector2.ZERO)
	var target = _make_unit("target", "bravo", false, Vector2(64.0, 0.0))
	attacker.team_id = "team_alpha"
	target.team_id = "team_bravo"
	var command = UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"team_target_support_percent": 5.0,
		"target_position": Vector2(64.0, 0.0),
	})
	attacker.call("assign_unit_command", command)
	var result: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("build_damage_effect", {
		"attacker": attacker,
		"target": target,
		"attacker_id": "attacker",
		"target_id": "target",
		"contact_state": "confirmed",
	}, {"friendly_team_id": "team_alpha"}))
	var effect: Dictionary = Dictionary(result.get("effect", {}))
	var expected_hit: float = clampf(float(WEAPON_DATA_SCRIPT.call("get_base_hit_chance", "rifle")) + 0.05, 0.02, 0.98)
	_assert(absf(float(effect.get("hit_chance", 0.0)) - expected_hit) < 0.001, "Team target support adjusts hit chance")
	_assert(absf(float(effect.get("team_target_support_percent", 0.0)) - 5.0) < 0.001, "Damage effect exposes target support percent")
	_cleanup_units([attacker, target])


func _test_contact_initiative_adjusts_detection_delay() -> void:
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	var base_unit = _make_unit("base_detector", "alpha", true, Vector2.ZERO)
	var cautious_unit = _make_unit("cautious_detector", "alpha", true, Vector2.ZERO)
	var normal_unit = _make_unit("normal_detector", "alpha", true, Vector2.ZERO)
	base_unit.awareness = 0.5
	cautious_unit.awareness = 0.5
	normal_unit.awareness = 0.5
	cautious_unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA, "contact_initiative_seconds": -0.3, "target_position": Vector2.ZERO}))
	normal_unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA, "contact_initiative_seconds": 0.3, "target_position": Vector2.ZERO}))
	var base_delay: int = int(driver.call("_get_detection_delay_ticks", base_unit))
	var cautious_delay: int = int(driver.call("_get_detection_delay_ticks", cautious_unit))
	var normal_delay: int = int(driver.call("_get_detection_delay_ticks", normal_unit))
	_assert(cautious_delay < base_delay, "Cautious contact initiative shortens detection")
	_assert(normal_delay > base_delay, "Normal contact initiative can lengthen detection")
	_cleanup_units([base_unit, cautious_unit, normal_unit])


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_451 - Fireteam Workbench Runtime Import"), "TASK_451 task file exists")
	_assert(status_text.contains("TASK_451 - Fireteam Workbench Runtime Import"), "Implementation status documents TASK_451")
	_assert(contract_text.contains("Runtime-Uebernahme aus Workbench `_05`"), "Behavior contract documents runtime import")


func _assert_stance(command_type: String, stance: String, speed: float, sight: float, cover: float, aim: float, contact_seconds: float, target_support: float) -> void:
	var modifiers: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", command_type, stance)
	var label: String = "%s/%s" % [command_type, stance]
	_assert(absf(float(modifiers.get("speed_multiplier", 0.0)) - speed) < 0.001, "%s speed from workbench" % label)
	_assert(absf(float(modifiers.get("sight_range_factor", 0.0)) - sight) < 0.001, "%s sight from workbench" % label)
	_assert(absf(float(modifiers.get("cover_priority_percent", 0.0)) - cover) < 0.001, "%s cover priority from workbench" % label)
	_assert(absf(float(modifiers.get("aim_readiness_percent", 0.0)) - aim) < 0.001, "%s aim readiness from workbench" % label)
	_assert(absf(float(modifiers.get("contact_initiative_seconds", 0.0)) - contact_seconds) < 0.001, "%s contact initiative from workbench" % label)
	_assert(absf(float(modifiers.get("team_target_support_percent", 0.0)) - target_support) < 0.001, "%s target support from workbench" % label)


func _execute(command_type: String, tactical_stance: String) -> Dictionary:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("%s_%s" % [command_type, tactical_stance])
	var profile := {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH,
		"tactical_stance": tactical_stance,
		"cover_priority": 0.55,
		"cohesion_threshold": 120.0,
		"order_fidelity": 1.0,
		"execution_cohesion": 0.65,
		"initiative": 0.5,
	}
	var result: Dictionary = Dictionary(controller.call("start_execution", "drill", command_type, 1, Vector2(520.0, 0.0), profile, units, units[0], simulation))
	_assert(bool(result.get("started", false)), "%s %s execution starts" % [command_type, tactical_stance])
	return {
		"state": Dictionary(result.get("movement_state", {})),
		"commands": simulation.commands.duplicate(true),
		"units": units,
	}


func _make_fireteam_units(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-24.0, 0.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(18.0, -10.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 20.0)),
	]


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2):
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


func _slot_close(actual: Vector2, expected: Vector2) -> bool:
	return actual.distance_to(expected) < 0.01


func _assert_slot_components(actual: Vector2, anchor: Vector2, lateral: Vector2, forward: Vector2, expected_lateral: float, expected_forward: float, label: String) -> void:
	var delta: Vector2 = actual - anchor
	var lateral_value: float = lateral.dot(delta)
	var forward_value: float = forward.dot(delta)
	_assert(absf(lateral_value - expected_lateral) < 0.01 and absf(forward_value - expected_forward) < 0.01, label)


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit is Node:
			(unit as Node).queue_free()


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


class SimulationStub:
	var commands: Array = []

	func enqueue_command(command: Dictionary) -> void:
		commands.append(command.duplicate(true))
