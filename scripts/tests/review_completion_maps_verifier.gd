extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const CATALOG = preload("res://scripts/mission/productive_ground_maps.gd")
const REAL_ACTOR = preload("res://scripts/npc/test_unit.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const QUERY = preload("res://scripts/core/hex_visibility_query.gd")
var matrix: Array = []

func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	for path: String in CATALOG.all_paths():
		_test_map(path)
		await process_frame
	var historical = MAP.load_from_file("res://maps/facing_sightline_debug_12x12.json")
	_check(historical.get_grid_topology() == "square8" and historical.get_tactical_grid_rules().is_empty(), "explicit historical fixture keeps Square8 import semantics")
	_test_runtime_import()
	print("REVIEW_COMPLETION_MAP_MATRIX ", JSON.stringify(matrix))
	print("REVIEW_COMPLETION_MAPS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_runtime_import() -> void:
	var source := "res://maps/legacy/fireteam_command_drill_24x24_square8_20261113.json"
	var digest := FileAccess.get_sha256(source)
	var legacy = MAP.load_from_file(source)
	var point: Vector2 = legacy.get_marker_position("spawn_alpha")
	var origin: Vector2 = legacy.get_grid_origin()
	var metrics: Dictionary = legacy.get_tile_size()
	var skew := Vector2((point.x-origin.x)/metrics.half_width,(point.y-origin.y)/metrics.half_height)
	var q := (skew.x+skew.y)*0.5
	var r := (skew.y-skew.x)*0.5
	var expected := origin + Vector2((q+0.5*r-sqrt(3.0)*0.5*r)*metrics.half_width,(q+0.5*r+sqrt(3.0)*0.5*r)*metrics.half_height)
	var count: int = legacy.get_tiles().size()
	_check(legacy.activate_hex_tactical_runtime().get("ok",false) and legacy.get_grid_topology()=="hex_axial_v1" and legacy.get_tactical_grid_rules()=="hex_tactical_v1","custom Legacy import activates the same Hex runtime contract")
	_check(legacy.get_marker_position("spawn_alpha").distance_to(expected)<0.001 and legacy.get_tiles().size()==count,"custom import migrates marker world coordinates while preserving logical tiles")
	var once: Vector2 = legacy.get_marker_position("spawn_alpha")
	_check(legacy.activate_hex_tactical_runtime().get("ok",false) and legacy.get_marker_position("spawn_alpha")==once and FileAccess.get_sha256(source)==digest,"runtime import is idempotent and leaves the user's original map artifact unchanged")

func _test_map(path: String) -> void:
	var started := Time.get_ticks_msec()
	var map = MAP.load_from_file(path)
	var label := path.get_file()
	var valid: bool = map.get_load_issue_message().is_empty() and map.get_grid_topology() == "hex_axial_v1" and map.get_tactical_grid_rules() == "hex_tactical_v1"
	_check(valid, label + " actual offered map is complete Hex tactics")
	if not valid: return
	if label in ["satellite_crash_site.json","trade_outpost.json","fortified_outpost.json"]:
		_check(map.get_grid_size() == Vector2i(512,256) and map.get_tiles().size() == 512*256, label + " retains full authored 512x256 dimensions")
	var rig := _admission_rig([])
	rig.sim.set_physics_process(false)
	rig.terrain.configure_iso_grid(map.get_grid_origin(), map.get_tile_size().half_width, map.get_tile_size().half_height, map.get_grid_topology())
	for tile in map.get_tiles(): rig.terrain.register_tile(tile)
	_check(rig.sim.configure_hex_ground_runtime(map, rig.terrain).get("ok",false), label + " actual Root configures authored terrain")
	var anchor := Vector2i.ZERO
	if CATALOG.BASES.has(path):
		var authored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var spawn: Array = authored.homebase_exploration.avatar_spawn_grid
		anchor = Vector2i(int(spawn[0]),int(spawn[1]))
	else:
		for marker in ["spawn_alpha","spawn_bravo","objective_point"]:
			_check(map.get_marker_ids().has(marker) and rig.terrain.is_walkable(rig.terrain.world_to_grid(map.get_marker_position(marker))),label+" authored "+marker+" exists on a walkable cell")
		anchor = rig.terrain.world_to_grid(map.get_marker_position("spawn_alpha"))
	_check(rig.terrain.is_walkable(anchor),label+" actual authored start is walkable; no fallback field")
	if not rig.terrain.is_walkable(anchor):
		rig.scene.free()
		return
	var ids := PackedStringArray()
	for number in range(30):
		var id := "map_person_%02d" % number
		var actor := REAL_ACTOR.new()
		actor.unit_id = id
		actor.team_id = "blue"
		rig.scene.add_child(actor)
		rig.units.register_unit(id, actor)
		rig.sim.register_known_unit(id, actor)
		rig.actors[id] = actor
		ids.append(id)
	var admitted: Dictionary = rig.sim.admit_hex_ground_actor_group(ids, anchor)
	_check(admitted.get("ok",false), label + " capacity probe admits all 30 actual registered actors: " + str(admitted.get("reason","")))
	if not admitted.get("ok",false):
		rig.scene.free()
		return
	var pose: Dictionary = rig.sim.get_hex_ground_planning_snapshot()
	_check(pose.occupant_by_grid.size() == 30, label + " has 30 unique logical occupants")
	var mover := ""
	var destination := Vector2i.ZERO
	for id in ids:
		for next: Vector2i in rig.terrain.get_legal_hex_neighbors(pose.units_by_id[id].grid):
			if not pose.occupant_by_grid.has(next):
				mover = id
				destination = next
				break
		if not mover.is_empty(): break
	_check(not mover.is_empty(), label + " has a legal unoccupied departure edge")
	var work := {"navigation_expansions":0,"plan_calls":0,"accepted_steps":0}
	if not mover.is_empty():
		var origin: Vector2i = pose.units_by_id[mover].grid
		rig.sim.enqueue_command(_command(mover, rig.terrain.grid_to_world(destination)))
		for step in range(45):
			rig.sim._physics_process(0.1)
			var audit: Dictionary = rig.sim.get_hex_movement_audit_snapshot()
			for key in work: work[key] += int(audit.get(key,0))
		_check(rig.sim.get_hex_unit_state(mover).grid == destination and rig.sim.has_hex_position_arrived(mover,rig.terrain.grid_to_world(destination),"move_"+mover), label + " real command reaches neighbor through Root reservations")
		var observer: Dictionary = rig.sim.get_hex_unit_state(mover)
		var target := {"grid":origin,"stand_height_steps2":roundi(rig.terrain.get_stand_height_at(origin)*2.0)}
		var sight: Dictionary = QUERY.evaluate(observer,target,rig.terrain,{"range_hex":1,"arc_degrees":360.0})
		_check(sight.in_range, label + " same Hex cell geometry drives sight template")
		# A live terrain/door change closes the next step before it can be taken.
		rig.terrain.set_runtime_tile_overrides([{"grid_position":origin,"walkable_override":false}])
		var door_command := _command(mover,rig.terrain.grid_to_world(origin))
		door_command.command_token = "door_"+mover
		rig.sim.enqueue_command(door_command)
		for step in range(4): rig.sim._physics_process(0.1)
		_check(rig.sim.get_hex_unit_state(mover).grid == destination, label + " closed terrain endpoint cannot be entered")
		rig.terrain.clear_runtime_tile_overrides()
		rig.sim._physics_process(0.1)
	var first := ids[0]
	var second := ids[1]
	if label in ["satellite_crash_site.json","trade_outpost.json","fortified_outpost.json"]:
		_test_authored_ramp(rig,map,second,label)
	var occupied: Vector2i = rig.sim.get_hex_unit_state(second).grid
	var occupied_command := _command(first,rig.terrain.grid_to_world(occupied))
	occupied_command.command_token = "occupied_"+first
	rig.sim.enqueue_command(occupied_command)
	for step in range(12): rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state(first).grid != occupied and rig.sim.get_hex_ground_planning_snapshot().occupant_by_grid.size() == 30, label + " occupied destination remains owned without overlap")
	var save: Dictionary = rig.sim.export_hex_checkpoint_state()
	_check(save.get("ok",false), label + " actual movement/traffic state is checkpointable")
	if save.get("ok",false):
		var restored: Dictionary = rig.sim.restore_hex_checkpoint_state(JSON.parse_string(JSON.stringify(save.state)))
		if not restored.get("ok",false) or rig.sim.get_hex_ground_planning_snapshot().occupant_by_grid.size()!=30:
			print("MAP_RESTORE_REJECT ",path," ",restored," occupants=",rig.sim.get_hex_ground_planning_snapshot().occupant_by_grid.size())
		_check(restored.get("ok",false) and rig.sim.get_hex_ground_planning_snapshot().occupant_by_grid.size() == 30, label + " portable restore retains all 30 owners")
	var embarked: Dictionary = rig.sim.embark_hex_ground_actor_group(PackedStringArray([second]))
	_check(embarked.get("ok",false) and rig.sim.get_hex_unit_state(second).is_empty() and rig.units.get_unit(second) == rig.actors[second], label + " embark releases Ground and preserves actual actor identity")
	var deploy: Dictionary = rig.sim.admit_hex_ground_actor_group(PackedStringArray([second]),occupied)
	_check(deploy.get("ok",false), label + " same actor can redeploy through canonical admission")
	matrix.append({"map":path,"size":str(map.get_grid_size()),"actors":30,"tiles":map.get_tiles().size(),"work":work,"elapsed_msec":Time.get_ticks_msec()-started,"kind":"bounded_headless_functional_not_fps"})
	rig.scene.free()

func _test_authored_ramp(rig: Dictionary,map,id: String,label: String) -> void:
	var occupancy: Dictionary = rig.sim.get_hex_ground_planning_snapshot().occupant_by_grid
	var selected: Array[Vector2i] = []
	for tile in map.get_tiles():
		if tile.ramp_direction < 0 or occupancy.has(tile.grid_position): continue
		for next: Vector2i in rig.terrain.get_legal_hex_neighbors(tile.grid_position):
			if not occupancy.has(next) and not is_equal_approx(rig.terrain.get_stand_height_at(tile.grid_position),rig.terrain.get_stand_height_at(next)):
				selected = [tile.grid_position,next]
				break
		if not selected.is_empty(): break
	_check(not selected.is_empty(),label+" contains an authored traversable half-height ramp edge")
	if selected.is_empty(): return
	var released: Dictionary = rig.sim.embark_hex_ground_actor_group(PackedStringArray([id]))
	var placed: Dictionary = rig.sim.admit_hex_ground_actor_group(PackedStringArray([id]),selected[0]) if released.get("ok",false) else released
	_check(placed.get("ok",false),label+" same actual actor can be admitted at the authored ramp")
	if not placed.get("ok",false): return
	var command := _command(id,rig.terrain.grid_to_world(selected[1]))
	command.command_token = "authored_ramp_"+id
	rig.sim.enqueue_command(command)
	for step in range(45): rig.sim._physics_process(0.1)
	_check(rig.sim.has_hex_position_arrived(id,rig.terrain.grid_to_world(selected[1]),command.command_token),label+" actual Root movement crosses the authored height transition")
