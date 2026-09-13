extends Node3D
class_name RestartWorld
## Snapshot projection only. Commands are emitted for the authoritative core.
signal object_selected(kind: String, id: String)
signal ground_clicked(position: Vector2)
signal units_selected(ids: Array[String])
signal context_clicked(kind: String, id: String, screen: Vector2)

const Geo = preload("res://scripts/world/world_geometry.gd")
const Terrain = preload("res://scripts/world/world_terrain.gd")
const Landmarks = preload("res://scripts/world/world_landmarks.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const OrbitProjection = preload("res://scripts/world/world_orbit_projection.gd")
const GroundProjection = preload("res://scripts/world/world_ground_projection.gd")
const Armor = preload("res://scripts/world/world_armor.gd")
const ControlScript = preload("res://scripts/world/world_control.gd")

var _orbit: RefCounted
var _ground: RefCounted
var _camera: Camera3D
var _map: Node3D
var _environment: Environment
var _units: Dictionary = {}
var _objects: Dictionary = {}
var _snapshot: Dictionary = {}
var _region := ""
var _focus := Vector3(4,0,0)
var _zoom := 48.0
var _selected_kind := ""
var _selected_id := ""
var _dragging := false
var _destination: MeshInstance3D
var _destination_label: Label3D
var _destination_age := 10.0
var _flying := false
var _flight_camera_follow := false
var _control: Node
var _selected_units: Array[String] = []
var _last_motion: Dictionary = {}
var _follow_delay := 0.0
var _follow_mode := false
var _follow_unit := ""

func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _zoom
	_camera.far = 1800
	_camera.near = 0.1
	_camera.current = true
	add_child(_camera)
	_control = ControlScript.new()
	add_child(_control)
	_control.clicked.connect(_pick)
	_control.box_finished.connect(_box_select)
	_lighting()
	if not _snapshot.is_empty():
		present(_snapshot)
	_update_camera()

func present(state: Dictionary) -> void:
	# A joining/reconnecting client has no confirmed snapshot yet. Keep the last
	# rendered map until the host sends a complete state.
	if state.is_empty() or not state.has("region") or not state.get("crew") is Dictionary:
		return
	_snapshot = state
	if not is_node_ready():
		return
	var region := str(state.get("region","base"))
	if region != _region:
		_region = region
		_build_map()
	var crew: Dictionary = state.get("crew",{})
	for id in crew:
		if not _units.has(id):
			_create_unit(str(id),crew[id])
		var root: Node3D = _units[id]
		var data: Dictionary = crew[id]
		var coords: Array = data.get("position",[0,0])
		var next := Vector3(float(coords[0]),0.08,float(coords[1]))
		var movement := next - root.position
		if movement.length() > 0.005:
			_last_motion[id] = Time.get_ticks_msec()
		if movement.length() > 0.015:
			var model := root.get_node("Model") as Node3D
			model.rotation.y = atan2(movement.x,movement.z)
		root.position = next
		root.set_meta("moving",movement.length() > 0.005)
		var task := str(data.get("assignment","idle"))
		Armor.show(root.get_meta("armor_parts",[]),str(data.get("equipment",{}).get("armor",""))=="armor")
		(root.get_node("Model") as Node3D).rotation.z=PI/2 if task=="downed" else 0.0
		(root.get_node("Model") as Node3D).position.y=0.3 if task=="downed" else 0.0
		var targets: Array = data.get("target",coords)
		var moving_recently := Time.get_ticks_msec()-int(_last_motion.get(id,-1000)) < 130
		var walking := Vector2(coords[0],coords[1]).distance_to(Vector2(targets[0],targets[1])) > 0.05 or moving_recently
		if not walking and task in ["work","salvage","gather"]:
			var station_id := "workbench" if task == "work" else str(state.get("ground",{}).get("activity",{}).get("site_id","")) if task=="gather" else "satellite"
			if _objects.has(station_id):
				var toward := (_objects[station_id] as Node3D).position - root.position
				(root.get_node("Model") as Node3D).rotation.y = atan2(toward.x,toward.z)
		var animation: AnimationPlayer = root.get_meta("animation_player",null)
		if animation != null:
			var wanted := "Walk" if walking and task!="downed" else "Work" if task in ["work","salvage","gather"] else "Idle"
			if animation.has_animation(wanted) and animation.current_animation != wanted:
				animation.play(wanted,0.15)
			animation.speed_scale = 0.0 if bool(state.get("paused",false)) or task=="downed" else 1.0
		var title := root.get_node("Title") as Label3D
		title.text = str(data.get("name",id)) + (" · ARBEIT" if task == "work" else " · BERGUNG" if task in ["salvage","gather"] else " · BERGUNG IN %ds" % int(ceil(float(data.get("respawn_remaining",0)))) if task=="downed" else " · %d LP" % int(data.health) if float(data.get("health",100))<100 else "")
	var was_flying:=_flying
	_flying = str(state.get("ship",{}).get("mode","landed")) == "flying" or (bool(state.get("travel",{}).get("active",false)) and str(state.get("travel",{}).get("phase","")) == "flying")
	_orbit.present(_map,_objects,state)
	_ground.present(_map,_objects,_units,state)
	if _flying and not was_flying and _region in ["base","rust","station","orbit","space","bunker_surface","distribution","tradepost"]:
		_flight_camera_follow=true
	for id in _units:
		(_units[id] as Node3D).visible = crew.has(id) and not _flying and str(crew.get(id,{}).get("assignment","idle")) != "aboard"
		Geo.set_pickable(_units[id],(_units[id] as Node3D).visible)
	_apply_selection()

func _process(delta: float) -> void:
	if _camera == null:
		return
	var ui_focus := get_viewport().gui_get_focus_owner()
	var typing := ui_focus is LineEdit or ui_focus is TextEdit or ui_focus is SpinBox
	_follow_delay = maxf(0,_follow_delay-delta)
	if not typing:
		var horizontal := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		var vertical := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		var right := _camera.global_basis.x
		var forward := Vector3(_camera.global_basis.z.x,0,_camera.global_basis.z.z).normalized()
		# Keep fine movement when close; cross the visible area quickly when zoomed out.
		var camera_speed := maxf(22.0,_zoom*0.9)
		if Input.is_physical_key_pressed(KEY_SHIFT): camera_speed *= 1.7
		_focus += (right*horizontal+forward*vertical).limit_length(1.0)*delta*camera_speed
		if absf(horizontal)+absf(vertical)>0:
			_follow_delay = 1.0
			_flight_camera_follow=false
		_focus.x = clampf(_focus.x,-Catalog.bounds(_region),Catalog.bounds(_region))
		_focus.z = clampf(_focus.z,-Catalog.bounds(_region),Catalog.bounds(_region))
	if _follow_mode and _units.has(_follow_unit) and _follow_delay <= 0 and not _dragging:
		_focus = _focus.lerp((_units[_follow_unit] as Node3D).position,1.0-exp(-delta*4.0))
	elif _flying and _flight_camera_follow and _objects.has("shuttle") and not _dragging:
		var target: Vector3=(_objects.shuttle as Node3D).position
		if _region=="space": target+=Vector3(minf(32,_zoom*0.22),0,-minf(8,_zoom*0.055))
		_focus=_focus.lerp(target,1.0-exp(-delta*4.0))
	_update_camera()
	if is_instance_valid(_map):
		for title: Label3D in _map.find_children("*","Label3D",true,false):
			title.pixel_size=0.030*clampf(_zoom/48.0,0.7,8.0)
	_destination_age += delta
	if is_instance_valid(_destination):
		_destination.visible = _destination_age < 3.0
		_destination.scale = Vector3.ONE * (1.0 + sin(_destination_age*5.0)*0.1)
		_destination_label.visible = _destination.visible

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom*0.85,19,_max_zoom())
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom/0.85,19,_max_zoom())
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			var hit := _hit_at(event.position)
			if not hit.is_empty():
				var collider: Object = hit.collider
				if collider.has_meta("id") and str(collider.get_meta("id"))=="shuttle":
					context_clicked.emit("object","shuttle",event.position)
					get_viewport().set_input_as_handled()
					return
			var at: Variant = _ground_at(event.position)
			if at != null:
				ground_clicked.emit(Vector2(at.x,at.z))
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		var factor := _zoom / maxf(get_viewport().get_visible_rect().size.y,1)
		var right := _camera.global_basis.x
		var forward := Vector3(_camera.global_basis.z.x,0,_camera.global_basis.z.z).normalized()
		_focus -= right*event.relative.x*factor + forward*event.relative.y*factor*1.4
		_follow_delay = 1.0
		_flight_camera_follow=false
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		focus_home()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		_dragging = false
		get_viewport().set_input_as_handled()

