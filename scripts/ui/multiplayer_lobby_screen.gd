extends Control

signal back_requested

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")
const MULTIPLAYER_DROPSHIP_BOOTSTRAP_SCRIPT: GDScript = preload("res://scripts/mission/multiplayer_dropship_bootstrap.gd")
const CONTACT_APPROACH_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/contact_approach_resolver.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const LOBBY_BACKGROUND_ID: String = "multiplayer_lobby_hangar"
const LOBBY_PANEL_SIZE: Vector2 = Vector2(720.0, 560.0)
const TEAM_PLAY_MODE_COOP: String = "coop"
const TEAM_PLAY_MODE_VERSUS: String = "versus"
const CONNECTION_MODE_LAN: String = "lan"
const CONNECTION_MODE_DIRECT_WAN: String = "direct_wan"
const CONNECTION_MODE_UPNP: String = "upnp"
const DEFAULT_MAP_FILE_NAME: String = "Ground_Mission01_32x32.json"
const RELEASE_HOST_ARG: String = "--release-multiplayer-host"
const RELEASE_JOIN_ARG: String = "--release-multiplayer-join"
const RELEASE_ADDRESS_ARG: String = "--release-multiplayer-address="
const RELEASE_PORT_ARG: String = "--release-multiplayer-port="
const RELEASE_AUTO_START_ARG: String = "--release-multiplayer-auto-start"
const RELEASE_TRACE_ARG: String = "--release-multiplayer-trace="
const RELEASE_DROP_DECISION_ARG: String = "--release-multiplayer-drop-decision"
const RELEASE_FIRST_CONTACT_ARG: String = "--release-multiplayer-first-contact"
const RELEASE_TRACE_HEARTBEAT_MSEC: int = 1000

@onready var _status_label: Label = get_node("Panel/Margin/VBox/StatusLabel")
@onready var _team_readability_label: Label = get_node("Panel/Margin/VBox/TeamReadabilityLabel")
@onready var _team_badge_row: HBoxContainer = get_node("Panel/Margin/VBox/TeamBadgeRow")
@onready var _host_port_spin: SpinBox = get_node("Panel/Margin/VBox/HostJoinGrid/HostPortSpinBox")
@onready var _host_button: Button = get_node("Panel/Margin/VBox/HostJoinGrid/HostButton")
@onready var _join_address_edit: LineEdit = get_node("Panel/Margin/VBox/HostJoinGrid/JoinAddressLineEdit")
@onready var _join_port_spin: SpinBox = get_node("Panel/Margin/VBox/HostJoinGrid/JoinPortSpinBox")
@onready var _join_button: Button = get_node("Panel/Margin/VBox/HostJoinGrid/JoinButton")
@onready var _ready_button: Button = get_node("Panel/Margin/VBox/SessionRow/ReadyButton")
@onready var _start_button: Button = get_node("Panel/Margin/VBox/SessionRow/StartMissionButton")
@onready var _disconnect_button: Button = get_node("Panel/Margin/VBox/SessionRow/DisconnectButton")
@onready var _back_button: Button = get_node("Panel/Margin/VBox/SessionRow/BackButton")
@onready var _roster_mode_option: OptionButton = get_node("Panel/Margin/VBox/RosterModeRow/RosterModeOptionButton")
@onready var _roster_mode_summary_label: Label = get_node("Panel/Margin/VBox/RosterModeRow/RosterModeSummaryLabel")
@onready var _peer_label: Label = get_node("Panel/Margin/VBox/PeerLabel")
@onready var _assignment_label: Label = get_node("Panel/Margin/VBox/AssignmentLabel")
@onready var _settings_label: Label = get_node("Panel/Margin/VBox/SettingsLabel")
@onready var _map_consent_panel: PanelContainer = get_node("Panel/Margin/VBox/MapConsentPanel")
@onready var _map_consent_label: Label = get_node("Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentLabel")
@onready var _map_accept_button: Button = get_node("Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentRow/MapAcceptButton")
@onready var _map_reject_button: Button = get_node("Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentRow/MapRejectButton")

var _session: Node = null
var _settings_config_path: String = GAME_SETTINGS_CONTRACT_SCRIPT.CONFIG_PATH
var _last_start_assignments: Dictionary = {}
var _mission_start_request_count: int = 0
var _pending_map_manifest: Dictionary = {}
var _map_consent_state: Dictionary = {
	"state": "none",
	"requires_consent": false,
	"can_start_client": true,
}
var _audio_event_bus = null
var _background_rect: TextureRect = null
var _background_shade: ColorRect = null
var _mission_host: Node = null
var _active_mission: Node = null
const PRODUCT_MISSION_COMBAT_STARTUP_GRACE_TICKS := 180
var _player_name_edit: LineEdit = null
var _player_roster_option: OptionButton = null
var _player_team_option: OptionButton = null
var _team_mode_option: OptionButton = null
var _map_option: OptionButton = null
var _connection_mode_option: OptionButton = null
var _network_hint_label: Label = null
var _role_readability_snapshot: Dictionary = {
	"ui_sets_gameplay_truth": false,
	"active_count": 0,
	"spectator_count": 0,
	"local_role_label": "",
}
var _release_playtest_config: Dictionary = {}
var _release_playtest_stage: String = "disabled"
var _release_playtest_action_started: bool = false
var _release_playtest_ready_sent: bool = false
var _release_playtest_last_trace_key: String = ""
var _release_drop_decision_stage: String = "disabled"
var _release_drop_lz_sent: bool = false
var _release_drop_call_sent: bool = false
var _release_first_decision_sent: bool = false
var _release_first_decision_accepted: bool = false
var _release_local_fireteam_id: String = ""
var _release_local_craft_id: String = ""
var _release_first_contact_stage: String = "disabled"
var _release_first_contact_advance_sent: bool = false
var _release_initial_movement_observed: bool = false
var _release_initial_movement_observe_frames: int = 0
var _release_first_contact_advance_attempted: bool = false
var _release_first_contact_target_position: Vector2 = Vector2.ZERO
var _release_first_contact_advance_started_msec: int = 0
var _release_first_contact_advance_started_tick: int = 0
var _release_first_contact_start_position: Vector2 = Vector2.ZERO
var _release_contact_approach_evidence: Dictionary = {}


func _ready() -> void:
	set_meta("multiplayer_lobby_screen", true)
	set_process(false)
	_ensure_background_nodes()
	_apply_background_texture()
	_ensure_multiplayer_session()
	_ensure_mission_host()
	_ensure_audio_event_bus()
	_ensure_lobby_setup_controls()
	_enforce_lobby_panel_geometry()
	_configure_default_inputs()
	_connect_ui_signals()
	_apply_contextual_help_ids()
	_refresh_from_session()
	_release_playtest_config = get_release_multiplayer_deeplink_snapshot()
	if bool(_release_playtest_config.get("enabled", false)):
		_release_playtest_stage = "configured"
		set_process(true)
		call_deferred("_start_release_multiplayer_playtest")
	call_deferred("_enforce_lobby_panel_geometry")


func _process(_delta: float) -> void:
	if not bool(_release_playtest_config.get("enabled", false)):
		return
	_advance_release_multiplayer_playtest()


func get_release_multiplayer_deeplink_snapshot(user_args: Array = []) -> Dictionary:
	var args: Array = user_args.duplicate() if not user_args.is_empty() else Array(_get_release_multiplayer_cmdline_args())
	var role := ""
	var address := MULTIPLAYER_SESSION_SCRIPT.DEFAULT_ADDRESS
	var port: int = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT
	var auto_start := false
	var drop_decision := false
	var first_contact := false
	var trace_path := ""
	for value in args:
		var arg: String = String(value).strip_edges()
		if arg == RELEASE_HOST_ARG:
			role = "host"
		elif arg == RELEASE_JOIN_ARG:
			role = "client"
		elif arg.begins_with(RELEASE_ADDRESS_ARG):
			address = arg.trim_prefix(RELEASE_ADDRESS_ARG).strip_edges()
		elif arg.begins_with(RELEASE_PORT_ARG):
			port = maxi(1, int(arg.trim_prefix(RELEASE_PORT_ARG)))
		elif arg == RELEASE_AUTO_START_ARG:
			auto_start = true
		elif arg == RELEASE_DROP_DECISION_ARG:
			drop_decision = true
		elif arg == RELEASE_FIRST_CONTACT_ARG:
			first_contact = true
			drop_decision = true
		elif arg.begins_with(RELEASE_TRACE_ARG):
			trace_path = arg.trim_prefix(RELEASE_TRACE_ARG).strip_edges()
	return {
		"schema": "sternenbuergerchen.release_multiplayer_deeplink.v1",
		"task_id": "TASK_1147",
		"enabled": not role.is_empty(),
		"role": role,
		"address": address,
		"port": port,
		"auto_ready": not role.is_empty(),
		"auto_start": auto_start and role == "host",
		"drop_decision": drop_decision and not role.is_empty(),
		"first_contact": first_contact and not role.is_empty(),
		"trace_path": trace_path,
		"read_only_config": true,
		"ui_sets_gameplay_truth": false,
	}


func get_release_multiplayer_playtest_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.release_multiplayer_playtest.v1",
		"task_id": "TASK_1147",
		"stage": _release_playtest_stage,
		"config": _release_playtest_config.duplicate(true),
		"session": get_session_snapshot(),
		"active_mission": has_active_mission(),
		"drop_decision": get_release_multiplayer_drop_decision_snapshot(),
		"first_contact": get_release_multiplayer_first_contact_snapshot(),
		"ui_sets_gameplay_truth": false,
	}


