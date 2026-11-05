extends Control
## Local explorable place. Existing Meta owners receive terminal signals only.

signal terminal_open_requested(id: String)
signal exploration_exit_requested

const MAP_PATH: String = "res://maps/homebase_frontier_exploration.json"
const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const UNITS_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const SIM_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const AVATAR_SCRIPT: GDScript = preload("res://scripts/meta/homebase_commander_avatar.gd")
const FLIGHT_VISUAL_SCRIPT: GDScript = preload("res://scripts/terrain/mission_flight_visual.gd")
const HEX_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")
const CLOSED_BUILDING_SCRIPT: GDScript = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const INTERACTION_RADIUS: float = 1.8

var _active: bool = false
var _initialized: bool = false
var _host: SubViewportContainer
var _viewport: SubViewport
var _runtime: Node
var _view: CanvasLayer
var _terrain: Node
var _units: Node
var _sim: Node
var _avatar: Node2D
var _model: Node3D
var _player: AnimationPlayer
var _idle_clip: String = ""
var _walk_clip: String = ""
var _walking: bool = false
var _previous_position: Vector2 = Vector2.ZERO
var _terminals: Array[Dictionary] = []
var _terminal_labels: Dictionary = {}
var _layout: Dictionary = {}
var _asset_sources: Array[Dictionary] = []
var _map_bounds: Rect2
var _map_data
var _hint: Label
var _interact: Button
var _nearby_terminal: String = ""
var _keys: Dictionary = {}
var _keyboard_move: bool = false
var _move_cadence: float = 0.0
var _movement_command_count: int = 0
var _command_sequence: int = 0
var _drone_model: Node3D
var _drone_helper: Node3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_host = SubViewportContainer.new()
	_host.name = "BaseWorldViewport"
	_host.stretch = true
	_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_host.focus_mode = Control.FOCUS_ALL
	add_child(_host)
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.gui_input.connect(_on_world_gui_input)
	_host.focus_exited.connect(_clear_keyboard_input)
	_viewport = SubViewport.new()
	_viewport.name = "BaseWorld"
	_viewport.own_world_3d = true
	_viewport.world_2d = World2D.new()
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_host.add_child(_viewport)
	_build_overlay()
	visibility_changed.connect(_on_visibility_changed)
	set_active(_active)


func set_active(active: bool) -> void:
	_active = active
	if not is_node_ready():
		return
	visible = active
	if active and not _initialized:
		_initialize_runtime()
	if _runtime != null:
		_runtime.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if _drone_helper != null:
		_drone_helper.call("set_operating_visual", active)
	if not active:
		_clear_keyboard_input()
		if _sim != null:
			_sim.call("clear_queues")
	set_process(active)
	set_physics_process(active)
	set_process_unhandled_key_input(active)
	if active:
		_host.grab_focus()
		_update_nearby_terminal()


func _on_visibility_changed() -> void:
	if _active and not is_visible_in_tree():
		set_active(false)


