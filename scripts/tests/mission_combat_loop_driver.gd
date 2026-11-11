extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const COMBAT_VISIBILITY_CACHE_SCRIPT: GDScript = preload("res://scripts/mission/combat_visibility_cache.gd")
const HEX_SIGHT_ADAPTER_SCRIPT = preload("res://scripts/core/hex_sight_runtime_adapter.gd")
const HEX_DETECTION_STATE_SCRIPT = preload("res://scripts/core/hex_detection_state.gd")
const OVERWATCH_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/overwatch_controller.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const COMBAT_DECISION_INTERVAL_TICKS: int = 3
const CONTACT_TRACKER_SCRIPT: GDScript = preload("res://scripts/tactical/contact_tracker.gd")
const FLANK_VULNERABILITY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/flank_vulnerability_resolver.gd")
const MEDIC_SUPPORT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/medic_support_resolver.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_limbo_behavior_adapter.gd")
const ENEMY_BEHAVIOR_ORCHESTRATOR_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_behavior_orchestrator.gd")
const TACTICAL_COMMUNICATION_EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_authority_contract.gd")
const MISSION_COMBAT_REMOTE_EVENT_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_remote_event_bridge.gd")
const MISSION_COMBAT_RESOLUTION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_resolution_resolver.gd")
const MISSION_SCENARIO_RUNTIME_GATES_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_runtime_gates.gd")
const MISSION_CARGO_TOUCHDOWN_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_cargo_touchdown_bridge.gd")
const MISSION_INTERACTION_BINDING_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const MISSION_INTERACTION_DOOR_RUNTIME_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_door_runtime_collision_los.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const COMBAT_READABILITY_PRESENTER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_readability_presenter.gd")
const WIN_CONDITION_ELIMINATION: String = "elimination"
const WIN_CONDITION_OBJECTIVE_CAPTURE: String = "objective_capture"
const WIN_CONDITION_OBJECTIVE_DEFENSE: String = "objective_defense"
const DEFAULT_EVENT_COLOR: Color = Color(1.0, 0.95, 0.5, 1.0)
const HIT_EVENT_COLOR: Color = Color(1.0, 0.78, 0.35, 1.0)
const DOWN_EVENT_COLOR: Color = Color(1.0, 0.55, 0.55, 1.0)
const BLEEDOUT_EVENT_COLOR: Color = Color(0.92, 0.6, 0.6, 1.0)
const RESPAWN_EVENT_COLOR: Color = Color(0.72, 0.9, 1.0, 1.0)
const EVENT_DEFAULT_DURATION: float = 1.2
const LEADERSHIP_BONUS_FACTOR: float = 0.15
const LEADERSHIP_EVENT_COLOR: Color = Color(0.6, 0.85, 1.0, 1.0)
const MAX_DETECTION_DELAY_TICKS: int = 15
const CONTACT_INITIATIVE_BASELINE_SECONDS: float = 2.0
const AIM_READINESS_BASELINE_PERCENT: float = 50.0
const AIM_READINESS_MAX_DELAY_DELTA_TICKS: int = 4
const RECENT_FIRE_EVENT_TTL_TICKS: int = 72
const MAX_RECENT_FIRE_EVENTS: int = 8
const DOWN_STATE_VISIBLE_MIN_SECONDS: float = 3.0
const TACTICAL_COMBAT_VISUAL_REFRESH_INTERVAL_MSEC: int = 160
const COMBAT_HOTPATH_AUDIT_BUCKET_CELL_SIZE: float = 256.0
const DETECTION_EVENT_COLOR: Color = Color(0.85, 0.85, 0.55, 1.0)
const STEALTH_RANGE_REDUCTION_FACTOR: float = 0.5
const SPOTTED_CONTACT_HIT_CHANCE_MALUS: float = -0.15
const DISCIPLINE_BREAK_BASE_CHANCE: float = 0.08
const DISCIPLINE_BREAK_COOLDOWN_TICKS: int = 10
const DISCIPLINE_BREAK_EVENT_COLOR: Color = Color(1.0, 0.65, 0.3, 1.0)
const RETURN_FIRE_WINDOW_TICKS: int = 18
const MISIDENTIFICATION_BASE_CHANCE: float = 0.03
const MISIDENTIFICATION_COOLDOWN_TICKS: int = 15
const MISIDENTIFICATION_EVENT_COLOR: Color = Color(1.0, 0.4, 0.4, 1.0)
const MEDIC_SUPPORT_TILE_RANGE: int = 1
const MEDIC_SUPPORT_MOVE_MAX_TILE_DISTANCE: int = 3
const MEDIC_SUPPORT_RANGE_FALLBACK_WORLD: float = 80.0
const MEDIC_SUPPORT_MOVE_MAX_DISTANCE_FALLBACK_WORLD: float = 216.0
const MEDIC_SUPPORT_MOVE_SPEED_FACTOR: float = 0.55
const MEDIC_SUPPORT_MOVE_REISSUE_TICKS: int = 4
const MEDIC_SUPPORT_APPROACH_STANDOFF: float = 28.0
const MEDIC_SUPPORT_WOUNDED_THRESHOLD: float = 0.65
const MEDIC_SUPPORT_REMOTE_WOUNDED_THRESHOLD: float = 0.45
const MEDIC_SUPPORT_HEAL_AMOUNT: int = 35
const MEDIC_SUPPORT_COOLDOWN_TICKS: int = 12
const MEDIC_SUPPORT_PRIORITY: int = 25
const MEDIC_SUPPORT_MOVE_PRIORITY: int = 14
const MEDIC_EVENT_COLOR: Color = Color(0.55, 1.0, 0.72, 1.0)
const FRIENDLY_STANDARD_COVER_RADIUS: float = 48.0
const FRIENDLY_STANDARD_COVER_MIN_DISTANCE: float = 10.0
const FRIENDLY_STANDARD_COVER_COOLDOWN_MSEC: int = 1600
const FRIENDLY_LOW_COVER_THRESHOLD: int = 16
const ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE: float = 18.0
const ENEMY_TACTICS_PUSH_STEP_DISTANCE: float = 144.0
const ENEMY_TACTICS_PROBE_STEP_DISTANCE: float = 96.0
const ENEMY_TACTICS_BOUND_STEP_DISTANCE: float = 128.0
const ENEMY_TACTICS_COVER_SEARCH_RADIUS: float = 220.0
const ENEMY_POSTURE_TRAVEL: String = "travel"
const ENEMY_POSTURE_TACTICAL: String = "tactical"
const ENEMY_POSTURE_ENGAGE: String = "engage"
const ENEMY_POSTURE_OVERWATCH: String = "overwatch"
const ENEMY_WEAPON_LOWERED: String = "lowered"
const ENEMY_WEAPON_READY: String = "ready"
const ENEMY_WEAPON_AIMED: String = "aimed"

signal contact_established(attacker, target)
signal combat_resolved(mission_result: Dictionary)

@export var friendly_team_id: String = "team_alpha"
@export var contact_range: float = 180.0
@export var damage_per_hit: int = 40
@export var base_hit_chance: float = 0.45
@export var base_damage_multiplier: float = 1.0
@export var ticks_between_attacks: int = 10
@export var enemy_advance_enabled: bool = true
@export var enemy_advance_speed_factor: float = 0.3
@export var enemy_engage_distance: float = 200.0
@export var enemy_reposition_enabled: bool = true
@export var enemy_reposition_cooldown_seconds: float = 4.0
@export var enemy_reposition_min_distance: float = 30.0
@export var enemy_reposition_max_distance: float = 60.0
@export var enemy_reposition_move_speed_factor: float = 0.45
@export var enemy_limbo_behavior_smoke_enabled: bool = true
@export var enemy_limbo_cover_cooldown_seconds: float = 2.0
@export var enemy_limbo_cover_min_cover_score: int = 20
@export var enemy_limbo_cover_search_radius: float = 160.0
@export var enemy_limbo_cover_min_distance: float = 16.0
@export var win_condition: String = WIN_CONDITION_ELIMINATION
@export var objective_defense_hold_seconds: float = 8.0
@export var mission_time_limit_seconds: float = 0.0
@export var mission_timer_started_at_msec: int = 0
@export var simulation_root_path: NodePath
@export var status_label_path: NodePath
@export var friendly_unit_paths: Array[NodePath] = []
@export var enemy_unit_paths: Array[NodePath] = []
@export var respawn_manager_path: NodePath
@export var enemy_wave_controller_path: NodePath
@export var terrain_registry_path: NodePath
@export var combat_visibility_cache_path: NodePath
@export var tactical_controller_path: NodePath
@export var preview_mode: bool = false
@export var combat_tick_budget_debug_enabled: bool = false
@export var flank_vulnerability_enabled: bool = false
var use_observed_fire_candidate_index: bool = true

func set_use_observed_fire_candidate_index(enabled: bool) -> void:
	use_observed_fire_candidate_index = enabled

func get_resolver_target_evaluation_count() -> int:
	return _resolver_target_evaluation_count

func _record_resolver_target_evaluation(_attacker, _target) -> void:
	_resolver_target_evaluation_count += 1

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _queued_bleedout_by_unit_id: Dictionary = {}
var _down_state_started_msec_by_unit_id: Dictionary = {}
var _enemy_reposition_ready_at_msec: Dictionary = {}
var _combat_finished: bool = false
var _winning_team_id: String = ""
var _last_contact: Dictionary = {}
var _current_tick: int = 0
var _fire_candidate_target_ids_by_attacker_id: Dictionary = {}
var _fire_candidate_index_tick: int = -1
var _fire_candidate_index_pair_count: int = 0
var _resolver_target_evaluation_count: int = 0
var _next_attack_tick: int = 1
var _last_event_text: String = "Combat waiting"
var _mission_started_at_msec: int = 0
var _objective_owned_since_msec: int = -1
var _mission_result: Dictionary = {}
var _mission_result_condition_override: String = ""
var _runs_local_authority: bool = true
var _combat_startup_grace_ticks: int = 0
var _last_standard_attacker_fireteam_id: String = ""
var _fireteam_original_leads: Dictionary = {}
var _fireteam_acting_leads: Dictionary = {}
var _fireteam_members: Dictionary = {}
var _detection_progress: Dictionary = {}
var _hex_sight_adapter = HEX_SIGHT_ADAPTER_SCRIPT.new()
var _hex_detection_state = HEX_DETECTION_STATE_SCRIPT.new()
var _hex_detection_context := ""
var _hex_adapter_initialized := false
var _hex_adapter_owner_path: NodePath
var _hex_adapter_cache_path: NodePath
var _hex_adapter_arc := -1.0
@export_range(0.0, 360.0, 1.0) var hex_sight_arc_degrees := 120.0
var _discipline_break_cooldown: Dictionary = {}
var _recent_incoming_fire_tick_by_fireteam: Dictionary = {}
var _misidentification_cooldown: Dictionary = {}
var _medic_support_cooldown: Dictionary = {}
var _medic_support_move_ready_tick: Dictionary = {}
var _friendly_cover_ready_at_msec: Dictionary = {}
var _enemy_limbo_cover_ready_at_msec: Dictionary = {}
var _enemy_limbo_behavior_decisions: Dictionary = {}
var _overlays_visible: bool = true
var _enemy_patrol_paths_by_unit_id: Dictionary = {}
var _enemy_patrol_waypoint_index_by_unit_id: Dictionary = {}
var _enemy_patrol_contact_locked: Dictionary = {}
var _enemy_security_states_by_group_id: Dictionary = {}
var _enemy_team_tactics_states_by_group_id: Dictionary = {}
var _enemy_team_tactics_input_signature: String = ""
var _enemy_team_tactics_input_signature_initialized: bool = false
var _enemy_team_tactics_rebuild_count: int = 0
var _enemy_team_tactics_skip_count: int = 0
var _recent_fire_events: Array = []
var _remote_contact_snapshot: Array = []
var _combat_outcome_by_fire_event_id: Dictionary = {}
var _next_fire_event_sequence: int = 1
var _combat_tick_budget_debug_snapshot: Dictionary = {}
var _combat_hotspot_profile: Dictionary = {"counts": {}, "usec": {}}
var _combat_fire_decision_debug_scopes_usec: Dictionary = {}
var _last_contact_decision_diagnostics: Dictionary = {}
var _suppress_fire_outcome_diagnostic_count: int = 0
var _suppress_fire_outcome_diagnostic_by_fireteam: Dictionary = {}
var _suppress_fire_outcome_diagnostic_keys_seen: Dictionary = {}
var _last_suppress_fire_outcome_diagnostic: Dictionary = {}
var _hotpath_unit_cache_active: bool = false
var _hotpath_unit_cache_tick: int = -1
var _hotpath_friendly_units: Array = []
var _hotpath_enemy_units: Array = []
var _hotpath_friendly_combat_units: Array = []
var _hotpath_enemy_combat_units: Array = []
var _last_contact_tracking_scan_pair_count: int = 0
var _last_contact_tracking_los_check_count: int = 0
var _last_contact_tracking_los_cache_hit_count: int = 0
var _last_fire_candidate_pair_scan_count: int = 0
var _last_tactical_combat_visual_refresh_msec: int = 0
var _tactical_combat_visual_refresh_pending: bool = false
var _tactical_combat_visual_refresh_count: int = 0
var _tactical_combat_visual_refresh_suppressed_count: int = 0
var _has_seen_active_friendly_units: bool = false
var _has_seen_active_enemy_units: bool = false
var _resolved_without_seen_friendly: bool = false
var _overwatch_controller = OVERWATCH_CONTROLLER_SCRIPT.new()
var _contact_tracker = CONTACT_TRACKER_SCRIPT.new()
var _flank_vulnerability_resolver = FLANK_VULNERABILITY_RESOLVER_SCRIPT.new()
var _enemy_limbo_behavior_adapter = ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.new()
var _enemy_behavior_orchestrator = ENEMY_BEHAVIOR_ORCHESTRATOR_SCRIPT.new()
var _remote_event_bridge = MISSION_COMBAT_REMOTE_EVENT_BRIDGE_SCRIPT.new()
var _combat_resolution_resolver = MISSION_COMBAT_RESOLUTION_RESOLVER_SCRIPT.new()
var _mission_scenario_runtime_gates = MISSION_SCENARIO_RUNTIME_GATES_SCRIPT.new()
var _mission_scenario_runtime_gate_snapshot: Dictionary = {}
var _mission_scenario_runtime_step_states: Dictionary = {}
var _mission_scenario_completed_step_ids: Array = []
var _mission_scenario_cargo_state: String = ""
var _mission_scenario_cargo_hold_seconds: float = 0.0
var _mission_cargo_touchdown_bridge = MISSION_CARGO_TOUCHDOWN_BRIDGE_SCRIPT.new()
var _mission_cargo_touchdown_snapshot: Dictionary = {}
var _mission_interaction_runtime_states: Dictionary = {}
# Static binding index and a derived terrain receipt, never a second Door state.
var _mission_interaction_door_bindings: Array = []
var _mission_interaction_door_runtime_configured: bool = false
var _mission_interaction_door_runtime_dirty: bool = true
var _mission_interaction_door_runtime_snapshot: Dictionary = {}
var _mission_interaction_door_runtime_fingerprint: String = ""
var _mission_interaction_door_runtime_registry_id: int = 0
var _mission_interaction_door_runtime_registry_revision: int = -1
var _mission_interaction_door_runtime_map_id: int = 0
var _mission_interaction_door_runtime_map_signature: String = ""
var _mission_interaction_door_runtime_apply_count: int = 0
var _pending_network_mission_interactions: Dictionary = {}
var _readability_presenter = COMBAT_READABILITY_PRESENTER_SCRIPT.new()
var _audio_event_bus = null


func _ready() -> void:
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		push_warning("MissionCombatLoopDriver requires a direct SimulationRoot reference.")
		return

	_runs_local_authority = _should_run_local_combat(simulation_root)
	if _runs_local_authority:
		_connect_unit_signals()
		_connect_respawn_signals()
		_connect_wave_controller_signals()
		_init_fireteam_leadership()
		_initialize_enemy_patrol_paths()
	if preview_mode:
		_apply_overlay_visibility()
	else:
		call_deferred("_finish_readability_setup")
	if mission_timer_started_at_msec != 0:
		_mission_started_at_msec = mission_timer_started_at_msec
	elif preview_mode:
		_mission_started_at_msec = 0
	else:
		_mission_started_at_msec = Time.get_ticks_msec()

	if _runs_local_authority:
		_sync_objective_countdown_state()

	if _runs_local_authority and simulation_root.has_signal("damage_effect_resolved"):
		var damage_resolved_callable := Callable(self, "_on_damage_effect_resolved")
		if not simulation_root.is_connected("damage_effect_resolved", damage_resolved_callable):
			simulation_root.connect("damage_effect_resolved", damage_resolved_callable)

	if _runs_local_authority and not simulation_root.tick_processed.is_connected(_on_tick_processed):
		simulation_root.tick_processed.connect(_on_tick_processed)
	if _runs_local_authority and simulation_root.has_signal("network_command_accepted"):
		var network_interaction_callable := Callable(self, "_on_network_command_accepted")
		if not simulation_root.is_connected("network_command_accepted", network_interaction_callable):
			simulation_root.connect("network_command_accepted", network_interaction_callable)
	if _runs_local_authority and simulation_root.has_method("set_network_command_preflight_validator"):
		simulation_root.call("set_network_command_preflight_validator", Callable(self, "_validate_network_interaction_command_preflight"))

	_update_status_label("waiting" if _runs_local_authority else "observing")


func _exit_tree() -> void:
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root != null and simulation_root.has_method("clear_network_command_preflight_validator"):
		simulation_root.call("clear_network_command_preflight_validator", Callable(self, "_validate_network_interaction_command_preflight"))


func is_combat_finished() -> bool:
	return _combat_finished


func get_winning_team_id() -> String:
	return _winning_team_id


func get_last_contact() -> Dictionary:
	return _last_contact.duplicate(true)


func get_contact_decision_diagnostics_snapshot() -> Dictionary:
	var snapshot: Dictionary = _last_contact_decision_diagnostics.duplicate(true)
	if snapshot.is_empty():
		return snapshot
	_refresh_contact_decision_snapshot_presence(snapshot)
	return snapshot


func set_combat_startup_grace_ticks(grace_ticks: int) -> void:
	_combat_startup_grace_ticks = maxi(grace_ticks, 0)


func get_contact_decision_diagnostics_for_fireteams(fireteam_ids: Variant) -> Dictionary:
	var selected: Dictionary = {}
	for fireteam_id_variant in Array(fireteam_ids):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			selected[fireteam_id] = true
	if selected.is_empty():
		return get_contact_decision_diagnostics_snapshot()
	for index in range(_recent_fire_events.size() - 1, -1, -1):
		var event_variant: Variant = _recent_fire_events[index]
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var fire_event: Dictionary = Dictionary(event_variant)
		var attacker_fireteam_id: String = String(fire_event.get("attacker_fireteam_id", "")).strip_edges().to_lower()
		var target_fireteam_id: String = String(fire_event.get("target_fireteam_id", "")).strip_edges().to_lower()
		if bool(selected.get(attacker_fireteam_id, false)) or bool(selected.get(target_fireteam_id, false)):
			return _build_remote_fire_event_diagnostics(fire_event)
	for contact_variant in _remote_contact_snapshot:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		if bool(selected.get(String(contact.get("fireteam_id", "")).strip_edges().to_lower(), false)):
			return _build_remote_contact_diagnostics(contact)
	return {}


func get_suppress_fire_outcome_aar_diagnostic_snapshot() -> Dictionary:
	var last_outcome: Dictionary = _last_suppress_fire_outcome_diagnostic.duplicate(true)
	return {
		"schema": "sternenbuergerchen.suppress_fire_outcome_aar_diagnostic.v1",
		"source": "MissionCombatLoopDriver",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"suppress_fire_outcome_count": _suppress_fire_outcome_diagnostic_count,
		"suppress_fire_outcome_by_fireteam": _suppress_fire_outcome_diagnostic_by_fireteam.duplicate(true),
		"last_suppress_fire_outcome": last_outcome,
		"dedupe_key_count": _suppress_fire_outcome_diagnostic_keys_seen.size(),
		"last_outcome_label": String(last_outcome.get("outcome_label", "")).strip_edges(),
		"last_fireteam_id": String(last_outcome.get("attacker_fireteam_id", "")).strip_edges(),
		"no_suppression_effect_payload": not bool(last_outcome.get("suppression_effect_payload_enqueued", false)),
		"no_ammo_consumption": not bool(last_outcome.get("ammo_consumed", false)),
		"no_suppress_damage_modifier": not bool(last_outcome.get("suppress_damage_modifier_applied", false)),
	}


func _refresh_contact_decision_snapshot_presence(snapshot: Dictionary) -> void:
	var active_friendly_count: int = _get_units(friendly_unit_paths).size()
	var active_enemy_count: int = _get_active_enemy_units().size()
	snapshot["active_friendly_count"] = active_friendly_count
	snapshot["active_enemy_count"] = active_enemy_count
	snapshot["contact_count"] = get_contact_snapshot().size()
	snapshot["detection_pending_count"] = get_detection_progress().size()

	var reason: String = String(snapshot.get("reason", "")).strip_edges().to_lower()
	if reason != "no_contact_pair":
		return

	var candidate: Dictionary = Dictionary(snapshot.get("candidate", {})).duplicate(true)
	var candidate_reason: String = String(candidate.get("candidate_reason", "")).strip_edges().to_lower()
	if ["no_friendly_units", "no_friendly_combat_units"].has(candidate_reason) and active_friendly_count > 0:
		snapshot["candidate"] = _build_first_fire_candidate_diagnostic()
	elif ["no_active_enemy_units", "no_enemy_combat_units"].has(candidate_reason) and active_enemy_count > 0:
		snapshot["candidate"] = _build_first_fire_candidate_diagnostic()


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


func get_mission_evacuation_authority_snapshot() -> Dictionary:
	var reason: String = "ready"
	if not _runs_local_authority:
		reason = "not_authority"
	elif _combat_finished:
		reason = "mission_resolved"
	return {
		"accepted": reason == "ready",
		"reason": reason,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func request_mission_evacuation() -> Dictionary:
	var authority: Dictionary = get_mission_evacuation_authority_snapshot()
	if not bool(authority.get("accepted", false)):
		return {
			"accepted": false,
			"reason": String(authority.get("reason", "rejected")),
			"mission_result": get_mission_result(),
		}
	_resolve_combat("aborted", "", "evacuation")
	return {
		"accepted": true,
		"reason": "evacuation",
		"mission_result": get_mission_result(),
	}


var _finite_enemy_roster: bool = false
var _known_enemy_gate_groups: Dictionary = {}

func configure_scenario_runtime_gates_from_file(path: String) -> bool:
	if _mission_scenario_runtime_gates == null:
		return false
	_reset_scenario_gate_inputs()
	_known_enemy_gate_groups.clear()
	var scenario: Dictionary = {}
	if not path.strip_edges().is_empty() and FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_DICTIONARY:
			scenario = Dictionary(parsed)
	_finite_enemy_roster = Dictionary(scenario.get("vertical_slice",{})).get("finite_enemy_roster",false) == true
	_configure_mission_interaction_door_runtime_bindings(scenario)
	_mission_scenario_runtime_gates.call("configure_from_file", path)
	_mission_scenario_runtime_gate_snapshot = Dictionary(_mission_scenario_runtime_gates.call("get_snapshot")).duplicate(true)
	if _mission_cargo_touchdown_bridge != null:
		_mission_cargo_touchdown_bridge.call("configure_from_file", path)
		_update_mission_cargo_touchdown_bridge(_mission_scenario_runtime_gate_snapshot)
	_update_mission_scenario_runtime_gates()
	if _runs_local_authority:
		_sync_objective_countdown_state()
	return bool(_mission_scenario_runtime_gates.call("is_configured"))


func configure_scenario_runtime_gates(slice: Dictionary) -> bool:
	if _mission_scenario_runtime_gates == null:
		return false
	_reset_scenario_gate_inputs()
	_known_enemy_gate_groups.clear()
	_finite_enemy_roster = slice.get("finite_enemy_roster",false) == true
	_configure_mission_interaction_door_runtime_bindings({"vertical_slice": slice})
	_mission_scenario_runtime_gates.call("configure_from_slice", slice)
	_mission_scenario_runtime_gate_snapshot = Dictionary(_mission_scenario_runtime_gates.call("get_snapshot")).duplicate(true)
	if _mission_cargo_touchdown_bridge != null:
		_mission_cargo_touchdown_bridge.call("configure_from_slice", slice)
		_update_mission_cargo_touchdown_bridge(_mission_scenario_runtime_gate_snapshot)
	_update_mission_scenario_runtime_gates()
	if _runs_local_authority:
		_sync_objective_countdown_state()
	return bool(_mission_scenario_runtime_gates.call("is_configured"))


func _reset_scenario_gate_inputs() -> void:
	# A newly configured scenario must not re-import the previous sortie's
	# completion inputs into its freshly reset gate evaluator.
	_mission_interaction_runtime_states.clear()
	_mission_scenario_runtime_step_states.clear()
	_mission_scenario_completed_step_ids.clear()
	_mission_scenario_cargo_state = ""
	_mission_scenario_cargo_hold_seconds = 0.0


func get_mission_scenario_runtime_gate_snapshot() -> Dictionary:
	return _mission_scenario_runtime_gate_snapshot.duplicate(true)


func configure_mission_cargo_touchdown_bridge(config: Dictionary) -> bool:
	if _mission_cargo_touchdown_bridge == null:
		return false
	_mission_cargo_touchdown_bridge.call("configure", config)
	_update_mission_cargo_touchdown_bridge(_mission_scenario_runtime_gate_snapshot)
	_update_mission_scenario_runtime_gates()
	return bool(_mission_cargo_touchdown_bridge.call("is_configured"))


func get_mission_cargo_touchdown_snapshot() -> Dictionary:
	return _mission_cargo_touchdown_snapshot.duplicate(true)


func _configure_mission_interaction_door_runtime_bindings(scenario: Dictionary) -> void:
	_mission_interaction_door_bindings.clear()
	for binding_variant in MISSION_INTERACTION_BINDING_SCRIPT.normalize_scenario_bindings(scenario):
		var binding: Dictionary = Dictionary(binding_variant)
		if String(binding.get("interaction_type", "")) == "door":
			_mission_interaction_door_bindings.append(binding.duplicate(true))
	_mission_interaction_door_runtime_configured = true
	_mission_interaction_door_runtime_dirty = true


func get_mission_interaction_door_runtime_collision_los_snapshot() -> Dictionary:
	var result: Dictionary = _mission_interaction_door_runtime_snapshot.duplicate(true)
	if result.is_empty():
		return result
	var registry = _get_terrain_registry()
	var terrain_map_data = _get_mission_interaction_door_runtime_map_data()
	var registry_id: int = int(registry.get_instance_id()) if registry != null else 0
	var registry_revision: int = int(registry.call("get_revision")) if registry != null and registry.has_method("get_revision") else -1
	var map_id: int = int(terrain_map_data.get_instance_id()) if terrain_map_data != null else 0
	# Validate the receipt in the returned copy. Reads never repair or publish it.
	result["producer_index_current"] = bool(result.get("producer_index_current", false)) and registry_id == _mission_interaction_door_runtime_registry_id and registry_revision == _mission_interaction_door_runtime_registry_revision and map_id == _mission_interaction_door_runtime_map_id and _build_mission_interaction_door_runtime_map_signature(terrain_map_data) == _mission_interaction_door_runtime_map_signature
	return result


func _get_mission_interaction_door_runtime_map_data():
	var setup: Node = get_node_or_null("../MissionSetup")
	return setup.get("_loaded_terrain_map_data") if setup != null else null


func _build_mission_interaction_door_runtime_map_signature(terrain_map_data) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for binding_variant in _mission_interaction_door_bindings:
		var binding: Dictionary = Dictionary(binding_variant)
		var marker_id: String = String(binding.get("marker_id", ""))
		if terrain_map_data == null or not terrain_map_data.has_method("has_marker") or not bool(terrain_map_data.call("has_marker", marker_id)):
			parts.append("%s:missing" % marker_id)
			continue
		var position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO))
		parts.append("%s:%s" % [marker_id, JSON.stringify([position.x, position.y])])
	parts.sort()
	return "|".join(parts)


func _refresh_mission_interaction_door_runtime_overrides() -> void:
	if not _mission_interaction_door_runtime_configured:
		return
	var registry = _get_terrain_registry()
	# MissionSetup owns the already loaded map. This path has no HUD/controller
	# dependency and never reads local selection or rendered unit anchors.
	var terrain_map_data = _get_mission_interaction_door_runtime_map_data()
	var registry_id: int = int(registry.get_instance_id()) if registry != null else 0
	var registry_revision: int = int(registry.call("get_revision")) if registry != null and registry.has_method("get_revision") else -1
	var map_id: int = int(terrain_map_data.get_instance_id()) if terrain_map_data != null else 0
	var map_signature: String = _build_mission_interaction_door_runtime_map_signature(terrain_map_data)
	if not _mission_interaction_door_runtime_dirty and registry_id == _mission_interaction_door_runtime_registry_id and registry_revision == _mission_interaction_door_runtime_registry_revision and map_id == _mission_interaction_door_runtime_map_id and map_signature == _mission_interaction_door_runtime_map_signature:
		return
	var result: Dictionary = MISSION_INTERACTION_DOOR_RUNTIME_SCRIPT.build_runtime_snapshot(_mission_interaction_door_bindings, _mission_interaction_runtime_states, terrain_map_data, registry)
	result["producer_schema"] = "sternenbuergerchen.mission_interaction_door_runtime_state_producer.v1"
	result["producer_source"] = "MissionCombatLoopDriver"
	result["producer_reads_runtime_truth"] = true
	result["producer_applied"] = false
	result["producer_applied_semantics"] = "last_runtime_producer_pass"
	result["producer_index_current"] = false
	result["producer_apply_reason"] = "terrain_registry_unavailable"
	result["terrain_registry_revision"] = registry_revision
	var overrides: Array = Array(result.get("overrides", []))
	var fingerprint: String = _build_mission_interaction_door_runtime_fingerprint(overrides)
	if registry != null and registry.has_method("set_runtime_tile_overrides"):
		var overrides_match: bool = _mission_interaction_door_runtime_overrides_match(registry, overrides)
		if fingerprint != _mission_interaction_door_runtime_fingerprint or not overrides_match:
			registry.call("set_runtime_tile_overrides", overrides)
			_mission_interaction_door_runtime_apply_count += 1
			result["producer_applied"] = true
			result["producer_apply_reason"] = "override_changed" if fingerprint != _mission_interaction_door_runtime_fingerprint else "registry_override_missing_or_changed"
		else:
			result["producer_apply_reason"] = "unchanged"
		result["producer_index_current"] = _mission_interaction_door_runtime_overrides_match(registry, overrides)
		result["terrain_registry_revision"] = int(registry.call("get_revision")) if registry.has_method("get_revision") else -1
	_mission_interaction_door_runtime_dirty = false
	_mission_interaction_door_runtime_fingerprint = fingerprint
	_mission_interaction_door_runtime_registry_id = registry_id
	_mission_interaction_door_runtime_registry_revision = int(result.get("terrain_registry_revision", -1))
	_mission_interaction_door_runtime_map_id = map_id
	_mission_interaction_door_runtime_map_signature = map_signature
	result["producer_apply_count"] = _mission_interaction_door_runtime_apply_count
	_mission_interaction_door_runtime_snapshot = result


