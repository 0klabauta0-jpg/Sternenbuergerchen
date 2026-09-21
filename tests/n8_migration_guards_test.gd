extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const Old=preload("res://scripts/core/legacy_n7/save_validator.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func legacy(sim:Node) -> Dictionary:
 var p:Dictionary=sim.export_payload()
 for key:String in ["site_revision","site_records","discovery_site","world_claims"]:p.state.erase(key)
 for item:String in ["food","medical_supplies"]:
  p.state.inventory.erase(item);p.state.cargo.erase(item)
  for unit:Dictionary in p.state.crew.values():unit.backpack.items.erase(item)
 p.state.erase("market_stock")
 p.state.base.erase("infrastructure")
 p.state.blueprints.erase("build_solar")
 for id:String in p.state.resources.keys():
  if "_v" in id:p.state.resources.erase(id)
 for id:String in p.state.ground.enemies.keys():
  if "_v" in id:p.state.ground.enemies.erase(id)
 return p
func run() -> void:
 var sim:=Core.new(3);sim.auto_tick=false;root.add_child(sim)
 var old:=legacy(sim);old.state.ship.position=[0,28];old.state.ship.target=[0,28]
 check(Old.validate(old).is_empty(),"fixture is genuinely valid N7")
 var result:Dictionary=sim.restore_payload(old)
 check(result.ok,"valid N7 ramp landing migrates "+str(result))
 check(Nav.landing_clear("base",sim.snapshot().ship),"migrated ship has safe landing")
 var damaged:=legacy(sim);damaged.state.resources.erase("mining_site")
 check(not sim.restore_payload(damaged).ok,"missing legacy stock is rejected")
 var malformed:Dictionary=sim.export_payload();malformed.state.base=3
 check(not sim.restore_payload(malformed).ok,"malformed base rejected without crash")
 print("MIGRATION GUARDS failures=",failures);quit(failures)
