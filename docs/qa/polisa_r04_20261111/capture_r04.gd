extends SceneTree
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const OUT="res://output/native_glut_maps/polisa_r04_20261111/"
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	root.size=Vector2i(1920,1080)
	await process_frame
	var map=MAP.load_from_file(OUT+"polisa_station_candidate.json")
	var view=VIEW.new()
	root.add_child(view)
	await process_frame
	view.set_frontier_art_enabled(true)
	view.configure_from_map(map)
	view.set_hex_grid_visible(true)
	var failed:=false
	for spec: Dictionary in [{"name":"station_near","size":66.0,"yaw":0.0,"pitch":58.0,"focus":Vector2(60*64,-60*32)},{"name":"whole_map","size":226.0,"yaw":0.0,"pitch":68.0,"focus":Vector2(-20.8*64,20.8*32)}]:
		view.set("_camera_size",float(spec.size))
		view.set("_camera_yaw_degrees",float(spec.yaw))
		view.set("_camera_pitch_degrees",float(spec.pitch))
		view.focus_world_position(spec.focus)
		view.call("_request_viewport_redraw",true,60000)
		for i in range(20):await process_frame
		await RenderingServer.frame_post_draw
		var picture:=root.get_texture().get_image()
		var path:=OUT+"polisa_r04_"+String(spec.name)+".png"
		var error:=picture.save_png(path)
		failed=failed or error!=OK
		print("POLISA_R04_CAPTURE ",path," error=",error)
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
	failed=failed or counts.station.is_empty() or int(counts.station.get("static_triangles",0))>=30000 or int(counts.active_collisions)!=0 or int(counts.dressing_visible_mesh_nodes)!=int(counts.station.get("static_mesh_nodes",0))+int(counts.showcase_mesh_nodes)
	var file:=FileAccess.open(OUT+"native_metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(counts,"  "));file.close()
	print("POLISA_R04_METRICS ",JSON.stringify(counts))
	print("PASS: Polisa R04 art capture" if not failed else "FAIL: Polisa R04 art capture")
	view.queue_free()
	await process_frame
	quit(1 if failed else 0)
