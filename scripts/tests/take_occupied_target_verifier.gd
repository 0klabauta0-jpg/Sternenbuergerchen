extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
## G2: a TAKE order whose target cell is held by a standing enemy must send the
## members to a free neighbouring cell instead of waiting forever (target_occupied).
## Real Root, real hex movement and the real fireteam movement controller.
## A lone operator (and an aggressive RUSH squad) gets the zero-offset slot, so its
## goal is exactly the TAKE cell; that is the case the campaign guard post produces.
const ACTOR=preload("res://scripts/npc/test_unit.gd")
const FMC=preload("res://scripts/tactical/fireteam_movement_controller.gd")
const TICK:=0.1
const START:=Vector2i(3,2)
const TARGET:=Vector2i(6,2)
const RUSH:={"tactical_stance":"aggressive","advance_style":"rush"}

func _run()->void:
	_test_t1_standing_enemy()
	_test_t2_enemy_arrives_later()
	_test_t3_nearest_neighbor()
	_test_t4_free_target()
	_test_t5_moving_comrade()
	_test_t6_all_neighbors_blocked()
	print("TAKE_OCCUPIED_TARGET passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func _cells(width:int,height:int,missing:Array=[])->Array:
	var cells:Array=[]
	for x in range(width):
		for y in range(height):
			var cell:=Vector2i(x,y)
			if not missing.has(cell):cells.append(cell)
	return cells

func _make_rig(cells:Array)->Dictionary:
	var rig:=_admission_rig(cells)
	rig.sim.name="SimulationRoot";rig.units.name="UnitRegistry";rig.terrain.name="TerrainRegistry"
	rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units);rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain)
	rig.sim.set_physics_process(false)
	return rig

func _add_actor(rig:Dictionary,id:String,team:String,fireteam:String,lead:bool=false)->Node:
	var actor:=ACTOR.new();actor.unit_id=id;actor.team_id=team;actor.fireteam_id=fireteam;actor.is_fireteam_lead=lead
	actor.weapon_1_id="none";actor.weapon_2_id="none";rig.scene.add_child(actor);actor.set_physics_process(false)
	rig.units.register_unit(id,actor);rig.sim.register_known_unit(id,actor)
	return actor

func _grid(rig:Dictionary,id:String)->Vector2i:
	return rig.sim.get_hex_unit_state(id).grid

func _stuck(rig:Dictionary,ids:Array)->Array:
	var stuck:Array=[]
	for id in ids:
		var readout:Dictionary=rig.sim.get_hex_movement_readout(id)
		if String(readout.get("status",""))=="waiting_reservation" and String(readout.get("reason",""))=="target_occupied":stuck.append(id)
	return stuck

func _squad(rig:Dictionary,count:int)->Dictionary:
	var units:Array=[]
	var ids:PackedStringArray=PackedStringArray()
	for index in range(count):
		var id:="take_%s"%char(97+index)
		units.append(_add_actor(rig,id,"team_alpha","ft1",index==0))
		ids.append(id)
	rig.sim.admit_hex_ground_actor_group(ids,START)
	return {"units":units,"lead":units[0],"ids":ids}

func _start_take(rig:Dictionary,fmc,squad:Dictionary,profile=null)->Dictionary:
	return fmc.start_execution("ft1","take",0,rig.terrain.grid_to_world(TARGET),profile,squad.units,squad.lead,rig.sim,rig.terrain)

## Runs the squad. Returns the issued target history per unit (changes only) and
## the units stuck on target_occupied in the final tick.
func _run_take(rig:Dictionary,fmc,squad:Dictionary,seconds:float,on_tick:Callable=Callable())->Dictionary:
	var history:Dictionary={}
	for tick in range(int(seconds/TICK)):
		if on_tick.is_valid():on_tick.call(tick)
		fmc.update_execution("ft1",squad.units,squad.lead,rig.sim,rig.terrain)
		for command in rig.sim.command_queue:
			var key:String=String(command.get("unit_id",""))
			if not history.has(key):history[key]=[]
			var list:Array=history[key]
			var target:Vector2=Vector2(command.get("target_position",Vector2.ZERO))
			if list.is_empty() or Vector2(list[list.size()-1])!=target:list.append(target)
		rig.sim._physics_process(TICK)
	return {"history":history,"stuck":_stuck(rig,squad.ids)}

func _changes(history:Dictionary,id:String)->int:
	return maxi(0,Array(history.get(id,[])).size()-1)

func _any_adjacent(rig:Dictionary,squad:Dictionary)->bool:
	for id in squad.ids:
		if HEX.distance(_grid(rig,id),TARGET)==1:return true
	return false

func _diag(label:String,rig:Dictionary,squad:Dictionary,result:Dictionary)->void:
	var info:Dictionary={"stuck":result.stuck}
	for id in squad.ids:info[id]={"grid":_grid(rig,id),"readout":rig.sim.get_hex_movement_readout(id)}
	print(label," ",info)

func _test_t1_standing_enemy()->void:
	for variant in ["lone","rush_pair"]:
		var rig:=_make_rig(_cells(10,6))
		var squad:=_squad(rig,1 if variant=="lone" else 2)
		_add_actor(rig,"enemy_1","team_enemy","enemy_ft")
		_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["enemy_1"]),TARGET).ok,"T1 %s: enemy stands on the TAKE cell"%variant)
		var fmc:=FMC.new()
		_check(_start_take(rig,fmc,squad,RUSH if variant=="rush_pair" else null).get("started",false),"T1 %s: TAKE starts"%variant)
		var result:=_run_take(rig,fmc,squad,20.0)
		_diag("T1_DIAG_"+variant,rig,squad,result)
		_check(result.stuck.is_empty(),"T1 %s: no member waits on target_occupied after 20 s"%variant)
		_check(_any_adjacent(rig,squad),"T1 %s: a member stands next to the enemy"%variant)
		_check(_grid(rig,"enemy_1")==TARGET,"T1 %s: enemy not displaced"%variant)
		_check(_changes(result.history,"take_a")<=4,"T1 %s: leader target does not flicker (%d changes)"%[variant,_changes(result.history,"take_a")])
		rig.scene.free()

