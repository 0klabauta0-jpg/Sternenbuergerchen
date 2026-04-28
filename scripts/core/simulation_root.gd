class_name SimulationRoot
extends Node

signal tick_processed(tick: int)

const MOVE_SPEED_PER_SECOND: float = 120.0
const DAMAGE_MODEL_SCRIPT: GDScript = preload("res://scripts/core/damage_model.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC: int = 600
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const CAPTURE_PROGRESS_PER_TICK: float = 0.01
const HPA_NAVIGATION_CLUSTER_SIZE: int = 8

const HIT_CHANCE_MIN: float = 0.05
const HIT_CHANCE_MAX: float = 0.95
const ATTACKER_COVER_HIT_BONUS_FACTOR: float = 0.05
const TARGET_COVER_HIT_PENALTY_FACTOR: float = 0.35
const TARGET_COVER_DAMAGE_PENALTY_FACTOR: float = 0.2
const DAMAGE_MULTIPLIER_MIN: float = 0.1
const HEIGHT_ADVANTAGE_ACCURACY_BONUS: float = 0.1
const HEIGHT_DISADVANTAGE_ACCURACY_PENALTY: float = 0.05
const LOW_COVER_HEIGHT_THRESHOLD: float = 0.8
const MID_COVER_HEIGHT_THRESHOLD: float = 1.3
const HIGH_COVER_HEIGHT_THRESHOLD: float = 2.0

@export var is_server_authoritative: bool = false
@export var unit_registry_path: NodePath
@export var terrain_registry_path: NodePath
@export var combat_rng_seed: int = 1
@export var terrain_move_debug_enabled: bool = false
@export var navigation_budget_enabled: bool = true
@export_range(0, 64, 1) var navigation_max_new_path_queries_per_tick: int = 4
@export var navigation_debug_enabled: bool = false
@export_range(1, 128, 1) var navigation_debug_query_history_limit: int = 24
@export var navigation_cover_aware_enabled: bool = false
@export_range(0.0, 8.0, 0.1) var navigation_default_exposure_weight: float = 0.8
@export_range(0.0, 8.0, 0.1) var navigation_default_cover_weight: float = 0.25
@export_range(1.0, 64.0, 1.0) var navigation_exposure_max_grid_distance: float = 8.0
@export var local_avoidance_enabled: bool = false
@export var local_avoidance_debug_enabled: bool = false
@export_range(4.0, 96.0, 1.0) var local_avoidance_agent_radius: float = 18.0
@export_range(8.0, 192.0, 1.0) var local_avoidance_neighbor_radius: float = 56.0
@export_range(8.0, 192.0, 1.0) var local_avoidance_spatial_cell_size: float = 64.0
@export_range(1, 32, 1) var local_avoidance_max_neighbors: int = 8
@export_range(0.1, 5.0, 0.1) var local_avoidance_stuck_threshold_seconds: float = 1.0
@export_range(0.0, 60.0, 1.0) var local_avoidance_stuck_speed_threshold: float = 5.0

var command_queue: Array = []
var effects_queue: Array = []
var tick_counter: int = 0
var is_processing_tick: bool = false
var _contact_path_recompute_ready_at_msec: Dictionary = {}
var _objective_status: RefCounted = null
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
var _last_terrain_move_debug_by_unit_id: Dictionary = {}
var _known_units_by_id: Dictionary = {}
var _peer_team_assignments: Dictionary = {1: "team_alpha"}
var _last_broadcast_vital_state_by_unit_id: Dictionary = {}
var _last_server_state: Dictionary = {}
var _combat_rng := RandomNumberGenerator.new()
var _hpa_navigation_graph = null
var _hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
var _hpa_navigation_registry = null
var _hpa_navigation_tile_count: int = -1
var _navigation_new_path_queries_this_tick: int = 0
var _navigation_path_queries_this_tick: int = 0
var _navigation_delayed_this_tick: int = 0
var _navigation_fallback_queries_this_tick: int = 0
var _navigation_unreachable_queries_this_tick: int = 0
var _navigation_last_delay_reason: String = ""
var _navigation_last_tick_queries: Array = []
var _navigation_most_expensive_query: Dictionary = {}
var _navigation_last_path_metrics: Dictionary = {}
var _local_avoidance_resolver = LOCAL_AVOIDANCE_RESOLVER_SCRIPT.new()
var _local_avoidance_prepared_tick: int = -1
var _local_avoidance_debug_by_unit_id: Dictionary = {}
var _local_avoidance_stuck_seconds_by_unit_id: Dictionary = {}
var _last_air_move_debug_by_unit_id: Dictionary = {}
var _last_air_targeting_debug: Dictionary = {}


func _init() -> void:
	_combat_rng.seed = int(combat_rng_seed)


func _ready() -> void:
	set_combat_rng_seed(combat_rng_seed)


func enqueue_command(cmd: Dictionary) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_command expects a Dictionary command.")
		return

	var command_token: String = String(cmd.get("command_token", "")).strip_edges()
	if not command_token.is_empty():
		for index in range(command_queue.size()):
			var queued_command: Dictionary = Dictionary(command_queue[index])
			if String(queued_command.get("command_token", "")).strip_edges() != command_token:
				continue
			command_queue[index] = cmd.duplicate(true)
			return

	command_queue.append(cmd)


func enqueue_effect(effect: Dictionary) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_effect expects a Dictionary effect.")
		return

	effects_queue.append(effect)


func set_terrain_move_debug_enabled(enabled: bool) -> void:
	terrain_move_debug_enabled = enabled
	if not terrain_move_debug_enabled:
		_last_terrain_move_debug_by_unit_id.clear()


func get_terrain_move_debug_snapshot(unit_id: String = "") -> Variant:
	if unit_id.strip_edges().is_empty():
		var result: Array = []
		var unit_ids: Array = _last_terrain_move_debug_by_unit_id.keys()
		unit_ids.sort()
		for unit_id_variant in unit_ids:
			result.append(Dictionary(_last_terrain_move_debug_by_unit_id.get(unit_id_variant, {})).duplicate(true))
		return result
	return Dictionary(_last_terrain_move_debug_by_unit_id.get(unit_id.strip_edges(), {})).duplicate(true)


func set_navigation_budget_enabled(enabled: bool) -> void:
	navigation_budget_enabled = enabled


func set_navigation_max_new_path_queries_per_tick(limit: int) -> void:
	navigation_max_new_path_queries_per_tick = maxi(0, limit)


func set_navigation_debug_enabled(enabled: bool) -> void:
	navigation_debug_enabled = enabled
	if not navigation_debug_enabled:
		_navigation_last_tick_queries.clear()
		_navigation_most_expensive_query.clear()
		_navigation_last_path_metrics.clear()


func get_navigation_debug_snapshot() -> Dictionary:
	return {
		"enabled": navigation_debug_enabled,
		"budget_enabled": navigation_budget_enabled,
		"tick": tick_counter,
		"max_new_path_queries_per_tick": navigation_max_new_path_queries_per_tick,
		"new_path_queries_this_tick": _navigation_new_path_queries_this_tick,
		"path_queries_this_tick": _navigation_path_queries_this_tick,
		"fallback_queries_this_tick": _navigation_fallback_queries_this_tick,
		"unreachable_queries_this_tick": _navigation_unreachable_queries_this_tick,
		"delayed_this_tick": _navigation_delayed_this_tick,
		"pending_query_count": _count_pending_navigation_queries(),
		"last_delay_reason": _navigation_last_delay_reason,
		"last_queries": _duplicate_dictionary_array(_navigation_last_tick_queries),
		"most_expensive_query": _navigation_most_expensive_query.duplicate(true),
		"last_path_metrics": _navigation_last_path_metrics.duplicate(true),
	}


func set_local_avoidance_enabled(enabled: bool) -> void:
	local_avoidance_enabled = enabled
	_local_avoidance_prepared_tick = -1
	if not local_avoidance_enabled:
		_local_avoidance_resolver.clear()


func set_local_avoidance_debug_enabled(enabled: bool) -> void:
	local_avoidance_debug_enabled = enabled
	if not local_avoidance_debug_enabled:
		_local_avoidance_debug_by_unit_id.clear()


func get_local_avoidance_debug_snapshot(unit_id: String = "") -> Variant:
	if unit_id.strip_edges().is_empty():
		var result: Array = []
		var unit_ids: Array = _local_avoidance_debug_by_unit_id.keys()
		unit_ids.sort()
		for unit_id_variant in unit_ids:
			result.append(Dictionary(_local_avoidance_debug_by_unit_id.get(unit_id_variant, {})).duplicate(true))
		return result
	return Dictionary(_local_avoidance_debug_by_unit_id.get(unit_id.strip_edges(), {})).duplicate(true)


func get_air_layer_debug_snapshot(unit_id: String = "") -> Dictionary:
	var movement_records: Variant = null
	if unit_id.strip_edges().is_empty():
		var records: Array = []
		var unit_ids: Array = _last_air_move_debug_by_unit_id.keys()
		unit_ids.sort()
		for unit_id_variant in unit_ids:
			records.append(Dictionary(_last_air_move_debug_by_unit_id.get(unit_id_variant, {})).duplicate(true))
		movement_records = records
	else:
		movement_records = Dictionary(_last_air_move_debug_by_unit_id.get(unit_id.strip_edges(), {})).duplicate(true)
	return {
		"movement": movement_records,
		"targeting": _last_air_targeting_debug.duplicate(true),
	}


func clear_queues() -> void:
	command_queue.clear()
	effects_queue.clear()


func get_tick() -> int:
	return tick_counter


func set_combat_rng_seed(seed_value: int) -> void:
	combat_rng_seed = seed_value
	_combat_rng.seed = int(seed_value)


func get_next_combat_roll() -> float:
	return _combat_rng.randf()


func register_known_unit(unit_id: String, unit: Node) -> bool:
	if unit_id.is_empty() or unit == null:
		return false

	_known_units_by_id[unit_id] = unit
	return true


func set_peer_team(peer_id: int, team_id: String) -> void:
	if peer_id <= 0:
		return

	var normalized_team_id: String = team_id.strip_edges()
	if normalized_team_id.is_empty():
		_peer_team_assignments.erase(peer_id)
		return

	_peer_team_assignments[peer_id] = normalized_team_id


func set_peer_team_assignments(assignments: Dictionary) -> void:
	_peer_team_assignments.clear()
	for raw_peer_id in assignments.keys():
		var peer_id: int = int(raw_peer_id)
		var team_id: String = String(assignments[raw_peer_id]).strip_edges()
		if peer_id <= 0 or team_id.is_empty():
			continue

		_peer_team_assignments[peer_id] = team_id

	if not _peer_team_assignments.has(1):
		_peer_team_assignments[1] = "team_alpha"


func get_peer_team(peer_id: int) -> String:
	if peer_id <= 0:
		return ""

	return String(_peer_team_assignments.get(peer_id, ""))


func get_last_server_state() -> Dictionary:
	return _last_server_state.duplicate(true)


func set_objective_status(objective_status) -> bool:
	if objective_status == null:
		_objective_status = null
		return true

	if not _is_valid_objective_status(objective_status):
		push_warning("SimulationRoot.set_objective_status expects a valid ObjectiveStatus-like object.")
		return false

	_objective_status = objective_status
	return true


func get_objective_status():
	return _objective_status


@rpc("any_peer", "reliable")
func request_command(command_dict: Dictionary) -> void:
	if not is_server_authoritative:
		enqueue_command(command_dict)
		return

	if _has_active_multiplayer_peer() and not multiplayer.is_server():
		push_warning("SimulationRoot.request_command can only be executed on the authority while server-authoritative mode is active.")
		return

	if not _is_valid_network_command(command_dict):
		push_warning("SimulationRoot rejected an invalid network command.")
		return

	var sending_peer_id: int = multiplayer.get_remote_sender_id()
	if sending_peer_id <= 0:
		sending_peer_id = 1

	var requested_team_id: String = String(command_dict.get("team_id", ""))
	if not _is_peer_allowed_for_team(sending_peer_id, requested_team_id):
		push_warning("SimulationRoot rejected a network command for an unauthorized team.")
		return

	enqueue_command(command_dict)


@rpc("authority", "unreliable")
func _receive_tick_state(state_dict: Dictionary) -> void:
	_last_server_state = state_dict.duplicate(true)
	_apply_remote_state(state_dict)


@rpc("authority", "reliable")
func _receive_vital_state_updates(vital_updates: Array) -> void:
	for vital_update in vital_updates:
		if typeof(vital_update) != TYPE_DICTIONARY:
			continue

		var unit = _resolve_known_unit(String(vital_update.get("unit_id", "")))
		if unit == null or not unit.has_method("apply_remote_vital_update"):
			continue

		unit.call("apply_remote_vital_update", vital_update)


# Commands are committed before effects on every authoritative physics tick.
func _physics_process(delta: float) -> void:
	if _should_skip_local_tick_processing():
		return

	tick_counter += 1
	is_processing_tick = true
	_begin_navigation_budget_tick()
	_prepare_local_avoidance_tick()

	var commands: Array = _drain_queue(command_queue)
	_process_commands(commands, delta)

	var effects: Array = _drain_queue(effects_queue)
	_process_effects(effects, delta)
	_update_objective_capture()

	_finish_navigation_budget_tick()
	is_processing_tick = false
	_broadcast_tick_state()
	tick_processed.emit(tick_counter)


func _should_skip_local_tick_processing() -> bool:
	if not is_server_authoritative:
		return false

	if not _has_active_multiplayer_peer():
		return false

	return not multiplayer.is_server()


func _has_active_multiplayer_peer() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null:
		return false

	return peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func _is_valid_network_command(command_dict: Dictionary) -> bool:
	var command = UNIT_COMMAND_SCRIPT.call("from_dict", command_dict)
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		return false

	var unit_id: String = String(command_dict.get("unit_id", ""))
	var team_id: String = String(command_dict.get("team_id", ""))
	if unit_id.is_empty() or team_id.is_empty():
		return false

	var unit = _resolve_known_unit(unit_id)
	if unit != null and unit.has_method("get_team_id"):
		return String(unit.call("get_team_id")) == team_id

	return true


func _is_peer_allowed_for_team(peer_id: int, team_id: String) -> bool:
	if team_id.is_empty():
		return false

	if not _has_active_multiplayer_peer():
		return peer_id == 1 and team_id == "team_alpha"

	return get_peer_team(peer_id) == team_id


func _broadcast_tick_state() -> void:
	if not is_server_authoritative or not _has_active_multiplayer_peer() or not multiplayer.is_server():
		return

	var state_dict: Dictionary = _build_tick_state()
	_receive_tick_state.rpc(state_dict)

	var vital_updates: Array = _build_vital_state_updates()
	if not vital_updates.is_empty():
		_receive_vital_state_updates.rpc(vital_updates)


func _build_tick_state() -> Dictionary:
	var state_dict: Dictionary = {
		"tick": tick_counter,
		"units": [],
	}
	for unit in _get_snapshot_units():
		var unit_snapshot: Dictionary = _build_unit_snapshot(unit)
		if unit_snapshot.is_empty():
			continue

		state_dict["units"].append(unit_snapshot)

	if _is_valid_objective_status(_objective_status):
		state_dict["objective"] = {
			"owning_team_id": _objective_status.owning_team_id,
			"capture_progress": _objective_status.capture_progress,
			"capturing_team_id": _objective_status.capturing_team_id,
			"contested": _objective_status.is_contested(),
		}

	return state_dict


func _build_vital_state_updates() -> Array:
	var updates: Array = []
	for unit in _get_snapshot_units():
		var vital_update: Dictionary = _build_unit_vital_update(unit)
		if vital_update.is_empty():
			continue

		var unit_id: String = String(vital_update.get("unit_id", ""))
		if unit_id.is_empty():
			continue

		var previous_update: Dictionary = _last_broadcast_vital_state_by_unit_id.get(unit_id, {})
		if previous_update == vital_update:
			continue

		_last_broadcast_vital_state_by_unit_id[unit_id] = vital_update.duplicate(true)
		updates.append(vital_update)

	return updates


func _get_snapshot_units() -> Array:
	var snapshot_units: Array = []
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		for unit in unit_registry.call("get_all_units"):
			if unit == null or not unit.has_method("get_unit_id"):
				continue

			snapshot_units.append(unit)
		return snapshot_units

	for unit in _known_units_by_id.values():
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		if unit is CanvasItem and not (unit as CanvasItem).visible:
			continue

		snapshot_units.append(unit)

	return snapshot_units


func _build_unit_snapshot(unit) -> Dictionary:
	if unit == null or not unit.has_method("get_unit_id"):
		return {}

	var unit_id: String = String(unit.call("get_unit_id"))
	if unit_id.is_empty():
		return {}

	var snapshot: Dictionary = {
		"unit_id": unit_id,
		"visible": true,
	}
	if unit is Node2D:
		snapshot["position"] = (unit as Node2D).global_position

	if unit is CanvasItem:
		snapshot["visible"] = bool((unit as CanvasItem).visible)

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			var runtime_dict: Dictionary = runtime_status.call("to_dict")
			snapshot["runtime_state"] = String(runtime_dict.get("status", ""))
			snapshot["fire_mode"] = String(runtime_dict.get("fire_status", ""))

	if unit.has_method("get_vital_status"):
		var vital_status = unit.call("get_vital_status")
		if vital_status != null and vital_status.has_method("to_dict"):
			var vital_dict: Dictionary = vital_status.call("to_dict")
			snapshot["vital_state"] = String(vital_dict.get("state", ""))
			snapshot["health"] = int(vital_dict.get("health_points", 0))
			snapshot["bleedout_ticks"] = int(vital_dict.get("bleedout_ticks", 0))

	if unit.has_method("get_tactical_stance_badge_snapshot"):
		var stance_snapshot_variant: Variant = unit.call("get_tactical_stance_badge_snapshot")
		if typeof(stance_snapshot_variant) == TYPE_DICTIONARY:
			snapshot.merge(Dictionary(stance_snapshot_variant), true)

	return snapshot


func _build_unit_vital_update(unit) -> Dictionary:
	if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_vital_status"):
		return {}

	var unit_id: String = String(unit.call("get_unit_id"))
	if unit_id.is_empty():
		return {}

	var vital_status = unit.call("get_vital_status")
	if vital_status == null or not vital_status.has_method("to_dict"):
		return {}

	return {
		"unit_id": unit_id,
		"vital_state": String(vital_status.state),
		"health": int(vital_status.health_points),
		"bleedout_ticks": int(vital_status.bleedout_ticks),
	}


func _apply_remote_state(state_dict: Dictionary) -> void:
	if typeof(state_dict) != TYPE_DICTIONARY:
		return

	var objective_dict: Variant = state_dict.get("objective", {})
	if typeof(objective_dict) == TYPE_DICTIONARY:
		_apply_remote_objective_state(objective_dict)

	var unit_snapshots: Variant = state_dict.get("units", [])
	if not (unit_snapshots is Array):
		return

	for unit_snapshot in unit_snapshots:
		if typeof(unit_snapshot) != TYPE_DICTIONARY:
			continue

		var unit = _resolve_known_unit(String(unit_snapshot.get("unit_id", "")))
		if unit == null:
			continue

		if unit.has_method("apply_remote_snapshot"):
			unit.call("apply_remote_snapshot", unit_snapshot)
			continue

		_apply_remote_snapshot_fallback(unit, unit_snapshot)


func _apply_remote_objective_state(objective_dict: Dictionary) -> void:
	if objective_dict.is_empty():
		return

	if not _is_valid_objective_status(_objective_status):
		_objective_status = OBJECTIVE_STATUS_SCRIPT.new()

	_objective_status.objective_id = String(objective_dict.get("objective_id", _objective_status.objective_id))
	_objective_status.position = _coerce_vector2(objective_dict.get("position", _objective_status.position), _objective_status.position)
	_objective_status.capture_radius = _extract_float(objective_dict.get("capture_radius", _objective_status.capture_radius), _objective_status.capture_radius)
	_objective_status.owning_team_id = String(objective_dict.get("owning_team_id", _objective_status.owning_team_id))
	_objective_status.capture_progress = clampf(_extract_float(objective_dict.get("capture_progress", _objective_status.capture_progress), _objective_status.capture_progress), 0.0, 1.0)
	_objective_status.capturing_team_id = String(objective_dict.get("capturing_team_id", _objective_status.capturing_team_id))
	_objective_status.set_contested(bool(objective_dict.get("contested", _objective_status.is_contested())))


func _apply_remote_snapshot_fallback(unit, unit_snapshot: Dictionary) -> void:
	if unit == null:
		return

	if unit is CanvasItem:
		(unit as CanvasItem).visible = bool(unit_snapshot.get("visible", true))

	if unit is Node2D:
		var target_position: Vector2 = _coerce_vector2(unit_snapshot.get("position", (unit as Node2D).global_position), (unit as Node2D).global_position)
		(unit as Node2D).global_position = (unit as Node2D).global_position.lerp(target_position, 0.75)


func _resolve_known_unit(unit_id: String):
	if unit_id.is_empty():
		return null

	var unit = _known_units_by_id.get(unit_id, null)
	if unit != null:
		return unit

	return _resolve_unit(unit_id)


func _process_commands(commands: Array, delta: float) -> void:
	var ordered_commands: Array = _order_payloads(commands)

	for cmd in ordered_commands:
		_apply_command(cmd, delta)


func _process_effects(effects: Array, delta: float) -> void:
	var ordered_effects: Array = _order_payloads(effects)

	for effect in ordered_effects:
		_apply_effect(effect, delta)


func _apply_command(cmd: Dictionary, delta: float) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary commands.")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying a command.")
		return

	match _extract_command_type(cmd):
		"move_to_position":
			_apply_move_command(cmd, delta)
		"engage_area":
			_apply_move_command(cmd, delta)
		_:
			# TODO: Authoritative gameplay state commits belong here once systems exist.
			pass


