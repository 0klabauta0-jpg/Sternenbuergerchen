class_name HexVisibilityQuery
extends RefCounted

## Pure logical-cell visibility. Terrain occlusion remains owned by the existing LOS reader.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const ARC_EPSILON := 0.000001


static func classify_candidate(observer: Dictionary, target: Dictionary,
		terrain_registry: Node, profile: Dictionary) -> Dictionary:
	var result := {"in_range":false,"in_arc":false,"terrain_clear":false,
		"terrain_checked":false,"visible":false,"reason":"invalid_terrain"}
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_grid_topology"):
		return result
	if String(terrain_registry.call("get_grid_topology")) != HEX.TOPOLOGY_ID:
		return result
	if not _valid_state(observer) or typeof(observer.get("facing_dir", null)) != TYPE_INT:
		result.reason = "invalid_observer"
		return result
	var facing: int = observer.facing_dir
	if facing < 0 or facing >= HEX.DIRECTIONS.size():
		result.reason = "invalid_observer"
		return result
	if not _valid_state(target):
		result.reason = "invalid_target"
		return result
	if terrain_registry.call("get_tile_at_grid", observer.grid) == null or terrain_registry.call("get_tile_at_grid", target.grid) == null:
		result.reason = "missing_cell"
		return result
	var raw_range: Variant = profile.get("range_hex", null)
	var raw_arc: Variant = profile.get("arc_degrees", 120.0)
	if typeof(raw_range) != TYPE_INT or int(raw_range) < -1 or (typeof(raw_arc) != TYPE_INT and typeof(raw_arc) != TYPE_FLOAT):
		result.reason = "invalid_profile"
		return result
	var arc: float = float(raw_arc)
	if not is_finite(arc) or arc < 0.0 or arc > 360.0:
		result.reason = "invalid_profile"
		return result
	var delta: Vector2i = target.grid - observer.grid
	result.in_range = int(raw_range) == -1 or HEX.distance(observer.grid, target.grid) <= int(raw_range)
	if not result.in_range:
		result.reason = "out_of_range"
		return result
	var direction: Vector2 = HEX.axial_to_plane(Vector2(HEX.DIRECTIONS[facing])).normalized()
	var to_target: Vector2 = HEX.axial_to_plane(Vector2(delta)).normalized()
	# Regel A: Wer neben (oder auf) dem Beobachter steht, ist nie ausserhalb des Sichtbogens; nur Sichtlinie
	# und Verdeckung koennen ihn noch verbergen. Abstand >= 2 bleibt Flanke (outside_arc).
	result.in_arc = HEX.distance(observer.grid, target.grid) <= 1 \
		or direction.dot(to_target) + ARC_EPSILON >= cos(deg_to_rad(arc) * 0.5)
	result.reason = "terrain_pending" if result.in_arc else "outside_arc"
	return result


static func evaluate(observer: Dictionary, target: Dictionary,
		terrain_registry: Node, profile: Dictionary) -> Dictionary:
	var result := classify_candidate(observer, target, terrain_registry, profile)
	if result.reason != "terrain_pending":
		return result
	var heights := Vector2(float(observer.stand_height_steps2) * 0.5, float(target.stand_height_steps2) * 0.5)
	var blocker: Vector2i = LOS.new().find_first_blocker_grid(observer.grid, target.grid,
		terrain_registry, Vector2(observer.grid), Vector2(target.grid), false, heights)
	result.terrain_checked = true
	result.terrain_clear = blocker == LOS.NO_BLOCKER_GRID
	result.visible = result.terrain_clear
	result.reason = "visible" if result.visible else "terrain_blocked"
	result["blocker_grid"] = blocker
	return result


static func _valid_state(state: Dictionary) -> bool:
	return typeof(state.get("grid", null)) == TYPE_VECTOR2I \
		and typeof(state.get("stand_height_steps2", null)) == TYPE_INT \
		and int(state.stand_height_steps2) >= 0
