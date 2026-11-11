extends Control
## Interactive projection of the strategic hex field and authoritative routes.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const WORLD = preload("res://scripts/ui/star_map_world_view.gd")
const SYSTEM = preload("res://scripts/core/singleplayer_space_travel_state.gd")
signal orbit_requested(orbit_id: String)
signal location_selected(location_id: String)
var _location_buttons: Dictionary={}
var _locations: Dictionary={}
var _travel: Dictionary = {}
var _orbit_buttons: Dictionary = {}
var _bodies: Dictionary = {}
var _orbit_by_hex: Dictionary = {}
var _world
static var _grid_mesh: ArrayMesh
var _body_hits: Dictionary = {}
var _camera_zoom := 1.0
var _camera_pan := Vector2.ZERO
var _initial_camera_framed := false
var _warp_arrival := Vector2.ZERO
var _warp_afterglow: float = 0.0
var _drag_button: int = 0
var _drag_position := Vector2.ZERO
var _recenter: Button
var _encounter_labels: Dictionary = {}
const MIN_ZOOM := 0.55
const MAX_ZOOM := 32.0

func _ready() -> void:
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 350), 250)
	set_meta("image_status", "native_hex_projection")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_world = WORLD.new()
	add_child(_world)
	set_process(false)
	var names := {"moon_orbit": "Moon", "planet_orbit": "Planet",
		"glut_1a_orbit": "Glut1a", "glut_1b_orbit": "Glut1b"}
	for id: String in names:
		_orbit_buttons[id] = _button(names[id] + "Orbit", "", id)
		var hit := Button.new()
		hit.name = names[id] + "Body"
		_style_hit_target(hit)
		hit.pressed.connect(func(): orbit_requested.emit(id))
		add_child(hit)
		hit.gui_input.connect(_child_gui_input.bind(hit))
		_body_hits[id] = hit
	_recenter = Button.new()
	_recenter.name = "RecenterMap"
	_recenter.text = "Gesamtansicht"
	_recenter.custom_minimum_size = Vector2(124, 30)
	_recenter.add_theme_font_size_override("font_size", 12)
	_recenter.pressed.connect(reset_camera)
	_recenter.gui_input.connect(_child_gui_input.bind(_recenter))
	add_child(_recenter)
	resized.connect(_layout_buttons)
	var system: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SYSTEM.DEFINITION_PATH))
	_set_bodies(system.bodies)
	_build_grid_mesh()
	set_travel_snapshot(_travel)


func _style_hit_target(button: Button) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