func _apply_effect(effect: Dictionary, delta: float) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary effects.")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying an effect.")
		return

	match _extract_effect_type(effect):
		"damage":
			_apply_damage_effect(effect)
		"heal":
			_apply_heal_effect(effect)
		"bleedout":
			_apply_bleedout_effect(effect)
		"respawn":
			_apply_respawn_effect(effect)
		"dropship_embark_unit":
			_apply_dropship_embark_unit_effect(effect)
		"dropship_deploy_unit":
			_apply_dropship_deploy_unit_effect(effect)
		"apply_loadout_modifiers":
			_apply_loadout_modifiers_effect(effect)
		_:
			# TODO: Deterministic effect commits belong here once systems exist.
			pass


func _drain_queue(queue: Array) -> Array:
	var drained: Array = queue.duplicate(false)
	queue.clear()
	return drained


func _order_payloads(payloads: Array) -> Array:
	var decorated: Array = []
	var index: int = 0

	for payload in payloads:
		if typeof(payload) != TYPE_DICTIONARY:
			push_warning("SimulationRoot expected queued payloads to be dictionaries.")
			index += 1
			continue

		decorated.append(
			{
				"index": index,
				"priority": _extract_priority(payload),
				"payload": payload,
			}
		)
		index += 1

	decorated.sort_custom(_sort_payload_entries)

	var ordered: Array = []
	for entry in decorated:
		ordered.append(entry["payload"])

	return ordered


