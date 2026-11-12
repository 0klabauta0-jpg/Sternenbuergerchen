extends "res://scripts/tests/root_receipt_prebinding_verifier.gd"
## Real Root movement/departure/return producers; fixture adapter supplies gates.
## No map generation, actor/pose patch, teleport or altered movement parameters.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const ORBIT_INTENT = preload("res://scripts/mission/orbit_intent_checkpoint.gd")
const SPACE = preload("res://scripts/core/space_combat_state.gd")
class Pilot extends Node:
 func is_pilot_aboard(_craft: String) -> bool: return true
class SurfaceAdapter extends Node:
 var _simulation: Node
 var _travel: RefCounted
 var _campaign: RefCounted
 var _surface_orbit_path_enabled := false
 var _surface_orbit_intents: Dictionary = {}
 var _surface_orbit_auto_disabled: Dictionary = {}
 var _space_operation_requests: Dictionary = {}
 func _built_home_pad_ids() -> Array: return []
 func validate_space_launch(_craft: String,_flag: bool) -> Dictionary: return {"ok":true}
 func preview_space_warp_entry(_craft: String) -> Dictionary: return {"ok":true,"owned_crafts":["a"],"craft_pilots":{"a":"pilot"}}
 func preview_departure(_craft: String) -> Dictionary:
  return {"ok":true,"departure":{"craft_id":"a","origin_location_id":"homebase","destination_location_id":"satellite_crash","landing_pad_id":"homebase_pad_01","job_id":""}}
 func preview_local_surface_return(_craft: String) -> Dictionary:
  return {"ok":true,"outward_token":"surface-checkpoint-departure","route":{"craft_id":"a","origin_location_id":"satellite_crash","destination_location_id":"homebase","landing_pad_id":"satellite_pad_01","job_id":""}}