func _button(node_name: String, title: String, orbit: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.custom_minimum_size = Vector2(64, 25)
	button.size = Vector2(64, 25)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_disabled_color", Color("b0c8d5"))
	button.pressed.connect(func(): orbit_requested.emit(orbit))
	button.gui_input.connect(_child_gui_input.bind(button))
	add_child(button)
	return button

func set_travel_snapshot(travel: Dictionary) -> void:
	if _world == null:
		_travel = travel.duplicate(true)
		return
	if not _travel.is_empty() and travel == _travel and _orbit_buttons.planet_orbit.text != "":
		return
	if String(_travel.get("phase", "")) == "quantum" and String(travel.get("phase", "")) == "orbit":
		_warp_arrival = GRID.pair(travel.get("position", []))
		_warp_afterglow = 0.35
		set_process(true)
	_travel = travel.duplicate(true)
	var bodies: Dictionary = travel.get("bodies", _bodies)
	if bodies != _bodies and bodies.has("sun"):
		_set_bodies(bodies)
	var can_jump: bool = String(travel.get("phase", "grounded")) in ["orbit", "stopped"]
	var orbit: String = String(travel.get("orbit_id", ""))
	for id in _orbit_buttons:
		var button: Button = _orbit_buttons[id]
		var body: Dictionary = _bodies[GRID.ORBITS[id]]
		button.text = String(body.name).get_slice(" · ", 0)
		button.disabled = not can_jump or orbit == id
		button.tooltip_text = String(body.name)
		_body_hits[id].disabled = button.disabled
	_world.update_ships(travel)
	_sync_encounter_labels()
	_layout_buttons()


func _set_bodies(bodies: Dictionary) -> void:
	_bodies = bodies
	_orbit_by_hex.clear()
	for id in GRID.ORBITS:
		var body: Dictionary = bodies[GRID.ORBITS[id]]
		for cell in GRID.ring(GRID.cell_from_record(body), int(body.ring_radius)):
			_orbit_by_hex[cell] = id
	_world.update_bodies(bodies)


func _pixels_per_unit() -> float:
	var available := (size - Vector2(30, 48)).max(Vector2.ONE)
	return minf(available.x / GRID.EXTENT.x, available.y / (GRID.EXTENT.y * WORLD.TILT)) * _camera_zoom


func _screen_scale() -> Vector2:
	return GRID.EXTENT * Vector2(1, WORLD.TILT) * _pixels_per_unit()


func map_to_screen(point: Vector2) -> Vector2:
	return (point - Vector2(0.5, 0.5)) * _screen_scale() + size * 0.5 + _camera_pan


func screen_to_map(point: Vector2) -> Vector2:
	return (point - size * 0.5 - _camera_pan) / _screen_scale() + Vector2(0.5, 0.5)


func screen_to_hex(point: Vector2) -> Vector2i:
	return GRID.cell_at(screen_to_map(point))


func zoom_at(cursor: Vector2, requested_zoom: float) -> void:
	if not is_finite(requested_zoom) or requested_zoom <= 0:
		return
	var fixed_point := screen_to_map(cursor)
	_camera_zoom = clampf(requested_zoom, MIN_ZOOM, MAX_ZOOM)
	_camera_pan += cursor - map_to_screen(fixed_point)
	_layout_buttons()

func pan_by(movement: Vector2) -> void:
	if is_finite(movement.x) and is_finite(movement.y):
		_camera_pan += movement
		_layout_buttons()

func reset_camera() -> void:
	_initial_camera_framed = true
	_camera_zoom = 1.0
	_camera_pan = Vector2.ZERO
	_layout_buttons()

func _gui_input(event: InputEvent) -> void:
	if _handle_gui_event(event):
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var id := String(_orbit_by_hex.get(screen_to_hex(event.position), ""))
		if not id.is_empty() and not _orbit_buttons[id].disabled:
			orbit_requested.emit(id)
			accept_event()

func _child_gui_input(event: InputEvent, control: Control) -> void:
	if _handle_gui_event(event):
		control.accept_event()

func _handle_gui_event(event: InputEvent) -> bool:
	if not event is InputEventMouseButton or not event.pressed:
		return false
	var cursor: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.global_position
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		zoom_at(cursor, _camera_zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15))
		return true
	return false

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_drag_button = 0
		return
	if _drag_button == 0:
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.global_position
			if Rect2(Vector2.ZERO, size).has_point(point):
				_drag_button = event.button_index
				_drag_position = point
				# Intercept before Button receives press and captures GUI mouse focus.
				get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == _drag_button and not event.pressed:
		_drag_button = 0
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var cursor: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.global_position
		pan_by(cursor - _drag_position)
		_drag_position = cursor
		get_viewport().set_input_as_handled()

func _layout_buttons() -> void:
	if _world == null or _bodies.is_empty():
		return
	if not _initial_camera_framed and size.x >= 350 and size.y >= 250:
		_initial_camera_framed = true
		_camera_zoom = 1.45
		_camera_pan = (Vector2(0.5, 0.5) - Vector2(0.57, 0.5)) * _screen_scale()
	_world.update_camera(size, _pixels_per_unit(), screen_to_map(size * 0.5) * GRID.EXTENT)
	var label_directions := {
		"moon_orbit": Vector2.DOWN, "planet_orbit": Vector2.DOWN,
		"glut_1a_orbit": Vector2.UP, "glut_1b_orbit": Vector2(0.8, -0.6),
	}
	for id in _orbit_buttons:
		var body: Dictionary = _bodies[GRID.ORBITS[id]]
		var center := map_to_screen(GRID.pair(body.position))
		var radius: float = float(body.radius) * _pixels_per_unit()
		var button: Button = _orbit_buttons[id]
		button.position = center + Vector2(label_directions[id]) * (radius + 20.0) - button.size * 0.5
		var hit: Button = _body_hits[id]
		hit.size = Vector2.ONE * maxf(16.0, radius * 2.0)
		hit.position = center - hit.size * 0.5
	_layout_location_buttons()
	for id in _encounter_labels:
		var label: Label = _encounter_labels[id]
		label.position = map_to_screen(_encounter_position(label.get_meta("slot"))) + Vector2(-60, 10)
		label.visible = _camera_zoom >= 4.0
	if _recenter != null:
		_recenter.position = Vector2(maxf(size.x - 138, 0), 12)
		_recenter.size = Vector2(124, 30)
	queue_redraw()