func _extract_priority(payload: Dictionary) -> int:
	if not payload.has("priority"):
		return 0

	var priority: Variant = payload["priority"]
	if typeof(priority) == TYPE_INT or typeof(priority) == TYPE_FLOAT:
		return int(priority)

	push_warning("SimulationRoot expected payload priority to be numeric.")
	return 0


func _sort_payload_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = int(a["priority"])
	var b_priority: int = int(b["priority"])

	if a_priority == b_priority:
		return int(a["index"]) < int(b["index"])

	return a_priority > b_priority


func _extract_command_type(cmd: Dictionary) -> String:
	if cmd.has("command_type"):
		return String(cmd["command_type"])

	if cmd.has("type"):
		return String(cmd["type"])

	return ""


func _extract_effect_type(effect: Dictionary) -> String:
	if effect.has("effect_type"):
		return String(effect["effect_type"])

	return ""


func _apply_move_command(cmd: Dictionary, delta: float) -> void:
	var unit_id: String = String(cmd.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot move command expects a non-empty unit_id.")
		return

	var target_position: Variant = cmd.get("target_position", null)
	if typeof(target_position) != TYPE_VECTOR2:
		push_warning("SimulationRoot move command expects a Vector2 target_position.")
		return

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		push_warning("SimulationRoot requires a direct UnitRegistry reference for move commands.")
		return

	var unit = unit_registry.call("get_unit", unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a move command.")
		return

	if not (unit is Node2D):
		push_warning("SimulationRoot move command expects a Node2D-compatible unit.")
		return

	if _is_stale_tokenized_move_command(cmd, unit):
		return

	var movement_layer: String = _extract_movement_layer(cmd, unit)
	var altitude_band: int = _extract_altitude_band(cmd, unit)
	if unit.has_method("set_target_position"):
		unit.call("set_target_position", target_position, int(cmd.get("target_floor_index", 0)), movement_layer, altitude_band)

	var node_2d: Node2D = unit
	var move_speed_factor: float = _extract_move_speed_factor(cmd, unit)
	if move_speed_factor <= 0.0:
		return

	var terrain_registry = _get_terrain_registry()
	if movement_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR:
		_apply_air_move_command(cmd, node_2d, target_position, move_speed_factor, delta, terrain_registry, altitude_band)
		return

	if terrain_registry != null:
		_apply_move_command_with_terrain(cmd, node_2d, target_position, move_speed_factor, delta, terrain_registry)
		return

	var current_position: Vector2 = node_2d.position
	var direction: Vector2 = target_position - current_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * delta
	if direction.length() <= step_distance:
		node_2d.position = target_position
		if unit.has_method("refresh_terrain_readability"):
			unit.call("refresh_terrain_readability")
		_update_local_avoidance_agent_position(unit_id, node_2d.global_position)
		return

	if direction.is_zero_approx():
		return

	var desired_velocity: Vector2 = direction.normalized() * (step_distance / maxf(delta, 0.0001))
	var safe_velocity: Vector2 = _resolve_local_avoidance_velocity(cmd, node_2d, current_position, desired_velocity, desired_velocity.length(), delta, null)
	var displacement: Vector2 = safe_velocity * delta
	if displacement.length() > step_distance:
		displacement = displacement.normalized() * step_distance
	node_2d.position = current_position + displacement
	_update_local_avoidance_agent_position(unit_id, node_2d.global_position)
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")
	if bool(cmd.get("requeue_until_target", true)):
		enqueue_command(cmd.duplicate(true))


func _apply_air_move_command(
	cmd: Dictionary,
	unit_node: Node2D,
	target_position: Vector2,
	move_speed_factor: float,
	delta: float,
	terrain_registry,
	altitude_band: int
) -> void:
	var unit_id: String = String(cmd.get("unit_id", _extract_unit_id_for_path_recompute(unit_node)))
	var target_resolution: Dictionary = _resolve_air_move_target(target_position, terrain_registry)
	var resolved_target_position: Vector2 = Vector2(target_resolution.get("replacement_position", target_position))
	var current_position: Vector2 = unit_node.global_position
	var direction: Vector2 = resolved_target_position - current_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * delta
	if direction.length() <= step_distance:
		unit_node.global_position = resolved_target_position
	else:
		if direction.is_zero_approx():
			_record_air_move_debug(cmd, unit_id, current_position, resolved_target_position, target_resolution, altitude_band, true)
			return
		unit_node.global_position = current_position + direction.normalized() * step_distance

	_update_local_avoidance_agent_position(unit_id, unit_node.global_position)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")
	var reached_target: bool = unit_node.global_position.distance_to(resolved_target_position) <= 0.5
	_record_air_move_debug(cmd, unit_id, current_position, resolved_target_position, target_resolution, altitude_band, reached_target)
	if bool(cmd.get("requeue_until_target", true)) and not reached_target:
		var next_cmd: Dictionary = cmd.duplicate(true)
		next_cmd["target_position"] = resolved_target_position
		next_cmd["air_target_resolution"] = target_resolution.duplicate(true)
		enqueue_command(next_cmd)


func _resolve_air_move_target(target_position: Vector2, terrain_registry) -> Dictionary:
	if terrain_registry == null or not terrain_registry.has_method("get_all_tiles") or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("grid_to_world"):
		return {
			"original_position": target_position,
			"original_grid": null,
			"replacement_grid": null,
			"replacement_position": target_position,
			"clamped_to_bounds": false,
			"reason": "terrain_registry_missing",
		}

	var tiles: Array = Array(terrain_registry.call("get_all_tiles"))
	if tiles.is_empty():
		return {
			"original_position": target_position,
			"original_grid": null,
			"replacement_grid": null,
			"replacement_position": target_position,
			"clamped_to_bounds": false,
			"reason": "mission_bounds_missing",
		}

	var min_grid: Vector2i = Vector2i(2147483647, 2147483647)
	var max_grid: Vector2i = Vector2i(-2147483648, -2147483648)
	for tile_data in tiles:
		if tile_data == null:
			continue
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		min_grid.x = mini(min_grid.x, grid_position.x)
		min_grid.y = mini(min_grid.y, grid_position.y)
		max_grid.x = maxi(max_grid.x, grid_position.x)
		max_grid.y = maxi(max_grid.y, grid_position.y)

	var original_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var replacement_grid: Vector2i = Vector2i(
		clampi(original_grid.x, min_grid.x, max_grid.x),
		clampi(original_grid.y, min_grid.y, max_grid.y)
	)
	var clamped_to_bounds: bool = replacement_grid != original_grid
	return {
		"original_position": target_position,
		"original_grid": original_grid,
		"replacement_grid": replacement_grid,
		"replacement_position": terrain_registry.call("grid_to_world", replacement_grid) if clamped_to_bounds else target_position,
		"min_grid": min_grid,
		"max_grid": max_grid,
		"clamped_to_bounds": clamped_to_bounds,
		"reason": "clamped_to_mission_bounds" if clamped_to_bounds else "inside_mission_bounds",
	}


func _record_air_move_debug(
	cmd: Dictionary,
	unit_id: String,
	from_position: Vector2,
	target_position: Vector2,
	target_resolution: Dictionary,
	altitude_band: int,
	reached_target: bool
) -> void:
	if unit_id.strip_edges().is_empty():
		return
	_last_air_move_debug_by_unit_id[unit_id] = {
		"tick": tick_counter,
		"unit_id": unit_id,
		"command_type": String(cmd.get("command_type", cmd.get("type", ""))),
		"movement_layer": MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR,
		"altitude_band": altitude_band,
		"from_position": from_position,
		"target_position": target_position,
		"original_target_position": target_resolution.get("original_position", target_position),
		"original_target_grid": target_resolution.get("original_grid", null),
		"replacement_target_grid": target_resolution.get("replacement_grid", null),
		"clamped_to_bounds": bool(target_resolution.get("clamped_to_bounds", false)),
		"reason": String(target_resolution.get("reason", "")),
		"reached_target": reached_target,
	}


func _apply_move_command_with_terrain(
	cmd: Dictionary,
	unit_node: Node2D,
	target_position: Vector2,
	move_speed_factor: float,
	delta: float,
	terrain_registry
) -> void:
	var path_world_points: Array = _extract_or_build_path_world_points(cmd, unit_node, unit_node.global_position, target_position, terrain_registry)
	if path_world_points.is_empty():
		return

	if _is_local_avoidance_enabled_for_command(cmd):
		_apply_move_command_with_terrain_avoidance(cmd, unit_node, target_position, move_speed_factor, delta, terrain_registry, path_world_points)
		return

	var current_position: Vector2 = unit_node.global_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * _extract_surface_speed_factor(unit_node) * delta
	while step_distance > 0.0 and not path_world_points.is_empty():
		var next_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
		var direction_to_waypoint: Vector2 = next_waypoint - current_position
		if direction_to_waypoint.is_zero_approx():
			path_world_points.pop_front()
			continue

		var distance_to_waypoint: float = direction_to_waypoint.length()
		if distance_to_waypoint <= step_distance:
			current_position = next_waypoint
			step_distance -= distance_to_waypoint
			path_world_points.pop_front()
			continue

		current_position += direction_to_waypoint.normalized() * step_distance
		step_distance = 0.0

	unit_node.global_position = current_position
	_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(target_position) > 0.5):
		enqueue_command(cmd.duplicate(true))


func _apply_move_command_with_terrain_avoidance(
	cmd: Dictionary,
	unit_node: Node2D,
	target_position: Vector2,
	move_speed_factor: float,
	delta: float,
	terrain_registry,
	path_world_points: Array
) -> void:
	var current_position: Vector2 = unit_node.global_position
	while not path_world_points.is_empty():
		var first_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
		if current_position.distance_to(first_waypoint) > 0.001:
			break
		path_world_points.pop_front()

	if path_world_points.is_empty():
		unit_node.global_position = current_position
		cmd["path"] = []
		_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
		if unit_node.has_method("refresh_terrain_readability"):
			unit_node.call("refresh_terrain_readability")
		return

	var next_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
	var direction_to_waypoint: Vector2 = next_waypoint - current_position
	if direction_to_waypoint.is_zero_approx():
		cmd["path"] = path_world_points.duplicate(true)
		return

	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * _extract_surface_speed_factor(unit_node) * delta
	var distance_to_waypoint: float = direction_to_waypoint.length()
	var desired_step_distance: float = minf(step_distance, distance_to_waypoint)
	var desired_velocity: Vector2 = direction_to_waypoint.normalized() * (desired_step_distance / maxf(delta, 0.0001))
	var safe_velocity: Vector2 = _resolve_local_avoidance_velocity(cmd, unit_node, current_position, desired_velocity, step_distance / maxf(delta, 0.0001), delta, terrain_registry)
	var displacement: Vector2 = safe_velocity * delta
	if displacement.length() > desired_step_distance:
		displacement = displacement.normalized() * desired_step_distance
	current_position += displacement
	if current_position.distance_to(next_waypoint) <= 0.5:
		current_position = next_waypoint
		path_world_points.pop_front()

	unit_node.global_position = current_position
	_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(target_position) > 0.5):
		enqueue_command(cmd.duplicate(true))


