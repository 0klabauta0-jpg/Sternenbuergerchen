class_name RespawnManager
extends Node

## Respawn timer thresholds (in seconds) per spawn type, matching V1 design:
## Rover: 30s, FOB: 150s (2.5 min), Homebase: 270s (4.5 min)

const RESPAWN_TIME_ROVER: float = 30.0
const RESPAWN_TIME_FOB: float = 150.0
const RESPAWN_TIME_HOMEBASE: float = 270.0

signal unit_respawn_started(unit_id: String, respawn_time: float)
signal unit_respawn_completed(unit_id: String)

@export var simulation_root_path: NodePath
@export var unit_registry_path: NodePath
@export var respawn_type: String = "rover"

## Spawn positions per team_id, set from outside (e.g. by MissionTestSetup).
var spawn_positions: Dictionary = {}

## Pending respawns: unit_id -> { "time_remaining": float, "team_id": String }
var _pending_respawns: Dictionary = {}


func get_respawn_time() -> float:
	match respawn_type:
		"fob":
			return RESPAWN_TIME_FOB
		"homebase":
			return RESPAWN_TIME_HOMEBASE
		_:
			return RESPAWN_TIME_ROVER


func set_spawn_position(team_id: String, position: Vector2) -> void:
	spawn_positions[team_id] = position


func get_spawn_position(team_id: String) -> Vector2:
	return spawn_positions.get(team_id, Vector2.ZERO)


func has_pending_respawn(unit_id: String) -> bool:
	return _pending_respawns.has(unit_id)


func get_pending_count() -> int:
	return _pending_respawns.size()


func get_pending_respawns() -> Dictionary:
	var pending_copy: Dictionary = {}
	for unit_id in _pending_respawns:
		var entry: Dictionary = _pending_respawns[unit_id]
		pending_copy[unit_id] = float(entry.get("time_remaining", 0.0))

	return pending_copy


func get_remaining_time(unit_id: String) -> float:
	if unit_id.is_empty() or not _pending_respawns.has(unit_id):
		return 0.0

	var entry: Dictionary = _pending_respawns[unit_id]
	return maxf(float(entry.get("time_remaining", 0.0)), 0.0)


func request_respawn(unit_id: String, team_id: String) -> bool:
	if unit_id.is_empty() or team_id.is_empty():
		return false

	if _pending_respawns.has(unit_id):
		return false

	var unit = _resolve_unit(unit_id)
	if unit == null:
		return false

	if unit.has_method("begin_respawn"):
		unit.call("begin_respawn")

	var respawn_time: float = get_respawn_time()
	_pending_respawns[unit_id] = {
		"time_remaining": respawn_time,
		"team_id": team_id,
	}
	unit_respawn_started.emit(unit_id, respawn_time)
	return true


func _physics_process(delta: float) -> void:
	if _pending_respawns.is_empty():
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		return

	var completed_ids: PackedStringArray = []
	for unit_id in _pending_respawns:
		var entry: Dictionary = _pending_respawns[unit_id]
		entry["time_remaining"] = maxf(float(entry["time_remaining"]) - delta, 0.0)

		if entry["time_remaining"] > 0.0:
			continue

		var team_id: String = String(entry["team_id"])
		var spawn_pos: Vector2 = get_spawn_position(team_id)
		simulation_root.call(
			"enqueue_effect",
			{
				"effect_type": "respawn",
				"priority": 10,
				"unit_id": unit_id,
				"spawn_position": spawn_pos,
			}
		)
		completed_ids.append(unit_id)

	for completed_id in completed_ids:
		_pending_respawns.erase(completed_id)
		unit_respawn_completed.emit(completed_id)


func _resolve_unit(unit_id: String):
	if unit_id.is_empty() or unit_registry_path.is_empty():
		return null

	var unit_registry = get_node_or_null(unit_registry_path)
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		return null

	return unit_registry.call("get_unit", unit_id)
