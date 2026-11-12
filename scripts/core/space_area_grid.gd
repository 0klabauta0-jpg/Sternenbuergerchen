extends RefCounted
## Static local geometry. Area identity and access remain runtime-owner checks.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const ORBIT = preload("res://scripts/mission/orbit_approach_layout.gd")
const STATION = preload("res://scripts/mission/polisa_station_dock_layout.gd")
static var _station_geometry: Dictionary = {}

static func _station_contract() -> Dictionary:
	if _station_geometry.is_empty():
		var layout: Dictionary = STATION.build()
		if not layout.get("ok", false):
			_station_geometry = {"ok":false}
		else:
			_station_geometry = {"ok":true, "area_id":layout.area_id, "revision":layout.revision, "target_id":layout.target_id, "block":layout.station_block, "dock_gate":layout.dock_gate}
	return _station_geometry

static func station_dock_layout() -> Dictionary:
	return _station_contract().duplicate(true)

static func dock_targets(area_id: String) -> Array:
	if area_id != STATION.AREA_ID: return []
	var station := _station_contract()
	if not station.get("ok", false): return []
	return [{"target_id":station.target_id, "revision":station.revision}]

static func contains(cell: Vector2i, area: Dictionary) -> bool:
	var frame: Variant = area.get("coordinate_frame", "strategic")
	var id: Variant = area.get("space_area_id", "")
	if typeof(frame) != TYPE_STRING or typeof(id) != TYPE_STRING: return false
	if frame == "strategic": return id.is_empty() and GRID.contains(cell)
	if frame == "local":
		if id.strip_edges().is_empty() or not ORBIT.contains_local_cell(GRID.to_offset(cell)): return false
		if id == STATION.AREA_ID:
			var station := _station_contract()
			if not station.get("ok", false) or station.area_id != id: return false
			return not station.block.has_point(GRID.to_offset(cell))
		return true
	return false
