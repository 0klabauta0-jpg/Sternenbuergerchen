class_name MissionDropshipEffectAdapter
extends RefCounted


func enqueue_embark_effect(simulation_root: Node, unit: Node, unit_id: String, world_position: Vector2) -> bool:
	_remember_known_unit(simulation_root, unit, unit_id)
	return _enqueue_effect(
		simulation_root,
		{
			"effect_type": "dropship_embark_unit",
			"unit_id": unit_id,
			"position": world_position,
			"visible": false,
			"priority": 30,
		}
	)


func enqueue_presence_effect(simulation_root: Node, unit: Node, unit_id: String, is_visible: bool) -> bool:
	_remember_known_unit(simulation_root, unit, unit_id)
	var effect_type: String = "dropship_deploy_unit" if is_visible else "dropship_embark_unit"
	return _enqueue_effect(
		simulation_root,
		{
			"effect_type": effect_type,
			"unit_id": unit_id,
			"visible": is_visible,
			"priority": 30,
		}
	)


func enqueue_deploy_effect(simulation_root: Node, unit: Node, unit_id: String, world_position: Vector2, team_id: String = "") -> bool:
	_remember_known_unit(simulation_root, unit, unit_id)
	var effect: Dictionary = {
		"effect_type": "dropship_deploy_unit",
		"unit_id": unit_id,
		"position": world_position,
		"visible": true,
		"runtime_status": "idle",
		"runtime_active": true,
		"runtime_leader_path": NodePath("../RuntimeLeader"),
		"ftl_registry_path": NodePath("../FTLRegistry"),
		"priority": 30,
	}
	var normalized_team_id: String = team_id.strip_edges()
	if not normalized_team_id.is_empty():
		effect["team_id"] = normalized_team_id
	return _enqueue_effect(simulation_root, effect)


func _remember_known_unit(simulation_root: Node, unit: Node, unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or unit == null:
		return
	if simulation_root != null and simulation_root.has_method("register_known_unit"):
		simulation_root.call("register_known_unit", normalized_unit_id, unit)


func _enqueue_effect(simulation_root: Node, effect: Dictionary) -> bool:
	if simulation_root == null or not simulation_root.has_method("enqueue_effect"):
		return false
	simulation_root.call("enqueue_effect", effect)
	return true
