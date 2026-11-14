extends SceneTree
## Grafikpass R1: comparable map captures for before/after sheets.
## Needs a real or virtual display (not --headless). Environment:
##   CAP_DIR   absolute output directory
##   CAP_SHOTS "name|map_id|focus_x|focus_y|camera_size;..." ; focus_x "obj"
##             frames the map's objective_point marker instead.
## Example shot list: docs/qa/grafikpass_r1_20261114/README.md
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var out := OS.get_environment("CAP_DIR")
	# shots: name|map|fx|fy|size ; separated by ';'
	var last_map := ""
	var v = null
	for shot in OS.get_environment("CAP_SHOTS").split(";", false):
		var f := shot.split("|")
		if f[1] != last_map:
			if v != null:
				v.queue_free()
				for i in 4: await process_frame
			var terrain = MAP.load_from_file("res://maps/" + f[1] + ".json")
			v = VIEW.new()
			root.add_child(v)
			var focus := Vector2(float(f[2]), float(f[3]))
			if f[2] == "obj": focus = terrain.get_marker_position("objective_point")
			v.configure_from_map(terrain, focus, float(f[4]))
			v.set_authoring_markers_visible(false)
			last_map = f[1]
		else:
			v.set("_camera_size", float(f[4]))
			v.call("focus_world_position", Vector2(float(f[2]), float(f[3])) if f[2] != "obj" else v.get("_terrain_map_data").get_marker_position("objective_point"))
			v.call("_update_camera_transform")
		for i in 16: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + "/" + f[0] + ".png")
		print("CAPTURED ", f[0])
	quit(0)
