extends Control
## Schematic artwork. All ship positions and phases are runtime projections.
signal orbit_requested(orbit_id: String)
signal location_selected(location_id: String)
var _location_buttons: Dictionary={}
var _ship_texture: Texture2D
var _travel: Dictionary = {}
var _moon: Button
var _planet: Button
var _body_hits: Dictionary = {}
var _camera_zoom := 1.0
var _camera_pan := Vector2.ZERO
var _drag_button: int = 0
var _drag_position := Vector2.ZERO
var _recenter: Button
var _encounter_labels: Dictionary = {}
const MIN_ZOOM := 0.55
const MAX_ZOOM := 3.5

func _ready() -> void:
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 350), 250)
	set_meta("visual_reference", "https://scplanner.org/#/karte")
	set_meta("image_status", "schematic_runtime_drawing")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ship_texture=load("res://scripts/terrain/frontier_ship_visuals.gd").get_ui_preview_texture({"craft_type":"dropship"})
	_moon = _button("MoonOrbit", "MOND\nMondbasis", "moon_orbit")
	_planet = _button("PlanetOrbit", "PLANET\nZwei Zielorte", "planet_orbit")
	for id in ["moon_orbit", "planet_orbit"]:
		var hit := Button.new()
		hit.name = "MoonBody" if id == "moon_orbit" else "PlanetBody"
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "disabled"]:
			hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
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
	set_travel_snapshot(_travel)

