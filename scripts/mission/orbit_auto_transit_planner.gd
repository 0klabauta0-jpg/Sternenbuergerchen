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
	var layout: Dictionary = LAYOUT.build_cached(area_id.trim_prefix("orbit_approach:").uri_decode())
	var area := {"coordinate_frame":"local", "space_area_id":area_id}
	if not layout.get("ok", false) or layout.body_map_id != area_id or not AREA.contains(start, area): return {"ok":false, "reason":"invalid_context"}
	var prepared := _prepared(area_id, layout)
	var body_mask: Dictionary = prepared.body_mask
	var blocked_mask := {}
	for cell: Vector2i in blocked: blocked_mask[cell] = true
	var start_offset: Vector2i = GRID.to_offset(start)
	var columns: Dictionary = prepared.inbound if direction == "inbound" else prepared.outbound
	# Reihenfolge wie die fruehere Sortierung (Abstand der Spalte zum Start, gleicher Abstand: linke Spalte zuerst, in der Spalte flachstes Feld
	# zuerst), aber ohne Sortieren je Aufruf: Spalten werden von der Startspalte nach aussen abgelaufen.
	var reach := int(prepared.max_column)
	for distance in range(0, reach + 1):
		for x in ([start_offset.x - distance, start_offset.x + distance] if distance > 0 else [start_offset.x]):
			if not columns.has(x): continue
			for y: int in columns[x]:
				var target: Vector2i = GRID.from_offset(Vector2i(x, y))
				var clear := true
				for center: Vector2i in HEX.line(start, target):
					for part: Vector2i in footprint:
						var cell := center + part
						if not AREA.contains(cell, area) or body_mask.has(cell) or blocked_mask.has(cell):
							clear = false; break
					if not clear: break
				if clear: return {"ok":true, "target_hex":target, "direction":direction}
	return {"ok":false, "reason":"route_blocked"}

## Je Koerper einmal: Planetenmaske sowie Kandidatenspalten (Spalte -> aufsteigende Zeilen) fuer Anflug und Abflug.
static var _prepared_cache: Dictionary = {}

static func _prepared(area_id: String, layout: Dictionary) -> Dictionary:
	if _prepared_cache.has(area_id): return _prepared_cache[area_id]
	var body_mask := {}
	for offset: Vector2i in layout.body_cells: body_mask[GRID.from_offset(offset)] = true
	var inbound := {}
	for offset: Vector2i in layout.gate_cells:
		if not inbound.has(offset.x): inbound[offset.x] = []
		inbound[offset.x].append(offset.y)
	for x in inbound: inbound[x].sort()
	var outbound := {}
	# Keep a one-row margin for the typical footprint; full bounds are
	# checked below for every footprint cell along the entire route.
	for x in range(layout.entry_band.position.x, layout.entry_band.end.x): outbound[x] = [layout.entry_band.end.y - 2]
	# Die Startspalte liegt auf der Karte (AREA.contains), also reichen MAP_SIZE.x Schritte nach aussen.
	var result := {"body_mask": body_mask, "inbound": inbound, "outbound": outbound, "max_column": LAYOUT.MAP_SIZE.x}
	_prepared_cache[area_id] = result
	return result