func _is_stale_tokenized_move_command(cmd: Dictionary, unit) -> bool:
	var command_token: String = String(cmd.get("command_token", "")).strip_edges()
	if command_token.is_empty():
		return false
	if unit == null or not unit.has_method("get_current_unit_command"):
		return false
	var current_command = unit.call("get_current_unit_command")
	if current_command == null:
		return true
	var current_token: String = ""
	if typeof(current_command) == TYPE_DICTIONARY:
		current_token = String(Dictionary(current_command).get("command_token", "")).strip_edges()
	elif current_command is Object:
		current_token = String(current_command.get("command_token")).strip_edges()
	return current_token != command_token


func _extract_or_build_path_world_points(
	cmd: Dictionary,
	unit,
	current_position: Vector2,
	target_position: Vector2,
	terrain_registry
) -> Array:
	var existing_path: Array = []
	var raw_path: Variant = cmd.get("path", [])
	if raw_path is Array:
		existing_path = (raw_path as Array).duplicate(true)

	if _should_recompute_move_path(cmd, unit, existing_path, current_position, target_position, terrain_registry):
		existing_path.clear()
		cmd["path"] = []

	if not existing_path.is_empty():
		return existing_path

	if not _try_begin_navigation_path_request(cmd, unit, current_position, target_position):
		return []

	var path_world_points: Array = _build_path_world_points(current_position, target_position, terrain_registry, cmd, unit)
	cmd["path"] = path_world_points.duplicate(true)
	if terrain_move_debug_enabled:
		_record_terrain_move_debug(cmd, unit, current_position, target_position, terrain_registry, path_world_points)
	return path_world_points


func _should_recompute_move_path(
	cmd: Dictionary,
	unit,
	existing_path: Array,
	current_position: Vector2,
	target_position: Vector2,
	terrain_registry
) -> bool:
	if terrain_registry == null or unit == null:
		return false

	var unit_id: String = _extract_unit_id_for_path_recompute(unit)
	if unit_id.is_empty():
		return false

	if not bool(cmd.get("requeue_until_target", true)) or not _is_unit_in_contact(unit):
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return false

	if existing_path.is_empty():
		return false

	var target_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var current_final_waypoint: Vector2 = _coerce_vector2(existing_path[-1], target_position)
	var current_final_grid: Vector2i = terrain_registry.call("world_to_grid", current_final_waypoint)
	if current_final_grid != target_grid:
		_contact_path_recompute_ready_at_msec[unit_id] = Time.get_ticks_msec() + CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC
		return true

	var current_grid: Vector2i = terrain_registry.call("world_to_grid", current_position)
	if current_grid == target_grid:
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return false

	var now_msec: int = Time.get_ticks_msec()
	if int(_contact_path_recompute_ready_at_msec.get(unit_id, 0)) > now_msec:
		return false

	_contact_path_recompute_ready_at_msec[unit_id] = now_msec + CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC
	return true


func _begin_navigation_budget_tick() -> void:
	_navigation_new_path_queries_this_tick = 0
	_navigation_path_queries_this_tick = 0
	_navigation_delayed_this_tick = 0
	_navigation_fallback_queries_this_tick = 0
	_navigation_unreachable_queries_this_tick = 0
	_navigation_last_delay_reason = ""
	_navigation_last_tick_queries.clear()
	_navigation_last_path_metrics.clear()


func _finish_navigation_budget_tick() -> void:
	if _navigation_last_tick_queries.size() > navigation_debug_query_history_limit:
		_navigation_last_tick_queries = _navigation_last_tick_queries.slice(_navigation_last_tick_queries.size() - navigation_debug_query_history_limit)


func _try_begin_navigation_path_request(cmd: Dictionary, unit, current_position: Vector2, target_position: Vector2) -> bool:
	var max_queries: int = maxi(0, navigation_max_new_path_queries_per_tick)
	if navigation_budget_enabled and is_processing_tick and _navigation_new_path_queries_this_tick >= max_queries:
		_delay_navigation_path_request(cmd, unit, current_position, target_position, "budget_exhausted")
		return false

	_navigation_new_path_queries_this_tick += 1
	cmd.erase("navigation_pending_reason")
	cmd.erase("navigation_pending_since_tick")
	return true


func _delay_navigation_path_request(cmd: Dictionary, unit, current_position: Vector2, target_position: Vector2, reason: String) -> void:
	_navigation_delayed_this_tick += 1
	_navigation_last_delay_reason = reason
	var delayed_cmd: Dictionary = cmd.duplicate(true)
	delayed_cmd["path"] = []
	delayed_cmd["navigation_pending_reason"] = reason
	delayed_cmd["navigation_pending_since_tick"] = tick_counter
	delayed_cmd["navigation_delay_count"] = int(cmd.get("navigation_delay_count", 0)) + 1
	enqueue_command(delayed_cmd)

	var record: Dictionary = _make_navigation_record(cmd, unit, Vector2i.ZERO, Vector2i.ZERO, {}, 0, "delayed", reason, 0)
	record["current_position"] = current_position
	record["target_position"] = target_position
	record["delayed"] = true
	_append_navigation_debug_record(record)


func _record_navigation_path_query(
	cmd: Dictionary,
	unit,
	from_grid: Vector2i,
	to_grid: Vector2i,
	query_result: Dictionary,
	duration_usec: int,
	query_kind: String,
	reason: String,
	candidate_count: int
) -> void:
	_navigation_path_queries_this_tick += 1
	if query_kind == "fallback":
		_navigation_fallback_queries_this_tick += 1
	var record: Dictionary = _make_navigation_record(cmd, unit, from_grid, to_grid, query_result, duration_usec, query_kind, reason, candidate_count)
	if bool(record.get("unreachable", false)):
		_navigation_unreachable_queries_this_tick += 1
	_append_navigation_debug_record(record)


func _make_navigation_record(
	cmd: Dictionary,
	unit,
	from_grid: Vector2i,
	to_grid: Vector2i,
	query_result: Dictionary,
	duration_usec: int,
	query_kind: String,
	reason: String,
	candidate_count: int
) -> Dictionary:
	var path: Array = Array(query_result.get("path", []))
	var status: String = String(query_result.get("status", ""))
	var unit_id: String = _extract_unit_id_for_path_recompute(unit)
	if unit_id.is_empty():
		unit_id = String(cmd.get("unit_id", ""))
	var route_type: String = "none"
	if status == "direct_a_star":
		route_type = "direct_a_star"
	elif status == HPA_PATHFINDER_SCRIPT.STATUS_HPA or status == HPA_PATHFINDER_SCRIPT.STATUS_SAME_COMPONENT:
		route_type = "hpa"
	elif query_kind == "delayed":
		route_type = "delayed"
	var unreachable: bool = path.is_empty() and (
		status == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE
		or status == HPA_PATHFINDER_SCRIPT.STATUS_NO_COMPONENT
		or status == HPA_PATHFINDER_SCRIPT.STATUS_LOCAL_PATH_FAILED
		or status == HPA_PATHFINDER_SCRIPT.STATUS_INVALID
	)
	return {
		"tick": tick_counter,
		"unit_id": unit_id,
		"command_type": String(cmd.get("command_type", cmd.get("type", ""))),
		"priority": _extract_priority(cmd),
		"query_kind": query_kind,
		"route_type": route_type,
		"status": status,
		"from_grid": from_grid,
		"to_grid": to_grid,
		"duration_usec": duration_usec,
		"path_grid_count": path.size(),
		"path_length_grid": int(query_result.get("path_length_grid", path.size())),
		"exposure_sum": float(query_result.get("exposure_sum", 0.0)),
		"cover_sum": float(query_result.get("cover_sum", 0.0)),
		"mean_exposure": float(query_result.get("mean_exposure", 0.0)),
		"mean_cover": float(query_result.get("mean_cover", 0.0)),
		"path_cost": float(query_result.get("path_cost", 0.0)),
		"candidate_count_estimate": candidate_count,
		"expanded_node_estimate": maxi(candidate_count, path.size()),
		"fallback_or_delay_reason": reason,
		"unreachable": unreachable,
	}


func _append_navigation_debug_record(record: Dictionary) -> void:
	if not navigation_debug_enabled:
		return
	_navigation_last_tick_queries.append(record)
	if _navigation_last_tick_queries.size() > navigation_debug_query_history_limit:
		_navigation_last_tick_queries.pop_front()
	var duration_usec: int = int(record.get("duration_usec", 0))
	if _navigation_most_expensive_query.is_empty() or duration_usec > int(_navigation_most_expensive_query.get("duration_usec", -1)):
		_navigation_most_expensive_query = record.duplicate(true)
	if String(record.get("query_kind", "")) != "delayed":
		_navigation_last_path_metrics = {
			"unit_id": String(record.get("unit_id", "")),
			"query_kind": String(record.get("query_kind", "")),
			"route_type": String(record.get("route_type", "")),
			"status": String(record.get("status", "")),
			"path_length_grid": int(record.get("path_length_grid", 0)),
			"exposure_sum": float(record.get("exposure_sum", 0.0)),
			"cover_sum": float(record.get("cover_sum", 0.0)),
			"mean_exposure": float(record.get("mean_exposure", 0.0)),
			"mean_cover": float(record.get("mean_cover", 0.0)),
			"path_cost": float(record.get("path_cost", 0.0)),
		}


func _count_pending_navigation_queries() -> int:
	var pending_count: int = 0
	for queued_command in command_queue:
		if typeof(queued_command) != TYPE_DICTIONARY:
			continue
		if not String(Dictionary(queued_command).get("navigation_pending_reason", "")).strip_edges().is_empty():
			pending_count += 1
	return pending_count


func _duplicate_dictionary_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append(Dictionary(value).duplicate(true))
	return result


func _prepare_local_avoidance_tick() -> void:
	if not local_avoidance_enabled:
		_local_avoidance_prepared_tick = -1
		return
	if _local_avoidance_prepared_tick == tick_counter:
		return
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		_local_avoidance_resolver.clear()
		_local_avoidance_prepared_tick = tick_counter
		return
	_local_avoidance_resolver.call(
		"build_from_units",
		Array(unit_registry.call("get_all_units")),
		local_avoidance_agent_radius,
		local_avoidance_spatial_cell_size
	)
	_local_avoidance_prepared_tick = tick_counter


func _is_local_avoidance_enabled_for_command(cmd: Dictionary) -> bool:
	if cmd.has("local_avoidance_enabled"):
		return bool(cmd.get("local_avoidance_enabled", false))
	return local_avoidance_enabled


