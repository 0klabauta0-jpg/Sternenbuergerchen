class_name SimulationRoot
extends Node

const PERSONNEL_LOADOUT_STATE = preload("res://scripts/core/personnel_loadout_state.gd")
var _personnel_loadout_owner: RefCounted = PERSONNEL_LOADOUT_STATE.new()


func get_personnel_loadout_state() -> RefCounted:
	return _personnel_loadout_owner


func configure_personnel_loadouts(owner: RefCounted) -> void:
	_personnel_loadout_owner = owner


func request_personnel_loadout_command(operation: String, payload: Dictionary) -> void:
	match operation:
		"configure_roster":
			_personnel_loadout_owner.call("configure_roster", Array(payload.get("roster", [])))
		"restore":
			_personnel_loadout_owner.call("restore_snapshot", Dictionary(payload.get("loadouts", {})))
		"import_fireteam_loadouts":
			_personnel_loadout_owner.call("import_fireteam_loadouts", Array(payload.get("definitions", [])), Dictionary(payload.get("members", {})))
		"reconcile_context":
			_personnel_loadout_owner.call("reconcile_context", Dictionary(payload.get("defaults", {})), Array(payload.get("definitions", [])), Dictionary(payload.get("members", {})), PackedStringArray(payload.get("retained_unit_ids", [])))
		"set_loadout":
			_personnel_loadout_owner.call("set_loadout", String(payload.get("unit_id", "")), Dictionary(payload.get("loadout", {})))
		"set_slot":
			_personnel_loadout_owner.call("set_slot", String(payload.get("unit_id", "")), String(payload.get("key", "")), String(payload.get("value", "")))

var _base_personnel_owner: Node
var _skirmish_economy_owner: RefCounted
var _skirmish_transaction: Callable

func configure_skirmish_economy(owner: RefCounted, transaction: Callable) -> void:
	_skirmish_economy_owner = owner
	_skirmish_transaction = transaction

func request_skirmish_command(command: Dictionary) -> Dictionary:
	if _skirmish_economy_owner == null:
		return {"ok": false, "reason": "skirmish_economy_unavailable"}
	return _skirmish_economy_owner.call("apply_command", command.duplicate(true), _skirmish_transaction)

func configure_base_personnel(owner: Node) -> void:
	_base_personnel_owner = owner

func request_base_personnel_command(operation: String, payload: Dictionary) -> Dictionary:
	if not is_instance_valid(_base_personnel_owner):
		return {"ok":false,"reason":"base_personnel_unavailable"}
	return _base_personnel_owner.call("apply_operation", operation, payload.duplicate(true))

signal tick_processed(tick: int)
signal hex_ground_events_committed(events: Array[Dictionary])
signal singleplayer_command_committed(command: Dictionary, result: Dictionary)

var _singleplayer_campaign_owner: RefCounted
var _singleplayer_supply_owner: RefCounted
var _campaign_onboarding_owner: RefCounted
var _singleplayer_space_travel_owner: RefCounted


func configure_singleplayer_owners(campaign: RefCounted, supply: RefCounted, onboarding: RefCounted = null, travel: RefCounted = null) -> void:
	_singleplayer_campaign_owner = campaign
	_singleplayer_supply_owner = supply
	_campaign_onboarding_owner = onboarding
	_singleplayer_space_travel_owner = travel


var _space_encounter_owner: RefCounted

func configure_space_encounter(owner: RefCounted) -> void:
	_space_encounter_owner = owner

func request_singleplayer_command(command: Dictionary, authority_context: Dictionary = {}) -> Dictionary:
	# Only the owning runtime adapter supplies authority_context. UI payload is
	# never interpreted as runtime evidence, service location or departure proof.
	var owner: RefCounted
	match String(command.get("contract_category", "")):
		"campaign_space":
			owner = _space_encounter_owner
		"singleplayer_campaign":
			owner = _singleplayer_campaign_owner
		"singleplayer_supply":
			owner = _singleplayer_supply_owner
		"campaign_onboarding":
			owner = _campaign_onboarding_owner
		"singleplayer_space_travel":
			owner = _singleplayer_space_travel_owner
		_:
			return {"ok": false, "reason": "unknown_singleplayer_contract"}
	if owner == null:
		return {"ok": false, "reason": "singleplayer_owner_unavailable"}
	var context: Dictionary = authority_context.duplicate(true)
	var equipment_commit: bool = String(command.get("contract_category", "")) == "singleplayer_supply" and String(command.get("operation", "")) == "inventory_equip"
	var unit_id: String = String(Dictionary(command.get("payload", {})).get("unit_id", ""))
	if equipment_commit:
		if not bool(_personnel_loadout_owner.call("has_unit", unit_id)):
			return {"ok": false, "reason": "inventory_access", "message": "Person ist hier nicht erreichbar"}
		context["loadout"] = _personnel_loadout_owner.call("get_loadout", unit_id)
	var result: Dictionary = owner.call("apply_command", command.duplicate(true), context)
	if equipment_commit and bool(result.get("ok", false)) and not bool(result.get("replayed", false)):
		# The Supply owner has validated the complete slot change. Publish both
		# sides synchronously before listeners can observe a committed command.
		_personnel_loadout_owner.call("set_loadout", unit_id, Dictionary(result.loadout))
	singleplayer_command_committed.emit(command.duplicate(true), result.duplicate(true))
	return result
signal damage_effect_resolved(result: Dictionary)
signal fire_rule_committed(state: Dictionary)
signal dropship_command_committed(command: Dictionary)
signal commander_intent_committed(command: Dictionary)
signal multiplayer_snapshot_applied(snapshot: Dictionary)
signal network_command_result_received(result: Dictionary)
signal network_command_accepted(command: Dictionary, peer_id: int)

