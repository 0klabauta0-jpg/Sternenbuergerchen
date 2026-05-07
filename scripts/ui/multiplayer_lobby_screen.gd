extends Control

signal back_requested

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const LOBBY_BACKGROUND_ID: String = "multiplayer_lobby_hangar"

@onready var _status_label: Label = get_node("Panel/Margin/VBox/StatusLabel")
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


func _ready() -> void:
	set_meta("multiplayer_lobby_screen", true)
	_ensure_background_nodes()
	_apply_background_texture()
	_ensure_multiplayer_session()
	_ensure_audio_event_bus()
	_configure_default_inputs()
	_connect_ui_signals()
	_apply_contextual_help_ids()
	_refresh_from_session()


func host_game(port: int = -1) -> bool:
	var resolved_port: int = port if port > 0 else int(_host_port_spin.value)
	var ok: bool = bool(_session.call("start_host", resolved_port))
	_play_ui_sfx("confirm" if ok else "warning", "host_game")
	return ok


func join_game(address: String = "", port: int = -1) -> bool:
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
		"peer_text": _peer_label.text,
		"assignment_text": _assignment_label.text,
		"settings_text": _settings_label.text,
		"map_consent_visible": _map_consent_panel.visible,
		"map_consent_text": _map_consent_label.text,
		"map_consent_state": _map_consent_state.duplicate(true),
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
	if not _session.session_disconnected.is_connected(_on_session_disconnected):
		_session.session_disconnected.connect(_on_session_disconnected)


func _configure_default_inputs() -> void:
	_host_port_spin.value = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT
	_join_port_spin.value = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_PORT
	_join_address_edit.text = MULTIPLAYER_SESSION_SCRIPT.DEFAULT_ADDRESS
	_configure_roster_mode_options()
	_refresh_settings_summary()


func _connect_ui_signals() -> void:
	if not _host_button.pressed.is_connected(_on_host_pressed):
		_host_button.pressed.connect(_on_host_pressed)
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


func _on_map_accept_pressed() -> void:
	_status_label.text = "Waiting for host map payload..."


func _on_map_reject_pressed() -> void:
	reject_pending_map_download()


func _on_session_snapshot_changed(snapshot: Dictionary) -> void:
	_apply_session_snapshot(snapshot)


func _on_session_mission_start_requested(assignments: Dictionary) -> void:
	_mission_start_request_count += 1
	_last_start_assignments = assignments.duplicate(true)
	_status_label.text = "Mission start requested by host."
	_refresh_lobby_controls(get_session_snapshot())


func _on_session_disconnected(_message: String) -> void:
	_refresh_from_session()


func _refresh_from_session() -> void:
	_apply_session_snapshot(get_session_snapshot())


func _apply_session_snapshot(snapshot: Dictionary) -> void:
	_status_label.text = String(snapshot.get("status_text", "Ready. Host or join a local session."))
	if snapshot.has("map_transfer"):
		_map_consent_state = Dictionary(snapshot.get("map_transfer", _map_consent_state)).duplicate(true)
	_apply_roster_mode_snapshot(Dictionary(snapshot.get("roster", {})))
	_peer_label.text = _format_peer_lines(Array(snapshot.get("peers", [])))
	_assignment_label.text = _format_assignment_lines(Dictionary(snapshot.get("assignments", {})))
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


func _show_map_consent_prompt(manifest: Dictionary) -> void:
	var prompt: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_download_prompt", manifest, 1))
	_map_consent_panel.visible = bool(prompt.get("visible", false))
	_map_consent_label.text = String(prompt.get("message", "Host bietet eine unbekannte Map an."))


func _hide_map_consent_prompt() -> void:
	_map_consent_panel.visible = false


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


func _refresh_settings_summary() -> void:
	var settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path))
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", settings))
	_settings_label.text = "FoW: %s" % String(snapshot.get("fog_of_war_mode", "known_terrain"))


func _format_peer_lines(peers: Array) -> String:
	if peers.is_empty():
		return "Peers: -"
	var lines: PackedStringArray = PackedStringArray(["Peers:"])
	for peer_variant in peers:
		if typeof(peer_variant) != TYPE_DICTIONARY:
			continue
		var peer: Dictionary = Dictionary(peer_variant)
		lines.append("#%d %s %s ready=%s" % [
			int(peer.get("peer_id", 0)),
			String(peer.get("team_id", "")),
			String(peer.get("role_id", "")),
			str(bool(peer.get("ready", false))),
		])
	return "\n".join(lines)


func _format_assignment_lines(assignments: Dictionary) -> String:
	var roles: Dictionary = Dictionary(assignments.get("peer_roles", {}))
	var teams: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	var fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	if roles.is_empty() and teams.is_empty() and fireteams.is_empty():
		return "Assignments: -"
	var lines: PackedStringArray = PackedStringArray(["Assignments:"])
	for peer_id_variant in teams.keys():
		var peer_id: int = int(peer_id_variant)
		lines.append("#%d %s %s %s" % [
			peer_id,
			String(teams.get(peer_id_variant, "")),
			String(roles.get(peer_id_variant, "")),
			",".join(PackedStringArray(fireteams.get(peer_id_variant, PackedStringArray()))),
		])
	return "\n".join(lines)