func get_release_multiplayer_drop_decision_snapshot() -> Dictionary:
	var controller: Node = _active_mission.get_node_or_null("TacticalController") if has_active_mission() else null
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state")) if controller != null and controller.has_method("get_planning_state") else {}
	var feedback: Dictionary = Dictionary(controller.call("get_network_fireteam_command_feedback_snapshot")) if controller != null and controller.has_method("get_network_fireteam_command_feedback_snapshot") else {}
	return {
		"schema": "sternenbuergerchen.release_multiplayer_drop_decision.v1",
		"task_id": "TASK_1148",
		"stage": _release_drop_decision_stage,
		"fireteam_id": _release_local_fireteam_id,
		"craft_id": _release_local_craft_id,
		"lz_sent": _release_drop_lz_sent,
		"drop_sent": _release_drop_call_sent,
		"decision_sent": _release_first_decision_sent,
		"decision_accepted": _release_first_decision_accepted,
		"mission_drop_cards": Array(planning_state.get("mission_drop_cards", [])).duplicate(true),
		"embarked_unit_ids": Array(planning_state.get("embarked_unit_ids", [])).duplicate(),
		"deployed_unit_ids": Array(planning_state.get("deployed_unit_ids", [])).duplicate(),
		"command_feedback": feedback,
		"ui_sets_gameplay_truth": false,
	}


