extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const OVERWATCH_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/overwatch_controller.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const CONTACT_TRACKER_SCRIPT: GDScript = preload("res://scripts/tactical/contact_tracker.gd")
const FLANK_VULNERABILITY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/flank_vulnerability_resolver.gd")
const MEDIC_SUPPORT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/medic_support_resolver.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const TACTICAL_COMMUNICATION_EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_authority_contract.gd")
const MISSION_COMBAT_REMOTE_EVENT_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_remote_event_bridge.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const CONTACT_LINE_NAME: String = "CombatContactLine"
const EVENT_LABEL_NAME: String = "CombatEventLabel"
const WINNER_LABEL_NAME: String = "CombatWinnerLabel"
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
const DETECTION_EVENT_COLOR: Color = Color(0.85, 0.85, 0.55, 1.0)
const STEALTH_RANGE_REDUCTION_FACTOR: float = 0.5
const SPOTTED_CONTACT_HIT_CHANCE_MALUS: float = -0.15
const DISCIPLINE_BREAK_BASE_CHANCE: float = 0.08
const DISCIPLINE_BREAK_COOLDOWN_TICKS: int = 10
const DISCIPLINE_BREAK_EVENT_COLOR: Color = Color(1.0, 0.65, 0.3, 1.0)
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

const COMBAT_TICK_PHASE_BLEEDOUT_QUEUE: String = "bleedout_queue"
const COMBAT_TICK_PHASE_LEADERSHIP: String = "leadership"
const COMBAT_TICK_PHASE_DETECTION_TIMERS: String = "detection_timers"
const COMBAT_TICK_PHASE_CONTACT_TRACKING: String = "contact_tracking"
const COMBAT_TICK_PHASE_ENEMY_SECURITY: String = "enemy_security"
const COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS: String = "enemy_team_tactics"
const COMBAT_TICK_PHASE_FLANK_VULNERABILITY: String = "flank_vulnerability"
const COMBAT_TICK_PHASE_COOLDOWNS: String = "cooldowns"
const COMBAT_TICK_PHASE_MEDIC_SUPPORT: String = "medic_support"
const COMBAT_TICK_PHASE_ENEMY_ADVANCE: String = "enemy_advance"
const COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR: String = "friendly_standard_behavior"
const COMBAT_TICK_PHASE_OVERWATCH_SECURITY: String = "overwatch_security"
const COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION: String = "combat_fire_decision"
const COMBAT_TICK_PHASE_COMBAT_RESOLUTION: String = "combat_resolution"
const COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT: String = "multiplayer_snapshot_context"
const COMBAT_TICK_PHASE_STATUS_UPDATE: String = "status_update"

