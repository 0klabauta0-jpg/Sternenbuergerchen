class_name HexGroundDeploymentAdapter
extends RefCounted

## Stateless bridge for an existing transport sequence. Root owns presence;
## the caller owns its unload timer/index and publishes only phase=committed.
const EFFECTS=preload("res://scripts/mission/mission_dropship_effect_adapter.gd")

func advance_phase(simulation_root:Node,sequence:Dictionary,anchor_world:Vector2)->Dictionary:
	if not is_instance_valid(simulation_root) or not anchor_world.is_finite():return _waiting("invalid_deployment_context")
	var units:Variant=sequence.get("units",[])
	var index:int=int(sequence.get("unit_index",0))
	if not units is Array or units.size()>64 or index<0 or index>units.size():return _waiting("invalid_deployment_sequence")
	if index==units.size():return {"phase":"complete"}
	var ids:=PackedStringArray()
	for slot in range(index,units.size()):
		var actor=units[slot]
		if not is_instance_valid(actor) or not actor is Node2D or not actor.has_method("get_unit_id"):return _waiting("deployment_actor_unavailable")
		ids.append(String(actor.call("get_unit_id")))
	var checked:Dictionary=simulation_root.call("_validate_hex_ground_actor_group",ids,true)
	if not checked.ok:return _waiting(String(checked.get("reason","deployment_actor_unavailable")))
	for slot in range(index,units.size()):
		if checked.actors[ids[slot-index]]!=units[slot]:return _waiting("deployment_actor_mismatch")
	var id:String=ids[0]
	var receipt:Dictionary=sequence.get("hex_admission",{})
	var admission_id:String=String(receipt.get("admission_id",""))
	if not String(receipt.get("pending_unit_id","")).is_empty():
		if receipt.pending_unit_id!=id:
			cancel(simulation_root,sequence,"sequence_changed")
			return _waiting("deployment_sequence_changed")
		var committed:Dictionary=simulation_root.call("get_hex_ground_deployment_receipt",admission_id,id)
		if committed.ok:
			receipt.erase("pending_unit_id")
			receipt.erase("sent_tick")
			committed.phase="committed"
			return committed
		if int(simulation_root.get("tick_counter"))<=int(receipt.get("sent_tick",-1)):return _waiting("deployment_effect_pending")
		receipt.erase("pending_unit_id")
		receipt.erase("sent_tick")
		var applied:Dictionary=simulation_root.call("get_last_hex_lifecycle_resolution")
		return _waiting(String(applied.get("reason","deployment_not_committed")))
	var ticket:Dictionary=simulation_root.call("get_hex_ground_deployment",admission_id) if not admission_id.is_empty() else {"ok":false}
	if not ticket.ok:
		var registry:Node=simulation_root.call("get_hex_ground_terrain_registry")
		if not is_instance_valid(registry):return _waiting("deployment_terrain_unavailable")
		ticket=simulation_root.call("prepare_hex_ground_deployment",ids,registry.call("world_to_grid",anchor_world))
		if not ticket.ok:return _waiting(String(ticket.get("reason","deployment_waiting_space")))
		admission_id=ticket.admission_id
		receipt={"admission_id":admission_id}
		sequence["hex_admission"]=receipt
	var placement:Dictionary={}
	for candidate in ticket.placements:
		if candidate.unit_id==id:placement=candidate;break
	if placement.is_empty():
		cancel(simulation_root,sequence,"sequence_changed")
		return _waiting("deployment_ticket_mismatch")
	var terrain:Node=simulation_root.call("get_hex_ground_terrain_registry")
	var actor:Node=units[index]
	var team_id:String=String(actor.call("get_team_id")) if actor.has_method("get_team_id") else ""
	var queued:bool=EFFECTS.new().enqueue_deploy_effect(simulation_root,actor,id,terrain.call("grid_to_world",placement.grid),team_id,admission_id)
	if not queued:return _waiting("deployment_queue_unavailable")
	receipt["pending_unit_id"]=id
	receipt["sent_tick"]=int(simulation_root.get("tick_counter"))
	return {"phase":"queued","unit_id":id,"admission_id":admission_id}

func cancel(simulation_root:Node,sequence:Dictionary,reason:String)->Dictionary:
	var receipt:Dictionary=sequence.get("hex_admission",{})
	var result:Dictionary=simulation_root.call("cancel_hex_ground_deployment",String(receipt.get("admission_id","")),reason)
	if result.ok:sequence.erase("hex_admission")
	return result

func _waiting(reason:String)->Dictionary:
	return {"phase":"waiting","reason":reason}
