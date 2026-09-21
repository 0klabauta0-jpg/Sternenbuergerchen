extends SceneTree
const Campaign=preload("res://scripts/core/team_campaign.gd")
const Core=preload("res://scripts/core/simulation_root.gd")
const Haul=preload("res://scripts/core/cargo_hauling.gd")
var failures:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func send(sim:Node,kind:String,data:Dictionary={},peer:int=1) -> Dictionary:
 serial+=1;var c:=data.duplicate();c.type=kind;c.request_id="guard-%d"%serial;return sim.submit(c,peer)
func run() -> void:
 var sim:=Campaign.new(3);sim.auto_tick=false;root.add_child(sim);sim.set_guest(7)
 send(sim,"assign_team",{"peer_id":7,"team":1});send(sim,"start_match")
 for core:Node in sim._cores:
  core._state.region="station";core._state.ship.position=[0.0,28.0];core._state.ship.target=[0.0,28.0]
  for unit:Dictionary in core._state.crew.values():unit.position=[0.0,20.0];unit.target=unit.position.duplicate()
 check(send(sim,"trade",{"side":"buy","item":"food","amount":2}).ok,"queue two units")
 check(not send(sim,"launch").ok,"cannot depart during pending loading")
 check(send(sim,"cancel_hauling").ok,"cancel queued consignment")
 check(sim._freight.crates.size()==1 and sim._freight.crates.values()[0].amount==2,"cancel preserves full source consignment")
 var id:String=sim._freight.crates.keys()[0]
 sim._freight.crates[id].amount=1 # Race fixture: a single physical unit, two arriving carriers.
 check(send(sim,"pickup_freight",{"crate_id":id,"unit_id":"ida"}).ok,"first competitor walks to crate")
 check(send(sim,"pickup_freight",{"crate_id":id,"unit_id":"ida"},7).ok,"second competitor walks to same crate")
 for i in 1200:
  sim.advance(0.05)
  if sim._cores[0]._state.cargo.food+sim._cores[1]._state.cargo.food==1:break
 check(sim._cores[0]._state.cargo.food+sim._cores[1]._state.cargo.food==1 and sim._freight.crates.is_empty(),"race gives exactly one unit")
 sim.advance(2)
 check(sim._cores[0]._state.hauling.jobs.is_empty() and sim._cores[1]._state.hauling.jobs.is_empty(),"loser releases carrier without hanging")
 var solo:=Core.new(3);solo.auto_tick=false;root.add_child(solo)
 check(send(solo,"transfer",{"item":"scrap","amount":2,"direction":"load"}).ok,"base load accepted without manually positioning worker")
 for i in 1200:
  solo.advance(0.05)
  if not solo._state.hauling.jobs.is_empty() and solo._state.hauling.jobs[0].held==1:break
 check(solo._state.hauling.jobs[0].held==1,"ramp-aware worker carries base material")
 var payload:Dictionary=solo.export_payload()
 for field:String in ["held","price","phase","unit"]:
  var bad:Dictionary=payload.duplicate(true)
  bad.state.hauling.jobs[0][field]={"held":-1,"price":999,"phase":"unknown","unit":"missing"}[field]
  var before:Dictionary=solo.snapshot()
  check(not solo.restore_payload(bad).ok and solo.snapshot()==before,"reject malformed hauling atomically: "+field)
 send(solo,"cancel_hauling")
 var amount:=0
 for box:Dictionary in solo._state.freight_world.crates.values():amount+=int(box.amount)
 check(amount==2 and solo._state.cargo.scrap==0 and solo._state.inventory.scrap==6,"cancel mid-carry preserves source and held quantity")
 check(solo.save_game("res://output/haul-cancel.json").ok,"save abandoned crates")
 check(solo.load_game("res://output/haul-cancel.json").ok,"load abandoned crates")
 print("HAUL GUARDS failures=",failures);quit(failures)