func _resolve_local_avoidance_velocity(
	cmd: Dictionary,
	unit_node: Node2D,
	current_position: Vector2,
	desired_velocity: Vector2,
	max_speed: float,
	delta: float,
	terrain_registry
) -> Vector2:
	if unit_node == null or not _is_local_avoidance_enabled_for_command(cmd) or desired_velocity.is_zero_approx():
		return desired_velocity
	_prepare_local_avoidance_tick()
	var unit_id: String = _extract_unit_id_for_path_recompute(unit_node)
	var started_usec: int = Time.get_ticks_usec()
	var result: Dictionary = Dictionary(_local_avoidance_resolver.call(
		"solve_velocity",
		unit_id,
		current_position,
		desired_velocity,
		max_speed,
		local_avoidance_neighbor_radius,
		local_avoidance_max_neighbors
	))
	var safe_velocity: Vector2 = Vector2(result.get("safe_velocity", desired_velocity))
	var discarded_correction: bool = false
	var discard_reason: String = ""
	if terrain_registry != null:
		var candidate_position: Vector2 = current_position + safe_velocity * delta
		if not _is_local_avoidance_position_walkable(candidate_position, terrain_registry):
			var desired_position: Vector2 = current_position + desired_velocity * delta
			discarded_correction = true
			discard_reason = "non_walkable_correction"
			if _is_local_avoidance_position_walkable(desired_position, terrain_registry):
				safe_velocity = desired_velocity
			else:
				safe_velocity = Vector2.ZERO
				discard_reason = "non_walkable_desired"
	result["safe_velocity"] = safe_velocity
	result["correction_velocity"] = safe_velocity - desired_velocity
	result["discarded_correction"] = discarded_correction
	result["discard_reason"] = discard_reason
	result["duration_usec"] = Time.get_ticks_usec() - started_usec
	_record_local_avoidance_debug(cmd, unit_id, result, delta)
	return safe_velocity


func _is_local_avoidance_position_walkable(position: Vector2, terrain_registry) -> bool:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("is_walkable"):
		return true
	return bool(terrain_registry.call("is_walkable", terrain_registry.call("world_to_grid", position)))


func _update_local_avoidance_agent_position(unit_id: String, position: Vector2) -> void:
	if unit_id.strip_edges().is_empty() or not local_avoidance_enabled:
		return
	if _local_avoidance_prepared_tick != tick_counter:
		return
	_local_avoidance_resolver.call("update_agent_position", unit_id, position)


func _record_local_avoidance_debug(cmd: Dictionary, unit_id: String, result: Dictionary, delta: float) -> void:
	var desired_velocity: Vector2 = Vector2(result.get("desired_velocity", Vector2.ZERO))
	var safe_velocity: Vector2 = Vector2(result.get("safe_velocity", desired_velocity))
	var desired_speed: float = desired_velocity.length()
	var safe_speed: float = safe_velocity.length()
	var stuck_seconds: float = float(_local_avoidance_stuck_seconds_by_unit_id.get(unit_id, 0.0))
	if desired_speed > local_avoidance_stuck_speed_threshold and safe_speed <= local_avoidance_stuck_speed_threshold:
		stuck_seconds += delta
	else:
		stuck_seconds = maxf(stuck_seconds - delta, 0.0)
	_local_avoidance_stuck_seconds_by_unit_id[unit_id] = stuck_seconds
	var deadlock_marked: bool = stuck_seconds >= local_avoidance_stuck_threshold_seconds
	if deadlock_marked:
		cmd["local_avoidance_deadlock"] = true
		cmd["local_avoidance_repath_requested"] = true
	if not local_avoidance_debug_enabled:
		return
	var neighbors: Array = Array(result.get("neighbors", []))
	var neighbor_ids: Array = []
	for neighbor_variant in neighbors:
		neighbor_ids.append(String(Dictionary(neighbor_variant).get("unit_id", "")))
	_local_avoidance_debug_by_unit_id[unit_id] = {
		"tick": tick_counter,
		"unit_id": unit_id,
		"neighbor_count": int(result.get("neighbor_count", 0)),
		"neighbor_ids": neighbor_ids,
		"collision_risk_count": int(result.get("collision_risk_count", 0)),
		"desired_velocity": desired_velocity,
		"avoidance_velocity": safe_velocity,
		"correction_velocity": Vector2(result.get("correction_velocity", Vector2.ZERO)),
		"stuck_time_seconds": stuck_seconds,
		"deadlock_marked": deadlock_marked,
		"discarded_correction": bool(result.get("discarded_correction", false)),
		"discard_reason": String(result.get("discard_reason", "")),
		"duration_usec": int(result.get("duration_usec", 0)),
	}


func _extract_unit_id_for_path_recompute(unit) -> String:
	if unit == null or not unit.has_method("get_unit_id"):
		return ""

	return String(unit.call("get_unit_id"))


func _extract_movement_layer(cmd: Dictionary, unit = null) -> String:
	if cmd.has("movement_layer"):
		return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(cmd.get("movement_layer", "")))
	if unit != null and unit.has_method("get_movement_layer"):
		return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(unit.call("get_movement_layer")))
	return MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND


func _extract_altitude_band(cmd: Dictionary, unit = null) -> int:
	if cmd.has("altitude_band"):
		return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(cmd.get("altitude_band"))
	if unit != null and unit.has_method("get_altitude_band"):
		return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(unit.call("get_altitude_band"))
	return MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND


func _is_unit_in_contact(unit) -> bool:
	return unit != null and unit.has_method("is_in_contact") and bool(unit.call("is_in_contact"))


func _build_path_world_points(current_position: Vector2, target_position: Vector2, terrain_registry, cmd: Dictionary = {}, unit = null) -> Array:
	var path_world_points: Array = []
	if terrain_registry == null or _terrain_pathfinder == null:
		path_world_points.append(target_position)
		return path_world_points

	var from_grid: Vector2i = terrain_registry.call("world_to_grid", current_position)
	var target_resolution: Dictionary = _resolve_walkable_move_target(target_position, terrain_registry)
	var raw_replacement_grid: Variant = target_resolution.get("replacement_grid", terrain_registry.call("world_to_grid", target_position))
	var to_grid: Vector2i = raw_replacement_grid if typeof(raw_replacement_grid) == TYPE_VECTOR2I else terrain_registry.call("world_to_grid", target_position)
	var target_grid_was_walkable: bool = bool(target_resolution.get("target_walkable", true))
	var resolved_target_position: Vector2 = Vector2(target_resolution.get("replacement_position", target_position))
	if terrain_registry.has_method("is_walkable") and not bool(terrain_registry.call("is_walkable", from_grid)):
		var nearest_start_grid: Variant = terrain_registry.call("get_nearest_walkable_grid", current_position) if terrain_registry.has_method("get_nearest_walkable_grid") else null
		if typeof(nearest_start_grid) == TYPE_VECTOR2I:
			from_grid = nearest_start_grid

	var navigation_options: Dictionary = _build_navigation_cost_options(cmd, terrain_registry)
	var navigation_started_usec: int = Time.get_ticks_usec()
	var navigation_query: Dictionary = _find_navigation_grid_path(from_grid, to_grid, terrain_registry, navigation_options)
	var navigation_duration_usec: int = Time.get_ticks_usec() - navigation_started_usec
	var path_grid_points: Array = Array(navigation_query.get("path", []))
	var navigation_status: String = String(navigation_query.get("status", ""))
	_annotate_navigation_query_metrics(navigation_query, path_grid_points, terrain_registry, navigation_options)
	_record_navigation_path_query(cmd, unit, from_grid, to_grid, navigation_query, navigation_duration_usec, "primary", "", path_grid_points.size())
	path_grid_points = _simplify_grid_path_turns(path_grid_points)
	if path_grid_points.is_empty():
		if from_grid == to_grid:
			path_world_points.append(resolved_target_position)
			return path_world_points

		var reachable_grid: Variant = _find_hpa_reachable_walkable_grid(from_grid, to_grid, terrain_registry) if navigation_status == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE else _find_nearest_reachable_walkable_grid(from_grid, to_grid, terrain_registry)
		if typeof(reachable_grid) != TYPE_VECTOR2I:
			return path_world_points
		var fallback_started_usec: int = Time.get_ticks_usec()
		var fallback_query: Dictionary = _find_navigation_grid_path(from_grid, reachable_grid, terrain_registry, navigation_options)
		var fallback_duration_usec: int = Time.get_ticks_usec() - fallback_started_usec
		var fallback_path_grid_points: Array = Array(fallback_query.get("path", []))
		_annotate_navigation_query_metrics(fallback_query, fallback_path_grid_points, terrain_registry, navigation_options)
		_record_navigation_path_query(cmd, unit, from_grid, reachable_grid, fallback_query, fallback_duration_usec, "fallback", navigation_status, fallback_path_grid_points.size())
		fallback_path_grid_points = _simplify_grid_path_turns(fallback_path_grid_points)
		if fallback_path_grid_points.is_empty() and reachable_grid != from_grid:
			return path_world_points
		for fallback_index in range(1, fallback_path_grid_points.size()):
			path_world_points.append(terrain_registry.call("grid_to_world", fallback_path_grid_points[fallback_index]))
		if path_world_points.is_empty():
			path_world_points.append(terrain_registry.call("grid_to_world", reachable_grid))
		return path_world_points

	for index in range(1, path_grid_points.size()):
		path_world_points.append(terrain_registry.call("grid_to_world", path_grid_points[index]))

	if target_grid_was_walkable and (path_world_points.is_empty() or _coerce_vector2(path_world_points[-1], target_position).distance_to(target_position) > 0.5):
		path_world_points.append(target_position)

	return path_world_points


func _simplify_grid_path_turns(path_grid_points: Array) -> Array:
	if path_grid_points.size() <= 2:
		return path_grid_points.duplicate()
	var simplified: Array = [Vector2i(path_grid_points[0]), Vector2i(path_grid_points[1])]
	var previous_direction: Vector2i = _grid_step_direction(Vector2i(path_grid_points[0]), Vector2i(path_grid_points[1]))
	for index in range(2, path_grid_points.size()):
		var current_direction: Vector2i = _grid_step_direction(Vector2i(path_grid_points[index - 1]), Vector2i(path_grid_points[index]))
		if current_direction != previous_direction:
			simplified.append(Vector2i(path_grid_points[index - 1]))
		previous_direction = current_direction
	simplified.append(Vector2i(path_grid_points[-1]))
	return simplified


func _grid_step_direction(from_grid: Vector2i, to_grid: Vector2i) -> Vector2i:
	var delta: Vector2i = to_grid - from_grid
	var direction_x: int = 0
	var direction_y: int = 0
	if delta.x > 0:
		direction_x = 1
	elif delta.x < 0:
		direction_x = -1
	if delta.y > 0:
		direction_y = 1
	elif delta.y < 0:
		direction_y = -1
	return Vector2i(direction_x, direction_y)


