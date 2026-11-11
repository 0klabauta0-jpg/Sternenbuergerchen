extends Control
## UNWIRED read-only projection. Requests are intents, never movement authority.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
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
	if static_changed and is_instance_valid(_static_layer): _static_layer.queue_redraw()
	queue_redraw()

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
	if not AREA.contains(target,{"coordinate_frame":"local","space_area_id":_snapshot.space_area_id}) or _body_mask.has(target): return false
	move_requested.emit(_selected,target)
	return true

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
	var grid := get_visible_grid_projection()
	var bounds: Rect2i = grid.offset_bounds
	for y in range(bounds.position.y,bounds.end.y,grid.stride):
		for x in range(bounds.position.x,bounds.end.x,grid.stride):
			var cell := GRID.from_offset(Vector2i(x,y))
			if grid.stride == 1: _outline(_polygon(cell),Color(0.25,0.48,0.58,0.22),_static_layer)
			else: _static_layer.draw_circle(hex_to_screen(cell),0.7,Color(0.25,0.48,0.58,0.3))
	var body_color := Color("866349")
	if _body_visual.get("color") is Color: body_color = _body_visual.color
	for cell: Vector2i in _body_mask:
		var point := hex_to_screen(cell)
		if Rect2(Vector2(-8,-8),size+Vector2(16,16)).has_point(point): _static_layer.draw_colored_polygon(_polygon(cell),body_color)
	for offset: Vector2i in _layout.gate_cells:
		var cell := GRID.from_offset(offset)
		if _scale() >= 5: _outline(_polygon(cell),Color(0.57,0.89,0.93,0.6),_static_layer)
		else: _static_layer.draw_circle(hex_to_screen(cell),0.8,Color("91e4ee"))

func _draw() -> void:
	if _layout.is_empty(): return
	for id: String in _actors:
		var actor: Dictionary = _actors[id]
		var selected := id == _selected
		var color := Color("f2c47c") if selected else Color("91e4ee")
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
	var name: String = str(_body_visual.get("name",_layout.body_id))
	draw_string(ThemeDB.fallback_font,Vector2(16,22),name+" Â· Orbit",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b0c8d5"))

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