func get_release_multiplayer_first_contact_snapshot() -> Dictionary:
	var controller: Node = _active_mission.get_node_or_null("TacticalController") if has_active_mission() else null
	var contacts: Array = Array(controller.call("get_fireteam_contact_snapshot", _release_local_fireteam_id)).duplicate(true) if controller != null and controller.has_method("get_fireteam_contact_snapshot") and not _release_local_fireteam_id.is_empty() else []
	var fire_events: Array = Array(controller.call("get_fire_event_snapshot")).duplicate(true) if controller != null and controller.has_method("get_fire_event_snapshot") else []
	var diagnostics: Dictionary = Dictionary(controller.call("get_contact_decision_diagnostics_snapshot")).duplicate(true) if controller != null and controller.has_method("get_contact_decision_diagnostics_snapshot") else {}
	var perspective: Dictionary = Dictionary(controller.call("get_connected_first_contact_hud_perspective_snapshot")).duplicate(true) if controller != null and controller.has_method("get_connected_first_contact_hud_perspective_snapshot") else {}
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", _release_local_fireteam_id)).duplicate(true) if controller != null and controller.has_method("get_fireteam_movement_state") and not _release_local_fireteam_id.is_empty() else {}
	var fireteam_status: Dictionary = {}
	if controller != null and controller.has_method("get_fireteam_status_card_snapshot"):
		for status_variant in Array(controller.call("get_fireteam_status_card_snapshot")):
			if typeof(status_variant) == TYPE_DICTIONARY and String(Dictionary(status_variant).get("fireteam_id", "")).strip_edges().to_lower() == _release_local_fireteam_id:
				fireteam_status = Dictionary(status_variant).duplicate(true)
				break
	var fire_event_ids: PackedStringArray = PackedStringArray()
	for event_variant in fire_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event_id: String = String(Dictionary(event_variant).get("event_id", "")).strip_edges()
		if not event_id.is_empty() and not fire_event_ids.has(event_id):
			fire_event_ids.append(event_id)
	var current_position: Vector2 = Vector2(Dictionary(fireteam_status.get("position", {})).get("world_position", Vector2.ZERO))
	var movement_wall_time_msec: int = maxi(Time.get_ticks_msec() - _release_first_contact_advance_started_msec, 0) if _release_first_contact_advance_started_msec > 0 else 0
	var initial_distance: float = _release_first_contact_start_position.distance_to(_release_first_contact_target_position)
	var movement_distance_travelled: float = _release_first_contact_start_position.distance_to(current_position) if _release_first_contact_advance_started_msec > 0 else 0.0
	var movement_remaining_distance: float = current_position.distance_to(_release_first_contact_target_position) if _release_first_contact_advance_started_msec > 0 else 0.0
	var movement_progress_ratio: float = clampf(1.0 - (movement_remaining_distance / initial_distance), 0.0, 1.0) if initial_distance > 0.001 else 0.0
	var simulation_root: Node = _active_mission.get_node_or_null("SimulationRoot") if has_active_mission() else null
	var simulation_tick: int = int(simulation_root.call("get_tick")) if simulation_root != null and simulation_root.has_method("get_tick") else 0
	return {
		"schema": "sternenbuergerchen.release_multiplayer_first_contact.v1",
		"task_id": "TASK_1150",
		"stage": _release_first_contact_stage,
		"fireteam_id": _release_local_fireteam_id,
		"advance_sent": _release_first_contact_advance_sent,
		"advance_attempted": _release_first_contact_advance_attempted,
		"initial_movement_observed": _release_initial_movement_observed,
		"initial_movement_observe_frames": _release_initial_movement_observe_frames,
		"requested_target_position": _release_first_contact_target_position,
		"movement_state": movement_state,
		"fireteam_position": Dictionary(fireteam_status.get("position", {})).duplicate(true),
		"movement_wall_time_msec": movement_wall_time_msec,
		"simulation_tick": simulation_tick,
		"simulation_ticks_since_advance": maxi(simulation_tick - _release_first_contact_advance_started_tick, 0),
		"physics_fps": Engine.get_frames_per_second(),
		"movement_start_position": _release_first_contact_start_position,
		"movement_distance_travelled": movement_distance_travelled,
		"movement_remaining_distance": movement_remaining_distance,
		"movement_progress_ratio": movement_progress_ratio,
		"contact_approach_evidence": _release_contact_approach_evidence.duplicate(true),
		"contact_count": contacts.size(),
		"contacts": contacts,
		"fire_event_count": fire_events.size(),
		"fire_event_ids": Array(fire_event_ids),
		"fire_events": fire_events,
		"diagnostics": diagnostics,
		"perspective": perspective,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _get_release_multiplayer_cmdline_args() -> PackedStringArray:
	var result := PackedStringArray()
	for value in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		var arg: String = String(value).strip_edges()
		if not arg.is_empty() and not result.has(arg):
			result.append(arg)
	return result


func _start_release_multiplayer_playtest() -> void:
	var role: String = String(_release_playtest_config.get("role", ""))
	var port: int = int(_release_playtest_config.get("port", MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT))
	_release_playtest_action_started = host_game(port) if role == "host" else join_game(String(_release_playtest_config.get("address", MULTIPLAYER_SESSION_SCRIPT.DEFAULT_ADDRESS)), port)
	_release_playtest_stage = "hosting" if role == "host" and _release_playtest_action_started else "connecting" if _release_playtest_action_started else "start_failed"
	_write_release_multiplayer_trace()


func _advance_release_multiplayer_playtest() -> void:
	var snapshot: Dictionary = get_session_snapshot()
	if not _release_playtest_action_started:
		_write_release_multiplayer_trace()
		return
	if bool(snapshot.get("mission_started", false)) or has_active_mission():
		if bool(_release_playtest_config.get("drop_decision", false)):
			_advance_release_multiplayer_drop_decision()
			if bool(_release_playtest_config.get("first_contact", false)):
				_advance_release_multiplayer_first_contact()
				_release_playtest_stage = "first_contact:%s" % _release_first_contact_stage
			else:
				_release_playtest_stage = "drop_decision:%s" % _release_drop_decision_stage
		else:
			_release_playtest_stage = "mission_started"
	elif bool(snapshot.get("can_toggle_ready", false)) and not bool(snapshot.get("local_ready", false)) and not _release_playtest_ready_sent:
		_release_playtest_ready_sent = set_ready(true)
		_release_playtest_stage = "ready_sent" if _release_playtest_ready_sent else "ready_failed"
	elif String(_release_playtest_config.get("role", "")) == "host" and bool(_release_playtest_config.get("auto_start", false)) and bool(snapshot.get("can_start_mission", false)):
		_release_playtest_stage = "mission_start_sent" if start_mission() else "mission_start_failed"
	elif bool(snapshot.get("has_active_peer", false)):
		_release_playtest_stage = "connected"
	_write_release_multiplayer_trace()


func _advance_release_multiplayer_drop_decision() -> void:
	if not has_active_mission():
		_release_drop_decision_stage = "waiting_for_mission"
		return
	var controller: Node = _active_mission.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("get_planning_state"):
		_release_drop_decision_stage = "controller_missing"
		return
	if _release_drop_decision_stage == "disabled":
		_release_drop_decision_stage = "waiting_for_dropship"
	_resolve_release_local_drop_assignment(controller)
	if _release_local_fireteam_id.is_empty() or _release_local_craft_id.is_empty():
		return
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var card: Dictionary = _find_release_drop_card(Array(planning_state.get("mission_drop_cards", [])), _release_local_craft_id)
	if card.is_empty():
		_release_drop_decision_stage = "waiting_for_dropship"
		return
	var pending_count: int = int(Dictionary(controller.call("get_network_dropship_pending_debug_snapshot")).get("pending_count", 0)) if controller.has_method("get_network_dropship_pending_debug_snapshot") else 0
	if not bool(card.get("has_lz_position", false)):
		if not _release_drop_lz_sent and pending_count <= 0:
			controller.call("select_mission_dropship_fireteam", _release_local_craft_id, _release_local_fireteam_id)
			var lz_position := Vector2(384.0, 224.0) if _release_local_fireteam_id == "blue" else Vector2(704.0, 384.0)
			var approach := "NW" if _release_local_fireteam_id == "blue" else "SE"
			_release_drop_lz_sent = bool(controller.call("request_network_authoritative_dropship_command", "set_lz", _release_local_craft_id, _release_local_fireteam_id, {"lz_position": lz_position, "approach_angle": approach}))
			_release_drop_decision_stage = "lz_requested" if _release_drop_lz_sent else "lz_request_failed"
		return
	if not _release_drop_call_sent and pending_count <= 0 and String(card.get("state", "")).strip_edges().to_lower() == "waiting":
		controller.call("select_mission_dropship_fireteam", _release_local_craft_id, _release_local_fireteam_id)
		_release_drop_call_sent = bool(controller.call("request_network_authoritative_dropship_command", "call_dropship", _release_local_craft_id, _release_local_fireteam_id))
		_release_drop_decision_stage = "drop_requested" if _release_drop_call_sent else "drop_request_failed"
		return
	var local_member_ids: Array = _release_fireteam_member_ids(controller, _release_local_fireteam_id)
	var deployed_ids: Array = Array(planning_state.get("deployed_unit_ids", []))
	if not local_member_ids.is_empty() and _all_release_ids_present(local_member_ids, deployed_ids):
		if not _release_first_decision_sent:
			_release_first_decision_sent = _submit_release_first_move_decision(controller, card)
			_release_drop_decision_stage = "decision_submitted" if _release_first_decision_sent else "decision_submit_failed"
			if _release_first_decision_sent and bool(get_session_snapshot().get("is_host", false)):
				_release_first_decision_accepted = true
				_release_drop_decision_stage = "first_decision_accepted"
			return
		var feedback: Dictionary = Dictionary(controller.call("get_network_fireteam_command_feedback_snapshot")) if controller.has_method("get_network_fireteam_command_feedback_snapshot") else {}
		if bool(feedback.get("accepted", false)) and String(feedback.get("fireteam_id", "")).strip_edges().to_lower() == _release_local_fireteam_id:
			_release_first_decision_accepted = true
			_release_drop_decision_stage = "first_decision_accepted"
		else:
			_release_drop_decision_stage = "waiting_for_host_decision"
		return
	if _release_drop_call_sent:
		_release_drop_decision_stage = "drop_in_progress"


func _advance_release_multiplayer_first_contact() -> void:
	if not _release_first_decision_accepted:
		_release_first_contact_stage = "waiting_for_first_decision"
		return
	if not has_active_mission():
		_release_first_contact_stage = "waiting_for_mission"
		return
	var controller: Node = _active_mission.get_node_or_null("TacticalController")
	if controller == null:
		_release_first_contact_stage = "controller_missing"
		return
	var contact_snapshot: Dictionary = get_release_multiplayer_first_contact_snapshot()
	if int(contact_snapshot.get("contact_count", 0)) > 0 and int(contact_snapshot.get("fire_event_count", 0)) > 0:
		_release_first_contact_stage = "first_fire_observed"
		return
	if int(contact_snapshot.get("contact_count", 0)) > 0:
		_release_first_contact_stage = "contact_detected"
		return
	if _release_first_contact_advance_sent:
		_release_first_contact_stage = "waiting_for_contact"
		return
	if _release_first_contact_advance_attempted:
		_release_first_contact_stage = "contact_advance_failed"
		return
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", _release_local_fireteam_id)) if controller.has_method("get_fireteam_movement_state") else {}
	var member_busy: bool = _release_fireteam_has_busy_members(controller, _release_local_fireteam_id)
	if not movement_state.is_empty() or member_busy:
		_release_initial_movement_observed = true
		_release_initial_movement_observe_frames += 1
		if _release_initial_movement_observe_frames < 30:
			_release_first_contact_stage = "waiting_for_initial_move"
			return
	if not _release_initial_movement_observed:
		_release_first_contact_stage = "waiting_for_initial_move_start"
		return
	_release_first_contact_advance_attempted = true
	_release_first_contact_advance_sent = _submit_release_contact_advance(controller)
	_release_first_contact_stage = "contact_advance_submitted" if _release_first_contact_advance_sent else "contact_advance_failed"


func _release_fireteam_has_busy_members(controller: Node, fireteam_id: String) -> bool:
	if controller == null or not controller.has_method("get_fireteam_member_status_row_snapshot"):
		return false
	for row_variant in Array(controller.call("get_fireteam_member_status_row_snapshot")):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		return int(Dictionary(row.get("counts", {})).get("busy", 0)) > 0
	return false


func _submit_release_contact_advance(controller: Node) -> bool:
	var requested_target := Vector2(1344.0, 992.0)
	if controller.has_method("get_mission_marker_world_position"):
		requested_target = Vector2(controller.call("get_mission_marker_world_position", "spawn_bravo", requested_target))
	var terrain_registry: Node = _active_mission.get_node_or_null("TerrainRegistry")
	var unit_registry: Node = _active_mission.get_node_or_null("UnitRegistry")
	var pace_snapshot: Dictionary = get_release_multiplayer_first_contact_snapshot()
	var start_position := Vector2(Dictionary(pace_snapshot.get("fireteam_position", {})).get("world_position", Vector2.ZERO))
	var local_team_id: String = ""
	var enemy_positions: Array = []
	if unit_registry != null and unit_registry.has_method("get_all_units"):
		var all_units: Array = unit_registry.call("get_all_units")
		for unit in all_units:
			if unit == null or not unit.has_method("get_team_id"):
				continue
			if unit.has_method("get_fireteam_id") and String(unit.call("get_fireteam_id")).strip_edges().to_lower() == _release_local_fireteam_id:
				local_team_id = String(unit.call("get_team_id")).strip_edges()
		for unit in all_units:
			if unit == null or not (unit is Node2D) or not unit.has_method("get_team_id"):
				continue
			if not local_team_id.is_empty() and String(unit.call("get_team_id")).strip_edges() != local_team_id:
				enemy_positions.append((unit as Node2D).global_position)
	if enemy_positions.is_empty():
		enemy_positions.append(requested_target)
	if terrain_registry != null:
		_release_contact_approach_evidence = Dictionary(CONTACT_APPROACH_RESOLVER_SCRIPT.new().call("find_reachable_approach", start_position, enemy_positions, terrain_registry))
		if bool(_release_contact_approach_evidence.get("found", false)):
			requested_target = Vector2(_release_contact_approach_evidence.get("position", requested_target))
	if terrain_registry != null and terrain_registry.has_method("resolve_walkable_target"):
		var resolved: Dictionary = Dictionary(terrain_registry.call("resolve_walkable_target", requested_target))
		requested_target = Vector2(resolved.get("replacement_position", requested_target))
	_release_first_contact_target_position = requested_target
	var accepted: bool = bool(controller.call("request_network_authoritative_fireteam_intent", _release_local_fireteam_id, "move", requested_target))
	if accepted:
		_release_first_contact_start_position = Vector2(Dictionary(pace_snapshot.get("fireteam_position", {})).get("world_position", Vector2.ZERO))
		_release_first_contact_advance_started_msec = Time.get_ticks_msec()
		_release_first_contact_advance_started_tick = int(pace_snapshot.get("simulation_tick", 0))
	return accepted


func _resolve_release_local_drop_assignment(controller: Node) -> void:
	if not _release_local_fireteam_id.is_empty() and not _release_local_craft_id.is_empty():
		return
	var assignments: Dictionary = Dictionary(get_session_snapshot().get("assignments", {}))
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	var local_peer_id: int = int(get_session_snapshot().get("local_peer_id", 0))
	var fireteams := PackedStringArray(peer_fireteams.get(local_peer_id, PackedStringArray()))
	if fireteams.is_empty():
		return
	_release_local_fireteam_id = String(fireteams[0]).strip_edges().to_lower()
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	for card_variant in Array(planning_state.get("mission_drop_cards", [])):
		var card: Dictionary = Dictionary(card_variant)
		if Array(card.get("boarded_fireteam_ids", [])).has(_release_local_fireteam_id):
			_release_local_craft_id = String(card.get("craft_id", "")).strip_edges()
			return


func _find_release_drop_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card.duplicate(true)
	return {}


func _release_fireteam_member_ids(controller: Node, fireteam_id: String) -> Array:
	for row_variant in Array(controller.call("get_fireteam_member_status_row_snapshot")):
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		var result: Array = []
		for member_variant in Array(row.get("members", [])):
			var unit_id: String = String(Dictionary(member_variant).get("unit_id", "")).strip_edges()
			if not unit_id.is_empty():
				result.append(unit_id)
		return result
	return []


func _all_release_ids_present(expected_ids: Array, actual_ids: Array) -> bool:
	for unit_id in expected_ids:
		if not actual_ids.has(unit_id):
			return false
	return not expected_ids.is_empty()


func _submit_release_first_move_decision(controller: Node, card: Dictionary) -> bool:
	var lz_position: Vector2 = Vector2(card.get("lz_position", Vector2.ZERO))
	var requested_target := lz_position + (Vector2(128.0, 64.0) if _release_local_fireteam_id == "blue" else Vector2(-128.0, 64.0))
	var terrain_registry: Node = _active_mission.get_node_or_null("TerrainRegistry")
	if terrain_registry != null and terrain_registry.has_method("resolve_walkable_target"):
		var resolved: Dictionary = Dictionary(terrain_registry.call("resolve_walkable_target", requested_target))
		requested_target = Vector2(resolved.get("replacement_position", requested_target))
	return bool(controller.call("request_network_authoritative_fireteam_intent", _release_local_fireteam_id, "move", requested_target))


func _write_release_multiplayer_trace() -> void:
	var trace_path: String = String(_release_playtest_config.get("trace_path", "")).strip_edges()
	if trace_path.is_empty():
		return
	var snapshot: Dictionary = get_release_multiplayer_playtest_snapshot()
	var trace_key := "%s|%s|%s|%s" % [
		_release_playtest_stage,
		str(snapshot.session.get("connected_count", 0)),
		str(snapshot.session.get("ready_count", 0)),
		str(snapshot.get("active_mission", false)),
	]
	trace_key += "|%s" % _release_drop_decision_stage
	var drop_snapshot: Dictionary = Dictionary(snapshot.get("drop_decision", {}))
	var drop_deployed_count: int = Array(drop_snapshot.get("deployed_unit_ids", [])).size()
	var drop_embarked_count: int = Array(drop_snapshot.get("embarked_unit_ids", [])).size()
	trace_key += "|dep:%d|emb:%d" % [drop_deployed_count, drop_embarked_count]
	var first_contact_snapshot: Dictionary = Dictionary(snapshot.get("first_contact", {}))
	var trace_heartbeat_bucket: int = int(first_contact_snapshot.get("movement_wall_time_msec", 0)) / RELEASE_TRACE_HEARTBEAT_MSEC
	trace_key += "|fc:%s|contacts:%d|fire:%d" % [
		String(first_contact_snapshot.get("stage", "")),
		int(first_contact_snapshot.get("contact_count", 0)),
		int(first_contact_snapshot.get("fire_event_count", 0)),
	]
	if bool(_release_playtest_config.get("first_contact", false)):
		trace_key += "|pace:%d" % trace_heartbeat_bucket
	if trace_key == _release_playtest_last_trace_key:
		return
	_release_playtest_last_trace_key = trace_key
	var absolute_path: String = ProjectSettings.globalize_path(trace_path) if trace_path.begins_with("res://") or trace_path.begins_with("user://") else trace_path
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot, "\t"))