func _build_navigation_cost_options(cmd: Dictionary, terrain_registry) -> Dictionary:
	var cover_aware_enabled: bool = navigation_cover_aware_enabled
	if cmd.has("navigation_cover_aware"):
		cover_aware_enabled = bool(cmd.get("navigation_cover_aware", false))
	elif cmd.has("cover_aware_navigation"):
		cover_aware_enabled = bool(cmd.get("cover_aware_navigation", false))

	var weights: Dictionary = _get_navigation_cost_weights_for_command(cmd)
	if cmd.has("navigation_exposure_weight"):
		weights["exposure_weight"] = maxf(float(cmd.get("navigation_exposure_weight", 0.0)), 0.0)
	if cmd.has("navigation_cover_weight"):
		weights["cover_weight"] = maxf(float(cmd.get("navigation_cover_weight", 0.0)), 0.0)

	return {
		"cover_aware_enabled": cover_aware_enabled,
		"exposure_weight": float(weights.get("exposure_weight", navigation_default_exposure_weight)),
		"cover_weight": float(weights.get("cover_weight", navigation_default_cover_weight)),
		"exposure_max_grid_distance": float(cmd.get("navigation_exposure_max_grid_distance", navigation_exposure_max_grid_distance)),
		"hazard_grids": _extract_navigation_hazard_grids(cmd, terrain_registry),
	}


func _get_navigation_cost_weights_for_command(cmd: Dictionary) -> Dictionary:
	var source_command_type: String = String(cmd.get("source_command_type", cmd.get("origin_command_type", ""))).strip_edges().to_lower()
	if source_command_type.is_empty():
		var command_type: String = String(cmd.get("command_type", cmd.get("type", ""))).strip_edges().to_lower()
		match command_type:
			"engage_area":
				source_command_type = "engage"
			"move_to_position":
				source_command_type = "move"
			_:
				source_command_type = command_type
	match source_command_type:
		"defend":
			return {"exposure_weight": 0.9, "cover_weight": 0.75}
		"take", "engage":
			return {"exposure_weight": 1.1, "cover_weight": 0.45}
		"flank":
			return {"exposure_weight": 1.2, "cover_weight": 0.3}
		"rush":
			return {"exposure_weight": 0.15, "cover_weight": 0.05}
		_:
			return {"exposure_weight": navigation_default_exposure_weight, "cover_weight": navigation_default_cover_weight}


func _extract_navigation_hazard_grids(cmd: Dictionary, terrain_registry) -> Array:
	var hazard_grids: Array = []
	for key in ["navigation_threat_grids", "threat_grids", "danger_grids"]:
		for grid_variant in Array(cmd.get(key, [])):
			_append_unique_navigation_hazard_grid(hazard_grids, Vector2i(grid_variant))
	if terrain_registry != null and terrain_registry.has_method("world_to_grid"):
		for key in ["navigation_threat_positions", "threat_positions", "danger_positions", "enemy_positions"]:
			for position_variant in Array(cmd.get(key, [])):
				if typeof(position_variant) != TYPE_VECTOR2:
					continue
				_append_unique_navigation_hazard_grid(hazard_grids, terrain_registry.call("world_to_grid", Vector2(position_variant)))
	hazard_grids.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a)
		var grid_b: Vector2i = Vector2i(b)
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	return hazard_grids


func _append_unique_navigation_hazard_grid(hazard_grids: Array, grid_position: Vector2i) -> void:
	if not hazard_grids.has(grid_position):
		hazard_grids.append(grid_position)


func _annotate_navigation_query_metrics(query: Dictionary, path_grid_points: Array, terrain_registry, navigation_options: Dictionary) -> void:
	var path_metrics: Dictionary = Dictionary(_terrain_pathfinder.call("score_path", path_grid_points, terrain_registry, navigation_options))
	for key in path_metrics.keys():
		query[key] = path_metrics[key]


func _find_navigation_grid_path(from_grid: Vector2i, to_grid: Vector2i, terrain_registry, navigation_options: Dictionary = {}) -> Dictionary:
	var graph = _ensure_hpa_navigation_graph(terrain_registry)
	if graph != null and _hpa_pathfinder != null:
		var hpa_query: Dictionary = Dictionary(_hpa_pathfinder.call("find_path_with_status", from_grid, to_grid, terrain_registry, graph, navigation_options))
		var hpa_status: String = String(hpa_query.get("status", ""))
		if not Array(hpa_query.get("path", [])).is_empty():
			return hpa_query
		if hpa_status == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE or hpa_status == HPA_PATHFINDER_SCRIPT.STATUS_NO_COMPONENT:
			return hpa_query

	return {
		"path": _terrain_pathfinder.call("find_path_with_options", from_grid, to_grid, terrain_registry, navigation_options),
		"status": "direct_a_star",
	}


func _ensure_hpa_navigation_graph(terrain_registry):
	if terrain_registry == null or not terrain_registry.has_method("get_all_tiles"):
		return null
	var tile_count: int = Array(terrain_registry.call("get_all_tiles")).size()
	if _hpa_navigation_graph != null and _hpa_navigation_registry == terrain_registry and _hpa_navigation_tile_count == tile_count:
		return _hpa_navigation_graph
	_hpa_navigation_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	if not bool(_hpa_navigation_graph.call("build_from_registry", terrain_registry, HPA_NAVIGATION_CLUSTER_SIZE)):
		_hpa_navigation_graph = null
		_hpa_navigation_registry = null
		_hpa_navigation_tile_count = -1
		return null
	_hpa_navigation_registry = terrain_registry
	_hpa_navigation_tile_count = tile_count
	return _hpa_navigation_graph


func _resolve_walkable_move_target(target_position: Vector2, terrain_registry) -> Dictionary:
	if terrain_registry != null and terrain_registry.has_method("resolve_walkable_target"):
		return Dictionary(terrain_registry.call("resolve_walkable_target", target_position)).duplicate(true)
	var to_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var target_walkable: bool = bool(terrain_registry.call("is_walkable", to_grid)) if terrain_registry != null and terrain_registry.has_method("is_walkable") else true
	if target_walkable:
		return {
			"original_position": target_position,
			"original_grid": to_grid,
			"target_walkable": true,
			"replacement_grid": to_grid,
			"replacement_position": target_position,
			"blocked_grid": null,
			"blocked_position": null,
			"blocker_reason": "",
		}
	var nearest_target_grid: Variant = terrain_registry.call("get_nearest_walkable_grid", target_position) if terrain_registry != null and terrain_registry.has_method("get_nearest_walkable_grid") else to_grid
	return {
		"original_position": target_position,
		"original_grid": to_grid,
		"target_walkable": false,
		"replacement_grid": nearest_target_grid,
		"replacement_position": terrain_registry.call("grid_to_world", nearest_target_grid) if typeof(nearest_target_grid) == TYPE_VECTOR2I and terrain_registry.has_method("grid_to_world") else target_position,
		"blocked_grid": to_grid,
		"blocked_position": target_position,
		"blocker_reason": "target_not_walkable",
	}


func _find_hpa_reachable_walkable_grid(from_grid: Vector2i, desired_grid: Vector2i, terrain_registry) -> Variant:
	var graph = _ensure_hpa_navigation_graph(terrain_registry)
	if graph == null:
		return null
	var component_key: String = String(graph.call("get_component_key_for_grid", from_grid))
	if component_key.is_empty():
		return null
	var candidates: Array = Array(graph.call("get_component_tiles", component_key))
	candidates.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a)
		var grid_b: Vector2i = Vector2i(b)
		var distance_a: float = _grid_distance_score(grid_a, desired_grid)
		var distance_b: float = _grid_distance_score(grid_b, desired_grid)
		if absf(distance_a - distance_b) > 0.001:
			return distance_a < distance_b
		var source_distance_a: float = _grid_distance_score(grid_a, from_grid)
		var source_distance_b: float = _grid_distance_score(grid_b, from_grid)
		if absf(source_distance_a - source_distance_b) > 0.001:
			return source_distance_a < source_distance_b
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	return null if candidates.is_empty() else Vector2i(candidates[0])


func _find_nearest_reachable_walkable_grid(from_grid: Vector2i, desired_grid: Vector2i, terrain_registry) -> Variant:
	if terrain_registry == null or not terrain_registry.has_method("get_all_tiles"):
		return null
	var candidates: Array = []
	for tile_data in Array(terrain_registry.call("get_all_tiles")):
		if tile_data == null or not bool(tile_data.walkable):
			continue
		candidates.append(tile_data)
	candidates.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a.grid_position)
		var grid_b: Vector2i = Vector2i(b.grid_position)
		var distance_a: float = _grid_distance_score(grid_a, desired_grid)
		var distance_b: float = _grid_distance_score(grid_b, desired_grid)
		if absf(distance_a - distance_b) > 0.001:
			return distance_a < distance_b
		var source_distance_a: float = _grid_distance_score(grid_a, from_grid)
		var source_distance_b: float = _grid_distance_score(grid_b, from_grid)
		if absf(source_distance_a - source_distance_b) > 0.001:
			return source_distance_a < source_distance_b
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	for tile_data in candidates:
		var candidate_grid: Vector2i = Vector2i(tile_data.grid_position)
		if candidate_grid == from_grid:
			return candidate_grid
		if not _terrain_pathfinder.find_path(from_grid, candidate_grid, terrain_registry).is_empty():
			return candidate_grid
	return null


func _grid_distance_score(a: Vector2i, b: Vector2i) -> float:
	return absf(float(a.x - b.x)) + absf(float(a.y - b.y))


func _record_terrain_move_debug(cmd: Dictionary, unit, current_position: Vector2, target_position: Vector2, terrain_registry, path_world_points: Array) -> void:
	var unit_id: String = _extract_unit_id_for_path_recompute(unit)
	if unit_id.is_empty() or terrain_registry == null:
		return
	var target_resolution: Dictionary = _resolve_walkable_move_target(target_position, terrain_registry)
	var replacement_position: Vector2 = Vector2(target_resolution.get("replacement_position", target_position))
	var final_position: Vector2 = _coerce_vector2(path_world_points[-1], replacement_position) if not path_world_points.is_empty() else current_position
	var original_grid: Vector2i = Vector2i(target_resolution.get("original_grid", terrain_registry.call("world_to_grid", target_position)))
	var replacement_grid: Variant = target_resolution.get("replacement_grid", null)
	var final_grid: Vector2i = terrain_registry.call("world_to_grid", final_position) if terrain_registry.has_method("world_to_grid") else Vector2i.ZERO
	var path_blocked: bool = not bool(target_resolution.get("target_walkable", true)) or (typeof(replacement_grid) == TYPE_VECTOR2I and final_grid != Vector2i(replacement_grid))
	var reason: String = String(target_resolution.get("blocker_reason", ""))
	if reason.is_empty() and path_blocked:
		reason = "no_reachable_path"
	_last_terrain_move_debug_by_unit_id[unit_id] = {
		"unit_id": unit_id,
		"command_type": String(cmd.get("command_type", "")),
		"original_target_position": target_position,
		"original_target_grid": original_grid,
		"target_walkable": bool(target_resolution.get("target_walkable", true)),
		"blocked_target_grid": target_resolution.get("blocked_grid", null),
		"blocked_target_position": target_resolution.get("blocked_position", null),
		"replacement_target_grid": replacement_grid,
		"replacement_target_position": replacement_position,
		"final_waypoint_position": final_position,
		"final_waypoint_grid": final_grid,
		"blocker_reason": reason,
		"path_waypoint_count": path_world_points.size(),
	}


