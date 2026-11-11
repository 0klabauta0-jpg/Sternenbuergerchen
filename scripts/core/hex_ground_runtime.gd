class_name HexGroundRuntime
extends RefCounted

## SimulationRoot-owned logical ground state. Registries and views only read it.
## No unit transforms, commands or terrain data are mutated by this helper.
const TOPOLOGY := "hex_axial_v1"
const RESERVATION_SCHEMA_VERSION := 1
const MAX_TICK := 1000000000000
const PLANNER = preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")

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


func admit_units(placements: Array[Dictionary]) -> Dictionary:
	if not _is_configured():
		return _reject("not_configured")
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
		var facing: Variant = placement.get("facing_dir", 0)
		if typeof(facing) != TYPE_INT or int(facing) < 0 or int(facing) > 5:
			return _reject("invalid_facing", unit_id)
		var posture: Variant = placement.get("posture_key", "standing")
		if typeof(posture) != TYPE_STRING or String(posture).strip_edges().is_empty():
			return _reject("invalid_posture", unit_id)
		if _occupant_by_grid.has(grid) or staged_cells.has(grid):
			return _reject("cell_occupied", unit_id)
		if _cell_has_future_claim(grid):
			return _reject("cell_reserved",unit_id)
		if not bool(_registry.call("is_walkable", grid)):
			return _reject("cell_unwalkable", unit_id)
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
		_units_by_id.merge(staged_units)
		_occupant_by_grid.merge(staged_cells)
		_revision += 1
	return {"ok": true, "admitted_unit_ids": staged_units.keys()}


func read_unit(unit_id: String) -> Dictionary:
	if not _is_configured() or not _units_by_id.has(unit_id):
		return {}
	var result: Dictionary = Dictionary(_units_by_id[unit_id]).duplicate(true)
	# Read current terrain revision/height without turning a getter into a mutation.
	result["stand_height_steps2"] = roundi(2.0 * float(_registry.call("get_stand_height_at", result["grid"])))
	result["terrain_revision"] = _terrain_revision()
	result["movement_state"] = {"moving":false}
	for segment in _segments_by_unit_id.get(unit_id,[]):
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
	}


func get_current_tick() -> int:
	return _tick


func release_unit(unit_id: String, _reason: String) -> void:
	if not _units_by_id.has(unit_id):
		return
	var grid: Vector2i = _units_by_id[unit_id]["grid"]
	_occupant_by_grid.erase(grid)
	_units_by_id.erase(unit_id)
	_segments_by_unit_id.erase(unit_id)
	for grant in _corridor_grants:
		grant.unit_ids.erase(unit_id)
	_prune_corridor_grants()
	_revision += 1


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
		var id: String = segment.unit_id
		if not _units_by_id.has(id) or String(segment.command_id).strip_edges().is_empty() or int(segment.start_tick) < _tick:
			return _reject("invalid_segment_context",id)
		if int(segment.start_tick)>MAX_TICK-int(segment.duration_ticks):
			return _reject("segment_outside_clock",id)
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
	var policy_result := _validate_new_corridor_policy(additions,plan.corridor_grants)
	if not policy_result.ok:return policy_result
	for id in additions:
		var conflict: String = PLANNER._hex_grant_conflict(id,additions[id],plan.corridor_grants)
		if not conflict.is_empty():return _reject(conflict,id)
	var next_grants: Array[Dictionary] = []
	for grant in plan.corridor_grants: next_grants.append(grant.duplicate(true))
	var changed: bool = not plan.accepted_steps.is_empty() or next_grants != _corridor_grants
	var nonempty: Dictionary = {}
	for id in schedules:
		if not schedules[id].is_empty():nonempty[id]=schedules[id]
	_segments_by_unit_id = nonempty
	_corridor_grants = next_grants
	_reservation_terrain_revision = _terrain_revision()
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
		_topology_revalidation_pending=not _corridor_grants.is_empty()
		var legal := true
		for segments in _segments_by_unit_id.values():
			for segment in segments:
				if not PLANNER._hex_legal_step(segment.from_grid,segment.to_grid,_registry):legal=false
		if not legal:
			for id in _segments_by_unit_id:
				if not _segments_by_unit_id[id].is_empty():
					events.append({"event_type":"hex_route_cancelled","unit_id":id,"reason":"terrain_changed"})
			_segments_by_unit_id.clear()
			_corridor_grants.clear()
			_topology_revalidation_pending=false
			_revision+=1
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
			else:expired=true
		if live.is_empty():_segments_by_unit_id.erase(id)
		else:_segments_by_unit_id[id]=live
	_tick=tick
	if expired:_revision+=1
	_prune_corridor_grants()
	return events


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
	_registry = null
	_map_id = ""
	_tick = 0
	_units_by_id.clear()
	_occupant_by_grid.clear()
	_segments_by_unit_id.clear()
	_corridor_grants.clear()
	_reservation_terrain_revision=-1
	_topology_revalidation_pending=false
	_revision += 1


func _is_configured() -> bool:
	return is_instance_valid(_registry) and not _map_id.is_empty() and _registry.has_method("get_grid_topology") and String(_registry.call("get_grid_topology"))==TOPOLOGY


func _terrain_revision() -> int:
	if is_instance_valid(_registry) and _registry.has_method("get_revision"):
		return int(_registry.call("get_revision"))
	return -1


func _reject(reason: String, unit_id: String = "") -> Dictionary:
	return {"ok": false, "reason": reason, "unit_id": unit_id}