func host_game(port: int = -1) -> bool:
	_apply_lobby_setup_to_session()
	var resolved_port: int = port if port > 0 else int(_host_port_spin.value)
	var ok: bool = bool(_session.call("start_host", resolved_port))
	if ok:
		_apply_selected_map_manifest()
	_play_ui_sfx("confirm" if ok else "warning", "host_game")
	return ok


func join_game(address: String = "", port: int = -1) -> bool:
	_apply_lobby_setup_to_session()
	var resolved_address: String = address.strip_edges() if not address.strip_edges().is_empty() else _join_address_edit.text.strip_edges()
	if resolved_address.is_empty():
		resolved_address = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_ADDRESS
	var resolved_port: int = port if port > 0 else int(_join_port_spin.value)
	var ok: bool = bool(_session.call("join_session", resolved_address, resolved_port))
	_play_ui_sfx("confirm" if ok else "warning", "join_game")
	return ok


func disconnect_game() -> void:
	_session.call("disconnect_session", "Disconnected. Back in multiplayer lobby.")
	_play_ui_sfx("cancel", "disconnect_game")


func set_ready(ready: bool) -> bool:
	var ok: bool = bool(_session.call("set_local_ready", ready))
	_play_ui_sfx("switch" if ok else "warning", "set_ready")
	return ok


func set_roster_mode(mode: String) -> bool:
	var ok: bool = bool(_session.call("set_roster_mode", mode))
	_play_ui_sfx("switch" if ok else "warning", "set_roster_mode")
	return ok


func start_mission() -> bool:
	if bool(_map_consent_state.get("requires_consent", false)) and not bool(_map_consent_state.get("can_start_client", true)):
		_status_label.text = "Map consent required before mission start."
		_play_ui_sfx("warning", "start_mission_blocked")
		return false
	var ok: bool = bool(_session.call("request_start_mission"))
	_play_ui_sfx("confirm" if ok else "warning", "start_mission")
	return ok


func has_active_mission() -> bool:
	return _active_mission != null and is_instance_valid(_active_mission)


func return_to_main_menu() -> void:
	_play_ui_sfx("cancel", "return_to_main_menu")
	disconnect_game()
	back_requested.emit()
	if get_tree() != null and ResourceLoader.exists(MAIN_MENU_SCENE_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func set_settings_path_for_tests(config_path: String) -> void:
	_settings_config_path = config_path
	_refresh_settings_summary()


func set_host_map_manifest(manifest: Dictionary, local_map_paths: Array = []) -> Dictionary:
	_pending_map_manifest = manifest.duplicate(true)
	_map_consent_state = Dictionary(_session.call("evaluate_client_map_manifest", manifest, local_map_paths))
	if bool(_map_consent_state.get("requires_consent", false)):
		_show_map_consent_prompt(_pending_map_manifest)
	else:
		_hide_map_consent_prompt()
	_refresh_from_session()
	return _map_consent_state.duplicate(true)


func accept_pending_map_download(map_json_text: String, cache_root: String = MAP_MANIFEST_SCRIPT.DOWNLOAD_ROOT) -> Dictionary:
	if _pending_map_manifest.is_empty():
		return {"accepted": false, "state": "no_pending_manifest", "can_start_client": false}
	_map_consent_state = Dictionary(_session.call("accept_map_download", _pending_map_manifest, map_json_text, cache_root))
	if bool(_map_consent_state.get("accepted", false)):
		_hide_map_consent_prompt()
		_status_label.text = "Map accepted."
		_play_ui_sfx("confirm", "accept_map_download")
	else:
		_show_map_consent_prompt(_pending_map_manifest)
		_status_label.text = "Map rejected: %s" % String(_map_consent_state.get("state", "invalid"))
		_play_ui_sfx("warning", "accept_map_download_failed")
	_refresh_from_session()
	return _map_consent_state.duplicate(true)


func reject_pending_map_download() -> Dictionary:
	if _pending_map_manifest.is_empty():
		return {"accepted": false, "state": "no_pending_manifest", "can_start_client": false}
	_map_consent_state = Dictionary(_session.call("reject_map_download", _pending_map_manifest))
	_hide_map_consent_prompt()
	_status_label.text = "Map download rejected."
	_play_ui_sfx("cancel", "reject_map_download")
	_refresh_from_session()
	return _map_consent_state.duplicate(true)


func configure_host_state_for_test(peer_ids: Array = []) -> void:
	_session.call("configure_host_state_for_test", peer_ids)


func configure_client_state_for_test(peer_ids: Array = []) -> void:
	_session.call("configure_client_state_for_test", peer_ids)


func set_peer_ready_for_test(peer_id: int, ready: bool) -> void:
	_session.call("set_peer_ready_for_test", peer_id, ready)


func set_player_name_for_tests(player_name: String) -> void:
	if _player_name_edit != null:
		_player_name_edit.text = player_name
	_apply_lobby_setup_to_session()


func set_player_roster_for_tests(roster_path: String) -> void:
	_select_option_by_metadata(_player_roster_option, roster_path)
	_apply_lobby_setup_to_session()


func set_player_team_for_tests(team_slot: String) -> void:
	_select_option_by_metadata(_player_team_option, team_slot)
	_apply_lobby_setup_to_session()


func set_team_play_mode_for_tests(team_play_mode: String) -> void:
	_select_option_by_metadata(_team_mode_option, team_play_mode)
	_apply_lobby_setup_to_session()


func set_lobby_map_for_tests(map_path: String) -> void:
	_select_option_by_metadata(_map_option, map_path)
	_apply_lobby_setup_to_session()
	_apply_selected_map_manifest()


func set_connection_mode_for_tests(connection_mode: String) -> void:
	_select_option_by_metadata(_connection_mode_option, connection_mode)
	_apply_lobby_setup_to_session()
	_refresh_connection_hint()


func get_session_snapshot() -> Dictionary:
	return Dictionary(_session.call("get_session_snapshot")).duplicate(true)


func get_lobby_ui_snapshot() -> Dictionary:
	var session_snapshot: Dictionary = get_session_snapshot()
	return {
		"has_multiplayer_session": _session != null and _session.get_script() == MULTIPLAYER_SESSION_SCRIPT,
		"host_controls_visible": _host_button.visible and _host_port_spin.visible,
		"join_controls_visible": _join_button.visible and _join_address_edit.visible and _join_port_spin.visible,
		"ready_visible": _ready_button.visible,
		"start_visible": _start_button.visible,
		"disconnect_visible": _disconnect_button.visible,
		"back_visible": _back_button.visible,
		"roster_mode_text": _roster_mode_summary_label.text,
		"roster_mode_selected": String(_roster_mode_option.get_item_metadata(_roster_mode_option.selected)) if _roster_mode_option.selected >= 0 else "",
		"roster_mode_disabled": _roster_mode_option.disabled,
		"status_text": _status_label.text,
		"team_readability_text": _team_readability_label.text,
		"team_badge_text": _build_team_badge_summary(session_snapshot),
		"team_badge_count": _team_badge_row.get_child_count(),
		"team_badges": _build_team_badge_data(session_snapshot),
		"peer_text": _peer_label.text,
		"assignment_text": _assignment_label.text,
		"role_readability": _role_readability_snapshot.duplicate(true),
		"settings_text": _settings_label.text,
		"map_consent_visible": _map_consent_panel.visible,
		"map_consent_text": _map_consent_label.text,
		"map_consent_state": _map_consent_state.duplicate(true),
		"setup": _build_lobby_setup_snapshot_from_controls(),
		"network_hint_text": _network_hint_label.text if _network_hint_label != null else "",
		"background": get_background_catalog_snapshot(),
		"start_disabled": _start_button.disabled,
		"ready_disabled": _ready_button.disabled,
		"disconnect_disabled": _disconnect_button.disabled,
		"mission_start_request_count": _mission_start_request_count,
		"last_start_assignments": _last_start_assignments.duplicate(true),
		"audio_sfx": get_audio_sfx_debug_snapshot(),
		"session": session_snapshot,
	}


func get_background_path() -> String:
	return String(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_path", LOBBY_BACKGROUND_ID))


func get_background_catalog_snapshot() -> Dictionary:
	var entry: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", LOBBY_BACKGROUND_ID))
	return {
		"background_id": LOBBY_BACKGROUND_ID,
		"path": get_background_path(),
		"entry": entry,
		"uses_catalog": not entry.is_empty(),
		"has_texture": _background_rect != null and _background_rect.texture != null,
		"dim_strength": _background_shade.color.a if _background_shade != null else 0.0,
	}


func get_audio_sfx_debug_snapshot() -> Dictionary:
	var bus = _ensure_audio_event_bus()
	if bus != null and bus.has_method("get_diagnostic_snapshot"):
		return Dictionary(bus.call("get_diagnostic_snapshot")).duplicate(true)
	return {}


func _ensure_audio_event_bus():
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus):
		return _audio_event_bus
	var settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path))
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree != null:
		var current_scene := tree.current_scene
		if current_scene != null:
			var scene_bus := current_scene.find_child("AudioEventBus", true, false)
			if scene_bus != null and scene_bus.has_method("emit_ui_action"):
				_audio_event_bus = scene_bus
				if _audio_event_bus.has_method("apply_settings"):
					_audio_event_bus.call("apply_settings", settings)
				return _audio_event_bus
		var root_bus := tree.root.find_child("AudioEventBus", true, false)
		if root_bus != null and root_bus.has_method("emit_ui_action"):
			_audio_event_bus = root_bus
			if _audio_event_bus.has_method("apply_settings"):
				_audio_event_bus.call("apply_settings", settings)
			return _audio_event_bus
	_audio_event_bus = AUDIO_EVENT_BUS_SCRIPT.new()
	_audio_event_bus.name = "AudioEventBus"
	var parent: Node = self
	if tree != null and tree.current_scene != null:
		parent = tree.current_scene
	parent.add_child(_audio_event_bus)
	if _audio_event_bus.has_method("initialize"):
		_audio_event_bus.call("initialize", "res://data/audio_sfx_catalog.json", settings)
	return _audio_event_bus


