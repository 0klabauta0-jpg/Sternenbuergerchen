extends "res://scripts/tests/runtime_hitches_r4_20261107_fog_los_verifier.gd"
## Frozen original point entry plus unchanged real terrain body as oracle.
## Synthetic fixtures, not physical movement or native FPS evidence.
class R7CountingLOS extends "res://scripts/core/los_system.gd":
	var ranges := 0
	var range_usec := 0
	func _range_distance(source: Vector2, target: Vector2, registry) -> float:
		var started := Time.get_ticks_usec()
		var result := super._range_distance(source, target, registry)
		ranges += 1
		range_usec += Time.get_ticks_usec() - started
		return result
class OriginalLOS extends R7CountingLOS:
	func has_line_of_sight_between_points(source: Vector2, target: Vector2, max_range: float = DEFAULT_MAX_RANGE, registry = null) -> bool:
		if max_range >= 0.0 and _range_distance(source, target, registry) > max_range:
			return false
		if registry == null:
			return true
		return has_line_of_sight_with_terrain(source, target, registry, max_range)
func _initialize() -> void:
	call_deferred("r7_run")
func r7_run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		var registry = make_registry(topology)
		root.add_child(registry)
		var los := R7CountingLOS.new()
		var oracle := OriginalLOS.new()
		var source: Vector2 = registry.grid_to_world(Vector2i(2, 3))
		var revision: int = registry.get_revision()
		var tiles_before := tile_facts(registry)
		var equal := true
		var results: Array = []
		for blocker in [false, true, false]:
			registry.set_runtime_tile_overrides([{"grid_position": Vector2i(4, 3), "blocks_los_override": blocker, "object_height_override": 3}])
			for tile in registry.get_sorted_tiles():
				var distance: float = registry.get_movement_distance(source, tile.world_position)
				for limit in [-1.0, 0.0, distance, maxf(distance - 0.001, 0.0), distance + 0.001, 640.0]:
					var expected: bool = oracle.has_line_of_sight_between_points(source, tile.world_position, limit, registry)
					var actual: bool = los.has_line_of_sight_between_points(source, tile.world_position, limit, registry)
					equal = equal and expected == actual
					results.append(actual)
		check(equal and results.has(true) and results.has(false), topology + " complete LOS oracle parity: ranges, exact boundary, blocked/open/reclosed, unlimited")
		check(tile_facts(registry) == tiles_before and registry.get_revision() >= revision, topology + " read queries preserve all authored tiles")
		los.ranges = 0
		var target: Vector2 = registry.grid_to_world(Vector2i(3, 3))
		los.has_line_of_sight_between_points(source, target, 640.0, registry)
		check(los.ranges == 1, topology + " admitted real terrain query calculates range exactly once")
		los.ranges = 0
		check(not los.has_line_of_sight_between_points(source, target, 0.0, registry) and los.ranges == 1, topology + " rejected range retains one calculation")
		los.ranges = 0
		los.has_line_of_sight_with_terrain(source, target, registry, 640.0)
		check(los.ranges == 1, topology + " direct terrain entry retains its own complete guard")
		los.ranges = 0
		los.has_line_of_sight_between_points(source, target, -1.0, registry)
		check(los.ranges == 0, topology + " unlimited query never evaluates range")
		var node_a := Node2D.new()
		var node_b := Node2D.new()
		root.add_child(node_a)
		root.add_child(node_b)
		node_a.position = source
		node_b.position = target
		check(los.has_line_of_sight_between_nodes(node_a, node_b, 640.0, registry) == oracle.has_line_of_sight_between_points(source, target, 640.0, registry) and los.has_line_of_sight_to_position(node_a, target, 640.0, registry) == oracle.has_line_of_sight_between_points(source, target, 640.0, registry), topology + " node/position wrappers match frozen point oracle")
		check(not los.has_line_of_sight_between_nodes(null, node_b, 640.0, registry) and not los.has_line_of_sight_to_position(null, target, 640.0, registry), topology + " null observer stays rejected")
		node_a.free()
		node_b.free()
		for implementation in [oracle, los]:
			implementation.ranges = 0
			implementation.range_usec = 0
			var start := Time.get_ticks_usec()
			for iteration in range(32):
				for tile in registry.get_sorted_tiles():
					implementation.has_line_of_sight_between_points(source, tile.world_position, 640.0, registry)
			print("R7_LOS_BENCH ", JSON.stringify({"topology": topology, "original": implementation == oracle, "queries": 2560, "range_calls": implementation.ranges, "range_usec": implementation.range_usec, "total_usec": Time.get_ticks_usec() - start}))
		r7_pair_publication(registry, topology)
		check_pair_publication(registry, topology)
		registry.free()
	var plain := R7CountingLOS.new()
	for limit in [-1.0, 0.0, 5.0, 4.999]:
		var expected: bool = limit < 0.0 or limit >= 5.0
		check(plain.has_line_of_sight_between_points(Vector2.ZERO, Vector2(3, 4), limit, null) == expected and plain.has_line_of_sight_with_terrain(Vector2.ZERO, Vector2(3, 4), null, limit) == expected, "No-terrain entry parity at %s" % limit)
	await process_frame
	print("R7_LOS_DONE ", JSON.stringify({"passed": passed, "failed": failed}))
	quit(0 if failed == 0 else 1)

