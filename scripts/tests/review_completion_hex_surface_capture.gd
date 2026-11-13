extends "res://scripts/tests/review_completion_maps_capture.gd"
## Run unchanged against private before/after source copies, same GL camera.
func run()->void:
	output=OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name()=="headless":quit(2);return
	check(OS.get_user_data_dir().replace("\\","/")==OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\","/"),"private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	for map_id:String in ["station_outpost_64x64","Ground_Mission02_128x128","fortified_outpost"]:
		var terrain=MAP.load_from_file("res://maps/"+map_id+".json")
		var focus:Vector2=terrain.get_marker_position("objective_point")
		var camera_size:=26.0 if map_id=="station_outpost_64x64" else 20.0
		if map_id=="fortified_outpost":
			for tile in terrain.get_tiles():
				if String(tile.object_type_id)=="glut_bridge_deck":focus=tile.world_position;break
		var view=VIEW.new();root.add_child(view)
		view.configure_from_map(terrain,focus,camera_size);view.set_authoring_markers_visible(false)
		await settle_map(view)
		await capture(map_id+"_hex_surface",{"source":"res://maps/"+map_id+".json","camera_size":camera_size,"focus":focus,"render":view.get_render_snapshot()})
		if map_id=="fortified_outpost":
			var pad:Dictionary=terrain.get_place_presentation().pads[0]
			var center:=Vector2(float(pad.center[0]),float(pad.center[1]))
			var axial:Vector2=preload("res://scripts/terrain/hex_grid.gd").plane_to_axial(center/float(view.call("_get_3d_cell_size")))
			view.focus_world_position(view.call("_grid_float_to_world",axial));view.set("_camera_size",9.0);view.call("_update_camera_transform")
			await settle_map(view)
			await capture("actual_painted_pad_hex_surface",{"source":"res://maps/fortified_outpost.json","camera_size":9.0,"pad":pad,"render":view.get_render_snapshot()})
			for tile in terrain.get_tiles():
				if tile.explicit_hex_ramps and tile.ramp_direction>=0:
					view.focus_world_position(tile.world_position);view.set("_camera_size",12.0);view.call("_update_camera_transform");break
			await settle_map(view)
			await capture("actual_hill_ramp_hex_surface",{"source":"res://maps/fortified_outpost.json","camera_size":12.0,"render":view.get_render_snapshot()})
		view.queue_free();await frames()
	var sample=MAP.create_empty("hex_surface_gallery",Vector2i(12,10),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	for x in range(2,8):
		for y in range(1,5):
			var tile=sample.get_tile_at_grid(Vector2i(x,y));tile.type_id="station_set_floor_panel";tile.height_level=1
			if y==1:tile.object_type_id="station_set_wall";tile.walkable=false
	for direction in range(6):
		var cell:=Vector2i(2+direction,7)
		var tile=sample.get_tile_at_grid(cell);tile.explicit_hex_ramps=true;tile.ramp_direction=direction;tile.height_level=1
	var view=VIEW.new();root.add_child(view)
	view.configure_from_map(sample,sample.get_tile_at_grid(Vector2i(5,5)).world_position,13.0);view.set_authoring_markers_visible(false)
	var actor=load("res://scripts/npc/test_unit.gd").new();actor.unit_id="hex_surface_fixture";actor.team_id="team_alpha";actor.armor_id="suit"
	# Native pose fixture using the actual Actor->View proxy pipeline; the
	# companion verifier separately publishes real Ground motion through Root.
	var actor_cell:=Vector2i(5,3)
	actor.position=sample.get_tile_at_grid(actor_cell).world_position
	actor.set_meta("hex_ground_stand_height_logical",1.0);actor.set_meta("hex_ground_moving",false);actor.set_meta("hex_ground_facing_angle",0.0)
	actor.set_meta("hex_ground_surface_segment",{"from_axial":Vector2(actor_cell),"to_axial":Vector2(actor_cell),"progress":0.0})
	root.add_child(actor);actor.set_process(false);actor.set_physics_process(false)
	view.set_unit_nodes([actor]);view.set_selected_grid_positions([actor_cell])
	await settle_map(view)
	var proxy:Node3D=view.get("_unit_proxies_by_id").get("hex_surface_fixture")
	check(proxy!=null,"actual actor creates its native proxy")
	await capture("kenney_and_six_ramps_hex_surface",{"source":"isolated native Kenney floor/wall plus six canonical ramp directions and actual Actor proxy","camera_size":13.0,"actor_logical_height":actor.get_meta("hex_ground_stand_height_logical"),"proxy_position":proxy.position if proxy!=null else Vector3.ZERO,"render":view.get_render_snapshot()})
	view.set_selected_grid_positions([])
	view.focus_world_position(actor.position);view.set("_camera_size",4.0);view.call("_update_camera_transform")
	await settle_map(view)
	await capture("actual_actor_floor_closeup",{"source":"same actual Actor/proxy, unchanged model scale, no tile selection","camera_size":4.0,"proxy_position":proxy.position if proxy!=null else Vector3.ZERO,"surface_y":view.call("_get_world_surface_y",actor.position),"render":view.get_render_snapshot()})
	actor.queue_free();view.queue_free();await frames()
	var file:=FileAccess.open(output.path_join("capture_manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("REVIEW_HEX_SURFACE_CAPTURE passed=%d failed=%d"%[passed,failed]);quit(1 if failed else 0)
