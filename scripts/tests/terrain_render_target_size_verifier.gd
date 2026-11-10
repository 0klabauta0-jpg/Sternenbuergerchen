extends SceneTree
## No map or mesh fixture: exercise the real render-size owner and resize signal.
## Five half-resolution SSR/SSAO mip levels require each full-size axis >=32.

const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var _passed := 0
var _failed := 0
var _outer: SubViewport
var _ancestor: Node
var _view: CanvasLayer
var _inner: SubViewport

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_outer = SubViewport.new()
	_outer.name = "PlainOuterViewport"
	_outer.size = Vector2i(16, 16)
	_outer.own_world_3d = true
	_outer.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_outer)
	_ancestor = Node.new()
	_ancestor.name = "ViewProcessAncestor"
	_outer.add_child(_ancestor)
	_view = VIEW.new()
	_view.name = "ActualTerrainView"
	_ancestor.add_child(_view)
	_view.call("set_frontier_art_enabled", true)
	_inner = _view.get_node("ViewportContainer/SubViewport") as SubViewport
	var environment_node: WorldEnvironment = _inner.get_node("WorldRoot/WorldEnvironment")
	_check(_inner.get_camera_3d() != null, "Fixture uses the real TerrainMap3DView camera")
	_check(environment_node.environment != null and environment_node.environment.ssao_enabled, "The shipped Frontier SSAO remains enabled")
	_check(_inner.size == Vector2i(32, 32), "Initial 16x16 parent allocates a safe 32x32 terrain render target before any frame")
	print("TERRAIN_RENDER_SIZE initial outer=", _outer.size, " inner=", _inner.size)
	_ancestor.process_mode = Node.PROCESS_MODE_DISABLED
	_check(not _view.can_process(), "Ancestor disables the real view's process loop")
	# No process_frame, private resize call, or manual redraw between the size
	# assignment and these checks: the viewport signal must update synchronously.
	_resize_and_check(Vector2i(1280, 720), Vector2i(1280, 720), "1280x720")
	await process_frame
	_check(_inner.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "Disabled view does not resume continuous drawing after the resize")
	_resize_and_check(Vector2i(1920, 1080), Vector2i(1920, 1080), "1920x1080")
	_resize_and_check(Vector2i(16, 720), Vector2i(32, 720), "narrow parent")
	_resize_and_check(Vector2i(1280, 16), Vector2i(1280, 32), "short parent")
	_resize_and_check(Vector2i(16, 16), Vector2i(32, 32), "back to 16x16")
	await process_frame
	_check(_inner.size == Vector2i(32, 32), "The safe minimum survives the next frame with processing disabled")
	_check(_inner.render_target_update_mode != SubViewport.UPDATE_ALWAYS and not _view.can_process(), "Static resized preview stays static and its ancestor stays disabled")
	_check(environment_node.environment.ssao_enabled, "Resize safety preserves SSAO instead of disabling graphics effects")
	_outer.queue_free()
	await process_frame
	print("TERRAIN_RENDER_TARGET_SIZE_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _resize_and_check(parent_size: Vector2i, expected_size: Vector2i, label: String) -> void:
	_outer.size = parent_size
	print("TERRAIN_RENDER_SIZE ", label, " parent=", _outer.size, " visible=", _outer.get_visible_rect().size, " inner=", _inner.size, " update=", _inner.render_target_update_mode, " can_process=", _view.can_process())
	_check(_inner.size == expected_size, label + " synchronously sizes the real inner target to the full visible area or safe minimum")
	_check(_inner.render_target_update_mode == SubViewport.UPDATE_ONCE, label + " requests exactly one redraw while the view's process loop is disabled")

func _check(value: bool, label: String) -> void:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
