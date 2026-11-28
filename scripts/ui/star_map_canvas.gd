extends Control
## Interactive projection of the strategic hex field and authoritative routes.
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const WORLD = preload("res://scripts/ui/star_map_world_view.gd")
const SYSTEM = preload("res://scripts/core/singleplayer_space_travel_state.gd")
signal body_selected(body_id: String)
## Bleibt als Signal erhalten (Altweg); Klicks auf der Karte senden seit Stufe 1 nur noch orbit_previewed. Erst "Start" der Sternkarte fliegt los.
signal orbit_requested(orbit_id: String, marker_id: String)
## Klick (links oder rechts) auf einen Orbitmarker: das Ziel wird nur vorgemerkt, der Kurs gezeigt.
signal orbit_previewed(orbit_id: String, marker_id: String)
## Rechtsklick ohne Ziehen auf freier Flaeche: ein vorgemerktes Ziel verwerfen.
signal preview_cleared
signal location_selected(location_id: String)
## Doppelklick auf einen Ortsmarker (der erste Klick hat den Ort schon gewaehlt): Ansicht auf den Ort, Kurs setzen. Startet keinen Flug.
signal location_activated(location_id: String)
signal craft_selected(craft_id: String)
signal crafts_box_selected(craft_ids: Array, additive: bool)
var _location_buttons: Dictionary={}
var _locations: Dictionary={}
var _travel: Dictionary = {}
var _selected_ship_id := ""
var _selection_active := false
var _selection_start := Vector2.ZERO
var _selection_end := Vector2.ZERO
var _selection_additive := false
var _body_labels: Dictionary = {}
var _bodies: Dictionary = {}
var _orbits: Dictionary = {}
var _catalog_version := 2
var _orbit_by_hex: Dictionary = {}
var _snapshot_applied := false
var _world
static var _grid_mesh: ArrayMesh
var _camera_zoom := 1.0
var _camera_pan := Vector2.ZERO
var _initial_camera_framed := false
var _warp_arrival := Vector2.ZERO
var _warp_afterglow: float = 0.0
var _drag_button: int = 0
var _drag_position := Vector2.ZERO
var _recenter: Button
var _drag_moved := 0.0
var _preview_points := PackedVector2Array()
var _preview_target := Vector2.ZERO
var _preview_cells := 0
## Zoomstufe nach Doppelklick: Orte eines Koerpers sind dann lesbar benannt.
const FOCUS_ZOOM := 6.0
## Ab dieser Zoomstufe tragen die Orte ihren Namen.
const LABEL_ZOOM := 3.0
const MIN_ZOOM := 0.55
const MAX_ZOOM := 32.0
const MIN_ORBIT_RADIUS_PX := 10.0
const MIN_LOCATION_DIAMETER_PX := 20.0
## Mindestabstand zweier Ortsmarker (Mittelpunkt zu Mittelpunkt); naeher beieinander liegende Marker ruecken auseinander.
const SITE_MIN_SEPARATION_PX := 22.0
const HOME_LABEL := "Heimatbasis"
const HOME_FONT_SIZE := 12
var _home_marker_draws := 0

func _ready() -> void:
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 350), 250)
	set_meta("image_status", "native_hex_projection")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_world = WORLD.new()
	add_child(_world)
	set_process(false)
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
	_catalog_version = int(system.get("version",2))
	_set_bodies(system.bodies)
	_set_orbits(system.orbits)
	_build_grid_mesh()
	set_travel_snapshot(_travel)


func _style_hit_target(button: Button) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

func set_travel_snapshot(travel: Dictionary) -> void:
	if _world == null:
		_travel = travel.duplicate(true)
		return
	if _snapshot_applied and travel == _travel:
		return
	if String(_travel.get("phase", "")) == "quantum" and String(travel.get("phase", "")) == "orbit":
		_warp_arrival = GRID.pair(travel.get("position", []))
		_warp_afterglow = 0.35
		set_process(true)
	_travel = travel.duplicate(true)
	_snapshot_applied = true
	var previous_version := _catalog_version
	_catalog_version = int(travel.get("system_version",travel.get("version",_catalog_version)))
	var bodies: Dictionary = travel.get("bodies", _bodies)
	if bodies != _bodies and bodies.has("sun"):
		_set_bodies(bodies)
	var orbits: Dictionary = travel.get("orbits", _orbits)
	if travel.get("draft",false) == true:
		_set_orbits({})
	elif orbits != _orbits or previous_version != _catalog_version:
		_set_orbits(orbits)
	_world.update_ships(travel)
	_layout_buttons()


func _set_bodies(bodies: Dictionary) -> void:
	_bodies = bodies.duplicate(true)
	_world.update_bodies(bodies)


