extends SceneTree

const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

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
	print("=== TASK_120 Team Quality Execution Verifier ===")
	_test_execution_profile_separates_high_and_low_quality_teams()
	_test_movement_consumes_execution_profile_for_order_quality()
	await _test_mission_ui_reads_execution_quality()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_execution_profile_separates_high_and_low_quality_teams() -> void:
	var high_units: Array = _make_quality_team("high", 0.88, 0.82, 0.92, 0.86, 0.9, 0.9, ["calm", "steady"])
	var low_units: Array = _make_quality_team("low", 0.28, 0.34, 0.16, 0.32, 0.14, 0.18, ["reckless", "aggressive"])
	var high_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "high", high_units, high_units[0], "move", Vector2(320.0, 120.0), null, "normal")
	var low_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "low", low_units, low_units[0], "move", Vector2(320.0, 120.0), null, "normal")
	_assert(float(high_profile.order_fidelity) > float(low_profile.order_fidelity), "High quality team receives higher order fidelity")
	_assert(float(high_profile.reaction_delay_seconds) < float(low_profile.reaction_delay_seconds), "High quality team receives lower reaction delay")
	_assert(float(high_profile.execution_cohesion) > float(low_profile.execution_cohesion), "High quality team receives stronger execution cohesion")
	_assert(String(high_profile.execution_label) == "CLEAN EXEC", "High quality team exposes clean execution feedback")
	_assert(String(low_profile.execution_label) != "CLEAN EXEC", "Low quality team does not expose clean execution feedback")
	_cleanup_units(high_units + low_units)


func _test_movement_consumes_execution_profile_for_order_quality() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var target_position := Vector2(360.0, 96.0)
	var high_units: Array = _make_quality_team("high", 0.88, 0.82, 0.92, 0.86, 0.9, 0.9, ["calm", "steady"])
	var low_units: Array = _make_quality_team("low", 0.28, 0.34, 0.16, 0.32, 0.14, 0.18, ["reckless", "aggressive"])
	var high_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "high", high_units, high_units[0], "move", target_position, null, "normal")
	var low_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "low", low_units, low_units[0], "move", target_position, null, "normal")
	var high_result: Dictionary = Dictionary(controller.call("start_execution", "high", "move", 1, target_position, high_profile, high_units, high_units[0], SimulationStub.new()))
	var low_result: Dictionary = Dictionary(controller.call("start_execution", "low", "move", 1, target_position, low_profile, low_units, low_units[0], SimulationStub.new()))
	var high_state: Dictionary = Dictionary(high_result.get("movement_state", {}))
	var low_state: Dictionary = Dictionary(low_result.get("movement_state", {}))
	_assert(Vector2(low_state.get("order_target_offset", Vector2.ZERO)).length() > Vector2(high_state.get("order_target_offset", Vector2.ZERO)).length(), "Low fidelity movement receives a larger target offset")
	_assert(float(low_state.get("formation_scatter_factor", 1.0)) > float(high_state.get("formation_scatter_factor", 1.0)), "Low cohesion movement receives wider formation scatter")
	_assert(float(high_state.get("move_speed_multiplier", 1.0)) > float(low_state.get("move_speed_multiplier", 1.0)), "High initiative movement receives a better speed multiplier")
	_assert(String(low_state.get("execution_label", "")) == String(low_profile.execution_label), "Movement state preserves execution feedback label")
	_cleanup_units(high_units + low_units)


func _test_mission_ui_reads_execution_quality() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(260.0, 160.0))
	var started: bool = bool(controller.call("advance_to_next_phase"))
	await process_frame
	var profile_dict: Dictionary = Dictionary(controller.call("get_active_behavior_profile", "blue"))
	var status_text: String = String(controller.call("_build_fireteam_status_text"))
	_assert(started, "Mission scene starts an execution for UI quality feedback")
	_assert(profile_dict.has("order_fidelity") and profile_dict.has("execution_label"), "Active behavior profile exposes execution quality fields")
	_assert(status_text.contains("EXEC"), "Fireteam status text reads and displays execution quality")
	scene.queue_free()
	await process_frame


func _make_quality_team(
	fireteam_id: String,
	accuracy: float,
	speed: float,
	leadership: float,
	toughness: float,
	discipline: float,
	recognition: float,
	traits: Array
) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2.ZERO, accuracy, speed, leadership, toughness, discipline, recognition, traits),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-24.0, 8.0), accuracy, speed, leadership * 0.5, toughness, discipline, recognition, traits),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(24.0, 10.0), accuracy, speed, leadership * 0.45, toughness, discipline, recognition, traits),
	]


func _make_unit(
	unit_id: String,
	fireteam_id: String,
	is_lead: bool,
	position_value: Vector2,
	accuracy: float,
	speed: float,
	leadership: float,
	toughness: float,
	discipline: float,
	recognition: float,
	traits: Array
) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_accuracy = accuracy
	unit.skill_speed = speed
	unit.skill_leadership = leadership
	unit.skill_toughness = toughness
	unit.discipline = discipline
	unit.recognition = recognition
	unit.trait_ids = PackedStringArray(traits)
	unit.position = position_value
	unit._ready()
	return unit


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