func run() -> void:
 var sim=SIM.new(); root.add_child(sim); sim.set_physics_process(false)
 var adapter=SurfaceAdapter.new(); root.add_child(adapter)
 var pilot=Pilot.new(); root.add_child(pilot); sim.configure_base_personnel(pilot)
 var b:=owners(sim,adapter); b.supply.register_craft("a")
 adapter._simulation=sim; adapter._travel=b.fleet; adapter._campaign=b.campaign
 b.equipment.configure([{"craft_id":"a","model_id":"cutlass"}]); bind(sim,b)
 sim.configure_space_runtime_tick(func(_delta: float): pass)
 sim.set_physics_process(false)
 var launch: Dictionary=sim.commit_singleplayer_space_launch(adapter,"a","surface-checkpoint-launch")
 if not check(launch.get("ok",false),"actual launch begins surface owner fixture"): finish_surface(sim,adapter,pilot); return
 sim.publish_singleplayer_space_launch_event(adapter,"surface-checkpoint-launch")
 var satellite_orbit: String=String(b.fleet.get_craft_snapshot("a").location_orbits.get("satellite_crash",""))
 var jump: Dictionary=b.fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"start_quantum","payload":{"craft_id":"a","target_orbit_id":satellite_orbit},"request_id":"surface-checkpoint-bootstrap"},{})
 if not check(jump.get("ok",false),"actual owner quantum starts toward surface body"): finish_surface(sim,adapter,pilot); return
 var entry: Dictionary={}
 for attempt in range(128):
  entry=sim.advance_singleplayer_warp_entry(adapter,"a",60.0)
  if not entry.get("ok",false) or entry.get("status")!="pending": break
 if not check(entry.get("ok",false) and entry.get("status")=="complete","actual warp entry admits canonical local Flight"): print(entry); finish_surface(sim,adapter,pilot); return
 sim.publish_singleplayer_warp_entry_event(adapter,entry.receipt_id)
 var target: Dictionary=surface_target(sim,b)
 if not check(target.get("ok",false),"actual footprint has an unblocked surface gate target"): finish_surface(sim,adapter,pilot); return
 var move: Dictionary=sim.request_singleplayer_space_move({"craft_id":"a","target_hex":target.cell,"request_id":"surface-checkpoint-move"})
 if not check(move.get("ok",false),"actual Root accepts movement to surface gate"): print(move); finish_surface(sim,adapter,pilot); return
 var gate: Dictionary={}
 var steps:=0
 for step in range(12000):
  sim._physics_process(0.05); steps=step+1
  var pose: Dictionary=b.fleet.get_flight_state("a").get_snapshot()
  var travel: Dictionary=b.fleet.get_craft_snapshot("a")
  gate=sim.preview_surface_deactivation("a","satellite_crash",pose.revision,travel.revision,sim._space_combat_state.get_area_revision(pose.space_area_id),sim._space_wing_state.get_snapshot().revision,{"runtime_authorized":true,"actor_id":"singleplayer"})
  if gate.get("ok",false): break
  if sim._space_combat_state.get_flight_controls().is_empty(): break
 print("LOCAL_SURFACE_FLIGHT_STEPS ",steps," gate=",gate.get("reason","ok"))
 if not check(gate.get("ok",false),"real movement reaches actual surface gate without pose changes"): finish_surface(sim,adapter,pilot); return
 var before_pose: Dictionary=b.fleet.get_flight_state("a").get_snapshot()
 var departure: Dictionary=sim.commit_singleplayer_departure(adapter,"a","surface-checkpoint-departure","surface-checkpoint-approach")
 if not check(departure.get("ok",false),"real Root departure deactivates the actual Flight"): print(departure); finish_surface(sim,adapter,pilot); return
 sim.publish_singleplayer_departure_events(adapter,"surface-checkpoint-departure")
 # Fixture projection of the real Adapter's retained terminal intent, not an
 # assertion that this fixture ran the complete Adapter/UI journey.
 adapter._surface_orbit_intents={"a":{"location_id":"satellite_crash","target_orbit_id":satellite_orbit,"direction":"inbound","status":"arrived"}}
 var intent_bindings: Dictionary={"simulation_root":sim,"fleet":b.fleet,"combat":sim._space_combat_state,"campaign":b.campaign,"space_operation_requests":adapter._space_operation_requests}
 check(not ORBIT_INTENT.capture(adapter,intent_bindings).has("schema"),"terminal intent alone cannot authorize unfinished approach")
 check(not b.fleet.export_checkpoint_state().has("schema"),"unfinished approach remains unsaveable")
 var landed: Dictionary=b.fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"finish_approach","payload":{"craft_id":"a"},"request_id":"surface-checkpoint-finish"},{"runtime_authorized":true})
 if not check(landed.get("ok",false),"actual owner finish_approach produces stable local surface"): finish_surface(sim,adapter,pilot); return
 var pose: Dictionary=b.fleet.get_flight_state("a").get_snapshot()
 check(pose.motion_mode=="inactive" and pose.velocity_plane==before_pose.velocity_plane and pose.angular_velocity==before_pose.angular_velocity,"actual inactive producer preserves velocity and angular velocity")
 var saved: Dictionary=b.fleet.export_checkpoint_state()
 if check(saved.get("schema")=="space_fleet_checkpoint.v1","actual inactive surface Fleet exports"):
  var wire: Dictionary=JSON.parse_string(JSON.stringify(saved,"",true,true))
  var receiver=FLEET.new(); receiver.configure()
  var restored: Dictionary=receiver.prepare_checkpoint_restore(wire,["a"])
  if check(restored.get("ok",false),"actual inactive surface Flight restores detached owners"):
   check(restored.candidate.export_checkpoint_state()==saved,"inactive pose and owner request receipts roundtrip exactly")
  var bad:=wire.duplicate(true); bad.crafts.a.flight.motion_mode="tactical"
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"inactive surface cannot restore tactical mode")
  bad=wire.duplicate(true)
  var raw: Dictionary=CODEC.decode_value(bad.crafts.a.travel).value; raw.location_id="homebase"
  bad.crafts.a.travel=CODEC.encode_value(raw).value
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"surface location outside actual body rejects")
 check_surface_intent(sim,adapter,b,intent_bindings)
 # Surface completion occurs after the next normal Root tick in the real game.
 sim._physics_process(0.05)
 var returned: Dictionary=sim.commit_singleplayer_local_return(adapter,"a")
 print("LOCAL_SURFACE_RETURN_RESULT ",returned)
 if check(returned.get("ok",false),"actual Root reactivates surface Flight through fuel-backed local return"):
  sim.publish_singleplayer_local_return_events(adapter,returned.receipt_id)
  var capture: Dictionary=HELPER.capture(sim,b)
  check(capture.get("schema")=="root_receipt_checkpoint.v1","actual finalized local-return receipt captures without signature coercion")
  if not capture.has("schema"): print("LOCAL_RETURN_CAPTURE ",capture)
  var masks: Dictionary=sim.get("_fixture_area_blockers")
  var key: String=masks.keys()[0]
  var original: Array=masks[key].duplicate()
  masks[key].append(Vector2i(-99999,-99999))
  check(not HELPER.capture(sim,b).has("schema"),"noncanonical derived body mask rejects instead of silently persisting")
  masks[key]=original
  check(HELPER.capture(sim,b).get("schema")=="root_receipt_checkpoint.v1","exact canonical derived mask restoration is saveable")
 finish_surface(sim,adapter,pilot)