func _set_orbits(orbits: Dictionary) -> void:
	# Owners validate the catalog. This rejects mismatched display records too.
	_orbits = {}
	_orbit_by_hex.clear()
	var expected := GRID.orbits_for_version(_catalog_version)
	var marker_count := 1 if _catalog_version == 3 else 3
	var valid := not expected.is_empty() and orbits.size() == expected.size()
	var projected_cells := {}
	var seen_cells := {}
	if valid:
		for id: String in expected:
			var orbit: Variant = orbits.get(id)
			var body: Variant = _bodies.get(expected[id])
			if not orbit is Dictionary or not body is Dictionary or orbit.get("body_id") != body.get("id") or body.get("kind","") == "station":
				valid = false
				break
			var markers: Variant = orbit.get("markers")
			if not markers is Array or markers.size() != marker_count:
				valid = false
				break
			for index in marker_count:
				var marker: Variant = markers[index]
				if not marker is Dictionary or marker.get("id") != "orbit_%d" % (index+1) or not _display_cell_valid(marker.get("hex")):
					valid = false
					break
				var cell := GRID.cell_from_record(marker)
				if seen_cells.has(cell):
					valid = false
					break
				seen_cells[cell] = true
				if index == 0:
					projected_cells[cell] = {"orbit_id":id,"marker_id":marker.id}
			if not valid: break
	if valid:
		_orbits = orbits.duplicate(true)
		_orbit_by_hex = projected_cells
	_sync_body_labels()

static func _display_cell_valid(pair: Variant) -> bool:
	if not pair is Array or pair.size() != 2: return false
	for value in pair:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or float(value) != floor(float(value)): return false
	var row := float(pair[1])
	var column: float = float(pair[0]) + floor(row*0.5)
	return row >= 0 and row < GRID.SIZE.y and column >= 0 and column < GRID.SIZE.x

func _sync_body_labels() -> void:
	for id in _body_labels.keys():
		if not _orbits.has(id):
			remove_child(_body_labels[id])
			_body_labels[id].queue_free()
			_body_labels.erase(id)
	var names := {"moon_orbit":"Moon","planet_orbit":"Planet","glut_1a_orbit":"Glut1a","glut_1b_orbit":"Glut1b","polisa_orbit":"Glut2Polisa"}
	for id: String in _orbits:
		if _body_labels.has(id): continue
		var label := Label.new()
		label.name = String(names.get(id,id.validate_node_name())) + "Caption"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size",15)
		label.add_theme_color_override("font_color",Color("b0c8d5"))
		label.add_theme_color_override("font_outline_color", Color("060e18"))
		label.add_theme_constant_override("outline_size", 4)
		add_child(label)
		_body_labels[id] = label

func get_orbit_definitions() -> Dictionary:
	return _orbits.duplicate(true)


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

func focus_body(body_id: String) -> void:
	var body: Dictionary = _bodies.get(body_id, {})
	if body.is_empty(): return
	_initial_camera_framed = true
	_camera_pan = (Vector2(0.5, 0.5) - GRID.pair(body.position)) * _screen_scale()
	_layout_buttons()

## Zoomt auf den Koerper (Doppelklick): Zoomstufe setzen, dann den Koerper in die Bildmitte.
func zoom_to_body(body_id: String, requested_zoom: float = FOCUS_ZOOM) -> void:
	if not _bodies.has(body_id): return
	_camera_zoom = clampf(maxf(requested_zoom, _camera_zoom), MIN_ZOOM, MAX_ZOOM)
	focus_body(body_id)

## Zoomt auf einen Ort: Orte auf einem Koerper zoomen auf diesen Koerper, die uebrigen auf ihren Kartenpunkt.
func zoom_to_location(location_id: String, requested_zoom: float = FOCUS_ZOOM) -> void:
	var body: Dictionary = _body_for_location(location_id)
	if not body.is_empty():
		zoom_to_body(String(body.id), requested_zoom)
		return
	var point := location_map_point(location_id)
	if point == Vector2.ZERO: return
	_camera_zoom = clampf(maxf(requested_zoom, _camera_zoom), MIN_ZOOM, MAX_ZOOM)
	_initial_camera_framed = true
	_camera_pan = (Vector2(0.5, 0.5) - point) * _screen_scale()
	_layout_buttons()

## Kurs-Vorschau (vor dem Start): Linie vom Schiff zum vorgemerkten Ziel, beides in Kartenkoordinaten (0..1).
func set_preview_course(origin: Vector2, destination: Vector2) -> void:
	var control := GRID.route_control(origin, destination)
	var points := PackedVector2Array()
	for index in range(65):
		points.append(GRID.route_point(origin, control, destination, float(index) / 64.0))
	_preview_points = points
	_preview_target = destination
	_preview_cells = GRID.route(origin, control, destination).size()
	queue_redraw()

func clear_preview_course() -> void:
	if _preview_points.is_empty(): return
	_preview_points = PackedVector2Array()
	_preview_cells = 0
	queue_redraw()

func get_preview_course() -> PackedVector2Array:
	return _preview_points

## Anzahl Felder der Vorschau-Strecke (Start- und Zielfeld eingeschlossen).
func get_preview_cell_count() -> int:
	return _preview_cells

