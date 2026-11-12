extends RefCounted
## Lookup and caller-maintained spatial index; no movement or gameplay mutation.

var _actors: Dictionary = {}
var _cells: Dictionary = {}
var _actor_cells: Dictionary = {}
var _actor_areas: Dictionary = {}
var _area_actors: Dictionary = {}
var _area_revisions: Dictionary = {}

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
	if _actor_areas.get(craft_id, null) == area:
		var old_cells: Array = _actor_cells.get(craft_id, [])
		if old_cells.size() == unique.size():
			var unchanged := true
			for cell in old_cells:
				if not unique.has(cell): unchanged = false; break
			if unchanged: return true
	_remove_actor_cells(craft_id)
	_actor_cells[craft_id] = unique.keys()
	_actor_areas[craft_id] = area
	if not _area_actors.has(area): _area_actors[area] = {}
	_area_actors[area][craft_id] = true
	if not _cells.has(area): _cells[area] = {}
	for cell in unique:
		if not _cells[area].has(cell): _cells[area][cell] = {}
		_cells[area][cell][craft_id] = true
	_area_revisions[area] = get_area_revision(area) + 1
	return true

func get_area_revision(area_id: String = "") -> int:
	return int(_area_revisions.get(area_id, 0))

func get_area_actor_ids(area_id: String) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(Dictionary(_area_actors.get(area_id, {})).keys())
	ids.sort()
	return ids

func get_indexed_actor_cells(craft_id: String) -> Array:
	return Array(_actor_cells.get(craft_id, [])).duplicate()

func can_register_actor(craft_id: String, flight: RefCounted) -> bool:
	return not craft_id.strip_edges().is_empty() and flight != null and not _actors.has(craft_id) and not _actor_cells.has(craft_id) and not _actor_areas.has(craft_id) and flight.get_snapshot().get("craft_id") == craft_id

func _publish_register_actor_cells(craft_id: String, flight: RefCounted, area_id: String, cells: Array) -> void:
	# Root-private tail: identity, cells and occupancy were checked immediately
	# before the coordinated Flight transition. No callbacks or revalidation.
	_actors[craft_id] = flight
	_actor_cells[craft_id] = cells.duplicate()
	_actor_areas[craft_id] = area_id
	if not _area_actors.has(area_id): _area_actors[area_id] = {}
	_area_actors[area_id][craft_id] = true
	if not _cells.has(area_id): _cells[area_id] = {}
	for cell in cells:
		if not _cells[area_id].has(cell): _cells[area_id][cell] = {}
		_cells[area_id][cell][craft_id] = true
	_area_revisions[area_id] = get_area_revision(area_id) + 1

func actor_cells_match(craft_id: String, area_id: String, cells: Array[Vector2i]) -> bool:
	if _actor_areas.get(craft_id, null) != area_id: return false
	var indexed: Array = _actor_cells.get(craft_id, [])
	var requested := {}
	for cell in cells: requested[cell] = true
	if indexed.size() != requested.size(): return false
	for cell in indexed:
		if not requested.has(cell): return false
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
	_publish_unregister_actor(craft_id)
	return true

func _publish_unregister_actor(craft_id: String) -> void:
	# Caller has already validated identity; no external callbacks or signals.
	_remove_actor_cells(craft_id)
	_actors.erase(craft_id)

func _remove_actor_cells(craft_id: String) -> void:
	var area: String = String(_actor_areas.get(craft_id, ""))
	var had_cells := _actor_cells.has(craft_id)
	for cell in _actor_cells.get(craft_id, []):
		_cells[area][cell].erase(craft_id)
		if _cells[area][cell].is_empty(): _cells[area].erase(cell)
	if _cells.has(area) and _cells[area].is_empty(): _cells.erase(area)
	_actor_cells.erase(craft_id)
	_actor_areas.erase(craft_id)
	if had_cells:
		_area_actors[area].erase(craft_id)
		if _area_actors[area].is_empty(): _area_actors.erase(area)
	if had_cells: _area_revisions[area] = get_area_revision(area) + 1

const CHECKPOINT_SCHEMA := "space_registry_checkpoint.v1"
const CHECKPOINT_LIMIT := 4096
const CHECKPOINT_MAX_REVISION := 9007199254740991

func export_checkpoint_index() -> Dictionary:
	# Validate through the same detached reconstruction used by restore, then
	# compare every maintained lookup: a partial/unindexed owner is not savable.
	if _actors.size() > CHECKPOINT_LIMIT: return _checkpoint_error("actor_limit")
	var ids: Array = _actors.keys()
	for id in ids:
		if not _checkpoint_id(id, false): return _checkpoint_error("invalid_craft_id")
	ids.sort()
	var actors: Array = []
	for id in ids:
		var flight: Variant = _actors[id]
		if not flight is RefCounted or not flight.has_method("get_snapshot"):
			return _checkpoint_error("invalid_flight")
		var snapshot: Variant = flight.get_snapshot()
		if typeof(snapshot) != TYPE_DICTIONARY: return _checkpoint_error("invalid_flight")
		var cells: Array = []
		var indexed: Variant = _actor_cells.get(id)
		if typeof(indexed) != TYPE_ARRAY or indexed.is_empty() or indexed.size() > CHECKPOINT_LIMIT:
			return _checkpoint_error("unindexed_actor")
		for cell in indexed:
			if typeof(cell) != TYPE_VECTOR2I: return _checkpoint_error("invalid_cell")
			cells.append([cell.x, cell.y])
		cells.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
		actors.append({"craft_id":id, "area_id":_actor_areas.get(id), "flight_revision":snapshot.get("revision"), "cells":cells})
	var state := {"schema":CHECKPOINT_SCHEMA, "actors":actors, "area_revisions":_area_revisions.duplicate(true)}
	var prepared := prepare_checkpoint_candidate(state, _actors)
	if not prepared.ok: return prepared
	var candidate: RefCounted = prepared.candidate
	if candidate._cells != _cells or candidate._actor_areas != _actor_areas or candidate._area_actors != _area_actors or _actor_cells.size() != actors.size():
		return _checkpoint_error("inconsistent_index")
	return state

