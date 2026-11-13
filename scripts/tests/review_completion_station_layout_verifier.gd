extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const ISOLATION = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const DOOR = preload("res://scripts/mission/mission_interaction_door_runtime_collision_los.gd")
const BINDINGS = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const FOOTPRINT = preload("res://scripts/mission/mission_door_footprint.gd")

func _run() -> void:
	if not ISOLATION.require_isolated_user_data(): return
	for spec: Array in [["station_outpost_64x64",0],["station_outpost_192x192",64]]:
		_verify_map(String(spec[0]),int(spec[1]))
		await process_frame
	print("REVIEW_STATION_LAYOUT passed=%d failed=%d" % [passed,failed])
	quit(0 if failed == 0 else 1)

func _verify_map(name:String,offset:int)->void:
	var path:="res://maps/"+name+".json"
	var map=MAP.load_from_file(path)
	var raw:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var layout:Dictionary=raw.place_presentation.station_module_layout
	_check(layout.schema=="warehouse_axes_v1" and layout.row_anchor==31+offset and layout.source_region==[float(22+offset),float(23+offset),20.0,18.0],name+" declares bounded authored warehouse alignment")
	var rig:=_admission_rig([])
	rig.sim.set_physics_process(false)
	rig.terrain.configure_iso_grid(map.get_grid_origin(),map.get_tile_size().half_width,map.get_tile_size().half_height,map.get_grid_topology())
	for tile in map.get_tiles(): rig.terrain.register_tile(tile)
	_check(rig.sim.configure_hex_ground_runtime(map,rig.terrain).get("ok",false),name+" actual Root owns revised Hex terrain")
	var contiguous:=true
	var bounded_axis:=true
	var previous:=Vector2i.ZERO
	var x_min:=INF
	var x_max:=-INF
	for r in range(26+offset,38+offset):
		var q:=24+offset-floori(float(r-(31+offset))/2.0)
		var cell:=Vector2i(q,r)
		contiguous=contiguous and not rig.terrain.is_walkable(cell) and (r==26+offset or HEX.are_neighbors(previous,cell))
		var plane:Vector2=HEX.axial_to_plane(Vector2(cell))
		x_min=minf(x_min,plane.x);x_max=maxf(x_max,plane.x)
		previous=cell
	bounded_axis=is_equal_approx(x_max-x_min,0.5)
	_check(contiguous,name+" physical west wall is an unbroken blocked Hex chain")
	_check(bounded_axis,name+" wall cells contain one straight warehouse axis within quarter-cell offsets")
	for marker:String in ["spawn_alpha","spawn_bravo","objective_point"]:
		_check(rig.terrain.is_walkable(rig.terrain.world_to_grid(map.get_marker_position(marker))),name+" unchanged authored "+marker+" remains legal")
	for point:Vector2 in map.get_patrol_paths().station_loop_route:
		_check(rig.terrain.is_walkable(rig.terrain.world_to_grid(point)),name+" revised actual station patrol waypoint remains walkable")
	var removal:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/review_completion_20261113/station_pipe_removal.json"))
	var ensemble_revision:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/review_completion_20261113/station_outer_layout_migration.json"))
	var moved_cells:Dictionary={}
	for record:Dictionary in ensemble_revision.maps:
		if record.map!=path:continue
		for move:Dictionary in record.moved_cells:
			moved_cells[Vector2i(int(move.from[0]),int(move.from[1]))]=Vector2i(int(move.to[0]),int(move.to[1]))
	_check(layout.regions.size()==(1 if offset==0 else 9),name+" every authored station ensemble has an explicit visual region")
	var removed_cells:Array=[]
	for record:Dictionary in removal.maps:
		if record.map==path:removed_cells=record.removed_cells
	_check(removed_cells.size()==(33 if offset==0 else 265) and layout.pipe_extension_cells.is_empty() and not layout.has("pipe_transition_cell"),name+" removed pipe revision has exact authored scope and no visual extension")
	var released:=true
	for record:Dictionary in removed_cells:
		var cell:=Vector2i(int(record.grid[0]),int(record.grid[1]))
		# Follow the exact later tile permutation, not a historical world spot
		# that may now contain a visible, legitimately relocated station wall.
		cell=moved_cells.get(cell,cell)
		var tile=rig.terrain.get_tile_at_grid(cell)
		released=released and rig.terrain.is_walkable(cell) and not rig.terrain.blocks_los_at_grid(cell) and tile.object_type_id.is_empty() and tile.object_height==0 and tile.cover_value==0
	_check(released,name+" every removed pipe terrain record remains genuinely walkable after the bounded ensemble relocation")
	var no_pipes:=true
	for tile in map.get_tiles():no_pipes=no_pipes and not String(tile.object_type_id).begins_with("spacekit_pipe")
	_check(no_pipes,name+" no rejected pipe object remains anywhere in the actual map")
	# Enter the actual relocated northern doorway from its real interior neighbor.
	var door_cell:=Vector2i(34+offset,25+offset)
	var inside:=Vector2i(34+offset,26+offset)
	_check(String(rig.terrain.get_tile_at_grid(door_cell).object_type_id)=="station_set_wall_door" and rig.terrain.blocks_los_at_grid(door_cell),name+" relocated real door keeps closed LOS and model identity")
	_add_admission_actor(rig,"visitor")
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["visitor"]),inside).get("ok",false),name+" actual actor enters legal interior through Root admission")
	rig.sim.enqueue_command(_command("visitor",rig.terrain.grid_to_world(door_cell)))
	for i in range(8):rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("visitor").grid==inside,name+" closed relocated door blocks real movement")
	var projection:Dictionary=DOOR.build_snapshot({"entries":[{"object_kind":"door","interaction_id":"authored_north_door","grid_position":door_cell,"runtime_visual_state":"open"}]},rig.terrain)
	rig.terrain.set_runtime_tile_overrides(projection.overrides)
	_check(rig.terrain.is_walkable(door_cell) and not rig.terrain.blocks_los_at_grid(door_cell),name+" canonical open-door projection updates same physical cell")
	for i in range(60):rig.sim._physics_process(0.1)
	_check(rig.sim.has_hex_position_arrived("visitor",rig.terrain.grid_to_world(door_cell),"move_visitor"),name+" actual token completes through opened relocated door")
	var save:Dictionary=rig.sim.export_hex_checkpoint_state()
	_check(save.get("ok",false),name+" revised map exports real Root state")
	if save.get("ok",false):
		var state:Dictionary=JSON.parse_string(JSON.stringify(save.state))
		_check(rig.sim.restore_hex_checkpoint_state(state).get("ok",false),name+" portable revised-map checkpoint restores exact owners")
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		state.map_fingerprint="0".repeat(64)
		var rejected:Dictionary=rig.sim.restore_hex_checkpoint_state(state)
		_check(not rejected.get("ok",false) and rejected.get("reason")=="checkpoint_map_mismatch" and rig.sim.get_hex_ground_planning_snapshot()==before,name+" other map revision remains rejected without mutation")
	_verify_eastern_door(rig,map,offset,name)
	rig.scene.free()

