extends RefCounted
## Synchronizes the legacy ground-position owner with the real actor models.
## Outer mission coordinator must validate all other owners before publication.
const GROUND = preload("res://scripts/mission/legacy_ground_checkpoint.gd")
const ACTORS = preload("res://scripts/mission/mission_actor_checkpoint_batch.gd")
class PreparedGroundActors extends RefCounted:
	pass
var _preparations: Dictionary = {}

func prepare_restore(sim: Node, terrain: Node, ground_state: Dictionary, actor_state: Dictionary, active_ids: Array) -> Dictionary:
	var ground = GROUND.new()
	var actors = ACTORS.new()
	var gp: Dictionary = ground.prepare_restore(sim,terrain,ground_state,active_ids)
	if not gp.get("ok",false): return gp
	var ap: Dictionary = actors.prepare_restore(sim,actor_state,gp.positions)
	if not ap.get("ok",false): return ap
	for id in _preparations.keys():
		if _preparations[id].handle.get_ref()==null: _preparations.erase(id)
	if _preparations.size() >= 32: return {"ok":false,"reason":"ground_actor_capacity"}
	var handle := PreparedGroundActors.new()
	_preparations[handle.get_instance_id()] = {"handle":weakref(handle),"ground":ground,"actors":actors,"gp":gp.prepared,"ap":ap.prepared,"phase":"prepared"}
	return {"ok":true,"prepared":handle}

func validate_restore(handle: RefCounted) -> Dictionary:
	if handle==null or not _preparations.has(handle.get_instance_id()): return {"ok":false,"reason":"ground_actor_unknown"}
	var record: Dictionary = _preparations[handle.get_instance_id()]
	if record.handle.get_ref()!=handle or record.phase!="prepared": return {"ok":false,"reason":"ground_actor_changed"}
	var check: Dictionary = record.ground.validate_restore(record.gp)
	if not check.get("ok",false): return check
	return record.actors.validate_restore(record.ap)

func _publish_restore(handle: RefCounted) -> void:
	var record: Dictionary = _preparations[handle.get_instance_id()]
	record.ground._publish_restore(record.gp)
	record.actors._publish_restore(record.ap,{"ok":true})
	record.phase = "published"

func finalize_restore(handle: RefCounted) -> Dictionary:
	if handle==null or not _preparations.has(handle.get_instance_id()): return {"ok":false,"reason":"ground_actor_unknown"}
	var record: Dictionary = _preparations[handle.get_instance_id()]
	if record.handle.get_ref()!=handle or record.phase!="published": return {"ok":false,"reason":"ground_actor_changed"}
	_preparations.erase(handle.get_instance_id())
	return record.actors.finalize_restore(record.ap)
