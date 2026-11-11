extends SceneTree
## Real viewport input checks: cursor-anchored zoom, drag over children and transformed picking.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var checks := 0
var failed := 0
var targets: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		printerr("FAIL: " + label)

func _button(point: Vector2, index: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = index
	event.pressed = pressed
	if index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		event.button_mask = (1 << (int(index) - 1)) if pressed else 0
	root.push_input(event, true)
	if pressed and index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# Desktop wheel delivery includes its release; do not leave a synthetic
		# wheel button captured by the previous hovered GUI control.
		var release: InputEventMouseButton = event.duplicate()
		release.pressed = false
		root.push_input(release, true)

func _move(point: Vector2, relative: Vector2, mask: int = 0) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = relative
	event.button_mask = mask
	root.push_input(event, true)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var canvas: Control = load("res://scripts/ui/star_map_canvas.gd").new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.connect("orbit_requested", func(id: String): targets.append(id))
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	var travel := {"phase": "orbit", "craft_id": "test_ship", "orbit_id": "moon_orbit", "position": [0.18, 0.70], "orbits": definitions.orbits, "bodies": definitions.bodies}
	var before: Dictionary = travel.duplicate(true)
	canvas.call("set_travel_snapshot", travel)
	await process_frame
	_check(canvas.has_method("screen_to_map") and canvas.has_method("map_to_screen"), "Map has explicit invertible camera transform")
	if not canvas.has_method("screen_to_map"):
		canvas.free()
		_finish()
		return
	_check(float(canvas.call("get_camera_snapshot").zoom) > 1.0, "Initial view is closer than the complete overview")
	for body: Dictionary in definitions.bodies.values():
		_check(Rect2(Vector2.ZERO, canvas.size).has_point(canvas.map_to_screen(GRID.pair(body.position))),
			"Initial view shows " + String(body.name))
	var cursor := Vector2(420, 290)
	var world_before: Vector2 = canvas.call("screen_to_map", cursor)
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_WHEEL_UP, true)
	await process_frame
	_check(float(canvas.call("get_camera_snapshot").zoom) > 1.0, "Actual viewport wheel event zooms empty map")
	_check(world_before.distance_to(canvas.call("screen_to_map", cursor)) < 0.00001, "Wheel zoom preserves world coordinate under cursor")
	var planet: Control = canvas.find_child("PlanetBody", true, false)
	cursor = planet.get_global_rect().get_center()
	world_before = canvas.call("screen_to_map", cursor)
	var zoom_before: float = canvas.call("get_camera_snapshot").zoom
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_WHEEL_UP, true)
	await process_frame
	_check(float(canvas.call("get_camera_snapshot").zoom) > zoom_before, "Wheel over actual body hit control still reaches camera")
	_check(world_before.distance_to(canvas.call("screen_to_map", cursor)) < 0.00001, "Body-hover wheel keeps exact cursor anchor")
	var caption: Control = canvas.find_child("PlanetOrbit", true, false)
	cursor = caption.get_global_rect().get_center()
	world_before = canvas.call("screen_to_map", cursor)
	zoom_before = canvas.call("get_camera_snapshot").zoom
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_WHEEL_DOWN, true)
	await process_frame
	_check(float(canvas.call("get_camera_snapshot").zoom) < zoom_before and world_before.distance_to(canvas.call("screen_to_map", cursor)) < 0.00001, "Wheel over keyboard caption zooms with the same cursor anchor")
	cursor = caption.get_global_rect().get_center()
	var anchor_before: Vector2 = canvas.call("map_to_screen", Vector2(0.80, 0.28))
	var count_before := targets.size()
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_MIDDLE, true)
	_move(cursor + Vector2(36, -22), Vector2(36, -22), MOUSE_BUTTON_MASK_MIDDLE)
	_button(cursor + Vector2(36, -22), MOUSE_BUTTON_MIDDLE, false)
	await process_frame
	_check((Vector2(canvas.call("map_to_screen", Vector2(0.80, 0.28))) - anchor_before).distance_to(Vector2(36, -22)) < 0.01, "Middle drag over keyboard caption pans the displayed map")
	_check(targets.size() == count_before, "Dragging a body caption never starts a jump")
	planet = canvas.find_child("PlanetBody", true, false)
	cursor = planet.get_global_rect().get_center()
	anchor_before = canvas.call("map_to_screen", Vector2(0.80, 0.28))
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_RIGHT, true)
	_move(cursor + Vector2(-18, 24), Vector2(-18, 24), MOUSE_BUTTON_MASK_RIGHT)
	_button(cursor + Vector2(-18, 24), MOUSE_BUTTON_RIGHT, false)
	await process_frame
	_check((Vector2(canvas.call("map_to_screen", Vector2(0.80, 0.28))) - anchor_before).distance_to(Vector2(-18, 24)) < 0.01, "Right drag over body hit control pans without being swallowed")
	_check(targets.size() == count_before, "Right drag on a body never requests travel")
	cursor = planet.get_global_rect().get_center()
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_LEFT, true)
	_button(cursor, MOUSE_BUTTON_LEFT, false)
	_check(not targets.is_empty() and targets.back() == "planet_orbit", "Actual planet picking remains correct after zoom and pan")
	_check(travel == before, "All camera interaction leaves authoritative travel snapshot unchanged")
	canvas.reset_camera()
	var center: Vector2 = canvas.map_to_screen(GRID.pair(definitions.bodies.planet.position))
	canvas.zoom_at(center, 8.0)
	canvas.pan_by(canvas.size * 0.5 - center)
	var ring_cell: Vector2i = GRID.cell_from_record(definitions.orbits.planet_orbit)
	cursor = canvas.map_to_screen(GRID.normalized(ring_cell))
	count_before = targets.size()
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_LEFT, true)
	_button(cursor, MOUSE_BUTTON_LEFT, false)
	_check(targets.size() == count_before + 1 and targets.back() == "planet_orbit", "Rendered orbit belt cell is a clickable target")
	canvas.reset_camera()
	for index in range(30):
		canvas.call("zoom_at", Vector2(250, 200), 100.0)
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), 32.0), "Zoom maximum is bounded")
	canvas.call("zoom_at", Vector2(250, 200), 0.001)
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), 0.55), "Zoom minimum is bounded")
	var recenter: Control = canvas.find_child("RecenterMap", true, false)
	cursor = recenter.get_global_rect().get_center()
	var overlapping_label: Control = canvas.find_child("Future_planet_orbit_sector_03", true, false)
	canvas.call("pan_by", cursor - overlapping_label.get_global_rect().get_center())
	_move(cursor, Vector2.ZERO)
	await process_frame
	_button(cursor, MOUSE_BUTTON_LEFT, true)
	await process_frame
	_button(cursor, MOUSE_BUTTON_LEFT, false)
	await process_frame
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), 1.0), "Gesamtansicht restores fitting zoom")
	_check(Vector2(canvas.call("get_camera_snapshot").pan).is_zero_approx(), "Gesamtansicht restores the system center")
	var placeholders: Array = Array(canvas.call("get_camera_snapshot").encounter_slots)
	_check(placeholders.size() == 3 and placeholders.all(func(slot: Dictionary): return not slot.available), "Exactly three future orbit areas remain unavailable")
	canvas.zoom_at(center, 5.0)
	canvas.pan_by(canvas.size * 0.5 - center)
	var placeholder: Control = canvas.find_child("Future_planet_orbit_sector_03", true, false)
	_check(placeholder.visible and Rect2(Vector2.ZERO, canvas.size).has_point(placeholder.get_global_rect().get_center()),
		"Unavailable orbit label is actually visible before testing its click")
	count_before = targets.size()
	cursor = placeholder.get_global_rect().get_center()
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_LEFT, true)
	_button(cursor, MOUSE_BUTTON_LEFT, false)
	_check(targets.size() == count_before, "Clicking a future Orbitbereich does not start travel")
	canvas.free()
	_finish()

func _finish() -> void:
	print("STAR_MAP_CAMERA checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)
