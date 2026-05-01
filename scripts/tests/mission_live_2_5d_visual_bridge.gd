class_name MissionLive25DVisualBridge
extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_camera_controller.gd")
const TERRAIN_25D_VISUAL_PROJECTION_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_visual_projection.gd")
const TERRAIN_25D_PICKER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_picker.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")

const FRIENDLY_TEAM_ID: String = "team_alpha"
const LEGACY_2D_VISUAL_META_KEY: String = "task_149_legacy_2d_visible"
const LEGACY_2D_OVERLAY_META_KEY: String = "task_150_legacy_2d_overlay_visible"
const FRIENDLY_UNIT_MODEL_PATH: String = "res://Assets/kenney_space-kit/Models/GLTF format/astronautA.glb"
const ENEMY_UNIT_MODEL_PATH: String = "res://Assets/kenney_space-kit/Models/GLTF format/astronautB.glb"
const UNIT_MODEL_TARGET_HEIGHT: float = 0.88
const DROPSHIP_MODEL_TYPE_ID: String = "fahrzeug_speeder_b"
const DROPSHIP_MODEL_PATH: String = "res://Assets/kenney_space-kit/3d/craft_speederB.glb"
const DROPSHIP_MARKER_BASE_Y_OFFSET: float = 0.18
const DROPSHIP_FALLBACK_SCALE: float = 1.48
const SCREEN_UNIT_HIT_RADIUS: float = 30.0
const SCREEN_WAYPOINT_HIT_RADIUS: float = 22.0
const SCREEN_AREA_HIT_RADIUS: float = 34.0
const AREA_ORDER_ISO_TILE_HALF_WIDTH: float = 64.0
const AREA_ORDER_ISO_TILE_HALF_HEIGHT: float = 32.0
const SECURITY_SECTOR_RADIUS: float = 74.0
const TACTICAL_OVERLAY_Y_OFFSET: float = 0.1

@export var bridge_enabled: bool = true
@export var mission_setup_path: NodePath
@export var terrain_registry_path: NodePath
@export var map_root_2d_path: NodePath
@export var unit_registry_path: NodePath
@export var target_marker_path: NodePath
@export var lz_marker_path: NodePath
@export var dropship_marker_path: NodePath
@export var order_visualizer_path: NodePath
@export var contact_overlay_path: NodePath
@export var show_debug_grid: bool = false
@export var hide_2d_map_when_visible: bool = false
@export var camera_current_when_visible: bool = false
@export var camera_controls_enabled: bool = true
@export var camera_pan_speed: float = 15.0
@export var camera_zoom_step: float = 1.4
@export var camera_min_size: float = 5.0
@export var camera_max_size: float = 42.0
@export var keyboard_fallback_toggle_enabled: bool = true
@export var sync_runtime_visuals_enabled: bool = true
@export var show_runtime_debug_labels: bool = false
@export var use_character_unit_models: bool = true
@export var unit_model_target_height: float = UNIT_MODEL_TARGET_HEIGHT
@export var dropship_visual_type_id: String = DROPSHIP_MODEL_TYPE_ID
@export var dropship_visual_scale_multiplier: float = 1.0
@export var hide_2d_unit_sprites_when_primary: bool = true
@export var hide_2d_mission_overlays_when_primary: bool = true
@export var legacy_2d_mission_overlay_paths: Array[NodePath] = []
@export_range(0.05, 1.0, 0.05) var runtime_visual_sync_interval_seconds: float = 0.15

var render_result: Dictionary = {}
var bridge_snapshot: Dictionary = {}
var runtime_visual_snapshot: Dictionary = {}
var last_pick_snapshot: Dictionary = {}
var _2d_fallback_compare_visible: bool = false
var _is_camera_panning: bool = false

var _renderer = null
var _camera_controller = TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT.new()
var _visual_projection = TERRAIN_25D_VISUAL_PROJECTION_SCRIPT.new()
var _picker = TERRAIN_25D_PICKER_SCRIPT.new()
var _sync_accumulator: float = 0.0
var _unit_mesh: Mesh = null
var _unit_head_mesh: Mesh = null
var _unit_badge_mesh: Mesh = null
var _unit_lead_mesh: Mesh = null
var _selection_mesh: Mesh = null
var _target_mesh: Mesh = null
var _lz_mesh: Mesh = null
var _preview_mesh: Mesh = null
var _area_tile_mesh: Mesh = null
var _air_shadow_mesh: Mesh = null
var _dropship_fallback_mesh: Mesh = null
var _friendly_unit_scene: PackedScene = null
var _enemy_unit_scene: PackedScene = null
var _dropship_scene: PackedScene = null
var _dropship_scene_model_path: String = ""
var _unit_material_ground: StandardMaterial3D = null
var _unit_material_air: StandardMaterial3D = null
var _unit_material_friendly: StandardMaterial3D = null
var _unit_material_enemy: StandardMaterial3D = null
var _unit_material_neutral: StandardMaterial3D = null
var _unit_material_friendly_air: StandardMaterial3D = null
var _unit_material_enemy_air: StandardMaterial3D = null
var _unit_head_material: StandardMaterial3D = null
var _unit_lead_material: StandardMaterial3D = null
var _selection_material: StandardMaterial3D = null
var _target_material: StandardMaterial3D = null
var _lz_material: StandardMaterial3D = null
var _preview_material: StandardMaterial3D = null
var _area_material_defensive: StandardMaterial3D = null
var _area_material_offensive: StandardMaterial3D = null
var _area_material_take: StandardMaterial3D = null
var _area_material_neutral: StandardMaterial3D = null
var _area_preview_material: StandardMaterial3D = null
var _ad_hoc_material: StandardMaterial3D = null
var _security_material: StandardMaterial3D = null
var _contact_confirmed_material: StandardMaterial3D = null
var _contact_suspected_material: StandardMaterial3D = null
var _contact_lost_material: StandardMaterial3D = null
var _air_shadow_material: StandardMaterial3D = null
var _dropship_material: StandardMaterial3D = null
var _approach_material: StandardMaterial3D = null
var _fireteam_materials: Dictionary = {}


func _ready() -> void:
	set_process_unhandled_input(true)
	_renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	_configure_visual_projection()
	_prepare_runtime_visual_resources()
	_ensure_camera_and_light()
	call_deferred("refresh_bridge")


func _process(delta: float) -> void:
	_process_camera_controls(delta)
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
	last_pick_snapshot.clear()
	_renderer = null


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if keyboard_fallback_toggle_enabled and key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_F7:
		set_2d_fallback_visible(not is_2d_fallback_visible())
		get_viewport().set_input_as_handled()
		return

	if not _should_handle_camera_controls():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed and not _is_pointer_over_control():
			zoom_camera_by_steps(-1)
			get_viewport().set_input_as_handled()
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed and not _is_pointer_over_control():
			zoom_camera_by_steps(1)
			get_viewport().set_input_as_handled()
			return
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_camera_panning = mouse_event.pressed and not _is_pointer_over_control()
			if mouse_event.pressed:
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_camera_panning:
		var mouse_motion := event as InputEventMouseMotion
		var drag_direction := Vector2(-mouse_motion.relative.x, mouse_motion.relative.y)
		_pan_camera_from_input(drag_direction, get_camera_size() * 0.018)
		get_viewport().set_input_as_handled()


func pan_camera_by_local(input_direction: Vector2, amount: float = -1.0) -> void:
	if amount < 0.0:
		amount = camera_pan_speed * 0.016 * maxf(get_camera_size() / 20.0, 0.55)
	_pan_camera_from_input(input_direction, amount)


func zoom_camera_by_steps(step_count: int) -> void:
	_camera_controller.zoom_step = camera_zoom_step
	_camera_controller.min_size = camera_min_size
	_camera_controller.max_size = camera_max_size
	_camera_controller.call("zoom_by_steps", step_count)


func get_camera_focus() -> Vector3:
	return Vector3(_camera_controller.call("get_focus"))


func get_camera_size() -> float:
	return float(_camera_controller.call("get_camera_size"))


func _process_camera_controls(delta: float) -> void:
	if not _should_handle_camera_controls() or _is_pointer_over_control():
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if direction == Vector2.ZERO:
		return
	_pan_camera_from_input(direction, camera_pan_speed * delta * maxf(get_camera_size() / 20.0, 0.55))


func _pan_camera_from_input(input_direction: Vector2, amount: float) -> void:
	if input_direction == Vector2.ZERO or amount <= 0.0:
		return
	_camera_controller.call("pan_by_local", input_direction.normalized(), amount)


func _should_handle_camera_controls() -> bool:
	return camera_controls_enabled and is_primary_3d_view_active() and not is_2d_fallback_visible()


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


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
	_update_legacy_2d_unit_visual_visibility()
	_update_legacy_2d_mission_overlay_visibility()


func set_2d_fallback_visible(is_visible: bool) -> void:
	_2d_fallback_compare_visible = is_visible
	hide_2d_map_when_visible = not is_visible
	_update_2d_map_visibility()
	_update_legacy_2d_unit_visual_visibility()
	_update_legacy_2d_mission_overlay_visibility()
	if bool(bridge_snapshot.get("valid", false)):
		bridge_snapshot["hide_2d_map_when_visible"] = hide_2d_map_when_visible
		bridge_snapshot["fallback_2d_visible"] = is_2d_fallback_visible()


func is_2d_fallback_visible() -> bool:
	var map_root_2d = get_node_or_null(map_root_2d_path)
	if map_root_2d != null and map_root_2d is CanvasItem:
		return (map_root_2d as CanvasItem).visible
	return _2d_fallback_compare_visible


func is_primary_3d_view_active() -> bool:
	var camera := get_node_or_null("Camera3D") as Camera3D
	return bridge_enabled and visible and camera != null and camera.current


func get_bridge_snapshot() -> Dictionary:
	return bridge_snapshot.duplicate(true)


func get_render_result() -> Dictionary:
	return render_result.duplicate(true)


func get_runtime_visual_snapshot() -> Dictionary:
	return runtime_visual_snapshot.duplicate(true)