func _mission_interaction_door_runtime_overrides_match(registry: Node, overrides: Array) -> bool:
	if not registry.has_method("get_runtime_tile_override"):
		return false
	for override_variant in overrides:
		var expected: Dictionary = Dictionary(override_variant)
		if Dictionary(registry.call("get_runtime_tile_override", Vector2i(expected.get("grid_position", Vector2i.ZERO)))) != expected:
			return false
	return true


func _build_mission_interaction_door_runtime_fingerprint(overrides: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for override_variant in overrides:
		var override: Dictionary = Dictionary(override_variant)
		var grid: Vector2i = Vector2i(override.get("grid_position", Vector2i.ZERO))
		parts.append("%d,%d:%s:%s:%d:%d:%s:%s" % [grid.x, grid.y, str(bool(override.get("walkable_override", false))), str(bool(override.get("blocks_los_override", false))), int(override.get("object_height_override", 0)), int(override.get("cover_value_override", 0)), String(override.get("source_interaction_id", "")), String(override.get("source_runtime_visual_state", ""))])
	parts.sort()
	return "|".join(parts)


func get_mission_interaction_runtime_states() -> Dictionary:
	return _mission_interaction_runtime_states.duplicate(true)


func get_mission_interaction_runtime_state_snapshot() -> Dictionary:
	var states: Dictionary = _mission_interaction_runtime_states.duplicate(true)
	var complete_count: int = 0
	var in_progress_count: int = 0
	for state_variant in states.values():
		var state: Dictionary = Dictionary(state_variant)
		if bool(state.get("complete", false)):
			complete_count += 1
		elif ["active", "holding", "operating", "in_progress"].has(String(state.get("state", "")).strip_edges().to_lower()):
			in_progress_count += 1
	return {
		"schema": "sternenbuergerchen.mission_interaction_runtime_progress.v1",
		"runtime_authority": "MissionCombatLoopDriver",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"interaction_count": states.size(),
		"in_progress_count": in_progress_count,
		"complete_count": complete_count,
		"interaction_states": states,
	}


func apply_multiplayer_interaction_snapshot(snapshot: Dictionary) -> Dictionary:
	var source_states: Dictionary = Dictionary(snapshot.get("interaction_states", {}))
	_mission_interaction_runtime_states.clear()
	_mission_interaction_door_runtime_dirty = true
	_mission_scenario_runtime_step_states.clear()
	var interaction_ids: Array = source_states.keys()
	interaction_ids.sort()
	for interaction_id_variant in interaction_ids:
		var interaction_id: String = String(interaction_id_variant).strip_edges()
		if interaction_id.is_empty() or typeof(source_states.get(interaction_id_variant, null)) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(source_states.get(interaction_id_variant, {})).duplicate(true)
		state["read_only"] = true
		state["ui_sets_gameplay_truth"] = false
		_mission_interaction_runtime_states[interaction_id] = state
		if bool(state.get("complete", false)):
			_apply_completed_mission_interaction_state(state)
		else:
			_apply_in_progress_mission_interaction_state(state)
	_update_mission_scenario_runtime_gates()
	_refresh_mission_interaction_door_runtime_overrides()
	return {
		"applied_count": _mission_interaction_runtime_states.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func get_pending_network_mission_interaction_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.pending_network_mission_interactions.v1",
		"pending_count": _pending_network_mission_interactions.size(),
		"entries": _pending_network_mission_interactions.duplicate(true),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _on_network_command_accepted(command: Dictionary, peer_id: int) -> void:
	if not ["mission_interaction_door_breach_command", "mission_interaction_use_intent_command"].has(String(command.get("source_context", "")).strip_edges()):
		return
	var interaction_id: String = String(command.get("interaction_id", "")).strip_edges()
	var unit_id: String = String(command.get("unit_id", "")).strip_edges()
	var target_position: Variant = command.get("target_position", null)
	if interaction_id.is_empty() or unit_id.is_empty() or typeof(target_position) != TYPE_VECTOR2:
		return
	var previous_pending: Dictionary = Dictionary(_pending_network_mission_interactions.get(interaction_id, {}))
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	var continues_existing: bool = not previous_pending.is_empty() and String(previous_pending.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id
	var next_pending: Dictionary = {
		"interaction_id": interaction_id,
		"unit_id": unit_id,
		"peer_id": maxi(peer_id, 0),
		"target_position": Vector2(target_position),
		"radius_world": maxf(float(command.get("interaction_radius_world", 72.0)), 1.0),
		"hold_seconds": 0.0,
		"duration_seconds": maxf(float(command.get("duration_seconds", 0.0)), 0.0),
		"fireteam_id": fireteam_id,
		"team_id": String(command.get("team_id", friendly_team_id)).strip_edges().to_lower(),
		"step_id": String(command.get("step_id", "")).strip_edges(),
		"gate_id": String(command.get("gate_id", command.get("step_id", ""))).strip_edges(),
		"required_state": String(command.get("required_state", "door_open")).strip_edges(),
		"interaction_type": String(command.get("interaction_type", "door")).strip_edges().to_lower(),
		"command_type": String(command.get("command_type", "")).strip_edges().to_lower(),
	}
	if continues_existing:
		for stable_key in ["target_position", "radius_world", "hold_seconds", "duration_seconds", "fireteam_id", "team_id", "step_id", "gate_id", "required_state", "interaction_type", "command_type"]:
			if previous_pending.has(stable_key):
				next_pending[stable_key] = previous_pending[stable_key]
	_pending_network_mission_interactions[interaction_id] = next_pending


func _validate_network_interaction_command_preflight(command: Dictionary, _peer_id: int) -> Dictionary:
	if not ["mission_interaction_door_breach_command", "mission_interaction_use_intent_command"].has(String(command.get("source_context", "")).strip_edges()):
		return {"accepted": true}
	var interaction_id: String = String(command.get("interaction_id", "")).strip_edges()
	var requested_fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	if interaction_id.is_empty() or requested_fireteam_id.is_empty():
		return {"accepted": true}
	var pending: Dictionary = Dictionary(_pending_network_mission_interactions.get(interaction_id, {}))
	if pending.is_empty():
		return {"accepted": true}
	var owner_fireteam_id: String = String(pending.get("fireteam_id", "")).strip_edges().to_lower()
	if owner_fireteam_id.is_empty():
		return {"accepted": true}
	if owner_fireteam_id == requested_fireteam_id:
		var canonical_command: Dictionary = command.duplicate(true)
		var stable_command_fields: Dictionary = {
			"target_position": "target_position",
			"interaction_radius_world": "radius_world",
			"duration_seconds": "duration_seconds",
			"fireteam_id": "fireteam_id",
			"team_id": "team_id",
			"step_id": "step_id",
			"gate_id": "gate_id",
			"required_state": "required_state",
			"interaction_type": "interaction_type",
			"command_type": "command_type",
		}
		for command_key in stable_command_fields.keys():
			var pending_key: String = String(stable_command_fields[command_key])
			if pending.has(pending_key):
				canonical_command[command_key] = pending[pending_key]
		return {
			"accepted": true,
			"command": canonical_command,
		}
	return {
		"accepted": false,
		"reason": "interaction_reserved_by_other_fireteam",
	}


func _advance_pending_network_mission_interactions(delta: float) -> void:
	for interaction_id_variant in _pending_network_mission_interactions.keys().duplicate():
		var interaction_id: String = String(interaction_id_variant)
		var pending: Dictionary = Dictionary(_pending_network_mission_interactions.get(interaction_id, {})).duplicate(true)
		var unit = _resolve_runtime_unit_by_id(String(pending.get("unit_id", "")))
		if unit == null or not (unit is Node2D):
			continue
		var target_position: Vector2 = Vector2(pending.get("target_position", Vector2.ZERO))
		if (unit as Node2D).global_position.distance_to(target_position) > float(pending.get("radius_world", 72.0)):
			var had_hold_progress: bool = float(pending.get("hold_seconds", 0.0)) > 0.0
			pending["hold_seconds"] = 0.0
			_pending_network_mission_interactions[interaction_id] = pending
			if had_hold_progress:
				_publish_pending_network_interaction_progress(pending, false)
			continue
		var duration_seconds: float = maxf(float(pending.get("duration_seconds", 0.0)), 0.0)
		var hold_seconds: float = maxf(float(pending.get("hold_seconds", 0.0)) + maxf(delta, 0.0), 0.0)
		var complete: bool = duration_seconds <= 0.0 or hold_seconds + 0.001 >= duration_seconds
		pending["hold_seconds"] = hold_seconds
		_pending_network_mission_interactions[interaction_id] = pending
		_publish_pending_network_interaction_progress(pending, complete)
		if complete:
			_pending_network_mission_interactions.erase(interaction_id)


func _publish_pending_network_interaction_progress(pending: Dictionary, complete: bool) -> void:
	var interaction_id: String = String(pending.get("interaction_id", "")).strip_edges()
	if interaction_id.is_empty():
		return
	var duration_seconds: float = maxf(float(pending.get("duration_seconds", 0.0)), 0.0)
	var hold_seconds: float = maxf(float(pending.get("hold_seconds", 0.0)), 0.0)
	update_mission_interaction_runtime_progress({
		"interaction_id": interaction_id,
		"state": "complete" if complete else ("holding" if String(pending.get("interaction_type", "")) == "hold_zone" else "operating"),
		"complete": complete,
		"hold_seconds": hold_seconds,
		"duration_seconds": duration_seconds,
		"fireteam_id": String(pending.get("fireteam_id", "")),
		"team_id": String(pending.get("team_id", friendly_team_id)),
		"step_id": String(pending.get("step_id", "")),
		"gate_id": String(pending.get("gate_id", "")),
		"required_state": String(pending.get("required_state", "")),
		"interaction_type": String(pending.get("interaction_type", "")),
		"command_type": String(pending.get("command_type", "")),
		"can_complete_zero_duration": duration_seconds <= 0.0,
	})


func _resolve_runtime_unit_by_id(unit_id: String):
	var registry = _get_unit_registry()
	if registry != null and registry.has_method("get_unit"):
		var registered_unit = registry.call("get_unit", unit_id)
		if registered_unit != null:
			return registered_unit
	return _resolve_known_unit_by_id(unit_id)


func _resolve_known_unit_by_id(unit_id: String):
	for unit in _get_units(friendly_unit_paths):
		if unit != null and unit.has_method("get_unit_id") and String(unit.call("get_unit_id")) == unit_id:
			return unit
	return null


func update_mission_interaction_runtime_progress(payload: Dictionary) -> Dictionary:
	var interaction_id: String = String(payload.get("interaction_id", "")).strip_edges()
	if interaction_id.is_empty():
		return {}
	var duration_seconds: float = maxf(float(payload.get("duration_seconds", 0.0)), 0.0)
	var hold_seconds: float = clampf(maxf(float(payload.get("hold_seconds", 0.0)), 0.0), 0.0, duration_seconds if duration_seconds > 0.0 else INF)
	var complete: bool = bool(payload.get("complete", false)) or (duration_seconds <= 0.0 and bool(payload.get("can_complete_zero_duration", false))) or (duration_seconds > 0.0 and hold_seconds + 0.001 >= duration_seconds)
	if complete and (interaction_id == "ship_return" or String(payload.get("step_id", "")) == "return_to_ship") and not _has_actual_campaign_return_craft():
		return {"accepted": false, "complete": false, "reason": "return_craft_not_at_authored_pad"}
	var resources: Node=get_parent().get_node_or_null("LocationResources")
	if resources!=null:
		var gate: Dictionary=resources.call("accept_progress",payload,complete)
		if not bool(gate.get("accepted",false)): return gate
	var progress: float = 1.0 if complete else clampf(float(payload.get("progress", 0.0)), 0.0, 1.0)
	if duration_seconds > 0.0:
		progress = 1.0 if complete else clampf(hold_seconds / duration_seconds, 0.0, 1.0)
	var state_name: String = String(payload.get("state", "active")).strip_edges().to_lower()
	if complete:
		state_name = "complete"
	var state: Dictionary = {
		"state": state_name,
		"complete": complete,
		"hold_seconds": hold_seconds,
		"duration_seconds": duration_seconds,
		"progress": progress,
		"fireteam_id": String(payload.get("fireteam_id", "")).strip_edges().to_lower(),
		"team_id": String(payload.get("team_id", friendly_team_id)).strip_edges().to_lower(),
		"active_team_id": String(payload.get("team_id", friendly_team_id)).strip_edges().to_lower(),
		"step_id": String(payload.get("step_id", "")).strip_edges(),
		"gate_id": String(payload.get("gate_id", payload.get("step_id", ""))).strip_edges(),
		"required_state": String(payload.get("required_state", "")).strip_edges(),
		"interaction_type": String(payload.get("interaction_type", "")).strip_edges().to_lower(),
		"command_type": String(payload.get("command_type", "")).strip_edges().to_lower(),
		"updated_msec": Time.get_ticks_msec(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	var previous_state: Dictionary = Dictionary(_mission_interaction_runtime_states.get(interaction_id, {}))
	var previous_progress_bucket: int = int(round(float(previous_state.get("progress", -1.0)) * 100.0))
	var next_progress_bucket: int = int(round(progress * 100.0))
	var previous_hold_bucket: int = int(round(float(previous_state.get("hold_seconds", -1.0)) * 10.0))
	var next_hold_bucket: int = int(round(hold_seconds * 10.0))
	var state_changed: bool = String(previous_state.get("state", "")) != state_name or bool(previous_state.get("complete", false)) != complete or previous_progress_bucket != next_progress_bucket or previous_hold_bucket != next_hold_bucket
	_mission_interaction_runtime_states[interaction_id] = state.duplicate(true)
	_mission_interaction_door_runtime_dirty = true
	if complete:
		_apply_completed_mission_interaction_state(state)
	elif state_changed:
		_apply_in_progress_mission_interaction_state(state)
	_refresh_mission_interaction_door_runtime_overrides()
	return state.duplicate(true)


func _has_actual_campaign_return_craft() -> bool:
	var mission: Node = get_parent()
	var setup: Node = mission.get_node_or_null("MissionSetup") if mission != null else null
	# Isolated generic gate/contract drivers have no scene to project. Actual
	# peaceful mission scenes must prove their bound craft's physical presence.
	if setup == null:
		return true
	var scenario: Variant = setup.get("_mission_scenario")
	if scenario == null or not scenario.has_method("is_noncombat_singleplayer") or not bool(scenario.call("is_noncombat_singleplayer")):
		return true
	var identity: Dictionary = Dictionary(mission.get_meta("singleplayer_mission_identity", {}))
	var craft_id: String = String(identity.get("craft_id", ""))
	if craft_id.is_empty() or String(identity.get("job_id", "")).is_empty() or String(identity.get("scenario_id", "")) != String(scenario.get("scenario_id")):
		return false
	var controller: Node = mission.get_node_or_null("TacticalController")
	return controller != null and controller.has_method("is_campaign_return_craft_at_authored_pad") and bool(controller.call("is_campaign_return_craft_at_authored_pad", craft_id))


func set_mission_scenario_runtime_step_state(step_id: String, state: String) -> void:
	var normalized_step_id: String = step_id.strip_edges()
	if normalized_step_id.is_empty():
		return
	_mission_scenario_runtime_step_states[normalized_step_id] = state.strip_edges()
	_update_mission_scenario_runtime_gates()


func mark_mission_scenario_runtime_step_complete(step_id: String) -> void:
	var normalized_step_id: String = step_id.strip_edges()
	if normalized_step_id.is_empty() or _mission_scenario_completed_step_ids.has(normalized_step_id):
		return
	_mission_scenario_completed_step_ids.append(normalized_step_id)
	_update_mission_scenario_runtime_gates()


func set_mission_scenario_cargo_state(state: String, hold_seconds: float = 0.0) -> void:
	set_mission_cargo_touchdown_state(state, hold_seconds)


func set_mission_cargo_touchdown_state(state: String, hold_seconds: float = 0.0, progress: float = -1.0) -> void:
	_mission_scenario_cargo_state = state.strip_edges().to_lower()
	_mission_scenario_cargo_hold_seconds = maxf(hold_seconds, 0.0)
	if _mission_cargo_touchdown_bridge != null and bool(_mission_cargo_touchdown_bridge.call("is_configured")):
		_mission_cargo_touchdown_bridge.call("set_runtime_state", _mission_scenario_cargo_state, _mission_scenario_cargo_hold_seconds, progress)
	_update_mission_scenario_runtime_gates()


func _apply_in_progress_mission_interaction_state(state: Dictionary) -> void:
	if String(state.get("interaction_type", "")).strip_edges().to_lower() != "hold_zone":
		return
	var step_id: String = String(state.get("step_id", "")).strip_edges()
	if step_id != "cargo_touchdown_extract":
		return
	set_mission_cargo_touchdown_state("landed", float(state.get("hold_seconds", 0.0)), float(state.get("progress", 0.0)))


func _apply_completed_mission_interaction_state(state: Dictionary) -> void:
	var step_id: String = String(state.get("step_id", "")).strip_edges()
	var required_state: String = String(state.get("required_state", "complete")).strip_edges()
	if step_id == "cargo_touchdown_extract":
		set_mission_cargo_touchdown_state(required_state if not required_state.is_empty() else "cargo_departed", float(state.get("hold_seconds", 0.0)), 1.0)
	if not step_id.is_empty():
		set_mission_scenario_runtime_step_state(step_id, required_state if not required_state.is_empty() else "complete")


func get_playability_snapshot() -> Dictionary:
	var base_snapshot: Dictionary = {
		"combat_state": "resolved" if _combat_finished else "active",
		"win_condition_type": win_condition,
		"mission_resolved": _combat_finished,
		"result": String(_mission_result.get("result", "")),
		"winning_team_id": _winning_team_id,
		"enemy_fit_count": _count_fit_enemy_units(),
		"friendly_fit_count": _count_fit_units(friendly_unit_paths),
		"duration_seconds": _get_duration_seconds(),
		"remaining_time_limit_seconds": get_remaining_time_limit_seconds(),
		"last_event_text": _last_event_text,
		"mission_scenario_runtime_gates": _mission_scenario_runtime_gate_snapshot.duplicate(true),
		"mission_cargo_touchdown": _mission_cargo_touchdown_snapshot.duplicate(true),
	}
	return Dictionary(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("build_playability_snapshot", base_snapshot, _get_objective_status(), _mission_result))


func get_objective_countdown_snapshot() -> Dictionary:
	var objective_status = _get_objective_status()
	if objective_status == null or not objective_status.has_method("get_countdown_snapshot"):
		return {}
	return Dictionary(objective_status.call("get_countdown_snapshot")).duplicate(true)


func get_authority_contract_snapshot() -> Dictionary:
	return Dictionary(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("get_contract_snapshot")).duplicate(true)


func set_combat_tick_budget_debug_enabled(enabled: bool) -> void:
	combat_tick_budget_debug_enabled = enabled
	if not combat_tick_budget_debug_enabled:
		_combat_tick_budget_debug_snapshot.clear()
	_combat_hotspot_profile = {"counts": {}, "usec": {}}
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache != null and cache.has_method("set_debug_profiling_enabled"):
		cache.call("set_debug_profiling_enabled", enabled)

func get_combat_hotspot_debug_snapshot() -> Dictionary:
	var snapshot := _combat_hotspot_profile.duplicate(true)
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache != null and cache.has_method("get_debug_profile_snapshot"):
		snapshot["visibility_cache"] = Dictionary(cache.call("get_debug_profile_snapshot"))
	snapshot["enabled"] = combat_tick_budget_debug_enabled
	snapshot["derived_only"] = true
	snapshot["read_only"] = true
	snapshot["snapshot_serialized"] = false
	return snapshot

func _record_combat_hotspot(name: String, elapsed_usec: int) -> void:
	if not combat_tick_budget_debug_enabled:
		return
	var counts: Dictionary = _combat_hotspot_profile.get("counts", {})
	var usec: Dictionary = _combat_hotspot_profile.get("usec", {})
	counts[name] = int(counts.get(name, 0)) + 1
	usec[name] = int(usec.get(name, 0)) + elapsed_usec
	_combat_hotspot_profile["counts"] = counts
	_combat_hotspot_profile["usec"] = usec


func get_combat_tick_budget_debug_snapshot() -> Dictionary:
	return _combat_tick_budget_debug_snapshot.duplicate(true)


func get_combat_hotpath_audit_snapshot() -> Dictionary:
	var active_friendly_units: Array = _get_units(friendly_unit_paths)
	var active_enemy_units: Array = _get_active_enemy_units()
	var combat_friendly_units: Array = _get_friendly_combat_units()
	var combat_enemy_units: Array = _get_enemy_combat_units()
	var visibility_cache_audit: Dictionary = _get_combat_visibility_cache_audit()
	return {
		"authority_root": "SimulationRoot",
		"combat_driver_role": "authoritative_tick_subscriber",
		"unit_sources": "configured_unit_paths_with_unit_registry_active_filter",
		"active_filter_policy": "UnitRegistry_has_unit_required_when_registry_available",
		"combat_candidate_policy": "registered_Node2D_and_vital_fit",
		"scene_tree_lookup_policy": "direct_NodePath_or_registry_lookup_only",
		"per_unit_area2d_ai": false,
		"navigation_authority": "existing_TerrainRegistry_HPA_AStar_path",
		"client_viewer_paths_read_only": true,
		"snapshot_publication": "SimulationRoot.set_multiplayer_snapshot_context",
		"cache_active": _hotpath_unit_cache_active,
		"cache_tick": _hotpath_unit_cache_tick,
		"active_friendly_count": active_friendly_units.size(),
		"active_enemy_count": active_enemy_units.size(),
		"combat_friendly_count": combat_friendly_units.size(),
		"combat_enemy_count": combat_enemy_units.size(),
		"potential_combat_pair_count": combat_friendly_units.size() * combat_enemy_units.size(),
		"last_contact_tracking_scan_pair_count": _last_contact_tracking_scan_pair_count,
		"last_contact_tracking_los_check_count": _last_contact_tracking_los_check_count,
		"last_contact_tracking_los_cache_hit_count": _last_contact_tracking_los_cache_hit_count,
		"contact_tracking_los_cache_status": String(visibility_cache_audit.get("cache_status", "unavailable")),
		"visibility_cache_asked_pair_count": int(visibility_cache_audit.get("asked_pair_count", 0)),
		"visibility_cache_actual_los_check_count": int(visibility_cache_audit.get("actual_los_check_count", 0)),
		"visibility_cache_hit_count": int(visibility_cache_audit.get("cache_hit_count", 0)),
		"visibility_cache_tactics_rebuild_count": _enemy_team_tactics_rebuild_count,
		"visibility_cache": visibility_cache_audit,
		"last_fire_candidate_pair_scan_count": _last_fire_candidate_pair_scan_count,
		"spatial_bucket_status": "diagnostic_next_step_not_runtime_filter",
		"spatial_bucket_cell_size": COMBAT_HOTPATH_AUDIT_BUCKET_CELL_SIZE,
		"down_linger_min_seconds": DOWN_STATE_VISIBLE_MIN_SECONDS,
		"tactical_visual_refresh_interval_msec": TACTICAL_COMBAT_VISUAL_REFRESH_INTERVAL_MSEC,
		"tactical_visual_refresh_count": _tactical_combat_visual_refresh_count,
		"tactical_visual_refresh_pending": _tactical_combat_visual_refresh_pending,
		"tactical_visual_refresh_suppressed_count": _tactical_combat_visual_refresh_suppressed_count,
	}


func _begin_combat_visibility_cache_tick(tick: int) -> void:
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache != null and cache.has_method("begin_tick"):
		cache.call("begin_tick", tick)


func _get_combat_visibility_system():
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache != null and cache.has_method("has_line_of_sight_between_nodes") and cache.has_method("has_line_of_sight_between_points"):
		return cache
	return _los_system


func get_hex_sight_adapter() -> RefCounted:
	if not _hex_adapter_initialized or simulation_root_path != _hex_adapter_owner_path or combat_visibility_cache_path != _hex_adapter_cache_path or hex_sight_arc_degrees != _hex_adapter_arc or not _hex_sight_adapter.has_runtime_dependencies():
		_hex_sight_adapter.configure(get_node_or_null(simulation_root_path), _get_combat_visibility_system(), hex_sight_arc_degrees)
		_hex_adapter_owner_path = simulation_root_path
		_hex_adapter_cache_path = combat_visibility_cache_path
		_hex_adapter_arc = hex_sight_arc_degrees
		_hex_adapter_initialized = true
	return _hex_sight_adapter


func _query_current_visibility(attacker, target, range_world: float) -> Dictionary:
	return get_hex_sight_adapter().query_units(attacker, target, range_world)


func _get_hex_combat_geometry(attacker, target) -> Dictionary:
	var owner = get_node_or_null(simulation_root_path)
	if owner == null or not owner.has_method("get_hex_combat_geometry"):
		return {"handled":false}
	var attacker_id: String = String(attacker.call("get_unit_id")) if attacker != null and attacker.has_method("get_unit_id") else ""
	var target_id: String = String(target.call("get_unit_id")) if target != null and target.has_method("get_unit_id") else ""
	return owner.call("get_hex_combat_geometry",attacker_id,target_id)


## A gameplay sound producer supplies an already addressed hint, not a target
## confirmation. Audio playback/visibility is deliberately not its producer.
func notify_hex_sound_cue(unit_id: String, source_grid: Vector2i, event_id: String) -> Dictionary:
	var adapter = get_hex_sight_adapter()
	if not adapter.is_active() or event_id.strip_edges().is_empty():
		return {"ok":false,"reason":"invalid_sound_context"}
	var owner = get_node_or_null(simulation_root_path)
	var registry = owner.call("get_hex_ground_terrain_registry")
	var unit = _resolve_unit_by_id(unit_id)
	var position: Dictionary = adapter.read_position(unit)
	if not bool(position.get("valid",false)) or registry.call("get_tile_at_grid",source_grid) == null:
		return {"ok":false,"reason":"invalid_sound_hint"}
	var destination: Vector2 = registry.call("grid_to_world",source_grid)
	var delta: Vector2 = destination-Vector2(position.position)
	if delta.length_squared() < 0.000001:
		return {"ok":false,"reason":"sound_has_no_direction"}
	var delay := maxi(_get_detection_delay_ticks(unit),1)
	if _current_tick < 0 or _current_tick > 9223372036854775807-delay:
		return {"ok":false,"reason":"invalid_sound_tick"}
	return owner.call("queue_hex_facing_intent",unit_id,adapter.world_angle_to_facing(delta.angle()),"sound:%s"%event_id,"noise_reaction",_current_tick+delay)


func _get_contact_observation_position(unit) -> Vector2:
	var adapter = get_hex_sight_adapter()
	if adapter.is_active():
		return Vector2(adapter.build_observer_state(unit,-1.0).get("position",Vector2.ZERO))
	return (unit as Node2D).global_position if unit is Node2D else Vector2.ZERO


func _get_hex_detection_state() -> RefCounted:
	var owner = get_node_or_null(simulation_root_path)
	var context := "%d:%d" % [owner.get_instance_id(), owner.get_hex_ground_context_revision()]
	if context != _hex_detection_context:
		_hex_detection_state.clear()
		_hex_detection_context = context
	return _hex_detection_state


func _get_combat_visibility_cache_audit() -> Dictionary:
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache != null and cache.has_method("get_audit_snapshot"):
		return Dictionary(cache.call("get_audit_snapshot")).duplicate(true)
	return {
		"cache_status": "unavailable",
		"derived_only": true,
		"asked_pair_count": 0,
		"actual_los_check_count": 0,
		"cache_hit_count": 0,
	}


func get_contact_snapshot() -> Array:
	if not _runs_local_authority:
		return _remote_contact_snapshot.duplicate(true)
	if _contact_tracker == null:
		return []
	return Array(_contact_tracker.call("get_contact_snapshot", _current_tick)).duplicate(true)


func get_unit_presence_audit_snapshot() -> Dictionary:
	var active_friendly_units: Array = _get_units(friendly_unit_paths)
	var active_enemy_units: Array = _get_active_enemy_units()
	var all_friendly_units: Array = _get_units_for_presence_audit(friendly_unit_paths)
	var all_enemy_units: Array = _get_units_for_presence_audit(enemy_unit_paths)
	var active_friendly_ids: Array = _extract_presence_audit_unit_ids(active_friendly_units)
	var active_enemy_ids: Array = _extract_presence_audit_unit_ids(active_enemy_units)
	return {
		"active_friendly_unit_ids": active_friendly_ids,
		"active_enemy_unit_ids": active_enemy_ids,
		"inactive_friendly_unit_ids": _extract_inactive_presence_audit_unit_ids(all_friendly_units, active_friendly_ids),
		"inactive_enemy_unit_ids": _extract_inactive_presence_audit_unit_ids(all_enemy_units, active_enemy_ids),
		"combat_friendly_unit_ids": _extract_presence_audit_unit_ids(_get_friendly_combat_units()),
		"combat_enemy_unit_ids": _extract_presence_audit_unit_ids(_get_enemy_combat_units()),
		"current_wave_number": _get_enemy_wave_number("get_current_wave_number"),
		"total_wave_count": _get_enemy_wave_number("get_total_wave_count"),
		"all_waves_started": _enemy_waves_all_started(),
	}


func get_fireteam_contact_snapshot(fireteam_id: String) -> Array:
	if not _runs_local_authority:
		var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
		var filtered: Array = []
		for entry_variant in _remote_contact_snapshot:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = Dictionary(entry_variant)
			if String(entry.get("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
				filtered.append(entry.duplicate(true))
		return filtered
	if _contact_tracker == null:
		return []
	return Array(_contact_tracker.call("get_fireteam_contacts", fireteam_id, _current_tick)).duplicate(true)


func apply_multiplayer_combat_snapshot(snapshot: Dictionary) -> bool:
	refresh_multiplayer_runtime_authority()
	if _runs_local_authority:
		return false
	_current_tick = maxi(int(snapshot.get("tick", _current_tick)), _current_tick)
	_remote_contact_snapshot = _sanitize_remote_combat_entries(snapshot.get("contacts", []), "unit_id")
	_recent_fire_events = _sanitize_remote_combat_entries(snapshot.get("fire_events", []), "event_id")
	_last_contact_decision_diagnostics = _build_remote_contact_decision_diagnostics()
	return true


func refresh_multiplayer_runtime_authority() -> bool:
	return _refresh_runtime_authority(get_node_or_null(simulation_root_path))


func _sanitize_remote_combat_entries(entries_variant: Variant, identity_key: String) -> Array:
	var result: Array = []
	var seen_ids: Dictionary = {}
	for entry_variant in Array(entries_variant):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var identity: String = String(entry.get(identity_key, "")).strip_edges()
		if identity.is_empty():
			continue
		if identity_key == "unit_id":
			identity = "%s|%s" % [String(entry.get("fireteam_id", "")).strip_edges().to_lower(), identity]
		if seen_ids.has(identity):
			continue
		seen_ids[identity] = true
		entry["read_only"] = true
		entry["ui_sets_gameplay_truth"] = false
		result.append(entry)
	return result


func _build_remote_contact_decision_diagnostics() -> Dictionary:
	if not _recent_fire_events.is_empty():
		return _build_remote_fire_event_diagnostics(Dictionary(_recent_fire_events.back()))
	if not _remote_contact_snapshot.is_empty():
		return _build_remote_contact_diagnostics(Dictionary(_remote_contact_snapshot[0]))
	return {}


func _build_remote_fire_event_diagnostics(fire_event: Dictionary) -> Dictionary:
	return {
		"status": "fired",
		"reason": "fired",
		"fire_event_id": String(fire_event.get("event_id", "")),
		"attacker_unit_id": String(fire_event.get("attacker_unit_id", "")),
		"attacker_team_id": String(fire_event.get("attacker_team_id", "")),
		"attacker_fireteam_id": String(fire_event.get("attacker_fireteam_id", "")),
		"target_unit_id": String(fire_event.get("target_unit_id", "")),
		"target_team_id": String(fire_event.get("target_team_id", "")),
		"target_fireteam_id": String(fire_event.get("target_fireteam_id", "")),
		"weapon_id": String(fire_event.get("weapon_id", "")),
		"combat_outcome": String(fire_event.get("combat_outcome", fire_event.get("result", ""))),
		"source": "multiplayer_combat_snapshot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_remote_contact_diagnostics(contact: Dictionary) -> Dictionary:
	return {
		"status": "contact",
		"reason": "contact_visible",
		"target_unit_id": String(contact.get("unit_id", "")),
		"target_team_id": String(contact.get("team_id", "")),
		"target_position": contact.get("last_known_position", Vector2.ZERO),
		"source": "multiplayer_combat_snapshot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _publish_multiplayer_snapshot_context(simulation_root: Node) -> void:
	if simulation_root == null or not simulation_root.has_method("set_multiplayer_snapshot_context"):
		return
	_prune_recent_fire_events()

	simulation_root.call(
		"set_multiplayer_snapshot_context",
		{
			"contacts": get_contact_snapshot(),
			"enemy_security": get_enemy_security_snapshot(),
			"enemy_team_tactics": get_enemy_team_tactics_snapshot(),
			"character_gameplay": get_character_gameplay_snapshot(),
			"fire_events": get_fire_event_snapshot(),
			"mission_interactions": get_mission_interaction_runtime_state_snapshot(),
			"mission_result": get_mission_result(),
		}
	)


func get_flank_vulnerability_snapshot() -> Array:
	if not flank_vulnerability_enabled or _flank_vulnerability_resolver == null:
		return []
	return Array(_flank_vulnerability_resolver.call("get_state_snapshot", _current_tick)).duplicate(true)


func get_enemy_security_snapshot() -> Array:
	var result: Array = []
	var group_ids: Array = _enemy_security_states_by_group_id.keys()
	group_ids.sort()
	for group_id_variant in group_ids:
		var state: Dictionary = Dictionary(_enemy_security_states_by_group_id.get(group_id_variant, {})).duplicate(true)
		if state.is_empty():
			continue
		result.append(state)
	return result


func get_enemy_security_state_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	for state_variant in get_enemy_security_snapshot():
		var state: Dictionary = Dictionary(state_variant)
		if PackedStringArray(state.get("unit_ids", PackedStringArray())).has(normalized_unit_id):
			return state
	return {}


func get_enemy_team_tactics_snapshot() -> Array:
	var result: Array = []
	var group_ids: Array = _enemy_team_tactics_states_by_group_id.keys()
	group_ids.sort()
	for group_id_variant in group_ids:
		var state: Dictionary = Dictionary(_enemy_team_tactics_states_by_group_id.get(group_id_variant, {})).duplicate(true)
		if state.is_empty():
			continue
		result.append(state)
	return result


func get_enemy_team_tactics_state_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	for state_variant in get_enemy_team_tactics_snapshot():
		var state: Dictionary = Dictionary(state_variant)
		if PackedStringArray(state.get("unit_ids", PackedStringArray())).has(normalized_unit_id):
			return state
	return {}


func get_enemy_limbo_behavior_snapshot() -> Dictionary:
	if _enemy_limbo_behavior_adapter == null or not _enemy_limbo_behavior_adapter.has_method("get_behavior_tree_snapshot"):
		return {}
	var snapshot: Dictionary = Dictionary(_enemy_limbo_behavior_adapter.call("get_behavior_tree_snapshot")).duplicate(true)
	snapshot["enabled"] = enemy_limbo_behavior_smoke_enabled
	snapshot["cover_cooldown_count"] = _enemy_limbo_cover_ready_at_msec.size()
	snapshot["decision_count"] = _enemy_limbo_behavior_decisions.size()
	snapshot["decisions"] = _build_enemy_limbo_behavior_decision_snapshot()
	return snapshot


func _build_enemy_limbo_behavior_decision_snapshot() -> Array:
	var result: Array = []
	var unit_ids: PackedStringArray = PackedStringArray()
	for unit_id_variant in _enemy_limbo_behavior_decisions.keys():
		unit_ids.append(String(unit_id_variant))
	unit_ids.sort()
	for unit_id in unit_ids:
		var entry: Dictionary = Dictionary(_enemy_limbo_behavior_decisions.get(unit_id, {})).duplicate(true)
		if not entry.is_empty():
			result.append(entry)
	return result


func get_fire_event_snapshot() -> Array:
	var result: Array = []
	for event_variant in _recent_fire_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant).duplicate(true)
		var fire_event_id: String = String(event.get("event_id", "")).strip_edges()
		if _combat_outcome_by_fire_event_id.has(fire_event_id):
			for key in Dictionary(_combat_outcome_by_fire_event_id.get(fire_event_id, {})).keys():
				event[key] = Dictionary(_combat_outcome_by_fire_event_id.get(fire_event_id, {})).get(key)
		result.append(event)
	return result


func get_overwatch_member_ready_snapshot() -> Dictionary:
	if _overwatch_controller == null or not _overwatch_controller.has_method("get_member_ready_snapshot"):
		return {}
	return Dictionary(_overwatch_controller.call("get_member_ready_snapshot", _current_tick)).duplicate(true)


func get_audio_sfx_debug_snapshot() -> Dictionary:
	var bus = _ensure_audio_event_bus(false)
	if bus != null and bus.has_method("get_diagnostic_snapshot"):
		return Dictionary(bus.call("get_diagnostic_snapshot")).duplicate(true)
	return {}


func emit_impact_sfx_for_tests(hit_context: Dictionary, unit = null) -> Dictionary:
	return _emit_impact_sfx(hit_context, unit)


func get_character_gameplay_snapshot() -> Array:
	var mission_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("build_mission_character_context", _get_units(friendly_unit_paths)))
	return Array(mission_context.get("public_snapshot", [])).duplicate(true)


func _record_fire_event_from_effect(effect: Dictionary, attacker, target, source: String) -> String:
	if effect.is_empty():
		return ""
	var event: Dictionary = _build_fire_event(
		String(effect.get("attacker_unit_id", "")),
		String(effect.get("attacker_team_id", "")),
		String(effect.get("unit_id", "")),
		String(target.call("get_team_id")) if target != null and target.has_method("get_team_id") else "",
		String(effect.get("weapon_id", "")),
		int(effect.get("weapon_tile_range", 0)),
		float(effect.get("weapon_range_world", 0.0)),
		attacker,
		target,
		source
	)
	if bool(effect.get("is_flank", false)):
		event["is_flank"] = true
		event["flank_fireteam_id"] = String(effect.get("flank_fireteam_id", ""))
		event["flank_source_angle"] = float(effect.get("flank_source_angle", 0.0))
		event["flank_direction_label"] = String(effect.get("flank_direction_label", ""))
		event["flank_morale_state"] = String(effect.get("flank_morale_state", ""))
	if bool(effect.get("is_friendly_fire", false)):
		event["is_friendly_fire"] = true
		event["friendly_fire_target_unit_id"] = String(effect.get("friendly_fire_target_unit_id", effect.get("unit_id", "")))
		event["intended_target_unit_id"] = String(effect.get("intended_target_unit_id", ""))
		event["misidentified_target_unit_id"] = String(effect.get("misidentified_target_unit_id", effect.get("unit_id", "")))
	return _append_fire_event(event)


func _record_fire_event_from_shot(shot: Dictionary, attacker, target, source: String) -> String:
	if shot.is_empty():
		return ""
	var event: Dictionary = _build_fire_event(
		String(shot.get("attacker_unit_id", "")),
		String(shot.get("attacker_team_id", "")),
		String(shot.get("target_unit_id", "")),
		String(target.call("get_team_id")) if target != null and target.has_method("get_team_id") else "",
		String(shot.get("weapon_id", "")),
		int(shot.get("weapon_tile_range", 0)),
		float(shot.get("weapon_range_world", 0.0)),
		attacker,
		target,
		source
	)
	return _append_fire_event(event)


func _build_fire_event(
	attacker_unit_id: String,
	attacker_team_id: String,
	target_unit_id: String,
	target_team_id: String,
	weapon_id: String,
	weapon_tile_range: int,
	weapon_range_world: float,
	attacker,
	target,
	source: String
) -> Dictionary:
	var sequence: int = _next_fire_event_sequence
	var event_id: String = "fire_%08d_%04d_%s_%s" % [_current_tick, sequence, attacker_unit_id, target_unit_id]
	var attacker_position: Vector2 = _get_unit_world_position(attacker)
	var target_position: Vector2 = _get_unit_world_position(target)
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": source,
		"tick": _current_tick,
		"sequence": sequence,
		"attacker_unit_id": attacker_unit_id,
		"attacker_team_id": attacker_team_id,
		"attacker_fireteam_id": _get_unit_fireteam_id(attacker),
		"target_unit_id": target_unit_id,
		"target_team_id": target_team_id,
		"target_fireteam_id": _get_unit_fireteam_id(target),
		"weapon_id": weapon_id,
		"weapon_tile_range": weapon_tile_range,
		"weapon_range_world": weapon_range_world,
		"attacker_position": attacker_position,
		"target_position": target_position,
		"attacker_facing_angle": _get_facing_angle_between_positions(attacker_position, target_position),
	}


func _append_fire_event(event: Dictionary) -> String:
	var event_id: String = String(event.get("event_id", "")).strip_edges()
	if event_id.is_empty():
		return ""
	_recent_fire_events.append(event.duplicate(true))
	_next_fire_event_sequence += 1
	_prune_recent_fire_events()
	return event_id


func _prune_recent_fire_events() -> void:
	var retained: Array = []
	var retained_ids: Dictionary = {}
	for event_variant in _recent_fire_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		if _current_tick - int(event.get("tick", _current_tick)) <= RECENT_FIRE_EVENT_TTL_TICKS:
			retained.append(event)
			retained_ids[String(event.get("event_id", "")).strip_edges()] = true
	if retained.size() > MAX_RECENT_FIRE_EVENTS:
		retained = retained.slice(retained.size() - MAX_RECENT_FIRE_EVENTS)
		retained_ids.clear()
		for retained_event_variant in retained:
			var retained_event: Dictionary = Dictionary(retained_event_variant)
			retained_ids[String(retained_event.get("event_id", "")).strip_edges()] = true
	_recent_fire_events = retained
	for fire_event_id in _combat_outcome_by_fire_event_id.keys().duplicate():
		if not bool(retained_ids.get(String(fire_event_id), false)):
			_combat_outcome_by_fire_event_id.erase(fire_event_id)


func _on_damage_effect_resolved(result: Dictionary) -> void:
	var fire_event_id: String = String(result.get("fire_event_id", "")).strip_edges()
	if fire_event_id.is_empty():
		return
	var outcome: Dictionary = {
		"combat_outcome": String(result.get("outcome", "miss")),
		"combat_hit": bool(result.get("hit", false)),
		"hit_chance_resolved": float(result.get("hit_chance_resolved", 0.0)),
		"roll": float(result.get("roll", 0.0)),
		"damage_resolved": int(result.get("damage_resolved", 0)),
		"damage_multiplier_resolved": float(result.get("damage_multiplier_resolved", 0.0)),
		"target_cover_score": float(result.get("target_cover_score", 0.0)),
		"target_cover_ratio": float(result.get("target_cover_ratio", 0.0)),
		"target_health_points": int(result.get("target_health_points", -1)),
		"target_vital_state": String(result.get("target_vital_state", "")),
	}
	_combat_outcome_by_fire_event_id[fire_event_id] = outcome
	for index in range(_recent_fire_events.size()):
		var event_variant = _recent_fire_events[index]
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant).duplicate(true)
		if String(event.get("event_id", "")).strip_edges() != fire_event_id:
			continue
		for key in outcome.keys():
			event[key] = outcome[key]
		_recent_fire_events[index] = event
		break
	if bool(result.get("hit", false)):
		_set_event_text("%s HIT %d" % [String(result.get("unit_id", result.get("target_unit_id", ""))), int(result.get("damage_resolved", 0))])
	else:
		_set_event_text("%s MISS %s%%" % [String(result.get("attacker_unit_id", "")), int(round(float(result.get("hit_chance_resolved", 0.0)) * 100.0))])
	_refresh_tactical_combat_visuals()


func _get_unit_world_position(unit) -> Vector2:
	if unit is Node2D:
		return (unit as Node2D).global_position
	return Vector2.ZERO


func _get_facing_angle_between_positions(from_position: Vector2, to_position: Vector2) -> float:
	if from_position.distance_squared_to(to_position) <= 0.0001:
		return 0.0
	return (to_position - from_position).angle()


func _store_combat_attacker_facing(attacker, target) -> void:
	if attacker == null or target == null or not (attacker is Node) or not attacker.has_method("get_unit_id"):
		return
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("enqueue_effect"):
		return
	var attacker_position: Vector2 = _get_unit_world_position(attacker)
	var target_position: Vector2 = _get_unit_world_position(target)
	if attacker_position.distance_squared_to(target_position) <= 0.0001:
		return
	var facing_angle: float = _get_facing_angle_between_positions(attacker_position, target_position)
	var hex_adapter = get_hex_sight_adapter()
	if hex_adapter.is_active():
		var logical: Dictionary = hex_adapter.build_observer_state(attacker,-1.0)
		if logical.is_empty():
			return
		facing_angle = hex_adapter.facing_to_world_angle(int(logical.hex_state.facing_dir))
	var is_enemy_attacker: bool = attacker.has_method("get_team_id") and String(attacker.call("get_team_id")) != friendly_team_id
	var effect: Dictionary = {
		"effect_type": "set_unit_combat_posture",
		"unit_id": String(attacker.call("get_unit_id")).strip_edges(),
		"facing_angle": facing_angle,
		"enemy_facing": is_enemy_attacker,
		"apply_posture": is_enemy_attacker,
	}
	if String(effect.get("unit_id", "")).is_empty():
		return
	if is_enemy_attacker:
		effect["movement_posture"] = ENEMY_POSTURE_ENGAGE
		effect["weapon_posture"] = ENEMY_WEAPON_AIMED
		effect["posture_policy_id"] = "fire_event"
		effect["move_speed_factor"] = _get_enemy_aim_move_speed_factor(attacker)
	simulation_root.call("enqueue_effect", effect)


func _ensure_audio_event_bus(create_if_missing: bool = true):
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus):
		return _audio_event_bus
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree != null:
		var current_scene := tree.current_scene
		if current_scene != null:
			var scene_bus := current_scene.find_child("AudioEventBus", true, false)
			if scene_bus != null and scene_bus.has_method("emit_impact"):
				_audio_event_bus = scene_bus
				return _audio_event_bus
		var root_bus := tree.root.find_child("AudioEventBus", true, false)
		if root_bus != null and root_bus.has_method("emit_impact"):
			_audio_event_bus = root_bus
			return _audio_event_bus
	if not create_if_missing:
		return null
	_audio_event_bus = AUDIO_EVENT_BUS_SCRIPT.new()
	_audio_event_bus.name = "AudioEventBus"
	var parent: Node = self
	if tree != null and tree.current_scene != null:
		parent = tree.current_scene
	parent.add_child(_audio_event_bus)
	if _audio_event_bus.has_method("initialize"):
		_audio_event_bus.call("initialize")
	return _audio_event_bus


func _emit_impact_sfx(hit_context: Dictionary, unit = null) -> Dictionary:
	var bus = _ensure_audio_event_bus()
	if bus == null or not bus.has_method("emit_impact"):
		return {"played": false, "reason": "missing_audio_event_bus"}
	var weapon_id: String = String(hit_context.get("weapon_id", "")).strip_edges().to_lower()
	var unit_id: String = String(hit_context.get("unit_id", ""))
	if unit_id.is_empty() and unit != null and unit.has_method("get_unit_id"):
		unit_id = String(unit.call("get_unit_id"))
	var fire_event_id: String = String(hit_context.get("fire_event_id", "hit:%s:%d" % [unit_id, _current_tick])).strip_edges()
	var world_position: Vector2 = _get_unit_world_position(unit)
	var impact_type: String = _impact_type_for_weapon_id(weapon_id)
	var result: Dictionary = Dictionary(bus.call("emit_impact", impact_type, {
		"position": Vector3(world_position.x, 0.0, world_position.y),
		"unit_id": unit_id,
		"team_id": String(hit_context.get("attacker_team_id", "")),
		"source": "mission_damage_applied",
		"visible_to_local": bool(hit_context.get("visible_to_local", true)),
		"visibility_context": String(hit_context.get("visibility_context", "damage_visible")),
		"dedupe_key": "impact:%s" % fire_event_id,
		"dedupe_window_msec": 5000,
	})).duplicate(true)
	if weapon_id == "rocket_launcher" and bus.has_method("emit_explosion"):
		bus.call("emit_explosion", "large", {
			"position": Vector3(world_position.x, 0.0, world_position.y),
			"unit_id": unit_id,
			"team_id": String(hit_context.get("attacker_team_id", "")),
			"source": "mission_damage_applied",
			"visible_to_local": bool(hit_context.get("visible_to_local", true)),
			"visibility_context": String(hit_context.get("visibility_context", "damage_visible")),
			"dedupe_key": "explosion:%s" % fire_event_id,
			"dedupe_window_msec": 5000,
		})
	return result


func _impact_type_for_weapon_id(weapon_id: String) -> String:
	match String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", weapon_id)):
		"rail_gun", "rocket_launcher":
			return "metal_heavy"
		"sniper":
			return "metal_medium"
		"smg":
			return "metal_light"
		_:
			return "generic_light"


func get_fireteam_flank_vulnerability_state(fireteam_id: String) -> Dictionary:
	if not flank_vulnerability_enabled or _flank_vulnerability_resolver == null:
		return {}
	return Dictionary(_flank_vulnerability_resolver.call("get_fireteam_state", fireteam_id, _current_tick)).duplicate(true)


@rpc("authority", "reliable")
func _receive_mission_result(mission_result: Dictionary) -> void:
	if _runs_local_authority:
		return

	_combat_finished = true
	_mission_result = mission_result.duplicate(true)
	_winning_team_id = String(_mission_result.get("winning_team_id", ""))
	_set_event_text("MISSION %s" % String(_mission_result.get("result", "ended")).to_upper())
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	combat_resolved.emit(get_mission_result())


@rpc("authority", "reliable")
func _receive_remote_event(
	event_text: String,
	unit_id: String = "",
	event_color: Color = DEFAULT_EVENT_COLOR,
	duration_seconds: float = EVENT_DEFAULT_DURATION,
	unit_event_text: String = ""
) -> void:
	if _runs_local_authority:
		return

	var payload: Dictionary = Dictionary(_remote_event_bridge.call("build_event_payload", event_text, unit_id, event_color, duration_seconds, unit_event_text))
	_remote_event_bridge.call("apply_event_payload", self, payload)


func _on_tick_processed(tick: int) -> void:
	_current_tick = tick
	_refresh_mission_interaction_door_runtime_overrides()
	var simulation_root = get_node_or_null(simulation_root_path)
	if not _refresh_runtime_authority(simulation_root):
		_close_hotpath_unit_cache_scope()
		return
	_refresh_hotpath_unit_cache_for_tick()
	_begin_combat_visibility_cache_tick(tick)
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	var tick_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var profile_scopes: Dictionary = {}
	var scope_started_usec: int = 0
	if _combat_finished:
		_update_presence_seen_flags()
		if _try_recover_premature_startup_resolution():
			pass
		else:
			_update_status_label("resolved")
			_sync_objective_countdown_state()
			if profile_enabled:
				scope_started_usec = Time.get_ticks_usec()
			_publish_multiplayer_snapshot_context(simulation_root)
			if profile_enabled:
				profile_scopes["multiplayer_snapshot_context_usec"] = Time.get_ticks_usec() - scope_started_usec
				_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, simulation_root, "resolved")
			_close_hotpath_unit_cache_scope()
			return
	if simulation_root == null:
		if profile_enabled:
			_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, simulation_root, "missing_simulation_root")
		_close_hotpath_unit_cache_scope()
		return
	var interaction_delta: float = float(simulation_root.call("get_last_tick_delta")) if simulation_root.has_method("get_last_tick_delta") else 0.0
	_advance_pending_network_mission_interactions(interaction_delta)

	_update_presence_seen_flags()
	if _current_tick < _combat_startup_grace_ticks:
		# Grace delays combat decisions, while the existing owner still publishes
		# scenario/countdown progress. Snapshot readers remain side-effect free.
		_sync_objective_countdown_state()
		_update_status_label("staging")
		_publish_multiplayer_snapshot_context(simulation_root)
		if profile_enabled:
			_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, simulation_root, "startup_grace")
		_close_hotpath_unit_cache_scope()
		return

	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_queue_bleedout_for_downed_enemy(simulation_root)
	_queue_bleedout_for_downed_friendly(simulation_root)
	if profile_enabled:
		profile_scopes["bleedout_queue_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_update_fireteam_leadership()
	if profile_enabled:
		profile_scopes["leadership_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_advance_detection_timers()
	if profile_enabled:
		profile_scopes["detection_timers_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_update_contact_tracking()
	if profile_enabled:
		profile_scopes["contact_tracking_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_advance_discipline_cooldowns()
	_advance_return_fire_windows()
	_advance_misidentification_cooldowns()
	_advance_medic_support_cooldowns()
	if profile_enabled:
		profile_scopes["cooldowns_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	if not _should_run_combat_decision_tick(tick):
		if profile_enabled:
			_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, simulation_root, "decision_cadence_skip")
		_close_hotpath_unit_cache_scope()
		return
	_update_enemy_security_state()
	if profile_enabled:
		profile_scopes["enemy_security_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_update_enemy_team_tactics_state()
	if profile_enabled:
		profile_scopes["enemy_team_tactics_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_advance_flank_vulnerability_state()
	if profile_enabled:
		profile_scopes["flank_vulnerability_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_try_enqueue_medic_support(simulation_root)
	if profile_enabled:
		profile_scopes["medic_support_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_advance_enemy_units(simulation_root)
	if profile_enabled:
		profile_scopes["enemy_advance_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_apply_friendly_standard_behavior(simulation_root)
	if profile_enabled:
		profile_scopes["friendly_standard_behavior_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	var overwatch_shots: Array = _try_enqueue_overwatch(simulation_root)
	if profile_enabled:
		profile_scopes["overwatch_security_usec"] = Time.get_ticks_usec() - scope_started_usec
	if overwatch_shots.is_empty():
		if profile_enabled:
			scope_started_usec = Time.get_ticks_usec()
		_try_enqueue_attacks(simulation_root)
		if profile_enabled:
			profile_scopes["combat_fire_decision_usec"] = Time.get_ticks_usec() - scope_started_usec
			for fire_scope_name_variant in _combat_fire_decision_debug_scopes_usec.keys():
				var fire_scope_name: String = String(fire_scope_name_variant)
				profile_scopes[fire_scope_name] = int(_combat_fire_decision_debug_scopes_usec.get(fire_scope_name_variant, 0))
	elif profile_enabled:
		profile_scopes["combat_fire_decision_usec"] = 0
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_sync_objective_countdown_state()
	_update_combat_resolution()
	if profile_enabled:
		profile_scopes["combat_resolution_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_publish_multiplayer_snapshot_context(simulation_root)
	if profile_enabled:
		profile_scopes["multiplayer_snapshot_context_usec"] = Time.get_ticks_usec() - scope_started_usec
	if not _combat_finished:
		if profile_enabled:
			scope_started_usec = Time.get_ticks_usec()
		_update_status_label("active")
		if profile_enabled:
			profile_scopes["status_update_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	_flush_pending_tactical_combat_visuals()
	if profile_enabled:
		profile_scopes["combat_visual_refresh_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, simulation_root, "active")
	_close_hotpath_unit_cache_scope()


func _should_run_combat_decision_tick(tick: int) -> bool:
	return tick % COMBAT_DECISION_INTERVAL_TICKS == 0


func _refresh_runtime_authority(simulation_root: Node) -> bool:
	var should_run: bool = _should_run_local_combat(simulation_root)
	if should_run == _runs_local_authority:
		return should_run
	_runs_local_authority = should_run
	if not should_run:
		if simulation_root != null and simulation_root.has_method("clear_network_command_preflight_validator"):
			simulation_root.call("clear_network_command_preflight_validator", Callable(self, "_validate_network_interaction_command_preflight"))
		_update_status_label("observing")
		return false
	if simulation_root != null and simulation_root.has_method("set_network_command_preflight_validator"):
		simulation_root.call("set_network_command_preflight_validator", Callable(self, "_validate_network_interaction_command_preflight"))
	_update_status_label("active")
	return true


func _record_combat_tick_budget_debug_snapshot(tick: int, tick_started_usec: int, profile_scopes: Dictionary, simulation_root: Node, state: String) -> void:
	var command_queue_after_tick: int = 0
	var effect_queue_after_tick: int = 0
	if simulation_root != null:
		var command_queue_variant: Variant = simulation_root.get("command_queue")
		if command_queue_variant is Array:
			command_queue_after_tick = (command_queue_variant as Array).size()
		var effect_queue_variant: Variant = simulation_root.get("effects_queue")
		if effect_queue_variant is Array:
			effect_queue_after_tick = (effect_queue_variant as Array).size()
	var friendly_units: Array = _get_units(friendly_unit_paths)
	var enemy_units: Array = _get_units(enemy_unit_paths)
	var active_enemy_units: Array = _get_active_enemy_units()
	_combat_tick_budget_debug_snapshot = {
		"enabled": combat_tick_budget_debug_enabled,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"tick": tick,
		"state": state,
		"total_tick_usec": Time.get_ticks_usec() - tick_started_usec,
		"scopes_usec": profile_scopes.duplicate(true),
		"friendly_unit_count": friendly_units.size(),
		"enemy_unit_count": enemy_units.size(),
		"active_enemy_unit_count": active_enemy_units.size(),
		"enemy_security_group_count": _enemy_security_states_by_group_id.size(),
		"enemy_team_tactics_group_count": _enemy_team_tactics_states_by_group_id.size(),
		"recent_fire_event_count": _recent_fire_events.size(),
		"command_queue_after_tick": command_queue_after_tick,
		"effect_queue_after_tick": effect_queue_after_tick,
		"authority_side": _runs_local_authority,
		"hotpath_audit": get_combat_hotpath_audit_snapshot(),
	}


func _queue_bleedout_for_downed_enemy(simulation_root: Node) -> void:
	_queue_bleedout_for_downed_units(simulation_root, _get_units(enemy_unit_paths))


func _queue_bleedout_for_downed_friendly(simulation_root: Node) -> void:
	_queue_bleedout_for_downed_units(simulation_root, _get_units(friendly_unit_paths))


func _queue_bleedout_for_downed_units(simulation_root: Node, units: Array) -> void:
	if simulation_root == null:
		return
	for unit in units:
		if unit == null or not unit.has_method("get_vital_state") or not unit.has_method("get_unit_id"):
			continue

		var unit_id: String = String(unit.call("get_unit_id"))
		if unit_id.is_empty() or _queued_bleedout_by_unit_id.get(unit_id, false):
			continue

		if String(unit.call("get_vital_state")) != "down":
			continue

		if not _has_down_state_linger_elapsed(unit_id):
			continue

		simulation_root.call(
			"enqueue_effect",
			{
				"effect_type": "bleedout",
				"priority": 20,
				"unit_id": unit_id,
			}
		)
		_queued_bleedout_by_unit_id[unit_id] = true
		_set_event_text("%s BLEEDOUT" % unit_id)
		return


func _mark_unit_down_started(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or _down_state_started_msec_by_unit_id.has(normalized_unit_id):
		return
	_down_state_started_msec_by_unit_id[normalized_unit_id] = Time.get_ticks_msec()


func _clear_down_state_linger(unit_id: String) -> void:
	_down_state_started_msec_by_unit_id.erase(unit_id.strip_edges())


func _has_down_state_linger_elapsed(unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return false
	if not _down_state_started_msec_by_unit_id.has(normalized_unit_id):
		_mark_unit_down_started(normalized_unit_id)
		return false
	var started_msec: int = int(_down_state_started_msec_by_unit_id.get(normalized_unit_id, Time.get_ticks_msec()))
	var elapsed_seconds: float = float(Time.get_ticks_msec() - started_msec) / 1000.0
	return elapsed_seconds >= DOWN_STATE_VISIBLE_MIN_SECONDS


func _request_respawn_for_unit(unit, unit_id: String) -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("request_respawn"):
		return

	var unit_team_id: String = ""
	if unit.has_method("get_team_id"):
		unit_team_id = String(unit.call("get_team_id"))

	if unit_team_id.is_empty():
		return
	if _finite_enemy_roster and unit_team_id != friendly_team_id:
		return

	respawn_manager.call("request_respawn", unit_id, unit_team_id)


func _try_enqueue_attacks(simulation_root: Node) -> void:
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	if profile_enabled:
		_combat_fire_decision_debug_scopes_usec.clear()
	var scope_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var contact_pair: Dictionary = _find_first_contact_pair()
	if profile_enabled:
		_combat_fire_decision_debug_scopes_usec["fire_find_contact_pair_usec"] = Time.get_ticks_usec() - scope_started_usec
	if contact_pair.is_empty():
		if profile_enabled:
			scope_started_usec = Time.get_ticks_usec()
		_clear_contact_visuals()
		_record_contact_decision_diagnostics("no_contact_pair", {"candidate": _build_first_fire_candidate_diagnostic()})
		if profile_enabled:
			_combat_fire_decision_debug_scopes_usec["fire_no_contact_diagnostic_usec"] = Time.get_ticks_usec() - scope_started_usec
		return

	var attacker = contact_pair["attacker"]
	var target = contact_pair["target"]
	var attacker_id: String = String(contact_pair["attacker_id"])
	var target_id: String = String(contact_pair["target_id"])
	var contact_state: String = String(contact_pair.get("contact_state", "")).strip_edges().to_lower()
	if attacker_id.is_empty() or target_id.is_empty():
		_clear_contact_visuals()
		_record_contact_decision_diagnostics("invalid_contact_pair", _build_contact_pair_decision_diagnostic(contact_pair))
		return

	_last_contact = {
		"attacker_id": attacker_id,
		"target_id": target_id,
	}
	_set_contact_visuals(attacker, target)
	_update_status_label("contact")
	if _current_tick < _next_attack_tick:
		if profile_enabled:
			scope_started_usec = Time.get_ticks_usec()
		_record_contact_decision_diagnostics("cooldown", _build_contact_pair_decision_diagnostic(contact_pair))
		if profile_enabled:
			_combat_fire_decision_debug_scopes_usec["fire_cooldown_diagnostic_usec"] = Time.get_ticks_usec() - scope_started_usec
		return

	if profile_enabled:
		scope_started_usec = Time.get_ticks_usec()
	var decision: Dictionary = COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("build_damage_effect", contact_pair, _build_fire_decision_context())
	if profile_enabled:
		_combat_fire_decision_debug_scopes_usec["fire_build_damage_effect_usec"] = Time.get_ticks_usec() - scope_started_usec
	if decision.is_empty():
		if profile_enabled:
			scope_started_usec = Time.get_ticks_usec()
		_record_contact_decision_diagnostics("no_damage_effect", _build_contact_pair_decision_diagnostic(contact_pair))
		if profile_enabled:
			_combat_fire_decision_debug_scopes_usec["fire_no_damage_effect_diagnostic_usec"] = Time.get_ticks_usec() - scope_started_usec
		return
	var actual_target = decision.get("target", target)
	var actual_target_id: String = String(decision.get("target_id", target_id))
	var is_friendly_fire: bool = bool(decision.get("is_friendly_fire", false))

	_store_combat_attacker_facing(attacker, actual_target)
	contact_established.emit(attacker, actual_target)
	if is_friendly_fire:
		_set_event_text("%s verwechselt Ziel! -> %s" % [attacker_id, actual_target_id])
	else:
		_set_event_text("%s ENGAGE %s" % [attacker_id, actual_target_id])
	var damage_effect: Dictionary = Dictionary(decision.get("effect", {})).duplicate(true)
	if is_friendly_fire:
		damage_effect["is_friendly_fire"] = true
		damage_effect["friendly_fire_target_unit_id"] = actual_target_id
		damage_effect["intended_target_unit_id"] = target_id
		damage_effect["misidentified_target_unit_id"] = actual_target_id
	var fire_event_id: String = _record_fire_event_from_effect(damage_effect, attacker, actual_target, "standard")
	if not fire_event_id.is_empty():
		_last_standard_attacker_fireteam_id = _get_unit_fireteam_id(attacker)
		damage_effect["fire_event_id"] = fire_event_id
		_refresh_tactical_combat_visuals()
	simulation_root.call("enqueue_effect", damage_effect)
	_record_return_fire_window_if_needed(attacker, actual_target)
	var flank_modifiers: Dictionary = Dictionary(decision.get("flank_modifiers", {}))
	_maybe_publish_flank_event(flank_modifiers, attacker, actual_target)
	if is_friendly_fire:
		if attacker != null and attacker.has_method("show_event_text"):
			attacker.call("show_event_text", "EIGENBESCHUSS!", MISIDENTIFICATION_EVENT_COLOR, 1.6)
		if actual_target != null and actual_target.has_method("show_event_text"):
			actual_target.call("show_event_text", "FRIENDLY FIRE", MISIDENTIFICATION_EVENT_COLOR, 1.8)
		_broadcast_remote_event("%s verwechselt Ziel! -> %s" % [attacker_id, actual_target_id], attacker_id, MISIDENTIFICATION_EVENT_COLOR, 1.6, "EIGENBESCHUSS!")
		_broadcast_remote_event("FRIENDLY FIRE %s" % actual_target_id, actual_target_id, MISIDENTIFICATION_EVENT_COLOR, 1.8, "FRIENDLY FIRE")
		_record_friendly_fire_feedback(attacker, actual_target, attacker_id, target_id, actual_target_id)
	_next_attack_tick = _current_tick + max(int(decision.get("weapon_ticks", 1)), 1)
	var fired_diagnostic: Dictionary = _build_contact_pair_decision_diagnostic(contact_pair, decision)
	fired_diagnostic["fire_event_id"] = fire_event_id
	fired_diagnostic["actual_target_id"] = actual_target_id
	fired_diagnostic["is_friendly_fire"] = is_friendly_fire
	fired_diagnostic["hit_chance"] = float(damage_effect.get("hit_chance", 0.0))
	fired_diagnostic["damage"] = int(damage_effect.get("damage", 0))
	fired_diagnostic["weapon_ticks"] = int(decision.get("weapon_ticks", 1))
	_record_contact_decision_diagnostics("fired", fired_diagnostic)


func _record_contact_decision_diagnostics(reason: String, data: Dictionary = {}) -> void:
	var normalized_reason: String = reason.strip_edges().to_lower()
	var snapshot: Dictionary = {
		"source": "MissionCombatLoopDriver",
		"read_only": true,
		"tick": _current_tick,
		"reason": normalized_reason,
		"status": _resolve_contact_decision_status(normalized_reason),
		"current_tick": _current_tick,
		"next_attack_tick": _next_attack_tick,
		"cooldown_ticks_remaining": maxi(_next_attack_tick - _current_tick, 0),
		"active_friendly_count": _get_units(friendly_unit_paths).size(),
		"active_enemy_count": _get_active_enemy_units().size(),
		"combat_friendly_count": _get_friendly_combat_units().size(),
		"combat_enemy_count": _get_enemy_combat_units().size(),
		"potential_combat_pair_count": _get_friendly_combat_units().size() * _get_enemy_combat_units().size(),
		"last_contact_tracking_scan_pair_count": _last_contact_tracking_scan_pair_count,
		"last_contact_tracking_los_check_count": _last_contact_tracking_los_check_count,
		"last_contact_tracking_los_cache_hit_count": _last_contact_tracking_los_cache_hit_count,
		"contact_count": get_contact_snapshot().size(),
		"detection_pending_count": get_detection_progress().size(),
	}
	var detection_snapshot: Dictionary = _build_first_detection_progress_snapshot()
	if not detection_snapshot.is_empty():
		snapshot["first_detection"] = detection_snapshot
	for key in data.keys():
		snapshot[key] = data[key]
	_last_contact_decision_diagnostics = snapshot
	_record_suppress_fire_outcome_diagnostic_if_needed(snapshot)


func _resolve_contact_decision_status(reason: String) -> String:
	match reason:
		"fired":
			return "fired"
		"cooldown":
			return "waiting"
		"no_contact_pair", "invalid_contact_pair", "no_damage_effect":
			return "blocked"
		_:
			return "unknown"


func _record_suppress_fire_outcome_diagnostic_if_needed(snapshot: Dictionary) -> void:
	if not _is_suppress_fire_outcome_diagnostic_countable(snapshot):
		return
	var dedupe_key: String = _build_suppress_fire_outcome_diagnostic_key(snapshot)
	if dedupe_key.is_empty() or bool(_suppress_fire_outcome_diagnostic_keys_seen.get(dedupe_key, false)):
		return
	_suppress_fire_outcome_diagnostic_keys_seen[dedupe_key] = true
	_suppress_fire_outcome_diagnostic_count += 1
	var fireteam_id: String = String(snapshot.get("attacker_fireteam_id", "")).strip_edges().to_lower()
	if not fireteam_id.is_empty():
		_suppress_fire_outcome_diagnostic_by_fireteam[fireteam_id] = int(_suppress_fire_outcome_diagnostic_by_fireteam.get(fireteam_id, 0)) + 1
	var fire_rule_outcome: Dictionary = Dictionary(snapshot.get("fire_rule_outcome", {})).duplicate(true)
	_last_suppress_fire_outcome_diagnostic = {
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"dedupe_key": dedupe_key,
		"tick": int(snapshot.get("tick", _current_tick)),
		"reason": String(snapshot.get("reason", "")).strip_edges().to_lower(),
		"status": String(snapshot.get("status", "")).strip_edges().to_lower(),
		"fire_event_id": String(snapshot.get("fire_event_id", "")).strip_edges(),
		"attacker_unit_id": String(snapshot.get("attacker_unit_id", "")).strip_edges(),
		"target_unit_id": String(snapshot.get("target_unit_id", "")).strip_edges(),
		"attacker_fireteam_id": fireteam_id,
		"attacker_fire_rule": String(snapshot.get("attacker_fire_rule", "")).strip_edges().to_lower(),
		"outcome_label": String(fire_rule_outcome.get("outcome_label", snapshot.get("attacker_fire_rule_outcome", ""))).strip_edges(),
		"suppress_intent_active": bool(snapshot.get("suppress_intent_active", fire_rule_outcome.get("suppress_intent_active", false))),
		"suppress_pressure_intent_visible": bool(snapshot.get("suppress_pressure_intent_visible", fire_rule_outcome.get("suppress_pressure_intent_visible", false))),
		"suppress_effect_applied": bool(snapshot.get("suppress_effect_applied", fire_rule_outcome.get("suppress_effect_applied", false))),
		"suppression_effect_payload_enqueued": bool(snapshot.get("suppression_effect_payload_enqueued", fire_rule_outcome.get("suppression_effect_payload_enqueued", false))),
		"ammo_consumed": bool(snapshot.get("ammo_consumed", fire_rule_outcome.get("ammo_consumed", false))),
		"suppress_damage_modifier_applied": bool(snapshot.get("suppress_damage_modifier_applied", fire_rule_outcome.get("suppress_damage_modifier_applied", false))),
	}


func _is_suppress_fire_outcome_diagnostic_countable(snapshot: Dictionary) -> bool:
	if String(snapshot.get("status", "")).strip_edges().to_lower() != "fired":
		return false
	var fire_rule_outcome: Dictionary = Dictionary(snapshot.get("fire_rule_outcome", {}))
	var outcome_label: String = String(fire_rule_outcome.get("outcome_label", snapshot.get("attacker_fire_rule_outcome", ""))).strip_edges().to_lower()
	return bool(snapshot.get("suppress_intent_active", fire_rule_outcome.get("suppress_intent_active", false))) \
		and outcome_label == "suppress_pressure_intent"


func _build_suppress_fire_outcome_diagnostic_key(snapshot: Dictionary) -> String:
	var fire_event_id: String = String(snapshot.get("fire_event_id", "")).strip_edges()
	if not fire_event_id.is_empty():
		return "fire_event:%s" % fire_event_id
	return "tick:%d:%s:%s:%s" % [
		int(snapshot.get("tick", _current_tick)),
		String(snapshot.get("attacker_unit_id", "")).strip_edges(),
		String(snapshot.get("target_unit_id", "")).strip_edges(),
		String(snapshot.get("reason", "")).strip_edges().to_lower(),
	]


func _build_contact_pair_decision_diagnostic(contact_pair: Dictionary, decision: Dictionary = {}) -> Dictionary:
	var attacker = contact_pair.get("attacker", null)
	var target = contact_pair.get("target", null)
	var contact_state: String = String(contact_pair.get("contact_state", "")).strip_edges().to_lower()
	var readout: Dictionary = {}
	if attacker != null and target != null:
		readout = build_cover_effectiveness_readout_for_units(attacker, target, contact_state)
	var effect: Dictionary = Dictionary(decision.get("effect", {})).duplicate(true) if typeof(decision.get("effect", {})) == TYPE_DICTIONARY else {}
	var weapon_id: String = String(effect.get("weapon_id", readout.get("weapon_id", _get_unit_active_weapon_id(attacker)))).strip_edges()
	var fire_rule_outcome: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call(
		"build_fire_rule_outcome_diagnostic",
		attacker,
		{
			"can_attack": bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_unit_attack", attacker, _build_fire_decision_context())),
		}
	))
	return {
		"attacker_unit_id": String(contact_pair.get("attacker_id", _get_unit_id_for_diagnostics(attacker))).strip_edges(),
		"target_unit_id": String(contact_pair.get("target_id", _get_unit_id_for_diagnostics(target))).strip_edges(),
		"attacker_team_id": _get_unit_team_id_for_diagnostics(attacker),
		"target_team_id": _get_unit_team_id_for_diagnostics(target),
		"attacker_fireteam_id": _get_unit_fireteam_id(attacker),
		"attacker_fire_status": String(attacker.call("get_fire_status")) if attacker != null and attacker.has_method("get_fire_status") else "",
		"attacker_fire_rule": _get_unit_fire_rule_for_diagnostics(attacker),
		"attacker_return_fire_window_active": _can_unit_return_fire(attacker),
		"fire_rule_outcome": fire_rule_outcome,
		"attacker_fire_rule_outcome": String(fire_rule_outcome.get("outcome_label", "")).strip_edges(),
		"suppress_intent_active": bool(fire_rule_outcome.get("suppress_intent_active", false)),
		"suppress_pressure_intent_visible": bool(fire_rule_outcome.get("suppress_pressure_intent_visible", false)),
		"suppress_effect_applied": bool(fire_rule_outcome.get("suppress_effect_applied", false)),
		"suppression_effect_payload_enqueued": bool(fire_rule_outcome.get("suppression_effect_payload_enqueued", false)),
		"ammo_consumed": bool(fire_rule_outcome.get("ammo_consumed", false)),
		"suppress_damage_modifier_applied": bool(fire_rule_outcome.get("suppress_damage_modifier_applied", false)),
		"contact_state": contact_state,
		"weapon_id": weapon_id,
		"weapon_range_world": float(effect.get("weapon_range_world", readout.get("weapon_range_world", 0.0))),
		"distance_world": float(readout.get("distance_world", -1.0)),
		"range_state": String(readout.get("range_state", "")).strip_edges(),
		"los_state": String(readout.get("los_state", "")).strip_edges(),
		"cover_state": String(readout.get("cover_state", "")).strip_edges(),
		"combat_attackable": bool(readout.get("combat_attackable", false)),
		"attack_quality_label": String(readout.get("attack_quality_label", "")).strip_edges(),
	}


func _build_first_fire_candidate_diagnostic() -> Dictionary:
	var friendly_units: Array = _get_friendly_combat_units()
	var enemy_units: Array = _get_enemy_combat_units()
	_last_fire_candidate_pair_scan_count = 0
	if friendly_units.is_empty():
		return {"candidate_reason": "no_friendly_combat_units"}
	if enemy_units.is_empty():
		return {"candidate_reason": "no_enemy_combat_units"}
	var context: Dictionary = _build_fire_decision_context()
	for friendly in friendly_units:
		var attacker_ready: bool = bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_unit_attack", friendly, context))
		for enemy in enemy_units:
			_last_fire_candidate_pair_scan_count += 1
			var readout: Dictionary = build_cover_effectiveness_readout_for_units(friendly, enemy, "")
			var candidate: Dictionary = {
				"candidate_reason": _resolve_candidate_block_reason(readout, attacker_ready, bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_target_receive_attack", enemy))),
				"candidate_pair_scan_count": _last_fire_candidate_pair_scan_count,
				"attacker_ready": attacker_ready,
				"target_receive_attack": bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_target_receive_attack", enemy)),
				"attacker_unit_id": _get_unit_id_for_diagnostics(friendly),
				"target_unit_id": _get_unit_id_for_diagnostics(enemy),
				"weapon_id": String(readout.get("weapon_id", _get_unit_active_weapon_id(friendly))).strip_edges(),
				"weapon_range_world": float(readout.get("weapon_range_world", 0.0)),
				"distance_world": float(readout.get("distance_world", -1.0)),
				"range_state": String(readout.get("range_state", "")).strip_edges(),
				"los_state": String(readout.get("los_state", "")).strip_edges(),
				"combat_attackable": bool(readout.get("combat_attackable", false)),
				"attack_quality_label": String(readout.get("attack_quality_label", "")).strip_edges(),
			}
			return candidate
	return {"candidate_reason": "no_candidate"}


func _resolve_candidate_block_reason(readout: Dictionary, attacker_ready: bool, target_receive_attack: bool) -> String:
	if not attacker_ready:
		return "attacker_not_engage_ready"
	if not target_receive_attack:
		return "target_not_attackable"
	var attack_quality: String = String(readout.get("attack_quality_label", "")).strip_edges().to_lower()
	if not attack_quality.is_empty() and attack_quality != "open" and attack_quality != "covered" and attack_quality != "flank_opportunity":
		return attack_quality
	if String(readout.get("range_state", "")).strip_edges().to_lower() == "out_of_range":
		return "out_of_range"
	if String(readout.get("los_state", "")).strip_edges().to_lower() == "blocked":
		return "no_los"
	if not bool(readout.get("combat_attackable", false)):
		return "not_attackable"
	return "candidate_pending_detection_or_contact_state"


func _build_first_detection_progress_snapshot() -> Dictionary:
	if get_hex_sight_adapter().is_active():
		var episodes: Array = _get_hex_detection_state().build_episode_snapshot(_current_tick)
		if episodes.is_empty():
			return {}
		return episodes[0].duplicate(true)
	if _detection_progress.is_empty():
		return {}
	var keys: Array = _detection_progress.keys()
	keys.sort()
	var key: String = String(keys[0])
	var parts: PackedStringArray = key.split(":")
	return {
		"key": key,
		"attacker_unit_id": parts[0] if parts.size() > 0 else "",
		"target_unit_id": parts[1] if parts.size() > 1 else "",
		"ticks_remaining": int(_detection_progress.get(key, 0)),
	}


func _get_unit_id_for_diagnostics(unit) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return ""


func _get_unit_team_id_for_diagnostics(unit) -> String:
	if unit != null and unit.has_method("get_team_id"):
		return String(unit.call("get_team_id")).strip_edges()
	return ""


func _refresh_tactical_combat_visuals(force_refresh: bool = false) -> void:
	var now_msec: int = Time.get_ticks_msec()
	if not force_refresh and _last_tactical_combat_visual_refresh_msec > 0:
		var elapsed_msec: int = now_msec - _last_tactical_combat_visual_refresh_msec
		if elapsed_msec < TACTICAL_COMBAT_VISUAL_REFRESH_INTERVAL_MSEC:
			_tactical_combat_visual_refresh_pending = true
			_tactical_combat_visual_refresh_suppressed_count += 1
			return

	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null:
		_tactical_combat_visual_refresh_pending = false
		return
	if tactical_controller.has_method("_sync_primary_3d_order_visuals"):
		tactical_controller.call("_sync_primary_3d_order_visuals")
	if tactical_controller.has_method("refresh_contact_overlay"):
		tactical_controller.call("refresh_contact_overlay")
	_last_tactical_combat_visual_refresh_msec = now_msec
	_tactical_combat_visual_refresh_pending = false
	_tactical_combat_visual_refresh_count += 1


func _flush_pending_tactical_combat_visuals() -> void:
	if not _tactical_combat_visual_refresh_pending:
		return
	var now_msec: int = Time.get_ticks_msec()
	if _last_tactical_combat_visual_refresh_msec > 0:
		var elapsed_msec: int = now_msec - _last_tactical_combat_visual_refresh_msec
		if elapsed_msec < TACTICAL_COMBAT_VISUAL_REFRESH_INTERVAL_MSEC:
			return
	_refresh_tactical_combat_visuals(true)


func _update_presence_seen_flags() -> void:
	if not _has_seen_active_friendly_units and _count_fit_units(friendly_unit_paths) > 0:
		_has_seen_active_friendly_units = true
	if not _has_seen_active_enemy_units and _get_active_enemy_units().size() > 0:
		_has_seen_active_enemy_units = true


func _try_recover_premature_startup_resolution() -> bool:
	if not _combat_finished or not _resolved_without_seen_friendly:
		return false
	if _count_fit_units(friendly_unit_paths) <= 0:
		return false

	_combat_finished = false
	_winning_team_id = ""
	_mission_result_condition_override = ""
	_mission_result.clear()
	_resolved_without_seen_friendly = false
	_has_seen_active_friendly_units = true
	_set_event_text("COMBAT ACTIVE")
	_update_status_label("active")
	_update_winner_label()
	_record_contact_decision_diagnostics(
		"startup_presence_recovered",
		{"candidate": _build_first_fire_candidate_diagnostic()}
	)
	return true


func _update_combat_resolution() -> void:
	if _combat_finished:
		return
	_update_mission_scenario_runtime_gates()
	var decision: Dictionary = Dictionary(_combat_resolution_resolver.call(
		"build_resolution_decision",
		{
			"combat_finished": false,
			"duration_seconds": _get_duration_seconds(),
			"mission_time_limit_seconds": mission_time_limit_seconds,
			"victory_condition_met": _is_victory_condition_met(),
			"friendly_fit_count": _count_fit_units(friendly_unit_paths),
			"has_seen_active_friendly_units": _has_seen_active_friendly_units,
			"has_pending_friendly_insertions": _has_pending_friendly_insertions(),
			"friendly_team_id": friendly_team_id,
			"enemy_team_id": _get_enemy_team_id(),
		}
	))
	if not bool(decision.get("resolved", false)):
		return
	_resolve_combat(
		String(decision.get("result", "")),
		String(decision.get("winning_team_id", "")),
		String(decision.get("result_condition_override", ""))
	)


func _update_mission_scenario_runtime_gates() -> void:
	if _mission_scenario_runtime_gates == null or not bool(_mission_scenario_runtime_gates.call("is_configured")):
		_mission_scenario_runtime_gate_snapshot = {}
		_update_mission_cargo_touchdown_bridge({})
		_refresh_mission_interaction_door_runtime_overrides()
		return
	_mission_scenario_runtime_gate_snapshot = Dictionary(_mission_scenario_runtime_gates.call("update", _build_mission_scenario_runtime_gate_context())).duplicate(true)
	_update_mission_cargo_touchdown_bridge(_mission_scenario_runtime_gate_snapshot)
	_mission_scenario_runtime_gate_snapshot = Dictionary(_mission_scenario_runtime_gates.call("update", _build_mission_scenario_runtime_gate_context())).duplicate(true)
	_refresh_mission_interaction_door_runtime_overrides()


func _update_mission_cargo_touchdown_bridge(gate_snapshot: Dictionary) -> void:
	if _mission_cargo_touchdown_bridge == null or not bool(_mission_cargo_touchdown_bridge.call("is_configured")):
		_mission_cargo_touchdown_snapshot = {}
		return
	_mission_cargo_touchdown_snapshot = Dictionary(_mission_cargo_touchdown_bridge.call("update", {
		"scenario_gate_snapshot": gate_snapshot,
		"cargo_state": _mission_scenario_cargo_state,
		"cargo_hold_seconds": _mission_scenario_cargo_hold_seconds,
	})).duplicate(true)


func _build_mission_scenario_runtime_gate_context() -> Dictionary:
	var cargo_state: String = _mission_scenario_cargo_state
	var cargo_hold_seconds: float = _mission_scenario_cargo_hold_seconds
	if not _mission_cargo_touchdown_snapshot.is_empty():
		var bridged_cargo_state: String = String(_mission_cargo_touchdown_snapshot.get("cargo_state", "")).strip_edges().to_lower()
		if not bridged_cargo_state.is_empty() and bridged_cargo_state != "unconfigured":
			cargo_state = bridged_cargo_state
		cargo_hold_seconds = maxf(float(_mission_cargo_touchdown_snapshot.get("hold_seconds", cargo_hold_seconds)), 0.0)
	return {
		"now_msec": Time.get_ticks_msec(),
		"objective_status": _get_objective_status(),
		"friendly_team_id": friendly_team_id,
		"enemy_group_fit_counts": _build_enemy_group_fit_counts(),
		"completed_step_ids": _mission_scenario_completed_step_ids.duplicate(true),
		"step_states": _mission_scenario_runtime_step_states.duplicate(true),
		"cargo_state": cargo_state,
		"cargo_hold_seconds": cargo_hold_seconds,
	}


func _build_enemy_group_fit_counts() -> Dictionary:
	# A defeated final defender drops out of live tactics. Retain the group
	# identity once actually observed, so zero is distinct from not yet spawned.
	var result: Dictionary = {}
	for known_group in _known_enemy_gate_groups: result[known_group]=0
	for group_id_variant in _enemy_team_tactics_states_by_group_id.keys():
		var group_id: String = String(group_id_variant).strip_edges()
		if group_id.is_empty():
			continue
		_known_enemy_gate_groups[group_id]=true
		var state: Dictionary = Dictionary(_enemy_team_tactics_states_by_group_id.get(group_id_variant, {}))
		var fit_count: int = 0
		var candidate_units: Array = _get_active_enemy_units()
		for unit_id_variant in Array(state.get("unit_ids", [])):
			var unit = _find_unit_by_id(candidate_units, String(unit_id_variant))
			if _is_unit_fit_for_gate_count(unit):
				fit_count += 1
		result[group_id] = fit_count
	return result


func _is_unit_fit_for_gate_count(unit) -> bool:
	if unit == null:
		return false
	if unit.has_method("is_fit_for_combat"):
		return bool(unit.call("is_fit_for_combat"))
	if unit.has_method("get_vital_state"):
		var vital_state: String = String(unit.call("get_vital_state")).strip_edges().to_lower()
		return vital_state == "fit"
	return true


func _refresh_hotpath_unit_cache_for_tick() -> void:
	_hotpath_unit_cache_active = false
	_hotpath_unit_cache_tick = _current_tick
	_hotpath_friendly_units = _get_units_uncached(friendly_unit_paths)
	_hotpath_enemy_units = _get_active_enemy_units_uncached()
	_hotpath_friendly_combat_units = _filter_combat_candidate_units(_hotpath_friendly_units)
	_hotpath_enemy_combat_units = _filter_combat_candidate_units(_hotpath_enemy_units)
	_hotpath_unit_cache_active = true


func _close_hotpath_unit_cache_scope() -> void:
	_hotpath_unit_cache_active = false


func _get_units(paths: Array[NodePath]) -> Array:
	if _hotpath_unit_cache_active and _node_path_arrays_equal(paths, friendly_unit_paths):
		return _hotpath_friendly_units.duplicate()
	if _hotpath_unit_cache_active and _node_path_arrays_equal(paths, enemy_unit_paths):
		return _hotpath_enemy_units.duplicate()
	return _get_units_uncached(paths)


func _get_units_uncached(paths: Array[NodePath]) -> Array:
	var units: Array = []
	var unit_registry = _get_unit_registry()
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			if unit_registry != null and unit.has_method("get_unit_id") and unit_registry.has_method("has_unit"):
				var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
				if unit_id.is_empty() or not bool(unit_registry.call("has_unit", unit_id)):
					continue
			units.append(unit)

	var team_filter: String = _infer_registry_team_filter_for_paths(paths)
	if not team_filter.is_empty():
		units = _merge_units_by_id(units, _get_registered_units_for_team_filter(team_filter))

	return units


func _get_friendly_combat_units() -> Array:
	if _hotpath_unit_cache_active:
		return _hotpath_friendly_combat_units.duplicate()
	return _filter_combat_candidate_units(_get_units_uncached(friendly_unit_paths))


func _get_enemy_combat_units() -> Array:
	if _hotpath_unit_cache_active:
		return _hotpath_enemy_combat_units.duplicate()
	return _filter_combat_candidate_units(_get_active_enemy_units_uncached())


func _filter_combat_candidate_units(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		if String(unit.call("get_unit_id")).strip_edges().is_empty():
			continue
		if not _can_target_receive_attack(unit):
			continue
		result.append(unit)
	return result


func _infer_registry_team_filter_for_paths(paths: Array[NodePath]) -> String:
	var matches_friendly: bool = _node_path_arrays_equal(paths, friendly_unit_paths)
	var matches_enemy: bool = _node_path_arrays_equal(paths, enemy_unit_paths)
	if matches_friendly and not matches_enemy:
		return friendly_team_id
	if matches_enemy and not matches_friendly:
		return "!%s" % friendly_team_id
	return ""


func _node_path_arrays_equal(left: Array[NodePath], right: Array[NodePath]) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if String(left[index]) != String(right[index]):
			return false
	return true


func _get_registered_units_for_team_filter(team_filter: String) -> Array:
	var registry = _get_unit_registry()
	if registry == null or not registry.has_method("get_all_units"):
		return []

	var filter_text: String = team_filter.strip_edges()
	var wants_enemy: bool = filter_text.begins_with("!")
	var team_id: String = filter_text.substr(1).strip_edges() if wants_enemy else filter_text
	if team_id.is_empty():
		return []

	var result: Array = []
	for unit in Array(registry.call("get_all_units")):
		if unit == null or not (unit is Node2D) or not unit.has_method("get_team_id"):
			continue
		var unit_team_id: String = String(unit.call("get_team_id")).strip_edges()
		if wants_enemy:
			if unit_team_id == team_id:
				continue
		elif unit_team_id != team_id:
			continue
		result.append(unit)

	result.sort_custom(func(a, b): return _get_unit_id_for_diagnostics(a) < _get_unit_id_for_diagnostics(b))
	return result


func _merge_units_by_id(primary_units: Array, supplemental_units: Array) -> Array:
	var result: Array = []
	var seen_unit_ids: Dictionary = {}
	for unit in primary_units:
		var unit_id: String = _get_unit_id_for_diagnostics(unit)
		if unit_id.is_empty() or seen_unit_ids.has(unit_id):
			continue
		result.append(unit)
		seen_unit_ids[unit_id] = true
	for unit in supplemental_units:
		var unit_id: String = _get_unit_id_for_diagnostics(unit)
		if unit_id.is_empty() or seen_unit_ids.has(unit_id):
			continue
		result.append(unit)
		seen_unit_ids[unit_id] = true
	result.sort_custom(func(a, b): return _get_unit_id_for_diagnostics(a) < _get_unit_id_for_diagnostics(b))
	return result


func _get_units_for_presence_audit(paths: Array[NodePath]) -> Array:
	var units: Array = []
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D and unit.has_method("get_unit_id"):
			units.append(unit)
	return units


func _extract_presence_audit_unit_ids(units: Array) -> Array:
	var unit_ids: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _extract_inactive_presence_audit_unit_ids(units: Array, active_unit_ids: Array) -> Array:
	var active_lookup: Dictionary = {}
	for unit_id_variant in active_unit_ids:
		active_lookup[String(unit_id_variant)] = true
	var unit_ids: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty() or active_lookup.has(unit_id):
			continue
		unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _get_enemy_wave_number(method_name: String) -> int:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null or not enemy_wave_controller.has_method(method_name):
		return 0
	return int(enemy_wave_controller.call(method_name))


func _enemy_waves_all_started() -> bool:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("are_all_waves_started"):
		return true
	return bool(enemy_wave_controller.call("are_all_waves_started"))


func _init_fireteam_leadership() -> void:
	_fireteam_original_leads.clear()
	_fireteam_acting_leads.clear()
	_fireteam_members.clear()
	for unit in _get_units(friendly_unit_paths):
		if unit == null or not unit.has_method("get_fireteam_id") or not unit.has_method("get_unit_id"):
			continue

		var ft_id: String = String(unit.call("get_fireteam_id"))
		if ft_id.is_empty():
			continue

		var uid: String = String(unit.call("get_unit_id"))
		if not _fireteam_members.has(ft_id):
			_fireteam_members[ft_id] = []

		_fireteam_members[ft_id].append(uid)
		if unit.has_method("get") and unit.get("is_fireteam_lead"):
			_fireteam_original_leads[ft_id] = uid
			_fireteam_acting_leads[ft_id] = uid

	_apply_all_leadership_bonuses()


func _update_fireteam_leadership() -> void:
	var changed: bool = false
	for ft_id in _fireteam_original_leads.keys():
		var original_lead_id: String = String(_fireteam_original_leads[ft_id])
		var current_acting_id: String = String(_fireteam_acting_leads.get(ft_id, ""))
		var original_lead = _resolve_unit_by_id(original_lead_id)
		var original_is_fit: bool = original_lead != null and original_lead.has_method("get_vital_state") and String(original_lead.call("get_vital_state")) == "fit"

		if original_is_fit:
			if current_acting_id != original_lead_id:
				_fireteam_acting_leads[ft_id] = original_lead_id
				changed = true
				_show_leadership_event(original_lead_id, "LEAD BACK")
		else:
			if current_acting_id == original_lead_id or not _is_acting_lead_fit(current_acting_id):
				var successor_id: String = _find_best_successor(ft_id, original_lead_id)
				if successor_id != current_acting_id:
					_fireteam_acting_leads[ft_id] = successor_id
					changed = true
					if not successor_id.is_empty():
						_show_leadership_event(successor_id, "ACTING LEAD")

	if changed:
		_apply_all_leadership_bonuses()


func _is_acting_lead_fit(uid: String) -> bool:
	if uid.is_empty():
		return false

	var unit = _resolve_unit_by_id(uid)
	if unit == null or not unit.has_method("get_vital_state"):
		return false

	return String(unit.call("get_vital_state")) == "fit"


func _find_best_successor(ft_id: String, exclude_id: String) -> String:
	var best_id: String = ""
	var best_leadership: float = -1.0
	var best_toughness: float = -1.0
	var members: Array = _fireteam_members.get(ft_id, [])
	for uid in members:
		if String(uid) == exclude_id:
			continue

		var unit = _resolve_unit_by_id(String(uid))
		if unit == null or not unit.has_method("get_vital_state"):
			continue

		if String(unit.call("get_vital_state")) != "fit":
			continue

		var leadership: float = 0.0
		if unit.has_method("get_leadership_skill"):
			leadership = float(unit.call("get_leadership_skill"))
		var toughness: float = 0.0
		if unit.has_method("get_toughness_skill"):
			toughness = float(unit.call("get_toughness_skill"))

		if leadership > best_leadership:
			best_leadership = leadership
			best_toughness = toughness
			best_id = String(uid)
			continue
		if is_equal_approx(leadership, best_leadership) and toughness > best_toughness:
			best_toughness = toughness
			best_id = String(uid)

	return best_id


func _try_enqueue_medic_support(simulation_root: Node) -> void:
	var reserved_target_ids: Dictionary = {}
	_try_enqueue_medic_support_for_units(simulation_root, _get_units(friendly_unit_paths), _get_units(friendly_unit_paths), reserved_target_ids)
	_try_enqueue_medic_support_for_units(simulation_root, _get_active_enemy_units(), _get_active_enemy_units(), reserved_target_ids)


func _try_enqueue_medic_support_for_units(simulation_root: Node, medics: Array, allies: Array, reserved_target_ids: Dictionary) -> void:
	var actions: Array = Array(
		MEDIC_SUPPORT_RESOLVER_SCRIPT.call(
			"build_support_actions",
			medics,
			allies,
			reserved_target_ids,
			_medic_support_cooldown,
			_medic_support_move_ready_tick,
			_get_terrain_registry(),
			_current_tick,
			_build_medic_support_config()
		)
	)
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = Dictionary(action_variant)
		var medic = action.get("medic", null)
		var target = action.get("target", null)
		var medic_id: String = String(action.get("medic_id", "")).strip_edges()
		var target_id: String = String(action.get("target_id", "")).strip_edges()
		if String(action.get("action_type", "")) == "heal":
			simulation_root.call(
				"enqueue_effect",
				{
					"effect_type": "heal",
					"priority": MEDIC_SUPPORT_PRIORITY,
					"unit_id": target_id,
					"healer_unit_id": medic_id,
					"healer_team_id": String(medic.call("get_team_id")) if medic != null and medic.has_method("get_team_id") else "",
					"amount": MEDIC_SUPPORT_HEAL_AMOUNT,
					"support_resource": "medictool",
				}
			)
			_medic_support_cooldown[medic_id] = MEDIC_SUPPORT_COOLDOWN_TICKS
			_set_event_text("%s PATCH %s" % [medic_id, target_id])
			if medic != null and medic.has_method("show_event_text"):
				medic.call("show_event_text", "PATCH", MEDIC_EVENT_COLOR, 1.2)
			continue
		if String(action.get("action_type", "")) != "move":
			continue
		_enqueue_medic_move_action(simulation_root, action)


func _build_medic_support_config() -> Dictionary:
	return {
		"tile_range": MEDIC_SUPPORT_TILE_RANGE,
		"move_max_tile_distance": MEDIC_SUPPORT_MOVE_MAX_TILE_DISTANCE,
		"range_fallback_world": MEDIC_SUPPORT_RANGE_FALLBACK_WORLD,
		"move_max_distance_fallback_world": MEDIC_SUPPORT_MOVE_MAX_DISTANCE_FALLBACK_WORLD,
		"approach_standoff": MEDIC_SUPPORT_APPROACH_STANDOFF,
		"wounded_threshold": MEDIC_SUPPORT_WOUNDED_THRESHOLD,
		"remote_wounded_threshold": MEDIC_SUPPORT_REMOTE_WOUNDED_THRESHOLD,
	}


func _can_medic_support(unit) -> bool:
	return bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("can_medic_support", unit, _medic_support_cooldown))


func _is_medic_unit(unit) -> bool:
	return bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("is_medic_unit", unit))


func _pick_medic_target(medic, allies: Array, reserved_target_ids: Dictionary):
	return MEDIC_SUPPORT_RESOLVER_SCRIPT.call("pick_medic_target", medic, allies, reserved_target_ids, _get_terrain_registry(), _build_medic_support_config())

func _pick_medic_move_target(medic, allies: Array, reserved_target_ids: Dictionary):
	return MEDIC_SUPPORT_RESOLVER_SCRIPT.call("pick_medic_move_target", medic, allies, reserved_target_ids, _get_terrain_registry(), _build_medic_support_config())


func _pick_best_medic_target(medic, allies: Array, reserved_target_ids: Dictionary, require_in_range: bool):
	return MEDIC_SUPPORT_RESOLVER_SCRIPT.call("pick_best_medic_target", medic, allies, reserved_target_ids, require_in_range, _get_terrain_registry(), _build_medic_support_config())


func _score_medic_target(medic, ally, reserved_target_ids: Dictionary, require_in_range: bool) -> float:
	return float(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("score_medic_target", medic, ally, reserved_target_ids, require_in_range, _get_terrain_registry(), _build_medic_support_config()))


func _is_valid_medic_target(medic, ally, reserved_target_ids: Dictionary, require_in_range: bool = true) -> bool:
	return bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("is_valid_medic_target", medic, ally, reserved_target_ids, require_in_range, _get_terrain_registry(), _build_medic_support_config()))


func _has_required_medic_tool(unit) -> bool:
	return bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("has_required_medic_tool", unit))


func _try_enqueue_medic_move(simulation_root: Node, medic, target) -> bool:
	if simulation_root == null or medic == null or target == null:
		return false
	if not (medic is Node2D) or not (target is Node2D):
		return false
	if not medic.has_method("get_unit_id") or not target.has_method("get_unit_id"):
		return false
	var medic_id: String = String(medic.call("get_unit_id")).strip_edges()
	var target_id: String = String(target.call("get_unit_id")).strip_edges()
	if medic_id.is_empty() or target_id.is_empty():
		return false
	var distance: float = (medic as Node2D).global_position.distance_to((target as Node2D).global_position)
	if _is_within_medic_support_range(medic, target, distance):
		return false
	if int(_medic_support_move_ready_tick.get(medic_id, -1)) > _current_tick:
		return false
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": MEDIC_SUPPORT_MOVE_PRIORITY,
			"unit_id": medic_id,
			"target_position": _build_medic_approach_position(medic, target),
			"move_speed_factor": MEDIC_SUPPORT_MOVE_SPEED_FACTOR,
			"requeue_until_target": false,
		}
	)
	_medic_support_move_ready_tick[medic_id] = _current_tick + MEDIC_SUPPORT_MOVE_REISSUE_TICKS
	if medic.has_method("show_event_text"):
		medic.call("show_event_text", "MEDIC MOVE", MEDIC_EVENT_COLOR, 1.0)
	return true


func _enqueue_medic_move_action(simulation_root: Node, action: Dictionary) -> bool:
	var medic = action.get("medic", null)
	var medic_id: String = String(action.get("medic_id", "")).strip_edges()
	var target_id: String = String(action.get("target_id", "")).strip_edges()
	if simulation_root == null or medic == null or medic_id.is_empty() or target_id.is_empty():
		return false
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": MEDIC_SUPPORT_MOVE_PRIORITY,
			"unit_id": medic_id,
			"target_position": Vector2(action.get("target_position", Vector2.ZERO)),
			"move_speed_factor": MEDIC_SUPPORT_MOVE_SPEED_FACTOR,
			"requeue_until_target": false,
		}
	)
	_medic_support_move_ready_tick[medic_id] = _current_tick + MEDIC_SUPPORT_MOVE_REISSUE_TICKS
	if medic.has_method("show_event_text"):
		medic.call("show_event_text", "MEDIC MOVE", MEDIC_EVENT_COLOR, 1.0)
	return true


func _build_medic_approach_position(medic, target) -> Vector2:
	return Vector2(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("build_medic_approach_position", medic, target, MEDIC_SUPPORT_APPROACH_STANDOFF, _get_terrain_registry(), _build_medic_support_config()))


func _is_within_medic_support_range(medic, target, fallback_distance: float = -1.0) -> bool:
	return bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("is_within_medic_support_range", medic, target, _get_terrain_registry(), fallback_distance, _build_medic_support_config()))


func _is_within_medic_move_range(medic, target, fallback_distance: float = -1.0) -> bool:
	return bool(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("is_within_medic_move_range", medic, target, _get_terrain_registry(), fallback_distance, _build_medic_support_config()))


func _get_medic_tile_distance(medic, target) -> int:
	return int(MEDIC_SUPPORT_RESOLVER_SCRIPT.call("get_medic_tile_distance", medic, target, _get_terrain_registry()))


func _apply_all_leadership_bonuses() -> void:
	for unit in _get_units(friendly_unit_paths):
		if unit == null or not unit.has_method("clear_leadership_bonus"):
			continue

		unit.call("clear_leadership_bonus")

	for ft_id in _fireteam_acting_leads.keys():
		var acting_lead_id: String = String(_fireteam_acting_leads[ft_id])
		if acting_lead_id.is_empty():
			continue

		var lead_unit = _resolve_unit_by_id(acting_lead_id)
		if lead_unit == null or not lead_unit.has_method("get_vital_state"):
			continue

		if String(lead_unit.call("get_vital_state")) != "fit":
			continue

		var leadership_value: float = 0.0
		if lead_unit.has_method("get_leadership_skill"):
			leadership_value = float(lead_unit.call("get_leadership_skill"))

		var bonus: float = leadership_value * LEADERSHIP_BONUS_FACTOR
		if bonus <= 0.0:
			continue

		var members: Array = _fireteam_members.get(ft_id, [])
		for uid in members:
			if String(uid) == acting_lead_id:
				continue

			var member = _resolve_unit_by_id(String(uid))
			if member == null or not member.has_method("apply_leadership_bonus"):
				continue

			member.call("apply_leadership_bonus", bonus)


func _show_leadership_event(uid: String, text: String) -> void:
	var unit = _resolve_unit_by_id(uid)
	if unit != null and unit.has_method("show_event_text"):
		unit.call("show_event_text", text, LEADERSHIP_EVENT_COLOR, EVENT_DEFAULT_DURATION)

	_set_event_text("%s %s" % [uid, text])


func _pick_target_for_attacker(attacker, target_paths: Array[NodePath]):
	return COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("pick_target_from_units", attacker, _get_units(target_paths), _build_fire_decision_context())


func _can_enemy_attack(unit) -> bool:
	return bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_enemy_attack", unit))


func _can_unit_attack(unit) -> bool:
	return bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_unit_attack", unit, _build_fire_decision_context()))


func _check_discipline_break(unit) -> bool:
	if unit == null:
		return false
	var unit_id: String = ""
	if unit.has_method("get_unit_id"):
		unit_id = String(unit.call("get_unit_id"))
	if unit_id.is_empty():
		return false

	var cooldown_remaining: int = _discipline_break_cooldown.get(unit_id, 0) as int
	if cooldown_remaining > 0:
		return false

	var unit_discipline: float = 0.5
	if unit.has_method("get_discipline"):
		unit_discipline = clampf(float(unit.call("get_discipline")), 0.0, 1.0)

	var break_chance: float = DISCIPLINE_BREAK_BASE_CHANCE * (1.0 - unit_discipline)
	if break_chance <= 0.0:
		return false

	if randf() >= break_chance:
		return false

	_discipline_break_cooldown[unit_id] = DISCIPLINE_BREAK_COOLDOWN_TICKS
	var event_msg: String = "%s bricht Feuerstopp!" % unit_id
	_set_event_text(event_msg)
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "FEUERSTOPP GEBROCHEN!", DISCIPLINE_BREAK_EVENT_COLOR, 1.6)
	_broadcast_remote_event(event_msg, unit_id, DISCIPLINE_BREAK_EVENT_COLOR, 1.6, "FEUERSTOPP GEBROCHEN!")
	return true


func _record_return_fire_window_if_needed(attacker, target) -> void:
	if attacker == null or target == null:
		return
	if _get_unit_team_id_for_diagnostics(attacker) == friendly_team_id:
		return
	if _get_unit_team_id_for_diagnostics(target) != friendly_team_id:
		return
	var fireteam_id: String = _get_unit_fireteam_id(target)
	if fireteam_id.is_empty():
		return
	_recent_incoming_fire_tick_by_fireteam[fireteam_id] = _current_tick


func _can_unit_return_fire(unit) -> bool:
	var fireteam_id: String = _get_unit_fireteam_id(unit)
	if fireteam_id.is_empty() or not _recent_incoming_fire_tick_by_fireteam.has(fireteam_id):
		return false
	var last_incoming_tick: int = int(_recent_incoming_fire_tick_by_fireteam.get(fireteam_id, -RETURN_FIRE_WINDOW_TICKS - 1))
	return _current_tick - last_incoming_tick <= RETURN_FIRE_WINDOW_TICKS


func _get_unit_fire_rule_for_diagnostics(unit) -> String:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return ""
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("get"):
		return ""
	return String(command.get("fire_rule")).strip_edges().to_lower()


func _get_detection_delay_ticks(unit) -> int:
	var unit_awareness: float = 0.5
	if unit != null and unit.has_method("get_awareness"):
		unit_awareness = clampf(float(unit.call("get_awareness")), 0.0, 1.0)

	var base_delay: int = int(round((1.0 - unit_awareness) * float(MAX_DETECTION_DELAY_TICKS)))
	return maxi(base_delay + _get_contact_initiative_delay_delta_ticks(unit) + _get_aim_readiness_delay_delta_ticks(unit), 0)


func _get_contact_initiative_delay_delta_ticks(unit) -> int:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return 0
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("get"):
		return 0
	var raw_seconds: Variant = command.get("contact_initiative_seconds")
	if typeof(raw_seconds) != TYPE_INT and typeof(raw_seconds) != TYPE_FLOAT:
		return 0
	return int(round((float(raw_seconds) / CONTACT_INITIATIVE_BASELINE_SECONDS) * float(MAX_DETECTION_DELAY_TICKS)))


func _get_aim_readiness_delay_delta_ticks(unit) -> int:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return 0
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("get"):
		return 0
	var raw_readiness: Variant = command.get("aim_readiness_percent")
	if typeof(raw_readiness) != TYPE_INT and typeof(raw_readiness) != TYPE_FLOAT:
		return 0
	var readiness: float = clampf(float(raw_readiness), 0.0, 100.0)
	if readiness <= 0.0:
		return 0
	var normalized_delta: float = clampf((AIM_READINESS_BASELINE_PERCENT - readiness) / AIM_READINESS_BASELINE_PERCENT, -1.0, 1.0)
	return int(round(normalized_delta * float(AIM_READINESS_MAX_DELAY_DELTA_TICKS)))


func _make_detection_key(attacker_id: String, target_id: String) -> String:
	return "%s:%s" % [attacker_id, target_id]


func _is_detection_complete(attacker_id: String, target_id: String) -> bool:
	if get_hex_sight_adapter().is_active():
		return bool(_get_hex_detection_state().read_pair(attacker_id,target_id,_current_tick).get("detection_complete",false))
	var key: String = _make_detection_key(attacker_id, target_id)
	return _detection_progress.has(key) and int(_detection_progress[key]) <= 0


func _start_or_continue_detection(attacker, attacker_id: String, target_id: String) -> void:
	if get_hex_sight_adapter().is_active():
		var target = _resolve_unit_by_id(target_id)
		if not _has_valid_los(attacker,target):
			return
		var episode: Dictionary = _get_hex_detection_state().observe_pair(attacker_id,target_id,true,_current_tick,_get_detection_delay_ticks(attacker))
		if bool(episode.get("episode_started",false)) and not bool(episode.get("detection_complete",false)) and attacker != null and attacker.has_method("show_event_text"):
			attacker.call("show_event_text","DETECTING...",DETECTION_EVENT_COLOR,0.8)
		return
	var key: String = _make_detection_key(attacker_id, target_id)
	if _detection_progress.has(key):
		return

	var delay: int = _get_detection_delay_ticks(attacker)
	_detection_progress[key] = delay
	if delay > 0 and attacker != null and attacker.has_method("show_event_text"):
		attacker.call("show_event_text", "DETECTING...", DETECTION_EVENT_COLOR, 0.8)


func _advance_detection_timers() -> void:
	if get_hex_sight_adapter().is_active():
		var state = _get_hex_detection_state()
		for episode in state.build_episode_snapshot(_current_tick):
			if not _has_valid_los(_resolve_unit_by_id(episode.attacker_unit_id),_resolve_unit_by_id(episode.target_unit_id)):
				state.observe_pair(episode.attacker_unit_id,episode.target_unit_id,false,_current_tick,0)
		return
	var keys_to_remove: Array = []
	for key in _detection_progress.keys():
		var remaining: int = int(_detection_progress[key])
		if remaining > 0:
			_detection_progress[key] = remaining - 1
		else:
			# Already detected, keep entry
			pass

	# Prune pairs that lost LOS
	for key in _detection_progress.keys():
		var parts: PackedStringArray = String(key).split(":")
		if parts.size() != 2:
			keys_to_remove.append(key)
			continue

		var attacker = _resolve_unit_by_id(parts[0])
		var target = _resolve_unit_by_id(parts[1])
		if attacker == null or target == null:
			keys_to_remove.append(key)
			continue

		if not _has_valid_los(attacker, target):
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_detection_progress.erase(key)


func _advance_discipline_cooldowns() -> void:
	var keys_to_remove: Array = []
	for key in _discipline_break_cooldown.keys():
		var remaining: int = int(_discipline_break_cooldown[key])
		if remaining > 1:
			_discipline_break_cooldown[key] = remaining - 1
		else:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_discipline_break_cooldown.erase(key)


func get_discipline_break_cooldown() -> Dictionary:
	return _discipline_break_cooldown


func _advance_return_fire_windows() -> void:
	var keys_to_remove: Array = []
	for key in _recent_incoming_fire_tick_by_fireteam.keys():
		var last_tick: int = int(_recent_incoming_fire_tick_by_fireteam[key])
		if _current_tick - last_tick > RETURN_FIRE_WINDOW_TICKS:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_recent_incoming_fire_tick_by_fireteam.erase(key)


func get_return_fire_window_snapshot() -> Dictionary:
	return _recent_incoming_fire_tick_by_fireteam.duplicate(true)


func _advance_misidentification_cooldowns() -> void:
	var keys_to_remove: Array = []
	for key in _misidentification_cooldown.keys():
		var remaining: int = int(_misidentification_cooldown[key])
		if remaining > 1:
			_misidentification_cooldown[key] = remaining - 1
		else:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_misidentification_cooldown.erase(key)


func get_misidentification_cooldown() -> Dictionary:
	return _misidentification_cooldown


func get_medic_support_cooldown() -> Dictionary:
	return _medic_support_cooldown.duplicate(true)


func _advance_medic_support_cooldowns() -> void:
	var keys_to_remove: Array = []
	for key in _medic_support_cooldown.keys():
		var remaining: int = int(_medic_support_cooldown[key])
		if remaining > 1:
			_medic_support_cooldown[key] = remaining - 1
		else:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_medic_support_cooldown.erase(key)


func _check_misidentification(attacker, attacker_id: String) -> Dictionary:
	if attacker == null or attacker_id.is_empty():
		return {}

	var cooldown_remaining: int = _misidentification_cooldown.get(attacker_id, 0) as int
	if cooldown_remaining > 0:
		return {}

	# Only friendlies can misidentify (not enemies)
	var attacker_team: String = ""
	if attacker.has_method("get_team_id"):
		attacker_team = String(attacker.call("get_team_id"))
	if attacker_team != friendly_team_id:
		return {}

	var unit_recognition: float = 0.5
	if attacker.has_method("get_recognition"):
		unit_recognition = clampf(float(attacker.call("get_recognition")), 0.0, 1.0)

	var misid_chance: float = MISIDENTIFICATION_BASE_CHANCE * (1.0 - unit_recognition)
	if misid_chance <= 0.0:
		return {}

	if randf() >= misid_chance:
		return {}

	# Find nearest friendly unit (not self) as misidentified target
	var nearest_friendly = null
	var nearest_dist: float = INF
	for friendly in _get_friendly_combat_units():
		if friendly == attacker:
			continue
		if not friendly.has_method("get_vital_state"):
			continue
		if String(friendly.call("get_vital_state")) != "fit":
			continue
		var dist: float = attacker.global_position.distance_to(friendly.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_friendly = friendly

	if nearest_friendly == null:
		return {}

	_misidentification_cooldown[attacker_id] = MISIDENTIFICATION_COOLDOWN_TICKS
	var friendly_id: String = String(nearest_friendly.call("get_unit_id"))
	return {
		"target": nearest_friendly,
		"target_id": friendly_id,
	}


func _has_valid_los(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	if not attacker.has_method("get_vital_state") or String(attacker.call("get_vital_state")) != "fit":
		return false

	if not target.has_method("get_vital_state") or String(target.call("get_vital_state")) != "fit":
		return false

	var los_range: float = _get_effective_range(target)
	if _uses_weapon_range_for_contact_detection(attacker):
		los_range = maxf(los_range, _get_weapon_attack_range(attacker, target))
	var logical: Dictionary = _query_current_visibility(attacker,target,los_range)
	if bool(logical.get("handled",false)):
		return bool(logical.get("visible",false))
	return bool(_get_combat_visibility_system().call("has_line_of_sight_between_nodes", attacker, target, los_range, _get_terrain_registry()))


func _uses_weapon_range_for_contact_detection(attacker) -> bool:
	if attacker == null:
		return false
	if attacker.has_method("get_source_command_type") and String(attacker.call("get_source_command_type")).strip_edges().to_lower() == "engage":
		return true
	if attacker.has_method("get_current_unit_command"):
		var command = attacker.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			return String(command.get("source_command_type")).strip_edges().to_lower() == "engage"
	return false


func _update_contact_tracking() -> void:
	if _contact_tracker == null:
		return
	var contact_observations: Array = []
	var active_enemies: Array = _get_enemy_combat_units()
	var active_friendlies: Array = _get_friendly_combat_units()
	_last_contact_tracking_scan_pair_count = 0
	_last_contact_tracking_los_check_count = 0
	_last_contact_tracking_los_cache_hit_count = 0
	_fire_candidate_target_ids_by_attacker_id.clear()
	_fire_candidate_index_tick = _current_tick
	_fire_candidate_index_pair_count = 0
	var cache_hit_count_before: int = int(_get_combat_visibility_cache_audit().get("cache_hit_count", 0))
	for friendly in active_friendlies:
		if friendly == null or not friendly.has_method("get_fireteam_id") or not friendly.has_method("get_unit_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		var attacker_id: String = String(friendly.call("get_unit_id")).strip_edges()
		if fireteam_id.is_empty() or attacker_id.is_empty():
			continue
		_fire_candidate_target_ids_by_attacker_id[attacker_id] = PackedStringArray()
		for enemy in active_enemies:
			_last_contact_tracking_scan_pair_count += 1
			_last_contact_tracking_los_check_count += 1
			if not _has_valid_los(friendly, enemy):
				continue
			var enemy_unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
			if enemy_unit_id.is_empty():
				continue
			var target_ids := PackedStringArray(_fire_candidate_target_ids_by_attacker_id.get(attacker_id, PackedStringArray()))
			if not target_ids.has(enemy_unit_id):
				target_ids.append(enemy_unit_id)
				_fire_candidate_target_ids_by_attacker_id[attacker_id] = target_ids
				_fire_candidate_index_pair_count += 1
			_start_or_continue_detection(friendly, attacker_id, enemy_unit_id)
			contact_observations.append({
				"fireteam_id": fireteam_id,
				"unit_id": enemy_unit_id,
				"team_id": String(enemy.call("get_team_id")) if enemy.has_method("get_team_id") else "",
				"enemy_type": _get_contact_enemy_type(enemy),
				"last_known_position": _get_contact_observation_position(enemy),
				"detection_complete": _is_detection_complete(attacker_id, enemy_unit_id),
			})
	for attacker_id_variant in _fire_candidate_target_ids_by_attacker_id.keys():
		var sorted_target_ids := PackedStringArray(_fire_candidate_target_ids_by_attacker_id[attacker_id_variant])
		sorted_target_ids.sort()
		_fire_candidate_target_ids_by_attacker_id[attacker_id_variant] = sorted_target_ids
	_last_contact_tracking_los_cache_hit_count = maxi(0, int(_get_combat_visibility_cache_audit().get("cache_hit_count", 0)) - cache_hit_count_before)
	var did_change: bool = bool(
		_contact_tracker.call(
			"update",
			_current_tick,
			contact_observations,
			_get_known_friendly_fireteam_ids(),
			_get_fireteam_leadership_snapshot()
		)
	)
	if not did_change:
		return
	var tactical_controller = _get_tactical_controller()
	if tactical_controller != null and tactical_controller.has_method("refresh_contact_overlay"):
		tactical_controller.call("refresh_contact_overlay")

func get_fire_candidate_index_debug_snapshot() -> Dictionary:
	var pairs_by_attacker_id: Dictionary = {}
	for attacker_id_variant in _fire_candidate_target_ids_by_attacker_id.keys():
		var attacker_id: String = String(attacker_id_variant)
		pairs_by_attacker_id[attacker_id] = PackedStringArray(_fire_candidate_target_ids_by_attacker_id.get(attacker_id_variant, PackedStringArray()))
	return {"tick": _fire_candidate_index_tick, "candidate_attacker_count": pairs_by_attacker_id.size(), "candidate_pair_count": _fire_candidate_index_pair_count, "pairs_by_attacker_id": pairs_by_attacker_id, "derived_only": true, "read_only": true, "snapshot_serialized": false}



func _advance_flank_vulnerability_state() -> void:
	if not flank_vulnerability_enabled or _flank_vulnerability_resolver == null:
		return
	var did_change: bool = bool(_flank_vulnerability_resolver.call("advance", _current_tick))
	if not did_change:
		return
	var tactical_controller = _get_tactical_controller()
	if tactical_controller != null and tactical_controller.has_method("refresh_flank_vulnerability_state"):
		tactical_controller.call("refresh_flank_vulnerability_state")


func get_detection_progress() -> Dictionary:
	if get_hex_sight_adapter().is_active():
		var result: Dictionary = {}
		for episode in _get_hex_detection_state().build_episode_snapshot(_current_tick):
			result[JSON.stringify([episode.attacker_unit_id,episode.target_unit_id])] = episode.ticks_remaining
		return result
	return _detection_progress.duplicate(true)


func _get_effective_range(target) -> float:
	var target_stealth: float = 0.0
	if target != null and target.has_method("get_stealth"):
		target_stealth = clampf(float(target.call("get_stealth")), 0.0, 1.0)

	return contact_range * (1.0 - target_stealth * STEALTH_RANGE_REDUCTION_FACTOR)


func _get_weapon_attack_range(attacker, _target = null) -> float:
	var weapon_id: String = _get_unit_active_weapon_id(attacker)
	if weapon_id.is_empty():
		return 0.0
	return WEAPON_DATA_SCRIPT.call("get_effective_world_range", weapon_id, _get_terrain_registry())


func _is_target_attackable(attacker, target) -> bool:
	return bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", attacker, target, _build_fire_decision_context()))


func _can_target_receive_attack(unit) -> bool:
	return bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_target_receive_attack", unit))


func _is_engage_ready(unit) -> bool:
	return bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_engage_ready", unit))


func _update_status_label(state_name: String) -> void:
	var status_label = get_node_or_null(status_label_path)
	if _readability_presenter == null:
		return
	_readability_presenter.call("update_status_label", status_label, state_name, _build_readability_status_context(), _overlays_visible, preview_mode)


func _build_readability_status_context() -> Dictionary:
	return {
		"win_condition": win_condition,
		"combat_finished": _combat_finished,
		"winning_team_id": _winning_team_id,
		"enemy_fit_count": _count_fit_enemy_units(),
		"friendly_fit_count": _count_fit_units(friendly_unit_paths),
		"duration_seconds": _get_duration_seconds(),
		"objective_status_text": _build_objective_status_text(),
		"wave_status_text": _build_wave_status_text(),
		"show_hold_timer": win_condition == WIN_CONDITION_OBJECTIVE_DEFENSE and _objective_owned_since_msec >= 0 and not _combat_finished,
		"objective_defense_elapsed_seconds": _get_objective_defense_elapsed_seconds(),
		"objective_defense_hold_seconds": objective_defense_hold_seconds,
		"mission_scenario_runtime_gates": get_mission_scenario_runtime_gate_snapshot(),
		"attack_readiness_text": _build_attack_readiness_text(),
		"last_event_text": _last_event_text,
		"last_contact": _last_contact.duplicate(true),
	}


func _build_team_states(paths: Array[NodePath]) -> Array:
	var team_states: Array = []
	for unit in _get_units(paths):
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		var health_points: int = 0
		if unit.has_method("get_health"):
			health_points = int(unit.call("get_health"))

		var vital_state: String = ""
		if unit.has_method("get_vital_state"):
			vital_state = String(unit.call("get_vital_state"))

		var display_name: String = String(unit.call("get_display_name")) if unit.has_method("get_display_name") else String(unit.call("get_unit_id"))
		team_states.append(
			{
				"unit_id": String(unit.call("get_unit_id")),
				"display_name": display_name,
				"vital_state": vital_state,
				"health_points": health_points,
			}
		)

	return team_states


func _describe_friendly_unit(unit) -> String:
	if unit == null:
		return "- missing"

	var runtime_status = null
	var status_name: String = ""
	if unit.has_method("get_runtime_status"):
		runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			status_name = String(runtime_status.get("status"))

	var unit_command = null
	var command_type: String = ""
	if unit.has_method("get_current_unit_command"):
		unit_command = unit.call("get_current_unit_command")
		if unit_command != null and unit_command.has_method("get"):
			command_type = String(unit_command.get("command_type"))

	return "%s %s %s %s c%.2f a%.2f" % [
		String(unit.call("get_unit_id")),
		status_name,
		command_type,
		String(unit.call("get_fire_status")),
		float(unit.call("get_cover_score")),
		float(unit.call("get_attack_bonus")),
	]


func _describe_enemy_unit(unit) -> String:
	if unit == null:
		return "- missing"

	var health: int = 0
	if unit.has_method("get_health"):
		health = int(unit.call("get_health"))

	return "%s %s hp=%d" % [
		String(unit.call("get_unit_id")),
		String(unit.call("get_vital_state")),
		health,
	]


func _get_unit_active_weapon_id(unit) -> String:
	return String(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("get_unit_active_weapon_id", unit))


func _get_contact_enemy_type(enemy) -> String:
	if enemy == null:
		return "unknown"
	var weapon_id: String = _get_unit_active_weapon_id(enemy).strip_edges().to_lower()
	if weapon_id == "sniper" or weapon_id == "rocket_launcher" or weapon_id == "rail_gun":
		return weapon_id
	if enemy.has_method("get_role_id"):
		var role_id: String = String(enemy.call("get_role_id")).strip_edges().to_lower()
		if not role_id.is_empty():
			return role_id
	if not weapon_id.is_empty():
		return weapon_id
	return "unknown"


func _find_first_contact_pair() -> Dictionary:
	var friendly_units: Array = _prioritize_standard_attack_fireteam_fairness(_get_friendly_combat_units())
	var cache = get_node_or_null(combat_visibility_cache_path)
	if combat_tick_budget_debug_enabled and cache != null and cache.has_method("set_debug_profile_scope_active"):
		cache.call("set_debug_profile_scope_active", true)
	var result := Dictionary(
		COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call(
			"find_first_contact_pair",
			_build_fire_decision_context(
				{
					"friendly_units": friendly_units,
					"enemy_units": _get_enemy_combat_units(),
				}
			)
		)
	).duplicate(true)
	if cache != null and cache.has_method("set_debug_profile_scope_active"):
		cache.call("set_debug_profile_scope_active", false)
	return result


func _prioritize_standard_attack_fireteam_fairness(units: Array) -> Array:
	if _last_standard_attacker_fireteam_id.is_empty():
		return units
	var prioritized: Array = []
	var deferred: Array = []
	for unit in units:
		if _get_unit_fireteam_id(unit) == _last_standard_attacker_fireteam_id:
			deferred.append(unit)
		else:
			prioritized.append(unit)
	prioritized.append_array(deferred)
	return prioritized


func resolve_flank_attack(attacker, target) -> Dictionary:
	if not flank_vulnerability_enabled or attacker == null or target == null:
		return {}
	if target.has_method("get_team_id") and String(target.call("get_team_id")) != friendly_team_id:
		var enemy_security_state: Dictionary = get_enemy_security_state_for_unit(String(target.call("get_unit_id")) if target.has_method("get_unit_id") else "")
		var enemy_group_id: String = String(enemy_security_state.get("security_group_id", "")).strip_edges().to_lower()
		if enemy_group_id.is_empty():
			return {}
		return resolve_flank_attack_with_state(enemy_group_id, attacker, target, enemy_security_state)
	if not target.has_method("get_fireteam_id"):
		return {}
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("get_fireteam_security_state"):
		return {}
	var defending_fireteam_id: String = String(target.call("get_fireteam_id")).strip_edges().to_lower()
	if defending_fireteam_id.is_empty():
		return {}
	var security_state: Dictionary = Dictionary(tactical_controller.call("get_fireteam_security_state", defending_fireteam_id)).duplicate(true)
	return resolve_flank_attack_with_state(defending_fireteam_id, attacker, target, security_state)


func resolve_flank_attack_with_state(fireteam_id: String, attacker, target, security_state: Dictionary) -> Dictionary:
	if not flank_vulnerability_enabled or _flank_vulnerability_resolver == null or fireteam_id.strip_edges().is_empty():
		return {}
	_flank_vulnerability_resolver.configure_hex_sight_adapter(get_hex_sight_adapter())
	var result: Dictionary = Dictionary(_flank_vulnerability_resolver.call("resolve_attack", fireteam_id, attacker, target, security_state, _current_tick)).duplicate(true)
	if result.is_empty():
		return {}
	var tactical_controller = _get_tactical_controller()
	if tactical_controller != null and tactical_controller.has_method("refresh_flank_vulnerability_state"):
		tactical_controller.call("refresh_flank_vulnerability_state")
	return result


func build_cover_effectiveness_readout(attacker_unit_id: String, target_unit_id: String, contact_state: String = "") -> Dictionary:
	var attacker = _resolve_unit_by_id(attacker_unit_id.strip_edges())
	var target = _resolve_unit_by_id(target_unit_id.strip_edges())
	return build_cover_effectiveness_readout_for_units(attacker, target, contact_state)


func build_cover_effectiveness_readout_for_units(attacker, target, contact_state: String = "") -> Dictionary:
	var normalized_contact_state: String = contact_state.strip_edges().to_lower()
	return Dictionary(
		COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call(
			"build_cover_effectiveness_readout",
			attacker,
			target,
			_build_fire_decision_context(
				{
					"contact_state": normalized_contact_state,
					"respect_contact_state": not normalized_contact_state.is_empty(),
					"resolve_flank_attack_preview": Callable(self, "resolve_flank_attack_preview"),
				}
			)
		)
	).duplicate(true)


func build_cover_effectiveness_readout_for_contact(fireteam_id: String, target_unit_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var normalized_target_id: String = target_unit_id.strip_edges()
	var contact_state: Dictionary = _get_fireteam_contact_state(normalized_fireteam_id, normalized_target_id)
	var attacker = _resolve_fireteam_readout_attacker(normalized_fireteam_id)
	var target = _resolve_unit_by_id(normalized_target_id)
	var readout: Dictionary = build_cover_effectiveness_readout_for_units(attacker, target, String(contact_state.get("detection_state", "")))
	readout["fireteam_id"] = normalized_fireteam_id
	readout["contact_unit_id"] = normalized_target_id
	return readout


func resolve_flank_attack_preview(attacker, target) -> Dictionary:
	if not flank_vulnerability_enabled or attacker == null or target == null or _flank_vulnerability_resolver == null:
		return {}
	if target.has_method("get_team_id") and String(target.call("get_team_id")) != friendly_team_id:
		var enemy_security_state: Dictionary = get_enemy_security_state_for_unit(String(target.call("get_unit_id")) if target.has_method("get_unit_id") else "")
		var enemy_group_id: String = String(enemy_security_state.get("security_group_id", "")).strip_edges().to_lower()
		if enemy_group_id.is_empty():
			return {}
		return resolve_flank_attack_preview_with_state(enemy_group_id, attacker, target, enemy_security_state)
	if not target.has_method("get_fireteam_id"):
		return {}
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("get_fireteam_security_state"):
		return {}
	var defending_fireteam_id: String = String(target.call("get_fireteam_id")).strip_edges().to_lower()
	if defending_fireteam_id.is_empty():
		return {}
	var security_state: Dictionary = Dictionary(tactical_controller.call("get_fireteam_security_state", defending_fireteam_id)).duplicate(true)
	return resolve_flank_attack_preview_with_state(defending_fireteam_id, attacker, target, security_state)


func resolve_flank_attack_preview_with_state(fireteam_id: String, attacker, target, security_state: Dictionary) -> Dictionary:
	if not flank_vulnerability_enabled or _flank_vulnerability_resolver == null or fireteam_id.strip_edges().is_empty():
		return {}
	_flank_vulnerability_resolver.configure_hex_sight_adapter(get_hex_sight_adapter())
	return Dictionary(_flank_vulnerability_resolver.call("preview_attack", fireteam_id, attacker, target, security_state, _current_tick)).duplicate(true)


func _maybe_publish_flank_event(flank_modifiers: Dictionary, attacker, target) -> void:
	if flank_modifiers.is_empty() or not (bool(flank_modifiers.get("triggered_now", false)) or bool(flank_modifiers.get("morale_triggered_now", false))):
		return
	var fireteam_id: String = String(flank_modifiers.get("fireteam_id", "")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return
	var direction_label: String = String(flank_modifiers.get("direction_label", "")).strip_edges().to_upper()
	var morale_state: String = String(flank_modifiers.get("morale_state", "")).strip_edges().to_lower()
	var event_text: String = "FLANK %s" % fireteam_id.to_upper()
	if not direction_label.is_empty():
		event_text = "%s %s" % [event_text, direction_label]
	if morale_state == "shaken":
		event_text = "%s SHK" % event_text
	_set_event_text(event_text)
	if target != null and target.has_method("show_event_text"):
		var target_event_text: String = "FLANKED"
		if morale_state == "shaken":
			target_event_text = "SHAKEN"
		elif not direction_label.is_empty():
			target_event_text = "%s FLANK" % direction_label
		target.call("show_event_text", target_event_text, DOWN_EVENT_COLOR, 1.2)
	if attacker != null and attacker.has_method("show_event_text"):
		var attacker_event_text: String = "FLANK"
		if not direction_label.is_empty():
			attacker_event_text = "%s %s" % [attacker_event_text, direction_label]
		attacker.call("show_event_text", attacker_event_text, DEFAULT_EVENT_COLOR, 1.0)
	var event_router = get_node_or_null("../EventRouter")
	if event_router != null and event_router.has_method("notify_flank_vulnerability_triggered"):
		event_router.call("notify_flank_vulnerability_triggered", fireteam_id, flank_modifiers)


func _record_friendly_fire_feedback(attacker, target, attacker_id: String, intended_target_id: String, actual_target_id: String) -> void:
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("record_tactical_communication_event"):
		return
	var fireteam_id: String = _get_unit_fireteam_id(attacker)
	var context: Dictionary = {
		"event_id": "friendly_fire:%s:%s:%d" % [attacker_id, actual_target_id, _current_tick],
		"fireteam_id": fireteam_id,
		"unit_id": actual_target_id,
		"phase": 1,
		"short_text": "FRIENDLY FIRE",
		"detail_text": "%s misidentified %s and hit %s" % [attacker_id, intended_target_id, actual_target_id],
		"map_label": "FRIENDLY FIRE",
		"priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL,
		"duration_seconds": 3.2,
		"feedback_action": "engage",
		"feedback_state": "contact",
		"anchor_position": _get_unit_world_position(attacker),
		"target_position": _get_unit_world_position(target),
		"metadata": {
			"attacker_unit_id": attacker_id,
			"intended_target_unit_id": intended_target_id,
			"actual_target_unit_id": actual_target_id,
		},
	}
	tactical_controller.call(
		"record_tactical_communication_event",
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_FRIENDLY_FIRE,
		context,
		{"now_msec": Time.get_ticks_msec(), "cooldown_msec": 250}
	)


func _get_unit_fireteam_id(unit) -> String:
	if unit != null and unit.has_method("get_fireteam_id"):
		return String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	return ""


func _get_fireteam_contact_state(fireteam_id: String, enemy_unit_id: String) -> Dictionary:
	if _contact_tracker == null or fireteam_id.strip_edges().is_empty() or enemy_unit_id.strip_edges().is_empty():
		return {}
	return Dictionary(_contact_tracker.call("get_contact_state", fireteam_id, enemy_unit_id)).duplicate(true)


func _build_fire_decision_context(extra: Dictionary = {}) -> Dictionary:
	var context: Dictionary = {
		"friendly_team_id": friendly_team_id,
		"contact_range": contact_range,
		"base_damage_multiplier": base_damage_multiplier,
		"spotted_contact_hit_chance_malus": SPOTTED_CONTACT_HIT_CHANCE_MALUS,
		"cache_effective_attack_range_by_attacker": true,
		"los_system": _get_combat_visibility_system(),
		"terrain_registry": _get_terrain_registry(),
		"check_discipline_break": Callable(self, "_check_discipline_break"),
		"can_return_fire": Callable(self, "_can_unit_return_fire"),
		"start_detection": Callable(self, "_start_or_continue_detection"),
		"is_detection_complete": Callable(self, "_is_detection_complete"),
		"get_contact_state": Callable(self, "_get_fireteam_contact_state"),
		"check_misidentification": Callable(self, "_check_misidentification"),
		"resolve_flank_attack": Callable(self, "resolve_flank_attack"),
		"get_effective_range": Callable(self, "_get_effective_range"),
		"get_weapon_attack_range": Callable(self, "_get_weapon_attack_range"),
		"get_attack_area_context": Callable(self, "_get_attack_area_context_for_fireteam"),
	}
	if get_hex_sight_adapter().is_active():
		context["query_current_visibility"] = Callable(self,"_query_current_visibility")
		context["get_hex_combat_geometry"] = Callable(self,"_get_hex_combat_geometry")
	if combat_tick_budget_debug_enabled:
		context["record_target_evaluation"] = Callable(self, "_record_resolver_target_evaluation")
		context["combat_hotspot_debug_enabled"] = true
		context["record_combat_hotspot"] = Callable(self, "_record_combat_hotspot")
	if use_observed_fire_candidate_index and _fire_candidate_index_tick == _current_tick:
		context["observed_target_ids_by_attacker_id"] = _fire_candidate_target_ids_by_attacker_id
		context["use_observed_fire_candidate_index"] = true
	for key in extra.keys():
		context[key] = extra[key]
	return context


func _get_attack_area_context_for_fireteam(fireteam_id: String) -> Dictionary:
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("get_fireteam_attack_area_context"):
		return {}
	return Dictionary(tactical_controller.call("get_fireteam_attack_area_context", fireteam_id)).duplicate(true)


func is_area_cleared(area_context: Dictionary) -> bool:
	if area_context.is_empty():
		return true
	for enemy in _get_enemy_combat_units():
		if not (enemy is Node2D):
			continue
		if bool(AREA_ORDER_RESOLVER_SCRIPT.call("is_position_in_area_context", area_context, (enemy as Node2D).global_position)):
			return false
	return true


func _get_known_friendly_fireteam_ids() -> Array:
	var known_fireteam_ids: Dictionary = {}
	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not friendly.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		known_fireteam_ids[fireteam_id] = true
	var result: Array = known_fireteam_ids.keys()
	result.sort()
	return result


func _get_fireteam_leadership_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for fireteam_id_variant in _get_known_friendly_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant)
		var leadership: float = 0.0
		var acting_lead = get_current_fireteam_lead_unit(fireteam_id)
		if acting_lead != null and acting_lead.has_method("get_leadership_skill"):
			leadership = float(acting_lead.call("get_leadership_skill"))
		result[fireteam_id] = leadership
	return result


func _ensure_readability_nodes() -> void:
	if _readability_presenter == null:
		return
	_readability_presenter.call("ensure_nodes", get_parent(), preview_mode)


func _connect_unit_signals() -> void:
	for unit in _get_units(friendly_unit_paths) + _get_units(enemy_unit_paths):
		if unit == null:
			continue

		if unit.has_signal("damage_applied"):
			var damage_callable := Callable(self, "_on_unit_damage_applied").bind(unit)
			if not unit.is_connected("damage_applied", damage_callable):
				unit.connect("damage_applied", damage_callable)

		if unit.has_signal("healed_applied"):
			var healed_callable := Callable(self, "_on_unit_healed_applied").bind(unit)
			if not unit.is_connected("healed_applied", healed_callable):
				unit.connect("healed_applied", healed_callable)

		if unit.has_signal("vital_status_changed"):
			var vital_callable := Callable(self, "_on_unit_vital_status_changed").bind(unit)
			if not unit.is_connected("vital_status_changed", vital_callable):
				unit.connect("vital_status_changed", vital_callable)


func _connect_respawn_signals() -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null:
		return

	if respawn_manager.has_signal("unit_respawn_completed"):
		if not respawn_manager.is_connected("unit_respawn_completed", Callable(self, "_on_unit_respawn_completed")):
			respawn_manager.connect("unit_respawn_completed", Callable(self, "_on_unit_respawn_completed"))


func _connect_wave_controller_signals() -> void:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null:
		return

	if enemy_wave_controller.has_signal("wave_started"):
		if not enemy_wave_controller.is_connected("wave_started", Callable(self, "_on_enemy_wave_started")):
			enemy_wave_controller.connect("wave_started", Callable(self, "_on_enemy_wave_started"))


func _on_unit_respawn_completed(unit_id: String) -> void:
	_queued_bleedout_by_unit_id.erase(unit_id)
	_clear_down_state_linger(unit_id)
	_set_event_text("%s RESPAWN READY" % unit_id)
	_broadcast_remote_event("%s RESPAWN READY" % unit_id, unit_id, RESPAWN_EVENT_COLOR, 1.6, "RESPAWN READY")


func _set_contact_visuals(attacker, target) -> void:
	_clear_unit_contact_states()
	if attacker == null or target == null:
		if _readability_presenter != null:
			_readability_presenter.call("clear_contact_line")
		return

	if _readability_presenter != null:
		_readability_presenter.call("set_contact_line", attacker, target)

	if attacker.has_method("set_contact_state"):
		attacker.call("set_contact_state", true, String(target.call("get_unit_id")))

	if target.has_method("set_contact_state"):
		target.call("set_contact_state", true, String(attacker.call("get_unit_id")))


func _clear_contact_visuals() -> void:
	_clear_unit_contact_states()
	if _readability_presenter != null:
		_readability_presenter.call("clear_contact_line")


func _clear_unit_contact_states() -> void:
	for unit in _get_units(friendly_unit_paths) + _get_units(enemy_unit_paths):
		if unit != null and unit.has_method("set_contact_state"):
			unit.call("set_contact_state", false, "")


func _on_unit_damage_applied(amount: int, _health_points: int, _hit_context: Dictionary, unit) -> void:
	var unit_id: String = String(unit.call("get_unit_id"))
	_set_event_text("%s HIT -%d" % [unit_id, amount])
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "HIT -%d" % amount, HIT_EVENT_COLOR)
	_broadcast_remote_event("%s HIT -%d" % [unit_id, amount], unit_id, HIT_EVENT_COLOR, EVENT_DEFAULT_DURATION, "HIT -%d" % amount)
	_emit_impact_sfx(_hit_context, unit)
	_try_reposition_enemy_on_damage(unit, _hit_context)
	_update_status_label("contact")


func _on_unit_healed_applied(amount: int, _health_points: int, heal_context: Dictionary, unit) -> void:
	if unit == null or not unit.has_method("get_unit_id"):
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var healer_unit_id: String = String(heal_context.get("healer_unit_id", ""))
	var event_text: String = "%s PATCH %s +%d" % [healer_unit_id if not healer_unit_id.is_empty() else "MEDIC", unit_id, amount]
	_set_event_text(event_text)
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "PATCH +%d" % amount, MEDIC_EVENT_COLOR, 1.4)
	if not healer_unit_id.is_empty():
		var healer = _resolve_unit_by_id(healer_unit_id)
		if healer != null and healer.has_method("show_event_text"):
			healer.call("show_event_text", "PATCH", MEDIC_EVENT_COLOR, 1.2)
	_broadcast_remote_event(event_text, unit_id, MEDIC_EVENT_COLOR, 1.4, "PATCH +%d" % amount)
	_update_status_label("active")


func _on_unit_vital_status_changed(vital_status, unit) -> void:
	if vital_status == null or not vital_status.has_method("get"):
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var vital_state: String = String(vital_status.get("state"))
	if vital_state == "fit":
		_queued_bleedout_by_unit_id.erase(unit_id)
		_clear_down_state_linger(unit_id)
	match vital_state:
		"down":
			_mark_unit_down_started(unit_id)
			_set_event_text("%s DOWN" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "DOWN", DOWN_EVENT_COLOR, 1.5)
			_broadcast_remote_event("%s DOWN" % unit_id, unit_id, DOWN_EVENT_COLOR, 1.5, "DOWN")
		"bleedout":
			_set_event_text("%s BLEEDOUT" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "BLEEDOUT", BLEEDOUT_EVENT_COLOR, 1.6)
			_broadcast_remote_event("%s BLEEDOUT" % unit_id, unit_id, BLEEDOUT_EVENT_COLOR, 1.6, "BLEEDOUT")
			_request_respawn_for_unit(unit, unit_id)
		"respawning":
			_set_event_text("%s RESPAWNING" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "RESPAWNING", RESPAWN_EVENT_COLOR, 1.6)
			_broadcast_remote_event("%s RESPAWNING" % unit_id, unit_id, RESPAWN_EVENT_COLOR, 1.6, "RESPAWNING")
	_update_status_label("active")


func _set_event_text(event_text: String) -> void:
	_last_event_text = event_text
	_update_event_label()


func _broadcast_remote_event(
	event_text: String,
	unit_id: String = "",
	event_color: Color = DEFAULT_EVENT_COLOR,
	duration_seconds: float = EVENT_DEFAULT_DURATION,
	unit_event_text: String = ""
) -> void:
	if not _can_broadcast_to_clients():
		return

	var payload: Dictionary = Dictionary(_remote_event_bridge.call("build_event_payload", event_text, unit_id, event_color, duration_seconds, unit_event_text))
	_receive_remote_event.rpc(
		String(payload.get("event_text", "")),
		String(payload.get("unit_id", "")),
		Color(payload.get("event_color", DEFAULT_EVENT_COLOR)),
		float(payload.get("duration_seconds", EVENT_DEFAULT_DURATION)),
		String(payload.get("unit_event_text", ""))
	)


func _update_event_label() -> void:
	if _readability_presenter == null:
		return
	_readability_presenter.call("update_event_label", _last_event_text)


func _should_run_local_combat(simulation_root: Node) -> bool:
	if simulation_root == null:
		return true

	if not _variant_to_bool(simulation_root.get("is_server_authoritative")):
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


func _can_broadcast_to_clients() -> bool:
	if not _runs_local_authority:
		return false

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false

	return multiplayer.is_server()


func _update_winner_label() -> void:
	if _readability_presenter == null:
		return
	_readability_presenter.call(
		"update_winner_label",
		{
			"combat_finished": _combat_finished,
			"winning_team_id": _winning_team_id,
			"result": String(_mission_result.get("result", "")),
			"win_condition_type": String(_mission_result.get("win_condition_type", "")),
		}
	)


func _count_fit_units(paths: Array[NodePath]) -> int:
	var fit_count: int = 0
	for unit in _get_units(paths):
		if unit != null and unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) == "fit":
			fit_count += 1

	return fit_count


func _count_fit_enemy_units() -> int:
	var fit_count: int = 0
	for enemy in _get_active_enemy_units():
		if enemy != null and enemy.has_method("get_vital_state") and String(enemy.call("get_vital_state")) == "fit":
			fit_count += 1

	return fit_count


func _build_attack_readiness_text() -> String:
	if _current_tick >= _next_attack_tick:
		return "ready"

	return "tick %d" % (_next_attack_tick - _current_tick)


func _finish_readability_setup() -> void:
	if preview_mode:
		_remove_readability_nodes()
		_apply_overlay_visibility()
		return
	_ensure_readability_nodes()
	_apply_overlay_visibility()
	_update_event_label()
	_update_winner_label()
	_update_status_label("waiting")


func set_preview_mode(is_preview: bool) -> void:
	preview_mode = is_preview
	if preview_mode:
		_remove_readability_nodes()
		_apply_overlay_visibility()
		return
	if is_inside_tree():
		_finish_readability_setup()


func set_overlay_visible(is_visible: bool) -> void:
	_overlays_visible = is_visible
	_apply_overlay_visibility()


func _apply_overlay_visibility() -> void:
	var status_label = get_node_or_null(status_label_path)
	if _readability_presenter != null:
		_readability_presenter.call("apply_overlay_visibility", status_label, _overlays_visible, preview_mode)


func _remove_readability_nodes() -> void:
	if _readability_presenter != null:
		_readability_presenter.call("remove_nodes")


func _is_victory_condition_met() -> bool:
	if _mission_scenario_runtime_gates != null and bool(_mission_scenario_runtime_gates.call("is_configured")):
		_update_mission_scenario_runtime_gates()
		return bool(_mission_scenario_runtime_gates.call("are_all_gates_complete"))
	if win_condition == WIN_CONDITION_OBJECTIVE_CAPTURE or win_condition == WIN_CONDITION_OBJECTIVE_DEFENSE:
		_update_objective_hold_tracking()
	var enemy_team_eliminated: bool = _is_enemy_team_eliminated() if win_condition != WIN_CONDITION_OBJECTIVE_CAPTURE and win_condition != WIN_CONDITION_OBJECTIVE_DEFENSE else false
	return bool(_combat_resolution_resolver.call(
		"is_victory_condition_met",
		win_condition,
		_is_objective_captured_by_friendly(),
		_get_objective_defense_elapsed_seconds(),
		objective_defense_hold_seconds,
		enemy_team_eliminated
	))


func _is_enemy_team_eliminated() -> bool:
	if _has_pending_enemy_waves():
		return false

	if _has_pending_enemy_respawns():
		return false

	var active_enemy_units: Array = _get_active_enemy_units()
	if active_enemy_units.is_empty():
		return true

	return _count_fit_enemy_units() == 0


func _resolve_combat(result: String, winning_team_id: String, result_condition_override: String = "") -> void:
	if _combat_finished:
		return

	_resolved_without_seen_friendly = result.strip_edges().to_lower() == "defeat" and not _has_seen_active_friendly_units
	_combat_finished = true
	_winning_team_id = winning_team_id
	_mission_result_condition_override = result_condition_override.strip_edges()
	_mission_result = _build_mission_result(result, winning_team_id)
	_set_event_text("MISSION %s" % result.to_upper())
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	if _can_broadcast_to_clients():
		_receive_mission_result.rpc(_mission_result)
	combat_resolved.emit(get_mission_result())


func _build_mission_result(result: String, winning_team_id: String) -> Dictionary:
	var result_condition: String = _mission_result_condition_override if not _mission_result_condition_override.is_empty() else win_condition
	var mission_result: Dictionary = Dictionary(_combat_resolution_resolver.call(
		"build_mission_result",
		{
			"result": result,
			"winning_team_id": winning_team_id,
			"friendly_team_id": friendly_team_id,
			"win_condition_type": result_condition,
			"objective_captured": _is_objective_captured_by_friendly(),
			"duration_seconds": _get_duration_seconds(),
			"team_states": _build_team_states(friendly_unit_paths),
			"fireteam_tactical_debrief": _build_fireteam_tactical_debrief_entries(),
		}
	))
	if not _mission_scenario_runtime_gate_snapshot.is_empty():
		mission_result["mission_scenario_runtime_gates"] = _mission_scenario_runtime_gate_snapshot.duplicate(true)
	return mission_result


func _build_fireteam_tactical_debrief_entries() -> Array:
	var result: Array = []
	var tactical_controller = _get_tactical_controller()
	for fireteam_id_variant in _get_known_friendly_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var profile: Dictionary = {}
		if tactical_controller != null and tactical_controller.has_method("get_active_behavior_profile"):
			profile = Dictionary(tactical_controller.call("get_active_behavior_profile", fireteam_id)).duplicate(true)
		var metadata: Dictionary = Dictionary(profile.get("metadata", {}))
		var public_snapshot: Dictionary = Dictionary(metadata.get("ftl_public_snapshot", {}))
		var skill_snapshot: Dictionary = Dictionary(metadata.get("ftl_tactical_skill", {}))
		var contacts: Array = get_fireteam_contact_snapshot(fireteam_id)
		if profile.is_empty() and public_snapshot.is_empty() and contacts.is_empty():
			continue
		result.append({
			"fireteam_id": fireteam_id,
			"reaction_delay_seconds": clampf(float(public_snapshot.get("reaction_delay_seconds", profile.get("reaction_delay_seconds", 0.35))), 0.0, 2.0),
			"plan_quality": clampf(float(public_snapshot.get("plan_quality", skill_snapshot.get("plan_quality", 0.5))), 0.0, 1.0),
			"tempo_modifier": clampf(float(public_snapshot.get("tempo_modifier", skill_snapshot.get("tempo_modifier", 1.0))), 0.0, 2.0),
			"contact_report_quality": clampf(float(public_snapshot.get("contact_report_quality", skill_snapshot.get("contact_report_quality", 0.5))), 0.0, 1.0),
			"contact_report_count": contacts.size(),
			"morale": clampf(float(public_snapshot.get("morale", skill_snapshot.get("morale", 0.5))), 0.0, 1.0),
			"frustration": clampf(float(public_snapshot.get("frustration", skill_snapshot.get("frustration", 0.0))), 0.0, 1.0),
		})
	return result


func _get_enemy_team_id() -> String:
	for enemy in _get_units(enemy_unit_paths):
		if enemy != null and enemy.has_method("get_team_id"):
			var team_id: String = String(enemy.call("get_team_id"))
			if not team_id.is_empty():
				return team_id

	return ""


func _get_duration_seconds() -> float:
	if _mission_started_at_msec == 0:
		return 0.0

	return maxf(float(Time.get_ticks_msec() - _mission_started_at_msec) / 1000.0, 0.0)


func get_remaining_time_limit_seconds() -> float:
	if mission_time_limit_seconds <= 0.0 or _mission_started_at_msec == 0:
		return -1.0
	return maxf(mission_time_limit_seconds - _get_duration_seconds(), 0.0)


func _sync_objective_countdown_state() -> void:
	var objective_status = _get_objective_status()
	if objective_status == null or not objective_status.has_method("set_countdown") or not objective_status.has_method("clear_countdown"):
		return
	var countdown: Dictionary = _build_objective_countdown_source()
	if countdown.is_empty():
		objective_status.call("clear_countdown")
		return
	objective_status.call(
		"set_countdown",
		float(countdown.get("countdown_seconds", 0.0)),
		String(countdown.get("timer_state", "none")),
		String(countdown.get("timer_source", "")),
		float(countdown.get("countdown_total_seconds", countdown.get("countdown_seconds", 0.0))),
		String(countdown.get("timer_label", ""))
	)


func _build_objective_countdown_source() -> Dictionary:
	if _mission_scenario_runtime_gates != null and bool(_mission_scenario_runtime_gates.call("is_configured")):
		_update_mission_scenario_runtime_gates()
		var scenario_countdown: Dictionary = Dictionary(_mission_scenario_runtime_gates.call("build_countdown_source"))
		if not scenario_countdown.is_empty():
			return scenario_countdown
	if win_condition == WIN_CONDITION_OBJECTIVE_DEFENSE:
		_update_objective_hold_tracking()
	return Dictionary(_combat_resolution_resolver.call(
		"build_objective_countdown_source",
		win_condition,
		objective_defense_hold_seconds,
		_get_objective_defense_elapsed_seconds(),
		_is_objective_captured_by_friendly(),
		mission_time_limit_seconds,
		get_remaining_time_limit_seconds()
	))


func _get_objective_status():
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return null

	return simulation_root.call("get_objective_status")


func _is_objective_captured_by_friendly() -> bool:
	var objective_status = _get_objective_status()
	if objective_status == null:
		return false

	return String(objective_status.owning_team_id) == friendly_team_id and float(objective_status.capture_progress) >= 1.0


func _update_objective_hold_tracking() -> void:
	if win_condition != WIN_CONDITION_OBJECTIVE_DEFENSE:
		return

	if _is_objective_captured_by_friendly():
		if _objective_owned_since_msec < 0:
			_objective_owned_since_msec = Time.get_ticks_msec()
		return

	_objective_owned_since_msec = -1


func _get_objective_defense_elapsed_seconds() -> float:
	if _objective_owned_since_msec < 0:
		return 0.0

	return maxf(float(Time.get_ticks_msec() - _objective_owned_since_msec) / 1000.0, 0.0)


func _build_objective_status_text() -> String:
	var objective_status = _get_objective_status()
	if objective_status == null:
		return "Objective: unavailable"

	var owner_text: String = String(objective_status.owning_team_id)
	if owner_text.is_empty():
		owner_text = "neutral"

	var progress_percent: int = int(round(clampf(float(objective_status.capture_progress), 0.0, 1.0) * 100.0))
	var status_text: String = "Objective: %s %d%%" % [owner_text, progress_percent]
	if bool(objective_status.call("is_contested")):
		status_text += " contested"

	return status_text


func _update_enemy_security_state() -> void:
	_enemy_security_states_by_group_id.clear()
	var grouped_units: Dictionary = {}
	var tactics_by_group: Dictionary = {}
	for enemy in _get_active_enemy_units():
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue
		var tactics: Dictionary = _get_enemy_tactics_config(enemy)
		var group_id: String = _get_enemy_security_group_id(enemy, tactics)
		if group_id.is_empty():
			continue
		if not grouped_units.has(group_id):
			grouped_units[group_id] = []
			tactics_by_group[group_id] = tactics
		var units: Array = Array(grouped_units.get(group_id, []))
		units.append(enemy)
		grouped_units[group_id] = units
	for group_id_variant in grouped_units.keys():
		var group_id: String = String(group_id_variant)
		var state: Dictionary = _build_enemy_security_state(group_id, Array(grouped_units.get(group_id_variant, [])), Dictionary(tactics_by_group.get(group_id_variant, {})))
		if state.is_empty():
			continue
		_enemy_security_states_by_group_id[group_id] = state


func _build_enemy_security_state(group_id: String, units: Array, tactics: Dictionary) -> Dictionary:
	if units.is_empty():
		return {}
	var unit_ids: PackedStringArray = PackedStringArray()
	var anchor_position: Vector2 = _resolve_enemy_security_anchor(units)
	var focus_position: Vector2 = _resolve_enemy_security_focus_position(units, anchor_position)
	var fallback_angle: float = (focus_position - anchor_position).angle() if not focus_position.is_equal_approx(anchor_position) else 0.0
	var facing: String = String(tactics.get("facing", "auto")).strip_edges().to_lower()
	var direction_angle: float = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.call("resolve_facing_angle", facing, fallback_angle)
	var security_mode: String = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.call("normalize_enemy_security_mode", String(tactics.get("security_mode", "directional")))
	var assignments: Array = Array(FIRETEAM_SECURITY_CONTROLLER_SCRIPT.call("build_enemy_member_assignments", units, security_mode, direction_angle, _get_terrain_registry()))
	var hex_adapter = get_hex_sight_adapter()
	if hex_adapter.is_active():
		assignments = hex_adapter.apply_security_assignments(assignments,"enemy_security:%s:%d"%[group_id,_current_tick],security_mode,direction_angle)
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		unit_ids.append(unit_id)
		if unit is Node:
			(unit as Node).set_meta("enemy_security_group_id", group_id)
			var visual_angle: float = direction_angle
			if hex_adapter.is_active():
				var logical: Dictionary = hex_adapter.build_observer_state(unit,-1.0)
				if not logical.is_empty():
					visual_angle = hex_adapter.facing_to_world_angle(int(logical.hex_state.facing_dir))
			(unit as Node).set_meta("enemy_facing_angle", visual_angle)
			(unit as Node).set_meta("enemy_security_mode", security_mode)
	var state: Dictionary = {
		"security_group_id": group_id,
		"fireteam_id": group_id,
		"team_id": String(tactics.get("team_id", _get_enemy_team_id())),
		"profile_id": String(tactics.get("profile_id", "")),
		"security_mode": security_mode,
		"facing": facing,
		"facing_angle": direction_angle,
		"direction_angle": direction_angle,
		"sector_width": TAU if security_mode == "360" else FIRETEAM_SECURITY_CONTROLLER_SCRIPT.DIRECTIONAL_ARC_WIDTH,
		"anchor_position": anchor_position,
		"focus_position": focus_position,
		"unit_ids": unit_ids,
		"member_assignments": assignments,
		"is_active": true,
		"overwatch_ready": security_mode == "360" or String(tactics.get("profile_id", "")).strip_edges().to_lower() == "sniper_watch",
	}
	state["watched_unit_ids"] = _build_enemy_watched_unit_ids(units, state)
	if hex_adapter.is_active():
		state["hex_tactical"] = true
		state["sector_width"] = deg_to_rad(hex_sight_arc_degrees)
	state["watch_label"] = _build_enemy_security_label(state)
	return state


func _build_enemy_watched_unit_ids(units: Array, state: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var assignment_by_unit_id: Dictionary = {}
	for assignment_variant in Array(state.get("member_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		assignment_by_unit_id[String(assignment.get("unit_id", ""))] = assignment
	for enemy in units:
		if enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
			continue
		var enemy_id: String = String(enemy.call("get_unit_id"))
		var assignment: Dictionary = Dictionary(assignment_by_unit_id.get(enemy_id, {}))
		if assignment.is_empty():
			continue
		for friendly in _get_friendly_combat_units():
			if friendly == null or not (friendly is Node2D):
				continue
			var friendly_id: String = String(friendly.call("get_unit_id")) if friendly.has_method("get_unit_id") else ""
			if friendly_id.is_empty() or result.has(friendly_id):
				continue
			var hex_adapter = get_hex_sight_adapter()
			if hex_adapter.is_active():
				var enemy_position: Vector2 = _get_contact_observation_position(enemy)
				var friendly_position: Vector2 = _get_contact_observation_position(friendly)
				if not _angle_within_sector(hex_adapter.bearing(enemy_position,friendly_position),hex_adapter.world_angle_to_plane(float(assignment.get("center_angle",0.0))),float(assignment.get("arc_width",0.0))):
					continue
				if bool(_query_current_visibility(enemy,friendly,float(assignment.get("weapon_range_world",0.0))).get("visible",false)):
					result.append(friendly_id)
				continue
			var to_target: Vector2 = (friendly as Node2D).global_position - (enemy as Node2D).global_position
			if String(state.get("security_mode", "")) != "360" and not _angle_within_sector(to_target.angle(), float(assignment.get("center_angle", 0.0)), float(assignment.get("arc_width", 0.0))):
				continue
			if to_target.length() > float(assignment.get("weapon_range_world", 0.0)):
				continue
			if not bool(_get_combat_visibility_system().call("has_line_of_sight_between_nodes", enemy, friendly, float(assignment.get("weapon_range_world", 0.0)), _get_terrain_registry())):
				continue
			result.append(friendly_id)
	return result


func _resolve_enemy_security_anchor(units: Array) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for unit in units:
		if unit is Node2D:
			var position: Dictionary = get_hex_sight_adapter().read_position(unit)
			if not bool(position.get("valid",false)):
				continue
			sum += Vector2(position.position)
			count += 1
	if count <= 0:
		return Vector2.ZERO
	return sum / float(count)


func _resolve_enemy_security_focus_position(units: Array, fallback_position: Vector2) -> Vector2:
	var nearest_position: Vector2 = fallback_position
	var nearest_distance: float = INF
	var hex_adapter = get_hex_sight_adapter()
	for enemy in units:
		if enemy == null or not (enemy is Node2D):
			continue
		for friendly in _get_friendly_combat_units():
			if friendly == null or not (friendly is Node2D):
				continue
			var distance: float = (enemy as Node2D).global_position.distance_to((friendly as Node2D).global_position)
			if hex_adapter.is_active():
				if not _has_valid_los(enemy,friendly):
					continue
				distance = hex_adapter.distance(_get_contact_observation_position(enemy),_get_contact_observation_position(friendly))
			if distance >= nearest_distance:
				continue
			nearest_distance = distance
			nearest_position = _get_contact_observation_position(friendly)
	if nearest_distance < INF:
		return nearest_position
	return _get_objective_position()


func _get_enemy_tactics_config(enemy) -> Dictionary:
	if enemy is Node and (enemy as Node).has_meta("enemy_tactics_config"):
		var metadata_tactics: Dictionary = Dictionary((enemy as Node).get_meta("enemy_tactics_config", {})).duplicate(true)
		metadata_tactics["has_explicit_tactics"] = true
		return metadata_tactics
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller != null and enemy_wave_controller.has_method("get_tactic_config_for_unit") and enemy != null and enemy.has_method("get_unit_id"):
		var wave_tactics: Dictionary = Dictionary(enemy_wave_controller.call("get_tactic_config_for_unit", String(enemy.call("get_unit_id")))).duplicate(true)
		if not wave_tactics.is_empty():
			wave_tactics["has_explicit_tactics"] = true
			return wave_tactics
	return {
		"profile_id": "guard_hold",
		"security_mode": "directional",
		"facing": "auto",
		"has_explicit_tactics": false,
	}


func _get_enemy_security_group_id(enemy, tactics: Dictionary) -> String:
	var group_id: String = String(tactics.get("group_id", "")).strip_edges().to_lower()
	if not group_id.is_empty():
		return group_id
	if enemy != null and enemy.has_method("get_fireteam_id"):
		group_id = String(enemy.call("get_fireteam_id")).strip_edges().to_lower()
		if not group_id.is_empty():
			return group_id
	if enemy != null and enemy.has_method("get_team_id"):
		group_id = String(enemy.call("get_team_id")).strip_edges().to_lower()
		if not group_id.is_empty():
			return group_id
	return "enemy_team"


func _build_enemy_security_label(state: Dictionary) -> String:
	var mode: String = String(state.get("security_mode", "")).strip_edges().to_upper()
	var watched_count: int = PackedStringArray(state.get("watched_unit_ids", PackedStringArray())).size()
	if watched_count > 0:
		return "EN SEC %s W%d" % [mode, watched_count]
	return "EN SEC %s" % mode


func _angle_within_sector(target_angle: float, center_angle: float, arc_width: float) -> bool:
	return absf(wrapf(target_angle - center_angle, -PI, PI)) <= arc_width * 0.5


func _update_enemy_team_tactics_state() -> void:
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	var phase_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var grouped_units: Dictionary = {}
	var tactics_by_group: Dictionary = {}
	for enemy in _get_active_enemy_units():
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue
		var tactics: Dictionary = _get_enemy_tactics_config(enemy)
		if not bool(tactics.get("has_explicit_tactics", false)):
			continue
		var group_id: String = _get_enemy_security_group_id(enemy, tactics)
		if group_id.is_empty():
			continue
		if not grouped_units.has(group_id):
			grouped_units[group_id] = []
			tactics_by_group[group_id] = tactics
		var units: Array = Array(grouped_units.get(group_id, []))
		units.append(enemy)
		grouped_units[group_id] = units
	if profile_enabled:
		_record_combat_hotspot("tactics_group_units", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	var input_signature: String = _build_enemy_team_tactics_input_signature(grouped_units, tactics_by_group)
	if profile_enabled:
		_record_combat_hotspot("tactics_signature", Time.get_ticks_usec() - phase_started_usec)
	if _enemy_team_tactics_input_signature_initialized and input_signature == _enemy_team_tactics_input_signature:
		_enemy_team_tactics_skip_count += 1
		return
	_enemy_team_tactics_input_signature = input_signature
	_enemy_team_tactics_input_signature_initialized = true
	_enemy_team_tactics_rebuild_count += 1
	_enemy_team_tactics_states_by_group_id.clear()
	for group_id_variant in grouped_units.keys():
		var group_id: String = String(group_id_variant)
		var state: Dictionary = _build_enemy_team_tactics_state(group_id, Array(grouped_units.get(group_id_variant, [])), Dictionary(tactics_by_group.get(group_id_variant, {})))
		if state.is_empty():
			continue
		_enemy_team_tactics_states_by_group_id[group_id] = state


func _build_enemy_team_tactics_input_signature(grouped_units: Dictionary, tactics_by_group: Dictionary) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	var group_ids: Array = grouped_units.keys()
	group_ids.sort()
	for group_id_variant in group_ids:
		var group_id: String = String(group_id_variant)
		var tactics: Dictionary = Dictionary(tactics_by_group.get(group_id, {}))
		tokens.append("group:%s:%s:%s:%s" % [
			group_id,
			String(tactics.get("profile_id", "")),
			String(tactics.get("advance_style", "")),
			String(tactics.get("cover_behavior", "")),
		])
		for unit in _sort_enemy_units_by_id(Array(grouped_units.get(group_id, []))):
			_append_enemy_team_tactics_signature_unit(tokens, unit, "enemy")
	for friendly in _sort_enemy_units_by_id(_get_friendly_combat_units()):
		_append_enemy_team_tactics_signature_unit(tokens, friendly, "friendly")
	var objective_position: Vector2 = _get_objective_position()
	tokens.append("objective:%.3f:%.3f" % [objective_position.x, objective_position.y])
	return "|".join(tokens)


func _append_enemy_team_tactics_signature_unit(tokens: PackedStringArray, unit, relation: String) -> void:
	if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id"):
		return
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	if unit_id.is_empty():
		return
	var vital_state: String = String(unit.call("get_vital_state")) if unit.has_method("get_vital_state") else "fit"
	var position: Vector2 = (unit as Node2D).global_position
	tokens.append("%s:%s:%s:%.3f:%.3f" % [relation, unit_id, vital_state, position.x, position.y])


func get_enemy_team_tactics_runtime_guard_snapshot() -> Dictionary:
	return {
		"input_signature_initialized": _enemy_team_tactics_input_signature_initialized,
		"rebuild_count": _enemy_team_tactics_rebuild_count,
		"skip_count": _enemy_team_tactics_skip_count,
		"group_count": _enemy_team_tactics_states_by_group_id.size(),
		"read_only_diagnostics": true,
		"sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _build_enemy_team_tactics_state(group_id: String, units: Array, tactics: Dictionary) -> Dictionary:
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	var phase_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var fit_units: Array = _sort_enemy_units_by_id(_filter_fit_node2d_units(units))
	if profile_enabled:
		_record_combat_hotspot("tactics_state_fit_sort", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	if fit_units.is_empty():
		return {}
	var profile_id: String = String(tactics.get("profile_id", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.DEFAULT_PROFILE_ID)).strip_edges().to_lower()
	var profile: Dictionary = Dictionary(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_profile", profile_id))
	var visual_archetype_id: String = String(tactics.get("visual_archetype", profile.get("visual_archetype", ""))).strip_edges().to_lower()
	var advance_style: String = String(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_advance_style", tactics.get("advance_style", profile.get("advance_style", "hold")), String(profile.get("advance_style", "hold"))))
	var cover_behavior: String = String(tactics.get("cover_behavior", profile.get("cover_behavior", ""))).strip_edges().to_lower()
	var posture_config: Dictionary = _build_enemy_posture_config(tactics, profile)
	if profile_enabled:
		_record_combat_hotspot("tactics_state_config", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	var anchor_position: Vector2 = _resolve_enemy_security_anchor(fit_units)
	var focus_position: Vector2 = _resolve_enemy_security_focus_position(fit_units, anchor_position)
	var advance_direction: Vector2 = (focus_position - anchor_position).normalized() if not focus_position.is_equal_approx(anchor_position) else Vector2.RIGHT
	if profile_enabled:
		_record_combat_hotspot("tactics_state_anchor_focus", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	var unit_ids: PackedStringArray = _extract_unit_ids_from_units(fit_units)
	var role_by_unit_id: Dictionary = _build_enemy_team_roles(fit_units)
	var moving_unit_ids: PackedStringArray = _resolve_enemy_moving_unit_ids(advance_style, unit_ids)
	var covering_unit_ids: PackedStringArray = _subtract_unit_ids(unit_ids, moving_unit_ids)
	if profile_enabled:
		_record_combat_hotspot("tactics_state_roles", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	var target_positions_by_unit_id: Dictionary = _build_enemy_tactics_target_positions(fit_units, unit_ids, moving_unit_ids, advance_style, cover_behavior, anchor_position, focus_position, advance_direction)
	if profile_enabled:
		_record_combat_hotspot("tactics_state_targets", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	var movement_posture_by_unit_id: Dictionary = {}
	var weapon_posture_by_unit_id: Dictionary = {}
	var posture_policy_by_unit_id: Dictionary = {}
	var move_speed_factor_by_unit_id: Dictionary = {}
	for unit in fit_units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var posture_unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if posture_unit_id.is_empty():
			continue
		var posture: Dictionary = _resolve_enemy_posture_for_unit(unit, posture_config, focus_position, advance_style, moving_unit_ids.has(posture_unit_id))
		movement_posture_by_unit_id[posture_unit_id] = String(posture.get("movement_posture", ENEMY_POSTURE_TACTICAL))
		weapon_posture_by_unit_id[posture_unit_id] = String(posture.get("weapon_posture", ENEMY_WEAPON_READY))
		posture_policy_by_unit_id[posture_unit_id] = String(posture.get("posture_policy_id", posture_config.get("movement_posture_policy", "")))
		move_speed_factor_by_unit_id[posture_unit_id] = float(posture.get("move_speed_factor", _get_enemy_tactics_speed_factor(advance_style)))
	if profile_enabled:
		_record_combat_hotspot("tactics_state_posture", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	for unit in fit_units:
		if unit is Node and unit.has_method("get_unit_id"):
			var unit_id: String = String(unit.call("get_unit_id"))
			(unit as Node).set_meta("enemy_tactics_group_id", group_id)
			(unit as Node).set_meta("enemy_tactic_profile_id", profile_id)
			(unit as Node).set_meta("enemy_advance_style", advance_style)
			(unit as Node).set_meta("enemy_role", String(role_by_unit_id.get(unit_id, "")))
			(unit as Node).set_meta("enemy_movement_posture", String(movement_posture_by_unit_id.get(unit_id, ENEMY_POSTURE_TACTICAL)))
			(unit as Node).set_meta("enemy_weapon_posture", String(weapon_posture_by_unit_id.get(unit_id, ENEMY_WEAPON_READY)))
			(unit as Node).set_meta("enemy_posture_policy_id", String(posture_policy_by_unit_id.get(unit_id, "")))
			if not visual_archetype_id.is_empty():
				(unit as Node).set_meta("enemy_visual_archetype_id", visual_archetype_id)
	if profile_enabled:
		_record_combat_hotspot("tactics_state_meta", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	var state: Dictionary = {
		"security_group_id": group_id,
		"team_id": String(tactics.get("team_id", _get_enemy_team_id())),
		"profile_id": profile_id,
		"visual_archetype": visual_archetype_id,
		"advance_style": advance_style,
		"cover_behavior": cover_behavior,
		"anchor_position": anchor_position,
		"focus_position": focus_position,
		"advance_direction": advance_direction,
		"unit_ids": unit_ids,
		"moving_unit_ids": moving_unit_ids,
		"covering_unit_ids": covering_unit_ids,
		"role_by_unit_id": role_by_unit_id,
		"target_positions_by_unit_id": target_positions_by_unit_id,
		"movement_posture_policy": String(posture_config.get("movement_posture_policy", "")),
		"ready_distance_world": float(posture_config.get("ready_distance_world", 640.0)),
		"travel_speed_factor": float(posture_config.get("travel_speed_factor", 0.55)),
		"ready_speed_factor": float(posture_config.get("ready_speed_factor", 0.30)),
		"aim_move_speed_factor": float(posture_config.get("aim_move_speed_factor", 0.18)),
		"movement_posture_by_unit_id": movement_posture_by_unit_id,
		"weapon_posture_by_unit_id": weapon_posture_by_unit_id,
		"posture_policy_by_unit_id": posture_policy_by_unit_id,
		"move_speed_factor_by_unit_id": move_speed_factor_by_unit_id,
		"has_explicit_tactics": true,
		"priority": _get_enemy_tactics_priority(advance_style),
		"move_speed_factor": _get_enemy_group_move_speed_factor(move_speed_factor_by_unit_id, _get_enemy_tactics_speed_factor(advance_style)),
	}
	state["tactic_label"] = _build_enemy_team_tactics_label(state)
	for unit in fit_units:
		if unit is Node:
			(unit as Node).set_meta("enemy_tactic_label", String(state.get("tactic_label", "")))
	if profile_enabled:
		_record_combat_hotspot("tactics_state_assemble", Time.get_ticks_usec() - phase_started_usec)
	return state


func _filter_fit_node2d_units(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		result.append(unit)
	return result


func _sort_enemy_units_by_id(units: Array) -> Array:
	var sorted_units: Array = units.duplicate()
	sorted_units.sort_custom(func(a, b) -> bool:
		var id_a: String = String(a.call("get_unit_id")) if a != null and a.has_method("get_unit_id") else ""
		var id_b: String = String(b.call("get_unit_id")) if b != null and b.has_method("get_unit_id") else ""
		return id_a < id_b
	)
	return sorted_units


func _extract_unit_ids_from_units(units: Array) -> PackedStringArray:
	var unit_ids: PackedStringArray = PackedStringArray()
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	return unit_ids


func _build_enemy_team_roles(units: Array) -> Dictionary:
	var role_by_unit_id: Dictionary = {}
	for index in range(units.size()):
		var unit = units[index]
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		role_by_unit_id[unit_id] = _resolve_enemy_team_role(unit, index)
	return role_by_unit_id


func _resolve_enemy_team_role(unit, index: int) -> String:
	var weapon_id: String = _get_unit_active_weapon_id(unit)
	var role_id: String = String(unit.call("get_role_id")) if unit != null and unit.has_method("get_role_id") else ""
	if weapon_id == "sniper":
		return "sniper_watch"
	if weapon_id == "rail_gun" or weapon_id == "rocket_launcher":
		return "support"
	if role_id.find("medic") >= 0 or weapon_id == "medictool":
		return "medic"
	if index == 0:
		return "point"
	if index == 1:
		return "cover"
	return "rifle"


func _resolve_enemy_moving_unit_ids(advance_style: String, unit_ids: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if unit_ids.is_empty():
		return result
	match advance_style:
		"hold":
			return result
		"probe":
			result.append(unit_ids[0])
		"bounding":
			var moving_count: int = maxi(1, int(ceil(float(unit_ids.size()) * 0.5)))
			for index in range(moving_count):
				result.append(unit_ids[index])
		"push":
			for unit_id in unit_ids:
				result.append(unit_id)
		_:
			for unit_id in unit_ids:
				result.append(unit_id)
	return result


func _subtract_unit_ids(all_unit_ids: PackedStringArray, moving_unit_ids: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for unit_id in all_unit_ids:
		if not moving_unit_ids.has(unit_id):
			result.append(unit_id)
	return result


func _build_enemy_tactics_target_positions(
	units: Array,
	unit_ids: PackedStringArray,
	moving_unit_ids: PackedStringArray,
	advance_style: String,
	cover_behavior: String,
	anchor_position: Vector2,
	focus_position: Vector2,
	advance_direction: Vector2
) -> Dictionary:
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	var phase_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var target_positions: Dictionary = {}
	var claimed_targets: Array = []
	if _enemy_cover_behavior_uses_slots(cover_behavior):
		target_positions = _build_enemy_cover_slot_targets(units, focus_position, claimed_targets)
	if profile_enabled:
		_record_combat_hotspot("tactics_targets_cover_select", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	if advance_style == "hold":
		return target_positions
	var step_distance: float = _get_enemy_tactics_step_distance(advance_style)
	var movement_anchor: Vector2 = anchor_position + advance_direction * step_distance
	var spaced_targets: Dictionary = Dictionary(LOCAL_AVOIDANCE_RESOLVER_SCRIPT.call("build_spaced_line_targets", moving_unit_ids, movement_anchor, advance_direction, LOCAL_AVOIDANCE_RESOLVER_SCRIPT.DEFAULT_MINIMUM_SPACING))
	if profile_enabled:
		_record_combat_hotspot("tactics_targets_spacing", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	for unit_id in moving_unit_ids:
		var target_position: Vector2 = Vector2(target_positions.get(String(unit_id), spaced_targets.get(String(unit_id), movement_anchor)))
		target_positions[String(unit_id)] = _resolve_enemy_walkable_tactic_target(target_position)
	if profile_enabled:
		_record_combat_hotspot("tactics_targets_resolve_walkable", Time.get_ticks_usec() - phase_started_usec)
		phase_started_usec = Time.get_ticks_usec()
	for unit_id in unit_ids:
		if target_positions.has(String(unit_id)):
			continue
		var unit = _find_unit_by_id(units, String(unit_id))
		if unit is Node2D:
			target_positions[String(unit_id)] = (unit as Node2D).global_position
	if profile_enabled:
		_record_combat_hotspot("tactics_targets_fill", Time.get_ticks_usec() - phase_started_usec)
	return target_positions


func _enemy_cover_behavior_uses_slots(cover_behavior: String) -> bool:
	return cover_behavior.find("cover") >= 0


func _build_enemy_cover_slot_targets(units: Array, focus_position: Vector2, claimed_targets: Array) -> Dictionary:
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	var target_positions: Dictionary = {}
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		return target_positions
	for unit in units:
		if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		var phase_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
		var candidates: Array = Array(terrain_registry.call("get_walkable_cover_tiles_in_radius", (unit as Node2D).global_position, ENEMY_TACTICS_COVER_SEARCH_RADIUS))
		if profile_enabled:
			_record_combat_hotspot("tactics_cover_query", Time.get_ticks_usec() - phase_started_usec)
			phase_started_usec = Time.get_ticks_usec()
		# Inputs stay fixed during this synchronous selection. Reuse the exact
		# score on repeated sort/threshold reads; retain first-read order and ties.
		var score_by_tile: Dictionary = {}
		var score_for_tile := func(tile) -> float:
			if not score_by_tile.has(tile):
				var score_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
				score_by_tile[tile] = _score_enemy_cover_tile(unit, tile, focus_position)
				if profile_enabled:
					_record_combat_hotspot("tactics_cover_score", Time.get_ticks_usec() - score_started_usec)
			return float(score_by_tile[tile])
		candidates.sort_custom(func(a, b) -> bool:
			return float(score_for_tile.call(a)) > float(score_for_tile.call(b))
		)
		if profile_enabled:
			_record_combat_hotspot("tactics_cover_sort", Time.get_ticks_usec() - phase_started_usec)
			phase_started_usec = Time.get_ticks_usec()
		for tile in candidates:
			if tile == null or typeof(tile.world_position) != TYPE_VECTOR2:
				continue
			var candidate_position: Vector2 = Vector2(tile.world_position)
			if not _is_enemy_tactic_slot_available(candidate_position, claimed_targets):
				continue
			if float(score_for_tile.call(tile)) <= -999.0:
				continue
			target_positions[unit_id] = candidate_position
			claimed_targets.append(candidate_position)
			break
		if profile_enabled:
			_record_combat_hotspot("tactics_cover_claim_select", Time.get_ticks_usec() - phase_started_usec)
	return target_positions


func _score_enemy_cover_tile(unit, tile, focus_position: Vector2) -> float:
	if tile == null or typeof(tile.world_position) != TYPE_VECTOR2:
		return -1000.0
	if not bool(tile.walkable):
		return -1000.0
	var tile_position: Vector2 = Vector2(tile.world_position)
	var attack_range: float = _get_weapon_attack_range(unit, null)
	if attack_range > 0.0 and tile_position.distance_to(focus_position) > attack_range:
		return -1000.0
	if not bool(_get_combat_visibility_system().call("has_line_of_sight_between_points", tile_position, focus_position, attack_range, _get_terrain_registry())):
		return -1000.0
	var unit_position: Vector2 = (unit as Node2D).global_position if unit is Node2D else tile_position
	var cover_score: float = clampf(float(tile.cover_value) / 100.0, 0.0, 1.0)
	var height_score: float = clampf(float(tile.height_level) * 0.08, -0.2, 0.35)
	var move_cost: float = unit_position.distance_to(tile_position) * 0.003
	var focus_distance: float = tile_position.distance_to(focus_position)
	var range_score: float = 0.0 if attack_range <= 0.0 else clampf(1.0 - (focus_distance / attack_range), 0.0, 1.0) * 0.25
	return cover_score * 2.0 + height_score + range_score - move_cost


func _is_enemy_tactic_slot_available(candidate_position: Vector2, claimed_targets: Array) -> bool:
	for claimed_variant in claimed_targets:
		if typeof(claimed_variant) != TYPE_VECTOR2:
			continue
		if candidate_position.distance_to(Vector2(claimed_variant)) < LOCAL_AVOIDANCE_RESOLVER_SCRIPT.DEFAULT_MINIMUM_SPACING - 0.001:
			return false
	return true


func _resolve_enemy_walkable_tactic_target(target_position: Vector2) -> Vector2:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("resolve_walkable_target"):
		return target_position
	var resolved: Dictionary = Dictionary(terrain_registry.call("resolve_walkable_target", target_position))
	return Vector2(resolved.get("replacement_position", target_position))


func _find_unit_by_id(units: Array, unit_id: String):
	for unit in units:
		if unit != null and unit.has_method("get_unit_id") and String(unit.call("get_unit_id")) == unit_id:
			return unit
	return null


func _get_enemy_tactics_step_distance(advance_style: String) -> float:
	match advance_style:
		"probe":
			return ENEMY_TACTICS_PROBE_STEP_DISTANCE
		"bounding":
			return ENEMY_TACTICS_BOUND_STEP_DISTANCE
		"push":
			return ENEMY_TACTICS_PUSH_STEP_DISTANCE
		_:
			return 0.0


func _get_enemy_tactics_priority(advance_style: String) -> int:
	match advance_style:
		"bounding":
			return 10
		"push":
			return 9
		"probe":
			return 8
		_:
			return 6


func _get_enemy_tactics_speed_factor(advance_style: String) -> float:
	match advance_style:
		"bounding":
			return enemy_advance_speed_factor * 0.82
		"probe":
			return enemy_advance_speed_factor * 0.7
		"push":
			return enemy_advance_speed_factor
		_:
			return enemy_advance_speed_factor * 0.5


func _build_enemy_posture_config(tactics: Dictionary, profile: Dictionary) -> Dictionary:
	var profile_policy: String = String(profile.get("movement_posture_policy", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT))
	return {
		"movement_posture_policy": String(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_movement_posture_policy", tactics.get("movement_posture_policy", tactics.get("posture_policy_id", profile_policy)), profile_policy)),
		"ready_distance_world": _normalize_non_negative_float(tactics.get("ready_distance_world", profile.get("ready_distance_world", 640.0)), float(profile.get("ready_distance_world", 640.0))),
		"travel_speed_factor": _normalize_non_negative_float(tactics.get("travel_speed_factor", profile.get("travel_speed_factor", 0.55)), float(profile.get("travel_speed_factor", 0.55))),
		"ready_speed_factor": _normalize_non_negative_float(tactics.get("ready_speed_factor", profile.get("ready_speed_factor", 0.30)), float(profile.get("ready_speed_factor", 0.30))),
		"aim_move_speed_factor": _normalize_non_negative_float(tactics.get("aim_move_speed_factor", profile.get("aim_move_speed_factor", 0.18)), float(profile.get("aim_move_speed_factor", 0.18))),
	}


func _normalize_non_negative_float(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return maxf(float(value), 0.0)
	if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		var text: String = String(value).strip_edges()
		if text.is_valid_float():
			return maxf(text.to_float(), 0.0)
	return maxf(fallback, 0.0)


func _resolve_enemy_posture_for_unit(unit, posture_config: Dictionary, focus_position: Vector2, advance_style: String, is_moving: bool) -> Dictionary:
	var policy_id: String = String(posture_config.get("movement_posture_policy", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT)).strip_edges().to_lower()
	var movement_posture: String = ENEMY_POSTURE_TACTICAL
	var weapon_posture: String = ENEMY_WEAPON_READY
	var should_ready: bool = _enemy_ready_triggered(unit, focus_position, float(posture_config.get("ready_distance_world", 640.0)))
	match policy_id:
		"overwatch":
			movement_posture = ENEMY_POSTURE_OVERWATCH
			weapon_posture = ENEMY_WEAPON_READY
		"hold_ready":
			movement_posture = ENEMY_POSTURE_TACTICAL if is_moving else ENEMY_POSTURE_OVERWATCH
			weapon_posture = ENEMY_WEAPON_READY
		"always_ready":
			movement_posture = ENEMY_POSTURE_TACTICAL if is_moving else ENEMY_POSTURE_OVERWATCH
			weapon_posture = ENEMY_WEAPON_READY
		"aggressive_ready":
			movement_posture = ENEMY_POSTURE_TACTICAL if is_moving else ENEMY_POSTURE_OVERWATCH
			weapon_posture = ENEMY_WEAPON_READY
		_:
			if should_ready:
				movement_posture = ENEMY_POSTURE_TACTICAL if is_moving else ENEMY_POSTURE_OVERWATCH
				weapon_posture = ENEMY_WEAPON_READY
			elif is_moving:
				movement_posture = ENEMY_POSTURE_TRAVEL
				weapon_posture = ENEMY_WEAPON_LOWERED
			else:
				movement_posture = ENEMY_POSTURE_TACTICAL
				weapon_posture = ENEMY_WEAPON_READY
	if advance_style == "hold" and movement_posture == ENEMY_POSTURE_TRAVEL:
		movement_posture = ENEMY_POSTURE_OVERWATCH
		weapon_posture = ENEMY_WEAPON_READY
	return {
		"movement_posture": movement_posture,
		"weapon_posture": weapon_posture,
		"posture_policy_id": policy_id,
		"move_speed_factor": _get_enemy_posture_speed_factor(movement_posture, posture_config, advance_style),
	}


func _enemy_ready_triggered(unit, focus_position: Vector2, ready_distance_world: float) -> bool:
	if unit == null or not (unit is Node2D):
		return true
	if ready_distance_world <= 0.0:
		return true
	var unit_position: Vector2 = (unit as Node2D).global_position
	if not focus_position.is_equal_approx(Vector2.ZERO) and unit_position.distance_to(focus_position) <= ready_distance_world:
		return true
	var objective_position: Vector2 = _get_objective_position()
	if not objective_position.is_equal_approx(Vector2.ZERO) and unit_position.distance_to(objective_position) <= ready_distance_world:
		return true
	for friendly in _get_friendly_combat_units():
		if friendly == null or not (friendly is Node2D) or not _can_target_receive_attack(friendly):
			continue
		if unit_position.distance_to((friendly as Node2D).global_position) <= ready_distance_world:
			return true
	return false


func _get_enemy_posture_speed_factor(movement_posture: String, posture_config: Dictionary, advance_style: String) -> float:
	match movement_posture:
		"travel":
			return maxf(float(posture_config.get("travel_speed_factor", 0.55)), 0.0)
		"tactical":
			return maxf(float(posture_config.get("ready_speed_factor", _get_enemy_tactics_speed_factor(advance_style))), 0.0)
		"engage":
			return maxf(float(posture_config.get("aim_move_speed_factor", 0.18)), 0.0)
		"overwatch":
			return 0.0
		_:
			return _get_enemy_tactics_speed_factor(advance_style)


func _get_enemy_group_move_speed_factor(move_speed_factor_by_unit_id: Dictionary, fallback: float) -> float:
	var highest_speed_factor: float = 0.0
	for value_variant in move_speed_factor_by_unit_id.values():
		if typeof(value_variant) == TYPE_INT or typeof(value_variant) == TYPE_FLOAT:
			highest_speed_factor = maxf(highest_speed_factor, float(value_variant))
	if highest_speed_factor > 0.0:
		return highest_speed_factor
	return fallback


func _get_enemy_aim_move_speed_factor(unit) -> float:
	if unit != null and unit.has_method("get_unit_id"):
		var state: Dictionary = get_enemy_team_tactics_state_for_unit(String(unit.call("get_unit_id")))
		if not state.is_empty():
			return maxf(float(state.get("aim_move_speed_factor", 0.18)), 0.0)
	return 0.18


func _build_enemy_team_tactics_label(state: Dictionary) -> String:
	var style: String = String(state.get("advance_style", "")).strip_edges().to_lower()
	var prefix: String = "HOLD"
	match style:
		"push":
			prefix = "PUSH"
		"probe":
			prefix = "PROBE"
		"bounding":
			prefix = "BND"
		"hold":
			prefix = "HOLD"
	var moving_count: int = PackedStringArray(state.get("moving_unit_ids", PackedStringArray())).size()
	var covering_count: int = PackedStringArray(state.get("covering_unit_ids", PackedStringArray())).size()
	if covering_count > 0:
		return "%s M%d C%d" % [prefix, moving_count, covering_count]
	return "%s M%d" % [prefix, moving_count]


func _try_enqueue_enemy_team_tactics_move(simulation_root: Node, enemy) -> bool:
	if simulation_root == null or enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
		return false
	var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if unit_id.is_empty():
		return false
	var state: Dictionary = get_enemy_team_tactics_state_for_unit(unit_id)
	var decision: Dictionary = Dictionary(_enemy_behavior_orchestrator.call(
		"build_team_tactics_decision",
		enemy,
		state,
		unit_id,
		ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE,
		enemy_advance_speed_factor
	))
	if not bool(decision.get("handled", false)):
		return false
	var command: Dictionary = Dictionary(decision.get("command", {}))
	if command.is_empty():
		return true
	return _enqueue_enemy_behavior_command(simulation_root, command)


func _enqueue_enemy_posture_hold_command(simulation_root: Node, enemy, state: Dictionary, unit_id: String) -> void:
	if simulation_root == null or enemy == null or unit_id.strip_edges().is_empty():
		return
	var decision: Dictionary = Dictionary(_enemy_behavior_orchestrator.call(
		"build_team_tactics_decision",
		enemy,
		state,
		unit_id,
		ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE,
		enemy_advance_speed_factor
	))
	_enqueue_enemy_behavior_command(simulation_root, Dictionary(decision.get("command", {})))


func _build_enemy_posture_command_fields(state: Dictionary, unit_id: String) -> Dictionary:
	return Dictionary(_enemy_behavior_orchestrator.call("build_posture_command_fields", state, unit_id, enemy_advance_speed_factor))


func _build_enemy_patrol_posture_command_fields(enemy) -> Dictionary:
	var posture_config: Dictionary = {
		"movement_posture_policy": ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT,
		"ready_distance_world": 640.0,
		"travel_speed_factor": 0.55,
		"ready_speed_factor": 0.30,
		"aim_move_speed_factor": 0.18,
	}
	return _resolve_enemy_posture_for_unit(enemy, posture_config, _get_objective_position(), "probe", true)


func _build_enemy_fallback_posture_command_fields(enemy) -> Dictionary:
	var posture_config: Dictionary = {
		"movement_posture_policy": ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT,
		"ready_distance_world": 640.0,
		"travel_speed_factor": 0.55,
		"ready_speed_factor": 0.30,
		"aim_move_speed_factor": 0.18,
	}
	return _resolve_enemy_posture_for_unit(enemy, posture_config, _get_objective_position(), "push", true)


func _advance_enemy_units(simulation_root: Node) -> void:
	if not enemy_advance_enabled:
		return

	var objective_position: Vector2 = _get_objective_position()
	for enemy in _get_active_enemy_units():
		if enemy == null or not enemy.has_method("get_vital_state"):
			continue

		if String(enemy.call("get_vital_state")) != "fit":
			continue

		if _try_enqueue_enemy_team_tactics_move(simulation_root, enemy):
			continue

		if _try_enqueue_enemy_limbo_behavior(simulation_root, enemy):
			continue

		if _try_enqueue_enemy_patrol_move(simulation_root, enemy):
			continue

		if _enemy_should_hold_position(enemy):
			continue

		var posture_fields: Dictionary = _build_enemy_fallback_posture_command_fields(enemy)
		_enqueue_enemy_behavior_command(
			simulation_root,
			Dictionary(_enemy_behavior_orchestrator.call(
				"build_fallback_advance_command",
				String(enemy.call("get_unit_id")),
				objective_position,
				posture_fields,
				enemy_advance_speed_factor
			))
		)


func _initialize_enemy_patrol_paths() -> void:
	_enemy_patrol_paths_by_unit_id.clear()
	_enemy_patrol_waypoint_index_by_unit_id.clear()
	_enemy_patrol_contact_locked.clear()
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("get_patrol_path_for_unit"):
		return
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue
		var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		var patrol_path: Array = Array(enemy_wave_controller.call("get_patrol_path_for_unit", unit_id)).duplicate(true)
		if patrol_path.is_empty():
			continue
		_enemy_patrol_paths_by_unit_id[unit_id] = patrol_path
		_enemy_patrol_waypoint_index_by_unit_id[unit_id] = 0
		_enemy_patrol_contact_locked[unit_id] = false


func _try_enqueue_enemy_patrol_move(simulation_root: Node, enemy) -> bool:
	if enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
		return false
	var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if unit_id.is_empty() or not _enemy_patrol_paths_by_unit_id.has(unit_id):
		return false
	var decision: Dictionary = Dictionary(_enemy_behavior_orchestrator.call(
		"build_patrol_decision",
		enemy,
		{
			"unit_id": unit_id,
			"patrol_path": Array(_enemy_patrol_paths_by_unit_id.get(unit_id, [])),
			"waypoint_index": int(_enemy_patrol_waypoint_index_by_unit_id.get(unit_id, 0)),
			"contact_locked": bool(_enemy_patrol_contact_locked.get(unit_id, false)),
			"should_hold": _enemy_should_hold_position(enemy),
			"waypoint_reached_distance": ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE,
			"posture_fields": _build_enemy_patrol_posture_command_fields(enemy),
			"default_speed_factor": enemy_advance_speed_factor,
		}
	))
	if bool(decision.get("contact_locked", false)):
		_enemy_patrol_contact_locked[unit_id] = true
		return false
	if not bool(decision.get("handled", false)):
		return false
	_enemy_patrol_waypoint_index_by_unit_id[unit_id] = int(decision.get("waypoint_index", _enemy_patrol_waypoint_index_by_unit_id.get(unit_id, 0)))
	return _enqueue_enemy_behavior_command(simulation_root, Dictionary(decision.get("command", {})))


func _try_enqueue_enemy_limbo_behavior(simulation_root: Node, enemy) -> bool:
	if not enemy_limbo_behavior_smoke_enabled:
		return false
	if simulation_root == null or enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
		return false
	if _enemy_limbo_behavior_adapter == null or not _enemy_limbo_behavior_adapter.has_method("evaluate"):
		return false
	var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if unit_id.is_empty():
		return false
	var has_contact: bool = _enemy_should_hold_position(enemy)
	var cover_score: int = _get_enemy_limbo_cover_score(enemy)
	var context: Dictionary = {
		"unit_id": unit_id,
		"has_contact": has_contact,
		"has_patrol": _enemy_limbo_has_patrol(unit_id),
		"should_seek_cover": _enemy_limbo_should_seek_cover(enemy, has_contact, unit_id),
		"cover_score": cover_score,
		"cover_min_score": enemy_limbo_cover_min_cover_score,
		"seek_cover_action": Callable(self, "_try_enqueue_enemy_limbo_cover_move").bind(simulation_root, enemy),
		"contact_hold_action": Callable(self, "_try_enqueue_enemy_limbo_contact_hold").bind(simulation_root, enemy),
		"patrol_action": Callable(self, "_try_enqueue_enemy_patrol_move").bind(simulation_root, enemy),
	}
	var result: Dictionary = Dictionary(_enemy_limbo_behavior_adapter.call("evaluate", enemy, context, self, 1.0 / float(Engine.physics_ticks_per_second)))
	_record_enemy_limbo_behavior_decision(unit_id, enemy, context, result)
	if not bool(result.get("handled", false)):
		return false
	(enemy as Node).set_meta("enemy_limbo_behavior_action", String(result.get("selected_action", "")))
	(enemy as Node).set_meta("enemy_limbo_behavior_source", String(result.get("source", "")))
	(enemy as Node).set_meta("enemy_limbo_behavior_reason", String(result.get("reason", "")))
	return true


func _record_enemy_limbo_behavior_decision(unit_id: String, enemy, context: Dictionary, result: Dictionary) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var entry: Dictionary = {
		"unit_id": normalized_unit_id,
		"handled": bool(result.get("handled", false)),
		"selected_action": String(result.get("selected_action", "")),
		"reason": String(result.get("reason", "")),
		"status_text": String(result.get("status_text", "")),
		"source": String(result.get("source", "limboai_behavior_tree")),
		"has_contact": bool(context.get("has_contact", false)),
		"has_patrol": bool(context.get("has_patrol", false)),
		"should_seek_cover": bool(context.get("should_seek_cover", false)),
		"cover_score": int(context.get("cover_score", 0)),
		"cover_min_score": int(context.get("cover_min_score", enemy_limbo_cover_min_cover_score)),
		"last_updated_tick": _current_tick,
	}
	if enemy is Node2D:
		entry["position"] = (enemy as Node2D).global_position
	_enemy_limbo_behavior_decisions[normalized_unit_id] = entry


func _enemy_limbo_has_patrol(unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return false
	return _enemy_patrol_paths_by_unit_id.has(normalized_unit_id) and not bool(_enemy_patrol_contact_locked.get(normalized_unit_id, false))


func _enemy_limbo_should_seek_cover(enemy, has_contact: bool, unit_id: String) -> bool:
	if not has_contact or enemy == null or not (enemy is Node2D):
		return false
	var now_msec: int = Time.get_ticks_msec()
	if int(_enemy_limbo_cover_ready_at_msec.get(unit_id, 0)) > now_msec:
		return false
	if _get_enemy_limbo_cover_score(enemy) >= enemy_limbo_cover_min_cover_score:
		return false
	var terrain_registry = _get_terrain_registry()
	return terrain_registry != null and terrain_registry.has_method("get_walkable_cover_tiles_in_radius")


func _try_enqueue_enemy_limbo_cover_move(simulation_root: Node, enemy) -> bool:
	if simulation_root == null or enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
		return false
	var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if unit_id.is_empty():
		return false
	var cover_target: Vector2 = _build_enemy_limbo_cover_target(enemy)
	if cover_target == Vector2.INF:
		return false
	if not _enqueue_enemy_behavior_command(simulation_root, Dictionary(_enemy_behavior_orchestrator.call(
		"build_limbo_cover_command",
		unit_id,
		cover_target,
		enemy_reposition_move_speed_factor,
		ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.ACTION_SEEK_COVER,
		ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.REASON_SEEK_COVER
	))):
		return false
	_enemy_limbo_cover_ready_at_msec[unit_id] = Time.get_ticks_msec() + int(enemy_limbo_cover_cooldown_seconds * 1000.0)
	if _enemy_patrol_paths_by_unit_id.has(unit_id):
		_enemy_patrol_contact_locked[unit_id] = true
	return true


func _try_enqueue_enemy_limbo_contact_hold(simulation_root: Node, enemy) -> bool:
	if simulation_root == null or enemy == null or not enemy.has_method("get_unit_id"):
		return false
	var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if unit_id.is_empty() or not _enemy_should_hold_position(enemy):
		return false
	if not _enqueue_enemy_behavior_command(simulation_root, Dictionary(_enemy_behavior_orchestrator.call(
		"build_limbo_contact_hold_command",
		unit_id,
		ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.ACTION_CONTACT_HOLD,
		ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.REASON_CONTACT_HOLD
	))):
		return false
	if _enemy_patrol_paths_by_unit_id.has(unit_id):
		_enemy_patrol_contact_locked[unit_id] = true
	return true


func _build_enemy_limbo_cover_target(enemy) -> Vector2:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		return Vector2.INF
	if enemy == null or not (enemy is Node2D):
		return Vector2.INF
	var enemy_node: Node2D = enemy
	var min_dist_sq: float = enemy_limbo_cover_min_distance * enemy_limbo_cover_min_distance
	var best_position: Vector2 = Vector2.INF
	var best_score: float = -INF
	for tile in terrain_registry.call("get_walkable_cover_tiles_in_radius", enemy_node.global_position, enemy_limbo_cover_search_radius):
		if tile == null:
			continue
		var tile_position: Vector2 = Vector2(tile.world_position)
		var distance_sq: float = enemy_node.global_position.distance_squared_to(tile_position)
		if distance_sq < min_dist_sq:
			continue
		var cover_score: float = clampf(float(tile.cover_value) / 100.0, 0.0, 1.0)
		var score: float = (cover_score * 1.2) - (sqrt(distance_sq) * 0.015)
		if score <= best_score:
			continue
		best_score = score
		best_position = tile_position
	return best_position


func _get_enemy_limbo_cover_score(enemy) -> int:
	if enemy == null:
		return 0
	if enemy.has_method("get_effective_cover_score"):
		return int(enemy.call("get_effective_cover_score"))
	if enemy is Node2D:
		var terrain_registry = _get_terrain_registry()
		if terrain_registry != null and terrain_registry.has_method("get_cover_at_world"):
			return int(terrain_registry.call("get_cover_at_world", (enemy as Node2D).global_position))
	return 0


func _enemy_should_hold_position(enemy) -> bool:
	if enemy == null or not (enemy is Node2D):
		return true

	for friendly in _get_friendly_combat_units():
		if friendly == null or not _can_target_receive_attack(friendly):
			continue

		var attack_range: float = _get_weapon_attack_range(enemy, friendly)
		if not bool(_get_combat_visibility_system().call("has_line_of_sight_between_nodes", enemy, friendly, attack_range, _get_terrain_registry())):
			continue

		if (enemy as Node2D).global_position.distance_to((friendly as Node2D).global_position) <= maxf(enemy_engage_distance, attack_range):
			return true

	return false


func _pick_target_from_units(attacker, targets: Array):
	return COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("pick_target_from_units", attacker, targets, _build_fire_decision_context())


func _get_active_enemy_units() -> Array:
	if _hotpath_unit_cache_active:
		return _hotpath_enemy_units.duplicate()
	return _get_active_enemy_units_uncached()


func _get_active_enemy_units_uncached() -> Array:
	var active_units: Array = []
	var unit_registry = _get_unit_registry()
	for enemy in _get_units_uncached(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue

		if unit_registry != null and unit_registry.has_method("has_unit"):
			if not bool(unit_registry.call("has_unit", String(enemy.call("get_unit_id")))):
				continue

		active_units.append(enemy)

	return active_units


func _has_pending_friendly_insertions() -> bool:
	var tactical_controller = _get_tactical_controller()
	if tactical_controller != null and tactical_controller.has_method("has_pending_friendly_insertions"):
		return bool(tactical_controller.call("has_pending_friendly_insertions"))
	return false


func _get_unit_registry():
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("get_unit_registry"):
		return null

	return simulation_root.call("get_unit_registry")


func _get_objective_position() -> Vector2:
	var objective_status = _get_objective_status()
	if objective_status != null:
		return objective_status.position

	return Vector2.ZERO


func _try_reposition_enemy_on_damage(unit, hit_context: Dictionary) -> void:
	if not enemy_reposition_enabled:
		return

	if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"):
		return

	if String(unit.call("get_team_id")) == friendly_team_id:
		return

	if not _get_active_enemy_units().has(unit):
		return

	if String(unit.call("get_vital_state")) != "fit":
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var now_msec: int = Time.get_ticks_msec()
	if int(_enemy_reposition_ready_at_msec.get(unit_id, 0)) > now_msec:
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		return

	var reposition_target: Vector2 = _build_enemy_reposition_target(unit, hit_context)
	if not _enqueue_enemy_behavior_command(simulation_root, Dictionary(_enemy_behavior_orchestrator.call(
		"build_damage_reposition_command",
		unit_id,
		reposition_target,
		enemy_reposition_move_speed_factor,
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.MOVEMENT_POSTURE_POLICY_AGGRESSIVE_READY
	))):
		return
	_enemy_reposition_ready_at_msec[unit_id] = now_msec + int(round(enemy_reposition_cooldown_seconds * 1000.0))


func _build_enemy_reposition_target(unit, hit_context: Dictionary) -> Vector2:
	var unit_node: Node2D = unit
	var unit_id: String = String(unit.call("get_unit_id")) if unit != null and unit.has_method("get_unit_id") else ""
	var attacker_direction: Vector2 = Vector2.ZERO
	var attacker_unit_id: String = String(hit_context.get("attacker_unit_id", ""))
	var attacker = _resolve_unit_by_id(attacker_unit_id)
	if attacker != null and attacker is Node2D:
		attacker_direction = unit_node.global_position - (attacker as Node2D).global_position

	if attacker_direction.is_zero_approx():
		attacker_direction = _build_deterministic_axis("%s:%s:%d" % [unit_id, attacker_unit_id, _current_tick])

	# Try cover-seeking: find walkable cover tiles in reposition radius
	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null and terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		var cover_tiles: Array = terrain_registry.call("get_walkable_cover_tiles_in_radius", unit_node.global_position, enemy_reposition_max_distance)
		if cover_tiles.size() > 0:
			# Filter tiles that are at least min_distance away
			var min_dist_sq: float = enemy_reposition_min_distance * enemy_reposition_min_distance
			var candidates: Array = []
			for tile in cover_tiles:
				if unit_node.global_position.distance_squared_to(tile.world_position) >= min_dist_sq:
					candidates.append(tile)
			if candidates.size() > 0:
				# Sort by cover_value descending, pick best
				candidates.sort_custom(func(a, b): return int(a.cover_value) > int(b.cover_value))
				return Vector2(candidates[0].world_position)

	# Fallback: random reposition away from attacker
	var t: float = _build_deterministic_unit_interval("%s:%s:%d:reposition" % [unit_id, attacker_unit_id, _current_tick])
	var reposition_distance: float = lerpf(enemy_reposition_min_distance, enemy_reposition_max_distance, t)
	return unit_node.global_position + attacker_direction.normalized() * reposition_distance


func _build_deterministic_axis(seed_text: String) -> Vector2:
	var t: float = _build_deterministic_unit_interval(seed_text)
	return Vector2.RIGHT.rotated(t * TAU)


func _build_deterministic_unit_interval(seed_text: String) -> float:
	var hash_value: int = abs(int(seed_text.hash()))
	return float(hash_value % 10000) / 9999.0


func _enqueue_enemy_behavior_command(simulation_root: Node, command: Dictionary) -> bool:
	if simulation_root == null or command.is_empty() or not simulation_root.has_method("enqueue_command"):
		return false
	simulation_root.call("enqueue_command", command)
	return true


func _resolve_unit_by_id(unit_id: String):
	if unit_id.is_empty():
		return null

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		return null

	return unit_registry.call("get_unit", unit_id)


func _resolve_fireteam_readout_attacker(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var acting_lead_id: String = String(_fireteam_acting_leads.get(normalized_fireteam_id, "")).strip_edges()
	if not acting_lead_id.is_empty():
		var acting_lead = _resolve_unit_by_id(acting_lead_id)
		if acting_lead != null:
			return acting_lead
	for member_id_variant in Array(_fireteam_members.get(normalized_fireteam_id, [])):
		var member = _resolve_unit_by_id(String(member_id_variant).strip_edges())
		if member != null:
			return member
	for friendly in _get_friendly_combat_units():
		if friendly == null or not friendly.has_method("get_fireteam_id"):
			continue
		if String(friendly.call("get_fireteam_id")).strip_edges().to_lower() == normalized_fireteam_id:
			return friendly
	return null


func _get_enemy_wave_controller():
	if enemy_wave_controller_path.is_empty():
		return null

	return get_node_or_null(enemy_wave_controller_path)


func _get_terrain_registry():
	if not terrain_registry_path.is_empty():
		return get_node_or_null(terrain_registry_path)

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("_get_terrain_registry"):
		return null

	return simulation_root.call("_get_terrain_registry")


func _get_tactical_controller():
	if not tactical_controller_path.is_empty():
		return get_node_or_null(tactical_controller_path)
	return get_node_or_null("../TacticalController")


func _apply_friendly_standard_behavior(simulation_root: Node) -> void:
	if simulation_root == null:
		return
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("get_active_behavior_profile"):
		return
	for friendly in _get_friendly_combat_units():
		if friendly == null or not (friendly is Node2D) or not friendly.has_method("get_vital_state"):
			continue
		if String(friendly.call("get_vital_state")) != "fit":
			continue
		if not (friendly.has_method("is_in_contact") and bool(friendly.call("is_in_contact"))):
			continue
		if not friendly.has_method("get_fireteam_id") or not friendly.has_method("get_unit_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		var profile_dict: Dictionary = Dictionary(tactical_controller.call("get_active_behavior_profile", fireteam_id))
		if profile_dict.is_empty():
			continue
		var metadata: Dictionary = Dictionary(profile_dict.get("metadata", {}))
		if String(metadata.get("origin", "")) != "standard_behavior":
			continue
		if not bool(metadata.get("prefer_cover_seek", false)):
			continue
		if _extract_current_command_type(friendly) != "hold_position":
			continue
		if friendly.has_method("get_effective_cover_score") and int(friendly.call("get_effective_cover_score")) >= FRIENDLY_LOW_COVER_THRESHOLD:
			continue
		var unit_id: String = String(friendly.call("get_unit_id"))
		var now_msec: int = Time.get_ticks_msec()
		if int(_friendly_cover_ready_at_msec.get(unit_id, 0)) > now_msec:
			continue
		var cover_target: Vector2 = _build_friendly_cover_target(friendly, profile_dict)
		if cover_target == Vector2.INF:
			continue
		simulation_root.call(
			"enqueue_command",
			{
				"command_type": "move_to_position",
				"priority": 11,
				"unit_id": unit_id,
				"target_position": cover_target,
				"move_speed_factor": 0.35,
				"requeue_until_target": true,
			}
		)
		_friendly_cover_ready_at_msec[unit_id] = now_msec + FRIENDLY_STANDARD_COVER_COOLDOWN_MSEC
		if friendly.has_method("show_event_text"):
			friendly.call("show_event_text", "SEEK COVER", DEFAULT_EVENT_COLOR, 0.9)


func _try_enqueue_overwatch(simulation_root: Node) -> Array:
	if simulation_root == null or _overwatch_controller == null:
		return []
	_overwatch_controller.configure_hex_sight_adapter(get_hex_sight_adapter())
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("refresh_fireteam_security_state") or not tactical_controller.has_method("get_fireteam_security_snapshot"):
		_overwatch_controller.call("reset_all")
		return []
	if tactical_controller.has_method("refresh_fireteam_security_state_for_combat"):
		tactical_controller.call("refresh_fireteam_security_state_for_combat")
	else:
		tactical_controller.call("refresh_fireteam_security_state")
	var friendly_units_by_fireteam: Dictionary = {}
	for friendly in _get_friendly_combat_units():
		if friendly == null or not friendly.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		if not friendly_units_by_fireteam.has(fireteam_id):
			friendly_units_by_fireteam[fireteam_id] = []
		var fireteam_units: Array = Array(friendly_units_by_fireteam.get(fireteam_id, []))
		fireteam_units.append(friendly)
		friendly_units_by_fireteam[fireteam_id] = fireteam_units
	var shots: Array = Array(
		_overwatch_controller.call(
			"update",
			simulation_root,
			Array(tactical_controller.call("get_fireteam_security_snapshot")),
			friendly_units_by_fireteam,
			_get_enemy_combat_units(),
			_get_terrain_registry(),
			contact_range,
			_current_tick
		)
	)
	for shot_variant in shots:
		if typeof(shot_variant) != TYPE_DICTIONARY:
			continue
		var shot: Dictionary = Dictionary(shot_variant)
		var attacker = _resolve_unit_by_id(String(shot.get("attacker_unit_id", "")))
		var target = _resolve_unit_by_id(String(shot.get("target_unit_id", "")))
		var fire_event_id: String = _record_fire_event_from_shot(shot, attacker, target, "overwatch")
		if attacker != null and target != null:
			_set_contact_visuals(attacker, target)
			var overwatch_diagnostic: Dictionary = _build_contact_pair_decision_diagnostic(
				{
					"attacker": attacker,
					"target": target,
					"attacker_id": String(shot.get("attacker_unit_id", "")),
					"target_id": String(shot.get("target_unit_id", "")),
					"contact_state": "overwatch",
				}
			)
			overwatch_diagnostic["fire_event_id"] = fire_event_id
			_record_contact_decision_diagnostics("fired", overwatch_diagnostic)
		if not fire_event_id.is_empty():
			_refresh_tactical_combat_visuals()
		var event_text: String = "OVERWATCH %s -> %s" % [String(shot.get("attacker_unit_id", "")), String(shot.get("target_unit_id", ""))]
		_set_event_text(event_text)
		if attacker != null and attacker.has_method("show_event_text"):
			attacker.call("show_event_text", "OVERWATCH", DEFAULT_EVENT_COLOR, 1.1)
		_broadcast_remote_event(event_text, String(shot.get("attacker_unit_id", "")), DEFAULT_EVENT_COLOR, 1.1, "OVERWATCH")
	return shots


func _extract_current_command_type(unit) -> String:
	if unit == null:
		return ""
	if unit.has_method("get_current_unit_command"):
		var command = unit.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			return String(command.get("command_type"))
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			return String(runtime_status.get("active_command_type"))
	return ""


func _build_friendly_cover_target(unit, profile_dict: Dictionary) -> Vector2:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		return Vector2.INF
	if unit == null or not (unit is Node2D):
		return Vector2.INF
	var unit_node: Node2D = unit
	var min_dist_sq: float = FRIENDLY_STANDARD_COVER_MIN_DISTANCE * FRIENDLY_STANDARD_COVER_MIN_DISTANCE
	var best_position: Vector2 = Vector2.INF
	var best_score: float = -INF
	var cover_priority: float = clampf(float(profile_dict.get("cover_priority", 0.5)), 0.0, 1.0)
	for tile in terrain_registry.call("get_walkable_cover_tiles_in_radius", unit_node.global_position, FRIENDLY_STANDARD_COVER_RADIUS):
		if tile == null:
			continue
		var tile_position: Vector2 = Vector2(tile.world_position)
		var distance_sq: float = unit_node.global_position.distance_squared_to(tile_position)
		if distance_sq < min_dist_sq:
			continue
		var cover_score: float = clampf(float(tile.cover_value) / 100.0, 0.0, 1.0)
		var score: float = (cover_score * (0.6 + cover_priority)) - (sqrt(distance_sq) * 0.02)
		if score <= best_score:
			continue
		best_score = score
		best_position = tile_position
	return best_position


func get_current_fireteam_lead_unit(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges()
	if normalized_fireteam_id.is_empty():
		return null
	var acting_lead_id: String = String(_fireteam_acting_leads.get(normalized_fireteam_id, ""))
	if not acting_lead_id.is_empty():
		return _resolve_unit_by_id(acting_lead_id)
	return null


func _has_pending_enemy_waves() -> bool:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("are_all_waves_started"):
		return false

	return not bool(enemy_wave_controller.call("are_all_waves_started"))


func _has_pending_enemy_respawns() -> bool:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("has_pending_respawn"):
		return false

	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue

		var unit_id: String = String(enemy.call("get_unit_id"))
		if unit_id.is_empty():
			continue

		if bool(respawn_manager.call("has_pending_respawn", unit_id)):
			return true

	return false


func _build_wave_status_text() -> String:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null:
		return "Wave: none"

	if not enemy_wave_controller.has_method("get_current_wave_number") or not enemy_wave_controller.has_method("get_total_wave_count"):
		return "Wave: unavailable"

	return "Wave: %d/%d" % [
		int(enemy_wave_controller.call("get_current_wave_number")),
		int(enemy_wave_controller.call("get_total_wave_count")),
	]


func _on_enemy_wave_started(wave_number: int) -> void:
	_initialize_enemy_patrol_paths()
	if wave_number <= 1:
		_set_event_text("ENEMY WAVE %d" % wave_number)
		_broadcast_remote_event("ENEMY WAVE %d" % wave_number)
		return

	_set_event_text("ENEMY REINFORCEMENTS")
	_broadcast_remote_event("ENEMY REINFORCEMENTS")


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback

func reset_for_location_job(scenario_path: String) -> void:
	# Reset only job execution, never the retained world, its units or Supply.
	_combat_finished=false; _winning_team_id=""; _mission_result.clear()
	_mission_result_condition_override=""; _resolved_without_seen_friendly=false
	_has_seen_active_friendly_units=false; _mission_started_at_msec=Time.get_ticks_msec()
	configure_scenario_runtime_gates_from_file(scenario_path)
