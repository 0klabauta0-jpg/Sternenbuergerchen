extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const CONTROLLER_PATH := "res://scripts/tactical/fireteam_movement_controller.gd"
const CONTRACT_PATH := "res://docs/dev/fireteam_behavior_modes_contract.md"
const TASK_421_PATH := "res://docs/tasks/TASK_421_move_stance_posture_speed_sight.md"
const TASK_425_PATH := "res://docs/tasks/TASK_425_live_move_stance_update.md"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1135 Tactical Stance Doctrine Contract Reconciliation ===")
	_test_global_profile_values()
	_test_command_specific_postures_survive()
	_test_single_balance_source()
	_test_historical_contract_markers()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_global_profile_values() -> void:
	var expected := {
		"cautious": Vector2(0.35, 1.0),
		"normal": Vector2(0.65, 0.8),
		"aggressive": Vector2(1.0, 0.5),
	}
	for command_type in ["move", "defend", "take", "engage"]:
		for stance in ["cautious", "normal", "aggressive"]:
			var modifiers: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", command_type, stance)
			var values: Vector2 = expected[stance]
			_assert(is_equal_approx(float(modifiers.get("speed_multiplier", -1.0)), values.x), "%s/%s uses global speed" % [command_type, stance])
			_assert(is_equal_approx(float(modifiers.get("sight_range_factor", -1.0)), values.y), "%s/%s uses global sight" % [command_type, stance])


func _test_command_specific_postures_survive() -> void:
	var move_normal: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", "move", "normal")
	var defend_normal: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", "defend", "normal")
	var take_aggressive: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", "take", "aggressive")
	_assert(String(move_normal.get("movement_posture", "")) == "travel" and String(move_normal.get("weapon_posture", "")) == "lowered", "Move normal keeps travel/lowered identity")
	_assert(String(defend_normal.get("movement_posture", "")) == "tactical" and String(defend_normal.get("weapon_posture", "")) == "ready", "Defend normal keeps tactical/ready identity")
	_assert(String(take_aggressive.get("movement_posture", "")) == "run" and String(take_aggressive.get("weapon_posture", "")) == "aimed", "Take aggressive keeps run/aimed identity")


func _test_single_balance_source() -> void:
	var source := _read_text(CONTROLLER_PATH)
	_assert(source.contains("STANCE_CAUTIOUS_SPEED_MULTIPLIER") and source.contains("STANCE_AGGRESSIVE_SIGHT_FACTOR"), "Controller retains the global stance profile")
	var obsolete_markers := [
		"MOVE_STANCE_CAUTIOUS_SPEED_MULTIPLIER",
		"DEFEND_STANCE_NORMAL_SIGHT_FACTOR",
		"TAKE_STANCE_AGGRESSIVE_ATTACK_BONUS",
		"ENGAGE_STANCE_CAUTIOUS_SPEED_MULTIPLIER",
	]
	var has_obsolete := false
	for marker in obsolete_markers:
		has_obsolete = has_obsolete or source.contains(marker)
	_assert(not has_obsolete, "Controller no longer advertises ignored command-specific stance balance")


func _test_historical_contract_markers() -> void:
	var contract := _read_text(CONTRACT_PATH)
	var task_421 := _read_text(TASK_421_PATH)
	var task_425 := _read_text(TASK_425_PATH)
	_assert(contract.contains("seit TASK_451 globale Haltungsprofile"), "Current behavior contract names TASK_451 global authority")
	_assert(task_421.contains("TASK_1135") and task_421.contains("superseded"), "TASK_421 marks old balance as superseded")
	_assert(task_425.contains("TASK_1135") and task_425.contains("superseded"), "TASK_425 marks old balance as superseded")


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
