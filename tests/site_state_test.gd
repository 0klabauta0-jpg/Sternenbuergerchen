extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const Sites=preload("res://scripts/core/site_state.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
 var sim:=Core.new(3);sim.auto_tick=false;root.add_child(sim)
 var state:Dictionary=sim._state
 state.discovery.radar_scanned=true;state.discovery.signals=Catalog.radar_contacts("rust");state.wreck_remaining=3
 Sites.enter(state,"rust_v2")
 check(not state.discovery.radar_scanned and state.wreck_remaining==8,"new site starts unexplored and stocked")
 state.discovery.radar_scanned=true;state.discovery.signals=Catalog.radar_contacts("rust_v2");state.wreck_remaining=6
 Sites.enter(state,"rust")
 check(state.discovery.radar_scanned and state.wreck_remaining==3,"return keeps previous site depletion")
 check(sim.save_game("res://output/n8-sites.json").ok and sim.load_game("res://output/n8-sites.json").ok,"multiple site records survive save/load")
 Sites.enter(sim._state,"rust_v2")
 check(sim._state.wreck_remaining==6 and sim._state.discovery.signals[0].position==Catalog.radar_contacts("rust_v2")[0].position,"restored other site retains correct contacts")
 var bad:Dictionary=sim.export_payload();bad.state.site_records.rust.discovery.signals[0].kind="forged"
 check(not sim.restore_payload(bad).ok,"inactive site contact kind validated")
 bad=sim.export_payload();bad.state.site_records.rust.discovery.satellite_found=true
 check(not sim.restore_payload(bad).ok,"inactive site discovery consistency validated")
 print("SITE STATE failures=",failures);quit(failures)
