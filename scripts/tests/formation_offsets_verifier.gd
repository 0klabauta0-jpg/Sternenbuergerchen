extends SceneTree

const RUNTIME_LEADER_SCRIPT: GDScript = preload("res://scripts/ftl/runtime_leader.gd")
const FTL_TASK_SCRIPT: GDScript = preload("res://scripts/ftl/ftl_task.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Formation Offsets Verifier ===")
	_test_single_unit_keeps_anchor()
	_test_fireteam_members_get_distinct_targets()
	_test_lead_gets_center_slot_even_if_added_later()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_single_unit_keeps_anchor() -> void:
	var leader = RUNTIME_LEADER_SCRIPT.new()
	var unit = _make_unit("solo", false, Vector2.ZERO)
	leader.add_unit_member(unit)
	var target: Vector2 = Vector2(200.0, 100.0)
	var resolved: Vector2 = leader.call("_derive_target_position", _make_task(target), unit, "move_to_position", "move")
	_assert(resolved.distance_to(target) <= 0.01, "Single unit keeps original target anchor")
	unit.queue_free()


func _test_fireteam_members_get_distinct_targets() -> void:
	var leader = RUNTIME_LEADER_SCRIPT.new()
	var lead_unit = _make_unit("lead", true, Vector2(0.0, 0.0))
	var wing_a = _make_unit("wing_a", false, Vector2(-20.0, 10.0))
	var wing_b = _make_unit("wing_b", false, Vector2(20.0, 10.0))
	leader.add_unit_member(lead_unit)
	leader.add_unit_member(wing_a)
	leader.add_unit_member(wing_b)
	var target: Vector2 = Vector2(220.0, 140.0)
	var lead_target: Vector2 = leader.call("_derive_target_position", _make_task(target), lead_unit, "move_to_position", "move")
	var wing_a_target: Vector2 = leader.call("_derive_target_position", _make_task(target), wing_a, "move_to_position", "move")
	var wing_b_target: Vector2 = leader.call("_derive_target_position", _make_task(target), wing_b, "move_to_position", "move")
	_assert(lead_target.distance_to(target) <= 0.01, "Lead keeps center slot")
	_assert(wing_a_target.distance_to(target) > 1.0, "First wing gets offset target")
	_assert(wing_b_target.distance_to(target) > 1.0, "Second wing gets offset target")
	_assert(wing_a_target.distance_to(wing_b_target) > 1.0, "Wing targets do not stack")
	lead_unit.queue_free()
	wing_a.queue_free()
	wing_b.queue_free()


func _test_lead_gets_center_slot_even_if_added_later() -> void:
	var leader = RUNTIME_LEADER_SCRIPT.new()
	var wing_a = _make_unit("wing_c", false, Vector2(-30.0, 0.0))
	var lead_unit = _make_unit("late_lead", true, Vector2(0.0, 0.0))
	var wing_b = _make_unit("wing_d", false, Vector2(30.0, 0.0))
	leader.add_unit_member(wing_a)
	leader.add_unit_member(lead_unit)
	leader.add_unit_member(wing_b)
	var target: Vector2 = Vector2(180.0, 120.0)
	var resolved_lead: Vector2 = leader.call("_derive_target_position", _make_task(target), lead_unit, "move_to_position", "move")
	var resolved_wing: Vector2 = leader.call("_derive_target_position", _make_task(target), wing_a, "move_to_position", "move")
	_assert(resolved_lead.distance_to(target) <= 0.01, "Lead is centered even when added after another unit")
	_assert(resolved_wing.distance_to(target) > 1.0, "Non-lead receives formation offset")
	wing_a.queue_free()
	lead_unit.queue_free()
	wing_b.queue_free()


func _make_task(target_position: Vector2):
	var task = FTL_TASK_SCRIPT.new()
	task.task_type = "move_to_area"
	task.priority = 10
	task.unit_id = "team_alpha"
	task.team_id = "team_alpha"
	task.target_position = target_position
	task.source_command_type = "move"
	return task


func _make_unit(unit_id: String, is_lead: bool, position_value: Vector2) -> Node:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.is_fireteam_lead = is_lead
	root.add_child(unit)
	unit.position = position_value
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)