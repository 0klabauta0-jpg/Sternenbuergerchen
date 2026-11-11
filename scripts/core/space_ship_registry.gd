extends RefCounted
## Lookup and caller-maintained spatial index; no movement or gameplay mutation.

var _actors: Dictionary = {}
var _cells: Dictionary = {}
var _actor_cells: Dictionary = {}
var _actor_areas: Dictionary = {}

func register_actor(craft_id: String, flight: RefCounted) -> bool:
	if craft_id.strip_edges().is_empty() or flight == null or not flight.has_method("get_snapshot") or _actors.has(craft_id):
		return false
	var snapshot: Variant = flight.get_snapshot()
	if typeof(snapshot) != TYPE_DICTIONARY or snapshot.get("craft_id") != craft_id:
		return false
	_actors[craft_id] = flight
	return true

func get_actor(craft_id: String) -> RefCounted:
	return _actors.get(craft_id)

func update_actor_cells(craft_id: String, cells: Array[Vector2i]) -> bool:
	if not _actors.has(craft_id) or cells.is_empty():
		return false
	var unique: Dictionary = {}
	for cell in cells:
		unique[cell] = true
	var snapshot: Dictionary = _actors[craft_id].get_snapshot()
	var area: Variant = snapshot.get("space_area_id", "")
	if typeof(area) != TYPE_STRING: return false
	_remove_actor_cells(craft_id)
	_actor_cells[craft_id] = unique.keys()
	_actor_areas[craft_id] = area
	if not _cells.has(area): _cells[area] = {}
	for cell in unique:
		if not _cells[area].has(cell): _cells[area][cell] = {}
		_cells[area][cell][craft_id] = true
	return true

func query_cells(cells: Array[Vector2i], area_id: String = "") -> Array[String]:
	var found: Dictionary = {}
	var area_cells: Dictionary = _cells.get(area_id, {})
	for cell in cells:
		for craft_id in area_cells.get(cell, {}):
			found[craft_id] = true
	var result: Array[String] = []
	result.assign(found.keys())
	result.sort()
	return result

func unregister_actor(craft_id: String) -> bool:
	if not _actors.has(craft_id): return false
	_remove_actor_cells(craft_id)
	_actors.erase(craft_id)
	return true

func _remove_actor_cells(craft_id: String) -> void:
	var area: String = String(_actor_areas.get(craft_id, ""))
	for cell in _actor_cells.get(craft_id, []):
		_cells[area][cell].erase(craft_id)
		if _cells[area][cell].is_empty(): _cells[area].erase(cell)
	if _cells.has(area) and _cells[area].is_empty(): _cells.erase(area)
	_actor_cells.erase(craft_id)
	_actor_areas.erase(craft_id)