const COMBAT_TICK_PHASE_ORDER: Array = [
	COMBAT_TICK_PHASE_BLEEDOUT_QUEUE,
	COMBAT_TICK_PHASE_LEADERSHIP,
	COMBAT_TICK_PHASE_DETECTION_TIMERS,
	COMBAT_TICK_PHASE_CONTACT_TRACKING,
	COMBAT_TICK_PHASE_ENEMY_SECURITY,
	COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS,
	COMBAT_TICK_PHASE_FLANK_VULNERABILITY,
	COMBAT_TICK_PHASE_COOLDOWNS,
	COMBAT_TICK_PHASE_MEDIC_SUPPORT,
	COMBAT_TICK_PHASE_ENEMY_ADVANCE,
	COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR,
	COMBAT_TICK_PHASE_OVERWATCH_SECURITY,
	COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION,
	COMBAT_TICK_PHASE_COMBAT_RESOLUTION,
	COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT,
	COMBAT_TICK_PHASE_STATUS_UPDATE,
]
const COMBAT_TICK_PHASE_SCOPE_KEYS: Dictionary = {
	COMBAT_TICK_PHASE_BLEEDOUT_QUEUE: "bleedout_queue_usec",
	COMBAT_TICK_PHASE_LEADERSHIP: "leadership_usec",
	COMBAT_TICK_PHASE_DETECTION_TIMERS: "detection_timers_usec",
	COMBAT_TICK_PHASE_CONTACT_TRACKING: "contact_tracking_usec",
	COMBAT_TICK_PHASE_ENEMY_SECURITY: "enemy_security_usec",
	COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS: "enemy_team_tactics_usec",
	COMBAT_TICK_PHASE_FLANK_VULNERABILITY: "flank_vulnerability_usec",
	COMBAT_TICK_PHASE_COOLDOWNS: "cooldowns_usec",
	COMBAT_TICK_PHASE_MEDIC_SUPPORT: "medic_support_usec",
	COMBAT_TICK_PHASE_ENEMY_ADVANCE: "enemy_advance_usec",
	COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR: "friendly_standard_behavior_usec",
	COMBAT_TICK_PHASE_OVERWATCH_SECURITY: "overwatch_security_usec",
	COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION: "combat_fire_decision_usec",
	COMBAT_TICK_PHASE_COMBAT_RESOLUTION: "combat_resolution_usec",
	COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT: "multiplayer_snapshot_context_usec",
	COMBAT_TICK_PHASE_STATUS_UPDATE: "status_update_usec",
}
const COMBAT_TICK_PHASE_LABELS: Dictionary = {
	COMBAT_TICK_PHASE_BLEEDOUT_QUEUE: "Queue bleedout effects",
	COMBAT_TICK_PHASE_LEADERSHIP: "Refresh fireteam leadership",
	COMBAT_TICK_PHASE_DETECTION_TIMERS: "Advance detection timers",
	COMBAT_TICK_PHASE_CONTACT_TRACKING: "Update contact tracking",
	COMBAT_TICK_PHASE_ENEMY_SECURITY: "Update enemy security",
	COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS: "Update enemy team tactics",
	COMBAT_TICK_PHASE_FLANK_VULNERABILITY: "Advance flank vulnerability",
	COMBAT_TICK_PHASE_COOLDOWNS: "Advance combat cooldowns",
	COMBAT_TICK_PHASE_MEDIC_SUPPORT: "Try medic support",
	COMBAT_TICK_PHASE_ENEMY_ADVANCE: "Advance enemy units",
	COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR: "Apply friendly standard behavior",
	COMBAT_TICK_PHASE_OVERWATCH_SECURITY: "Resolve overwatch security",
	COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION: "Resolve combat fire decisions",
	COMBAT_TICK_PHASE_COMBAT_RESOLUTION: "Update combat resolution",
	COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT: "Publish multiplayer snapshot context",
	COMBAT_TICK_PHASE_STATUS_UPDATE: "Update status label",
}
const COMBAT_TICK_PHASE_DEPENDENCIES: Dictionary = {
	COMBAT_TICK_PHASE_CONTACT_TRACKING: [COMBAT_TICK_PHASE_DETECTION_TIMERS],
	COMBAT_TICK_PHASE_ENEMY_SECURITY: [COMBAT_TICK_PHASE_CONTACT_TRACKING],
	COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS: [COMBAT_TICK_PHASE_ENEMY_SECURITY],
	COMBAT_TICK_PHASE_FLANK_VULNERABILITY: [COMBAT_TICK_PHASE_CONTACT_TRACKING],
	COMBAT_TICK_PHASE_MEDIC_SUPPORT: [COMBAT_TICK_PHASE_COOLDOWNS],
	COMBAT_TICK_PHASE_ENEMY_ADVANCE: [COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS],
	COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR: [COMBAT_TICK_PHASE_LEADERSHIP],
	COMBAT_TICK_PHASE_OVERWATCH_SECURITY: [COMBAT_TICK_PHASE_CONTACT_TRACKING],
	COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION: [COMBAT_TICK_PHASE_OVERWATCH_SECURITY],
	COMBAT_TICK_PHASE_COMBAT_RESOLUTION: [COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION],
	COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT: [COMBAT_TICK_PHASE_COMBAT_RESOLUTION],
	COMBAT_TICK_PHASE_STATUS_UPDATE: [COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT],
}
const COMBAT_TICK_PHASE_BUDGET_CANDIDATE_NOTES: Dictionary = {
	COMBAT_TICK_PHASE_ENEMY_SECURITY: "Review for every-N-ticks only after contact staleness is proven acceptable.",
	COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS: "Review for every-N-ticks after enemy reaction cadence is playtested.",
	COMBAT_TICK_PHASE_FLANK_VULNERABILITY: "Review for dirty/contact-change gating; not changed in TASK_336.",
	COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR: "Review for dirty behavior-profile gating; not changed in TASK_336.",
	COMBAT_TICK_PHASE_STATUS_UPDATE: "Low-risk UI label candidate, but kept per tick for unchanged feedback.",
}

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
@export var tactical_controller_path: NodePath
@export var preview_mode: bool = false
@export var combat_tick_budget_debug_enabled: bool = false

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _queued_bleedout_by_unit_id: Dictionary = {}
var _enemy_reposition_ready_at_msec: Dictionary = {}
var _combat_finished: bool = false
var _winning_team_id: String = ""
var _last_contact: Dictionary = {}
var _current_tick: int = 0
var _next_attack_tick: int = 1
var _last_event_text: String = "Combat waiting"
var _contact_line: Line2D = null
var _event_label: Label = null
var _winner_label: Label = null
var _mission_started_at_msec: int = 0
var _objective_owned_since_msec: int = -1
var _mission_result: Dictionary = {}
var _mission_result_condition_override: String = ""
var _runs_local_authority: bool = true
var _fireteam_original_leads: Dictionary = {}
var _fireteam_acting_leads: Dictionary = {}
var _fireteam_members: Dictionary = {}
var _detection_progress: Dictionary = {}
var _discipline_break_cooldown: Dictionary = {}
var _misidentification_cooldown: Dictionary = {}
var _medic_support_cooldown: Dictionary = {}
var _medic_support_move_ready_tick: Dictionary = {}
var _friendly_cover_ready_at_msec: Dictionary = {}
var _overlays_visible: bool = true
var _enemy_patrol_paths_by_unit_id: Dictionary = {}
var _enemy_patrol_waypoint_index_by_unit_id: Dictionary = {}
var _enemy_patrol_contact_locked: Dictionary = {}
var _enemy_security_states_by_group_id: Dictionary = {}
var _enemy_team_tactics_states_by_group_id: Dictionary = {}
var _recent_fire_events: Array = []
var _next_fire_event_sequence: int = 1
var _combat_tick_budget_debug_snapshot: Dictionary = {}
var _overwatch_controller = OVERWATCH_CONTROLLER_SCRIPT.new()
var _contact_tracker = CONTACT_TRACKER_SCRIPT.new()
var _flank_vulnerability_resolver = FLANK_VULNERABILITY_RESOLVER_SCRIPT.new()
var _remote_event_bridge = MISSION_COMBAT_REMOTE_EVENT_BRIDGE_SCRIPT.new()
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

	if _runs_local_authority and not simulation_root.tick_processed.is_connected(_on_tick_processed):
		simulation_root.tick_processed.connect(_on_tick_processed)

	_update_status_label("waiting" if _runs_local_authority else "observing")


func is_combat_finished() -> bool:
	return _combat_finished


func get_winning_team_id() -> String:
	return _winning_team_id


func get_last_contact() -> Dictionary:
	return _last_contact.duplicate(true)


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


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
	}
	return Dictionary(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("build_playability_snapshot", base_snapshot, _get_objective_status(), _mission_result))


func get_authority_contract_snapshot() -> Dictionary:
	return Dictionary(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("get_contract_snapshot")).duplicate(true)


func set_combat_tick_budget_debug_enabled(enabled: bool) -> void:
	combat_tick_budget_debug_enabled = enabled
	if not combat_tick_budget_debug_enabled:
		_combat_tick_budget_debug_snapshot.clear()


func get_combat_tick_budget_debug_snapshot() -> Dictionary:
	return _combat_tick_budget_debug_snapshot.duplicate(true)


func get_combat_tick_phase_catalog() -> Array:
	var catalog: Array = []
	for phase_id_variant in COMBAT_TICK_PHASE_ORDER:
		catalog.append(_build_combat_tick_phase_definition(String(phase_id_variant)))
	return catalog


func get_combat_tick_phase_inventory_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"phase_order": COMBAT_TICK_PHASE_ORDER.duplicate(),
		"phase_catalog": get_combat_tick_phase_catalog(),
		"budget_candidate_phase_ids": _get_combat_tick_budget_candidate_phase_ids(),
		"authority_root": "SimulationRoot",
		"rules_rebalanced": false,
	}


func get_combat_hotpath_audit_snapshot() -> Dictionary:
	return {
		"authority_root": "SimulationRoot",
		"combat_driver_role": "authoritative_tick_subscriber",
		"unit_sources": "configured_unit_paths_with_unit_registry_active_filter",
		"scene_tree_lookup_policy": "direct_NodePath_or_registry_lookup_only",
		"client_viewer_paths_read_only": true,
		"snapshot_publication": "SimulationRoot.set_multiplayer_snapshot_context",
	}


func get_contact_snapshot() -> Array:
	if _contact_tracker == null:
		return []
	return Array(_contact_tracker.call("get_contact_snapshot")).duplicate(true)