func _play_ui_sfx(action_type: String, action_id: String) -> void:
	var bus = _ensure_audio_event_bus()
	if bus == null or not bus.has_method("emit_ui_action"):
		return
	bus.call("emit_ui_action", action_type, {
		"action_id": action_id,
		"unit_id": "multiplayer_lobby",
		"dedupe_key": "multiplayer_lobby:%s" % action_id,
		"dedupe_window_msec": 40,
	})


func _ensure_background_nodes() -> void:
	_background_rect = get_node_or_null("Background") as TextureRect
	if _background_rect == null:
		_background_rect = TextureRect.new()
		_background_rect.name = "Background"
		_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_background_rect)
		move_child(_background_rect, 0)
	_background_rect.layout_mode = 1
	_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	_background_shade = get_node_or_null("BackgroundShade") as ColorRect
	if _background_shade == null:
		_background_shade = ColorRect.new()
		_background_shade.name = "BackgroundShade"
		_background_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_background_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_background_shade)
	move_child(_background_shade, 1)
	_background_shade.layout_mode = 1
	_background_shade.set_anchors_preset(Control.PRESET_FULL_RECT)


func _apply_background_texture() -> void:
	if _background_rect == null:
		return
	var result: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("apply_to_texture_rect", _background_rect, LOBBY_BACKGROUND_ID))
	var entry: Dictionary = Dictionary(result.get("entry", BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", LOBBY_BACKGROUND_ID)))
	var dim_strength: float = clampf(float(entry.get("dim_strength", 0.56)), 0.0, 0.95)
	if _background_shade != null:
		_background_shade.color = Color(0.015, 0.025, 0.03, dim_strength)


func _ensure_lobby_setup_controls() -> void:
	var vbox := get_node_or_null("Panel/Margin/VBox") as VBoxContainer
	if vbox == null:
		return
	var setup_panel := get_node_or_null("Panel/Margin/VBox/LobbySetupPanel") as PanelContainer
	if setup_panel == null:
		setup_panel = PanelContainer.new()
		setup_panel.name = "LobbySetupPanel"
		setup_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var margin := MarginContainer.new()
		margin.name = "Margin"
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		setup_panel.add_child(margin)
		var setup_vbox := VBoxContainer.new()
		setup_vbox.name = "VBox"
		setup_vbox.add_theme_constant_override("separation", 6)
		margin.add_child(setup_vbox)
		var title := Label.new()
		title.name = "SetupTitleLabel"
		title.text = "Spieler / Team / Map"
		setup_vbox.add_child(title)
		var grid := GridContainer.new()
		grid.name = "SetupGrid"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 6)
		setup_vbox.add_child(grid)
		_add_setup_label(grid, "Spielername", "multiplayer.player_name")
		_player_name_edit = _add_setup_line_edit(grid, "PlayerNameLineEdit", "Player", "multiplayer.player_name")
		_add_setup_label(grid, "Roster", "multiplayer.player_roster")
		_player_roster_option = _add_setup_option(grid, "PlayerRosterOptionButton", "multiplayer.player_roster")
		_add_setup_label(grid, "Spielerseite", "multiplayer.player_team")
		_player_team_option = _add_setup_option(grid, "PlayerTeamOptionButton", "multiplayer.player_team")
		_add_setup_label(grid, "Teammodus", "multiplayer.team_mode")
		_team_mode_option = _add_setup_option(grid, "TeamModeOptionButton", "multiplayer.team_mode")
		_add_setup_label(grid, "Map", "multiplayer.map_select")
		_map_option = _add_setup_option(grid, "MapOptionButton", "multiplayer.map_select")
		_add_setup_label(grid, "Verbindung", "multiplayer.connection_mode")
		_connection_mode_option = _add_setup_option(grid, "ConnectionModeOptionButton", "multiplayer.connection_mode")
		_network_hint_label = Label.new()
		_network_hint_label.name = "NetworkHintLabel"
		_network_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_network_hint_label.add_theme_font_size_override("font_size", 12)
		_apply_help_id(_network_hint_label, "multiplayer.connection_mode")
		setup_vbox.add_child(_network_hint_label)
		var host_join_grid := vbox.get_node_or_null("HostJoinGrid")
		vbox.add_child(setup_panel)
		if host_join_grid != null:
			vbox.move_child(setup_panel, host_join_grid.get_index())
	else:
		_player_name_edit = setup_panel.find_child("PlayerNameLineEdit", true, false) as LineEdit
		_player_roster_option = setup_panel.find_child("PlayerRosterOptionButton", true, false) as OptionButton
		_player_team_option = setup_panel.find_child("PlayerTeamOptionButton", true, false) as OptionButton
		_team_mode_option = setup_panel.find_child("TeamModeOptionButton", true, false) as OptionButton
		_map_option = setup_panel.find_child("MapOptionButton", true, false) as OptionButton
		_connection_mode_option = setup_panel.find_child("ConnectionModeOptionButton", true, false) as OptionButton
		_network_hint_label = setup_panel.find_child("NetworkHintLabel", true, false) as Label


func _enforce_lobby_panel_geometry() -> void:
	var panel := get_node_or_null("Panel") as Control
	if panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280.0, 720.0)
	var panel_size := Vector2(minf(LOBBY_PANEL_SIZE.x, viewport_size.x - 32.0), minf(LOBBY_PANEL_SIZE.y, viewport_size.y - 32.0))
	var panel_position := Vector2(
		floor((viewport_size.x - panel_size.x) * 0.5),
		floor((viewport_size.y - panel_size.y) * 0.5)
	)
	panel.custom_minimum_size = Vector2.ZERO
	panel.clip_contents = true
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y
	panel.position = panel_position
	panel.size = panel_size


