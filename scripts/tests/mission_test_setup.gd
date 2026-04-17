extends Node

const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
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
	if target_marker != null and objective_marker != null:
		target_marker.global_position = objective_marker.global_position

	var first_unit: Node = null
	var friendly_spawn_index: int = 0
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

		_apply_unit_identity_preset(unit, unit_id, unit_team_id)

		if unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", _get_fireteam_id_for_unit(unit_id, unit_team_id))

		var respawn_manager = get_node_or_null(respawn_manager_path)
		if respawn_manager != null and unit.has_method("set_respawn_manager"):
			unit.call("set_respawn_manager", respawn_manager)

		if unit_team_id == team_id and not _is_selected_friendly_unit(unit_id):
			if unit is CanvasItem:
				unit.visible = false
			continue

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


func _is_selected_friendly_unit(unit_id: String) -> bool:
	if selected_team_unit_ids.is_empty():
		return true

	return selected_team_unit_ids.has(unit_id)


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

	match unit_id:
		"unit_alpha", "unit_bravo":
			return "blue"
		"unit_charlie":
			return "gold"
		_:
			return ""
