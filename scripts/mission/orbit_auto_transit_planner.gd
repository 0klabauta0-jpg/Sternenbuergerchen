extends RefCounted
## Read-only route proposal. Flight, sensor and travel owners must validate and
## publish the actual command; an obstacle never causes an implicit teleport.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")

static func plan(area_id: String, start: Vector2i, direction: String, footprint: Array, blocked: Array, contacts: Array) -> Dictionary:
	if not area_id.begins_with("orbit_approach:") or direction not in ["inbound", "outbound"]: return {"ok":false, "reason":"invalid_context"}
	if not contacts.is_empty(): return {"ok":false, "reason":"contact_detected"}
	if footprint.is_empty() or footprint.size() > 128 or blocked.size() > 4096: return {"ok":false, "reason":"invalid_geometry"}
	for cell in footprint:
		if typeof(cell) != TYPE_VECTOR2I: return {"ok":false, "reason":"invalid_geometry"}
	for cell in blocked:
		if typeof(cell) != TYPE_VECTOR2I: return {"ok":false, "reason":"invalid_geometry"}
	var layout: Dictionary = LAYOUT.build(area_id.trim_prefix("orbit_approach:").uri_decode())
	var area := {"coordinate_frame":"local", "space_area_id":area_id}
	if not layout.get("ok", false) or layout.body_map_id != area_id or not AREA.contains(start, area): return {"ok":false, "reason":"invalid_context"}
	var mask := {}
	for cell: Vector2i in blocked: mask[cell] = true
	for offset: Vector2i in layout.body_cells: mask[GRID.from_offset(offset)] = true
	var start_offset: Vector2i = GRID.to_offset(start)
	var candidates: Array[Vector2i] = []
	if direction == "inbound":
		candidates.assign(layout.gate_cells)
	else:
		# Keep a one-row margin for the typical footprint; full bounds are
		# checked below for every footprint cell along the entire route.
		for x in range(layout.entry_band.position.x, layout.entry_band.end.x): candidates.append(Vector2i(x, layout.entry_band.end.y - 2))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := absi(a.x - start_offset.x); var db := absi(b.x - start_offset.x)
		return a.x < b.x if da == db else da < db)
	for offset in candidates:
		var target: Vector2i = GRID.from_offset(offset)
		var clear := true
		for center: Vector2i in HEX.line(start, target):
			for part: Vector2i in footprint:
				var cell := center + part
				if not AREA.contains(cell, area) or mask.has(cell):
					clear = false; break
			if not clear: break
		if clear: return {"ok":true, "target_hex":target, "direction":direction}
	return {"ok":false, "reason":"route_blocked"}