func r7_pair_publication(registry: Node, topology: String) -> void:
	var modern = FOG.new()
	var original = FOG.new()
	modern.set_mode_for_team(TEAM, "unexplored_blackout")
	original.set_mode_for_team(TEAM, "unexplored_blackout")
	var los := R7CountingLOS.new()
	var oracle := OriginalLOS.new()
	var observer := Node2D.new()
	root.add_child(observer)
	observer.position = registry.grid_to_world(Vector2i(2, 3))
	for phase in ["full", "dirty"]:
		if phase == "dirty":
			observer.position = registry.grid_to_world(Vector2i(3, 3))
		var input_before := tile_facts(registry)
		var revision_before: int = registry.get_revision()
		var previous: Dictionary = modern.build_team_state_snapshot(TEAM)
		los.ranges = 0
		oracle.ranges = 0
		modern.request_tile_visibility_update_for_team(TEAM, [observer], registry, los, 64.0)
		original.request_tile_visibility_update_for_team(TEAM, [observer], registry, oracle, 64.0)
		var completed := false
		var same := true
		var atomic := true
		var slices := 0
		while not completed and slices < 100:
			var a: Dictionary = modern.process_pending_tile_visibility_work(TEAM, 7)
			var b: Dictionary = original.process_pending_tile_visibility_work(TEAM, 7)
			completed = bool(a.get("completed", false))
			for key in ["completed", "candidate_scan_pending", "candidate_scan_processed", "processed_tile_count", "processed_in_slice", "candidate_tile_count", "full_scan"]:
				same = same and a.get(key) == b.get(key)
			if not completed:
				atomic = atomic and modern.build_team_state_snapshot(TEAM) == previous and original.build_team_state_snapshot(TEAM) == previous
			slices += 1
		check(completed and same and slices > 1, "%s %s frozen original Fog job preserves exact progress and budget" % [topology, phase])
		check(atomic and modern.build_team_state_snapshot(TEAM) == original.build_team_state_snapshot(TEAM), "%s %s frozen original Fog job preserves full atomic publication/delta" % [topology, phase])
		check(los.ranges > 0 and los.ranges * 2 == oracle.ranges, "%s %s actual Fog job halves LOS-owned range evaluations" % [topology, phase])
		check(tile_facts(registry) == input_before and registry.get_revision() == revision_before, "%s %s exact Fog job leaves source terrain/revision unchanged" % [topology, phase])
	observer.free()
