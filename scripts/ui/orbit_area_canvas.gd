extends Control
## UNWIRED read-only projection. Requests are intents, never movement authority.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const DOCK = preload("res://scripts/mission/polisa_station_dock_layout.gd")
const TILT := 0.72
const MIN_ZOOM := 0.6
const MAX_ZOOM := 48.0
const MAP_CENTER := Vector2(256.0, 110.8512516844)
signal move_requested(craft_id: String, target_hex: Vector2i)
var _snapshot: Dictionary = {}
var _actors: Dictionary = {}
var _selected := ""
var _layout: Dictionary = {}
var _body_visual: Dictionary = {}
var _body_mask: Dictionary = {}
var _zoom := 1.0
var _pan := Vector2.ZERO
var _dragging := false
var _static_layer: Control
var _dock_cache: Dictionary = {}
var _dock_projection: Dictionary = {}
var _dock_visible := false
## Zuletzt angeklickter Zielpunkt (nur Anzeige): die Kurslinie vom Schiff dorthin wird gezeichnet, bis das Schiff ankommt.
var _course_target := Vector2i.ZERO
var _course_active := false
const COURSE_ARRIVAL_DISTANCE := 1.5
## Hintergrundbild fuer alle Orbit-Karten. Die Datei ist so gedreht abgelegt, dass der Planet des Bildes
## an der oberen Kante liegt, wie der Planetenbogen der Karte (orbit_approach_layout: Planet oben, Eintrittsband unten).
const BACKGROUND_PATH := "res://art/orbit_backgrounds/orbit_map01.jpg"
const BACKGROUND_PLANET_EDGE := "top"
## Deckwert des Bildes (1 = unverdunkelt); der Rest wird von der dunklen Grundfarbe gedeckt.
const BACKGROUND_OPACITY := 0.55
const MAP_PLANE_SIZE := Vector2(512.0, 221.7025033689)
var _background_texture: Texture2D
var _background_tried := false

func get_background_texture() -> Texture2D:
	if _background_tried: return _background_texture
	_background_tried = true
	if ResourceLoader.exists(BACKGROUND_PATH):
		_background_texture = load(BACKGROUND_PATH) as Texture2D
	elif FileAccess.file_exists(BACKGROUND_PATH):
		var image := Image.load_from_file(ProjectSettings.globalize_path(BACKGROUND_PATH))
		if image != null and not image.is_empty(): _background_texture = ImageTexture.create_from_image(image)
	return _background_texture

## Bildfuellend ueber die Kartenflaeche, Seitenverhaeltnis gehalten (beschneiden, oben verankert, damit der Planet am Planetenrand bleibt).
func _draw_background() -> void:
	var texture := get_background_texture()
	if texture == null or texture.get_width() <= 0: return
	var top_left := plane_to_screen(Vector2.ZERO)
	var bottom_right := plane_to_screen(MAP_PLANE_SIZE)
	var target := Rect2(top_left, bottom_right - top_left)
	if target.size.x < 1.0 or target.size.y < 1.0: return
	var tex_size := Vector2(texture.get_width(), texture.get_height())
	var source_size := tex_size
	if target.size.x / target.size.y > tex_size.x / tex_size.y: source_size.y = tex_size.x * target.size.y / target.size.x
	else: source_size.x = tex_size.y * target.size.x / target.size.y
	var source := Rect2(Vector2((tex_size.x - source_size.x) * 0.5, 0.0), source_size)
	_static_layer.draw_texture_rect_region(texture, target, source, Color(1, 1, 1, BACKGROUND_OPACITY))

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(350,250)
	set_process(false)
	_static_layer = Control.new()
	_static_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_static_layer.show_behind_parent = true
	add_child(_static_layer)
	_static_layer.draw.connect(_draw_static)
	resized.connect(_camera_changed)
	_camera_changed()

