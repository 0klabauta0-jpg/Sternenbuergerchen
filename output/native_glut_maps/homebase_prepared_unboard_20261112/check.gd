extends SceneTree
const SCREEN=preload("res://scripts/meta/homebase_screen.gd")
var passed:=0
var failed:=0
func check(ok:bool,label:String)->void:
 if ok:passed+=1
 else:failed+=1
 print("PASS " if ok else "FAIL ",label)
func rig():
 var screen=SCREEN.new()
 screen.set_transport_state([{"craft_id":"ship_a","model_id":"cutlass","crew_capacity":8},{"craft_id":"ship_b","model_id":"cutlass","crew_capacity":8}],{},[],[],{"ship_a":"homebase","ship_b":"homebase"})
 screen._selected_unit_ids=PackedStringArray(["u1","u2","u3"])
 screen._selected_fireteam_ids=PackedStringArray(["ft1","ft1","ft2"])
 screen._fireteam_definitions=[{"id":"ft1","label":"ALPHA","member_unit_ids":PackedStringArray(["u1","u2"])},{"id":"ft2","label":"BRAVO","member_unit_ids":PackedStringArray(["u3"])}]
 screen._add_homebase_direct_payload_fireteam_to_craft("ft1","ship_a")
 screen._add_homebase_direct_payload_fireteam_to_craft("ft2","ship_b")
 screen._aircraft_manager.set_selected_aircraft_id("ship_b")
 return screen
