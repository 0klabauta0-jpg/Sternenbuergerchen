extends Node

const MAP_LOADER_SCRIPT: GDScript = preload("res://scripts/maps/map_loader.gd")
const MAP_DEFINITION_SCRIPT: GDScript = preload("res://scripts/maps/map_definition.gd")
const FRIENDLY_SPAWN_ROW_SPACING: float = 60.0
const ENEMY_SPAWN_ROW_SPACING: float = 82.0

@export var team_id: String = "team_alpha"
@export var runtime_leader_path: NodePath
@export var unit_registry_path: NodePath
@export var ftl_registry_path: NodePath
@export var map_root_path: NodePath
@export var target_marker_path: NodePath
@export var fallback_map_definition: Resource
@export var unit_paths: Array[NodePath] = []
@export var selected_team_unit_ids: PackedStringArray = []

var _is_initialized: bool = false


func _ready() -> void:
	if _is_initialized:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var ftl_registry = get_node_or_null(ftl_registry_path)
	if runtime_leader == null or unit_registry == null or ftl_registry == null:
		push_warning("MissionTestSetup requires direct references to RuntimeLeader, UnitRegistry and FTLRegistry.")
		return

	_apply_map_definition(_resolve_map_definition())

	var first_unit: Node = null
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		var unit_id: String = String(unit.call("get_unit_id"))
		var unit_team_id: String = ""
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id"))

		if unit_team_id == team_id and not _is_selected_friendly_unit(unit_id):
			if unit is CanvasItem:
				unit.visible = false
			continue

		if unit is CanvasItem:
			unit.visible = true

		unit_registry.call("register_unit", unit_id, unit)

		if unit_team_id == team_id:
			runtime_leader.call("add_unit_member", unit)

		if first_unit == null and unit_team_id == team_id:
			first_unit = unit

	if first_unit != null:
		runtime_leader.call("assign", first_unit)

	ftl_registry.call("register_ftl", team_id, runtime_leader)
	_is_initialized = true


func _is_selected_friendly_unit(unit_id: String) -> bool:
	if selected_team_unit_ids.is_empty():
		return true

	return selected_team_unit_ids.has(unit_id)


func _resolve_map_definition() -> Resource:
	var map_root = get_node_or_null(map_root_path)
	return MAP_LOADER_SCRIPT.get_map_definition(map_root, fallback_map_definition)


func _apply_map_definition(map_definition: Resource) -> void:
	if not _is_map_definition_resource(map_definition):
		return

	var friendly_spawn_points: Array = []
	var raw_friendly_spawn_points: Variant = map_definition.get("friendly_spawn_points")
	if raw_friendly_spawn_points != null:
		friendly_spawn_points = Array(raw_friendly_spawn_points)

	var enemy_spawn_points: Array = []
	var raw_enemy_spawn_points: Variant = map_definition.get("enemy_spawn_points")
	if raw_enemy_spawn_points != null:
		enemy_spawn_points = Array(raw_enemy_spawn_points)

	_apply_unit_positions(
		_get_selected_friendly_units(),
		_build_spawn_positions(
			Vector2(map_definition.get("spawn_alpha")),
			friendly_spawn_points,
			_get_selected_friendly_units().size(),
			FRIENDLY_SPAWN_ROW_SPACING
		)
	)
	_apply_unit_positions(
		_get_enemy_units(),
		_build_spawn_positions(
			Vector2(map_definition.get("spawn_bravo")),
			enemy_spawn_points,
			_get_enemy_units().size(),
			ENEMY_SPAWN_ROW_SPACING
		)
	)
	_apply_objective_position(Vector2(map_definition.get("objective_position")))


func _get_selected_friendly_units() -> Array:
	var friendly_units: Array = []
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_team_id") or not unit.has_method("get_unit_id"):
			continue

		if String(unit.call("get_team_id")) != team_id:
			continue

		if not _is_selected_friendly_unit(String(unit.call("get_unit_id"))):
			continue

		friendly_units.append(unit)

	return friendly_units


func _get_enemy_units() -> Array:
	var enemy_units: Array = []
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_team_id"):
			continue

		if String(unit.call("get_team_id")) == team_id:
			continue

		enemy_units.append(unit)

	return enemy_units


func _build_spawn_positions(
	base_spawn: Vector2,
	explicit_spawn_points: Array[Vector2],
	required_count: int,
	row_spacing: float
) -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	for spawn_point in explicit_spawn_points:
		spawn_positions.append(spawn_point)
		if spawn_positions.size() >= required_count:
			return spawn_positions

	var next_spawn_index: int = spawn_positions.size()
	while spawn_positions.size() < required_count:
		spawn_positions.append(base_spawn + Vector2(0.0, row_spacing * next_spawn_index))
		next_spawn_index += 1

	return spawn_positions


func _apply_unit_positions(units: Array, spawn_positions: Array[Vector2]) -> void:
	var position_count: int = mini(units.size(), spawn_positions.size())
	for unit_index in range(position_count):
		var unit = units[unit_index]
		if unit is Node2D:
			(unit as Node2D).position = spawn_positions[unit_index]


func _apply_objective_position(objective_position: Vector2) -> void:
	var target_marker = get_node_or_null(target_marker_path)
	if target_marker is Node2D:
		(target_marker as Node2D).position = objective_position


func _is_map_definition_resource(resource: Resource) -> bool:
	return resource != null and resource.get_script() == MAP_DEFINITION_SCRIPT
