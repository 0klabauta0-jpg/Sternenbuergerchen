extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"

const NUL_CHECK_PATHS: PackedStringArray = [
	"res://docs/dev/fireteam_behavior_modes_contract.md",
	"res://docs/reports/fireteam_behavior_control_checklist.html",
	"res://docs/reports/fireteam_command_decision_reference.html",
	"res://docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md",
	"res://scripts/tactical/fireteam_security_controller.gd",
	"res://scripts/tests/task_429_fireteam_behavior_modes_runtime.gd",
	"res://scripts/tools/generate_fireteam_command_drill_24x24.gd",
	"res://data/mission_scenarios/fireteam_command_drill_24x24.json",
]

var _passed: int = 0
var _failed: int = 0


class DummyUnit extends Node2D:
	var unit_id: String = ""
	var is_fireteam_lead: bool = false
	var leadership: float = 0.8
	var accuracy: float = 0.55

	func _init(next_unit_id: String, next_position: Vector2, next_is_lead: bool = false) -> void:
		unit_id = next_unit_id
		global_position = next_position
		is_fireteam_lead = next_is_lead

	func get_unit_id() -> String:
		return unit_id

	func get_vital_state() -> String:
		return "fit"

	func get_accuracy_skill() -> float:
		return accuracy

	func get_leadership_skill() -> float:
		return leadership

	func get_trait_ids() -> PackedStringArray:
		return PackedStringArray()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_429 Fireteam Behavior Modes Runtime ===")
	_test_behavior_modifier_table()
	_test_security_controller_defense_distribution()
	_test_scenario_and_text_files()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_behavior_modifier_table() -> void:
	_assert_modifier("move", "cautious", 0.65, 1.2, 0.0, 0.0, "engage", "aimed")
	_assert_modifier("move", "normal", 1.0, 1.0, 0.0, 0.0, "travel", "lowered")
	_assert_modifier("move", "aggressive", 1.2, 0.65, 0.0, 0.0, "run", "lowered")
	_assert_modifier("defend", "cautious", 0.8, 1.2, 15.0, -0.03, "engage", "aimed")
	_assert_modifier("defend", "normal", 1.0, 1.0, 0.0, 0.0, "tactical", "ready")
	_assert_modifier("defend", "aggressive", 1.1, 0.85, -10.0, 0.04, "engage", "aimed")
	_assert_modifier("take", "cautious", 0.7, 1.15, 10.0, 0.0, "engage", "aimed")
	_assert_modifier("take", "normal", 1.0, 1.0, 0.0, 0.0, "travel", "ready")
	_assert_modifier("take", "aggressive", 1.2, 0.75, -12.0, 0.06, "run", "aimed")
	_assert_modifier("engage", "cautious", 0.75, 1.15, 10.0, 0.02, "engage", "aimed")
	_assert_modifier("engage", "normal", 1.0, 1.0, 0.0, 0.0, "engage", "aimed")
	_assert_modifier("engage", "aggressive", 1.15, 0.8, -8.0, 0.08, "run", "aimed")


func _test_security_controller_defense_distribution() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	_assert(controller.has_method("get_fireteam_state"), "FireteamSecurityController exposes get_fireteam_state")
	var units: Array = [
		DummyUnit.new("alpha", Vector2(0, 0), true),
		DummyUnit.new("bravo", Vector2(32, 0)),
		DummyUnit.new("charlie", Vector2(0, 32)),
		DummyUnit.new("delta", Vector2(32, 32)),
	]
	var state: Dictionary = Dictionary(controller.call(
		"update_fireteam_state",
		"drill",
		units,
		units[0],
		{
			"metadata": {
				"origin_command_type": "defend",
				"security_mode_override": "360",
			},
		},
		{},
		{},
		{},
		[],
		{
			"command_type": "defend",
			"security_mode": "360",
		}
	))
	_assert(String(state.get("command_type", "")) == "defend", "Security state keeps defend command type")
	_assert(String(state.get("security_mode", "")) == "360", "Security state uses 360 mode")
	_assert(bool(state.get("defense_ready", false)), "Defense readiness is exposed")
	_assert(not bool(state.get("overwatch_ready", true)), "Overwatch is disabled for the new baseline")
	var assignments: Array = Array(state.get("member_assignments", []))
	_assert(assignments.size() == 4, "Four members receive defense assignments")
	if assignments.size() == 4:
		_assert(_angle_close(float(Dictionary(assignments[0]).get("base_angle", 99.0)), -PI * 0.5), "First member covers north")
		_assert(_angle_close(float(Dictionary(assignments[1]).get("base_angle", 99.0)), 0.0), "Second member covers east")
		_assert(_angle_close(float(Dictionary(assignments[2]).get("base_angle", 99.0)), PI * 0.5), "Third member covers south")
		_assert(_angle_close(absf(float(Dictionary(assignments[3]).get("base_angle", 0.0))), PI), "Fourth member covers west")


func _test_scenario_and_text_files() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Drill scenario loads")
	if scenario != null:
		var validation: Dictionary = Dictionary(scenario.call("validate"))
		_assert(bool(validation.get("valid", false)), "Drill scenario validates")
	for path in NUL_CHECK_PATHS:
		var text: String = _read_text(String(path))
		_assert(not text.is_empty(), "%s is readable" % String(path))
		_assert(not _contains_nul_codepoint(text), "%s is NUL-free" % String(path))


func _assert_modifier(command_type: String, stance: String, speed: float, sight: float, cover: float, attack: float, movement_posture: String, weapon_posture: String) -> void:
	var modifiers: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", command_type, stance)
	var label: String = "%s/%s" % [command_type, stance]
	_assert(absf(float(modifiers.get("speed_multiplier", 0.0)) - speed) < 0.001, "%s speed multiplier" % label)
	_assert(absf(float(modifiers.get("sight_range_factor", 0.0)) - sight) < 0.001, "%s sight factor" % label)
	_assert(absf(float(modifiers.get("cover_score_bonus", 0.0)) - cover) < 0.001, "%s cover bonus" % label)
	_assert(absf(float(modifiers.get("attack_bonus", 0.0)) - attack) < 0.001, "%s attack bonus" % label)
	_assert(String(modifiers.get("movement_posture", "")) == movement_posture, "%s movement posture" % label)
	_assert(String(modifiers.get("weapon_posture", "")) == weapon_posture, "%s weapon posture" % label)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _contains_nul_codepoint(text: String) -> bool:
	for index in range(text.length()):
		if text.unicode_at(index) == 0:
			return true
	return false


func _angle_close(a: float, b: float) -> bool:
	return absf(wrapf(a - b, -PI, PI)) < 0.02


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
