class_name HexGroundRuntime
extends RefCounted

## SimulationRoot-owned logical ground state. Registries and views only read it.
## No unit transforms, commands or terrain data are mutated by this helper.
const TOPOLOGY := "hex_axial_v1"
const RESERVATION_SCHEMA_VERSION := 1
const MAX_TICK := 1000000000000
const PLANNER = preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

var _registry: Node
var _map_id := ""
var _tick := 0
var _revision := 0
var _units_by_id: Dictionary = {}
var _occupant_by_grid: Dictionary = {}
var _segments_by_unit_id: Dictionary = {}
var _corridor_grants: Array[Dictionary] = []
var _reservation_terrain_revision := -1
var _topology_revalidation_pending := false
var _centering_by_unit_id: Dictionary = {}
var _motion_geometry_by_unit_id: Dictionary = {}
var _admission_by_id: Dictionary = {}
var _admission_slots_by_grid: Dictionary = {}
var _admission_id_by_unit: Dictionary = {}
var _restore_binding_epoch := 0
var _prepared_restores: Dictionary = {}

class PreparedGroundRestore extends RefCounted:
	pass


func configure(registry: Node, map_id: String, tick: int) -> void:
	clear()
	if not is_instance_valid(registry) or map_id.strip_edges().is_empty() or tick < 0 or tick > MAX_TICK:
		return
	if not registry.has_method("get_grid_topology") or String(registry.call("get_grid_topology")) != TOPOLOGY:
		return
	if not registry.has_method("is_walkable") or not registry.has_method("get_stand_height_at"):
		return
	_registry = registry
	_map_id = map_id
	_tick = tick
	_reservation_terrain_revision = _terrain_revision()


func _stage_admission_units(placements: Array[Dictionary], admission_id:String="") -> Dictionary:
	if not _is_configured():
		return _reject("not_configured")
	if placements.size()>64:return _reject("admission_budget")
	if not admission_id.is_empty() and not _admission_by_id.has(admission_id):return _reject("admission_ticket_unavailable")
	var staged_units: Dictionary = {}
	var staged_cells: Dictionary = {}
	for placement in placements:
		var raw_id: Variant = placement.get("unit_id", null)
		if typeof(raw_id) != TYPE_STRING or String(raw_id).is_empty() or String(raw_id) != String(raw_id).strip_edges():
			return _reject("invalid_unit_id")
		var unit_id: String = raw_id
		if _units_by_id.has(unit_id) or staged_units.has(unit_id):
			return _reject("unit_already_admitted", unit_id)
		var grid: Variant = placement.get("grid", null)
		if typeof(grid) != TYPE_VECTOR2I:
			return _reject("invalid_grid", unit_id)
		if not admission_id.is_empty():
			var expected:Dictionary=_admission_by_id[admission_id].remaining.get(unit_id,{})
			if expected.is_empty() or expected.grid!=grid:return _reject("admission_ticket_mismatch",unit_id)
		elif _admission_id_by_unit.has(unit_id):return _reject("unit_admission_pending",unit_id)
		var facing: Variant = placement.get("facing_dir", 0)
		if typeof(facing) != TYPE_INT or int(facing) < 0 or int(facing) > 5:
			return _reject("invalid_facing", unit_id)
		var posture: Variant = placement.get("posture_key", "standing")
		if typeof(posture) != TYPE_STRING or String(posture).strip_edges().is_empty():
			return _reject("invalid_posture", unit_id)
		if _occupant_by_grid.has(grid) or staged_cells.has(grid):
			return _reject("cell_occupied", unit_id)
		if not bool(_registry.call("is_walkable", grid)):
			return _reject("cell_unwalkable", unit_id)
		var tile=_registry.call("get_tile_at_grid",grid)
		if tile==null or not tile.is_valid():return _reject("invalid_admission_tile",unit_id)
		var stand_height: float = float(_registry.call("get_stand_height_at", grid))
		if not is_finite(stand_height):
			return _reject("invalid_stand_height", unit_id)
		staged_units[unit_id] = {
			"unit_id": unit_id, "grid": grid, "facing_dir": int(facing),
			"posture_key": String(posture), "state_revision": _revision + 1,
			"movement_state": {"moving": false},
		}
		staged_cells[grid] = unit_id
	if not staged_units.is_empty():
		# A vacated endpoint remains locked until the whole crossing ends. Closed
		# corridor cohorts also protect cells beyond the three promised steps.
		var claims:Dictionary=can_block_cells(staged_cells.keys(),admission_id)
		if not claims.ok or not claims.can_block:return _reject("cell_reserved")
	return {"ok":true,"units":staged_units,"cells":staged_cells}


func admit_units(placements:Array[Dictionary],admission_id:String="")->Dictionary:
	var staged:Dictionary=_stage_admission_units(placements,admission_id)
	if not staged.ok:return staged
	if not admission_id.is_empty() and not _admission_access_valid(_admission_by_id[admission_id]):return _reject("admission_access_changed")
	if not staged.units.is_empty():
		if not admission_id.is_empty():
			for id in staged.units:staged.units[id]["admission_id"]=admission_id
		_units_by_id.merge(staged.units)
		_occupant_by_grid.merge(staged.cells)
		if not admission_id.is_empty():
			for id in staged.units:
				_admission_slots_by_grid.erase(staged.units[id].grid)
				_admission_id_by_unit.erase(id)
				_admission_by_id[admission_id].remaining.erase(id)
			if _admission_by_id[admission_id].remaining.is_empty():_admission_by_id.erase(admission_id)
		_revision+=1
	return {"ok":true,"admitted_unit_ids":staged.units.keys()}


func reserve_admission_group(admission_id:String,placements:Array[Dictionary],expected_revision:int)->Dictionary:
	if admission_id.is_empty() or admission_id!=admission_id.strip_edges() or admission_id.length()>256:return _reject("invalid_admission_ticket")
	if _admission_by_id.has(admission_id) or _admission_by_id.size()>=16 or expected_revision!=_revision:return _reject("admission_revision_or_budget")
	if placements.is_empty():return _reject("invalid_admission_group")
	var staged:Dictionary=_stage_admission_units(placements)
	if not staged.ok:return staged
	var remaining:Dictionary={}
	for entry in placements:remaining[entry.unit_id]=entry.duplicate(true)
	var group:Dictionary={"admission_id":admission_id,"entry_grid":placements[0].grid,"access_cells":staged.cells.duplicate(),"remaining":remaining}
	if not _admission_access_valid(group):return _reject("invalid_admission_access")
	_admission_by_id[admission_id]=group
	for id in remaining:
		_admission_slots_by_grid[remaining[id].grid]={"admission_id":admission_id,"unit_id":id}
		_admission_id_by_unit[id]=admission_id
	_revision+=1
	return get_admission_group(admission_id)


func get_admission_group(admission_id:String)->Dictionary:
	if not _admission_by_id.has(admission_id):return _reject("admission_ticket_unavailable")
	var group:Dictionary=_admission_by_id[admission_id]
	return {"ok":true,"admission_id":admission_id,"placements":group.remaining.values().duplicate(true),"remaining_unit_ids":PackedStringArray(group.remaining.keys())}


func has_pending_admission(unit_id:String)->bool:
	return _admission_id_by_unit.has(unit_id)


func cancel_admission_group(admission_id:String,reason:String)->Dictionary:
	if reason.strip_edges().is_empty():return _reject("invalid_admission_cancel")
	if not _admission_by_id.has(admission_id):return {"ok":true,"released_unit_ids":PackedStringArray()}
	var group:Dictionary=_admission_by_id[admission_id]
	for id in group.remaining:
		_admission_slots_by_grid.erase(group.remaining[id].grid)
		_admission_id_by_unit.erase(id)
	_admission_by_id.erase(admission_id)
	_revision+=1
	return {"ok":true,"released_unit_ids":PackedStringArray(group.remaining.keys())}


