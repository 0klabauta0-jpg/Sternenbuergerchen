extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const ENEMY_WAVE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/enemy_wave_controller.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_108 Patrol Contract Verifier ===")
	_test_patrol_data_contract_roundtrip()
	_test_enemy_wave_controller_patrol_storage()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_patrol_data_contract_roundtrip() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.create_empty("patrol_test", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0)
	map_data.set_patrol_path("enemy_delta", [Vector2(100.0, 120.0), Vector2(180.0, 160.0)])
	var patrol_paths: Dictionary = map_data.get_patrol_paths()
	_assert(patrol_paths.has("enemy_delta"), "terrain map keeps patrol path dictionary")
	var path_points: Array = map_data.get_patrol_path("enemy_delta")
	_assert(path_points.size() == 2, "terrain map returns ordered patrol waypoint list")
	_assert(Vector2(path_points[0]).distance_to(Vector2(100.0, 120.0)) <= 0.01, "first waypoint stays stable")


func _test_enemy_wave_controller_patrol_storage() -> void:
	var wave_controller = ENEMY_WAVE_CONTROLLER_SCRIPT.new()
	wave_controller.set_patrol_paths({"enemy_echo": [Vector2(10.0, 20.0), Vector2(30.0, 40.0)]})
	var path_points: Array = wave_controller.get_patrol_path_for_unit("enemy_echo")
	_assert(path_points.size() == 2, "enemy wave controller stores patrol paths per unit")
	_assert(Vector2(path_points[1]).distance_to(Vector2(30.0, 40.0)) <= 0.01, "enemy wave controller returns ordered points")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
