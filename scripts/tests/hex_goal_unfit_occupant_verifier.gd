extends SceneTree
## Stillstand-Befund 1e-B: Ein Bewegungsziel, das ein NICHT fitter Besetzer
## (niedergestreckt/tot) haelt, wird von der Bewegungs-Laufzeit auf eine freie
## Nachbarzelle umgelenkt. Fitte Besetzer bleiben ein Grund zu warten.
const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
var passed:=0
var failed:=0
class CMD extends RefCounted:
	var command_type:="move_to_position"
	var target_position:Vector2
	var command_token:=""
class Actor extends Node2D:
	var unit_id:String
	var current_command:RefCounted
	var target_position:Vector2
	var vital_state:="fit"
	var health:=100
	func get_unit_id():return unit_id
	func get_team_id():return "blue"
	func get_vital_state():return vital_state
	func get_current_unit_command():return current_command
	func assign_unit_command(value):current_command=value
	func set_target_position(value):target_position=value
	func get_target_position():return target_position
	func get_move_speed_factor():return 1.0
	func get_combat_speed_multiplier():return 1.0
	func refresh_terrain_readability():pass
	func get_health():return health
	func apply_damage(_amount:int,_context:Dictionary={}):return true
func _init()->void:call_deferred("_run")
func _check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _command(id:String,target:Vector2,token:String)->Dictionary:
	return {"type":"move_to_position","unit_id":id,"team_id":"blue","target_position":target,"move_speed_factor":1.0,"command_token":token,"requeue_until_target":true}
# tiles: Array of Vector2i; units: Array of {id,grid,vital}
func _rig(size:Vector2i,tiles:Array,units:Array)->Dictionary:
	var terrain=REGISTRY.new()
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for grid in tiles:terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[grid.x,grid.y],"grid_position":grid}))
	var registry=UNITS.new()
	root.add_child(registry)
	var sim=SIM.new()
	root.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	sim.local_avoidance_enabled=true
	sim.unit_minimum_spacing_enabled=true
	sim.bottleneck_reservation_enabled=true
	var map=MAP.create_empty("goal_unfit",size,Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actors:Dictionary={}
	var batch:Array[Dictionary]=[]
	for record in units:
		var actor=Actor.new()
		actor.unit_id=record.id
		root.add_child(actor)
		actor.global_position=terrain.grid_to_world(record.grid)
		registry.register_unit(record.id,actor)
		sim.register_known_unit(record.id,actor)
		actors[record.id]=actor
		batch.append({"unit_id":record.id,"grid":record.grid})
	sim.admit_hex_ground_units(batch)
	for record in units:actors[record.id].vital_state=String(record.get("vital","fit"))
	return {"sim":sim,"terrain":terrain,"registry":registry,"actors":actors}
func _free_rig(rig:Dictionary)->void:
	for actor in rig.actors.values():actor.free()
	rig.sim.free()
	rig.registry.free()
	rig.terrain.free()
func _tiles(width:int,height:int)->Array:
	var tiles:Array=[]
	for x in range(width):
		for y in range(height):tiles.append(Vector2i(x,y))
	return tiles
func _run_ticks(rig:Dictionary,count:int,token:String="")->void:
	for i in range(count):
		rig.sim._physics_process(0.25)
		if token!="" and rig.sim.has_hex_destination_arrived("a",token):break
func _run()->void:
	_test_unfit_goal_redirected()
	_test_fit_occupant_still_waits()
	_test_chain_behind_stuck_waiter()
	_finish()

func _test_unfit_goal_redirected()->void:
	var rig:Dictionary=_rig(Vector2i(6,2),_tiles(6,2),[{"id":"a","grid":Vector2i(0,0)},{"id":"d","grid":Vector2i(3,0),"vital":"down"}])
	var sim=rig.sim
	sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(3,0)),"move_a"))
	_run_ticks(rig,160,"move_a")
	var readout:Dictionary=sim.get_hex_movement_readout("a")
	print("INFO redirect readout=",readout," grid=",sim.get_hex_unit_state("a").grid)
	_check(String(readout.get("reason",""))!="target_occupied","goal on a downed unit is not left waiting on target_occupied")
	_check(String(readout.get("status",""))=="arrived" and sim.has_hex_destination_arrived("a","move_a"),"unit arrives on a free neighbour of the fallen")
	var grid:Vector2i=sim.get_hex_unit_state("a").grid
	_check(grid!=Vector2i(3,0) and HEX.distance(grid,Vector2i(3,0))==1,"unit stops directly next to the fallen unit")
	_check(sim.get_hex_unit_state("d").grid==Vector2i(3,0),"the fallen unit keeps its own cell")
	# W1: die Ausweichzelle ist das wirksame Ziel. Die Fragen "angekommen?" (Speicherpruefung, Einzelsteuerung) nennen die
	# BEFOHLENE Zelle und muessen trotzdem mit "ja" antworten.
	var original_target:Vector2=rig.terrain.grid_to_world(Vector2i(3,0))
	_check(sim.has_hex_position_arrived("a",original_target,"move_a"),"W1: arrival at the redirect cell counts as arrived for the commanded target")
	var command=CMD.new()
	command.target_position=original_target
	command.command_token="move_a"
	var checkpoint=load("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd").new()
	_check(checkpoint._command_is_stable(sim,rig.actors.a,command),"W1: the save check sees the redirected move as finished (no mission_movement_pending)")
	_check(not sim.has_hex_position_arrived("a",rig.terrain.grid_to_world(Vector2i(5,1)),"move_a"),"W1: an unrelated target is still not arrived")
	var movement=sim.get("_hex_movement_runtime")
	var saved:Dictionary=movement.export_state()
	var prepared:Dictionary=movement.prepare_restore_state(JSON.parse_string(JSON.stringify(saved)))
	_check(prepared.get("ok",false),"a redirected goal still passes real movement save validation")
	_free_rig(rig)