func _initialize_runtime() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	_layout = Dictionary(raw.get("homebase_exploration", {}))
	_map_data = MAP_SCRIPT.load_from_file(MAP_PATH)
	_runtime = Node.new()
	_runtime.name = "HomebaseRuntime"
	_viewport.add_child(_runtime)
	_terrain = TERRAIN_SCRIPT.new()
	_terrain.name = "TerrainRegistry"
	_runtime.add_child(_terrain)
	var tile_size: Dictionary = _map_data.get_tile_size()
	_terrain.call("configure_iso_grid", _map_data.get_grid_origin(), tile_size["half_width"], tile_size["half_height"], _map_data.get_grid_topology())
	var first: bool = true
	for tile in _map_data.get_tiles():
		_terrain.call("register_tile", tile)
		if first:
			_map_bounds = Rect2(tile.world_position, Vector2.ZERO)
			first = false
		else:
			_map_bounds = _map_bounds.expand(tile.world_position)
	_units = UNITS_SCRIPT.new()
	_units.name = "UnitRegistry"
	_runtime.add_child(_units)
	_sim = SIM_SCRIPT.new()
	_sim.name = "SimulationRoot"
	_sim.set("unit_registry_path", NodePath("../UnitRegistry"))
	_sim.set("terrain_registry_path", NodePath("../TerrainRegistry"))
	_runtime.add_child(_sim)
	_avatar = AVATAR_SCRIPT.new()
	_avatar.name = "CommanderAvatar"
	_runtime.add_child(_avatar)
	_avatar.position = _world_at_grid(_layout.get("avatar_spawn_grid", [7, 11]))
	_units.call("register_unit", AVATAR_SCRIPT.UNIT_ID, _avatar)
	_sim.call("register_known_unit", AVATAR_SCRIPT.UNIT_ID, _avatar)
	_view = VIEW_SCRIPT.new()
	_view.name = "Primary3DView"
	_runtime.add_child(_view)
	_view.call("set_frontier_art_enabled", true)
	_view.call("set_hex_grid_visible", false)
	_view.call("configure_from_map", _map_data)
	_view.set("_camera_size", 16.0)
	_view.set("_camera_yaw_degrees", 24.0)
	_view.set("_camera_pitch_degrees", 50.0)
	_view.call("focus_world_position", _avatar.position)
	var world: Node3D = _view.get_node("ViewportContainer/SubViewport/WorldRoot") as Node3D
	var stage := Node3D.new()
	stage.name = "HomebaseAuthoredVisuals"
	world.add_child(stage)
	for asset_variant in Array(_layout.get("assets", [])):
		var asset: Dictionary = Dictionary(asset_variant)
		var visual: Node3D = _load_visual(asset)
		if visual != null:
			stage.add_child(visual)
			visual.position = _plane_position(asset.get("plane", [0.0, 0.0]))
			if String(asset.get("id", "")) in ["habitat_cutaway_01", "freihafen_hall_01"]:
				var shell: Node3D = CLOSED_BUILDING_SCRIPT.new()
				shell.name = "ClosedExterior_" + String(asset["id"])
				stage.add_child(shell)
				shell.call("build", _visual_bounds(visual), String(asset["id"]) == "freihafen_hall_01")
				visual.visible = false
	var avatar_visual: Dictionary = Dictionary(_layout.get("avatar_visual", {}))
	_model = _load_visual(avatar_visual)
	if _model != null:
		_model.name = "CommanderVisual"
		stage.add_child(_model)
		var players: Array[Node] = _model.find_children("*", "AnimationPlayer", true, false)
		_player = players[0] as AnimationPlayer if not players.is_empty() else null
		if _player != null:
			for clip in _player.get_animation_list():
				if String(clip).to_lower().ends_with("idle"):
					_idle_clip = String(clip)
				if String(clip).to_lower().ends_with("walk"):
					_walk_clip = String(clip)
			if not _idle_clip.is_empty():
				_player.play(_idle_clip)
	_build_terminals(stage)
	_build_service_drone(stage)
	# These stored blockers are the footprints of the authored scene above.
	# Register its visual ownership so generic missing-asset boxes do not draw
	# through the real buildings and parked ship. Navigation facts stay intact.
	var footprint_visuals: Dictionary = {}
	for tile in _map_data.get_tiles():
		if not bool(tile.walkable):
			footprint_visuals[Vector2i(tile.grid_position)] = stage
	_view.call("set_external_terrain_object_visuals", footprint_visuals)
	_previous_position = _avatar.position
	_initialized = true
	_update_avatar_visual()


func _load_visual(source: Dictionary) -> Node3D:
	var path: String = String(source.get("path", ""))
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var visual: Node3D = scene.instantiate() as Node3D
	visual.scale = Vector3.ONE * float(source.get("scale", 1.0))
	var fact: Dictionary = source.duplicate(true)
	fact["actual_sha256"] = FileAccess.get_sha256(path)
	_asset_sources.append(fact)
	return visual


