extends "res://scripts/tests/frontier_main_startup_verifier.gd"

# The existing real menu -> Homebase -> GM01 -> timed transport -> LZ -> GO
# smoke owns every interaction. This subclass only selects capture resolution.
# It never stages actors, changes a timer or writes private simulation state.
func _initialize() -> void:
	var data_path := OS.get_user_data_dir()
	if not data_path.contains("SternenBuergerchen_UI_R4_Normalstart"):
		push_error("R4 normal-start captures require their isolated user-data directory.")
		quit(2)
		return
	_facts["ui_test_user_data_dir"] = data_path
	_facts["isolated_user_data"] = true
	super._initialize()

func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	var dimensions := _argument("--ui-size", "1920x1080").split("x")
	var requested := Vector2i(int(dimensions[0]), int(dimensions[1]))
	root.size = requested
	root.content_scale_size = requested
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await super._capture(id, view, settle_frames)
