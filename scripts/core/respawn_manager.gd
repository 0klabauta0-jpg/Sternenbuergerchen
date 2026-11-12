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


func get_respawn_time(spawn_type: String = "") -> float:
	match _normalize_respawn_type(spawn_type):
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


func get_pending_respawn_details() -> Dictionary:
	var pending_copy: Dictionary = {}
	for unit_id in _pending_respawns:
		var entry: Dictionary = _pending_respawns[unit_id]
		pending_copy[unit_id] = {
			"time_remaining": float(entry.get("time_remaining", 0.0)),
			"team_id": String(entry.get("team_id", "")),
			"spawn_type": String(entry.get("spawn_type", _normalize_respawn_type(""))),
			"respawn_time": float(entry.get("respawn_time", get_respawn_time(String(entry.get("spawn_type", ""))))),
		}
	return pending_copy


func get_remaining_time(unit_id: String) -> float:
	if unit_id.is_empty() or not _pending_respawns.has(unit_id):
		return 0.0

	var entry: Dictionary = _pending_respawns[unit_id]
	return maxf(float(entry.get("time_remaining", 0.0)), 0.0)


func request_respawn(unit_id: String, team_id: String, spawn_type: String = "") -> bool:
	if unit_id.is_empty() or team_id.is_empty():
		return false

	if _pending_respawns.has(unit_id):
		return false
	if not _should_process_locally():return false
	var simulation:Node=get_node_or_null(simulation_root_path)
	if simulation!=null and simulation.has_method("is_hex_ground_runtime_required") and simulation.is_hex_ground_runtime_required():
		return bool(simulation.begin_hex_respawn(self,unit_id,team_id,_normalize_respawn_type(spawn_type)).get("ok",false))

	var unit = _resolve_unit(unit_id)
	if unit == null:
		return false

	if unit.has_method("begin_respawn"):
		if unit.call("begin_respawn")==false:return false

	var normalized_spawn_type: String = _normalize_respawn_type(spawn_type)
	var respawn_time: float = get_respawn_time(normalized_spawn_type)
	_pending_respawns[unit_id] = {
		"time_remaining": respawn_time,
		"team_id": team_id,
		"spawn_type": normalized_spawn_type,
		"respawn_time": respawn_time,
	}
	unit_respawn_started.emit(unit_id, respawn_time)
	return true


func _physics_process(delta: float) -> void:
	if not _should_process_locally():
		return

	if _pending_respawns.is_empty():
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		for unit_id in _pending_respawns.keys():
			if _pending_respawns[unit_id].has("hex_ticket"):_pending_respawns.erase(unit_id)
		return

	var completed_ids: PackedStringArray = []
	for unit_id in _pending_respawns.keys():
		if not _pending_respawns.has(unit_id):continue
		var entry: Dictionary = _pending_respawns[unit_id]
		if entry.has("hex_ticket"):
			var bound_root=entry.root.get_ref()
			if not is_instance_valid(bound_root) or bound_root!=simulation_root:
				_pending_respawns.erase(unit_id)
				continue
			var receipt:Dictionary=bound_root.get_hex_respawn_receipt(entry.hex_ticket)
			if not receipt.get("ok",false) or receipt.get("status","") in ["stale","cancelled"]:
				_pending_respawns.erase(unit_id)
				continue
			entry.time_remaining=maxf(float(entry.time_remaining)-maxf(delta,0.0),0.0)
			if entry.time_remaining<=0.0:bound_root.enqueue_hex_respawn(entry.hex_ticket,get_spawn_position(entry.team_id))
			continue
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


## Assignment-only tails called by the validated Root transaction.
func _publish_hex_respawn_begin(unit_id:String,entry:Dictionary)->void:
	_pending_respawns[unit_id]=entry


func _finalize_hex_respawn_started(unit_id:String,ticket:String)->void:
	if not _pending_respawns.has(unit_id) or _pending_respawns[unit_id].get("hex_ticket","")!=ticket:return
	var entry:Dictionary=_pending_respawns[unit_id]
	if entry.started:return
	entry.started=true
	unit_respawn_started.emit(unit_id,entry.respawn_time)


func _publish_hex_respawn_complete(unit_id:String,ticket:String)->void:
	if _pending_respawns.has(unit_id) and _pending_respawns[unit_id].get("hex_ticket","")==ticket:_pending_respawns.erase(unit_id)


func _finalize_hex_respawn_completed(unit_id:String,_ticket:String)->void:
	if not _pending_respawns.has(unit_id):unit_respawn_completed.emit(unit_id)


func _resolve_unit(unit_id: String):
	if unit_id.is_empty() or unit_registry_path.is_empty():
		return null

	var unit_registry = get_node_or_null(unit_registry_path)
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		return null

	return unit_registry.call("get_unit", unit_id)


func _normalize_respawn_type(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	if normalized.is_empty():
		normalized = respawn_type.strip_edges().to_lower()
	match normalized:
		"fob", "homebase":
			return normalized
		_:
			return "rover"


func _should_process_locally() -> bool:
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root!=null and simulation_root.has_method("_should_skip_local_tick_processing") and simulation_root.call("_should_skip_local_tick_processing"):return false
	if simulation_root == null:
		return true

	var is_server_authoritative: Variant = simulation_root.get("is_server_authoritative")
	if not _variant_to_bool(is_server_authoritative):
		return true

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return true

	return multiplayer.is_server()


func _variant_to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized := String(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1"
		_:
			return value != null