func get_unit_presence_audit_snapshot() -> Dictionary:
	var active_friendly_units: Array = _get_units(friendly_unit_paths)
	var active_enemy_units: Array = _get_active_enemy_units()
	var all_enemy_units: Array = _get_units_for_presence_audit(enemy_unit_paths)
	var active_enemy_ids: Array = _extract_presence_audit_unit_ids(active_enemy_units)
	return {
		"active_friendly_unit_ids": _extract_presence_audit_unit_ids(active_friendly_units),
		"active_enemy_unit_ids": active_enemy_ids,
		"inactive_enemy_unit_ids": _extract_inactive_presence_audit_unit_ids(all_enemy_units, active_enemy_ids),
		"current_wave_number": _get_enemy_wave_number("get_current_wave_number"),
		"total_wave_count": _get_enemy_wave_number("get_total_wave_count"),
		"all_waves_started": _enemy_waves_all_started(),
	}


func get_fireteam_contact_snapshot(fireteam_id: String) -> Array:
	if _contact_tracker == null:
		return []
	return Array(_contact_tracker.call("get_fireteam_contacts", fireteam_id)).duplicate(true)


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
			"mission_result": get_mission_result(),
		}
	)


func get_flank_vulnerability_snapshot() -> Array:
	if _flank_vulnerability_resolver == null:
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


func get_fire_event_snapshot() -> Array:
	var result: Array = []
	for event_variant in _recent_fire_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		result.append(Dictionary(event_variant).duplicate(true))
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
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": source,
		"tick": _current_tick,
		"sequence": sequence,
		"attacker_unit_id": attacker_unit_id,
		"attacker_team_id": attacker_team_id,
		"target_unit_id": target_unit_id,
		"target_team_id": target_team_id,
		"weapon_id": weapon_id,
		"weapon_tile_range": weapon_tile_range,
		"weapon_range_world": weapon_range_world,
		"attacker_position": _get_unit_world_position(attacker),
		"target_position": _get_unit_world_position(target),
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
	for event_variant in _recent_fire_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		if _current_tick - int(event.get("tick", _current_tick)) <= 4:
			retained.append(event)
	_recent_fire_events = retained


func _get_unit_world_position(unit) -> Vector2:
	if unit is Node2D:
		return (unit as Node2D).global_position
	return Vector2.ZERO


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
	if _flank_vulnerability_resolver == null:
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


func _build_combat_tick_phase_definition(phase_id: String) -> Dictionary:
	var budget_candidate_note: String = String(COMBAT_TICK_PHASE_BUDGET_CANDIDATE_NOTES.get(phase_id, ""))
	return {
		"phase_id": phase_id,
		"order_index": COMBAT_TICK_PHASE_ORDER.find(phase_id),
		"scope_key": _get_combat_tick_phase_scope_key(phase_id),
		"label": String(COMBAT_TICK_PHASE_LABELS.get(phase_id, phase_id)),
		"hard_dependencies": Array(COMBAT_TICK_PHASE_DEPENDENCIES.get(phase_id, [])).duplicate(),
		"every_n_ticks_candidate": not budget_candidate_note.is_empty(),
		"budget_candidate_note": budget_candidate_note,
	}


func _get_combat_tick_phase_scope_key(phase_id: String) -> String:
	return String(COMBAT_TICK_PHASE_SCOPE_KEYS.get(phase_id, ""))


func _get_combat_tick_budget_candidate_phase_ids() -> Array:
	var result: Array = []
	for phase_id_variant in COMBAT_TICK_PHASE_ORDER:
		var phase_id: String = String(phase_id_variant)
		if COMBAT_TICK_PHASE_BUDGET_CANDIDATE_NOTES.has(phase_id):
			result.append(phase_id)
	return result


func _build_combat_tick_phase_record(phase_id: String, duration_usec: int, result: Dictionary, simulation_root: Node, skipped: bool, skip_reason: String) -> Dictionary:
	var counters: Dictionary = _build_combat_tick_phase_counters(phase_id, simulation_root, result)
	var record: Dictionary = _build_combat_tick_phase_definition(phase_id)
	record["duration_usec"] = duration_usec
	record["skipped"] = skipped
	record["skip_reason"] = skip_reason
	record["counters"] = counters
	return record


func _build_combat_tick_phase_counters(phase_id: String, simulation_root: Node, result: Dictionary) -> Dictionary:
	var counters: Dictionary = {}
	match phase_id:
		COMBAT_TICK_PHASE_BLEEDOUT_QUEUE:
			counters["queued_bleedout_count"] = _queued_bleedout_by_unit_id.size()
			counters["effect_queue_after_phase"] = _get_effect_queue_size(simulation_root)
		COMBAT_TICK_PHASE_LEADERSHIP:
			counters["fireteam_count"] = _fireteam_members.size()
			counters["acting_lead_count"] = _fireteam_acting_leads.size()
		COMBAT_TICK_PHASE_DETECTION_TIMERS:
			counters["detection_progress_count"] = _detection_progress.size()
		COMBAT_TICK_PHASE_CONTACT_TRACKING:
			counters["contact_count"] = get_contact_snapshot().size()
		COMBAT_TICK_PHASE_ENEMY_SECURITY:
			counters["enemy_security_group_count"] = _enemy_security_states_by_group_id.size()
		COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS:
			counters["enemy_team_tactics_group_count"] = _enemy_team_tactics_states_by_group_id.size()
		COMBAT_TICK_PHASE_FLANK_VULNERABILITY:
			counters["flank_state_count"] = _flank_vulnerability_resolver.call("get_state_snapshot", _current_tick).size() if _flank_vulnerability_resolver != null else 0
		COMBAT_TICK_PHASE_COOLDOWNS:
			counters["discipline_cooldown_count"] = _discipline_break_cooldown.size()
			counters["misidentification_cooldown_count"] = _misidentification_cooldown.size()
			counters["medic_support_cooldown_count"] = _medic_support_cooldown.size()
		COMBAT_TICK_PHASE_MEDIC_SUPPORT:
			counters["medic_move_ready_count"] = _medic_support_move_ready_tick.size()
			counters["command_queue_after_phase"] = _get_command_queue_size(simulation_root)
		COMBAT_TICK_PHASE_ENEMY_ADVANCE:
			counters["active_enemy_unit_count"] = _get_active_enemy_units().size()
			counters["command_queue_after_phase"] = _get_command_queue_size(simulation_root)
		COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR:
			counters["friendly_unit_count"] = _get_units(friendly_unit_paths).size()
			counters["command_queue_after_phase"] = _get_command_queue_size(simulation_root)
		COMBAT_TICK_PHASE_OVERWATCH_SECURITY:
			counters["overwatch_shot_count"] = int(result.get("overwatch_shot_count", 0))
			counters["command_queue_after_phase"] = _get_command_queue_size(simulation_root)
		COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION:
			counters["recent_fire_event_count"] = _recent_fire_events.size()
			counters["command_queue_after_phase"] = _get_command_queue_size(simulation_root)
		COMBAT_TICK_PHASE_COMBAT_RESOLUTION:
			counters["combat_finished"] = _combat_finished
		COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT:
			counters["recent_fire_event_count"] = _recent_fire_events.size()
		COMBAT_TICK_PHASE_STATUS_UPDATE:
			counters["combat_finished"] = _combat_finished
	return counters


