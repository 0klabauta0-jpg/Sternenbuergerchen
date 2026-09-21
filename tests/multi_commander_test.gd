extends SceneTree
func _initialize() -> void:
	var sim:Node=preload("res://scripts/core/simulation_root.gd").new(3)
	sim.auto_tick=false;root.add_child(sim)
	sim.set_guest(7);sim.set_guest(8)
	var first:Dictionary=sim.submit({"type":"toggle_pause","request_id":"first"},7)
	var second:Dictionary=sim.submit({"type":"toggle_pause","request_id":"second"},8)
	if not first.ok or not second.ok:
		printerr("FAIL earlier commander loses membership when another joins");quit(1);return
	sim.clear_guest(7)
	if sim.submit({"type":"toggle_pause","request_id":"gone"},7).ok:
		printerr("FAIL disconnected commander retained authority");quit(1);return
	if not sim.submit({"type":"toggle_pause","request_id":"remaining"},8).ok:
		printerr("FAIL removing one commander removed another");quit(1);return
	print("MULTI_COMMANDER 4 checks passed")
	quit()

