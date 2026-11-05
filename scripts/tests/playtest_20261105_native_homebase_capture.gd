extends "res://scripts/tests/playtest_20261105_fullscreen_performance_capture.gd"
## Native input route through visible controls. No actor/state/timer injection.
var _native_size := Vector2i.ZERO

func _initialize() -> void:
	_native_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	root.mode = Window.MODE_FULLSCREEN
	super._initialize()

func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	root.mode = Window.MODE_FULLSCREEN
	root.content_scale_size = _native_size
	await super._capture(id, view, settle_frames)
	if id != "02_homebase":
		return
	var screen: Control = current_scene.get_node("HomebaseScreen")
	var presenter: Control = screen.get("_operations_presenter")
	_check(presenter != null and presenter.is_visible_in_tree(), "New Operations presenter is the normal visible Homebase")
	_check(root.mode == Window.MODE_FULLSCREEN and DisplayServer.window_get_size() == _native_size, "Homebase input test covers the actual display in fullscreen")
	var portrait: TextureRect = presenter.get("_focused_portrait")
	_check(portrait.texture is AtlasTexture, "Normal Homebase shows the new atlas portrait")
	_check(portrait.size.x <= portrait.size.y * 1.25, "Focused portrait keeps the complete face within a portrait-shaped control")
	var navigation: Dictionary = presenter.get("_nav")
	await _click_visible(navigation["base"])
	var base: Control = presenter.get("_base")
	_check(bool(base.call("get_exploration_snapshot").get("active", false)), "Actual navigation button activates the explorable base")
	await _frames(8)
	await super._capture("02a_base_walkable", null, 4)
	var before: Dictionary = base.call("get_exploration_snapshot")
	var host: Control = base.get("_host")
	await _click_visible(host)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.keycode = KEY_D
	key.pressed = true
	root.push_input(key, true)
	await create_timer(1.3).timeout
	key = key.duplicate()
	key.pressed = false
	root.push_input(key, true)
	await _frames(5)
	var after: Dictionary = base.call("get_exploration_snapshot")
	_check(int(after.movement_command_count) > int(before.movement_command_count), "Native D key reaches the real base input handler")
	_check(Vector2(after.avatar_position).distance_to(Vector2(before.avatar_position)) > 1.0, "Commander moves through SimulationRoot after native keyboard input")
	_check(after.avatar_instance_id == before.avatar_instance_id and not bool(after.tree_paused), "Walking preserves commander identity and leaves the global tree active")
	await super._capture("02b_base_after_keyboard", null, 4)
	# Proximity and movement use the actual right-click/keyboard input route.
	var terminal: Dictionary = Array(after.terminals)[0]
	var base_view: Node = base.get("_view")
	var local_point: Vector2 = base_view.call("world_to_screen_position", Vector2(terminal.world_position))
	var base_viewport: SubViewport = base.get("_viewport")
	var point: Vector2 = host.global_position + local_point * host.size / Vector2(base_viewport.size)
	await _click_point(point, MOUSE_BUTTON_RIGHT)
	var reached := await _wait_until("native right-click walking reaches Personnel console", func() -> bool:
		return String(base.call("get_exploration_snapshot").get("nearby_terminal", "")) == "personnel"
	,12.0)
	_check(reached, "Native right-click walks to the existing console using its real proximity gate")
	var interact := InputEventKey.new()
	interact.keycode = KEY_E
	interact.physical_keycode = KEY_E
	interact.pressed = true
	root.push_input(interact, true)
	interact = interact.duplicate()
	interact.pressed = false
	root.push_input(interact, true)
	await _frames(3)
	_check(String(presenter.call("get_presentation_snapshot").get("mode", "")) == "personnel", "Native E key opens the real Personnel page from the console")
	await _click_visible(navigation["base"])
	await _frames(3)
	var exit: Button = base.get_node("ExitExploration")
	await _click_visible(exit)
	_check(not bool(base.call("get_exploration_snapshot").get("active", true)), "Visible base exit deactivates its local runtime")
	_check(String(presenter.call("get_presentation_snapshot").get("mode", "")) == "squad", "Visible base exit returns to team/equipment")
	_facts["native_homebase"] = {"before":before,"after":after,"window_mode":root.mode,"physical_size":DisplayServer.window_get_size(),"content_size":root.content_scale_size,"input_route":"Viewport.push_input mouse + physical D key; no actor writes"}
	await super._capture("02c_operations_after_base", null, 4)
	var mapping: Dictionary = base_view.call("get_render_snapshot")
	_check(int(mapping.get("missing_map_asset_mapping_count", -1)) == 0, "Native base renders the authored footprints without missing-asset cubes")

func _click_point(point: Vector2, button_index: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await _frames(1)
	var click := InputEventMouseButton.new()
	click.position = point
	click.button_index = button_index
	click.button_mask = MOUSE_BUTTON_MASK_RIGHT if button_index == MOUSE_BUTTON_RIGHT else MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	click.button_mask = 0
	root.push_input(click, true)
	await _frames(2)

func _click_visible(control: Control) -> void:
	_check(control != null and control.is_visible_in_tree() and control.get_global_rect().size.x > 0, "Native input target is visibly laid out")
	if control == null:
		return
	var point := control.get_global_rect().get_center()
	_check(Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(point), "Native input target lies inside the fullscreen viewport")
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await _frames(1)
	var click := InputEventMouseButton.new()
	click.position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	click.button_mask = 0
	root.push_input(click, true)
	await _frames(2)
