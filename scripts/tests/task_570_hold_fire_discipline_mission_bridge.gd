extends SceneTree

const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_570_hold_fire_discipline_mission_bridge.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const UNIT_COMMAND_PATH: String = "res://scripts/npc/unit_command.gd"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const COMBAT_RESOLVER_PATH: String = "res://scripts/tactical/combat_fire_decision_resolver.gd"
const MISSION_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const COMBAT_DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"

var _passed: int = 0
var _failed: int = 0


class FakeSimulationRoot:
	extends Node

	var commands: Array = []

	func enqueue_command(command: Dictionary) -> void:
		commands.append(command.duplicate(true))


class FakeUnit:
	extends Node2D

	var unit_id: String = "alpha_1"
	var team_id: String = "team_alpha"
	var fireteam_id: String = "blue"
	var active_weapon_id: String = "rifle"
	var _current_unit_command = null

	func _init(next_unit_id: String = "alpha_1", next_team_id: String = "team_alpha", next_fireteam_id: String = "blue") -> void:
		unit_id = next_unit_id
		team_id = next_team_id
		fireteam_id = next_fireteam_id

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_fireteam_id() -> String:
		return fireteam_id

	func get_vital_state() -> String:
		return "fit"

	func get_active_weapon_id() -> String:
		return active_weapon_id

	func get_current_unit_command():
		return _current_unit_command

	func get_fire_status() -> String:
		if _current_unit_command != null and _current_unit_command.has_method("get"):
			return String(_current_unit_command.get("fire_status"))
		return "fire_at_will"

	func get_speed_skill() -> float:
		return 0.5

	func get_accuracy_skill() -> float:
		return 0.5

	func assign_unit_command(command) -> bool:
		_current_unit_command = command
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_570 Hold Fire Discipline Mission Bridge ===")
	_test_docs_and_wiring()
	_test_combat_fire_rule_matrix()
	_test_movement_fire_rule_bridge()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_570: FAILED")
		quit(1)
		return
	print("TASK_570: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var unit_command_text: String = _read_text(UNIT_COMMAND_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var combat_text: String = _read_text(COMBAT_RESOLVER_PATH)
	var mission_controller_text: String = _read_text(MISSION_CONTROLLER_PATH)
	var combat_driver_text: String = _read_text(COMBAT_DRIVER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_570 task file exists")
	_assert(task_text.contains("Hold Fire Discipline Mission Bridge"), "TASK_570 task file names the bridge")
	_assert(status_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "Implementation status tracks TASK_570")
	_assert(roadmap_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge (implementiert)"), "Roadmap marks TASK_570 implemented")
	_assert(roadmap_text.contains("TASK_571 - Fire Rule Controls Readability Polish"), "Roadmap names TASK_571 follow-up")
	_assert(report_text.contains("TASK_570 - Hold Fire Discipline Mission Bridge"), "HTML report tracks TASK_570")
	_assert(report_text.contains("TASK_571 - Fire Rule Controls Readability Polish"), "HTML report names TASK_571 follow-up")
	_assert(contract_text.contains("Hold-Fire-Discipline-Mission-Bridge"), "Mission command feedback contract documents TASK_570")
	_assert(unit_command_text.contains("var fire_rule"), "UnitCommand carries fire_rule")
	_assert(movement_text.contains("_resolve_unit_command_fire_rule"), "FireteamMovementController resolves fire_rule")
	_assert(combat_text.contains("can_return_fire"), "Combat resolver accepts return-fire context")
	_assert(mission_controller_text.contains("set_fireteams_fire_rule"), "Mission controller exposes fire-rule setter")
	_assert(combat_driver_text.contains("RETURN_FIRE_WINDOW_TICKS"), "Combat driver owns return-fire window")


func _test_combat_fire_rule_matrix() -> void:
	_assert(not _can_unit_attack_for_rule(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD, {}), "hold blocks voluntary fire")
	_assert(not _can_unit_attack_for_rule(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_RETURN, {}), "return blocks without incoming-fire context")
	_assert(_can_unit_attack_for_rule(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_RETURN, {"can_return_fire": Callable(self, "_always_true")}), "return fires when incoming-fire window is active")
	_assert(_can_unit_attack_for_rule(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_FREE, {}), "free keeps unit fire-ready")
	_assert(_can_unit_attack_for_rule(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS, {}), "suppress keeps unit fire-ready for the MVP bridge")


func _test_movement_fire_rule_bridge() -> void:
	var expected_status_by_rule: Dictionary = {
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD: UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE,
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_RETURN: UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE,
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_FREE: UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS: UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
	}
	for fire_rule in expected_status_by_rule.keys():
		var unit := FakeUnit.new("alpha_%s" % fire_rule, "team_alpha", "blue")
		var simulation_root := FakeSimulationRoot.new()
		var movement_controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
		root.add_child(simulation_root)
		root.add_child(unit)
		var result: Dictionary = Dictionary(movement_controller.call(
			"start_execution",
			"blue",
			"move",
			1,
			Vector2(96.0, 0.0),
			_build_behavior_profile(fire_rule),
			[unit],
			unit,
			simulation_root,
			null
		))
		_assert(bool(result.get("started", false)), "movement execution starts for fire rule %s" % fire_rule)
		var command = unit.get_current_unit_command()
		_assert(command != null, "unit receives command for fire rule %s" % fire_rule)
		if command != null:
			_assert(String(command.get("fire_rule")) == fire_rule, "UnitCommand stores fire rule %s" % fire_rule)
			_assert(String(command.get("fire_status")) == String(expected_status_by_rule[fire_rule]), "UnitCommand maps fire status for %s" % fire_rule)
			var state: Dictionary = Dictionary(result.get("movement_state", {}))
			_assert(String(state.get("fire_rule", "")) == fire_rule, "movement state snapshots fire rule %s" % fire_rule)
		_assert(simulation_root.commands.size() > 0, "SimulationRoot receives command for fire rule %s" % fire_rule)
		if simulation_root.commands.size() > 0:
			var command_dict: Dictionary = Dictionary(simulation_root.commands[0])
			_assert(String(command_dict.get("fire_rule")) == fire_rule, "queued command dict carries fire rule %s" % fire_rule)
		unit.queue_free()
		simulation_root.queue_free()


func _can_unit_attack_for_rule(fire_rule: String, context: Dictionary) -> bool:
	var unit := FakeUnit.new("alpha_rule_%s" % fire_rule, "team_alpha", "blue")
	root.add_child(unit)
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
	command.priority = 12
	command.unit_id = unit.unit_id
	command.team_id = unit.team_id
	command.target_position = Vector2.ZERO
	command.source_command_type = "defend"
	command.fire_rule = fire_rule
	match fire_rule:
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD, TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_RETURN:
			command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE
		_:
			command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	unit.assign_unit_command(command)
	var result: bool = bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_unit_attack", unit, context))
	unit.queue_free()
	return result


func _build_behavior_profile(fire_rule: String) -> Dictionary:
	return {
		"fireteam_id": "blue",
		"leader_unit_id": "alpha_%s" % fire_rule,
		"advance_style": "rush",
		"cover_priority": 0.5,
		"fire_discipline": "semi_disciplined",
		"cohesion_threshold": 100.0,
		"suppression_threshold": 1,
		"tactical_stance": "normal",
		"order_fidelity": 0.65,
		"reaction_delay_seconds": 0.25,
		"execution_cohesion": 0.65,
		"execution_fire_discipline": 0.65,
		"contact_stability": 0.65,
		"initiative": 0.5,
		"execution_label": "STEADY",
		"execution_reason": "test",
		"execution_hint": "test",
		"metadata": {
			"fire_rule": fire_rule,
		},
	}


func _always_true(_unit = null) -> bool:
	return true


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