func _apply_damage_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot damage effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a damage effect.")
		return

	if not unit.has_method("apply_damage"):
		push_warning("SimulationRoot damage effect expects a unit with apply_damage().")
		return

	var attacker_team_id: String = String(effect.get("attacker_team_id", ""))
	var attacker_unit_id: String = String(effect.get("attacker_unit_id", ""))
	var target_team_id: String = ""
	if unit.has_method("get_team_id"):
		target_team_id = String(unit.call("get_team_id"))

	var is_friendly_fire: bool = not attacker_team_id.is_empty() and not target_team_id.is_empty() and attacker_team_id == target_team_id
	var allow_friendly_fire: bool = bool(effect.get("allow_friendly_fire", true))
	if is_friendly_fire and not allow_friendly_fire:
		return

	var base_damage: int = _extract_int(effect.get("damage", 0))
	if base_damage <= 0:
		push_warning("SimulationRoot damage effect expects a positive damage value.")
		return

	var attacker_unit = _resolve_attacker_unit(attacker_unit_id)
	var air_targeting_gate: Dictionary = _build_air_targeting_gate(effect, attacker_unit, unit)
	_last_air_targeting_debug = air_targeting_gate.duplicate(true)
	if not bool(air_targeting_gate.get("allowed", true)):
		return

	var target_cover_profile: Dictionary = _build_terrain_cover_height_profile(unit, attacker_unit)
	var target_cover_score: float = _extract_effective_cover_score(unit, attacker_unit)
	if effect.has("target_cover_override"):
		target_cover_score = clampf(_extract_float(effect.get("target_cover_override", target_cover_score), target_cover_score), 0.0, 80.0)
	var attacker_attack_bonus: float = _extract_unit_attack_bonus(attacker_unit)
	var attacker_cover_score: float = _extract_unit_cover_score(attacker_unit)
	var hit_chance: float = _extract_float(effect.get("hit_chance", 1.0), 1.0)
	hit_chance *= _extract_unit_accuracy_multiplier(attacker_unit)
	hit_chance = clampf(
		hit_chance + attacker_attack_bonus + _extract_unit_hit_modifier(attacker_unit) + _extract_height_accuracy_modifier(attacker_unit, unit) + (attacker_cover_score * ATTACKER_COVER_HIT_BONUS_FACTOR) - _extract_unit_evasion_modifier(unit) - (target_cover_score * TARGET_COVER_HIT_PENALTY_FACTOR),
		HIT_CHANCE_MIN,
		HIT_CHANCE_MAX
	)
	var roll: float = _extract_damage_roll(effect)
	var damage_multiplier: float = _extract_float(effect.get("damage_multiplier", 1.0), 1.0)
	damage_multiplier = maxf(damage_multiplier + attacker_attack_bonus - (target_cover_score * TARGET_COVER_DAMAGE_PENALTY_FACTOR), DAMAGE_MULTIPLIER_MIN)
	damage_multiplier *= _extract_unit_damage_taken_multiplier(unit)
	var damage_model = DAMAGE_MODEL_SCRIPT.new()
	if not bool(damage_model.call("resolve_hit", hit_chance, roll)):
		return

	var resolved_damage: int = int(damage_model.call("resolve_damage", base_damage, damage_multiplier))
	if resolved_damage <= 0:
		return

	var hit_context: Dictionary = {
		"effect_type": "damage",
		"unit_id": unit_id,
		"attacker_unit_id": attacker_unit_id,
		"attacker_team_id": attacker_team_id,
		"attacker_attack_bonus": attacker_attack_bonus,
		"attacker_profile_hit_modifier": _extract_unit_hit_modifier(attacker_unit),
		"target_profile_evasion_modifier": _extract_unit_evasion_modifier(unit),
		"height_accuracy_modifier": _extract_height_accuracy_modifier(attacker_unit, unit),
		"target_cover_score": target_cover_score,
		"target_cover_profile": target_cover_profile,
		"friendly_fire": is_friendly_fire,
		"attacker_movement_layer": String(air_targeting_gate.get("attacker_movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND)),
		"target_movement_layer": String(air_targeting_gate.get("target_movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND)),
		"attacker_altitude_band": int(air_targeting_gate.get("attacker_altitude_band", 0)),
		"target_altitude_band": int(air_targeting_gate.get("target_altitude_band", 0)),
		"air_targeting_reason": String(air_targeting_gate.get("reason", "allowed")),
	}
	if bool(effect.get("is_flank", false)):
		hit_context["is_flank"] = true
		hit_context["flank_fireteam_id"] = String(effect.get("flank_fireteam_id", ""))
		hit_context["flank_source_angle"] = _extract_float(effect.get("flank_source_angle", 0.0), 0.0)
		hit_context["flank_direction_label"] = String(effect.get("flank_direction_label", "")).strip_edges().to_lower()
		hit_context["flank_morale_state"] = String(effect.get("flank_morale_state", "")).strip_edges().to_lower()
	unit.call("apply_damage", resolved_damage, hit_context)


func _extract_damage_roll(effect: Dictionary) -> float:
	if effect.has("roll_override"):
		return _extract_float(effect.get("roll_override", -1.0), -1.0)
	return get_next_combat_roll()


func _apply_heal_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot heal effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a heal effect.")
		return

	if not unit.has_method("apply_heal"):
		push_warning("SimulationRoot heal effect expects a unit with apply_heal().")
		return

	var heal_amount: int = _extract_int(effect.get("amount", 0))
	if heal_amount <= 0:
		push_warning("SimulationRoot heal effect expects a positive amount value.")
		return

	var healer_team_id: String = String(effect.get("healer_team_id", ""))
	if not healer_team_id.is_empty() and unit.has_method("get_team_id"):
		if healer_team_id != String(unit.call("get_team_id")):
			return

	var heal_context: Dictionary = {
		"effect_type": "heal",
		"unit_id": unit_id,
		"healer_unit_id": String(effect.get("healer_unit_id", "")),
		"healer_team_id": healer_team_id,
	}
	unit.call("apply_heal", heal_amount, heal_context)


func _apply_bleedout_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot bleedout effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a bleedout effect.")
		return

	if not unit.has_method("advance_bleedout"):
		push_warning("SimulationRoot bleedout effect expects a unit with advance_bleedout().")
		return

	unit.call("advance_bleedout")


func _get_unit_registry():
	if unit_registry_path.is_empty():
		return null

	return get_node_or_null(unit_registry_path)


func _get_terrain_registry():
	if terrain_registry_path.is_empty():
		return null

	return get_node_or_null(terrain_registry_path)


func _resolve_unit(unit_id: String):
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		push_warning("SimulationRoot requires a direct UnitRegistry reference for unit lookups.")
		return null

	return unit_registry.call("get_unit", unit_id)


func _resolve_attacker_unit(attacker_unit_id: String):
	if attacker_unit_id.is_empty():
		return null

	return _resolve_known_unit(attacker_unit_id)


func _build_air_targeting_gate(effect: Dictionary, attacker_unit, target_unit) -> Dictionary:
	var attacker_layer: String = _get_unit_movement_layer(attacker_unit)
	var target_layer: String = _get_unit_movement_layer(target_unit)
	var attacker_altitude_band: int = _get_unit_altitude_band(attacker_unit)
	var target_altitude_band: int = _get_unit_altitude_band(target_unit)
	var result: Dictionary = {
		"allowed": true,
		"reason": "allowed",
		"attacker_unit_id": String(effect.get("attacker_unit_id", "")),
		"target_unit_id": String(effect.get("unit_id", "")),
		"attacker_movement_layer": attacker_layer,
		"target_movement_layer": target_layer,
		"attacker_altitude_band": attacker_altitude_band,
		"target_altitude_band": target_altitude_band,
		"requires_anti_air": false,
	}
	if target_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR and attacker_layer != MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR:
		result["requires_anti_air"] = true
		if not bool(effect.get("anti_air", false)):
			result["allowed"] = false
			result["reason"] = "anti_air_required"
			return result

	if attacker_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR and target_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR and effect.has("air_to_air") and not bool(effect.get("air_to_air", true)):
		result["allowed"] = false
		result["reason"] = "air_to_air_disabled"
		return result

	if attacker_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR and target_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND and effect.has("air_to_ground") and not bool(effect.get("air_to_ground", true)):
		result["allowed"] = false
		result["reason"] = "air_to_ground_disabled"
		return result

	return result


func _get_unit_movement_layer(unit) -> String:
	if unit == null:
		return MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND
	if unit.has_method("get_movement_layer"):
		return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(unit.call("get_movement_layer")))
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status is Object:
			return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(runtime_status.get("movement_layer")))
	return MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND


func _get_unit_altitude_band(unit) -> int:
	if unit == null:
		return MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND
	if unit.has_method("get_altitude_band"):
		return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(unit.call("get_altitude_band"))
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status is Object:
			return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(runtime_status.get("altitude_band"))
	return MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND


func _extract_unit_cover_score(unit) -> float:
	if unit == null or not unit.has_method("get_cover_score"):
		return 0.0

	return float(unit.call("get_cover_score"))


func _extract_effective_cover_score(unit, attacker_unit = null) -> float:
	var command_cover_score: float = _extract_unit_cover_score(unit)
	var terrain_cover_score: float = _extract_terrain_cover_score(unit, attacker_unit)
	return clampf(command_cover_score + terrain_cover_score, 0.0, 80.0)


func _extract_terrain_cover_score(unit, attacker_unit = null) -> float:
	return float(_build_terrain_cover_height_profile(unit, attacker_unit).get("effective_cover_score", 0.0))


func _build_terrain_cover_height_profile(unit, attacker_unit = null) -> Dictionary:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D):
		return {
			"base_cover_score": 0.0,
			"effective_cover_score": 0.0,
			"cover_height": 0.0,
			"cover_height_factor": 0.0,
			"height_factor": 1.0,
			"attacker_floor_height": 0.0,
			"target_floor_height": 0.0,
			"attacker_height_advantage": 0.0,
		}

	var target_position: Vector2 = (unit as Node2D).global_position
	var base_cover_score: float = float(terrain_registry.call("get_cover_at_world", target_position))
	var cover_height: float = 0.0
	var target_floor_height: float = 0.0
	if terrain_registry.has_method("get_cover_height_at_world"):
		cover_height = float(terrain_registry.call("get_cover_height_at_world", target_position))
	if terrain_registry.has_method("get_floor_height_at_world"):
		target_floor_height = float(terrain_registry.call("get_floor_height_at_world", target_position))
	var attacker_floor_height: float = target_floor_height
	if attacker_unit != null and attacker_unit is Node2D and terrain_registry.has_method("get_floor_height_at_world"):
		attacker_floor_height = float(terrain_registry.call("get_floor_height_at_world", (attacker_unit as Node2D).global_position))
	var attacker_height_advantage: float = attacker_floor_height - target_floor_height
	var cover_height_factor: float = _get_cover_height_factor(cover_height, base_cover_score)
	var height_factor: float = _get_relative_cover_height_factor(attacker_height_advantage)
	var effective_cover_score: float = clampf(base_cover_score * cover_height_factor * height_factor, 0.0, 100.0)
	return {
		"base_cover_score": base_cover_score,
		"effective_cover_score": effective_cover_score,
		"cover_height": cover_height,
		"cover_height_factor": cover_height_factor,
		"height_factor": height_factor,
		"attacker_floor_height": attacker_floor_height,
		"target_floor_height": target_floor_height,
		"attacker_height_advantage": attacker_height_advantage,
	}


func _get_cover_height_factor(cover_height: float, base_cover_score: float) -> float:
	if base_cover_score <= 0.0:
		return 0.0
	if cover_height <= 0.0:
		return 0.75
	if cover_height < LOW_COVER_HEIGHT_THRESHOLD:
		return 0.55
	if cover_height < MID_COVER_HEIGHT_THRESHOLD:
		return 0.75
	if cover_height < HIGH_COVER_HEIGHT_THRESHOLD:
		return 0.9
	return 1.0


func _get_relative_cover_height_factor(attacker_height_advantage: float) -> float:
	if attacker_height_advantage > 0.0:
		return clampf(1.0 - (attacker_height_advantage * 0.25), 0.35, 1.0)
	if attacker_height_advantage < 0.0:
		return clampf(1.0 + (absf(attacker_height_advantage) * 0.1), 1.0, 1.15)
	return 1.0


func _extract_unit_attack_bonus(unit) -> float:
	if unit == null or not unit.has_method("get_attack_bonus"):
		return 0.0

	return float(unit.call("get_attack_bonus"))


func _extract_height_accuracy_modifier(attacker_unit, target_unit) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or attacker_unit == null or target_unit == null:
		return 0.0

	if not (attacker_unit is Node2D) or not (target_unit is Node2D):
		return 0.0

	var attacker_height: int = int(terrain_registry.call("get_height_at_world", (attacker_unit as Node2D).global_position))
	var target_height: int = int(terrain_registry.call("get_height_at_world", (target_unit as Node2D).global_position))
	var height_difference: int = attacker_height - target_height
	if height_difference > 0:
		return HEIGHT_ADVANTAGE_ACCURACY_BONUS * float(height_difference)

	if height_difference < 0:
		return -HEIGHT_DISADVANTAGE_ACCURACY_PENALTY * float(abs(height_difference))

	return 0.0


func _extract_surface_speed_factor(unit) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D):
		return 1.0

	return float(terrain_registry.call("get_surface_speed_factor_at_world", (unit as Node2D).global_position))


