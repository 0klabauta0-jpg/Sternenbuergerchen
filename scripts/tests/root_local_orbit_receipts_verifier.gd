extends "res://scripts/tests/root_receipt_prebinding_verifier.gd"
## Bounded real Root/Fleet/Flight producers; adapter/pilot gates are fixture inputs.
## Does not prove physical boarding, navigation restoration or a player journey.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
class Pilot extends Node:
 func is_pilot_aboard(_craft: String) -> bool: return true
class OrbitAdapter extends Node:
 func preview_departure(_craft: String) -> Dictionary: return {"ok":false}
 func _built_home_pad_ids() -> Array: return []
 func validate_space_launch(_craft: String, _flag: bool) -> Dictionary: return {"ok":true}
 func preview_space_warp_entry(_craft: String) -> Dictionary: return {"ok":true,"owned_crafts":["a"],"craft_pilots":{"a":"pilot"}}

func run() -> void:
 var sim = SIM.new(); root.add_child(sim); sim.set_physics_process(false)
 var adapter = OrbitAdapter.new(); root.add_child(adapter)
 var pilot = Pilot.new(); root.add_child(pilot); sim.configure_base_personnel(pilot)
 var b := owners(sim,adapter)
 b.equipment.configure([{"craft_id":"a","model_id":"cutlass"}]); bind(sim,b)
 sim.configure_space_runtime_tick(func(_delta: float): pass); sim.set_physics_process(false)
 var launch: Dictionary = sim.commit_singleplayer_space_launch(adapter,"a","orbit-receipt-launch")
 if not check(launch.get("ok",false),"actual Root launch uses real Fleet/Flight/Equipment"): finish_local(sim,adapter,pilot); return
 sim.publish_singleplayer_space_launch_event(adapter,"orbit-receipt-launch")
 var strategic_capture: Dictionary=HELPER.capture(sim,b)
 if not check(strategic_capture.has("schema"),"actual strategic launch receipt captures before local travel"): finish_local(sim,adapter,pilot); return
 var strategic_data: Dictionary=CODEC.decode_value(strategic_capture.value).value
 var historical := {"launch":strategic_data.launch,"departure":strategic_data.departure,"equipment":strategic_data.equipment}
 var historical_prepared: Dictionary=HELPER.prepare_prebinding(sim,wire_local(historical),b)
 check(historical_prepared.get("ok",false),"historical three-field projection preserves actual strategic launch history")
 if historical_prepared.get("ok",false): check(HELPER.validate_prebinding(sim,historical_prepared.candidate,b).ok,"historical strategic receipt projection validates exact real owners")
 # Enter the first local orbit through the real completion producer. This
 # strategic bootstrap command is an owner API, not a patched Flight pose.
 var satellite_orbit: String=String(b.fleet.get_craft_snapshot("a").location_orbits.get("satellite_crash",""))
 var jump: Dictionary = b.fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"start_quantum","payload":{"craft_id":"a","target_orbit_id":satellite_orbit},"request_id":"orbit-receipt-bootstrap"},{})
 if not check(jump.get("ok",false),"real strategic bootstrap starts quantum"): finish_local(sim,adapter,pilot); return
 var entry := {}
 for attempt in range(128):
  entry = sim.advance_singleplayer_warp_entry(adapter,"a",60.0)
  if not entry.get("ok",false) or entry.get("status") != "pending": break
 if not check(entry.get("ok",false) and entry.get("status")=="complete","actual bounded Root warp-entry producer admits local Flight"): print(entry); finish_local(sim,adapter,pilot); return
 sim.publish_singleplayer_warp_entry_event(adapter,entry.receipt_id)
 var pose: Dictionary = b.fleet.get_flight_state("a").get_snapshot()
 var target := GRID.HEX.round_axial(GRID.HEX.plane_to_axial(pose.position_plane))
 var move := {"craft_id":"a","target_hex":target,"request_id":"orbit-receipt-move"}
 var moved: Dictionary = sim.request_singleplayer_space_move(move)
 if not check(moved.get("ok",false),"actual Root move producer creates canonical dedup receipt"): print(moved); finish_local(sim,adapter,pilot); return
 var first := roundtrip_local(sim,b,adapter)
 if not first.is_empty():
  var fresh: Node = first.sim
  var before: Dictionary = HELPER._owner_stamp(first.bindings)
  var events: Array=[]; fresh.singleplayer_command_committed.connect(func(c: Dictionary,r: Dictionary): events.append([c,r]))
  var replay: Dictionary = fresh.advance_singleplayer_warp_entry(adapter,"a",1.0)
  check(replay.get("ok",false) and replay.get("replayed",false) and replay.travel_result.get("replayed",false),"actual warp entry replays with original nested replay semantics")
  check(fresh.request_singleplayer_space_move(move)=={"ok":true,"replayed":true},"actual move replays after fresh owner restore")
  var conflict := move.duplicate(); conflict.target_hex += Vector2i(1,0)
  check(not fresh.request_singleplayer_space_move(conflict).get("ok",false),"changed target with same move ID conflicts")
  fresh.publish_singleplayer_warp_entry_event(adapter,entry.receipt_id)
  check(before==HELPER._owner_stamp(first.bindings) and events.is_empty(),"restored receipt replays mutate no owners or published events")
  fresh.free()
 # Real subsequent runtime ticks make the next area-transition tick newer than admission.
 sim._physics_process(0.05); sim._physics_process(0.05)
 var command := {"craft_id":"a","target_orbit_id":"moon_orbit","request_id":"orbit-receipt-warp-out"}
 var departure: Dictionary = sim.commit_singleplayer_warp_departure(adapter,command)
 print("LOCAL_WARP_DEPARTURE_RESULT ",departure)
 if check(departure.get("ok",false),"actual local-to-strategic warp-departure producer commits"):
  sim.publish_singleplayer_warp_departure_event(adapter,command.request_id)
  var second := roundtrip_local(sim,b,adapter)
  if not second.is_empty():
   var before: Dictionary = HELPER._owner_stamp(second.bindings)
   var replay: Dictionary = second.sim.commit_singleplayer_warp_departure(adapter,command)
   check(replay.get("ok",false) and replay.get("replayed",false),"actual warp departure replays through fresh Fleet candidate")
   check(before==HELPER._owner_stamp(second.bindings),"warp departure replay repeats no Flight/Travel mutation")
   second.sim.free()
 finish_local(sim,adapter,pilot)