func _admission_access_valid(group:Dictionary)->bool:
	var cells:Dictionary=group.access_cells
	var queue:Array=[group.entry_grid]
	var reached:Dictionary={group.entry_grid:true}
	var cursor:=0
	while cursor<queue.size() and cursor<64:
		var grid:Vector2i=queue[cursor]
		cursor+=1
		var tile=_registry.call("get_tile_at_grid",grid)
		if tile==null or not tile.is_valid() or not bool(_registry.call("is_walkable",grid)):return false
		for next in _registry.call("get_legal_hex_neighbors",grid):
			if cells.has(next) and not reached.has(next):reached[next]=true;queue.append(next)
	return reached.size()==cells.size()


func read_unit(unit_id: String) -> Dictionary:
	if not _is_configured() or not _units_by_id.has(unit_id):
		return {}
	var result: Dictionary = Dictionary(_units_by_id[unit_id]).duplicate(true)
	# Read current terrain revision/height without turning a getter into a mutation.
	result["stand_height_steps2"] = roundi(2.0 * float(_registry.call("get_stand_height_at", result["grid"])))
	result["terrain_revision"] = _terrain_revision()
	result["movement_state"] = {"moving":false}
	var route:Array=_segments_by_unit_id.get(unit_id,[])
	result["route_state"]={"has_commitments":not route.is_empty()}
	if not route.is_empty():
		var last:Dictionary=route.back()
		result.route_state.merge({"final_grid":last.to_grid,"last_handoff_tick":last.handoff_tick,"end_tick":int(last.start_tick)+int(last.duration_ticks),"command_id":last.command_id})
	var centering:Dictionary=_centering_by_unit_id.get(unit_id,{})
	if not centering.is_empty() and _tick<int(centering.start_tick)+int(centering.duration_ticks):
		result["movement_state"]={"moving":true,"phase":"centering","start_tick":centering.start_tick,"duration_ticks":centering.duration_ticks}
	for segment in _segments_by_unit_id.get(unit_id,[]):
		if result.movement_state.get("phase","")=="centering":break
		if int(segment.start_tick) <= _tick and _tick < int(segment.start_tick)+int(segment.duration_ticks):
			result["movement_state"] = {"moving":true,"command_id":segment.command_id,
				"from_grid":segment.from_grid,"to_grid":segment.to_grid,
				"start_tick":segment.start_tick,"duration_ticks":segment.duration_ticks}
			break
	return result


func build_planning_snapshot() -> Dictionary:
	var units: Dictionary = {}
	for unit_id in _units_by_id:
		units[unit_id] = read_unit(String(unit_id))
	return {
		"map_id": _map_id, "revision": _revision, "current_tick": _tick,
		"terrain_revision": _terrain_revision(), "units_by_id": units,
		"occupant_by_grid": _occupant_by_grid.duplicate(true),
		"reservation_schema_version":RESERVATION_SCHEMA_VERSION,
		"committed_segments":_all_segments(),
		"committed_corridor_grants":_corridor_grants.duplicate(true),
		"admission_slots_by_grid":_admission_slots_by_grid.duplicate(true),
	}


func get_current_tick() -> int:
	return _tick


func has_unit(unit_id: String) -> bool:
	return _is_configured() and _units_by_id.has(unit_id)


func get_unit_ids() -> Array:
	return _units_by_id.keys() if _is_configured() else []


func get_unit_grid(unit_id:String) -> Variant:
	return _units_by_id[unit_id].grid if has_unit(unit_id) else null


func has_motion_commitments(unit_id: String) -> bool:
	return _segments_by_unit_id.has(unit_id) or _centering_by_unit_id.has(unit_id)


## Presentation only: fractional reads never advance ownership, clocks or rolls.
func get_motion_projection(unit_id: String, interpolation_fraction: float, height_step_world: float = 1.0) -> Dictionary:
	if not _is_configured() or not _units_by_id.has(unit_id) or not is_finite(interpolation_fraction) or not is_finite(height_step_world) or height_step_world<=0.0:return {}
	var unit:Dictionary=_units_by_id[unit_id]
	var grid:Vector2i=unit.grid
	var position:Vector2=_registry.call("grid_to_world",grid)
	var height:float=_registry.call("get_stand_height_at",grid)
	var moving:=false
	var centering:Dictionary=_centering_by_unit_id.get(unit_id,{})
	if not centering.is_empty() and _tick<int(centering.start_tick)+int(centering.duration_ticks):
		var progress:float=clampf((float(_tick-int(centering.start_tick))+clampf(interpolation_fraction,0.0,1.0))/float(centering.duration_ticks),0.0,1.0)
		var offset:Vector2=Vector2(centering.offset_axial)*(1.0-progress)
		var axis_q:Vector2=Vector2(_registry.call("grid_to_world",grid+Vector2i(1,0)))-position
		var axis_r:Vector2=Vector2(_registry.call("grid_to_world",grid+Vector2i(0,1)))-position
		position+=axis_q*offset.x+axis_r*offset.y
		height=lerpf(float(centering.stand_height_logical),height,progress)
		moving=true
	for segment in _segments_by_unit_id.get(unit_id,[]):
		if moving:break
		if int(segment.start_tick)>_tick or _tick>=int(segment.start_tick)+int(segment.duration_ticks):continue
		var progress:float=clampf((float(_tick-int(segment.start_tick))+clampf(interpolation_fraction,0.0,1.0))/float(segment.duration_ticks),0.0,1.0)
		var geometry:Dictionary=_motion_geometry_by_unit_id.get(unit_id,{}).get(int(segment.start_tick),{})
		if geometry.is_empty():return {}
		var source:Vector2=geometry.source_world
		var target:Vector2=geometry.target_world
		position=source.lerp(target,progress)
		var low:float=geometry.source_height
		var high:float=geometry.target_height
		if geometry.explicit_ramps:
			var shared:float=geometry.shared_height
			height=lerpf(low,shared,progress*2.0) if progress<=0.5 else lerpf(shared,high,(progress-0.5)*2.0)
		else:height=lerpf(low,high,progress)
		moving=true
		break
	var facing_step:Vector2i=HEX.DIRECTIONS[int(unit.facing_dir)]
	var bearing:Vector2=Vector2(_registry.call("grid_to_world",grid+facing_step))-Vector2(_registry.call("grid_to_world",grid))
	return {"position_world":position,"stand_height_logical":height,"stand_height_world":height*height_step_world,"facing_angle":bearing.angle(),"moving":moving}


func _build_motion_geometry(segment: Dictionary) -> Dictionary:
	var source:Vector2=_registry.call("grid_to_world",segment.from_grid)
	var target:Vector2=_registry.call("grid_to_world",segment.to_grid)
	var from_tile=_registry.call("get_tile_at_grid",segment.from_grid)
	var to_tile=_registry.call("get_tile_at_grid",segment.to_grid)
	if from_tile==null or to_tile==null or not source.is_finite() or not target.is_finite():return {}
	var explicit_ramps:bool=from_tile.explicit_hex_ramps and to_tile.explicit_hex_ramps
	var shared:=0.0
	if explicit_ramps:
		shared=TILE.endpoint_height_for_registry(from_tile,segment.to_grid,bool(_registry.call("is_walkable",segment.from_grid)))
		var other:float=TILE.endpoint_height_for_registry(to_tile,segment.from_grid,bool(_registry.call("is_walkable",segment.to_grid)))
		if not is_finite(shared) or not is_finite(other) or not is_equal_approx(shared,other):return {}
	return {"source_world":source,"target_world":target,"source_height":TILE.stand_height(from_tile),"target_height":TILE.stand_height(to_tile),"shared_height":shared,"explicit_ramps":explicit_ramps}