func _encounter_slots() -> Array:
	return Array(Dictionary(Dictionary(_travel.get("orbits", {})).get("planet_orbit", {})).get("encounter_slots", []))

func _sync_encounter_labels() -> void:
	for slot in _encounter_slots():
		var id: String = String(slot.get("id", ""))
		if id.is_empty() or _encounter_labels.has(id):
			continue
		var label := Label.new()
		label.name = "Future_" + id.validate_node_name()
		label.text = String(slot.get("name", "Orbitbereich")) + "\nspäter"
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("78949e"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(120, 32)
		label.tooltip_text = "Zukünftiger Orbitbereich · noch nicht verfügbar"
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.gui_input.connect(_child_gui_input.bind(label))
		label.set_meta("slot", Dictionary(slot).duplicate(true))
		add_child(label)
		_encounter_labels[id] = label
	# Panned labels must never cover the camera's recovery action.
	if _recenter != null:
		move_child(_recenter, get_child_count() - 1)

func _encounter_position(slot: Dictionary) -> Vector2:
	var planet: Dictionary = _bodies.planet
	var angle := deg_to_rad(float(slot.get("angle_degrees", 0)))
	return GRID.pair(planet.position) + Vector2.from_angle(angle) * (float(planet.ring_radius) + 3.0) / GRID.EXTENT


func get_camera_snapshot() -> Dictionary:
	return {"zoom": _camera_zoom, "pan": _camera_pan, "encounter_slots": _encounter_slots().duplicate(true),
		"grid_size": GRID.SIZE, "cells": GRID.SIZE.x * GRID.SIZE.y}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("060e18"))
	if _bodies.is_empty():
		return
	if _grid_mesh != null:
		var scale_2d := _screen_scale()
		draw_mesh(_grid_mesh, null, Transform2D(Vector2(scale_2d.x, 0), Vector2(0, scale_2d.y), map_to_screen(Vector2.ZERO)), Color(0.25, 0.48, 0.58, 0.25))
	for i in range(110):
		var point := Vector2(float((i * 149 + 37) % 997) / 997.0 * size.x, float((i * 241 + 71) % 619) / 619.0 * size.y)
		draw_circle(point, 0.55, Color(0.6, 0.72, 0.88, 0.25))
	for body: Dictionary in _bodies.values():
		var center: Vector2 = GRID.pair(body.position)
		var parent_id := String(body.parent_id)
		if not parent_id.is_empty():
			var parent := GRID.pair(_bodies[parent_id].position)
			_draw_orbit(parent, ((center - parent) * GRID.EXTENT).length())
		var ring_radius := int(body.ring_radius)
		if ring_radius > 0:
			for cell in GRID.ring(GRID.cell_from_record(body), ring_radius):
				var polygon := _cell_polygon(cell)
				draw_colored_polygon(polygon, Color(0.18, 0.70, 0.76, 0.13))
				_outline(polygon, Color(0.27, 0.72, 0.80, 0.65))
	var sun_center := map_to_screen(GRID.pair(_bodies.sun.position))
	var sun_radius: float = float(_bodies.sun.radius) * _pixels_per_unit()
	for factor in [2.6, 2.1, 1.65, 1.3]:
		draw_circle(sun_center, sun_radius * factor, Color(0.99, 0.48, 0.1, 0.036), true, -1, true)
	_draw_route()
	_draw_warp_effect()
	_draw_cutlass_exhaust()
	draw_texture_rect(_world.get_texture(), Rect2(Vector2.ZERO, size), false)
	draw_string(ThemeDB.fallback_font, sun_center + Vector2(sun_radius + 7, -3), "Glut", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffc87c"))
	for id in _location_buttons:
		var body: Dictionary = _body_for_location(id)
		if body.is_empty():
			continue
		var hex: PackedVector2Array = _world.surface_hex(body)
		var selected: bool = _locations[id].get("selected", false)
		draw_colored_polygon(hex, Color(0.12, 0.57, 0.67, 0.42))
		_outline(hex, Color("e8fff8") if selected else Color("91e4ee"))
		if _camera_zoom >= 3.0:
			var letter: String = {"satellite_crash": "A", "trade_outpost": "B", "fortified_outpost": "C"}.get(id, "")
			draw_string(ThemeDB.fallback_font, _hex_center(hex) + Vector2(-4, 4), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ebfaff"))
	for slot in _encounter_slots():
		if _camera_zoom >= 4.0:
			draw_circle(map_to_screen(_encounter_position(slot)), 2.0, Color("8e785e"), false, 1.0, true)


func _process(delta: float) -> void:
	_warp_afterglow = maxf(0.0, _warp_afterglow - delta)
	queue_redraw()
	if _warp_afterglow == 0.0:
		set_process(false)


func _draw_warp_effect() -> void:
	if _warp_afterglow > 0.0:
		var fade := _warp_afterglow / 0.35
		_draw_warp_gate(_warp_arrival, fade, fade)
	if String(_travel.get("phase", "")) != "quantum":
		return
	var progress := float(_travel.get("progress", 0.0))
	if progress < 0.28:
		var opening := smoothstep(0.0, 0.13, progress)
		var visibility := 1.0 - smoothstep(0.12, 0.28, progress)
		_draw_warp_gate(GRID.pair(_travel.get("origin_position", [])), opening, visibility)
	elif progress > 0.77:
		var opening := smoothstep(0.77, 0.98, progress)
		_draw_warp_gate(GRID.pair(_travel.get("route_destination", [])), opening, opening)


func _draw_warp_gate(point: Vector2, opening: float, opacity: float) -> void:
	var center := map_to_screen(point)
	var diameter := clampf(_pixels_per_unit() * 7.0, 52.0, 114.0)
	var radius := lerpf(5.0, diameter * 0.5, opening)
	for index in range(4):
		var glow_radius := radius * (1.14 - float(index) * 0.19)
		draw_circle(center, glow_radius, Color(0.24, 0.22, 0.93, 0.045 * opacity), true, -1.0, true)
	draw_arc(center, radius * 0.86, 0.0, TAU, 72, Color(0.19, 0.80, 1.0, 0.34 * opacity), 4.0, true)
	draw_arc(center, radius * 0.86, 0.0, TAU, 72, Color(0.62, 0.96, 1.0, 0.88 * opacity), 1.5, true)
	var twist := opening * 2.7
	draw_arc(center, radius, twist, twist + PI * 1.37, 48, Color(0.88, 0.34, 1.0, 0.76 * opacity), 2.4, true)
	draw_arc(center, radius * 1.08, twist + PI, twist + PI * 1.82, 32, Color(1.0, 0.66, 0.31, 0.62 * opacity), 1.7, true)


func _draw_cutlass_exhaust() -> void:
	var routes: Dictionary = _travel.get("routes", {String(_travel.get("craft_id", "")): _travel})
	for id in routes:
		var route: Dictionary = routes[id]
		if id.is_empty() or String(route.get("phase", "")) not in ["quantum", "approach"]:
			continue
		var tangent := (Vector2.from_angle(float(route.get("heading", 0.0))) * Vector2(1.0, WORLD.TILT)).normalized()
		var center := map_to_screen(GRID.pair(route.get("position", [])))
		var emitter := center - tangent * maxf(1.5, _pixels_per_unit() * 0.32)
		var length_px := clampf(_pixels_per_unit() * 2.1, 14.0, 78.0)
		var width := clampf(_pixels_per_unit() * 0.14, 1.5, 5.0)
		var side := tangent.orthogonal() * width
		var tail := emitter - tangent * length_px
		draw_polygon(PackedVector2Array([emitter + side, tail, emitter - side]),
			PackedColorArray([Color(0.30, 0.66, 1.0, 0.77), Color(0.25, 0.45, 0.99, 0.0), Color(0.30, 0.66, 1.0, 0.77)]))
		draw_line(emitter, emitter.lerp(tail, 0.44), Color(0.75, 0.93, 1.0, 0.87), maxf(1.0, width * 0.53), true)


func _draw_route() -> void:
	if String(_travel.get("phase", "")) != "quantum":
		return
	var cells: Array = _travel.get("route_hexes", [])
	if cells.size() < 2:
		return
	var origin := GRID.pair(_travel.get("origin_position", []))
	var control := GRID.pair(_travel.get("route_control", []))
	var destination := GRID.pair(_travel.get("route_destination", []))
	var guide := PackedVector2Array()
	for index in range(65):
		guide.append(map_to_screen(GRID.route_point(origin, control, destination, float(index) / 64.0)))
	draw_polyline(guide, Color(0.47, 0.86, 0.92, 0.72), 1.3, true)
	var cell: Vector2i = _travel.get("hex", cells[0])
	_outline(_cell_polygon(cell), Color("b6f6ff"))


func _draw_orbit(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(193):
		var angle := TAU * float(i) / 192.0
		points.append(map_to_screen(center + Vector2.from_angle(angle) * radius / GRID.EXTENT))
	draw_polyline(points, Color(0.47, 0.68, 0.78, 0.30), 1.0, true)


func _cell_polygon(cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner in GRID.HEX.corners(GRID.HEX.axial_to_plane(Vector2(cell))):
		points.append(map_to_screen(corner / GRID.EXTENT))
	return points


func _outline(points: PackedVector2Array, color: Color) -> void:
	var outline := points.duplicate()
	outline.append(outline[0])
	draw_polyline(outline, color, 1.0, true)


func _build_grid_mesh() -> void:
	if _grid_mesh != null:
		return
	var vertices := PackedVector3Array()
	var corners: PackedVector2Array = GRID.HEX.corners()
	for row in GRID.SIZE.y:
		for col in GRID.SIZE.x:
			var cell: Vector2i = GRID.from_offset(Vector2i(col, row))
			var center: Vector2 = GRID.HEX.axial_to_plane(Vector2(cell))
			for edge in range(6):
				if edge >= 3 and GRID.contains(cell + GRID.HEX.DIRECTIONS[(5 - edge + 6) % 6]):
					continue
				var a: Vector2 = (center + corners[edge]) / GRID.EXTENT
				var b: Vector2 = (center + corners[(edge + 1) % 6]) / GRID.EXTENT
				vertices.append(Vector3(a.x, a.y, 0))
				vertices.append(Vector3(b.x, b.y, 0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	_grid_mesh = ArrayMesh.new()
	_grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)


func set_location_snapshot(locations: Dictionary) -> void:
	_locations = locations.duplicate(true)
	for id in _location_buttons.keys():
		if not locations.has(id):
			_location_buttons[id].queue_free()
			_location_buttons.erase(id)
	for id in locations:
		if not _location_buttons.has(id):
			var created:=Button.new()
			created.name="PlanetSite_"+String(id)
			created.custom_minimum_size = Vector2(18,18)
			_style_hit_target(created)
			created.pressed.connect(func(): location_selected.emit(String(id)))
			created.gui_input.connect(_child_gui_input.bind(created))
			add_child(created); _location_buttons[id]=created
		var data: Dictionary=locations[id]
		var button: Button=_location_buttons[id]
		button.text="◆" if bool(data.get("selected",false)) else ("◈" if String(id)=="satellite_crash" else "⌂")
		button.disabled=not bool(data.get("available",false))
		button.tooltip_text=String(data.get("name",id))+"\n"+String(data.get("reason","Ort auswaehlen"))
	_layout_location_buttons()

func _body_for_location(id: String) -> Dictionary:
	for body: Dictionary in _bodies.values():
		if String(body.surface_location_id) == id:
			return body
	return {}


func _hex_center(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for point in points:
		center += point
	return center / points.size()


func location_map_point(id: String) -> Vector2:
	var body := _body_for_location(id)
	if not body.is_empty() and _world != null:
		return screen_to_map(_hex_center(_world.surface_hex(body)))
	var planet: Vector2 = GRID.pair(_bodies.planet.position)
	if id == "distress_orbit":
		return planet + Vector2(7, 5) / GRID.EXTENT
	var authored: Variant = Dictionary(_locations.get(id, {})).get("region_position", [])
	if authored is Array and authored.size() == 2:
		return planet + (GRID.pair(authored) - Vector2(0.5, 0.5)) * 24.0 / GRID.EXTENT
	return Vector2.ZERO


func _layout_location_buttons() -> void:
	for id in _location_buttons:
		var button: Button = _location_buttons[id]
		button.size = Vector2(18, 18)
		button.position = map_to_screen(location_map_point(id)) - button.size * 0.5
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if button.disabled else Control.MOUSE_FILTER_STOP
		button.text = "◇" if _body_for_location(id).is_empty() else ""
	if _recenter != null:
		move_child(_recenter, get_child_count() - 1)