func focus_unit(id: String) -> void:
	if _units.has(id):
		_focus = (_units[id] as Node3D).position

func focus_object(id: String) -> void:
	if _objects.has(id) and (_objects[id] as Node3D).visible:
		_focus = (_objects[id] as Node3D).position
		_zoom = minf(_zoom,43.0)
		_flight_camera_follow=id=="shuttle"

func focus_home() -> void:
	_flight_camera_follow=_region in ["base","rust","station","orbit","space","bunker_surface","distribution","tradepost"]
	match _region:
		"base":
			var ship: Dictionary=_snapshot.get("ship",{})
			var coords: Array=ship.get("position",[2,0])
			_focus=Vector3(coords[0],0,coords[1]) if ship.get("mode","")=="flying" else Vector3(2,0,-1)
			_zoom=78.0 if ship.get("mode","")=="flying" else 48.0
		"rust":
			var coords: Array = _snapshot.get("ship",{}).get("position",[-210,180])
			_focus = Vector3(coords[0],0,coords[1])
			_zoom = 76.0
		"station":
			_focus = Vector3(0,0,0)
			_zoom = 70.0
		"space","orbit":
			var coords: Array = _snapshot.get("ship",{}).get("position",[-85,0])
			_focus = Vector3(coords[0]+35,0,coords[1]-8)
			_zoom = 145.0
		"bunker_surface","distribution","tradepost":
			var coords: Array = _snapshot.get("ship",{}).get("position",[0,0])
			_focus=Vector3(coords[0],0,coords[1])
			_zoom=82.0 if _region=="distribution" else 65.0
		"bunker_depths":
			_focus=Vector3(0,0,22)
			_zoom=64.0
		_:
			_focus = Vector3(2,0,-1)
			_zoom = 48.0