## Batch stop: any remaining trajectory depending on a now held cell joins it.
func stop_units(unit_ids: PackedStringArray, reason: String) -> Dictionary:
	if not _is_configured() or reason.strip_edges().is_empty():return _reject("invalid_stop_context")
	for id in unit_ids:
		if not _units_by_id.has(id):return _reject("unit_not_admitted",id)
	var future_owners:Dictionary={}
	for id in _segments_by_unit_id:
		for interval in PLANNER._hex_timeline(id,_units_by_id[id].grid,_segments_by_unit_id[id],_tick):
			if not future_owners.has(interval.grid):future_owners[interval.grid]={}
			future_owners[interval.grid][id]=true
	var affected:Dictionary={}
	var queue:Array=[]
	for id in unit_ids:
		if not affected.has(id):affected[id]=true;queue.append(id)
	var cursor:=0
	while cursor<queue.size():
		var grid:Vector2i=_units_by_id[queue[cursor]].grid
		cursor+=1
		for id in future_owners.get(grid,{}):
			if not affected.has(id):affected[id]=true;queue.append(id)
	var ids:Array=affected.keys()
	ids.sort()
	var staged_centers:Dictionary={}
	for id in ids:
		if _centering_by_unit_id.has(id) or not _segments_by_unit_id.has(id):continue
		var pose:Dictionary=get_motion_projection(id,0.0)
		if pose.is_empty():return _reject("invalid_motion_projection",id)
		for segment in _segments_by_unit_id[id]:
			if int(segment.start_tick)>_tick or _tick>=int(segment.start_tick)+int(segment.duration_ticks):continue
			var progress:float=float(_tick-int(segment.start_tick))/float(segment.duration_ticks)
			var offset:Vector2=Vector2(segment.from_grid).lerp(Vector2(segment.to_grid),progress)-Vector2(_units_by_id[id].grid)
			if offset.is_zero_approx():break
			var duration:int=_tick-int(segment.start_tick) if _units_by_id[id].grid==segment.from_grid else int(segment.start_tick)+int(segment.duration_ticks)-_tick
			staged_centers[id]={"offset_axial":offset,"stand_height_logical":pose.stand_height_logical,"start_tick":_tick,"duration_ticks":duration}
			break
	var events:Array[Dictionary]=[]
	for id in ids:
		if not _segments_by_unit_id.has(id):continue
		_segments_by_unit_id.erase(id)
		_motion_geometry_by_unit_id.erase(id)
		if staged_centers.has(id):_centering_by_unit_id[id]=staged_centers[id]
		events.append({"event_type":"hex_route_cancelled","unit_id":id,"reason":reason if unit_ids.has(id) else "dependency_stop","tick":_tick})
	if not events.is_empty():
		_revision+=1
		for event in events:_units_by_id[event.unit_id].state_revision=_revision
	_prune_corridor_grants()
	return {"ok":true,"affected_unit_ids":ids,"events":events}


func release_unit(unit_id: String, _reason: String) -> void:
	if _admission_id_by_unit.has(unit_id):cancel_admission_group(_admission_id_by_unit[unit_id],_reason if not _reason.strip_edges().is_empty() else "unit_released")
	if not _units_by_id.has(unit_id):
		return
	var grid: Vector2i = _units_by_id[unit_id]["grid"]
	_occupant_by_grid.erase(grid)
	_units_by_id.erase(unit_id)
	_segments_by_unit_id.erase(unit_id)
	_centering_by_unit_id.erase(unit_id)
	_motion_geometry_by_unit_id.erase(unit_id)
	for grant in _corridor_grants:
		grant.unit_ids.erase(unit_id)
	_prune_corridor_grants()
	_revision += 1


## Respawn moves an existing claim without ever exposing a release/admit gap.
## It cancels only this member's promises, never another cohort member's route.
func relocate_unit(unit_id:String,target:Vector2i,expected_revision:int)->Dictionary:
	if not _is_configured() or expected_revision!=_revision:return _reject("respawn_revision_conflict")
	if not _units_by_id.has(unit_id) or _admission_id_by_unit.has(unit_id):return _reject("respawn_unit_unavailable",unit_id)
	if _occupant_by_grid.has(target) and _occupant_by_grid[target]!=unit_id:return _reject("cell_occupied",unit_id)
	if _admission_slots_by_grid.has(target):return _reject("cell_reserved",unit_id)
	if not bool(_registry.call("is_walkable",target)):return _reject("cell_unwalkable",unit_id)
	var tile=_registry.call("get_tile_at_grid",target)
	if tile==null or not tile.is_valid() or not is_finite(float(_registry.call("get_stand_height_at",target))):return _reject("invalid_respawn_tile",unit_id)
	for id in _segments_by_unit_id:
		if id==unit_id:continue
		for segment in _segments_by_unit_id[id]:
			if int(segment.start_tick)+int(segment.duration_ticks)>_tick and target in [segment.from_grid,segment.to_grid]:return _reject("cell_reserved",unit_id)
	var source:Vector2i=_units_by_id[unit_id].grid
	for grant in _corridor_grants:
		# The unchanged, already held field grants no new passage access. Actual
		# foreign edge promises above remain hard blockers even in this case.
		if target==source or not grant.cells.has(target):continue
		for member in grant.unit_ids:
			if member!=unit_id:return _reject("cell_reserved",unit_id)
	_occupant_by_grid.erase(source)
	_occupant_by_grid[target]=unit_id
	_units_by_id[unit_id].grid=target
	_units_by_id[unit_id].movement_state={"moving":false}
	_segments_by_unit_id.erase(unit_id)
	_centering_by_unit_id.erase(unit_id)
	_motion_geometry_by_unit_id.erase(unit_id)
	for grant in _corridor_grants:grant.unit_ids.erase(unit_id)
	_prune_corridor_grants()
	_revision+=1
	_units_by_id[unit_id].state_revision=_revision
	return {"ok":true,"grid":target,"revision":_revision}


## Only the owning SimulationRoot commits accepted runtime intents here.
func commit_facing(unit_id: String, direction: int) -> bool:
	if not _is_configured() or not _units_by_id.has(unit_id) or direction < 0 or direction > 5:
		return false
	if int(_units_by_id[unit_id]["facing_dir"]) == direction:
		return true
	_revision += 1
	_units_by_id[unit_id]["facing_dir"] = direction
	_units_by_id[unit_id]["state_revision"] = _revision
	return true


