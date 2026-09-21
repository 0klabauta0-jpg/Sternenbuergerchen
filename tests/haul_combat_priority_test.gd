extends SceneTree
const Campaign=preload("res://scripts/core/team_campaign.gd")
var failures:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func send(sim:Node,kind:String,data:Dictionary={}) -> Dictionary:
 serial+=1;var c:=data.duplicate();c.type=kind;c.request_id="priority-%d"%serial;return sim.submit(c)
func run() -> void:
 var sim:=Campaign.new(3);sim.auto_tick=false;root.add_child(sim);sim.set_guest(7)
 send(sim,"assign_team",{"peer_id":7,"team":1});send(sim,"start_match")
 for core:Node in sim._cores:
  core._state.region="station"
  for unit:Dictionary in core._state.crew.values():unit.position=[0.0,20.0];unit.target=[0.0,20.0]
 check(send(sim,"attack",{"unit_id":"ida","target_id":"team1:jaro"}).ok,"manual PvP order accepted")
 check(send(sim,"trade",{"side":"buy","item":"food","amount":1}).ok,"automatic freight queued")
 sim.advance(0.05)
 check(sim._combat.orders.has("0:ida") and sim._cores[0]._state.crew.ida.assignment=="idle","manual PvP survives automatic job allocation")
 check(sim._cores[0]._state.crew.jaro.assignment=="hauling","other free NPC carries instead")
 print("HAUL COMBAT PRIORITY failures=",failures);quit(failures)
