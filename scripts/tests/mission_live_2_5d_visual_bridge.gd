class_name MissionLive25DVisualBridge
extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_camera_controller.gd")
const TERRAIN_25D_VISUAL_PROJECTION_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_visual_projection.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")

@export var bridge_enabled: bool = true
@export var mission_setup_path: NodePath
@export var terrain_registry_path: NodePath
@export var map_root_2d_path: NodePath
@export var unit_registry_path: NodePath
@export var target_marker_path: NodePath
@export var order_visualizer_path: NodePath
@export var show_debug_grid: bool = false
@export var hide_2d_map_when_visible: bool = false
@export var camera_current_when_visible: bool = false
@export var sync_runtime_visuals_enabled: bool = true
@export_range(0.05, 1.0, 0.05) var runtime_visual_sync_interval_seconds: float = 0.15

var render_result: Dictionary = {}
var bridge_snapshot: Dictionary = {}
var runtime_visual_snapshot: Dictionary = {}

var _renderer = null
var _camera_controller = TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT.new()
var _visual_projection = TERRAIN_25D_VISUAL_PROJECTION_SCRIPT.new()
var _sync_accumulator: float = 0.0
var _unit_mesh: Mesh = null
var _selection_mesh: Mesh = null
var _target_mesh: Mesh = null
var _preview_mesh: Mesh = null
var _air_shadow_mesh: Mesh = null
var _unit_material_ground: StandardMaterial3D = null
var _unit_material_air: StandardMaterial3D = null
var _selection_material: StandardMaterial3D = null
var _target_material: StandardMaterial3D = null
var _preview_material: StandardMaterial3D = null
var _air_shadow_material: StandardMaterial3D = null


func _ready() -> void:
	_renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	_configure_visual_projection()
	_prepare_runtime_visual_resources()
	_ensure_camera_and_light()
	call_deferred("refresh_bridge")


func _process(delta: float) -> void:
	if not bridge_enabled or not visible or not sync_runtime_visuals_enabled:
		return
	_sync_accumulator += delta
	if _sync_accumulator < runtime_visual_sync_interval_seconds:
		return
	_sync_accumulator = 0.0
	sync_runtime_visuals()


func _exit_tree() -> void:
	render_result.clear()
	bridge_snapshot.clear()
	runtime_visual_snapshot.clear()
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
	_configure_visual_projection()
	_frame_camera(map_data)
	_set_visuals_visible(true)
	sync_runtime_visuals()
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


func get_runtime_visual_snapshot() -> Dictionary:
	return runtime_visual_snapshot.duplicate(true)


