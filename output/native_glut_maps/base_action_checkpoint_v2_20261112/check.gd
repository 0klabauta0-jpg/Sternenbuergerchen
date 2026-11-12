extends SceneTree
const BASE=preload("res://scripts/core/base_personnel_runtime.gd")
const ACTOR=preload("res://scripts/core/base_personnel_actor.gd")
const ROOT=preload("res://scripts/core/simulation_root.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const SCREEN=preload("res://scripts/meta/homebase_screen.gd")
var passed:=0
var failed:=0
class Flow extends Node:
 var _all_team_units:Array=[{"unit_id":"a"},{"unit_id":"b"}]
 var _aircraft_location_by_craft:Dictionary={"home_ship":"homebase"}
 func _find_homebase_aircraft_definition(id:String)->Dictionary:return {"craft_id":id} if id=="home_ship" else {}
 func _find_pending_mission_craft_transfer(_id:String)->Dictionary:return {}
class HomeEnvelope extends Node:
 func get_space_travel_snapshot(_craft:String)->Dictionary:return {"phase":"grounded"}
func check(ok:bool,label:String)->void:
 if ok:passed+=1
 else:failed+=1
 print("PASS " if ok else "FAIL ",label)
func copy(value:Dictionary)->Dictionary:return JSON.parse_string(JSON.stringify(value))
func _initialize()->void:call_deferred("run")
func rig(delta:float=0.1)->Dictionary:
 var holder=HomeEnvelope.new();root.add_child(holder)
 var terrain=REGISTRY.new();terrain.name="Terrain";holder.add_child(terrain);terrain.configure_iso_grid(Vector2(1536,64),16,8,"hex_axial_v1")
 for q in range(31,35):
  for row in range(28,31):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,row],"grid_position":Vector2i(q,row)}))
 var units=UNITS.new();units.name="Units";holder.add_child(units)
 var sim=ROOT.new();sim.unit_registry_path=NodePath("../Units");sim.terrain_registry_path=NodePath("../Terrain");holder.add_child(sim);sim.set_physics_process(false);sim.set_process(false)
 var map=MAP.create_empty("Authored original room clearance",Vector2i(384,392),Vector2(1536,64),16,8,3,"hex_axial_v1");map.set_tactical_grid_rules("hex_tactical_v1");assert(sim.configure_hex_ground_runtime(map,terrain).ok)
 var flow=Flow.new();holder.add_child(flow)
 var screen=SCREEN.new();screen._aircraft_manager.set_transport_state([{"craft_id":"home_ship"}],{},[])
 var base=BASE.new();holder.add_child(base);base._sim=sim;base._terrain=terrain;base._registry=units;base._flow=flow;base._screen=screen
 base._layout={"beds":[{"id":"habitat_bed_01","grid":[32,28]}],"terminals":[{"id":"personnel","grid":[32,30],"enabled":true}]}
 sim.configure_base_personnel(base);sim.tick_processed.connect(base._on_tick)
 var placements:Array[Dictionary]=[]
 for id in ["a","b"]:
  var actor=ACTOR.new();actor.unit_id=id;base.add_child(actor);units.register_unit(id,actor);sim.register_known_unit(id,actor)
  base._states[id]={"unit_id":id,"name":id,"role":"operator","status":"outside","craft_id":"","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":false,"rest_automatic":false,"idle_seconds":7.0,"manual_priority_seconds":12.0}
  placements.append({"unit_id":id,"grid":Vector2i(32,29) if id=="a" else Vector2i(33,29)})
 assert(sim.admit_base_ground_people(base,placements).ok)
 assert(base.request_operation("base_sleep",{"unit_id":"a","bed_id":"habitat_bed_01"}).ok)
 assert(base.request_operation("base_terminal",{"unit_id":"b","terminal_id":"personnel"}).ok)
 sim._physics_process(delta)
 base._poll_seconds=0.125;base._rest_elapsed=0.125
 base._states.a.idle_seconds=7.0;base._states.a.manual_priority_seconds=12.0
 return {"holder":holder,"sim":sim,"terrain":terrain,"units":units,"flow":flow,"screen":screen,"base":base,"ground":sim._hex_ground_runtime,"movement":sim._hex_movement_runtime}
