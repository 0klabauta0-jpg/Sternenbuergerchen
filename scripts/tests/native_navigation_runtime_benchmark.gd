extends SceneTree
## Actual SimulationRoot command ticks after explicit loading preparation.
const SIM = preload("res://scripts/core/simulation_root.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const FIX = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
var rows: Array = []
var preparation: Array = []
var failures: Array = []

class ProbeUnit:
	extends Node2D
	var unit_id: String = ""
	func get_unit_id() -> String:
		return unit_id
	func get_team_id() -> String:
		return "team_alpha"
	func get_vital_state() -> String:
		return "fit"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ClassDB.class_exists("NativeNavigationKernel"):
		push_error("Runtime benchmark requires real native extension")
		quit(1)
		return
	for fixture in ["hex24", "gm01"]:
		var terrain = FIX.real_map() if fixture == "gm01" else FIX.synthetic("hex_axial_v1", 24, 24, Vector2i(-4, -3), true)
		_run_fixture(fixture, terrain)
	var summaries: Dictionary = {}
	for fixture in ["hex24", "gm01"]:
		var gd: Array = []
		var native: Array = []
		for row in rows:
			if row.fixture == fixture:
				gd.append(row.gdscript_tick_usec)
				native.append(row.native_tick_usec)
		summaries[fixture] = {"gdscript": _stats(gd), "native": _stats(native), "small_sample_warning": true}
	var result := {"schema": "native_navigation_runtime_command.v1", "unit": "usec",
		"passed": failures.is_empty(), "failures": failures, "pair_count": rows.size(), "rows": rows,
		"preparation": preparation, "summaries": summaries,
		"context": {"engine": Engine.get_version_info(), "os": OS.get_name(), "cpu": OS.get_processor_name(),
			"renderer": "headless", "gpu_timing": "unavailable", "samples_per_fixture": 8, "seed": 0,
			"ordering": "Native first on odd samples, GDScript first on even samples",
			"timed_boundary": "Actual SimulationRoot._physics_process(0.1) after enqueue_command: includes navigation, score_path/metrics, world-path conversion, first movement update and remaining owner tick work. Both arms prewarm before commands; loading preparation separately measured including graph creation.",
			"scope": "Real production owner/command queue and UnitRegistry with simple Node2D units; synthetic hex and saved GM01 terrain. Not a rendered actor playthrough, complete level-load timing or FPS proof."}}
	if not FIX.write_json(FIX.argument("--output", "user://native_navigation_runtime_benchmark.json"), result):
		failures.append("Evidence write failed")
	print("NATIVE_NAVIGATION_RUNTIME_BENCHMARK pairs=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _run_fixture(name: String, terrain) -> void:
	var scene := Node.new()
	root.add_child(scene)
	terrain.name = "Terrain"
	scene.add_child(terrain)
	var units = UNITS.new()
	units.name = "Units"
	scene.add_child(units)
	var contexts: Dictionary = {}
	for backend in ["gdscript", "native"]:
		var sim = SIM.new()
		sim.native_navigation_enabled = backend == "native"
		sim.name = backend + "Simulation"
		sim.terrain_registry_path = NodePath("../Terrain")
		sim.unit_registry_path = NodePath("../Units")
		sim.unit_minimum_spacing_enabled = false
		sim.local_avoidance_enabled = false
		sim.bottleneck_reservation_enabled = false
		scene.add_child(sim)
		sim.set_physics_process(false)
		sim.set_process(false)
		var unit := ProbeUnit.new()
		unit.unit_id = name + "_" + backend
		scene.add_child(unit)
		units.register_unit(unit.unit_id, unit)
		var started: int = Time.get_ticks_usec()
		var prepared: Dictionary = sim.prewarm_navigation()
		var elapsed: int = Time.get_ticks_usec() - started
		if not bool(prepared.get("ready", false)) or bool(prepared.get("native_prepared", false)) != (backend == "native"):
			failures.append(name + "/" + backend + " preparation failed")
		preparation.append({"fixture": name, "backend": backend, "usec": elapsed, "details": prepared})
		contexts[backend] = {"simulation": sim, "unit": unit}
	var terrain_revision: int = terrain.get_revision()
	var pairs: Array = FIX.query_pairs(terrain, 8)
	for sample in range(pairs.size()):
		var pair: Array = pairs[sample]
		var outcomes: Dictionary = {}
		for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
			var context: Dictionary = contexts[backend]
			var sim = context.simulation
			var unit = context.unit
			unit.position = terrain.grid_to_world(pair[0])
			sim.command_queue.clear()
			var command: Dictionary = _command(unit.unit_id, pair, sample, terrain)
			var options: Dictionary = sim.call("_build_navigation_cost_options", command, terrain)
			sim.enqueue_command(command)
			var started: int = Time.get_ticks_usec()
			sim._physics_process(0.1)
			var elapsed: int = Time.get_ticks_usec() - started
			var pending: Array = sim.command_queue
			outcomes[backend] = {"usec": elapsed, "options": options, "position": unit.position,
				"world_path": Array(pending[0].get("path", [])).duplicate() if not pending.is_empty() else [],
				"backend": sim.get_navigation_backend_debug_snapshot(),
				"owner_graph": sim.get_navigation_debug_snapshot().hpa_navigation.duplicate(true)}
		# These extra reference queries happen outside timing. Capture tick debug
		# above, before a cached parity query can change the last-backend snapshot.
		for backend in ["gdscript", "native"]:
			outcomes[backend]["grid_result"] = contexts[backend].simulation.call("_find_navigation_grid_path", pair[0], pair[1], terrain, outcomes[backend].options)
		var gd: Dictionary = outcomes.gdscript
		var cpp: Dictionary = outcomes.native
		var scorer = PATH.new()
		var gd_score: Dictionary = scorer.score_path(gd.grid_result.get("path", []), terrain, gd.options)
		var cpp_score: Dictionary = scorer.score_path(cpp.grid_result.get("path", []), terrain, cpp.options)
		var parity: bool = gd.options == cpp.options and gd.position == cpp.position and gd.world_path == cpp.world_path and gd.grid_result.get("path", []) == cpp.grid_result.get("path", []) and gd.grid_result.get("status", "") == cpp.grid_result.get("status", "") and gd_score == cpp_score
		var reused: bool = cpp.backend.get("snapshot_build_count", 0) == 1 and cpp.backend.get("graph_build_count", 0) == 1 and cpp.owner_graph.get("build_count", 0) == 1
		var native_used: bool = cpp.backend.get("last_backend", "") == "native" and not cpp.backend.get("result_cache_hit", true)
		var nonempty: bool = not Array(cpp.grid_result.get("path", [])).is_empty() and not cpp.world_path.is_empty()
		var unchanged: bool = terrain.get_revision() == terrain_revision
		if not parity or not reused or not native_used or not nonempty or not unchanged:
			var message := "%s sample%d parity=%s reuse=%s native=%s nonempty=%s unchanged=%s" % [name, sample, parity, reused, native_used, nonempty, unchanged]
			failures.append(message)
			push_error(message)
		rows.append({"fixture": name, "sample": sample, "from": [pair[0].x, pair[0].y], "to": [pair[1].x, pair[1].y],
			"gdscript_tick_usec": gd.usec, "native_tick_usec": cpp.usec, "full_runtime_result_equal": parity,
			"native_used_without_result_cache": native_used, "preloaded_snapshots_reused": reused,
			"terrain_unchanged": unchanged, "nonempty_route": nonempty, "native_debug_after_tick": cpp.backend,
			"options_variant_hex": var_to_bytes(cpp.options).hex_encode(), "status": cpp.grid_result.get("status", ""),
			"grid_path_length": cpp.grid_result.get("path", []).size(), "score": cpp_score,
			"path_sha256": var_to_bytes(cpp.grid_result.get("path", [])).hex_encode().sha256_text()})
		print("RUNTIME_NAV_PAIR ", name, " ", sample, " gd_tick_usec=", gd.usec, " native_tick_usec=", cpp.usec, " parity=", parity)
	scene.free()

func _command(unit_id: String, pair: Array, sample: int, terrain) -> Dictionary:
	var origin: Vector2 = terrain.grid_to_world(Vector2i.ZERO)
	var projected: float = maxf((terrain.grid_to_world(Vector2i.RIGHT) - origin).length(), (terrain.grid_to_world(Vector2i.DOWN) - origin).length())
	return {"command_type": "move_to_position", "unit_id": unit_id, "team_id": "team_alpha",
		"command_token": "runtime_benchmark_%d" % sample, "target_position": terrain.grid_to_world(pair[1]),
		"move_speed_factor": 1.0, "requeue_until_target": true,
		"navigation_cover_aware": true, "navigation_exposure_weight": 0.72, "navigation_cover_weight": 0.56,
		"navigation_corridor_enabled": true, "navigation_corridor_start_position": terrain.grid_to_world(pair[0]),
		"navigation_corridor_end_position": terrain.grid_to_world(pair[1]), "navigation_corridor_half_width_world": 96.0,
		"navigation_corridor_weight": 0.62, "navigation_lane_enabled": true, "navigation_lane_weight": 0.88,
		"navigation_lane_offset_world": float(sample % 3 - 1) * 0.75 * projected,
		"navigation_blocker_clearance_weight": 0.392, "navigation_blocker_clearance_radius": 1}

func _stats(values: Array) -> Dictionary:
	var sorted: Array = values.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value in sorted: total += value
	var count: int = sorted.size()
	return {"count": count, "sum": total, "mean": total / count,
		"median": float(sorted[int(count / 2)]) if count % 2 == 1 else (float(sorted[int(count / 2) - 1]) + float(sorted[int(count / 2)])) / 2.0,
		"p95": sorted[maxi(0, int(ceil(count * 0.95)) - 1)], "max": sorted[-1]}
