extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"

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
	print("=== TASK_446 Fireteam Workbench Spacing Runtime Pass ===")
	_test_move_stances_use_wide_parallel_slots()
	_test_engage_bounding_keeps_buddy_spacing()
	_test_engage_aggressive_uses_wide_fireline()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_move_stances_use_wide_parallel_slots() -> void:
	var expectations: Dictionary = {
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS: 80.0,
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL: 117.0,
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE: 117.0,
	}
	for stance in expectations.keys():
		var result: Dictionary = _execute("move", String(stance))
		var state: Dictionary = Dictionary(result.get("state", {}))
		var targets: Dictionary = Dictionary(state.get("current_target_positions", {}))
		var expected_spacing: float = float(expectations.get(stance, 0.0))
		_assert(absf(float(state.get("formation_parallel_spacing_world", 0.0)) - expected_spacing) <= 0.001, "Move %s exposes workbench parallel spacing %.0f" % [stance, expected_spacing])
		_assert(String(state.get("formation_slot_source", "")).begins_with("fireteam_formation_tuning_2026-05-17"), "Move %s uses the imported workbench source" % stance)
		_assert(_minimum_target_distance(targets) >= 70.0, "Move %s keeps readable target spacing" % stance)
		_assert(_lateral_span(targets, state) >= 80.0, "Move %s keeps lateral separation from the saved preset" % stance)
		_cleanup_units(Array(result.get("units", [])))


func _test_engage_bounding_keeps_buddy_spacing() -> void:
	for stance in [FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL]:
		var result: Dictionary = _execute("engage", String(stance))
		var state: Dictionary = Dictionary(result.get("state", {}))
		var targets: Dictionary = Dictionary(state.get("current_target_positions", {}))
		_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING, "Engage %s remains buddy-bounding" % stance)
		_assert(_minimum_target_distance(targets) >= 70.0, "Engage %s keeps readable buddy spacing" % stance)
		_cleanup_units(Array(result.get("units", [])))


func _test_engage_aggressive_uses_wide_fireline() -> void:
	var result: Dictionary = _execute("engage", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE)
	var state: Dictionary = Dictionary(result.get("state", {}))
	var targets: Dictionary = Dictionary(state.get("current_target_positions", {}))
	_assert(String(state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "Aggressive Engage remains fireline rush")
	_assert(absf(float(state.get("formation_parallel_spacing_world", 0.0)) - 93.0) <= 0.001, "Aggressive Engage exposes imported workbench spacing")
	_assert(_minimum_target_distance(targets) >= 80.0, "Aggressive Engage target slots are wide enough to read")
	_assert(_lateral_span(targets, state) > _forward_span(targets, state) + 80.0, "Aggressive Engage advances as a wide fireline")
	_cleanup_units(Array(result.get("units", [])))


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	_assert(task_text.contains("TASK_446 - Fireteam Workbench Spacing Runtime Pass"), "TASK_446 task file exists")
	_assert(status_text.contains("TASK_446 - Fireteam Workbench Spacing Runtime Pass"), "Implementation status documents TASK_446")
	_assert(roadmap_text.contains("TASK_446 - Fireteam Workbench Spacing Runtime Pass"), "Roadmap lists TASK_446")
	_assert(movement_text.contains("MOVE_CAUTIOUS_PARALLEL_TARGET_SPACING"), "Movement controller exposes workbench spacing constants")


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


func _minimum_target_distance(targets: Dictionary) -> float:
	var positions: Array = targets.values()
	var min_distance: float = INF
	for left_index in range(positions.size()):
		for right_index in range(left_index + 1, positions.size()):
			min_distance = minf(min_distance, Vector2(positions[left_index]).distance_to(Vector2(positions[right_index])))
	return min_distance if min_distance < INF else 0.0


func _lateral_span(targets: Dictionary, state: Dictionary) -> float:
	return _axis_span(targets, state, _movement_lateral(state))


func _forward_span(targets: Dictionary, state: Dictionary) -> float:
	return _axis_span(targets, state, _movement_forward(state))


func _axis_span(targets: Dictionary, _state: Dictionary, axis: Vector2) -> float:
	if axis.is_zero_approx() or targets.is_empty():
		return 0.0
	var min_value: float = INF
	var max_value: float = -INF
	for position_variant in targets.values():
		var projected: float = Vector2(position_variant).dot(axis.normalized())
		min_value = minf(min_value, projected)
		max_value = maxf(max_value, projected)
	return max_value - min_value


func _movement_forward(state: Dictionary) -> Vector2:
	var origin: Vector2 = Vector2(state.get("origin_anchor_position", Vector2.ZERO))
	var target: Vector2 = Vector2(state.get("final_target_position", origin + Vector2.RIGHT))
	var direction: Vector2 = target - origin
	return direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT


func _movement_lateral(state: Dictionary) -> Vector2:
	return _movement_forward(state).orthogonal().normalized()


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
