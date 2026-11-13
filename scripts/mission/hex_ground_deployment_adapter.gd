class_name HexGroundDeploymentAdapter
extends RefCounted

## Stateless bridge for an existing transport sequence. Root owns presence;
## the caller owns its unload timer/index and publishes only phase=committed.
const EFFECTS=preload("res://scripts/mission/mission_dropship_effect_adapter.gd")

func advance_phase(simulation_root:Node,sequence:Dictionary,anchor_world:Vector2,obstacle_source:Callable=Callable())->Dictionary:
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
			# Root has committed the final actor. The sequence no longer owns a
			# pending admission; retaining its receipt would block stable saves.
			if index == units.size()-1: sequence.erase("hex_admission")
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
		var excluded:Array[Vector2i]=[]
		var anchor_grid:Vector2i=registry.call("world_to_grid",anchor_world)
		if obstacle_source.is_valid():
			# Disembarking actors need a free ground cell outside every hull,
			# including the vessel they just left.
			var mask:Variant=obstacle_source.call("")
			if not mask is Dictionary or not bool(mask.get("ok",false)):return _waiting(String(mask.get("reason","ground_ship_geometry_unbound")) if mask is Dictionary else "ground_ship_geometry_unbound")
			if int(mask.get("registry_id",0))!=registry.get_instance_id() or not mask.get("blocked_cells") is Array or mask.blocked_cells.size()>4096:return _waiting("ground_ship_registry_unavailable")
			for grid in mask.blocked_cells:
				if not grid is Vector2i:return _waiting("ground_ship_registry_unavailable")
				excluded.append(grid)
			# An unload anchor can lie under its own hull. Search outwards through
			# only that hull; never cross a different ship to select an exit.
			if excluded.has(anchor_grid):
				var foreign:Variant=obstacle_source.call(String(sequence.get("craft_id","")))
				if not foreign is Dictionary or not foreign.get("ok",false) or int(foreign.get("registry_id",0))!=registry.get_instance_id() or not foreign.get("blocked_cells") is Array or foreign.blocked_cells.size()>4096:return _waiting("ground_ship_registry_unavailable")
				var result:Dictionary=_exit_anchor(registry,anchor_grid,excluded,foreign.blocked_cells)
				if not result.ok:return _waiting("deployment_waiting_space")
				anchor_grid=result.grid
		ticket=simulation_root.call("prepare_hex_ground_deployment",ids,anchor_grid,excluded)
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

func _exit_anchor(registry:Node,start:Vector2i,all_cells:Array,foreign_cells:Array)->Dictionary:
	var all:Dictionary={}
	var foreign:Dictionary={}
	for cell in all_cells:all[cell]=true
	for cell in foreign_cells:
		if not cell is Vector2i:return {"ok":false}
		foreign[cell]=true
	var queue:Array[Vector2i]=[start]
	var seen:Dictionary={start:true}
	var cursor:=0
	while cursor<queue.size() and cursor<256:
		var grid:Vector2i=queue[cursor];cursor+=1
		if foreign.has(grid):continue
		if not all.has(grid) and bool(registry.call("is_walkable",grid)):return {"ok":true,"grid":grid}
		for next:Vector2i in registry.call("get_legal_hex_neighbors",grid):
			if not seen.has(next) and not foreign.has(next):seen[next]=true;queue.append(next)
	return {"ok":false}
