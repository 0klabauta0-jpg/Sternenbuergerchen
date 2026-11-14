extends SceneTree
## Main-specific semantic gates: ramps, blockers, incremental jobs and HexGround.
const FIX = preload("res://scripts/tests/native_navigation_main_fixtures.gd")
const IO = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")
const NATIVE = preload("res://scripts/terrain/native_navigation.gd")
var passed: int = 0
var failed: int = 0
var failures: Array = []
var expect_native: bool = true
var slice_pairs: int = 0
var runtime_pairs: Array = []

func _init() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		failures.append(label)
		push_error(label)

func _run() -> void:
	expect_native = IO.argument("--expect-native", "true") == "true"
	_check(ClassDB.class_exists("NativeNavigationKernel") == expect_native, "Actual extension availability matches requested backend")
	if failed == 0:
		_test_ramps_and_blockers()
		_test_incremental_interleaving()
		_test_revision_identity()
		_test_runtime("ramps", FIX.synthetic())
		_test_runtime("gm01", FIX.real_map())
		_test_runtime_revision()
		_test_checkpoint_prewarm()
		_check(runtime_pairs.size() == 4, "All four required real runtime command pairs executed")
	var result := {"schema": "native_navigation_main.v1", "engine": Engine.get_version_info(),
		"passed": passed, "failed": failed, "failures": failures, "expect_native": expect_native,
		"slice_pairs": slice_pairs, "runtime_pairs": runtime_pairs,
		"scope": "Current Main ramp/blocker and incremental semantics, real HexGround commands with simple actors; no rendered/FPS/network/save acceptance."}
	if not IO.write_json(IO.argument("--output", "user://native_navigation_main.json"), result): failed += 1
	print("NATIVE_NAVIGATION_MAIN ", passed, "/", failed, " slice_pairs=", slice_pairs, " runtime_pairs=", runtime_pairs.size())
	quit(0 if failed == 0 else 1)

func _test_ramps_and_blockers() -> void:
	var fixture: Dictionary = FIX.synthetic()
	var terrain = fixture.terrain
	var candidate = NATIVE.new()
	var oracle = PATH.new()
	var graph = IO.graph_for(terrain, 4)
	var source := Vector2i(1, 2)
	var goal := Vector2i(22, 9)
	var options_list: Array = IO.option_sets()
	options_list.append({"blocked_grids": {Vector2i(8, 2): true}})
	options_list.append({"blocked_grids": {Vector2i(8, 9): true}, "cover_aware_enabled": true, "cover_weight": 0.35})
	options_list.append({"blocked_grids": {Vector2i(8, 2): true, Vector2i(8, 9): true}})
	options_list.append({"blocked_grids": {Vector2i(8, 2): false}})
	options_list.append({})
	for index in range(options_list.size()):
		var options: Dictionary = options_list[index]
		var before: PackedByteArray = var_to_bytes(options)
		var expected: Array = oracle.find_path_with_options(source, goal, terrain, options)
		var actual: Array = candidate.find_path_with_options(source, goal, terrain, options)
		_check(actual == expected, "Ramps/blockers A* exact ordered path %d" % index)
		_check(oracle.score_path(actual, terrain, options) == oracle.score_path(expected, terrain, options), "Ramps/blockers A* exact score %d" % index)
		_check(candidate.get_debug_snapshot().last_backend == ("native" if expect_native else "gdscript_fallback"), "Ramps/blockers actual A* backend %d" % index)
		var expected_hpa: Dictionary = HPA.new().find_path_with_status(source, goal, terrain, graph, options)
		var actual_hpa: Dictionary = candidate.find_path_with_status(source, goal, terrain, graph, options)
		_check(actual_hpa.get("path") == expected_hpa.get("path") and actual_hpa.get("status") == expected_hpa.get("status"), "Ramps/blockers HPA path/status %d" % index)
		_check(candidate.find_path_with_status(source, goal, terrain, graph, options) == actual_hpa, "Ramps/blockers repeated HPA result %d" % index)
		_check(var_to_bytes(options) == before, "Ramps/blockers caller options retained %d" % index)
		if expect_native:
			candidate.prepare(terrain, options)
			var costs_equal: bool = true
			for from in [Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4), Vector2i(8, 2)]:
				for direction: Vector2i in FIX.HEX.DIRECTIONS:
					costs_equal = costs_equal and candidate.get("_kernel").step_cost(from, from + direction) == oracle.get_step_cost(from, from + direction, terrain, options)
			_check(costs_equal, "Exact directed ramp half-height/blocked costs %d" % index)
	var slope_cost: float = oracle.get_step_cost(Vector2i(11, 4), Vector2i(12, 4), terrain)
	var ramp = terrain.get_tile_at_grid(Vector2i(12, 4))
	_check(slope_cost == FIX.TILE.get_surface_path_cost(ramp.surface_type) + 0.5, "Fixture exercises canonical H+0.5 ramp cost")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", 0) == (1 if expect_native else 0), "Cost/blocker switches do not rebuild terrain")
	terrain.free()

