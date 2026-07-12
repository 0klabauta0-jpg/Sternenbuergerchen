class_name ContactApproachResolver
extends RefCounted

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const SEARCH_RADII: Array[float] = [256.0, 384.0, 512.0, 640.0]
const SEARCH_DIRECTION_COUNT: int = 16
const MAX_CONTACT_RANGE_WORLD: float = 1600.0

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func find_reachable_approach(start_position: Vector2, enemy_positions: Array, terrain_registry) -> Dictionary:
	if terrain_registry == null or enemy_positions.is_empty():
		return _build_result(false, start_position, 0, 0.0, "missing_context")
	var best_result: Dictionary = {}
	var candidate_count: int = 0
	for enemy_variant in enemy_positions:
		if typeof(enemy_variant) != TYPE_VECTOR2:
			continue
		var enemy_position := Vector2(enemy_variant)
		for radius in SEARCH_RADII:
			for direction_index in range(SEARCH_DIRECTION_COUNT):
				var angle: float = TAU * float(direction_index) / float(SEARCH_DIRECTION_COUNT)
				var raw_candidate := enemy_position + Vector2.from_angle(angle) * radius
				var resolution: Dictionary = Dictionary(terrain_registry.call("resolve_walkable_target", raw_candidate))
				var candidate := Vector2(resolution.get("replacement_position", raw_candidate))
				candidate_count += 1
				if not _los_system.has_line_of_sight_between_points(candidate, enemy_position, MAX_CONTACT_RANGE_WORLD, terrain_registry):
					continue
				var from_grid: Vector2i = terrain_registry.call("world_to_grid", start_position)
				var to_grid: Vector2i = terrain_registry.call("world_to_grid", candidate)
				var path: Array = _pathfinder.find_path(from_grid, to_grid, terrain_registry)
				if path.is_empty() and from_grid != to_grid:
					continue
				var score: float = float(path.size()) + start_position.distance_to(candidate) / 10000.0
				if best_result.is_empty() or score < float(best_result.get("score", INF)):
					best_result = _build_result(true, candidate, path.size(), score, "reachable_los")
					best_result["enemy_position"] = enemy_position
	if best_result.is_empty():
		return _build_result(false, start_position, candidate_count, 0.0, "no_reachable_los_candidate")
	best_result["candidate_count"] = candidate_count
	return best_result


func _build_result(found: bool, position: Vector2, path_point_count: int, score: float, reason: String) -> Dictionary:
	return {
		"found": found,
		"position": position,
		"path_point_count": path_point_count,
		"score": score,
		"reason": reason,
		"read_only": true,
		"sets_gameplay_truth": false,
	}
