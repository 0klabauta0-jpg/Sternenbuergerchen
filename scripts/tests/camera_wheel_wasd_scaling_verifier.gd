extends SceneTree

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
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

	# 2. Rasten vom Minimum bis zum Maximum zaehlen.
	view.set("_camera_size", VIEW.CAMERA_MIN_SIZE)
	var n: int = 0
	while n < 200:
		var size_now: float = view.get_camera_size()
		if size_now >= VIEW.CAMERA_MAX_SIZE - 0.001:
			break
		view.zoom_camera_by_factor_steps(-1.0)
		n += 1
	check(n >= 15 and n <= 25, "wheel reaches max in 15-25 notches (got %d)" % n)
	var max_size: float = view.get_camera_size()
	check(max_size <= VIEW.CAMERA_MAX_SIZE, "wheel zoom out is clamped to CAMERA_MAX_SIZE")

	# 3. Hinein bis zum Minimum.
	var m: int = 0
	while m < 200:
		var size_now2: float = view.get_camera_size()
		if size_now2 <= VIEW.CAMERA_MIN_SIZE + 0.001:
			break
		view.zoom_camera_by_factor_steps(1.0)
		m += 1
	check(m >= 15 and m <= 25, "wheel reaches min in 15-25 notches (got %d)" % m)
	var min_size: float = view.get_camera_size()
	check(min_size >= VIEW.CAMERA_MIN_SIZE, "wheel zoom in is clamped to CAMERA_MIN_SIZE")

	# 4. Rasten-Verhaeltnis.
	view.set("_camera_size", 34.0)
	view.call("_update_camera_transform")
	view.zoom_camera_by_factor_steps(-1.0)
	var ratio_size: float = view.get_camera_size()
	check(is_equal_approx(ratio_size, 34.0 * VIEW.CAMERA_WHEEL_ZOOM_FACTOR), "one wheel notch multiplies size by CAMERA_WHEEL_ZOOM_FACTOR")

	# 5. Linearer Altweg unveraendert.
	view.set("_camera_size", 34.0)
	view.call("_update_camera_transform")
	view.zoom_camera(1.0)
	var linear_size: float = view.get_camera_size()
	check(is_equal_approx(linear_size, 34.0 - VIEW.CAMERA_ZOOM_STEP), "linear zoom_camera keeps CAMERA_ZOOM_STEP behaviour")

	# 6. WASD-Tempo.
	view.set("_camera_size", 34.0)
	var speed_34: float = view.get_keyboard_pan_units_per_second()
	check(absf(speed_34 - 18.02) < 0.1, "keyboard pan speed at size 34 is about 18 units/s (got %f)" % speed_34)
	view.set("_camera_size", 120.0)
	var speed_120: float = view.get_keyboard_pan_units_per_second()
	check(speed_120 > 60.0, "keyboard pan speed at size 120 is above 60 units/s (got %f)" % speed_120)
	view.set("_camera_size", 5.5)
	var speed_min: float = view.get_keyboard_pan_units_per_second()
	check(is_equal_approx(speed_min, VIEW.CAMERA_KEY_PAN_MIN_UNITS_PER_SECOND), "keyboard pan speed is clamped to minimum at size 5.5")

	# 7. WASD bewegt proportional zur Zeit.
	view.set("_grid_size", Vector2i(400, 400))
	view.set("_active_grid_topology", "square8")
	view.set("_camera_yaw_degrees", 0.0)
	view.set("_focus_grid_position", Vector2(200, 200))
	view.set("_camera_size", 34.0)
	view.call("_update_camera_transform")
	var a: Vector2 = view.get_camera_focus_grid_position()
	view.pan_camera_keyboard(Vector2.RIGHT, 0.5)
	var b: Vector2 = view.get_camera_focus_grid_position()
	var moved: float = a.distance_to(b)
	var expected_moved: float = view.get_keyboard_pan_units_per_second() * 0.5
	check(absf(moved - expected_moved) < 0.05, "WASD pan distance matches speed times delta (moved %f, expected %f)" % [moved, expected_moved])

	# 8. Anker beim Mausrad.
	view.set("_camera_size", 34.0)
	view.set("_focus_grid_position", Vector2(200, 200))
	view.call("_update_camera_transform")
	var pointer: Vector2 = Vector2(849.25, 273.75)
	var before: Variant = view.screen_to_world_plane_position(pointer, 0.0)
	view.zoom_camera_wheel_at_screen_position(1.0, pointer)
	var after: Variant = view.screen_to_world_plane_position(pointer, 0.0)
	if before is Vector2 and after is Vector2:
		var drift: float = Vector2(before).distance_to(Vector2(after))
		check(drift < 0.02, "wheel zoom keeps the point under the cursor fixed (drift %f)" % drift)
	else:
		check(false, "wheel anchor: screen to plane returned no Vector2")

	print("CAMERA_WHEEL_WASD checks=%d failures=%d" % [checks, failures])
	host.free()
	quit(1 if failures > 0 else 0)