func _test_fit_occupant_still_waits()->void:
	var rig:Dictionary=_rig(Vector2i(6,2),_tiles(6,2),[{"id":"a","grid":Vector2i(0,0)},{"id":"d","grid":Vector2i(3,0)}])
	var sim=rig.sim
	sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(3,0)),"move_a"))
	_run_ticks(rig,40)
	var readout:Dictionary=sim.get_hex_movement_readout("a")
	_check(String(readout.get("status",""))=="waiting_reservation" and String(readout.get("reason",""))=="target_occupied","a fit stationary occupant still makes the goal wait")
	_check(sim.get_hex_unit_state("a").grid==Vector2i(0,0),"the waiting unit does not move onto or past a fit occupant")
	_free_rig(rig)

## Kette (Ergaenzung D): c wartet mit target_occupied auf einen fitten, haltenden d.
## a soll hinter c vorbei; die kuerzeste Strecke fuehrt durch c, ein laengerer Umweg existiert.
## c blockiert dauerhaft, also muss die Wegsuche c wie eine ruhende Einheit behandeln.
func _test_chain_behind_stuck_waiter()->void:
	var rig:Dictionary=_rig(Vector2i(5,3),_tiles(5,3),[{"id":"a","grid":Vector2i(0,1)},{"id":"c","grid":Vector2i(1,1)},{"id":"d","grid":Vector2i(1,2)}])
	var sim=rig.sim
	sim.enqueue_command(_command("c",rig.terrain.grid_to_world(Vector2i(1,2)),"move_c"))
	_run_ticks(rig,8)
	_check(String(sim.get_hex_movement_readout("c").get("reason",""))=="target_occupied","chain: c waits on the fit holder d")
	sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(3,1)),"move_a"))
	_run_ticks(rig,200,"move_a")
	var readout:Dictionary=sim.get_hex_movement_readout("a")
	print("INFO chain readout a=",readout," grid=",sim.get_hex_unit_state("a").grid)
	_check(String(readout.get("reason",""))!="backoff_required","chain: a does not wait on a stuck waiter")
	_check(sim.has_hex_destination_arrived("a","move_a") and sim.get_hex_unit_state("a").grid==Vector2i(3,1),"chain: a takes the detour and arrives")
	_check(sim.get_hex_unit_state("c").grid==Vector2i(1,1),"chain: the waiting unit stays where it is")
	_free_rig(rig)

func _finish()->void:
	print("HEX_GOAL_UNFIT_OCCUPANT passed=%d failed=%d"%[passed,failed])
	quit(0 if failed==0 else 1)
