extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
## Actual runtime editor -> two private saved files -> real bound Root movement.
const ISOLATION = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const EDITOR = preload("res://scenes/editor/map_editor.tscn")
const GATE = preload("res://scripts/editor/wall_gate_authoring.gd")
const FOOTPRINT = preload("res://scripts/mission/mission_door_footprint.gd")
const BINDINGS = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const DOOR = preload("res://scripts/mission/mission_interaction_door_runtime_collision_los.gd")
const MAP_PATH := "user://editor_wall_gate/map.json"
const SCENARIO_PATH := "user://editor_wall_gate/scenario.json"
var _editor: Node

func _init() -> void:
	if ISOLATION.require_isolated_user_data(): call_deferred("_run")

func _run() -> void:
	if not ISOLATION.require_isolated_user_data(): return
	_check(FileAccess.file_exists("user://review2_isolation_canary.json"), "actual private-profile canary")
	_test_marker_save_precision()
	_editor = EDITOR.instantiate()
	root.add_child(_editor)
	for frame in 8: await process_frame
	_editor._create_new_map(Vector2i(32,24))
	var map = _editor.get("_terrain_map_data")
	_check(map.get_grid_topology() == "hex_axial_v1" and map.get_terrain_height_rules() == "explicit_hex_ramps_v1", "actual editor new-map path enables its existing explicit Hex authoring contract")
	_editor.set("_current_map_path",MAP_PATH)
	_editor._save_current_map()
	_check(FileAccess.file_exists(MAP_PATH),"actual editor saves private initial map")
	_editor.set_mission_scenario_authoring_fields({"scenario_id":"editor_wall_gate","map_file_path":MAP_PATH,"vertical_slice":{"contract_version":1,"interaction_points":[]}})
	map = _editor.get("_terrain_map_data")
	var start := Vector2i(4,10)
	var end := Vector2i(13,10)
	var path: Array[Vector2i] = _editor._build_network_drag_path(start,end)
	var initial := _state()
	var planned: Dictionary = GATE.plan(map,path,Callable(_editor,"_building_owns_grid"))
	_check(planned.get("ok",false) and _state() == initial,"pure plan selects two interior door cells without authoring mutations")
	if not planned.get("ok",false): await _finish_editor(); return
	var tool: Button = _editor.find_child("BuilderTool_wallgate",true,false)
	_check(tool != null and tool.text == "M+T" and tool.is_visible_in_tree(),"actual builder rail exposes M+T beside existing wall tool")
	tool.pressed.emit()
	_check(_editor.get("_network_tool_kind") == "wall_gate", "actual tool action selects the existing network-drag input path")
	_check(_editor._begin_network_drag_at_world_position(map.get_tile_at_grid(start).world_position),"actual drag begins on map")
	_check(_editor._update_network_drag_preview_at_world_position(map.get_tile_at_grid(end).world_position),"actual drag preview reaches endpoint")
	var preview: Dictionary = _editor._build_network_drag_preview_summary()
	var preview_doors: Array = preview.auto_snapping.path_pieces.filter(func(piece: Dictionary): return piece.type_id in [GATE.FRAME,GATE.LEAF])
	_check(preview_doors.size() == 2 and preview.handles.filter(func(handle: Dictionary): return handle.label == "Tor").size() == 2 and _state() == initial,"preview names exactly both actual door assets without writing map or scenario")
	_check(_editor._finish_network_drag_at_world_position(map.get_tile_at_grid(end).world_position),"actual drag release commits complete wall and gate")
	var marker := String(planned.marker_id)
	var authored := _state()
	var points: Array = _editor.get_current_mission_scenario_dict().vertical_slice.interaction_points
	_check(points.size() == 1 and FOOTPRINT.validate_binding(points[0],map).get("ok",false),"actual scenario binding resolves the same two physical door cells and marker")
	_check(_editor.get_undo_debug_snapshot().undo_depth == 1 and _editor.get_undo_debug_snapshot().top_tile_state_count == path.size(),"one gesture records one complete tile transaction")
	var applied: Array = _editor.get("_last_network_apply_snapshot").changed_pieces.filter(func(piece: Dictionary): return piece.piece_key == "door")
	_check(applied == preview_doors,"actual door assets and rotations match the presented preview")
	_editor._undo_last_change()
	_check(_state() == initial and not map.has_marker(marker),"one actual undo restores cells, removes new marker and only its binding")
	_editor._redo_explicit_terrain_change()
	_check(_state() == authored and map.has_marker(marker),"actual Hex redo reconstructs the complete same ensemble")
	var before_duplicate := _state()
	_check(not _editor.apply_runtime_network_path_for_authoring("wall_gate",start,end) and _state() == before_duplicate,"duplicate gate cannot replace the existing door or binding")
	_editor._undo_last_change()
	_check(_state() == initial,"second undo leaves a clean fixture for rejection checks")
	var blocked = map.get_tile_at_grid(Vector2i(9,10))
	var original: Dictionary = blocked.to_dict()
	_editor.get("_tile_catalog").apply_type_to_tile(blocked,"station_set_door_double_closed")
	var occupied := _state()
	_check(not _editor.apply_runtime_network_path_for_authoring("wall_gate",start,end) and _state() == occupied,"foreign object rejects entire wall without partial writes")
	_editor._restore_tile_from_undo_state({"tile_states":[{"grid_position":Vector2i(9,10),"tile_dict":original}]})
	blocked.height_level = 1
	var uneven := _state()
	_check(not _editor.apply_runtime_network_path_for_authoring("wall_gate",start,end) and _state() == uneven,"uneven ground rejects atomically")
	blocked.height_level = 0
	var offset_marker: Vector2 = blocked.world_position + Vector2(5,3)
	_check(_editor.get("_terrain_registry").world_to_grid(offset_marker) == Vector2i(9,10),"offset marker remains inside the real registry's proposed wall cell")
	map.set_marker("existing_objective","objective_point",offset_marker)
	var protected_marker := _state()
	_check(not _editor.apply_runtime_network_path_for_authoring("wall_gate",start,end) and _state() == protected_marker,"off-centre gameplay marker is protected by the same registry grid mapping as the drag")
	map.remove_marker("existing_objective")
	var building: Dictionary = _editor.request_building_operation("place",{"asset_id":"frontier_hall_exterior","grid":Vector2i(9,10),"scale":1.0})
	_check(building.get("ok",false),"actual building owner reserves cells in the proposed wall")
	var protected_building := _state()
	_check(not _editor.apply_runtime_network_path_for_authoring("wall_gate",start,end) and _state() == protected_building,"actual reserved building footprint rejects the complete wall")
	if building.get("ok",false): _editor.request_building_operation("remove",{"building_id":building.building_id})
	_editor._clear_undo_history()
	_check(not GATE.plan(map,[Vector2i(4,10),Vector2i(5,10),Vector2i(8,10),Vector2i(9,10)]).get("ok",true),"disconnected external plan rejects")
	_check(not _editor.apply_runtime_network_path_for_authoring("wall_gate",start,start+Vector2i(2,0)),"too-short wall keeps a concrete tool rejection")
	_check(_editor.apply_runtime_network_path_for_authoring("wall_gate",start,end),"valid wall still builds after all negative attempts")
	_editor._save_current_map()
	_check(_editor.save_mission_scenario_from_editor(SCENARIO_PATH) == OK,"actual editor saves its scenario beside its map")
	var saved_map = MAP.load_from_file(MAP_PATH)
	var saved_scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_PATH))
	var bindings: Array = BINDINGS.normalize_scenario_bindings(saved_scenario)
	_check(BINDINGS.validate_bindings(bindings,saved_map).valid and bindings.size() == 1 and bindings[0].door_cells.size() == 2,"saved map and scenario reload into the unchanged real runtime binding contract")
	_check(saved_map.get_tile_at_grid(planned.frame).object_type_id == GATE.FRAME and saved_map.get_tile_at_grid(planned.leaf).object_type_id == GATE.LEAF,"roundtrip preserves real frame and closed leaf assets")
	if bindings.size() == 1: _test_real_door(saved_map,bindings[0],planned)
	_check(_editor.apply_runtime_network_path_for_authoring("wall",Vector2i(3,16),Vector2i(8,16)),"ordinary wall-line behavior remains available")
	_check(_editor.get_current_mission_scenario_dict().vertical_slice.interaction_points.size() == 1,"ordinary wall does not invent another door binding")
	await _finish_editor()

