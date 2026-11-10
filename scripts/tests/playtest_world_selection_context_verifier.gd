extends SceneTree
var checks:=0
var failures:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
	else: print("PASS: ",label)
func _run() -> void:
	root.size=Vector2i(1280,720)
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow)
	await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	screen.request_operation("navigate",{"mode":"mission"})
	for i in 16: await process_frame
	var initial_base: Node=screen.get("_operations_presenter").get("_base")
	check(initial_base.is_visible_in_tree() and initial_base.get("_view")!=null,"direct initial launch menu initializes actual pad preview")
	screen.request_operation("navigate",{"mode":"base"})
	for i in 12: await process_frame
	var presenter: Node=screen.get("_operations_presenter")
	var base: Node=presenter.get("_base")
	var runtime: Node=flow.get("_singleplayer_runtime")
	var people: Node=runtime.call("get_base_personnel_runtime")
	base.clear_world_selection(); flow.call("_refresh_singleplayer_services")
	check(not flow.get("_singleplayer_services").visible,"base does not permanently show ship service overlay")
	var craft: Dictionary=Array(flow.get("_homebase_aircraft_definitions"))[0]
	var craft_id:=String(craft.craft_id)
	var before: Dictionary=people.export_state()
	check(base.select_world_craft(craft_id),"left selection can identify actual visible ship")
	check(flow.get("_singleplayer_services").visible,"selected ship opens actual right service/details panel")
	check(people.export_state()==before,"selection never orders someone to board")
	base.clear_world_selection()
	check(not flow.get("_singleplayer_services").visible,"empty world click/deselect hides ship panel")
	var id:=String(Array(flow.get("_all_team_units"))[0].unit_id)
	base.call("_select_person",id)
	var view: Node=base.get("_view")
	view.focus_world_position(people.get_actor(id).position)
	var point: Vector2=view.world_to_screen_position(people.get_actor(id).position)
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.double_click=true;event.position=point
	base.call("_on_world_gui_input",event)
	flow.call("_refresh_singleplayer_services")
	check(not flow.get("_campaign_tutorial").visible,"campaign hints do not obscure the person details modal")
	await capture("npc_details")
	check(screen.get("_character_sheet_open"),"world NPC doubleclick opens authoritative person details")
	check(screen.get("_focused_unit_id")==id,"world doubleclick retains actual clicked identity")
	screen.call("_on_close_sheet_button_pressed")
	base.call("_refresh_screen_world_labels")
	var labels: Dictionary=base.get("_screen_world_labels")
	check(not labels.is_empty(),"world produces screen-space labels")
	for label: Label in labels.values(): check(label.get_theme_font_size("font_size")>=16,"world label has readable minimum font")
	view.set("_camera_size",60.0);view.call("_update_camera_transform");base.call("_refresh_screen_world_labels")
	for label: Label in labels.values(): check(label.get_theme_font_size("font_size")>=16,"zooming out preserves label text size")
	await capture("base_zoomed_out")
	screen.request_operation("navigate",{"mode":"mission"})
	for i in 16: await process_frame
	await capture("launch_pad_preview")
	print("PREVIEW_CONTEXT ",presenter.get("_ship_preview_context")," visible=",base.is_visible_in_tree()," size=",base.size)
	check(not base.get("_screen_labels_host").visible,"base world labels do not leak into smaller launch preview")
	check(base.is_visible_in_tree() and base.get("_view")!=null,"launch menu renders actual pad and ship rather than black rectangle")
	check(float(base.get("_view").get_camera_size())<=9.0,"launch preview frames the pad and craft closely enough to inspect ramp")
	check(Dictionary(base.get("_craft_visuals")).has(craft_id),"launch preview contains the real selected craft")
	# Display-only transfer fixture; not a completed trip or campaign event.
	var old_transfers: Array=Array(flow.get("_pending_mission_craft_transfers")).duplicate(true)
	flow.set("_pending_mission_craft_transfers",[{"craft_id":craft_id,"phase":"to_mission","elapsed_seconds":2.0,"duration_seconds":8.0,"payload_source":"homebase_direct"}])
	var snapshot: Dictionary=runtime.get_snapshot()
	var moving_craft: Dictionary={}
	for item: Dictionary in snapshot.crafts:
		if String(item.craft_id)==craft_id: moving_craft=item
	check(not Dictionary(moving_craft.get("pad_visual",{})).is_empty(),"authoritative existing transfer clock provides departure display projection")
	var fuel_before: Dictionary=runtime.get("_supply").export_state()
	base.set_transport_snapshot(snapshot)
	var displayed: Dictionary=base.get("_craft_visuals")[craft_id]
	check((displayed.node as Node3D).position.y>0.1,"real pad model follows lifted display-only departure curve")
	check((displayed.node as Node3D).find_child("ReadOnlyFlightVisual",true,false)!=null,"real Entermesser pad model has mounted exhaust helper")
	base.call("_advance_pad_flight_effects",.1)
	check(runtime.get("_supply").export_state()==fuel_before,"visual maneuver and exhaust do not mutate fuel or gameplay state")
	flow.set("_pending_mission_craft_transfers",old_transfers)
	flow.queue_free();await process_frame
	print("WORLD_SELECTION_CONTEXT checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var path: String="res://docs/qa/playtest_details_cursor_camera_20261110/ui"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	root.get_texture().get_image().save_png(path+"/"+label+".png")