func commit_plan(plan: Dictionary, expected_revision: int) -> Dictionary:
	if not _is_configured():
		return _reject("not_configured")
	if expected_revision != _revision or typeof(plan.get("expected_revision")) != TYPE_INT or int(plan.expected_revision) != _revision:
		return _reject("revision_conflict")
	if typeof(plan.get("terrain_revision")) != TYPE_INT or int(plan.terrain_revision) != _terrain_revision():
		return _reject("terrain_revision_conflict")
	if typeof(plan.get("ok")) != TYPE_BOOL or not plan.ok or not plan.get("accepted_steps") is Array or not plan.get("corridor_grants") is Array:
		return _reject("invalid_plan")
	if plan.accepted_steps.size() > 48:
		return _reject("plan_budget_exceeded")
	var schedules: Dictionary = _segments_by_unit_id.duplicate(true)
	for id in _units_by_id:
		if not schedules.has(id): schedules[id] = []
	var added_by_unit: Dictionary = {}
	var additions: Dictionary = {}
	for value in plan.accepted_steps:
		if not value is Dictionary or not PLANNER._hex_valid_segment(value):
			return _reject("invalid_segment")
		var segment: Dictionary = value
		if _admission_slots_by_grid.has(segment.from_grid) or _admission_slots_by_grid.has(segment.to_grid):return _reject("admission_reserved",segment.unit_id)
		var id: String = segment.unit_id
		if not _units_by_id.has(id) or String(segment.command_id).strip_edges().is_empty() or int(segment.start_tick) < _tick:
			return _reject("invalid_segment_context",id)
		if int(segment.start_tick)>MAX_TICK-int(segment.duration_ticks):
			return _reject("segment_outside_clock",id)
		var centering:Dictionary=_centering_by_unit_id.get(id,{})
		if not centering.is_empty() and int(segment.start_tick)<int(centering.start_tick)+int(centering.duration_ticks):return _reject("centering_in_progress",id)
		added_by_unit[id] = int(added_by_unit.get(id,0))+1
		if int(added_by_unit[id]) > 3 or added_by_unit.size() > 16:
			return _reject("plan_budget_exceeded",id)
		schedules[id].append(segment.duplicate(true))
		if not additions.has(id):additions[id]=[]
		additions[id].append(segment)
	for id in schedules:
		schedules[id].sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.start_tick<b.start_tick)
		if not PLANNER._hex_valid_schedule(schedules[id],_units_by_id[id].grid,_tick,_registry):
			return _reject("invalid_schedule",id)
		var future_count := 0
		for segment in schedules[id]:
			if int(segment.handoff_tick)>_tick: future_count+=1
		if future_count>3:
			return _reject("horizon_exceeded",id)
	var index: Dictionary = PLANNER._hex_index(_units_by_id,schedules,_tick)
	for id in _units_by_id:
		var conflict: String = PLANNER._hex_conflict(id,_units_by_id[id].grid,schedules[id],_tick,index)
		if not conflict.is_empty(): return _reject(conflict,id)
	for id in additions:
		var conflict: String = PLANNER._hex_grant_conflict(id,additions[id],_corridor_grants)
		if not conflict.is_empty():return _reject(conflict,id)
	var grants_result := _validate_grants(plan.corridor_grants,schedules)
	if not grants_result.ok: return grants_result
	for grant in plan.corridor_grants:
		for grid in grant.cells:
			if _admission_slots_by_grid.has(grid):return _reject("admission_reserved")
	var policy_result := _validate_new_corridor_policy(additions,plan.corridor_grants)
	if not policy_result.ok:return policy_result
	for id in additions:
		var conflict: String = PLANNER._hex_grant_conflict(id,additions[id],plan.corridor_grants)
		if not conflict.is_empty():return _reject(conflict,id)
	var next_grants: Array[Dictionary] = []
	for grant in plan.corridor_grants: next_grants.append(grant.duplicate(true))
	var staged_geometry:Dictionary={}
	for id in additions:
		staged_geometry[id]={}
		for segment in additions[id]:
			var geometry:=_build_motion_geometry(segment)
			if geometry.is_empty():return _reject("invalid_motion_geometry",id)
			staged_geometry[id][int(segment.start_tick)]=geometry
	var changed: bool = not plan.accepted_steps.is_empty() or next_grants != _corridor_grants
	var nonempty: Dictionary = {}
	for id in schedules:
		if not schedules[id].is_empty():nonempty[id]=schedules[id]
	_segments_by_unit_id = nonempty
	_corridor_grants = next_grants
	for id in staged_geometry:
		if not _motion_geometry_by_unit_id.has(id):_motion_geometry_by_unit_id[id]={}
		_motion_geometry_by_unit_id[id].merge(staged_geometry[id])
	if changed: _revision+=1
	return {"ok":true,"revision":_revision,"committed":changed}


func _validate_grants(grants: Array, schedules: Dictionary) -> Dictionary:
	for value in grants:
		if not value is Dictionary or not value.get("cells") is Array or not value.get("unit_ids") is Array:
			return _reject("invalid_corridor_grant")
		var grant: Dictionary = value
		var max_cells:int=int(_registry.call("get_tile_count")) if _registry.has_method("get_hex_corridor_topology") and _registry.has_method("get_tile_count") else 64
		if grant.cells.size()<2 or grant.cells.size()>max_cells or grant.unit_ids.is_empty():
			return _reject("invalid_corridor_grant")
		var geometry_issue := _corridor_geometry_issue(grant.cells,true)
		if not geometry_issue.is_empty():return _reject(geometry_issue)
		var members: Dictionary = {}
		var cohort_direction := 0
		for id in grant.unit_ids:
			if not id is String or not _units_by_id.has(id) or members.has(id):
				return _reject("invalid_corridor_members")
			members[id]=true
			var direction: int = PLANNER._hex_direction(schedules.get(id,[]),grant.cells)
			if direction!=0:
				if cohort_direction!=0 and cohort_direction!=direction:return _reject("corridor_direction_conflict")
				cohort_direction=direction
		if not PLANNER._hex_grant_active(grant,_units_by_id,schedules):
			return _reject("inactive_corridor_grant")
	for old in _corridor_grants:
		if not PLANNER._hex_grant_active(old,_units_by_id,schedules):continue
		var retained := false
		for grant in grants:
			if grant.cells==old.cells and grant.unit_ids==old.unit_ids:
				retained=true
				break
		if not retained:return _reject("active_corridor_grant_lost")
	return {"ok":true}


func _corridor_geometry_issue(corridor_cells: Array, require_complete: bool = false) -> String:
	var cells: Dictionary = {}
	for i in range(corridor_cells.size()):
		var grid: Variant = corridor_cells[i]
		if not grid is Vector2i or cells.has(grid) or not bool(_registry.call("is_walkable",grid)):
			return "invalid_corridor_cells"
		if i>0 and not PLANNER._hex_legal_step(corridor_cells[i-1],grid,_registry):
			return "invalid_corridor_cells"
		if _registry.has_method("get_legal_hex_neighbors"):
			if _registry.call("get_legal_hex_neighbors",grid).size()>2:return "corridor_is_junction"
		else:
			var hex=preload("res://scripts/terrain/hex_grid.gd")
			var degree:=0
			for direction in hex.DIRECTIONS:
				if PLANNER._hex_legal_step(grid,grid+direction,_registry):degree+=1
			if degree>2:return "corridor_is_junction"
		cells[grid]=true
	if _registry.has_method("get_hex_corridor_topology"):
		var proof:Dictionary=_registry.call("get_hex_corridor_topology",[corridor_cells[0]],0)
		if not proof.get("ok",false) or proof.get("registry_id")!=_registry.get_instance_id() or proof.get("terrain_revision")!=_terrain_revision():return "invalid_corridor_topology"
		if not proof.get("query_complete",false):
			return "corridor_topology_pending" if require_complete else ""
		for component in proof.corridors:
			if component.directed and component.cells==corridor_cells:return ""
		return "incomplete_corridor_component"
	return ""

