extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Sites=preload("res://scripts/core/site_state.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
 for region:String in ["rust_v2","rust_v3","rust_v4"]:
  var sim:=Core.new(3);sim.auto_tick=false;root.add_child(sim);sim._state.region=region;Sites.enter(sim._state,region)
  var id:="mining_site__"+region;var point:Array=Catalog.interaction_point(region,id)
  sim._state.crew.ida.position=point;sim._state.crew.ida.target=point
  var request:Dictionary={"type":"gather","unit_id":"ida","site_id":id,"request_id":"radar"}
  check(not sim.submit(request).ok,"unidentified variant mining blocked "+region)
  sim._state.discovery.radar_scanned=true;sim._state.discovery.signals=Catalog.radar_contacts(region);sim._state.discovery.signals[1].identified=true;sim._state.discovery.signals[1].kind="mining_site"
  request.request_id="tool"
  check(not sim.submit(request).ok,"tool-less variant mining blocked "+region)
  sim._state.crew.ida.equipment.tool="multitool";sim._state.crew.ida.equipment.attachment="mining_attachment";request.request_id="ready"
  check(sim.submit(request).ok,"identified equipped miner starts "+region)
 print("VARIANT EQUIPMENT failures=",failures);quit(failures)
