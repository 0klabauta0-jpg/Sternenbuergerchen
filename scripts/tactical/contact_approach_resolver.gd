class_name ContactApproachResolver
extends RefCounted

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const SEARCH_RADII: Array[float] = [256.0, 384.0, 512.0, 640.0]
const SEARCH_DIRECTION_COUNT: int = 16
const MAX_CONTACT_RANGE_WORLD: float = 1600.0
const MIN_FORMATION_LOS_SAMPLE_COUNT: int = 6
const MIN_FORMATION_REACHABLE_SAMPLE_COUNT: int = 9
const FORMATION_SAMPLE_OFFSETS: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(256.0, 0.0), Vector2(-256.0, 0.0),
	Vector2(0.0, 256.0), Vector2(0.0, -256.0),
	Vector2(181.0, 181.0), Vector2(-181.0, 181.0),
	Vector2(181.0, -181.0), Vector2(-181.0, -181.0),
]

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
				var sample_evidence: Dictionary = _evaluate_formation_samples(start_position, candidate, enemy_position, terrain_registry)
				if int(sample_evidence.get("reachable_sample_count", 0)) < MIN_FORMATION_REACHABLE_SAMPLE_COUNT:
					continue
				if int(sample_evidence.get("los_sample_count", 0)) < MIN_FORMATION_LOS_SAMPLE_COUNT:
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
					best_result["reachable_sample_count"] = int(sample_evidence.get("reachable_sample_count", 0))
					best_result["los_sample_count"] = int(sample_evidence.get("los_sample_count", 0))
	if best_result.is_empty():
		return _build_result(false, start_position, candidate_count, 0.0, "no_reachable_los_candidate")
	best_result["candidate_count"] = candidate_count
	return best_result


func _evaluate_formation_samples(start_position: Vector2, candidate: Vector2, enemy_position: Vector2, terrain_registry) -> Dictionary:
	var reachable_sample_count: int = 0
	var los_sample_count: int = 0
	for offset in FORMATION_SAMPLE_OFFSETS:
		var sample_resolution: Dictionary = Dictionary(terrain_registry.call("resolve_walkable_target", candidate + offset))
		var sample_position := Vector2(sample_resolution.get("replacement_position", candidate + offset))
		if not _path_reaches_sample(start_position, sample_position, terrain_registry):
			continue
		reachable_sample_count += 1
		if _los_system.has_line_of_sight_between_points(sample_position, enemy_position, MAX_CONTACT_RANGE_WORLD, terrain_registry):
			los_sample_count += 1
	return {
		"reachable_sample_count": reachable_sample_count,
		"los_sample_count": los_sample_count,
	}


func _path_reaches_sample(start_position: Vector2, sample_position: Vector2, terrain_registry) -> bool:
	var from_grid: Vector2i = terrain_registry.call("world_to_grid", start_position)
	var to_grid: Vector2i = terrain_registry.call("world_to_grid", sample_position)
	if from_grid == to_grid:
		return true
	return not _pathfinder.find_path(from_grid, to_grid, terrain_registry).is_empty()


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