func _validate_new_corridor_policy(additions: Dictionary, grants: Array) -> Dictionary:
	var queries: Array = []
	for segments in additions.values():
		for segment in segments:queries.append({"path_grid_points":[segment.from_grid,segment.to_grid]})
	var topology:Dictionary=PLANNER._hex_query_corridors(queries,_registry,0)
	if not topology.ok:return _reject("invalid_corridor_topology")
	if not topology.complete:return _reject("corridor_topology_pending")
	var corridors:Array=topology.corridors
	for cells in corridors:
		var effective_old: Array = []
		for old in _corridor_grants:
			var intersects := false
			for grid in old.cells:
				if cells.has(grid):intersects=true;break
			if intersects:effective_old.append({"cells":cells,"unit_ids":old.unit_ids})
		var accepted_traffic: Array = []
		var traffic_ids: Array = []
		for id in additions:
			if not PLANNER._hex_segments_touch(additions[id],cells):continue
			var conflict: String = PLANNER._hex_grant_conflict(id,additions[id],effective_old)
			if not conflict.is_empty():return _reject(conflict,id)
			var clearing_only: bool = not effective_old.is_empty()
			for old in effective_old:
				if old.unit_ids.has(id):clearing_only=false
			if clearing_only:continue
			var covered := false
			for grant in grants:
				if not grant.unit_ids.has(id):continue
				var whole := true
				for grid in cells:
					if not grant.cells.has(grid):whole=false;break
				if whole:covered=true;break
			if not covered:return _reject("corridor_grant_missing",id)
			conflict=PLANNER._hex_new_direction_conflict(additions[id],accepted_traffic,[cells])
			if not conflict.is_empty():return _reject(conflict,id)
			accepted_traffic.append_array(additions[id])
			traffic_ids.append(id)
		if not traffic_ids.is_empty():
			var common_grant:=false
			for grant in grants:
				var covers_all:=true
				for id in traffic_ids:
					if not grant.unit_ids.has(id):covers_all=false
				for grid in cells:
					if not grant.cells.has(grid):covers_all=false
				if covers_all:common_grant=true;break
			if not common_grant:return _reject("corridor_cohort_split")
	return {"ok":true}


## Pure logical tick kernel; visible actor projection is wired separately.
func advance_tick(tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not _is_configured() or tick<=_tick or tick>MAX_TICK:
		return events
	var due: Array[Dictionary] = []
	if _reservation_terrain_revision != _terrain_revision():
		for admission_id in _admission_by_id.keys():
			if not _admission_access_valid(_admission_by_id[admission_id]):
				var cancelled:Dictionary=cancel_admission_group(admission_id,"terrain_changed")
				events.append({"event_type":"hex_admission_cancelled","admission_id":admission_id,"unit_ids":cancelled.released_unit_ids,"reason":"terrain_changed"})
		_topology_revalidation_pending=not _corridor_grants.is_empty()
		var invalid_ids:=PackedStringArray()
		for id in _segments_by_unit_id:
			for segment in _segments_by_unit_id[id]:
				if not PLANNER._hex_legal_step(segment.from_grid,segment.to_grid,_registry):
					invalid_ids.append(id)
					break
		if not invalid_ids.is_empty():
			var stopped:=stop_units(invalid_ids,"terrain_changed")
			if stopped.ok:events.append_array(stopped.events)
			else:
				# Corrupt projection data cannot authorize an illegal field handoff.
				for id in _segments_by_unit_id:events.append({"event_type":"hex_route_cancelled","unit_id":id,"reason":"invalid_motion_geometry"})
				_segments_by_unit_id.clear()
				_motion_geometry_by_unit_id.clear()
				_corridor_grants.clear()
				_revision+=1
		# Remaining legal routes adopt the current canonical terrain/metric profile.
		for id in _segments_by_unit_id:
			var geometry_by_start:Dictionary={}
			for segment in _segments_by_unit_id[id]:geometry_by_start[int(segment.start_tick)]=_build_motion_geometry(segment)
			_motion_geometry_by_unit_id[id]=geometry_by_start
		_reservation_terrain_revision=_terrain_revision()
	if _topology_revalidation_pending:
		var retained: Array[Dictionary] = []
		var unresolved:=false
		for grant in _corridor_grants:
			var issue:=_corridor_geometry_issue(grant.cells,true)
			if issue=="corridor_topology_pending":
				retained.append(grant)
				unresolved=true
			elif issue.is_empty():retained.append(grant)
			else:events.append({"event_type":"hex_corridor_invalidated","reason":"terrain_changed","cells":grant.cells.duplicate()})
		if retained.size()!=_corridor_grants.size():
			_corridor_grants=retained
			_revision+=1
		_topology_revalidation_pending=unresolved
	for segments in _segments_by_unit_id.values():
		for segment in segments:
			if _tick<int(segment.handoff_tick) and int(segment.handoff_tick)<=tick:
				due.append({"kind":0,"tick":int(segment.handoff_tick),"segment":segment})
			var end: int = int(segment.start_tick)+int(segment.duration_ticks)
			if _tick<end and end<=tick:due.append({"kind":1,"tick":end,"segment":segment})
	due.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if a.tick!=b.tick:return a.tick<b.tick
		if a.kind!=b.kind:return a.kind<b.kind
		return String(a.segment.unit_id)<String(b.segment.unit_id))
	var cursor := 0
	while cursor<due.size():
		var time: int = due[cursor].tick
		var changes: Array = []
		var finished: Array = []
		while cursor<due.size() and int(due[cursor].tick)==time:
			if int(due[cursor].kind)==0:changes.append(due[cursor].segment)
			else:finished.append(due[cursor].segment)
			cursor+=1
		# Remove every source before publishing targets: cycles and joint column
		# handoffs never expose an intermediate duplicate occupancy.
		for segment in changes:_occupant_by_grid.erase(segment.from_grid)
		if not changes.is_empty():_revision+=1
		for segment in changes:
			var id: String = segment.unit_id
			_units_by_id[id].grid=segment.to_grid
			_units_by_id[id].state_revision=_revision
			_occupant_by_grid[segment.to_grid]=id
			events.append({"event_type":"hex_field_changed","unit_id":id,"command_id":segment.command_id,"from_grid":segment.from_grid,"to_grid":segment.to_grid,"tick":time})
		for segment in finished:
			events.append({"event_type":"hex_segment_completed","unit_id":segment.unit_id,"command_id":segment.command_id,"tick":time})
	var expired := false
	for id in _segments_by_unit_id.keys():
		var live: Array = []
		for segment in _segments_by_unit_id[id]:
			if int(segment.start_tick)+int(segment.duration_ticks)>tick:live.append(segment)
			else:
				expired=true
				_motion_geometry_by_unit_id.get(id,{}).erase(int(segment.start_tick))
		if live.is_empty():
			_segments_by_unit_id.erase(id)
			_motion_geometry_by_unit_id.erase(id)
		else:_segments_by_unit_id[id]=live
	for id in _centering_by_unit_id.keys():
		var centering:Dictionary=_centering_by_unit_id[id]
		var end:int=int(centering.start_tick)+int(centering.duration_ticks)
		if end>tick:continue
		_centering_by_unit_id.erase(id)
		expired=true
		events.append({"event_type":"hex_centering_completed","unit_id":id,"tick":end})
	_tick=tick
	if expired:_revision+=1
	_prune_corridor_grants()
	return events