static func prepare_checkpoint_candidate(state: Dictionary, flights: Dictionary) -> Dictionary:
	# No Flight mutation: the coordinator owns restoring and publishing Flights.
	if state.size() != 3 or not state.has_all(["schema", "actors", "area_revisions"]) or state.schema != CHECKPOINT_SCHEMA:
		return _checkpoint_error("invalid_schema")
	if typeof(state.actors) != TYPE_ARRAY or state.actors.size() > CHECKPOINT_LIMIT or typeof(state.area_revisions) != TYPE_DICTIONARY or state.area_revisions.size() > CHECKPOINT_LIMIT:
		return _checkpoint_error("invalid_shape")
	var candidate: RefCounted = load("res://scripts/core/space_ship_registry.gd").new()
	for area in state.area_revisions:
		if not _checkpoint_id(area, true) or not _checkpoint_integer(state.area_revisions[area], 0, CHECKPOINT_MAX_REVISION):
			return _checkpoint_error("invalid_area_revision")
		candidate._area_revisions[area] = int(state.area_revisions[area])
	var owners := {}
	for actor in state.actors:
		if typeof(actor) != TYPE_DICTIONARY or actor.size() != 4 or not actor.has_all(["craft_id", "area_id", "flight_revision", "cells"]):
			return _checkpoint_error("invalid_actor")
		if not _checkpoint_id(actor.craft_id, false) or not _checkpoint_id(actor.area_id, true) or not _checkpoint_integer(actor.flight_revision, 0, CHECKPOINT_MAX_REVISION):
			return _checkpoint_error("invalid_actor_identity")
		var id: String = actor.craft_id
		var area: String = actor.area_id
		if candidate._actors.has(id) or not flights.has(id): return _checkpoint_error("duplicate_or_missing_actor")
		var flight: Variant = flights[id]
		if not flight is RefCounted or not flight.has_method("get_snapshot") or owners.has(flight):
			return _checkpoint_error("invalid_flight_owner")
		var snapshot: Variant = flight.get_snapshot()
		if typeof(snapshot) != TYPE_DICTIONARY or snapshot.get("craft_id") != id or snapshot.get("space_area_id") != area or not _checkpoint_integer(snapshot.get("revision"), 0, CHECKPOINT_MAX_REVISION) or snapshot.revision != actor.flight_revision:
			return _checkpoint_error("stale_flight")
		if typeof(actor.cells) != TYPE_ARRAY or actor.cells.is_empty() or actor.cells.size() > CHECKPOINT_LIMIT:
			return _checkpoint_error("invalid_cells")
		var cells: Array = []
		var seen := {}
		for pair in actor.cells:
			if typeof(pair) != TYPE_ARRAY or pair.size() != 2 or not _checkpoint_integer(pair[0], -2147483648, 2147483647) or not _checkpoint_integer(pair[1], -2147483648, 2147483647):
				return _checkpoint_error("invalid_cell")
			var cell := Vector2i(int(pair[0]), int(pair[1]))
			if seen.has(cell) or candidate._cells.get(area, {}).has(cell): return _checkpoint_error("cell_collision")
			seen[cell] = true
			cells.append(cell)
		owners[flight] = true
		candidate._actors[id] = flight
		candidate._actor_cells[id] = cells
		candidate._actor_areas[id] = area
		if not candidate._area_actors.has(area): candidate._area_actors[area] = {}
		candidate._area_actors[area][id] = true
		if not candidate._cells.has(area): candidate._cells[area] = {}
		for cell in cells: candidate._cells[area][cell] = {id:true}
	for area in candidate._area_actors:
		if not candidate._area_revisions.has(area) or candidate._area_revisions[area] < candidate._area_actors[area].size():
			return _checkpoint_error("missing_area_revision")
	return {"ok":true, "candidate":candidate}

static func _checkpoint_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) == TYPE_INT: return value >= minimum and value <= maximum
	return typeof(value) == TYPE_FLOAT and is_finite(value) and value >= minimum and value <= maximum and floor(value) == value

static func _checkpoint_id(value: Variant, allow_empty: bool) -> bool:
	return typeof(value) == TYPE_STRING and value.length() <= 256 and (allow_empty or not value.strip_edges().is_empty())

static func _checkpoint_error(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
