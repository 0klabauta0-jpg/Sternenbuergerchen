extends SceneTree

const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const OVERWATCH_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/overwatch_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var effects: Array = []

	func enqueue_effect(effect_dict: Dictionary) -> void:
		effects.append(effect_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_111 Fireteam Security + Overwatch Verifier ===")
	_test_security_controller_assigns_360_sectors_for_high_leadership()
	_test_security_controller_prefers_directional_with_low_leadership_and_aggressive_focus()
	_test_security_mode_override_keeps_post_drop_360()
	await _test_directional_sector_shift_reacts_with_leadership_delay()
	_test_overwatch_triggers_on_enemy_movement_inside_watched_sector()
	_test_overwatch_stays_disabled_under_suppression_or_movement()
	await _test_scene_exposes_security_snapshot_for_holding_fireteams()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_security_controller_assigns_360_sectors_for_high_leadership() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("sec_lead", "blue", true, Vector2(0.0, 0.0), 0.42, 0.62, 0.82, ["steady"])
	var wing_a = _make_unit("sec_a", "blue", false, Vector2(-12.0, 10.0), 0.51, 0.58, 0.35, [])
	var wing_b = _make_unit("sec_b", "blue", false, Vector2(12.0, 12.0), 0.48, 0.57, 0.34, [])
	var state: Dictionary = controller.update_fireteam_state("blue", [leader, wing_a, wing_b], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [])
	_assert(String(state.get("security_mode", "")) == "360", "High-leadership hold fireteams default to 360 security")
	_assert(Array(state.get("member_assignments", [])).size() == 3, "360 security builds one sector assignment per fit member")
	_assert(bool(state.get("overwatch_ready", false)), "Holding fireteams become overwatch-ready when no movement is active")
	_cleanup_units([leader, wing_a, wing_b])


func _test_security_controller_prefers_directional_with_low_leadership_and_aggressive_focus() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("dir_lead", "gold", true, Vector2(0.0, 0.0), 0.55, 0.48, 0.32, ["aggressive"])
	var wing = _make_unit("dir_wing", "gold", false, Vector2(14.0, 14.0), 0.45, 0.7, 0.28, [])
	var enemy = _make_enemy("enemy_focus", Vector2(90.0, 0.0))
	var state: Dictionary = controller.update_fireteam_state("gold", [leader, wing], leader, _build_behavior_profile("take"), {}, {}, {}, [enemy])
	var assignments: Array = Array(state.get("member_assignments", []))
	_assert(String(state.get("security_mode", "")) == "directional", "Low leadership or aggressive threat focus selects directional security")
	_assert(assignments.size() == 2, "Directional security still assigns all fit members")
	if assignments.size() == 2:
		var first_angle: float = float(Dictionary(assignments[0]).get("center_angle", 0.0))
		var second_angle: float = float(Dictionary(assignments[1]).get("center_angle", 99.0))
		_assert(absf(first_angle - second_angle) < 0.001, "Directional security points all assignments at the same main threat direction")
	_cleanup_units([leader, wing, enemy])


func _test_security_mode_override_keeps_post_drop_360() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("drop_lead", "blue", true, Vector2(0.0, 0.0), 0.55, 0.48, 0.28, ["aggressive"])
	var wing = _make_unit("drop_wing", "blue", false, Vector2(14.0, 14.0), 0.45, 0.7, 0.28, [])
	var enemy = _make_enemy("drop_enemy", Vector2(90.0, 0.0))
	var profile: Dictionary = _build_behavior_profile("hold_position")
	var metadata: Dictionary = Dictionary(profile.get("metadata", {}))
	metadata["origin"] = "post_drop_360_security"
	metadata["security_mode_override"] = "360"
	profile["metadata"] = metadata
	var state: Dictionary = controller.update_fireteam_state("blue", [leader, wing], leader, profile, {}, {}, {}, [enemy])
	_assert(String(state.get("security_mode", "")) == "360", "Post-drop behavior profile can force immediate 360 security")
	_cleanup_units([leader, wing, enemy])


func _test_directional_sector_shift_reacts_with_leadership_delay() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("shift_lead", "blue", true, Vector2(0.0, 0.0), 0.55, 0.42, 0.58, ["aggressive"])
	var wing = _make_unit("shift_wing", "blue", false, Vector2(-8.0, 10.0), 0.49, 0.62, 0.31, [])
	var enemy_right = _make_enemy("enemy_right", Vector2(100.0, 0.0))
	var state_a: Dictionary = controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [enemy_right])
	var angle_a: float = float(state_a.get("direction_angle", 0.0))
	var enemy_left = _make_enemy("enemy_left", Vector2(-100.0, 0.0))
	var state_b: Dictionary = controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [enemy_left])
	var angle_b: float = float(state_b.get("direction_angle", 0.0))
	_assert(absf(angle_a - angle_b) < 0.001, "Mid-leadership fireteams keep their sector until the delayed shift matures")
	await create_timer(1.3).timeout
	var state_c: Dictionary = controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [enemy_left])
	var angle_c: float = float(state_c.get("direction_angle", 0.0))
	_assert(absf(angle_c - angle_a) > 1.0, "Delayed directional sector shifts eventually rotate toward an uncovered threat")
	_cleanup_units([leader, wing, enemy_right, enemy_left])


