extends RefCounted
## Synchronizes the Hex ground owner with the real actor models.
## Outer mission coordinator must validate all other owners before publication.
## Checkpoints in the pre-Hex format (legacy_ground_positions.v1) are rejected
## since 20.11.2026; only hex_mission_ground.v1 is restored.
class PreparedGroundActors extends RefCounted:
	pass
var _preparations: Dictionary = {}

func prepare_restore(sim: Node, terrain: Node, ground_state: Dictionary, actor_state: Dictionary, active_ids: Array, lifecycle_state:Dictionary={}) -> Dictionary:
	for id in _preparations.keys():
		if _preparations[id].handle.get_ref()==null: _preparations.erase(id)
	if _preparations.size() >= 32: return {"ok":false,"reason":"ground_actor_capacity"}
	if ground_state.get("schema") != "hex_mission_ground.v1": return {"ok":false,"reason":"unsupported_ground_schema"}
	if ground_state.size() != 3 or ground_state.get("ok") != true or not ground_state.get("checkpoint") is Dictionary or not sim.is_hex_ground_runtime_active(): return {"ok":false,"reason":"invalid_hex_mission_ground"}
	var checkpoint: Dictionary = ground_state.checkpoint
	# Root validates the complete actual registry against the independently
	# prepared Ground projection and the actor batch; never use actor position
	# itself as its own placement proof.
	var actor_records: Variant = actor_state.get("actors")
	if not actor_records is Dictionary or active_ids.size() != actor_records.size(): return {"ok":false,"reason":"actor_registry_mismatch"}
	var prepared: Dictionary = sim.prepare_hex_checkpoint_restore(checkpoint, actor_state)
	if not prepared.get("ok",false): return prepared
	var handle := PreparedGroundActors.new()
	_preparations[handle.get_instance_id()] = {"handle":weakref(handle),"hex_owner":weakref(sim),"gp":prepared.prepared,"phase":"prepared"}
	return {"ok":true,"prepared":handle}

func validate_restore(handle: RefCounted) -> Dictionary:
	if handle==null or not _preparations.has(handle.get_instance_id()): return {"ok":false,"reason":"ground_actor_unknown"}
	var record: Dictionary = _preparations[handle.get_instance_id()]
	if record.handle.get_ref()!=handle or record.phase!="prepared": return {"ok":false,"reason":"ground_actor_changed"}
	var owner: Node = record.hex_owner.get_ref()
	return owner.validate_prepared_hex_checkpoint_restore(record.gp) if is_instance_valid(owner) else {"ok":false,"reason":"ground_actor_changed"}

func _publish_restore(handle: RefCounted) -> void:
	var record: Dictionary = _preparations[handle.get_instance_id()]
	record.hex_owner.get_ref().commit_hex_checkpoint_restore(record.gp, false)
	record.phase = "published"

func finalize_restore(handle: RefCounted) -> Dictionary:
	if handle==null or not _preparations.has(handle.get_instance_id()): return {"ok":false,"reason":"ground_actor_unknown"}
	var record: Dictionary = _preparations[handle.get_instance_id()]
	if record.handle.get_ref()!=handle or record.phase!="published": return {"ok":false,"reason":"ground_actor_changed"}
	_preparations.erase(handle.get_instance_id())
	var owner: Node = record.hex_owner.get_ref()
	return owner.finalize_hex_checkpoint_restore(record.gp) if is_instance_valid(owner) else {"ok":true,"context_changed":true}
