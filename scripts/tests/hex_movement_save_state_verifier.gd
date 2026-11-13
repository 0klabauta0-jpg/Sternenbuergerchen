extends SceneTree
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
 var context:=1
 var navigation_budget_enabled:=false
 var navigation_max_new_path_queries_per_tick:=4
 var units
 var ground
 var blocked:Array=[]
 func _get_hex_respawn_ship_mask()->Dictionary:return {"ok":true,"blocked_cells":blocked,"source_signature":str(blocked)}
 var resolve_calls:=0
 var known:Dictionary={}
 func get_hex_ground_context_revision()->int:return context
 func _get_unit_registry():return units
 func _resolve_known_unit_for_contract(id:String):
  resolve_calls+=1
  var actor=known.get(id)
  return actor if is_instance_valid(actor) else units.get_unit(id)
 func _extract_move_speed_factor(command:Dictionary,_actor)->float:return float(command.get("move_speed_factor",1.0))
 func _build_navigation_cost_options(_command:Dictionary,_registry)->Dictionary:return {}
 func _commit_hex_movement_facing(id:String,direction:int)->void:ground.commit_facing(id,direction)
 func commit_hex_ground_plan(plan:Dictionary,revision:int)->Dictionary:return ground.commit_plan(plan,revision)
 func stop_hex_ground_units(ids:PackedStringArray,reason:String)->Dictionary:return ground.stop_units(ids,reason)
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 if ok:passed+=1
 else:failed+=1
 print("PASS " if ok else "FAIL ",label)
func copy(value:Dictionary)->Dictionary:return JSON.parse_string(JSON.stringify(value))
func rig(far_goal:bool=false)->Dictionary:
 var owner=Owner.new();root.add_child(owner)
 var terrain=REGISTRY.new();owner.add_child(terrain);terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
 for q in range(6):
  for r in range(2):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,r],"grid_position":Vector2i(q,r),"walkable":true}))
 var units=UNITS.new();owner.add_child(units);owner.units=units
 var ground=GROUND.new();ground.configure(terrain,"movement-save",0);owner.ground=ground
 var placements:Array[Dictionary]=[]
 for id in ["a","b"]:
  var actor=BASE.new();actor.unit_id=id;owner.add_child(actor);units.register_unit(id,actor);owner.known[id]=actor
  placements.append({"unit_id":id,"grid":Vector2i.ZERO if id=="a" else Vector2i.RIGHT})
 assert(ground.admit_units(placements).ok)
 var movement=MOVE.new();movement.configure(owner,terrain,ground)
 for id in ["a","b"]:
  var goal:Vector2=terrain.grid_to_world((Vector2i(5,0) if far_goal else Vector2i.RIGHT) if id=="a" else Vector2i.ZERO)+Vector2(0.125,0.0625)
  assert(movement.stage_move({"type":"move_to_position","unit_id":id,"team_id":"blue","target_position":goal,"priority":5 if id=="a" else 0,"command_token":"source-"+id,"move_speed_factor":0.5 if far_goal and id=="a" else 1.0,"movement_posture":"tactical","fire_rule":"return","requeue_until_target":true},units.get_unit(id)).ok)
 return {"owner":owner,"terrain":terrain,"units":units,"ground":ground,"movement":movement}
func step(r:Dictionary)->void:
 r.owner.tick_counter+=1
 var events:Array=r.ground.advance_tick(r.owner.tick_counter)
 r.movement.notify_ground_events(events)
 r.movement.tick(0.1)