func set_projection(snapshot: Dictionary, selected_craft_id: String = "", body_visual: Dictionary = {}) -> void:
	if snapshot == _snapshot and selected_craft_id == _selected and body_visual == _body_visual: return
	_snapshot = snapshot.duplicate(true)
	var static_changed: bool = body_visual != _body_visual
	_body_visual = body_visual.duplicate(true)
	_actors.clear()
	_selected = ""
	var area_id: String = str(snapshot.get("space_area_id", ""))
	if snapshot.get("ok") == true and area_id.begins_with("orbit_approach:"):
		var layout: Dictionary = _layout if _layout.get("body_map_id") == area_id else LAYOUT.build(area_id.trim_prefix("orbit_approach:").uri_decode())
		if layout.get("ok",false) and layout.body_map_id == area_id:
			if _layout.get("body_map_id") != area_id:
				_layout = layout
				_body_mask.clear()
				for offset: Vector2i in layout.body_cells: _body_mask[GRID.from_offset(offset)] = true
				static_changed = true
			if snapshot.get("actors") is Array:
				for actor in _snapshot.actors:
					if not actor is Dictionary or not actor.get("flight") is Dictionary: continue
					var id: String = str(actor.get("craft_id", ""))
					var flight: Dictionary = actor.flight
					if id.is_empty() or _actors.has(id) or flight.get("craft_id") != id or flight.get("coordinate_frame") != "local" or flight.get("space_area_id") != area_id or flight.get("motion_mode") != "tactical": continue
					if not _finite_vector(flight.get("position_plane")) or not _finite_number(flight.get("heading_rad",0.0)): continue
					_actors[id] = actor
			if _actors.has(selected_craft_id): _selected = selected_craft_id
	if snapshot.get("ok") != true or _layout.get("body_map_id") != area_id:
		static_changed = static_changed or not _layout.is_empty()
		_layout = {}
		_body_mask.clear()
	static_changed = _sync_dock_projection(_snapshot) or static_changed
	if static_changed and is_instance_valid(_static_layer): _static_layer.queue_redraw()
	queue_redraw()

## Read-only target display. Never derives a target from body/area alone.
func _sync_dock_projection(snapshot: Dictionary) -> bool:
	var was_visible := _dock_visible
	var targets: Variant = snapshot.get("dock_targets")
	var expected := {"target_id":"polisa_station_dock","revision":DOCK.REVISION}
	_dock_visible = snapshot.get("ok") == true and _layout.get("body_map_id") == DOCK.AREA_ID and snapshot.get("space_area_id") == DOCK.AREA_ID and targets is Array and targets.size() == 1 and targets[0] is Dictionary and targets[0] == expected
	if not _dock_visible:
		_dock_projection = {}
		return was_visible
	var key := DOCK.AREA_ID + ":" + DOCK.REVISION
	if not _dock_cache.has(key):
		var descriptor: Dictionary = DOCK.build()
		if not descriptor.get("ok",false):
			_dock_cache[key] = {"ok":false}
		else:
			_dock_cache[key] = _build_dock_draw_projection(descriptor)
	if not _dock_cache[key].get("ok",false):
		_dock_visible = false
		_dock_projection = {}
		return was_visible
	_dock_projection = _dock_cache[key]
	return not was_visible

func _build_dock_draw_projection(descriptor: Dictionary) -> Dictionary:
	var block: Rect2i = descriptor.station_block
	var hull_points := PackedVector2Array()
	# Offset-row parity shifts alternate rows. Use the actual perimeter,
	# not just four corner cells, so the hull encloses both row parities.
	var perimeter: Array[Vector2i] = []
	for x in range(block.position.x,block.end.x):
		perimeter.append(Vector2i(x,block.position.y))
		perimeter.append(Vector2i(x,block.end.y-1))
	for y in range(block.position.y+1,block.end.y-1):
		perimeter.append(Vector2i(block.position.x,y))
		perimeter.append(Vector2i(block.end.x-1,y))
	for offset: Vector2i in perimeter:
		# Descriptor cells are offsets. Flight/Hex geometry is axial.
		var axial := GRID.from_offset(offset)
		hull_points.append_array(HEX.corners(HEX.axial_to_plane(Vector2(axial))))
	var station_polygon := Geometry2D.convex_hull(hull_points)
	if station_polygon.size() > 1 and station_polygon[0] == station_polygon[-1]: station_polygon.resize(station_polygon.size()-1)
	var gate_axial := GRID.from_offset(descriptor.dock_gate)
	return {"ok":true,"descriptor":descriptor,"station_polygon_plane":station_polygon,
		"anchor_plane":HEX.axial_to_plane(Vector2(GRID.from_offset(descriptor.station_anchor))),
		"gate_axial":gate_axial,"gate_polygon_plane":HEX.corners(HEX.axial_to_plane(Vector2(gate_axial)))}

func get_projection() -> Dictionary:
	return _snapshot.duplicate(true)

func get_selected_craft_id() -> String:
	return _selected

func _scale() -> float:
	return maxf(0.001, minf(maxf(1.0,size.x-32.0)/512.0, maxf(1.0,size.y-48.0)/(256.0*HEX.SQRT_THREE*0.5*TILT)) * _zoom)

func plane_to_screen(point: Vector2) -> Vector2:
	return (point - MAP_CENTER) * Vector2(1,TILT) * _scale() + size * 0.5 + _pan

func screen_to_plane(point: Vector2) -> Vector2:
	return (point - size * 0.5 - _pan) / (_scale() * Vector2(1,TILT)) + MAP_CENTER

