extends "res://scripts/tests/frontier_main_startup_verifier.gd"
## Real normal start, separate test profile; no fixture/state/timer modification.

func _initialize() -> void:
	var data_path := OS.get_user_data_dir()
	if not data_path.contains("SternenBuergerchen_GM01_Frontier_QA"):
		push_error("GM01 normal capture requires its isolated QA user-data directory.")
		quit(2)
		return
	_facts["ui_test_user_data_dir"] = data_path
	_facts["isolated_user_data"] = true
	super._initialize()


func _visual_snapshot(view: Node) -> Dictionary:
	var snapshot := super._visual_snapshot(view)
	var authored := _snapshot(view, "get_render_snapshot")
	for key in ["authored_visual_layout_id", "authored_visual_layout_active", "authored_visual_owned_tile_count", "authored_visual_assets"]:
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
		# A second real camera view shows the composition beyond the selected squad.
		# Fog, runtime actors and elapsed simulation time remain untouched.
		view.call("frame_world_positions", [Vector2(0, 192), Vector2(512, 1152), Vector2(-512, 768)], 8.0, 26.0, 32.0)
		await super._capture("07_outpost_overview", view, 8)
		view.call("frame_world_positions", [Vector2(320, 1312), Vector2(704, 2400)], 8.0, 28.0, 36.0)
		await super._capture("08_eastern_supply", view, 8)
		view.call("frame_world_positions", [Vector2.ZERO, Vector2(512, 2752)], 8.0, 48.0, 56.0)
		await super._capture("09_expanded_map", view, 8)