func get_legacy_2d_mission_visual_audit() -> Dictionary:
	var map_root_2d = get_node_or_null(map_root_2d_path)
	var map_visible: bool = map_root_2d != null and map_root_2d is CanvasItem and (map_root_2d as CanvasItem).visible
	var unit_registry = get_node_or_null(unit_registry_path)
	var unit_count: int = 0
	var hidden_unit_visual_count: int = 0
	var visible_unit_visual_count: int = 0
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		for unit in Array(unit_registry.call("get_all_units")):
			if unit == null or not (unit is Node2D):
				continue
			unit_count += 1
			hidden_unit_visual_count += _count_hidden_legacy_2d_unit_visuals(unit)
			visible_unit_visual_count += _count_visible_legacy_2d_unit_visuals(unit)
	var overlay_audit: Dictionary = _get_legacy_2d_mission_overlay_audit()
	return {
		"valid": true,
		"primary_3d_view_active": is_primary_3d_view_active(),
		"fallback_2d_visible": is_2d_fallback_visible(),
		"map_root_2d_path": String(map_root_2d_path),
		"map_root_2d_present": map_root_2d != null,
		"map_root_2d_visible": map_visible,
		"hide_2d_map_when_visible": hide_2d_map_when_visible,
		"unit_count": unit_count,
		"visible_legacy_unit_visual_count": visible_unit_visual_count,
		"hidden_legacy_unit_visual_count": hidden_unit_visual_count,
		"hide_2d_unit_sprites_when_primary": hide_2d_unit_sprites_when_primary,
		"visible_legacy_overlay_count": int(overlay_audit.get("visible_count", 0)),
		"hidden_legacy_overlay_count": int(overlay_audit.get("hidden_count", 0)),
		"missing_legacy_overlay_count": int(overlay_audit.get("missing_count", 0)),
		"legacy_overlay_paths": Array(overlay_audit.get("paths", [])).duplicate(true),
		"hide_2d_mission_overlays_when_primary": hide_2d_mission_overlays_when_primary,
	}


func pick_screen_position(screen_position: Vector2, options: Dictionary = {}) -> Dictionary:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		last_pick_snapshot = {
			"valid": false,
			"reason": "camera_missing",
		}
		return last_pick_snapshot.duplicate(true)
	var terrain_registry = get_node_or_null(terrain_registry_path)
	var pick_options := options.duplicate(true)
	if not pick_options.has("floor_mode"):
		pick_options["floor_mode"] = "highest"
	last_pick_snapshot = Dictionary(_picker.call("pick_screen", camera, screen_position, terrain_registry, pick_options))
	return last_pick_snapshot.duplicate(true)


func get_last_pick_snapshot() -> Dictionary:
	return last_pick_snapshot.duplicate(true)


func build_area_order_payload_from_screen_rect(screen_rect: Rect2) -> Dictionary:
	if not _should_use_primary_3d_interaction():
		return {}
	var normalized_rect: Rect2 = _normalize_screen_rect(screen_rect)
	if normalized_rect.size.x <= 0.0 or normalized_rect.size.y <= 0.0:
		return {}
	var terrain_registry = get_node_or_null(terrain_registry_path)
	if terrain_registry == null:
		return {}
	var tile_entries: Array = _get_tile_entries_in_screen_rect(normalized_rect, terrain_registry)
	if not tile_entries.is_empty():
		return _build_area_order_payload_from_tile_entries(tile_entries)
	return _build_area_order_payload_from_screen_rect_corners(normalized_rect, terrain_registry)


func project_world_position_to_screen(world_position: Vector2, use_base_position: bool = false) -> Dictionary:
	if not _should_use_primary_3d_interaction():
		return {"valid": false, "reason": "primary_3d_inactive"}
	var terrain_registry = get_node_or_null(terrain_registry_path)
	if terrain_registry == null:
		return {"valid": false, "reason": "terrain_registry_missing"}
	return _project_world_position_to_screen(world_position, terrain_registry, use_base_position)


func get_waypoint_hit(screen_position: Vector2) -> Dictionary:
	if not _should_use_primary_3d_interaction():
		return {}
	var order_visualizer = get_node_or_null(order_visualizer_path)
	var terrain_registry = get_node_or_null(terrain_registry_path)
	if order_visualizer == null or terrain_registry == null or not order_visualizer.has_method("get_visible_waypoints"):
		return {}
	var best_hit: Dictionary = {}
	var best_distance: float = SCREEN_WAYPOINT_HIT_RADIUS
	for waypoint_variant in Array(order_visualizer.call("get_visible_waypoints")):
		if typeof(waypoint_variant) != TYPE_DICTIONARY:
			continue
		var waypoint: Dictionary = Dictionary(waypoint_variant)
		if typeof(waypoint.get("position", null)) != TYPE_VECTOR2:
			continue
		var screen_result: Dictionary = _project_world_position_to_screen(Vector2(waypoint.get("position", Vector2.ZERO)), terrain_registry)
		if not bool(screen_result.get("valid", false)):
			continue
		var distance: float = Vector2(screen_result.get("screen_position", Vector2.ZERO)).distance_to(screen_position)
		if distance > best_distance:
			continue
		best_distance = distance
		best_hit = waypoint.duplicate(true)
	return best_hit


func get_area_order_hit(screen_position: Vector2) -> Dictionary:
	if not _should_use_primary_3d_interaction():
		return {}
	var order_visualizer = get_node_or_null(order_visualizer_path)
	var terrain_registry = get_node_or_null(terrain_registry_path)
	if order_visualizer == null or terrain_registry == null or not order_visualizer.has_method("get_visible_area_orders"):
		return {}
	var best_hit: Dictionary = {}
	var best_distance: float = SCREEN_AREA_HIT_RADIUS
	for area_variant in Array(order_visualizer.call("get_visible_area_orders")):
		if typeof(area_variant) != TYPE_DICTIONARY:
			continue
		var area_order: Dictionary = Dictionary(area_variant)
		var candidate_positions: Array = []
		if typeof(area_order.get("center_position", null)) == TYPE_VECTOR2:
			candidate_positions.append(Vector2(area_order.get("center_position", Vector2.ZERO)))
		for tile_position_variant in Array(area_order.get("tile_world_positions", [])):
			if typeof(tile_position_variant) == TYPE_VECTOR2:
				candidate_positions.append(Vector2(tile_position_variant))
		for world_position_variant in candidate_positions:
			var screen_result: Dictionary = _project_world_position_to_screen(Vector2(world_position_variant), terrain_registry)
			if not bool(screen_result.get("valid", false)):
				continue
			var distance: float = Vector2(screen_result.get("screen_position", Vector2.ZERO)).distance_to(screen_position)
			if distance > best_distance:
				continue
			best_distance = distance
			best_hit = area_order.duplicate(true)
	return best_hit


