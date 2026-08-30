extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Path Recompute Under Fire Verifier ===")
	_test_stale_path_recomputed_on_contact()
	_test_contact_recompute_is_throttled()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_stale_path_recomputed_on_contact() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var registry = _make_registry()
	var unit = _make_unit("path_under_fire_a")
	unit.set_contact_state(true, "enemy_1")
	var current_position: Vector2 = registry.grid_to_world(Vector2i(0, 0))
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var stale_path: Array = [Vector2(9999.0, 9999.0)]
	var cmd: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": unit.get_unit_id(),
		"target_position": target_position,
		"requeue_until_target": true,
		"path": stale_path.duplicate(true),
	}
	var result: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, current_position, target_position, registry)
	_assert(not result.is_empty(), "Contact path rebuild returns a path")
	_assert(result != stale_path, "Stale path is replaced under contact")
	var last_waypoint: Vector2 = result[-1]
	_assert(last_waypoint.distance_to(target_position) <= 0.5, "Rebuilt path still ends at target")
	unit.free()
	simulation_root.free()
	registry.free()


func _test_contact_recompute_is_throttled() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var registry = _make_registry()
	var unit = _make_unit("path_under_fire_b")
	unit.set_contact_state(true, "enemy_2")
	var current_position: Vector2 = registry.grid_to_world(Vector2i(0, 0))
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var cmd: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": unit.get_unit_id(),
		"target_position": target_position,
		"requeue_until_target": true,
		"path": [target_position],
	}
	var first_result: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, current_position, target_position, registry)
	cmd["path"] = first_result.duplicate(true)
	var second_result: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, current_position, target_position, registry)
	_assert(first_result == second_result, "Immediate second contact evaluation reuses cached path")
	unit.free()
	simulation_root.free()
	registry.free()


func _make_registry() -> Node:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(3):
		for y in range(2):
			var grid: Vector2i = Vector2i(x, y)
			var tile = TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "tile_%d_%d" % [x, y],
				"type_id": "ground",
				"grid_position": grid,
				"world_position": registry.grid_to_world(grid),
				"walkable": true,
				"cover_value": 0,
				"surface_type": "ground",
			})
			registry.register_tile(tile)
	return registry


func _make_unit(unit_id: String) -> Node:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	root.add_child(unit)
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
