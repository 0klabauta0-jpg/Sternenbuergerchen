extends RefCounted
## Encounter metadata references registered motion; it does not copy positions.
const REGISTRY = preload("res://scripts/core/space_ship_registry.gd")
var _registry: RefCounted = REGISTRY.new()
var _metadata: Dictionary = {}

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
	return {"ok": true}

func get_actor(craft_id: String) -> RefCounted:
	return _registry.get_actor(craft_id)

func query_cells(cells: Array[Vector2i]) -> Array[String]:
	return _registry.query_cells(cells)

func get_metadata(craft_id: String) -> Dictionary:
	return Dictionary(_metadata.get(craft_id, {})).duplicate(true)
