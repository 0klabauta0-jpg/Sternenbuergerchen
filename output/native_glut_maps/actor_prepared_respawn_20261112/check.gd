extends SceneTree
const ACTOR=preload("res://scripts/npc/test_unit.gd")
const SIM=preload("res://scripts/core/simulation_root.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const COMMAND=preload("res://scripts/npc/unit_command.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const MANAGER=preload("res://scripts/core/respawn_manager.gd")
var passed:=0
var failed:=0
class PoseWatch extends Node2D:
 var actor
 var barrier:Dictionary
 var armed:=false
 var notifications:=0
 var consistent:=true
 func _notification(what:int)->void:
  if what==NOTIFICATION_TRANSFORM_CHANGED and armed:
   notifications+=1
   consistent=consistent and barrier.ready and actor.get_vital_state()=="fit" and actor.get_health()==actor.max_health_points and actor.get_runtime_status().status=="idle" and actor.get_current_unit_command()==null and not actor.is_in_contact() and actor.get_last_damage_context().is_empty()
func check(ok:bool,label:String)->void:
 if ok:passed+=1
 else:failed+=1
 print("PASS " if ok else "FAIL ",label)
func _initialize()->void:call_deferred("run")
func rig()->Dictionary:
 var holder=Node.new();root.add_child(holder)
 var units=UNITS.new();units.name="Units";holder.add_child(units)
 var sim=SIM.new();sim.name="Root";sim.unit_registry_path=NodePath("../Units");holder.add_child(sim);sim.set_physics_process(false);sim.set_process(false)
 var manager=MANAGER.new();manager.unit_registry_path=NodePath("../Units");manager.simulation_root_path=NodePath("../Root");holder.add_child(manager);manager.set_physics_process(false)
 var frame=Node2D.new();frame.position=Vector2(120,75);frame.rotation=0.35;frame.scale=Vector2(1.5,0.75);holder.add_child(frame)
 var actor=ACTOR.new();actor.unit_id="medical";actor.team_id="blue";frame.add_child(actor);actor.position=Vector2(23,17);actor.set_process(false);actor.set_respawn_manager(manager)
 units.register_unit("medical",actor);sim.register_known_unit("medical",actor)
 assert(actor.assign_unit_command(COMMAND.new({"command_type":"move_to_position","unit_id":"medical","team_id":"blue","target_position":Vector2(30,40),"command_token":"old"})))
 actor.set_contact_state(true,"enemy")
 actor.apply_damage(actor.max_health_points,{"source_unit_id":"enemy","hit_position":Vector2(4,5)})
 return {"holder":holder,"units":units,"root":sim,"manager":manager,"frame":frame,"actor":actor}
func bind_ground(r:Dictionary,name:String)->void:
 if not r.has("terrain"):
  var terrain=REGISTRY.new();r.holder.add_child(terrain);terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
  for q in range(2):
   for row in range(2):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,row],"grid_position":Vector2i(q,row)}))
  r.terrain=terrain
 var map=MAP.create_empty(name,Vector2i(2,2),Vector2.ZERO,64,32,3,"hex_axial_v1");map.set_tactical_grid_rules("hex_tactical_v1")
 assert(r.root.configure_hex_ground_runtime(map,r.terrain).ok)