func body_at(point: Vector2) -> String:
	for id: String in _bodies:
		var body: Dictionary = _bodies[id]
		if point.distance_to(map_to_screen(GRID.pair(body.position))) <= maxf(12.0, float(body.radius) * _pixels_per_unit()): return id
	return ""

func reset_camera() -> void:
	_initial_camera_framed = true
	_camera_zoom = 1.0
	_camera_pan = Vector2.ZERO
	_layout_buttons()

func _gui_input(event: InputEvent) -> void:
	if _handle_gui_event(event):
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			# Ferner Ort (Schiff im Orbit woanders): sein Marker ist gesperrt und laesst Klicks durch; erst der Doppelklick greift ihn.
			var remote_site := course_site_at(event.position)
			if not remote_site.is_empty():
				zoom_to_location(remote_site)
				location_activated.emit(remote_site)
				accept_event()
				return
		var craft_id := craft_at(event.position)
		if not craft_id.is_empty():
			if event.ctrl_pressed: crafts_box_selected.emit([craft_id], true)
			else: craft_selected.emit(craft_id)
		else:
			# Marker zuerst: Kleine Koerper haben einen Mindest-Klickradius, der bei kleinem Zoom ihre Marker verdecken wuerde.
			var target := orbit_marker_at(event.position)
			if not target.is_empty() and GRID.can_jump_to_marker(_travel, target.orbit_id, target.marker_id):
				orbit_previewed.emit(target.orbit_id, target.marker_id)
				accept_event()
				return
			var body_id := body_at(event.position)
			if not body_id.is_empty():
				body_selected.emit(body_id)
				if event.double_click: zoom_to_body(body_id)
				accept_event()
				return
		_selection_start = event.position
		_selection_end = event.position
		_selection_additive = event.ctrl_pressed
		_selection_active = true
		accept_event()

## Ort, dessen gesperrter Marker (Flugziel in der Ferne, "course_target") an diesem Leinwandpunkt liegt; leer, wenn keiner.
const COURSE_SITE_HINT := "Doppelklick: Kurs setzen"

## Tooltip fuer ferne Orte: ihr Marker ist gesperrt und ignoriert die Maus, darum haengt der Hinweis an der Karte selbst.
func _get_tooltip(at_position: Vector2) -> String:
	var site := course_site_at(at_position)
	if site.is_empty(): return tooltip_text
	return String(Dictionary(_locations.get(site, {})).get("name", site)) + "\n" + COURSE_SITE_HINT

func course_site_at(point: Vector2) -> String:
	var ids: Array = _location_buttons.keys()
	ids.sort()
	for id in ids:
		var button: Button = _location_buttons[id]
		if button.disabled and bool(Dictionary(_locations.get(id, {})).get("course_target", false)) and Rect2(button.position, button.size).has_point(point):
			return String(id)
	return ""

func craft_at(point: Vector2) -> String:
	var routes: Dictionary = _travel.get("routes", {String(_travel.get("craft_id", "")): _travel})
	var closest := ""
	var distance := 144.0
	for id in routes:
		var route: Dictionary = routes[id]
		if String(id).is_empty() or String(route.get("phase", "grounded")) in ["grounded", "surface"]: continue
		var position: Variant = route.get("position", [])
		if not position is Array or position.size() != 2: continue
		var candidate := point.distance_squared_to(map_to_screen(GRID.pair(position)))
		if candidate < distance:
			distance = candidate
			closest = String(id)
	return closest

func set_selected_ship(craft_id: String) -> void:
	_selected_ship_id = craft_id
	queue_redraw()

var _ship_names: Dictionary = {}
var _ship_hidden: Array = []

## Anzeigenamen der Spielerschiffe (craft_id -> Name); "hidden" sind Schiffe ohne Marke (z. B. der Stationsshuttle).
func set_ship_names(names: Dictionary, hidden: Array = []) -> void:
	if names == _ship_names and hidden == _ship_hidden: return
	_ship_names = names.duplicate()
	_ship_hidden = hidden.duplicate()
	queue_redraw()