func _test_overwatch_triggers_on_enemy_movement_inside_watched_sector() -> void:
	var security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var overwatch_controller = OVERWATCH_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("ovw_lead", "blue", true, Vector2(0.0, 0.0), 0.52, 0.81, 0.84, ["steady"])
	var wing = _make_unit("ovw_wing", "blue", false, Vector2(-14.0, 8.0), 0.46, 0.68, 0.3, [])
	var enemy = _make_enemy("enemy_runner", Vector2(72.0, 0.0))
	var security_state: Dictionary = security_controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [enemy])
	var friendly_by_fireteam: Dictionary = {"blue": [leader, wing]}
	overwatch_controller.update(simulation, [security_state], friendly_by_fireteam, [enemy], null, 180.0, 1)
	enemy.global_position = Vector2(88.0, 0.0)
	var shots: Array = overwatch_controller.update(simulation, [security_state], friendly_by_fireteam, [enemy], null, 180.0, 2)
	_assert(shots.size() == 1, "Enemy movement into a watched sector triggers an overwatch shot")
	_assert(simulation.effects.size() == 1, "Overwatch enqueues an authoritative damage effect")
	if simulation.effects.size() == 1:
		_assert(float(Dictionary(simulation.effects[0]).get("hit_chance", 0.0)) > 0.45, "Overwatch shots receive the configured hit chance bonus")
	_cleanup_units([leader, wing, enemy])


func _test_overwatch_stays_disabled_under_suppression_or_movement() -> void:
	var security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("block_lead", "blue", true, Vector2(0.0, 0.0), 0.42, 0.76, 0.82, ["steady"])
	var wing = _make_unit("block_wing", "blue", false, Vector2(10.0, 12.0), 0.4, 0.55, 0.3, [])
	var suppressed_state: Dictionary = security_controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {"is_suppressed": true}, {}, [])
	var moving_state: Dictionary = security_controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {"effective_style": "rush"}, {}, {}, [])
	_assert(not bool(suppressed_state.get("overwatch_ready", true)), "Suppression disables overwatch readiness")
	_assert(not bool(moving_state.get("overwatch_ready", true)), "Active movement disables overwatch readiness")
	_cleanup_units([leader, wing])


func _test_scene_exposes_security_snapshot_for_holding_fireteams() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var started: bool = controller.call("advance_to_next_phase")
	for _index in range(4):
		await process_frame
	controller.call("refresh_fireteam_security_state")
	var snapshot: Array = Array(controller.call("get_fireteam_security_snapshot"))
	_assert(started, "Scene phase start succeeds for security integration")
	_assert(snapshot.size() >= 1, "Mission tactical controller exposes active security states")
	var has_overwatch_ready: bool = false
	for state_variant in snapshot:
		var state: Dictionary = Dictionary(state_variant)
		if bool(state.get("overwatch_ready", false)):
			has_overwatch_ready = true
			break
	_assert(has_overwatch_ready, "At least one holding fireteam becomes overwatch-ready in the mission scene")
	scene.queue_free()
	await process_frame


func _build_behavior_profile(command_type: String) -> Dictionary:
	return {
		"fireteam_id": "blue",
		"metadata": {
			"origin_command_type": command_type,
			"origin": "standard_behavior",
		},
	}


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2, speed: float, accuracy: float, leadership: float, traits: Array) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_speed = speed
	unit.skill_accuracy = accuracy
	unit.skill_leadership = leadership
	unit.skill_toughness = 0.55
	unit.trait_ids = PackedStringArray(traits)
	unit.position = position_value
	unit._ready()
	root.add_child(unit)
	return unit


func _make_enemy(unit_id: String, position_value: Vector2) -> Node2D:
	var enemy = TEST_UNIT_SCRIPT.new()
	enemy.unit_id = unit_id
	enemy.display_name = unit_id
	enemy.team_id = "team_bravo"
	enemy.fireteam_id = "enemy"
	enemy.skill_speed = 0.55
	enemy.skill_accuracy = 0.45
	enemy.skill_leadership = 0.2
	enemy.skill_toughness = 0.4
	enemy.position = position_value
	enemy._ready()
	root.add_child(enemy)
	return enemy


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
