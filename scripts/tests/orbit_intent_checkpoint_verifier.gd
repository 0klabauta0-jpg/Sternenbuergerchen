extends SceneTree
## Focused real-owner projection fixture. Requires integrated2f37621a6 orbit APIs.
## No map/native journey or whole-world Continue acceptance is implied.
const HELPER = preload("res://scripts/mission/orbit_intent_checkpoint.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const CRAFT := "space_fixture_orbit_checkpoint"
class Flow extends Node:
 var _last_mission_result := {}
 var _selected_mission_id := ""
class Pilot extends Node:
 func is_pilot_aboard(_id: String) -> bool: return true
var passed := 0
var failed := 0
func check(value: bool,label: String) -> bool:
 if value: passed+=1; print("PASS: ",label)
 else: failed+=1; printerr("FAIL: ",label)
 return value
func _initialize() -> void: call_deferred("run")
func fixture(direction: String = "inbound") -> Dictionary:
 var sim=ROOT.new(); root.add_child(sim); sim.set_physics_process(false)
 var fleet=FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(CRAFT)
 assert(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"launch_to_orbit","payload":{"craft_id":CRAFT},"request_id":"launch"},{"runtime_authorized":true}).ok)
 var location := "satellite_crash"
 var target_orbit: String = fleet.get_craft_snapshot(CRAFT).location_orbits[location]
 assert(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"start_quantum","payload":{"craft_id":CRAFT,"target_orbit_id":target_orbit},"request_id":"fixture-jump"},{}).ok)
 for step in range(10):
  if fleet.get_craft_snapshot(CRAFT).phase != "quantum": break
  assert(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"advance","payload":{"craft_id":CRAFT,"delta_seconds":60.0},"request_id":"fixture-advance:"+str(step)},{"runtime_authorized":true}).ok)
 assert(fleet.get_craft_snapshot(CRAFT).phase=="orbit")
 var body_id: String=fleet.get_craft_snapshot(CRAFT).orbits[target_orbit].body_id
 var campaign=CAMPAIGN.new(); assert(campaign.configure().ok)
 assert(campaign.apply_command({"contract_category":"singleplayer_campaign","operation":"select_destination","payload":{"location_id":location},"request_id":"select"},{}).ok)
 var equipment=EQUIPMENT.new(); assert(equipment.configure([{"craft_id":CRAFT,"model_id":"cutlass"}]).ok)
 var pilot=Pilot.new(); var adapter=ADAPTER.new(); var flow=Flow.new()
 adapter.set("_flow",flow); adapter.set("_space_route_requested",true)
 adapter.set("_simulation",sim); adapter.set("_travel",fleet); adapter.set("_campaign",campaign)
 sim.configure_singleplayer_owners(campaign,null,null,fleet); sim.configure_ship_equipment(equipment); sim.configure_base_personnel(pilot)
 assert(sim.configure_departure_adapter(adapter).ok)
 var flight: RefCounted=fleet.get_flight_state(CRAFT)
 assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision,"mass":equipment.get_space_flight_profile(CRAFT).mass},flight.get_snapshot().tick+1).ok)
 var start: Vector2i=GRID.from_offset(Vector2i(256,240) if direction=="inbound" else Vector2i(256,8))
 assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:"+body_id.uri_encode(),"position_plane":GRID.HEX.axial_to_plane(Vector2(start)),"motion_mode":"tactical"},flight.get_snapshot().tick+1).ok)
 var combat: RefCounted=sim.get("_space_combat_state")
 assert(combat.admit_actor({"craft_id":CRAFT,"start_hex":start,"faction_id":"player","control_domain":"player","footprint_hexes":[Vector2i.ZERO]},flight,true).ok)
 assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer",[CRAFT],[CRAFT],{CRAFT:"pilot"}).ok)
 # Initial local manual projection is a fixture setup, then real adapter command
 # and Root planner generate the actual Flight/navigation controls being tested.
 adapter.set("_surface_orbit_path_enabled",true)
 adapter.set("_surface_orbit_intents",{CRAFT:{"location_id":location,"target_orbit_id":target_orbit,"direction":direction,"status":"manual"}})
 assert(adapter.request_operation("space_set_orbit_automatic",{"craft_id":CRAFT,"enabled":true}).ok)
 var pending: Dictionary
 if direction=="inbound": pending=adapter._request_space_operation("space_begin_approach",{"craft_id":CRAFT,"location_id":location},"fixture-pending-approach")
 else: pending=adapter._request_space_operation("space_start_quantum",{"craft_id":CRAFT,"target_orbit_id":"moon_orbit"},"fixture-pending-warp")
 assert(pending.get("ok",false) and pending.get("pending",false))
 return {"flow":flow,"adapter":adapter,"simulation_root":sim,"fleet":fleet,"combat":combat,"campaign":campaign,"equipment":equipment,"pilot":pilot,"flight":flight}
