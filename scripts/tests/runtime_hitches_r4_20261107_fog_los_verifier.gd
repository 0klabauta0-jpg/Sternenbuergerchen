extends SceneTree
## Synthetic component fixture: real Fog/LOS/Registry and explicit authored
## observer positions. No physical movement, combat or native FPS proof.
const FOG = preload("res://scripts/core/fog_of_war_system.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEAM := "team_alpha"

class CountingLOS extends "res://scripts/core/los_system.gd":
	var point_calls := 0
	var terrain_calls := 0
	func has_line_of_sight_between_points(source: Vector2, target: Vector2, max_range: float = DEFAULT_MAX_RANGE, registry = null) -> bool:
		point_calls += 1
		return super.has_line_of_sight_between_points(source, target, max_range, registry)
	func has_line_of_sight_with_terrain(source: Vector2, target: Vector2, registry, max_range: float = DEFAULT_MAX_RANGE) -> bool:
		terrain_calls += 1
		return super.has_line_of_sight_with_terrain(source, target, registry, max_range)
	func reset_counts() -> void:
		point_calls = 0
		terrain_calls = 0

class TerrainOnlyLOS extends RefCounted:
	var real = LOS.new()
	var calls := 0
	func has_line_of_sight_with_terrain(source: Vector2, target: Vector2, registry, max_range: float = 320.0) -> bool:
		calls += 1
		return real.has_line_of_sight_with_terrain(source, target, registry, max_range)

class PointsOnlyLOS extends RefCounted:
	var real = LOS.new()
	var calls := 0
	func has_line_of_sight_between_points(source: Vector2, target: Vector2, max_range: float = 320.0, registry = null) -> bool:
		calls += 1
		return real.has_line_of_sight_between_points(source, target, max_range, registry)

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		var registry = make_registry(topology)
		root.add_child(registry)
		registry.set_runtime_tile_overrides([{"grid_position": Vector2i(4, 3), "blocks_los_override": true, "object_height_override": 3}])
		var before := tile_facts(registry)
		var revision_before: int = registry.get_revision()
		var fog = FOG.new()
		var los := CountingLOS.new()
		var oracle = LOS.new()
		var source: Vector2 = registry.grid_to_world(Vector2i(2, 3))
		var cases: Array[Dictionary] = [
			{"label": "free", "grid": Vector2i(3, 3), "range": 640.0, "visible": true, "point_calls": 1, "terrain_calls": 1},
			{"label": "blocked", "grid": Vector2i(7, 3), "range": 640.0, "visible": false, "point_calls": 1, "terrain_calls": 1},
			{"label": "out_of_range", "grid": Vector2i(3, 3), "range": 1.0, "visible": false, "point_calls": 0, "terrain_calls": 0},
		]
		for spec in cases:
			var tile = registry.get_tile_at_grid(spec.grid)
			var states := {"fixture_observer": {"position": source, "sight_range_world": float(spec.range)}}
			var input_before := var_to_bytes(states)
			var expected: bool = oracle.has_line_of_sight_between_points(source, tile.world_position, float(spec.range), registry)
			check(expected == bool(spec.visible), "%s authored %s case has its independent real LOS result" % [topology, spec.label])
			los.reset_counts()
			var actual: Dictionary = fog.call("_evaluate_tile_visibility", tile, "unexplored_blackout", states, registry, los)
			check(actual == {"visible": expected, "checked_tile_count": 1, "los_blocked_count": 0 if expected else 1}, "%s %s retains the exact Fog result and counters" % [topology, spec.label])
			check(los.point_calls == int(spec.point_calls) and los.terrain_calls == int(spec.terrain_calls), "%s %s performs one complete real terrain LOS per admitted pair" % [topology, spec.label])
			check(var_to_bytes(states) == input_before, "%s %s does not mutate query inputs" % [topology, spec.label])
			var fallback := TerrainOnlyLOS.new()
			var fallback_result: Dictionary = fog.call("_evaluate_tile_visibility", tile, "unexplored_blackout", states, registry, fallback)
			check(fallback_result == actual and fallback.calls == int(spec.terrain_calls), "%s %s preserves terrain-only API fallback" % [topology, spec.label])
			var points := PointsOnlyLOS.new()
			var point_result: Dictionary = fog.call("_evaluate_tile_visibility", tile, "unexplored_blackout", states, registry, points)
			check(point_result == actual and points.calls == int(spec.point_calls), "%s %s preserves complete points-only API" % [topology, spec.label])
		var target = registry.get_tile_at_grid(Vector2i(7, 3))
		var states := {"blocked_observer": {"position": source, "sight_range_world": 640.0}, "clear_observer": {"position": registry.grid_to_world(Vector2i(7, 4)), "sight_range_world": 640.0}}
		los.reset_counts()
		var actual: Dictionary = fog.call("_evaluate_tile_visibility", target, "known_terrain", states, registry, los)
		check(actual == {"visible": true, "checked_tile_count": 2, "los_blocked_count": 1}, "%s keeps observer order and first-visible early return" % topology)
		check(los.point_calls == 2 and los.terrain_calls == 2, "%s blocked then visible observers perform exactly two complete terrain queries" % topology)
		los.reset_counts()
		check(fog.call("_evaluate_tile_visibility", target, "off", states, registry, los) == {"visible": true, "checked_tile_count": 0, "los_blocked_count": 0} and los.point_calls == 0 and los.terrain_calls == 0, "%s mode-off keeps its no-query fast path" % topology)
		check(fog.call("_evaluate_tile_visibility", null, "unexplored_blackout", states, registry, los) == {"visible": false, "checked_tile_count": 0, "los_blocked_count": 0}, "%s absent tile remains safely invisible" % topology)
		check_pair_publication(registry, topology)
		check(tile_facts(registry) == before and registry.get_revision() == revision_before, "%s all real query/commit work preserves registry and source tile data" % topology)
		registry.free()
	await process_frame
	await process_frame
	print("R4_FOG_LOS: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_FOG_LOS_PASS")
	quit(1 if failed else 0)

func check_pair_publication(registry: Node, topology: String) -> void:
	var modern = FOG.new()
	var fallback = FOG.new()
	modern.set_mode_for_team(TEAM, "unexplored_blackout")
	fallback.set_mode_for_team(TEAM, "unexplored_blackout")
	var los := CountingLOS.new()
	var terrain := TerrainOnlyLOS.new()
	var observer := Node2D.new()
	root.add_child(observer)
	observer.position = registry.call("grid_to_world", Vector2i(2, 3))
	var sources: Array = [observer]
	for phase in ["full", "dirty"]:
		if phase == "dirty":
			# Explicit synthetic new sample, never presented as physical movement.
			observer.position = registry.call("grid_to_world", Vector2i(3, 3))
		var previous: Dictionary = modern.build_team_state_snapshot(TEAM)
		los.reset_counts()
		terrain.calls = 0
		modern.request_tile_visibility_update_for_team(TEAM, sources, registry, los, 64.0, {"work_budget_tiles": 512})
		fallback.request_tile_visibility_update_for_team(TEAM, sources, registry, terrain, 64.0, {"work_budget_tiles": 512})
		var same_progress := true
		var same_candidates := true
		var atomic := true
		var completed := false
		var slices := 0
		while not completed and slices < 16:
			var a: Dictionary = modern.process_pending_tile_visibility_work(TEAM, 512)
			var b: Dictionary = fallback.process_pending_tile_visibility_work(TEAM, 512)
			completed = bool(a.get("completed", false))
			for key in ["completed", "candidate_scan_pending", "candidate_scan_processed", "processed_tile_count", "processed_in_slice", "candidate_tile_count", "full_scan"]:
				if a.get(key) != b.get(key):
					same_progress = false
			if not completed:
				atomic = atomic and modern.build_team_state_snapshot(TEAM) == previous and fallback.build_team_state_snapshot(TEAM) == previous
				var pending_a: Dictionary = Dictionary(modern.get("_pending_tile_visibility_by_team")).get(TEAM, {})
				var pending_b: Dictionary = Dictionary(fallback.get("_pending_tile_visibility_by_team")).get(TEAM, {})
				same_candidates = same_candidates and candidate_ids(pending_a) == candidate_ids(pending_b)
			slices += 1
		check(completed and same_progress and same_candidates, "%s %s candidate order/cursor/count and 512-tile scheduling match the real fallback oracle" % [topology, phase])
		check(atomic and modern.build_team_state_snapshot(TEAM) == fallback.build_team_state_snapshot(TEAM), "%s %s atomically publishes an exact complete team/delta snapshot" % [topology, phase])
		check(los.point_calls == terrain.calls and los.terrain_calls == terrain.calls, "%s %s never repeats complete terrain LOS across the actual job" % [topology, phase])
	observer.free()

func make_registry(topology: String) -> Node:
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 16.0, 8.0, topology)
	for x in range(10):
		for y in range(8):
			var grid := Vector2i(x, y)
			registry.register_tile(TILE.from_dict({"tile_id": "tile_%d_%d" % [x, y], "type_id": "ground_flat", "grid_position": grid, "world_position": registry.grid_to_world(grid), "walkable": true, "blocks_los": false, "cover_value": 0, "height_level": 0, "object_height": 0, "surface_type": "ground", "edge_type": "none"}))
	return registry

func candidate_ids(work: Dictionary) -> Array:
	var result: Array = []
	for tile in Array(work.get("candidate_tiles", [])):
		result.append(String(tile.tile_id))
	return result

func tile_facts(registry: Node) -> Array:
	var result: Array = []
	for tile in Array(registry.call("get_sorted_tiles")):
		result.append([tile.tile_id, tile.grid_position, tile.world_position, tile.walkable, tile.blocks_los, tile.height_level, tile.object_height, tile.cover_value, tile.surface_type, tile.edge_type])
	return result

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
