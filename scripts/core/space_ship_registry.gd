extends RefCounted
## Lookup and caller-maintained spatial index; no movement or gameplay mutation.

var _actors: Dictionary = {}
var _cells: Dictionary = {}
var _actor_cells: Dictionary = {}

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
	for cell in _actor_cells.get(craft_id, []):
		_cells[cell].erase(craft_id)
		if _cells[cell].is_empty(): _cells.erase(cell)
	_actor_cells[craft_id] = unique.keys()
	for cell in unique:
		if not _cells.has(cell): _cells[cell] = {}
		_cells[cell][craft_id] = true
	return true

func query_cells(cells: Array[Vector2i]) -> Array[String]:
	var found: Dictionary = {}
	for cell in cells:
		for craft_id in _cells.get(cell, {}):
			found[craft_id] = true
	var result: Array[String] = []
	result.assign(found.keys())
	result.sort()
	return result

func unregister_actor(craft_id: String) -> bool:
	if not _actors.has(craft_id): return false
	for cell in _actor_cells.get(craft_id, []):
		_cells[cell].erase(craft_id)
		if _cells[cell].is_empty(): _cells.erase(cell)
	_actor_cells.erase(craft_id)
	_actors.erase(craft_id)
	return true
