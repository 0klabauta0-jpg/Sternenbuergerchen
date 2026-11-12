extends RefCounted
## Legacy actor positions, prepared separately from actor models. A world-level
## transaction must also validate ship/transport, orders and mission state.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
class PreparedLegacyGround extends RefCounted:
	pass
var _preparations: Dictionary = {}

func export_positions(owner: Node, terrain: Node, active_ids: Array) -> Dictionary:
	if not _context_valid(owner, terrain) or active_ids.size() > 128: return _reject("legacy_ground_unavailable")
	var registry: Node = owner.get_unit_registry()
	var positions := {}
	for value in active_ids:
		if typeof(value) != TYPE_STRING or value.is_empty() or positions.has(value): return _reject("invalid_legacy_ground_identity")
		var actor: Node = registry.get_unit(value)
		if not actor is Node2D or not actor.global_position.is_finite() or not terrain.is_walkable(terrain.world_to_grid(actor.global_position)): return _reject("invalid_legacy_ground_position")
		positions[value] = actor.global_position
	var payload := CODEC.encode_value(positions)
	if not payload.ok: return payload
	return {"ok":true, "schema":"legacy_ground_positions.v1", "frame":terrain.get_checkpoint_grid_frame(), "map_fingerprint":terrain.get_checkpoint_map_fingerprint(), "overrides":terrain.export_checkpoint_overrides(), "positions":payload.value}

func prepare_restore(owner: Node, terrain: Node, state: Dictionary, active_ids: Array) -> Dictionary:
	if not _context_valid(owner,terrain) or state.size()!=6 or not state.has_all(["ok","schema","frame","map_fingerprint","overrides","positions"]) or state.ok != true or state.schema != "legacy_ground_positions.v1" or state.frame != terrain.get_checkpoint_grid_frame() or state.map_fingerprint != terrain.get_checkpoint_map_fingerprint() or JSON.stringify(state.overrides,"",true) != JSON.stringify(terrain.export_checkpoint_overrides(),"",true): return _reject("legacy_ground_map_mismatch")
	var decoded := CODEC.decode_value(state.positions)
	if not decoded.ok or not decoded.value is Dictionary or decoded.value.size() != active_ids.size() or active_ids.size() > 128: return _reject("invalid_legacy_ground_position")
	var registry: Node = owner.get_unit_registry()
	var seen := {}
	var records: Array = []
	for value in active_ids:
		if typeof(value) != TYPE_STRING or value.is_empty() or seen.has(value) or not decoded.value.has(value): return _reject("invalid_legacy_ground_identity")
		seen[value] = true
		var actor: Node = registry.get_unit(value)
		var position: Variant = decoded.value[value]
		if not actor is Node2D or actor.is_queued_for_deletion() or not position is Vector2 or not position.is_finite() or not terrain.is_walkable(terrain.world_to_grid(position)): return _reject("invalid_legacy_ground_position")
		for entry in records:
			if position.distance_to(entry.target) < 0.001: return _reject("legacy_ground_overlap")
		records.append({"id":value,"actor":weakref(actor),"source":actor.global_position,"target":position,"parent":weakref(actor.get_parent())})
	for id in _preparations.keys():
		if _preparations[id].handle.get_ref() == null: _preparations.erase(id)
	if _preparations.size() >= 32: return _reject("legacy_ground_capacity")
	var handle := PreparedLegacyGround.new()
	_preparations[handle.get_instance_id()] = {"handle":weakref(handle),"owner":weakref(owner),"terrain":weakref(terrain),"registry":weakref(registry),"revision":terrain.get_revision(),"records":records}
	return {"ok":true,"prepared":handle,"positions":decoded.value.duplicate(true)}

func validate_restore(handle: RefCounted) -> Dictionary:
	if handle == null or not _preparations.has(handle.get_instance_id()): return _reject("legacy_ground_unknown")
	var record: Dictionary = _preparations[handle.get_instance_id()]
	var owner: Node = record.owner.get_ref()
	var terrain: Node = record.terrain.get_ref()
	var registry: Node = record.registry.get_ref()
	if record.handle.get_ref() != handle or not _context_valid(owner,terrain) or owner.get_unit_registry()!=registry or terrain.get_revision()!=record.revision: return _reject("legacy_ground_changed")
	for entry in record.records:
		var actor: Node = entry.actor.get_ref()
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or registry.get_unit(entry.id)!=actor or actor.get_parent()!=entry.parent.get_ref() or actor.global_position!=entry.source or not terrain.is_walkable(terrain.world_to_grid(entry.target)): return _reject("legacy_ground_changed")
	return {"ok":true}

func commit_restore(handle: RefCounted) -> Dictionary:
	var checked := validate_restore(handle)
	if not checked.ok: return checked
	_publish_restore(handle)
	return {"ok":true}

func _publish_restore(handle: RefCounted) -> void:
	var record: Dictionary = _preparations[handle.get_instance_id()]
	_preparations.erase(handle.get_instance_id())
	for entry in record.records:
		var actor: Node2D = entry.actor.get_ref()
		actor.global_position = entry.target

func _context_valid(owner: Node, terrain: Node) -> bool:
	return is_instance_valid(owner) and not owner.is_queued_for_deletion() and owner.has_method("get_unit_registry") and owner.has_method("is_hex_ground_runtime_active") and not owner.is_hex_ground_runtime_active() and is_instance_valid(owner.get_unit_registry()) and is_instance_valid(terrain) and not terrain.is_queued_for_deletion() and terrain.has_method("get_checkpoint_map_fingerprint")

func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
