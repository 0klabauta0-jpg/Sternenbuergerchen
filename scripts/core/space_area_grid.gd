extends RefCounted
## Bounds only. Area identity and access must be checked by the runtime owner.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const ORBIT = preload("res://scripts/mission/orbit_approach_layout.gd")

static func contains(cell: Vector2i, area: Dictionary) -> bool:
	var frame: Variant = area.get("coordinate_frame", "strategic")
	var id: Variant = area.get("space_area_id", "")
	if typeof(frame) != TYPE_STRING or typeof(id) != TYPE_STRING: return false
	if frame == "strategic": return id.is_empty() and GRID.contains(cell)
	if frame == "local":
		return not id.strip_edges().is_empty() and ORBIT.contains_local_cell(GRID.to_offset(cell))
	return false
