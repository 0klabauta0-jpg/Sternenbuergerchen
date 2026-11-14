extends SceneTree
## Windbruch integration: real importer, native parity and a continuous Root round trip.
## Simple actors; no enemy combat, transport boarding, renderer or campaign acceptance.
const FIX = preload("res://scripts/tests/native_navigation_main_fixtures.gd")
const IO = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const NAV = preload("res://scripts/terrain/native_navigation.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
const MAP_PATH := "res://maps/windbruch_outpost.json"
const TICK_LIMIT := 4096
var passed := 0
var failed := 0
var failures: Array = []
var evidence: Array = []
var ramp_edges := 0

func _init() -> void: call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		failures.append(label)
		push_error(label)

func _run() -> void:
	_check(ClassDB.class_exists("NativeNavigationKernel") and ClassDB.class_exists("NativeTerrainBuilder"), "Actual Main navigation and terrain extension classes are loaded")
	if failed == 0: _test_windbruch()
	var result := {"schema": "grafikpass_r123_navigation.v1", "passed": passed, "failed": failed,
		"failures": failures, "engine": Engine.get_version_info(), "map": MAP_PATH,
		"ramp_edges": ramp_edges, "routes": evidence,
		"scope": "Actual Windbruch importer/registry and native/GDScript exact paths, costs and continuous SimulationRoot landing-chip-return commands with simple actors. No combat, boarding, rendering or full campaign acceptance."}
	if not IO.write_json(IO.argument("--output", "user://grafikpass_r123_navigation.json"), result): failed += 1
	print("GRAFIKPASS_R123_NAVIGATION ", passed, "/", failed, " routes=", evidence.size(), " ramp_edges=", ramp_edges)
	quit(0 if failed == 0 else 1)

func _tile_bytes(map) -> PackedByteArray:
	var records: Array = []
	for tile in map.get_tiles(): records.append([tile.to_dict(), tile.explicit_hex_ramps])
	return var_to_bytes(records)

func _test_windbruch() -> void:
	var source_hash := FileAccess.get_sha256(MAP_PATH)
	var map = FIX.MAP.load_from_file(MAP_PATH)
	_check(not map.has_load_issue() and map.get_tiles().size() == 131072, "Actual Windbruch source imports all 131072 authored cells")
	_check(map.get_grid_topology() == "hex_axial_v1" and map.get_tactical_grid_rules() == "hex_tactical_v1" and map.get_terrain_height_rules() == "explicit_hex_ramps_v1", "Importer retains productive hex and explicit height rules")
	for marker: String in ["spawn_alpha", "outpost_chip", "ship_return"]:
		_check(map.has_marker(marker), "Authored mission marker exists: " + marker)
	if failed > 0: return
	var fixture: Dictionary = FIX.from_map(map)
	var terrain = fixture.terrain
	var scene := Node.new()
	root.add_child(scene)
	scene.add_child(terrain)
	var revision: int = terrain.get_revision()
	var source_tiles := _tile_bytes(map)
	var landing: Vector2i = terrain.world_to_grid(map.get_marker_position("spawn_alpha"))
	var chip: Vector2i = terrain.world_to_grid(map.get_marker_position("outpost_chip"))
	var returning: Vector2i = terrain.world_to_grid(map.get_marker_position("ship_return"))
	_check(terrain.is_walkable(landing) and terrain.is_walkable(chip) and terrain.is_walkable(returning), "Landing, chip and return markers resolve to actual walkable registry cells")
	_check(terrain.get_stand_height_at(landing) == 0.0 and terrain.get_stand_height_at(chip) == 4.0 and landing == returning, "Authored round trip climbs from height zero to four and returns to its landing cell")
	var native = NAV.new()
	var oracle = PATH.new()
	_check(native.prepare(terrain), "Native snapshot accepts the real imported Windbruch registry")
	_check(native.get_debug_snapshot().get("terrain_builder") == "native", "Real Windbruch edges are built by NativeTerrainBuilder")
	if failed > 0:
		scene.free()
		return
	var ramp_count := 0
	var all_explicit := true
	var half_heights := true
	var ramp_costs := true
	for tile in map.get_tiles():
		all_explicit = all_explicit and tile.explicit_hex_ramps
		if not FIX.TILE.is_explicit_ramp(tile): continue
		ramp_count += 1
		half_heights = half_heights and FIX.TILE.stand_height(tile) == float(tile.height_level) + 0.5
		for direction: Vector2i in FIX.HEX.DIRECTIONS:
			var target: Vector2i = tile.grid_position + direction
			if not oracle.can_traverse_step(tile.grid_position, target, terrain): continue
			ramp_edges += 1
			ramp_costs = ramp_costs and native.get("_kernel").step_cost(tile.grid_position, target) == oracle.get_step_cost(tile.grid_position, target, terrain)
	_check(all_explicit and ramp_count == 240 and half_heights, "Root metadata activates all tiles and preserves all 240 half-height ramps")
	_check(ramp_edges > 0 and ramp_costs, "Every legal directed authored ramp edge has the exact native/GDScript cost")
	var pairs: Array = [[landing, chip], [chip, returning]]
	var gd: Dictionary = FIX.create_rig(scene, map, terrain, false)
	var cpp: Dictionary = FIX.create_rig(scene, map, terrain, true)
	var native_prepared: Dictionary = cpp.sim.prewarm_navigation()
	gd.sim.prewarm_navigation()
	_check(native_prepared.get("search_mode") == "regional_hex" and native_prepared.get("native_prepared", false), "Productive owner prewarms the real incremental native regional backend")
	for rig: Dictionary in [gd, cpp]:
		_check(rig.configured.get("ok", false) and rig.configured.get("enabled", false), "Real SimulationRoot configures Windbruch HexGround")
		rig.actor.global_position = terrain.grid_to_world(landing)
		var placements: Array[Dictionary] = [{"unit_id": "probe", "grid": landing}]
		var admitted: Dictionary = rig.sim.admit_hex_ground_units(placements)
		_check(admitted.get("ok", false), "Existing admission accepts the actor at the authored landing")
	if failed > 0:
		scene.free()
		return
	for index in range(pairs.size()):
		var pair: Array = pairs[index]
		var expected: Array = oracle.find_path_with_options(pair[0], pair[1], terrain, {})
		var actual: Array = native.find_path_with_options(pair[0], pair[1], terrain, {})
		_check(not actual.is_empty() and actual.back() == pair[1], "Direct route reaches exact mission target %d" % index)
		_check(actual == expected and oracle.score_path(actual, terrain) == oracle.score_path(expected, terrain), "Direct ordered route and score exactly match GDScript %d" % index)
		_check(native.get_debug_snapshot().get("last_backend") == "native", "Direct route actually uses native search %d" % index)
		var a: Dictionary = _continue_move(gd, terrain, pair, index)
		var b: Dictionary = _continue_move(cpp, terrain, pair, index)
		_check(a.arrived and b.arrived and not b.path.is_empty(), "Continuous queued Root command reaches target %d" % index)
		_check(a.trace == b.trace and a.path == b.path and a.position == b.position, "Exact full Root trace, route and final position %d" % index)
		_check(a.bounded and b.bounded and a.expansions == b.expansions, "Per-tick navigation and reservation budgets remain bounded %d" % index)
		_check(b.native_slices > 0 and b.gdscript_slices == 0 and a.native_slices == 0 and a.gdscript_slices > 0, "Actual Root commands prove both requested backends %d" % index)
		_check(oracle.score_path(a.path, terrain, a.options) == oracle.score_path(b.path, terrain, b.options), "Real command options retain exact path costs %d" % index)
		var crossed_ramps := 0
		for cell: Vector2i in b.path:
			if FIX.TILE.is_explicit_ramp(terrain.get_tile_at_grid(cell)): crossed_ramps += 1
		_check(crossed_ramps > 0, "Real mission route crosses authored ramps %d" % index)
		_check(b.stand_height == terrain.get_stand_height_at(pair[1]), "Root final stand height matches source terrain %d" % index)
		evidence.append({"leg": "landing_to_chip" if index == 0 else "chip_to_return", "source": pair[0], "target": pair[1],
			"arrived": b.arrived, "ticks": b.ticks, "path_nodes": b.path.size(), "ramp_nodes": crossed_ramps,
			"expanded_count": b.expansions, "native_slices": b.native_slices, "gdscript_slices": b.gdscript_slices,
			"trace_equal": a.trace == b.trace, "trace_sha256": var_to_bytes(b.trace).hex_encode().sha256_text(), "backend": b.backend})
		if not a.arrived or not b.arrived: break
	_check(evidence.size() == 2, "Both continuous mission legs execute without re-admission or teleport")
	_check(terrain.get_revision() == revision and _tile_bytes(map) == source_tiles and FileAccess.get_sha256(MAP_PATH) == source_hash, "Queries and Root movement preserve source map bytes, logical tile facts and terrain revision")
	scene.free()

func _continue_move(rig: Dictionary, terrain, pair: Array, sample: int) -> Dictionary:
	# The caller admits once; the return command starts at the real prior arrival.
	var sim = rig.sim
	var cmd: Dictionary = FIX.command(terrain, pair, sample)
	sim.enqueue_command(cmd)
	var trace: Array = []
	var path: Array = []
	var expansions := 0
	var native_slices := 0
	var gdscript_slices := 0
	var bounded := true
	for tick in range(TICK_LIMIT):
		sim._physics_process(0.25)
		var audit: Dictionary = sim.get_hex_movement_audit_snapshot()
		var state: Dictionary = sim.get_hex_unit_state("probe")
		var readout: Dictionary = sim.get_hex_movement_readout("probe")
		if state.is_empty() or readout.is_empty(): break
		expansions += int(audit.get("navigation_expansions", 0))
		native_slices += int(audit.get("native_navigation_slices", 0))
		gdscript_slices += int(audit.get("gdscript_navigation_slices", 0))
		bounded = bounded and int(audit.get("navigation_slices", 0)) <= 4 and int(audit.get("navigation_expansions", 0)) <= 96
		bounded = bounded and int(audit.get("reservation_requests", 0)) <= 16 and int(audit.get("accepted_steps", 0)) <= 48
		var orders: Dictionary = sim.get("_hex_movement_runtime").get("_orders")
		if path.is_empty() and orders.has("probe") and not orders.probe.path.is_empty(): path = orders.probe.path.duplicate()
		trace.append([state.get("grid"), state.get("movement_state", {}).get("moving", false), rig.actor.global_position,
			rig.actor.get_meta("hex_ground_stand_height_logical", -1.0), readout.get("status"), readout.get("reason"),
			readout.get("navigation_jobs"), readout.get("navigation_pending"), audit.get("navigation_expansions", 0),
			audit.get("navigation_slices", 0), audit.get("reservation_requests", 0), audit.get("accepted_steps", 0)])
		if sim.has_hex_destination_arrived("probe", cmd.command_token): break
	return {"arrived": sim.has_hex_destination_arrived("probe", cmd.command_token), "path": path, "trace": trace,
		"position": rig.actor.global_position, "ticks": trace.size(), "expansions": expansions,
		"native_slices": native_slices, "gdscript_slices": gdscript_slices, "bounded": bounded,
		"stand_height": rig.actor.get_meta("hex_ground_stand_height_logical", -1.0),
		"options": sim._build_navigation_cost_options(cmd, terrain), "backend": sim.get_navigation_backend_debug_snapshot()}
