class_name HexGroundAdmission
extends RefCounted

## Pure, bounded group placement. Root validates actors and commits the result.
const MAX_EXPANSIONS:=64

func plan_group(unit_ids:PackedStringArray,anchor_grid:Vector2i,terrain_registry:Node,ground_snapshot:Dictionary,max_expansions:int=64)->Dictionary:
	var rejected:Dictionary={"ok":false,"placements":[],"waiting_unit_ids":unit_ids.duplicate(),"reason":"invalid_admission_context","expanded":0}
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_grid_topology") or terrain_registry.call("get_grid_topology")!="hex_axial_v1":return rejected
	for method in ["get_legal_hex_neighbors","get_tile_at_grid","is_walkable","get_revision"]:
		if not terrain_registry.has_method(method):return rejected
	if not ground_snapshot.get("units_by_id") is Dictionary or not ground_snapshot.get("occupant_by_grid") is Dictionary or int(ground_snapshot.get("terrain_revision",-1))!=int(terrain_registry.call("get_revision")):return rejected
	if unit_ids.is_empty() or unit_ids.size()>MAX_EXPANSIONS or max_expansions<1:
		rejected.reason="invalid_admission_group"
		return rejected
	var ids:Dictionary={}
	for id in unit_ids:
		if id.is_empty() or id!=id.strip_edges() or ids.has(id) or ground_snapshot.units_by_id.has(id):
			rejected.reason="invalid_admission_unit"
			return rejected
		ids[id]=true
	var blocked:Dictionary=ground_snapshot.occupant_by_grid.duplicate()
	for grid in ground_snapshot.get("external_admission_blocked_grids",{}):blocked[grid]=true
	var now:int=int(ground_snapshot.get("current_tick",0))
	for segment in ground_snapshot.get("committed_segments",[]):
		if int(segment.start_tick)+int(segment.duration_ticks)>now:
			blocked[segment.from_grid]=true
			blocked[segment.to_grid]=true
	for grant in ground_snapshot.get("committed_corridor_grants",[]):
		for grid in grant.cells:blocked[grid]=true
	for grid in ground_snapshot.get("admission_slots_by_grid",{}):blocked[grid]=true
	var budget:int=mini(MAX_EXPANSIONS,max_expansions)
	var queue:Array[Vector2i]=[anchor_grid]
	var seen:Dictionary={anchor_grid:true}
	var cursor:=0
	var placements:Array[Dictionary]=[]
	while cursor<queue.size() and cursor<budget:
		var grid:Vector2i=queue[cursor]
		cursor+=1
		rejected.expanded=cursor
		if blocked.has(grid) or not bool(terrain_registry.call("is_walkable",grid)):continue
		var tile=terrain_registry.call("get_tile_at_grid",grid)
		if tile==null or not tile.is_valid():continue
		placements.append({"unit_id":unit_ids[placements.size()],"grid":grid,"facing_dir":0,"posture_key":"standing"})
		if placements.size()==unit_ids.size():return {"ok":true,"placements":placements,"waiting_unit_ids":PackedStringArray(),"reason":"","expanded":cursor}
		for next in terrain_registry.call("get_legal_hex_neighbors",grid):
			if not seen.has(next) and not blocked.has(next):
				seen[next]=true
				queue.append(next)
	rejected.reason="admission_budget" if cursor<queue.size() else "insufficient_admission_space"
	return rejected