func hex_to_screen(cell: Vector2i) -> Vector2:
	return plane_to_screen(HEX.axial_to_plane(Vector2(cell)))

func screen_to_hex(point: Vector2) -> Vector2i:
	return HEX.round_axial(HEX.plane_to_axial(screen_to_plane(point)))

func zoom_at(cursor: Vector2, requested_zoom: float) -> void:
	if not _finite_vector(cursor) or not _finite_number(requested_zoom) or requested_zoom <= 0: return
	var fixed := screen_to_plane(cursor)
	_zoom = clampf(requested_zoom,MIN_ZOOM,MAX_ZOOM)
	_pan += cursor - plane_to_screen(fixed)
	_camera_changed()

func pan_by(movement: Vector2) -> void:
	if not _finite_vector(movement): return
	_pan += movement
	_camera_changed()

func reset_camera() -> void:
	_zoom = 1.0
	_pan = Vector2.ZERO
	_camera_changed()

func recenter_selected() -> bool:
	if not _actors.has(_selected): return false
	_pan = Vector2.ZERO
	_pan = size * 0.5 - plane_to_screen(_actors[_selected].flight.position_plane)
	_camera_changed()
	return true

func request_move_at(point: Vector2) -> bool:
	if _selected.is_empty() or not _actors.has(_selected) or _layout.is_empty() or not _finite_vector(point): return false
	var target := screen_to_hex(point)
	if _dock_visible and Rect2i(_dock_projection.descriptor.station_block).has_point(GRID.to_offset(target)): return false
	if not AREA.contains(target,{"coordinate_frame":"local","space_area_id":_snapshot.space_area_id}) or _body_mask.has(target): return false
	_course_target = target
	_course_active = true
	move_requested.emit(_selected,target)
	queue_redraw()
	return true

## Kurslinie vom gewaehlten Schiff zum letzten Klickpunkt (Bildschirmkoordinaten); leer, wenn kein Kurs offen ist.
func get_course_line() -> PackedVector2Array:
	if not _course_active or not _actors.has(_selected): return PackedVector2Array()
	var from: Vector2 = _actors[_selected].flight.position_plane
	var to := HEX.axial_to_plane(Vector2(_course_target))
	if from.distance_to(to) <= COURSE_ARRIVAL_DISTANCE: return PackedVector2Array()
	return PackedVector2Array([plane_to_screen(from), plane_to_screen(to)])

## Viewport-only offset ranges; adaptive stride caps work even when zoomed out.
func get_visible_grid_projection() -> Dictionary:
	var first := Vector2i(512,256)
	var last := Vector2i.ZERO
	for point in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
		var offset := GRID.to_offset(screen_to_hex(point))
		first = first.min(offset)
		last = last.max(offset)
	first = (first-Vector2i(2,2)).clamp(Vector2i.ZERO,Vector2i(512,256))
	last = (last+Vector2i(3,3)).clamp(Vector2i.ZERO,Vector2i(512,256))
	var stride := 1
	while _scale()*stride < 9.0 or ceili(float(maxi(0,last.x-first.x))/stride)*ceili(float(maxi(0,last.y-first.y))/stride) > 5000: stride *= 2
	return {"offset_bounds":Rect2i(first,(last-first).max(Vector2i.ZERO)),"stride":stride}