func can_block_cells(grids:Array,ignore_admission_id:String="") -> Dictionary:
	if not _is_configured():return _reject("not_configured")
	if grids.size()>64:return _reject("cell_query_budget")
	var wanted:Dictionary={}
	for value in grids:
		if typeof(value)!=TYPE_VECTOR2I:return _reject("invalid_cell")
		if _registry.call("get_tile_at_grid",value)==null:return _reject("unknown_cell")
		wanted[value]=true
	var blocked:Dictionary={}
	for grid in wanted:
		if _occupant_by_grid.has(grid):_record_block_claim(blocked,grid,"occupied",PackedStringArray([String(_occupant_by_grid[grid])]))
		var slot:Dictionary=_admission_slots_by_grid.get(grid,{})
		if not slot.is_empty() and slot.admission_id!=ignore_admission_id:_record_block_claim(blocked,grid,"admission_slot",PackedStringArray([String(slot.unit_id)]))
	for id in _segments_by_unit_id:
		for segment in _segments_by_unit_id[id]:
			if int(segment.start_tick)+int(segment.duration_ticks)<=_tick:continue
			for grid in [segment.from_grid,segment.to_grid]:
				if wanted.has(grid):_record_block_claim(blocked,grid,"segment",PackedStringArray([String(id)]))
	for grant in _corridor_grants:
		if not PLANNER._hex_grant_active(grant,_units_by_id,_segments_by_unit_id):continue
		for grid in wanted:
			if grant.cells.has(grid):_record_block_claim(blocked,grid,"corridor_grant",PackedStringArray(grant.unit_ids))
	var result:Array=[]
	for grid in wanted:
		if blocked.has(grid):result.append(blocked[grid])
	return {"ok":true,"can_block":result.is_empty(),"blocked_cells":result}


func _record_block_claim(blocked:Dictionary,grid:Vector2i,reason:String,ids:PackedStringArray) -> void:
	var entry:Dictionary=blocked.get(grid,{"grid":grid,"reasons":PackedStringArray(),"unit_ids":PackedStringArray()})
	var reasons:PackedStringArray=entry.reasons
	if not reasons.has(reason):reasons.append(reason)
	var units:PackedStringArray=entry.unit_ids
	for id in ids:
		if not units.has(id):units.append(id)
	units.sort()
	entry.reasons=reasons
	entry.unit_ids=units
	blocked[grid]=entry


func _cell_has_future_claim(grid: Vector2i) -> bool:
	for segments in _segments_by_unit_id.values():
		for segment in segments:
			if segment.to_grid==grid and int(segment.handoff_tick)>_tick:return true
	return false


func _all_segments() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array = _segments_by_unit_id.keys()
	ids.sort()
	for id in ids:
		for segment in _segments_by_unit_id[id]:result.append(segment.duplicate(true))
	return result


func _prune_corridor_grants() -> void:
	var live: Array[Dictionary] = []
	for grant in _corridor_grants:
		if not grant.unit_ids.is_empty() and PLANNER._hex_grant_active(grant,_units_by_id,_segments_by_unit_id):live.append(grant)
	if live!=_corridor_grants:
		_corridor_grants=live
		_revision+=1


func clear() -> void:
	_restore_binding_epoch += 1
	_registry = null
	_map_id = ""
	_tick = 0
	_units_by_id.clear()
	_occupant_by_grid.clear()
	_segments_by_unit_id.clear()
	_centering_by_unit_id.clear()
	_motion_geometry_by_unit_id.clear()
	_corridor_grants.clear()
	_admission_by_id.clear()
	_admission_slots_by_grid.clear()
	_admission_id_by_unit.clear()
	_reservation_terrain_revision=-1
	_topology_revalidation_pending=false
	_revision += 1


func _is_configured() -> bool:
	return is_instance_valid(_registry) and not _map_id.is_empty() and _registry.has_method("get_grid_topology") and String(_registry.call("get_grid_topology"))==TOPOLOGY


## AP7 PART ONLY: canonical host save values, never a peer/planning snapshot.
## Pending deployment still requires a coordinated admission schema.
func export_state() -> Dictionary:
	var blocked := _save_context_issue()
	if not blocked.is_empty(): return _reject(blocked)
	if _units_by_id.size()>64: return _reject("ground_save_unit_budget")
	var units:Array=[]
	var centers:Array=[]
	var ids:Array=_units_by_id.keys();ids.sort()
	for id in ids:
		var unit:Dictionary=_units_by_id[id]
		units.append({"unit_id":id,"grid":[unit.grid.x,unit.grid.y],"facing_dir":unit.facing_dir,"posture_key":unit.posture_key})
		if _centering_by_unit_id.has(id):
			var center:Dictionary=_centering_by_unit_id[id]
			centers.append({"unit_id":id,"offset_axial":[center.offset_axial.x,center.offset_axial.y],"stand_height_logical":center.stand_height_logical,"start_tick":center.start_tick,"duration_ticks":center.duration_ticks})
	var segments:Array=[]
	for segment in _all_segments():
		segments.append({"unit_id":segment.unit_id,"command_id":segment.command_id,"from_grid":[segment.from_grid.x,segment.from_grid.y],"to_grid":[segment.to_grid.x,segment.to_grid.y],"start_tick":segment.start_tick,"duration_ticks":segment.duration_ticks,"handoff_tick":segment.handoff_tick})
	var commitments:Array=[]
	for grant in _corridor_grants:
		if not PLANNER._hex_grant_active(grant,_units_by_id,_segments_by_unit_id):continue
		var cells:Array=[]
		for cell in grant.cells:cells.append([cell.x,cell.y])
		var members:Array=grant.unit_ids.duplicate();members.sort()
		commitments.append({"cells":cells,"unit_ids":members})
	commitments.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return JSON.stringify(a.cells)<JSON.stringify(b.cells))
	var state:Dictionary={"schema":"hex_ground_v2","passage_commitments":commitments,"map_id":_map_id,"topology":TOPOLOGY,"tick":_tick,"terrain_revision":_terrain_revision(),"units":units,"active_segments":segments,"centering":centers}
	var checked:Dictionary=_save_candidate(state)
	return state if checked.ok else _reject(String(checked.reason))


func restore_state(state:Dictionary) -> Dictionary:
	var blocked := _save_context_issue()
	if not blocked.is_empty(): return _reject(blocked)
	var checked:Dictionary=_save_candidate(state)
	if not checked.ok:return _reject(String(checked.reason))
	var candidate=checked.candidate
	# All validation/geometry construction finished. Preserve this owner object and
	# registry binding; publish no signals and invoke no fallible owner operation.
	_tick=candidate._tick
	_units_by_id=candidate._units_by_id
	_occupant_by_grid=candidate._occupant_by_grid
	_segments_by_unit_id=candidate._segments_by_unit_id
	_centering_by_unit_id=candidate._centering_by_unit_id
	_motion_geometry_by_unit_id=candidate._motion_geometry_by_unit_id
	_corridor_grants=candidate._corridor_grants
	_reservation_terrain_revision=candidate._reservation_terrain_revision
	_topology_revalidation_pending=false
	_revision+=1
	for id in _units_by_id:_units_by_id[id].state_revision=_revision
	return {"ok":true,"unit_count":_units_by_id.size(),"tick":_tick,"revision":_revision}


func _save_context_issue() -> String:
	if not _is_configured():return "ground_save_not_configured"
	if _reservation_terrain_revision != _terrain_revision():return "ground_save_terrain_revalidation_pending"
	if not _admission_by_id.is_empty() or not _admission_slots_by_grid.is_empty() or not _admission_id_by_unit.is_empty():return "ground_save_pending_admission"
	if _topology_revalidation_pending:return "ground_save_topology_pending"
	return ""


