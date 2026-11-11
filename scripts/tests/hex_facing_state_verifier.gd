extends SceneTree

const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const COMMAND=preload("res://scripts/npc/unit_command.gd")
var passed:=0
var failed:=0

class Actor extends Node2D:
	var command=COMMAND.new({"command_type":"hold_position","unit_id":"a"})
	var vital_state:="fit"
	func get_unit_id() -> String: return "a"
	func get_current_unit_command(): return command
	func get_vital_state() -> String: return vital_state
class DeniedSimulation extends SimulationRoot:
	var deny:=false
	func _should_skip_local_tick_processing() -> bool: return deny

func _init() -> void: call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)

func _run() -> void:
	var sim=SIM.new()
	root.add_child(sim)
	sim.set_physics_process(false)
	_check(sim.has_method("queue_hex_facing_intent"),"simulation owns queued hex facing intents")
	if failed>0:
		sim.free()
		_finish()
		return
	var terrain=REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"a","grid_position":Vector2i.ZERO,"walkable":true}))
	var map=MAP.create_empty("facing_fixture",Vector2i.ONE,Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO,"facing_dir":0}]
	sim.admit_hex_ground_units(batch)
	var actor:=Actor.new()
	root.add_child(actor)
	sim.register_known_unit("a",actor)
	_check(not sim.queue_hex_facing_intent("a",6,"bad","security_assignment").ok,"invalid direction rejected")
	_check(not sim.queue_hex_facing_intent("unknown",0,"bad","security_assignment").ok,"unknown ground unit rejected")
	_check(not sim.queue_hex_facing_intent("a",1,"","security_assignment").ok and not sim.queue_hex_facing_intent("a",1,"bad","unknown").ok,"missing command identity and unknown reason rejected")
	_check(sim.queue_hex_facing_intent("a",3,"first","security_assignment").ok and sim.get_hex_unit_state("a").facing_dir==0,"queue does not directly change logical facing")
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==0,"future intent cannot commit early")
	sim.tick_counter=1
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==3,"authoritative tick commits facing")
	var before:Dictionary=sim.get_hex_unit_state("a")
	_check(sim.queue_hex_facing_intent("a",3,"first","security_assignment").replayed and sim.get_hex_unit_state("a")==before,"replayed intent does not mutate unit revision")
	_check(not sim.queue_hex_facing_intent("a",1,"noise_hold","noise_reaction",4).ok,"noise cannot replace a hold/security order")
	actor.command=COMMAND.new({"command_type":"engage_area","unit_id":"a","source_command_type":"engage","command_token":"engage1"})
	_check(sim.queue_hex_facing_intent("a",1,"noise_free","noise_reaction",4).ok,"permitted assignment can receive delayed noise reaction")
	_check(sim.queue_hex_facing_intent("a",0,"secure","security_assignment").ok,"security assignment supersedes free reaction")
	sim.tick_counter=2
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==0,"higher priority security direction wins")
	_check(sim.queue_hex_facing_intent("a",1,"later_noise","noise_reaction",5).ok,"next reaction scheduled once")
	actor.command.command_token="engage2"
	sim.tick_counter=5
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==0,"changed order cancels stale reaction before commit")
	sim.queue_hex_facing_intent("a",3,"old_context","security_assignment",10)
	sim.configure_hex_ground_runtime(map,terrain)
	sim.admit_hex_ground_units(batch)
	sim.tick_counter=10
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==0,"new ground context discards old pending facing")
	for index in range(sim.HEX_FACING_REPLAY_CAPACITY+2):
		sim.queue_hex_facing_intent("a",0,"bounded_%d"%index,"security_assignment")
	_check(sim._hex_facing_seen.size()==sim.HEX_FACING_REPLAY_CAPACITY and sim._hex_facing_replay_keys.size()==sim.HEX_FACING_REPLAY_CAPACITY,"facing replay bookkeeping remains bounded")
	_check(sim.queue_hex_facing_intent("a",0,"bounded_%d"%(sim.HEX_FACING_REPLAY_CAPACITY+1),"security_assignment").replayed and not sim.queue_hex_facing_intent("a",0,"bounded_0","security_assignment").replayed,"replay ring retains recent IDs and evicts the oldest")
	sim.queue_hex_facing_intent("a",3,"actual_tick","security_assignment")
	_check(not sim.queue_hex_facing_intent("a",1,"lower_priority","noise_reaction").ok,"lower priority cannot replace a pending security turn")
	var observed:Array=[]
	sim.tick_processed.connect(func(_tick): observed.append(sim.get_hex_unit_state("a").facing_dir))
	sim.unit_minimum_spacing_enabled=false
	sim._physics_process(0.0)
	_check(sim.tick_counter==11 and sim.get_hex_unit_state("a").facing_dir==3 and observed==[3],"real physics tick commits facing before tick consumers")
	sim.queue_hex_facing_intent("a",1,"delayed_success","noise_reaction",15)
	sim.tick_counter=14
	sim.queue_hex_facing_intent("a",1,"repeated_direction","noise_reaction",17)
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==3,"delayed reaction retains facing before its exact deadline")
	sim.tick_counter=15
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==1,"delayed reaction commits exactly at its deadline")
	sim.queue_hex_facing_intent("a",0,"downed","security_assignment",18)
	actor.vital_state="downed"
	sim.tick_counter=18
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==1,"downed unit cannot commit a pending turn")
	actor.vital_state="fit"
	sim.queue_hex_facing_intent("a",0,"released","security_assignment",19)
	sim.release_hex_ground_unit("a","removed")
	_check(sim._hex_facing_pending.is_empty(),"release clears the unit's pending facing")
	sim.admit_hex_ground_units(batch)
	var denied:=DeniedSimulation.new()
	root.add_child(denied)
	denied.set_physics_process(false)
	denied.configure_hex_ground_runtime(map,terrain)
	denied.admit_hex_ground_units(batch)
	denied.register_known_unit("a",actor)
	denied.queue_hex_facing_intent("a",3,"denied_commit","security_assignment")
	denied.deny=true
	denied.tick_counter=1
	denied._commit_hex_facing_intents()
	_check(denied.get_hex_unit_state("a").facing_dir==0 and not denied.queue_hex_facing_intent("a",2,"denied_queue","security_assignment").ok,"missing authority prevents queue and pending commit")
	denied.free()
	sim.unregister_known_unit("a")
	actor.free()
	terrain.free()
	sim.free()
	_finish()

func _finish() -> void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("HEX_FACING_STATE_PASS")
	quit(0 if failed==0 else 1)