const MOVE_SPEED_PER_SECOND: float = 80.0
const DAMAGE_MODEL_SCRIPT: GDScript = preload("res://scripts/core/damage_model.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC: int = 600
const LOCAL_AVOIDANCE_MIN_FORWARD_PROGRESS_FACTOR: float = 0.35
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const REGIONAL_NAVIGATION_MIN_TILES: int = 512 * 256
const REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE: int = 24
const REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK: int = 96
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const BOTTLENECK_RESERVATION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const MULTIPLAYER_COMMAND_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const HEX_GROUND_RUNTIME_SCRIPT: GDScript = preload("res://scripts/core/hex_ground_runtime.gd")
const HEX_MOVEMENT_RUNTIME_SCRIPT=preload("res://scripts/core/hex_movement_command_runtime.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")
const CAPTURE_PROGRESS_PER_TICK: float = 0.01
const HPA_NAVIGATION_CLUSTER_SIZE: int = 8
const SNAPSHOT_CHUNK_PAYLOAD_BYTES: int = 1000
const SNAPSHOT_MAX_CHUNK_COUNT: int = 256
const SNAPSHOT_MAX_RAW_BYTES: int = 8 * 1024 * 1024
const SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS: int = 32
const SNAPSHOT_REASSEMBLY_TIMEOUT_MSEC: int = 1500
const NETWORK_COMMAND_DEDUPE_MAX_IDS: int = 2048
const SNAPSHOT_COMPRESSION_MODE: int = FileAccess.COMPRESSION_ZSTD

const HIT_CHANCE_MIN: float = 0.05
const HIT_CHANCE_MAX: float = 0.95
const ATTACKER_COVER_HIT_BONUS_FACTOR: float = 0.05
const TARGET_COVER_HIT_PENALTY_FACTOR: float = 0.35
const TARGET_COVER_DAMAGE_PENALTY_FACTOR: float = 0.2
const DAMAGE_MULTIPLIER_MIN: float = 0.1
const HEIGHT_ADVANTAGE_ACCURACY_BONUS: float = 0.1
const HEIGHT_DISADVANTAGE_ACCURACY_PENALTY: float = 0.05

@export var is_server_authoritative: bool = false
@export var unit_registry_path: NodePath
@export var terrain_registry_path: NodePath
@export var audio_event_bus_path: NodePath
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
@export var runtime_tick_budget_debug_enabled: bool = false
@export var unit_minimum_spacing_enabled: bool = true
@export_range(8.0, 192.0, 1.0) var unit_minimum_spacing_distance: float = 36.0
@export_range(1, 8, 1) var unit_minimum_spacing_solver_iterations: int = 4
@export var unit_minimum_spacing_debug_enabled: bool = false
@export var local_avoidance_enabled: bool = false
@export var local_avoidance_debug_enabled: bool = false
@export_range(4.0, 96.0, 1.0) var local_avoidance_agent_radius: float = 18.0
@export_range(8.0, 192.0, 1.0) var local_avoidance_neighbor_radius: float = 56.0
@export_range(8.0, 192.0, 1.0) var local_avoidance_spatial_cell_size: float = 64.0
@export_range(1, 32, 1) var local_avoidance_max_neighbors: int = 8
@export_range(0.1, 5.0, 0.1) var local_avoidance_stuck_threshold_seconds: float = 1.0
@export_range(0.0, 60.0, 1.0) var local_avoidance_stuck_speed_threshold: float = 5.0
@export var bottleneck_reservation_enabled: bool = false
@export var bottleneck_reservation_debug_enabled: bool = false
@export_range(1, 64, 1) var bottleneck_reservation_horizon_ticks: int = 16

var command_queue: Array = []
var effects_queue: Array = []
var tick_counter: int = 0
var is_processing_tick: bool = false
var _last_tick_delta: float = 0.0
var _contact_path_recompute_ready_at_msec: Dictionary = {}
var _objective_status: RefCounted = null
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
var _last_terrain_move_debug_by_unit_id: Dictionary = {}
var _last_discarded_move_command: Dictionary = {}
var _discarded_move_command_count: int = 0
var _discarded_move_command_counts_by_reason: Dictionary = {}
var _latest_command_token_by_unit_id: Dictionary = {}
var _committed_command_token_by_unit_id: Dictionary = {}
var _known_units_by_id: Dictionary = {}
var _peer_team_assignments: Dictionary = {1: "team_alpha"}
var _peer_role_assignments: Dictionary = {1: "commander"}
var _peer_fireteam_assignments: Dictionary = {}
var _last_network_command_rejection: Dictionary = {}
var _last_network_command_result: Dictionary = {}
var _network_command_accept_count: int = 0
var _network_command_reject_count: int = 0
var _accepted_network_dropship_command_ids: Dictionary = {}
var _accepted_network_dropship_command_id_order: Array = []
var _network_command_dedupe_hit_count: int = 0
var _network_command_preflight_validator: Callable = Callable()
var _multiplayer_snapshot_context: Dictionary = {}
var _authoritative_fire_rules_by_fireteam: Dictionary = {}
var _air_asset_status_by_id: Dictionary = {}
var _last_applied_snapshot_tick: int = -1
var _last_applied_vital_tick_by_unit_id: Dictionary = {}
var _snapshot_apply_count: int = 0
var _snapshot_out_of_order_count: int = 0
var _snapshot_missing_unit_count: int = 0
var _last_snapshot_reject_reason: String = ""
var _snapshot_audio_event_ids_played: Dictionary = {}
var _snapshot_audio_played_count: int = 0
var _snapshot_audio_suppressed_count: int = 0
var _last_snapshot_audio_result: Dictionary = {}
var _audio_event_bus = null
var _last_broadcast_vital_state_by_unit_id: Dictionary = {}
var _last_server_state: Dictionary = {}
var _incoming_snapshot_chunks_by_tick: Dictionary = {}
var _snapshot_transport_last_chunk_count: int = 0
var _snapshot_transport_last_max_chunk_payload_bytes: int = 0
var _snapshot_transport_last_raw_bytes: int = 0
var _snapshot_transport_last_wire_bytes: int = 0
var _snapshot_transport_reassembled_count: int = 0
var _snapshot_transport_reassembly_failure_count: int = 0
var _snapshot_transport_expired_tick_count: int = 0
var _snapshot_transport_evicted_tick_count: int = 0
var _snapshot_transport_stale_chunk_count: int = 0
var _snapshot_transport_next_prune_msec: int = 0
var _snapshot_transport_last_pack_usec: int = 0
var _snapshot_transport_last_reassembly_usec: int = 0
var _snapshot_broadcast_paused: bool = false
var _snapshot_blocked_peer_ids: Dictionary = {}
var _combat_rng := RandomNumberGenerator.new()
var _hpa_navigation_graph = null
var _hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
var _hpa_navigation_registry = null
var _hpa_navigation_tile_count: int = -1
var _hpa_navigation_registry_revision: int = -1
var _hpa_navigation_build_count: int = 0
var _hpa_navigation_cache_hit_count: int = 0
var _hpa_navigation_last_build_stats: Dictionary = {}
var _navigation_new_path_queries_this_tick: int = 0
var _navigation_path_queries_this_tick: int = 0
var _regional_navigation_expansions_this_tick: int = 0
var _regional_navigation_admissions: Dictionary = {}
var _regional_navigation_last_service_tick: Dictionary = {}
var _navigation_delayed_this_tick: int = 0
var _navigation_fallback_queries_this_tick: int = 0
var _navigation_unreachable_queries_this_tick: int = 0
var _navigation_last_delay_reason: String = ""
var _navigation_last_tick_queries: Array = []
var _navigation_most_expensive_query: Dictionary = {}
var _navigation_last_path_metrics: Dictionary = {}
var _runtime_tick_budget_debug_snapshot: Dictionary = {}
var _runtime_frame_budget_debug = preload("res://scripts/core/frame_timing_accumulator.gd").new()
var _runtime_command_type_count: Dictionary = {}
var _runtime_command_type_usec: Dictionary = {}
var _runtime_command_requeue_count: Dictionary = {}
var _local_avoidance_resolver = LOCAL_AVOIDANCE_RESOLVER_SCRIPT.new()
var _bottleneck_reservation_resolver = BOTTLENECK_RESERVATION_RESOLVER_SCRIPT.new()
var _multiplayer_command_contract = MULTIPLAYER_COMMAND_CONTRACT_SCRIPT.new()
var _multiplayer_snapshot_contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
var _unit_minimum_spacing_debug_snapshot: Dictionary = {}
var _local_avoidance_prepared_tick: int = -1
var _local_avoidance_debug_by_unit_id: Dictionary = {}
var _local_avoidance_stuck_seconds_by_unit_id: Dictionary = {}
var _bottleneck_reservation_debug_snapshot: Dictionary = {}
var _last_damage_effect_resolution: Dictionary = {}
var _hex_ground_runtime = HEX_GROUND_RUNTIME_SCRIPT.new()
var _hex_ground_registry: Node
var _hex_ground_enabled := false
var _hex_ground_context_revision := 0
const HEX_FACING_PRIORITIES := {"noise_reaction":10,"combat_reaction":20,"security_assignment":30,"movement":40}
const HEX_FACING_REPLAY_CAPACITY := 4096
var _hex_facing_pending: Dictionary = {}
var _hex_facing_seen: Dictionary = {}
var _hex_facing_replay_keys: Array[String] = []
var _hex_facing_replay_cursor := 0
var _last_hex_ground_events: Array[Dictionary] = []
var _hex_movement_runtime=HEX_MOVEMENT_RUNTIME_SCRIPT.new()
var _hex_visual_unit_ids:Dictionary={}
var _hex_projection_terrain_revision:=-1
var _hex_boundary_facing:Dictionary={}


## Called by the owning map runtime, never interpreted from a UI/network payload.
## Validate before replacing the current context, so failed loads preserve it.
func configure_hex_ground_runtime(map_data: RefCounted, terrain_registry: Node) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok": false, "reason": "not_authority"}
	if map_data == null or not map_data.has_method("get_tactical_grid_rules") or not map_data.has_method("get_grid_topology") or not map_data.has_method("has_load_issue"):
		return {"ok": false, "reason": "invalid_map_data"}
	if bool(map_data.call("has_load_issue")):
		return {"ok": false, "reason": "map_load_issue"}
	if not map_data.has_method("get_map_name") or not map_data.has_method("get_grid_size"):
		return {"ok": false, "reason": "invalid_map_context"}
	var map_size: Variant = map_data.call("get_grid_size")
	if String(map_data.call("get_map_name")).strip_edges().is_empty() or typeof(map_size) != TYPE_VECTOR2I or map_size.x <= 0 or map_size.y <= 0 or tick_counter < 0 or tick_counter > HEX_GROUND_RUNTIME_SCRIPT.MAX_TICK:
		return {"ok": false, "reason": "invalid_map_context"}
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_grid_topology") or String(terrain_registry.call("get_grid_topology")) != String(map_data.call("get_grid_topology")):
		return {"ok": false, "reason": "invalid_terrain_registry"}
	var rules := String(map_data.call("get_tactical_grid_rules"))
	if rules.is_empty():
		_clear_hex_movement_context()
		_hex_ground_runtime.clear()
		_hex_ground_registry = null
		_hex_ground_enabled = false
		_hex_ground_context_revision += 1
		_hex_facing_pending.clear()
		_hex_facing_seen.clear()
		_hex_facing_replay_keys.clear()
		_hex_facing_replay_cursor = 0
		_last_hex_ground_events.clear()
		return {"ok": true, "enabled": false}
	if rules != "hex_tactical_v1" or String(map_data.call("get_grid_topology")) != HEX_GROUND_RUNTIME_SCRIPT.TOPOLOGY:
		return {"ok": false, "reason": "unsupported_tactical_grid_rules"}
	if not is_instance_valid(terrain_registry) or not terrain_registry.has_method("get_grid_topology") or String(terrain_registry.call("get_grid_topology")) != HEX_GROUND_RUNTIME_SCRIPT.TOPOLOGY:
		return {"ok": false, "reason": "invalid_hex_registry"}
	for method in ["is_walkable","get_stand_height_at","grid_to_world","world_to_grid_float","get_movement_distance","get_cover_at","get_tile_at_grid"]:
		if not terrain_registry.has_method(method):
			return {"ok": false, "reason": "invalid_hex_registry"}
	_clear_hex_movement_context()
	_hex_ground_runtime.configure(terrain_registry, String(map_data.call("get_map_name")), tick_counter)
	_hex_ground_registry = terrain_registry
	_hex_ground_enabled = true
	_hex_ground_context_revision += 1
	_hex_facing_pending.clear()
	_hex_facing_seen.clear()
	_hex_facing_replay_keys.clear()
	_hex_facing_replay_cursor = 0
	_last_hex_ground_events.clear()
	_hex_movement_runtime.configure(self,terrain_registry,_hex_ground_runtime)
	return {"ok": true, "enabled": true}


func _clear_hex_movement_context() -> void:
	for id in _hex_ground_runtime.get_unit_ids():_clear_hex_actor_metadata(String(id))
	_hex_movement_runtime.clear()
	_hex_visual_unit_ids.clear()
	_hex_boundary_facing.clear()
	_hex_projection_terrain_revision=-1


func _clear_hex_actor_metadata(unit_id:String) -> void:
	var actor=_resolve_known_unit_for_contract(unit_id)
	if not is_instance_valid(actor):return
	for key in ["hex_ground_stand_height_logical","hex_ground_moving","hex_ground_facing_angle"]:
		if actor.has_meta(key):actor.remove_meta(key)


func get_hex_movement_readout(unit_id:String) -> Dictionary:
	return _hex_movement_runtime.get_readout(unit_id) if is_hex_ground_runtime_active() else {}


func get_hex_movement_audit_snapshot() -> Dictionary:
	return _hex_movement_runtime.get_audit() if is_hex_ground_runtime_active() else {}


func has_hex_destination_arrived(unit_id:String,command_id:String) -> bool:
	return is_hex_ground_runtime_active() and _hex_movement_runtime.has_arrived(unit_id,command_id)


func get_hex_logical_unit_position(unit_id:String) -> Variant:
	var state:Dictionary=get_hex_unit_state(unit_id)
	return _hex_ground_registry.call("grid_to_world",state.grid) if not state.is_empty() else null


func has_hex_position_arrived(unit_id:String,target_position:Vector2,command_id:String) -> bool:
	if not is_hex_ground_runtime_active() or not target_position.is_finite() or command_id.is_empty():return false
	var state:Dictionary=get_hex_unit_state(unit_id)
	if state.is_empty() or state.movement_state.moving or state.route_state.has_commitments:return false
	var target_grid:Vector2i=_hex_ground_registry.call("world_to_grid",target_position)
	if state.grid!=target_grid:return false
	var order:Dictionary=get_hex_movement_readout(unit_id)
	if not order.is_empty() and order.goal_grid==target_grid and has_hex_destination_arrived(unit_id,command_id):return true
	# Covering members receive an explicit Hold for this stage, not a Move goal.
	var actor=_resolve_known_unit_for_contract(unit_id)
	if not is_instance_valid(actor) or not actor.has_method("get_current_unit_command"):return false
	var command=actor.call("get_current_unit_command")
	if command==null or String(command.command_type)!="hold_position" or String(command.command_token)!=command_id:return false
	var command_target:Variant=command.target_position
	return typeof(command_target)==TYPE_VECTOR2 and Vector2(command_target).is_finite() and _hex_ground_registry.call("world_to_grid",Vector2(command_target))==target_grid


func _commit_hex_movement_facing(unit_id:String,direction:int) -> void:
	if direction<0 or direction>5 or not is_hex_ground_runtime_active():return
	_hex_ground_runtime.commit_facing(unit_id,direction)
	_hex_boundary_facing[unit_id]=true


func _project_hex_ground_actors(fraction:float) -> void:
	if not is_hex_ground_runtime_active():return
	for id in _hex_visual_unit_ids.keys():
		var actor=_resolve_known_unit_for_contract(id)
		if not is_instance_valid(actor) or not actor is Node2D or not _hex_ground_runtime.has_unit(id):
			_hex_visual_unit_ids.erase(id)
			continue
		var projection:Dictionary=get_hex_motion_projection(id,fraction)
		if projection.is_empty():continue
		(actor as Node2D).global_position=projection.position_world
		actor.set_meta("facing_angle",projection.facing_angle)
		actor.set_meta("map_facing_angle",projection.facing_angle)
		actor.set_meta("hex_ground_stand_height_logical",projection.stand_height_logical)
		actor.set_meta("hex_ground_moving",projection.moving)
		actor.set_meta("hex_ground_facing_angle",projection.facing_angle)
		if not _hex_ground_runtime.has_motion_commitments(id):_hex_visual_unit_ids.erase(id)


func is_hex_ground_runtime_active() -> bool:
	return _hex_ground_enabled and is_instance_valid(_hex_ground_registry)


func get_hex_ground_terrain_registry() -> Node:
	return _hex_ground_registry if is_hex_ground_runtime_active() else null


func get_hex_ground_context_revision() -> int:
	return _hex_ground_context_revision


func get_hex_combat_geometry(attacker_id: String, target_id: String) -> Dictionary:
	if not is_hex_ground_runtime_active():
		return {"handled":false}
	var source := get_hex_unit_state(attacker_id)
	var destination := get_hex_unit_state(target_id)
	if source.is_empty() or destination.is_empty():
		return {"handled":true,"valid":false,"distance_world":-1.0,"target_cover_score":-1}
	var origin: Vector2 = _hex_ground_registry.call("grid_to_world",Vector2i.ZERO)
	var neighbor: Vector2 = _hex_ground_registry.call("grid_to_world",Vector2i(1,0))
	var spacing: float = _hex_ground_registry.call("get_movement_distance",origin,neighbor)
	var target = _resolve_known_unit_for_contract(target_id)
	return {"handled":true,"valid":true,
		"distance_world":float(HEX_GRID_SCRIPT.distance(source.grid,destination.grid))*spacing,
		"target_cover_score":roundi(_extract_effective_cover_score(target))}


func get_hex_unit_state(unit_id: String) -> Dictionary:
	return _hex_ground_runtime.read_unit(unit_id) if is_hex_ground_runtime_active() else {}


func get_hex_motion_projection(unit_id: String, interpolation_fraction: float, height_step_world: float = 1.0) -> Dictionary:
	return _hex_ground_runtime.get_motion_projection(unit_id,interpolation_fraction,height_step_world) if is_hex_ground_runtime_active() else {}


func get_hex_ground_planning_snapshot() -> Dictionary:
	if not is_hex_ground_runtime_active():
		return {}
	var snapshot: Dictionary = _hex_ground_runtime.build_planning_snapshot()
	snapshot["current_tick"] = tick_counter
	return snapshot


func commit_hex_ground_plan(plan: Dictionary, expected_revision: int) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():
		return {"ok":false,"reason":"hex_ground_inactive"}
	if int(_hex_ground_runtime.get_current_tick()) != tick_counter:
		return {"ok":false,"reason":"hex_clock_unsynced"}
	var result:Dictionary=_hex_ground_runtime.commit_plan(plan,expected_revision)
	if result.ok:
		for segment in plan.accepted_steps:_hex_visual_unit_ids[segment.unit_id]=true
	return result


func get_hex_ground_events() -> Array[Dictionary]:
	return _last_hex_ground_events.duplicate(true)


func stop_hex_ground_units(unit_ids: PackedStringArray, reason: String) -> Dictionary:
	if _should_skip_local_tick_processing():return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_inactive"}
	if int(_hex_ground_runtime.get_current_tick())!=tick_counter:return {"ok":false,"reason":"hex_clock_unsynced"}
	var result:Dictionary=_hex_ground_runtime.stop_units(unit_ids,reason)
	if result.ok:
		_hex_movement_runtime.mark_external_stop(unit_ids,reason)
		for id in result.affected_unit_ids:_hex_visual_unit_ids[id]=true
	if result.ok and not result.events.is_empty():
		_last_hex_ground_events.append_array(result.events)
		_hex_movement_runtime.notify_ground_events(result.events)
		hex_ground_events_committed.emit(result.events.duplicate(true))
	return result


func _advance_hex_ground_tick() -> void:
	_last_hex_ground_events.clear()
	if not is_hex_ground_runtime_active():return
	_last_hex_ground_events = _hex_ground_runtime.advance_tick(tick_counter)
	_hex_movement_runtime.notify_ground_events(_last_hex_ground_events)
	var revision:int=_hex_ground_registry.call("get_revision")
	if _hex_projection_terrain_revision!=revision:
		for id in _hex_ground_runtime.get_unit_ids():_hex_visual_unit_ids[id]=true
		_hex_projection_terrain_revision=revision
	if not _last_hex_ground_events.is_empty():
		hex_ground_events_committed.emit(_last_hex_ground_events.duplicate(true))


## Internal runtime admission boundary; lifecycle adapters choose placements.
func admit_hex_ground_units(placements: Array[Dictionary]) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok": false, "reason": "not_authority"}
	if not is_hex_ground_runtime_active():
		return {"ok": false, "reason": "hex_ground_inactive"}
	var result:Dictionary=_hex_ground_runtime.admit_units(placements)
	if result.ok:
		for id in result.admitted_unit_ids:_hex_visual_unit_ids[id]=true
		_project_hex_ground_actors(0.0)
	return result


func release_hex_ground_unit(unit_id: String, reason: String) -> void:
	if _should_skip_local_tick_processing():
		return
	_clear_hex_actor_metadata(unit_id)
	_hex_visual_unit_ids.erase(unit_id)
	_hex_movement_runtime.release_unit(unit_id)
	_hex_ground_runtime.release_unit(unit_id, reason)
	_hex_facing_pending.erase(unit_id)


## Internal runtime intents, never accepted as client/UI-provided facing state.
## A delayed reaction can specify its already skill-derived ready tick.
func queue_hex_facing_intent(unit_id: String, direction: int, command_id: String, reason: String, ready_tick: int = -1) -> Dictionary:
	if _should_skip_local_tick_processing():
		return {"ok":false,"reason":"not_authority"}
	if not is_hex_ground_runtime_active() or get_hex_unit_state(unit_id).is_empty():
		return {"ok":false,"reason":"hex_unit_unavailable"}
	if direction < 0 or direction > 5 or command_id.strip_edges().is_empty() or not HEX_FACING_PRIORITIES.has(reason):
		return {"ok":false,"reason":"invalid_facing_intent"}
	if tick_counter < 0 or tick_counter == 9223372036854775807 or ready_tick < -1:
		return {"ok":false,"reason":"invalid_facing_tick"}
	var unit = _resolve_known_unit_for_contract(unit_id)
	if not is_instance_valid(unit):
		return {"ok":false,"reason":"runtime_unit_unavailable"}
	var order := _get_hex_facing_order(unit)
	if reason in ["noise_reaction","combat_reaction"]:
		var command_type := String(order.get("command_type",""))
		var source_type := String(order.get("source_command_type",""))
		if command_type in ["hold_position","retreat","seek_cover"] or source_type in ["defend","take","retreat"] or (command_type == "move_to_position" and source_type not in ["engage","flank"]):
			return {"ok":false,"reason":"assignment_locks_facing"}
	var replay_key := JSON.stringify([unit_id,command_id])
	if _hex_facing_seen.has(replay_key):
		return {"ok":true,"replayed":true}
	var order_key := JSON.stringify(order)
	var previous: Dictionary = _hex_facing_pending.get(unit_id,{})
	if not previous.is_empty() and String(previous.get("order_key","")) == order_key and int(previous.get("priority",0)) > int(HEX_FACING_PRIORITIES[reason]):
		return {"ok":false,"reason":"higher_priority_facing_pending"}
	if _hex_facing_replay_keys.size() < HEX_FACING_REPLAY_CAPACITY:
		_hex_facing_replay_keys.append(replay_key)
	else:
		_hex_facing_seen.erase(_hex_facing_replay_keys[_hex_facing_replay_cursor])
		_hex_facing_replay_keys[_hex_facing_replay_cursor] = replay_key
		_hex_facing_replay_cursor = (_hex_facing_replay_cursor+1) % HEX_FACING_REPLAY_CAPACITY
	_hex_facing_seen[replay_key] = true
	var resolved_ready := maxi(ready_tick,tick_counter+1)
	if not previous.is_empty() and String(previous.get("order_key","")) == order_key and int(previous.get("priority",0)) == int(HEX_FACING_PRIORITIES[reason]) and int(previous.get("direction",-1)) == direction:
		resolved_ready = mini(resolved_ready,int(previous["ready_tick"]))
	_hex_facing_pending[unit_id] = {"direction":direction,"ready_tick":resolved_ready,
		"priority":HEX_FACING_PRIORITIES[reason],"order_key":order_key}
	return {"ok":true,"replayed":false}


func _get_hex_facing_order(unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.has_method("get_current_unit_command"):
		return {}
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("to_dict"):
		return {}
	var data: Dictionary = command.call("to_dict")
	var result: Dictionary = {}
	# Exclude continually derived cover/skill readouts; only the actual order
	# identity and its policy can invalidate an intent between ticks.
	for key in ["command_type","source_command_type","command_token","target_position","target_area_id","phase","fire_rule","movement_posture"]:
		result[key] = data.get(key)
	return result


func _commit_hex_facing_intents() -> void:
	if _should_skip_local_tick_processing() or not is_hex_ground_runtime_active():
		return
	var unit_ids: Array = _hex_facing_pending.keys()
	unit_ids.sort()
	for unit_id in unit_ids:
		var intent: Dictionary = _hex_facing_pending[unit_id]
		if _hex_boundary_facing.has(unit_id):continue
		if int(intent["ready_tick"]) > tick_counter:
			continue
		_hex_facing_pending.erase(unit_id)
		var unit = _resolve_known_unit_for_contract(unit_id)
		if not is_instance_valid(unit) or String(intent["order_key"]) != JSON.stringify(_get_hex_facing_order(unit)):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		if _hex_ground_runtime.commit_facing(String(unit_id),int(intent["direction"])):_hex_visual_unit_ids[unit_id]=true


func _init() -> void:
	_combat_rng.seed = int(combat_rng_seed)


func _ready() -> void:
	set_combat_rng_seed(combat_rng_seed)


func enqueue_command(cmd: Dictionary) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_command expects a Dictionary command.")
		return
	if is_hex_ground_runtime_active() and _extract_command_type(cmd) in ["move_to_position","engage_area"] and not String(cmd.get("unit_id","")).is_empty():
		var target:Variant=cmd.get("target_position")
		if not target is Vector2 or not target.is_finite():
			_record_discarded_move_command(cmd,"invalid_target_position")
			return

	var queued_command: Dictionary = cmd.duplicate(true)
	var command_token: String = String(queued_command.get("command_token", "")).strip_edges()
	var unit_id: String = String(queued_command.get("unit_id", "")).strip_edges()
	if not command_token.is_empty() and not unit_id.is_empty():
		_latest_command_token_by_unit_id[unit_id] = command_token
	if not command_token.is_empty():
		for index in range(command_queue.size()):
			var pending_command: Dictionary = Dictionary(command_queue[index])
			if String(pending_command.get("command_token", "")).strip_edges() != command_token:
				continue
			_retain_regional_navigation(pending_command, queued_command)
			command_queue[index] = queued_command
			return

	command_queue.append(queued_command)


func _retain_regional_navigation(pending: Dictionary, replacement: Dictionary) -> void:
	if not pending.has("_regional_navigation_search") and not pending.has("_regional_navigation_route"):
		return
	if pending.get("unit_id") != replacement.get("unit_id") or _extract_command_type(pending) != _extract_command_type(replacement):
		return
	if not Vector2(pending.get("target_position", Vector2.ZERO)).is_equal_approx(Vector2(replacement.get("target_position", Vector2.ZERO))):
		return
	var registry = _get_terrain_registry()
	if _build_navigation_cost_options(pending, registry) != _build_navigation_cost_options(replacement, registry):
		return
	for key in ["_regional_navigation_search", "_regional_navigation_route", "path", "navigation_resolved_target_position",
			"navigation_path_terrain_revision", "local_avoidance_repath_requested", "local_avoidance_deadlock"]:
		if pending.has(key) and not replacement.has(key):
			replacement[key] = pending[key]
		elif pending.has(key) and key == "path" and Array(replacement[key]).is_empty():
			replacement[key] = pending[key]


func enqueue_effect(effect: Dictionary) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_effect expects a Dictionary effect.")
		return

	effects_queue.append(effect)


func get_air_asset_status_snapshot(asset_id: String = "") -> Dictionary:
	var normalized_id: String = asset_id.strip_edges()
	if normalized_id.is_empty():
		var result: Dictionary = {}
		var asset_ids: Array = _air_asset_status_by_id.keys()
		asset_ids.sort()
		for id_variant in asset_ids:
			var key: String = String(id_variant)
			result[key] = Dictionary(_air_asset_status_by_id.get(key, {})).duplicate(true)
		return result
	return Dictionary(_air_asset_status_by_id.get(normalized_id, {})).duplicate(true)


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


func clear_discarded_move_command_debug() -> void:
	_last_discarded_move_command.clear()
	_discarded_move_command_count = 0
	_discarded_move_command_counts_by_reason.clear()


func get_discarded_move_command_count(reason: String = "") -> int:
	var normalized_reason: String = reason.strip_edges().to_lower()
	if normalized_reason.is_empty():
		return _discarded_move_command_count
	return int(_discarded_move_command_counts_by_reason.get(normalized_reason, 0))


func get_last_discarded_move_command() -> Dictionary:
	return _last_discarded_move_command.duplicate(true)


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
		"hpa_navigation": _get_hpa_navigation_debug_snapshot(),
	}


func _get_hpa_navigation_debug_snapshot() -> Dictionary:
	return {
		"has_graph": _hpa_navigation_graph != null,
		"cluster_size": HPA_NAVIGATION_CLUSTER_SIZE,
		"tile_count": _hpa_navigation_tile_count,
		"registry_revision": _hpa_navigation_registry_revision,
		"build_count": _hpa_navigation_build_count,
		"cache_hit_count": _hpa_navigation_cache_hit_count,
		"last_build_stats": _hpa_navigation_last_build_stats.duplicate(true),
	}


func set_runtime_tick_budget_debug_enabled(enabled: bool) -> void:
	runtime_tick_budget_debug_enabled = enabled
	if not runtime_tick_budget_debug_enabled:
		_runtime_tick_budget_debug_snapshot.clear()
		_runtime_frame_budget_debug.clear()
		_runtime_command_type_count.clear()
		_runtime_command_type_usec.clear()
		_runtime_command_requeue_count.clear()
		_runtime_command_ordering_usec = 0
		_runtime_command_apply_usec = 0


func get_runtime_tick_budget_debug_snapshot() -> Dictionary:
	return _runtime_tick_budget_debug_snapshot.duplicate(true)


func get_runtime_frame_budget_debug_snapshot(process_frame: int = -1) -> Dictionary:
	var frame_id := Engine.get_process_frames() if process_frame < 0 else process_frame
	var result: Dictionary = _runtime_frame_budget_debug.get_snapshot(frame_id)
	result["enabled"] = runtime_tick_budget_debug_enabled
	result["known_empty_current_frame"] = runtime_tick_budget_debug_enabled and frame_id == Engine.get_process_frames() and not bool(result.has_sample)
	result["read_only"] = true
	return result


func _record_runtime_tick_budget_debug_snapshot(delta: float, tick_started_usec: int, profile_scopes: Dictionary, command_count: int, effect_count: int) -> void:
	var record_started_usec := Time.get_ticks_usec()
	_runtime_tick_budget_debug_snapshot = {
		"enabled": runtime_tick_budget_debug_enabled,
		"process_frame": Engine.get_process_frames(),
		"tick": tick_counter,
		"delta": delta,
		"total_tick_usec": Time.get_ticks_usec() - tick_started_usec,
		"scopes_usec": profile_scopes.duplicate(true),
		"command_count": command_count,
		"command_type_count": _runtime_command_type_count.duplicate(true),
		"command_type_usec": _runtime_command_type_usec.duplicate(true),
		"command_requeue_count": _runtime_command_requeue_count.duplicate(true),
		"effect_count": effect_count,
		"command_queue_after_tick": command_queue.size(),
		"effect_queue_after_tick": effects_queue.size(),
		"registered_unit_count": _count_runtime_registered_units(),
		"known_unit_count": _known_units_by_id.size(),
		"navigation": get_navigation_debug_snapshot(),
		"hex_movement":get_hex_movement_audit_snapshot(),
		"unit_minimum_spacing": get_unit_minimum_spacing_debug_snapshot(),
		"hotpath_audit": {
			"authority_root": "SimulationRoot",
			"command_queue_scope": "drain_order_apply",
			"effect_queue_scope": "drain_order_apply",
			"unit_lookup_source": "UnitRegistry_or_known_units",
			"viewer_paths_read_only": true,
		},
	}
	var record_usec := Time.get_ticks_usec() - record_started_usec
	_runtime_tick_budget_debug_snapshot["debug_record_usec"] = record_usec
	var frame_scopes: Dictionary = profile_scopes.duplicate()
	frame_scopes["debug_record_usec"] = record_usec
	_runtime_frame_budget_debug.record_sample(Engine.get_process_frames(), Time.get_ticks_usec() - tick_started_usec, frame_scopes, tick_counter)


func _count_runtime_registered_units() -> int:
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		return Array(unit_registry.call("get_all_units")).size()
	return _known_units_by_id.size()


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


func set_bottleneck_reservation_enabled(enabled: bool) -> void:
	bottleneck_reservation_enabled = enabled
	if not bottleneck_reservation_enabled:
		_bottleneck_reservation_resolver.clear()
		_bottleneck_reservation_debug_snapshot.clear()


func set_bottleneck_reservation_debug_enabled(enabled: bool) -> void:
	bottleneck_reservation_debug_enabled = enabled
	if not bottleneck_reservation_debug_enabled:
		_bottleneck_reservation_debug_snapshot.clear()


func get_bottleneck_reservation_debug_snapshot() -> Dictionary:
	return _bottleneck_reservation_debug_snapshot.duplicate(true)


func resolve_bottleneck_reservation_for_commands(commands: Array, candidates: Array, options: Dictionary = {}) -> Dictionary:
	if is_hex_ground_runtime_active():return {}
	if not bottleneck_reservation_enabled:
		return {}
	var plan_options: Dictionary = options.duplicate(true)
	if not plan_options.has("start_tick"):
		plan_options["start_tick"] = tick_counter
	if not plan_options.has("horizon_ticks"):
		plan_options["horizon_ticks"] = bottleneck_reservation_horizon_ticks
	var plan: Dictionary = Dictionary(_bottleneck_reservation_resolver.call("build_reservation_plan", commands, candidates, plan_options))
	var decisions_by_unit_id: Dictionary = Dictionary(plan.get("decisions_by_unit_id", {}))
	for command_variant in commands:
		if typeof(command_variant) != TYPE_DICTIONARY:
			continue
		var command: Dictionary = Dictionary(command_variant)
		var unit_id: String = String(command.get("unit_id", ""))
		if decisions_by_unit_id.has(unit_id):
			_bottleneck_reservation_resolver.call("apply_reservation_metadata", command, Dictionary(decisions_by_unit_id.get(unit_id, {})))
	if bottleneck_reservation_debug_enabled:
		_bottleneck_reservation_debug_snapshot = plan.duplicate(true)
	return plan


func resolve_bottleneck_reservation_for_command(command: Dictionary, bottleneck_cells: Array, current_tick: int = -1, options: Dictionary = {}) -> Dictionary:
	if is_hex_ground_runtime_active():return {}
	if not bottleneck_reservation_enabled:
		return {}
	var plan_options: Dictionary = options.duplicate(true)
	if not plan_options.has("horizon_ticks"):
		plan_options["horizon_ticks"] = bottleneck_reservation_horizon_ticks
	var resolved_tick: int = tick_counter if current_tick < 0 else current_tick
	var decision: Dictionary = Dictionary(_bottleneck_reservation_resolver.call("resolve_command", command, bottleneck_cells, resolved_tick, plan_options))
	if bottleneck_reservation_debug_enabled:
		_bottleneck_reservation_debug_snapshot = _bottleneck_reservation_resolver.call("get_debug_snapshot")
	return decision


func set_unit_minimum_spacing_enabled(enabled: bool) -> void:
	unit_minimum_spacing_enabled = enabled
	if not unit_minimum_spacing_enabled:
		_unit_minimum_spacing_debug_snapshot.clear()


func get_unit_minimum_spacing_debug_snapshot() -> Dictionary:
	return _unit_minimum_spacing_debug_snapshot.duplicate(true)


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


func get_last_damage_effect_resolution() -> Dictionary:
	return _last_damage_effect_resolution.duplicate(true)


func register_known_unit(unit_id: String, unit: Node) -> bool:
	if unit_id.is_empty() or unit == null:
		return false

	_known_units_by_id[unit_id] = unit
	if is_hex_ground_runtime_active() and _hex_ground_runtime.has_unit(unit_id):
		_hex_visual_unit_ids[unit_id]=true
		_project_hex_ground_actors(0.0)
	return true


func unregister_known_unit(unit_id: String) -> void:
	_discard_pending_move_commands_for_unit(unit_id)
	_known_units_by_id.erase(unit_id)
	_latest_command_token_by_unit_id.erase(unit_id)
	_committed_command_token_by_unit_id.erase(unit_id)
	_contact_path_recompute_ready_at_msec.erase(unit_id)


func set_peer_team(peer_id: int, team_id: String) -> void:
	if peer_id <= 0:
		return

	var normalized_team_id: String = team_id.strip_edges()
	if normalized_team_id.is_empty():
		_peer_team_assignments.erase(peer_id)
		return

	_peer_team_assignments[peer_id] = normalized_team_id
	if not _peer_role_assignments.has(peer_id):
		_peer_role_assignments[peer_id] = "commander"


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
	if not _peer_role_assignments.has(1):
		_peer_role_assignments[1] = "commander"


func get_peer_team(peer_id: int) -> String:
	if peer_id <= 0:
		return ""

	return String(_peer_team_assignments.get(peer_id, ""))


func set_peer_role(peer_id: int, role_id: String) -> void:
	if peer_id <= 0:
		return
	var normalized_role_id: String = role_id.strip_edges().to_lower()
	if normalized_role_id.is_empty():
		_peer_role_assignments.erase(peer_id)
		return
	if not MULTIPLAYER_COMMAND_CONTRACT_SCRIPT.call("is_allowed_role", normalized_role_id):
		push_warning("SimulationRoot rejected an unknown multiplayer peer role.")
		return
	_peer_role_assignments[peer_id] = normalized_role_id


func set_peer_role_assignments(assignments: Dictionary) -> void:
	_peer_role_assignments.clear()
	for raw_peer_id in assignments.keys():
		set_peer_role(int(raw_peer_id), String(assignments[raw_peer_id]))
	if not _peer_role_assignments.has(1):
		_peer_role_assignments[1] = "commander"


func get_peer_role(peer_id: int) -> String:
	if peer_id <= 0:
		return ""
	return String(_peer_role_assignments.get(peer_id, "commander"))


func set_peer_fireteams(peer_id: int, fireteam_ids: Variant) -> void:
	if peer_id <= 0:
		return
	var normalized_fireteam_ids: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in Array(fireteam_ids):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or normalized_fireteam_ids.has(fireteam_id):
			continue
		normalized_fireteam_ids.append(fireteam_id)
	if normalized_fireteam_ids.is_empty():
		_peer_fireteam_assignments.erase(peer_id)
		return
	_peer_fireteam_assignments[peer_id] = normalized_fireteam_ids


func set_peer_fireteam_assignments(assignments: Dictionary) -> void:
	_peer_fireteam_assignments.clear()
	for raw_peer_id in assignments.keys():
		set_peer_fireteams(int(raw_peer_id), assignments[raw_peer_id])


func get_peer_fireteams(peer_id: int) -> PackedStringArray:
	if peer_id <= 0:
		return PackedStringArray()
	return PackedStringArray(_peer_fireteam_assignments.get(peer_id, PackedStringArray()))


func get_network_command_contract_snapshot() -> Dictionary:
	return {
		"accepted_count": _network_command_accept_count,
		"rejected_count": _network_command_reject_count,
		"last_rejection": _last_network_command_rejection.duplicate(true),
		"peer_teams": _peer_team_assignments.duplicate(true),
		"peer_roles": _peer_role_assignments.duplicate(true),
		"peer_fireteams": _duplicate_peer_fireteam_assignments(),
	}


func get_last_server_state() -> Dictionary:
	return _last_server_state.duplicate(true)


func get_last_network_command_result() -> Dictionary:
	return _last_network_command_result.duplicate(true)


func set_network_command_preflight_validator(validator: Callable) -> void:
	_network_command_preflight_validator = validator


func clear_network_command_preflight_validator(validator: Callable = Callable()) -> void:
	if not validator.is_valid() or _network_command_preflight_validator == validator:
		_network_command_preflight_validator = Callable()


func get_authoritative_fire_rule_state(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _authoritative_fire_rules_by_fireteam.has(normalized_fireteam_id):
		return {}
	return Dictionary(_authoritative_fire_rules_by_fireteam[normalized_fireteam_id]).duplicate(true)


func get_authoritative_fire_rule_snapshot() -> Array:
	var fireteam_ids: Array = _authoritative_fire_rules_by_fireteam.keys()
	fireteam_ids.sort()
	var result: Array = []
	for fireteam_id_variant in fireteam_ids:
		result.append(Dictionary(_authoritative_fire_rules_by_fireteam[fireteam_id_variant]).duplicate(true))
	return result


func set_multiplayer_snapshot_context(context: Dictionary) -> void:
	var normalized_context: Dictionary = Dictionary(_multiplayer_snapshot_contract.call("normalize_display_context", context))
	var next_context: Dictionary = _multiplayer_snapshot_context.duplicate(true)
	if context.has("dropship"):
		next_context["dropship"] = Dictionary(normalized_context.get("dropship", {})).duplicate(true)
	if context.has("contacts"):
		next_context["contacts"] = Array(normalized_context.get("contacts", [])).duplicate(true)
	if context.has("enemy_security"):
		next_context["enemy_security"] = Array(normalized_context.get("enemy_security", [])).duplicate(true)
	if context.has("enemy_team_tactics"):
		next_context["enemy_team_tactics"] = Array(normalized_context.get("enemy_team_tactics", [])).duplicate(true)
	if context.has("character_gameplay"):
		next_context["character_gameplay"] = Array(normalized_context.get("character_gameplay", [])).duplicate(true)
	if context.has("fire_events"):
		next_context["fire_events"] = Array(normalized_context.get("fire_events", [])).duplicate(true)
	if context.has("feedback_bubbles"):
		next_context["feedback_bubbles"] = Array(normalized_context.get("feedback_bubbles", [])).duplicate(true)
	if context.has("fireteam_tactical"):
		next_context["fireteam_tactical"] = Array(normalized_context.get("fireteam_tactical", [])).duplicate(true)
	if context.has("commander_intents"):
		next_context["commander_intents"] = Array(normalized_context.get("commander_intents", [])).duplicate(true)
	if context.has("fireteam_plan_status"):
		next_context["fireteam_plan_status"] = Array(normalized_context.get("fireteam_plan_status", [])).duplicate(true)
	if context.has("communication_events"):
		next_context["communication_events"] = Array(normalized_context.get("communication_events", [])).duplicate(true)
	if context.has("tactical_rules"):
		next_context["tactical_rules"] = Array(normalized_context.get("tactical_rules", [])).duplicate(true)
	if context.has("breakout_states"):
		next_context["breakout_states"] = Array(normalized_context.get("breakout_states", [])).duplicate(true)
	if context.has("air_asset_status") or context.has("air_asset_statuses"):
		next_context["air_asset_status"] = Array(normalized_context.get("air_asset_status", [])).duplicate(true)
	if context.has("mission_interactions"):
		next_context["mission_interactions"] = Dictionary(normalized_context.get("mission_interactions", {})).duplicate(true)
	if context.has("mission_result"):
		next_context["mission_result"] = Dictionary(normalized_context.get("mission_result", {})).duplicate(true)
	_multiplayer_snapshot_context = next_context


func clear_multiplayer_snapshot_context() -> void:
	_multiplayer_snapshot_context.clear()


func get_multiplayer_snapshot_debug_snapshot() -> Dictionary:
	return {
		"last_applied_tick": _last_applied_snapshot_tick,
		"apply_count": _snapshot_apply_count,
		"out_of_order_count": _snapshot_out_of_order_count,
		"missing_unit_count": _snapshot_missing_unit_count,
		"last_reject_reason": _last_snapshot_reject_reason,
		"audio": get_snapshot_audio_debug_snapshot(),
		"transfer_contract": Dictionary(_multiplayer_snapshot_contract.call("get_transfer_contract")).duplicate(true),
	}


func get_snapshot_transport_debug_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.snapshot_chunk_transport_debug.v1",
		"chunk_payload_budget_bytes": SNAPSHOT_CHUNK_PAYLOAD_BYTES,
		"last_chunk_count": _snapshot_transport_last_chunk_count,
		"last_max_chunk_payload_bytes": _snapshot_transport_last_max_chunk_payload_bytes,
		"last_raw_bytes": _snapshot_transport_last_raw_bytes,
		"last_wire_bytes": _snapshot_transport_last_wire_bytes,
		"reassembled_snapshot_count": _snapshot_transport_reassembled_count,
		"reassembly_failure_count": _snapshot_transport_reassembly_failure_count,
		"last_pack_usec": _snapshot_transport_last_pack_usec,
		"last_reassembly_usec": _snapshot_transport_last_reassembly_usec,
		"pending_tick_count": _incoming_snapshot_chunks_by_tick.size(),
		"max_pending_tick_count": SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS,
		"reassembly_timeout_msec": SNAPSHOT_REASSEMBLY_TIMEOUT_MSEC,
		"expired_tick_count": _snapshot_transport_expired_tick_count,
		"evicted_tick_count": _snapshot_transport_evicted_tick_count,
		"stale_chunk_count": _snapshot_transport_stale_chunk_count,
		"broadcast_paused": _snapshot_broadcast_paused,
		"blocked_peer_ids": _snapshot_blocked_peer_ids.keys(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func set_snapshot_broadcast_paused(paused: bool) -> void:
	_snapshot_broadcast_paused = paused


func set_snapshot_peer_blocked(peer_id: int, blocked: bool) -> void:
	if peer_id <= 1:
		return
	if blocked:
		_snapshot_blocked_peer_ids[peer_id] = true
	else:
		_snapshot_blocked_peer_ids.erase(peer_id)


func get_snapshot_audio_debug_snapshot() -> Dictionary:
	return {
		"played_count": _snapshot_audio_played_count,
		"suppressed_count": _snapshot_audio_suppressed_count,
		"played_event_ids": _snapshot_audio_event_ids_played.keys(),
		"last_result": _last_snapshot_audio_result.duplicate(true),
		"read_only_audio_events": true,
		"audio_sets_gameplay_state": false,
	}


func build_multiplayer_snapshot() -> Dictionary:
	return _build_tick_state()


func apply_multiplayer_snapshot(snapshot: Dictionary) -> Dictionary:
	return _apply_remote_state(snapshot)


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
		_record_network_command_rejection(
			{
				"accepted": false,
				"reason": "request_on_non_authority",
			},
			command_dict,
			multiplayer.get_unique_id()
		)
		push_warning("SimulationRoot.request_command can only be executed on the authority while server-authoritative mode is active.")
		return

	var sending_peer_id: int = multiplayer.get_remote_sender_id()
	if sending_peer_id <= 0:
		sending_peer_id = 1

	var result: Dictionary = submit_network_command_for_peer(command_dict, sending_peer_id)
	_send_network_command_result(sending_peer_id, result, command_dict)
	if not bool(result.get("accepted", false)):
		push_warning("SimulationRoot rejected a network command: %s." % String(result.get("reason", "unknown")))
		return


@rpc("authority", "reliable")
func _receive_network_command_result(result: Dictionary) -> void:
	_last_network_command_result = result.duplicate(true)
	network_command_result_received.emit(_last_network_command_result.duplicate(true))


func _send_network_command_result(peer_id: int, result: Dictionary, command: Dictionary) -> void:
	var payload: Dictionary = {
		"schema": "sternenbuergerchen.network_command_result.v1",
		"accepted": bool(result.get("accepted", false)),
		"reason": String(result.get("reason", "")).strip_edges(),
		"category": String(result.get("category", command.get("contract_category", ""))).strip_edges().to_lower(),
		"command_type": String(result.get("command_type", command.get("command_type", ""))).strip_edges().to_lower(),
		"team_id": String(result.get("team_id", command.get("team_id", ""))).strip_edges(),
		"fireteam_id": String(result.get("fireteam_id", command.get("fireteam_id", ""))).strip_edges().to_lower(),
		"craft_id": String(command.get("craft_id", "")).strip_edges(),
		"command_id": String(command.get("command_id", "")).strip_edges(),
		"duplicate": bool(result.get("duplicate", false)),
		"fire_rule": String(command.get("fire_rule", "")).strip_edges().to_lower(),
		"source_context": String(command.get("source_context", "")).strip_edges(),
		"interaction_id": String(command.get("interaction_id", "")).strip_edges(),
		"peer_id": peer_id,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	if _has_active_multiplayer_peer() and multiplayer.is_server() and peer_id > 1:
		_receive_network_command_result.rpc_id(peer_id, payload)
		return
	_receive_network_command_result(payload)


func validate_network_command_for_peer(command_dict: Dictionary, peer_id: int = 1) -> Dictionary:
	if typeof(command_dict) != TYPE_DICTIONARY:
		return {
			"accepted": false,
			"reason": "command_not_dictionary",
		}
	var validation: Dictionary = Dictionary(_multiplayer_command_contract.call("validate", command_dict, _build_network_command_context(command_dict, peer_id))).duplicate(true)
	if not bool(validation.get("accepted", false)) or not _network_command_preflight_validator.is_valid():
		return validation
	var accepted_command: Dictionary = Dictionary(validation.get("command", command_dict)).duplicate(true)
	var preflight_variant: Variant = _network_command_preflight_validator.call(accepted_command, peer_id)
	if typeof(preflight_variant) != TYPE_DICTIONARY:
		return validation
	var preflight: Dictionary = Dictionary(preflight_variant)
	if bool(preflight.get("accepted", true)):
		if typeof(preflight.get("command", null)) == TYPE_DICTIONARY:
			var canonical_command: Dictionary = Dictionary(preflight.get("command", {})).duplicate(true)
			validation["command"] = canonical_command
			for result_key in ["category", "command_type", "team_id", "fireteam_id"]:
				var command_key: String = "contract_category" if result_key == "category" else result_key
				if canonical_command.has(command_key):
					validation[result_key] = canonical_command[command_key]
		return validation
	validation["accepted"] = false
	validation["reason"] = String(preflight.get("reason", "network_command_preflight_rejected")).strip_edges()
	return validation


func submit_network_command_for_peer(command_dict: Dictionary, peer_id: int = 1) -> Dictionary:
	if not is_server_authoritative:
		enqueue_command(command_dict)
		return {
			"accepted": true,
			"reason": "",
			"peer_id": peer_id,
			"command": command_dict.duplicate(true),
		}

	var sending_peer_id: int = peer_id if peer_id > 0 else 1
	var validation: Dictionary = validate_network_command_for_peer(command_dict, sending_peer_id)
	if not bool(validation.get("accepted", false)):
		_record_network_command_rejection(validation, command_dict, sending_peer_id)
		return validation

	var accepted_command: Dictionary = Dictionary(validation.get("command", command_dict)).duplicate(true)
	var command_id: String = String(accepted_command.get("command_id", "")).strip_edges()
	if String(validation.get("category", "")).strip_edges() == "dropship_command" and not command_id.is_empty():
		if _accepted_network_dropship_command_ids.has(command_id):
			_network_command_dedupe_hit_count += 1
			validation["duplicate"] = true
			validation["command"] = accepted_command
			return validation
		_register_accepted_network_dropship_command_id(command_id)
	_network_command_accept_count += 1
	enqueue_command(accepted_command)
	network_command_accepted.emit(accepted_command.duplicate(true), sending_peer_id)
	return validation


func _register_accepted_network_dropship_command_id(command_id: String) -> void:
	var normalized_command_id: String = command_id.strip_edges()
	if normalized_command_id.is_empty() or _accepted_network_dropship_command_ids.has(normalized_command_id):
		return
	_accepted_network_dropship_command_ids[normalized_command_id] = true
	_accepted_network_dropship_command_id_order.append(normalized_command_id)
	while _accepted_network_dropship_command_id_order.size() > NETWORK_COMMAND_DEDUPE_MAX_IDS:
		var expired_command_id: String = String(_accepted_network_dropship_command_id_order.pop_front())
		_accepted_network_dropship_command_ids.erase(expired_command_id)


func get_network_command_dedupe_debug_snapshot() -> Dictionary:
	return {
		"cached_id_count": _accepted_network_dropship_command_ids.size(),
		"max_cached_ids": NETWORK_COMMAND_DEDUPE_MAX_IDS,
		"dedupe_hit_count": _network_command_dedupe_hit_count,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


@rpc("authority", "unreliable_ordered")
func _receive_tick_state(state_dict: Dictionary) -> void:
	_apply_remote_state(state_dict)


@rpc("authority", "unreliable")
func _receive_tick_state_chunk(tick: int, chunk_index: int, chunk_count: int, raw_size: int, compressed: bool, chunk: PackedByteArray) -> void:
	if tick < 0 or chunk_count <= 0 or chunk_count > SNAPSHOT_MAX_CHUNK_COUNT or chunk_index < 0 or chunk_index >= chunk_count or raw_size <= 0 or raw_size > SNAPSHOT_MAX_RAW_BYTES:
		_snapshot_transport_reassembly_failure_count += 1
		return
	if chunk.size() > SNAPSHOT_CHUNK_PAYLOAD_BYTES:
		_snapshot_transport_reassembly_failure_count += 1
		return
	if tick <= _last_applied_snapshot_tick:
		_snapshot_transport_stale_chunk_count += 1
		return
	_prune_incoming_snapshot_chunks(tick)
	var entry: Dictionary = Dictionary(_incoming_snapshot_chunks_by_tick.get(tick, {}))
	if not entry.is_empty() and (int(entry.get("chunk_count", -1)) != chunk_count or int(entry.get("raw_size", -1)) != raw_size or bool(entry.get("compressed", false)) != compressed):
		_snapshot_transport_reassembly_failure_count += 1
		return
	if entry.is_empty():
		entry = {
			"first_received_msec": Time.get_ticks_msec(),
			"chunk_count": chunk_count,
			"raw_size": raw_size,
			"compressed": compressed,
			"chunks": {},
		}
	var chunks: Dictionary = Dictionary(entry.get("chunks", {}))
	chunks[chunk_index] = chunk.duplicate()
	entry["chunks"] = chunks
	_incoming_snapshot_chunks_by_tick[tick] = entry
	_prune_incoming_snapshot_chunks(tick)
	if not _incoming_snapshot_chunks_by_tick.has(tick):
		return
	if chunks.size() < chunk_count:
		return
	var reassembly_started_usec: int = Time.get_ticks_usec()
	var wire_bytes := PackedByteArray()
	for index in range(chunk_count):
		if not chunks.has(index):
			_snapshot_transport_reassembly_failure_count += 1
			return
		wire_bytes.append_array(PackedByteArray(chunks[index]))
	_incoming_snapshot_chunks_by_tick.erase(tick)
	var raw_bytes: PackedByteArray = wire_bytes.decompress(raw_size, SNAPSHOT_COMPRESSION_MODE) if compressed else wire_bytes
	if raw_bytes.size() != raw_size:
		_snapshot_transport_reassembly_failure_count += 1
		return
	var decoded: Variant = bytes_to_var(raw_bytes)
	if typeof(decoded) != TYPE_DICTIONARY:
		_snapshot_transport_reassembly_failure_count += 1
		return
	if int(decoded.get("tick", -1)) != tick:
		_snapshot_transport_reassembly_failure_count += 1
		return
	_snapshot_transport_reassembled_count += 1
	_apply_remote_state(Dictionary(decoded))
	_prune_incoming_snapshot_chunks(tick)
	_snapshot_transport_last_reassembly_usec = Time.get_ticks_usec() - reassembly_started_usec


func _prune_incoming_snapshot_chunks(_latest_tick: int) -> void:
	var now_msec: int = Time.get_ticks_msec()
	for tick_variant in _incoming_snapshot_chunks_by_tick.keys():
		var entry: Dictionary = _incoming_snapshot_chunks_by_tick[tick_variant]
		if int(tick_variant) <= _last_applied_snapshot_tick:
			_incoming_snapshot_chunks_by_tick.erase(tick_variant)
		elif now_msec - int(entry.get("first_received_msec", now_msec)) >= SNAPSHOT_REASSEMBLY_TIMEOUT_MSEC:
			_incoming_snapshot_chunks_by_tick.erase(tick_variant)
			_snapshot_transport_expired_tick_count += 1
	if _incoming_snapshot_chunks_by_tick.size() > SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS:
		var pending_ticks: Array = _incoming_snapshot_chunks_by_tick.keys()
		pending_ticks.sort()
		while _incoming_snapshot_chunks_by_tick.size() > SNAPSHOT_REASSEMBLY_MAX_PENDING_TICKS:
			_incoming_snapshot_chunks_by_tick.erase(pending_ticks.pop_front())
			_snapshot_transport_evicted_tick_count += 1


@rpc("authority", "reliable")
func _receive_vital_state_updates(vital_updates: Array) -> void:
	for vital_update in vital_updates:
		if typeof(vital_update) != TYPE_DICTIONARY:
			continue

		var unit_id: String = String(vital_update.get("unit_id", "")).strip_edges()
		var unit = _resolve_known_unit(unit_id)
		if unit == null or not unit.has_method("apply_remote_vital_update"):
			continue
		if not _accept_remote_vital_tick(unit_id, vital_update):
			continue

		unit.call("apply_remote_vital_update", vital_update)


func _has_remote_vital_fields(payload: Dictionary) -> bool:
	return payload.has("vital_state") or payload.has("health") or payload.has("bleedout_ticks")


func _accept_remote_vital_tick(unit_id: String, payload: Dictionary, snapshot_tick: int = -1) -> bool:
	if not _has_remote_vital_fields(payload):
		return false
	var previous_tick: int = int(_last_applied_vital_tick_by_unit_id.get(unit_id, -1))
	var vital_tick: int = int(payload.get("vital_tick", snapshot_tick))
	if vital_tick < 0:
		# Legacy reliable data is usable only before this unit has ordered state.
		return previous_tick < 0
	if vital_tick <= previous_tick:
		return false
	_last_applied_vital_tick_by_unit_id[unit_id] = vital_tick
	return true


func _copy_current_remote_vitals(unit, payload: Dictionary) -> void:
	var current_vitals: Dictionary = _build_unit_vital_update(unit)
	if current_vitals.is_empty():
		for key in ["vital_state", "health", "bleedout_ticks", "vital_tick"]:
			payload.erase(key)
		return
	payload.merge(current_vitals, true)
	payload["vital_tick"] = int(_last_applied_vital_tick_by_unit_id.get(String(current_vitals["unit_id"]), -1))


func _process(_delta: float) -> void:
	_project_hex_ground_actors(Engine.get_physics_interpolation_fraction())
	# A stopped packet stream must not retain incomplete buffers indefinitely.
	if _incoming_snapshot_chunks_by_tick.is_empty():
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _snapshot_transport_next_prune_msec:
		return
	_snapshot_transport_next_prune_msec = now_msec + 250
	_prune_incoming_snapshot_chunks(-1)


# Commands are committed before effects on every authoritative physics tick.
func _physics_process(delta: float) -> void:
	if _should_skip_local_tick_processing():
		return

	_last_tick_delta = maxf(delta, 0.0)
	var profile_enabled: bool = runtime_tick_budget_debug_enabled
	var tick_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var profile_scopes: Dictionary = {}
	var scope_started_usec: int = 0

	tick_counter += 1
	is_processing_tick = true
	_hex_boundary_facing.clear()
	_begin_navigation_budget_tick()
	_advance_hex_ground_tick()
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_prepare_local_avoidance_tick()
	if profile_enabled:
		profile_scopes["local_avoidance_prepare_usec"] = Time.get_ticks_usec() - scope_started_usec

	var commands: Array = _drain_queue(command_queue)
	var command_count: int = commands.size()
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
		_process_commands_profiled(commands, delta)
		profile_scopes["command_ordering_usec"] = _runtime_command_ordering_usec
		profile_scopes["command_apply_usec"] = _runtime_command_apply_usec
	else:
		_process_commands(commands, delta)
	if profile_enabled:
		profile_scopes["command_queue_usec"] = Time.get_ticks_usec() - scope_started_usec

	if profile_enabled:scope_started_usec=Time.get_ticks_usec()
	if is_hex_ground_runtime_active():_hex_movement_runtime.tick(delta)
	if profile_enabled:profile_scopes["hex_move_plan_usec"]=Time.get_ticks_usec()-scope_started_usec
	_commit_hex_facing_intents()
	_project_hex_ground_actors(0.0)
	var effects: Array = _drain_queue(effects_queue)
	var effect_count: int = effects.size()
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_process_effects(effects, delta)
	if _hex_movement_runtime.flush_stops():_project_hex_ground_actors(0.0)
	if profile_enabled:
		profile_scopes["effect_queue_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_enforce_unit_minimum_spacing()
	if profile_enabled:
		profile_scopes["unit_minimum_spacing_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_update_objective_capture()
	if profile_enabled:
		profile_scopes["objective_capture_usec"] = Time.get_ticks_usec() - scope_started_usec

	_finish_navigation_budget_tick()
	is_processing_tick = false
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_broadcast_tick_state()
	if profile_enabled:
		profile_scopes["snapshot_broadcast_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	tick_processed.emit(tick_counter)
	if profile_enabled:
		profile_scopes["tick_signal_emit_usec"] = Time.get_ticks_usec() - scope_started_usec
		_record_runtime_tick_budget_debug_snapshot(delta, tick_started_usec, profile_scopes, command_count, effect_count)


func get_last_tick_delta() -> float:
	return _last_tick_delta


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
	return bool(validate_network_command_for_peer(command_dict, 1).get("accepted", false))


func _build_network_command_context(command_dict: Dictionary, peer_id: int) -> Dictionary:
	var unit_id: String = String(command_dict.get("unit_id", "")).strip_edges()
	var unit = _resolve_known_unit_for_contract(unit_id)
	var unit_team_id: String = ""
	var unit_fireteam_id: String = ""
	if unit != null:
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id")).strip_edges()
		if unit.has_method("get_fireteam_id"):
			unit_fireteam_id = String(unit.call("get_fireteam_id")).strip_edges().to_lower()

	var craft_id: String = String(command_dict.get("craft_id", "")).strip_edges()
	var craft_exists := false
	var craft_fireteam_ids := PackedStringArray()
	if not craft_id.is_empty():
		var dropship_context: Dictionary = Dictionary(_multiplayer_snapshot_context.get("dropship", {}))
		for card_variant in Array(dropship_context.get("mission_drop_cards", [])):
			if typeof(card_variant) != TYPE_DICTIONARY:
				continue
			var card: Dictionary = Dictionary(card_variant)
			if String(card.get("craft_id", "")).strip_edges() != craft_id:
				continue
			craft_exists = true
			craft_fireteam_ids = PackedStringArray(Array(card.get("boarded_fireteam_ids", [])))
			break

	return {
		"peer_id": peer_id,
		"peer_role": get_peer_role(peer_id),
		"peer_team_id": get_peer_team(peer_id),
		"peer_fireteam_ids": get_peer_fireteams(peer_id),
		"unit_team_id": unit_team_id,
		"unit_fireteam_id": unit_fireteam_id,
		"craft_exists": craft_exists,
		"craft_fireteam_ids": craft_fireteam_ids,
	}


func _resolve_known_unit_for_contract(unit_id: String):
	if unit_id.strip_edges().is_empty():
		return null

	if _known_units_by_id.has(unit_id):
		return _known_units_by_id.get(unit_id, null)

	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("get_unit"):
		return unit_registry.call("get_unit", unit_id)

	return null


func _record_network_command_rejection(validation: Dictionary, command_dict: Dictionary, peer_id: int) -> void:
	_network_command_reject_count += 1
	_last_network_command_rejection = {
		"peer_id": peer_id,
		"reason": String(validation.get("reason", "unknown")),
		"category": String(validation.get("category", "")),
		"command_type": _extract_command_type(command_dict),
		"team_id": String(command_dict.get("team_id", "")),
		"unit_id": String(command_dict.get("unit_id", "")),
		"fireteam_id": String(command_dict.get("fireteam_id", "")),
	}


func _duplicate_peer_fireteam_assignments() -> Dictionary:
	var result: Dictionary = {}
	for peer_id_variant in _peer_fireteam_assignments.keys():
		result[peer_id_variant] = PackedStringArray(_peer_fireteam_assignments[peer_id_variant])
	return result


func _is_peer_allowed_for_team(peer_id: int, team_id: String) -> bool:
	if team_id.is_empty():
		return false

	if not _has_active_multiplayer_peer():
		return peer_id == 1 and team_id == "team_alpha"

	return get_peer_team(peer_id) == team_id


func _broadcast_tick_state() -> void:
	if _snapshot_broadcast_paused or not is_server_authoritative or not _has_active_multiplayer_peer() or not multiplayer.is_server():
		return

	var recipient_peer_ids: PackedInt32Array = _get_snapshot_recipient_peer_ids()
	if recipient_peer_ids.is_empty():
		return
	var state_dict: Dictionary = _build_tick_state()
	_broadcast_tick_state_chunks(state_dict, recipient_peer_ids)

	var vital_updates: Array = _build_vital_state_updates()
	if not vital_updates.is_empty():
		for peer_id in recipient_peer_ids:
			_receive_vital_state_updates.rpc_id(peer_id, vital_updates)


func _broadcast_tick_state_chunks(state_dict: Dictionary, recipient_peer_ids: PackedInt32Array) -> void:
	var pack_started_usec: int = Time.get_ticks_usec()
	var raw_bytes: PackedByteArray = var_to_bytes(state_dict)
	if raw_bytes.size() > SNAPSHOT_MAX_RAW_BYTES:
		push_warning("SimulationRoot snapshot exceeds raw transport capacity: %d bytes." % raw_bytes.size())
		return
	var compressed_bytes: PackedByteArray = raw_bytes.compress(SNAPSHOT_COMPRESSION_MODE)
	var use_compression: bool = not compressed_bytes.is_empty() and compressed_bytes.size() < raw_bytes.size()
	var wire_bytes: PackedByteArray = compressed_bytes if use_compression else raw_bytes
	var chunk_count: int = maxi((wire_bytes.size() + SNAPSHOT_CHUNK_PAYLOAD_BYTES - 1) / SNAPSHOT_CHUNK_PAYLOAD_BYTES, 1)
	if chunk_count > SNAPSHOT_MAX_CHUNK_COUNT:
		push_warning("SimulationRoot snapshot exceeds chunk transport capacity: %d chunks." % chunk_count)
		return
	_snapshot_transport_last_chunk_count = chunk_count
	_snapshot_transport_last_max_chunk_payload_bytes = 0
	_snapshot_transport_last_raw_bytes = raw_bytes.size()
	_snapshot_transport_last_wire_bytes = wire_bytes.size()
	for chunk_index in range(chunk_count):
		var start_offset: int = chunk_index * SNAPSHOT_CHUNK_PAYLOAD_BYTES
		var end_offset: int = mini(start_offset + SNAPSHOT_CHUNK_PAYLOAD_BYTES, wire_bytes.size())
		var chunk: PackedByteArray = wire_bytes.slice(start_offset, end_offset)
		_snapshot_transport_last_max_chunk_payload_bytes = maxi(_snapshot_transport_last_max_chunk_payload_bytes, chunk.size())
		for peer_id in recipient_peer_ids:
			_receive_tick_state_chunk.rpc_id(peer_id, tick_counter, chunk_index, chunk_count, raw_bytes.size(), use_compression, chunk)
	_snapshot_transport_last_pack_usec = Time.get_ticks_usec() - pack_started_usec


func _get_snapshot_recipient_peer_ids() -> PackedInt32Array:
	var result := PackedInt32Array()
	for peer_id_variant in multiplayer.get_peers():
		var peer_id: int = int(peer_id_variant)
		if peer_id > 1 and not _snapshot_blocked_peer_ids.has(peer_id):
			result.append(peer_id)
	return result


func _build_tick_state() -> Dictionary:
	var snapshot_context: Dictionary = Dictionary(_multiplayer_snapshot_context).duplicate(true)
	return Dictionary(
		_multiplayer_snapshot_contract.call(
			"build_state_snapshot",
			{
				"tick": tick_counter,
				"units": _build_unit_snapshots(),
				"vital_updates": _build_all_vital_state_snapshots(),
				"objective": _build_objective_snapshot(),
				"dropship": snapshot_context.get("dropship", {}),
				"contacts": snapshot_context.get("contacts", []),
				"enemy_security": snapshot_context.get("enemy_security", []),
				"enemy_team_tactics": snapshot_context.get("enemy_team_tactics", []),
				"character_gameplay": snapshot_context.get("character_gameplay", []),
				"fire_events": snapshot_context.get("fire_events", []),
				"feedback_bubbles": snapshot_context.get("feedback_bubbles", []),
				"fireteam_tactical": snapshot_context.get("fireteam_tactical", []),
				"commander_intents": snapshot_context.get("commander_intents", []),
				"fireteam_plan_status": snapshot_context.get("fireteam_plan_status", []),
				"communication_events": snapshot_context.get("communication_events", []),
				"tactical_rules": _build_authoritative_tactical_rules_snapshot(snapshot_context.get("tactical_rules", [])),
				"breakout_states": snapshot_context.get("breakout_states", []),
				"air_asset_status": _build_air_asset_status_snapshots(snapshot_context.get("air_asset_status", [])),
				"mission_interactions": snapshot_context.get("mission_interactions", {}),
				"mission_result": snapshot_context.get("mission_result", {}),
			}
		)
	)


func _build_unit_snapshots() -> Array:
	var unit_snapshots: Array = []
	for unit in _get_snapshot_units():
		var unit_snapshot: Dictionary = _build_unit_snapshot(unit)
		if unit_snapshot.is_empty():
			continue

		unit_snapshots.append(unit_snapshot)
	return unit_snapshots


func _build_air_asset_status_snapshots(context_statuses: Variant = []) -> Array:
	var by_asset_id: Dictionary = {}
	for status_variant in Array(context_statuses):
		if typeof(status_variant) != TYPE_DICTIONARY:
			continue
		var status: Dictionary = Dictionary(status_variant).duplicate(true)
		var asset_id: String = String(status.get("asset_id", "")).strip_edges()
		if asset_id.is_empty():
			continue
		by_asset_id[asset_id] = status
	for asset_id_variant in _air_asset_status_by_id.keys():
		var asset_id: String = String(asset_id_variant).strip_edges()
		if asset_id.is_empty():
			continue
		by_asset_id[asset_id] = Dictionary(_air_asset_status_by_id.get(asset_id_variant, {})).duplicate(true)
	var keys: Array = by_asset_id.keys()
	keys.sort()
	var result: Array = []
	for key_variant in keys:
		result.append(Dictionary(by_asset_id.get(key_variant, {})).duplicate(true))
	return result


func _build_objective_snapshot() -> Dictionary:
	if not _is_valid_objective_status(_objective_status):
		return {}
	if _objective_status.has_method("to_dict"):
		return Dictionary(_objective_status.call("to_dict")).duplicate(true)
	return {}


func _build_all_vital_state_snapshots() -> Array:
	var updates: Array = []
	for unit in _get_snapshot_units():
		var vital_update: Dictionary = _build_unit_vital_update(unit)
		if vital_update.is_empty():
			continue

		vital_update["vital_tick"] = tick_counter
		updates.append(vital_update)
	return updates


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
		# Dedupe the content before attaching its transport version.
		vital_update["vital_tick"] = tick_counter
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
	if unit.has_method("get_team_id"):
		snapshot["team_id"] = String(unit.call("get_team_id")).strip_edges()
	if unit.has_method("get_fireteam_id"):
		snapshot["fireteam_id"] = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	if unit is Node2D:
		snapshot["position"] = (unit as Node2D).global_position
		if unit.has_meta("facing_angle"):
			snapshot["facing_angle"] = float(unit.get_meta("facing_angle", 0.0))

	if unit is CanvasItem:
		snapshot["visible"] = bool((unit as CanvasItem).visible)

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			var runtime_dict: Dictionary = runtime_status.call("to_dict")
			snapshot["runtime_state"] = String(runtime_dict.get("status", ""))
			snapshot["fire_mode"] = String(runtime_dict.get("fire_status", ""))
			snapshot["active_command_type"] = String(runtime_dict.get("active_command_type", ""))
			snapshot["source_command_type"] = String(runtime_dict.get("source_command_type", ""))
			snapshot["move_speed_factor"] = float(runtime_dict.get("move_speed_factor", 1.0))
			snapshot["sight_range_factor"] = float(runtime_dict.get("sight_range_factor", 1.0))
			snapshot["movement_posture"] = String(runtime_dict.get("movement_posture", "idle"))
			snapshot["weapon_posture"] = String(runtime_dict.get("weapon_posture", "lowered"))
			snapshot["posture_policy_id"] = String(runtime_dict.get("posture_policy_id", ""))
			if runtime_dict.has("target_position"):
				snapshot["target_position"] = runtime_dict["target_position"]
			if runtime_dict.has("phase"):
				snapshot["phase"] = int(runtime_dict.get("phase", -1))

	if unit.has_method("get_vital_status"):
		var vital_status = unit.call("get_vital_status")
		if vital_status != null and vital_status.has_method("to_dict"):
			var vital_dict: Dictionary = vital_status.call("to_dict")
			snapshot["vital_state"] = String(vital_dict.get("state", ""))
			snapshot["health"] = int(vital_dict.get("health_points", 0))
			snapshot["bleedout_ticks"] = int(vital_dict.get("bleedout_ticks", 0))
			snapshot["vital_tick"] = tick_counter

	if unit.has_method("get_tactical_stance_badge_snapshot"):
		var stance_snapshot_variant: Variant = unit.call("get_tactical_stance_badge_snapshot")
		if typeof(stance_snapshot_variant) == TYPE_DICTIONARY:
			snapshot.merge(Dictionary(stance_snapshot_variant), true)
	if unit.has_method("get_active_weapon_id"):
		var raw_active_weapon_id: String = String(unit.call("get_active_weapon_id")).strip_edges()
		if not raw_active_weapon_id.is_empty():
			var active_weapon_id: String = WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", raw_active_weapon_id)
			if bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", active_weapon_id)):
				snapshot["active_weapon_id"] = active_weapon_id
				snapshot["weapon_tile_range"] = int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", active_weapon_id))
				snapshot["weapon_range_world"] = float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", active_weapon_id, _get_terrain_registry()))
	if unit is Node:
		_copy_enemy_meta_to_snapshot(unit as Node, snapshot)

	return snapshot


func _copy_enemy_meta_to_snapshot(unit: Node, snapshot: Dictionary) -> void:
	for string_key in [
		"enemy_security_group_id",
		"enemy_security_mode",
		"enemy_tactics_group_id",
		"enemy_tactic_profile_id",
		"enemy_visual_archetype_id",
		"enemy_advance_style",
		"enemy_role",
		"enemy_tactic_label",
		"enemy_movement_posture",
		"enemy_weapon_posture",
		"enemy_posture_policy_id",
		"enemy_limbo_behavior_action",
		"enemy_limbo_behavior_source",
		"enemy_limbo_behavior_reason",
	]:
		if unit.has_meta(string_key):
			snapshot[string_key] = String(unit.get_meta(string_key, ""))
	if unit.has_meta("enemy_facing_angle"):
		snapshot["enemy_facing_angle"] = float(unit.get_meta("enemy_facing_angle", 0.0))


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


func _apply_remote_state(state_dict: Dictionary) -> Dictionary:
	if typeof(state_dict) != TYPE_DICTIONARY:
		_last_snapshot_reject_reason = "snapshot_not_dictionary"
		return {
			"accepted": false,
			"reason": _last_snapshot_reject_reason,
		}

	var validation: Dictionary = Dictionary(_multiplayer_snapshot_contract.call("validate_for_apply", state_dict, _last_applied_snapshot_tick))
	if not bool(validation.get("accepted", false)):
		_last_snapshot_reject_reason = String(validation.get("reason", "unknown"))
		if _last_snapshot_reject_reason == "out_of_order_snapshot":
			_snapshot_out_of_order_count += 1
		return validation

	var snapshot: Dictionary = Dictionary(validation.get("snapshot", {})).duplicate(true)
	_last_applied_snapshot_tick = int(snapshot.get("tick", _last_applied_snapshot_tick))
	_snapshot_apply_count += 1
	_last_snapshot_reject_reason = ""
	_emit_snapshot_audio_events(snapshot)

	var objective_dict: Variant = snapshot.get("objective", {})
	if typeof(objective_dict) == TYPE_DICTIONARY:
		_apply_remote_objective_state(objective_dict)

	var unit_snapshots: Variant = snapshot.get("units", [])
	if not (unit_snapshots is Array):
		return {
			"accepted": true,
			"tick": _last_applied_snapshot_tick,
			"missing_unit_count": 0,
		}

	var missing_unit_count: int = 0
	for unit_snapshot in unit_snapshots:
		if typeof(unit_snapshot) != TYPE_DICTIONARY:
			continue

		var unit = _resolve_known_unit(String(unit_snapshot.get("unit_id", "")))
		if unit == null:
			missing_unit_count += 1
			continue

		if _has_remote_vital_fields(unit_snapshot) and not _accept_remote_vital_tick(String(unit_snapshot["unit_id"]), unit_snapshot, _last_applied_snapshot_tick):
			# Keep movement/runtime updates while retaining the newer vital projection.
			_copy_current_remote_vitals(unit, unit_snapshot)
		if unit.has_method("apply_remote_snapshot"):
			unit.call("apply_remote_snapshot", unit_snapshot)
			continue

		_apply_remote_snapshot_fallback(unit, unit_snapshot)

	for vital_update in Array(snapshot.get("vital_updates", [])):
		var unit_id: String = String(vital_update.get("unit_id", ""))
		if int(vital_update.get("vital_tick", _last_applied_snapshot_tick)) >= int(_last_applied_vital_tick_by_unit_id.get(unit_id, -1)):
			continue
		var unit = _resolve_known_unit(unit_id)
		if unit != null:
			_copy_current_remote_vitals(unit, vital_update)
	_last_server_state = snapshot.duplicate(true)
	_snapshot_missing_unit_count += missing_unit_count
	multiplayer_snapshot_applied.emit(snapshot.duplicate(true))
	return {
		"accepted": true,
		"tick": _last_applied_snapshot_tick,
		"missing_unit_count": missing_unit_count,
	}


func _emit_snapshot_audio_events(snapshot: Dictionary) -> void:
	var bus = _resolve_audio_event_bus()
	if bus == null or not bus.has_method("emit_weapon_fire"):
		return
	for fire_event_variant in Array(snapshot.get("fire_events", [])):
		if typeof(fire_event_variant) != TYPE_DICTIONARY:
			continue
		var fire_event: Dictionary = Dictionary(fire_event_variant)
		var event_id: String = String(fire_event.get("event_id", "")).strip_edges()
		if event_id.is_empty():
			continue
		var position: Variant = fire_event.get("muzzle_position", fire_event.get("attacker_position", Vector2.ZERO))
		var result: Dictionary = Dictionary(bus.call("emit_weapon_fire", String(fire_event.get("weapon_id", "")), {
			"position": position,
			"unit_id": String(fire_event.get("attacker_unit_id", "")),
			"team_id": String(fire_event.get("attacker_team_id", "")),
			"target_unit_id": String(fire_event.get("target_unit_id", "")),
			"from_multiplayer_snapshot": true,
			"network_read_only": true,
			"source": "multiplayer_snapshot",
			"visible_to_local": bool(fire_event.get("visible_to_local", true)),
			"visibility_context": String(fire_event.get("visibility_context", "snapshot_visible")),
			"dedupe_key": event_id,
			"dedupe_window_msec": 5000,
		})).duplicate(true)
		_last_snapshot_audio_result = result.duplicate(true)
		if bool(result.get("played", false)):
			_snapshot_audio_event_ids_played[event_id] = true
			_snapshot_audio_played_count += 1
		else:
			_snapshot_audio_suppressed_count += 1


func _resolve_audio_event_bus():
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus) and _audio_event_bus.has_method("emit_weapon_fire"):
		return _audio_event_bus
	_audio_event_bus = null
	if audio_event_bus_path != NodePath():
		var path_bus := get_node_or_null(audio_event_bus_path)
		if path_bus != null and path_bus.has_method("emit_weapon_fire"):
			_audio_event_bus = path_bus
			return _audio_event_bus
	var child_bus := get_node_or_null("AudioEventBus")
	if child_bus != null and child_bus.has_method("emit_weapon_fire"):
		_audio_event_bus = child_bus
		return _audio_event_bus
	var parent_node := get_parent()
	if parent_node != null:
		var sibling_bus := parent_node.get_node_or_null("AudioEventBus")
		if sibling_bus != null and sibling_bus.has_method("emit_weapon_fire"):
			_audio_event_bus = sibling_bus
			return _audio_event_bus
	return null


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
	if objective_dict.has("timer_state") or objective_dict.has("countdown_seconds"):
		var timer_source: String = String(objective_dict.get("timer_source", objective_dict.get("source", ""))).strip_edges()
		var timer_state: String = String(objective_dict.get("timer_state", "none")).strip_edges().to_lower()
		if timer_source.is_empty() or timer_state == "none":
			_objective_status.clear_countdown()
		else:
			_objective_status.set_countdown(
				_extract_float(objective_dict.get("countdown_seconds", 0.0), 0.0),
				timer_state,
				timer_source,
				_extract_float(objective_dict.get("countdown_total_seconds", objective_dict.get("countdown_seconds", 0.0)), 0.0),
				String(objective_dict.get("timer_label", ""))
			)


func _apply_remote_snapshot_fallback(unit, unit_snapshot: Dictionary) -> void:
	if unit == null:
		return

	if unit is CanvasItem:
		(unit as CanvasItem).visible = bool(unit_snapshot.get("visible", true))

	if unit is Node2D:
		var target_position: Vector2 = _coerce_vector2(unit_snapshot.get("position", (unit as Node2D).global_position), (unit as Node2D).global_position)
		(unit as Node2D).global_position = (unit as Node2D).global_position.lerp(target_position, 0.75)
		if unit_snapshot.has("facing_angle") and unit is Node:
			(unit as Node).set_meta("facing_angle", float(unit_snapshot.get("facing_angle", 0.0)))


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


var _runtime_command_ordering_usec: int = 0
var _runtime_command_apply_usec: int = 0

func _process_commands_profiled(commands: Array, delta: float) -> void:
	_runtime_command_type_count.clear()
	_runtime_command_type_usec.clear()
	_runtime_command_requeue_count.clear()
	var ordering_started_usec: int = Time.get_ticks_usec()
	var ordered_commands: Array = _order_payloads(commands)
	_runtime_command_ordering_usec = Time.get_ticks_usec() - ordering_started_usec
	var apply_loop_started_usec: int = Time.get_ticks_usec()
	for cmd in ordered_commands:
		var command_type: String = _normalize_runtime_command_type(cmd)
		_runtime_command_type_count[command_type] = int(_runtime_command_type_count.get(command_type, 0)) + 1
		if not _runtime_command_requeue_count.has(command_type):
			_runtime_command_requeue_count[command_type] = 0
		var queue_size_before: int = command_queue.size()
		var apply_started_usec: int = Time.get_ticks_usec()
		_apply_command(cmd, delta)
		var apply_usec: int = Time.get_ticks_usec() - apply_started_usec
		_runtime_command_type_usec[command_type] = int(_runtime_command_type_usec.get(command_type, 0)) + apply_usec
		if command_queue.size() > queue_size_before:
			_runtime_command_requeue_count[command_type] = int(_runtime_command_requeue_count.get(command_type, 0)) + 1
	_runtime_command_apply_usec = Time.get_ticks_usec() - apply_loop_started_usec


func _normalize_runtime_command_type(cmd: Variant) -> String:
	if typeof(cmd) != TYPE_DICTIONARY:
		return "unknown"
	var command_type: String = String((cmd as Dictionary).get("command_type", (cmd as Dictionary).get("type", ""))).strip_edges().to_lower()
	return command_type if not command_type.is_empty() else "unknown"


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
	if String(cmd.get("contract_category", "")) in ["singleplayer_campaign", "singleplayer_supply", "campaign_onboarding", "singleplayer_space_travel"]:
		# Queued UI-origin requests cannot inject a trusted runtime context.
		request_singleplayer_command(cmd)
		return
	if String(cmd.get("contract_category", "")).strip_edges().to_lower() == "commander_intent":
		commander_intent_committed.emit(cmd.duplicate(true))
		return

	match _extract_command_type(cmd):
		"move_to_position":
			_apply_move_command(cmd, delta)
		"engage_area":
			_apply_move_command(cmd, delta)
		"hold_position":
			_apply_unit_command_status(cmd)
		"set_fire_rule":
			_apply_fire_rule_command(cmd)
		"set_lz", "clear_lz", "call_dropship", "set_dropship_approach", "return_dropship":
			_apply_dropship_command(cmd)
		_:
			# TODO: Authoritative gameplay state commits belong here once systems exist.
			pass


func _apply_dropship_command(command: Dictionary) -> void:
	dropship_command_committed.emit(command.duplicate(true))


func _apply_fire_rule_command(command: Dictionary) -> void:
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	var fire_rule: String = String(command.get("fire_rule", "")).strip_edges().to_lower()
	if fireteam_id.is_empty() or not fire_rule in ["hold", "return", "free", "suppress"]:
		return
	var previous: Dictionary = Dictionary(_authoritative_fire_rules_by_fireteam.get(fireteam_id, {}))
	var revision: int = int(previous.get("revision", 0)) + 1
	_authoritative_fire_rules_by_fireteam[fireteam_id] = {
		"fireteam_id": fireteam_id,
		"team_id": String(command.get("team_id", previous.get("team_id", ""))).strip_edges(),
		"fire_rule": fire_rule,
		"revision": revision,
		"command_id": String(command.get("command_id", "roe:%s:%d" % [fireteam_id, revision])).strip_edges(),
		"runtime_authority": "SimulationRoot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	fire_rule_committed.emit(get_authoritative_fire_rule_state(fireteam_id))


func _build_authoritative_tactical_rules_snapshot(context_rules: Variant) -> Array:
	var by_fireteam: Dictionary = {}
	for entry_variant in Array(context_rules):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			by_fireteam[fireteam_id] = entry
	for entry_variant in get_authoritative_fire_rule_snapshot():
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		by_fireteam[String(entry.get("fireteam_id", ""))] = entry
	var fireteam_ids: Array = by_fireteam.keys()
	fireteam_ids.sort()
	var result: Array = []
	for fireteam_id_variant in fireteam_ids:
		result.append(Dictionary(by_fireteam[fireteam_id_variant]).duplicate(true))
	return result


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
		"air_asset_status_update":
			_apply_air_asset_status_update_effect(effect)
		"apply_loadout_modifiers":
			_apply_loadout_modifiers_effect(effect)
		"set_unit_combat_posture":
			_apply_unit_combat_posture_effect(effect)
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
		_record_discarded_move_command(cmd, "missing_unit_id")
		push_warning("SimulationRoot move command expects a non-empty unit_id.")
		return

	var target_position: Variant = cmd.get("target_position", null)
	if typeof(target_position) != TYPE_VECTOR2:
		_record_discarded_move_command(cmd, "invalid_target_position", {"unit_id": unit_id})
		push_warning("SimulationRoot move command expects a Vector2 target_position.")
		return
	if is_hex_ground_runtime_active() and not Vector2(target_position).is_finite():
		_record_discarded_move_command(cmd,"invalid_target_position",{"unit_id":unit_id})
		return

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		_record_discarded_move_command(cmd, "missing_unit_registry", {"unit_id": unit_id})
		push_warning("SimulationRoot requires a direct UnitRegistry reference for move commands.")
		return

	var unit = unit_registry.call("get_unit", unit_id)
	if unit == null:
		_record_discarded_move_command(cmd, "unit_not_registered", {"unit_id": unit_id})
		return

	if not (unit is Node2D):
		_record_discarded_move_command(cmd, "unit_not_node2d", {"unit_id": unit_id})
		push_warning("SimulationRoot move command expects a Node2D-compatible unit.")
		return

	if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
		_record_discarded_move_command(cmd, "unit_not_fit", {"unit_id": unit_id})
		if is_hex_ground_runtime_active():_hex_movement_runtime.stage_stop(unit_id,"unit_not_fit")
		return

	if _is_stale_tokenized_move_command(cmd, unit):
		_record_discarded_move_command(cmd, "stale_command_token", {"unit_id": unit_id})
		return
	if is_hex_ground_runtime_active() and not _hex_ground_runtime.has_unit(unit_id):
		_record_discarded_move_command(cmd,"hex_unit_not_admitted",{"unit_id":unit_id})
		return

	var command_applied:bool=_apply_unit_command_status(cmd,unit)
	if is_hex_ground_runtime_active():
		if not command_applied:
			_record_discarded_move_command(cmd,"invalid_hex_unit_command",{"unit_id":unit_id})
			return
		var staged:Dictionary=_hex_movement_runtime.stage_move(cmd,unit)
		if not staged.ok:_record_discarded_move_command(cmd,String(staged.reason),{"unit_id":unit_id})
		return

	if unit.has_method("set_target_position"):
		unit.call("set_target_position", target_position)

	var node_2d: Node2D = unit
	var move_speed_factor: float = _extract_move_speed_factor(cmd, unit)
	if move_speed_factor <= 0.0:
		return

	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null:
		_apply_move_command_with_terrain(cmd, node_2d, target_position, move_speed_factor, delta, terrain_registry)
		return

	var current_position: Vector2 = node_2d.position
	var direction: Vector2 = target_position - current_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * delta
	if direction.length() <= step_distance:
		_store_unit_facing_from_positions(unit, current_position, target_position)
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
	var next_position: Vector2 = current_position + displacement
	_store_unit_facing_from_positions(unit, current_position, next_position)
	node_2d.position = next_position
	_update_local_avoidance_agent_position(unit_id, node_2d.global_position)
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")
	if bool(cmd.get("requeue_until_target", true)):
		enqueue_command(cmd)


func _apply_unit_command_status(cmd: Dictionary, unit = null) -> bool:
	var target_unit = unit
	if target_unit == null:
		var unit_id: String = String(cmd.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			return false
		var unit_registry = _get_unit_registry()
		if unit_registry != null and unit_registry.has_method("get_unit"):
			target_unit = unit_registry.call("get_unit", unit_id)
		if target_unit == null:
			target_unit = _resolve_known_unit(unit_id)
	if target_unit == null or not target_unit.has_method("assign_unit_command"):
		return false

	var status_data:Dictionary=cmd
	if is_hex_ground_runtime_active() and not cmd.has("command_type"):
		status_data=cmd.duplicate(false)
		status_data["command_type"]=_extract_command_type(cmd)
	var command = UNIT_COMMAND_SCRIPT.call("from_dict", status_data)
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		return false

	var applied:Variant=target_unit.call("assign_unit_command",command)
	if is_hex_ground_runtime_active() and applied is bool and not applied:return false
	if is_hex_ground_runtime_active() and _extract_command_type(cmd)=="hold_position":_hex_movement_runtime.stage_stop(String(cmd.get("unit_id","")),"hold_position")
	var command_token: String = String(cmd.get("command_token", "")).strip_edges()
	var unit_id: String = String(cmd.get("unit_id", "")).strip_edges()
	if not unit_id.is_empty():
		_committed_command_token_by_unit_id[unit_id] = command_token
		if command_token.is_empty():
			# An authoritative untokenized Hold supersedes already queued Moves.
			_latest_command_token_by_unit_id[unit_id] = ""
	_apply_unit_command_facing(cmd, target_unit)
	return true


func _apply_unit_command_facing(cmd: Dictionary, unit) -> void:
	if unit == null or not (unit is Node) or not cmd.has("facing_angle"):
		return
	var facing_value: Variant = cmd.get("facing_angle", null)
	if not (typeof(facing_value) == TYPE_FLOAT or typeof(facing_value) == TYPE_INT):
		return
	var unit_node: Node = unit as Node
	var facing_angle: float = float(facing_value)
	unit_node.set_meta("facing_angle", facing_angle)
	unit_node.set_meta("map_facing_angle", facing_angle)
	if cmd.has("security_mode"):
		unit_node.set_meta("security_facing_angle", facing_angle)
		unit_node.set_meta("security_facing_active", true)


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
	var previous_position: Vector2 = current_position
	var hex_metric: bool = _uses_hex_movement_metric(terrain_registry)
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * _extract_surface_speed_factor(unit_node) * delta
	while step_distance > 0.0 and not path_world_points.is_empty():
		var next_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
		var direction_to_waypoint: Vector2 = next_waypoint - current_position
		if direction_to_waypoint.is_zero_approx():
			path_world_points.pop_front()
			continue

		var distance_to_waypoint: float = direction_to_waypoint.length()
		if hex_metric:
			distance_to_waypoint = float(terrain_registry.call("get_movement_distance", current_position, next_waypoint))
		if distance_to_waypoint <= step_distance:
			current_position = next_waypoint
			step_distance -= distance_to_waypoint
			path_world_points.pop_front()
			continue

		if hex_metric:
			current_position = current_position.lerp(next_waypoint, step_distance / distance_to_waypoint)
		else:
			current_position += direction_to_waypoint.normalized() * step_distance
		step_distance = 0.0

	_store_unit_facing_from_positions(unit_node, previous_position, current_position)
	unit_node.global_position = current_position
	_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	var resolved_target_position: Vector2 = _coerce_vector2(cmd.get("navigation_resolved_target_position", target_position), target_position)
	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(resolved_target_position) > 0.5):
		enqueue_command(cmd)


func _uses_hex_movement_metric(terrain_registry) -> bool:
	return terrain_registry != null and terrain_registry.has_method("get_grid_topology") and String(terrain_registry.call("get_grid_topology")) == "hex_axial_v1"


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
	var previous_position: Vector2 = current_position
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
	var hex_metric: bool = _uses_hex_movement_metric(terrain_registry)
	if hex_metric:
		distance_to_waypoint = float(terrain_registry.call("get_movement_distance", current_position, next_waypoint))
	var desired_step_distance: float = minf(step_distance, distance_to_waypoint)
	var desired_velocity: Vector2 = direction_to_waypoint.normalized() * (desired_step_distance / maxf(delta, 0.0001))
	if hex_metric:
		desired_velocity = direction_to_waypoint * (desired_step_distance / distance_to_waypoint) / maxf(delta, 0.0001)
	var avoidance_speed: float = desired_velocity.length() if hex_metric else step_distance / maxf(delta, 0.0001)
	var safe_velocity: Vector2 = _resolve_local_avoidance_velocity(cmd, unit_node, current_position, desired_velocity, avoidance_speed, delta, terrain_registry)
	if safe_velocity.length_squared() <= 0.0001 \
		and bool(cmd.get("local_avoidance_deadlock", false)) \
		and _is_local_avoidance_transition_walkable(current_position, next_waypoint, terrain_registry):
		safe_velocity = desired_velocity
	var displacement: Vector2 = safe_velocity * delta
	if hex_metric:
		var physical_displacement: float = float(terrain_registry.call("get_movement_distance", current_position, current_position + displacement))
		if physical_displacement > desired_step_distance:
			displacement *= desired_step_distance / physical_displacement
	elif displacement.length() > desired_step_distance:
		displacement = displacement.normalized() * desired_step_distance
	current_position += displacement
	if current_position.distance_to(next_waypoint) <= 0.5:
		current_position = next_waypoint
		path_world_points.pop_front()

	_store_unit_facing_from_positions(unit_node, previous_position, current_position)
	unit_node.global_position = current_position
	_update_local_avoidance_agent_position(_extract_unit_id_for_path_recompute(unit_node), unit_node.global_position)
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	var resolved_target_position: Vector2 = _coerce_vector2(cmd.get("navigation_resolved_target_position", target_position), target_position)
	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(resolved_target_position) > 0.5):
		enqueue_command(cmd)


func _store_unit_facing_from_positions(unit, from_position: Vector2, to_position: Vector2) -> void:
	if unit == null or not (unit is Node):
		return
	var direction: Vector2 = to_position - from_position
	if direction.length_squared() <= 0.0001:
		return
	(unit as Node).set_meta("facing_angle", direction.angle())


func _is_stale_tokenized_move_command(cmd: Dictionary, unit) -> bool:
	var command_token: String = String(cmd.get("command_token", "")).strip_edges()
	if command_token.is_empty():
		return false
	var unit_id: String = String(cmd.get("unit_id", "")).strip_edges()
	var latest_token: String = String(_latest_command_token_by_unit_id.get(unit_id, "")).strip_edges()
	if _latest_command_token_by_unit_id.has(unit_id) and latest_token != command_token:
		return true
	if unit == null or not unit.has_method("get_current_unit_command"):
		return false
	var current_command = unit.call("get_current_unit_command")
	if current_command == null:
		return false
	var current_token: String = ""
	if typeof(current_command) == TYPE_DICTIONARY:
		current_token = String(Dictionary(current_command).get("command_token", "")).strip_edges()
	elif current_command is Object:
		current_token = String(current_command.get("command_token")).strip_edges()
	if current_token == command_token:
		return false
	var committed_token: String = String(_committed_command_token_by_unit_id.get(unit_id, "")).strip_edges()
	return not _committed_command_token_by_unit_id.has(unit_id) or committed_token != current_token


func _discard_pending_move_commands_for_unit(unit_id: String) -> void:
	if is_hex_ground_runtime_active():_hex_movement_runtime.stage_stop(unit_id,"unit_not_fit")
	for index in range(command_queue.size() - 1, -1, -1):
		var pending_command: Dictionary = command_queue[index]
		if String(pending_command.get("unit_id", "")).strip_edges() != unit_id:
			continue
		if _extract_command_type(pending_command) not in ["move_to_position", "engage_area"]:
			continue
		command_queue.remove_at(index)
		_record_discarded_move_command(pending_command, "unit_not_fit", {"unit_id": unit_id})


func _record_discarded_move_command(cmd: Dictionary, reason: String, details: Dictionary = {}) -> void:
	var normalized_reason: String = reason.strip_edges().to_lower()
	if normalized_reason.is_empty():
		normalized_reason = "unknown"
	_discarded_move_command_count += 1
	_discarded_move_command_counts_by_reason[normalized_reason] = int(_discarded_move_command_counts_by_reason.get(normalized_reason, 0)) + 1
	var record: Dictionary = {
		"tick": tick_counter,
		"reason": normalized_reason,
		"command_type": String(cmd.get("command_type", cmd.get("type", ""))).strip_edges(),
		"unit_id": String(cmd.get("unit_id", "")).strip_edges(),
		"team_id": String(cmd.get("team_id", "")).strip_edges(),
		"source_command_type": String(cmd.get("source_command_type", cmd.get("origin_command_type", ""))).strip_edges(),
		"phase": int(cmd.get("phase", -1)),
		"command_token": String(cmd.get("command_token", "")).strip_edges(),
		"target_position": cmd.get("target_position", null),
		"requeue_until_target": bool(cmd.get("requeue_until_target", false)),
		"will_requeue": false,
	}
	for key in details.keys():
		record[key] = details[key]
	_last_discarded_move_command = record


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
		cmd.erase("navigation_resolved_target_position")

	if not existing_path.is_empty():
		cmd["navigation_resolved_target_position"] = _coerce_vector2(existing_path[-1], target_position)
		return existing_path

	if not _try_begin_navigation_path_request(cmd, unit, current_position, target_position):
		return []

	var path_world_points: Array = _build_path_world_points(current_position, target_position, terrain_registry, cmd, unit)
	if cmd.has("_regional_navigation_search"):
		_delay_navigation_path_request(cmd, unit, current_position, target_position, "regional_search_pending")
		return []
	cmd["path"] = path_world_points.duplicate(true)
	if not path_world_points.is_empty():
		cmd["navigation_resolved_target_position"] = _coerce_vector2(path_world_points[-1], target_position)
		cmd["navigation_path_terrain_revision"] = _get_terrain_registry_revision(terrain_registry)
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

	if bool(cmd.get("local_avoidance_repath_requested", false)):
		cmd.erase("local_avoidance_repath_requested")
		cmd.erase("local_avoidance_deadlock")
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return true

	if cmd.has("navigation_path_terrain_revision") and int(cmd["navigation_path_terrain_revision"]) != _get_terrain_registry_revision(terrain_registry):
		return true

	if not bool(cmd.get("requeue_until_target", true)) or not _is_unit_in_contact(unit):
		_contact_path_recompute_ready_at_msec.erase(unit_id)
		return false

	if existing_path.is_empty():
		return false

	# An exact regional route already uses this command's fixed costs. The
	# explicit avoidance request and terrain revision checks above still apply.
	if _uses_regional_navigation(terrain_registry):
		return false

	var resolved_target_position: Vector2 = _coerce_vector2(cmd.get("navigation_resolved_target_position", target_position), target_position)
	var target_grid: Vector2i = terrain_registry.call("world_to_grid", resolved_target_position)
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
	_regional_navigation_expansions_this_tick = 0
	_prepare_regional_navigation_admissions()
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
	if is_processing_tick and _uses_regional_navigation(_get_terrain_registry()):
		var unit_id := _extract_unit_id_for_path_recompute(unit)
		if not _regional_navigation_admissions.has(unit_id):
			_delay_navigation_path_request(cmd, unit, current_position, target_position, "regional_search_turn")
			return false
		_regional_navigation_last_service_tick[unit_id] = tick_counter

	_navigation_new_path_queries_this_tick += 1
	cmd.erase("navigation_pending_reason")
	cmd.erase("navigation_pending_since_tick")
	return true


func _prepare_regional_navigation_admissions() -> void:
	_regional_navigation_admissions.clear()
	if is_hex_ground_runtime_active():
		_regional_navigation_last_service_tick.clear()
		return
	var registry = _get_terrain_registry()
	if not _uses_regional_navigation(registry):
		_regional_navigation_last_service_tick.clear()
		return
	var candidates: Array[Dictionary] = []
	var next_history: Dictionary = {}
	var revision := _get_terrain_registry_revision(registry)
	for index in range(command_queue.size()):
		var command: Dictionary = command_queue[index]
		if _extract_command_type(command) not in ["move_to_position", "engage_area"]:
			continue
		if not Array(command.get("path", [])).is_empty() and not bool(command.get("local_avoidance_repath_requested", false)) and int(command.get("navigation_path_terrain_revision", -1)) == revision:
			continue
		var unit_id := String(command.get("unit_id", ""))
		var last_tick: int = _regional_navigation_last_service_tick.get(unit_id, -1)
		next_history[unit_id] = last_tick
		candidates.append({"unit_id": unit_id, "priority": _extract_priority(command), "last_tick": last_tick, "index": index})
	_regional_navigation_last_service_tick = next_history
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.priority != b.priority:
			return int(a.priority) > int(b.priority)
		if a.last_tick != b.last_tick:
			return int(a.last_tick) < int(b.last_tick)
		return int(a.index) < int(b.index)
	)
	var slots := REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK / REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE
	if navigation_budget_enabled:
		slots = mini(slots, maxi(0, navigation_max_new_path_queries_per_tick))
	for candidate: Dictionary in candidates:
		if _regional_navigation_admissions.size() >= slots:
			break
		_regional_navigation_admissions[candidate.unit_id] = REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE
	# Reuse the existing total budget when fewer than four jobs are admitted.
	# Selection, priority and least-recent-service rotation stay unchanged.
	if not _regional_navigation_admissions.is_empty():
		var share: int = REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK / _regional_navigation_admissions.size()
		for unit_id: String in _regional_navigation_admissions:
			_regional_navigation_admissions[unit_id] = share


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
	var pending_search: Variant = cmd.get("_regional_navigation_search")
	if pending_search != null:
		record["duration_usec"] = pending_search.last_slice_usec if reason == "regional_search_pending" else 0
		record["search_total_usec"] = pending_search.work_usec
		record["search_max_slice_usec"] = pending_search.max_slice_usec
		record["search_expanded_count"] = pending_search.expanded_count
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
	if status in ["direct_a_star", "regional_nearest_reachable"]:
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
	unreachable = unreachable or status == "regional_nearest_reachable"
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
		"search_elapsed_usec": int(query_result.get("search_elapsed_usec", duration_usec)),
		"search_max_slice_usec": int(query_result.get("search_max_slice_usec", duration_usec)),
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


func _prepare_local_avoidance_tick(force: bool = false) -> void:
	if not local_avoidance_enabled and not force:
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
		_get_legacy_spacing_units(Array(unit_registry.call("get_all_units"))),
		local_avoidance_agent_radius,
		local_avoidance_spatial_cell_size
	)
	_local_avoidance_prepared_tick = tick_counter


func _enforce_unit_minimum_spacing() -> void:
	if not unit_minimum_spacing_enabled:
		return
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return
	var units: Array = []
	for unit in Array(unit_registry.call("get_all_units")):
		if not (unit is Node2D):
			continue
		if is_hex_ground_runtime_active() and unit.has_method("get_unit_id") and _hex_ground_runtime.has_unit(String(unit.call("get_unit_id"))):continue
		if unit.has_method("get_unit_id") and String(unit.call("get_unit_id")).strip_edges().is_empty():
			continue
		units.append(unit)
	if units.size() < 2:
		_unit_minimum_spacing_debug_snapshot = {
			"tick": tick_counter,
			"enabled": true,
			"minimum_distance": unit_minimum_spacing_distance,
			"unit_count": units.size(),
			"moved_unit_ids": [],
			"minimum_distance_after": INF,
			"minimum_distance_measured": unit_minimum_spacing_debug_enabled,
			"solver_pair_check_count": 0,
			"diagnostic_pair_check_count": 0,
			"blocked_pair_count": 0,
			"downed_units_keep_space": true,
		}
		return
	var result: Dictionary = Dictionary(_local_avoidance_resolver.call(
		"resolve_minimum_spacing_positions",
		units,
		unit_minimum_spacing_distance,
		_get_terrain_registry(),
		unit_minimum_spacing_solver_iterations,
		unit_minimum_spacing_debug_enabled
	))
	var positions_by_unit_id: Dictionary = Dictionary(result.get("positions_by_unit_id", {}))
	var moved_unit_ids: Array = Array(result.get("moved_unit_ids", []))
	var moved_lookup: Dictionary = {}
	for unit_id_variant in moved_unit_ids:
		moved_lookup[String(unit_id_variant)] = true
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty() or not moved_lookup.has(unit_id):
			continue
		var next_position: Variant = positions_by_unit_id.get(unit_id, null)
		if typeof(next_position) != TYPE_VECTOR2:
			continue
		(unit as Node2D).global_position = Vector2(next_position)
		if unit.has_method("refresh_terrain_readability"):
			unit.call("refresh_terrain_readability")
		_update_local_avoidance_agent_position(unit_id, (unit as Node2D).global_position)
	_unit_minimum_spacing_debug_snapshot = {
		"tick": tick_counter,
		"enabled": true,
		"minimum_distance": float(result.get("minimum_distance", unit_minimum_spacing_distance)),
		"minimum_distance_after": float(result.get("minimum_distance_after", INF)),
		"minimum_distance_measured": bool(result.get("minimum_distance_measured", false)),
		"solver_pair_check_count": int(result.get("solver_pair_check_count", 0)),
		"diagnostic_pair_check_count": int(result.get("diagnostic_pair_check_count", 0)),
		"unit_count": units.size(),
		"moved_unit_ids": moved_unit_ids,
		"active_unit_ids": Array(result.get("active_unit_ids", [])),
		"resolved_pair_count": int(result.get("resolved_pair_count", 0)),
		"blocked_pair_count": int(result.get("blocked_pair_count", 0)),
		"blocked_pairs": Array(result.get("blocked_pairs", [])).duplicate(true),
		"downed_units_keep_space": true,
	}
	if unit_minimum_spacing_debug_enabled and int(_unit_minimum_spacing_debug_snapshot.get("blocked_pair_count", 0)) > 0:
		push_warning("SimulationRoot minimum spacing could not separate every active unit pair.")


func _get_legacy_spacing_units(units:Array) -> Array:
	if not is_hex_ground_runtime_active():return units
	var legacy:Array=[]
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("get_unit_id") and _hex_ground_runtime.has_unit(String(unit.call("get_unit_id"))):continue
		legacy.append(unit)
	return legacy


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
	var command_avoidance_enabled: bool = _is_local_avoidance_enabled_for_command(cmd)
	if unit_node == null or not command_avoidance_enabled or desired_velocity.is_zero_approx():
		return desired_velocity
	_prepare_local_avoidance_tick(command_avoidance_enabled)
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
	safe_velocity = _preserve_local_avoidance_forward_progress(desired_velocity, safe_velocity, max_speed)
	var discarded_correction: bool = false
	var discard_reason: String = ""
	if terrain_registry != null:
		var candidate_position: Vector2 = current_position + safe_velocity * delta
		if not _is_local_avoidance_transition_walkable(current_position, candidate_position, terrain_registry):
			var desired_position: Vector2 = current_position + desired_velocity * delta
			discarded_correction = true
			discard_reason = "non_walkable_correction"
			if _is_local_avoidance_transition_walkable(current_position, desired_position, terrain_registry):
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


func _preserve_local_avoidance_forward_progress(desired_velocity: Vector2, safe_velocity: Vector2, max_speed: float) -> Vector2:
	var desired_speed: float = desired_velocity.length()
	if desired_speed <= 0.001 or max_speed <= 0.001:
		return safe_velocity
	var desired_direction: Vector2 = desired_velocity / desired_speed
	var minimum_forward_speed: float = minf(desired_speed, max_speed) * LOCAL_AVOIDANCE_MIN_FORWARD_PROGRESS_FACTOR
	var current_forward_speed: float = safe_velocity.dot(desired_direction)
	if current_forward_speed >= minimum_forward_speed:
		return safe_velocity
	var lateral_velocity: Vector2 = safe_velocity - desired_direction * current_forward_speed
	var next_velocity: Vector2 = desired_direction * minimum_forward_speed + lateral_velocity
	if next_velocity.length() > max_speed:
		next_velocity = next_velocity.normalized() * max_speed
	return next_velocity


func _is_local_avoidance_transition_walkable(from_position: Vector2, to_position: Vector2, terrain_registry) -> bool:
	if not _is_local_avoidance_position_walkable(to_position, terrain_registry): return false
	if terrain_registry == null or not terrain_registry.has_method("get_tile_at_world"): return true
	var from_tile = terrain_registry.call("get_tile_at_world", from_position)
	var to_tile = terrain_registry.call("get_tile_at_world", to_position)
	var explicit_ramp_rules: bool = (from_tile != null and bool(from_tile.explicit_hex_ramps)) \
		or (to_tile != null and bool(to_tile.explicit_hex_ramps))
	if not explicit_ramp_rules: return true
	# Reuse the same bounded segment partition as minimum-spacing correction.
	# Every crossed edge is checked by TerrainPathfinder, including ramp flanks.
	return bool(_local_avoidance_resolver.call("_is_spacing_transition_walkable", from_position, to_position, terrain_registry))


func _is_local_avoidance_position_walkable(position: Vector2, terrain_registry) -> bool:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("is_walkable"):
		return true
	return bool(terrain_registry.call("is_walkable", terrain_registry.call("world_to_grid", position)))


func _update_local_avoidance_agent_position(unit_id: String, position: Vector2) -> void:
	if unit_id.strip_edges().is_empty():
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
		"command_local_avoidance_enabled": bool(cmd.get("local_avoidance_enabled", false)),
	}


func _extract_unit_id_for_path_recompute(unit) -> String:
	if unit == null or not unit.has_method("get_unit_id"):
		return ""

	return String(unit.call("get_unit_id"))


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
	if _uses_regional_navigation(terrain_registry):
		return _build_regional_path_world_points(cmd, unit, terrain_registry, from_grid, to_grid, resolved_target_position, navigation_options)
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


func _uses_regional_navigation(terrain_registry) -> bool:
	return (
		_uses_hex_movement_metric(terrain_registry)
		and terrain_registry.has_method("get_tile_count")
		and int(terrain_registry.call("get_tile_count")) >= REGIONAL_NAVIGATION_MIN_TILES
	)


func _build_regional_path_world_points(cmd: Dictionary, unit, terrain_registry, from_grid: Vector2i, to_grid: Vector2i, resolved_target: Vector2, options: Dictionary) -> Array:
	var revision := _get_terrain_registry_revision(terrain_registry)
	var search: TERRAIN_PATHFINDER_SCRIPT.RegionalHexSearch = cmd.get("_regional_navigation_search")
	if (
		search == null or search.source != from_grid or search.goal != to_grid
		or search.revision != revision or search.registry_id != terrain_registry.get_instance_id()
		or search.cost_options != options
	):
		search = TERRAIN_PATHFINDER_SCRIPT.RegionalHexSearch.new(from_grid, to_grid, revision, options, terrain_registry)
		cmd["_regional_navigation_search"] = search
	var limit := REGIONAL_NAVIGATION_EXPANSIONS_PER_SLICE
	if is_processing_tick:
		var unit_id := _extract_unit_id_for_path_recompute(unit)
		limit = int(_regional_navigation_admissions.get(unit_id, limit))
		limit = mini(limit, REGIONAL_NAVIGATION_EXPANSIONS_PER_TICK - _regional_navigation_expansions_this_tick)
	var started := Time.get_ticks_usec()
	_regional_navigation_expansions_this_tick += search.advance(_terrain_pathfinder, terrain_registry, limit)
	search.last_slice_usec = Time.get_ticks_usec() - started
	search.work_usec += search.last_slice_usec
	search.max_slice_usec = maxi(search.max_slice_usec, search.last_slice_usec)
	if not search.finished:
		return []
	cmd.erase("_regional_navigation_search")
	cmd["_regional_navigation_route"] = true
	var reached: bool = not search.path.is_empty() and search.path[-1] == to_grid
	if navigation_debug_enabled:
		var result := {"path": search.path, "status": "direct_a_star" if reached else "regional_nearest_reachable"}
		_annotate_navigation_query_metrics(result, search.path, terrain_registry, options)
		result["search_elapsed_usec"] = Time.get_ticks_usec() - search.started_usec
		result["search_max_slice_usec"] = search.max_slice_usec
		_record_navigation_path_query(cmd, unit, from_grid, to_grid, result, search.work_usec, "primary", "", search.expanded_count)
	var simplified := _simplify_grid_path_turns(search.path)
	var world_path: Array = []
	for index in range(1, simplified.size()):
		world_path.append(terrain_registry.call("grid_to_world", simplified[index]))
	if reached and (world_path.is_empty() or Vector2(world_path[-1]).distance_to(resolved_target) > 0.5):
		world_path.append(resolved_target)
	return world_path


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

	var options: Dictionary = {
		"cover_aware_enabled": cover_aware_enabled,
		"exposure_weight": float(weights.get("exposure_weight", navigation_default_exposure_weight)),
		"cover_weight": float(weights.get("cover_weight", navigation_default_cover_weight)),
		"exposure_max_grid_distance": float(cmd.get("navigation_exposure_max_grid_distance", navigation_exposure_max_grid_distance)),
		"hazard_grids": _extract_navigation_hazard_grids(cmd, terrain_registry),
	}
	_append_navigation_corridor_options(options, cmd, terrain_registry)
	return options


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


func _append_navigation_corridor_options(options: Dictionary, cmd: Dictionary, terrain_registry) -> void:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return
	if bool(cmd.get("navigation_corridor_enabled", false)):
		var start_position_variant: Variant = cmd.get("navigation_corridor_start_position", null)
		var end_position_variant: Variant = cmd.get("navigation_corridor_end_position", null)
		if typeof(start_position_variant) == TYPE_VECTOR2 and typeof(end_position_variant) == TYPE_VECTOR2:
			options["corridor_enabled"] = true
			options["corridor_from_grid"] = terrain_registry.call("world_to_grid", Vector2(start_position_variant))
			options["corridor_to_grid"] = terrain_registry.call("world_to_grid", Vector2(end_position_variant))
			options["corridor_half_width_grid"] = _world_distance_to_navigation_grid_distance(
				maxf(float(cmd.get("navigation_corridor_half_width_world", 0.0)), 0.0),
				terrain_registry
			)
			options["corridor_weight"] = maxf(float(cmd.get("navigation_corridor_weight", 0.0)), 0.0)
	if bool(cmd.get("navigation_lane_enabled", false)):
		options["lane_enabled"] = true
		var lane_sample_variant: Variant = cmd.get("navigation_lane_sample_position", null)
		if (
			bool(options.get("corridor_enabled", false))
			and typeof(lane_sample_variant) == TYPE_VECTOR2
			and options.has("corridor_from_grid")
			and options.has("corridor_to_grid")
		):
			options["lane_offset_grid"] = _signed_navigation_grid_line_distance(
				Vector2i(terrain_registry.call("world_to_grid", Vector2(lane_sample_variant))),
				Vector2i(options.get("corridor_from_grid", Vector2i.ZERO)),
				Vector2i(options.get("corridor_to_grid", Vector2i.ZERO))
			)
		else:
			options["lane_offset_grid"] = _world_distance_to_navigation_grid_distance(
				float(cmd.get("navigation_lane_offset_world", 0.0)),
				terrain_registry
			)
		options["lane_weight"] = maxf(float(cmd.get("navigation_lane_weight", 0.0)), 0.0)
	if cmd.has("navigation_blocker_clearance_weight"):
		options["blocker_clearance_weight"] = maxf(float(cmd.get("navigation_blocker_clearance_weight", 0.0)), 0.0)
	if cmd.has("navigation_blocker_clearance_radius"):
		options["blocker_clearance_radius"] = maxi(int(cmd.get("navigation_blocker_clearance_radius", 1)), 1)


func _world_distance_to_navigation_grid_distance(world_distance: float, terrain_registry) -> float:
	if is_zero_approx(world_distance):
		return 0.0
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return world_distance
	var origin_world: Vector2 = Vector2(terrain_registry.call("grid_to_world", Vector2i.ZERO))
	var x_world: Vector2 = Vector2(terrain_registry.call("grid_to_world", Vector2i.RIGHT))
	var y_world: Vector2 = Vector2(terrain_registry.call("grid_to_world", Vector2i.DOWN))
	var tile_world_distance: float = maxf((x_world - origin_world).length(), (y_world - origin_world).length())
	if tile_world_distance <= 0.001:
		return world_distance
	return world_distance / tile_world_distance


func _signed_navigation_grid_line_distance(grid_position: Vector2i, from_grid: Vector2i, to_grid: Vector2i) -> float:
	var from_value: Vector2 = Vector2(from_grid)
	var to_value: Vector2 = Vector2(to_grid)
	var point_value: Vector2 = Vector2(grid_position)
	var line: Vector2 = to_value - from_value
	var length: float = line.length()
	if length <= 0.001:
		return 0.0
	return line.cross(point_value - from_value) / length


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
	var tile_count: int = int(terrain_registry.call("get_tile_count")) if terrain_registry.has_method("get_tile_count") else Array(terrain_registry.call("get_all_tiles")).size()
	var registry_revision: int = _get_terrain_registry_revision(terrain_registry)
	if (
		_hpa_navigation_graph != null
		and _hpa_navigation_registry == terrain_registry
		and _hpa_navigation_tile_count == tile_count
		and _hpa_navigation_registry_revision == registry_revision
	):
		_hpa_navigation_cache_hit_count += 1
		return _hpa_navigation_graph
	var incremental_candidate: bool = (
		_hpa_navigation_graph != null
		and _hpa_navigation_registry == terrain_registry
		and _hpa_navigation_tile_count == tile_count
		and _hpa_navigation_graph.has_method("rebuild_dirty_clusters_from_registry")
	)
	var dirty_grids: Array = _get_terrain_registry_dirty_grids(terrain_registry) if incremental_candidate else []
	if not dirty_grids.is_empty():
		var incremental_built: bool = bool(_hpa_navigation_graph.call("rebuild_dirty_clusters_from_registry", terrain_registry, dirty_grids, HPA_NAVIGATION_CLUSTER_SIZE))
		_hpa_navigation_build_count += 1
		_hpa_navigation_last_build_stats = _get_hpa_graph_build_stats(_hpa_navigation_graph)
		_hpa_navigation_last_build_stats["registry_revision"] = registry_revision
		_hpa_navigation_last_build_stats["runtime_build_count"] = _hpa_navigation_build_count
		_hpa_navigation_last_build_stats["runtime_rebuild_mode"] = "incremental"
		if incremental_built:
			_hpa_navigation_registry_revision = registry_revision
			_clear_terrain_registry_dirty_grids(terrain_registry)
			return _hpa_navigation_graph
	_hpa_navigation_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	var built: bool = bool(_hpa_navigation_graph.call("build_from_registry", terrain_registry, HPA_NAVIGATION_CLUSTER_SIZE))
	_hpa_navigation_build_count += 1
	_hpa_navigation_last_build_stats = _get_hpa_graph_build_stats(_hpa_navigation_graph)
	_hpa_navigation_last_build_stats["registry_revision"] = registry_revision
	_hpa_navigation_last_build_stats["runtime_build_count"] = _hpa_navigation_build_count
	_hpa_navigation_last_build_stats["runtime_rebuild_mode"] = "full"
	if not built:
		_hpa_navigation_graph = null
		_hpa_navigation_registry = null
		_hpa_navigation_tile_count = -1
		_hpa_navigation_registry_revision = -1
		return null
	_hpa_navigation_registry = terrain_registry
	_hpa_navigation_tile_count = tile_count
	_hpa_navigation_registry_revision = registry_revision
	_clear_terrain_registry_dirty_grids(terrain_registry)
	return _hpa_navigation_graph


func _get_terrain_registry_revision(terrain_registry) -> int:
	if terrain_registry != null and terrain_registry.has_method("get_revision"):
		return int(terrain_registry.call("get_revision"))
	return -1


func _get_terrain_registry_dirty_grids(terrain_registry) -> Array:
	if terrain_registry != null and terrain_registry.has_method("get_dirty_grid_positions"):
		return Array(terrain_registry.call("get_dirty_grid_positions"))
	return []


func _clear_terrain_registry_dirty_grids(terrain_registry) -> void:
	if terrain_registry != null and terrain_registry.has_method("clear_dirty_grid_positions"):
		terrain_registry.call("clear_dirty_grid_positions")


func _get_hpa_graph_build_stats(graph) -> Dictionary:
	if graph != null and graph.has_method("get_last_build_stats"):
		return Dictionary(graph.call("get_last_build_stats")).duplicate(true)
	return {}


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
	var target_cover_score: float = _extract_effective_cover_score(unit)
	if effect.has("target_cover_override"):
		target_cover_score = clampf(_extract_float(effect.get("target_cover_override", target_cover_score), target_cover_score), 0.0, 80.0)
	var attacker_attack_bonus: float = _extract_unit_attack_bonus(attacker_unit)
	var attacker_cover_score: float = _extract_unit_cover_score(attacker_unit)
	var target_cover_ratio: float = _normalize_cover_score_for_combat(target_cover_score)
	var attacker_cover_ratio: float = _normalize_cover_score_for_combat(attacker_cover_score)
	var hit_chance: float = _extract_float(effect.get("hit_chance", 1.0), 1.0)
	hit_chance *= _extract_unit_accuracy_multiplier(attacker_unit)
	hit_chance = clampf(
		hit_chance
		+ attacker_attack_bonus
		+ _extract_unit_hit_modifier(attacker_unit)
		+ _extract_height_accuracy_modifier(attacker_unit, unit)
		+ (attacker_cover_ratio * ATTACKER_COVER_HIT_BONUS_FACTOR)
		- _extract_unit_evasion_modifier(unit)
		- (target_cover_ratio * TARGET_COVER_HIT_PENALTY_FACTOR),
		HIT_CHANCE_MIN,
		HIT_CHANCE_MAX
	)
	var roll: float = _extract_damage_roll(effect)
	var damage_multiplier: float = _extract_float(effect.get("damage_multiplier", 1.0), 1.0)
	damage_multiplier = maxf(damage_multiplier + attacker_attack_bonus - (target_cover_ratio * TARGET_COVER_DAMAGE_PENALTY_FACTOR), DAMAGE_MULTIPLIER_MIN)
	damage_multiplier *= _extract_unit_damage_taken_multiplier(unit)
	var damage_model = DAMAGE_MODEL_SCRIPT.new()
	if not bool(damage_model.call("resolve_hit", hit_chance, roll)):
		_emit_damage_effect_resolution(_build_damage_effect_resolution(
			effect,
			unit,
			attacker_unit,
			false,
			hit_chance,
			roll,
			base_damage,
			0,
			damage_multiplier,
			attacker_attack_bonus,
			attacker_cover_score,
			attacker_cover_ratio,
			target_cover_score,
			target_cover_ratio,
			is_friendly_fire
		))
		return

	var resolved_damage: int = int(damage_model.call("resolve_damage", base_damage, damage_multiplier))
	if resolved_damage <= 0:
		_emit_damage_effect_resolution(_build_damage_effect_resolution(
			effect,
			unit,
			attacker_unit,
			true,
			hit_chance,
			roll,
			base_damage,
			resolved_damage,
			damage_multiplier,
			attacker_attack_bonus,
			attacker_cover_score,
			attacker_cover_ratio,
			target_cover_score,
			target_cover_ratio,
			is_friendly_fire
		))
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
		"target_cover_ratio": target_cover_ratio,
		"attacker_cover_score": attacker_cover_score,
		"attacker_cover_ratio": attacker_cover_ratio,
		"resolved_hit_chance": hit_chance,
		"roll": roll,
		"damage_multiplier": damage_multiplier,
		"friendly_fire": is_friendly_fire,
		"weapon_id": String(effect.get("weapon_id", "")),
		"fire_event_id": String(effect.get("fire_event_id", "")),
	}
	if bool(effect.get("is_flank", false)):
		hit_context["is_flank"] = true
		hit_context["flank_fireteam_id"] = String(effect.get("flank_fireteam_id", ""))
		hit_context["flank_source_angle"] = _extract_float(effect.get("flank_source_angle", 0.0), 0.0)
		hit_context["flank_direction_label"] = String(effect.get("flank_direction_label", "")).strip_edges().to_lower()
		hit_context["flank_morale_state"] = String(effect.get("flank_morale_state", "")).strip_edges().to_lower()
	unit.call("apply_damage", resolved_damage, hit_context)
	if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
		# Effects follow commands: cancel this tick's continuation before a heal/respawn can restore fitness.
		_discard_pending_move_commands_for_unit(unit_id)
	_emit_damage_effect_resolution(_build_damage_effect_resolution(
		effect,
		unit,
		attacker_unit,
		true,
		hit_chance,
		roll,
		base_damage,
		resolved_damage,
		damage_multiplier,
		attacker_attack_bonus,
		attacker_cover_score,
		attacker_cover_ratio,
		target_cover_score,
		target_cover_ratio,
		is_friendly_fire
	))


func _build_damage_effect_resolution(
	effect: Dictionary,
	unit,
	attacker_unit,
	did_hit: bool,
	hit_chance: float,
	roll: float,
	base_damage: int,
	resolved_damage: int,
	damage_multiplier: float,
	attacker_attack_bonus: float,
	attacker_cover_score: float,
	attacker_cover_ratio: float,
	target_cover_score: float,
	target_cover_ratio: float,
	is_friendly_fire: bool
) -> Dictionary:
	var target_health_points: int = -1
	var target_vital_state: String = ""
	if unit != null:
		if unit.has_method("get_health_points"):
			target_health_points = int(unit.call("get_health_points"))
		elif unit.has_method("get_health"):
			target_health_points = int(unit.call("get_health"))
		if unit.has_method("get_vital_state"):
			target_vital_state = String(unit.call("get_vital_state"))
	return {
		"effect_type": "damage",
		"unit_id": String(effect.get("unit_id", "")),
		"target_unit_id": String(effect.get("unit_id", "")),
		"attacker_unit_id": String(effect.get("attacker_unit_id", "")),
		"attacker_team_id": String(effect.get("attacker_team_id", "")),
		"weapon_id": String(effect.get("weapon_id", "")),
		"fire_event_id": String(effect.get("fire_event_id", "")),
		"hit": did_hit,
		"outcome": "hit" if did_hit else "miss",
		"hit_chance_resolved": hit_chance,
		"roll": roll,
		"base_damage": base_damage,
		"damage_resolved": resolved_damage,
		"damage_multiplier_resolved": damage_multiplier,
		"attacker_attack_bonus": attacker_attack_bonus,
		"attacker_cover_score": attacker_cover_score,
		"attacker_cover_ratio": attacker_cover_ratio,
		"target_cover_score": target_cover_score,
		"target_cover_ratio": target_cover_ratio,
		"target_health_points": target_health_points,
		"target_vital_state": target_vital_state,
		"target_position": _get_unit_world_position_for_damage_resolution(unit),
		"attacker_position": _get_unit_world_position_for_damage_resolution(attacker_unit),
		"friendly_fire": is_friendly_fire,
	}


func _emit_damage_effect_resolution(result: Dictionary) -> void:
	var snapshot: Dictionary = result.duplicate(true)
	snapshot["read_only"] = true
	_last_damage_effect_resolution = snapshot
	damage_effect_resolved.emit(snapshot.duplicate(true))


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


func get_unit_registry():
	return _get_unit_registry()


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


func _extract_unit_cover_score(unit) -> float:
	if unit == null or not unit.has_method("get_cover_score"):
		return 0.0

	return float(unit.call("get_cover_score"))


func _normalize_cover_score_for_combat(cover_score: float) -> float:
	return clampf(cover_score / 100.0, 0.0, 1.0)


func _extract_effective_cover_score(unit) -> float:
	var command_cover_score: float = _extract_unit_cover_score(unit)
	var terrain_cover_score: float = _extract_terrain_cover_score(unit)
	return clampf(command_cover_score + terrain_cover_score, 0.0, 80.0)


func _extract_terrain_cover_score(unit) -> float:
	if is_hex_ground_runtime_active():
		var state := _hex_ground_state_for_unit(unit)
		return float(_hex_ground_registry.call("get_cover_at",state.grid)) if not state.is_empty() else 0.0
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D) or not terrain_registry.has_method("get_cover_at_world"):
		return 0.0

	return float(terrain_registry.call("get_cover_at_world", (unit as Node2D).global_position))


func _get_unit_world_position_for_damage_resolution(unit) -> Vector2:
	if is_hex_ground_runtime_active():
		var state := _hex_ground_state_for_unit(unit)
		return Vector2(_hex_ground_registry.call("grid_to_world",state.grid)) if not state.is_empty() else Vector2.ZERO
	if unit is Node2D:
		return (unit as Node2D).global_position
	return Vector2.ZERO


func _hex_ground_state_for_unit(unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.has_method("get_unit_id"):
		return {}
	return get_hex_unit_state(String(unit.call("get_unit_id")))


func _extract_unit_attack_bonus(unit) -> float:
	if unit == null or not unit.has_method("get_attack_bonus"):
		return 0.0

	return float(unit.call("get_attack_bonus"))


func _extract_height_accuracy_modifier(attacker_unit, target_unit) -> float:
	if is_hex_ground_runtime_active():
		var source := _hex_ground_state_for_unit(attacker_unit)
		var destination := _hex_ground_state_for_unit(target_unit)
		if source.is_empty() or destination.is_empty():
			return 0.0
		var difference := clampf(float(int(source.stand_height_steps2)-int(destination.stand_height_steps2))*0.5,-2.0,2.0)
		return HEIGHT_ADVANTAGE_ACCURACY_BONUS*difference if difference>=0.0 else HEIGHT_DISADVANTAGE_ACCURACY_PENALTY*difference
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or attacker_unit == null or target_unit == null:
		return 0.0

	if not (attacker_unit is Node2D) or not (target_unit is Node2D):
		return 0.0

	var attacker_height: int = int(terrain_registry.call("get_height_at_world", (attacker_unit as Node2D).global_position))
	var target_height: int = int(terrain_registry.call("get_height_at_world", (target_unit as Node2D).global_position))
	# Additional terrain elevations extend geometry, not the existing accuracy budget.
	var height_difference: int = clampi(attacker_height - target_height, -2, 2)
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
	var hex_mode:bool=is_hex_ground_runtime_active()
	var objective_grid:Vector2i=_hex_ground_registry.call("world_to_grid",objective_position) if hex_mode else Vector2i.ZERO
	var hex_spacing:float=float(_hex_ground_registry.call("get_movement_distance",_hex_ground_registry.call("grid_to_world",Vector2i.ZERO),_hex_ground_registry.call("grid_to_world",Vector2i.RIGHT))) if hex_mode else 1.0
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

		var distance:float=0.0
		if hex_mode:
			if not unit.has_method("get_unit_id"):continue
			var grid:Variant=_hex_ground_runtime.get_unit_grid(String(unit.call("get_unit_id")))
			if not grid is Vector2i:continue
			distance=float(HEX_GRID_SCRIPT.distance(grid,objective_grid))*hex_spacing
		else:distance=(unit as Node2D).global_position.distance_to(objective_position)
		if distance <= capture_radius:
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
	unit.set_meta("dropship_embarked", true)
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
	unit.set_meta("dropship_embarked", false)
	_apply_dropship_runtime_activation(unit_id, unit, effect)
	_apply_dropship_position_and_visibility(unit, effect, true)
	var runtime_status: String = String(effect.get("runtime_status", "")).strip_edges()
	if not runtime_status.is_empty() and unit.has_method("set_runtime_status"):
		unit.call("set_runtime_status", runtime_status)
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")


func _apply_air_asset_status_update_effect(effect: Dictionary) -> void:
	var status_snapshot: Dictionary = Dictionary(effect.get("status_snapshot", effect.get("air_asset_status", {}))).duplicate(true)
	if status_snapshot.is_empty():
		status_snapshot = {
			"asset_id": String(effect.get("asset_id", "")).strip_edges(),
			"asset_type": String(effect.get("asset_type", "")).strip_edges(),
			"state": String(effect.get("state", "")).strip_edges(),
		}
	var asset_id: String = String(status_snapshot.get("asset_id", effect.get("asset_id", ""))).strip_edges()
	if asset_id.is_empty():
		push_warning("SimulationRoot air asset status effect expects a non-empty asset_id.")
		return
	status_snapshot["asset_id"] = asset_id
	status_snapshot["asset_type"] = String(status_snapshot.get("asset_type", effect.get("asset_type", "dropship"))).strip_edges()
	status_snapshot["state"] = String(status_snapshot.get("state", effect.get("state", "intact"))).strip_edges()
	status_snapshot["last_event_id"] = String(status_snapshot.get("last_event_id", effect.get("event_id", ""))).strip_edges()
	status_snapshot["vfx_events"] = Array(effect.get("vfx_events", status_snapshot.get("vfx_events", []))).duplicate(true)
	status_snapshot["sfx_events"] = Array(effect.get("sfx_events", status_snapshot.get("sfx_events", []))).duplicate(true)
	status_snapshot["runtime_authority"] = "SimulationRoot"
	status_snapshot["applied_by"] = "SimulationRoot"
	status_snapshot["applied_tick"] = tick_counter
	status_snapshot["ui_sets_gameplay_truth"] = false
	_air_asset_status_by_id[asset_id] = status_snapshot


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


func _apply_unit_combat_posture_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		push_warning("SimulationRoot combat posture effect expects a non-empty unit_id.")
		return
	var unit = _resolve_known_unit(unit_id)
	if unit == null or not (unit is Node):
		push_warning("SimulationRoot could not resolve the target unit for a combat posture effect.")
		return
	var unit_node: Node = unit as Node
	var facing_value: Variant = effect.get("facing_angle", null)
	if typeof(facing_value) == TYPE_FLOAT or typeof(facing_value) == TYPE_INT:
		var facing_angle: float = float(facing_value)
		unit_node.set_meta("facing_angle", facing_angle)
		unit_node.set_meta("map_facing_angle", facing_angle)
		if bool(effect.get("enemy_facing", false)):
			unit_node.set_meta("enemy_facing_angle", facing_angle)

	if not bool(effect.get("apply_posture", false)):
		return
	if not unit.has_method("get_runtime_status") or not unit.has_method("set_runtime_status"):
		push_warning("SimulationRoot combat posture effect expects a unit runtime status interface.")
		return
	var runtime_status = unit.call("get_runtime_status")
	if runtime_status == null or not runtime_status.has_method("get"):
		push_warning("SimulationRoot combat posture effect requires a readable runtime status.")
		return
	var movement_posture: String = String(effect.get("movement_posture", runtime_status.get("movement_posture"))).strip_edges().to_lower()
	var weapon_posture: String = String(effect.get("weapon_posture", runtime_status.get("weapon_posture"))).strip_edges().to_lower()
	var posture_policy_id: String = String(effect.get("posture_policy_id", runtime_status.get("posture_policy_id"))).strip_edges().to_lower()
	var move_speed_factor: float = float(effect.get("move_speed_factor", runtime_status.get("move_speed_factor")))
	unit.call(
		"set_runtime_status",
		String(runtime_status.get("status")),
		String(runtime_status.get("active_command_type")),
		int(runtime_status.get("priority")),
		String(runtime_status.get("fire_status")),
		String(runtime_status.get("source_command_type")),
		move_speed_factor,
		float(runtime_status.get("cover_score")),
		float(runtime_status.get("attack_bonus")),
		int(runtime_status.get("phase")),
		runtime_status.get("target_position"),
		movement_posture,
		weapon_posture,
		posture_policy_id,
		float(runtime_status.get("sight_range_factor")),
		float(runtime_status.get("aim_readiness_percent"))
	)
	if bool(effect.get("enemy_facing", false)):
		unit_node.set_meta("enemy_movement_posture", movement_posture)
		unit_node.set_meta("enemy_weapon_posture", weapon_posture)
		unit_node.set_meta("enemy_posture_policy_id", posture_policy_id)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	return fallback


var _location_resource_owner: Node
func configure_location_resources(owner: Node) -> void:
	_location_resource_owner=owner
func request_location_resource_command(operation: String, payload: Dictionary) -> Dictionary:
	if not is_instance_valid(_location_resource_owner): return {"ok":false,"reason":"resource_owner_missing"}
	return _location_resource_owner.call("apply_operation",operation,payload)
