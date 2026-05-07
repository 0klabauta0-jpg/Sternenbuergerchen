class_name PerformanceDeepPassHarness
extends RefCounted

const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const RENDER_SPIKE_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_render_spike.tscn"
const NAVIGATION_BENCHMARK_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/navigation_benchmark_harness.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const DEFAULT_REPETITIONS: int = 3
const SCENE_WAIT_FRAMES: int = 10
const LIVE_WAIT_FRAMES: int = 18

const MONITOR_NAMES: PackedStringArray = [
	"TIME_FPS",
	"TIME_PROCESS",
	"TIME_PHYSICS_PROCESS",
	"MEMORY_STATIC",
	"MEMORY_STATIC_MAX",
	"OBJECT_COUNT",
	"OBJECT_RESOURCE_COUNT",
	"OBJECT_NODE_COUNT",
	"OBJECT_ORPHAN_NODE_COUNT",
	"RENDER_TOTAL_OBJECTS_IN_FRAME",
	"RENDER_TOTAL_PRIMITIVES_IN_FRAME",
	"RENDER_TOTAL_DRAW_CALLS_IN_FRAME",
	"RENDER_VIDEO_MEM_USED",
	"RENDER_TEXTURE_MEM_USED",
	"RENDER_BUFFER_MEM_USED",
	"PIPELINE_COMPILATIONS_CANVAS",
	"PIPELINE_COMPILATIONS_MESH",
	"PIPELINE_COMPILATIONS_SURFACE",
	"PIPELINE_COMPILATIONS_DRAW",
	"PIPELINE_COMPILATIONS_SPECIALIZATION",
]


func run_all(scene_parent: Node, repetitions: int = DEFAULT_REPETITIONS) -> Dictionary:
	var safe_repetitions: int = maxi(repetitions, 1)
	var result: Dictionary = {
		"schema_version": 1,
		"generated_unix_time": Time.get_unix_time_from_system(),
		"environment": _build_environment_snapshot(),
		"test_windows": _build_test_windows(),
		"monitor_names": Array(MONITOR_NAMES),
		"scenes": {},
		"navigation": {},
		"snapshot": {},
	}
	var scenes: Dictionary = {}
	scenes["homebase"] = await measure_scene(scene_parent, "homebase", HOMEBASE_SCENE_PATH, SCENE_WAIT_FRAMES, safe_repetitions)
	scenes["fob"] = await measure_scene(scene_parent, "fob", FOB_SCENE_PATH, SCENE_WAIT_FRAMES, safe_repetitions)
	scenes["live_mission_2_5d"] = await measure_scene(scene_parent, "live_mission_2_5d", LIVE_MISSION_SCENE_PATH, LIVE_WAIT_FRAMES, safe_repetitions)
	scenes["render_spike_32x32"] = await measure_scene(scene_parent, "render_spike_32x32", RENDER_SPIKE_SCENE_PATH, LIVE_WAIT_FRAMES, safe_repetitions)
	result["scenes"] = scenes
	result["navigation"] = _run_navigation_baseline(scene_parent)
	result["snapshot"] = _run_snapshot_baseline(scene_parent, safe_repetitions)
	result["summary"] = _build_summary(result)
	return result


func measure_scene(scene_parent: Node, scenario_id: String, scene_path: String, wait_frames: int, repetitions: int) -> Dictionary:
	var runs: Array = []
	for run_index in range(repetitions):
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			runs.append({
				"ok": false,
				"run_index": run_index,
				"error": "missing_scene",
				"scene_path": scene_path,
			})
			continue
		var start_usec: int = Time.get_ticks_usec()
		var scene_root := packed_scene.instantiate()
		scene_parent.add_child(scene_root)
		await _wait_frames(scene_parent, wait_frames)
		await _wait_physics_frames(scene_parent, 2)
		var elapsed_usec: int = Time.get_ticks_usec() - start_usec
		var monitor_snapshot: Dictionary = _collect_monitor_snapshot()
		var render_snapshot: Dictionary = _collect_primary_view_snapshot(scene_root)
		var run: Dictionary = {
			"ok": true,
			"run_index": run_index,
			"scene_ready_usec": elapsed_usec,
			"node_count": _count_nodes(scene_root),
			"monitor_snapshot": monitor_snapshot,
			"primary_render_snapshot": render_snapshot,
			"map_render_duration_msec": int(render_snapshot.get("map_render_duration_msec", -1)),
			"tile_count": int(render_snapshot.get("tile_count", 0)),
			"asset_model_count": int(render_snapshot.get("asset_model_count", 0)),
			"unit_model_count": int(render_snapshot.get("unit_model_count", 0)),
		}
		runs.append(run)
		scene_root.queue_free()
		await _wait_frames(scene_parent, 2)
	return {
		"scenario_id": scenario_id,
		"scene_path": scene_path,
		"repetitions": repetitions,
		"runs": runs,
		"stats": _build_scene_stats(runs),
	}


