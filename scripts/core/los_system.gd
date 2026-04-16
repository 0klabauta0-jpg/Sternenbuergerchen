class_name LineOfSightSystem
extends RefCounted

const DEFAULT_MAX_RANGE: float = 320.0


func has_line_of_sight_between_points(
	source_position: Vector2,
	target_position: Vector2,
	max_range: float = DEFAULT_MAX_RANGE
) -> bool:
	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		return false

	return true


func has_line_of_sight_to_position(source: Node2D, target_position: Vector2, max_range: float = DEFAULT_MAX_RANGE) -> bool:
	if source == null:
		return false

	return has_line_of_sight_between_points(source.global_position, target_position, max_range)


func has_line_of_sight_between_nodes(source: Node2D, target: Node2D, max_range: float = DEFAULT_MAX_RANGE) -> bool:
	if source == null or target == null:
		return false

	return has_line_of_sight_between_points(source.global_position, target.global_position, max_range)