func _add_setup_label(parent: Node, text: String, help_id: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(118.0, 0.0)
	_apply_help_id(label, help_id)
	parent.add_child(label)
	return label


func _add_setup_line_edit(parent: Node, node_name: String, placeholder: String, help_id: String) -> LineEdit:
	var line_edit := LineEdit.new()
	line_edit.name = node_name
	line_edit.placeholder_text = placeholder
	line_edit.text = placeholder
	line_edit.custom_minimum_size = Vector2(250.0, 34.0)
	_apply_help_id(line_edit, help_id)
	parent.add_child(line_edit)
	return line_edit


func _add_setup_option(parent: Node, node_name: String, help_id: String) -> OptionButton:
	var option := OptionButton.new()
	option.name = node_name
	option.custom_minimum_size = Vector2(250.0, 34.0)
	_apply_help_id(option, help_id)
	parent.add_child(option)
	return option


func _ensure_multiplayer_session() -> void:
	_session = get_node_or_null("MultiplayerSession")
	if _session == null:
		_session = MULTIPLAYER_SESSION_SCRIPT.new()
		_session.name = "MultiplayerSession"
		add_child(_session)
	if not _session.session_snapshot_changed.is_connected(_on_session_snapshot_changed):
		_session.session_snapshot_changed.connect(_on_session_snapshot_changed)
	if not _session.mission_start_requested.is_connected(_on_session_mission_start_requested):
		_session.mission_start_requested.connect(_on_session_mission_start_requested)
	if not _session.mission_assignments_changed.is_connected(_on_session_mission_assignments_changed):
		_session.mission_assignments_changed.connect(_on_session_mission_assignments_changed)
	if not _session.mission_rejoin_peer_block_changed.is_connected(_on_session_rejoin_peer_block_changed):
		_session.mission_rejoin_peer_block_changed.connect(_on_session_rejoin_peer_block_changed)
	if not _session.session_disconnected.is_connected(_on_session_disconnected):
		_session.session_disconnected.connect(_on_session_disconnected)


func _ensure_mission_host() -> void:
	_mission_host = get_node_or_null("MissionHost")
	if _mission_host == null:
		_mission_host = Node.new()
		_mission_host.name = "MissionHost"
		add_child(_mission_host)


func _configure_default_inputs() -> void:
	_host_port_spin.value = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT
	_join_port_spin.value = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT
	_join_address_edit.text = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_ADDRESS
	_configure_roster_mode_options()
	_configure_lobby_setup_options()
	_apply_lobby_setup_to_session()
	_apply_selected_map_manifest()
	_refresh_settings_summary()


func _connect_ui_signals() -> void:
	if not _host_button.pressed.is_connected(_on_host_pressed):
		_host_button.pressed.connect(_on_host_pressed)
	if not _host_port_spin.value_changed.is_connected(_on_lobby_setup_changed):
		_host_port_spin.value_changed.connect(_on_lobby_setup_changed)
	if not _join_button.pressed.is_connected(_on_join_pressed):
		_join_button.pressed.connect(_on_join_pressed)
	if not _ready_button.pressed.is_connected(_on_ready_pressed):
		_ready_button.pressed.connect(_on_ready_pressed)
	if not _start_button.pressed.is_connected(_on_start_pressed):
		_start_button.pressed.connect(_on_start_pressed)
	if not _disconnect_button.pressed.is_connected(_on_disconnect_pressed):
		_disconnect_button.pressed.connect(_on_disconnect_pressed)
	if not _back_button.pressed.is_connected(return_to_main_menu):
		_back_button.pressed.connect(return_to_main_menu)
	if not _roster_mode_option.item_selected.is_connected(_on_roster_mode_selected):
		_roster_mode_option.item_selected.connect(_on_roster_mode_selected)
	if _player_name_edit != null and not _player_name_edit.text_changed.is_connected(_on_lobby_setup_changed):
		_player_name_edit.text_changed.connect(_on_lobby_setup_changed)
	for option in [_player_roster_option, _player_team_option, _team_mode_option, _map_option, _connection_mode_option]:
		if option != null and not option.item_selected.is_connected(_on_lobby_setup_changed):
			option.item_selected.connect(_on_lobby_setup_changed)
	if not _map_accept_button.pressed.is_connected(_on_map_accept_pressed):
		_map_accept_button.pressed.connect(_on_map_accept_pressed)
	if not _map_reject_button.pressed.is_connected(_on_map_reject_pressed):
		_map_reject_button.pressed.connect(_on_map_reject_pressed)


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/HostJoinGrid"), "multiplayer_lobby.host_join")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/HostJoinGrid/HostPortLabel"), "multiplayer.host")
	_apply_help_id(_host_port_spin, "multiplayer.host")
	_apply_help_id(_host_button, "multiplayer.host")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/HostJoinGrid/JoinAddressLabel"), "multiplayer.join")
	_apply_help_id(_join_address_edit, "multiplayer.join")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/HostJoinGrid/JoinPortLabel"), "multiplayer.join")
	_apply_help_id(_join_port_spin, "multiplayer.join")
	_apply_help_id(_join_button, "multiplayer.join")
	_apply_help_id(_player_name_edit, "multiplayer.player_name")
	_apply_help_id(_player_roster_option, "multiplayer.player_roster")
	_apply_help_id(_player_team_option, "multiplayer.player_team")
	_apply_help_id(_team_mode_option, "multiplayer.team_mode")
	_apply_help_id(_map_option, "multiplayer.map_select")
	_apply_help_id(_connection_mode_option, "multiplayer.connection_mode")
	_apply_help_id(_network_hint_label, "multiplayer.connection_mode")
	_apply_help_id(_ready_button, "multiplayer.ready")
	_apply_help_id(_start_button, "multiplayer.start")
	_apply_help_id(_disconnect_button, "multiplayer.disconnect")
	_apply_help_id(_back_button, "multiplayer.disconnect")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/RosterModeRow/RosterModeLabel"), "multiplayer.roster_ownership")
	_apply_help_id(_roster_mode_option, "multiplayer.roster_ownership")
	_apply_help_id(_roster_mode_summary_label, "multiplayer.roster_ownership")
	_apply_help_id(_assignment_label, "multiplayer.roster_ownership")
	_apply_help_id(_settings_label, "settings.fog_of_war_mode")
	_apply_help_id(_map_consent_panel, "multiplayer.map_download")
	_apply_help_id(_map_consent_label, "multiplayer.map_download")
	_apply_help_id(_map_accept_button, "multiplayer.map_download")
	_apply_help_id(_map_reject_button, "multiplayer.map_download")


func _apply_help_id(node: Node, help_id: String) -> void:
	var control := node as Control
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	control.set_meta("help_id", normalized_id)


func _on_host_pressed() -> void:
	host_game()


func _on_join_pressed() -> void:
	join_game()


func _on_ready_pressed() -> void:
	var snapshot: Dictionary = get_session_snapshot()
	set_ready(not bool(snapshot.get("local_ready", false)))


func _on_start_pressed() -> void:
	start_mission()


func _on_disconnect_pressed() -> void:
	disconnect_game()


func _on_roster_mode_selected(index: int) -> void:
	if index < 0 or index >= _roster_mode_option.item_count:
		return
	set_roster_mode(String(_roster_mode_option.get_item_metadata(index)))


func _on_lobby_setup_changed(_value: Variant = null) -> void:
	_apply_lobby_setup_to_session()
	_apply_selected_map_manifest()
	_refresh_connection_hint()
	_refresh_lobby_controls(get_session_snapshot())


func _on_map_accept_pressed() -> void:
	_status_label.text = "Waiting for host map payload..."


func _on_map_reject_pressed() -> void:
	reject_pending_map_download()


func _on_session_snapshot_changed(snapshot: Dictionary) -> void:
	if has_active_mission() and not bool(snapshot.get("mission_started", false)):
		_retire_active_mission()
		_set_lobby_panel_visible(true)
	_apply_session_snapshot(snapshot)


func _on_session_mission_start_requested(assignments: Dictionary) -> void:
	_mission_start_request_count += 1
	_last_start_assignments = assignments.duplicate(true)
	_launch_mission(assignments)
	_status_label.text = "Mission running."
	_refresh_lobby_controls(get_session_snapshot())


func _on_session_mission_assignments_changed(assignments: Dictionary) -> void:
	_last_start_assignments = assignments.duplicate(true)
	if has_active_mission():
		_apply_session_assignments_to_simulation_root(_active_mission.get_node_or_null("SimulationRoot"), assignments)
		_apply_local_mission_fireteam_perspective(_active_mission, assignments)
	_apply_session_snapshot(get_session_snapshot())


func _on_session_rejoin_peer_block_changed(peer_id: int, blocked: bool) -> void:
	if not has_active_mission():
		return
	var simulation_root: Node = _active_mission.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_snapshot_peer_blocked"):
		simulation_root.call("set_snapshot_peer_blocked", peer_id, blocked)


func _on_session_disconnected(_message: String) -> void:
	_release_active_mission()
	_set_lobby_panel_visible(true)
	_refresh_from_session()


func _launch_mission(assignments: Dictionary) -> void:
	_release_active_mission()
	_ensure_mission_host()
	var mission_instance: Node = MISSION_SCENE.instantiate()
	_apply_session_assignments_to_simulation_root(mission_instance.get_node_or_null("SimulationRoot"), assignments)
	var startup_combat_driver: Node = mission_instance.get_node_or_null("CombatLoopDriver")
	if startup_combat_driver != null and startup_combat_driver.has_method("set_combat_startup_grace_ticks"):
		startup_combat_driver.call("set_combat_startup_grace_ticks", PRODUCT_MISSION_COMBAT_STARTUP_GRACE_TICKS)
	_mission_host.add_child(mission_instance)
	_active_mission = mission_instance
	initialize_multiplayer_mission_dropships(mission_instance, assignments, bool(get_session_snapshot().get("is_host", false)))
	_apply_local_mission_fireteam_perspective(mission_instance, assignments)
	var combat_driver: Node = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver != null and combat_driver.has_signal("combat_resolved"):
		var resolved_callable := Callable(self, "_on_product_mission_resolved")
		if not combat_driver.is_connected("combat_resolved", resolved_callable):
			combat_driver.connect("combat_resolved", resolved_callable)
	if not bool(get_session_snapshot().get("is_host", false)):
		_session.rpc_id(1, "notify_mission_runtime_ready")
	_set_lobby_panel_visible(false)


func initialize_multiplayer_mission_dropships(mission_instance: Node, assignments: Dictionary, is_host: bool) -> bool:
	if not is_host or mission_instance == null:
		return false
	var controller: Node = mission_instance.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("set_planning_state"):
		return false
	var planning_state: Dictionary = Dictionary(MULTIPLAYER_DROPSHIP_BOOTSTRAP_SCRIPT.call("build_initial_planning_state", controller, assignments))
	if planning_state.is_empty():
		return false
	controller.call("set_planning_state", planning_state)
	return true