func _initialize()->void:
 var screen=rig()
 check(screen.has_method("prepare_base_unboard") and screen.has_method("validate_prepared_base_unboard") and screen.has_method("_publish_prepared_base_unboard") and screen.has_method("finalize_base_unboard"),"Actual Screen exposes additive prepared unboard bridge")
 if failed:screen.free();finish();return
 var before:Dictionary=screen._base_unboard_context("ship_a","ft1")
 var prepared:Dictionary=screen.prepare_base_unboard("ship_a","ft1")
 check(prepared.get("ok",false) and screen._base_unboard_context("ship_a","ft1")==before and prepared.removed_unit_ids==PackedStringArray(["u1","u2"]) and prepared.removed_fireteam_ids==PackedStringArray(["ft1"]),"Preparation is read-only and returns exact detached source team and units")
 check(screen._aircraft_manager.get_selected_aircraft_id()=="ship_b" and screen.validate_prepared_base_unboard(prepared.prepared).ok,"Explicit parallel craft may unboard without selecting it")
 prepared.unit_ids[0]="mutated";prepared.fireteam_definition.member_unit_ids[0]="mutated"
 check(screen.validate_prepared_base_unboard(prepared.prepared).ok and screen._get_member_unit_ids_for_fireteam("ft1")==PackedStringArray(["u1","u2"]),"Source DTO mutation aliases neither existing context nor private patch")
 check(not screen.prepare_base_unboard("ship_b","ft1").get("ok",false) and screen._base_unboard_context("ship_a","ft1")==before,"Foreign craft cannot remove another craft payload")
 var other=rig()
 check(not other.validate_prepared_base_unboard(prepared.prepared).get("ok",false),"Opaque prepared handle is bound to exact Screen")
 other.free()
 var events:Dictionary={"count":0,"complete":false,"replayed":false,"blocked":false}
 var handle:RefCounted=prepared.prepared
 screen.fireteam_context_changed.connect(func(units,teams):
  events.count+=1
  events.complete=not screen._homebase_dropship_staged_fireteam_ids_by_craft.has("ship_a") and screen._homebase_dropship_staged_fireteam_ids_by_craft.ship_b==PackedStringArray(["ft2"]) and not screen._homebase_direct_boarding_state_by_fireteam_id.has("ft1") and screen._homebase_dropship_staged_fireteam_ids==PackedStringArray(["ft2"]) and screen._homebase_dropship_payload_craft_id=="ship_b"
  events.replayed=screen.finalize_base_unboard(handle).get("replayed",false)
  events.blocked=not screen.prepare_base_unboard("ship_a","ft1").get("ok",false)
  units.clear();teams.clear())
 var validated:Dictionary=screen.validate_prepared_base_unboard(handle)
 check(screen.finalize_base_unboard(handle).get("reason")=="base_unboard_not_published" and events.count==0,"Finalize cannot emit before commit")
 assert(validated.ok)
 check(screen._publish_prepared_base_unboard(handle,validated).get("ok",false) and events.count==0,"Actual publish changes projections silently before any observer")
 check(not screen.validate_prepared_base_unboard(handle).get("ok",false),"Published handle cannot validate a second payload removal")
 check(screen.finalize_base_unboard(handle).get("ok",false) and events.count==1 and events.complete,"Actual context signal sees every projection already complete")
 check(events.replayed and events.blocked and events.count==1,"Synchronous reentrant observer cannot double finalize or repeat unboard")
 check(screen._selected_unit_ids==PackedStringArray(["u1","u2","u3"]) and screen._selected_fireteam_ids==PackedStringArray(["ft1","ft1","ft2"]) and screen._aircraft_manager.get_selected_aircraft_id()=="ship_b","Signal values detached, roster membership and actual selector retained")
 check(screen.finalize_base_unboard(handle).get("replayed",false) and events.count==1,"Later finalize replay emits no duplicate signal")
 screen.free()
 var stale=rig();prepared=stale.prepare_base_unboard("ship_a","ft1");stale._selected_unit_ids[0]="changed"
 check(stale.validate_prepared_base_unboard(prepared.prepared).get("reason")=="base_unboard_context_changed" and stale._homebase_dropship_staged_fireteam_ids_by_craft.ship_a==PackedStringArray(["ft1"]),"Changed selected context rejects before payload mutation")
 stale.free()
 stale=rig();prepared=stale.prepare_base_unboard("ship_a","ft1");stale._homebase_direct_boarding_state_by_fireteam_id.ft1.elapsed_seconds=2.0
 check(stale.validate_prepared_base_unboard(prepared.prepared).get("reason")=="base_unboard_context_changed","Changed real boarding projection invalidates prepared patch")
 stale.free()
 var reset=rig();prepared=reset.prepare_base_unboard("ship_a","ft1");handle=prepared.prepared
 var reset_events:Dictionary={"count":0}
 reset.fireteam_context_changed.connect(func(_units,_teams):reset_events.count+=1;reset._selected_unit_ids=PackedStringArray();reset._selected_fireteam_ids=PackedStringArray())
 validated=reset.validate_prepared_base_unboard(handle);assert(validated.ok);assert(reset._publish_prepared_base_unboard(handle,validated).ok)
 check(reset.finalize_base_unboard(handle).get("context_changed",false) and reset_events.count==1 and reset._selected_unit_ids.is_empty(),"Reentrant context reset prevents stale post-observer UI rebuild")
 reset.free()
 var pre_reset=rig();prepared=pre_reset.prepare_base_unboard("ship_a","ft1");handle=prepared.prepared
 validated=pre_reset.validate_prepared_base_unboard(handle);assert(validated.ok);assert(pre_reset._publish_prepared_base_unboard(handle,validated).ok)
 var prior_reset_events:Dictionary={"count":0}
 pre_reset.fireteam_context_changed.connect(func(_a,_b):prior_reset_events.count+=1)
 pre_reset._selected_unit_ids=PackedStringArray();pre_reset._selected_fireteam_ids=PackedStringArray()
 var finalized:Dictionary=pre_reset.finalize_base_unboard(handle)
 check(finalized.get("ok",false) and finalized.get("context_changed",false) and prior_reset_events.count==0 and pre_reset.finalize_base_unboard(handle).get("replayed",false),"Committed action tolerates changed screen before finalize without old-context signal or reject")
 pre_reset.free()
 var mirror=rig()
 var defs:Array=mirror._aircraft_manager.get_aircraft_definitions();defs.append({"craft_id":"ship_c"})
 mirror._aircraft_manager.set_transport_state(defs,{},[])
 mirror._selected_unit_ids.append("u4");mirror._selected_fireteam_ids.append("ft3")
 mirror._fireteam_definitions.append({"id":"ft3","member_unit_ids":PackedStringArray(["u4"])})
 mirror._add_homebase_direct_payload_fireteam_to_craft("ft3","ship_c")
 mirror._selected_unit_ids.remove_at(2);mirror._selected_fireteam_ids.remove_at(2);mirror._fireteam_definitions[1].member_unit_ids=PackedStringArray()
 mirror._homebase_dropship_payload_craft_id="ship_b"
 prepared=mirror.prepare_base_unboard("ship_a","ft1");assert(prepared.ok);validated=mirror.validate_prepared_base_unboard(prepared.prepared);assert(validated.ok)
 assert(mirror._publish_prepared_base_unboard(prepared.prepared,validated).ok)
 check(mirror._homebase_dropship_payload_craft_id=="ship_c" and mirror._homebase_dropship_staged_fireteam_ids==PackedStringArray(["ft3"]),"Legacy mirror follows remaining actual-member payload rather than empty team array")
 mirror.free()
 finish()
func finish()->void:
 print("HOMEBASE_PREPARED_UNBOARD passed=",passed," failed=",failed)
 quit(0 if failed==0 else 1)
