extends Node

const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

@export var team_id: String = "team_alpha"
@export var runtime_leader_path: NodePath
@export var unit_registry_path: NodePath
@export var ftl_registry_path: NodePath
@export var target_marker_path: NodePath
@export var spawn_alpha_path: NodePath
@export var spawn_bravo_path: NodePath
@export var objective_point_path: NodePath
@export var unit_paths: Array[NodePath] = []
@export var selected_team_unit_ids: PackedStringArray = []
@export var respawn_manager_path: NodePath
@export var enemy_wave_controller_path: NodePath
@export var terrain_registry_path: NodePath
@export var map_file_path: String = "res://maps/test_mission.json"

var _is_initialized: bool = false


func _ready() -> void:
	if _is_initialized:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var ftl_registry = get_node_or_null(ftl_registry_path)
	var simulation_root = get_node_or_null("../SimulationRoot")
	if runtime_leader == null or unit_registry == null or ftl_registry == null or simulation_root == null:
		push_warning("MissionTestSetup requires direct references to RuntimeLeader, UnitRegistry, FTLRegistry and SimulationRoot.")
		return

	var spawn_alpha_marker := _resolve_marker(spawn_alpha_path)
	var spawn_bravo_marker := _resolve_marker(spawn_bravo_path)
	var objective_marker := _resolve_marker(objective_point_path)
	var target_marker := _resolve_marker(target_marker_path)
	var terrain_registry = _setup_terrain_registry()
	if target_marker != null and objective_marker != null:
		target_marker.global_position = objective_marker.global_position

	var first_unit: Node = null
	var friendly_spawn_index: int = 0
	var friendly_slot_index: int = 0
	var enemy_spawn_index: int = 0
	var enemy_units: Array = []
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		var unit_id: String = String(unit.call("get_unit_id"))
		var unit_team_id: String = ""
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id"))

		if unit_team_id == team_id:
			if not _is_friendly_slot_enabled(friendly_slot_index):
				if unit is CanvasItem:
					unit.visible = false
				friendly_slot_index += 1
				continue

			unit_id = _get_selected_unit_id_for_friendly_slot(friendly_slot_index, unit_id)
			friendly_slot_index += 1

		_apply_unit_identity_preset(unit, unit_id, unit_team_id)
		if unit.has_method("get_unit_id"):
			unit_id = String(unit.call("get_unit_id"))
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id"))

		if unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", _get_fireteam_id_for_unit(unit_id, unit_team_id))

		var respawn_manager = get_node_or_null(respawn_manager_path)
		if respawn_manager != null and unit.has_method("set_respawn_manager"):
			unit.call("set_respawn_manager", respawn_manager)
		if terrain_registry != null and unit.has_method("set_terrain_registry"):
			unit.call("set_terrain_registry", terrain_registry)

		if simulation_root.has_method("register_known_unit"):
			simulation_root.call("register_known_unit", unit_id, unit)

		if unit is Node2D:
			var unit_node: Node2D = unit
			if unit_team_id == team_id and spawn_alpha_marker != null:
				unit_node.global_position = spawn_alpha_marker.global_position + _get_friendly_spawn_offset(friendly_spawn_index)
				friendly_spawn_index += 1
			elif unit_team_id != team_id and spawn_bravo_marker != null:
				unit_node.global_position = spawn_bravo_marker.global_position + _get_enemy_spawn_offset(enemy_spawn_index)
				enemy_spawn_index += 1

			if unit is CanvasItem:
				unit.visible = true

			if terrain_registry != null and unit.has_method("refresh_terrain_readability"):
				unit.call("refresh_terrain_readability")

		unit_registry.call("register_unit", unit_id, unit)

		if unit_team_id == team_id:
			runtime_leader.call("add_unit_member", unit)
		else:
			enemy_units.append(unit)

		if first_unit == null and unit_team_id == team_id:
			first_unit = unit

	if first_unit != null:
		runtime_leader.call("assign", first_unit)

	ftl_registry.call("register_ftl", team_id, runtime_leader)
	_setup_objective_status(simulation_root, objective_marker)

	_setup_respawn_manager(spawn_alpha_marker, spawn_bravo_marker)
	_setup_enemy_waves(enemy_units)
	_is_initialized = true


func _is_friendly_slot_enabled(slot_index: int) -> bool:
	if selected_team_unit_ids.is_empty():
		return true

	return slot_index >= 0 and slot_index < selected_team_unit_ids.size()


func _get_selected_unit_id_for_friendly_slot(slot_index: int, fallback_unit_id: String) -> String:
	if not _is_friendly_slot_enabled(slot_index):
		return fallback_unit_id

	var selected_unit_id: String = String(selected_team_unit_ids[slot_index]).strip_edges()
	if selected_unit_id.is_empty():
		return fallback_unit_id

	return selected_unit_id


