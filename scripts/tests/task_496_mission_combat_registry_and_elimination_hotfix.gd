extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_496_mission_combat_registry_and_elimination_hotfix.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

var _passed: int = 0
var _failed: int = 0


class FakeWaveController:
	extends Node

	var all_waves_started: bool = true

	func _init(started: bool = true) -> void:
		all_waves_started = started

	func are_all_waves_started() -> bool:
		return all_waves_started


class FakeRespawnManager:
	extends Node

	var pending_ids: Dictionary = {}

	func has_pending_respawn(unit_id: String) -> bool:
		return pending_ids.has(unit_id)


class FakeEnemyUnit:
	extends Node2D

	var unit_id: String = ""
	var vital_state: String = "fit"

	func _init(id: String = "", state: String = "fit") -> void:
		unit_id = id
		vital_state = state

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return "team_bravo"

	func get_vital_state() -> String:
		return vital_state


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_496 Mission Combat Registry and Elimination Hotfix ===")
	await _test_public_registry_contract()
	await _test_elimination_without_active_enemies_wins()
	await _test_pending_waves_block_empty_elimination()
	await _test_pending_respawn_blocks_elimination()
	await _test_down_enemy_without_pending_work_counts_as_eliminated()
	await _test_fit_enemy_still_blocks_elimination()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_public_registry_contract() -> void:
	var fixture: Dictionary = _make_fixture()
	var simulation_root: Node = fixture["simulation_root"]
	var unit_registry: Node = fixture["unit_registry"]
	var driver: Node = fixture["driver"]

	_assert(simulation_root.has_method("get_unit_registry"), "SimulationRoot exposes public get_unit_registry()")
	_assert(simulation_root.call("get_unit_registry") == unit_registry, "SimulationRoot public registry accessor returns configured UnitRegistry")
	_assert(driver.call("_get_unit_registry") == unit_registry, "CombatLoopDriver resolves UnitRegistry through public SimulationRoot API")

	var driver_source: String = _read_text("res://scripts/tests/mission_combat_loop_driver.gd")
	_assert(not driver_source.contains("call(\"_get_unit_registry\")"), "CombatLoopDriver does not call SimulationRoot._get_unit_registry()")
	_assert(not driver_source.contains("has_method(\"_get_unit_registry\")"), "CombatLoopDriver does not probe SimulationRoot._get_unit_registry()")

	_cleanup_fixture(fixture)
	await _wait_frames(2)


func _test_elimination_without_active_enemies_wins() -> void:
	var fixture: Dictionary = _make_fixture()
	var driver: Node = fixture["driver"]

	driver.set("enemy_unit_paths", [])
	_assert(bool(driver.call("_is_enemy_team_eliminated")), "No active enemies and no pending work count as eliminated")

	_cleanup_fixture(fixture)
	await _wait_frames(2)


func _test_pending_waves_block_empty_elimination() -> void:
	var fixture: Dictionary = _make_fixture()
	var root_node: Node = fixture["root"]
	var driver: Node = fixture["driver"]
	var wave_controller := FakeWaveController.new(false)
	wave_controller.name = "EnemyWaveController"
	root_node.add_child(wave_controller)
	driver.set("enemy_wave_controller_path", driver.get_path_to(wave_controller))

	_assert(not bool(driver.call("_is_enemy_team_eliminated")), "Pending enemy waves block elimination even with no active enemies")

	_cleanup_fixture(fixture)
	await _wait_frames(2)


func _test_pending_respawn_blocks_elimination() -> void:
	var fixture: Dictionary = _make_fixture()
	var root_node: Node = fixture["root"]
	var driver: Node = fixture["driver"]
	var unit_registry: Node = fixture["unit_registry"]

	var enemy := FakeEnemyUnit.new("enemy_pending_respawn", "down")
	enemy.name = "EnemyPendingRespawn"
	root_node.add_child(enemy)
	unit_registry.call("register_unit", enemy.unit_id, enemy)

	var respawn_manager := FakeRespawnManager.new()
	respawn_manager.name = "RespawnManager"
	respawn_manager.pending_ids[enemy.unit_id] = true
	root_node.add_child(respawn_manager)
	_set_enemy_paths(driver, [enemy])
	driver.set("respawn_manager_path", driver.get_path_to(respawn_manager))

	_assert(not bool(driver.call("_is_enemy_team_eliminated")), "Pending enemy respawn blocks elimination")

	_cleanup_fixture(fixture)
	await _wait_frames(2)


func _test_down_enemy_without_pending_work_counts_as_eliminated() -> void:
	var fixture: Dictionary = _make_fixture()
	var root_node: Node = fixture["root"]
	var driver: Node = fixture["driver"]
	var unit_registry: Node = fixture["unit_registry"]

	var enemy := FakeEnemyUnit.new("enemy_downed", "down")
	enemy.name = "EnemyDowned"
	root_node.add_child(enemy)
	unit_registry.call("register_unit", enemy.unit_id, enemy)
	_set_enemy_paths(driver, [enemy])

	_assert(bool(driver.call("_is_enemy_team_eliminated")), "Registered down enemy without pending work counts as eliminated")

	_cleanup_fixture(fixture)
	await _wait_frames(2)


func _test_fit_enemy_still_blocks_elimination() -> void:
	var fixture: Dictionary = _make_fixture()
	var root_node: Node = fixture["root"]
	var driver: Node = fixture["driver"]
	var unit_registry: Node = fixture["unit_registry"]

	var enemy := FakeEnemyUnit.new("enemy_fit", "fit")
	enemy.name = "EnemyFit"
	root_node.add_child(enemy)
	unit_registry.call("register_unit", enemy.unit_id, enemy)
	_set_enemy_paths(driver, [enemy])

	_assert(not bool(driver.call("_is_enemy_team_eliminated")), "Fit active enemy still blocks elimination")

	_cleanup_fixture(fixture)
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("TASK_496 - Mission Combat Registry and Elimination Hotfix"), "TASK_496 task file exists")
	_assert(status_text.contains("TASK_496 - Mission Combat Registry and Elimination Hotfix"), "Implementation status documents TASK_496")


func _make_fixture() -> Dictionary:
	var root_node := Node.new()
	root_node.name = "Task496Fixture"
	root.add_child(root_node)

	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	root_node.add_child(simulation_root)

	var unit_registry: Node = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root_node.add_child(unit_registry)
	simulation_root.set("unit_registry_path", NodePath("../UnitRegistry"))

	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.set("simulation_root_path", NodePath("../SimulationRoot"))
	driver.set("win_condition", "elimination")
	root_node.add_child(driver)

	return {
		"root": root_node,
		"simulation_root": simulation_root,
		"unit_registry": unit_registry,
		"driver": driver,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	var root_node: Node = fixture.get("root", null)
	if root_node != null:
		root_node.queue_free()


func _set_enemy_paths(driver: Node, enemies: Array) -> void:
	var enemy_paths: Array[NodePath] = []
	for enemy in enemies:
		if enemy == null or not (enemy is Node):
			continue
		enemy_paths.append(driver.get_path_to(enemy))
	driver.set("enemy_unit_paths", enemy_paths)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
