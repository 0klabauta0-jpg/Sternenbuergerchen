extends SceneTree
## Full current Main HexGround commands, preserving incremental search budgets.
const FIX = preload("res://scripts/tests/native_navigation_main_fixtures.gd")
const IO = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
var failures: Array = []
var rows: Array = []
var preparation: Array = []

func _init() -> void: call_deferred("_run")

func _run() -> void:
	if not ClassDB.class_exists("NativeNavigationKernel"):
		push_error("Main benchmark requires the native extension")
		quit(1)
		return
	for name in ["ramps", "gm01"]:
		_run_fixture(name, FIX.real_map() if name == "gm01" else FIX.synthetic())
	if rows.size() != 16: failures.append("All sixteen required real runtime command pairs must execute")
	var result := {"schema": "native_navigation_main_command.v1", "passed": failures.is_empty(), "failures": failures,
		"pair_count": rows.size(), "rows": rows, "preparation": preparation,
		"context": {"engine": Engine.get_version_info(), "os": OS.get_name(), "cpu": OS.get_processor_name(),
			"renderer": "headless", "gpu_timing": "unavailable", "samples_per_fixture": 8,
			"ordering": "GDScript first on even samples, Native first on odd samples",
			"metric": "Actual SimulationRoot._physics_process(0.25) for each tick from enqueue to authoritative HexGround arrival. Full tick CPU sums and navigation-active tick sums separated; 24-expansion slices and 96-expansion shared budget unchanged. Prewarm and fixture/loading/trace comparisons outside timed boundary.",
			"scope": "Current Main imported GM01 and explicit-ramp synthetic terrain with real UnitRegistry/SimulationRoot/HexGround and simple Node2D actors; no rendering, FPS, full mission-loader or network claims."}}
	if not IO.write_json(IO.argument("--output", "user://native_navigation_main_benchmark.json"), result): failures.append("Evidence write failed")
	print("NATIVE_NAVIGATION_MAIN_BENCHMARK pairs=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _run_fixture(name: String, fixture: Dictionary) -> void:
	var scene := Node.new()
	root.add_child(scene)
	var terrain = fixture.terrain
	scene.add_child(terrain)
	var rigs: Dictionary = {}
	for backend in ["gdscript", "native"]:
		var rig: Dictionary = FIX.create_rig(scene, fixture.map, terrain, backend == "native")
		var started: int = Time.get_ticks_usec()
		var prepared: Dictionary = rig.sim.prewarm_navigation()
		var elapsed: int = Time.get_ticks_usec() - started
		preparation.append({"fixture": name, "backend": backend, "usec": elapsed, "details": prepared})
		if not rig.configured.get("enabled", false) or prepared.get("search_mode") != "regional_hex" or bool(prepared.native_prepared) != (backend == "native"):
			failures.append(name + "/" + backend + " preparation/configuration failed")
		rigs[backend] = rig
	var pairs: Array = FIX.connected_pairs(terrain, 8)
	var revision: int = terrain.get_revision()
	if pairs.size() != 8: failures.append(name + " needs eight nonempty connected routes")
	for sample in range(pairs.size()):
		var outcomes: Dictionary = {}
		for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
			outcomes[backend] = FIX.run_move(rigs[backend], fixture.map, terrain, pairs[sample], sample)
		var gd: Dictionary = outcomes.gdscript
		var cpp: Dictionary = outcomes.native
		var same: bool = gd.trace == cpp.trace and gd.path == cpp.path and gd.position == cpp.position and gd.options == cpp.options
		var scores_equal: bool = PATH.new().score_path(gd.path, terrain, gd.options) == PATH.new().score_path(cpp.path, terrain, cpp.options)
		var native_used: bool = cpp.native_slices > 0 and cpp.gdscript_slices == 0
		var reused: bool = cpp.backend.get("snapshot_build_count", -1) == 1 and cpp.backend.get("graph_build_count", -1) == 0
		var bounded: bool = gd.budget_bounded and cpp.budget_bounded and gd.expanded_count == cpp.expanded_count
		if not same or not scores_equal or not native_used or not reused or not bounded or not gd.arrived or not cpp.arrived or cpp.path.is_empty() or terrain.get_revision() != revision:
			var message := "%s pair %d exact=%s score=%s native=%s reused=%s bounded=%s arrived=%s/%s path=%d prerequisite=%s/%s" % [name, sample, same, scores_equal, native_used, reused, bounded, gd.arrived, cpp.arrived, cpp.path.size(), gd.get("failure_reason", ""), cpp.get("failure_reason", "")]
			failures.append(message)
			push_error(message)
		rows.append({"fixture": name, "sample": sample, "from": pairs[sample][0], "to": pairs[sample][1],
			"gdscript_total_tick_usec": _sum(gd.tick_times_usec), "native_total_tick_usec": _sum(cpp.tick_times_usec),
			"gdscript_navigation_tick_usec": _sum(gd.navigation_tick_times_usec), "native_navigation_tick_usec": _sum(cpp.navigation_tick_times_usec),
			"gdscript_tick_samples_usec": gd.tick_times_usec, "native_tick_samples_usec": cpp.tick_times_usec,
			"gdscript_navigation_samples_usec": gd.navigation_tick_times_usec, "native_navigation_samples_usec": cpp.navigation_tick_times_usec,
			"ticks_to_arrival": cpp.ticks, "expanded_count": cpp.expanded_count, "native_slices": cpp.native_slices,
			"full_runtime_trace_equal": same, "scores_equal": scores_equal, "arrived": gd.arrived and cpp.arrived,
			"native_used": native_used, "preloaded_snapshot_reused": reused, "budget_bounded": bounded,
			"path_nodes": cpp.path.size(), "path_sha256": var_to_bytes(cpp.path).hex_encode().sha256_text(),
			"trace_sha256": var_to_bytes(cpp.trace).hex_encode().sha256_text(), "backend": cpp.backend})
		print("MAIN_NAV_PAIR ", name, " ", sample, " gd_nav_usec=", _sum(gd.navigation_tick_times_usec), " native_nav_usec=", _sum(cpp.navigation_tick_times_usec), " exact=", same)
	scene.free()

func _sum(values: Array) -> int:
	var total: int = 0
	for value in values: total += int(value)
	return total
