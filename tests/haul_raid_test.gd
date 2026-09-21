extends SceneTree
const Campaign=preload("res://scripts/core/team_campaign.gd")
var failures:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func send(s:Node,type:String,data:Dictionary={},peer:int=1) -> Dictionary:
 serial+=1;var c:=data.duplicate();c.type=type;c.request_id="raid-%d"%serial;return s.submit(c,peer)
func run() -> void:
 var sim:=Campaign.new(3);sim.auto_tick=false;root.add_child(sim);sim.set_guest(7)
 send(sim,"assign_team",{"peer_id":7,"team":1});send(sim,"start_match")
 for i in 2:
  var s:Dictionary=sim._cores[i]._state;s.region="station";s.ship.position=[0.0,28.0];s.ship.target=s.ship.position.duplicate()
  for u:Dictionary in s.crew.values():u.position=[0.0,20.0];u.target=u.position.duplicate()
 check(send(sim,"trade",{"side":"buy","item":"medical_supplies","amount":1}).ok,"buy a physical medical shipment")
 for i in 800:
  sim.advance(0.05)
  if not sim._cores[0]._state.hauling.jobs.is_empty() and sim._cores[0]._state.hauling.jobs[0].held==1:break
 var s:Dictionary=sim._cores[0]._state
 check(not s.hauling.jobs.is_empty() and s.hauling.jobs[0].held==1,"carrier holds goods before ship arrival")
 if s.hauling.jobs.is_empty():quit(1);return
 var save:=sim.save_game("res://output/haul-raid.json");check(save.ok,"save carrier and shared stock: "+save.reason)
 var loaded:=sim.load_game("res://output/haul-raid.json");check(loaded.ok,"restore active carrier: "+loaded.reason)
 s=sim._cores[0]._state
 var victim:String=s.hauling.jobs[0].unit;var at:Array=s.crew[victim].position.duplicate()
 s.crew[victim].health=1.0
 var enemy:Dictionary=sim._cores[1]._state.crew.ida;enemy.position=at.duplicate();enemy.target=at.duplicate()
 check(send(sim,"attack",{"unit_id":"ida","target_id":"team0:"+victim},7).ok,"enemy attacks real carrier")
 sim.advance(0.1)
 check(s.crew[victim].health==0,"carrier downed")
 check(s.cargo.medical_supplies==0,"victim cargo not credited")
 var crates:Dictionary=sim._freight.crates
 check(crates.size()==1,"held unit dropped exactly once")
 if crates.size()!=1:quit(1);return
 var id:String=crates.keys()[0]
 check(crates[id].amount==1 and crates[id].item=="medical_supplies","real dropped content")
 check(sim.snapshot_for(1).freight_world==sim.snapshot_for(7).freight_world,"both teams see same crate")
 var request:Dictionary={"type":"pickup_freight","crate_id":id,"unit_id":"ida","request_id":"same-pickup"}
 check(sim.submit(request,7).ok and sim.submit(request,7).ok,"duplicate request reuses receipt")
 check(sim._cores[1]._state.hauling.jobs.size()==1,"no duplicate pickup job")
 for i in 1200:
  sim.advance(0.05)
  if sim._cores[1]._state.cargo.medical_supplies==1:break
 check(sim._cores[1]._state.cargo.medical_supplies==1 and s.cargo.medical_supplies==0,"stolen cargo delivered only to rival ship")
 check(sim._freight.crates.is_empty(),"looted crate exhausted")
 check(not send(sim,"pickup_freight",{"crate_id":id,"unit_id":"jaro"}).ok,"exhausted crate cannot be reclaimed")
 check(sim.save_game("res://output/haul-raid-after.json").ok,"save after robbery and recovery")
 print("HAUL RAID failures=",failures);quit(failures)
