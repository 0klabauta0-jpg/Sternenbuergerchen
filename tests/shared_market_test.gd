extends SceneTree
const Campaign=preload("res://scripts/core/team_campaign.gd")
var failures:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func send(sim:Node,type:String,data:Dictionary={},peer:int=1) -> Dictionary:
 serial+=1;var c:=data.duplicate();c.type=type;c.request_id="stock-%d"%serial;return sim.submit(c,peer)
func run() -> void:
 var sim:=Campaign.new(3);sim.auto_tick=false;root.add_child(sim);sim.set_guest(7)
 send(sim,"assign_team",{"peer_id":7,"team":1});send(sim,"start_match")
 if not sim.snapshot().has("market_stock"):
  check(false,"shared finite market state exists");quit(1);return
 for core:Node in sim._cores:core._state.region="station";core._state.credits=1000
 var stock:Dictionary=sim._cores[0]._state.market_stock.station
 for item:String in ["food","medical_supplies"]:
  stock.items[item]=1
  check(send(sim,"trade",{"side":"buy","item":item,"amount":1}).ok,"first team buys last "+item)
  check(not send(sim,"trade",{"side":"buy","item":item,"amount":1},7).ok,"second team cannot duplicate "+item)
  check(sim.snapshot_for(7).market_stock.station.items[item]==0,"shared depletion visible for "+item)
 stock.items.parts=2;stock.remaining=300.0
 check(send(sim,"trade",{"side":"buy","item":"parts","amount":2}).ok,"first team takes remaining two parts")
 var credits:int=sim.snapshot_for(7).credits
 check(not send(sim,"trade",{"side":"buy","item":"parts","amount":1},7).ok,"other team cannot buy sold-out goods")
 check(sim.snapshot_for(7).credits==credits,"failed purchase charges nothing")
 for tick in 3000:
  sim.advance(0.1)
  if sim._cores[0]._state.hauling.jobs.is_empty():break
 check(send(sim,"trade",{"side":"sell","item":"parts","amount":1}).ok,"sale returns a real unit to trader")
 for tick in 1200:
  sim.advance(0.1)
  if sim._cores[0]._state.hauling.jobs.is_empty():break
 check(send(sim,"trade",{"side":"buy","item":"parts","amount":1},7).ok,"other team can buy sold unit")
 stock.remaining=300.0
 send(sim,"toggle_pause");sim.advance(400)
 check(stock.items.parts==0 and stock.remaining==300.0,"pause stops market replenishment")
 send(sim,"toggle_pause");sim.advance(299)
 check(stock.items.parts==0 and stock.remaining>0,"no premature or per-team double replenishment")
 check(sim.save_game("res://output/n8-shared-market.json").ok,"shared stock and near-due delivery save")
 check(sim.load_game("res://output/n8-shared-market.json").ok,"shared stock and timer restore")
 stock=sim._cores[0]._state.market_stock.station
 check(stock.items.parts==0 and stock.remaining<1.1,"restore does not refill or reset timer")
 sim.advance(1.1)
 check(stock.items.parts>0,"time-based delivery replenishes shared stock")
 check(sim.snapshot_for(1).market_stock==sim.snapshot_for(7).market_stock,"all teams see same market goods and timer")
 print("SHARED MARKET failures=",failures);quit(failures)
