extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
 var sim:=Core.new(3);sim.auto_tick=false;root.add_child(sim)
 sim._state.region="station";sim._state.ship.position=[0.0,28.0];sim._state.ship.target=[0.0,28.0]
 for u:Dictionary in sim._state.crew.values():u.position=[0.0,20.0];u.target=u.position.duplicate()
 check(sim.submit({"type":"trade","side":"buy","item":"food","amount":2,"request_id":"buy"}).ok,"purchase accepted")
 check(sim.snapshot().cargo.food==0,"purchase does not teleport into hold")
 if not sim.snapshot().has("hauling"):check(false,"persistent hauling state exists");quit(1);return
 sim.advance(0.1)
 check(sim.snapshot().hauling.jobs.size()==1,"automatic worker assignment")
 var before:Dictionary=sim.snapshot();sim._state.paused=true;sim.advance(20)
 check(sim.snapshot().crew==before.crew,"pause stops carriers")
 sim._state.paused=false
 for i in 1200:
  sim.advance(0.1)
  if sim.snapshot().cargo.food==2:break
 check(sim.snapshot().cargo.food==2,"worker delivers real cargo")
 check(sim.snapshot().hauling.jobs.is_empty(),"completed job released")
 check(sim.save_game("res://output/haul-flow.json").ok,"haul save valid")
 var credits:int=sim.snapshot().credits
 check(sim.submit({"type":"trade","side":"sell","item":"food","amount":1,"request_id":"sell"}).ok,"sell creates delivery")
 check(sim.snapshot().credits==credits,"no payment before delivery")
 for i in 1200:
  sim.advance(0.1)
  if sim.snapshot().hauling.jobs.is_empty():break
 check(sim.snapshot().credits==credits+12,"payment at trader")
 print("HAUL FLOW failures=",failures);quit(failures)