func prepared_pair(r:Dictionary,g:Dictionary,m:Dictionary)->Dictionary:
 var ground:Dictionary=r.ground.prepare_restore_state(copy(g));assert(ground.ok)
 var target=r.ground.get_prepared_restore_ground(ground.prepared);assert(target!=null)
 var movement:Dictionary=r.movement.prepare_restore_state(copy(m),target);assert(movement.ok)
 return {"g":ground.prepared,"m":movement.prepared}
func run()->void:
 var r:Dictionary=rig();var base=r.base
 check(base.has_method("export_checkpoint_state") and base.has_method("prepare_restore_state") and base.has_method("validate_prepared_restore") and base.has_method("_publish_prepared_restore") and base.has_method("finalize_prepared_restore"),"Actual Base owner exposes separate V2 prepared checkpoint APIs")
 if failed:r.screen.free();r.holder.free();finish();return
 var state:Dictionary=base.export_checkpoint_state()
 print("EXPORT_REASON ",state.get("reason","ok"))
 check(state.get("version")==2 and state.units.a.status=="moving" and state.units.a.action.type=="sleep" and state.units.b.action.type=="terminal" and not state.units.a.has("position"),"Real Base operations export purpose/source token without second Actorposition")
 if failed:r.screen.free();r.holder.free();finish();return
 check(base.export_state().version==1 and base.export_state().units.a.status=="outside" and not base.export_state().units.a.has("action"),"Existing legacy V1 export remains unchanged and separately callable")
 var g:Dictionary=r.ground.export_state();var m:Dictionary=r.movement.export_state();var pair:Dictionary=prepared_pair(r,g,m)
 var movement_copy:Dictionary=r.movement.get_prepared_restore_state(pair.m);movement_copy.accepted_intents.clear()
 check(r.movement.get_prepared_restore_state(pair.m).accepted_intents.size()==2,"New Movement canonical target getter is detached and validates actual handle")
 var before:Dictionary=base._checkpoint_models()

 var prepared:Dictionary=base.prepare_restore_state(copy(state),pair.g,pair.m)
 print("PREPARE_REASON ",prepared.get("reason","ok"))
 check(prepared.get("ok",false) and base._checkpoint_models()==before,"Base prepares exact actual Ground and Movement targets without mutation")
 if failed:r.screen.free();r.holder.free();finish();return
 var bad:Dictionary=copy(state);bad.version=99
 check(not base.prepare_restore_state(bad,pair.g,pair.m).get("ok",false) and base._checkpoint_models()==before,"Unknown version rejects atomically")
 bad=copy(state);bad.units.b.action.command_token="base:1"
 check(not base.prepare_restore_state(bad,pair.g,pair.m).get("ok",false) and base._checkpoint_models()==before,"Wrong original Source token never binds to another action")
 bad=copy(state);bad.sequence=1
 check(base.prepare_restore_state(bad,pair.g,pair.m).get("reason")=="base_checkpoint_sequence_reuse","Sequence cannot reuse any saved original Base source ID")
 bad=copy(state);bad.units.b.action.target[0]+=16.0
 check(not base.prepare_restore_state(bad,pair.g,pair.m).get("ok",false),"World action target must match exact prepared Movement original target")
 bad=copy(state);bad.grid_frame.q[0]*=4.0
 check(base.prepare_restore_state(bad,pair.g,pair.m).get("reason")=="base_checkpoint_grid_frame","Coarse rendering coordinates cannot pass fine16x8 navigation binding")
 base._board_groups.home_ship={"ids":["a"]}
 check(base.export_checkpoint_state().get("reason")=="base_checkpoint_transport_pending","Pending boarding group is explicit saveguard")
 base._board_groups.clear();base._hex_admission_waiting=true
 check(base.export_checkpoint_state().get("reason")=="base_checkpoint_admission_pending","Pending admission is explicit saveguard")
 base._hex_admission_waiting=false
 # A tampered target removes one person from actual Ground/Movement but owns no transport membership.
 var absent_g:Dictionary=copy(g);var absent_m:Dictionary=copy(m)
 for i in range(absent_g.units.size()-1,-1,-1):
  if absent_g.units[i].unit_id=="a":absent_g.units.remove_at(i)
 for i in range(absent_g.active_segments.size()-1,-1,-1):
  if absent_g.active_segments[i].unit_id=="a":absent_g.active_segments.remove_at(i)
 for i in range(absent_m.accepted_intents.size()-1,-1,-1):
  if absent_m.accepted_intents[i].unit_id=="a":absent_m.accepted_intents.remove_at(i)
 var absent_pair:Dictionary=prepared_pair(r,absent_g,absent_m)
 bad=copy(state);bad.units.a.status="aboard";bad.units.a.craft_id="home_ship";bad.units.a.bed_id="";bad.units.a.action={}
 check(base.prepare_restore_state(bad,absent_pair.g,absent_pair.m).get("reason")=="base_checkpoint_aboard_context" and base._checkpoint_models()==before,"Home ship cannot acquire aboard person missing from actual Screen pilot/payload")
 r.screen._aircraft_manager.assign_pilot("home_ship","a")
 var aboard_prepared:Dictionary=base.prepare_restore_state(bad,absent_pair.g,absent_pair.m)
 check(aboard_prepared.get("ok",false),"Actual current Screen pilot membership supplies legitimate aboard context")
 r.screen._aircraft_manager.clear_assigned_pilot("home_ship")
 check(base.validate_prepared_restore(aboard_prepared.prepared).get("reason")=="base_checkpoint_context_changed","Transport owner membership change invalidates prepared aboard patch")
 # Legal independent movement intents may both ask for a bed, but Base cannot reserve it twice.
 var duplicate_g:Dictionary=copy(g);duplicate_g.active_segments=[]
 var duplicate_m:Dictionary=copy(m)
 for intent in duplicate_m.accepted_intents:
  if intent.unit_id=="b":
   intent.goal_grid=[32,28]
   for field in intent.command_intent:
    if field.key=="target_position":field.value=state.units.a.action.target.duplicate()
 var duplicate_pair:Dictionary=prepared_pair(r,duplicate_g,duplicate_m)
 bad=copy(state);bad.units.b.bed_id="habitat_bed_01";bad.units.b.action={"type":"sleep","target":state.units.a.action.target.duplicate(),"command_token":state.units.b.action.command_token,"bed_id":"habitat_bed_01","automatic":false}
 check(base.prepare_restore_state(bad,duplicate_pair.g,duplicate_pair.m).get("reason")=="base_checkpoint_bed_mismatch","Sleeping plus sleep-way reservations cannot duplicate one real bed")
 var detached:Dictionary=copy(state);var detached_prepared:Dictionary=base.prepare_restore_state(detached,pair.g,pair.m);assert(detached_prepared.ok);detached.units.a.action.command_token="changed"
 check(base.validate_prepared_restore(detached_prepared.prepared).get("ok",false),"Prepared Base patch has no alias to caller input")
 base._states.b.manual_priority_seconds+=1.0
 check(base.validate_prepared_restore(prepared.prepared).get("reason")=="base_checkpoint_context_changed","Changed actual Base state invalidates prepared patch")
 base._states.b.manual_priority_seconds-=1.0
 var events:Dictionary={"states":0,"terminal":0,"ready":false,"consistent":false,"replayed":false}
 var handle:RefCounted=prepared.prepared
 base.state_changed.connect(func():
  events.states+=1
  if not events.ready:return
  events.consistent=base._states.a.action.command_token==state.units.a.action.command_token and base._beds.get("habitat_bed_01")=="a" and base.get_actor("a").global_position==r.sim.get_hex_motion_projection("a",0.0).position_world
  events.replayed=base.finalize_prepared_restore(handle).get("replayed",false))
 base.terminal_ready.connect(func(id,terminal):
  if id=="b" and terminal=="personnel":events.terminal+=1)
 var gv:Dictionary=r.ground.validate_prepared_restore(pair.g);var mv:Dictionary=r.movement.validate_prepared_restore(pair.m);var bv:Dictionary=base.validate_prepared_restore(handle)
 assert(gv.ok and mv.ok and bv.ok)
 var actor_pos:Vector2=base.get_actor("a").global_position
 assert(r.ground._publish_prepared_restore(pair.g,gv).ok);assert(r.movement._publish_prepared_restore(pair.m,mv).ok);assert(base._publish_prepared_restore(handle,bv).ok)
 check(events.states==0 and events.terminal==0 and base.get_actor("a").global_position==actor_pos and base._states.a.status=="moving" and base._sequence==state.sequence and base._poll_seconds==state.poll_seconds and base._rest_elapsed==state.rest_elapsed and base._states.a.idle_seconds==7.0 and base._states.a.manual_priority_seconds==12.0,"Ground/Movement/Base model tails are silent and retain actions/tokens/timers without Actorwrites")
 r.sim._project_hex_ground_actors(0.0);events.ready=true
 check(base.finalize_prepared_restore(handle).get("ok",false) and events.states==1 and events.terminal==0 and events.consistent and events.replayed,"Source-style projection precedes one actual Base signal with safe reentrant finalize")
 check(base.finalize_prepared_restore(handle).get("replayed",false) and events.states==1 and not base.validate_prepared_restore(handle).get("ok",false),"Consumed Base restore cannot publish or emit twice")
 events.ready=false
 for i in range(24):
  r.sim._physics_process(0.1)
  if base._states.a.status=="sleeping" and events.terminal==1:break
 check(base._states.a.status=="sleeping" and base._states.a.bed_id=="habitat_bed_01" and events.terminal==1 and base._states.b.action.is_empty(),"Restored actual Root movement completes sleeping purpose and one terminal callback")
 var finished:Dictionary=base.export_checkpoint_state()
 check(finished.get("version")==2 and finished.units.a.status=="sleeping" and finished.sequence>=2,"Sleeping bed and archived arrived SourceIDs remain exportable")
 r.screen.free();r.holder.free();postprojection_cases();finish()