## Cold, trusted inprocess preparation. The handle contains no writable patch.
func prepare_restore_state(state:Dictionary,target_registry:Node=null)->Dictionary:
	var blocked:=_save_context_issue()
	if not blocked.is_empty():return _reject(blocked)
	for key in _prepared_restores.keys():
		var record:Dictionary=_prepared_restores[key]
		if record.handle.get_ref()==null or record.epoch!=_restore_binding_epoch:_prepared_restores.erase(key)
	if _prepared_restores.size()>=32:return _reject("ground_restore_prepare_capacity")
	var source_stamp:=_restore_value_stamp()
	var checked:Dictionary=_save_candidate(state,target_registry)
	if not checked.ok:return checked
	if source_stamp!=_restore_value_stamp():return _reject("ground_restore_context_changed")
	var candidate=checked.candidate
	var patch:Dictionary={"tick":candidate._tick,"units":candidate._units_by_id.duplicate(true),
		"occupants":candidate._occupant_by_grid.duplicate(true),"segments":candidate._segments_by_unit_id.duplicate(true),
		"centering":candidate._centering_by_unit_id.duplicate(true),"geometry":candidate._motion_geometry_by_unit_id.duplicate(true),
		"grants":candidate._corridor_grants.duplicate(true),"terrain_revision":candidate._reservation_terrain_revision,
		"revision":_revision+1}
	for id in patch.units:patch.units[id].state_revision=patch.revision
	var handle:=PreparedGroundRestore.new()
	_prepared_restores[handle.get_instance_id()]={"handle":weakref(handle),"epoch":_restore_binding_epoch,
		"source_stamp":source_stamp,"candidate":candidate,"target_stamp":candidate._restore_value_stamp(),"patch":patch}
	return {"ok":true,"prepared":handle}


func get_prepared_restore_ground(prepared:RefCounted)->RefCounted:
	if not validate_prepared_restore(prepared).ok:return null
	return _prepared_restores[prepared.get_instance_id()].candidate


func validate_prepared_restore(prepared:RefCounted)->Dictionary:
	if prepared==null or not _prepared_restores.has(prepared.get_instance_id()):return _reject("unknown_ground_restore")
	var record:Dictionary=_prepared_restores[prepared.get_instance_id()]
	if record.handle.get_ref()!=prepared or record.epoch!=_restore_binding_epoch:return _reject("ground_restore_owner_changed")
	var blocked:=_save_context_issue()
	if not blocked.is_empty():return _reject(blocked)
	if record.source_stamp!=_restore_value_stamp():return _reject("ground_restore_context_changed")
	if record.target_stamp!=record.candidate._restore_value_stamp():return _reject("ground_restore_candidate_changed")
	return {"ok":true,"prepared_id":prepared.get_instance_id()}


func publish_prepared_restore(prepared:RefCounted)->Dictionary:
	if prepared!=null and _prepared_restores.has(prepared.get_instance_id()) and _prepared_restores[prepared.get_instance_id()].candidate._registry!=_registry:return _reject("ground_restore_joint_publish_required")
	var validation:=validate_prepared_restore(prepared)
	if not validation.ok:return validation
	return _publish_prepared_restore(prepared,validation)


func _publish_prepared_restore(prepared:RefCounted,_validation:Dictionary)->Dictionary:
	# Root-private tail: all owners validated, no callbacks or fallible checks here.
	var patch:Dictionary=_prepared_restores[prepared.get_instance_id()].patch
	_tick=patch.tick
	_units_by_id=patch.units
	_occupant_by_grid=patch.occupants
	_segments_by_unit_id=patch.segments
	_centering_by_unit_id=patch.centering
	_motion_geometry_by_unit_id=patch.geometry
	_corridor_grants=patch.grants
	_reservation_terrain_revision=patch.terrain_revision
	_topology_revalidation_pending=false
	_revision=patch.revision
	_prepared_restores.erase(prepared.get_instance_id())
	return {"ok":true,"unit_count":_units_by_id.size(),"tick":_tick,"revision":_revision}


func _restore_value_stamp()->String:
	# Full value fingerprint also catches no-revision pending admission changes.
	return var_to_bytes([get_instance_id(),_restore_binding_epoch,
		_registry.get_instance_id() if is_instance_valid(_registry) else 0,_map_id,_revision,_tick,_terrain_revision(),
		_units_by_id,_occupant_by_grid,_segments_by_unit_id,_corridor_grants,_reservation_terrain_revision,
		_topology_revalidation_pending,_centering_by_unit_id,_motion_geometry_by_unit_id,
		_admission_by_id,_admission_slots_by_grid,_admission_id_by_unit]).hex_encode().sha256_text()