func _test_incremental_interleaving() -> void:
	var fixture: Dictionary = FIX.synthetic()
	var terrain = fixture.terrain
	var candidate = NATIVE.new()
	var jobs: Array = []
	var options_list: Array = IO.option_sets()
	options_list.append({"blocked_grids": {Vector2i(8, 2): true, Vector2i(8, 9): true}})
	options_list.append({"blocked_grids": {Vector2i(8, 9): true}, "cover_aware_enabled": true, "cover_weight": 0.5})
	options_list.append({})
	for index in range(options_list.size()):
		var options: Dictionary = options_list[index]
		var source := Vector2i(1, 2) if index % 2 == 0 else Vector2i(22, 9)
		var goal := Vector2i(22, 9) if index % 2 == 0 else Vector2i(1, 2)
		if index == options_list.size() - 1: goal = source
		var reference = PATH.RegionalHexSearch.new(source, goal, terrain.get_revision(), options, terrain)
		var actual = candidate.create_regional_search(source, goal, terrain, options)
		_check((not actual is PATH.RegionalHexSearch) == expect_native, "Regional job %d uses expected actual implementation" % index)
		jobs.append({"reference": reference, "actual": actual, "done": false, "options": options, "before": var_to_bytes(options)})
	var oracle = PATH.new()
	var all_done: bool = false
	for round_index in range(1024):
		all_done = true
		for index in range(jobs.size()):
			var job: Dictionary = jobs[index]
			if job.done: continue
			all_done = false
			var allowance: int = [1, 3, 24, 7][(round_index + index) % 4]
			var expected_used: int = job.reference.advance(oracle, terrain, allowance)
			var actual_used: int = job.actual.advance(oracle, terrain, allowance)
			slice_pairs += 1
			_check(expected_used == actual_used and actual_used <= allowance, "Interleaved job %d slice %d exact expansion allowance" % [index, round_index])
			_check(job.reference.expanded_count == job.actual.expanded_count and job.reference.finished == job.actual.finished and job.reference.path == job.actual.path, "Interleaved job %d slice %d exact frontier result" % [index, round_index])
			if job.reference.finished:
				job.done = true
				_check(not job.actual.path.is_empty(), "Regional completion produces target or nearest reachable path %d" % index)
				_check(var_to_bytes(job.options) == job.before, "Regional caller options retained %d" % index)
		if all_done: break
		# Normal requests change shared kernel query options between job slices.
		if round_index % 3 == 0:
			candidate.find_path_with_options(Vector2i(0, 0), Vector2i(3, 2), terrain, {"cover_aware_enabled": true, "cover_weight": 0.9})
		if round_index % 6 == 0:
			candidate.find_path_with_options(Vector2i(0, 0), Vector2i(3, 2), terrain, {"diagnostics": {}})
	_check(all_done, "All interleaved incremental jobs finish within bounded fixture")
	_check(jobs[7].actual.path.back() != jobs[7].actual.goal, "Disconnected wall returns same nearest reachable endpoint")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", 0) == (1 if expect_native else 0), "Interleaved jobs share one terrain snapshot")
	terrain.free()