func sync_runtime_visuals() -> Dictionary:
	if not bridge_enabled or not sync_runtime_visuals_enabled:
		runtime_visual_snapshot = {
			"enabled": sync_runtime_visuals_enabled,
			"valid": false,
			"reason": "runtime_visuals_disabled",
		}
		return runtime_visual_snapshot

	var terrain_registry = get_node_or_null(terrain_registry_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	if terrain_registry == null or unit_registry == null or not unit_registry.has_method("get_all_units"):
		runtime_visual_snapshot = {
			"enabled": true,
			"valid": false,
			"reason": "registry_missing",
			"terrain_registry_present": terrain_registry != null,
			"unit_registry_present": unit_registry != null,
		}
		return runtime_visual_snapshot

	var runtime_root := _ensure_runtime_visual_root()
	var unit_container := _ensure_container(runtime_root, "UnitVisuals3D")
	var selection_container := _ensure_container(runtime_root, "SelectionVisuals3D")
	var debug_container := _ensure_container(runtime_root, "DebugLabelAnchors3D")
	var air_container := _ensure_container(runtime_root, "AirShadowVisuals3D")
	var marker_container := _ensure_container(runtime_root, "MarkerVisuals3D")
	var preview_container := _ensure_container(runtime_root, "PathPreviewVisuals3D")
	var seen_units: PackedStringArray = []
	var unit_snapshots: Dictionary = {}
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not (unit is Node2D):
			continue
		var unit_id: String = _extract_unit_id(unit)
		if unit_id.is_empty():
			continue
		seen_units.append(_sanitize_node_key(unit_id))
		var projection: Dictionary = Dictionary(_visual_projection.call("project_node2d", unit, terrain_registry))
		if not bool(projection.get("valid", false)):
			continue
		_sync_unit_visual(unit_id, unit, projection, unit_container, selection_container, debug_container, air_container)
		unit_snapshots[unit_id] = _projection_snapshot(projection)

	_remove_stale_visuals(unit_container, seen_units)
	_remove_stale_visuals(selection_container, seen_units)
	_remove_stale_visuals(debug_container, seen_units)
	_remove_stale_visuals(air_container, seen_units)
	var target_snapshot: Dictionary = _sync_target_marker_visual(terrain_registry, marker_container)
	var preview_snapshot: Dictionary = _sync_path_preview_visuals(terrain_registry, preview_container)
	runtime_visual_snapshot = {
		"enabled": true,
		"valid": true,
		"unit_count": unit_snapshots.size(),
		"units": unit_snapshots,
		"target_marker": target_snapshot,
		"path_preview": preview_snapshot,
		"has_runtime_root": runtime_root != null,
		"has_unit_container": unit_container != null,
		"has_selection_container": selection_container != null,
		"has_debug_container": debug_container != null,
		"has_air_shadow_container": air_container != null,
		"has_marker_container": marker_container != null,
		"has_preview_container": preview_container != null,
	}
	return runtime_visual_snapshot


func _configure_visual_projection() -> void:
	var cell_size: float = float(_renderer.call("get_grid_cell_size")) if _renderer != null else 2.0
	var height_step: float = float(_renderer.call("get_grid_height_step")) if _renderer != null else 0.35
	_visual_projection.call("configure_grid", cell_size, height_step)


func _prepare_runtime_visual_resources() -> void:
	if _unit_mesh == null:
		var unit_mesh := CylinderMesh.new()
		unit_mesh.top_radius = 0.28
		unit_mesh.bottom_radius = 0.34
		unit_mesh.height = 0.55
		unit_mesh.radial_segments = 12
		_unit_mesh = unit_mesh
	if _selection_mesh == null:
		var selection_mesh := CylinderMesh.new()
		selection_mesh.top_radius = 0.48
		selection_mesh.bottom_radius = 0.48
		selection_mesh.height = 0.025
		selection_mesh.radial_segments = 24
		_selection_mesh = selection_mesh
	if _target_mesh == null:
		var target_mesh := SphereMesh.new()
		target_mesh.radius = 0.23
		target_mesh.height = 0.46
		_target_mesh = target_mesh
	if _preview_mesh == null:
		var preview_mesh := CylinderMesh.new()
		preview_mesh.top_radius = 0.25
		preview_mesh.bottom_radius = 0.25
		preview_mesh.height = 0.045
		preview_mesh.radial_segments = 18
		_preview_mesh = preview_mesh
	if _air_shadow_mesh == null:
		var air_shadow_mesh := CylinderMesh.new()
		air_shadow_mesh.top_radius = 0.5
		air_shadow_mesh.bottom_radius = 0.5
		air_shadow_mesh.height = 0.02
		air_shadow_mesh.radial_segments = 24
		_air_shadow_mesh = air_shadow_mesh
	_unit_material_ground = _ensure_material(_unit_material_ground, Color(0.25, 0.68, 1.0, 1.0), false)
	_unit_material_air = _ensure_material(_unit_material_air, Color(1.0, 0.68, 0.24, 1.0), false)
	_selection_material = _ensure_material(_selection_material, Color(0.7, 0.95, 1.0, 0.55), true)
	_target_material = _ensure_material(_target_material, Color(1.0, 0.85, 0.18, 1.0), false)
	_preview_material = _ensure_material(_preview_material, Color(0.5, 0.95, 0.65, 0.72), true)
	_air_shadow_material = _ensure_material(_air_shadow_material, Color(0.02, 0.03, 0.04, 0.32), true)


func _ensure_material(existing_material: StandardMaterial3D, color: Color, transparent: bool) -> StandardMaterial3D:
	if existing_material != null:
		return existing_material
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = false
	return material


func _ensure_runtime_visual_root() -> Node3D:
	var root := get_node_or_null("RuntimeVisual3D") as Node3D
	if root != null:
		return root
	root = Node3D.new()
	root.name = "RuntimeVisual3D"
	add_child(root)
	return root


func _ensure_container(parent: Node3D, node_name: String) -> Node3D:
	var container := parent.get_node_or_null(node_name) as Node3D
	if container != null:
		return container
	container = Node3D.new()
	container.name = node_name
	parent.add_child(container)
	return container


func _sync_unit_visual(unit_id: String, unit: Node2D, projection: Dictionary, unit_container: Node3D, selection_container: Node3D, debug_container: Node3D, air_container: Node3D) -> void:
	var key: String = _sanitize_node_key(unit_id)
	var movement_layer: String = String(projection.get("movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND))
	var is_air: bool = MOVEMENT_LAYER_SCRIPT.is_air_layer(movement_layer)
	var unit_visual := _ensure_mesh_instance(unit_container, key, "Unit_", _unit_mesh)
	unit_visual.position = Vector3(projection.get("visual_position_3d", Vector3.ZERO))
	unit_visual.material_override = _unit_material_air if is_air else _unit_material_ground
	unit_visual.visible = true

	var selection_visual := _ensure_mesh_instance(selection_container, key, "Selection_", _selection_mesh)
	selection_visual.position = Vector3(projection.get("selection_position_3d", Vector3.ZERO))
	selection_visual.material_override = _selection_material
	selection_visual.visible = unit.has_method("is_tactical_selected") and bool(unit.call("is_tactical_selected"))

	var debug_label := _ensure_debug_label(debug_container, key, unit_id)
	debug_label.position = Vector3(projection.get("debug_label_position_3d", Vector3.ZERO))
	debug_label.text = _build_debug_label_text(unit_id, projection)
	debug_label.visible = true

	var air_shadow := _ensure_mesh_instance(air_container, key, "AirShadow_", _air_shadow_mesh)
	air_shadow.position = Vector3(projection.get("shadow_position_3d", Vector3.ZERO))
	air_shadow.material_override = _air_shadow_material
	air_shadow.visible = is_air


func _sync_target_marker_visual(terrain_registry, marker_container: Node3D) -> Dictionary:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		_remove_stale_visuals(marker_container, PackedStringArray())
		return {
			"valid": false,
			"reason": "target_marker_missing",
		}
	var projection: Dictionary = Dictionary(_visual_projection.call("project_marker2d", target_marker, terrain_registry))
	if not bool(projection.get("valid", false)):
		return projection
	var marker_visual := _ensure_mesh_instance(marker_container, "target_marker", "Target_", _target_mesh)
	marker_visual.position = Vector3(projection.get("target_position_3d", Vector3.ZERO))
	marker_visual.material_override = _target_material
	marker_visual.visible = target_marker.visible
	_remove_stale_visuals(marker_container, PackedStringArray(["target_marker"]))
	var snapshot: Dictionary = _projection_snapshot(projection)
	snapshot["visible"] = marker_visual.visible
	return snapshot


func _sync_path_preview_visuals(terrain_registry, preview_container: Node3D) -> Dictionary:
	var order_visualizer = get_node_or_null(order_visualizer_path)
	if order_visualizer == null:
		_remove_stale_visuals(preview_container, PackedStringArray())
		return {
			"valid": false,
			"reason": "order_visualizer_missing",
			"preview_count": 0,
		}
	var seen_keys: PackedStringArray = []
	var preview_count: int = 0
	if order_visualizer.has_method("get_visible_waypoints"):
		var waypoint_index: int = 0
		for waypoint_variant in Array(order_visualizer.call("get_visible_waypoints")):
			if typeof(waypoint_variant) != TYPE_DICTIONARY:
				continue
			var waypoint: Dictionary = Dictionary(waypoint_variant)
			if typeof(waypoint.get("position", null)) != TYPE_VECTOR2:
				continue
			var key: String = "waypoint_%d" % waypoint_index
			_sync_preview_marker(preview_container, key, Vector2(waypoint.get("position", Vector2.ZERO)), terrain_registry)
			seen_keys.append(key)
			waypoint_index += 1
			preview_count += 1
	if order_visualizer.has_method("get_visible_area_orders"):
		var area_index: int = 0
		for area_variant in Array(order_visualizer.call("get_visible_area_orders")):
			if typeof(area_variant) != TYPE_DICTIONARY:
				continue
			var area_order: Dictionary = Dictionary(area_variant)
			if typeof(area_order.get("center_position", null)) == TYPE_VECTOR2:
				var center_key: String = "area_%d_center" % area_index
				_sync_preview_marker(preview_container, center_key, Vector2(area_order.get("center_position", Vector2.ZERO)), terrain_registry)
				seen_keys.append(center_key)
				preview_count += 1
			var tile_index: int = 0
			for tile_position_variant in Array(area_order.get("tile_world_positions", [])):
				if typeof(tile_position_variant) != TYPE_VECTOR2:
					continue
				var tile_key: String = "area_%d_tile_%d" % [area_index, tile_index]
				_sync_preview_marker(preview_container, tile_key, Vector2(tile_position_variant), terrain_registry)
				seen_keys.append(tile_key)
				tile_index += 1
				preview_count += 1
			area_index += 1
	_remove_stale_visuals(preview_container, seen_keys)
	return {
		"valid": true,
		"preview_count": preview_count,
	}


func _sync_preview_marker(preview_container: Node3D, key: String, world_position: Vector2, terrain_registry) -> void:
	var projection: Dictionary = Dictionary(_visual_projection.call("project_world_position", world_position, terrain_registry, {
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))
	if not bool(projection.get("valid", false)):
		return
	var preview_visual := _ensure_mesh_instance(preview_container, key, "Preview_", _preview_mesh)
	preview_visual.position = Vector3(projection.get("marker_position_3d", Vector3.ZERO))
	preview_visual.material_override = _preview_material
	preview_visual.visible = true


func _ensure_mesh_instance(container: Node3D, key: String, prefix: String, mesh: Mesh) -> MeshInstance3D:
	var node_name: String = "%s%s" % [prefix, key]
	var mesh_instance := container.get_node_or_null(node_name) as MeshInstance3D
	if mesh_instance != null:
		return mesh_instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	container.add_child(mesh_instance)
	return mesh_instance


func _ensure_debug_label(container: Node3D, key: String, unit_id: String) -> Label3D:
	var node_name: String = "Debug_%s" % key
	var label := container.get_node_or_null(node_name) as Label3D
	if label != null:
		return label
	label = Label3D.new()
	label.name = node_name
	label.text = unit_id
	label.font_size = 24
	label.modulate = Color(0.9, 0.96, 1.0, 1.0)
	label.outline_size = 4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	container.add_child(label)
	return label


func _remove_stale_visuals(container: Node3D, seen_keys: PackedStringArray) -> void:
	if container == null:
		return
	for child in container.get_children():
		var child_name: String = String(child.name)
		var key: String = child_name
		var separator_index: int = child_name.find("_")
		if separator_index >= 0:
			key = child_name.substr(separator_index + 1)
		if not seen_keys.has(key):
			child.queue_free()


func _projection_snapshot(projection: Dictionary) -> Dictionary:
	return {
		"valid": bool(projection.get("valid", false)),
		"grid_position": Vector2i(projection.get("grid_position", Vector2i.ZERO)),
		"continuous_grid_position": Vector2(projection.get("continuous_grid_position", Vector2.ZERO)),
		"floor_index": int(projection.get("floor_index", 0)),
		"floor_height": float(projection.get("floor_height", 0.0)),
		"movement_layer": String(projection.get("movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND)),
		"altitude_band": int(projection.get("altitude_band", 0)),
		"air_height": float(projection.get("air_height", 0.0)),
		"visual_position_3d": Vector3(projection.get("visual_position_3d", Vector3.ZERO)),
		"selection_position_3d": Vector3(projection.get("selection_position_3d", Vector3.ZERO)),
		"target_position_3d": Vector3(projection.get("target_position_3d", Vector3.ZERO)),
		"debug_label_position_3d": Vector3(projection.get("debug_label_position_3d", Vector3.ZERO)),
		"shadow_position_3d": Vector3(projection.get("shadow_position_3d", Vector3.ZERO)),
	}


func _extract_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	if unit != null:
		return String(unit.name).strip_edges()
	return ""


func _sanitize_node_key(value: String) -> String:
	var key: String = value.strip_edges()
	for needle in ["/", "\\", ":", " ", ".", "-"]:
		key = key.replace(needle, "_")
	return key


func _build_debug_label_text(unit_id: String, projection: Dictionary) -> String:
	var movement_layer: String = String(projection.get("movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND)).to_upper()
	if MOVEMENT_LAYER_SCRIPT.is_air_layer(movement_layer):
		return "%s AIR %d" % [unit_id, int(projection.get("altitude_band", 0))]
	return "%s F%d" % [unit_id, int(projection.get("floor_index", 0))]


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