func _extract_move_speed_factor(cmd: Dictionary, unit) -> float:
	var move_speed_factor: float = 1.0
	var raw_factor: Variant = cmd.get("move_speed_factor", null)
	if typeof(raw_factor) == TYPE_INT or typeof(raw_factor) == TYPE_FLOAT:
		move_speed_factor = maxf(float(raw_factor), 0.0)
	elif unit != null and unit.has_method("get_move_speed_factor"):
		move_speed_factor = maxf(float(unit.call("get_move_speed_factor")), 0.0)

	return move_speed_factor * _extract_unit_speed_multiplier(unit)


func _update_objective_capture() -> void:
	if not _is_valid_objective_status(_objective_status):
		return

	var capturing_team_ids: PackedStringArray = _get_objective_team_ids_in_radius(_objective_status)
	_objective_status.call("set_contested", capturing_team_ids.size() > 1)
	if capturing_team_ids.size() != 1:
		return

	var capturing_team_id: String = String(capturing_team_ids[0])
	if capturing_team_id.is_empty():
		return

	if String(_objective_status.owning_team_id) == capturing_team_id:
		_objective_status.capture_progress = 1.0
		_objective_status.capturing_team_id = capturing_team_id
		return

	if String(_objective_status.capturing_team_id) != capturing_team_id:
		_objective_status.capturing_team_id = capturing_team_id
		_objective_status.capture_progress = 0.0

	_objective_status.capture_progress = minf(float(_objective_status.capture_progress) + CAPTURE_PROGRESS_PER_TICK, 1.0)
	if float(_objective_status.capture_progress) < 1.0:
		return

	_objective_status.capture_progress = 1.0
	_objective_status.owning_team_id = capturing_team_id


func _get_objective_team_ids_in_radius(objective_status) -> PackedStringArray:
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return []

	var team_ids: PackedStringArray = []
	var objective_position: Vector2 = objective_status.position
	var capture_radius: float = maxf(float(objective_status.capture_radius), 0.0)
	for unit in unit_registry.call("get_all_units"):
		if unit == null or not (unit is Node2D):
			continue

		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue

		if not unit.has_method("get_team_id"):
			continue

		var team_id: String = String(unit.call("get_team_id"))
		if team_id.is_empty() or team_ids.has(team_id):
			continue

		var unit_position: Vector2 = (unit as Node2D).global_position
		if unit_position.distance_to(objective_position) <= capture_radius:
			team_ids.append(team_id)

	return team_ids


func _is_valid_objective_status(objective_status) -> bool:
	return objective_status != null and objective_status is OBJECTIVE_STATUS_SCRIPT


func _extract_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)

	return 0


func _extract_float(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)

	return fallback


func _extract_unit_hit_modifier(unit) -> float:
	if unit == null:
		return 0.0
	if unit.has_method("get_combat_hit_modifier"):
		return float(unit.call("get_combat_hit_modifier"))

	var modifier: float = 0.0
	if unit.has_method("get_order_fidelity_hit_modifier"):
		modifier += float(unit.call("get_order_fidelity_hit_modifier"))
	if unit.has_method("get_autonomy_hit_modifier"):
		modifier += float(unit.call("get_autonomy_hit_modifier"))
	if unit.has_method("get_leadership_hit_modifier"):
		modifier += float(unit.call("get_leadership_hit_modifier"))
	return modifier


func _extract_unit_evasion_modifier(unit) -> float:
	if unit == null:
		return 0.0
	if unit.has_method("get_combat_evasion_modifier"):
		return float(unit.call("get_combat_evasion_modifier"))
	if not unit.has_method("get_signature_control_evasion_modifier"):
		return 0.0

	return float(unit.call("get_signature_control_evasion_modifier"))


func _extract_unit_accuracy_multiplier(unit) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_combat_hit_chance_multiplier"):
		return maxf(float(unit.call("get_combat_hit_chance_multiplier")), 0.0)
	if not unit.has_method("get_accuracy_skill"):
		return 1.0

	return 0.5 + clampf(float(unit.call("get_accuracy_skill")), 0.0, 1.0)


func _extract_unit_speed_multiplier(unit) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_combat_speed_multiplier"):
		return maxf(float(unit.call("get_combat_speed_multiplier")), 0.0)
	if not unit.has_method("get_speed_skill"):
		return 1.0

	var base_multiplier: float = 0.5 + clampf(float(unit.call("get_speed_skill")), 0.0, 1.0)
	if unit.has_method("get_initiative_speed_multiplier"):
		base_multiplier *= float(unit.call("get_initiative_speed_multiplier"))
	return base_multiplier


func _extract_unit_damage_taken_multiplier(unit) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_combat_damage_taken_multiplier"):
		return maxf(float(unit.call("get_combat_damage_taken_multiplier")), 0.0)
	if not unit.has_method("get_toughness_skill"):
		return 1.0

	var toughness: float = clampf(float(unit.call("get_toughness_skill")), 0.0, 1.0)
	var damage_taken_multiplier: float = 1.0 - (toughness * 0.4)
	if unit.has_method("get_contact_stability_damage_taken_multiplier"):
		damage_taken_multiplier *= float(unit.call("get_contact_stability_damage_taken_multiplier"))
	return damage_taken_multiplier


func _apply_respawn_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot respawn effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a respawn effect.")
		return

	if not unit.has_method("respawn"):
		push_warning("SimulationRoot respawn effect expects a unit with respawn().")
		return

	var spawn_position: Variant = effect.get("spawn_position", null)
	if typeof(spawn_position) != TYPE_VECTOR2:
		push_warning("SimulationRoot respawn effect expects a Vector2 spawn_position.")
		return

	unit.call("respawn", spawn_position)


func _apply_dropship_embark_unit_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot dropship embark effect expects a non-empty unit_id.")
		return
	var unit = _resolve_known_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a dropship embark effect.")
		return
	_apply_dropship_position_and_visibility(unit, effect, false)


func _apply_dropship_deploy_unit_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot dropship deploy effect expects a non-empty unit_id.")
		return
	var unit = _resolve_known_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a dropship deploy effect.")
		return
	_apply_dropship_runtime_activation(unit_id, unit, effect)
	_apply_dropship_position_and_visibility(unit, effect, true)
	var runtime_status: String = String(effect.get("runtime_status", "")).strip_edges()
	if not runtime_status.is_empty() and unit.has_method("set_runtime_status"):
		unit.call("set_runtime_status", runtime_status)
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")


func _apply_dropship_position_and_visibility(unit, effect: Dictionary, default_visible: bool) -> void:
	if unit == null:
		return
	if effect.has("position") and unit is Node2D:
		var unit_node := unit as Node2D
		unit_node.global_position = _coerce_vector2(effect.get("position", unit_node.global_position), unit_node.global_position)
	if unit is CanvasItem:
		(unit as CanvasItem).visible = bool(effect.get("visible", default_visible))


func _apply_dropship_runtime_activation(unit_id: String, unit: Node, effect: Dictionary) -> void:
	if not bool(effect.get("runtime_active", false)):
		return
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("register_unit"):
		if not unit_registry.has_method("has_unit") or not bool(unit_registry.call("has_unit", unit_id)):
			unit_registry.call("register_unit", unit_id, unit)
	var runtime_leader = _resolve_optional_node_path(effect.get("runtime_leader_path", NodePath("")))
	if runtime_leader != null and runtime_leader.has_method("add_unit_member"):
		runtime_leader.call("add_unit_member", unit)
	var ftl_registry = _resolve_optional_node_path(effect.get("ftl_registry_path", NodePath("")))
	if ftl_registry == null or not ftl_registry.has_method("register_ftl"):
		return
	var team_id: String = String(effect.get("team_id", "")).strip_edges()
	if team_id.is_empty() and unit.has_method("get_team_id"):
		team_id = String(unit.call("get_team_id")).strip_edges()
	if not team_id.is_empty() and (not ftl_registry.has_method("has_ftl") or not bool(ftl_registry.call("has_ftl", team_id))):
		ftl_registry.call("register_ftl", team_id, runtime_leader)


func _resolve_optional_node_path(raw_path: Variant) -> Node:
	var node_path: NodePath = raw_path if raw_path is NodePath else NodePath(String(raw_path))
	if node_path.is_empty():
		return null
	return get_node_or_null(node_path)


func _apply_loadout_modifiers_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot loadout modifier effect expects a non-empty unit_id.")
		return
	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a loadout modifier effect.")
		return
	if not unit.has_method("apply_loadout_modifiers"):
		push_warning("SimulationRoot loadout modifier effect expects a unit with apply_loadout_modifiers().")
		return
	var modifiers_dict: Dictionary = Dictionary(effect.get("modifiers", {})).duplicate(true)
	if modifiers_dict.is_empty():
		modifiers_dict = {
			"unit_id": unit_id,
			"armor_id": String(effect.get("armor_id", "medium")),
			"weapon_1_id": String(effect.get("weapon_1_id", "rifle")),
			"weapon_2_id": String(effect.get("weapon_2_id", "rifle")),
			"accuracy_mod": float(effect.get("accuracy_mod", 0.0)),
			"speed_mod": float(effect.get("speed_mod", 0.0)),
			"toughness_mod": float(effect.get("toughness_mod", 0.0)),
			"cover_mod": float(effect.get("cover_mod", 0.0)),
			"range_class": String(effect.get("range_class", "medium")),
		}
	unit.call("apply_loadout_modifiers", modifiers_dict)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	return fallback