func _max_zoom() -> float:
	return minf(950,Catalog.bounds(_region)*2.0) if _region in ["base","rust","distribution","bunker_surface","tradepost"] else 400.0 if _region in ["space","orbit"] else 180.0

func mark_destination(at: Vector2, flight: bool) -> void:
	if not is_instance_valid(_destination): return
	_destination.position = Vector3(at.x,0.09,at.y)
	_destination_age = 0.0
	_destination_label.position = Vector3(at.x,2.0,at.y)
	_destination_label.text = "FLUGZIEL AUF DIESER KARTE" if flight else "LAUFZIEL"

func set_selection(kind: String, id: String) -> void:
	_selected_kind = kind
	_selected_id = id
	if kind == "unit":
		_selected_units = [id]
	_apply_selection()

func set_control_mode(follow: bool, unit_id: String) -> void:
	if _follow_mode == follow and _follow_unit == unit_id:
		return
	_follow_mode = follow
	_follow_unit = unit_id
	_follow_delay = 0.0

func set_selected_units(ids: Array[String]) -> void:
	_selected_units = ids.duplicate()
	_apply_selection()

func _box_select(bounds: Rect2) -> void:
	var ids: Array[String] = []
	for id in _units:
		var root: Node3D = _units[id]
		var point := root.global_position+Vector3(0,1,0)
		if root.visible and not _camera.is_position_behind(point) and bounds.has_point(_camera.unproject_position(point)):
			ids.append(str(id))
	ids.sort()
	units_selected.emit(ids)