func _world_at_grid(raw_grid: Variant) -> Vector2:
	var grid: Array = Array(raw_grid)
	return _terrain.call("grid_to_world", Vector2i(int(grid[0]), int(grid[1])))


func _visual_bounds(visual: Node3D) -> AABB:
	var bounds := AABB()
	var first: bool = true
	for node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var current: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = current if first else bounds.merge(current)
		first = false
	return bounds


func _plane_position(raw_plane: Variant) -> Vector3:
	var plane: Array = Array(raw_plane)
	return Vector3(float(plane[0]), 0.0, float(plane[1]))


func request_walk_to(world_position: Vector2) -> bool:
	if not _active or not _initialized or not is_visible_in_tree():
		return false
	var grid: Vector2i = _terrain.call("world_to_grid", world_position)
	if not bool(_terrain.call("is_walkable", grid)):
		return false
	_command_sequence += 1
	_sim.call("enqueue_command", {
		"type": "move_to_position", "unit_id": AVATAR_SCRIPT.UNIT_ID,
		"target_position": _terrain.call("grid_to_world", grid),
		"command_token": "homebase_walk_%d" % _command_sequence,
		"requeue_until_target": true,
	})
	_movement_command_count += 1
	return true


func request_terminal(id: String) -> bool:
	if not _active or not _initialized or not is_visible_in_tree():
		return false
	for terminal in _terminals:
		if String(terminal["id"]) == id and _terminal_distance(terminal) <= INTERACTION_RADIUS:
			_stop_avatar()
			terminal_open_requested.emit(id)
			return true
	return false


func _stop_avatar() -> void:
	if _sim == null:
		return
	_command_sequence += 1
	_sim.call("enqueue_command", {"type": "hold_position", "unit_id": AVATAR_SCRIPT.UNIT_ID, "command_token": "homebase_hold_%d" % _command_sequence})