func _resolve_marker(node_path: NodePath) -> Marker2D:
	if node_path.is_empty():
		return null

	return get_node_or_null(node_path) as Marker2D


func _get_friendly_spawn_offset(index: int) -> Vector2:
	var offsets: Array[Vector2] = [
		Vector2(-24.0, 12.0),
		Vector2(0.0, 0.0),
		Vector2(24.0, -12.0),
	]
	if index >= 0 and index < offsets.size():
		return offsets[index]

	return Vector2(24.0 * float(index), 0.0)


func _get_enemy_spawn_offset(index: int) -> Vector2:
	var offsets: Array[Vector2] = [
		Vector2(-18.0, -10.0),
		Vector2(18.0, 10.0),
	]
	if index >= 0 and index < offsets.size():
		return offsets[index]

	return Vector2(18.0 * float(index), 0.0)


func _setup_respawn_manager(spawn_alpha: Marker2D, spawn_bravo: Marker2D) -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("set_spawn_position"):
		return

	if spawn_alpha != null:
		respawn_manager.call("set_spawn_position", team_id, spawn_alpha.global_position)

	if spawn_bravo != null:
		respawn_manager.call("set_spawn_position", "team_bravo", spawn_bravo.global_position)


func _setup_objective_status(simulation_root: Node, objective_marker: Marker2D) -> void:
	if objective_marker == null or not simulation_root.has_method("set_objective_status"):
		return

	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "objective_point"
	objective_status.position = objective_marker.global_position
	objective_status.capture_radius = 80.0
	simulation_root.call("set_objective_status", objective_status)


func _setup_enemy_waves(enemy_units: Array) -> void:
	var enemy_wave_controller = get_node_or_null(enemy_wave_controller_path)
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("initialize_enemy_units"):
		return

	enemy_wave_controller.call("initialize_enemy_units", enemy_units)


func _setup_terrain_registry():
	if terrain_registry_path.is_empty():
		return null

	var terrain_registry = get_node_or_null(terrain_registry_path)
	if terrain_registry == null:
		return null

	if not terrain_registry.has_method("clear_tiles") or not terrain_registry.has_method("configure_iso_grid") or not terrain_registry.has_method("register_tile"):
		return terrain_registry

	if _try_load_terrain_from_json(terrain_registry):
		return terrain_registry

	_setup_terrain_from_hardcode(terrain_registry)
	return terrain_registry


func _try_load_terrain_from_json(terrain_registry) -> bool:
	if map_file_path.is_empty() or not FileAccess.file_exists(map_file_path):
		return false

	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_file_path)
	if terrain_map_data == null or terrain_map_data.call("get_tiles").is_empty():
		return false

	var tile_size: Dictionary = terrain_map_data.call("get_tile_size")
	terrain_registry.call("clear_tiles")
	terrain_registry.call(
		"configure_iso_grid",
		terrain_map_data.call("get_grid_origin"),
		float(tile_size.get("half_width", 64.0)),
		float(tile_size.get("half_height", 32.0))
	)

	var terrain_root: Node = get_node_or_null("../MapRoot/Terrain")
	for tile_data in terrain_map_data.call("get_tiles"):
		terrain_registry.call("register_tile", tile_data)
		if terrain_root != null:
			var tile_sprite := _find_tile_sprite_at(terrain_root, tile_data.world_position)
			_apply_terrain_tile_visual(tile_sprite, tile_data)

	return true


func _find_tile_sprite_at(terrain_root: Node, world_position: Vector2) -> Sprite2D:
	var best_sprite: Sprite2D = null
	var best_distance: float = INF
	for child in terrain_root.get_children():
		if not child is Sprite2D:
			continue

		var tile_center: Vector2 = _get_tile_world_center(child)
		var distance: float = tile_center.distance_squared_to(world_position)
		if distance < best_distance:
			best_distance = distance
			best_sprite = child

	return best_sprite