func _run_navigation_baseline(scene_parent: Node) -> Dictionary:
	var start_usec: int = Time.get_ticks_usec()
	var harness = NAVIGATION_BENCHMARK_HARNESS_SCRIPT.new()
	var result: Dictionary = Dictionary(harness.call("run_all", scene_parent))
	result["elapsed_usec"] = Time.get_ticks_usec() - start_usec
	return result


func _run_snapshot_baseline(scene_parent: Node, repetitions: int) -> Dictionary:
	var container := Node.new()
	container.name = "PerformanceSnapshotBaseline"
	scene_parent.add_child(container)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	container.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	container.add_child(simulation_root)
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = "perf_snapshot_unit"
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = Vector2(24.0, 32.0)
	container.add_child(unit)
	unit_registry.call("register_unit", "perf_snapshot_unit", unit)
	simulation_root.call("register_known_unit", "perf_snapshot_unit", unit)

	var build_times: Array = []
	var apply_times: Array = []
	var sizes: Array = []
	for index in range(maxi(repetitions, 1)):
		simulation_root.set("tick_counter", index + 1)
		var build_start_usec: int = Time.get_ticks_usec()
		var snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
		build_times.append(Time.get_ticks_usec() - build_start_usec)
		sizes.append(JSON.stringify(snapshot).length())
		snapshot["tick"] = int(snapshot.get("tick", 0)) + 100
		var apply_start_usec: int = Time.get_ticks_usec()
		simulation_root.call("apply_multiplayer_snapshot", snapshot)
		apply_times.append(Time.get_ticks_usec() - apply_start_usec)

	var result: Dictionary = {
		"repetitions": repetitions,
		"build_time_usec": _stats_from_values(build_times),
		"apply_time_usec": _stats_from_values(apply_times),
		"snapshot_size_bytes": _stats_from_values(sizes),
		"command_queue_empty": simulation_root.command_queue.is_empty(),
		"effects_queue_empty": simulation_root.effects_queue.is_empty(),
	}
	container.queue_free()
	return result


func _collect_monitor_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for monitor_name in MONITOR_NAMES:
		result[String(monitor_name)] = _get_monitor_value(String(monitor_name))
	return result


func _get_monitor_value(monitor_name: String) -> Dictionary:
	if not ClassDB.class_has_integer_constant("Performance", monitor_name):
		return {"available": false, "value": -1.0}
	var monitor_id: int = ClassDB.class_get_integer_constant("Performance", monitor_name)
	return {
		"available": true,
		"value": float(Performance.get_monitor(monitor_id)),
	}


func _collect_primary_view_snapshot(scene_root: Node) -> Dictionary:
	var primary_view := _find_node_by_name(scene_root, "Primary3DView")
	if primary_view == null or not primary_view.has_method("get_render_snapshot"):
		return {}
	return Dictionary(primary_view.call("get_render_snapshot"))


func _build_environment_snapshot() -> Dictionary:
	var version_info: Dictionary = Engine.get_version_info()
	var memory_info: Dictionary = {}
	if OS.has_method("get_memory_info"):
		memory_info = Dictionary(OS.call("get_memory_info"))
	return {
		"godot_version": String(version_info.get("string", "")),
		"godot_hash": String(version_info.get("hash", "")),
		"os_name": OS.get_name(),
		"processor_name": String(OS.call("get_processor_name")) if OS.has_method("get_processor_name") else "",
		"processor_count": int(OS.call("get_processor_count")) if OS.has_method("get_processor_count") else 0,
		"memory_info": memory_info,
	}


func _build_test_windows() -> Dictionary:
	return {
		"fixed_ui_fullhd": {"width": 1920, "height": 1080, "usage": "drop_light_fixed_ui"},
		"mission_2_5d": {"width": 1920, "height": 1080, "usage": "live_primary_view"},
		"fillrate_probe": {"width": 1280, "height": 720, "usage": "optional_manual_compare"},
	}


