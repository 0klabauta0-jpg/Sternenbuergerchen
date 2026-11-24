extends RefCounted
## Transactional preparation for actual registered mission actors. The caller
## must independently prepare ground/transport/mission owners before commit.
class PreparedActors extends RefCounted:
	pass
var _preparations: Dictionary = {}

func export_actors(owner: Node, staged_ids: Array = []) -> Dictionary:
	if not is_instance_valid(owner) or not owner.has_method("get_unit_registry"): return _reject("actor_owner_unavailable")
	var registry: Node = owner.get_unit_registry()
	if not is_instance_valid(registry): return _reject("actor_registry_unavailable")
	var actors := {}
	var units: Array = registry.get_all_units()
	# Luftrollen 5b-1: Akteure, die nie abgesetzt wurden (Ankunft im Kreisen), sind dem Root bekannt, stehen aber nicht im Register; sie werden ueber ihre Kennung mitgesichert.
	var staged := {}
	if not staged_ids.is_empty():
		units = units.duplicate()
		for staged_id in staged_ids:
			if typeof(staged_id) != TYPE_STRING or registry.has_unit(staged_id): continue
			var known: Variant = owner.call("_resolve_known_unit_for_contract", staged_id) if owner.has_method("_resolve_known_unit_for_contract") else null
			if not is_instance_valid(known): return _reject("actor_identity_mismatch")
			units.append(known)
			staged[staged_id] = true
	for actor in units:
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.has_method("export_mission_actor_checkpoint"): return _reject("actor_checkpoint_unavailable")
		var id := String(actor.get("unit_id"))
		if id.is_empty() or actors.has(id) or (not staged.has(id) and registry.get_unit(id) != actor): return _reject("actor_identity_mismatch")
		var state: Dictionary = actor.export_mission_actor_checkpoint()
		if state.get("ok", true) == false: return state
		actors[id] = state
	if actors.size() > 128: return _reject("actor_capacity")
	return {"ok":true, "schema":"mission_actor_batch.v1", "actors":actors}

func prepare_restore(owner: Node, state: Dictionary, expected_positions: Dictionary) -> Dictionary:
	for id in _preparations.keys():
		if _preparations[id].handle.get_ref() == null: _preparations.erase(id)
	if _preparations.size() >= 32: return _reject("actor_batch_capacity")
	if not is_instance_valid(owner) or not owner.has_method("get_unit_registry") or state.size() != 3 or state.get("ok") != true or state.get("schema") != "mission_actor_batch.v1" or not state.get("actors") is Dictionary or state.actors.size() > 128 or expected_positions.size() != state.actors.size(): return _reject("invalid_actor_batch")
	var registry: Node = owner.get_unit_registry()
	if not is_instance_valid(registry) or registry.get_all_units().size() != state.actors.size(): return _reject("actor_registry_mismatch")
	var records: Array = []
	var ids: Array = state.actors.keys()
	ids.sort()
	for id in ids:
		if typeof(id) != TYPE_STRING or not expected_positions.has(id) or not expected_positions[id] is Vector2 or not state.actors[id] is Dictionary: return _reject("invalid_actor_batch")
		var actor: Node = registry.get_unit(id)
		if not is_instance_valid(actor) or not actor.has_method("prepare_mission_actor_restore"): return _reject("actor_checkpoint_unavailable")
		var prepared: Dictionary = actor.prepare_mission_actor_restore(owner, state.actors[id], expected_positions[id])
		if not prepared.get("ok",false): return prepared
		records.append({"actor":weakref(actor), "id":id, "handle":prepared.prepared})
	var handle := PreparedActors.new()
	_preparations[handle.get_instance_id()] = {"handle":weakref(handle), "owner":weakref(owner), "registry":weakref(registry), "records":records, "phase":"prepared"}
	return {"ok":true, "prepared":handle}

func validate_restore(handle: RefCounted) -> Dictionary:
	if handle == null or not _preparations.has(handle.get_instance_id()): return _reject("actor_batch_unknown")
	var record: Dictionary = _preparations[handle.get_instance_id()]
	var owner: Node = record.owner.get_ref()
	var registry: Node = record.registry.get_ref()
	if record.phase != "prepared" or record.handle.get_ref() != handle or not is_instance_valid(owner) or not is_instance_valid(registry) or owner.get_unit_registry() != registry or registry.get_all_units().size() != record.records.size(): return _reject("actor_batch_changed")
	for entry in record.records:
		var actor: Node = entry.actor.get_ref()
		if not is_instance_valid(actor) or registry.get_unit(entry.id) != actor: return _reject("actor_batch_changed")
		var checked: Dictionary = actor.validate_mission_actor_restore(entry.handle)
		if not checked.get("ok",false): return checked
	return {"ok":true}

func commit_restore(handle: RefCounted) -> Dictionary:
	var checked := validate_restore(handle)
	if not checked.get("ok",false): return checked
	_publish_restore(handle, checked)
	return finalize_restore(handle)

# Caller must validate all other owners before this synchronous no-signal tail.
func _publish_restore(handle: RefCounted, checked: Dictionary) -> void:
	var record: Dictionary = _preparations[handle.get_instance_id()]
	for entry in record.records:
		var actor: Node = entry.actor.get_ref()
		actor._publish_mission_actor_restore(entry.handle, checked)
	record.phase = "published"

func finalize_restore(handle: RefCounted) -> Dictionary:
	if handle == null or not _preparations.has(handle.get_instance_id()): return _reject("actor_batch_unknown")
	var record: Dictionary = _preparations[handle.get_instance_id()]
	if record.phase != "published" or record.handle.get_ref() != handle: return _reject("actor_batch_changed")
	_preparations.erase(handle.get_instance_id())
	var context_changed := false
	for entry in record.records:
		var actor: Node = entry.actor.get_ref()
		if not is_instance_valid(actor):
			context_changed = true
			continue
		var result: Dictionary = actor.finalize_mission_actor_restore(entry.handle)
		if not result.get("ok",false) or result.get("context_changed",false): context_changed = true
	return {"ok":true, "context_changed":context_changed}

func _reject(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
