extends SceneTree
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const OUT="res://output/native_glut_maps/polisa_lookdev_candidate/"
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var map=MAP.load_from_file(OUT+"polisa_station_candidate.json")
	var view=VIEW.new()
	root.add_child(view)
	await process_frame
	view.set_frontier_art_enabled(true)
	view.configure_from_map(map)
	view.set_hex_grid_visible(true)
	var failed:=false
	for spec: Array in [[54.0,"overview"],[26.0,"hall"]]:
		view.set("_camera_size",float(spec[0]))
		view.set("_camera_yaw_degrees",24.0)
		view.set("_camera_pitch_degrees",50.0)
		view.focus_map_center()
		if String(spec[1])=="hall":
			view.focus_world_position(Vector2.ZERO)
		view.call("_request_viewport_redraw",true,60000)
		for i in range(20):await process_frame
		await RenderingServer.frame_post_draw
		var picture:=root.get_texture().get_image()
		var path:=OUT+"polisa_"+String(spec[1])+".png"
		var error:=picture.save_png(path)
		failed=failed or error!=OK
		print("POLISA_LOOKDEV_CAPTURE ",path," error=",error)
	var candidates:Array[Node]=[view]
	var counts:Dictionary={"mesh_nodes":0,"triangles":0,"collision_nodes":0,"metrics":{}}
	while not candidates.is_empty():
		var node:Node=candidates.pop_back()
		if node.has_meta("polisa_visual_metrics"):
			counts["metrics"]=node.get_meta("polisa_visual_metrics")
			for part:Node in node.get_children():
				if part is MeshInstance3D:
					counts["mesh_nodes"]+=1
					counts["triangles"]+=(part.mesh.get_faces().size()/3)
				if part is CollisionObject3D:counts["collision_nodes"]+=1
		for child:Node in node.get_children():candidates.append(child)
	failed=failed or int(counts["mesh_nodes"])==0 or int(counts["mesh_nodes"])>=80 or int(counts["triangles"])>=12000 or int(counts["collision_nodes"])!=0
	var file:=FileAccess.open(OUT+"native_metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(counts,"  "))
	file.close()
	print("POLISA_LOOKDEV_METRICS ",JSON.stringify(counts))
	print("PASS: polisa lookdev" if not failed else "FAIL: polisa lookdev")
	view.queue_free()
	await process_frame
	quit(1 if failed else 0)