func _test_t2_enemy_arrives_later()->void:
	# The enemy steps onto the target while the order is already running: early,
	# while the member is on its way, and late, when the member is next to the cell.
	for combo in [["lone",3],["lone",30],["bound_pair",3],["bound_pair",30]]:
		var variant:String=combo[0]
		var arrival_tick:int=combo[1]
		var rig:=_make_rig(_cells(10,6))
		var squad:=_squad(rig,1 if variant=="lone" else 2)
		_add_actor(rig,"enemy_1","team_enemy","enemy_ft")
		var fmc:=FMC.new()
		_start_take(rig,fmc,squad,RUSH if variant=="rush_pair" else null)
		var arrive:=func(tick:int)->void:
			if tick==arrival_tick:rig.sim.admit_hex_ground_actor_group(PackedStringArray(["enemy_1"]),TARGET)
		var result:=_run_take(rig,fmc,squad,(arrival_tick*TICK)+20.0,arrive)
		var tag:="%s@%d"%[variant,arrival_tick]
		_diag("T2_DIAG_"+tag,rig,squad,result)
		_check(_grid(rig,"enemy_1")==TARGET,"T2 %s: enemy appeared on the target after the order"%tag)
		_check(result.stuck.is_empty(),"T2 %s: no member waits on target_occupied 20 s after the enemy arrived"%tag)
		_check(_any_adjacent(rig,squad),"T2 %s: a member stands next to the enemy"%tag)
		_check(_changes(result.history,"take_a")<=4,"T2 %s: target does not flicker (%d changes)"%[tag,_changes(result.history,"take_a")])
		rig.scene.free()

func _test_t3_nearest_neighbor()->void:
	var rig:=_make_rig(_cells(10,6))
	var squad:=_squad(rig,1)
	_add_actor(rig,"enemy_1","team_enemy","enemy_ft")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["enemy_1"]),TARGET)
	var start_world:Vector2=rig.terrain.grid_to_world(START)
	var fmc:=FMC.new()
	_start_take(rig,fmc,squad)
	_run_take(rig,fmc,squad,20.0)
	var chosen:Vector2i=_grid(rig,"take_a")
	var opposite:Vector2i=TARGET*2-chosen
	var closer:bool=rig.terrain.grid_to_world(chosen).distance_to(start_world)<rig.terrain.grid_to_world(opposite).distance_to(start_world)
	print("T3_DIAG chosen=",chosen," opposite=",opposite)
	_check(HEX.distance(chosen,TARGET)==1 and closer,"T3 leader stands on the neighbor cell facing the approach, not the far side")
	rig.scene.free()

func _test_t4_free_target()->void:
	var rig:=_make_rig(_cells(10,6))
	var squad:=_squad(rig,1)
	var fmc:=FMC.new()
	_start_take(rig,fmc,squad)
	var result:=_run_take(rig,fmc,squad,25.0)
	_check(_grid(rig,"take_a")==TARGET and result.stuck.is_empty(),"T4 free target: the leader reaches the target cell itself")
	rig.scene.free()

func _test_t5_moving_comrade()->void:
	var rig:=_make_rig(_cells(8,6))
	for id in ["take_a","take_b"]:_add_actor(rig,id,"team_alpha","ft1",id=="take_a")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["take_a"]),Vector2i(0,2))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["take_b"]),Vector2i(3,2))
	var away:Vector2=rig.terrain.grid_to_world(Vector2i(3,5))
	var command:=_command("take_b",away);command.team_id="team_alpha"
	rig.sim.enqueue_command(command)
	rig.sim._physics_process(TICK)
	var fmc:=FMC.new()
	var records:Array=[{"unit_id":"take_a"},{"unit_id":"take_b"}]
	var desired:Dictionary={"take_a":rig.terrain.grid_to_world(Vector2i(3,2)),"take_b":away}
	var repaired:Dictionary=fmc._resolve_occupied_hex_formation_targets(rig.sim,records,desired,rig.terrain,PackedStringArray(["take_a","take_b"]))
	_check(repaired.is_empty(),"T5 comrade that is leaving its cell is not treated as an occupier")
	rig.scene.free()

func _test_t6_all_neighbors_blocked()->void:
	var neighbors:Array[Vector2i]=HEX.neighbors(TARGET)
	var rig:=_make_rig(_cells(10,6,[neighbors[0],neighbors[1],neighbors[2]]))
	var squad:=_squad(rig,1)
	_add_actor(rig,"enemy_1","team_enemy","enemy_ft")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["enemy_1"]),TARGET)
	for i in range(3,6):
		var id:="blocker_%d"%i
		_add_actor(rig,id,"team_enemy","enemy_ft")
		rig.sim.admit_hex_ground_actor_group(PackedStringArray([id]),neighbors[i])
	var fmc:=FMC.new()
	_start_take(rig,fmc,squad)
	var result:=_run_take(rig,fmc,squad,10.0)
	_diag("T6_DIAG",rig,squad,result)
	_check(_changes(result.history,"take_a")<=5,"T6 all neighbors blocked: issued target changes stay within 5 over 100 ticks (%d)"%_changes(result.history,"take_a"))
	rig.scene.free()
