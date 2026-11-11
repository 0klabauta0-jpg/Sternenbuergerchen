extends SceneTree
var checks:=0
var failures:=0
func _init()->void:call_deferred("_run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: ",label)
	else:print("PASS: ",label)
func _run()->void:
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(1280, 720)
	var mission:Node=load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	var setup:Node=mission.get_node("MissionSetup")
	setup.set("defer_friendly_runtime_activation",false)
	setup.set("selected_team_unit_ids",PackedStringArray(["unit_alpha","unit_bravo","unit_charlie","unit_delta"]))
	setup.set("selected_team_fireteam_ids",PackedStringArray(["ft1","ft1","ft2","ft3"]))
	root.add_child(mission);await process_frame;await physics_frame
	var controller:Node=mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams",PackedStringArray(["ft1"]),false)
	controller.call("_update_ui")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.content_scale_size = resolution
		root.size=resolution
		for i in 12:await process_frame
		controller.call("_update_ui")
		var panel:Control=controller.get_node("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel")
		var row:HBoxContainer=panel.get_node("A5TeamPortraits")
		check(row.get_child_count()==2,"focused card projects both actual FT1 portraits")
		var before:Array=row.get_children().map(func(node:Node):return node.get_instance_id())
		for portrait:TextureRect in row.get_children():
			check(is_equal_approx(portrait.custom_minimum_size.x,portrait.custom_minimum_size.y),"focused portraits are square")
			check(portrait.custom_minimum_size.x<=64,"portrait edge reduced by one third")
			check(portrait.texture!=null,"actual identity texture retained")
		var mini:Node=controller.get_node("../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
		check(not mini.get_node(("FireteamMiniCard_"+"ft1".capitalize())).is_visible_in_tree(),"selected FT1 is not duplicated in separate mini card")
		check(mini.get_node(("FireteamMiniCard_"+"ft2".capitalize())).is_visible_in_tree() and mini.get_node(("FireteamMiniCard_"+"ft3".capitalize())).is_visible_in_tree(),"other fireteams remain available")
		var board:Button=panel.get_node("A5TeamBoard")
		check(board.is_visible_in_tree() and board.text=="Aufsitzen","troop owns obvious boarding action")
		check(board.disabled and not panel.get_node("A5BoardStatus").text.is_empty(),"absent parked ship gives disabled action with reason")
		check(panel.get_global_rect().grow(2).encloses(board.get_global_rect()),"boarding remains inside combined card")
		_check_selected_card_geometry(panel, resolution)
		for i in 12:controller.call("_update_ui")
		check(row.get_children().map(func(node:Node):return node.get_instance_id())==before,"unchanged HUD retains portrait controls")
		if DisplayServer.get_name()!="headless":
			for i in 8:await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("C:/dev/SternenBuergerchen/output/compact_team_20261110")
			root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen/output/compact_team_20261110/hud_%d.png"%resolution.x)
	controller.call("_set_selected_fireteams",PackedStringArray(["ft2"]),false);controller.call("_update_ui")
	for i in 12:await process_frame
	controller.call("_update_ui")
	var panel:Node=controller.get_node("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel")
	var double_click:=InputEventMouseButton.new()
	double_click.button_index=MOUSE_BUTTON_LEFT;double_click.pressed=true;double_click.double_click=true
	panel.get_node("A5TeamPortraits").get_child(0).gui_input.emit(double_click)
	check(bool(controller.get("_character_overlay_open")) and String(controller.get("_character_overlay_unit_id"))=="unit_charlie","projected portrait double-click opens actual selected member details")
	controller.call("_close_character_overlay")
	var mini:Node=controller.get_node("../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	check(mini.get_node(("FireteamMiniCard_"+"ft1".capitalize())).is_visible_in_tree() and not mini.get_node(("FireteamMiniCard_"+"ft2".capitalize())).is_visible_in_tree(),"selection switch merges new focus without losing previous team")
	mission.queue_free();await process_frame
	print("COMPACT_TEAM checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)


func _check_selected_card_geometry(panel: Control, resolution: Vector2i) -> void:
	var all_button: Button = panel.get_node("FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton")
	var stance: Control = panel.get_node("FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel")
	var controls: Array[Control] = [
		panel.get_node("A5TeamIdentity"), panel.get_node("A5DetailsButton"), all_button,
		panel.get_node("A5TeamPortraits"), panel.get_node("A5TeamSummary"), stance,
		panel.get_node("A5FireRuleHeading"), panel.get_node("A5FireRuleSelector"),
		panel.get_node("A5TeamBoard"), panel.get_node("A5BoardStatus"),
	]
	var overlaps: PackedStringArray = []
	var outside_card: PackedStringArray = []
	for first in range(controls.size()):
		var control := controls[first]
		if not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if not panel.get_global_rect().encloses(rect):
			outside_card.append("%s %s" % [control.name, rect])
		for second in range(first + 1, controls.size()):
			var other := controls[second]
			if other.is_visible_in_tree() and rect.intersects(other.get_global_rect()):
				overlaps.append("%s %s / %s %s" % [control.name, rect, other.name, other.get_global_rect()])
	var viewport_size := root.get_visible_rect().size
	check(viewport_size == Vector2(resolution), "requested logical viewport %s, actual %s" % [resolution, viewport_size])
	check(overlaps.is_empty(), "%s: selected team controls have separate hit rectangles: %s" % [viewport_size, overlaps])
	check(outside_card.is_empty(), "%s: selected team controls fit their card: %s" % [viewport_size, outside_card])
