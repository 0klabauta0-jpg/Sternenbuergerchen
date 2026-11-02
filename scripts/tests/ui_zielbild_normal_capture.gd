extends "res://scripts/tests/frontier_main_startup_verifier.gd"
## Reuses the real normal-start route; own user://, no fixture or timer changes.
const ZIELBILD_QA_NAMESPACE := "SternenBuergerchen_UI_Zielbild_Normal_QA"

func _initialize() -> void:
	var data_path := OS.get_user_data_dir()
	if data_path.replace("\\", "/").trim_suffix("/").get_file() != ZIELBILD_QA_NAMESPACE:
		push_error("Zielbild normal capture requires its exact isolated QA user-data directory.")
		quit(2)
		return
	_facts["ui_test_user_data_dir"] = data_path
	_facts["isolated_user_data"] = true
	super._initialize()


func _frames(count: int) -> void:
	await super._frames(count)
	if _finished:
		# Only after the parent has freed current_scene: let the audio thread
		# release its Ogg movement playback before process exit. No extra mission
		# time, actor write, sound suppression or relaxed warning predicate.
		await create_timer(0.35, true, false, true).timeout


func _visual_snapshot(view: Node) -> Dictionary:
	var snapshot := super._visual_snapshot(view)
	var authored := _snapshot(view, "get_render_snapshot")
	for key in ["authored_visual_layout_id", "authored_visual_layout_active", "authored_visual_owned_tile_count", "authored_visual_assets", "hex_grid_visible", "hex_grid_edge_style", "hex_grid_width_world", "tile_grid_line_count", "fog_of_war_mode", "fow_overlay_tile_count", "fow_known_dim_tile_count", "fow_unknown_tile_count"]:
		snapshot[key] = authored.get(key)
	return snapshot


func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	var dimensions := _argument("--ui-size", "1920x1080").split("x")
	var requested := Vector2i(int(dimensions[0]), int(dimensions[1]))
	root.size = requested
	root.content_scale_size = requested
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await super._capture(id, view, settle_frames)
	if id == "06_go_movement" and view != null:
		# Same read-only camera views as GM01 QA, so old and new images compare.
		view.call("frame_world_positions", [Vector2(0, 192), Vector2(512, 1152), Vector2(-512, 768)], 8.0, 26.0, 32.0)
		await super._capture("07_outpost_overview", view, 8)
		view.call("frame_world_positions", [Vector2(320, 1312), Vector2(704, 2400)], 8.0, 28.0, 36.0)
		await super._capture("08_eastern_supply", view, 8)
		view.call("frame_world_positions", [Vector2.ZERO, Vector2(512, 2752)], 8.0, 48.0, 56.0)
		await super._capture("09_expanded_map", view, 8)