func _apply_local_mission_fireteam_perspective(mission_instance: Node, assignments: Dictionary) -> void:
	if mission_instance == null:
		return
	var controller: Node = mission_instance.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("apply_local_multiplayer_fireteam_perspective"):
		return
	var local_peer_id: int = multiplayer.get_unique_id()
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	controller.call("apply_local_multiplayer_fireteam_perspective", PackedStringArray(peer_fireteams.get(local_peer_id, PackedStringArray())))


func _release_active_mission() -> void:
	if _active_mission != null and is_instance_valid(_active_mission):
		_active_mission.queue_free()
	_active_mission = null


func _retire_active_mission() -> void:
	if not has_active_mission():
		return
	var retiring_mission: Node = _active_mission
	_active_mission = null
	_free_retired_mission_after_network_drain(retiring_mission)


func _free_retired_mission_after_network_drain(retiring_mission: Node) -> void:
	for _frame in range(4):
		await get_tree().process_frame
	if retiring_mission != null and is_instance_valid(retiring_mission):
		retiring_mission.queue_free()


func _set_lobby_panel_visible(visible: bool) -> void:
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = visible
	if _background_rect != null:
		_background_rect.visible = visible
	if _background_shade != null:
		_background_shade.visible = visible


func _on_product_mission_resolved(_mission_result: Dictionary) -> void:
	if not bool(get_session_snapshot().get("is_host", false)):
		return
	var simulation_root: Node = _active_mission.get_node_or_null("SimulationRoot") if has_active_mission() else null
	if simulation_root != null and simulation_root.has_method("set_snapshot_broadcast_paused"):
		simulation_root.call("set_snapshot_broadcast_paused", true)
	_retire_active_mission()
	_set_lobby_panel_visible(true)
	_session.call("complete_mission")


func _apply_session_assignments_to_simulation_root(simulation_root: Node, assignments: Dictionary) -> void:
	if simulation_root == null:
		return
	simulation_root.set("is_server_authoritative", true)
	if simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", Dictionary(assignments.get("peer_teams", {})).duplicate(true))
	if simulation_root.has_method("set_peer_role_assignments"):
		simulation_root.call("set_peer_role_assignments", Dictionary(assignments.get("peer_roles", {})).duplicate(true))
	if simulation_root.has_method("set_peer_fireteam_assignments"):
		simulation_root.call("set_peer_fireteam_assignments", Dictionary(assignments.get("peer_fireteams", {})).duplicate(true))


func _refresh_from_session() -> void:
	_apply_session_snapshot(get_session_snapshot())


func _apply_session_snapshot(snapshot: Dictionary) -> void:
	_status_label.text = String(snapshot.get("status_text", "Ready. Host or join a local session."))
	if snapshot.has("map_transfer"):
		_map_consent_state = Dictionary(snapshot.get("map_transfer", _map_consent_state)).duplicate(true)
	_apply_roster_mode_snapshot(Dictionary(snapshot.get("roster", {})))
	_role_readability_snapshot = _build_lobby_role_readability_snapshot(snapshot)
	_peer_label.text = String(_role_readability_snapshot.get("peer_text", "EINSATZROLLEN\n-"))
	_assignment_label.text = String(_role_readability_snapshot.get("assignment_text", "LOBBY\n-"))
	_team_readability_label.text = _build_team_readability_text(snapshot)
	_team_readability_label.visible = not _team_readability_label.text.strip_edges().is_empty()
	_refresh_team_badges(snapshot)
	_refresh_settings_summary()
	_refresh_lobby_controls(snapshot)


func _refresh_lobby_controls(snapshot: Dictionary) -> void:
	var has_active_peer: bool = bool(snapshot.get("has_active_peer", false))
	var can_toggle_ready: bool = bool(snapshot.get("can_toggle_ready", false))
	var can_disconnect: bool = bool(snapshot.get("can_disconnect", false))
	var is_host: bool = bool(snapshot.get("is_host", false))
	var can_start: bool = bool(snapshot.get("can_start_mission", false))
	var local_ready: bool = bool(snapshot.get("local_ready", false))
	_host_button.disabled = has_active_peer or bool(snapshot.get("mission_started", false))
	_join_button.disabled = has_active_peer or bool(snapshot.get("mission_started", false))
	_ready_button.visible = has_active_peer or can_toggle_ready
	_ready_button.disabled = not can_toggle_ready
	_ready_button.text = "Unready" if local_ready else "Ready"
	_start_button.visible = is_host
	_start_button.disabled = not can_start
	_disconnect_button.visible = has_active_peer or can_disconnect
	_disconnect_button.disabled = not can_disconnect
	_roster_mode_option.disabled = not is_host or bool(snapshot.get("mission_started", false))
	var mission_started: bool = bool(snapshot.get("mission_started", false))
	for control in [_player_name_edit, _player_roster_option, _player_team_option, _connection_mode_option]:
		if control is LineEdit:
			(control as LineEdit).editable = not mission_started
		elif control is OptionButton:
			(control as OptionButton).disabled = mission_started
	for host_only_control in [_team_mode_option, _map_option]:
		if host_only_control != null:
			host_only_control.disabled = mission_started or has_active_peer


func _show_map_consent_prompt(manifest: Dictionary) -> void:
	var prompt: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_download_prompt", manifest, 1))
	_map_consent_panel.visible = bool(prompt.get("visible", false))
	_map_consent_label.text = String(prompt.get("message", "Host bietet eine unbekannte Map an."))


func _hide_map_consent_prompt() -> void:
	_map_consent_panel.visible = false


func _configure_lobby_setup_options() -> void:
	if _player_name_edit != null and _player_name_edit.text.strip_edges().is_empty():
		_player_name_edit.text = "Player"
	_populate_roster_options()
	_populate_team_options()
	_populate_team_mode_options()
	_populate_map_options()
	_populate_connection_mode_options()
	_refresh_connection_hint()


func _populate_roster_options() -> void:
	if _player_roster_option == null:
		return
	_player_roster_option.clear()
	var roster_entries: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("list_roster_entries"))
	if int(roster_entries.get("entry_count", 0)) <= 0:
		PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster")
		roster_entries = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("list_roster_entries"))
	var active_index: int = -1
	for entry_variant in Array(roster_entries.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("valid", false)):
			continue
		var label: String = String(entry.get("team_name", "Team")).strip_edges()
		if label.is_empty():
			label = String(entry.get("path", "Roster")).get_file().get_basename()
		if bool(entry.get("active", false)):
			label = "%s (aktiv)" % label
		_player_roster_option.add_item(label)
		var item_index: int = _player_roster_option.item_count - 1
		_player_roster_option.set_item_metadata(item_index, String(entry.get("path", "")))
		if bool(entry.get("active", false)):
			active_index = item_index
	if _player_roster_option.item_count <= 0:
		_player_roster_option.add_item("Kein Roster gefunden")
		_player_roster_option.set_item_metadata(0, "")
	elif active_index >= 0:
		_player_roster_option.select(active_index)
	else:
		_player_roster_option.select(0)


func _populate_team_options() -> void:
	if _player_team_option == null:
		return
	_player_team_option.clear()
	_player_team_option.add_item("Alpha / Spieler")
	_player_team_option.set_item_metadata(0, "team_alpha")
	_player_team_option.add_item("Bravo / Gegner")
	_player_team_option.set_item_metadata(1, "team_bravo")
	_player_team_option.select(0)


func _populate_team_mode_options() -> void:
	if _team_mode_option == null:
		return
	_team_mode_option.clear()
	_team_mode_option.add_item("Zusammen")
	_team_mode_option.set_item_metadata(0, TEAM_PLAY_MODE_COOP)
	_team_mode_option.add_item("Gegeneinander")
	_team_mode_option.set_item_metadata(1, TEAM_PLAY_MODE_VERSUS)
	_team_mode_option.select(0)


func _populate_map_options() -> void:
	if _map_option == null:
		return
	_map_option.clear()
	var dir := DirAccess.open("res://maps")
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var path: String = "res://maps/%s" % file_name
				_map_option.add_item(file_name.get_basename())
				_map_option.set_item_metadata(_map_option.item_count - 1, path)
			file_name = dir.get_next()
		dir.list_dir_end()
	if _map_option.item_count <= 0:
		_map_option.add_item("Keine Map gefunden")
		_map_option.set_item_metadata(0, "")
		return
	for index in range(_map_option.item_count):
		if String(_map_option.get_item_metadata(index)).ends_with(DEFAULT_MAP_FILE_NAME):
			_map_option.select(index)
			return
	_map_option.select(0)


func _populate_connection_mode_options() -> void:
	if _connection_mode_option == null:
		return
	_connection_mode_option.clear()
	_connection_mode_option.add_item("LAN / VPN")
	_connection_mode_option.set_item_metadata(0, CONNECTION_MODE_LAN)
	_connection_mode_option.add_item("Direct IP Internet")
	_connection_mode_option.set_item_metadata(1, CONNECTION_MODE_DIRECT_WAN)
	_connection_mode_option.add_item("UPnP Internet")
	_connection_mode_option.set_item_metadata(2, CONNECTION_MODE_UPNP)
	_connection_mode_option.select(0)


func _configure_roster_mode_options() -> void:
	_roster_mode_option.clear()
	for mode in MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.VALID_ROSTER_MODES:
		_roster_mode_option.add_item(String(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("get_roster_mode_label", mode)))
		_roster_mode_option.set_item_metadata(_roster_mode_option.item_count - 1, String(mode))
	var session_snapshot: Dictionary = Dictionary(_session.call("get_session_snapshot"))
	_apply_roster_mode_snapshot(Dictionary(session_snapshot.get("roster", {})))


