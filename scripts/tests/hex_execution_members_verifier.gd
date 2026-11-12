extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

const FMC=preload("res://scripts/tactical/fireteam_movement_controller.gd")
const BEHAVIOR=preload("res://scripts/command/fireteam_behavior_profile.gd")

func _run()->void:
	_test_members()
	_test_bounding_retirement()
	_test_bounding_retirement("caterpillar")
	_test_bounding_retirement("bounding",true)
	_test_scope_lifetimes()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_EXECUTION_MEMBERS_PASS")
	quit(0 if failed==0 else 1)

func _test_members()->void:
	var cells:Array=[]
	for x in range(6):
		for y in range(2):cells.append(Vector2i(x,y))
	var rig:Dictionary=_admission_rig(cells)
	var a=_add_admission_actor(rig,"a")
	var b=_add_admission_actor(rig,"b")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a","b"]),Vector2i.ZERO)
	var movement=FMC.new()
	var target:Vector2=rig.terrain.grid_to_world(Vector2i(5,0))
	var started:Dictionary=movement.start_execution("ft1","move",0,target,null,[a,b],a,rig.sim,rig.terrain)
	_check(started.get("started",false),"actual FMC starts a two-person Hex execution")
	var before:Dictionary=movement.get_fireteam_state("ft1")
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
	rig.sim.command_queue.clear()
	movement.update_execution("ft1",[a,b],a,rig.sim,rig.terrain)
	var after:Dictionary=movement.get_fireteam_state("ft1")
	_check(not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"readmitted member cannot receive old reissue while remaining buddy keeps moving")
	_check(not Dictionary(after.get("current_target_positions",{})).has("a") and Dictionary(after.get("current_target_positions",{})).get("b")==Dictionary(before.get("current_target_positions",{})).get("b"),"retirement removes only the stale member's target")
	rig.sim.command_queue.clear()
	movement.update_tactical_stance("ft1","cautious",[a,b],a,rig.sim,rig.terrain)
	movement.update_fire_rule("ft1","hold_fire",[a,b],a,rig.sim,rig.terrain)
	_check(not _queued(rig.sim,"a"),"stance and fire-rule updates cannot revive retired membership")
	var restarted:Dictionary=movement.start_execution("ft1","move",0,target,null,[a,b],a,rig.sim,rig.terrain)
	_check(restarted.get("started",false) and _queued(rig.sim,"a"),"new explicit execution can include the readmitted member")
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a","b"]))
	rig.sim.command_queue.clear()
	var completed:Dictionary=movement.update_execution("ft1",[a,b],a,rig.sim,rig.terrain)
	_check(completed.get("finished",false) and not movement.has_active_execution("ft1") and rig.sim.command_queue.is_empty(),"execution with no remaining ground members terminates without new commands")
	rig.scene.free()

func _test_bounding_retirement(style:String="bounding",contact_halt:bool=false)->void:
	var cells:Array=[]
	for x in range(6):
		for y in range(2):cells.append(Vector2i(x,y))
	var rig:Dictionary=_admission_rig(cells)
	var a=_add_admission_actor(rig,"a")
	var b=_add_admission_actor(rig,"b")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a","b"]),Vector2i.ZERO)
	var movement=FMC.new()
	var profile=BEHAVIOR.new({"advance_style":style})
	var command_type:String="engage" if style=="bounding" else "flank"
	var started:Dictionary=movement.start_execution("ft1",command_type,0,rig.terrain.grid_to_world(Vector2i(5,0)),profile,[a,b],a,rig.sim,rig.terrain)
	var before:Dictionary=movement.get_fireteam_state("ft1")
	var moving:PackedStringArray=before.get("current_moving_unit_ids",PackedStringArray())
	_check(started.get("started",false) and before.get("effective_style")==style and moving.size()==1,"actual two-person execution starts a %s stage"%style)
	if moving.size()==1:
		var retired:String=moving[0]
		var retained:String="b" if retired=="a" else "a"
		if contact_halt:movement.update_execution("ft1",[a,b],a,rig.sim,rig.terrain,{"should_halt":true})
		rig.sim.embark_hex_ground_actor_group(PackedStringArray([retired]))
		rig.sim.admit_hex_ground_actor_group(PackedStringArray([retired]),Vector2i.ZERO)
		rig.sim.command_queue.clear()
		if contact_halt:
			movement.update_tactical_stance("ft1","cautious",[a,b],a,rig.sim,rig.terrain)
			movement.update_fire_rule("ft1","hold_fire",[a,b],a,rig.sim,rig.terrain)
			movement.update_execution("ft1",[a,b],a,rig.sim,rig.terrain,{"should_halt":true})
			var only_holds:bool=not _queued(rig.sim,retired)
			for queued in rig.sim.command_queue:
				if queued.get("command_type")!="hold_position":only_holds=false
			_check(only_holds,"retiring current mover during contact plus stance/fire changes preserves the contact hold")
			rig.sim.command_queue.clear()
		movement.update_execution("ft1",[a,b],a,rig.sim,rig.terrain)
		var after:Dictionary=movement.get_fireteam_state("ft1")
		_check(not _queued(rig.sim,retired) and PackedStringArray(after.get("current_moving_unit_ids",PackedStringArray())).has(retained) and _queued(rig.sim,retained),"remaining coverer advances when the entire moving subgroup retires")
		var no_empty:=true
		for group in Array(after.get("group_cycle",[])):
			if group.is_empty():no_empty=false
		_check(no_empty,"retirement does not leave empty bounding groups that can stall later stages")
	rig.scene.free()

