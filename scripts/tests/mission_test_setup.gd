extends Node

@export var team_id: String = "team_alpha"
@export var runtime_leader_path: NodePath
@export var unit_registry_path: NodePath
@export var ftl_registry_path: NodePath
@export var map_root_path: NodePath
@export var target_marker_path: NodePath
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

	var first_unit: Node = null
	var friendly_units: Array = []
	var enemy_units: Array = []
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
			friendly_units.append(unit)
		else:
			enemy_units.append(unit)

		if first_unit == null and unit_team_id == team_id:
			first_unit = unit

	_apply_map_positions(friendly_units, enemy_units)

	if first_unit != null:
		runtime_leader.call("assign", first_unit)

	ftl_registry.call("register_ftl", team_id, runtime_leader)
	_is_initialized = true


func _is_selected_friendly_unit(unit_id: String) -> bool:
	if selected_team_unit_ids.is_empty():
		return true

	return selected_team_unit_ids.has(unit_id)


func _apply_map_positions(friendly_units: Array, enemy_units: Array) -> void:
	var map_root = get_node_or_null(map_root_path)
	if map_root == null:
		return

	var spawn_alpha = _resolve_map_marker(map_root, "spawn_alpha")
	var spawn_bravo = _resolve_map_marker(map_root, "spawn_bravo")
	var objective_point = _resolve_map_marker(map_root, "objective_point")
	_position_units_from_marker(friendly_units, spawn_alpha, _friendly_formation_offsets())
	_position_units_from_marker(enemy_units, spawn_bravo, _enemy_formation_offsets())

	var target_marker = get_node_or_null(target_marker_path)
	if objective_point != null and target_marker is Node2D:
		(target_marker as Node2D).position = objective_point.position


func _resolve_map_marker(map_root: Node, marker_name: String):
	var marker = map_root.get_node_or_null(marker_name)
	if marker != null and marker is Node2D:
		return marker

	return null


func _position_units_from_marker(units: Array, marker, offsets: Array) -> void:
	if marker == null:
		return

	var base_position: Vector2 = marker.position
	var unit_index: int = 0
	for unit in units:
		if not (unit is Node2D):
			continue

		var offset: Vector2 = Vector2.ZERO
		if unit_index < offsets.size():
			offset = offsets[unit_index]

		(unit as Node2D).position = base_position + offset
		unit_index += 1


func _friendly_formation_offsets() -> Array:
	return [
		Vector2(0.0, 0.0),
		Vector2(30.0, 34.0),
		Vector2(-28.0, 68.0),
	]


func _enemy_formation_offsets() -> Array:
	return [
		Vector2(0.0, 0.0),
		Vector2(-34.0, 38.0),
		Vector2(28.0, 74.0),
	]