func _get_command_queue_size(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var command_queue_variant: Variant = simulation_root.get("command_queue")
	return (command_queue_variant as Array).size() if command_queue_variant is Array else 0


func _get_effect_queue_size(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var effect_queue_variant: Variant = simulation_root.get("effects_queue")
	return (effect_queue_variant as Array).size() if effect_queue_variant is Array else 0


func _on_tick_processed(tick: int) -> void:
	_current_tick = tick
	var simulation_root = get_node_or_null(simulation_root_path)
	var profile_enabled: bool = combat_tick_budget_debug_enabled
	var tick_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var profile_scopes: Dictionary = {}
	var phase_records: Array = []
	if _combat_finished:
		_update_status_label("resolved")
		_run_profiled_combat_tick_phase(COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT, simulation_root, profile_enabled, profile_scopes, phase_records)
		if profile_enabled:
			_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, phase_records, simulation_root, "resolved")
		return

	if simulation_root == null:
		if profile_enabled:
			_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, phase_records, simulation_root, "missing_simulation_root")
		return

	_run_core_combat_tick_phases(simulation_root, profile_enabled, profile_scopes, phase_records)
	if profile_enabled:
		_record_combat_tick_budget_debug_snapshot(tick, tick_started_usec, profile_scopes, phase_records, simulation_root, "active")


func _run_core_combat_tick_phases(simulation_root: Node, profile_enabled: bool, profile_scopes: Dictionary, phase_records: Array) -> void:
	var overwatch_shot_count: int = 0
	for phase_id_variant in COMBAT_TICK_PHASE_ORDER:
		var phase_id: String = String(phase_id_variant)
		if phase_id == COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION and overwatch_shot_count > 0:
			_record_skipped_combat_tick_phase(phase_id, "overwatch_fired", profile_enabled, profile_scopes, phase_records)
			continue
		if phase_id == COMBAT_TICK_PHASE_STATUS_UPDATE and _combat_finished:
			_record_skipped_combat_tick_phase(phase_id, "combat_resolved", profile_enabled, profile_scopes, phase_records)
			continue
		var result: Dictionary = _run_profiled_combat_tick_phase(phase_id, simulation_root, profile_enabled, profile_scopes, phase_records)
		if phase_id == COMBAT_TICK_PHASE_OVERWATCH_SECURITY:
			overwatch_shot_count = int(result.get("overwatch_shot_count", 0))


func _run_profiled_combat_tick_phase(phase_id: String, simulation_root: Node, profile_enabled: bool, profile_scopes: Dictionary, phase_records: Array) -> Dictionary:
	var started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var result: Dictionary = _execute_combat_tick_phase(phase_id, simulation_root)
	if not profile_enabled:
		return result
	var duration_usec: int = Time.get_ticks_usec() - started_usec
	var scope_key: String = _get_combat_tick_phase_scope_key(phase_id)
	if not scope_key.is_empty():
		profile_scopes[scope_key] = duration_usec
	phase_records.append(_build_combat_tick_phase_record(phase_id, duration_usec, result, simulation_root, false, ""))
	return result


func _record_skipped_combat_tick_phase(phase_id: String, skip_reason: String, profile_enabled: bool, profile_scopes: Dictionary, phase_records: Array) -> void:
	if not profile_enabled:
		return
	var scope_key: String = _get_combat_tick_phase_scope_key(phase_id)
	if not scope_key.is_empty():
		profile_scopes[scope_key] = 0
	phase_records.append(_build_combat_tick_phase_record(phase_id, 0, {}, null, true, skip_reason))


func _execute_combat_tick_phase(phase_id: String, simulation_root: Node) -> Dictionary:
	match phase_id:
		COMBAT_TICK_PHASE_BLEEDOUT_QUEUE:
			_queue_bleedout_for_downed_enemy(simulation_root)
			_queue_bleedout_for_downed_friendly(simulation_root)
		COMBAT_TICK_PHASE_LEADERSHIP:
			_update_fireteam_leadership()
		COMBAT_TICK_PHASE_DETECTION_TIMERS:
			_advance_detection_timers()
		COMBAT_TICK_PHASE_CONTACT_TRACKING:
			_update_contact_tracking()
		COMBAT_TICK_PHASE_ENEMY_SECURITY:
			_update_enemy_security_state()
		COMBAT_TICK_PHASE_ENEMY_TEAM_TACTICS:
			_update_enemy_team_tactics_state()
		COMBAT_TICK_PHASE_FLANK_VULNERABILITY:
			_advance_flank_vulnerability_state()
		COMBAT_TICK_PHASE_COOLDOWNS:
			_advance_discipline_cooldowns()
			_advance_misidentification_cooldowns()
			_advance_medic_support_cooldowns()
		COMBAT_TICK_PHASE_MEDIC_SUPPORT:
			_try_enqueue_medic_support(simulation_root)
		COMBAT_TICK_PHASE_ENEMY_ADVANCE:
			_advance_enemy_units(simulation_root)
		COMBAT_TICK_PHASE_FRIENDLY_STANDARD_BEHAVIOR:
			_apply_friendly_standard_behavior(simulation_root)
		COMBAT_TICK_PHASE_OVERWATCH_SECURITY:
			var overwatch_shots: Array = _try_enqueue_overwatch(simulation_root)
			return {"overwatch_shot_count": overwatch_shots.size()}
		COMBAT_TICK_PHASE_COMBAT_FIRE_DECISION:
			_try_enqueue_attacks(simulation_root)
		COMBAT_TICK_PHASE_COMBAT_RESOLUTION:
			_update_combat_resolution()
		COMBAT_TICK_PHASE_MULTIPLAYER_SNAPSHOT_CONTEXT:
			_publish_multiplayer_snapshot_context(simulation_root)
		COMBAT_TICK_PHASE_STATUS_UPDATE:
			_update_status_label("active")
	return {}


func _record_combat_tick_budget_debug_snapshot(tick: int, tick_started_usec: int, profile_scopes: Dictionary, phase_records: Array, simulation_root: Node, state: String) -> void:
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
		"tick": tick,
		"state": state,
		"total_tick_usec": Time.get_ticks_usec() - tick_started_usec,
		"scopes_usec": profile_scopes.duplicate(true),
		"phase_order": COMBAT_TICK_PHASE_ORDER.duplicate(),
		"phase_records": phase_records.duplicate(true),
		"phase_catalog": get_combat_tick_phase_catalog(),
		"budget_candidate_phase_ids": _get_combat_tick_budget_candidate_phase_ids(),
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
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_vital_state") or not enemy.has_method("get_unit_id"):
			continue

		var unit_id: String = String(enemy.call("get_unit_id"))
		if unit_id.is_empty() or _queued_bleedout_by_unit_id.get(unit_id, false):
			continue

		if String(enemy.call("get_vital_state")) != "down":
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