func postprojection_cases()->void:
 for kind in ["flow","screen","flow_exit","queued_actor","actor_id","actor_exit"]:
  var r:Dictionary=rig(0.001);var base=r.base
  var state:Dictionary=base.export_checkpoint_state()
  var g:Dictionary=r.ground.export_state();var m:Dictionary=r.movement.export_state()
  var saved_world:Vector2=base.get_actor("a").global_position
  r.sim._physics_process(0.001)
  var later_world:Vector2=base.get_actor("a").global_position
  var pair:Dictionary=prepared_pair(r,g,m)
  var prepared:Dictionary=base.prepare_restore_state(copy(state),pair.g,pair.m);assert(prepared.ok)
  var gv:Dictionary=r.ground.validate_prepared_restore(pair.g);var mv:Dictionary=r.movement.validate_prepared_restore(pair.m);var bv:Dictionary=base.validate_prepared_restore(prepared.prepared);assert(gv.ok and mv.ok and bv.ok)
  var signals:Dictionary={"count":0}
  base.state_changed.connect(func():signals.count+=1)
  assert(r.ground._publish_prepared_restore(pair.g,gv).ok);assert(r.movement._publish_prepared_restore(pair.m,mv).ok);assert(base._publish_prepared_restore(prepared.prepared,bv).ok)
  var actor=base.get_actor("a")
  r.sim._publish_base_ground_actors(PackedStringArray(["a","b"]))
  var actual_reprojection:bool=not later_world.is_equal_approx(saved_world) and actor.global_position.is_equal_approx(saved_world)
  # Explicit API boundary, no claim of a native/headless notification callback.
  var replacement:Node=null
  if kind=="flow":replacement=Flow.new();r.holder.add_child(replacement);base._flow=replacement
  elif kind=="screen":replacement=SCREEN.new();base._screen=replacement
  elif kind=="flow_exit":r.holder.remove_child(r.flow)
  elif kind=="queued_actor":actor.queue_free()
  elif kind=="actor_exit":base.remove_child(actor)
  else:actor.unit_id="changed-id"
  var result:Dictionary=base.finalize_prepared_restore(prepared.prepared)
  check(actual_reprojection and result.get("ok",false) and result.get("context_changed",false) and signals.count==0,"After real Root reprojection boundary "+kind+" suppresses historical signal without rollback")
  if kind=="queued_actor":
   var fresh_g:Dictionary=r.ground.export_state();var fresh_m:Dictionary=r.movement.export_state()
   var fresh_pair:Dictionary=prepared_pair(r,fresh_g,fresh_m)
   check(base.prepare_restore_state(copy(state),fresh_pair.g,fresh_pair.m).get("reason")=="base_checkpoint_actor_unbound","New candidate also rejects queued Actor with unchanged Registry/Known pointer")
  if kind=="screen" and is_instance_valid(replacement):replacement.free()
  if kind=="actor_exit":actor.free()
  if kind=="flow_exit":r.flow.free()
  r.screen.free();r.holder.free()
func finish()->void:
 print("BASE_ACTION_CHECKPOINT_V2 passed=",passed," failed=",failed)
 quit(0 if failed==0 else 1)
