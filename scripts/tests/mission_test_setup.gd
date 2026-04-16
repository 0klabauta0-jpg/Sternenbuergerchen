extends Node

@export var team_id: String = "team_alpha"
@export var runtime_leader_path: NodePath
@export var unit_registry_path: NodePath
@export var ftl_registry_path: NodePath
@export var unit_paths: Array[NodePath] = []


func _ready() -> void:
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
		unit_registry.call("register_unit", unit_id, unit)
		runtime_leader.call("add_unit_member", unit)
		if first_unit == null:
			first_unit = unit

	if first_unit != null:
		runtime_leader.call("assign", first_unit)

	ftl_registry.call("register_ftl", team_id, runtime_leader)