func _save_candidate(state:Dictionary,target_registry:Node=null) -> Dictionary:
	var registry:Node=target_registry if target_registry!=null else _registry
	var keys:Array=["schema","map_id","topology","tick","terrain_revision","units","active_segments","centering"]
	if state.get("schema")=="hex_ground_v2":keys.append("passage_commitments")
	elif state.get("schema")!="hex_ground_v1":return _reject("invalid_ground_save_schema")
	if not _save_keys(state,keys):return _reject("invalid_ground_save_schema")
	if not _save_id(state.map_id) or state.map_id!=_map_id or state.topology!=TOPOLOGY:return _reject("ground_save_map_mismatch")
	if not _save_integer(state.tick,0,MAX_TICK) or not _save_integer(state.terrain_revision,0,MAX_TICK) or int(state.terrain_revision)!=int(registry.call("get_revision")):return _reject("ground_save_terrain_context")
	if typeof(state.units)!=TYPE_ARRAY or state.units.size()>64 or typeof(state.active_segments)!=TYPE_ARRAY or state.active_segments.size()>256 or typeof(state.centering)!=TYPE_ARRAY or state.centering.size()>64:return _reject("ground_save_budget")
	var candidate=get_script().new()
	candidate.configure(registry,_map_id,int(state.tick))
	var placements:Array[Dictionary]=[]
	for value in state.units:
		if not _save_keys(value,["unit_id","grid","facing_dir","posture_key"]) or not _save_id(value.unit_id) or not _save_id(value.posture_key) or not _save_integer(value.facing_dir,0,5):return _reject("invalid_ground_save_unit")
		var cell:Dictionary=_save_grid(value.grid)
		if not cell.ok:return cell
		placements.append({"unit_id":String(value.unit_id),"grid":cell.grid,"facing_dir":int(value.facing_dir),"posture_key":String(value.posture_key)})
	var admitted:Dictionary=candidate.admit_units(placements)
	if not admitted.ok:return _reject("ground_save_"+String(admitted.reason))
	var schedules:Dictionary={}
	for id in candidate._units_by_id:schedules[id]=[]
	for value in state.active_segments:
		if not _save_keys(value,["unit_id","command_id","from_grid","to_grid","start_tick","duration_ticks","handoff_tick"]) or not _save_id(value.unit_id) or not _save_id(value.command_id) or not schedules.has(value.unit_id):return _reject("invalid_ground_save_segment")
		for key in ["start_tick","handoff_tick"]:
			if not _save_integer(value[key],0,MAX_TICK):return _reject("invalid_ground_save_segment_time")
		if not _save_integer(value.duration_ticks,1,1000000) or int(value.start_tick)>MAX_TICK-int(value.duration_ticks):return _reject("invalid_ground_save_segment_time")
		var source:Dictionary=_save_grid(value.from_grid);var target:Dictionary=_save_grid(value.to_grid)
		if not source.ok or not target.ok:return _reject("invalid_ground_save_grid")
		var segment:Dictionary={"unit_id":String(value.unit_id),"command_id":String(value.command_id),"from_grid":source.grid,"to_grid":target.grid,"start_tick":int(value.start_tick),"duration_ticks":int(value.duration_ticks),"handoff_tick":int(value.handoff_tick)}
		if not PLANNER._hex_valid_segment(segment):return _reject("invalid_ground_save_segment")
		schedules[segment.unit_id].append(segment)
		if schedules[segment.unit_id].size()>4:return _reject("ground_save_horizon")
	for value in state.centering:
		if not _save_keys(value,["unit_id","offset_axial","stand_height_logical","start_tick","duration_ticks"]) or not _save_id(value.unit_id) or not candidate._units_by_id.has(value.unit_id) or candidate._centering_by_unit_id.has(value.unit_id):return _reject("invalid_ground_save_centering")
		if not _save_integer(value.start_tick,0,int(state.tick)) or not _save_integer(value.duration_ticks,1,1000000) or int(value.start_tick)>MAX_TICK-int(value.duration_ticks) or int(value.start_tick)+int(value.duration_ticks)<=int(state.tick):return _reject("invalid_ground_save_centering_time")
		if typeof(value.offset_axial)!=TYPE_ARRAY or value.offset_axial.size()!=2 or not _save_number(value.offset_axial[0],0.500001) or not _save_number(value.offset_axial[1],0.500001) or not _save_number(value.stand_height_logical,1000000.0):return _reject("invalid_ground_save_centering_offset")
		var offset:=Vector2(float(value.offset_axial[0]),float(value.offset_axial[1]))
		if offset.is_zero_approx() or absf(offset.x+offset.y)>0.500001 or not (is_zero_approx(offset.x) or is_zero_approx(offset.y) or is_zero_approx(offset.x+offset.y)):return _reject("invalid_ground_save_centering_offset")
		candidate._centering_by_unit_id[String(value.unit_id)]={"offset_axial":offset,"stand_height_logical":float(value.stand_height_logical),"start_tick":int(value.start_tick),"duration_ticks":int(value.duration_ticks)}
	for id in schedules:
		schedules[id].sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.start_tick<b.start_tick)
		if not PLANNER._hex_valid_schedule(schedules[id],candidate._units_by_id[id].grid,candidate._tick,registry):return _reject("invalid_ground_save_schedule",id)
		var future_count:=0
		for segment in schedules[id]:
			if segment.handoff_tick>candidate._tick:future_count+=1
			var center:Dictionary=candidate._centering_by_unit_id.get(id,{})
			if not center.is_empty() and segment.start_tick<int(center.start_tick)+int(center.duration_ticks):return _reject("ground_save_centering_overlap",id)
			var geometry:Dictionary=candidate._build_motion_geometry(segment)
			if geometry.is_empty():return _reject("invalid_ground_save_geometry",id)
			if not candidate._motion_geometry_by_unit_id.has(id):candidate._motion_geometry_by_unit_id[id]={}
			candidate._motion_geometry_by_unit_id[id][segment.start_tick]=geometry
		if future_count>3:return _reject("ground_save_horizon",id)
		if not schedules[id].is_empty():candidate._segments_by_unit_id[id]=schedules[id]
	var index:Dictionary=PLANNER._hex_index(candidate._units_by_id,schedules,candidate._tick)
	for id in schedules:
		var conflict:String=PLANNER._hex_conflict(id,candidate._units_by_id[id].grid,schedules[id],candidate._tick,index)
		if not conflict.is_empty():return _reject("ground_save_"+conflict,id)
	var grants_result:Dictionary=candidate._save_passage_commitments(state.get("passage_commitments",[]),schedules)
	if not grants_result.ok:return grants_result
	# Existing commitments must precede policy: nonmembers may monotonically clear.
	candidate._corridor_grants=grants_result.grants
	for id in schedules:
		var issue:String=PLANNER._hex_grant_conflict(id,schedules[id],candidate._corridor_grants)
		if not issue.is_empty():return _reject("ground_save_"+issue,id)
	var policy:Dictionary=candidate._validate_new_corridor_policy(schedules,candidate._corridor_grants)
	if not policy.ok:return _reject("ground_save_"+String(policy.reason))
	if int(registry.call("get_revision"))!=int(state.terrain_revision):return _reject("ground_save_terrain_context")
	return {"ok":true,"candidate":candidate}


func _save_passage_commitments(values:Variant,schedules:Dictionary) -> Dictionary:
	if typeof(values)!=TYPE_ARRAY or values.size()>64:return _reject("ground_save_passage_budget")
	var grants:Array[Dictionary]=[]
	var occupied:Dictionary={}
	var total:=0
	var remaining_nodes:=64
	for value in values:
		if not _save_keys(value,["cells","unit_ids"]) or typeof(value.cells)!=TYPE_ARRAY or value.cells.size()<2 or typeof(value.unit_ids)!=TYPE_ARRAY or value.unit_ids.is_empty() or value.unit_ids.size()>64:return _reject("invalid_ground_save_passage")
		total+=value.cells.size()
		if total>4096:return _reject("ground_save_passage_budget")
		var cells:Array=[]
		for pair in value.cells:
			var parsed:Dictionary=_save_grid(pair)
			if not parsed.ok or occupied.has(parsed.get("grid")):return _reject("ground_save_passage_overlap")
			cells.append(parsed.grid);occupied[parsed.grid]=true
		var members:Array=[]
		for id in value.unit_ids:
			if not _save_id(id) or not _units_by_id.has(id) or members.has(id):return _reject("invalid_ground_save_passage_member")
			members.append(String(id))
		members.sort()
		if not _registry.has_method("get_hex_corridor_topology"):return _reject("ground_save_passage_topology_missing")
		var proof:Dictionary=_registry.call("get_hex_corridor_topology",[cells[0]],remaining_nodes)
		remaining_nodes=maxi(0,remaining_nodes-int(proof.get("processed_nodes",0)))
		if not proof.get("ok",false) or not proof.get("query_complete",false) or proof.get("registry_id")!=_registry.get_instance_id() or proof.get("terrain_revision")!=_terrain_revision():return _reject("ground_save_passage_topology_pending")
		var whole:=false
		for component in proof.get("corridors",[]):
			if component.get("directed",false) and component.get("cells")==cells:whole=true;break
		if not whole:return _reject("ground_save_passage_incomplete")
		var issue:=_corridor_geometry_issue(cells,true)
		if not issue.is_empty():return _reject("ground_save_"+issue)
		grants.append({"cells":cells,"unit_ids":members})
	var valid:=_validate_grants(grants,schedules)
	if not valid.ok:return _reject("ground_save_"+String(valid.reason))
	return {"ok":true,"grants":grants}


func _save_keys(value:Variant,keys:Array) -> bool:
	if typeof(value)!=TYPE_DICTIONARY or value.size()!=keys.size():return false
	for key in keys:
		if not value.has(key):return false
	return true


func _save_id(value:Variant) -> bool:
	return typeof(value)==TYPE_STRING and not String(value).is_empty() and String(value)==String(value).strip_edges() and String(value).length()<=256


func _save_integer(value:Variant,minimum:int,maximum:int) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==floorf(float(value)) and float(value)>=minimum and float(value)<=maximum


func _save_number(value:Variant,maximum:float) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and absf(float(value))<=maximum


func _save_grid(value:Variant) -> Dictionary:
	if typeof(value)!=TYPE_ARRAY or value.size()!=2 or not _save_integer(value[0],-2147480000,2147480000) or not _save_integer(value[1],-2147480000,2147480000):return _reject("invalid_ground_save_grid")
	return {"ok":true,"grid":Vector2i(int(value[0]),int(value[1]))}


func _terrain_revision() -> int:
	if is_instance_valid(_registry) and _registry.has_method("get_revision"):
		return int(_registry.call("get_revision"))
	return -1


func _reject(reason: String, unit_id: String = "") -> Dictionary:
	return {"ok": false, "reason": reason, "unit_id": unit_id}
