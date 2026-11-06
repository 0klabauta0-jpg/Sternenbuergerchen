extends "res://scripts/tests/reference_polish_r3_20261106_homebase_verifier.gd"
## Native fullscreen presentation fixture. Actual normal owner route is separate.

func _initialize() -> void:
	root.mode = Window.MODE_FULLSCREEN
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	super._initialize()

func _resize(owner: SnapshotOwner, presenter: Control, dimensions: Vector2i, mode: String) -> void:
	await super._resize(owner, presenter, dimensions, mode)
	_check(DisplayServer.get_name() != "headless", "Fixture uses native GPU")
	_check(root.mode == Window.MODE_FULLSCREEN and DisplayServer.window_get_size() == DisplayServer.screen_get_size(), "Fixture covers actual display in fullscreen")
	await RenderingServer.frame_post_draw
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-output="):
			var path := argument.trim_prefix("--evidence-output=").get_basename() + "_%dx%d_%s.png" % [dimensions.x, dimensions.y, mode]
			# 1920 squad is revisited after narrow-state assertions.
			if FileAccess.file_exists(path):
				path = path.get_basename() + "_return.png"
			_check(not FileAccess.file_exists(path), "Fullscreen fixture target is new")
			_check(root.get_texture().get_image().save_png(path) == OK, "Fullscreen fixture PNG saved")