func _apply_roster_mode_snapshot(roster_snapshot: Dictionary) -> void:
	var mode: String = String(roster_snapshot.get("roster_mode", MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.ROSTER_MODE_HOST_ROSTER))
	for index in range(_roster_mode_option.item_count):
		if String(_roster_mode_option.get_item_metadata(index)) == mode:
			_roster_mode_option.select(index)
			break
	_roster_mode_summary_label.text = "Roster: %s | local=%s | authority=%s" % [
		String(roster_snapshot.get("roster_mode_label", MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("get_roster_mode_label", mode))),
		str(bool(roster_snapshot.get("uses_local_roster", false))),
		String(roster_snapshot.get("mission_authority", MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.CHARACTER_GAMEPLAY_AUTHORITY)),
	]


func _apply_lobby_setup_to_session() -> void:
	if _session == null or not _session.has_method("set_lobby_player_setup"):
		return
	_session.call("set_lobby_player_setup", _build_lobby_setup_snapshot_from_controls())


func _apply_selected_map_manifest() -> void:
	if _session == null or not _session.has_method("set_host_map_manifest"):
		return
	var setup: Dictionary = _build_lobby_setup_snapshot_from_controls()
	var map_path: String = String(setup.get("map_path", "")).strip_edges()
	if map_path.is_empty() or not FileAccess.file_exists(map_path):
		return
	var manifest: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", map_path, "", String(setup.get("player_name", ""))))
	_session.call("set_host_map_manifest", manifest)


func _build_lobby_setup_snapshot_from_controls() -> Dictionary:
	return {
		"player_name": _player_name_edit.text.strip_edges() if _player_name_edit != null else "Player",
		"roster_path": _get_selected_option_metadata(_player_roster_option),
		"team_slot": _get_selected_option_metadata(_player_team_option),
		"team_play_mode": _get_selected_option_metadata(_team_mode_option),
		"map_path": _get_selected_option_metadata(_map_option),
		"connection_mode": _get_selected_option_metadata(_connection_mode_option),
	}


func _get_selected_option_metadata(option: OptionButton) -> String:
	if option == null or option.selected < 0 or option.selected >= option.item_count:
		return ""
	return String(option.get_item_metadata(option.selected)).strip_edges()


func _select_option_by_metadata(option: OptionButton, metadata: String) -> bool:
	if option == null:
		return false
	var normalized: String = metadata.strip_edges()
	for index in range(option.item_count):
		if String(option.get_item_metadata(index)).strip_edges() == normalized:
			option.select(index)
			return true
	return false


func _refresh_connection_hint() -> void:
	if _network_hint_label == null:
		return
	var mode: String = _get_selected_option_metadata(_connection_mode_option)
	var port: int = int(_host_port_spin.value) if _host_port_spin != null else MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT
	if mode == CONNECTION_MODE_UPNP:
		_network_hint_label.text = "UPnP: Host versucht UDP-Port %d automatisch am Router zu oeffnen. Wenn der Router UPnP blockt: manuell freigeben oder VPN nutzen." % port
	elif mode == CONNECTION_MODE_DIRECT_WAN:
		_network_hint_label.text = "Internet Direct IP: Host braucht UDP-Port %d in Firewall und Router weitergeleitet; Client nutzt die oeffentliche IP oder VPN." % port
	else:
		_network_hint_label.text = "LAN/VPN: beide Spieler muessen im selben lokalen Netz oder VPN sein. Fuer Internet Direct IP bitte Portfreigabe oder UPnP nutzen."


func _refresh_settings_summary() -> void:
	var settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path))
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", settings))
	_settings_label.text = "FoW: %s" % String(snapshot.get("fog_of_war_mode", "known_terrain"))


func _build_lobby_role_readability_snapshot(snapshot: Dictionary) -> Dictionary:
	var assignments: Dictionary = Dictionary(snapshot.get("assignments", {}))
	var roles: Dictionary = Dictionary(assignments.get("peer_roles", {}))
	var fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	var local_peer_id: int = int(snapshot.get("local_peer_id", 0))
	var peers: Array = Array(snapshot.get("peers", [])).duplicate(true)
	peers.sort_custom(func(left: Variant, right: Variant) -> bool:
		return int(Dictionary(left).get("peer_id", 0)) < int(Dictionary(right).get("peer_id", 0))
	)
	var peer_lines := PackedStringArray(["EINSATZROLLEN"])
	var active_count := 0
	var spectator_count := 0
	var local_role_label := ""
	for peer_variant in peers:
		if typeof(peer_variant) != TYPE_DICTIONARY:
			continue
		var peer: Dictionary = Dictionary(peer_variant)
		var peer_id: int = int(peer.get("peer_id", 0))
		var role_id: String = String(roles.get(peer_id, peer.get("role_id", ""))).strip_edges().to_lower()
		var assigned_fireteams := PackedStringArray(fireteams.get(peer_id, peer.get("fireteam_ids", PackedStringArray())))
		var role_label: String = _build_lobby_role_label(role_id, assigned_fireteams)
		if role_id == "spectator" or assigned_fireteams.is_empty():
			spectator_count += 1
		else:
			active_count += 1
		if peer_id == local_peer_id:
			local_role_label = role_label
		var local_prefix: String = "DU | " if peer_id == local_peer_id else ""
		peer_lines.append("%s%s | %s | %s" % [
			local_prefix,
			String(peer.get("display_name", "Player")).strip_edges(),
			role_label,
			"BEREIT" if bool(peer.get("ready", false)) else "NICHT BEREIT",
		])
	if peers.is_empty():
		peer_lines[0] = "EINSATZROLLEN | -"
	var mode: String = String(assignments.get("team_play_mode", TEAM_PLAY_MODE_COOP)).strip_edges().to_lower()
	var mode_label: String = "VERSUS" if mode == TEAM_PLAY_MODE_VERSUS else "COOP"
	var assignment_lines := PackedStringArray(["%s | %d AKTIV | %d ZUSCHAUER" % [mode_label, active_count, spectator_count]])
	if mode == TEAM_PLAY_MODE_COOP and spectator_count > 0:
		assignment_lines.append("Zuschauer ruecken vor dem Start nach, sobald ein Fireteam frei wird.")
	return {
		"schema": "lobby_role_readability_v1",
		"ui_sets_gameplay_truth": false,
		"team_play_mode": mode,
		"active_count": active_count,
		"spectator_count": spectator_count,
		"local_role_label": local_role_label,
		"peer_text": "\n".join(peer_lines),
		"assignment_text": "\n".join(assignment_lines),
	}


func _build_lobby_role_label(role_id: String, fireteam_ids: PackedStringArray) -> String:
	if role_id == "spectator" or fireteam_ids.is_empty():
		return "ZUSCHAUER"
	var fireteam_label: String = " + ".join(fireteam_ids).to_upper()
	if role_id == "host":
		return "HOST / %s" % fireteam_label
	return "AKTIV / %s" % fireteam_label


func _build_team_readability_text(snapshot: Dictionary) -> String:
	var direct_summary: String = String(snapshot.get("team_readability_summary", "")).strip_edges()
	if not direct_summary.is_empty():
		return direct_summary
	var team_readability: Dictionary = Dictionary(snapshot.get("team_readability", {}))
	return String(team_readability.get("summary_text", "")).strip_edges()


func _refresh_team_badges(snapshot: Dictionary) -> void:
	for child in _team_badge_row.get_children():
		child.queue_free()
	var badge_entries: Array = _build_team_badge_data(snapshot)
	_team_badge_row.visible = not badge_entries.is_empty()
	for entry_variant in badge_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var label := Label.new()
		label.text = String(entry.get("badge_text", ""))
		label.tooltip_text = String(entry.get("tooltip", ""))
		label.custom_minimum_size = Vector2(192.0, 30.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
		label.add_theme_stylebox_override("normal", _make_team_badge_style(String(entry.get("team_color_hex", ""))))
		_team_badge_row.add_child(label)


func _build_team_badge_data(snapshot: Dictionary) -> Array:
	var team_readability: Dictionary = Dictionary(snapshot.get("team_readability", {}))
	var result: Array = []
	for entry_variant in Array(team_readability.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var badge_text: String = String(entry.get("badge_text", "")).strip_edges()
		if badge_text.is_empty():
			badge_text = "%s | %s | %s" % [
				String(entry.get("short_label", "Team")),
				String(entry.get("ownership_label", "Unassigned")),
				String(entry.get("spawn_marker_id", "spawn ?")),
			]
		result.append({
			"team_id": String(entry.get("team_id", "")),
			"team_color_hex": String(entry.get("team_color_hex", "#9aa3ad")),
			"badge_text": badge_text,
			"spawn_chip_text": String(entry.get("spawn_chip_text", "")),
			"tooltip": "%s | %s | %s" % [
				String(entry.get("display_name", "")),
				String(entry.get("control_label", "")),
				String(entry.get("spawn_label", "")),
			],
		})
	return result


func _build_team_badge_summary(snapshot: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for entry_variant in _build_team_badge_data(snapshot):
		var entry: Dictionary = Dictionary(entry_variant)
		var text: String = String(entry.get("badge_text", "")).strip_edges()
		if not text.is_empty():
			parts.append(text)
	return " || ".join(parts)


func _make_team_badge_style(color_hex: String) -> StyleBoxFlat:
	var team_color: Color = Color.from_string(color_hex.strip_edges(), Color(0.45, 0.52, 0.58, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = team_color.darkened(0.45)
	style.border_color = team_color.lightened(0.15)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style
