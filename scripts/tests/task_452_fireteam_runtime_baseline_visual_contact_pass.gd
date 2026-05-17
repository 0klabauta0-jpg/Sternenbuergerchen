extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_452_fireteam_runtime_baseline_visual_contact_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	print("=== TASK_452 Fireteam Runtime Baseline Visual Contact Pass ===")
	_test_missing_take_and_defend_presets_exist()
	_test_aim_readiness_reaches_runtime_and_visual_snapshot()
	_test_docs_capture_task()
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_missing_take_and_defend_presets_exist() -> void:
	_assert_preset("take", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, "take:cautious", "Take C uses a runtime start preset")
	_assert_preset("take", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL, "take:normal", "Take N uses a runtime start preset")
	_assert_preset("defend", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, "defend:cautious", "Defend C uses a runtime start preset")
	_assert_preset("defend", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL, "defend:normal", "Defend N uses a runtime start preset")
	_assert_preset("defend", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE, "defend:aggressive", "Defend A uses a runtime start preset")


func _test_aim_readiness_reaches_runtime_and_visual_snapshot() -> void:
	var unit = _make_unit("task452_aim_unit", "task452", true, Vector2.ZERO)
	var command = UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": "task452_aim_unit",
		"team_id": "team_alpha",
		"target_position": Vector2(128.0, 0.0),
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED,
		"movement_posture": UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TRAVEL,
		"aim_readiness_percent": 75.0,
	})
	_assert(bool(unit.call("assign_unit_command", command)), "Unit accepts an aim-readiness command")
	var runtime_status = unit.call("get_runtime_status")
	_assert(runtime_status != null and absf(float(runtime_status.get("aim_readiness_percent")) - 75.0) < 0.001, "UnitRuntimeStatus carries aim readiness")
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(view.call("_get_unit_runtime_posture_snapshot", unit))
	_assert(absf(float(snapshot.get("aim_readiness_percent", 0.0)) - 75.0) < 0.001, "3D view reads aim readiness from runtime status")
	_assert(String(view.call("_resolve_displayed_weapon_posture_from_readiness", {}, "lowered", 75.0)) == "aimed", "High aim readiness visibly raises a lowered weapon")
	_assert(String(view.call("_resolve_displayed_weapon_posture_from_readiness", {}, "lowered", 30.0)) == "lowered", "Low aim readiness keeps a lowered weapon lowered")
	view.queue_free()
	unit.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_452 - Fireteam Runtime Baseline Visual Contact Pass"), "TASK_452 task file exists")
	_assert(status_text.contains("TASK_452 - Fireteam Runtime Baseline Visual Contact Pass"), "Implementation status documents TASK_452")
	_assert(roadmap_text.contains("TASK_452 - Fireteam Runtime Baseline Visual Contact Pass"), "Roadmap lists TASK_452")
	_assert(contract_text.contains("TASK_452 Startpresets"), "Behavior contract documents TASK_452 start presets")


func _assert_preset(command_type: String, stance: String, expected_key: String, label: String) -> void:
	var result: Dictionary = _execute(command_type, stance)
	var state: Dictionary = Dictionary(result.get("state", {}))
	_assert(String(state.get("formation_preset_key", "")) == expected_key, label)
	_assert(String(state.get("formation_slot_source", "")).begins_with("fireteam_formation_tuning_2026-05-17"), "%s exposes the runtime preset source" % expected_key)
	_assert(Dictionary(state.get("current_target_positions", {})).size() == 4, "%s builds four formation targets" % expected_key)
	_cleanup_units(Array(result.get("units", [])))


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


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit is Node:
			(unit as Node).queue_free()


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command: Dictionary) -> void:
		commands.append(command.duplicate(true))
