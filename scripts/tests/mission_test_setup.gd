extends Node

@export var team_id: String = "team_alpha"
@export var runtime_leader_path: NodePath
@export var unit_registry_path: NodePath
@export var ftl_registry_path: NodePath
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