## Schiffsmarken im Leinwandraum: [{craft_id, name, point, rect, at_site}]. Unterwegs sitzt die Marke an der Schiffsposition,
## an einem Ort (gelandet/am Zielort) leicht versetzt neben dem Ortssymbol, damit dieses klickbar bleibt.
func get_ship_marks() -> Array:
	var marks: Array = []
	if _world == null: return marks
	var routes: Dictionary = _travel.get("routes", {String(_travel.get("craft_id", "")): _travel})
	var ids: Array = routes.keys()
	ids.sort()
	var slots := {}
	for id in ids:
		var key := String(id)
		if key.is_empty() or key in _ship_hidden: continue
		var route: Dictionary = routes[id]
		var phase := String(route.get("phase", "grounded"))
		var point := Vector2.ZERO
		var offset := Vector2(10.0, -10.0)
		var at_site := phase in ["grounded", "surface"]
		var slot_key := "space"
		if at_site:
			slot_key = String(route.get("location_id", ""))
			if slot_key.is_empty(): slot_key = "homebase"
			if _body_for_location(slot_key).is_empty() and not _location_buttons.has(slot_key): continue
			point = _location_anchor(slot_key)
			offset = Vector2(MIN_LOCATION_DIAMETER_PX * 0.5 + 2.0, MIN_LOCATION_DIAMETER_PX * 0.5 + 4.0)
		else:
			var position: Variant = route.get("position", [])
			if not position is Array or position.size() != 2: continue
			point = map_to_screen(GRID.pair(position))
		var slot := int(slots.get(slot_key, 0))
		slots[slot_key] = slot + 1
		var center := point + offset + Vector2(0.0, 16.0 * slot)
		var text := String(_ship_names.get(key, key))
		var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
		marks.append({"craft_id": key, "name": text, "point": center, "at_site": at_site,
			"rect": Rect2(center + Vector2(8.0, -9.0), Vector2(text_size.x + 10.0, 18.0))})
	return marks

func _draw_ship_marks() -> void:
	for mark: Dictionary in get_ship_marks():
		var center: Vector2 = mark.point
		var color := Color("f2c47c") if String(mark.craft_id) == _selected_ship_id else Color("8fe8f2")
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -6), center + Vector2(6, 0), center + Vector2(0, 6), center + Vector2(-6, 0)]), color)
		draw_polyline(PackedVector2Array([center + Vector2(0, -6), center + Vector2(6, 0), center + Vector2(0, 6), center + Vector2(-6, 0), center + Vector2(0, -6)]), Color("060e18"), 1.0)
		var rect: Rect2 = mark.rect
		draw_rect(rect, Color(0.024, 0.055, 0.094, 0.85), true)
		draw_rect(rect, color, false, 1.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 13.0), String(mark.name), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, Color("ebfaff"))


func orbit_marker_at(point: Vector2) -> Dictionary:
	var cell := screen_to_hex(point)
	if _orbit_by_hex.has(cell):
		return _orbit_by_hex[cell]
	if _pixels_per_unit() * GRID.HEX.DEFAULT_RADIUS >= MIN_ORBIT_RADIUS_PX:
		return {}
	var closest: Dictionary = {}
	var closest_distance := INF
	for candidate: Vector2i in _orbit_by_hex:
		if Geometry2D.is_point_in_polygon(point, _orbit_marker_polygon(candidate)):
			var distance := point.distance_squared_to(map_to_screen(GRID.normalized(candidate)))
			if distance < closest_distance:
				closest = _orbit_by_hex[candidate]
				closest_distance = distance
	return closest

func _child_gui_input(event: InputEvent, control: Control) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		for id in _location_buttons:
			if _location_buttons[id] == control:
				zoom_to_location(String(id))
				location_activated.emit(String(id))
				control.accept_event()
				return
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

func cancel_modal_input() -> void:
	_drag_button = 0
	_drag_position = Vector2.ZERO
	_selection_active = false
	_selection_start = Vector2.ZERO
	_selection_end = Vector2.ZERO
	_selection_additive = false
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_drag_button = 0
		_selection_active = false
		return
	if _selection_active:
		if event is InputEventMouseMotion:
			_selection_end = get_global_transform_with_canvas().affine_inverse() * event.global_position
			queue_redraw()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_selection_end = get_global_transform_with_canvas().affine_inverse() * event.global_position
			_selection_active = false
			if _selection_start.distance_to(_selection_end) >= 6.0:
				var box := Rect2(_selection_start, _selection_end - _selection_start).abs()
				var selected: Array = []
				var routes: Dictionary = _travel.get("routes", {String(_travel.get("craft_id", "")): _travel})
				for id in routes:
					var route: Dictionary = routes[id]
					var pos: Variant = route.get("position", [])
					if not String(id).is_empty() and String(route.get("phase", "grounded")) not in ["grounded", "surface"] and pos is Array and pos.size() == 2 and box.has_point(map_to_screen(GRID.pair(pos))): selected.append(String(id))
				crafts_box_selected.emit(selected, _selection_additive)
			queue_redraw()
			get_viewport().set_input_as_handled()
		return
	if _drag_button == 0:
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.global_position
			if Rect2(Vector2.ZERO, size).has_point(point):
				if event.button_index == MOUSE_BUTTON_RIGHT:
					var target := orbit_marker_at(point)
					if not target.is_empty() and GRID.can_jump_to_marker(_travel, target.orbit_id, target.marker_id):
						orbit_previewed.emit(target.orbit_id, target.marker_id)
						get_viewport().set_input_as_handled()
						return
				_drag_button = event.button_index
				_drag_position = point
				_drag_moved = 0.0
				# Intercept before Button receives press and captures GUI mouse focus.
				get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == _drag_button and not event.pressed:
		# Rechtsklick ohne Ziehen auf freier Flaeche verwirft ein vorgemerktes Ziel.
		if _drag_button == MOUSE_BUTTON_RIGHT and _drag_moved < 4.0:
			preview_cleared.emit()
		_drag_button = 0
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var cursor: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.global_position
		_drag_moved += cursor.distance_to(_drag_position)
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
		"moon_orbit": Vector2.DOWN, "planet_orbit": Vector2.DOWN, "polisa_orbit": Vector2.DOWN,
		"glut_1a_orbit": Vector2.UP, "glut_1b_orbit": Vector2(0.8, -0.6),
	}
	for id in _body_labels:
		var body: Dictionary = _bodies[_orbits[id].body_id]
		var center := map_to_screen(GRID.pair(body.position))
		var radius: float = float(body.radius) * _pixels_per_unit()
		var label: Label = _body_labels[id]
		label.text = DISPLAY.body_name(String(body.id), body)
		label.reset_size()
		label.position = center + Vector2(label_directions.get(id,Vector2.LEFT if String(body.id) == "sun" else Vector2.DOWN)) * (radius + 24.0) - label.size * 0.5
	_layout_location_buttons()
	if _recenter != null:
		_recenter.position = Vector2(maxf(size.x - 138, 0), 12)
		_recenter.size = Vector2(124, 30)
	queue_redraw()