func _apply_selection() -> void:
	for id in _objects:
		var root: Node3D = _objects[id]
		(root.get_node("Selection") as MeshInstance3D).visible = _selected_kind == "object" and _selected_id == id
	for id in _units:
		var root: Node3D = _units[id]
		(root.get_node("Selection") as MeshInstance3D).visible = id in _selected_units

func _build_map() -> void:
	if is_instance_valid(_map):
		remove_child(_map)
		_map.queue_free()
	_units.clear()
	_last_motion.clear()
	_objects.clear()
	_map = Node3D.new()
	_map.name = "Region_"+_region
	add_child(_map)
	Terrain.build(_map,_region)
	var points: Dictionary = Catalog.landmarks(_region)
	if _region=="space": points={"shuttle":[-85,0],"pirate":[55,-25]}
	_objects = Landmarks.build(_map,_region,points)
	_orbit=OrbitProjection.new()
	_ground=GroundProjection.new()
	_destination = Geo.ring(_map,0.65,Color("f6d497"))
	_destination_label = Geo.label(_map,"",Vector3.ZERO,Color("f6d497"),18)
	_destination_age = 10.0
	_environment.background_color = Color("091624") if _region in ["station","space","orbit","bunker_depths"] else Color("839ba6")
	_environment.fog_enabled = _region not in ["station","space","orbit","bunker_depths"]
	focus_home()

func _create_unit(id: String, data: Dictionary) -> void:
	var root := Node3D.new()
	root.name = id
	_map.add_child(root)
	var model := Geo.asset(root,"white_astronaut",Vector3.ZERO,Vector3(0.85,1.95,0.6))
	model.name = "Model"
	var players := model.find_children("*","AnimationPlayer",true,false)
	if not players.is_empty():
		var player := players[0] as AnimationPlayer
		for animation_name in ["Idle","Walk","Work"]:
			if player.has_animation(animation_name):
				player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
		player.play("Idle")
		player.advance(0)
		root.set_meta("animation_player",player)
	root.set_meta("armor_parts",Armor.attach(model))
	var color := Color("91dfd6") if id == "ida" else Color("eac890")
	Geo.collider(root,"unit",id,Vector3(1.2,2.2,1.2))
	var disk := Geo.cylinder(root,Vector3(0,0.035,0),0.47,0.04,Color("334f58"),16)
	disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var selected := Geo.ring(root,0.65,color)
	selected.name = "Selection"
	selected.visible = false
	var label := Geo.label(root,str(data.get("name",id)),Vector3(0,2.45,0),color,27)
	label.name = "Title"
	_units[id] = root

func _update_camera() -> void:
	_camera.size = _zoom
	# Slight left framing compensates for the wider inspection panel on the right.
	var target := _focus + Vector3(2.1,0,-1.7)
	_camera.position = target + Vector3(30,39,44).normalized()*maxf(66,_zoom*1.15)
	_camera.look_at(target,Vector3.UP)

func _pick(screen: Vector2) -> void:
	var hit := _hit_at(screen)
	if hit.is_empty(): return
	var collider: Object = hit.collider
	if collider.has_meta("id") and str(collider.get_meta("kind")) != "ground":
		object_selected.emit(str(collider.get_meta("kind")),str(collider.get_meta("id")))
		get_viewport().set_input_as_handled()

func _hit_at(screen: Vector2) -> Dictionary:
	var origin := _camera.project_ray_origin(screen)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+_camera.project_ray_normal(screen)*1800)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _ground_at(screen: Vector2) -> Variant:
	return Plane(Vector3.UP,0).intersects_ray(_camera.project_ray_origin(screen),_camera.project_ray_normal(screen))

func _lighting() -> void:
	var world_env := WorldEnvironment.new()
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("839ba6")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("adc9dc")
	_environment.ambient_light_energy = 0.48
	_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_environment.fog_enabled = true
	_environment.fog_light_color = Color("b8b8ac")
	_environment.fog_light_energy = 0.7
	_environment.fog_density = 0.0006
	world_env.environment = _environment
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_color = Color("ffe0ac")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 220
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.15
	sun.shadow_normal_bias = 2.0
	add_child(sun)
