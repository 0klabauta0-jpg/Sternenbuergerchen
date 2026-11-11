extends RefCounted
## Pure deterministic entry candidates; caller must revalidate before commit.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")

static func allocate(body_id: String, requests: Array[Dictionary], occupancy: RefCounted) -> Dictionary:
	if occupancy == null or not occupancy.has_method("preview_footprint") or not occupancy.has_method("query_cells") or requests.is_empty() or requests.size() > 64:
		return {"ok":false, "reason":"invalid_request"}
	var layout: Dictionary = LAYOUT.build(body_id)
	if not layout.get("ok", false): return {"ok":false, "reason":"invalid_body"}
	var by_id := {}
	for request in requests:
		var id: Variant = request.get("craft_id")
		var flight: Variant = request.get("flight")
		var footprint: Variant = request.get("footprint_hexes")
		if typeof(id) != TYPE_STRING or String(id).strip_edges().is_empty() or by_id.has(id) or not flight is RefCounted or not flight.has_method("get_snapshot") or typeof(footprint) != TYPE_ARRAY or footprint.is_empty() or footprint.size() > 64:
			return {"ok":false, "reason":"invalid_request"}
		var seen := {}
		for offset in footprint:
			if typeof(offset) != TYPE_VECTOR2I or seen.has(offset): return {"ok":false, "reason":"invalid_request"}
			seen[offset] = true
		if not seen.has(Vector2i.ZERO) or flight.get_snapshot().get("craft_id") != id: return {"ok":false, "reason":"invalid_request"}
		by_id[id] = request
	var ids: Array = by_id.keys()
	ids.sort()
	var reserved := {}
	var body_cells := {}
	for cell in layout.body_cells: body_cells[cell] = true
	var allocations := {}
	for id in ids:
		var request: Dictionary = by_id[id]
		var snapshot: Dictionary = request.flight.get_snapshot()
		snapshot["coordinate_frame"] = "local"
		snapshot["space_area_id"] = layout.body_map_id
		var found := false
		for y in range(layout.entry_band.end.y - 1, layout.entry_band.position.y - 1, -1):
			if found: break
			for x in range(layout.entry_band.position.x, layout.entry_band.end.x):
				var anchor: Vector2i = GRID.from_offset(Vector2i(x, y))
				snapshot["position_plane"] = GRID.HEX.axial_to_plane(Vector2(anchor))
				var cells: Array[Vector2i] = occupancy.preview_footprint(snapshot, request.footprint_hexes)
				if cells.is_empty(): continue
				var invalid := false
				for cell in cells:
					if not layout.entry_band.has_point(GRID.to_offset(cell)) or body_cells.has(GRID.to_offset(cell)) or reserved.has(cell):
						invalid = true
						break
				if invalid or not occupancy.query_cells(cells, layout.body_map_id).is_empty(): continue
				for cell in cells: reserved[cell] = true
				allocations[id] = {"position_plane":snapshot.position_plane, "cells":cells}
				found = true
				break
		if not found: return {"ok":false, "reason":"entry_full"}
	return {"ok":true, "space_area_id":layout.body_map_id, "allocations":allocations}