func _queue_bleedout_for_downed_friendly(simulation_root: Node) -> void:
	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not friendly.has_method("get_vital_state") or not friendly.has_method("get_unit_id"):
			continue

		var unit_id: String = String(friendly.call("get_unit_id"))
		if unit_id.is_empty() or _queued_bleedout_by_unit_id.get(unit_id, false):
			continue

		if String(friendly.call("get_vital_state")) != "down":
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


func _request_respawn_for_unit(unit, unit_id: String) -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("request_respawn"):
		return

	var unit_team_id: String = ""
	if unit.has_method("get_team_id"):
		unit_team_id = String(unit.call("get_team_id"))

	if unit_team_id.is_empty():
		return

	respawn_manager.call("request_respawn", unit_id, unit_team_id)


func _try_enqueue_attacks(simulation_root: Node) -> void:
	var contact_pair: Dictionary = _find_first_contact_pair()
	if contact_pair.is_empty():
		_clear_contact_visuals()
		return

	var attacker = contact_pair["attacker"]
	var target = contact_pair["target"]
	var attacker_id: String = String(contact_pair["attacker_id"])
	var target_id: String = String(contact_pair["target_id"])
	var contact_state: String = String(contact_pair.get("contact_state", "")).strip_edges().to_lower()
	if attacker_id.is_empty() or target_id.is_empty():
		_clear_contact_visuals()
		return

	_last_contact = {
		"attacker_id": attacker_id,
		"target_id": target_id,
	}
	_set_contact_visuals(attacker, target)
	_update_status_label("contact")
	if _current_tick < _next_attack_tick:
		return

	var decision: Dictionary = COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("build_damage_effect", contact_pair, _build_fire_decision_context())
	if decision.is_empty():
		return
	var actual_target = decision.get("target", target)
	var actual_target_id: String = String(decision.get("target_id", target_id))
	var is_friendly_fire: bool = bool(decision.get("is_friendly_fire", false))

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
		damage_effect["fire_event_id"] = fire_event_id
	simulation_root.call("enqueue_effect", damage_effect)
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


func _update_combat_resolution() -> void:
	if _combat_finished:
		return

	if mission_time_limit_seconds > 0.0 and _get_duration_seconds() >= mission_time_limit_seconds:
		_resolve_combat("defeat", _get_enemy_team_id(), "time_limit")
		return

	if _is_victory_condition_met():
		_resolve_combat("victory", friendly_team_id)
		return

	if _count_fit_units(friendly_unit_paths) > 0:
		return

	if _has_pending_friendly_insertions():
		return

	_resolve_combat("defeat", _get_enemy_team_id())


func _get_units(paths: Array[NodePath]) -> Array:
	var units: Array = []
	var unit_registry = get_node_or_null("../UnitRegistry")
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			if unit_registry != null and unit.has_method("get_unit_id") and unit_registry.has_method("has_unit"):
				var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
				if unit_id.is_empty() or not bool(unit_registry.call("has_unit", unit_id)):
					continue
			units.append(unit)

	return units


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


func _get_detection_delay_ticks(unit) -> int:
	var unit_awareness: float = 0.5
	if unit != null and unit.has_method("get_awareness"):
		unit_awareness = clampf(float(unit.call("get_awareness")), 0.0, 1.0)

	return int(round((1.0 - unit_awareness) * float(MAX_DETECTION_DELAY_TICKS)))


func _make_detection_key(attacker_id: String, target_id: String) -> String:
	return "%s:%s" % [attacker_id, target_id]


func _is_detection_complete(attacker_id: String, target_id: String) -> bool:
	var key: String = _make_detection_key(attacker_id, target_id)
	return _detection_progress.has(key) and int(_detection_progress[key]) <= 0


func _start_or_continue_detection(attacker, attacker_id: String, target_id: String) -> void:
	var key: String = _make_detection_key(attacker_id, target_id)
	if _detection_progress.has(key):
		return

	var delay: int = _get_detection_delay_ticks(attacker)
	_detection_progress[key] = delay
	if delay > 0 and attacker != null and attacker.has_method("show_event_text"):
		attacker.call("show_event_text", "DETECTING...", DETECTION_EVENT_COLOR, 0.8)


func _advance_detection_timers() -> void:
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
	for friendly in _get_units(friendly_unit_paths):
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

	return _los_system.has_line_of_sight_between_nodes(attacker, target, _get_effective_range(target), _get_terrain_registry())


