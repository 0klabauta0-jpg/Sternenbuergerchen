extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const COMBAT_SOURCE_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const SIMULATION_SOURCE_PATH: String = "res://scripts/core/simulation_root.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1048 Simulation Tick Signal Fanout Audit ===")
	_test_direct_fanout_contract()
	await _test_live_combat_listener_timing_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_direct_fanout_contract() -> void:
	var combat_source: String = FileAccess.get_file_as_string(COMBAT_SOURCE_PATH)
	var simulation_source: String = FileAccess.get_file_as_string(SIMULATION_SOURCE_PATH)
	_assert(simulation_source.contains("signal tick_processed(tick: int)"), "SimulationRoot declares the authoritative tick signal")
	_assert(combat_source.contains("simulation_root.tick_processed.connect(_on_tick_processed)"), "Combat loop is a direct tick listener")
	_assert(combat_source.contains("func get_combat_tick_budget_debug_snapshot() -> Dictionary:"), "Combat listener exposes existing opt-in timing snapshot")


func _test_live_combat_listener_timing_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(simulation_root != null and combat_driver != null, "Mission fixture exposes simulation and direct combat listener")
	if simulation_root == null or combat_driver == null:
		scene.queue_free()
		return
	combat_driver.call("set_combat_tick_budget_debug_enabled", true)
	await _wait_frames(4)
	var snapshot: Dictionary = Dictionary(combat_driver.call("get_combat_tick_budget_debug_snapshot"))
	_assert(bool(snapshot.get("enabled", false)) and snapshot.has("scopes_usec"), "Combat listener records named tick scopes when explicitly enabled")
	_assert(bool(snapshot.get("authority_side", false)), "Combat timing runs on the authoritative side")
	_assert(snapshot.has("read_only") and bool(snapshot.get("read_only", false)) and not bool(snapshot.get("creates_command", true)) and not bool(snapshot.get("sets_multiplayer_truth", true)), "Combat timing snapshot remains read-only diagnostics")
	print("FANOUT combat_total_usec=%d scopes=%s" % [int(snapshot.get("total_tick_usec", 0)), str(Dictionary(snapshot.get("scopes_usec", {})))])
	combat_driver.call("set_combat_tick_budget_debug_enabled", false)
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
