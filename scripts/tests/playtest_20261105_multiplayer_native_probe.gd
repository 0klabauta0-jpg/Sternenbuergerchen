extends Node
## Test-only overlay autoload: display evidence and orderly owned-test cleanup.
## Never installed in the product project. No actor/order/timer/authority writes.
var _output := ""
var _resolution := Vector2i.ZERO
var _elapsed := 0.0
var _closing := false
var _captured := false

func _ready() -> void:
	if not preload("res://scripts/tests/review2_isolated_user_guard.gd").require_isolated_user_data():
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-mp-probe="):
			_output = argument.trim_prefix("--qa-mp-probe=")
		elif argument.begins_with("--qa-mp-resolution="):
			var parts := argument.trim_prefix("--qa-mp-resolution=").split("x")
			if parts.size() == 2:
				_resolution = Vector2i(int(parts[0]), int(parts[1]))
	if _output.is_empty() or _resolution == Vector2i.ZERO:
		push_error("Native multiplayer probe requires explicit output and display size")
		get_tree().quit(2)
		return
	# Select by actual geometry, independent of Windows/Godot monitor numbering.
	var selected := -1
	for screen in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_size(screen) == _resolution:
			selected = screen
			break
	if selected < 0:
		push_error("Requested physical fullscreen display does not exist")
		get_tree().quit(2)
		return
	DisplayServer.window_set_current_screen(selected)
	get_tree().root.content_scale_size = _resolution
	get_tree().root.mode = Window.MODE_FULLSCREEN
	call_deferred("_record_display")

func _process(delta: float) -> void:
	if _closing or _output.is_empty():
		return
	if FileAccess.file_exists("user://qa_mp_quit_request"):
		_closing = true
		_finish_owned_test()
		return
	_elapsed += delta
	if _elapsed >= 0.25:
		_elapsed = 0.0
		_record_display()
	if not _captured and FileAccess.file_exists("user://qa_mp_capture_request"):
		_captured = true
		await RenderingServer.frame_post_draw
		var path := _output.get_basename() + "_mission.png"
		var result := get_tree().root.get_texture().get_image().save_png(path)
		if result != OK:
			push_error("Native multiplayer screenshot failed")
		_record_display()

func _record_display() -> void:
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"schema":"sternenbuergerchen.multiplayer_native_display.v1",
		"mode":DisplayServer.window_get_mode(),
		"window_size":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],
		"screen_size":[DisplayServer.screen_get_size().x,DisplayServer.screen_get_size().y],
		"screen":DisplayServer.window_get_current_screen(),
		"logical_size":str(get_tree().root.get_visible_rect().size),
		"renderer":RenderingServer.get_current_rendering_method(),
		"time_scale":Engine.time_scale,"captured":_captured,
		"scene":get_tree().current_scene.scene_file_path if get_tree().current_scene != null else "",
		"gameplay_writes":false
	}))

func _finish_owned_test() -> void:
	var scene := get_tree().current_scene
	# The same normal Disconnect action releases the mission/network first.
	if is_instance_valid(scene) and scene.has_method("disconnect_game"):
		scene.call("disconnect_game")
	for frame in range(6):
		await get_tree().process_frame
	if is_instance_valid(scene):
		scene.queue_free()
		get_tree().current_scene = null
	for frame in range(6):
		await get_tree().process_frame
	await get_tree().create_timer(0.5, true, false, true).timeout
	get_tree().quit()