func _update_contact_tracking() -> void:
	if _contact_tracker == null:
		return
	var contact_observations: Array = []
	var active_enemies: Array = _get_active_enemy_units()
	for friendly in _get_units(friendly_unit_paths):
		if not _can_target_receive_attack(friendly):
			continue
		if friendly == null or not friendly.has_method("get_fireteam_id") or not friendly.has_method("get_unit_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		var attacker_id: String = String(friendly.call("get_unit_id")).strip_edges()
		if fireteam_id.is_empty() or attacker_id.is_empty():
			continue
		for enemy in active_enemies:
			if not _has_valid_los(friendly, enemy):
				continue
			var enemy_unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
			if enemy_unit_id.is_empty():
				continue
			_start_or_continue_detection(friendly, attacker_id, enemy_unit_id)
			contact_observations.append({
				"fireteam_id": fireteam_id,
				"unit_id": enemy_unit_id,
				"team_id": String(enemy.call("get_team_id")) if enemy.has_method("get_team_id") else "",
				"last_known_position": (enemy as Node2D).global_position if enemy is Node2D else Vector2.ZERO,
				"detection_complete": _is_detection_complete(attacker_id, enemy_unit_id),
			})
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


func _advance_flank_vulnerability_state() -> void:
	if _flank_vulnerability_resolver == null:
		return
	var did_change: bool = bool(_flank_vulnerability_resolver.call("advance", _current_tick))
	if not did_change:
		return
	var tactical_controller = _get_tactical_controller()
	if tactical_controller != null and tactical_controller.has_method("refresh_flank_vulnerability_state"):
		tactical_controller.call("refresh_flank_vulnerability_state")


func get_detection_progress() -> Dictionary:
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
	if status_label == null:
		return
	if preview_mode:
		status_label.set("visible", false)
		return

	status_label.set("visible", _overlays_visible)
	status_label.set("text", _build_status_text(state_name))


func _build_status_text(state_name: String) -> String:
	var lines: PackedStringArray = []
	lines.append("Combat: %s" % state_name)
	lines.append("Win condition: %s" % win_condition)

	if _combat_finished and not _winning_team_id.is_empty():
		lines.append("Winner: %s" % _winning_team_id)

	lines.append("Enemies fit: %d" % _count_fit_enemy_units())
	lines.append("Friendlies fit: %d" % _count_fit_units(friendly_unit_paths))
	lines.append("Duration: %.1fs" % _get_duration_seconds())
	lines.append(_build_objective_status_text())
	lines.append(_build_wave_status_text())

	if win_condition == WIN_CONDITION_OBJECTIVE_DEFENSE and _objective_owned_since_msec >= 0 and not _combat_finished:
		lines.append("Hold timer: %.1fs / %.1fs" % [_get_objective_defense_elapsed_seconds(), objective_defense_hold_seconds])

	lines.append("Next shot: %s" % _build_attack_readiness_text())
	lines.append("Last event: %s" % _last_event_text)

	if not _last_contact.is_empty():
		lines.append("Last contact: %s -> %s" % [String(_last_contact.get("attacker_id", "")), String(_last_contact.get("target_id", ""))])

	return "\n".join(lines)


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


func _find_first_contact_pair() -> Dictionary:
	return Dictionary(
		COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call(
			"find_first_contact_pair",
			_build_fire_decision_context(
				{
					"friendly_units": _get_units(friendly_unit_paths),
					"enemy_units": _get_active_enemy_units(),
				}
			)
		)
	).duplicate(true)


func resolve_flank_attack(attacker, target) -> Dictionary:
	if attacker == null or target == null:
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
	if _flank_vulnerability_resolver == null or fireteam_id.strip_edges().is_empty():
		return {}
	var result: Dictionary = Dictionary(_flank_vulnerability_resolver.call("resolve_attack", fireteam_id, attacker, target, security_state, _current_tick)).duplicate(true)
	if result.is_empty():
		return {}
	var tactical_controller = _get_tactical_controller()
	if tactical_controller != null and tactical_controller.has_method("refresh_flank_vulnerability_state"):
		tactical_controller.call("refresh_flank_vulnerability_state")
	return result


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
		"los_system": _los_system,
		"terrain_registry": _get_terrain_registry(),
		"check_discipline_break": Callable(self, "_check_discipline_break"),
		"start_detection": Callable(self, "_start_or_continue_detection"),
		"is_detection_complete": Callable(self, "_is_detection_complete"),
		"get_contact_state": Callable(self, "_get_fireteam_contact_state"),
		"check_misidentification": Callable(self, "_check_misidentification"),
		"resolve_flank_attack": Callable(self, "resolve_flank_attack"),
		"get_effective_range": Callable(self, "_get_effective_range"),
		"get_weapon_attack_range": Callable(self, "_get_weapon_attack_range"),
		"get_attack_area_context": Callable(self, "_get_attack_area_context_for_fireteam"),
	}
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
	for enemy in _get_active_enemy_units():
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
	if preview_mode:
		return
	var scene_root = get_parent()
	if scene_root == null:
		return

	_contact_line = scene_root.get_node_or_null(CONTACT_LINE_NAME) as Line2D
	if _contact_line == null:
		_contact_line = Line2D.new()
		_contact_line.name = CONTACT_LINE_NAME
		_contact_line.default_color = Color(1.0, 0.92, 0.35, 0.9)
		_contact_line.width = 2.0
		_contact_line.z_index = 20
		scene_root.add_child(_contact_line)

	_event_label = scene_root.get_node_or_null(EVENT_LABEL_NAME) as Label
	if _event_label == null:
		_event_label = Label.new()
		_event_label.name = EVENT_LABEL_NAME
		_event_label.top_level = true
		_event_label.position = Vector2(16.0, 220.0)
		_event_label.add_theme_font_size_override("font_size", 14)
		_event_label.add_theme_constant_override("outline_size", 2)
		_event_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_event_label)

	_winner_label = scene_root.get_node_or_null(WINNER_LABEL_NAME) as Label
	if _winner_label == null:
		_winner_label = Label.new()
		_winner_label.name = WINNER_LABEL_NAME
		_winner_label.top_level = true
		_winner_label.position = Vector2(280.0, 16.0)
		_winner_label.add_theme_font_size_override("font_size", 20)
		_winner_label.add_theme_constant_override("outline_size", 3)
		_winner_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_winner_label)


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
	_set_event_text("%s RESPAWN READY" % unit_id)
	_broadcast_remote_event("%s RESPAWN READY" % unit_id, unit_id, RESPAWN_EVENT_COLOR, 1.6, "RESPAWN READY")


func _set_contact_visuals(attacker, target) -> void:
	_clear_unit_contact_states()
	if attacker == null or target == null:
		if _contact_line != null:
			_contact_line.clear_points()
		return

	if _contact_line != null:
		_contact_line.clear_points()
		_contact_line.add_point(attacker.position)
		_contact_line.add_point(target.position)

	if attacker.has_method("set_contact_state"):
		attacker.call("set_contact_state", true, String(target.call("get_unit_id")))

	if target.has_method("set_contact_state"):
		target.call("set_contact_state", true, String(attacker.call("get_unit_id")))


func _clear_contact_visuals() -> void:
	_clear_unit_contact_states()
	if _contact_line != null:
		_contact_line.clear_points()


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
	match vital_state:
		"down":
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
	if _event_label == null:
		return

	_event_label.text = "Event: %s" % _last_event_text


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
	if _winner_label == null:
		return

	if _combat_finished and not _winning_team_id.is_empty():
		var result_text: String = String(_mission_result.get("result", "")).to_upper()
		var condition_text: String = String(_mission_result.get("win_condition_type", ""))
		_winner_label.text = "%s\nWinner: %s\nCondition: %s" % [result_text, _winning_team_id, condition_text]
		return

	_winner_label.text = ""


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
	if status_label != null:
		status_label.set("visible", _overlays_visible and not preview_mode)
	if _contact_line != null:
		_contact_line.visible = _overlays_visible and not preview_mode
	if _event_label != null:
		_event_label.visible = _overlays_visible and not preview_mode
	if _winner_label != null:
		_winner_label.visible = _overlays_visible and not preview_mode


func _remove_readability_nodes() -> void:
	if _contact_line != null:
		_contact_line.queue_free()
		_contact_line = null
	if _event_label != null:
		_event_label.queue_free()
		_event_label = null
	if _winner_label != null:
		_winner_label.queue_free()
		_winner_label = null


func _is_victory_condition_met() -> bool:
	match win_condition:
		WIN_CONDITION_OBJECTIVE_CAPTURE:
			_update_objective_hold_tracking()
			return _is_objective_captured_by_friendly()
		WIN_CONDITION_OBJECTIVE_DEFENSE:
			_update_objective_hold_tracking()
			return _is_objective_captured_by_friendly() and _get_objective_defense_elapsed_seconds() >= objective_defense_hold_seconds
		_:
			return _is_enemy_team_eliminated()


