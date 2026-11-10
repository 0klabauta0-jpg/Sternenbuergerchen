extends SceneTree

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const CONTROLLER = preload("res://scripts/tests/mission_map_camera_controller.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var host := Node2D.new()
	root.add_child(host)
	var view = VIEW.new()
	view.name = "Primary3DView"
	host.add_child(view)
	view.set_process(false)
	view.call("_update_camera_transform")
	check(view.get("_subviewport").msaa_3d == Viewport.MSAA_2X, "world render target uses bounded 2x geometric antialiasing")
	check(view.has_method("zoom_camera_at_screen_position"), "cursor zoom API exists")
	check(view.has_method("pan_camera_between_screen_positions"), "plane drag API exists")
	if failures > 0:
		host.free()
		quit(1)
		return
	for topology in ["square8", "hex_axial_v1"]:
		view.set("_active_grid_topology", topology)
		for yaw in [0.0, 45.0, 137.0]:
			view.set("_camera_yaw_degrees", yaw)
			view.set("_camera_size", 34.0)
			view.call("_update_camera_transform")
			var pointer := Vector2(849.25, 273.75)
			var before: Vector2 = view.screen_to_world_plane_position(pointer, 2.0)
			view.zoom_camera_at_screen_position(1.0, pointer, 2.0)
			check(before.distance_to(view.screen_to_world_plane_position(pointer, 2.0)) < 0.02, topology + " zoom in holds precise anchor")
			view.zoom_camera_at_screen_position(-1.0, pointer, 2.0)
			check(before.distance_to(view.screen_to_world_plane_position(pointer, 2.0)) < 0.02, topology + " zoom out holds precise anchor")
			var target := pointer + Vector2(71.5, -34.25)
			view.pan_camera_between_screen_positions(pointer, target, 2.0)
			check(before.distance_to(view.screen_to_world_plane_position(target, 2.0)) < 0.02, topology + " drag follows exact ground point")
			check(is_equal_approx(view.get_camera_yaw_degrees(), yaw), "drag never rotates")
	# Parent canvas offset and scaled render surface use the same coordinate conversion.
	var container: SubViewportContainer = view.get("_viewport_container")
	container.position = Vector2(50, 30)
	container.scale = Vector2(0.8, 0.9)
	var transformed_pointer: Vector2 = container.get_global_transform_with_canvas() * Vector2(600, 270)
	var expected_viewport_position: Vector2 = Vector2(600, 270) * Vector2(view.get("_subviewport").size) / container.size
	check(expected_viewport_position.distance_to(view.call("_screen_to_viewport_position", transformed_pointer)) < 0.001, "canvas transform converts to actual render coordinates")
	var transformed_before: Vector2 = view.screen_to_world_plane_position(transformed_pointer)
	view.zoom_camera_at_screen_position(1, transformed_pointer)
	check(transformed_before.distance_to(view.screen_to_world_plane_position(transformed_pointer)) < 0.02, "transformed container anchor")
	for steps in [10000.0, -10000.0]:
		var limit_before: Vector2 = view.screen_to_world_plane_position(transformed_pointer)
		view.zoom_camera_at_screen_position(steps, transformed_pointer)
		check(limit_before.distance_to(view.screen_to_world_plane_position(transformed_pointer)) < 0.03, "zoom limits retain anchor")
		check(view.get_camera_size() >= VIEW.CAMERA_MIN_SIZE and view.get_camera_size() <= VIEW.CAMERA_MAX_SIZE, "zoom size is bounded")
	view.set("_camera_size", 34.0)
	view.set("_grid_size", Vector2i(8, 8))
	view.set("_active_grid_topology", "square8")
	view.set("_focus_grid_position", Vector2(4, 4))
	view.call("_update_camera_transform")
	view.pan_camera_between_screen_positions(Vector2(0, 0), Vector2(1200, 650))
	var focus: Vector2 = view.get_camera_focus_grid_position()
	check(focus.x >= -2 and focus.x <= 10 and focus.y >= -2 and focus.y <= 10, "drag clamps focus to map")
	check(is_equal_approx(focus.x, -2) or is_equal_approx(focus.y, -2) or is_equal_approx(focus.x, 10) or is_equal_approx(focus.y, 10), "large drag reaches an actual clamp edge")
	var camera: Camera3D = view.get("_camera")
	check(absf(rad_to_deg(camera.rotation.x) + 35.1) < 1.0, "flatter approximately isometric starting elevation")
	var controller = CONTROLLER.new()
	host.add_child(controller)
	controller.set_process(false)
	view.set("_grid_size", Vector2i.ZERO)
	view.set("_focus_grid_position", Vector2.ZERO)
	view.call("_update_camera_transform")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_MIDDLE
	press.pressed = true
	press.position = Vector2(500, 300)
	controller.call("_unhandled_input", press)
	check(controller.get("_is_panning"), "MMB press starts drag")
	controller.call("_process", 0.0)
	check(controller.get("_is_panning"), "primary camera processing does not reset active drag")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(520, 310)
	motion.relative = Vector2(20, 10)
	motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	var yaw_before: float = view.get_camera_yaw_degrees()
	var drag_before: Vector2 = view.screen_to_world_plane_position(press.position)
	controller.call("_input", motion)
	check(is_equal_approx(yaw_before, view.get_camera_yaw_degrees()), "mission MMB motion preserves yaw")
	check(drag_before.distance_to(view.screen_to_world_plane_position(motion.position)) < 0.02, "mission event motion uses exact pan API")
	press.pressed = false
	controller.call("_input", press)
	check(not controller.get("_is_panning"), "release in input stage ends drag even over UI")
	press.pressed = true
	controller.call("_unhandled_input", press)
	controller.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not controller.get("_is_panning"), "focus loss ends drag")
	press.pressed = true
	controller.call("_unhandled_input", press)
	motion.button_mask = 0
	controller.call("_input", motion)
	check(not controller.get("_is_panning"), "missing held button cancels stale drag")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = Vector2(850, 300)
	var wheel_before: Vector2 = view.screen_to_world_plane_position(wheel.position)
	var size_before: float = view.get_camera_size()
	controller.call("_unhandled_input", wheel)
	check(view.get_camera_size() < size_before, "wheel event changes zoom")
	check(wheel_before.distance_to(view.screen_to_world_plane_position(wheel.position)) < 0.02, "wheel event preserves cursor anchor")
	Input.action_press(CONTROLLER.ACTION_ROTATE_RIGHT)
	controller.call("_process", 0.1)
	Input.action_release(CONTROLLER.ACTION_ROTATE_RIGHT)
	check(not is_equal_approx(view.get_camera_yaw_degrees(), yaw_before), "Q/E action rotation retained")
	var panel := Panel.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(200, 200)
	root.add_child(panel)
	motion.position = Vector2(100, 100)
	motion.button_mask = 0
	root.push_input(motion, true)
	await process_frame
	check(root.gui_get_hovered_control() == panel, "real viewport GUI hover fixture")
	press.position = motion.position
	press.pressed = true
	root.push_input(press, true)
	check(not controller.get("_is_panning"), "GUI consumes MMB start")
	size_before = view.get_camera_size()
	wheel.position = motion.position
	root.push_input(wheel, true)
	check(is_equal_approx(size_before, view.get_camera_size()), "GUI consumes wheel without camera zoom")
	motion.position = Vector2(900, 500)
	root.push_input(motion, true)
	await process_frame
	press.position = motion.position
	root.push_input(press, true)
	check(controller.get("_is_panning"), "unhandled world MMB starts real viewport drag")
	motion.position = Vector2(100, 100)
	motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	var gui_drag_before: Vector2 = view.get_camera_focus_grid_position()
	root.push_input(motion, true)
	check(controller.get("_is_panning") and gui_drag_before.distance_to(view.get_camera_focus_grid_position()) > 0.01, "active world drag continues over GUI")
	press.position = motion.position
	press.pressed = false
	root.push_input(press, true)
	check(not controller.get("_is_panning"), "GUI release ends real viewport drag")
	panel.free()
	host.free()
	print("CURSOR_CAMERA checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