func _setup_terrain_from_hardcode(terrain_registry) -> void:
	var terrain_root: Node = get_node_or_null("../MapRoot/Terrain")
	if terrain_root == null:
		return

	var terrain_tiles: Array = []
	for child in terrain_root.get_children():
		if child is Sprite2D:
			terrain_tiles.append(child)

	if terrain_tiles.is_empty():
		return

	var first_tile: Sprite2D = terrain_tiles[0]
	var second_tile: Sprite2D = terrain_tiles[1] if terrain_tiles.size() > 1 else null
	var grid_origin_world: Vector2 = _get_tile_world_center(first_tile)
	var half_tile_width: float = 64.0
	var half_tile_height: float = 32.0
	if second_tile != null:
		half_tile_width = absf(second_tile.global_position.x - first_tile.global_position.x)
		half_tile_height = absf(second_tile.global_position.y - first_tile.global_position.y)

	terrain_registry.call("clear_tiles")
	terrain_registry.call("configure_iso_grid", grid_origin_world, half_tile_width, half_tile_height)
	for terrain_tile in terrain_tiles:
		var tile_center: Vector2 = _get_tile_world_center(terrain_tile)
		var grid_position: Vector2i = terrain_registry.call("world_to_grid", tile_center)
		var tile_data = TERRAIN_TILE_DATA_SCRIPT.new(
			{
				"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
				"grid_position": grid_position,
				"world_position": tile_center,
				"walkable": not _is_blocked_tile(grid_position),
				"blocks_los": _blocks_line_of_sight(grid_position),
				"cover_value": _get_cover_value_for_tile(grid_position),
				"height_level": _get_height_level_for_tile(grid_position),
				"surface_type": _get_surface_type_for_tile(grid_position),
			}
		)
		terrain_registry.call("register_tile", tile_data)
		_apply_terrain_tile_visual(terrain_tile, tile_data)



func _apply_unit_identity_preset(unit, unit_id: String, unit_team_id: String) -> void:
	if unit == null or not unit.has_method("apply_identity_config"):
		return

	var preset: Dictionary = UNIT_ROSTER_PRESETS_SCRIPT.get_preset(unit_id, unit_team_id)
	if preset.is_empty():
		return

	unit.call("apply_identity_config", preset)


func _get_fireteam_id_for_unit(unit_id: String, unit_team_id: String) -> String:
	if unit_team_id != team_id:
		return ""

	var preset: Dictionary = UNIT_ROSTER_PRESETS_SCRIPT.get_preset(unit_id, unit_team_id)
	return String(preset.get("fireteam_id", "")).strip_edges().to_lower()


func _get_tile_world_center(tile_sprite: Sprite2D) -> Vector2:
	if tile_sprite == null or tile_sprite.texture == null:
		return Vector2.ZERO

	return tile_sprite.global_position + (tile_sprite.texture.get_size() * 0.5)


func _is_blocked_tile(grid_position: Vector2i) -> bool:
	return grid_position == Vector2i(4, 1) or grid_position == Vector2i(4, 2) or grid_position == Vector2i(5, 2)


func _blocks_line_of_sight(grid_position: Vector2i) -> bool:
	return grid_position == Vector2i(4, 2) or grid_position == Vector2i(5, 2)


func _get_cover_value_for_tile(grid_position: Vector2i) -> int:
	if grid_position == Vector2i(3, 4) or grid_position == Vector2i(4, 4) or grid_position == Vector2i(4, 5):
		return 20

	if grid_position == Vector2i(5, 3) or grid_position == Vector2i(2, 5):
		return 35

	return 0


func _get_height_level_for_tile(grid_position: Vector2i) -> int:
	if grid_position == Vector2i(4, 4) or grid_position == Vector2i(5, 3):
		return 2

	if (
		grid_position == Vector2i(3, 3)
		or grid_position == Vector2i(4, 3)
		or grid_position == Vector2i(3, 4)
		or grid_position == Vector2i(5, 4)
		or grid_position == Vector2i(3, 5)
		or grid_position == Vector2i(4, 5)
		or grid_position == Vector2i(5, 5)
	):
		return 1

	return 0


func _get_surface_type_for_tile(grid_position: Vector2i) -> String:
	if (
		grid_position == Vector2i(4, 0)
		or grid_position == Vector2i(3, 1)
		or grid_position == Vector2i(3, 2)
		or grid_position == Vector2i(3, 3)
		or grid_position == Vector2i(4, 4)
		or grid_position == Vector2i(3, 5)
	):
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD

	if (
		grid_position == Vector2i(2, 7)
		or grid_position == Vector2i(2, 6)
		or grid_position == Vector2i(1, 6)
		or grid_position == Vector2i(2, 5)
	):
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND

	if grid_position == Vector2i(5, 3) or grid_position == Vector2i(5, 4):
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK

	return TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND


func _apply_terrain_tile_visual(tile_sprite: Sprite2D, tile_data) -> void:
	if tile_sprite == null or tile_data == null:
		return

	var tile_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	match String(tile_data.surface_type):
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			tile_color = Color(0.82, 0.82, 0.84, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			tile_color = Color(1.0, 0.95, 0.72, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
			tile_color = Color(0.88, 0.78, 0.66, 1.0)

	var height_level: int = int(tile_data.height_level)
	if height_level == 1:
		tile_color = tile_color.lightened(0.08)
	elif height_level >= 2:
		tile_color = tile_color.lightened(0.16)

	if bool(tile_data.blocks_los):
		tile_color = tile_color.darkened(0.1)

	if not bool(tile_data.walkable):
		tile_color = tile_color.darkened(0.14)

	tile_sprite.modulate = tile_color
