extends SceneTree
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const OUT="res://docs/qa/polisa_r07_20261111/"
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	root.size=Vector2i(1920,1080)
	await process_frame
	var map=MAP.load_from_file("res://maps/polisa_station.json")
	var view=VIEW.new()
	root.add_child(view)
	await process_frame
	view.set_frontier_art_enabled(true)
	view.configure_from_map(map)
	view.set_hex_grid_visible(true)
	var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/polisa_r07_20261111/layout_compiled.json"))
	var near:Dictionary=layout.standard_camera
	var plane:=Vector2(float(layout.origin_plane[0])+float(near.focus_local[0]),float(layout.origin_plane[1])+float(near.focus_local[1]))
	var near_iso:=Vector2((plane.x-plane.y)*64,(plane.x+plane.y)*32)
	var failed:=false
	for spec: Dictionary in [{"name":"station_near","size":float(near.size),"yaw":float(near.yaw),"pitch":float(near.pitch),"focus":near_iso},{"name":"whole_map","size":320.0,"yaw":0.0,"pitch":68.0,"focus":Vector2(-21*64,21*32)}, {"name":"pad_hex_near","size":16.0,"yaw":0.0,"pitch":65.0,"focus":map.get_marker_position("polisa_pad_04")}]:
		view.set("_camera_size",float(spec.size))
		view.set("_camera_yaw_degrees",float(spec.yaw))
		view.set("_camera_pitch_degrees",float(spec.pitch))
		view.focus_world_position(spec.focus)
		view.call("_request_viewport_redraw",true,60000)
		for i in range(30):await process_frame
		await RenderingServer.frame_post_draw
		var snapshot:Dictionary=view.get_render_snapshot()
		var grid_report:Dictionary={"camera":spec.name,"streaming":snapshot.get("visual_streaming_active"),"total_tiles":snapshot.get("total_tile_count"),"rendered_tiles":snapshot.get("rendered_tile_count"),"line_count":snapshot.get("tile_grid_line_count"),"map_plane_bounds":str(view.get("_map_plane_bounds")),"focus_axial":str(view.get("_focus_grid_position")),"grid_meshes":[]}
		for line:MeshInstance3D in view.find_children("TileGridLines3D","MeshInstance3D",true,false):
			grid_report.grid_meshes.append({"aabb":str(line.get_aabb()),"visible":line.is_visible_in_tree(),"triangles":line.mesh.get_faces().size()/3})
		var diagnostic:=FileAccess.open(OUT+"grid_final_"+String(spec.name)+".json",FileAccess.WRITE)
		diagnostic.store_string(JSON.stringify(grid_report,"  "));diagnostic.close()
		print("POLISA_R07_GRID ",JSON.stringify(grid_report))
		var picture:=root.get_texture().get_image()
		var path:=OUT+"polisa_r07_"+String(spec.name)+".png"
		var error:=picture.save_png(path)
		failed=failed or error!=OK
		print("POLISA_R07_CAPTURE ",path," error=",error)
	var candidates:Array[Node]=[view]
	var counts:Dictionary={"station":{},"showcase_triangles":0,"showcase_mesh_nodes":0,"active_collisions":0,"dressing_visible_mesh_nodes":0,"dressing_visible_triangles":0}
	while not candidates.is_empty():
		var node:Node=candidates.pop_back()
		if String(node.name)=="PlaceReferenceDressing":
			for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
				if mesh.visible and mesh.mesh!=null:
					counts.dressing_visible_mesh_nodes+=1
					counts.dressing_visible_triangles+=mesh.mesh.get_faces().size()/3
		if node.has_meta("polisa_visual_metrics"):
			counts.station=node.get_meta("polisa_visual_metrics")
			for child:Node in node.get_children():
				if String(child.name).begins_with("Showcase_"):
					for mesh:MeshInstance3D in child.find_children("*","MeshInstance3D",true,false):
						if mesh.visible and mesh.mesh!=null:
							counts.showcase_mesh_nodes+=1
							counts.showcase_triangles+=mesh.mesh.get_faces().size()/3
			for child:Node in node.find_children("*","CollisionObject3D",true,false):counts.active_collisions+=1
		for child:Node in node.get_children():candidates.append(child)
	failed=failed or counts.station.is_empty() or int(counts.station.get("static_triangles",0))>=35000 or int(counts.active_collisions)!=0 or int(counts.dressing_visible_mesh_nodes)!=int(counts.station.get("static_mesh_nodes",0))+int(counts.showcase_mesh_nodes)
	var file:=FileAccess.open(OUT+"native_metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(counts,"  "));file.close()
	print("POLISA_R07_METRICS ",JSON.stringify(counts))
	print("PASS: Polisa R07 art capture" if not failed else "FAIL: Polisa R07 art capture")
	view.queue_free()
	await process_frame
	quit(1 if failed else 0)