func check_surface_intent(sim: Node,adapter: Node,b: Dictionary,bindings: Dictionary) -> void:
 var captured: Dictionary=ORBIT_INTENT.capture(adapter,bindings)
 if not check(captured.get("schema")=="orbit_intent_checkpoint.v1","actual inactive surface accepts fixture terminal inbound projection"): print(captured); return
 var wire: Dictionary=JSON.parse_string(JSON.stringify(captured,"",true,true))
 var fleet_wire: Dictionary=JSON.parse_string(JSON.stringify(b.fleet.export_checkpoint_state(),"",true,true))
 var builder=FLEET.new(); builder.configure()
 var restored: Dictionary=builder.prepare_checkpoint_restore(fleet_wire,["a"])
 if not check(restored.get("ok",false),"surface intent fixture obtains detached actual Fleet checkpoint"): return
 var flight: RefCounted=restored.candidate.get_flight_state("a")
 var nav_wire: Dictionary=JSON.parse_string(JSON.stringify(sim._space_combat_state.export_navigation_checkpoint(),"",true,true))
 var navigation: Dictionary=SPACE.prepare_navigation_checkpoint_candidate(nav_wire,{"a":flight},{"a":{"equipment_owner":b.equipment}})
 if not check(navigation.get("ok",false),"surface intent fixture reconstructs detached inactive Combat binding"): print(navigation); return
 var future: Dictionary={"simulation_root":sim,"fleet":restored.candidate,"combat":navigation.candidate,"campaign":b.campaign,"space_operation_requests":adapter._space_operation_requests}
 var before: Dictionary=ORBIT_INTENT._owner_stamp(future)
 var prepared: Dictionary=ORBIT_INTENT.prepare(adapter,wire,future)
 if not check(prepared.get("ok",false),"typed surface intent prepares against fresh inactive Flight identities"): print(prepared); return
 check(ORBIT_INTENT.validate(adapter,prepared.candidate,future).ok,"fresh terminal surface intent validates")
 check(before==ORBIT_INTENT._owner_stamp(future) and not adapter._surface_orbit_path_enabled,"surface intent preparation changes no owners or capability")
 var data: Dictionary=CODEC.decode_value(wire.value).value
 for change in [{"direction":"outbound"},{"status":"flying"},{"location_id":"trade_outpost"},{"pending_approach":{}}]:
  var bad:=data.duplicate(true); bad.intents.a.merge(change,true)
  var bad_wire: Dictionary={"schema":"orbit_intent_checkpoint.v1","value":CODEC.encode_value(bad).value}
  check(not ORBIT_INTENT.prepare(adapter,bad_wire,future).ok,"inactive Flight cannot manufacture terminal arrival: "+str(change))
 # Change only a detached candidate's identity binding. No physical pose or
 # live gameplay actor is edited to construct the positive producer evidence.
 navigation.candidate._inactive_actors["a"]=b.fleet.get_flight_state("a")
 check(not ORBIT_INTENT.validate(adapter,prepared.candidate,future).ok,"foreign inactive identity invalidates prepared surface intent")
 check(not ORBIT_INTENT.prepare(adapter,wire,future).ok,"matching pose with foreign inactive Flight rejects new preparation")
 navigation.candidate._inactive_actors["a"]=flight
 check(ORBIT_INTENT.validate(adapter,prepared.candidate,future).ok,"exact inactive identity restoration validates without commands")

func surface_target(sim: Node,b: Dictionary) -> Dictionary:
 var travel: Dictionary=b.fleet.get_craft_snapshot("a")
 var orbit_id: String=String(travel.location_orbits.get("satellite_crash",""))
 var body_id: String=String(Dictionary(travel.orbits.get(orbit_id,{})).get("body_id",""))
 var layout: Dictionary=LAYOUT.build(body_id)
 var body: Dictionary={}; var gates: Dictionary={}
 for cell in layout.body_cells: body[cell]=true
 for cell in layout.gate_cells: gates[cell]=true
 var current: Vector2=b.fleet.get_flight_state("a").get_snapshot().position_plane
 var choices: Array=[]
 for gate: Vector2i in layout.gate_cells:
  for shift in range(8):
   var cell: Vector2i=GRID.from_offset(gate+Vector2i(0,shift))
   var point: Vector2=GRID.HEX.axial_to_plane(Vector2(cell))
   choices.append({"cell":cell,"point":point,"distance":point.distance_squared_to(current)})
 choices.sort_custom(func(a: Dictionary,c: Dictionary)->bool: return float(a.distance)<float(c.distance))
 for choice: Dictionary in choices:
  var cells: Array=sim._space_combat_state.preview_actor_cells("a",{"position_plane":choice.point})
  var valid: bool=not cells.is_empty(); var touches:=false
  for cell: Vector2i in cells:
   var offset: Vector2i=GRID.to_offset(cell)
   if body.has(offset): valid=false
   if gates.has(offset): touches=true
  if valid and touches: return {"ok":true,"cell":choice.cell}
 return {"ok":false}

func finish_surface(sim: Node,adapter: Node,pilot: Node) -> void:
 sim.free(); adapter.free(); pilot.free()
 print("LOCAL_SURFACE_FLEET_CHECKPOINT passed=%d failed=%d" % [passed,failed])
 if failed==0: print("LOCAL_SURFACE_FLEET_CHECKPOINT_PASS")
 quit(0 if failed==0 else 1)