func get_camera_snapshot() -> Dictionary:
	return {"zoom": _camera_zoom, "pan": _camera_pan, "orbit_marker_count": _orbit_by_hex.size(),
		"grid_size": GRID.SIZE, "cells": GRID.SIZE.x * GRID.SIZE.y, "grid_alpha": _grid_opacity(),
		"minimum_orbit_radius_px": MIN_ORBIT_RADIUS_PX, "minimum_location_diameter_px": MIN_LOCATION_DIAMETER_PX}


func _grid_opacity() -> float:
	# Fade subpixel/dense lines in overview; preserve the cached mesh and full
	# geometric precision when players zoom in to inspect individual cells.
	var cell_radius_px := _pixels_per_unit() * GRID.HEX.DEFAULT_RADIUS
	return lerpf(0.035, 0.20, smoothstep(2.0, 12.0, cell_radius_px))


## Hintergrundbild der Systemkarte: Die Bildmitte (Leuchten) liegt auf der Sonne und wandert und zoomt mit der Karte.
const BACKGROUND_PATH := "res://art/orbit_backgrounds/sternkarte01.jpg"
## Deckwert des Bildes (1 = unverdunkelt); der Rest wird von der dunklen Grundfarbe gedeckt.
const BACKGROUND_OPACITY := 0.6
## Kantenlaenge des Bildes in Kartenebenen-Einheiten: doppelte Diagonale der Karte, damit es bei kleinstem Zoom alles deckt.
const BACKGROUND_SIDE_UNITS := 680.0
var _background_texture: Texture2D
var _background_tried := false


func get_background_texture() -> Texture2D:
	if _background_tried:
		return _background_texture
	_background_tried = true
	if ResourceLoader.exists(BACKGROUND_PATH):
		_background_texture = load(BACKGROUND_PATH) as Texture2D
	elif FileAccess.file_exists(BACKGROUND_PATH):
		var image := Image.load_from_file(ProjectSettings.globalize_path(BACKGROUND_PATH))
		if image != null and not image.is_empty():
			_background_texture = ImageTexture.create_from_image(image)
	return _background_texture


## Bildflaeche auf dem Bildschirm; Mitte = Bildschirmpunkt der Sonne (Kartenkoordinaten des Zentralsterns).
func get_background_rect() -> Rect2:
	if not _bodies.has("sun"):
		return Rect2()
	var half := Vector2.ONE * BACKGROUND_SIDE_UNITS * 0.5 * _pixels_per_unit()
	return Rect2(map_to_screen(GRID.pair(_bodies.sun.position)) - half, half * 2.0)


