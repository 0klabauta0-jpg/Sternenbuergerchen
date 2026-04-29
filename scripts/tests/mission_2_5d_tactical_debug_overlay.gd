class_name Mission25DTacticalDebugOverlay
extends Node3D

const TERRAIN_25D_VISUAL_PROJECTION_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_visual_projection.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")

const LAYER_HEIGHT_FLOOR: String = "height_floor"
const LAYER_COVER_LOS: String = "cover_los"
const LAYER_WALKABILITY: String = "walkability"
const LAYER_PATH: String = "path"
const LAYER_AIR: String = "air"
const ALL_LAYERS: PackedStringArray = [
	LAYER_HEIGHT_FLOOR,
	LAYER_COVER_LOS,
	LAYER_WALKABILITY,
	LAYER_PATH,
	LAYER_AIR,
]

@export var overlay_enabled: bool = false
@export var keyboard_toggles_enabled: bool = true
@export var terrain_registry_path: NodePath
@export var simulation_root_path: NodePath
@export var unit_registry_path: NodePath
@export var order_visualizer_path: NodePath
@export var bridge_path: NodePath
@export var height_floor_layer_enabled: bool = true
@export var cover_los_layer_enabled: bool = true
@export var walkability_layer_enabled: bool = true
@export var path_layer_enabled: bool = true
@export var air_layer_enabled: bool = true
@export_range(16, 1024, 1) var max_tile_labels: int = 256
@export_range(8, 512, 1) var max_path_labels: int = 96

var overlay_snapshot: Dictionary = {}

var _visual_projection = TERRAIN_25D_VISUAL_PROJECTION_SCRIPT.new()


func _ready() -> void:
	_configure_visual_projection()
	_ensure_layer_containers()
	set_overlay_enabled(overlay_enabled)


func _unhandled_input(event: InputEvent) -> void:
	if not keyboard_toggles_enabled:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_F6:
			set_overlay_enabled(not overlay_enabled)
		KEY_1:
			toggle_layer(LAYER_HEIGHT_FLOOR)
		KEY_2:
			toggle_layer(LAYER_COVER_LOS)
		KEY_3:
			toggle_layer(LAYER_WALKABILITY)
		KEY_4:
			toggle_layer(LAYER_PATH)
		KEY_5:
			toggle_layer(LAYER_AIR)


func set_overlay_enabled(is_enabled: bool) -> void:
	overlay_enabled = is_enabled
	visible = overlay_enabled
	if overlay_enabled:
		refresh_overlay()
	else:
		_clear_all_layer_visuals()
		overlay_snapshot = _base_snapshot(false, "overlay_disabled")


func is_overlay_enabled() -> bool:
	return overlay_enabled


func set_layer_enabled(layer_id: String, is_enabled: bool) -> void:
	match layer_id:
		LAYER_HEIGHT_FLOOR:
			height_floor_layer_enabled = is_enabled
		LAYER_COVER_LOS:
			cover_los_layer_enabled = is_enabled
		LAYER_WALKABILITY:
			walkability_layer_enabled = is_enabled
		LAYER_PATH:
			path_layer_enabled = is_enabled
		LAYER_AIR:
			air_layer_enabled = is_enabled
		_:
			push_warning("Unknown tactical debug overlay layer: %s" % layer_id)
			return
	if overlay_enabled:
		refresh_overlay()


func toggle_layer(layer_id: String) -> bool:
	var next_state: bool = not is_layer_enabled(layer_id)
	set_layer_enabled(layer_id, next_state)
	return next_state


func is_layer_enabled(layer_id: String) -> bool:
	match layer_id:
		LAYER_HEIGHT_FLOOR:
			return height_floor_layer_enabled
		LAYER_COVER_LOS:
			return cover_los_layer_enabled
		LAYER_WALKABILITY:
			return walkability_layer_enabled
		LAYER_PATH:
			return path_layer_enabled
		LAYER_AIR:
			return air_layer_enabled
		_:
			return false