func bindings(f: Dictionary) -> Dictionary:
 return {"simulation_root":f.simulation_root,"fleet":f.fleet,"combat":f.combat,"campaign":f.campaign,"space_operation_requests":f.adapter.get("_space_operation_requests")}
func wire(data: Dictionary) -> Dictionary:
 return {"schema":"orbit_intent_checkpoint.v1","value":CODEC.encode_value(data).value}
func cleanup(f: Dictionary) -> void:
 f.adapter.free(); f.pilot.free(); f.flow.free(); f.simulation_root.free()
func run() -> void:
 if not FileAccess.file_exists("res://scripts/mission/orbit_surface_locations.gd"):
  printerr("ORBIT_INTENT_INTEGRATION_REQUIRED: pinned orbit APIs/catalog must be integrated before this verifier")
  quit(1); return
 var source:=fixture(); var target:=fixture()
 for f in [source,target]:
  f.simulation_root._advance_space_flights(0.1,f.flight.get_snapshot().tick+1)
  f.adapter.call("_advance_surface_orbit_intents")
 check(source.combat.get_flight_status(CRAFT)=={"ok":true,"reason":""},"actual accepted Root movement batch produces empty success reason")
 check(source.adapter.get("_surface_orbit_intents")[CRAFT].status=="flying","actual accepted Root step keeps adapter flying")
 var captured: Dictionary=HELPER.capture(source.adapter,bindings(source))
 if not check(captured.get("schema")=="orbit_intent_checkpoint.v1","original stable flying pending approach captures with actual Root controls"):
  cleanup(source); cleanup(target); quit(1); return
 var saved: Dictionary=JSON.parse_string(JSON.stringify(captured,"",true,true))
 target.adapter.set("_surface_orbit_intents",{})
 target.adapter.set("_surface_orbit_path_enabled",false)
 var before: Dictionary=HELPER._owner_stamp(bindings(target))
 var prepared: Dictionary=HELPER.prepare(target.adapter,saved,bindings(target))
 if not check(prepared.get("ok",false),"typed JSON prepares against fresh real owner identities"):
  cleanup(source); cleanup(target); quit(1); return
 check(target.adapter.get("_surface_orbit_intents").is_empty() and before==HELPER._owner_stamp(bindings(target)),"prepare mutates neither adapter maps nor Flight/navigation")
 check(HELPER.validate(target.adapter,prepared.candidate,bindings(target)).ok,"fresh candidate validates before publication")
 var old_campaign: RefCounted=target.adapter.get("_campaign")
 target.adapter.set("_campaign",source.campaign)
 check(not HELPER.validate(target.adapter,prepared.candidate,bindings(target)).ok,"changed old adapter owner pointer rejects")
 target.adapter.set("_campaign",old_campaign)
 var status: Dictionary=target.combat.get_flight_status(CRAFT)
 target.combat.set_flight_status(CRAFT,{"ok":false,"reason":"changed"})
 check(not HELPER.validate(target.adapter,prepared.candidate,bindings(target)).ok,"changed restored owner status rejects")
 target.combat.set_flight_status(CRAFT,status)
 var data: Dictionary=CODEC.decode_value(saved.value).value
 for unsafe in ["starting","completing","unknown"]:
  var bad:=data.duplicate(true); bad.intents[CRAFT].status=unsafe
  check(not HELPER.prepare(target.adapter,wire(bad),bindings(target)).ok,"unsafe status rejects: "+unsafe)
 for pending in ["pending_warp","pending_approach"]:
  var bad:=data.duplicate(true); bad.intents[CRAFT][pending]={}
  check(not HELPER.prepare(target.adapter,wire(bad),bindings(target)).ok,"malformed pending field rejects: "+pending)
 var missing_requests:=bindings(target); missing_requests.erase("space_operation_requests")
 check(not HELPER.prepare(target.adapter,saved,missing_requests).ok,"pending restore requires canonical future replay map")
 var corrupt:=data.duplicate(true); corrupt.intents[CRAFT].pending_approach.signature="fake"
 check(not HELPER.prepare(target.adapter,wire(corrupt),bindings(target)).ok,"forged pending signature rejects")
 corrupt=data.duplicate(true); corrupt.intents[CRAFT].pending_approach.request_id=""
 check(not HELPER.prepare(target.adapter,wire(corrupt),bindings(target)).ok,"empty pending request ID rejects")
 var pending_id: String=data.intents[CRAFT].pending_approach.request_id
 var conflicting:=bindings(target); conflicting.space_operation_requests=target.adapter.get("_space_operation_requests").duplicate(true)
 conflicting.space_operation_requests[pending_id]={"signature":data.intents[CRAFT].pending_approach.signature,"result":{"ok":true}}
 check(not HELPER.prepare(target.adapter,saved,conflicting).ok,"already replayed pending request ID rejects")
 corrupt=data.duplicate(true); corrupt["_surface_orbit_path_enabled"]=true
 check(not HELPER.prepare(target.adapter,wire(corrupt),bindings(target)).ok,"wire cannot activate capability")
 # Seit 1a74be4f9 ("Handflug ist Vorgabe") schreibt der Adapter selbst false-Eintraege ("Automatik ausdruecklich an"); Bjoern 28.11.: false wird angenommen.
 var explicit_auto:=data.duplicate(true); explicit_auto.auto_disabled[CRAFT]=false
 check(HELPER.prepare(target.adapter,wire(explicit_auto),bindings(target)).ok,"false disable entry (Automatik ausdruecklich an) is accepted")
 corrupt=data.duplicate(true); corrupt.intents[CRAFT].target_orbit_id="fake"
 check(not HELPER.prepare(target.adapter,wire(corrupt),bindings(target)).ok,"unmatched canonical route rejects")
 corrupt=data.duplicate(true); corrupt.intents[CRAFT].status="arrived"
 check(not HELPER.prepare(target.adapter,wire(corrupt),bindings(target)).ok,"intent alone cannot manufacture arrived state")
 for pending in HELPER.PENDING:
  target.simulation_root.get(pending)[CRAFT]={}
  check(not HELPER.validate(target.adapter,prepared.candidate,bindings(target)).ok,"actual Root deferred window rejects: "+pending)
  target.simulation_root.get(pending).clear()
 check(HELPER.validate(target.adapter,prepared.candidate,bindings(target)).ok,"unchanged actual owners validate immediately before tail")
 HELPER.publish(target.adapter,prepared.candidate)
 check(target.adapter.get("_surface_orbit_path_enabled")==false,"true opt-in source never enables false target capability")
 check(HELPER.capture(target.adapter,bindings(target))==captured,"published route intent matches exact semantic source")
 check(before==HELPER._owner_stamp(bindings(target)),"publication performs no Flight/navigation effects")
 check(not HELPER.validate(target.adapter,prepared.candidate,bindings(target)).ok,"published handle cannot be reused")
 # Actual disabled/braking window, followed by real owner ticks to settled manual.
 check(source.adapter.request_operation("space_set_orbit_automatic",{"craft_id":CRAFT,"enabled":false}).ok,"real adapter automatic-disable command accepted")
 check(not HELPER.capture(source.adapter,bindings(source)).has("schema"),"actual auto braking window rejects capture")
 for tick in range(200):
  source.simulation_root._advance_space_flights(0.1,source.flight.get_snapshot().tick+1)
  source.adapter.call("_advance_surface_orbit_intents")
  if source.combat.get_flight_status(CRAFT).get("reason")=="interrupted": break
 var manual: Dictionary=HELPER.capture(source.adapter,bindings(source))
 check(manual.get("schema")=="orbit_intent_checkpoint.v1" and source.adapter.get("_surface_orbit_intents")[CRAFT].status=="manual","settled actual manual/off state captures")
 check(source.adapter.get("_surface_orbit_auto_disabled").get(CRAFT)==true,"actual disabled preference retained")
 var outbound:=fixture("outbound")
 var out_saved: Dictionary=HELPER.capture(outbound.adapter,bindings(outbound))
 check(out_saved.get("schema")=="orbit_intent_checkpoint.v1","original producer flying pending warp captures")
 if out_saved.has("schema"):
  var out_data: Dictionary=CODEC.decode_value(out_saved.value).value
  var out_prepared: Dictionary=HELPER.prepare(outbound.adapter,out_saved,bindings(outbound))
  check(out_prepared.get("ok",false) and HELPER.validate(outbound.adapter,out_prepared.candidate,bindings(outbound)).ok,"stable outbound pending warp prepares without owner commands")
  for target_id in ["fake",out_data.intents[CRAFT].target_orbit_id]:
   var bad:=out_data.duplicate(true)
   bad.intents[CRAFT].pending_warp.payload.target_orbit_id=target_id
   bad.intents[CRAFT].pending_warp.signature=JSON.stringify({"operation":"space_start_quantum","payload":bad.intents[CRAFT].pending_warp.payload},"",true)
   check(not HELPER.prepare(outbound.adapter,wire(bad),bindings(outbound)).ok,"unknown/current pending warp target rejects: "+target_id)
  var bad:=out_data.duplicate(true); bad.intents[CRAFT].pending_warp.payload["target_orbit_marker_id"]="fake"
  bad.intents[CRAFT].pending_warp.signature=JSON.stringify({"operation":"space_start_quantum","payload":bad.intents[CRAFT].pending_warp.payload},"",true)
  check(not HELPER.prepare(outbound.adapter,wire(bad),bindings(outbound)).ok,"unknown pending warp marker rejects")
 cleanup(outbound); cleanup(source); cleanup(target)
 print("ORBIT_INTENT_CHECKPOINT passed=%d failed=%d" % [passed,failed])
 if failed==0: print("ORBIT_INTENT_CHECKPOINT_PASS")
 quit(0 if failed==0 else 1)
