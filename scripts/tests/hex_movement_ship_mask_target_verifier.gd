extends SceneTree
# Ziel unter der Maske eines gelandeten Schiffs: der Befehl darf nicht endlos
# warten (waiting_reservation/target_occupied). Eine Einheit auf dem Zielfeld
# bleibt dagegen ein normales Warten.
const MOVE=preload("res://scripts/core/hex_movement_command_runtime.gd")
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const BASE=preload("res://scripts/core/base_personnel_actor.gd")
var passed:=0
var failed:=0
class Owner extends Node:
	const MOVE_SPEED_PER_SECOND=80.0
	var tick_counter:=0
	var navigation_budget_enabled:=false
	var navigation_max_new_path_queries_per_tick:=4
	var units
	var ground
	var blocked:Array=[]
	var known:Dictionary={}
	func _get_hex_respawn_ship_mask()->Dictionary:return {"ok":true,"blocked_cells":blocked,"source_signature":str(blocked)}
	func get_hex_ground_context_revision()->int:return 1
	func _get_unit_registry():return units
	func _resolve_known_unit_for_contract(id:String):
		var actor=known.get(id)
		return actor if is_instance_valid(actor) else units.get_unit(id)
	func _extract_move_speed_factor(command:Dictionary,_actor)->float:return float(command.get("move_speed_factor",1.0))
	func _build_navigation_cost_options(_command:Dictionary,_registry)->Dictionary:return {}
	func create_regional_navigation_search(from_grid:Vector2i,to_grid:Vector2i,registry,options:Dictionary={}):
		return preload("res://scripts/terrain/terrain_pathfinder.gd").RegionalHexSearch.new(from_grid,to_grid,registry.get_revision(),options,registry)
	func _note_regional_navigation_backend(_search)->String:return "gdscript"
	func _commit_hex_movement_facing(id:String,direction:int)->void:ground.commit_facing(id,direction)
	func commit_hex_ground_plan(plan:Dictionary,revision:int)->Dictionary:return ground.commit_plan(plan,revision)
	func stop_hex_ground_units(ids:PackedStringArray,reason:String)->Dictionary:return ground.stop_units(ids,reason)
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func rig(records:Array,ship_cells:Array)->Dictionary:
	var owner=Owner.new();root.add_child(owner)
	owner.blocked=ship_cells
	var terrain=REGISTRY.new();owner.add_child(terrain);terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for q in range(6):
		for r in range(2):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,r],"grid_position":Vector2i(q,r),"walkable":true}))
	var units=UNITS.new();owner.add_child(units);owner.units=units
	var ground=GROUND.new();ground.configure(terrain,"ship-mask-target",0);owner.ground=ground
	var placements:Array[Dictionary]=[]
	for record in records:
		var actor=BASE.new();actor.unit_id=record.id;owner.add_child(actor);units.register_unit(record.id,actor);owner.known[record.id]=actor
		placements.append({"unit_id":record.id,"grid":record.grid})
	assert(ground.admit_units(placements).ok)
	var movement=MOVE.new();movement.configure(owner,terrain,ground)
	for record in records:
		if record.has("goal"):
			assert(movement.stage_move({"type":"move_to_position","unit_id":record.id,"team_id":"blue","target_position":terrain.grid_to_world(record.goal),"command_token":"source-"+record.id,"move_speed_factor":1.0,"requeue_until_target":true},units.get_unit(record.id)).ok)
	return {"owner":owner,"ground":ground,"movement":movement}
func step(r:Dictionary,count:int)->void:
	for i in range(count):
		r.owner.tick_counter+=1
		r.movement.notify_ground_events(r.ground.advance_tick(r.owner.tick_counter))
		r.movement.tick(0.1)
func run()->void:
	var ship:Array=[Vector2i(3,0)]
	var r:Dictionary=rig([{"id":"a","grid":Vector2i(1,0),"goal":Vector2i(3,0)}],ship.duplicate())
	step(r,60)
	var a:Dictionary=r.movement.get_readout("a")
	check(a.status=="blocked" and a.reason=="target_ship_occupied","goal under a landed ship ends blocked with a named reason instead of waiting (status=%s reason=%s)"%[a.status,a.reason])
	check(r.ground.read_unit("a").grid!=Vector2i(3,0),"the unit never enters the ship cell")
	r.owner.blocked=[]
	step(r,400)
	check(r.ground.read_unit("a").grid==Vector2i(3,0),"after the ship is gone the same order walks to the freed goal")
	r.owner.free()
	r=rig([{"id":"a","grid":Vector2i(2,0),"goal":Vector2i(3,0)},{"id":"b","grid":Vector2i(1,0),"goal":Vector2i(3,0)}],ship.duplicate())
	step(r,120)
	var first:Dictionary=r.movement.get_readout("a");var second:Dictionary=r.movement.get_readout("b")
	check(first.status=="blocked" and second.status=="blocked","second unit behind the first does not wait without end (a=%s/%s b=%s/%s)"%[first.status,first.reason,second.status,second.reason])
	r.owner.free()
	r=rig([{"id":"a","grid":Vector2i(1,0),"goal":Vector2i(3,0)},{"id":"c","grid":Vector2i(3,0)}],[])
	step(r,120)
	var waiting:Dictionary=r.movement.get_readout("a")
	check(waiting.status=="waiting_reservation" and waiting.reason=="target_occupied","goal held by another unit still waits (status=%s reason=%s)"%[waiting.status,waiting.reason])
	r.owner.free()
	print("SHIP_MASK_TARGET passed=%d failed=%d"%[passed,failed])
	quit(0 if failed==0 else 1)