func _build_scene_stats(runs: Array) -> Dictionary:
	var ready_values: Array = []
	var node_values: Array = []
	var render_values: Array = []
	var draw_call_values: Array = []
	for run_variant in runs:
		var run: Dictionary = Dictionary(run_variant)
		if not bool(run.get("ok", false)):
			continue
		ready_values.append(float(run.get("scene_ready_usec", 0)))
		node_values.append(float(run.get("node_count", 0)))
		var render_duration: int = int(run.get("map_render_duration_msec", -1))
		if render_duration >= 0:
			render_values.append(float(render_duration))
		var monitor_snapshot: Dictionary = Dictionary(run.get("monitor_snapshot", {}))
		var draw_calls: Dictionary = Dictionary(monitor_snapshot.get("RENDER_TOTAL_DRAW_CALLS_IN_FRAME", {}))
		if bool(draw_calls.get("available", false)):
			draw_call_values.append(float(draw_calls.get("value", 0.0)))
	return {
		"scene_ready_usec": _stats_from_values(ready_values),
		"node_count": _stats_from_values(node_values),
		"map_render_duration_msec": _stats_from_values(render_values),
		"draw_calls_in_frame": _stats_from_values(draw_call_values),
	}


func _stats_from_values(values: Array) -> Dictionary:
	var numeric_values: Array = []
	for value_variant in values:
		numeric_values.append(float(value_variant))
	numeric_values.sort()
	if numeric_values.is_empty():
		return {
			"count": 0,
			"median": -1.0,
			"p95": -1.0,
			"p99": -1.0,
			"min": -1.0,
			"max": -1.0,
		}
	return {
		"count": numeric_values.size(),
		"median": _percentile(numeric_values, 50.0),
		"p95": _percentile(numeric_values, 95.0),
		"p99": _percentile(numeric_values, 99.0),
		"min": float(numeric_values[0]),
		"max": float(numeric_values[numeric_values.size() - 1]),
	}


func _percentile(sorted_values: Array, percentile: float) -> float:
	if sorted_values.is_empty():
		return -1.0
	var raw_index: int = int(ceili((percentile / 100.0) * float(sorted_values.size()))) - 1
	var index: int = clampi(raw_index, 0, sorted_values.size() - 1)
	return float(sorted_values[index])


func _build_summary(result: Dictionary) -> Dictionary:
	var scenes: Dictionary = Dictionary(result.get("scenes", {}))
	var complete_scene_count: int = 0
	var has_stats: bool = true
	for scenario_variant in scenes.values():
		var scenario: Dictionary = Dictionary(scenario_variant)
		if int(scenario.get("repetitions", 0)) <= 0:
			has_stats = false
			continue
		var stats: Dictionary = Dictionary(scenario.get("stats", {}))
		var ready_stats: Dictionary = Dictionary(stats.get("scene_ready_usec", {}))
		if int(ready_stats.get("count", 0)) <= 0:
			has_stats = false
			continue
		complete_scene_count += 1
	var navigation: Dictionary = Dictionary(result.get("navigation", {}))
	var snapshot: Dictionary = Dictionary(result.get("snapshot", {}))
	return {
		"scene_count": scenes.size(),
		"complete_scene_count": complete_scene_count,
		"has_homebase": scenes.has("homebase"),
		"has_fob": scenes.has("fob"),
		"has_live_mission_2_5d": scenes.has("live_mission_2_5d"),
		"has_render_spike": scenes.has("render_spike_32x32"),
		"has_median_p95_p99": has_stats,
		"has_navigation_metrics": not navigation.is_empty() and Dictionary(navigation.get("summary", {})).size() > 0,
		"has_snapshot_metrics": int(Dictionary(snapshot.get("build_time_usec", {})).get("count", 0)) > 0,
	}


func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node == null:
		return null
	if String(node.name) == node_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _count_nodes(node: Node) -> int:
	if node == null:
		return 0
	var count: int = 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


func _wait_frames(scene_parent: Node, frame_count: int) -> void:
	var tree := scene_parent.get_tree()
	for _index in range(maxi(frame_count, 0)):
		await tree.process_frame


func _wait_physics_frames(scene_parent: Node, frame_count: int) -> void:
	var tree := scene_parent.get_tree()
	for _index in range(maxi(frame_count, 0)):
		await tree.physics_frame
