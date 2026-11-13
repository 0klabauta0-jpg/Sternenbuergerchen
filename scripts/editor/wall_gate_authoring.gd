extends RefCounted
## Pure editor planning; physical doors still use the mission door footprint.
const FOOTPRINT = preload("res://scripts/mission/mission_door_footprint.gd")
const FRAME := "station_set_wall_door_center"
const LEAF := "station_set_door_double_closed"

static func plan(map_data, path: Array[Vector2i], protected_cell: Callable = Callable(), marker_cell: Callable = Callable()) -> Dictionary:
	if map_data == null or path.size() < 4:
		return _bad("Mindestens vier Felder mit geradem Torabschnitt ziehen.")
	var first = map_data.get_tile_at_grid(path[0])
	if first == null: return _bad("Die Mauer muss innerhalb der Karte liegen.")
	var elevation: int = int(first.height_level)
	var seen := {}
	var previous := path[0]
	for grid: Vector2i in path:
		var tile = map_data.get_tile_at_grid(grid)
		if tile == null: return _bad("Die Mauer muss innerhalb der Karte liegen.")
		if seen.has(grid): return _bad("Die Mauer darf sich nicht selbst überlagern.")
		if not seen.is_empty() and absi(grid.x - previous.x) + absi(grid.y - previous.y) != 1:
			return _bad("Die Mauer muss eine zusammenhängende Linie bilden.")
		seen[grid] = true
		previous = grid
		if protected_cell.is_valid() and protected_cell.call(grid): return _bad("Eine Gebäudezelle liegt im Bauweg.")
		if not String(tile.object_type_id).is_empty() or (not tile.walkable and not is_wall(tile)):
			return _bad("Die Mauer würde ein vorhandenes Objekt überbauen.")
		if int(tile.height_level) != elevation or int(tile.ramp_direction) >= 0 or String(tile.edge_type) == "slope" or String(tile.surface_type) == "water":
			return _bad("Mauer und Tor benötigen eine freie, ebene Baufläche.")
	for marker: String in map_data.get_markers():
		if not marker_cell.is_valid(): return _bad("Markerzuordnung ist noch nicht verfügbar.")
		var position: Vector2 = map_data.get_marker_position(marker)
		if seen.has(marker_cell.call(position)):
			return _bad("Ein vorhandener Marker liegt im Bauweg.")
	var gate_index := -1
	var best_distance := path.size()
	for index in range(1, path.size() - 2):
		var step := path[index] - path[index - 1]
		if absi(step.x) + absi(step.y) != 1: continue
		if path[index + 1] - path[index] != step or path[index + 2] - path[index + 1] != step: continue
		var distance := absi(2 * index + 1 - (path.size() - 1))
		if distance < best_distance: best_distance = distance; gate_index = index
	if gate_index < 0: return _bad("Für das Tor einen geraden Abschnitt mit vier Feldern ziehen.")
	var frame := path[gate_index]
	var leaf := path[gate_index + 1]
	var marker_id := "wall_gate_%d_%d" % [leaf.x, leaf.y]
	if map_data.has_marker(marker_id): return _bad("An dieser Stelle ist bereits ein Tor gebunden.")
	var cells := [{"x":frame.x,"y":frame.y},{"x":leaf.x,"y":leaf.y}]
	if not FOOTPRINT.validate_cells(cells).get("ok",false): return _bad("Ungültige Torzellen.")
	return {"ok":true,"frame":frame,"leaf":leaf,"marker_id":marker_id,"door_cells":cells,
		"rotation_degrees":90.0 if frame.x != leaf.x else 0.0}

static func is_wall(tile) -> bool:
	return tile != null and String(tile.type_id) in ["modular_wall", "modular_wall_corner"] and String(tile.object_type_id).is_empty()

static func _bad(message: String) -> Dictionary:
	return {"ok":false,"message":message}