func refresh_overlay() -> Dictionary:
	_configure_visual_projection()
	_ensure_layer_containers()
	var terrain_registry = get_node_or_null(terrain_registry_path)
	var simulation_root = get_node_or_null(simulation_root_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var order_visualizer = get_node_or_null(order_visualizer_path)
	if terrain_registry == null:
		_clear_all_layer_visuals()
		overlay_snapshot = _base_snapshot(true, "terrain_registry_missing")
		return overlay_snapshot

	var layers: Dictionary = {}
	layers[LAYER_HEIGHT_FLOOR] = _refresh_layer(
		LAYER_HEIGHT_FLOOR,
		height_floor_layer_enabled,
		func(container): return _build_height_floor_layer(container, terrain_registry)
	)
	layers[LAYER_COVER_LOS] = _refresh_layer(
		LAYER_COVER_LOS,
		cover_los_layer_enabled,
		func(container): return _build_cover_los_layer(container, terrain_registry)
	)
	layers[LAYER_WALKABILITY] = _refresh_layer(
		LAYER_WALKABILITY,
		walkability_layer_enabled,
		func(container): return _build_walkability_layer(container, terrain_registry)
	)
	layers[LAYER_PATH] = _refresh_layer(
		LAYER_PATH,
		path_layer_enabled,
		func(container): return _build_path_layer(container, terrain_registry, simulation_root, order_visualizer)
	)
	layers[LAYER_AIR] = _refresh_layer(
		LAYER_AIR,
		air_layer_enabled,
		func(container): return _build_air_layer(container, terrain_registry, simulation_root, unit_registry)
	)
	overlay_snapshot = {
		"enabled": true,
		"valid": true,
		"reason": "",
		"layers": layers,
		"data_sources": _collect_data_sources(layers),
	}
	return overlay_snapshot.duplicate(true)


func get_overlay_snapshot() -> Dictionary:
	return overlay_snapshot.duplicate(true)


func _refresh_layer(layer_id: String, is_enabled: bool, builder: Callable) -> Dictionary:
	var container := _get_layer_container(layer_id)
	_clear_children(container)
	container.visible = overlay_enabled and is_enabled
	if not is_enabled:
		return {
			"enabled": false,
			"valid": true,
			"source": "",
			"label_count": 0,
			"samples": [],
		}
	var snapshot: Dictionary = Dictionary(builder.call(container))
	snapshot["enabled"] = true
	snapshot["valid"] = true
	if not snapshot.has("label_count"):
		snapshot["label_count"] = container.get_child_count()
	return snapshot


func _build_height_floor_layer(container: Node3D, terrain_registry) -> Dictionary:
	var samples: Array = []
	var count: int = 0
	for tile in _get_floor_tiles(terrain_registry):
		if count >= max_tile_labels:
			break
		var grid_position: Vector2i = Vector2i(tile.grid_position)
		var floor_index: int = int(tile.floor_index)
		var floor_height: float = float(tile.floor_height)
		var label_text: String = "F%d H%.1f" % [floor_index, floor_height]
		_add_label(container, "height_%d_%d_%d" % [grid_position.x, grid_position.y, floor_index], label_text, _project_tile_label_position(tile, terrain_registry, 0.25), Color(0.52, 0.86, 1.0, 1.0))
		samples.append({
			"grid_position": grid_position,
			"floor_index": floor_index,
			"floor_height": floor_height,
			"height_level": int(tile.height_level),
			"source": "TerrainRegistry",
		})
		count += 1
	return {
		"source": "TerrainRegistry",
		"label_count": count,
		"samples": samples,
	}


func _build_cover_los_layer(container: Node3D, terrain_registry) -> Dictionary:
	var samples: Array = []
	var count: int = 0
	for tile in _get_floor_tiles(terrain_registry):
		var cover_value: int = int(tile.cover_value)
		var cover_height: float = float(tile.cover_height)
		var blocks_los_height: float = float(tile.blocks_los_height)
		if cover_value <= 0 and cover_height <= 0.0 and blocks_los_height <= 0.0 and not bool(tile.blocks_los):
			continue
		if count >= max_tile_labels:
			break
		var grid_position: Vector2i = Vector2i(tile.grid_position)
		var label_text: String = "C%d CH%.1f L%.1f" % [cover_value, cover_height, blocks_los_height]
		_add_label(container, "cover_%d_%d_%d" % [grid_position.x, grid_position.y, int(tile.floor_index)], label_text, _project_tile_label_position(tile, terrain_registry, 0.55), Color(1.0, 0.82, 0.32, 1.0))
		samples.append({
			"grid_position": grid_position,
			"floor_index": int(tile.floor_index),
			"cover_value": cover_value,
			"cover_height": cover_height,
			"blocks_los": bool(tile.blocks_los),
			"blocks_los_height": blocks_los_height,
			"source": "TerrainRegistry",
		})
		count += 1
	return {
		"source": "TerrainRegistry",
		"label_count": count,
		"samples": samples,
	}


func _build_walkability_layer(container: Node3D, terrain_registry) -> Dictionary:
	var samples: Array = []
	var count: int = 0
	for tile in _get_floor_tiles(terrain_registry):
		if count >= max_tile_labels:
			break
		var grid_position: Vector2i = Vector2i(tile.grid_position)
		var walkable: bool = bool(tile.walkable)
		var transition_type: String = String(tile.height_transition_type)
		var label_text: String = "%s %s" % ["W" if walkable else "BLOCK", transition_type.to_upper()]
		var color: Color = Color(0.52, 1.0, 0.54, 1.0) if walkable else Color(1.0, 0.35, 0.28, 1.0)
		_add_label(container, "walk_%d_%d_%d" % [grid_position.x, grid_position.y, int(tile.floor_index)], label_text, _project_tile_label_position(tile, terrain_registry, 0.85), color)
		samples.append({
			"grid_position": grid_position,
			"floor_index": int(tile.floor_index),
			"walkable": walkable,
			"surface_type": String(tile.surface_type),
			"height_transition_type": transition_type,
			"floor_links": Array(tile.floor_links).duplicate(true),
			"source": "TerrainRegistry",
		})
		count += 1
	return {
		"source": "TerrainRegistry",
		"label_count": count,
		"samples": samples,
	}


func _build_path_layer(container: Node3D, terrain_registry, simulation_root, order_visualizer) -> Dictionary:
	var samples: Array = []
	var command_path_count: int = 0
	var target_count: int = 0
	if simulation_root != null:
		var command_index: int = 0
		for command_variant in Array(simulation_root.get("command_queue")):
			if typeof(command_variant) != TYPE_DICTIONARY:
				continue
			var command: Dictionary = Dictionary(command_variant)
			if typeof(command.get("target_position", null)) == TYPE_VECTOR2:
				target_count += 1
				_add_world_label(container, "cmd_%d_target" % command_index, "TARGET", Vector2(command.get("target_position", Vector2.ZERO)), terrain_registry, Color(0.62, 0.96, 0.72, 1.0), 0.45)
				samples.append({
					"kind": "command_target",
					"command_type": String(command.get("command_type", "")),
					"unit_id": String(command.get("unit_id", "")),
					"world_position": Vector2(command.get("target_position", Vector2.ZERO)),
					"source": "SimulationRoot",
				})
			var path_index: int = 0
			for path_point_variant in Array(command.get("path", [])):
				if typeof(path_point_variant) != TYPE_VECTOR2 or command_path_count >= max_path_labels:
					continue
				command_path_count += 1
				_add_world_label(container, "cmd_%d_path_%d" % [command_index, path_index], "P%d" % path_index, Vector2(path_point_variant), terrain_registry, Color(0.44, 0.95, 0.64, 1.0), 0.25)
				samples.append({
					"kind": "command_path",
					"path_index": path_index,
					"unit_id": String(command.get("unit_id", "")),
					"world_position": Vector2(path_point_variant),
					"source": "SimulationRoot",
				})
				path_index += 1
			command_index += 1
	if order_visualizer != null:
		_append_order_visualizer_path_samples(container, terrain_registry, order_visualizer, samples)
	return {
		"source": "SimulationRoot/FireteamOrderVisualizer",
		"label_count": container.get_child_count(),
		"command_path_count": command_path_count,
		"target_count": target_count,
		"samples": samples,
	}


func _build_air_layer(container: Node3D, terrain_registry, simulation_root, unit_registry) -> Dictionary:
	var samples: Array = []
	var air_unit_count: int = 0
	var max_altitude_band_seen: int = 0
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		for unit in Array(unit_registry.call("get_all_units")):
			if unit == null or not (unit is Node2D):
				continue
			if not _is_air_unit(unit):
				continue
			var unit_id: String = _extract_unit_id(unit)
			var altitude_band: int = _extract_altitude_band(unit)
			var movement_layer: String = _extract_movement_layer(unit)
			max_altitude_band_seen = maxi(max_altitude_band_seen, altitude_band)
			var projection: Dictionary = Dictionary(_visual_projection.call("project_node2d", unit, terrain_registry, {
				"movement_layer": movement_layer,
				"altitude_band": altitude_band,
			}))
			if bool(projection.get("valid", false)):
				_add_label(container, "air_%s" % _sanitize_node_key(unit_id), "AIR %d" % altitude_band, Vector3(projection.get("debug_label_position_3d", Vector3.ZERO)), Color(1.0, 0.68, 0.28, 1.0))
			samples.append({
				"kind": "air_unit",
				"unit_id": unit_id,
				"movement_layer": movement_layer,
				"altitude_band": altitude_band,
				"source": "UnitRegistry",
			})
			air_unit_count += 1
	var air_debug: Dictionary = _get_air_debug_snapshot(simulation_root)
	var targeting: Dictionary = Dictionary(air_debug.get("targeting", {}))
	var targeting_reason: String = String(targeting.get("reason", ""))
	if not targeting_reason.is_empty():
		_add_label(container, "aa_gate_reason", "AA %s" % targeting_reason, Vector3(0.0, 1.6, 0.0), Color(1.0, 0.42, 0.42, 1.0))
		samples.append({
			"kind": "aa_gate",
			"reason": targeting_reason,
			"target_unit_id": String(targeting.get("target_unit_id", "")),
			"attacker_unit_id": String(targeting.get("attacker_unit_id", "")),
			"source": "SimulationRoot",
		})
	return {
		"source": "UnitRegistry/SimulationRoot",
		"label_count": container.get_child_count(),
		"air_unit_count": air_unit_count,
		"max_altitude_band": max_altitude_band_seen,
		"targeting_reason": targeting_reason,
		"air_debug": air_debug,
		"samples": samples,
	}


func _append_order_visualizer_path_samples(container: Node3D, terrain_registry, order_visualizer, samples: Array) -> void:
	if order_visualizer.has_method("get_visible_waypoints"):
		var waypoint_index: int = 0
		for waypoint_variant in Array(order_visualizer.call("get_visible_waypoints")):
			if typeof(waypoint_variant) != TYPE_DICTIONARY:
				continue
			var waypoint: Dictionary = Dictionary(waypoint_variant)
			if typeof(waypoint.get("position", null)) != TYPE_VECTOR2:
				continue
			_add_world_label(container, "preview_waypoint_%d" % waypoint_index, "WP", Vector2(waypoint.get("position", Vector2.ZERO)), terrain_registry, Color(0.38, 1.0, 0.62, 1.0), 0.35)
			samples.append({
				"kind": "preview_waypoint",
				"world_position": Vector2(waypoint.get("position", Vector2.ZERO)),
				"source": "FireteamOrderVisualizer",
			})
			waypoint_index += 1
	if order_visualizer.has_method("get_visible_area_orders"):
		var area_index: int = 0
		for area_variant in Array(order_visualizer.call("get_visible_area_orders")):
			if typeof(area_variant) != TYPE_DICTIONARY:
				continue
			var area_order: Dictionary = Dictionary(area_variant)
			if typeof(area_order.get("center_position", null)) == TYPE_VECTOR2:
				_add_world_label(container, "preview_area_%d" % area_index, "AREA", Vector2(area_order.get("center_position", Vector2.ZERO)), terrain_registry, Color(0.38, 1.0, 0.62, 1.0), 0.35)
				samples.append({
					"kind": "preview_area",
					"world_position": Vector2(area_order.get("center_position", Vector2.ZERO)),
					"source": "FireteamOrderVisualizer",
				})
			area_index += 1


func _get_floor_tiles(terrain_registry) -> Array:
	if terrain_registry != null and terrain_registry.has_method("get_all_floor_tiles"):
		return Array(terrain_registry.call("get_all_floor_tiles"))
	if terrain_registry != null and terrain_registry.has_method("get_all_tiles"):
		return Array(terrain_registry.call("get_all_tiles"))
	return []


func _project_tile_label_position(tile, terrain_registry, y_offset: float) -> Vector3:
	var projection: Dictionary = Dictionary(_visual_projection.call("project_world_position", Vector2(tile.world_position), terrain_registry, {
		"floor_index": int(tile.floor_index),
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))
	return Vector3(projection.get("debug_label_position_3d", Vector3.ZERO)) + Vector3(0.0, y_offset, 0.0)


func _add_world_label(container: Node3D, node_name: String, label_text: String, world_position: Vector2, terrain_registry, color: Color, y_offset: float) -> void:
	var projection: Dictionary = Dictionary(_visual_projection.call("project_world_position", world_position, terrain_registry, {
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND,
	}))
	if not bool(projection.get("valid", false)):
		return
	_add_label(container, node_name, label_text, Vector3(projection.get("debug_label_position_3d", Vector3.ZERO)) + Vector3(0.0, y_offset, 0.0), color)


func _add_label(container: Node3D, node_name: String, label_text: String, position: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = label_text
	label.position = position
	label.font_size = 22
	label.outline_size = 4
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	container.add_child(label)
	return label


func _ensure_layer_containers() -> void:
	for layer_id in ALL_LAYERS:
		_get_layer_container(layer_id)


func _get_layer_container(layer_id: String) -> Node3D:
	var container_name: String = "Layer_%s" % layer_id
	var container := get_node_or_null(container_name) as Node3D
	if container != null:
		return container
	container = Node3D.new()
	container.name = container_name
	add_child(container)
	return container


func _clear_all_layer_visuals() -> void:
	for layer_id in ALL_LAYERS:
		_clear_children(_get_layer_container(layer_id))


func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.free()


func _configure_visual_projection() -> void:
	var bridge = get_node_or_null(bridge_path)
	if bridge != null and bridge.has_method("get_visual_projection_config"):
		var config: Dictionary = Dictionary(bridge.call("get_visual_projection_config"))
		_visual_projection.call("configure_grid", float(config.get("cell_size", 2.0)), float(config.get("height_step", 0.35)))


func _get_air_debug_snapshot(simulation_root) -> Dictionary:
	if simulation_root != null and simulation_root.has_method("get_air_layer_debug_snapshot"):
		return Dictionary(simulation_root.call("get_air_layer_debug_snapshot")).duplicate(true)
	return {}


func _is_air_unit(unit: Object) -> bool:
	if unit != null and unit.has_method("is_air_unit") and bool(unit.call("is_air_unit")):
		return true
	return MOVEMENT_LAYER_SCRIPT.is_air_layer(_extract_movement_layer(unit))


func _extract_unit_id(unit: Object) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	if unit != null:
		return String(unit.get("name")).strip_edges()
	return ""


func _extract_movement_layer(unit: Object) -> String:
	if unit != null and unit.has_method("get_movement_layer"):
		return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(unit.call("get_movement_layer")))
	if unit != null and unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null:
			return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(runtime_status.get("movement_layer")))
	return MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND


func _extract_altitude_band(unit: Object) -> int:
	if unit != null and unit.has_method("get_altitude_band"):
		return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(unit.call("get_altitude_band"))
	if unit != null and unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null:
			return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(runtime_status.get("altitude_band"))
	return MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND


func _sanitize_node_key(value: String) -> String:
	var key: String = value.strip_edges()
	for needle in ["/", "\\", ":", " ", ".", "-"]:
		key = key.replace(needle, "_")
	return key


func _collect_data_sources(layers: Dictionary) -> PackedStringArray:
	var sources: PackedStringArray = []
	for layer_id in layers.keys():
		var layer: Dictionary = Dictionary(layers.get(layer_id, {}))
		var source: String = String(layer.get("source", ""))
		if source.is_empty() or sources.has(source):
			continue
		sources.append(source)
	return sources


func _base_snapshot(is_enabled: bool, reason: String) -> Dictionary:
	return {
		"enabled": is_enabled,
		"valid": reason.is_empty(),
		"reason": reason,
		"layers": {},
		"data_sources": [],
	}