func run()->void:
 var r:Dictionary=rig();var actor=r.actor
 check(actor.has_method("prepare_actor_respawn") and actor.has_method("validate_prepared_actor_respawn") and actor.has_method("_publish_prepared_actor_respawn") and actor.has_method("finalize_actor_respawn"),"Real TestUnit exposes additive prepared medical bridge")
 if failed:r.holder.free();finish();return
 var origin:Vector2=actor.global_position
 var old_vital=actor.get_vital_status();var old_runtime=actor.get_runtime_status();var old_command=actor.get_current_unit_command()
 var old_damage:Dictionary=actor.get_last_damage_context()
 var old_runtime_data:Dictionary=old_runtime.to_dict().duplicate(true)
 var prepared:Dictionary=actor.prepare_actor_respawn(r.root,"begin")
 check(prepared.get("ok",false) and actor.get_vital_status()==old_vital and actor.get_runtime_status()==old_runtime and actor.get_current_unit_command()==old_command and actor.global_position==origin,"Prepare uses real models without mutating vitals/runtime/command/pose")
 var events:Dictionary={"order":[],"complete":true,"replay":false,"ready":false}
 var handle:RefCounted=prepared.prepared
 actor.runtime_status_changed.connect(func(_runtime):
  events.order.append("runtime")
  events.complete=events.complete and events.ready and actor.get_vital_state()=="respawning" and actor.get_runtime_status().status=="idle" and actor.get_current_unit_command()==null and not actor.is_in_contact()
  events.replay=actor.finalize_actor_respawn(handle).get("replayed",false))
 actor.vital_status_changed.connect(func(_vital):events.order.append("vital"))
 var validated:Dictionary=actor.validate_prepared_actor_respawn(handle);assert(validated.ok)
 check(actor.finalize_actor_respawn(handle).get("reason")=="actor_respawn_not_published" and events.order.is_empty(),"No medical callbacks before actor publication")
 assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 check(events.order.is_empty() and actor.get_vital_state()=="respawning" and actor.get_health()==0 and actor.get_runtime_status().status=="idle" and actor.get_current_unit_command()==null and not actor.is_in_contact() and actor.get_contact_target_id().is_empty() and actor.global_position==origin,"BEGIN publishes every actual actor model silently and leaves WORLDposition unchanged")
 check(actor.get_last_damage_context()==old_damage and old_vital.state=="down" and old_runtime.to_dict()==old_runtime_data and actor.get_runtime_status()!=old_runtime,"BEGIN preserves legacy lastDamage and does not mutate previous model objects")
 events.ready=true
 check(actor.finalize_actor_respawn(handle).get("ok",false) and events.order==["runtime","vital"] and events.complete and events.replay and actor.global_position==origin and actor.rotation_degrees==45.0,"BEGIN actual signal order/reentry and existing visual angle with unchanged WORLDposition")
 check(not actor.validate_prepared_actor_respawn(handle).get("ok",false) and actor.finalize_actor_respawn(handle).get("replayed",false) and events.order.size()==2,"Consumed BEGIN cannot publish or emit twice")
 # Fresh complete observers do not inherit the BEGIN expectation.
 for connection in actor.runtime_status_changed.get_connections():actor.runtime_status_changed.disconnect(connection.callable)
 for connection in actor.vital_status_changed.get_connections():actor.vital_status_changed.disconnect(connection.callable)
 actor.set_contact_state(true,"again")
 var goal:=Vector2(401,233)
 prepared=actor.prepare_actor_respawn(r.root,"complete",goal);assert(prepared.ok);handle=prepared.prepared
 var complete:Dictionary={"ready":false,"order":[],"consistent":true,"replay":false}
 var watch=PoseWatch.new();watch.actor=actor;watch.barrier=complete;actor.add_child(watch);watch.set_notify_transform(true);watch.force_update_transform();watch.armed=true
 actor.vital_status_changed.connect(func(_vital):
  complete.order.append("vital")
  complete.consistent=complete.consistent and complete.ready and actor.global_position.is_equal_approx(goal) and actor.get_health()==actor.max_health_points and actor.get_vital_state()=="fit" and actor.get_runtime_status().status=="idle" and actor.get_current_unit_command()==null and not actor.is_in_contact() and actor.get_last_damage_context().is_empty()
  complete.replay=actor.finalize_actor_respawn(handle).get("replayed",false))
 actor.runtime_status_changed.connect(func(_runtime):complete.order.append("runtime"))
 validated=actor.validate_prepared_actor_respawn(handle);assert(validated.ok);assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 check(complete.order.is_empty() and watch.notifications==0 and actor.global_position==origin and actor.get_vital_state()=="fit" and actor.get_health()==actor.max_health_points and actor.get_current_unit_command()==null and not actor.is_in_contact() and actor.get_last_damage_context().is_empty(),"COMPLETE model tail has neither signals nor pose notifications")
 complete.ready=true
 check(actor.finalize_actor_respawn(handle).get("ok",false) and actor.global_position.is_equal_approx(goal) and not actor.position.is_equal_approx(goal),"COMPLETE projects canonical WORLDposition under transformed parent")
 watch.force_update_transform()
 check(complete.order==["vital","runtime"] and complete.consistent and complete.replay,"COMPLETE preserves legacy vital then runtime order with fully consistent models")
 check(watch.notifications>0 and watch.consistent,"Actual Canvas transform notifications occur only after model barrier")
 check(not actor.prepare_actor_respawn(r.root,"begin").get("ok",false) and not actor.prepare_actor_respawn(r.root,"complete",goal).get("ok",false),"Fit actor is ineligible for either medical transition")
 r.holder.free()
 var stale:Dictionary=rig();actor=stale.actor
 prepared=actor.prepare_actor_respawn(stale.root,"begin");actor.get_vital_status().bleedout_ticks+=1
 check(actor.validate_prepared_actor_respawn(prepared.prepared).get("reason")=="actor_respawn_context_changed","Inplace real Vitals mutation invalidates preparation")
 prepared=actor.prepare_actor_respawn(stale.root,"begin");actor.get_current_unit_command().priority+=1
 check(actor.validate_prepared_actor_respawn(prepared.prepared).get("reason")=="actor_respawn_context_changed","Inplace real Command mutation invalidates preparation")
 prepared=actor.prepare_actor_respawn(stale.root,"begin");stale.root.release_hex_ground_unit("medical","fixture-lifecycle")
 check(actor.validate_prepared_actor_respawn(prepared.prepared).get("reason")=="actor_respawn_context_changed","Actual Root lifecycle change invalidates actor preparation")
 var other=SIM.new();other.unit_registry_path=NodePath("../OtherUnits");var other_units=UNITS.new();other_units.name="OtherUnits";stale.holder.add_child(other_units);stale.holder.add_child(other)
 check(not actor.prepare_actor_respawn(other,"begin").get("ok",false),"Another real Root without exact registry binding cannot prepare actor")
 var foreign=ACTOR.new();foreign.unit_id="foreign";stale.frame.add_child(foreign);foreign.set_process(false)
 check(not foreign.validate_prepared_actor_respawn(prepared.prepared).get("ok",false),"Opaque preparation cannot be used on a different real actor")
 actor.advance_bleedout();prepared=actor.prepare_actor_respawn(stale.root,"begin")
 check(prepared.get("ok",false) and actor.get_vital_state()=="bleedout","Existing real bleedout also eligible for BEGIN")
 check(not actor.prepare_actor_respawn(stale.root,"complete",Vector2(NAN,0)).get("ok",false),"Nonfinite WORLDposition rejects before any model write")
 stale.holder.free()
 var reentrant:Dictionary=rig();actor=reentrant.actor
 prepared=actor.prepare_actor_respawn(reentrant.root,"complete",Vector2(200,300));assert(prepared.ok);handle=prepared.prepared
 var changed:Dictionary={"runtime":0,"vital":0}
 actor.vital_status_changed.connect(func(_vital):
  changed.vital+=1
  if changed.vital==1:actor.apply_damage(1,{"source_unit_id":"observer"}))
 actor.runtime_status_changed.connect(func(_runtime):changed.runtime+=1)
 validated=actor.validate_prepared_actor_respawn(handle);assert(validated.ok);assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 check(actor.finalize_actor_respawn(handle).get("context_changed",false) and changed.vital==2 and changed.runtime==0 and actor.get_health()==actor.max_health_points-1,"Real reentrant damage prevents stale remaining runtime event or reset")
 reentrant.holder.free()
 var life:Dictionary=rig();bind_ground(life,"life-original");actor=life.actor
 prepared=actor.prepare_actor_respawn(life.root,"complete",Vector2(310,230));assert(prepared.ok);handle=prepared.prepared;validated=actor.validate_prepared_actor_respawn(handle);assert(validated.ok);assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 var life_events:Array=[]
 actor.vital_status_changed.connect(func(_v):life_events.append("vital"));actor.runtime_status_changed.connect(func(_v):life_events.append("runtime"))
 var context:int=life.root.get_hex_ground_context_revision();life.root.release_hex_ground_unit("medical","legitimate-respawn-lifecycle")
 check(life.root.get_hex_ground_context_revision()==context and actor.finalize_actor_respawn(handle).get("ok",false) and life_events==["vital","runtime"] and actor.global_position.is_equal_approx(Vector2(310,230)),"Lifecycle-only Root change permits legitimate respawn finalize")
 life.holder.free()
 var reset:Dictionary=rig();bind_ground(reset,"old-world");actor=reset.actor
 var reset_origin:Vector2=actor.global_position
 prepared=actor.prepare_actor_respawn(reset.root,"complete",Vector2(500,600));assert(prepared.ok);handle=prepared.prepared;validated=actor.validate_prepared_actor_respawn(handle);assert(validated.ok);assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 var reset_events:Array=[];actor.vital_status_changed.connect(func(_v):reset_events.append("vital"));actor.runtime_status_changed.connect(func(_v):reset_events.append("runtime"))
 var registry_id:int=reset.root.get_unit_registry().get_instance_id();context=reset.root.get_hex_ground_context_revision();bind_ground(reset,"new-world")
 check(reset.root.get_unit_registry().get_instance_id()==registry_id and reset.root.get_hex_ground_context_revision()!=context and actor.finalize_actor_respawn(handle).get("context_changed",false) and reset_events.is_empty() and actor.global_position==reset_origin,"Same Root and Registry rebound before finalize suppresses old WORLDpose and all events")
 reset.holder.free()
 var callback_reset:Dictionary=rig();bind_ground(callback_reset,"before-callback");actor=callback_reset.actor
 prepared=actor.prepare_actor_respawn(callback_reset.root,"complete",Vector2(330,420));assert(prepared.ok);handle=prepared.prepared;validated=actor.validate_prepared_actor_respawn(handle);assert(validated.ok);assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 var callback_events:Array=[]
 actor.vital_status_changed.connect(func(_v):callback_events.append("vital");bind_ground(callback_reset,"during-vital");actor.global_position=Vector2(-130,40))
 actor.runtime_status_changed.connect(func(_v):callback_events.append("runtime"))
 check(actor.finalize_actor_respawn(handle).get("context_changed",false) and callback_events==["vital"] and actor.global_position.is_equal_approx(Vector2(-130,40)),"Context rebound inside COMPLETE first callback suppresses stale remaining event and pose")
 callback_reset.holder.free()
 var begin_reset:Dictionary=rig();bind_ground(begin_reset,"before-begin");actor=begin_reset.actor
 prepared=actor.prepare_actor_respawn(begin_reset.root,"begin");assert(prepared.ok);handle=prepared.prepared;validated=actor.validate_prepared_actor_respawn(handle);assert(validated.ok);assert(actor._publish_prepared_actor_respawn(handle,validated).ok)
 var begin_events:Array=[]
 actor.runtime_status_changed.connect(func(_v):begin_events.append("runtime");bind_ground(begin_reset,"during-runtime"))
 actor.vital_status_changed.connect(func(_v):begin_events.append("vital"))
 check(actor.finalize_actor_respawn(handle).get("context_changed",false) and begin_events==["runtime"],"Context rebound inside BEGIN first callback suppresses stale vital event")
 begin_reset.holder.free();finish()
func finish()->void:
 print("ACTOR_PREPARED_RESPAWN passed=",passed," failed=",failed)
 quit(0 if failed==0 else 1)
