extends SceneTree
## Offline authoring only: render the native outpost as a static menu background.
## The menu loads the PNG, never this synthetic scene or its simulation.
const PREVIEW: PackedScene = preload("res://scenes/tests/frontier_art_preview.tscn")
const IMAGE_PATH: String = "res://Assets/curated/main_menu/frontier_outpost_main_20261101.png"
const REPORT_PATH: String = "res://output/grafik_20261101/main_adoption/menu_background_capture.json"

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var preview: Node = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	for child: Node in preview.get_children():
		if child is CanvasLayer and child != preview.get("_view"):
			(child as CanvasLayer).hide()
	preview.call("_set_buildings_closed", true)
	preview.call("_camera_view", "outpost")
	var view: Node = preview.get("_view")
	var camera: Camera3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	# Keep the existing menu's left text rail clear without moving any world asset.
	camera.h_offset = -3.0
	view.call("_request_viewport_redraw", true, 60000)
	for frame: int in range(32):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(IMAGE_PATH.get_base_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_PATH.get_base_dir()))
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(IMAGE_PATH)
	var sources: Dictionary = {}
	for path: String in ["res://scripts/tools/capture_frontier_main_background.gd", "res://scripts/tests/frontier_art_preview.gd", "res://scripts/terrain/terrain_map_3d_view.gd", "res://scripts/terrain/frontier_art_profile.gd", "res://scripts/terrain/frontier_access_anchors.gd", "res://scripts/terrain/frontier_art_dressing.gd", "res://scripts/terrain/frontier_closed_buildings.gd", "res://scripts/terrain/frontier_art_geology.gd", "res://scripts/terrain/frontier_outpost_pad.gd", "res://scripts/terrain/frontier_worklife.gd", "res://shaders/terrain/frontier_ground.gdshader", "res://shaders/terrain/frontier_building_wear.gdshader", "res://shaders/terrain/frontier_contact_paint.gdshader"]:
		sources[path] = FileAccess.get_sha256(path)
	var report: Dictionary = {
		"image": IMAGE_PATH, "sha256": FileAccess.get_sha256(IMAGE_PATH),
		"width": image.get_width(), "height": image.get_height(), "save_error": error,
		"engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(),
		"synthetic_outpost_render": true, "active_mission_screenshot": false,
		"menu_runtime_uses_static_png_only": true, "debug_canvas_hidden": true,
		"camera": {"transform": str(camera.global_transform), "size": camera.size, "h_offset": camera.h_offset},
		"models": preview.get("_model_facts"), "source_sha256": sources,
		"provenance": "Native Godot render of the project Frontier scene. Kenney-derived structures and characters plus project/Astra ship geometry; no third-party license claim for the composite image."
	}
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write background capture evidence")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("FRONTIER_MAIN_BACKGROUND ", JSON.stringify({"error": error, "width": image.get_width(), "height": image.get_height(), "sha256": report.sha256}))
	preview.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
