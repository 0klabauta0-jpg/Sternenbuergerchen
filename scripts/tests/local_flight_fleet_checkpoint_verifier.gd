extends "res://scripts/tests/root_local_orbit_receipts_verifier.gd"
## Reuses real launch/entry/move/warp-departure producers from the bounded fixture.
## No Flight pose, actor position, receipt or gameplay rule is patched for a pass.

func roundtrip_local(source: Node,b: Dictionary,adapter: Node) -> Dictionary:
 var state: Dictionary = b.fleet.export_checkpoint_state()
 if not check(state.get("schema")=="space_fleet_checkpoint.v1","actual stable local/quantum Fleet exports"): print(state); return {}
 var wire: Dictionary = JSON.parse_string(JSON.stringify(state,"",true,true))
 var receiver = FLEET.new(); receiver.configure()
 var before: Dictionary=receiver.export_checkpoint_state()
 var prepared: Dictionary=receiver.prepare_checkpoint_restore(wire,["a"])
 if not check(prepared.get("ok",false),"typed JSON restores detached actual Flight/Travel owners"): print(prepared); return {}
 var rebuilt: RefCounted=prepared.candidate
 check(receiver.export_checkpoint_state()==before,"detached Fleet preparation preserves receiver")
 check(rebuilt!=b.fleet and rebuilt.get_flight_state("a")!=b.fleet.get_flight_state("a"),"restored Fleet and Flight identities are fresh")
 check(rebuilt.export_checkpoint_state()==state,"complete semantic Fleet checkpoint survives roundtrip")
 var raw: Dictionary=CODEC.decode_value(state.crafts.a.travel).value
 if state.crafts.a.flight.coordinate_frame=="local":
  var bad:=wire.duplicate(true); bad.crafts.a.flight.space_area_id="orbit_approach:moon"
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"wrong canonical orbit body rejects")
  bad=wire.duplicate(true); bad.crafts.a.flight.motion_mode="grounded"
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"local grounded mode rejects")
  bad=wire.duplicate(true); bad.crafts.a.flight.position_plane=[1000000000.0,1000000000.0]
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"local position outside current map bounds rejects")
  bad=wire.duplicate(true); bad.crafts.a.flight.space_area_id="atmosphere:satellite_crash"
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"unsupported atmosphere flight rejects")
  bad=wire.duplicate(true)
  var corrupt:=raw.duplicate(true); corrupt.phase="surface"; corrupt.location_id="satellite_crash"
  bad.crafts.a.travel=CODEC.encode_value(corrupt).value
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"surface phase cannot retain tactical Flight")
  bad=wire.duplicate(true); corrupt=raw.duplicate(true); corrupt.orbit_id="moon_orbit"
  bad.crafts.a.travel=CODEC.encode_value(corrupt).value
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"changed travel body cannot retain previous local area")
  test_area_epoch(rebuilt._owners.a,state.crafts.a)
 for key in ["tick","revision"]:
  var bad:=wire.duplicate(true); bad.crafts.a.flight[key]=0.5
  check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"fractional Flight monotonic field rejects: "+key)
 var bad:=wire.duplicate(true); bad.crafts.a.flight.coordinate_frame="unknown"
 check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"unknown coordinate frame rejects")
 bad=wire.duplicate(true); bad.crafts.a.flight.velocity_plane=["bad",0]
 check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"untyped velocity wire rejects")
 bad=wire.duplicate(true); bad.crafts.a.flight["owner_id"]=42
 check(not receiver.prepare_checkpoint_restore(bad,["a"]).ok,"unexpected runtime identity field rejects")
 check(receiver.export_checkpoint_state()==before,"all corrupt restore preparations leave receiver untouched")
 var travel = load("res://scripts/core/singleplayer_space_travel_state.gd").new(); travel.configure("a")
 var handle: Dictionary=travel.prepare_checkpoint_restore(state.crafts.a)
 if check(handle.get("ok",false),"standalone actual Travel checkpoint prepares"):
  travel.configure("a")
  check(not travel.validate_checkpoint_restore(handle.prepared).ok,"same-value reconfigure invalidates pending Travel restore by epoch")
 var result: Dictionary=super.roundtrip_local(source,b,adapter)
 print("LOCAL_FLIGHT_FLEET_CHECKPOINT_STAGE phase=",raw.phase)
 return result

func test_area_epoch(owner: RefCounted,state: Dictionary) -> void:
 var raw: Dictionary=CODEC.decode_value(state.travel).value
 var payload:={"craft_id":"a","location_id":"satellite_crash"}
 var context:={"request_id":"old-area-preparation","request_signature":JSON.stringify({"operation":"begin_approach","payload":payload},"",true),"operation":"begin_approach","payload":payload,"source_area_id":state.flight.space_area_id,"target_area_id":state.flight.space_area_id,"expected_travel_revision":raw.revision,"expected_phase":"orbit","context_id":"old-area-preparation"}
 var area: Dictionary=owner._prepare_space_area_transition_state(raw.revision,context)
 if not check(area.get("ok",false),"actual local Travel can prepare read-only surface transition candidate"): print(area); return
 check(owner._validate_prepared_space_area_state(area,context).get("ok",false),"fresh area candidate validates before checkpoint restore")
 var checkpoint: Dictionary=owner.prepare_checkpoint_restore(state)
 if not check(checkpoint.get("ok",false),"same legitimate Travel state prepares restore"): return
 check(owner.commit_checkpoint_restore(checkpoint.prepared).ok,"same legitimate checkpoint restores silently")
 check(not owner._validate_prepared_space_area_state(area,context).get("ok",false),"old signed area candidate rejects after same-value restore epoch change")