func _is_enemy_team_eliminated() -> bool:
	var active_enemy_units: Array = _get_active_enemy_units()
	if active_enemy_units.is_empty():
		if _has_pending_enemy_waves():
			return false

		return false

	if _has_pending_enemy_waves():
		return false

	if _has_pending_enemy_respawns():
		return false

	return _count_fit_enemy_units() == 0


func _resolve_combat(result: String, winning_team_id: String, result_condition_override: String = "") -> void:
	if _combat_finished:
		return

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
	var mission_result: Dictionary = Dictionary(
		MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call(
			"build_mission_result",
			result,
			winning_team_id,
			friendly_team_id,
			result_condition,
			_is_objective_captured_by_friendly(),
			_get_duration_seconds(),
			_build_team_states(friendly_unit_paths)
		)
	)
	mission_result["fireteam_tactical_debrief"] = _build_fireteam_tactical_debrief_entries()
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
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		unit_ids.append(unit_id)
		if unit is Node:
			(unit as Node).set_meta("enemy_security_group_id", group_id)
			(unit as Node).set_meta("enemy_facing_angle", direction_angle)
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
		for friendly in _get_units(friendly_unit_paths):
			if friendly == null or not (friendly is Node2D) or not _can_target_receive_attack(friendly):
				continue
			var friendly_id: String = String(friendly.call("get_unit_id")) if friendly.has_method("get_unit_id") else ""
			if friendly_id.is_empty() or result.has(friendly_id):
				continue
			var to_target: Vector2 = (friendly as Node2D).global_position - (enemy as Node2D).global_position
			if String(state.get("security_mode", "")) != "360" and not _angle_within_sector(to_target.angle(), float(assignment.get("center_angle", 0.0)), float(assignment.get("arc_width", 0.0))):
				continue
			if to_target.length() > float(assignment.get("weapon_range_world", 0.0)):
				continue
			if not _los_system.has_line_of_sight_between_nodes(enemy, friendly, float(assignment.get("weapon_range_world", 0.0)), _get_terrain_registry()):
				continue
			result.append(friendly_id)
	return result


func _resolve_enemy_security_anchor(units: Array) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for unit in units:
		if unit is Node2D:
			sum += (unit as Node2D).global_position
			count += 1
	if count <= 0:
		return Vector2.ZERO
	return sum / float(count)


func _resolve_enemy_security_focus_position(units: Array, fallback_position: Vector2) -> Vector2:
	var nearest_position: Vector2 = fallback_position
	var nearest_distance: float = INF
	for enemy in units:
		if enemy == null or not (enemy is Node2D):
			continue
		for friendly in _get_units(friendly_unit_paths):
			if friendly == null or not (friendly is Node2D) or not _can_target_receive_attack(friendly):
				continue
			var distance: float = (enemy as Node2D).global_position.distance_to((friendly as Node2D).global_position)
			if distance >= nearest_distance:
				continue
			nearest_distance = distance
			nearest_position = (friendly as Node2D).global_position
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
	_enemy_team_tactics_states_by_group_id.clear()
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
	for group_id_variant in grouped_units.keys():
		var group_id: String = String(group_id_variant)
		var state: Dictionary = _build_enemy_team_tactics_state(group_id, Array(grouped_units.get(group_id_variant, [])), Dictionary(tactics_by_group.get(group_id_variant, {})))
		if state.is_empty():
			continue
		_enemy_team_tactics_states_by_group_id[group_id] = state


