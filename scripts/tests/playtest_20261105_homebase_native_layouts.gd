extends "res://scripts/tests/ui_zielbild_normal_capture.gd"
## Real normal menu/Homebase route; responsive UI inspection only.
var _layout_size := Vector2i(1280, 720)
var _physical_size := Vector2i.ZERO

func _argument(key: String, fallback: String = "") -> String:
	if key == "--ui-size":
		return "%dx%d" % [_layout_size.x, _layout_size.y]
	return super._argument(key, fallback)

func _run() -> void:
	_started = Time.get_ticks_msec()
	_deadline = _started + 120000
	_output = _argument("--evidence-output", "res://output/homebase_layouts_%d.json" % Time.get_ticks_usec())
	_capture_root = _output.get_basename() + "_captures/"
	if FileAccess.file_exists(_output) or DirAccess.dir_exists_absolute(_capture_root):
		push_error("Responsive capture refuses to replace existing evidence")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) != OK:
		quit(2)
		return
	_roster_existed = FileAccess.file_exists(ROSTER)
	_roster_before = FileAccess.get_sha256(ROSTER) if _roster_existed else ""
	_physical_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	_check(DisplayServer.get_name() != "headless", "Homebase layouts use a native display")
	var menu = load(MENU).instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	menu.get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton").pressed.emit()
	if not await _wait_until("real normal Homebase", func() -> bool: return current_scene != null and current_scene.scene_file_path == META):
		await _finish()
		return
	await _frames(8)
	var screen: Control = current_scene.get_node("HomebaseScreen")
	_roster_identity_before = _roster_identity_digest()
	var presenter: Control = screen.get("_operations_presenter")
	_check(screen.is_visible_in_tree() and presenter.is_visible_in_tree(), "Normal Singleplayer opens the actual Operations UI")
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	var owner_before := JSON.stringify([snapshot.roster,snapshot.fireteams,snapshot.missions])
	_facts["responsive_native_layouts"] = []
	for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		_layout_size = dimensions
		root.mode = Window.MODE_FULLSCREEN
		root.content_scale_size = dimensions
		await _frames(8)
		await _capture("homebase_%d" % dimensions.x)
		var layout: Dictionary = presenter.call("get_presentation_snapshot")
		_check(not bool(layout.columns.flight.visible) if dimensions.x == 1280 else bool(layout.columns.flight.visible), "%d: appropriate preparation column count" % dimensions.x)
		_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN and DisplayServer.window_get_size() == _physical_size, "%d: actual display remains fullscreen" % dimensions.x)
		_facts.responsive_native_layouts.append({"logical":str(dimensions),"physical":str(DisplayServer.window_get_size()),"mode":DisplayServer.window_get_mode(),"layout":layout})
		if dimensions.x == 1280:
			var nav: Dictionary = presenter.get("_nav")
			(nav.mission as Button).pressed.emit()
			await _frames(4)
			_check(bool(presenter.call("get_presentation_snapshot").columns.flight.visible), "1280: normal navigation exposes Flight and launch controls")
			await _capture("flight_1280")
			(nav.squad as Button).pressed.emit()
			await _frames(4)
	var owner_after: Dictionary = screen.call("get_operations_snapshot")
	_check(JSON.stringify([owner_after.roster,owner_after.fireteams,owner_after.missions]) == owner_before, "Layout and navigation preserve roster, team and mission data")
	await _finish()

func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	root.mode = Window.MODE_FULLSCREEN
	await super._capture(id, view, settle_frames)
