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
	# Stufe 1: Ein Klick auf einen Marker merkt das Ziel vor (orbit_previewed); orbit_requested sendet erst "Start" der Sternkarte.
	canvas.connect("orbit_previewed", func(orbit_id: String, marker_id: String): targets.append(orbit_id + "/" + marker_id))
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
	var travel := {"phase": "stopped", "craft_id": "test_ship", "position": [0.18, 0.70], "orbits": definitions.orbits, "bodies": definitions.bodies}
	var before: Dictionary = travel.duplicate(true)
	canvas.call("set_travel_snapshot", travel)
	await process_frame
	_check(float(canvas.call("get_camera_snapshot").zoom) > 1.0, "Initial view is closer than the complete overview")
	var expected_markers: int = definitions.orbits.size()
	_check(int(canvas.call("get_camera_snapshot").orbit_marker_count) == expected_markers, "One visible marker for each approach orbit")
	for body: Dictionary in definitions.bodies.values():
		_check(Rect2(Vector2.ZERO, canvas.size).has_point(canvas.map_to_screen(GRID.pair(body.position))), "Initial view shows " + String(body.name))
	for orbit_id in definitions.orbits:
		for marker: Dictionary in Array(definitions.orbits[orbit_id].markers).slice(0, 1):
			var cursor: Vector2 = canvas.map_to_screen(GRID.normalized(GRID.cell_from_record(marker)))
			var count := targets.size()
			_move(cursor, Vector2.ZERO)
			_button(cursor, MOUSE_BUTTON_LEFT, true)
			_button(cursor, MOUSE_BUTTON_LEFT, false)
			_check(targets.size() == count + 1 and targets.back() == orbit_id + "/" + String(marker.id), "Actual map click picks " + orbit_id + "/" + String(marker.id))
	var cursor := Vector2(420, 290)
	var world_before: Vector2 = canvas.call("screen_to_map", cursor)
	var zoom_before: float = canvas.call("get_camera_snapshot").zoom
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_WHEEL_UP, true)
	await process_frame
	_check(float(canvas.call("get_camera_snapshot").zoom) > zoom_before, "Actual viewport wheel event zooms empty map")
	_check(world_before.distance_to(canvas.call("screen_to_map", cursor)) < 0.00001, "Wheel zoom preserves world coordinate under cursor")
	var caption: Control = canvas.find_child("PlanetCaption", true, false)
	cursor = caption.get_global_rect().get_center()
	world_before = canvas.call("screen_to_map", cursor)
	zoom_before = canvas.call("get_camera_snapshot").zoom
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_WHEEL_DOWN, true)
	await process_frame
	_check(float(canvas.call("get_camera_snapshot").zoom) < zoom_before and world_before.distance_to(canvas.call("screen_to_map", cursor)) < 0.00001, "Wheel over body caption preserves cursor anchor")
	var anchor_before: Vector2 = canvas.call("map_to_screen", Vector2(0.80, 0.28))
	var count_before := targets.size()
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_MIDDLE, true)
	_move(cursor + Vector2(36, -22), Vector2(36, -22), MOUSE_BUTTON_MASK_MIDDLE)
	_button(cursor + Vector2(36, -22), MOUSE_BUTTON_MIDDLE, false)
	await process_frame
	_check((Vector2(canvas.call("map_to_screen", Vector2(0.80, 0.28))) - anchor_before).distance_to(Vector2(36, -22)) < 0.01 and targets.size() == count_before, "Middle drag pans without starting travel")
	var planet: Dictionary = definitions.bodies.planet
	cursor = canvas.map_to_screen(GRID.pair(planet.position))
	anchor_before = canvas.call("map_to_screen", Vector2(0.80, 0.28))
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_RIGHT, true)
	_move(cursor + Vector2(-18, 24), Vector2(-18, 24), MOUSE_BUTTON_MASK_RIGHT)
	_button(cursor + Vector2(-18, 24), MOUSE_BUTTON_RIGHT, false)
	await process_frame
	_check((Vector2(canvas.call("map_to_screen", Vector2(0.80, 0.28))) - anchor_before).distance_to(Vector2(-18, 24)) < 0.01 and targets.size() == count_before, "Right drag over a body pans without starting travel")
	canvas.reset_camera()
	var center: Vector2 = canvas.map_to_screen(GRID.pair(planet.position))
	canvas.zoom_at(center, 8.0)
	canvas.pan_by(canvas.size * 0.5 - center)
	var marker_cell := GRID.cell_from_record(definitions.orbits.planet_orbit.markers[0])
	cursor = canvas.map_to_screen(GRID.normalized(marker_cell))
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_LEFT, true)
	_button(cursor, MOUSE_BUTTON_LEFT, false)
	_check(targets.size() == count_before + 1 and targets.back() == "planet_orbit/orbit_1", "Zoomed and panned marker uses the same picking transform")
	count_before = targets.size()
	var old_ring_cell := GRID.cell_from_record(planet) + GRID.HEX.DIRECTIONS[0] * int(planet.ring_radius)
	for cell in [old_ring_cell, GRID.cell_from_record(planet)]:
		cursor = canvas.map_to_screen(GRID.normalized(cell))
		_move(cursor, Vector2.ZERO)
		_button(cursor, MOUSE_BUTTON_LEFT, true)
		_button(cursor, MOUSE_BUTTON_LEFT, false)
	_check(targets.size() == count_before, "Empty ring cells and the body itself do not start jumps")
	_check(travel == before, "All map interaction leaves authoritative travel snapshot unchanged")
	canvas.reset_camera()
	canvas.call("zoom_at", Vector2(250, 200), 100.0)
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), 32.0), "Zoom maximum is bounded")
	canvas.call("zoom_at", Vector2(250, 200), 0.001)
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), 0.55), "Zoom minimum is bounded")
	var recenter: Control = canvas.find_child("RecenterMap", true, false)
	cursor = recenter.get_global_rect().get_center()
	canvas.call("pan_by", cursor - canvas.map_to_screen(GRID.normalized(marker_cell)))
	_move(cursor, Vector2.ZERO)
	_button(cursor, MOUSE_BUTTON_LEFT, true)
	_button(cursor, MOUSE_BUTTON_LEFT, false)
	await process_frame
	_check(is_equal_approx(float(canvas.call("get_camera_snapshot").zoom), 1.0), "Gesamtansicht restores fitting zoom")
	_check(Vector2(canvas.call("get_camera_snapshot").pan).is_zero_approx(), "Gesamtansicht restores the system center")
	_check(targets.size() == count_before, "Recenter click cannot start a jump on a marker behind the button")
	_check(canvas.find_child("Future_planet_orbit_sector_03", true, false) == null, "Reserved encounter labels do not compete with active targets")
	canvas.free()
	_finish()

func _finish() -> void:
	print("STAR_MAP_CAMERA checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)