func _draw_background() -> void:
	var texture := get_background_texture()
	if texture == null:
		return
	var rect := get_background_rect()
	if rect.size.x >= 1.0:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, BACKGROUND_OPACITY))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("060e18"))
	if _bodies.is_empty():
		return
	_draw_background()
	if _grid_mesh != null:
		var scale_2d := _screen_scale()
		draw_mesh(_grid_mesh, null, Transform2D(Vector2(scale_2d.x, 0), Vector2(0, scale_2d.y), map_to_screen(Vector2.ZERO)), Color(0.25, 0.48, 0.58, _grid_opacity()))
	for i in range(110):
		var point := Vector2(float((i * 149 + 37) % 997) / 997.0 * size.x, float((i * 241 + 71) % 619) / 619.0 * size.y)
		draw_circle(point, 0.55, Color(0.6, 0.72, 0.88, 0.25))
	for body: Dictionary in _bodies.values():
		var center: Vector2 = GRID.pair(body.position)
		var parent_id := String(body.parent_id)
		if not parent_id.is_empty():
			var parent := GRID.pair(_bodies[parent_id].position)
			_draw_orbit(parent, ((center - parent) * GRID.EXTENT).length())
	var sun_center := map_to_screen(GRID.pair(_bodies.sun.position))
	var sun_radius: float = float(_bodies.sun.radius) * _pixels_per_unit()
	for factor in [2.6, 2.1, 1.65, 1.3]:
		draw_circle(sun_center, sun_radius * factor, Color(0.99, 0.48, 0.1, 0.036), true, -1, true)
	_draw_route()
	_draw_preview_course()
	_draw_warp_effect()
	_draw_cutlass_exhaust()
	draw_texture_rect(_world.get_texture(), Rect2(Vector2.ZERO, size), false)
	_draw_orbit_markers()
	var routes: Dictionary = _travel.get("routes", {String(_travel.get("craft_id", "")): _travel})
	for id in routes:
		var route: Dictionary = routes[id]
		if String(id).is_empty() or String(route.get("phase", "grounded")) in ["grounded", "surface"]: continue
		var position: Variant = route.get("position", [])
		if not position is Array or position.size() != 2 or _pixels_per_unit() * 0.84 >= 10.0: continue
		var point := map_to_screen(GRID.pair(position))
		# Screen-space locator supplements the unchanged, correctly scaled ship.
		var direction := (Vector2.from_angle(float(route.get("heading", 0.0))) * Vector2(1.0, WORLD.TILT)).normalized()
		var side := direction.orthogonal()
		draw_circle(point, 7.0, Color("060e18"))
		draw_colored_polygon(PackedVector2Array([point + direction * 6.0, point - direction * 4.0 + side * 4.0, point - direction * 4.0 - side * 4.0]), Color("f2c47c") if String(id) == _selected_ship_id else Color("d4f2f5"))
	if not _selected_ship_id.is_empty() and routes.has(_selected_ship_id):
		var route: Dictionary = routes[_selected_ship_id]
		if String(route.get("phase", "grounded")) not in ["grounded", "surface"] and route.get("position") is Array and route.position.size() == 2:
			draw_arc(map_to_screen(GRID.pair(route.position)), 12.0, 0.0, TAU, 24, Color("f2c47c"), 2.0, true)
	if not _body_labels.has("sun_orbit"):
		draw_string(ThemeDB.fallback_font, sun_center + Vector2(sun_radius + 7, -3), DISPLAY.body_name("sun", _bodies.sun), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffc87c"))
	for id in _location_buttons:
		var body: Dictionary = _body_for_location(id)
		if body.is_empty():
			continue
		var hex: PackedVector2Array = _location_marker_polygon(body)
		var selected: bool = _locations[id].get("selected", false)
		var far_site: bool = bool(_locations[id].get("course_target", false))
		draw_colored_polygon(hex, Color(0.67, 0.5, 0.18, 0.38) if far_site else Color(0.12, 0.57, 0.67, 0.42))
		_outline(hex, Color("e8fff8") if selected else (Color("f2c47c") if far_site else Color("91e4ee")))
		if bool(_locations[id].get("accepted_job", false)):
			var point := _hex_center(hex)
			draw_line(point + Vector2(0, -5), point + Vector2(0, -20), Color("f2c47c"), 2.0)
			draw_string(ThemeDB.fallback_font, point + Vector2(-5, -22), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2c47c"))
	_draw_location_labels()
	_draw_home_marker()
	_draw_ship_marks()
	if _selection_active and _selection_start.distance_to(_selection_end) >= 6.0:
		var box := Rect2(_selection_start, _selection_end - _selection_start).abs()
		draw_rect(box, Color(0.3, 0.85, 0.95, 0.18), true)
		draw_rect(box, Color("77dce9"), false, 1.0)


const LABEL_FONT_SIZE := 12

## Anzeigename eines Ortes (aus dem Anzeige-Katalog, vom Aufrufer im Orts-Snapshot mitgegeben). Nie nur ein Buchstabe.
func _location_label_text(id: String) -> String:
	var shown := String(Dictionary(_locations.get(id, {})).get("name", ""))
	if shown.length() <= 1: shown = DISPLAY.location_name(id)
	return shown

## Mittelpunkt des Ortsmarkers auf der Leinwand: Sechseck auf der Koerperoberflaeche, sonst der Kartenpunkt des Ortes.
func _location_anchor(id: String) -> Vector2:
	var body: Dictionary = _body_for_location(id)
	if not body.is_empty() and _world != null:
		return _hex_center(_location_marker_polygon(body))
	if _site_centers.has(id): return _site_centers[id]
	return map_to_screen(location_map_point(id))

## Namensschilder der Orte (id -> {text, rect, visible}) im Leinwandraum. Ab LABEL_ZOOM sichtbar; die Heimatbasis hat ihr eigenes Schild.
## Das Schild steht rechts vom Marker; liegen zwei Schilder uebereinander, rutscht das spaetere nach unten.
func get_location_labels() -> Dictionary:
	var result := {}
	if _world == null: return result
	var placed: Array[Rect2] = []
	var ids: Array = _location_buttons.keys()
	ids.sort()
	for id in ids:
		if String(id) == "homebase": continue
		var text := _location_label_text(String(id))
		var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
		var plate := Vector2(text_size.x + 10.0, 18.0)
		var anchor := _location_anchor(String(id))
		var rect := Rect2(anchor + Vector2(MIN_LOCATION_DIAMETER_PX * 0.5 + 4.0, -plate.y * 0.5), plate)
		for guard in range(8):
			var clash := false
			for other in placed:
				if rect.intersects(other):
					clash = true
					rect.position.y = other.end.y + 2.0
			if not clash: break
		placed.append(rect)
		result[String(id)] = {"text": text, "rect": rect, "visible": _camera_zoom >= LABEL_ZOOM}
	return result


func _draw_location_labels() -> void:
	var labels := get_location_labels()
	for id in labels:
		var entry: Dictionary = labels[id]
		if not bool(entry.visible): continue
		var rect: Rect2 = entry.rect
		draw_rect(rect, Color(0.024, 0.055, 0.094, 0.82), true)
		var far_site: bool = bool(Dictionary(_locations.get(id, {})).get("course_target", false))
		draw_rect(rect, Color("f2c47c") if far_site else Color("91e4ee"), false, 1.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 13.0), String(entry.text), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, Color("f6dba8") if far_site else Color("ebfaff"))


func _draw_preview_course() -> void:
	if _preview_points.size() < 2: return
	var line := PackedVector2Array()
	for point in _preview_points: line.append(map_to_screen(point))
	var gold := Color("f2c47c")
	draw_polyline(line, Color(gold, 0.85), 2.0, true)
	var end := line[line.size() - 1]
	draw_arc(end, 13.0, 0.0, TAU, 28, gold, 2.0, true)
	var back := line[line.size() - 4]
	var tangent := (end - back).normalized()
	var side := tangent.orthogonal()
	draw_colored_polygon(PackedVector2Array([end + tangent * 6.0, end - tangent * 8.0 + side * 6.0, end - tangent * 8.0 - side * 6.0]), gold)


## Rechteck des Auftragsmarkers ("!" mit Strich ueber dem Ort), im Leinwandraum. Leer, wenn der Ort keinen angenommenen Auftrag hat.
func get_job_marker_rect(id: String) -> Rect2:
	if not bool(Dictionary(_locations.get(id, {})).get("accepted_job", false)):
		return Rect2()
	var body: Dictionary = _body_for_location(id)
	if body.is_empty() or _world == null:
		return Rect2()
	var point := _hex_center(_location_marker_polygon(body))
	return Rect2(point + Vector2(-7, -26), Vector2(14, 24))


## Rechteck des Heimat-Markers (Haus + "Heimatbasis") im Leinwandraum. Er haengt nur am Himmelskoerper der Heimat (surface_location_id
## "homebase"), nicht an Auswahl, Zoom oder Auftrag. Platz: links vom Koerper; trifft das den Auftragsmarker eines Ortes, rechts, dann unten.
func get_home_marker_rect() -> Rect2:
	var body: Dictionary = _body_for_location("homebase")
	if body.is_empty() or _world == null:
		return Rect2()
	var polygon := _location_marker_polygon(body)
	var center := _hex_center(polygon)
	var radius := 0.0
	for point in polygon:
		radius = maxf(radius, point.distance_to(center))
	var text_size := ThemeDB.fallback_font.get_string_size(HOME_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, HOME_FONT_SIZE)
	var plate := Vector2(26.0 + text_size.x + 8.0, 22.0)
	var gap := radius + 8.0
	var candidates: Array[Rect2] = [
		Rect2(center + Vector2(-gap - plate.x, -plate.y * 0.5), plate),
		Rect2(center + Vector2(gap, -plate.y * 0.5), plate),
		Rect2(center + Vector2(-plate.x * 0.5, gap), plate),
	]
	var jobs: Array[Rect2] = []
	for id in _locations:
		var job_rect := get_job_marker_rect(String(id))
		if job_rect.has_area():
			jobs.append(job_rect)
	for candidate in candidates:
		var free := true
		for job_rect in jobs:
			if candidate.intersects(job_rect):
				free = false
		if free and Rect2(Vector2.ZERO, size).encloses(candidate):
			return candidate
	return candidates[0]


func _draw_home_marker() -> void:
	var rect := get_home_marker_rect()
	if not rect.has_area():
		return
	_home_marker_draws += 1
	var gold := Color("f2c47c")
	draw_rect(rect, Color(0.024, 0.055, 0.094, 0.9), true)
	draw_rect(rect, gold, false, 1.5)
	var origin := rect.position + Vector2(5.0, 2.0)
	# Haus: Dach (Dreieck), Wand, Tuer.
	draw_colored_polygon(PackedVector2Array([origin + Vector2(9, 1), origin + Vector2(0, 9), origin + Vector2(18, 9)]), gold)
	draw_rect(Rect2(origin + Vector2(3, 9), Vector2(12, 9)), Color("e8fff8"), true)
	draw_rect(Rect2(origin + Vector2(7, 12), Vector2(4, 6)), Color("0d2935"), true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(26.0, 15.0), HOME_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, HOME_FONT_SIZE, Color("f4f2e9"))


func _draw_orbit_markers() -> void:
	for cell: Vector2i in _orbit_by_hex:
		var target: Dictionary = _orbit_by_hex[cell]
		# Legacy marker IDs are travel aliases of the same body orbit map.
		var occupied: bool = target.orbit_id == _travel.get("orbit_id")
		var destination: bool = String(_travel.get("phase", "")) == "quantum" and target.orbit_id == _travel.get("target_orbit_id")
		var color := Color("f2c47c") if occupied or destination else Color("91e4ee")
		var polygon := _orbit_marker_polygon(cell)
		draw_colored_polygon(polygon, Color("0d2935"))
		_outline(polygon, color)
		var center := map_to_screen(GRID.normalized(cell))
		draw_string(ThemeDB.fallback_font, center + Vector2(-8, 3), "OM", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)


func _orbit_marker_polygon(cell: Vector2i) -> PackedVector2Array:
	var radius := maxf(GRID.HEX.DEFAULT_RADIUS, MIN_ORBIT_RADIUS_PX / _pixels_per_unit())
	return _cell_polygon(cell, radius)


func _location_marker_polygon(body: Dictionary) -> PackedVector2Array:
	var polygon: PackedVector2Array = _world.surface_hex(body)
	var center := _hex_center(polygon)
	var radius := 0.0
	for point in polygon: radius = maxf(radius, point.distance_to(center))
	if radius > 0.0 and radius < MIN_LOCATION_DIAMETER_PX * 0.5:
		for index in polygon.size():
			polygon[index] = center + (polygon[index] - center) * (MIN_LOCATION_DIAMETER_PX * 0.5 / radius)
	return polygon


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


func _cell_polygon(cell: Vector2i, radius: float = GRID.HEX.DEFAULT_RADIUS) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner in GRID.HEX.corners(GRID.HEX.axial_to_plane(Vector2(cell)), radius):
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
	if _locations == locations: return
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
		button.tooltip_text=String(data.get("name",id))+"\n"+(COURSE_SITE_HINT if bool(data.get("course_target",false)) else String(data.get("reason","Ort auswaehlen")))
	_layout_location_buttons()

func _body_for_location(id: String) -> Dictionary:
	if id.is_empty(): return {}
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


## Mittelpunkte der Ortsmarker ohne Koerperflaeche (id -> Leinwandpunkt). Liegen zwei Marker naeher als SITE_MIN_SEPARATION_PX,
## ruecken sie auseinander (Orte auf Koerpern bleiben stehen), damit jeder Marker einzeln anklickbar ist. Reihenfolge nach id, ohne Zufall.
var _site_centers: Dictionary = {}

func _spread_site_centers() -> void:
	var ids: Array = _location_buttons.keys()
	ids.sort()
	var points: Dictionary = {}
	var movable: Dictionary = {}
	for id in ids:
		var is_surface := not _body_for_location(String(id)).is_empty()
		points[id] = map_to_screen(location_map_point(String(id)))
		movable[id] = not is_surface
	for pass_index in range(32):
		var moved := false
		for i in range(ids.size()):
			for j in range(i + 1, ids.size()):
				var a: Variant = ids[i]
				var b: Variant = ids[j]
				if not movable[a] and not movable[b]: continue
				var delta: Vector2 = points[b] - points[a]
				if delta.length() >= SITE_MIN_SEPARATION_PX - 0.01: continue
				var direction := delta.normalized() if delta.length() > 0.001 else Vector2.from_angle(float(i * 7 + j * 3))
				var missing := SITE_MIN_SEPARATION_PX - delta.length()
				if movable[a] and movable[b]:
					points[a] -= direction * missing * 0.5
					points[b] += direction * missing * 0.5
				elif movable[a]:
					points[a] -= direction * missing
				else:
					points[b] += direction * missing
				moved = true
		if not moved: break
	_site_centers.clear()
	for id in ids:
		if movable[id]: _site_centers[String(id)] = points[id]

func _layout_location_buttons() -> void:
	_spread_site_centers()
	for id in _location_buttons:
		var button: Button = _location_buttons[id]
		var is_surface := not _body_for_location(id).is_empty()
		var extent := maxf(MIN_LOCATION_DIAMETER_PX, clampf(_pixels_per_unit() * 1.8, 5.0, 18.0)) if is_surface else 18.0
		button.custom_minimum_size = Vector2.ONE * extent
		button.size = Vector2.ONE * extent
		button.position = (_site_centers[id] if _site_centers.has(id) else map_to_screen(location_map_point(id))) - button.size * 0.5
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if button.disabled else Control.MOUSE_FILTER_STOP
		button.text = "" if is_surface else "◇"
	if _recenter != null:
		move_child(_recenter, get_child_count() - 1)