func _test_revision_identity() -> void:
	var fixture: Dictionary = FIX.synthetic()
	var other: Dictionary = FIX.synthetic()
	var terrain = fixture.terrain
	var candidate = NATIVE.new()
	var job = candidate.create_regional_search(Vector2i(1, 2), Vector2i(22, 9), terrain)
	job.advance(PATH.new(), terrain, 1)
	terrain.set_runtime_tile_overrides([{"grid_position": Vector2i(8, 2), "walkable_override": false}])
	if expect_native:
		_check(job.advance(PATH.new(), terrain, 24) == 0 and job.invalidated and job.finished and job.path.is_empty(), "A stale native job cannot cross registry revisions")
	var replacement = candidate.create_regional_search(Vector2i(1, 2), Vector2i(22, 9), terrain)
	var reference = PATH.RegionalHexSearch.new(Vector2i(1, 2), Vector2i(22, 9), terrain.get_revision(), {}, terrain)
	for index in range(100):
		var expected: int = reference.advance(PATH.new(), terrain, 24)
		var actual: int = replacement.advance(PATH.new(), terrain, 24)
		_check(expected == actual and reference.finished == replacement.finished and reference.path == replacement.path, "Fresh revised search slice %d matches" % index)
		if reference.finished: break
	_check(reference.finished and replacement.finished, "Revised route finishes")
	var old_map_job = candidate.create_regional_search(Vector2i(1, 2), Vector2i(22, 9), terrain)
	candidate.create_regional_search(Vector2i(1, 2), Vector2i(22, 9), other.terrain)
	if expect_native:
		_check(old_map_job.advance(PATH.new(), terrain, 24) == 0 and old_map_job.invalidated, "Snapshot replacement cannot silently reuse an old map job")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", 0) == (3 if expect_native else 0), "Terrain revision and map identity each invalidate exactly once")
	terrain.free()
	other.terrain.free()

func _test_runtime(name: String, fixture: Dictionary) -> void:
	var scene := Node.new()
	root.add_child(scene)
	var terrain = fixture.terrain
	scene.add_child(terrain)
	_check(not fixture.map.has_load_issue() and fixture.map.get_tactical_grid_rules() == "hex_tactical_v1", name + " uses actual current tactical map rules")
	var gd: Dictionary = FIX.create_rig(scene, fixture.map, terrain, false)
	var cpp: Dictionary = FIX.create_rig(scene, fixture.map, terrain, true)
	var prewarm: Dictionary = cpp.sim.prewarm_navigation()
	gd.sim.prewarm_navigation()
	_check(prewarm.get("search_mode") == "regional_hex" and bool(prewarm.get("native_prepared")) == expect_native, name + " load prepares the productive regional backend")
	_check(cpp.sim.get_navigation_backend_debug_snapshot().get("graph_build_count", -1) == 0, name + " avoids unused HPA preparation")
	var pairs: Array = FIX.connected_pairs(terrain, 2)
	_check(pairs.size() == 2, name + " nonempty connected fixtures")
	for index in range(pairs.size()):
		var a: Dictionary = FIX.run_move(gd, fixture.map, terrain, pairs[index], index)
		var b: Dictionary = FIX.run_move(cpp, fixture.map, terrain, pairs[index], index)
		_check(a.arrived and b.arrived and not b.path.is_empty(), name + " real queued command completes %d" % index)
		_check(a.trace == b.trace and a.path == b.path and a.position == b.position, name + " exact full runtime trace/path/final position %d" % index)
		_check(a.budget_bounded and b.budget_bounded and a.expanded_count == b.expanded_count, name + " keeps expansion and reservation budgets %d" % index)
		_check(b.native_slices > 0 and b.gdscript_slices == 0 if expect_native else b.native_slices == 0 and b.gdscript_slices > 0, name + " actual command uses expected search backend %d" % index)
		_check(b.backend.get("snapshot_build_count", -1) == (1 if expect_native else 0), name + " first/options-changed command reuses load terrain %d" % index)
		_check(PATH.new().score_path(a.path, terrain, a.options) == PATH.new().score_path(b.path, terrain, b.options), name + " exact command path scores %d" % index)
		runtime_pairs.append({"fixture": name, "sample": index, "ticks": b.ticks, "path_nodes": b.path.size(), "expanded_count": b.expanded_count,
			"native_slices": b.native_slices, "gdscript_slices": b.gdscript_slices, "backend": b.backend,
			"trace_sha256": var_to_bytes(b.trace).hex_encode().sha256_text(), "trace_equal": a.trace == b.trace})
	scene.free()

