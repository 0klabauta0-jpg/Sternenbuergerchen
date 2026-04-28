class_name MissionLive25DVisualBridge
extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_camera_controller.gd")

@export var bridge_enabled: bool = true
@export var mission_setup_path: NodePath
@export var terrain_registry_path: NodePath
@export var map_root_2d_path: NodePath
@export var show_debug_grid: bool = false
@export var hide_2d_map_when_visible: bool = false
@export var camera_current_when_visible: bool = false

var render_result: Dictionary = {}
var bridge_snapshot: Dictionary = {}

var _renderer = null
var _camera_controller = TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT.new()


func _ready() -> void:
	_renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	_ensure_camera_and_light()
	call_deferred("refresh_bridge")


func _exit_tree() -> void:
	render_result.clear()
	bridge_snapshot.clear()
	_renderer = null


func refresh_bridge() -> Dictionary:
	if not bridge_enabled:
		_set_visuals_visible(false)
		bridge_snapshot = {
			"enabled": false,
			"valid": false,
			"reason": "bridge_disabled",
		}
		return bridge_snapshot

	var map_data = _resolve_live_map_data()
	if map_data == null or not map_data.has_method("get_tiles") or Array(map_data.call("get_tiles")).is_empty():
		_set_visuals_visible(false)
		bridge_snapshot = {
			"enabled": true,
			"valid": false,
			"reason": "map_data_missing",
		}
		return bridge_snapshot

	var map_root_3d := _ensure_map_root_3d()
	render_result = Dictionary(_renderer.call("render_map", map_data, map_root_3d, {"show_debug_grid": show_debug_grid}))
	_frame_camera(map_data)
	_set_visuals_visible(true)
	bridge_snapshot = _build_bridge_snapshot(map_data)
	return bridge_snapshot


func set_bridge_visible(is_visible: bool) -> void:
	visible = is_visible
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		camera.current = is_visible and camera_current_when_visible
	_update_2d_map_visibility()


func get_bridge_snapshot() -> Dictionary:
	return bridge_snapshot.duplicate(true)


func get_render_result() -> Dictionary:
	return render_result.duplicate(true)


func _resolve_live_map_data():
	var mission_setup = get_node_or_null(mission_setup_path)
	if mission_setup != null and mission_setup.has_method("get_loaded_terrain_map_data"):
		var loaded_map_data = mission_setup.call("get_loaded_terrain_map_data")
		if loaded_map_data != null and loaded_map_data.has_method("get_tiles") and not Array(loaded_map_data.call("get_tiles")).is_empty():
			return loaded_map_data

	if mission_setup != null:
		var map_path: String = String(mission_setup.get("map_file_path")).strip_edges()
		if not map_path.is_empty() and FileAccess.file_exists(map_path):
			var fallback_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_path)
			if fallback_map_data != null and fallback_map_data.has_method("get_tiles") and not Array(fallback_map_data.call("get_tiles")).is_empty():
				return fallback_map_data

	return null


func _build_bridge_snapshot(map_data) -> Dictionary:
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var terrain_registry = get_node_or_null(terrain_registry_path)
	var registry_tile_count: int = 0
	if terrain_registry != null and terrain_registry.has_method("get_all_tiles"):
		registry_tile_count = Array(terrain_registry.call("get_all_tiles")).size()
	var map_tile_count: int = Array(map_data.call("get_tiles")).size()
	var object_count: int = int(stats.get("object_count", 0))
	return {
		"enabled": true,
		"valid": true,
		"map_name": String(map_data.call("get_map_name")) if map_data.has_method("get_map_name") else "",
		"map_tile_count": map_tile_count,
		"registry_tile_count": registry_tile_count,
		"terrain_count": int(stats.get("terrain_count", 0)),
		"object_count": object_count,
		"missing_models": Array(stats.get("missing_models", [])).duplicate(true),
		"terrain_matches_map": int(stats.get("terrain_count", 0)) == map_tile_count,
		"registry_matches_map": registry_tile_count == 0 or registry_tile_count == map_tile_count,
		"has_terrain_container": get_node_or_null("MapRoot3D/Terrain3D") != null,
		"has_object_container": get_node_or_null("MapRoot3D/Object3D") != null,
		"show_debug_grid": show_debug_grid,
		"camera_current_when_visible": camera_current_when_visible,
		"hide_2d_map_when_visible": hide_2d_map_when_visible,
	}


func _ensure_map_root_3d() -> Node3D:
	var map_root := get_node_or_null("MapRoot3D") as Node3D
	if map_root != null:
		return map_root
	map_root = Node3D.new()
	map_root.name = "MapRoot3D"
	add_child(map_root)
	return map_root


func _ensure_camera_and_light() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 30.0
	camera.current = visible and camera_current_when_visible
	_camera_controller.camera_size = camera.size
	_camera_controller.call("bind_camera", camera)

	var light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light == null:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		add_child(light)
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.45


func _frame_camera(map_data) -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null or map_data == null:
		return
	var grid_size: Vector2i = Vector2i(map_data.call("get_grid_size")) if map_data.has_method("get_grid_size") else Vector2i(32, 32)
	var cell_size: float = float(_renderer.call("get_grid_cell_size")) if _renderer != null else 2.0
	var focus := Vector3(
		maxf(float(grid_size.x - 1) * cell_size * 0.5, 0.0),
		0.0,
		maxf(float(grid_size.y - 1) * cell_size * 0.5, 0.0)
	)
	var camera_size: float = maxf(float(maxi(grid_size.x, grid_size.y)) * cell_size * 0.82, 12.0)
	_camera_controller.call("frame_focus", focus, camera_size, 35.5, 12.9, 9.0)


func _set_visuals_visible(is_visible: bool) -> void:
	visible = is_visible
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		camera.current = is_visible and camera_current_when_visible
	_update_2d_map_visibility()


func _update_2d_map_visibility() -> void:
	var map_root_2d = get_node_or_null(map_root_2d_path)
	if map_root_2d != null and map_root_2d is CanvasItem:
		(map_root_2d as CanvasItem).visible = not (hide_2d_map_when_visible and visible)
