extends SceneTree
var checks:=0
var failures:=0
func _init() -> void: call_deferred("_run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: ",label)
	else:print("PASS: ",label)
func _run()->void:
	root.size=Vector2i(1920,1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow:Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
	var screen:Node=flow.get_node("HomebaseScreen")
	screen.request_operation("navigate",{"mode":"mission"})
	var presenter:Node=screen.get("_operations_presenter")
	var nav:Dictionary=presenter.get("_nav")
	check(nav.mission.text=="Flugdeck","navigation calls launch view Flugdeck")
	check(nav.mission.get_index()+1==nav.map.get_index(),"Flugdeck immediately precedes Sternkarte")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.size=resolution
		for i in 24:await process_frame
		presenter.refresh()
		for i in 4:await process_frame
		var base:Node=presenter.get("_base")
		check(base.is_visible_in_tree() and base.get("_pad_preview"),"direct flightdeck entry shows actual pad %s"%resolution)
		check(base.get("_viewport").render_target_update_mode==SubViewport.UPDATE_WHEN_VISIBLE,"outer pad compositor stays live for inner dirty-render completion")
		var footer:Control=presenter.get("_columns").flight
		var pilot:Control=presenter.get("_pilot_selector")
		var board:Control=presenter.get("_board")
		var start:Control=presenter.get("_start")
		var craft:Control=presenter.get("_craft_selector")
		var pad:Control=presenter.get("_pad_selector")
		check(pilot.size.x<=220,"pilot choice bounded and compact %s"%resolution)
		check(absf(board.global_position.x-start.global_position.x)<2 and board.global_position.y<start.global_position.y,"boarding above launch in one compact column %s"%resolution)
		check(craft.global_position.x>pad.global_position.x,"ship dropdown to right of pad dropdown")
		check(footer.get_global_rect().grow(1).encloses(start.get_global_rect()),"launch stays inside compact footer %s"%resolution)
		check(footer.get_global_rect().grow(1).encloses(presenter.get("_launch_reason").get_global_rect()),"readiness reason stays inside footer %s"%resolution)
		check(not presenter.get("_squad_craft_image").is_visible_in_tree(),"duplicate lower-left craft card hidden on flightdeck")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var image:Image=base.get("_view").get("_subviewport").get_texture().get_image()
			var colors:Dictionary={}
			for y in range(0,image.get_height(),16):
				for x in range(0,image.get_width(),16):colors[image.get_pixel(x,y).to_html()]=true
			check(colors.size()>40,"actual pad render has detailed nonblack content %s"%resolution)
			var folder:="C:/dev/SternenBuergerchen/output/flugdeck_20261110/native"
			DirAccess.make_dir_recursive_absolute(folder)
			root.get_texture().get_image().save_png(folder+"/flugdeck_%d.png"%resolution.x)
		# Leave and re-enter through a different view; don't initialize by walking base first.
		screen.request_operation("navigate",{"mode":"squad"});await process_frame
		screen.request_operation("navigate",{"mode":"mission"})
	# Regression: return from a close pad preview, then move the actual rendered camera.
	root.size=Vector2i(1280,720)
	screen.request_operation("navigate",{"mode":"base"})
	for i in 12:await process_frame
	flow.get("_campaign_tutorial").refresh()
	presenter.get("_nav").base.mouse_entered.emit()
	for i in 3:await process_frame
	check(not flow.get("_campaign_tutorial").get("_strip").get_global_rect().intersects(presenter.get("_base_management_bar").get_global_rect()),"campaign help leaves base management buttons unobscured")
	var base_view:Node=presenter.get("_base")
	var terrain_view:Node=base_view.get("_view")
	check(float(terrain_view.get_camera_size())>20,"exploring restores overview instead of close pad preview")
	check(base_view.get("_viewport").render_target_update_mode in [SubViewport.UPDATE_ALWAYS,SubViewport.UPDATE_WHEN_VISIBLE],"base outer compositor cannot freeze after world-label cleanup")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var before:Image=root.get_texture().get_image()
		before.save_png("C:/dev/SternenBuergerchen/output/flugdeck_20261110/native/base_before_pan.png")
		var host:Control=base_view.get("_host")
		var begin:=host.get_global_rect().get_center()
		var initial_motion:=InputEventMouseMotion.new();initial_motion.position=begin;root.push_input(initial_motion,true);await process_frame
		var focus_before:Vector2=terrain_view.get_camera_focus_grid_position()
		for data in [{"button":true,"position":begin},{"move":true,"position":begin+Vector2(140,60)},{"button":false,"position":begin+Vector2(140,60)}]:
			if data.has("move"):
				var motion:=InputEventMouseMotion.new();motion.position=data.position;motion.button_mask=MOUSE_BUTTON_MASK_MIDDLE;root.push_input(motion,true)
			else:
				var click:=InputEventMouseButton.new();click.position=data.position;click.button_index=MOUSE_BUTTON_MIDDLE;click.pressed=data.button;root.push_input(click,true)
		for i in 12:await process_frame
		await RenderingServer.frame_post_draw
		var after:Image=root.get_texture().get_image()
		check(terrain_view.get_camera_focus_grid_position().distance_to(focus_before)>0.1,"actual middle-mouse input changes base camera focus")
		var inner:Image=terrain_view.get("_subviewport").get_texture().get_image()
		inner.save_png("C:/dev/SternenBuergerchen/output/flugdeck_20261110/native/base_inner_after_pan.png")
		var colors:Dictionary={}
		for y in range(0,inner.get_height(),12):
			for x in range(0,inner.get_width(),12):colors[inner.get_pixel(x,y).to_html()]=true
		print("BASE_INNER_DIAGNOSTIC colors=",colors.size()," camera=",terrain_view.get("_camera").global_position," focus=",terrain_view.get_camera_focus_grid_position()," current=",terrain_view.get("_camera").current," scene_visible=",base_view.get("_authored_stage").is_visible_in_tree())
		check(colors.size()>40,"base remains a detailed actual scene after pan")
		var different:=0
		for y in range(200,before.get_height()-80,20):
			for x in range(before.get_width()/2,before.get_width()-40,20):
				if (Vector3(before.get_pixel(x,y).r,before.get_pixel(x,y).g,before.get_pixel(x,y).b)-Vector3(after.get_pixel(x,y).r,after.get_pixel(x,y).g,after.get_pixel(x,y).b)).length()>.02:different+=1
		print("BASE_RENDER_CHANGED ",different)
		check(different>100,"base pan changes actual world pixels, not only projected text")
		after.save_png("C:/dev/SternenBuergerchen/output/flugdeck_20261110/native/base_after_pan.png")
	check(presenter.get("_pad_selector").item_count==1,"unbuilt campaign pad is not selectable")
	flow.queue_free();await process_frame
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"skirmish","new","early")
	flow=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
	screen=flow.get_node("HomebaseScreen");screen.request_operation("navigate",{"mode":"mission"});presenter=screen.get("_operations_presenter")
	for i in 10:await process_frame
	var selector:OptionButton=presenter.get("_pad_selector")
	check(selector.item_count>=3,"early exposes built fleet pads")
	var before:Dictionary=flow.get("_singleplayer_runtime").get_base_personnel_runtime().export_state()
	selector.select(1);selector.item_selected.emit(1)
	for i in 3:await process_frame
	check(String(presenter.get("_selected_pad_id"))==String(selector.get_item_metadata(1)),"pad selection retained")
	check(String(presenter.get("_base").get("_preview_pad_id"))==String(selector.get_item_metadata(1)),"actual camera follows selected pad")
	check(flow.get("_singleplayer_runtime").get_base_personnel_runtime().export_state()==before,"pad selection does not move or board people")
	flow.queue_free();await process_frame
	print("FLUGDECK_LAYOUT checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
