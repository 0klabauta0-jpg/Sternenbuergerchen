extends RefCounted
## Pure bounded validation of authored physical door cells.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MAX_CELLS := 4
const DOOR_TYPES := ["station_set_wall_door", "station_set_wall_door_center",
	"station_set_door_double_closed", "station_set_door_double_open"]

static func validate_binding(binding: Dictionary, map_data = null) -> Dictionary:
	if not binding.has("door_cells"): return {"ok":true, "cells":[]}
	if binding.get("interaction_type") != "door": return _bad("door_cells_on_non_door")
	if map_data == null: return validate_cells(binding.door_cells)
	var marker := String(binding.get("marker_id", ""))
	if not map_data.has_method("has_marker") or not map_data.has_marker(marker):
		return _bad("door_marker_unavailable")
	return validate_cells(binding.door_cells, map_data, map_data.get_marker_position(marker))

static func validate_cells(raw: Variant, terrain = null, marker: Variant = null) -> Dictionary:
	if not raw is Array or raw.is_empty() or raw.size() > MAX_CELLS: return _bad("invalid_door_cells")
	var cells: Array[Vector2i] = []
	for record in raw:
		if not record is Dictionary or record.size() != 2 or not _integer(record.get("x")) or not _integer(record.get("y")):
			return _bad("invalid_door_cell")
		var cell := Vector2i(int(record.x), int(record.y))
		if cells.has(cell): return _bad("duplicate_door_cell")
		cells.append(cell)
	if terrain == null: return {"ok":true, "cells":cells}
	if not terrain.has_method("get_tile_at_grid") or not marker is Vector2 or not marker.is_finite():
		return _bad("door_terrain_unavailable")
	var marker_found := false
	for cell: Vector2i in cells:
		var tile = terrain.get_tile_at_grid(cell)
		if tile == null or String(tile.get("object_type_id")) not in DOOR_TYPES:
			return _bad("door_cell_not_authored_door")
		marker_found = marker_found or Vector2(tile.get("world_position")).is_equal_approx(marker)
	if not marker_found: return _bad("door_marker_outside_footprint")
	var hex: bool = terrain.has_method("get_grid_topology") and terrain.get_grid_topology() == HEX.TOPOLOGY_ID
	var reached: Array[Vector2i] = [cells[0]]
	var cursor := 0
	while cursor < reached.size():
		var origin := reached[cursor]
		cursor += 1
		for cell: Vector2i in cells:
			var adjacent: bool = HEX.are_neighbors(origin, cell) if hex else absi(cell.x-origin.x)+absi(cell.y-origin.y)==1
			if adjacent and not reached.has(cell): reached.append(cell)
	if reached.size() != cells.size(): return _bad("disconnected_door_cells")
	return {"ok":true, "cells":cells}

static func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value)) and absf(float(value)) <= 2147483647.0

static func _bad(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason, "cells":[]}
