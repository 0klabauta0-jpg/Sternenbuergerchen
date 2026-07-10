extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SOURCE_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_SOURCE_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1047 Mission Visible Frame Cross-System Timing Breakdown ===")
	_test_profiler_contracts_are_present()
	await _test_live_fixture_produces_read_only_cross_system_timing()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_profiler_contracts_are_present() -> void:
	var controller_source: String = FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	var terrain_source: String = FileAccess.get_file_as_string(TERRAIN_SOURCE_PATH)
	_assert(controller_source.contains("func set_mission_visible_frame_timing_debug_enabled(enabled: bool) -> void:"), "Controller exposes opt-in visible-frame timing toggle")
	_assert(controller_source.contains("func get_mission_visible_frame_timing_debug_snapshot() -> Dictionary:"), "Controller exposes visible-frame timing snapshot")
	_assert(terrain_source.contains("func set_runtime_frame_timing_debug_enabled(enabled: bool) -> void:"), "Terrain exposes opt-in frame timing toggle")
	_assert(terrain_source.contains("func get_runtime_frame_timing_debug_snapshot() -> Dictionary:"), "Terrain exposes frame timing snapshot")


func _test_live_fixture_produces_read_only_cross_system_timing() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	var terrain: Node = scene.get_node_or_null("Primary3DView")
	_assert(controller != null and simulation_root != null and terrain != null, "Mission fixture exposes controller, simulation and terrain")
	if controller == null or simulation_root == null or terrain == null:
		scene.queue_free()
		return
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	simulation_root.call("set_runtime_tick_budget_debug_enabled", true)
	terrain.call("set_runtime_frame_timing_debug_enabled", true)
	await _wait_frames(4)
	var controller_snapshot: Dictionary = Dictionary(controller.call("get_mission_visible_frame_timing_debug_snapshot"))
	var simulation_snapshot: Dictionary = Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot"))
	var terrain_snapshot: Dictionary = Dictionary(terrain.call("get_runtime_frame_timing_debug_snapshot"))
	_assert(bool(controller_snapshot.get("enabled", false)) and int(controller_snapshot.get("total_usec", 0)) >= 0, "Controller records named timing snapshot when enabled")
	_assert(bool(simulation_snapshot.get("enabled", false)) and simulation_snapshot.has("scopes_usec"), "SimulationRoot records its existing named tick scopes")
	_assert(bool(terrain_snapshot.get("enabled", false)) and int(terrain_snapshot.get("total_usec", 0)) >= 0, "Terrain records named timing snapshot when enabled")
	_assert(bool(controller_snapshot.get("read_only", false)) and not bool(controller_snapshot.get("creates_command", true)), "Controller timing diagnostics stay read-only")
	_assert(bool(terrain_snapshot.get("read_only", false)) and not bool(terrain_snapshot.get("sets_gameplay_truth", true)), "Terrain timing diagnostics stay read-only")
	var slowest_scope: Dictionary = _find_slowest_scope(controller_snapshot, simulation_snapshot, terrain_snapshot)
	_assert(not String(slowest_scope.get("scope", "")).is_empty(), "Cross-system snapshot identifies a named slowest scope")
	print("TIMING slowest_scope=%s duration_usec=%d controller_total_usec=%d simulation_total_usec=%d terrain_total_usec=%d" % [
		String(slowest_scope.get("scope", "")),
		int(slowest_scope.get("duration_usec", 0)),
		int(controller_snapshot.get("total_usec", 0)),
		int(simulation_snapshot.get("total_tick_usec", 0)),
		int(terrain_snapshot.get("total_usec", 0)),
	])
	controller.call("set_mission_visible_frame_timing_debug_enabled", false)
	terrain.call("set_runtime_frame_timing_debug_enabled", false)
	simulation_root.call("set_runtime_tick_budget_debug_enabled", false)
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _find_slowest_scope(controller_snapshot: Dictionary, simulation_snapshot: Dictionary, terrain_snapshot: Dictionary) -> Dictionary:
	var slowest_scope: String = ""
	var slowest_duration_usec: int = -1
	for source in [
		{"prefix": "controller", "scopes": Dictionary(controller_snapshot.get("scopes_usec", {}))},
		{"prefix": "simulation", "scopes": Dictionary(simulation_snapshot.get("scopes_usec", {}))},
		{"prefix": "terrain", "scopes": Dictionary(terrain_snapshot.get("scopes_usec", {}))},
	]:
		var prefix: String = String(source.get("prefix", ""))
		var scopes: Dictionary = Dictionary(source.get("scopes", {}))
		for scope_name_variant in scopes.keys():
			var duration_usec: int = int(scopes.get(scope_name_variant, 0))
			if duration_usec > slowest_duration_usec:
				slowest_duration_usec = duration_usec
				slowest_scope = "%s.%s" % [prefix, String(scope_name_variant)]
	return {"scope": slowest_scope, "duration_usec": slowest_duration_usec}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
