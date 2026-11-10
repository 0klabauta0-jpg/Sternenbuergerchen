extends SceneTree
var failed := 0
func _init() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	if not value: failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _run() -> void:
	root.size=Vector2i(1920,1080)
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	screen.call("request_operation","navigate",{"mode":"personnel"})
	for frame in range(4): await process_frame
	var presenter: Control=screen.get("_operations_presenter")
	check(presenter.find_child("Navigate_fob",true,false)==null,"FOB removed from regular navigation")
	var mobile: Control=presenter.find_child("Navigate_jobs",true,false)
	check(mobile.get_index()==mobile.get_parent().get_child_count()-1,"Smart Mobile is bottommost navigation action")
	var columns: Dictionary=presenter.get("_columns")
	check(columns.roster.size.x<presenter.get("_workspace").size.x*.35,"personnel uses compact bounded roster width")
	var shared: Control=presenter.find_child("PersonnelInventory",true,false)
	check(shared!=null,"shared reference inventory exists")
	screen.call("request_operation","navigate",{"mode":"squad"})
	await process_frame
	check(presenter.find_child("PersonnelInventory",true,false)==shared,"squad uses same inventory instance")
	check(presenter.find_child("SquadCraftPreview",true,false)!=null,"squad has actual ship preview")
	var canvas: Control=load("res://scripts/ui/star_map_canvas.gd").new(); root.add_child(canvas)
	check(canvas.has_signal("location_selected"),"planet surface sites share destination selection signal")
	check(canvas.has_method("set_location_snapshot"),"planet markers project authoritative site availability")
	flow.queue_free(); canvas.queue_free(); await process_frame
	print("OPERATIONS_LAYOUT failed=",failed); quit(1 if failed else 0)