func _button(node_name: String, title: String, orbit: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.custom_minimum_size = Vector2(136, 40)
	button.size = Vector2(136, 40)
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(func(): orbit_requested.emit(orbit))
	button.gui_input.connect(_child_gui_input.bind(button))
	add_child(button)
	return button

func set_travel_snapshot(travel: Dictionary) -> void:
	_travel = travel.duplicate(true)
	if _moon == null:
		return
	var can_jump: bool = String(travel.get("phase", "grounded")) in ["orbit", "stopped"]
	var orbit: String = String(travel.get("orbit_id", ""))
	_moon.disabled = not can_jump or orbit == "moon_orbit"
	_planet.disabled = not can_jump or orbit == "planet_orbit"
	_body_hits.moon_orbit.disabled = _moon.disabled
	_body_hits.planet_orbit.disabled = _planet.disabled
	var bodies: Dictionary = travel.get("bodies", {})
	_moon.text = String(Dictionary(bodies.get("moon", {})).get("name", "Glut I · Mondbasis")).replace(" · ", "\n")
	_planet.text = String(Dictionary(bodies.get("planet", {})).get("name", "Glut")) + "\nPlanet"
	_moon.tooltip_text = "Quantum-Sprung zum Mondorbit starten." if not _moon.disabled else "Mondbasis: Abheben und Landen im Mondorbit."
	_planet.tooltip_text = "Quantum-Sprung zum Planetenorbit starten." if not _planet.disabled else "Im Planetenorbit einen Zielort auswaehlen."
	_sync_encounter_labels()
	_layout_buttons()
	queue_redraw()

func _point(value: Variant) -> Vector2:
	var coordinates: Array = value if value is Array and value.size() >= 2 else [0.18, 0.70]
	return map_to_screen(Vector2(float(coordinates[0]), float(coordinates[1])))

func map_to_screen(point: Vector2) -> Vector2:
	var base := Vector2(50, 32) + point * Vector2(maxf(size.x - 100, 1), maxf(size.y - 150, 1))
	return (base - size * 0.5) * _camera_zoom + size * 0.5 + _camera_pan

func screen_to_map(point: Vector2) -> Vector2:
	var base := (point - size * 0.5 - _camera_pan) / _camera_zoom + size * 0.5
	return (base - Vector2(50, 32)) / Vector2(maxf(size.x - 100, 1), maxf(size.y - 150, 1))

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
	_camera_zoom = 1.0
	_camera_pan = Vector2.ZERO
	_layout_buttons()

func _gui_input(event: InputEvent) -> void:
	if _handle_gui_event(event):
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

func _orbit_point(id: String) -> Vector2:
	var fallback: Array = [0.18, 0.70] if id == "moon_orbit" else [0.80, 0.28]
	return _point(Dictionary(Dictionary(_travel.get("orbits", {})).get(id, {})).get("position", fallback))

func _layout_buttons() -> void:
	_layout_location_buttons()
	if _moon != null:
		var width: float = clampf(size.x * 0.28, 104, 136)
		for button in [_moon, _planet]:
			button.custom_minimum_size = Vector2(width, 40)
			button.size = Vector2(width, 40)
		_moon.position = _orbit_point("moon_orbit") + Vector2(-width * 0.5, 66)
		_planet.position = _orbit_point("planet_orbit") + Vector2(-width * 0.5, 112)
		if not _body_hits.is_empty():
			_body_hits.moon_orbit.position = _orbit_point("moon_orbit") + Vector2(-28, 6)
			_body_hits.moon_orbit.size = Vector2(56, 56)
			_body_hits.planet_orbit.position = _orbit_point("planet_orbit") + Vector2(-37, -2)
			_body_hits.planet_orbit.size = Vector2(74, 70)
		for id in _encounter_labels:
			var label: Label = _encounter_labels[id]
			label.position = map_to_screen(_encounter_position(label.get_meta("slot"))) + Vector2(-60, 10)
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
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.gui_input.connect(_child_gui_input.bind(label))
		label.set_meta("slot", Dictionary(slot).duplicate(true))
		add_child(label)
		_encounter_labels[id] = label
	# Panned labels must never cover the camera's recovery action.
	if _recenter != null:
		move_child(_recenter, get_child_count() - 1)

func _encounter_position(slot: Dictionary) -> Vector2:
	var orbit: Dictionary = Dictionary(Dictionary(_travel.get("orbits", {})).get("planet_orbit", {}))
	var coordinates: Array = orbit.get("position", [0.80, 0.28])
	var center := Vector2(float(coordinates[0]), float(coordinates[1]))
	var angle := deg_to_rad(float(slot.get("angle_degrees", 0)))
	return center + Vector2(cos(angle) * 0.19, sin(angle) * 0.12).rotated(-0.16)

func get_camera_snapshot() -> Dictionary:
	return {"zoom": _camera_zoom, "pan": _camera_pan, "encounter_slots": _encounter_slots().duplicate(true)}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050b14"))
	_draw_grid()
	for i in range(130):
		var point := Vector2(fposmod(float(i * 149 + 37), 997.0) / 997.0 * size.x, fposmod(float(i * 241 + 71), 619.0) / 619.0 * size.y)
		draw_circle(point, 0.65 if i % 4 else 1.1, Color(0.6, 0.72, 0.88, 0.18 if i % 3 else 0.5))
	_world_ellipse(Vector2(0.5, 0.5), Vector2(0.49, 0.28), -0.16, Color(0.27, 0.53, 0.65, 0.19))
	var planet_definition: Dictionary = Dictionary(Dictionary(_travel.get("orbits", {})).get("planet_orbit", {}))
	var planet_coordinates: Array = planet_definition.get("position", [0.80, 0.28])
	var planet_center := Vector2(float(planet_coordinates[0]), float(planet_coordinates[1]))
	_world_ellipse(planet_center, Vector2(0.19, 0.12), -0.16, Color(0.8, 0.55, 0.28, 0.3))
	for slot in _encounter_slots():
		var marker := map_to_screen(_encounter_position(slot))
		draw_circle(marker, 8, Color(0.7, 0.53, 0.31, 0.09))
		draw_circle(marker, 3, Color("8e785e"), false, 1, true)
	var moon := _orbit_point("moon_orbit")
	var planet := _orbit_point("planet_orbit")
	draw_dashed_line(moon, planet, Color(0.4, 0.64, 0.72, 0.25), 1, 5)
	_draw_moon(moon + Vector2(0, 28))
	_draw_planet(planet + Vector2(0, 34))
	draw_string(ThemeDB.fallback_font, Vector2(18, 24), "LOKALES SYSTEM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("83afba"))
	draw_string(ThemeDB.fallback_font, Vector2(18, size.y - 16), "ZIEHEN: MITTEL / RECHTS  ·  MAUSRAD: ZOOM", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("557783"))
	var phase: String = String(_travel.get("phase", "grounded"))
	if phase == "grounded":
		return
	var ship := _point(_travel.get("position", [0.25, 0.62]))
	var direction := Vector2.RIGHT
	var target: String = String(_travel.get("target_orbit_id", ""))
	if phase == "quantum" and not target.is_empty():
		var destination := _orbit_point(target)
		direction = (destination - ship).normalized()
		var origin := _point(_travel.get("origin_position", [0.25, 0.62]))
		draw_line(origin, ship, Color(0.25, 0.9, 0.95, 0.10), 7, true)
		draw_line(origin, ship, Color("78d9e2"), 1.5, true)
		draw_dashed_line(ship, destination, Color(0.6, 0.85, 0.9, 0.55), 1, 6)
		draw_line(ship - direction * 35, ship - direction * 12, Color(0.25, 0.8, 1, 0.4), 7, true)
		draw_line(ship - direction * 28, ship - direction * 12, Color("b4f6ff"), 2, true)
	draw_circle(ship,28,Color(0.3,0.9,0.9,0.1))
	if _ship_texture!=null:
		draw_texture_rect(_ship_texture,Rect2(ship-Vector2(48,32),Vector2(96,64)),false)
	draw_string(ThemeDB.fallback_font,ship+Vector2(47,8),"ENTERMESSER",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e9d5b5"))

func _draw_grid() -> void:
	var center := Vector2(0.5, 0.52)
	var axis_x := Vector2(0.62, -0.065)
	var axis_y := Vector2(0.14, 0.36)
	for i in range(-8, 9):
		var step := float(i) / 8.0
		var tint := Color(0.23, 0.47, 0.58, 0.17 if i % 4 == 0 else 0.07)
		draw_line(map_to_screen(center + axis_x * step - axis_y), map_to_screen(center + axis_x * step + axis_y), tint, 1, true)
		draw_line(map_to_screen(center + axis_y * step - axis_x), map_to_screen(center + axis_y * step + axis_x), tint, 1, true)

func _world_ellipse(center: Vector2, radii: Vector2, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(97):
		var theta := TAU * float(i) / 96.0
		points.append(map_to_screen(center + Vector2(cos(theta) * radii.x, sin(theta) * radii.y).rotated(angle)))
	draw_polyline(points, color, 1, true)

func _ellipse(center: Vector2, radii: Vector2, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(97):
		var theta := TAU * float(i) / 96.0
		points.append(center + Vector2(cos(theta) * radii.x, sin(theta) * radii.y).rotated(angle))
	draw_polyline(points, color, 1, true)

func _draw_moon(center: Vector2) -> void:
	for radius in [29, 23, 18]:
		draw_circle(center, radius, Color(0.23, 0.72, 0.85, 0.055))
	_ellipse(center, Vector2(35, 13), -0.18, Color(0.4, 0.77, 0.85, 0.42))
	draw_circle(center, 12, Color("7ca8b6"))
	draw_circle(center + Vector2(-3, -3), 3, Color("416e82"))
	draw_circle(center + Vector2(4, 3), 2, Color("b2cbd3"))
	draw_rect(Rect2(center + Vector2(-4, 7), Vector2(8, 3)), Color("e8c891"))

func _draw_planet(center: Vector2) -> void:
	for radius in [74, 66, 59]:
		draw_circle(center, radius, Color(0.9, 0.49, 0.2, 0.045))
	_ellipse(center, Vector2(78, 30), -0.18, Color(0.82, 0.56, 0.28, 0.4))
	draw_circle(center, 52, Color("916c49"))
	draw_arc(center + Vector2(-2, -4), 39, 0.2, 2.8, 24, Color("d4a36a"), 7, true)
	draw_arc(center + Vector2(3, 1), 34, 3.3, 5.4, 24, Color("7a654e"), 6, true)
	draw_arc(center, 51, PI * 0.85, PI * 1.65, 36, Color("f2c992"), 1.5, true)

func set_location_snapshot(locations: Dictionary) -> void:
	for id in locations:
		if not _location_buttons.has(id):
			var created:=Button.new()
			created.name="PlanetSite_"+String(id)
			created.custom_minimum_size=Vector2(28,28)
			created.add_theme_font_size_override("font_size",15)
			created.pressed.connect(func(): location_selected.emit(String(id)))
			created.gui_input.connect(_child_gui_input.bind(created))
			add_child(created); _location_buttons[id]=created
		var data: Dictionary=locations[id]
		var button: Button=_location_buttons[id]
		button.text="◆" if bool(data.get("selected",false)) else ("◈" if String(id)=="satellite_crash" else "⌂")
		button.disabled=not bool(data.get("available",false))
		button.tooltip_text=String(data.get("name",id))+"\n"+String(data.get("reason","Ort auswaehlen"))
	_layout_location_buttons()

func location_map_point(id: String) -> Vector2:
	var coordinates: Array=Dictionary(Dictionary(_travel.get("orbits",{})).get("planet_orbit",{})).get("position",[0.80,0.28])
	return Vector2(float(coordinates[0]),float(coordinates[1]))+(Vector2(-0.028,0.075) if id=="satellite_crash" else Vector2(0.028,0.12))

func _layout_location_buttons() -> void:
	for id in _location_buttons:
		var button: Button=_location_buttons[id]
		button.size=Vector2(28,28).max(button.get_combined_minimum_size())
		button.position=map_to_screen(location_map_point(String(id)))-button.size*0.5
