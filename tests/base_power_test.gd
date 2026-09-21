extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const Power=preload("res://scripts/core/base_infrastructure.gd")
var failures:=0
var checks:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,label:String) -> void:
 checks+=1
 if not value:failures+=1;printerr("FAIL ",label)
func command(sim:Node,type:String,extra:Dictionary={}) -> Dictionary:
 serial+=1;var request:Dictionary=extra.duplicate();request.type=type;request.request_id="power-%d"%serial;return sim.submit(request)
func run() -> void:
 var sim:=Core.new(3);sim.auto_tick=false;root.add_child(sim)
 check(Power.budget(sim.snapshot()).supply==24,"starter solar is real")
 sim._state.base.workbench_tier=2
 sim._state.inventory.parts=8
 var start:Dictionary=command(sim,"assign_work",{"unit_id":"ida","recipe_id":"research_materials"})
 check(start.ok,"research reserved")
 sim.advance(30)
 var remaining:float=sim.snapshot().work.remaining;var stock:Dictionary=sim.snapshot().inventory
 check(remaining==45,"insufficient power pauses progress")
 var saved:Dictionary=sim.save_game("res://output/n8-power.json");print(saved)
 check(saved.ok,"power shortage save")
 check(sim.load_game("res://output/n8-power.json").ok,"power shortage restore")
 check(command(sim,"toggle_sender").ok,"player can free supply without deadlock")
 sim.advance(60)
 check(not sim.snapshot().work.active and "refine_alloy" in sim.snapshot().blueprints,"restored job finishes on available power")
 check(sim.snapshot().inventory==stock,"resume does not charge twice")
 check(command(sim,"build_solar").ok==false,"no bypass outside ordinary work command")
 check(command(sim,"assign_work",{"unit_id":"ida","recipe_id":"build_solar"}).ok,"solar build uses work transaction")
 sim.advance(40)
 check(sim.snapshot().base.infrastructure.solar==4 and Power.budget(sim.snapshot()).supply==32,"completed module adds real supply")
 var payload:Dictionary=sim.export_payload();payload.state.base.infrastructure.solar=-2
 check(not sim.restore_payload(payload).ok,"corrupt infrastructure rejected atomically")
 var shop:=Core.new(5);shop.auto_tick=false;root.add_child(shop);shop._state.credits=20000
 check(not command(shop,"buy_power",{"offer":"build_fusion_large"}).ok,"large fusion requires small reactor")
 check(shop.snapshot().credits==20000,"rejected purchase charges nothing")
 for offer:String in ["upgrade_solar","upgrade_solar_three","build_fusion_small","build_fusion_large"]:
  var before:int=shop.snapshot().credits
  var purchase:Dictionary={"type":"buy_power","offer":offer,"request_id":"purchase-"+offer}
  var result:Dictionary=shop.submit(purchase)
  check(result.ok,"buy "+offer+": "+str(result))
  check(shop.snapshot().credits==before-Power.offers()[offer].price,"exact price "+offer)
  check(shop.submit(purchase)==result and shop.snapshot().credits==before-Power.offers()[offer].price,"network retry cannot charge again "+offer)
 check(Power.budget(shop.snapshot()).supply==386,"three solar III plus both reactors supply power")
 check(shop.save_game("res://output/n8-fusion.json").ok and shop.load_game("res://output/n8-fusion.json").ok,"purchased fusion survives save and restore")
 check(Power.new().has_method("site_access"),"sender upgrade changes distant offers")
 if Power.new().has_method("site_access"):
  var starter:=Core.new(3)
  check(not Power.new().call("site_access",starter.snapshot(),"rust_v3").is_empty(),"distant contract coordinates need upgraded sender")
  starter._state.base.infrastructure.sender_tier=2
  check(Power.new().call("site_access",starter.snapshot(),"rust_v3").is_empty(),"sender II unlocks distant contract coordinates")
  check(Power.new().call("site_access",starter.snapshot(),"base").is_empty(),"home route never gated")
  starter.free()
 var delivery:=Core.new(3);delivery._state.credits=1000
 delivery._state.market_stock.station.items["power:build_solar"]=0
 var balance:int=delivery.snapshot().credits
 check(not delivery.submit({"type":"buy_power","offer":"build_solar","request_id":"sold-out"}).ok,"delivered power plants also use shared trader stock")
 check(delivery.snapshot().credits==balance,"sold-out plant purchase charges nothing")
 delivery.free()
 print("POWER ",checks," checks failures=",failures);quit(1 if failures else 0)
