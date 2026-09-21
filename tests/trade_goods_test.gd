extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
 var sim:=Core.new(3);sim.auto_tick=false;root.add_child(sim);sim._state.region="station"
 for item:String in ["food","medical_supplies"]:
  check(Catalog.ITEMS.has(item) and Catalog.prices("station").has(item),"distinct tradable good "+item)
  if not Catalog.ITEMS.has(item):continue
  var before:int=sim.snapshot().market_stock.station.items[item]
  check(sim.submit({"type":"trade","side":"buy","item":item,"amount":1,"request_id":item}).ok,"buy "+item)
  check(sim.snapshot().cargo[item]==0,"purchase awaits carrier "+item)
  for tick in 1200:
   sim.advance(0.1)
   if sim.snapshot().hauling.jobs.is_empty():break
  check(sim.snapshot().cargo[item]==1 and sim.snapshot().market_stock.station.items[item]==before-1,"real cargo and trader stock "+item)
 check(sim.save_game("res://output/n8-trade-goods.json").ok and sim.load_game("res://output/n8-trade-goods.json").ok,"new goods preserve save integrity")
 print("TRADE GOODS failures=",failures);quit(failures)