func get_unit_hit(screen_position: Vector2, friendly_only: bool = true) -> Dictionary:
	if not _should_use_primary_3d_interaction():
		return {}
	var terrain_registry = get_node_or_null(terrain_registry_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	if terrain_registry == null or unit_registry == null or not unit_registry.has_method("get_all_units"):
		return {}
	var best_hit: Dictionary = {}
	var best_distance: float = SCREEN_UNIT_HIT_RADIUS
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not (unit is Node2D) or not (unit as Node2D).is_visible_in_tree():
			continue
		var team_id: String = _extract_unit_method_string(unit, "get_team_id")
		if friendly_only and team_id != FRIENDLY_TEAM_ID:
			continue
		var projection: Dictionary = Dictionary(_visual_projection.call("project_node2d", unit, terrain_registry))
		if not bool(projection.get("valid", false)):
			continue
		var camera := get_node_or_null("Camera3D") as Camera3D
		if camera == null:
			continue
		var screen_position_3d: Vector2 = camera.unproject_position(Vector3(projection.get("visual_position_3d", Vector3.ZERO)))
		var distance: float = screen_position_3d.distance_to(screen_position)
		if distance > best_distance:
			continue
		best_distance = distance
		best_hit = {
			"unit_id": _extract_unit_id(unit),
			"fireteam_id": _extract_unit_method_string(unit, "get_fireteam_id"),
			"team_id": team_id,
			"screen_position": screen_position_3d,
		}
	return best_hit


func get_unit_hits_in_screen_rect(screen_rect: Rect2, friendly_only: bool = true) -> Array:
	if not _should_use_primary_3d_interaction():
		return []
	var normalized_rect: Rect2 = _normalize_screen_rect(screen_rect)
	if normalized_rect.size.x <= 0.0 or normalized_rect.size.y <= 0.0:
		return []
	var terrain_registry = get_node_or_null(terrain_registry_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var camera := get_node_or_null("Camera3D") as Camera3D
	if terrain_registry == null or unit_registry == null or camera == null or not unit_registry.has_method("get_all_units"):
		return []
	var hits: Array = []
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not (unit is Node2D) or not (unit as Node2D).is_visible_in_tree():
			continue
		var team_id: String = _extract_unit_method_string(unit, "get_team_id")
		if friendly_only and team_id != FRIENDLY_TEAM_ID:
			continue
		var projection: Dictionary = Dictionary(_visual_projection.call("project_node2d", unit, terrain_registry))
		if not bool(projection.get("valid", false)):
			continue
		var projected_screen_position: Vector2 = camera.unproject_position(Vector3(projection.get("visual_position_3d", Vector3.ZERO)))
		if not normalized_rect.has_point(projected_screen_position):
			continue
		hits.append({
			"unit_id": _extract_unit_id(unit),
			"fireteam_id": _extract_unit_method_string(unit, "get_fireteam_id"),
			"team_id": team_id,
			"screen_position": projected_screen_position,
		})
	return hits


func get_visual_projection_config() -> Dictionary:
	return {
		"cell_size": float(_visual_projection.cell_size),
		"height_step": float(_visual_projection.height_step),
	}


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
	var tactical_overlay_container := _ensure_container(runtime_root, "TacticalOverlayVisuals3D")
	var seen_units: PackedStringArray = []
	var unit_snapshots: Dictionary = {}
	var legacy_2d_hidden_count: int = 0
	var legacy_2d_visible: bool = _should_show_legacy_2d_unit_visuals()
	_update_legacy_2d_mission_overlay_visibility()
	var overlay_audit: Dictionary = _get_legacy_2d_mission_overlay_audit()
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not (unit is Node2D):
			continue
		var unit_id: String = _extract_unit_id(unit)
		if unit_id.is_empty():
			continue
		seen_units.append(_sanitize_node_key(unit_id))
		var projection: Dictionary = Dictionary(_visual_projection.call("project_node2d", unit, terrain_registry))
		if not bool(projection.get("valid", false)):
			_set_legacy_2d_unit_visuals_visible(unit, true)
			continue
		_set_legacy_2d_unit_visuals_visible(unit, legacy_2d_visible)
		legacy_2d_hidden_count += _count_hidden_legacy_2d_unit_visuals(unit)
		var visual_descriptor: Dictionary = _sync_unit_visual(unit_id, unit, projection, unit_container, selection_container, debug_container, air_container)
		var unit_snapshot: Dictionary = _projection_snapshot(projection)
		unit_snapshot.merge(visual_descriptor, true)
		unit_snapshots[unit_id] = unit_snapshot

	_remove_stale_visuals(unit_container, seen_units)
	_remove_stale_visuals(selection_container, seen_units)
	_remove_stale_visuals(debug_container, seen_units)
	_remove_stale_visuals(air_container, seen_units)
	var marker_seen_keys: PackedStringArray = []
	var target_snapshot: Dictionary = _sync_target_marker_visual(terrain_registry, marker_container)
	if bool(target_snapshot.get("visible", false)):
		marker_seen_keys.append("target_marker")
	var strategic_marker_snapshot: Dictionary = _sync_strategic_marker_visuals(terrain_registry, marker_container)
	for marker_key in PackedStringArray(strategic_marker_snapshot.get("seen_keys", PackedStringArray())):
		if not marker_seen_keys.has(marker_key):
			marker_seen_keys.append(marker_key)
	_remove_stale_visuals(marker_container, marker_seen_keys)
	var preview_snapshot: Dictionary = _sync_path_preview_visuals(terrain_registry, preview_container)
	var tactical_overlay_snapshot: Dictionary = _sync_tactical_overlay_visuals(terrain_registry, tactical_overlay_container)
	runtime_visual_snapshot = {
		"enabled": true,
		"valid": true,
		"unit_count": unit_snapshots.size(),
		"units": unit_snapshots,
		"target_marker": target_snapshot,
		"strategic_markers": strategic_marker_snapshot,
		"path_preview": preview_snapshot,
		"tactical_overlays": tactical_overlay_snapshot,
		"runtime_debug_labels_visible": show_runtime_debug_labels,
		"legacy_2d_unit_visuals_visible": legacy_2d_visible,
		"legacy_2d_unit_visual_hidden_count": legacy_2d_hidden_count,
		"legacy_2d_mission_overlays_visible": _should_show_legacy_2d_mission_overlays(),
		"legacy_2d_mission_overlay_hidden_count": int(overlay_audit.get("hidden_count", 0)),
		"legacy_2d_mission_overlay_visible_count": int(overlay_audit.get("visible_count", 0)),
		"legacy_2d_mission_overlay_missing_count": int(overlay_audit.get("missing_count", 0)),
		"has_runtime_root": runtime_root != null,
		"has_unit_container": unit_container != null,
		"has_selection_container": selection_container != null,
		"has_debug_container": debug_container != null,
		"has_air_shadow_container": air_container != null,
		"has_marker_container": marker_container != null,
		"has_preview_container": preview_container != null,
		"has_tactical_overlay_container": tactical_overlay_container != null,
	}
	return runtime_visual_snapshot


func _should_use_primary_3d_interaction() -> bool:
	return bridge_enabled and is_primary_3d_view_active() and not is_2d_fallback_visible()


func _normalize_screen_rect(screen_rect: Rect2) -> Rect2:
	var top_left := Vector2(minf(screen_rect.position.x, screen_rect.end.x), minf(screen_rect.position.y, screen_rect.end.y))
	var bottom_right := Vector2(maxf(screen_rect.position.x, screen_rect.end.x), maxf(screen_rect.position.y, screen_rect.end.y))
	return Rect2(top_left, bottom_right - top_left)


func _get_tile_entries_in_screen_rect(screen_rect: Rect2, terrain_registry) -> Array:
	if terrain_registry == null or not terrain_registry.has_method("get_all_tiles"):
		return []
	var tile_entries: Array = []
	for tile_data in Array(terrain_registry.call("get_all_tiles")):
		if tile_data == null or typeof(tile_data.world_position) != TYPE_VECTOR2:
			continue
		var screen_result: Dictionary = _project_world_position_to_screen(Vector2(tile_data.world_position), terrain_registry, true)
		if not bool(screen_result.get("valid", false)):
			continue
		if not screen_rect.has_point(Vector2(screen_result.get("screen_position", Vector2.ZERO))):
			continue
		tile_entries.append({
			"grid_position": Vector2i(tile_data.grid_position),
			"world_position": Vector2(tile_data.world_position),
			"screen_position": Vector2(screen_result.get("screen_position", Vector2.ZERO)),
		})
	return tile_entries


func _build_area_order_payload_from_tile_entries(tile_entries: Array) -> Dictionary:
	if tile_entries.is_empty():
		return {}
	var sorted_entries: Array = []
	for entry_variant in tile_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if typeof(entry.get("grid_position", null)) != TYPE_VECTOR2I or typeof(entry.get("world_position", null)) != TYPE_VECTOR2:
			continue
		sorted_entries.append(entry)
	if sorted_entries.is_empty():
		return {}
	sorted_entries.sort_custom(_sort_area_tile_entries)
	var tile_positions: Array = []
	var tile_world_positions: Array = []
	var center_position := Vector2.ZERO
	for entry_variant in sorted_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		tile_positions.append(Vector2i(entry.get("grid_position", Vector2i.ZERO)))
		var world_position := Vector2(entry.get("world_position", Vector2.ZERO))
		tile_world_positions.append(world_position)
		center_position += world_position
	center_position /= float(tile_world_positions.size())
	return {
		"tile_positions": tile_positions,
		"tile_world_positions": tile_world_positions,
		"world_polygon": _build_area_order_world_polygon(tile_world_positions),
		"center_position": center_position,
	}


func _build_area_order_payload_from_screen_rect_corners(screen_rect: Rect2, terrain_registry) -> Dictionary:
	var corner_points: Array[Vector2] = [
		screen_rect.position,
		Vector2(screen_rect.end.x, screen_rect.position.y),
		screen_rect.end,
		Vector2(screen_rect.position.x, screen_rect.end.y),
	]
	var world_polygon := PackedVector2Array()
	for corner in corner_points:
		var world_position: Variant = _pick_screen_world_position(corner, terrain_registry)
		if typeof(world_position) != TYPE_VECTOR2:
			return {}
		world_polygon.append(Vector2(world_position))
	if world_polygon.size() < 3:
		return {}
	return {
		"tile_positions": [],
		"tile_world_positions": [],
		"world_polygon": world_polygon,
		"center_position": _average_polygon_points(world_polygon),
	}


func _project_world_position_to_screen(world_position: Vector2, terrain_registry, use_base_position: bool = false) -> Dictionary:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return {"valid": false, "reason": "camera_missing"}
	var projection: Dictionary = Dictionary(_visual_projection.call("project_world_position", world_position, terrain_registry, {
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))
	if not bool(projection.get("valid", false)):
		return projection
	var world_3d: Vector3 = Vector3(projection.get("base_position_3d", projection.get("visual_position_3d", Vector3.ZERO))) if use_base_position else Vector3(projection.get("visual_position_3d", Vector3.ZERO))
	return {
		"valid": true,
		"screen_position": camera.unproject_position(world_3d),
		"world_position_3d": world_3d,
		"projection": projection,
	}


func _pick_screen_world_position(screen_position: Vector2, terrain_registry) -> Variant:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null or terrain_registry == null:
		return null
	var pick_snapshot: Dictionary = Dictionary(_picker.call("pick_screen", camera, screen_position, terrain_registry, {"floor_mode": "highest"}))
	if not bool(pick_snapshot.get("valid", false)) or typeof(pick_snapshot.get("target_position", null)) != TYPE_VECTOR2:
		return null
	return Vector2(pick_snapshot.get("target_position", Vector2.ZERO))


func _sort_area_tile_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_grid := Vector2i(a.get("grid_position", Vector2i.ZERO))
	var b_grid := Vector2i(b.get("grid_position", Vector2i.ZERO))
	if a_grid.x == b_grid.x:
		return a_grid.y < b_grid.y
	return a_grid.x < b_grid.x


func _build_area_order_world_polygon(tile_world_positions: Array) -> PackedVector2Array:
	if tile_world_positions.is_empty():
		return PackedVector2Array()
	var hull_points := PackedVector2Array()
	for world_position_variant in tile_world_positions:
		var world_position := Vector2(world_position_variant)
		hull_points.append(world_position + Vector2(0.0, -AREA_ORDER_ISO_TILE_HALF_HEIGHT))
		hull_points.append(world_position + Vector2(AREA_ORDER_ISO_TILE_HALF_WIDTH, 0.0))
		hull_points.append(world_position + Vector2(0.0, AREA_ORDER_ISO_TILE_HALF_HEIGHT))
		hull_points.append(world_position + Vector2(-AREA_ORDER_ISO_TILE_HALF_WIDTH, 0.0))
	if hull_points.size() <= 3:
		return hull_points
	return Geometry2D.convex_hull(hull_points)


func _average_polygon_points(polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	return center / float(polygon.size())


func _configure_visual_projection() -> void:
	var cell_size: float = float(_renderer.call("get_grid_cell_size")) if _renderer != null else 2.0
	var height_step: float = float(_renderer.call("get_grid_height_step")) if _renderer != null else 0.35
	_visual_projection.call("configure_grid", cell_size, height_step)
	_picker.call("configure_grid", cell_size, height_step)


func _prepare_runtime_visual_resources() -> void:
	if _unit_mesh == null:
		var unit_mesh := CapsuleMesh.new()
		unit_mesh.radius = 0.22
		unit_mesh.height = 0.62
		unit_mesh.radial_segments = 12
		unit_mesh.rings = 4
		_unit_mesh = unit_mesh
	if _unit_head_mesh == null:
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.16
		head_mesh.height = 0.24
		_unit_head_mesh = head_mesh
	if _unit_badge_mesh == null:
		var badge_mesh := BoxMesh.new()
		badge_mesh.size = Vector3(0.42, 0.04, 0.18)
		_unit_badge_mesh = badge_mesh
	if _unit_lead_mesh == null:
		var lead_mesh := CylinderMesh.new()
		lead_mesh.top_radius = 0.0
		lead_mesh.bottom_radius = 0.16
		lead_mesh.height = 0.24
		lead_mesh.radial_segments = 4
		_unit_lead_mesh = lead_mesh
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
	if _lz_mesh == null:
		var lz_mesh := CylinderMesh.new()
		lz_mesh.top_radius = 0.88
		lz_mesh.bottom_radius = 0.88
		lz_mesh.height = 0.025
		lz_mesh.radial_segments = 48
		_lz_mesh = lz_mesh
	if _preview_mesh == null:
		var preview_mesh := CylinderMesh.new()
		preview_mesh.top_radius = 0.25
		preview_mesh.bottom_radius = 0.25
		preview_mesh.height = 0.045
		preview_mesh.radial_segments = 18
		_preview_mesh = preview_mesh
	if _area_tile_mesh == null:
		var area_tile_mesh := BoxMesh.new()
		var cell_size: float = float(_renderer.call("get_grid_cell_size")) if _renderer != null else 2.0
		area_tile_mesh.size = Vector3(cell_size * 0.88, 0.028, cell_size * 0.88)
		_area_tile_mesh = area_tile_mesh
	if _air_shadow_mesh == null:
		var air_shadow_mesh := CylinderMesh.new()
		air_shadow_mesh.top_radius = 0.5
		air_shadow_mesh.bottom_radius = 0.5
		air_shadow_mesh.height = 0.02
		air_shadow_mesh.radial_segments = 24
		_air_shadow_mesh = air_shadow_mesh
	if _dropship_fallback_mesh == null:
		var dropship_mesh := BoxMesh.new()
		dropship_mesh.size = Vector3(0.72, 0.18, 1.12)
		_dropship_fallback_mesh = dropship_mesh
	if _friendly_unit_scene == null and ResourceLoader.exists(FRIENDLY_UNIT_MODEL_PATH):
		_friendly_unit_scene = load(FRIENDLY_UNIT_MODEL_PATH) as PackedScene
	if _enemy_unit_scene == null and ResourceLoader.exists(ENEMY_UNIT_MODEL_PATH):
		_enemy_unit_scene = load(ENEMY_UNIT_MODEL_PATH) as PackedScene
	var dropship_model_path: String = _get_dropship_model_path()
	if _dropship_scene == null and ResourceLoader.exists(dropship_model_path):
		_dropship_scene = load(dropship_model_path) as PackedScene
		_dropship_scene_model_path = dropship_model_path
	_unit_material_ground = _ensure_material(_unit_material_ground, Color(0.25, 0.68, 1.0, 1.0), false)
	_unit_material_air = _ensure_material(_unit_material_air, Color(1.0, 0.68, 0.24, 1.0), false)
	_unit_material_friendly = _ensure_material(_unit_material_friendly, Color(0.2, 0.62, 1.0, 1.0), false)
	_unit_material_enemy = _ensure_material(_unit_material_enemy, Color(1.0, 0.32, 0.26, 1.0), false)
	_unit_material_neutral = _ensure_material(_unit_material_neutral, Color(0.7, 0.76, 0.78, 1.0), false)
	_unit_material_friendly_air = _ensure_material(_unit_material_friendly_air, Color(0.35, 0.92, 1.0, 1.0), false)
	_unit_material_enemy_air = _ensure_material(_unit_material_enemy_air, Color(1.0, 0.62, 0.2, 1.0), false)
	_unit_head_material = _ensure_material(_unit_head_material, Color(0.92, 0.94, 0.9, 1.0), false)
	_unit_lead_material = _ensure_material(_unit_lead_material, Color(1.0, 0.9, 0.24, 1.0), false)
	_selection_material = _ensure_material(_selection_material, Color(0.7, 0.95, 1.0, 0.55), true)
	_target_material = _ensure_material(_target_material, Color(1.0, 0.85, 0.18, 1.0), false)
	_lz_material = _ensure_material(_lz_material, Color(0.18, 0.95, 0.42, 0.38), true)
	_preview_material = _ensure_material(_preview_material, Color(0.5, 0.95, 0.65, 0.72), true)
	_area_material_defensive = _ensure_material(_area_material_defensive, Color(0.18, 0.95, 0.42, 0.30), true)
	_area_material_offensive = _ensure_material(_area_material_offensive, Color(1.0, 0.22, 0.16, 0.32), true)
	_area_material_take = _ensure_material(_area_material_take, Color(1.0, 0.78, 0.22, 0.34), true)
	_area_material_neutral = _ensure_material(_area_material_neutral, Color(0.48, 0.82, 1.0, 0.26), true)
	_area_preview_material = _ensure_material(_area_preview_material, Color(0.82, 0.95, 1.0, 0.24), true)
	_ad_hoc_material = _ensure_material(_ad_hoc_material, Color(0.96, 0.96, 0.96, 0.86), true)
	_security_material = _ensure_material(_security_material, Color(0.62, 0.86, 1.0, 0.30), true)
	_contact_confirmed_material = _ensure_material(_contact_confirmed_material, Color(1.0, 0.38, 0.28, 0.86), true)
	_contact_suspected_material = _ensure_material(_contact_suspected_material, Color(0.95, 0.9, 0.28, 0.72), true)
	_contact_lost_material = _ensure_material(_contact_lost_material, Color(0.64, 0.68, 0.72, 0.58), true)
	_air_shadow_material = _ensure_material(_air_shadow_material, Color(0.02, 0.03, 0.04, 0.32), true)
	_dropship_material = _ensure_material(_dropship_material, Color(0.56, 1.0, 0.72, 0.92), true)
	_approach_material = _ensure_material(_approach_material, Color(0.45, 1.0, 0.62, 0.62), true)


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


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.free()


func _sync_unit_visual(unit_id: String, unit: Node2D, projection: Dictionary, unit_container: Node3D, selection_container: Node3D, debug_container: Node3D, air_container: Node3D) -> Dictionary:
	var key: String = _sanitize_node_key(unit_id)
	var movement_layer: String = String(projection.get("movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND))
	var is_air: bool = MOVEMENT_LAYER_SCRIPT.is_air_layer(movement_layer)
	var descriptor: Dictionary = _build_unit_visual_descriptor(unit, projection)
	var unit_visual := _ensure_mesh_instance(unit_container, key, "Unit_", _unit_mesh)
	unit_visual.position = Vector3(projection.get("visual_position_3d", Vector3.ZERO))
	unit_visual.material_override = _get_unit_body_material(descriptor)
	unit_visual.scale = Vector3(1.08, 1.08, 1.08) if bool(descriptor.get("is_selected", false)) else Vector3.ONE
	unit_visual.visible = true
	var uses_character_model: bool = _sync_unit_character_model(unit_visual, descriptor)
	descriptor["uses_character_model"] = uses_character_model
	descriptor["character_model_path"] = _get_unit_character_model_path(descriptor) if uses_character_model else ""
	descriptor["unit_model_target_height"] = unit_model_target_height
	unit_visual.mesh = null if uses_character_model else _unit_mesh
	_sync_unit_visual_parts(unit_visual, descriptor)

	var selection_visual := _ensure_mesh_instance(selection_container, key, "Selection_", _selection_mesh)
	selection_visual.position = Vector3(projection.get("selection_position_3d", Vector3.ZERO))
	selection_visual.material_override = _selection_material
	selection_visual.visible = bool(descriptor.get("is_selected", false))

	var debug_label := _ensure_debug_label(debug_container, key, unit_id)
	debug_label.position = Vector3(projection.get("debug_label_position_3d", Vector3.ZERO))
	debug_label.text = _build_unit_debug_label_text(unit_id, descriptor, projection)
	debug_label.visible = show_runtime_debug_labels

	var air_shadow := _ensure_mesh_instance(air_container, key, "AirShadow_", _air_shadow_mesh)
	air_shadow.position = Vector3(projection.get("shadow_position_3d", Vector3.ZERO))
	air_shadow.material_override = _air_shadow_material
	air_shadow.visible = is_air
	return descriptor


func _sync_unit_visual_parts(unit_visual: MeshInstance3D, descriptor: Dictionary) -> void:
	var uses_character_model: bool = bool(descriptor.get("uses_character_model", false))
	var head := _ensure_child_mesh_instance(unit_visual, "Head", _unit_head_mesh)
	head.position = Vector3(0.0, 0.42, 0.0)
	head.material_override = _unit_head_material
	head.visible = not uses_character_model

	var team_badge := _ensure_child_mesh_instance(unit_visual, "TeamBadge", _unit_badge_mesh)
	team_badge.position = Vector3(0.0, 0.02, -0.25)
	team_badge.material_override = _get_fireteam_material(String(descriptor.get("fireteam_id", "")), bool(descriptor.get("is_friendly", false)))
	team_badge.visible = true

	var lead_marker := _ensure_child_mesh_instance(unit_visual, "LeadMarker", _unit_lead_mesh)
	var marker_height: float = unit_model_target_height + 0.16 if uses_character_model else 0.76
	lead_marker.position = Vector3(0.0, marker_height, 0.0)
	lead_marker.material_override = _unit_lead_material
	lead_marker.visible = bool(descriptor.get("is_fireteam_lead", false))

	var role_label := _ensure_unit_role_label(unit_visual)
	role_label.text = String(descriptor.get("role_badge", "OP"))
	var role_label_height: float = unit_model_target_height + 0.08 if uses_character_model else 0.62
	role_label.position = Vector3(0.0, role_label_height, 0.0)
	role_label.visible = bool(descriptor.get("is_friendly", false))
	role_label.modulate = Color(0.92, 0.96, 1.0, 1.0) if bool(descriptor.get("is_friendly", false)) else Color(1.0, 0.86, 0.82, 1.0)


func _sync_unit_character_model(unit_visual: MeshInstance3D, descriptor: Dictionary) -> bool:
	var model_path: String = _get_unit_character_model_path(descriptor)
	if model_path.is_empty():
		_remove_unit_character_model(unit_visual)
		return false
	var scene := _get_unit_character_scene(model_path)
	if scene == null:
		_remove_unit_character_model(unit_visual)
		return false
	var model_root := unit_visual.get_node_or_null("CharacterModel") as Node3D
	if model_root != null and String(model_root.get_meta("model_path", "")) != model_path:
		unit_visual.remove_child(model_root)
		model_root.free()
		model_root = null
	if model_root == null:
		model_root = Node3D.new()
		model_root.name = "CharacterModel"
		model_root.set_meta("model_path", model_path)
		var model := scene.instantiate() as Node3D
		if model == null:
			model_root.free()
			return false
		model.name = "Model"
		model.rotation_degrees.y = 180.0
		_center_and_scale_model_node_to_height(model, unit_model_target_height)
		model_root.add_child(model)
		unit_visual.add_child(model_root)
	model_root.visible = true
	return true


func _remove_unit_character_model(unit_visual: Node3D) -> void:
	var model_root := unit_visual.get_node_or_null("CharacterModel") as Node3D
	if model_root != null:
		unit_visual.remove_child(model_root)
		model_root.free()


func _get_unit_character_model_path(descriptor: Dictionary) -> String:
	if not use_character_unit_models:
		return ""
	if bool(descriptor.get("is_enemy", false)):
		return ENEMY_UNIT_MODEL_PATH
	if bool(descriptor.get("is_friendly", false)):
		return FRIENDLY_UNIT_MODEL_PATH
	return ""


func _get_unit_character_scene(model_path: String) -> PackedScene:
	if model_path == FRIENDLY_UNIT_MODEL_PATH:
		if _friendly_unit_scene == null and ResourceLoader.exists(FRIENDLY_UNIT_MODEL_PATH):
			_friendly_unit_scene = load(FRIENDLY_UNIT_MODEL_PATH) as PackedScene
		return _friendly_unit_scene
	if model_path == ENEMY_UNIT_MODEL_PATH:
		if _enemy_unit_scene == null and ResourceLoader.exists(ENEMY_UNIT_MODEL_PATH):
			_enemy_unit_scene = load(ENEMY_UNIT_MODEL_PATH) as PackedScene
		return _enemy_unit_scene
	if ResourceLoader.exists(model_path):
		return load(model_path) as PackedScene
	return null


func _center_and_scale_model_node_to_height(node: Node3D, target_height: float) -> void:
	var bounds: Dictionary = _get_local_visual_bounds(node)
	if not bool(bounds.get("valid", false)):
		return
	var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
	var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
	var source_height: float = maxf(max_value.y - min_value.y, 0.001)
	var scale_factor: float = maxf(target_height, 0.001) / source_height
	_center_model_node_on_ground(node, scale_factor, bounds)


func _center_model_node_on_ground(node: Node3D, uniform_scale: float, bounds_override: Dictionary = {}) -> void:
	var bounds: Dictionary = bounds_override if not bounds_override.is_empty() else _get_local_visual_bounds(node)
	if not bool(bounds.get("valid", false)):
		node.scale = Vector3.ONE * uniform_scale
		return
	var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
	var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
	var center: Vector3 = (min_value + max_value) * 0.5
	node.scale = Vector3.ONE * uniform_scale
	node.position = Vector3(-center.x * uniform_scale, -min_value.y * uniform_scale, -center.z * uniform_scale)


func _get_local_visual_bounds(node: Node3D) -> Dictionary:
	var bounds: Dictionary = {
		"valid": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_local_visual_bounds(node, Transform3D.IDENTITY, bounds)
	return bounds


func _accumulate_local_visual_bounds(node: Node, parent_transform: Transform3D, bounds: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		_merge_transformed_aabb(bounds, current_transform, mesh_instance.get_aabb())
	for child in node.get_children():
		_accumulate_local_visual_bounds(child, current_transform, bounds)


func _merge_transformed_aabb(bounds: Dictionary, transform: Transform3D, aabb: AABB) -> void:
	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	for corner in corners:
		var transformed_corner: Vector3 = transform * corner
		if not bool(bounds.get("valid", false)):
			bounds["valid"] = true
			bounds["min"] = transformed_corner
			bounds["max"] = transformed_corner
			continue
		var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
		var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
		bounds["min"] = Vector3(
			minf(min_value.x, transformed_corner.x),
			minf(min_value.y, transformed_corner.y),
			minf(min_value.z, transformed_corner.z)
		)
		bounds["max"] = Vector3(
			maxf(max_value.x, transformed_corner.x),
			maxf(max_value.y, transformed_corner.y),
			maxf(max_value.z, transformed_corner.z)
		)


func _ensure_child_mesh_instance(parent: Node3D, node_name: String, mesh: Mesh) -> MeshInstance3D:
	var mesh_instance := parent.get_node_or_null(node_name) as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.mesh = mesh
		return mesh_instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return mesh_instance


func _ensure_unit_role_label(parent: Node3D) -> Label3D:
	var label := parent.get_node_or_null("RoleBadge") as Label3D
	if label != null:
		return label
	label = Label3D.new()
	label.name = "RoleBadge"
	label.font_size = 12
	label.outline_size = 3
	label.outline_modulate = Color(0.02, 0.025, 0.03, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label


func _build_unit_visual_descriptor(unit: Node2D, projection: Dictionary) -> Dictionary:
	var team_id: String = _extract_unit_method_string(unit, "get_team_id")
	var fireteam_id: String = _extract_unit_method_string(unit, "get_fireteam_id")
	var role_id: String = _extract_unit_method_string(unit, "get_role_id")
	var is_air: bool = MOVEMENT_LAYER_SCRIPT.is_air_layer(String(projection.get("movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND)))
	var is_selected: bool = unit.has_method("is_tactical_selected") and bool(unit.call("is_tactical_selected"))
	var is_fireteam_lead: bool = bool(unit.get("is_fireteam_lead")) if unit != null else false
	var legacy_hidden_count: int = _count_hidden_legacy_2d_unit_visuals(unit)
	return {
		"visual_kind": "tactical_3d_unit_v1",
		"team_id": team_id,
		"fireteam_id": fireteam_id,
		"role_id": role_id,
		"role_badge": _get_role_badge(role_id),
		"is_friendly": team_id == FRIENDLY_TEAM_ID,
		"is_enemy": not team_id.is_empty() and team_id != FRIENDLY_TEAM_ID,
		"is_air": is_air,
		"is_ground": not is_air,
		"is_selected": is_selected,
		"is_fireteam_lead": is_fireteam_lead,
		"legacy_2d_visual_hidden_count": legacy_hidden_count,
		"legacy_2d_visuals_hidden": legacy_hidden_count > 0,
	}


func _extract_unit_method_string(unit: Node, method_name: String) -> String:
	if unit != null and unit.has_method(method_name):
		return String(unit.call(method_name)).strip_edges()
	return ""


func _get_role_badge(role_id: String) -> String:
	var normalized_role_id: String = role_id.strip_edges().to_lower()
	if normalized_role_id.contains("medic"):
		return "M"
	if normalized_role_id.contains("pilot"):
		return "P"
	if normalized_role_id.contains("leader") or normalized_role_id.contains("commander"):
		return "L"
	if normalized_role_id.contains("sniper") or normalized_role_id.contains("marksman"):
		return "S"
	if normalized_role_id.contains("engineer") or normalized_role_id.contains("tech"):
		return "T"
	if normalized_role_id.contains("guard") or normalized_role_id.contains("security"):
		return "G"
	return "OP"


func _get_unit_body_material(descriptor: Dictionary) -> StandardMaterial3D:
	if bool(descriptor.get("is_air", false)):
		return _unit_material_friendly_air if bool(descriptor.get("is_friendly", false)) else _unit_material_enemy_air
	if bool(descriptor.get("is_friendly", false)):
		return _unit_material_friendly
	if bool(descriptor.get("is_enemy", false)):
		return _unit_material_enemy
	return _unit_material_neutral


func _get_fireteam_material(fireteam_id: String, is_friendly: bool) -> StandardMaterial3D:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var key: String = "%s:%s" % [normalized_fireteam_id, str(is_friendly)]
	if _fireteam_materials.has(key):
		return _fireteam_materials[key]
	var color := Color(0.92, 0.92, 0.92, 1.0)
	match normalized_fireteam_id:
		"blue", "ft1":
			color = Color(0.2, 0.52, 1.0, 1.0)
		"gold", "ft2":
			color = Color(1.0, 0.82, 0.24, 1.0)
		"green", "ft3":
			color = Color(0.28, 0.9, 0.52, 1.0)
		_:
			color = Color(0.78, 0.86, 0.95, 1.0) if is_friendly else Color(1.0, 0.48, 0.34, 1.0)
	var material := _ensure_material(null, color, false)
	_fireteam_materials[key] = material
	return material


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
	var snapshot: Dictionary = _projection_snapshot(projection)
	snapshot["visible"] = marker_visual.visible
	return snapshot


func _sync_strategic_marker_visuals(terrain_registry, marker_container: Node3D) -> Dictionary:
	var seen_keys := PackedStringArray()
	var lz_snapshot: Dictionary = _sync_lz_marker_visual(terrain_registry, marker_container)
	if bool(lz_snapshot.get("visible", false)):
		seen_keys.append("lz_marker")
	var dropship_snapshot: Dictionary = _sync_dropship_marker_visual(terrain_registry, marker_container, lz_snapshot)
	if bool(dropship_snapshot.get("visible", false)):
		seen_keys.append("dropship_marker")
	if bool(dropship_snapshot.get("approach_visible", false)):
		seen_keys.append("approach_line")
	return {
		"valid": bool(lz_snapshot.get("valid", false)) or bool(dropship_snapshot.get("valid", false)),
		"lz": lz_snapshot,
		"dropship": dropship_snapshot,
		"seen_keys": seen_keys,
	}


func _sync_lz_marker_visual(terrain_registry, marker_container: Node3D) -> Dictionary:
	var lz_marker := get_node_or_null(lz_marker_path) as Node2D
	if lz_marker == null:
		return {
			"valid": false,
			"reason": "lz_marker_missing",
			"visible": false,
		}
	var should_show: bool = _is_canvas_marker_effectively_visible(lz_marker)
	var projection: Dictionary = Dictionary(_visual_projection.call("project_marker2d", lz_marker, terrain_registry))
	if not bool(projection.get("valid", false)):
		projection["visible"] = false
		return projection
	var lz_visual := _ensure_mesh_instance(marker_container, "lz_marker", "LZ_", _lz_mesh)
	lz_visual.position = Vector3(projection.get("marker_position_3d", projection.get("target_position_3d", Vector3.ZERO))) + Vector3(0.0, 0.015, 0.0)
	lz_visual.material_override = _lz_material
	lz_visual.visible = should_show
	var snapshot: Dictionary = _projection_snapshot(projection)
	snapshot["visible"] = should_show
	return snapshot


func _sync_dropship_marker_visual(terrain_registry, marker_container: Node3D, lz_snapshot: Dictionary) -> Dictionary:
	var dropship_marker := get_node_or_null(dropship_marker_path) as Node2D
	if dropship_marker == null:
		_set_approach_line_visible(marker_container, false)
		return {
			"valid": false,
			"reason": "dropship_marker_missing",
			"visible": false,
			"approach_visible": false,
		}
	var should_show: bool = _is_canvas_marker_effectively_visible(dropship_marker)
	var projection: Dictionary = Dictionary(_visual_projection.call("project_marker2d", dropship_marker, terrain_registry))
	if not bool(projection.get("valid", false)):
		_set_approach_line_visible(marker_container, false)
		projection["visible"] = false
		projection["approach_visible"] = false
		return projection
	var visual_position: Vector3 = Vector3(projection.get("marker_position_3d", projection.get("target_position_3d", Vector3.ZERO))) + Vector3(0.0, DROPSHIP_MARKER_BASE_Y_OFFSET + _get_dropship_model_y_offset(), 0.0)
	var dropship_visual := _ensure_dropship_visual(marker_container, "dropship_marker")
	dropship_visual.position = visual_position
	dropship_visual.visible = should_show
	var lz_visible: bool = bool(lz_snapshot.get("visible", false))
	var lz_position: Vector3 = Vector3(lz_snapshot.get("target_position_3d", lz_snapshot.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, 0.12, 0.0)
	if should_show and lz_visible:
		_orient_node_toward_flat(dropship_visual, lz_position)
	var approach_visible: bool = should_show and lz_visible and visual_position.distance_to(lz_position) > 0.18
	_sync_approach_line_visual(marker_container, visual_position, lz_position, approach_visible)
	var snapshot: Dictionary = _projection_snapshot(projection)
	snapshot["visible"] = should_show
	snapshot["approach_visible"] = approach_visible
	snapshot["uses_model"] = _dropship_scene != null
	snapshot["model_path"] = _get_dropship_model_path()
	snapshot["model_type_id"] = dropship_visual_type_id
	snapshot["scale"] = _get_dropship_visual_scale()
	return snapshot


func _ensure_dropship_visual(container: Node3D, key: String) -> Node3D:
	var node_name: String = "Dropship_%s" % key
	var visual := container.get_node_or_null(node_name) as Node3D
	if visual != null:
		_sync_dropship_visual_asset(visual)
		return visual
	visual = Node3D.new()
	visual.name = node_name
	_sync_dropship_visual_asset(visual)
	container.add_child(visual)
	return visual


func _sync_dropship_visual_asset(visual: Node3D) -> void:
	var model_path: String = _get_dropship_model_path()
	var visual_scale: float = _get_dropship_visual_scale()
	if (_dropship_scene == null or _dropship_scene_model_path != model_path) and ResourceLoader.exists(model_path):
		_dropship_scene = load(model_path) as PackedScene
		_dropship_scene_model_path = model_path
	if _dropship_scene != null:
		var model := visual.get_node_or_null("Model") as Node3D
		if model == null or String(model.get_meta("model_path", "")) != model_path or not is_equal_approx(float(model.get_meta("visual_scale", -1.0)), visual_scale):
			_clear_children(visual)
			model = _dropship_scene.instantiate() as Node3D
			if model != null:
				model.name = "Model"
				model.set_meta("model_path", model_path)
				model.set_meta("visual_scale", visual_scale)
				_center_model_node_on_ground(model, visual_scale)
				visual.add_child(model)
		return
	_clear_children(visual)
	var fallback := MeshInstance3D.new()
	fallback.name = "FallbackBody"
	fallback.mesh = _dropship_fallback_mesh
	fallback.material_override = _dropship_material
	fallback.scale = Vector3.ONE * visual_scale
	visual.add_child(fallback)


func _get_dropship_model_path() -> String:
	if _renderer != null and _renderer.has_method("get_model_entry_for_type"):
		var entry: Dictionary = Dictionary(_renderer.call("get_model_entry_for_type", dropship_visual_type_id))
		var model_path: String = String(entry.get("model_path", "")).strip_edges()
		if not model_path.is_empty():
			return model_path
	return DROPSHIP_MODEL_PATH


func _get_dropship_visual_scale() -> float:
	var base_scale: float = DROPSHIP_FALLBACK_SCALE
	if _renderer != null and _renderer.has_method("get_model_scale_for_type"):
		base_scale = float(_renderer.call("get_model_scale_for_type", dropship_visual_type_id))
	return maxf(base_scale * maxf(dropship_visual_scale_multiplier, 0.05), 0.05)


func _get_dropship_model_y_offset() -> float:
	if _renderer != null and _renderer.has_method("get_model_y_offset_for_type"):
		return float(_renderer.call("get_model_y_offset_for_type", dropship_visual_type_id))
	return 0.0


func _sync_approach_line_visual(container: Node3D, from_position: Vector3, to_position: Vector3, is_visible: bool) -> void:
	var line := container.get_node_or_null("Approach_approach_line") as MeshInstance3D
	if line == null:
		line = MeshInstance3D.new()
		line.name = "Approach_approach_line"
		line.material_override = _approach_material
		container.add_child(line)
	if not is_visible:
		line.visible = false
		return
	var flat_from := Vector3(from_position.x, from_position.y, from_position.z)
	var flat_to := Vector3(to_position.x, from_position.y, to_position.z)
	var length: float = flat_from.distance_to(flat_to)
	if length <= 0.05:
		line.visible = false
		return
	var mesh := line.mesh as BoxMesh
	if mesh == null:
		mesh = BoxMesh.new()
		line.mesh = mesh
	mesh.size = Vector3(0.055, 0.04, length)
	line.position = (flat_from + flat_to) * 0.5
	line.look_at(flat_to, Vector3.UP)
	line.visible = true


func _set_approach_line_visible(container: Node3D, is_visible: bool) -> void:
	var line := container.get_node_or_null("Approach_approach_line") as MeshInstance3D
	if line != null:
		line.visible = is_visible


func _orient_node_toward_flat(node: Node3D, target_position: Vector3) -> void:
	if node == null:
		return
	var target := Vector3(target_position.x, node.global_position.y, target_position.z)
	if node.global_position.distance_to(target) <= 0.05:
		return
	node.look_at(target, Vector3.UP)


func _is_canvas_marker_effectively_visible(marker: CanvasItem) -> bool:
	if marker == null:
		return false
	if marker.visible:
		return true
	if marker.has_meta(LEGACY_2D_OVERLAY_META_KEY):
		return bool(marker.get_meta(LEGACY_2D_OVERLAY_META_KEY))
	return false


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
	var waypoint_count: int = 0
	var area_order_count: int = 0
	var area_tile_count: int = 0
	var area_preview_count: int = 0
	if order_visualizer.has_method("get_visible_waypoints"):
		var waypoint_index: int = 0
		var waypoints_by_fireteam: Dictionary = {}
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
			waypoint_count += 1
			var fireteam_id: String = String(waypoint.get("fireteam_id", "")).strip_edges().to_lower()
			if not waypoints_by_fireteam.has(fireteam_id):
				waypoints_by_fireteam[fireteam_id] = []
			waypoints_by_fireteam[fireteam_id].append(waypoint.duplicate(true))
		for fireteam_variant in waypoints_by_fireteam.keys():
			var fireteam_id := String(fireteam_variant)
			var fireteam_waypoints: Array = Array(waypoints_by_fireteam.get(fireteam_id, []))
			fireteam_waypoints.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return int(a.get("index", 0)) < int(b.get("index", 0))
			)
			var previous_position: Variant = null
			if not fireteam_waypoints.is_empty() and typeof(Dictionary(fireteam_waypoints[0]).get("anchor_position", null)) == TYPE_VECTOR2:
				previous_position = Vector2(Dictionary(fireteam_waypoints[0]).get("anchor_position", Vector2.ZERO))
			var line_index: int = 0
			for waypoint_variant in fireteam_waypoints:
				var waypoint: Dictionary = Dictionary(waypoint_variant)
				if typeof(previous_position) == TYPE_VECTOR2 and typeof(waypoint.get("position", null)) == TYPE_VECTOR2:
					var line_key: String = "waypoint_line_%s_%d" % [_sanitize_node_key(fireteam_id), line_index]
					var material: StandardMaterial3D = _get_area_order_material(String(waypoint.get("command_type", "")))
					if _sync_world_line_visual(preview_container, line_key, "PreviewLine_", Vector2(previous_position), Vector2(waypoint.get("position", Vector2.ZERO)), terrain_registry, material, 0.045, 0.07):
						seen_keys.append(line_key)
						preview_count += 1
				if typeof(waypoint.get("position", null)) == TYPE_VECTOR2:
					previous_position = Vector2(waypoint.get("position", Vector2.ZERO))
				line_index += 1
	if order_visualizer.has_method("get_visible_area_orders"):
		var area_index: int = 0
		for area_variant in Array(order_visualizer.call("get_visible_area_orders")):
			if typeof(area_variant) != TYPE_DICTIONARY:
				continue
			var area_order: Dictionary = Dictionary(area_variant)
			var area_seen_keys: PackedStringArray = _sync_area_order_visual(preview_container, "area_%d" % area_index, area_order, terrain_registry, false)
			for seen_key in area_seen_keys:
				seen_keys.append(seen_key)
			area_tile_count += _count_area_order_tile_positions(area_order)
			area_order_count += 1
			preview_count += area_seen_keys.size()
			area_index += 1
	if order_visualizer.has_method("get_area_order_preview_payload"):
		var preview_payload: Dictionary = Dictionary(order_visualizer.call("get_area_order_preview_payload"))
		if not preview_payload.is_empty():
			var preview_seen_keys: PackedStringArray = _sync_area_order_visual(preview_container, "area_preview", preview_payload, terrain_registry, true)
			for seen_key in preview_seen_keys:
				seen_keys.append(seen_key)
			area_preview_count = preview_seen_keys.size()
			preview_count += preview_seen_keys.size()
	_remove_stale_visuals(preview_container, seen_keys)
	return {
		"valid": true,
		"preview_count": preview_count,
		"waypoint_count": waypoint_count,
		"area_order_count": area_order_count,
		"area_tile_count": area_tile_count,
		"area_preview_count": area_preview_count,
	}


func _sync_area_order_visual(preview_container: Node3D, key_prefix: String, area_order: Dictionary, terrain_registry, is_preview: bool) -> PackedStringArray:
	var seen_keys := PackedStringArray()
	var material: StandardMaterial3D = _area_preview_material if is_preview else _get_area_order_material(String(area_order.get("command_type", "")))
	if typeof(area_order.get("center_position", null)) == TYPE_VECTOR2:
		var center_key: String = "%s_center" % key_prefix
		_sync_preview_marker(preview_container, center_key, Vector2(area_order.get("center_position", Vector2.ZERO)), terrain_registry, material)
		seen_keys.append(center_key)
		if typeof(area_order.get("anchor_position", null)) == TYPE_VECTOR2:
			var line_key: String = "%s_anchor_line" % key_prefix
			if _sync_world_line_visual(preview_container, line_key, "AreaLine_", Vector2(area_order.get("anchor_position", Vector2.ZERO)), Vector2(area_order.get("center_position", Vector2.ZERO)), terrain_registry, material, 0.05, 0.08):
				seen_keys.append(line_key)
	var tile_index: int = 0
	for tile_position_variant in Array(area_order.get("tile_world_positions", [])):
		if typeof(tile_position_variant) != TYPE_VECTOR2:
			continue
		var tile_key: String = "%s_tile_%d" % [key_prefix, tile_index]
		_sync_area_tile_visual(preview_container, tile_key, Vector2(tile_position_variant), terrain_registry, material)
		seen_keys.append(tile_key)
		tile_index += 1
	if tile_index <= 0:
		var polygon: PackedVector2Array = PackedVector2Array(area_order.get("world_polygon", PackedVector2Array()))
		var polygon_index: int = 0
		for point in polygon:
			var polygon_key: String = "%s_polygon_%d" % [key_prefix, polygon_index]
			_sync_area_tile_visual(preview_container, polygon_key, point, terrain_registry, material)
			seen_keys.append(polygon_key)
			polygon_index += 1
	return seen_keys


func _sync_area_tile_visual(preview_container: Node3D, key: String, world_position: Vector2, terrain_registry, material: StandardMaterial3D) -> void:
	var projection: Dictionary = Dictionary(_visual_projection.call("project_world_position", world_position, terrain_registry, {
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))
	if not bool(projection.get("valid", false)):
		return
	var area_visual := _ensure_mesh_instance(preview_container, key, "AreaTile_", _area_tile_mesh)
	area_visual.position = Vector3(projection.get("base_position_3d", projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, 0.06, 0.0)
	area_visual.material_override = material
	area_visual.visible = true


func _count_area_order_tile_positions(area_order: Dictionary) -> int:
	var count: int = 0
	for tile_position_variant in Array(area_order.get("tile_world_positions", [])):
		if typeof(tile_position_variant) == TYPE_VECTOR2:
			count += 1
	return count


func _get_area_order_material(command_type: String) -> StandardMaterial3D:
	match command_type.strip_edges().to_lower():
		"defend":
			return _area_material_defensive
		"take":
			return _area_material_take
		"engage", "flank":
			return _area_material_offensive
		_:
			return _area_material_neutral


func _sync_tactical_overlay_visuals(terrain_registry, overlay_container: Node3D) -> Dictionary:
	var seen_keys: PackedStringArray = []
	var ad_hoc_count: int = 0
	var security_state_count: int = 0
	var security_sector_count: int = 0
	var contact_count: int = 0
	var order_visualizer = get_node_or_null(order_visualizer_path)
	if order_visualizer != null:
		if order_visualizer.has_method("get_visible_ad_hoc_orders"):
			var ad_hoc_index: int = 0
			for order_variant in Array(order_visualizer.call("get_visible_ad_hoc_orders")):
				if typeof(order_variant) != TYPE_DICTIONARY:
					continue
				var order_keys: PackedStringArray = _sync_ad_hoc_order_visual(overlay_container, "ad_hoc_%d" % ad_hoc_index, Dictionary(order_variant), terrain_registry)
				if not order_keys.is_empty():
					ad_hoc_count += 1
				for seen_key in order_keys:
					seen_keys.append(seen_key)
				ad_hoc_index += 1
		if order_visualizer.has_method("get_visible_security_states"):
			var security_index: int = 0
			for security_variant in Array(order_visualizer.call("get_visible_security_states")):
				if typeof(security_variant) != TYPE_DICTIONARY:
					continue
				var security_result: Dictionary = _sync_security_state_visual(overlay_container, "security_%d" % security_index, Dictionary(security_variant), terrain_registry)
				if bool(security_result.get("visible", false)):
					security_state_count += 1
				security_sector_count += int(security_result.get("sector_count", 0))
				for seen_key in PackedStringArray(security_result.get("seen_keys", PackedStringArray())):
					seen_keys.append(seen_key)
				security_index += 1
	var contact_overlay = _get_contact_overlay()
	if contact_overlay != null and contact_overlay.has_method("get_visible_contacts"):
		var contact_index: int = 0
		for contact_variant in Array(contact_overlay.call("get_visible_contacts")):
			if typeof(contact_variant) != TYPE_DICTIONARY:
				continue
			var contact_key: String = "contact_%d" % contact_index
			if _sync_contact_visual(overlay_container, contact_key, Dictionary(contact_variant), terrain_registry):
				seen_keys.append(contact_key)
				contact_count += 1
			contact_index += 1
	_remove_stale_visuals(overlay_container, seen_keys)
	return {
		"valid": order_visualizer != null or contact_overlay != null,
		"ad_hoc_count": ad_hoc_count,
		"security_state_count": security_state_count,
		"security_sector_count": security_sector_count,
		"contact_count": contact_count,
		"overlay_count": seen_keys.size(),
	}


func _sync_ad_hoc_order_visual(overlay_container: Node3D, key: String, order_dict: Dictionary, terrain_registry) -> PackedStringArray:
	var seen_keys: PackedStringArray = []
	if typeof(order_dict.get("anchor_position", null)) != TYPE_VECTOR2 or typeof(order_dict.get("target_position", null)) != TYPE_VECTOR2:
		return seen_keys
	var anchor_position: Vector2 = Vector2(order_dict.get("anchor_position", Vector2.ZERO))
	var target_position: Vector2 = Vector2(order_dict.get("target_position", anchor_position))
	var anchor_projection: Dictionary = _project_ground_overlay_position(anchor_position, terrain_registry)
	var target_projection: Dictionary = _project_ground_overlay_position(target_position, terrain_registry)
	if not bool(anchor_projection.get("valid", false)) or not bool(target_projection.get("valid", false)):
		return seen_keys
	var anchor_visual := _ensure_mesh_instance(overlay_container, "%s_anchor" % key, "AdHoc_", _preview_mesh)
	anchor_visual.position = Vector3(anchor_projection.get("marker_position_3d", anchor_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, TACTICAL_OVERLAY_Y_OFFSET, 0.0)
	anchor_visual.material_override = _ad_hoc_material
	anchor_visual.visible = true
	seen_keys.append("%s_anchor" % key)
	var target_visual := _ensure_mesh_instance(overlay_container, "%s_target" % key, "AdHoc_", _preview_mesh)
	target_visual.position = Vector3(target_projection.get("marker_position_3d", target_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, TACTICAL_OVERLAY_Y_OFFSET, 0.0)
	target_visual.material_override = _ad_hoc_material
	target_visual.visible = true
	seen_keys.append("%s_target" % key)
	if _sync_line_visual(overlay_container, "%s_line" % key, "AdHocLine_", anchor_visual.position, target_visual.position, _ad_hoc_material, 0.045):
		seen_keys.append("%s_line" % key)
	return seen_keys


func _sync_security_state_visual(overlay_container: Node3D, key: String, security_dict: Dictionary, terrain_registry) -> Dictionary:
	var seen_keys: PackedStringArray = []
	var sector_count: int = 0
	if typeof(security_dict.get("anchor_position", null)) != TYPE_VECTOR2:
		return {
			"visible": false,
			"sector_count": 0,
			"seen_keys": seen_keys,
		}
	var anchor_position: Vector2 = Vector2(security_dict.get("anchor_position", Vector2.ZERO))
	var sector_index: int = 0
	for assignment_variant in Array(security_dict.get("member_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		var arc_width: float = float(assignment.get("arc_width", 0.0))
		if arc_width <= 0.001:
			continue
		var sector_key: String = "%s_sector_%d" % [key, sector_index]
		if _sync_security_sector_visual(overlay_container, sector_key, anchor_position, float(assignment.get("center_angle", 0.0)), arc_width, terrain_registry):
			seen_keys.append(sector_key)
			sector_count += 1
		sector_index += 1
	if bool(security_dict.get("overwatch_ready", false)):
		var anchor_projection: Dictionary = _project_ground_overlay_position(anchor_position, terrain_registry)
		if bool(anchor_projection.get("valid", false)):
			var anchor_key: String = "%s_anchor" % key
			var anchor_visual := _ensure_mesh_instance(overlay_container, anchor_key, "Security_", _selection_mesh)
			anchor_visual.position = Vector3(anchor_projection.get("marker_position_3d", anchor_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, TACTICAL_OVERLAY_Y_OFFSET + 0.02, 0.0)
			anchor_visual.material_override = _security_material
			anchor_visual.visible = true
			seen_keys.append(anchor_key)
	return {
		"visible": sector_count > 0 or seen_keys.size() > 0,
		"sector_count": sector_count,
		"seen_keys": seen_keys,
	}


func _sync_security_sector_visual(overlay_container: Node3D, key: String, anchor_position: Vector2, center_angle: float, arc_width: float, terrain_registry) -> bool:
	var mesh: ArrayMesh = _build_security_sector_mesh(anchor_position, center_angle, arc_width, SECURITY_SECTOR_RADIUS, terrain_registry)
	if mesh == null:
		return false
	var node_name: String = "SecuritySector_%s" % key
	var sector_visual := overlay_container.get_node_or_null(node_name) as MeshInstance3D
	if sector_visual == null:
		sector_visual = MeshInstance3D.new()
		sector_visual.name = node_name
		overlay_container.add_child(sector_visual)
	sector_visual.mesh = mesh
	sector_visual.material_override = _security_material
	sector_visual.visible = true
	return true


func _build_security_sector_mesh(anchor_position: Vector2, center_angle: float, arc_width: float, radius: float, terrain_registry) -> ArrayMesh:
	var anchor_projection: Dictionary = _project_ground_overlay_position(anchor_position, terrain_registry)
	if not bool(anchor_projection.get("valid", false)):
		return null
	var vertices := PackedVector3Array()
	vertices.append(Vector3(anchor_projection.get("base_position_3d", anchor_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, TACTICAL_OVERLAY_Y_OFFSET, 0.0))
	var start_angle: float = center_angle - (arc_width * 0.5)
	var steps: int = maxi(int(ceil(arc_width / (PI / 12.0))), 2)
	for step in range(steps + 1):
		var t: float = float(step) / float(steps)
		var angle: float = lerpf(start_angle, start_angle + arc_width, t)
		var edge_position: Vector2 = anchor_position + Vector2.RIGHT.rotated(angle) * radius
		var edge_projection: Dictionary = _project_ground_overlay_position(edge_position, terrain_registry)
		if not bool(edge_projection.get("valid", false)):
			continue
		vertices.append(Vector3(edge_projection.get("base_position_3d", edge_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, TACTICAL_OVERLAY_Y_OFFSET, 0.0))
	if vertices.size() < 3:
		return null
	var indices := PackedInt32Array()
	for index in range(1, vertices.size() - 1):
		indices.append(0)
		indices.append(index)
		indices.append(index + 1)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _sync_contact_visual(overlay_container: Node3D, key: String, contact_dict: Dictionary, terrain_registry) -> bool:
	if typeof(contact_dict.get("last_known_position", null)) != TYPE_VECTOR2:
		return false
	var projection: Dictionary = _project_ground_overlay_position(Vector2(contact_dict.get("last_known_position", Vector2.ZERO)), terrain_registry)
	if not bool(projection.get("valid", false)):
		return false
	var contact_visual := _ensure_mesh_instance(overlay_container, key, "Contact_", _preview_mesh)
	contact_visual.position = Vector3(projection.get("marker_position_3d", projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, TACTICAL_OVERLAY_Y_OFFSET + 0.05, 0.0)
	contact_visual.material_override = _get_contact_material(String(contact_dict.get("detection_state", "")))
	contact_visual.visible = true
	return true


func _sync_world_line_visual(container: Node3D, key: String, prefix: String, from_world_position: Vector2, to_world_position: Vector2, terrain_registry, material: StandardMaterial3D, width: float, y_offset: float) -> bool:
	var from_projection: Dictionary = _project_ground_overlay_position(from_world_position, terrain_registry)
	var to_projection: Dictionary = _project_ground_overlay_position(to_world_position, terrain_registry)
	if not bool(from_projection.get("valid", false)) or not bool(to_projection.get("valid", false)):
		return false
	var from_position: Vector3 = Vector3(from_projection.get("marker_position_3d", from_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, y_offset, 0.0)
	var to_position: Vector3 = Vector3(to_projection.get("marker_position_3d", to_projection.get("visual_position_3d", Vector3.ZERO))) + Vector3(0.0, y_offset, 0.0)
	return _sync_line_visual(container, key, prefix, from_position, to_position, material, width)


func _sync_line_visual(container: Node3D, key: String, prefix: String, from_position: Vector3, to_position: Vector3, material: StandardMaterial3D, width: float) -> bool:
	var flat_from := Vector3(from_position.x, from_position.y, from_position.z)
	var flat_to := Vector3(to_position.x, from_position.y, to_position.z)
	var length: float = flat_from.distance_to(flat_to)
	var line := container.get_node_or_null("%s%s" % [prefix, key]) as MeshInstance3D
	if line == null:
		line = MeshInstance3D.new()
		line.name = "%s%s" % [prefix, key]
		container.add_child(line)
	if length <= 0.05:
		line.visible = false
		return false
	var mesh := line.mesh as BoxMesh
	if mesh == null:
		mesh = BoxMesh.new()
		line.mesh = mesh
	mesh.size = Vector3(width, 0.035, length)
	line.position = (flat_from + flat_to) * 0.5
	line.look_at(flat_to, Vector3.UP)
	line.material_override = material
	line.visible = true
	return true


func _project_ground_overlay_position(world_position: Vector2, terrain_registry) -> Dictionary:
	return Dictionary(_visual_projection.call("project_world_position", world_position, terrain_registry, {
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))


func _get_contact_overlay():
	var overlay = get_node_or_null(contact_overlay_path)
	if overlay != null:
		return overlay
	return get_node_or_null("../ContactMapOverlay")


func _get_contact_material(detection_state: String) -> StandardMaterial3D:
	match detection_state.strip_edges().to_lower():
		"suspected":
			return _contact_suspected_material
		"lost":
			return _contact_lost_material
		_:
			return _contact_confirmed_material


func _sync_preview_marker(preview_container: Node3D, key: String, world_position: Vector2, terrain_registry, material: StandardMaterial3D = null) -> void:
	var projection: Dictionary = Dictionary(_visual_projection.call("project_world_position", world_position, terrain_registry, {
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))
	if not bool(projection.get("valid", false)):
		return
	var preview_visual := _ensure_mesh_instance(preview_container, key, "Preview_", _preview_mesh)
	preview_visual.position = Vector3(projection.get("marker_position_3d", Vector3.ZERO))
	preview_visual.material_override = material if material != null else _preview_material
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


func _build_unit_debug_label_text(unit_id: String, descriptor: Dictionary, projection: Dictionary) -> String:
	var parts: PackedStringArray = []
	var fireteam_id: String = String(descriptor.get("fireteam_id", "")).strip_edges().to_upper()
	var role_badge: String = String(descriptor.get("role_badge", "OP"))
	parts.append(unit_id)
	if not fireteam_id.is_empty():
		parts.append(fireteam_id)
	parts.append(role_badge)
	if bool(descriptor.get("is_air", false)):
		parts.append("AIR %d" % int(projection.get("altitude_band", 0)))
	if bool(descriptor.get("is_fireteam_lead", false)):
		parts.append("LEAD")
	return " ".join(parts)


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
		"hide_2d_unit_sprites_when_primary": hide_2d_unit_sprites_when_primary,
		"hide_2d_mission_overlays_when_primary": hide_2d_mission_overlays_when_primary,
		"primary_3d_view_active": is_primary_3d_view_active(),
		"fallback_2d_visible": is_2d_fallback_visible(),
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
	_camera_controller.min_size = camera_min_size
	_camera_controller.max_size = camera_max_size
	_camera_controller.zoom_step = camera_zoom_step
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
	_update_legacy_2d_unit_visual_visibility()
	_update_legacy_2d_mission_overlay_visibility()


func _update_2d_map_visibility() -> void:
	var map_root_2d = get_node_or_null(map_root_2d_path)
	if map_root_2d != null and map_root_2d is CanvasItem:
		(map_root_2d as CanvasItem).visible = not (hide_2d_map_when_visible and visible)


func _should_show_legacy_2d_mission_overlays() -> bool:
	if not hide_2d_mission_overlays_when_primary:
		return true
	if not is_primary_3d_view_active():
		return true
	return is_2d_fallback_visible()


func _update_legacy_2d_mission_overlay_visibility() -> void:
	var should_show: bool = _should_show_legacy_2d_mission_overlays()
	for overlay in _get_existing_legacy_2d_mission_overlay_items():
		_set_legacy_2d_overlay_visible(overlay, should_show)


func _get_existing_legacy_2d_mission_overlay_items() -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	for overlay_path in legacy_2d_mission_overlay_paths:
		var overlay := get_node_or_null(overlay_path) as CanvasItem
		if overlay != null:
			result.append(overlay)
	return result


func _set_legacy_2d_overlay_visible(overlay: CanvasItem, should_be_visible: bool) -> void:
	if overlay == null:
		return
	if should_be_visible:
		var original_visible: bool = bool(overlay.get_meta(LEGACY_2D_OVERLAY_META_KEY, overlay.visible))
		overlay.visible = original_visible
		return
	if overlay.visible:
		overlay.set_meta(LEGACY_2D_OVERLAY_META_KEY, true)
	elif not overlay.has_meta(LEGACY_2D_OVERLAY_META_KEY):
		overlay.set_meta(LEGACY_2D_OVERLAY_META_KEY, false)
	overlay.visible = false


func _get_legacy_2d_mission_overlay_audit() -> Dictionary:
	var path_entries: Array = []
	var visible_count: int = 0
	var hidden_count: int = 0
	var missing_count: int = 0
	for overlay_path in legacy_2d_mission_overlay_paths:
		var overlay := get_node_or_null(overlay_path) as CanvasItem
		var entry := {
			"path": String(overlay_path),
			"present": overlay != null,
			"visible": false,
			"remembered_visible": false,
		}
		if overlay == null:
			missing_count += 1
		else:
			var visible_now: bool = overlay.visible
			var remembered_visible: bool = bool(overlay.get_meta(LEGACY_2D_OVERLAY_META_KEY, visible_now))
			entry["visible"] = visible_now
			entry["remembered_visible"] = remembered_visible
			if visible_now:
				visible_count += 1
			elif remembered_visible:
				hidden_count += 1
		path_entries.append(entry)
	return {
		"visible_count": visible_count,
		"hidden_count": hidden_count,
		"missing_count": missing_count,
		"paths": path_entries,
	}


func _should_show_legacy_2d_unit_visuals() -> bool:
	if not hide_2d_unit_sprites_when_primary:
		return true
	if not is_primary_3d_view_active():
		return true
	return is_2d_fallback_visible()


func _update_legacy_2d_unit_visual_visibility() -> void:
	var unit_registry = get_node_or_null(unit_registry_path)
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return
	var should_show: bool = _should_show_legacy_2d_unit_visuals()
	for unit in Array(unit_registry.call("get_all_units")):
		if unit != null and unit is Node2D:
			_set_legacy_2d_unit_visuals_visible(unit, should_show)


func _set_legacy_2d_unit_visuals_visible(unit: Node, should_be_visible: bool) -> int:
	var affected_count: int = 0
	for child in unit.get_children():
		var canvas_child := child as CanvasItem
		if canvas_child == null:
			continue
		if not child.has_meta(LEGACY_2D_VISUAL_META_KEY):
			child.set_meta(LEGACY_2D_VISUAL_META_KEY, canvas_child.visible)
		var original_visible: bool = bool(child.get_meta(LEGACY_2D_VISUAL_META_KEY))
		if should_be_visible:
			canvas_child.visible = original_visible
		else:
			if canvas_child.visible:
				affected_count += 1
			canvas_child.visible = false
	return affected_count


func _count_hidden_legacy_2d_unit_visuals(unit: Node) -> int:
	var hidden_count: int = 0
	for child in unit.get_children():
		var canvas_child := child as CanvasItem
		if canvas_child != null and child.has_meta(LEGACY_2D_VISUAL_META_KEY) and bool(child.get_meta(LEGACY_2D_VISUAL_META_KEY)) and not canvas_child.visible:
			hidden_count += 1
	return hidden_count


func _count_visible_legacy_2d_unit_visuals(unit: Node) -> int:
	var visible_count: int = 0
	for child in unit.get_children():
		var canvas_child := child as CanvasItem
		if canvas_child != null and canvas_child.visible:
			visible_count += 1
	return visible_count