func _queued(sim,id:String)->bool:
	for command in sim.command_queue:
		if String(command.get("unit_id",""))==id:return true
	return false

func _test_scope_lifetimes()->void:
	var cells:Array=[]
	for x in range(6):
		for y in range(2):cells.append(Vector2i(x,y))
	var rig:Dictionary=_admission_rig(cells)
	var actors:Array=[]
	for id in ["a","b","c","d"]:actors.append(_add_admission_actor(rig,id))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a","b","c","d"]),Vector2i.ZERO)
	var movement=FMC.new()
	var snapshot:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var rng_before:int=rig.sim._combat_rng.state
	var scope:Dictionary=movement.capture_hex_execution_scope(actors,rig.sim)
	_check(rig.sim.get_hex_ground_planning_snapshot()==snapshot and rig.sim._combat_rng.state==rng_before,"capturing execution lifetime neither mutates Ground nor consumes RNG")
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
	rig.sim.command_queue.clear()
	var target:Vector2=rig.terrain.grid_to_world(Vector2i(5,0))
	var started:Dictionary=movement.start_execution("ft1","engage",0,target,null,actors,actors[0],rig.sim,rig.terrain,{"hex_execution_scope":scope})
	var state:Dictionary=movement.get_fireteam_state("ft1")
	var safe_groups:=true
	for group in Array(state.get("group_cycle",[])):
		if group.has("a"):safe_groups=false
	_check(started.get("started",false) and state.get("effective_style")=="bounding" and state.get("leader_unit_id")!="a" and safe_groups and not _queued(rig.sim,"a"),"retired leader cannot be reinserted by inherited bounding formation")
	rig.sim.command_queue.clear()
	movement.update_execution("ft1",actors,actors[0],rig.sim,rig.terrain,{"should_halt":true,"target_position":target})
	_check(not _queued(rig.sim,"a") and not rig.sim.command_queue.is_empty(),"actual contact halt only issues commands to surviving execution members")
	var b_grid:Vector2i=rig.sim.get_hex_unit_state("b").grid
	rig.sim.unregister_known_unit("b")
	rig.units.unregister_unit("b")
	var replacement=_add_admission_actor(rig,"b")
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["b"]),b_grid).ok,"replacement-actor fixture has a real admitted new presence")
	actors[1]=replacement
	rig.sim.command_queue.clear()
	movement.update_fire_rule("ft1","hold_fire",actors,actors[0],rig.sim,rig.terrain)
	_check(not _queued(rig.sim,"b"),"same-ID actor replacement cannot inherit the previous actor's live order")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a","b","c","d"]),Vector2i.ZERO)
	rig.sim.command_queue.clear()
	var changed:Dictionary=movement.update_execution("ft1",actors,actors[0],rig.sim,rig.terrain)
	_check(changed.get("finished",false) and rig.sim.command_queue.is_empty(),"same Root with a new map context cannot resume old execution")
	movement.start_execution("ft1","move",0,target,null,actors,actors[0],rig.sim,rig.terrain)
	var foreign:Dictionary=_admission_rig(cells)
	rig.sim.command_queue.clear()
	changed=movement.update_execution("ft1",actors,actors[0],foreign.sim,foreign.terrain)
	_check(changed.get("finished",false) and foreign.sim.command_queue.is_empty(),"replacement Root with equal context revision cannot receive old execution")
	foreign.scene.free()
	var legacy=MAP.create_empty("legacy_members",Vector2i(6,2),Vector2.ZERO,64,32)
	rig.sim.configure_hex_ground_runtime(legacy,rig.terrain)
	started=movement.start_execution("legacy","move",0,target,null,actors,actors[0],rig.sim,rig.terrain)
	_check(started.get("started",false) and not rig.sim.command_queue.is_empty(),"unflagged legacy execution still uses the existing free movement path")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a","b","c","d"]),Vector2i.ZERO)
	rig.sim.command_queue.clear()
	changed=movement.update_execution("legacy",actors,actors[0],rig.sim,rig.terrain)
	_check(changed.get("finished",false) and rig.sim.command_queue.is_empty(),"old legacy execution cannot acquire fresh receiver bindings after Hex activation")
	rig.scene.free()
