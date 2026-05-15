extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const HTML_PATH: String = "res://docs/reports/fireteam_command_decision_reference.html"
const TASK_PATH: String = "res://docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const BUBBLE_PATH: String = "res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_427 Fireteam Decision Feedback Aim Pose ===")
	_test_cautious_move_modifiers()
	_test_decision_reference()
	_test_feedback_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_cautious_move_modifiers() -> void:
	var cautious: Dictionary = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.call("get_behavior_stance_modifiers", "move", "cautious")
	_assert(String(cautious.get("movement_posture", "")) == UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, "Move+C uses engage movement posture")
	_assert(String(cautious.get("weapon_posture", "")) == UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, "Move+C uses aimed weapon posture")
	_assert(absf(float(cautious.get("speed_multiplier", 0.0)) - 0.65) < 0.001, "Move+C speed is 65%")
	_assert(absf(float(cautious.get("sight_range_factor", 0.0)) - 1.2) < 0.001, "Move+C sight is 120%")


func _test_decision_reference() -> void:
	var html_text: String = _read_text(HTML_PATH)
	for token in ["Move", "Defend", "Take", "Engage", "C", "N", "A", "Tile", "Area", "OVW", "DEF 360"]:
		_assert(html_text.contains(token), "Decision reference contains %s" % token)
	_assert(not _contains_nul_codepoint(html_text), "Decision reference is NUL-free text")


func _test_feedback_paths() -> void:
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var bubble_text: String = _read_text(BUBBLE_PATH)
	_assert(controller_text.contains("_build_selected_decision_status_text"), "Mission controller builds selected decision status text")
	_assert(controller_text.contains("_build_decision_effect_text"), "Mission controller builds decision effect text")
	_assert(controller_text.contains("MOVE"), "Mission controller can report MOVE")
	_assert(controller_text.contains("DEF"), "Mission controller can report DEF")
	_assert(bubble_text.contains("order") or bubble_text.contains("command"), "Feedback bubble resolver keeps command/order text path")
	var task_text: String = _read_text(TASK_PATH)
	_assert(task_text.contains("Move + C"), "TASK_427 documents Move + C aim check")


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
