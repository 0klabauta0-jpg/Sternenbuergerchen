extends SceneTree
const EDITOR = preload("res://scenes/editor/map_editor.tscn")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var passed:=0
var failed:=0
var editor: Node
func _init() -> void: call_deferred("_run")
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1
	print("PASS: " if value else "FAIL: ",label)
func props() -> Array: return editor.get("_terrain_map_data").get_place_presentation().get("props",[])
func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-editor-buildings"): return
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen-worktrees/.codex-evidence/editor-buildings-20261110/"+name+".png")
func _run() -> void:
	root.size=Vector2i(1920,1080)
	var path: String="user://building_controls_%d/map.json"%OS.get_process_id()
	var map=MAP.create_empty("Building controls",Vector2i(32,24),Vector2.ZERO,64,32,3,"hex_axial_v1")
	for tile in map.get_tiles(): tile.edge_type="none"
	map.set_terrain_visual_theme_id("frontier_illustrated_v1"); map.save_to_file(path)
	editor=EDITOR.instantiate(); editor.set("map_file_path",path); root.add_child(editor); await process_frame
	map=editor.get("_terrain_map_data")
	check(editor.has_node("UI/PropertyPanel/Margin/VBox/BuildingActions"),"visible building controls installed")
	editor.call("set_palette_type_for_authoring","frontier_hall_exterior")
	editor.call("set_object_placement_scale",1.0)
	editor.set("_placement_object_rotation_degrees",0.0)
	editor.call("_apply_brush_at_world_position",map.get_tile_at_grid(Vector2i(10,10)).world_position)
	check(props().size()==1,"normal palette brush places whole building")
	if props().is_empty(): editor.queue_free(); await process_frame; quit(1); return
	var id: String=props()[0].building_id
	check(editor.call("get_undo_debug_snapshot").undo_depth==1,"placement is one undo step")
	check(editor.get("_selected_grids").size()>1,"selection highlights complete footprint")
	editor.call("_set_selected_grid_position",Vector2i(2,2))
	editor.call("_select_grid_with_selection_tool",Vector2i(10,10),false)
	check(editor.get("_selected_grids").size()>1 and not editor.get_node("UI/PropertyPanel/Margin/VBox/BuildingActions/Buttons/move").disabled,"Select tool enables whole-building controls")
	editor.call("_select_grid_with_selection_tool",Vector2i(2,2),false)
	await process_frame
	check(editor.get_node("UI/PropertyPanel/Margin/VBox/BuildingActions/Buttons/move").disabled,"selecting ground disables building actions")
	editor.call("_select_grid_with_selection_tool",Vector2i(10,10),false)
	await process_frame
	var selected_root: Node=editor.get_node("Primary3DView").get("_selection_root")
	check(selected_root.get_child_count()>0 and not selected_root.get_child(0).material_override.no_depth_test,"footprint selection cannot paint over the building model")
	var protected=map.get_tile_at_grid(Vector2i(10,10))
	check(not editor.call("_apply_tile_patch",protected,{"walkable":true}),"generic inspector cannot break footprint")
	check(not editor.call("_apply_network_piece_to_tile",protected,{"type_id":"station_wall"}),"network tool cannot break footprint")
	await capture("01_placed")
	editor.get_node("UI/PropertyPanel/Margin/VBox/BuildingActions/Buttons/move").emit_signal("pressed")
	check(editor.get("_building_move_id")==id,"visible move button starts target-pick")
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
	event.position=editor.get_node("Primary3DView").call("world_to_screen_position",map.get_tile_at_grid(Vector2i(18,12)).world_position)
	editor.call("_unhandled_input",event)
	check(editor.get("_building_move_id").is_empty(),"target click finishes move mode")
	check(map.get_tile_at_grid(Vector2i(10,10)).walkable and not map.get_tile_at_grid(Vector2i(18,12)).walkable,"move releases old cells and reserves target")
	check(editor.call("get_undo_debug_snapshot").undo_depth==2,"move creates exactly one undo step")
	editor.get_node("UI/PropertyPanel/Margin/VBox/BuildingActions/Buttons/right").emit_signal("pressed")
	check(is_equal_approx(float(props()[0].rotation_degrees),90.0),"visible rotation button rotates building data")
	check(is_equal_approx(float(editor.call("_get_tile_object_rotation_degrees",map.get_tile_at_grid(Vector2i(18,12)))),90.0),"inspector reads building yaw")
	var depth: int=editor.call("get_undo_debug_snapshot").undo_depth
	var rejection: Dictionary=editor.call("request_building_operation","place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(18,12)})
	check(not rejection.ok and editor.call("get_undo_debug_snapshot").undo_depth==depth,"rejected placement leaves undo untouched")
	var tile=map.get_tile_at_grid(Vector2i(4,4))
	editor.call("_apply_tile_patch",tile,{"cover_value":73})
	editor.call("_undo_last_change")
	check(tile.cover_value==0 and is_equal_approx(float(props()[0].rotation_degrees),90.0),"ordinary terrain undo interleaves with building history")
	editor.call("_undo_last_change")
	check(is_equal_approx(float(props()[0].rotation_degrees),0.0),"undo restores pre-rotation building and footprint")
	editor.call("_undo_last_change")
	check(not map.get_tile_at_grid(Vector2i(10,10)).walkable and map.get_tile_at_grid(Vector2i(18,12)).walkable,"undo restores pre-move building and terrain")
	editor.call("_undo_last_change")
	check(props().is_empty() and map.get_tile_at_grid(Vector2i(10,10)).walkable,"undo placement removes model and restores substrate")
	editor.call("_apply_brush_at_world_position",map.get_tile_at_grid(Vector2i(10,10)).world_position)
	var saved: String="user://building_controls_%d/saved.json"%OS.get_process_id()
	editor.call("_on_save_as_file_selected",saved); editor.call("_load_map",saved)
	check(props().size()==1 and props()[0].building_id==id,"real SaveAs and reload preserve stable building identity")
	editor.call("_set_selected_grid_position",Vector2i(10,10))
	editor.get_node("UI/PropertyPanel/Margin/VBox/BuildingActions/Buttons/move").emit_signal("pressed")
	var escape:=InputEventKey.new(); escape.pressed=true; escape.physical_keycode=KEY_ESCAPE
	editor.call("_unhandled_input",escape)
	check(editor.get("_building_move_id").is_empty() and props().size()==1,"Escape cancels move without mutation")
	editor.call("_begin_building_move")
	editor.call("_on_tile_type_selected",0)
	check(editor.get("_building_move_id").is_empty(),"palette selection cancels pending move")
	var all_tools_cancel:=true
	for tool in ["terrain_brush","eraser","height","marker","patrol","select"]:
		editor.call("_begin_building_move")
		editor.call("set_authoring_tool",tool)
		all_tools_cancel=all_tools_cancel and editor.get("_building_move_id").is_empty() and not String(editor.get("_building_feedback_text")).contains("Ziel auf der Karte")
	check(all_tools_cancel,"switching authoring tool cancels pending move")
	editor.call("_set_selected_grid_position",Vector2i(10,10)); await capture("02_reloaded")
	editor.call("_begin_building_move")
	editor.get_node("UI/PropertyPanel/Margin/VBox/BuildingActions/Buttons/remove").emit_signal("pressed")
	check(editor.get("_building_move_id").is_empty(),"removing building cancels its pending move")
	check(props().is_empty() and editor.get("_terrain_map_data").get_tile_at_grid(Vector2i(10,10)).walkable,"visible remove restores persisted substrate")
	check(editor.call("get_undo_debug_snapshot").undo_depth==1,"loaded building removal is a new undo transaction")
	editor.call("_undo_last_change")
	check(props().size()==1,"undo restores removed saved building")
	await process_frame
	var snapshot: Dictionary=editor.get_node("Primary3DView").call("get_render_snapshot")
	check(int(snapshot.get("missing_map_asset_mapping_count",-1))==0,"current renderer has no missing asset boxes")
	if OS.get_cmdline_user_args().has("--capture-editor-buildings"):
		editor.call("_load_map","res://maps/station_outpost_64x64.json")
		map=editor.get("_terrain_map_data")
		var first: Dictionary=props()[0]
		var grid:=Vector2i(int(first.center[0]),int(first.center[1]))
		editor.call("_select_grid_with_selection_tool",grid,false)
		var view: Node=editor.get_node("Primary3DView")
		view.set("_camera_size",18.0)
		view.call("focus_world_position",map.get_tile_at_grid(grid).world_position)
		editor.call("_building_feedback","Bestehendes Habitat ausgewählt. Verschieben, drehen oder entfernen; Strg+Z macht die Aktion rückgängig.")
		await capture("03_existing_station")
	editor.queue_free(); await process_frame
	print("EDITOR_BUILDING_CONTROLS passed=%d failed=%d"%[passed,failed]); quit(1 if failed else 0)
