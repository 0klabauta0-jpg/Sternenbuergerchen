extends SceneTree
## CPU PLAN diagnostic only. Pinned native coordinates are numeric inputs,
## never assigned to units. No actors, simulation, movement or shot is created.
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const POSITIONS: Array[Vector2] = [Vector2(-354.355, 575.676), Vector2(-248.558, 574.050), Vector2(-282.783, 529.235)]
const OBJECTIVE: Vector2 = Vector2(-72, 740)
const RADIUS: float = 96.0
const CLEARANCE: float = 64.0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map_data: RefCounted = MAP.call("load_from_file", MAP_PATH)
	if map_data == null or Array(map_data.call("get_tiles")).is_empty():
		quit(1)
		return
	var registry: Node = REGISTRY.new()
	root.add_child(registry)
	var size: Dictionary = map_data.call("get_tile_size")
	registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(size.half_width), float(size.half_height), map_data.call("get_grid_topology"))
	for tile in map_data.call("get_tiles"):
		registry.call("register_tile", tile)
	var starts: Array = []
	for position in POSITIONS:
		var grid: Vector2i = registry.call("world_to_grid", position)
		var recovery: Variant = registry.call("get_nearest_walkable_grid", position)
		var start: Dictionary = {"position": position, "raw_grid": grid, "tile_exists": registry.call("get_tile_at_grid", grid) != null, "walkable": registry.call("is_walkable", grid), "recovery_grid": recovery, "position_capture_distance": position.distance_to(OBJECTIVE)}
		starts.append(start)
		print("R4_ROUTE_PLAN_START ", JSON.stringify(start))
	for target_grid in [Vector2i(3, 17), Vector2i(2, 17), Vector2i(3, 18), Vector2i(2, 18), Vector2i(1, 18), Vector2i(1, 17), Vector2i(0, 18)]:
		var target: Vector2 = registry.call("grid_to_world", target_grid)
		for start in starts:
			for recovery_mode in [false, true]:
				var start_grid: Vector2i = start.raw_grid
				if recovery_mode and not bool(start.walkable) and typeof(start.recovery_grid) == TYPE_VECTOR2I:
					start_grid = Vector2i(start.recovery_grid)
				var previous: Vector2 = Vector2(start.position)
				var minimum: float = target.distance_to(OBJECTIVE)
				var blocked: Array = []
				for cell in registry.call("get_grid_line", start_grid, target_grid):
					var point: Vector2 = registry.call("grid_to_world", cell)
					minimum = minf(minimum, segment_distance(previous, point))
					if not bool(registry.call("is_walkable", cell)):
						blocked.append({"grid": cell, "tile_exists": registry.call("get_tile_at_grid", cell) != null, "is_start": cell == start_grid})
					previous = point
				print("R4_ROUTE_PLAN_CANDIDATE ", JSON.stringify({"position": start.position, "target_grid": target_grid, "target_world": target, "target_walkable": registry.call("is_walkable", target_grid), "native_core_nearest_recovery_mode": recovery_mode, "start_grid_used_for_plan": start_grid, "minimum_capture_distance": minimum, "required_distance": RADIUS + CLEARANCE, "blocked_cells": blocked, "clear_plan": blocked.is_empty() and minimum > RADIUS + CLEARANCE}))
	print("R4_ROUTE_PLAN_SCOPE ", JSON.stringify({"map_path": MAP_PATH, "map_sha256": FileAccess.get_sha256(MAP_PATH), "tile_count": Array(map_data.call("get_tiles")).size(), "radius": RADIUS, "clearance": CLEARANCE, "position_source": "actual_route_diagnostic/20261107T102112Z-66b88d1a", "author_map_registry_only": true, "runtime_door_overrides_included": false, "physical_proof": false, "creates_actors_or_commands": false}))
	registry.queue_free()
	await process_frame
	print("R4_COMBAT_ROUTE_PLAN_DONE")
	quit(0)

func segment_distance(a: Vector2, b: Vector2) -> float:
	var delta: Vector2 = b - a
	var fraction: float = clampf((OBJECTIVE - a).dot(delta) / delta.length_squared(), 0.0, 1.0) if delta.length_squared() > 0.0001 else 0.0
	return (a + delta * fraction).distance_to(OBJECTIVE)
