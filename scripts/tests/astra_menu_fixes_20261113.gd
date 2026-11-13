extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const CAMERA = preload("res://scripts/tests/mission_map_camera_controller.gd")
const STAR_MAP = preload("res://scripts/ui/star_map_canvas.gd")
const WING = preload("res://scripts/ui/space_wing_panel.gd")
const TACTICAL = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const EDITOR = preload("res://scripts/editor/map_editor.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HOMEBASE = preload("res://scripts/meta/explorable_homebase.gd")
const STAR_SCREEN = preload("res://scripts/ui/star_map_screen.gd")
var passed := 0
var failed := 0
var presses := 0

class SceneInputCounter extends Node:
	var input_count := 0
	var shortcut_count := 0
	var key_count := 0
	var unhandled_count := 0
	var ticks := 0
	func _input(_event: InputEvent) -> void: input_count += 1
	func _shortcut_input(_event: InputEvent) -> void: shortcut_count += 1
	func _unhandled_key_input(_event: InputEvent) -> void: key_count += 1
	func _unhandled_input(_event: InputEvent) -> void: unhandled_count += 1
	func _process(_delta: float) -> void: ticks += 1
	func counts() -> Array: return [input_count, shortcut_count, key_count, unhandled_count]

class QuietStarMap extends STAR_MAP:
	# Keep actual input/projection methods; omit the unrelated 3D renderer.
	func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_STOP

class QuietTactical extends TACTICAL:
	var waypoint_writes := 0
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _update_waypoint_targets(_targets: Array, _position: Vector2) -> bool:
		waypoint_writes += 1
		return true

class QuietEditor extends EDITOR:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

class BasePanProbe extends CanvasLayer:
	var pan_calls := 0
	func pan_camera_between_screen_positions(_from: Vector2, _to: Vector2) -> void: pan_calls += 1

class CommandProbe extends Node:
	var commands: Array = []
	func enqueue_command(command: Dictionary) -> void: commands.append(command)

class QuietHomebase extends HOMEBASE:
	func _ready() -> void:
		# Actual base input receivers, without unrelated map/renderer setup.
		_host = SubViewportContainer.new()
		_host.size = Vector2(400, 250)
		_host.focus_mode = Control.FOCUS_ALL
		add_child(_host)
		_host.gui_input.connect(_on_world_gui_input)
		_host.focus_exited.connect(_clear_keyboard_input)
		_viewport = SubViewport.new()
		_viewport.size = Vector2i(400, 250)
		_viewport.gui_disable_input = true
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_host.add_child(_viewport)
		_view = BasePanProbe.new()
		add_child(_view)
		_active = true
		_initialized = true
		set_process(false)
		set_physics_process(false)

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		print("FAIL ", label)

func _key(code: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene := Control.new()
	root.add_child(scene)
	current_scene = scene
	var counter := SceneInputCounter.new()
	scene.add_child(counter)
	var disabled_counter := SceneInputCounter.new()
	scene.add_child(disabled_counter)
	disabled_counter.set_process_input(false)
	var button := Button.new()
	button.name = "UnderlyingAction"
	button.text = "Underlying action"
	button.position = Vector2(20, 20)
	button.size = Vector2(180, 60)
	button.pressed.connect(func(): presses += 1)
	scene.add_child(button)
	await process_frame
	var shell: Node = root.get_node("GlobalEscapeMenu")
	shell.set_test_mode(true)
	shell.set_settings_path_for_tests("user://astra-menu-settings.cfg")
	button.grab_focus()
	await _key(KEY_ESCAPE)
	_check(shell.is_menu_visible(), "Escape opens menu")
	_check(root.gui_get_focus_owner().name == "ResumeButton", "opening transfers focus")
	var counts := counter.counts()
	var ticks := counter.ticks
	await _key(KEY_K)
	_check(counter.counts() == counts, "all gameplay input callbacks suspended")
	_check(counter.ticks > ticks and not paused, "simulation processing continues")
	button.grab_focus()
	_check(shell.is_ancestor_of(root.gui_get_focus_owner()), "outside focus is contained")
	await _key(KEY_TAB, true)
	_check(root.gui_get_focus_owner().name == "QuitButton", "reverse Tab wraps inside menu")
	await _key(KEY_TAB)
	_check(root.gui_get_focus_owner().name == "ResumeButton", "forward Tab wraps inside menu")
	await _key(KEY_ENTER)
	_check(not shell.is_menu_visible(), "Enter activates focused menu button")
	_check(presses == 0, "Enter does not activate underlying button")
	_check(root.gui_get_focus_owner() == button, "previous focus restored")
	_check(counter.is_processing_input() and counter.is_processing_unhandled_key_input(), "input callbacks restored")
	_check(not disabled_counter.is_processing_input(), "previously disabled input stays disabled")
	await _key(KEY_K)
	_check(counter.counts() != counts, "game input works after closing")
	await _key(KEY_ENTER)
	_check(presses == 1, "underlying GUI works after closing")
	shell.open_settings()
	_check(root.gui_get_focus_owner() is HSlider, "direct settings opening transfers focus")
	for index in 8:
		await _key(KEY_TAB)
		_check(shell.is_ancestor_of(root.gui_get_focus_owner()), "settings Tab stays inside %d" % index)
	await _key(KEY_ESCAPE)
	_check(shell.is_menu_visible() and root.gui_get_focus_owner().name == "ResumeButton", "settings Escape returns to menu focus")
	shell.open_controls()
	_check(root.gui_get_focus_owner().name == "ControlsBackButton", "help receives focus")
	await _key(KEY_TAB)
	_check(root.gui_get_focus_owner().name == "ControlsBackButton", "single help button retains Tab focus")
	var late_counter := SceneInputCounter.new()
	scene.add_child(late_counter)
	await process_frame
	await process_frame
	_check(not late_counter.is_processing_input(), "new scene input also suspended")
	await _key(KEY_ESCAPE)
	await _key(KEY_ESCAPE)
	_check(root.gui_get_focus_owner() == button, "submenu chain preserves original focus")
	_check(late_counter.is_processing_input(), "new scene input restored")
	_test_polled_camera(scene, shell)
	await _test_new_load_tab(scene, shell)
	await _test_cancelled_gestures(scene, shell)
	await _test_base_and_alt_release(scene, shell)
	shell.open_menu()
	button.queue_free()
	await process_frame
	shell.close_menu()
	_check(not shell.is_menu_visible(), "freed previous focus closes safely")
	shell.open_menu()
	current_scene = null
	scene.queue_free()
	await process_frame
	shell.close_menu()
	_check(not shell.is_menu_visible(), "freed scene callbacks restore safely")
	await process_frame
	print("ASTRA_MENU_FIXES passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_polled_camera(scene: Node, shell: Node) -> void:
	var camera = CAMERA.new()
	scene.add_child(camera)
	camera.set_process(false)
	camera.make_current()
	var initial: Vector2 = camera.position
	Input.action_press(CAMERA.ACTION_PAN_RIGHT)
	camera._process(0.1)
	_check(camera.position.x > initial.x, "real camera polls Input action before modal")
	for open_method in ["open_menu", "open_settings", "open_controls"]:
		camera._is_panning = true
		shell.call(open_method)
		var before: Vector2 = camera.position
		camera._process(0.1)
		_check(camera.position == before and not camera._is_panning, "modal blocks camera polling and cancels pan: " + open_method)
		shell.close_menu()
	var before_resume: Vector2 = camera.position
	camera._process(0.1)
	_check(camera.position.x > before_resume.x, "real camera resumes polling without pausing tree")
	Input.action_release(CAMERA.ACTION_PAN_RIGHT)
	camera.free()


func _test_new_load_tab(scene: Node, shell: Node) -> void:
	# A real save action changes Load from disabled to enabled in the same menu.
	scene.scene_file_path = "res://scenes/tests/mission_reactivity_test.tscn"
	shell.set_save_path_for_tests("user://astra-menu-slot-%d.cfg" % Time.get_ticks_usec())
	shell.open_menu()
	var save_button: Button = shell.find_child("SaveMissionButton", true, false)
	var load_button: Button = shell.find_child("LoadMissionButton", true, false)
	_check(not save_button.disabled and load_button.disabled, "fresh slot starts with Save enabled and Load disabled")
	save_button.grab_focus()
	await _key(KEY_ENTER)
	_check(not load_button.disabled and root.gui_get_focus_owner() == save_button, "saving enables Load and preserves current focus")
	await _key(KEY_TAB)
	_check(root.gui_get_focus_owner() == load_button, "newly enabled Load joins the Tab ring immediately")
	shell.close_menu()


func _mouse_button(code: MouseButton, pressed: bool, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = code
	event.pressed = pressed
	event.position = point
	event.global_position = point
	root.push_input(event, true)
	await process_frame


func _mouse_motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = Vector2(30, 20)
	root.push_input(event, true)
	await process_frame


func _test_cancelled_gestures(scene: Node, shell: Node) -> void:
	var star := QuietStarMap.new()
	star.position = Vector2(650, 20)
	star.size = Vector2(400, 250)
	scene.add_child(star)
	var stats := {"box": 0, "wing": 0}
	star.crafts_box_selected.connect(func(_ids: Array, _additive: bool): stats.box += 1)
	var start: Vector2 = star.global_position + Vector2(40, 40)
	await _mouse_button(MOUSE_BUTTON_RIGHT, true, start)
	_check(star._drag_button == MOUSE_BUTTON_RIGHT, "real viewport press starts strategic map pan")
	var pan_before: Vector2 = star._camera_pan
	shell.open_menu()
	await _mouse_button(MOUSE_BUTTON_RIGHT, false, start)
	shell.close_menu()
	await _mouse_motion(start + Vector2(80, 40))
	_check(star._drag_button == 0 and star._camera_pan == pan_before, "release during modal cannot resume old strategic pan")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(40, 40)
	press.global_position = start
	star._gui_input(press)
	_check(star._selection_active, "production strategic selection receiver starts gesture")
	shell.open_menu()
	await _mouse_button(MOUSE_BUTTON_LEFT, false, start)
	shell.close_menu()
	await _mouse_motion(start + Vector2(90, 40))
	await _mouse_button(MOUSE_BUTTON_LEFT, false, start + Vector2(90, 40))
	_check(not star._selection_active and int(stats.box) == 0, "cancelled map box selection emits no late selection")
	star.free()

	var wing = WING.new()
	wing.position = Vector2(650, 20)
	scene.add_child(wing)
	var snapshot := {"space_wings": {"wings": {"w1": {"name": "One", "leader_craft_id": "ship", "craft_ids": ["ship"]}}}, "crafts": []}
	wing.configure(func(): return snapshot, Callable())
	wing.select_wing("w1")
	wing.wing_focus_requested.connect(func(_id: String): stats.wing += 1)
	var selected: Array = wing.selected_wing_ids()
	var expanded: Dictionary = wing._expanded_wings.duplicate(true)
	wing._card_input(press, "w1")
	_check(wing._drag_active, "production wing card receiver starts gesture")
	shell.open_menu()
	await _mouse_button(MOUSE_BUTTON_LEFT, false, start)
	shell.close_menu()
	await _mouse_motion(start + Vector2(80, 40))
	await _mouse_button(MOUSE_BUTTON_LEFT, false, start + Vector2(80, 40))
	_check(not wing._drag_active and wing.selected_wing_ids() == selected and wing._expanded_wings == expanded and int(stats.wing) == 0, "cancelled wing gesture preserves selection, expansion and focus")
	wing.free()

	var tactical := QuietTactical.new()
	scene.add_child(tactical)
	tactical._selected_fireteam_ids = PackedStringArray(["alpha"])
	tactical._focused_waypoint_ref = {"fireteam_id": "alpha", "waypoint_index": 0}
	var focused: Dictionary = tactical._focused_waypoint_ref.duplicate(true)
	tactical._dragged_waypoint_ref = focused.duplicate(true)
	tactical._is_dragging_waypoint = true
	tactical._has_dragged_waypoint = true
	tactical._right_order_press_active = true
	tactical._area_order_press_active = true
	tactical._selection_press_active = true
	tactical._selection_drag_active = true
	shell.open_menu()
	shell.close_menu()
	_check(not tactical._update_waypoint_drag(Vector2(100, 100)) and not tactical._finish_waypoint_drag(Vector2(100, 100)), "cancelled waypoint gesture cannot update or finish an order")
	_check(not tactical._finish_right_order_context_interaction(Vector2(100, 100)) and not tactical._finish_area_order_interaction(Vector2(100, 100)), "cancelled area gestures cannot commit commands")
	_check(tactical.waypoint_writes == 0 and tactical._focused_waypoint_ref == focused and Array(tactical._selected_fireteam_ids) == ["alpha"] and not tactical._selection_drag_active, "tactical cancellation preserves selection and existing waypoint reference")
	tactical.free()

	var editor := QuietEditor.new()
	scene.add_child(editor)
	var tile = TILE.new({"tile_id": "existing", "grid_position": Vector2i.ZERO})
	var tile_before: Dictionary = tile.to_dict().duplicate(true)
	editor.begin_undo_transaction("existing_stroke")
	editor.record_tile_before_change(tile)
	editor._is_painting = true
	editor._is_network_dragging = true
	editor._network_drag_preview_path.assign([Vector2i.ZERO, Vector2i(1, 0)])
	editor._is_dragging_marker = true
	editor._dragged_marker_id = "existing_marker"
	editor._dragged_patrol_waypoint_index = 1
	editor._right_mouse_pressed = true
	editor._is_panning = true
	shell.open_menu()
	_check(not editor._is_painting and not editor._is_network_dragging and not editor._is_dragging_marker and editor._dragged_patrol_waypoint_index == -1 and not editor._right_mouse_pressed and not editor._is_panning, "editor cancels incomplete pointer gestures")
	_check(editor._active_undo_transaction.is_empty() and editor._undo_stack.size() == 1 and tile.to_dict() == tile_before, "editor retains Undo for prior stroke without applying another terrain edit")
	shell.close_menu()
	editor.free()


func _key_state(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	root.push_input(event, true)
	await process_frame


func _test_base_and_alt_release(scene: Node, shell: Node) -> void:
	var base := QuietHomebase.new()
	base.position = Vector2(650, 20)
	scene.add_child(base)
	var commands := CommandProbe.new()
	base.add_child(commands)
	base._sim = commands
	base._selected_person_id = "existing_person"
	base._selected_world_craft_id = "existing_craft"
	base._move_armed = true
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_MIDDLE
	press.pressed = true
	press.position = Vector2(40, 40)
	base._on_world_gui_input(press)
	_check(base._camera_dragging, "actual homebase receiver starts middle-button pan")
	base._keys[KEY_D] = true
	base._keyboard_move = true
	base._move_cadence = 0.1
	base._world_context_hint = Label.new()
	base.add_child(base._world_context_hint)
	base._world_context_hint.show()
	shell.open_menu()
	_check(not base._camera_dragging and base._camera_drag_last == Vector2.ZERO and base._keys.is_empty() and not base._keyboard_move and is_zero_approx(base._move_cadence), "homebase modal hook clears held pointer and keyboard input")
	_check(commands.commands.is_empty() and base._selected_person_id == "existing_person" and base._selected_world_craft_id == "existing_craft" and base._move_armed and not base._world_context_hint.visible, "homebase cancellation preserves selection and accepted orders, clears only context hint")
	var point: Vector2 = base.global_position + Vector2(40, 40)
	await _mouse_button(MOUSE_BUTTON_MIDDLE, false, point)
	shell.close_menu()
	await _mouse_motion(point + Vector2(60, 30))
	_check(int(base._view.get("pan_calls")) == 0, "release while modal cannot resume old homebase pan")
	base._on_world_gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = point + Vector2(80, 40)
	motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	base._input(motion)
	_check(int(base._view.get("pan_calls")) == 1, "fresh homebase middle-button gesture still pans")
	motion.button_mask = 0
	base._input(motion)
	_check(not base._camera_dragging and int(base._view.get("pan_calls")) == 1 and commands.commands.is_empty(), "homebase missing-release guard stops pan without commands")
	base.free()

	var screen = STAR_SCREEN.new()
	scene.add_child(screen)
	screen._fuel_help = Label.new()
	screen.add_child(screen._fuel_help)
	await _key_state(KEY_ALT, true)
	_check(screen._show_fuel_help and screen._fuel_help.visible, "actual star-map ALT receiver shows fuel help")
	shell.open_menu()
	await _key_state(KEY_ALT, false)
	shell.close_menu()
	_check(not screen._show_fuel_help and not screen._fuel_help.visible, "ALT release during modal cannot leave fuel help stuck")
	await _key_state(KEY_ALT, true)
	_check(screen._show_fuel_help and screen._fuel_help.visible, "fresh ALT press still shows fuel help")
	await _key_state(KEY_ALT, false)
	_check(not screen._show_fuel_help and not screen._fuel_help.visible, "normal ALT release still hides fuel help")
	screen.free()