func run()->void:
 var r:Dictionary=rig();var m=r.movement
 check(m.has_method("export_state") and m.has_method("prepare_restore_state") and m.has_method("validate_prepared_restore") and m.has_method("publish_prepared_restore"),"Movement exposes separated prepared restore APIs")
 if failed:r.owner.free();finish();return
 var original:Dictionary=m.export_state()
 check(original.get("schema")=="hex_movement_v1" and original.accepted_intents.size()==2,"Actual BaseActors and registered accepted intents export without NPC capabilities")
 var baseline:Dictionary=m.get_readout("a")
 var prepared:Dictionary=m.prepare_restore_state(copy(original))
 check(prepared.get("ok",false) and m.get_readout("a")==baseline,"Preparation leaves existing accepted intent untouched")
 check(m.publish_prepared_restore(prepared.prepared).get("ok",false) and m.get_readout("a").command_id==baseline.command_id and m.get_readout("a").source_command_id=="source-a","JSON restore preserves stable source and internal command IDs")
 check(m._orders.a.command.target_position==r.terrain.grid_to_world(Vector2i.RIGHT)+Vector2(0.125,0.0625) and m._orders.a.command.fire_rule=="return" and m._orders.a.command.movement_posture=="tactical","Original midcell world target and legitimate UnitCommand intent preserved")
 check(not m.publish_prepared_restore(prepared.prepared).get("ok",false),"Published preparation cannot replay after owner epoch changes")
 var bad:Dictionary=copy(original);bad.schema="unknown"
 check(not m.prepare_restore_state(bad).get("ok",false) and m.get_readout("a")==baseline,"Invalid schema rejects without losing old intent")
 bad=copy(original);bad.accepted_intents[0].goal_grid=[4294967296,0]
 check(not m.prepare_restore_state(bad).get("ok",false),"Overflow target rejects before grid cast")
 bad=copy(original);bad.accepted_intents.append(bad.accepted_intents[0].duplicate(true))
 check(not m.prepare_restore_state(bad).get("ok",false),"Duplicate accepted unit rejects")
 prepared=m.prepare_restore_state(copy(original));r.owner.context+=1
 check(not m.publish_prepared_restore(prepared.prepared).get("ok",false),"Root context reset invalidates preparation")
 prepared=m.prepare_restore_state(copy(original));r.ground.commit_facing("a",2)
 check(not m.publish_prepared_restore(prepared.prepared).get("ok",false),"Ground revision changes invalidate preparation")
 prepared=m.prepare_restore_state(copy(original))
 var old=r.units.get_unit("a");r.units.unregister_unit("a")
 var replacement=BASE.new();replacement.unit_id="a";r.owner.add_child(replacement);r.units.register_unit("a",replacement)
 check(not m.publish_prepared_restore(prepared.prepared).get("ok",false),"Known A preferred over Registry rebound B still invalidates preparation")
 r.units.unregister_unit("a");r.units.register_unit("a",old);replacement.free()
 prepared=m.prepare_restore_state(copy(original));old.unit_id="wrong"
 check(not m.publish_prepared_restore(prepared.prepared).get("ok",false),"Registered actor must expose the exact canonical unit ID")
 old.unit_id="a"
 prepared=m.prepare_restore_state(copy(original));var real_units=r.owner.units;r.owner.units=null
 check(m.publish_prepared_restore(prepared.prepared).get("reason")=="movement_save_unit_registry_unavailable","Unavailable actual UnitRegistry fails closed without fallback to Known")
 r.owner.units=real_units
 prepared=m.prepare_restore_state(copy(original));m.configure(r.owner,r.terrain,r.ground)
 check(not m.publish_prepared_restore(prepared.prepared).get("ok",false),"Sameobject configure cannot reuse previous prepared authority")
 prepared=m.prepare_restore_state(copy(original));assert(prepared.ok);assert(m.publish_prepared_restore(prepared.prepared).ok)
 var state:Dictionary=m.export_state();state.accepted_intents[0].wait_ticks=37;state.accepted_intents[0].status="waiting_reservation";state.accepted_intents[0].next_attempt_tick=4
 prepared=m.prepare_restore_state(copy(state));assert(prepared.ok);assert(m.publish_prepared_restore(prepared.prepared).ok)
 check(m.get_readout("a").wait_ticks==37 and m._orders.a.next_attempt_tick==4 and m._orders.a.path.is_empty() and m._orders.a.search==null,"Wait age/retry deadline preserved while derived paths and searches rebuild")
 m.stage_stop("a","fixture-stop")
 check(m.export_state().get("reason")=="movement_save_pending_stop","Pending stop is explicit saveguard rather than discarded queue")
 m.flush_stops()
 prepared=m.prepare_restore_state(copy(original));assert(prepared.ok);assert(m.publish_prepared_restore(prepared.prepared).ok)
 var saved:Dictionary=m.export_state();saved.accepted_intents[0].command_intent[0].value="changed"
 check(m._orders.a.command.command_token=="source-a","Export has no alias into live command intent")
 var detached_input:Dictionary=copy(original);prepared=m.prepare_restore_state(detached_input);detached_input.serial=999
 check(m.publish_prepared_restore(prepared.prepared).get("ok",false) and m._serial==int(original.serial),"Prepared handle has detached input without public mutable patch")
 # New goalground candidate is already privately validated by actual Ground.
 var ground_state:Dictionary=r.ground.export_state();ground_state.tick=1
 var target_result:Dictionary=r.ground.prepare_restore_state(ground_state);assert(target_result.ok)
 var target_ground=r.ground.get_prepared_restore_ground(target_result.prepared);assert(target_ground!=null)
 var future:Dictionary=copy(original);future.tick=1
 prepared=m.prepare_restore_state(future,target_ground)
 check(prepared.get("ok",false) and m.publish_prepared_restore(prepared.prepared).get("reason")=="movement_restore_joint_publish_required","Target Ground candidate may prepare but cannot accidentally publish against live Ground")
 var validated:Dictionary=m.validate_prepared_restore(prepared.prepared);assert(validated.ok)
 var ground_validation:Dictionary=r.ground.validate_prepared_restore(target_result.prepared);assert(ground_validation.ok)
 assert(r.ground._publish_prepared_restore(target_result.prepared,ground_validation).ok)
 var calls:int=r.owner.resolve_calls
 m._publish_prepared_restore(prepared.prepared,validated)
 check(r.owner.resolve_calls==calls and m.get_readout("a").command_id==baseline.command_id and r.ground.get_current_tick()==1,"Joint prevalidation supports Ground-first silent Movementtail without late callbacks")
 r.owner.tick_counter=1
 # Reverse coverage must hold for every real target Ground movement horizon.
 var coverage:Dictionary=rig(true)
 for i in range(4):
  step(coverage)
  if coverage.ground.read_unit("a").route_state.has_commitments or coverage.ground.read_unit("b").route_state.has_commitments:break
 var coverage_state:Dictionary=coverage.movement.export_state()
 var coverage_ground:Dictionary=coverage.ground.export_state()
 var ground_prepared:Dictionary=coverage.ground.prepare_restore_state(coverage_ground);assert(ground_prepared.ok)
 var ground_target=coverage.ground.get_prepared_restore_ground(ground_prepared.prepared);assert(ground_target!=null)
 var moving:String="a" if ground_target.read_unit("a").route_state.has_commitments else "b"
 assert(ground_target.read_unit(moving).route_state.has_commitments)
 bad=copy(coverage_state);bad.accepted_intents=[]
 check(coverage.movement.prepare_restore_state(bad,ground_target).get("reason")=="movement_save_missing_intent" and coverage.movement.export_state()==coverage_state and coverage.ground.export_state()==coverage_ground,"Empty intents cannot discard actual target Ground horizon; both owners unchanged")
 bad=copy(coverage_state)
 for i in range(bad.accepted_intents.size()-1,-1,-1):
  if bad.accepted_intents[i].unit_id==moving:bad.accepted_intents.remove_at(i)
 check(coverage.movement.prepare_restore_state(bad,ground_target).get("reason")=="movement_save_missing_intent" and coverage.movement.export_state()==coverage_state,"Subset missing moving member rejects without losing existing intents")
 coverage.owner.tick_counter+=1;coverage.ground.advance_tick(coverage.owner.tick_counter)
 assert(coverage.ground.stop_units(PackedStringArray(["a","b"]),"completed-stop").ok)
 var stop_state:Dictionary=coverage.ground.export_state();assert(not stop_state.centering.is_empty())
 ground_prepared=coverage.ground.prepare_restore_state(stop_state);assert(ground_prepared.ok)
 ground_target=coverage.ground.get_prepared_restore_ground(ground_prepared.prepared)
 bad=copy(coverage_state);bad.tick=coverage.owner.tick_counter;bad.accepted_intents=[]
 check(coverage.movement.prepare_restore_state(bad,ground_target).get("ok",false),"Pure stop centering remains restorable without move intents")
 coverage.owner.free()
 # A real swap makes real Planner backoff and rebuilds runtime paths.
 var recovery_rig:Dictionary=rig(true)
 var recovery_save:Dictionary={}
 for i in range(12):
  step(recovery_rig)
  var state_now:Dictionary=recovery_rig.movement.export_state()
  if state_now.get("schema")=="hex_movement_v1":
   for intent in state_now.accepted_intents:
    if not intent.recovery.is_empty():recovery_save=state_now
  if not recovery_save.is_empty():break
 check(not recovery_save.is_empty() and recovery_rig.movement.get_audit().navigation_jobs_created>0,"Actual tick and Planner produce accepted backoff recovery")
 if not recovery_save.is_empty():
  var yielding:String=""
  for intent in recovery_save.accepted_intents:
   if not intent.recovery.is_empty():yielding=intent.unit_id
  var readout:Dictionary=recovery_rig.movement.get_readout(yielding)
  var recovery:Dictionary=recovery_rig.movement._orders[yielding].recovery.duplicate(true)
  prepared=recovery_rig.movement.prepare_restore_state(copy(recovery_save));assert(prepared.ok)
  assert(recovery_rig.movement.publish_prepared_restore(prepared.prepared).ok)
  check(recovery_rig.movement.get_readout(yielding).goal_grid==readout.goal_grid and recovery_rig.movement.get_readout(yielding).wait_ticks==readout.wait_ticks and recovery_rig.movement._orders[yielding].recovery==recovery,"Real backoff retains original goal, waitage, clearance and cohort IDs")
  var other:String=recovery.waiters.keys()[0]
  var seen:Dictionary={};var saw_waiting:=false
  for i in range(96):
   recovery_rig.owner.tick_counter+=1
   var events:Array=recovery_rig.ground.advance_tick(recovery_rig.owner.tick_counter)
   recovery_rig.movement.notify_ground_events(events)
   var current:Dictionary=recovery_rig.movement._orders[yielding].recovery
   if current.get("phase")=="waiting_clearance":saw_waiting=true
   if not current.is_empty() and current.waiters[other].seen:
    seen=recovery_rig.movement.export_state();break
   recovery_rig.movement.tick(0.1)
  check(not seen.is_empty() and saw_waiting,"Real Ground handoff proves passage after actual waiting_clearance")
  if seen.is_empty():recovery_rig.owner.free();r.owner.free();finish();return
  prepared=recovery_rig.movement.prepare_restore_state(copy(seen));assert(prepared.ok);assert(recovery_rig.movement.publish_prepared_restore(prepared.prepared).ok)
  check(recovery_rig.movement._orders[yielding].recovery.waiters[other].seen and recovery_rig.movement._recovery_watchers[other].has(yielding),"Seen passage roundtrips and watcher index is rebuilt from canonical waiters")
  var broken:Dictionary=copy(seen)
  for intent in broken.accepted_intents:
   if not intent.recovery.is_empty():intent.recovery.waiters[0].command_id="wrong"
  check(not recovery_rig.movement.prepare_restore_state(broken).get("ok",false),"Recovery cannot bind waiter to a different command")
  for i in range(128):
   step(recovery_rig)
   if recovery_rig.movement.has_arrived("a","source-a") and recovery_rig.movement.has_arrived("b","source-b"):break
  check(recovery_rig.movement.has_arrived("a","source-a") and recovery_rig.movement.has_arrived("b","source-b"),"Restored real backoff completes both original goal intents")
 recovery_rig.owner.free()
 var dynamic:Dictionary=rig(true)
 var recovery_id:=""
 var blocked_goal:Vector2i
 for i in range(20):
  step(dynamic)
  for id in dynamic.movement._orders:
   var order:Dictionary=dynamic.movement._orders[id]
   if not order.recovery.is_empty():recovery_id=id;blocked_goal=order.recovery.goal_grid
  if not recovery_id.is_empty():break
 check(not recovery_id.is_empty(),"Dynamic ship test starts actual Planner recovery")
 if not recovery_id.is_empty():
  dynamic.owner.blocked=[blocked_goal]
  step(dynamic)
  check(dynamic.movement._orders[recovery_id].recovery.is_empty() and dynamic.movement.get_readout(recovery_id).reason=="backoff_target_invalidated","New external blocker aborts pending recovery while preserving original intent")
  var safe:=true
  for i in range(400):
   step(dynamic)
   for id in dynamic.movement._orders:
    var order:Dictionary=dynamic.movement._orders[id]
    safe=safe and (order.recovery.is_empty() or order.recovery.goal_grid!=blocked_goal) and dynamic.ground.read_unit(id).grid!=blocked_goal
   if dynamic.movement.has_arrived("a","source-a") and dynamic.movement.has_arrived("b","source-b"):break
  check(safe and dynamic.movement.has_arrived("a","source-a") and dynamic.movement.has_arrived("b","source-b"),"Same accepted intents find legal backoff around external blocker and both actually arrive")
 dynamic.owner.free();r.owner.free();finish()
func finish()->void:
 print("HEX_MOVEMENT_SAVE_STATE passed=",passed," failed=",failed)
 quit(0 if failed==0 else 1)
