extends SceneTree

const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Buddy-Team Tactical Spacing ===")
	_test_attack_area_assignments_keep_buddy_pairs_close()
	_test_fireteam_movement_targets_use_buddy_pairs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_attack_area_assignments_keep_buddy_pairs_close() -> void:
	var units: Array = [
		_make_unit("buddy_lead", true, Vector2(-220.0, 96.0)),
		_make_unit("buddy_a", false, Vector2(-250.0, 112.0)),
		_make_unit("buddy_b", false, Vector2(-260.0, 80.0)),
		_make_unit("buddy_c", false, Vector2(-240.0, 132.0)),
	]
	var resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_attack_area", _make_area_order(), units, units[0], null)
	var assignments: Array = Array(resolution.get("assignments", []))
	var by_unit_id: Dictionary = _index_assignments(assignments)
	var lead_assignment: Dictionary = Dictionary(by_unit_id.get("buddy_lead", {}))
	var a_assignment: Dictionary = Dictionary(by_unit_id.get("buddy_a", {}))
	var b_assignment: Dictionary = Dictionary(by_unit_id.get("buddy_b", {}))
	var c_assignment: Dictionary = Dictionary(by_unit_id.get("buddy_c", {}))
	var pair_zero_distance: float = Vector2(lead_assignment.get("target_position", Vector2.ZERO)).distance_to(Vector2(a_assignment.get("target_position", Vector2.ZERO)))
	var pair_one_distance: float = Vector2(b_assignment.get("target_position", Vector2.ZERO)).distance_to(Vector2(c_assignment.get("target_position", Vector2.ZERO)))
	var cross_distance: float = Vector2(lead_assignment.get("target_position", Vector2.ZERO)).distance_to(Vector2(b_assignment.get("target_position", Vector2.ZERO)))
	_assert(assignments.size() == 4, "Attack Area assigns every fit member")
	_assert(int(lead_assignment.get("buddy_pair_index", -1)) == 0 and int(a_assignment.get("buddy_pair_index", -2)) == 0, "Lead and first wing form the first buddy pair")
	_assert(int(b_assignment.get("buddy_pair_index", -1)) == 1 and int(c_assignment.get("buddy_pair_index", -2)) == 1, "Second pair shares a buddy pair index")
	_assert(pair_zero_distance <= 30.0 and pair_one_distance <= 30.0, "Buddy pair approach targets stay close together")
	_assert(cross_distance > pair_zero_distance and cross_distance > pair_one_distance, "Buddy pairs are separated more than members inside a pair")
	_cleanup_units(units)


func _test_fireteam_movement_targets_use_buddy_pairs() -> void:
	var units: Array = [
		_make_unit("move_lead", true, Vector2.ZERO),
		_make_unit("move_a", false, Vector2(-24.0, 8.0)),
		_make_unit("move_b", false, Vector2(24.0, 10.0)),
		_make_unit("move_c", false, Vector2(12.0, 28.0)),
	]
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var records: Array = _build_member_records(units)
	var targets: Dictionary = Dictionary(controller.call("_build_formation_targets", Vector2(420.0, 0.0), records, "move_lead", 1.0, true))
	var lead_target: Vector2 = Vector2(targets.get("move_lead", Vector2.ZERO))
	var a_target: Vector2 = Vector2(targets.get("move_a", Vector2.ZERO))
	var b_target: Vector2 = Vector2(targets.get("move_b", Vector2.ZERO))
	var c_target: Vector2 = Vector2(targets.get("move_c", Vector2.ZERO))
	var travel_targets: Dictionary = Dictionary(controller.call("_build_formation_targets", Vector2(420.0, 0.0), records.slice(0, 3), "move_lead", 1.0, false))
	_assert(lead_target.distance_to(a_target) <= 32.0, "Movement keeps the FTL and first wing as a close buddy pair")
	_assert(b_target.distance_to(c_target) <= 32.0, "Movement keeps the second buddy pair close")
	_assert(lead_target.distance_to(b_target) > lead_target.distance_to(a_target), "Second buddy pair is distinct from the lead pair")
	_assert(_compute_target_spread(travel_targets) <= 35.0, "Regular move travel stays compact around the route anchor")
	_cleanup_units(units)


func _make_area_order():
	var center_position := Vector2(96.0, 96.0)
	return AREA_ORDER_SCRIPT.new({
		"area_order_id": "buddy_attack_area",
		"fireteam_id": "blue",
		"command_type": "take",
		"tile_positions": [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)],
		"tile_world_positions": [center_position + Vector2(-32.0, -24.0), center_position + Vector2(-32.0, 24.0), center_position + Vector2(32.0, -24.0), center_position + Vector2(32.0, 24.0)],
		"world_polygon": PackedVector2Array([center_position + Vector2(-64.0, -48.0), center_position + Vector2(64.0, -48.0), center_position + Vector2(64.0, 48.0), center_position + Vector2(-64.0, 48.0)]),
		"center_position": center_position,
		"created_at_order_index": 0,
		"status": "pending",
	})


func _make_unit(unit_id: String, is_lead: bool, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.is_fireteam_lead = is_lead
	unit.skill_accuracy = 0.7
	unit.skill_speed = 0.7
	unit.skill_leadership = 0.8 if is_lead else 0.3
	unit.skill_toughness = 0.65
	unit.discipline = 0.7
	unit.recognition = 0.7
	root.add_child(unit)
	unit.global_position = position_value
	return unit


func _build_member_records(units: Array) -> Array:
	var records: Array = []
	for unit in units:
		records.append({
			"unit": unit,
			"unit_id": String(unit.call("get_unit_id")),
			"team_id": String(unit.call("get_team_id")),
			"is_leader": bool(unit.get("is_fireteam_lead")),
		})
	return records


func _index_assignments(assignments: Array) -> Dictionary:
	var result: Dictionary = {}
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		result[String(assignment.get("unit_id", ""))] = assignment
	return result


func _compute_target_spread(target_positions: Dictionary) -> float:
	var positions: Array = []
	for target_variant in target_positions.values():
		if typeof(target_variant) == TYPE_VECTOR2:
			positions.append(Vector2(target_variant))
	var max_distance: float = 0.0
	for position_a in positions:
		for position_b in positions:
			max_distance = maxf(max_distance, Vector2(position_a).distance_to(Vector2(position_b)))
	return max_distance


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
