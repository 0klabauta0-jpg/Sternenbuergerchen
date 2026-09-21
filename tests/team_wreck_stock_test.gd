extends SceneTree
const Campaign=preload("res://scripts/core/team_campaign.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func finish(core:Node) -> void:
 var s:Dictionary=core._state;s.region="rust";s.contract.status="active" if s.contract.status=="available" else s.contract.status
 s.discovery.radar_scanned=true;s.discovery.signals=Catalog.radar_contacts("rust");s.discovery.signals[0].identified=true;s.discovery.signals[0].kind="satellite";s.discovery.satellite_found=true
 s.ship.position=Catalog.landmarks("rust").shuttle.duplicate();s.ship.target=s.ship.position.duplicate()
 s.crew.ida.position=Catalog.interaction_point("rust","satellite");s.crew.ida.target=s.crew.ida.position.duplicate();s.crew.ida.assignment="salvage"
 s.salvage={"active":true,"unit_id":"ida","remaining":0.01,"total":1.0,"phase":"working"}
 core.advance(0.1)
func run() -> void:
 var sim:=Campaign.new(3);sim.auto_tick=false;root.add_child(sim);sim._bind_world(1,"rust")
 finish(sim._cores[0]);finish(sim._cores[1]);finish(sim._cores[0])
 var a:Dictionary=sim._cores[0].snapshot();var b:Dictionary=sim._cores[1].snapshot()
 check(a.cargo.scrap+b.cargo.scrap==8,"one shared eight-unit wreck across teams")
 check(a.cargo.blackbox+b.cargo.blackbox==1,"one shared blackbox across teams")
 check(a.wreck_remaining==0 and b.wreck_remaining==0,"both projections show exhausted wreck")
 sim._bind_world(0,"ice")
 check(sim._cores[0].snapshot().wreck_remaining==8,"another world keeps own wreck")
 sim._bind_world(0,"rust")
 check(sim._cores[0].snapshot().wreck_remaining==0,"return cannot refill shared wreck")
 print("TEAM WRECK STOCK failures=",failures);quit(failures)