func _polygon(cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner in HEX.corners(HEX.axial_to_plane(Vector2(cell))): points.append(plane_to_screen(corner))
	return points

func _outline(points: PackedVector2Array, color: Color, target: Control = self) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	target.draw_polyline(closed,color,1.0,true)

func _camera_changed() -> void:
	if is_instance_valid(_static_layer): _static_layer.queue_redraw()
	queue_redraw()

func _draw_static() -> void:
	_static_layer.draw_rect(Rect2(Vector2.ZERO,size),Color("060e18"))
	if _layout.is_empty(): return
	_draw_background()
	var body_color := Color("866349")
	if _body_visual.get("color") is Color: body_color = _body_visual.color
	var upper_center := hex_to_screen(GRID.from_offset(Vector2i(256, 0)))
	var planet_radius := 90.0 * _scale()
	var has_background := get_background_texture() != null
	if not has_background: _static_layer.draw_circle(upper_center - Vector2(0, planet_radius + 3.0), planet_radius, Color(body_color, 0.45))
	_static_layer.draw_string(ThemeDB.fallback_font, upper_center + Vector2(-30, -8), "Planet", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c4d7de"))
	var lower_left := hex_to_screen(GRID.from_offset(Vector2i(0, 255)))
	var lower_right := hex_to_screen(GRID.from_offset(Vector2i(511, 255)))
	_static_layer.draw_line(lower_left, lower_right, Color("6ac8ee"), 2.0, true)
	_static_layer.draw_string(ThemeDB.fallback_font, (lower_left + lower_right) * 0.5 + Vector2(-60, 17), "Weltraum / System", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("8ed7f1"))
	var grid := get_visible_grid_projection()
	var bounds: Rect2i = grid.offset_bounds
	for y in range(bounds.position.y,bounds.end.y,grid.stride):
		for x in range(bounds.position.x,bounds.end.x,grid.stride):
			var cell := GRID.from_offset(Vector2i(x,y))
			if grid.stride == 1: _outline(_polygon(cell),Color(0.25,0.48,0.58,0.22),_static_layer)
			else: _static_layer.draw_circle(hex_to_screen(cell),0.7,Color(0.25,0.48,0.58,0.3))
	for cell: Vector2i in _body_mask:
		var point := hex_to_screen(cell)
		if Rect2(Vector2(-8,-8),size+Vector2(16,16)).has_point(point): _static_layer.draw_colored_polygon(_polygon(cell),Color(body_color, 0.3) if has_background else body_color)
	for offset: Vector2i in _layout.gate_cells:
		var cell := GRID.from_offset(offset)
		if _scale() >= 5: _outline(_polygon(cell),Color(0.57,0.89,0.93,0.6),_static_layer)
		else: _static_layer.draw_circle(hex_to_screen(cell),0.8,Color("91e4ee"))

	_draw_station_target()

func _screen_polygon(plane_points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in plane_points: result.append(plane_to_screen(point))
	return result

func _draw_station_target() -> void:
	if not _dock_visible: return
	var station := _screen_polygon(_dock_projection.station_polygon_plane)
	_static_layer.draw_colored_polygon(station,Color(0.12,0.25,0.30,0.92))
	_outline(station,Color("91e4ee"),_static_layer)
	var anchor := plane_to_screen(_dock_projection.anchor_plane)
	_static_layer.draw_string(ThemeDB.fallback_font,anchor+Vector2(-18,4),"Polisa",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b0c8d5"))
	var gate := _screen_polygon(_dock_projection.gate_polygon_plane)
	_static_layer.draw_colored_polygon(gate,Color(0.95,0.77,0.49,0.2))
	_outline(gate,Color("f2c47c"),_static_layer)
	var gate_center := hex_to_screen(_dock_projection.gate_axial)
	_static_layer.draw_circle(gate_center,maxf(2.0,_scale()*0.15),Color("f2c47c"))
	_static_layer.draw_string(ThemeDB.fallback_font,gate_center+Vector2(8,4),"Dockgate",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f2c47c"))

func _draw() -> void:
	if _layout.is_empty(): return
	for id: String in _actors:
		var actor: Dictionary = _actors[id]
		var selected := id == _selected
		var color := Color("f2c47c") if selected else (Color("f17b72") if actor.get("radar_contact", false) else Color("91e4ee"))
		for cell in actor.get("footprint_cells",[]):
			if cell is Vector2i:
				draw_colored_polygon(_polygon(cell),Color(color,0.2))
				_outline(_polygon(cell),Color(color,0.6))
		var point := plane_to_screen(actor.flight.position_plane)
		var heading: float = actor.flight.get("heading_rad",0.0)
		var forward := (Vector2.from_angle(heading)*Vector2(1,TILT)).normalized()
		var side := forward.orthogonal()
		var radius := clampf(_scale()*1.5,5.0,14.0)
		draw_colored_polygon(PackedVector2Array([point+forward*radius,point-forward*radius*0.65+side*radius*0.65,point-forward*radius*0.3,point-forward*radius*0.65-side*radius*0.65]),color)
		draw_string(ThemeDB.fallback_font,point+Vector2(10,-10),id,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b0c8d5"))
	var course := get_course_line()
	if course.size() == 2:
		draw_dashed_line(course[0],course[1],Color("f2c47c"),2.0,8.0,true)
		draw_arc(course[1],9.0,0.0,TAU,24,Color("f2c47c"),2.0,true)
	elif _course_active and not _actors.has(_selected):
		_course_active = false
	var name: String = str(_body_visual.get("name",_layout.body_id))
	draw_string(ThemeDB.fallback_font,Vector2(16,22),name+" Ã‚Â· Orbit",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b0c8d5"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position,_zoom*(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.15))
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if request_move_at(event.position): accept_event()
	elif event is InputEventMouseMotion and _dragging:
		if not event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_dragging = false
			return
		pan_by(event.relative)
		accept_event()

static func _finite_vector(value: Variant) -> bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y)

static func _finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))