func _test_runtime_revision() -> void:
	var fixture: Dictionary = FIX.synthetic(48, 16)
	var scene := Node.new()
	root.add_child(scene)
	scene.add_child(fixture.terrain)
	var rigs: Array = [FIX.create_rig(scene, fixture.map, fixture.terrain, false), FIX.create_rig(scene, fixture.map, fixture.terrain, true)]
	var pair: Array = [Vector2i(1, 2), Vector2i(46, 13)]
	for rig in rigs:
		rig.sim.prewarm_navigation()
		rig.actor.global_position = fixture.terrain.grid_to_world(pair[0])
		var placements: Array[Dictionary] = [{"unit_id": "probe", "grid": pair[0]}]
		var admitted: Dictionary = rig.sim.admit_hex_ground_units(placements)
		_check(admitted.get("ok", false), "Revision fixture admits its actual actor")
		if not admitted.get("ok", false):
			scene.free()
			return
		rig.sim.enqueue_command(FIX.command(fixture.terrain, pair, 99))
		rig.sim._physics_process(0.25)
		var readout: Dictionary = rig.sim.get_hex_movement_readout("probe")
		_check(not readout.is_empty() and readout.get("navigation_pending", false), "Revision fixture is still searching after first slice")
		if readout.is_empty():
			scene.free()
			return
	fixture.terrain.set_runtime_tile_overrides([{"grid_position": Vector2i(16, 2), "walkable_override": false}])
	var equal: bool = true
	for tick in range(4096):
		for rig in rigs: rig.sim._physics_process(0.25)
		equal = equal and rigs[0].sim.get_hex_unit_state("probe") == rigs[1].sim.get_hex_unit_state("probe")
		equal = equal and rigs[0].actor.global_position == rigs[1].actor.global_position
		if rigs[0].sim.has_hex_destination_arrived("probe", "native_main_99"): break
	_check(equal and rigs[1].sim.has_hex_destination_arrived("probe", "native_main_99"), "Real pending jobs restart after revision and retain identical movement")
	_check(rigs[1].sim.get_navigation_backend_debug_snapshot().get("snapshot_build_count", -1) == (2 if expect_native else 0), "Real runtime rebuilds native terrain exactly once for revision")
	scene.free()

func _test_checkpoint_prewarm() -> void:
	var fixture: Dictionary = FIX.synthetic()
	var scene := Node.new()
	root.add_child(scene)
	scene.add_child(fixture.terrain)
	var rig: Dictionary = FIX.create_rig(scene, fixture.map, fixture.terrain, true)
	var sim = rig.sim
	sim.prewarm_navigation()
	var exported: Dictionary = sim.export_hex_checkpoint_state()
	_check(exported.get("ok", false), "Actual idle HexGround checkpoint exports")
	if not exported.get("ok", false):
		scene.free()
		return
	var saved: Dictionary = JSON.parse_string(JSON.stringify(exported.state))
	fixture.terrain.set_runtime_tile_overrides([{"grid_position": Vector2i(1, 2), "cover_value_override": 99}])
	# Ground must acknowledge the new terrain revision before its checkpoint
	# guard admits another transaction, exactly as on a normal gameplay tick.
	sim._physics_process(0.25)
	sim.prewarm_navigation()
	var build_count: int = int(sim.get_navigation_backend_debug_snapshot().get("snapshot_build_count", -1))
	var prepared: Dictionary = sim.prepare_hex_checkpoint_restore(saved)
	_check(prepared.get("ok", false), "Actual checkpoint prepares terrain rollback: " + str(prepared.get("reason", "")))
	if not prepared.get("ok", false):
		scene.free()
		return
	var committed: Dictionary = sim.commit_hex_checkpoint_restore(prepared.prepared, false)
	_check(committed.get("ok", false), "Actual checkpoint commits without finalizing")
	_check(sim.get_navigation_backend_debug_snapshot().get("snapshot_build_count", -1) == build_count, "Atomic unpublished checkpoint does not prewarm mid-transaction")
	var finalized: Dictionary = sim.finalize_hex_checkpoint_restore(prepared.prepared) if committed.get("ok", false) else {}
	_check(finalized.get("ok", false) and finalized.get("committed", false), "Actual checkpoint finalizes successfully")
	var after_restore: Dictionary = sim.get_navigation_backend_debug_snapshot()
	_check(after_restore.get("snapshot_build_count", -1) == build_count + (1 if expect_native else 0), "Checkpoint finalize prepares restored terrain before the first command")
	_check(fixture.terrain.export_checkpoint_overrides() == saved.terrain_overrides, "Checkpoint restored exact terrain overrides")
	var pair: Array = [Vector2i(1, 2), Vector2i(22, 9)]
	var move: Dictionary = FIX.run_move(rig, fixture.map, fixture.terrain, pair, 101)
	_check(move.arrived and move.backend.get("snapshot_build_count", -1) == after_restore.get("snapshot_build_count", -2), "First real command after checkpoint reuses finalized snapshot and arrives")
	scene.free()
