extends RefCounted
## Encounter metadata references registered motion; it does not copy positions.
const REGISTRY = preload("res://scripts/core/space_ship_registry.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var _registry: RefCounted = REGISTRY.new()
var _metadata: Dictionary = {}
var _indexed_revisions: Dictionary = {}

func admit_actor(definition: Dictionary, flight: RefCounted) -> Dictionary:
	var craft_id: String = String(definition.get("craft_id", ""))
	var faction: String = String(definition.get("faction_id", ""))
	var domain: String = String(definition.get("control_domain", ""))
	var cell: Variant = definition.get("start_hex")
	if craft_id.strip_edges().is_empty() or faction.strip_edges().is_empty() or domain not in ["player", "neutral", "enemy"] or typeof(cell) != TYPE_VECTOR2I:
		return {"ok": false, "reason": "invalid_actor"}
	if not _registry.register_actor(craft_id, flight):
		return {"ok": false, "reason": "duplicate_or_invalid_actor"}
	var cells: Array[Vector2i] = [cell]
	if not _registry.update_actor_cells(craft_id, cells):
		_registry.unregister_actor(craft_id)
		return {"ok": false, "reason": "invalid_actor_cell"}
	_metadata[craft_id] = {"faction_id": faction, "control_domain": domain}
	_indexed_revisions[craft_id] = int(flight.get_snapshot().revision)
	return {"ok": true}

func get_actor(craft_id: String) -> RefCounted:
	return _registry.get_actor(craft_id)

func query_cells(cells: Array[Vector2i]) -> Array[String]:
	return _registry.query_cells(cells)

func update_actor_cell(craft_id: String, cell: Vector2i) -> bool:
	var cells: Array[Vector2i] = [cell]
	var updated: bool = _registry.update_actor_cells(craft_id, cells)
	if updated:
		_indexed_revisions[craft_id] = int(_registry.get_actor(craft_id).get_snapshot().revision)
	return updated

func sync_moved_actors() -> void:
	for craft_id in _metadata:
		var flight: RefCounted = _registry.get_actor(craft_id)
		var snapshot: Dictionary = flight.get_snapshot()
		if int(_indexed_revisions.get(craft_id, -1)) == int(snapshot.revision):
			continue
		var cell: Vector2i = GRID.cell_at(Vector2(snapshot.position_plane) / GRID.EXTENT)
		if GRID.contains(cell):
			update_actor_cell(craft_id, cell)

func get_metadata(craft_id: String) -> Dictionary:
	return Dictionary(_metadata.get(craft_id, {})).duplicate(true)