func _test_marker_save_precision() -> void:
	for topology: String in ["hex_axial_v1","square8"]:
		var map = MAP.create_empty("marker_precision",Vector2i(16,16),Vector2.ZERO,64,32,3,topology)
		var position: Vector2 = map.get_tile_at_grid(Vector2i(9,10)).world_position + Vector2(0.25,0.375)
		map.set_marker("precise","custom",position)
		var path := "user://editor_wall_gate/marker_"+topology+".json"
		_check(map.save_to_file(path) == OK,topology+" actual marker serializer writes private file")
		var reloaded = MAP.load_from_file(path)
		var expected: Vector2 = position if topology == "hex_axial_v1" else position.round()
		_check(reloaded.get_marker_position("precise") == expected,topology+" marker roundtrip preserves exact Hex coordinates and original Square rounding")

func _state() -> String:
	var map = _editor.get("_terrain_map_data")
	var tiles: Array = []
	for tile in map.get_tiles(): tiles.append(tile.to_dict())
	return JSON.stringify({"tiles":tiles,"markers":map.get_markers(),"presentation":map.get_place_presentation(),"points":_editor.get_current_mission_scenario_dict().vertical_slice.get("interaction_points",[])})

func _test_real_door(map, binding: Dictionary, gate: Dictionary) -> void:
	var rig: Dictionary = _admission_rig([])
	rig.sim.set_physics_process(false)
	var size: Dictionary = map.get_tile_size()
	rig.terrain.configure_iso_grid(map.get_grid_origin(),size.half_width,size.half_height,map.get_grid_topology())
	for tile in map.get_tiles(): rig.terrain.register_tile(tile)
	_check(rig.sim.configure_hex_ground_runtime(map,rig.terrain).get("ok",false),"actual Root accepts the editor-saved map")
	var start: Vector2i = gate.leaf + Vector2i(0,1)
	_add_admission_actor(rig,"gate_visitor")
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["gate_visitor"]),start).get("ok",false),"real actor admitted beside authored closed gate")
	rig.sim.enqueue_command(_command("gate_visitor",rig.terrain.grid_to_world(gate.leaf)))
	for tick in 8: rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("gate_visitor").grid == start,"saved closed gate blocks actual movement")
	var projection: Dictionary = DOOR.build_runtime_snapshot([binding],{String(binding.interaction_id):{"complete":true}},map,rig.terrain)
	_check(projection.overrides.size() == 2,"existing completed-door owner projects exactly both authored cells")
	rig.terrain.set_runtime_tile_overrides(projection.overrides)
	for destination: Vector2i in [gate.leaf,gate.frame,gate.frame+Vector2i(0,-1)]:
		var command: Dictionary = _command("gate_visitor",rig.terrain.grid_to_world(destination))
		command.command_token = "editor_gate:"+str(destination)
		rig.sim.enqueue_command(command)
		for tick in 200:
			rig.sim._physics_process(0.1)
			if rig.sim.has_hex_position_arrived("gate_visitor",command.target_position,command.command_token): break
		_check(rig.sim.has_hex_position_arrived("gate_visitor",command.target_position,command.command_token),"actual Root arrival crosses the opened saved gate: "+str(destination))
	rig.scene.free()

func _finish_editor() -> void:
	if is_instance_valid(_editor): _editor.queue_free()
	for frame in 3: await process_frame
	print("EDITOR_WALL_GATE passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