func wire_local(data: Dictionary) -> Dictionary:
 return {"schema":"root_receipt_checkpoint.v1","value":CODEC.encode_value(data).value}

func roundtrip_local(source: Node,b: Dictionary,adapter: Node) -> Dictionary:
 var saved: Dictionary = HELPER.capture(source,b)
 if not check(saved.get("schema")=="root_receipt_checkpoint.v1","completed actual local receipts capture"): print(saved); return {}
 var wire: Dictionary = JSON.parse_string(JSON.stringify(saved,"",true,true))
 var data: Dictionary = CODEC.decode_value(wire.value).value
 var target = SIM.new(); root.add_child(target); target.set_physics_process(false)
 var fresh := owners(target,adapter)
 fresh.equipment.configure([{"craft_id":"a","model_id":"cutlass"}])
 var fleet: Dictionary = b.fleet.prepare_checkpoint_restore(b.fleet.export_checkpoint_state(),["a"])
 if not check(fleet.get("ok",false),"real Fleet checkpoint creates fresh local/strategic Flight owners"): print(fleet); target.free(); return {}
 fresh.fleet=fleet.candidate; fresh.fleet.configure_space_area_transition_authority(target)
 var prepared: Dictionary=HELPER.prepare(target,wire,fresh)
 if not check(prepared.get("ok",false),"JSON receipt projection prepares detached real owners"): print(prepared); target.free(); return {}
 for kind in HELPER.ORBIT_MAPS:
  var missing:=data.duplicate(true); missing.erase(kind)
  check(not HELPER.prepare(target,wire_local(missing),fresh).ok,"missing expanded checkpoint map rejects: "+kind)
 var stripped := {"launch":data.launch,"departure":data.departure,"equipment":data.equipment}
 check(not HELPER.prepare(target,wire_local(stripped),fresh).ok,"stripping all local maps cannot masquerade as historical checkpoint")
 var old_prepared: Dictionary=HELPER.prepare_prebinding(source,wire,b)
 check(old_prepared.get("ok",false),"old Root prebinding stamp prepares before export failure")
 var source_pending:=pending_context("stamp-source-pending",b.fleet)
 check(b.fleet.bind_space_area_transition_context(source_pending,source).get("ok",false),"actual Fleet API binds separate unfinished old-owner context")
 check(b.fleet.export_checkpoint_state().get("ok",true)==false,"unfinished context makes actual old Fleet export fail")
 check(HELPER.capture(source,b).get("reason")=="receipt_owner_export_failed","capture explicitly rejects failed owner export")
 check(not HELPER.prepare_prebinding(source,wire,b).ok,"prebinding prepare rejects failed old-owner export")
 if old_prepared.get("ok",false): check(HELPER.validate_prebinding(source,old_prepared.candidate,b).get("reason")=="receipt_owner_export_failed","old Root stamp failure explicitly rejects validation")
 b.fleet.release_space_area_transition_context(source_pending.context_id,source)
 var target_pending:=pending_context("stamp-target-pending",fresh.fleet)
 check(fresh.fleet.bind_space_area_transition_context(target_pending,target).get("ok",false),"actual Fleet API binds unfinished detached-owner context")
 check(HELPER.prepare(target,wire,fresh).get("reason")=="receipt_owner_export_failed","prepare explicitly rejects failed detached-owner export")
 check(HELPER.validate_prebinding(target,prepared.candidate,fresh).get("reason")=="receipt_owner_export_failed","failed new-owner export cannot act as constant freshness stamp")
 fresh.fleet.release_space_area_transition_context(target_pending.context_id,target)
 check(HELPER.validate_prebinding(target,prepared.candidate,fresh).ok,"removing unfinished context restores exact valid detached stamp")
 var malformed := data.duplicate(true); malformed.warp_entry.values()[0].event_published=false
 check(not HELPER.prepare(target,wire_local(malformed),fresh).ok,"unfinished warp-entry event rejects")
 malformed=data.duplicate(true); malformed.warp_latest.a="missing"
 check(not HELPER.prepare(target,wire_local(malformed),fresh).ok,"dangling latest index rejects")
 malformed=data.duplicate(true); malformed.move["orbit-receipt-move"].signature="{}"
 check(not HELPER.prepare(target,wire_local(malformed),fresh).ok,"noncanonical move receipt rejects")
 malformed=data.duplicate(true); malformed.warp_entry.values()[0].result.travel_result["ok"]=false
 check(not HELPER.prepare(target,wire_local(malformed),fresh).ok,"forged Fleet result rejects")
 malformed=data.duplicate(true); malformed.launch.values()[0].context.operation="depart_station_purchase"
 check(not HELPER.prepare(target,wire_local(malformed),fresh).ok,"unsupported station-birth family remains fail closed")
 var original_operation: String=source._launch_receipts.values()[0].context.operation
 source._launch_receipts.values()[0].context.operation="enter_orbit"
 check(not HELPER.capture(source,b).has("schema"),"actual capture refuses unsupported station launch producer shape")
 source._launch_receipts.values()[0].context.operation=original_operation
 for field in ["_warp_entry_searches","_warp_completion_intents","_space_fire_receipts","_air_ground_order_receipts"]:
  source.get(field)["unfinished"]={}
  check(not HELPER.capture(source,b).has("schema"),"pending/unsupported source map rejects: "+field)
  source.get(field).erase("unfinished")
 var before: Dictionary=HELPER._owner_stamp(fresh)
 bind(target,fresh)
 if not check(HELPER.validate(target,prepared.candidate,fresh).ok,"fresh bindings validate before receipt publication"): target.free(); return {}
 target._warp_entry_latest_by_craft["a"]="foreign"
 check(not HELPER.validate(target,prepared.candidate,fresh).ok,"target latest-index mutation invalidates prepared candidate")
 target._warp_entry_latest_by_craft.clear()
 check(HELPER.validate(target,prepared.candidate,fresh).ok,"exact target baseline validates again")
 HELPER.publish(target,prepared.candidate)
 check(HELPER._owner_stamp(fresh)==before,"receipt publication changes no actual owner")
 check(HELPER.capture(target,fresh)==saved,"semantic recapture equals original local receipt checkpoint")
 check(not HELPER.prepare(target,wire,fresh).ok,"occupied local receipt maps cannot silently overwrite")
 return {"sim":target,"bindings":fresh,"wire":wire}

func pending_context(id: String,fleet: RefCounted) -> Dictionary:
 return {"request_id":id,"request_signature":JSON.stringify({"operation":"launch_to_orbit","payload":{"craft_id":"a"}},"",true),"operation":"launch_to_orbit","payload":{"craft_id":"a"},"source_area_id":"","target_area_id":"","expected_travel_revision":fleet.get_craft_snapshot("a").revision,"expected_phase":"grounded","context_id":id}

func finish_local(sim: Node,adapter: Node,pilot: Node) -> void:
 sim.free(); adapter.free(); pilot.free()
 print("ROOT_LOCAL_ORBIT_RECEIPTS passed=%d failed=%d" % [passed,failed])
 if failed==0: print("ROOT_LOCAL_ORBIT_RECEIPTS_PASS")
 quit(0 if failed==0 else 1)