func _on_world_gui_input(event: InputEvent) -> void:
	if not _active or not _initialized:
		return
	if event is InputEventMouseButton and event.pressed:
		_host.grab_focus()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var local: Vector2 = event.position * Vector2(_viewport.size) / _host.size.max(Vector2.ONE)
			var target: Variant = _view.call("screen_to_world_position", local)
			if typeof(target) == TYPE_VECTOR2:
				request_walk_to(Vector2(target))
			_host.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_view.call("zoom_camera", 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
			_host.accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			for terminal in _terminals:
				var point: Vector2 = _view.call("world_to_screen_position", terminal["world_position"])
				if point.distance_to(event.position) <= 38.0:
					request_terminal(String(terminal["id"]))
					_host.accept_event()
					break


func _unhandled_key_input(event: InputEvent) -> void:
	if not _active or not _initialized or not _host.has_focus() or not event is InputEventKey:
		return
	var key: Key = event.physical_keycode
	if key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_keys[key] = event.pressed
		get_viewport().set_input_as_handled()
	elif event.pressed and not event.echo and key == KEY_E:
		request_terminal(_nearby_terminal)
		get_viewport().set_input_as_handled()
	elif event.pressed and not event.echo and key == KEY_ESCAPE:
		exploration_exit_requested.emit()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not _active or not _initialized:
		return
	var direction := Vector2(float(bool(_keys.get(KEY_D, false))) - float(bool(_keys.get(KEY_A, false))), float(bool(_keys.get(KEY_S, false))) - float(bool(_keys.get(KEY_W, false))))
	if direction.is_zero_approx() or not _host.has_focus():
		if _keyboard_move:
			_stop_avatar()
		_keyboard_move = false
		_move_cadence = 0.0
		return
	_keyboard_move = true
	_move_cadence -= delta
	if _move_cadence > 0.0:
		return
	_move_cadence = 0.16
	var yaw: float = deg_to_rad(float(_view.call("get_camera_yaw_degrees")))
	var plane_direction: Vector2 = Vector2(cos(yaw), -sin(yaw)) * direction.normalized().x + Vector2(sin(yaw), cos(yaw)) * direction.normalized().y
	var origin_3d: Vector3 = _view.call("_world_to_3d_position", _avatar.position, 0.0)
	var target: Vector2 = _view.call("_position_3d_to_world", origin_3d + Vector3(plane_direction.x, 0.0, plane_direction.y) * 1.4)
	request_walk_to(target)


func _clear_keyboard_input() -> void:
	_keys.clear()
	if _keyboard_move:
		_stop_avatar()
	_keyboard_move = false


func _process(delta: float) -> void:
	if not _active or not _initialized:
		return
	_update_avatar_visual()
	_update_nearby_terminal()
	if _drone_helper != null and bool(_drone_helper.call("advance_visual", delta)):
		_view.call("_request_viewport_redraw")


func _update_avatar_visual() -> void:
	if _model == null:
		return
	var position_3d: Vector3 = _view.call("_world_to_surface_3d_position", _avatar.position, 0.006)
	var displacement: Vector3 = position_3d - _model.position
	var moving: bool = _avatar.position.distance_squared_to(_previous_position) > 0.00001
	_model.position = position_3d
	if moving:
		_model.rotation.y = atan2(displacement.x, displacement.z)
		_view.call("focus_world_position", _avatar.position)
	if moving != _walking and _player != null:
		var clip: String = _walk_clip if moving else _idle_clip
		if not clip.is_empty():
			_player.play(clip, 0.15)
	_walking = moving
	_previous_position = _avatar.position
	_view.call("_request_viewport_redraw")


func _build_terminals(stage: Node3D) -> void:
	for raw_terminal in Array(_layout.get("terminals", [])):
		var terminal: Dictionary = Dictionary(raw_terminal).duplicate(true)
		terminal["world_position"] = _world_at_grid(terminal["grid"])
		_terminals.append(terminal)
		var position_3d: Vector3 = _view.call("_world_to_surface_3d_position", terminal["world_position"], 0.0)
		var pedestal: MeshInstance3D = _box(stage, Vector3(0.24, 0.48, 0.20), position_3d + Vector3(0.33, 0.24, 0.0), Color("cbd4c5"))
		pedestal.name = "Terminal_" + String(terminal["id"])
		_box(stage, Vector3(0.25, 0.15, 0.025), position_3d + Vector3(0.33, 0.52, 0.10), Color("2ac6c7"))
		var label := Label3D.new()
		label.text = String(terminal["title"])
		label.font_size = 48
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("eaf2df")
		label.position = position_3d + Vector3(0.0, 0.95, 0.0)
		stage.add_child(label)
		_terminal_labels[String(terminal["id"])] = label


func _terminal_distance(terminal: Dictionary) -> float:
	var avatar_plane: Vector3 = _view.call("_world_to_3d_position", _avatar.position, 0.0)
	var terminal_plane: Vector3 = _view.call("_world_to_3d_position", terminal["world_position"], 0.0)
	return avatar_plane.distance_to(terminal_plane)


func _update_nearby_terminal() -> void:
	var nearest: String = ""
	var title: String = ""
	var distance_value: float = INTERACTION_RADIUS
	for terminal in _terminals:
		var distance_candidate: float = _terminal_distance(terminal)
		if distance_candidate <= distance_value:
			distance_value = distance_candidate
			nearest = String(terminal["id"])
			title = String(terminal["title"])
	if nearest == _nearby_terminal:
		return
	_nearby_terminal = nearest
	_interact.disabled = nearest.is_empty()
	_interact.text = "E · " + title if not nearest.is_empty() else "Konsole aufsuchen"
	for id in _terminal_labels:
		(_terminal_labels[id] as Label3D).modulate = Color("ffe08b") if String(id) == nearest else Color("eaf2df")


func _build_service_drone(stage: Node3D) -> void:
	var drone_owner := Node3D.new()
	drone_owner.name = "AuthoredServiceDrone"
	drone_owner.position = _plane_position(Dictionary(_layout.get("service_drone", {})).get("plane", [17.1, 10.7]))
	stage.add_child(drone_owner)
	_drone_model = Node3D.new()
	_drone_model.name = "ServiceDroneVisual"
	_drone_model.position.y = 0.85
	drone_owner.add_child(_drone_model)
	_box(_drone_model, Vector3(0.38, 0.15, 0.28), Vector3.ZERO, Color("cbd4c5"))
	_box(_drone_model, Vector3(0.18, 0.05, 0.22), Vector3(0.0, 0.10, 0.0), Color("326a69"))
	_box(_drone_model, Vector3(0.09, 0.06, 0.025), Vector3(0.0, 0.0, 0.15), Color("2ac6c7"))
	_drone_helper = FLIGHT_VISUAL_SCRIPT.new()
	_drone_helper.name = "ReadOnlyDroneMotion"
	drone_owner.add_child(_drone_helper)
	var nozzles: Array[Vector3] = [Vector3(0.0, 0.76, 0.0)]
	_drone_helper.call("configure_service_drone", _drone_model, nozzles)
	_drone_helper.call("set_operating_visual", true)


func _box(parent: Node3D, size_value: Vector3, position_value: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	visual.material_override = material
	visual.position = position_value
	parent.add_child(visual)
	return visual


func _build_overlay() -> void:
	var panel := VBoxContainer.new()
	panel.name = "ExplorationHelp"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -420.0
	panel.offset_top = -118.0
	panel.offset_right = -24.0
	panel.offset_bottom = -22.0
	_interact = Button.new()
	_interact.name = "InteractTerminal"
	_interact.text = "Konsole aufsuchen"
	_interact.disabled = true
	_interact.custom_minimum_size.y = 40.0
	_interact.pressed.connect(func(): request_terminal(_nearby_terminal))
	panel.add_child(_interact)
	_hint = Label.new()
	_hint.text = "WASD gehen · Rechtsklick Ziel · E Konsole"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_hint)
	var exit := Button.new()
	exit.name = "ExitExploration"
	exit.text = "Übersicht  ·  Esc"
	exit.pressed.connect(func(): exploration_exit_requested.emit())
	add_child(exit)
	exit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	exit.offset_left = -196.0
	exit.offset_top = 20.0
	exit.offset_right = -24.0
	exit.offset_bottom = 64.0


func get_exploration_snapshot() -> Dictionary:
	var result: Dictionary = {
		"initialized": _initialized, "active": _active,
		"map_path": MAP_PATH, "movement_owner": "SimulationRoot",
		"owns_roster": false, "owns_transport": false, "owns_inventory": false,
		"ephemeral_commander": true, "read_only": true,
		"tree_paused": get_tree().paused if is_inside_tree() else false,
	}
	if not _initialized:
		return result
	result.merge({
		"map_grid_size": _map_data.get_grid_size(), "map_bounds": _map_bounds,
		"avatar_position": _avatar.position, "avatar_instance_id": _avatar.get_instance_id(),
		"registered_unit_count": Array(_units.call("get_all_units")).size(),
		"simulation_ticks": int(_sim.get("tick_counter")),
		"movement_command_count": _movement_command_count,
		"terminals": _terminals.duplicate(true), "nearby_terminal": _nearby_terminal,
		"initial_walk_target": _world_at_grid(_layout.get("initial_walk_target_grid", [9, 11])),
		"blocked_test_position": _world_at_grid([11, 9]), "distant_terminal_id": "flightdeck",
		"asset_sources": _asset_sources.duplicate(true),
		"service_drone": {"decorative": true, "runtime_unit": false, "model_local_position": _drone_model.position, "model_local_rotation": _drone_model.rotation, "exhaust": _drone_helper.call("get_visual_snapshot")},
		"viewport_size": _viewport.size, "world_focus": _host.has_focus(),
	}, true)
	return result