func _verify_eastern_door(rig:Dictionary,map,offset:int,label:String)->void:
	var binding:Dictionary={"interaction_id":"station_route_drill_door","interaction_type":"door","marker_id":"station_entry_door","required_order":"breach","radius_world":128.0,"duration_seconds":2.0,"door_cells":[{"x":39+offset,"y":31+offset},{"x":40+offset,"y":31+offset}]}
	_check(FOOTPRINT.validate_binding(binding,map).get("ok",false),label+" actual two-cell frame and leaf pass authored footprint validation")
	var opened:Dictionary={"station_route_drill_door":{"complete":true}}
	var good:Dictionary=DOOR.build_runtime_snapshot([binding],opened,map,rig.terrain)
	var actual_cells:Array=[]
	for override:Dictionary in good.overrides:actual_cells.append(override.grid_position)
	_check(actual_cells.size()==2 and actual_cells.has(Vector2i(39+offset,31+offset)) and actual_cells.has(Vector2i(40+offset,31+offset)),label+" open state projects exactly the authored frame and leaf")
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	for spec:Array in [
		[7,"invalid_door_cells"],
		[[binding.door_cells[0],binding.door_cells[0]],"duplicate_door_cell"],
		[[binding.door_cells[0],{"x":41+offset,"y":31+offset}],"door_cell_not_authored_door"],
		[[binding.door_cells[1],{"x":31+offset,"y":31+offset}],"disconnected_door_cells"],
		[[{"x":INF,"y":31+offset}],"invalid_door_cell"],
	]:
		var bad:=binding.duplicate(true);bad.door_cells=spec[0]
		var normalized:Array=BINDINGS.normalize_scenario_bindings({"interaction_points":[bad]})
		var result:Dictionary=FOOTPRINT.validate_binding(normalized[0],map)
		var projection:Dictionary=DOOR.build_runtime_snapshot(normalized,opened,map,rig.terrain)
		_check(not result.get("ok",false) and result.get("reason")==spec[1] and projection.overrides.is_empty() and projection.invalid_footprint_count==1,label+" malformed footprint rejects without releasing any cell: "+spec[1])
	var marker:Vector2=map.get_marker_position("station_entry_door")
	map.set_marker_position("station_entry_door",marker+Vector2(8,0))
	var shifted:Dictionary=DOOR.build_runtime_snapshot([binding],opened,map,rig.terrain)
	_check(shifted.overrides.is_empty() and shifted.invalid_footprint_count==1,label+" moved marker cannot open the old physical footprint")
	map.set_marker_position("station_entry_door",marker)
	_check(rig.sim.get_hex_ground_planning_snapshot()==before,label+" all footprint reads and rejections preserve actual Root claims")
	var legacy:=binding.duplicate(true);legacy.erase("door_cells")
	_check(DOOR.build_runtime_snapshot([legacy],opened,map,rig.terrain).overrides.size()==1,label+" explicit historical single-cell binding remains compatible")
	var outside:=Vector2i(41+offset,31+offset)
	var leaf:=Vector2i(40+offset,31+offset)
	var frame:=Vector2i(39+offset,31+offset)
	_add_admission_actor(rig,"east_visitor")
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["east_visitor"]),outside).get("ok",false),label+" actual outside actor is admitted beside the closed entrance")
	rig.sim.enqueue_command(_command("east_visitor",rig.terrain.grid_to_world(leaf)))
	for i in range(8):rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("east_visitor").grid==outside,label+" actual closed leaf prevents outside entry")
	rig.terrain.set_runtime_tile_overrides(good.overrides)
	for destination:Vector2i in [leaf,frame,Vector2i(32+offset,31+offset)]:
		var command:=_command("east_visitor",rig.terrain.grid_to_world(destination))
		command.command_token="east-entry:"+str(destination)
		rig.sim.enqueue_command(command)
		for i in range(300):
			rig.sim._physics_process(0.1)
			if rig.sim.has_hex_position_arrived("east_visitor",command.target_position,command.command_token):break
		_check(rig.sim.has_hex_position_arrived("east_visitor",command.target_position,command.command_token),label+" actual Root actor traverses opened leaf/frame to computer: "+str(destination))
