extends Node

@export var event_router_path: NodePath
@export var simulation_root_path: NodePath
@export var friendly_unit_paths: Array[NodePath] = []
@export var respawn_delay_ticks: int = 18
@export var default_respawn_target: String = "fob"

var _pending_respawns_by_unit_id: Dictionary = {}


func _ready() -> void:
	var event_router = get_node_or_null(event_router_path)
	var simulation_root = get_node_or_null(simulation_root_path)
	if event_router == null or simulation_root == null:
		push_warning("MissionRespawnDriver requires direct EventRouter and SimulationRoot references.")
		return

	if not event_router.respawn_requested.is_connected(_on_respawn_requested):
		event_router.respawn_requested.connect(_on_respawn_requested)

	if not simulation_root.tick_processed.is_connected(_on_tick_processed):
		simulation_root.tick_processed.connect(_on_tick_processed)


func _on_respawn_requested(unit: Node, respawn_target: String) -> void:
	if unit == null or not unit.has_method("get_unit_id"):
		return

	if not _is_tracked_friendly_unit(unit):
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	if unit_id.is_empty() or _pending_respawns_by_unit_id.has(unit_id):
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	var current_tick: int = 0
	if simulation_root != null and simulation_root.has_method("get_tick"):
		current_tick = int(simulation_root.call("get_tick"))

	_pending_respawns_by_unit_id[unit_id] = {
		"due_tick": current_tick + maxi(respawn_delay_ticks, 1),
		"respawn_target": respawn_target if not respawn_target.is_empty() else default_respawn_target,
	}


func _on_tick_processed(tick: int) -> void:
	if _pending_respawns_by_unit_id.is_empty():
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("enqueue_effect"):
		return

	var ready_unit_ids: PackedStringArray = []
	for unit_id in _pending_respawns_by_unit_id.keys():
		var respawn_data: Dictionary = _pending_respawns_by_unit_id[unit_id]
		if tick < int(respawn_data.get("due_tick", tick + 1)):
			continue

		simulation_root.call(
			"enqueue_effect",
			{
				"effect_type": "respawn",
				"priority": 15,
				"unit_id": unit_id,
				"respawn_target": String(respawn_data.get("respawn_target", default_respawn_target)),
			}
		)
		ready_unit_ids.append(unit_id)

	for unit_id in ready_unit_ids:
		_pending_respawns_by_unit_id.erase(unit_id)


func _is_tracked_friendly_unit(unit: Node) -> bool:
	for unit_path in friendly_unit_paths:
		if get_node_or_null(unit_path) == unit:
			return true

	return false