func _build_enemy_team_tactics_state(group_id: String, units: Array, tactics: Dictionary) -> Dictionary:
	var fit_units: Array = _sort_enemy_units_by_id(_filter_fit_node2d_units(units))
	if fit_units.is_empty():
		return {}
	var profile_id: String = String(tactics.get("profile_id", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.DEFAULT_PROFILE_ID)).strip_edges().to_lower()
	var profile: Dictionary = Dictionary(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_profile", profile_id))
	var visual_archetype_id: String = String(tactics.get("visual_archetype", profile.get("visual_archetype", ""))).strip_edges().to_lower()
	var advance_style: String = String(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_advance_style", tactics.get("advance_style", profile.get("advance_style", "hold")), String(profile.get("advance_style", "hold"))))
	var cover_behavior: String = String(tactics.get("cover_behavior", profile.get("cover_behavior", ""))).strip_edges().to_lower()
	var anchor_position: Vector2 = _resolve_enemy_security_anchor(fit_units)
	var focus_position: Vector2 = _resolve_enemy_security_focus_position(fit_units, anchor_position)
	var advance_direction: Vector2 = (focus_position - anchor_position).normalized() if not focus_position.is_equal_approx(anchor_position) else Vector2.RIGHT
	var unit_ids: PackedStringArray = _extract_unit_ids_from_units(fit_units)
	var role_by_unit_id: Dictionary = _build_enemy_team_roles(fit_units)
	var moving_unit_ids: PackedStringArray = _resolve_enemy_moving_unit_ids(advance_style, unit_ids)
	var covering_unit_ids: PackedStringArray = _subtract_unit_ids(unit_ids, moving_unit_ids)
	var target_positions_by_unit_id: Dictionary = _build_enemy_tactics_target_positions(fit_units, unit_ids, moving_unit_ids, advance_style, cover_behavior, anchor_position, focus_position, advance_direction)
	for unit in fit_units:
		if unit is Node and unit.has_method("get_unit_id"):
			var unit_id: String = String(unit.call("get_unit_id"))
			(unit as Node).set_meta("enemy_tactics_group_id", group_id)
			(unit as Node).set_meta("enemy_tactic_profile_id", profile_id)
			(unit as Node).set_meta("enemy_advance_style", advance_style)
			(unit as Node).set_meta("enemy_role", String(role_by_unit_id.get(unit_id, "")))
			if not visual_archetype_id.is_empty():
				(unit as Node).set_meta("enemy_visual_archetype_id", visual_archetype_id)
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
		"has_explicit_tactics": true,
		"priority": _get_enemy_tactics_priority(advance_style),
		"move_speed_factor": _get_enemy_tactics_speed_factor(advance_style),
	}
	state["tactic_label"] = _build_enemy_team_tactics_label(state)
	for unit in fit_units:
		if unit is Node:
			(unit as Node).set_meta("enemy_tactic_label", String(state.get("tactic_label", "")))
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
	var target_positions: Dictionary = {}
	var claimed_targets: Array = []
	if _enemy_cover_behavior_uses_slots(cover_behavior):
		target_positions = _build_enemy_cover_slot_targets(units, focus_position, claimed_targets)
	if advance_style == "hold":
		return target_positions
	var step_distance: float = _get_enemy_tactics_step_distance(advance_style)
	var movement_anchor: Vector2 = anchor_position + advance_direction * step_distance
	var spaced_targets: Dictionary = Dictionary(LOCAL_AVOIDANCE_RESOLVER_SCRIPT.call("build_spaced_line_targets", moving_unit_ids, movement_anchor, advance_direction, LOCAL_AVOIDANCE_RESOLVER_SCRIPT.DEFAULT_MINIMUM_SPACING))
	for unit_id in moving_unit_ids:
		var target_position: Vector2 = Vector2(target_positions.get(String(unit_id), spaced_targets.get(String(unit_id), movement_anchor)))
		target_positions[String(unit_id)] = _resolve_enemy_walkable_tactic_target(target_position)
	for unit_id in unit_ids:
		if target_positions.has(String(unit_id)):
			continue
		var unit = _find_unit_by_id(units, String(unit_id))
		if unit is Node2D:
			target_positions[String(unit_id)] = (unit as Node2D).global_position
	return target_positions


func _enemy_cover_behavior_uses_slots(cover_behavior: String) -> bool:
	return cover_behavior.find("cover") >= 0


func _build_enemy_cover_slot_targets(units: Array, focus_position: Vector2, claimed_targets: Array) -> Dictionary:
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
		var candidates: Array = Array(terrain_registry.call("get_walkable_cover_tiles_in_radius", (unit as Node2D).global_position, ENEMY_TACTICS_COVER_SEARCH_RADIUS))
		candidates.sort_custom(func(a, b) -> bool:
			return _score_enemy_cover_tile(unit, a, focus_position) > _score_enemy_cover_tile(unit, b, focus_position)
		)
		for tile in candidates:
			if tile == null or typeof(tile.world_position) != TYPE_VECTOR2:
				continue
			var candidate_position: Vector2 = Vector2(tile.world_position)
			if not _is_enemy_tactic_slot_available(candidate_position, claimed_targets):
				continue
			if _score_enemy_cover_tile(unit, tile, focus_position) <= -999.0:
				continue
			target_positions[unit_id] = candidate_position
			claimed_targets.append(candidate_position)
			break
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
	if not _los_system.has_line_of_sight_between_points(tile_position, focus_position, attack_range, _get_terrain_registry()):
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
	if state.is_empty() or not bool(state.get("has_explicit_tactics", false)):
		return false
	var advance_style: String = String(state.get("advance_style", "hold"))
	if advance_style == "hold":
		return true
	var moving_unit_ids: PackedStringArray = PackedStringArray(state.get("moving_unit_ids", PackedStringArray()))
	if not moving_unit_ids.has(unit_id):
		return true
	var target_positions: Dictionary = Dictionary(state.get("target_positions_by_unit_id", {}))
	if not target_positions.has(unit_id):
		return true
	var target_position: Vector2 = Vector2(target_positions.get(unit_id, (enemy as Node2D).global_position))
	if (enemy as Node2D).global_position.distance_to(target_position) <= ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE:
		return true
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": int(state.get("priority", 8)),
			"unit_id": unit_id,
			"target_position": target_position,
			"move_speed_factor": float(state.get("move_speed_factor", enemy_advance_speed_factor)),
			"requeue_until_target": false,
			"enemy_tactic_label": String(state.get("tactic_label", "")),
			"enemy_advance_style": advance_style,
		}
	)
	return true


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

		if _try_enqueue_enemy_patrol_move(simulation_root, enemy):
			continue

		if _enemy_should_hold_position(enemy):
			continue

		simulation_root.call(
			"enqueue_command",
			{
				"command_type": "move_to_position",
				"priority": 8,
				"unit_id": String(enemy.call("get_unit_id")),
				"target_position": objective_position,
				"move_speed_factor": enemy_advance_speed_factor,
				"requeue_until_target": false,
			}
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
	if bool(_enemy_patrol_contact_locked.get(unit_id, false)):
		return false
	if _enemy_should_hold_position(enemy):
		_enemy_patrol_contact_locked[unit_id] = true
		return false
	var patrol_path: Array = Array(_enemy_patrol_paths_by_unit_id.get(unit_id, []))
	if patrol_path.is_empty():
		return false
	var waypoint_index: int = int(_enemy_patrol_waypoint_index_by_unit_id.get(unit_id, 0))
	if waypoint_index < 0:
		waypoint_index = 0
	if waypoint_index >= patrol_path.size():
		waypoint_index = 0
	var target_position: Vector2 = _coerce_vector2(patrol_path[waypoint_index], (enemy as Node2D).global_position)
	if (enemy as Node2D).global_position.distance_to(target_position) <= ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE:
		waypoint_index = (waypoint_index + 1) % patrol_path.size()
		_enemy_patrol_waypoint_index_by_unit_id[unit_id] = waypoint_index
		target_position = _coerce_vector2(patrol_path[waypoint_index], target_position)
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": 7,
			"unit_id": unit_id,
			"target_position": target_position,
			"move_speed_factor": enemy_advance_speed_factor,
			"requeue_until_target": false,
		}
	)
	return true


func _enemy_should_hold_position(enemy) -> bool:
	if enemy == null or not (enemy is Node2D):
		return true

	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not _can_target_receive_attack(friendly):
			continue

		var attack_range: float = _get_weapon_attack_range(enemy, friendly)
		if not _los_system.has_line_of_sight_between_nodes(enemy, friendly, attack_range, _get_terrain_registry()):
			continue

		if (enemy as Node2D).global_position.distance_to((friendly as Node2D).global_position) <= maxf(enemy_engage_distance, attack_range):
			return true

	return false


func _pick_target_from_units(attacker, targets: Array):
	return COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("pick_target_from_units", attacker, targets, _build_fire_decision_context())


func _get_active_enemy_units() -> Array:
	var active_units: Array = []
	var unit_registry = _get_unit_registry()
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue

		if unit_registry != null and unit_registry.has_method("has_unit"):
			if not bool(unit_registry.call("has_unit", String(enemy.call("get_unit_id")))):
				continue

		if enemy is CanvasItem and not (enemy as CanvasItem).visible:
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
	if simulation_root == null or not simulation_root.has_method("_get_unit_registry"):
		return null

	return simulation_root.call("_get_unit_registry")


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
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": 12,
			"unit_id": unit_id,
			"target_position": reposition_target,
			"move_speed_factor": enemy_reposition_move_speed_factor,
			"requeue_until_target": true,
		}
	)
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


func _resolve_unit_by_id(unit_id: String):
	if unit_id.is_empty():
		return null

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		return null

	return unit_registry.call("get_unit", unit_id)


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
	for friendly in _get_units(friendly_unit_paths):
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
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("refresh_fireteam_security_state") or not tactical_controller.has_method("get_fireteam_security_snapshot"):
		_overwatch_controller.call("reset_all")
		return []
	tactical_controller.call("refresh_fireteam_security_state")
	var friendly_units_by_fireteam: Dictionary = {}
	for friendly in _get_units(friendly_unit_paths):
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
			_get_active_enemy_units(),
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
		_record_fire_event_from_shot(shot, attacker, target, "overwatch")
		if attacker != null and target != null:
			_set_contact_visuals(attacker, target)
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
