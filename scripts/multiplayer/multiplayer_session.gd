class_name MultiplayerSession
extends Node

signal session_snapshot_changed(snapshot: Dictionary)
signal mission_start_requested(assignments: Dictionary)
signal session_disconnected(message: String)

const MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")

const DEFAULT_PORT: int = 7777
const DEFAULT_ADDRESS: String = "127.0.0.1"
const DEFAULT_MAX_PLAYERS: int = 2
const HOST_PEER_ID: int = 1

const STATE_IDLE: String = "idle"
const STATE_HOSTING: String = "hosting"
const STATE_CONNECTING: String = "connecting"
const STATE_JOINED: String = "joined"
const STATE_MISSION: String = "mission"

const ROLE_HOST: String = "host"
const ROLE_COMMANDER: String = "commander"
const ROLE_FIRETEAM: String = "fireteam"
const ROLE_SPECTATOR: String = "spectator"
const ALLOWED_CLIENT_ROLES: PackedStringArray = [
	ROLE_COMMANDER,
	ROLE_FIRETEAM,
	ROLE_SPECTATOR,
]
const TEAM_PLAY_MODE_COOP: String = "coop"
const TEAM_PLAY_MODE_VERSUS: String = "versus"
const VALID_TEAM_PLAY_MODES: PackedStringArray = [
	TEAM_PLAY_MODE_COOP,
	TEAM_PLAY_MODE_VERSUS,
]
const CONNECTION_MODE_LAN: String = "lan"
const CONNECTION_MODE_DIRECT_WAN: String = "direct_wan"
const CONNECTION_MODE_UPNP: String = "upnp"
const VALID_CONNECTION_MODES: PackedStringArray = [
	CONNECTION_MODE_LAN,
	CONNECTION_MODE_DIRECT_WAN,
	CONNECTION_MODE_UPNP,
]

@export var max_players: int = DEFAULT_MAX_PLAYERS
@export var default_port: int = DEFAULT_PORT
@export var default_address: String = DEFAULT_ADDRESS
@export var host_team_id: String = "team_alpha"
@export var client_team_id: String = "team_bravo"
@export var client_role_id: String = ROLE_COMMANDER
@export var host_fireteam_ids: PackedStringArray = PackedStringArray(["blue", "gold"])
@export var client_fireteam_ids: PackedStringArray = PackedStringArray(["red"])
@export var roster_mode: String = MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.ROSTER_MODE_PLAYER_ROSTERS

var _peers_by_id: Dictionary = {}
var _connection_state: String = STATE_IDLE
var _last_status_text: String = "Ready. Host or join a local test session."
var _last_error: String = ""
var _mission_started: bool = false
var _last_start_assignments: Dictionary = {}
var _local_is_host: bool = false
var _host_map_manifest: Dictionary = {}
var _map_transfer_state: Dictionary = {
	"state": "none",
	"requires_consent": false,
	"can_start_client": true,
}
var _player_name: String = "Player"
var _selected_roster_path: String = ""
var _selected_team_slot: String = "team_alpha"
var _team_play_mode: String = TEAM_PLAY_MODE_COOP
var _selected_map_path: String = ""
var _connection_mode: String = CONNECTION_MODE_LAN
var _upnp_mapping: Dictionary = {
	"enabled": false,
	"attempted": false,
	"mapped": false,
	"external_address": "",
	"port": 0,
	"result": "not_requested",
}


func _ready() -> void:
	_connect_multiplayer_signals()
	_emit_snapshot()


func start_host(port: int = DEFAULT_PORT) -> bool:
	_clear_multiplayer_peer()
	_reset_session_state(false)

	var peer := ENetMultiplayerPeer.new()
	var max_clients: int = maxi(1, max_players - 1)
	var error: Error = peer.create_server(port, max_clients)
	if error != OK:
		_last_error = error_string(error)
		_last_status_text = "Host failed: %s" % _last_error
		_emit_snapshot()
		return false

	multiplayer.multiplayer_peer = peer
	_prepare_host_network_mode(port)
	_configure_host_state()
	_broadcast_snapshot()
	return true


func join_session(address: String = DEFAULT_ADDRESS, port: int = DEFAULT_PORT) -> bool:
	_clear_multiplayer_peer()
	_reset_session_state(false)

	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		_last_error = error_string(error)
		_last_status_text = "Join failed: %s" % _last_error
		_emit_snapshot()
		return false

	multiplayer.multiplayer_peer = peer
	_connection_state = STATE_CONNECTING
	_last_status_text = "Connecting to %s:%d..." % [address, port]
	_emit_snapshot()
	return true


func disconnect_session(message: String = "Disconnected. Back in lobby.") -> void:
	_clear_multiplayer_peer()
	_reset_session_state(false)
	_last_status_text = message
	_emit_snapshot()
	session_disconnected.emit(message)


func set_local_ready(ready: bool) -> bool:
	if not _has_active_peer() and _connection_state != STATE_HOSTING:
		return false
	if _mission_started:
		return false

	if _is_authority_session():
		_set_peer_ready(HOST_PEER_ID, ready)
		_refresh_status_text()
		_emit_snapshot()
		_broadcast_snapshot()
		return true

	request_set_ready.rpc_id(HOST_PEER_ID, ready)
	_last_status_text = "Ready sent. Waiting for host..."
	_emit_snapshot()
	return true


func request_start_mission() -> bool:
	if not _is_authority_session():
		return false
	if not can_start_mission():
		return false

	_mission_started = true
	_connection_state = STATE_MISSION
	_last_start_assignments = build_session_assignments()
	_last_status_text = "Mission starting..."
	_emit_snapshot()
	_receive_start_mission.rpc(_last_start_assignments)
	mission_start_requested.emit(_last_start_assignments.duplicate(true))
	return true


func complete_mission() -> void:
	_mission_started = false
	if _connection_state == STATE_MISSION:
		_connection_state = STATE_HOSTING if _is_authority_session() else STATE_JOINED
	for peer_id in _peers_by_id.keys():
		_set_peer_ready(int(peer_id), false)
	_refresh_status_text()
	_emit_snapshot()
	_broadcast_snapshot()


func can_start_mission() -> bool:
	if not _is_authority_session() or _mission_started:
		return false
	if _peers_by_id.size() < max_players:
		return false
	return _are_all_connected_peers_ready()


func get_session_snapshot() -> Dictionary:
	return {
		"connection_state": _connection_state,
		"status_text": _last_status_text,
		"last_error": _last_error,
		"has_active_peer": _has_active_peer(),
		"is_host": _is_authority_session(),
		"is_client": _connection_state == STATE_JOINED,
		"local_peer_id": _get_local_peer_id(),
		"max_players": max_players,
		"connected_count": _peers_by_id.size(),
		"ready_count": _count_ready_peers(),
		"can_start_mission": can_start_mission(),
		"can_toggle_ready": (_connection_state == STATE_HOSTING or _connection_state == STATE_JOINED) and not _mission_started,
		"can_disconnect": _has_active_peer() or _connection_state == STATE_HOSTING or _connection_state == STATE_JOINED,
		"mission_started": _mission_started,
		"local_ready": _is_local_peer_ready(),
		"peers": _build_peer_snapshot_array(),
		"assignments": build_session_assignments(),
		"roster": MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("build_lobby_roster_mode_snapshot", roster_mode, _get_local_peer_id()),
		"map_manifest": _host_map_manifest.duplicate(true),
		"map_transfer": _map_transfer_state.duplicate(true),
		"lobby_setup": get_lobby_setup_snapshot(),
		"upnp": _upnp_mapping.duplicate(true),
	}


func build_session_assignments() -> Dictionary:
	return {
		"peer_teams": get_peer_team_assignments(),
		"peer_roles": get_peer_role_assignments(),
		"peer_fireteams": get_peer_fireteam_assignments(),
		"peer_rosters": get_peer_roster_assignments(),
		"roster_mode": MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("normalize_roster_mode", roster_mode),
		"team_play_mode": _team_play_mode,
		"selected_map_path": _selected_map_path,
		"lobby_setup": get_lobby_setup_snapshot(),
	}


func set_roster_mode(mode: String) -> bool:
	if not bool(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("is_valid_roster_mode", mode)):
		return false
	if _mission_started:
		return false
	if _connection_state == STATE_JOINED and not _is_authority_session():
		return false
	roster_mode = String(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("normalize_roster_mode", mode))
	_refresh_peer_roster_identities()
	_emit_snapshot()
	_broadcast_snapshot()
	return true


func get_roster_mode() -> String:
	return String(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("normalize_roster_mode", roster_mode))


func set_lobby_player_setup(setup: Dictionary) -> bool:
	if _mission_started:
		return false
	var previous_setup: Dictionary = get_lobby_setup_snapshot()
	_player_name = _normalize_player_name(String(setup.get("player_name", _player_name)))
	_selected_roster_path = String(setup.get("roster_path", _selected_roster_path)).strip_edges()
	_selected_team_slot = _normalize_team_slot(String(setup.get("team_slot", _selected_team_slot)))
	_team_play_mode = _normalize_team_play_mode(String(setup.get("team_play_mode", _team_play_mode)))
	_selected_map_path = String(setup.get("map_path", _selected_map_path)).strip_edges()
	_connection_mode = _normalize_connection_mode(String(setup.get("connection_mode", _connection_mode)))
	var changed: bool = previous_setup != get_lobby_setup_snapshot()
	if _peers_by_id.has(_get_local_peer_id()):
		_apply_local_setup_to_peer(_get_local_peer_id())
	if _connection_state == STATE_JOINED and not _is_authority_session() and _has_active_peer():
		request_update_player_setup.rpc_id(HOST_PEER_ID, get_lobby_setup_snapshot())
	if changed:
		_emit_snapshot()
		_broadcast_snapshot()
	return true


func get_lobby_setup_snapshot() -> Dictionary:
	return {
		"player_name": _player_name,
		"roster_path": _selected_roster_path,
		"team_slot": _selected_team_slot,
		"team_play_mode": _team_play_mode,
		"map_path": _selected_map_path,
		"connection_mode": _connection_mode,
		"direct_ip_policy": _get_direct_ip_policy_text(),
		"uses_upnp": _connection_mode == CONNECTION_MODE_UPNP,
		"upnp": _upnp_mapping.duplicate(true),
	}


func get_peer_team_assignments() -> Dictionary:
	var result: Dictionary = {}
	for peer_id in _peers_by_id.keys():
		result[int(peer_id)] = String(Dictionary(_peers_by_id[peer_id]).get("team_id", ""))
	return result


func get_peer_role_assignments() -> Dictionary:
	var result: Dictionary = {}
	for peer_id in _peers_by_id.keys():
		result[int(peer_id)] = String(Dictionary(_peers_by_id[peer_id]).get("role_id", ""))
	return result


func get_peer_fireteam_assignments() -> Dictionary:
	var result: Dictionary = {}
	for peer_id in _peers_by_id.keys():
		result[int(peer_id)] = PackedStringArray(Dictionary(_peers_by_id[peer_id]).get("fireteam_ids", PackedStringArray()))
	return result


func get_peer_roster_assignments() -> Dictionary:
	var result: Dictionary = {}
	for peer_id in _peers_by_id.keys():
		var peer_data: Dictionary = Dictionary(_peers_by_id[peer_id])
		result[int(peer_id)] = {
			"owner_peer_id": int(peer_data.get("owner_peer_id", HOST_PEER_ID)),
			"roster_source": String(peer_data.get("roster_source", MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.ROSTER_SOURCE_HOST)),
			"roster_mode": String(peer_data.get("roster_mode", get_roster_mode())),
			"roster_public_ref": String(peer_data.get("roster_public_ref", "")),
			"profile_public_ref": String(peer_data.get("profile_public_ref", "")),
			"uses_local_roster": bool(peer_data.get("uses_local_roster", false)),
			"can_manage_private_roster": bool(peer_data.get("can_manage_private_roster", false)),
			"fireteam_ids": PackedStringArray(peer_data.get("fireteam_ids", PackedStringArray())),
			"character_gameplay_authority": String(peer_data.get("character_gameplay_authority", MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.CHARACTER_GAMEPLAY_AUTHORITY)),
		}
	return result


func configure_host_state_for_test(peer_ids: Array = []) -> void:
	_reset_session_state(false)
	_configure_host_state(false)
	for peer_id_variant in peer_ids:
		var peer_id: int = int(peer_id_variant)
		if peer_id <= 0 or peer_id == HOST_PEER_ID:
			continue
		_upsert_peer(peer_id, false)
	_refresh_status_text()
	_emit_snapshot()


func configure_client_state_for_test(peer_ids: Array = []) -> void:
	_reset_session_state(false)
	_connection_state = STATE_JOINED
	for peer_id_variant in peer_ids:
		var peer_id: int = int(peer_id_variant)
		if peer_id <= 0:
			continue
		_upsert_peer(peer_id, peer_id == HOST_PEER_ID)
	_refresh_status_text()
	_emit_snapshot()


func set_peer_ready_for_test(peer_id: int, ready: bool) -> void:
	_set_peer_ready(peer_id, ready)
	_refresh_status_text()
	_emit_snapshot()


func set_host_map_manifest(manifest: Dictionary) -> Dictionary:
	var verification: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("verify_manifest", manifest))
	if bool(verification.get("valid", false)):
		_host_map_manifest = Dictionary(verification.get("manifest", {})).duplicate(true)
		_map_transfer_state = {
			"state": "host_manifest_ready",
			"requires_consent": false,
			"can_start_client": true,
			"manifest": _host_map_manifest.duplicate(true),
		}
	else:
		_host_map_manifest.clear()
		_map_transfer_state = {
			"state": "invalid_manifest",
			"requires_consent": false,
			"can_start_client": false,
			"errors": PackedStringArray(verification.get("errors", PackedStringArray())),
		}
	_emit_snapshot()
	return _map_transfer_state.duplicate(true)


func evaluate_client_map_manifest(manifest: Dictionary, local_map_paths: Array = []) -> Dictionary:
	var result: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("check_local_map", manifest, local_map_paths))
	_host_map_manifest = Dictionary(result.get("manifest", MAP_MANIFEST_SCRIPT.call("normalize_manifest", manifest))).duplicate(true)
	_map_transfer_state = result.duplicate(true)
	_map_transfer_state["can_start_client"] = not bool(result.get("requires_consent", false)) and String(result.get("state", "")) == "known"
	_emit_snapshot()
	return _map_transfer_state.duplicate(true)


func accept_map_download(manifest: Dictionary, map_json_text: String, cache_root: String = MAP_MANIFEST_SCRIPT.DOWNLOAD_ROOT) -> Dictionary:
	var result: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("accept_download", manifest, map_json_text, cache_root))
	_map_transfer_state = result.duplicate(true)
	if bool(result.get("accepted", false)):
		_host_map_manifest = Dictionary(result.get("manifest", {})).duplicate(true)
	_emit_snapshot()
	return _map_transfer_state.duplicate(true)


func reject_map_download(manifest: Dictionary) -> Dictionary:
	_map_transfer_state = Dictionary(MAP_MANIFEST_SCRIPT.call("reject_download", manifest))
	_host_map_manifest = Dictionary(_map_transfer_state.get("manifest", {})).duplicate(true)
	_emit_snapshot()
	return _map_transfer_state.duplicate(true)


@rpc("any_peer", "reliable")
func request_update_player_setup(setup: Dictionary) -> void:
	if not _is_authority_session():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if peer_id <= 0:
		peer_id = HOST_PEER_ID
	if not _peers_by_id.has(peer_id):
		_upsert_peer(peer_id, peer_id == HOST_PEER_ID)
	var peer_data: Dictionary = Dictionary(_peers_by_id.get(peer_id, {})).duplicate(true)
	peer_data["display_name"] = _normalize_player_name(String(setup.get("player_name", peer_data.get("display_name", "Player"))))
	peer_data["team_id"] = _normalize_team_slot(String(setup.get("team_slot", peer_data.get("team_id", client_team_id))))
	peer_data["roster_entry_path"] = String(setup.get("roster_path", peer_data.get("roster_entry_path", ""))).strip_edges()
	peer_data["connection_mode"] = _normalize_connection_mode(String(setup.get("connection_mode", CONNECTION_MODE_LAN)))
	_peers_by_id[peer_id] = peer_data
	_refresh_status_text()
	_emit_snapshot()
	_broadcast_snapshot()


@rpc("any_peer", "reliable")
func request_set_ready(ready: bool) -> void:
	if not _is_authority_session():
		return

	var peer_id: int = multiplayer.get_remote_sender_id()
	if peer_id <= 0:
		peer_id = HOST_PEER_ID
	if not _peers_by_id.has(peer_id):
		_upsert_peer(peer_id, peer_id == HOST_PEER_ID)
	_set_peer_ready(peer_id, ready)
	_refresh_status_text()
	_emit_snapshot()
	_broadcast_snapshot()


@rpc("authority", "reliable")
func _receive_session_snapshot(snapshot: Dictionary) -> void:
	if _is_authority_session():
		return

	_apply_authority_snapshot(snapshot)
	_emit_snapshot()


@rpc("authority", "reliable")
func _receive_start_mission(assignments: Dictionary) -> void:
	if _is_authority_session():
		return

	_mission_started = true
	_connection_state = STATE_MISSION
	_last_start_assignments = assignments.duplicate(true)
	_last_status_text = "Mission running..."
	_emit_snapshot()
	mission_start_requested.emit(assignments.duplicate(true))


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(peer_id: int) -> void:
	if not _is_authority_session():
		return
	_upsert_peer(peer_id, false)
	_refresh_status_text()
	_emit_snapshot()
	_broadcast_snapshot()


func _on_peer_disconnected(peer_id: int) -> void:
	if _is_authority_session():
		_peers_by_id.erase(peer_id)
		_mission_started = false
		_refresh_status_text()
		_emit_snapshot()
		_broadcast_snapshot()
		return

	_handle_disconnect("Peer disconnected. Returning to lobby.")


func _on_connected_to_server() -> void:
	_connection_state = STATE_JOINED
	_last_status_text = "Connected to host. Waiting for lobby state..."
	request_update_player_setup.rpc_id(HOST_PEER_ID, get_lobby_setup_snapshot())
	_emit_snapshot()


func _on_connection_failed() -> void:
	_handle_disconnect("Connection failed. Back in lobby.")


func _on_server_disconnected() -> void:
	_handle_disconnect("Disconnected from host. Back in lobby.")


func _handle_disconnect(message: String) -> void:
	_clear_multiplayer_peer()
	_reset_session_state(false)
	_last_status_text = message
	_emit_snapshot()
	session_disconnected.emit(message)


func _configure_host_state(emit_signal: bool = true) -> void:
	_local_is_host = true
	_connection_state = STATE_HOSTING
	_upsert_peer(HOST_PEER_ID, true)
	_refresh_status_text()
	if emit_signal:
		_emit_snapshot()


func _reset_session_state(emit_signal: bool = true) -> void:
	_peers_by_id.clear()
	_connection_state = STATE_IDLE
	_local_is_host = false
	_last_error = ""
	_last_status_text = "Ready. Host or join a local test session."
	_mission_started = false
	_last_start_assignments.clear()
	_host_map_manifest.clear()
	_clear_upnp_mapping()
	_reset_upnp_mapping_snapshot()
	_map_transfer_state = {
		"state": "none",
		"requires_consent": false,
		"can_start_client": true,
	}
	roster_mode = String(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("normalize_roster_mode", roster_mode))
	if emit_signal:
		_emit_snapshot()


func _clear_multiplayer_peer() -> void:
	_clear_upnp_mapping()
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null:
		return
	multiplayer.multiplayer_peer = null


func _upsert_peer(peer_id: int, is_host_peer: bool) -> void:
	if peer_id <= 0:
		return

	var existing: Dictionary = Dictionary(_peers_by_id.get(peer_id, {})).duplicate(true)
	var fireteams: PackedStringArray = host_fireteam_ids if is_host_peer else client_fireteam_ids
	var role_id: String = ROLE_HOST if is_host_peer else _get_client_role_id()
	existing["peer_id"] = peer_id
	existing["is_host"] = is_host_peer
	existing["team_id"] = _default_team_for_peer(is_host_peer)
	existing["role_id"] = role_id
	existing["fireteam_ids"] = _normalize_fireteam_ids(existing.get("fireteam_ids", fireteams))
	existing["ready"] = bool(existing.get("ready", false))
	existing = _apply_peer_roster_identity(peer_id, existing, is_host_peer)
	_peers_by_id[peer_id] = existing
	if peer_id == _get_local_peer_id() or (is_host_peer and _local_is_host):
		_apply_local_setup_to_peer(peer_id)


func _set_peer_ready(peer_id: int, ready: bool) -> void:
	if not _peers_by_id.has(peer_id):
		_upsert_peer(peer_id, peer_id == HOST_PEER_ID)
	var peer_data: Dictionary = Dictionary(_peers_by_id.get(peer_id, {})).duplicate(true)
	peer_data["ready"] = ready
	_peers_by_id[peer_id] = peer_data


func _refresh_status_text() -> void:
	if _mission_started:
		_last_status_text = "Mission running..."
		return
	if _connection_state == STATE_IDLE:
		_last_status_text = "Ready. Host or join a local test session."
		return
	if _connection_state == STATE_CONNECTING:
		return
	if _connection_state == STATE_JOINED:
		_last_status_text = "Connected to host. Waiting for start..."
		return

	var connected_players: int = _peers_by_id.size()
	if connected_players < max_players:
		_last_status_text = "Waiting for players... (%d/%d)" % [connected_players, max_players]
		return

	if not _are_all_connected_peers_ready():
		_last_status_text = "Connected (%d/%d). Ready %d/%d." % [connected_players, max_players, _count_ready_peers(), connected_players]
		return

	_last_status_text = "Ready to start (%d/%d)." % [connected_players, max_players]


func _emit_snapshot() -> void:
	session_snapshot_changed.emit(get_session_snapshot())


func _broadcast_snapshot() -> void:
	if not _is_authority_session() or not _has_active_peer():
		return
	_receive_session_snapshot.rpc(get_session_snapshot())


func _apply_authority_snapshot(snapshot: Dictionary) -> void:
	_last_status_text = String(snapshot.get("status_text", _last_status_text))
	_mission_started = bool(snapshot.get("mission_started", _mission_started))
	var roster_snapshot: Dictionary = Dictionary(snapshot.get("roster", {}))
	if roster_snapshot.has("roster_mode"):
		roster_mode = String(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("normalize_roster_mode", roster_snapshot.get("roster_mode", roster_mode)))
	if not _mission_started and _connection_state == STATE_MISSION:
		_connection_state = STATE_JOINED

	_peers_by_id.clear()
	for peer_variant in Array(snapshot.get("peers", [])):
		if typeof(peer_variant) != TYPE_DICTIONARY:
			continue
		var peer_data: Dictionary = Dictionary(peer_variant).duplicate(true)
		var peer_id: int = int(peer_data.get("peer_id", 0))
		if peer_id <= 0:
			continue
		peer_data["fireteam_ids"] = _normalize_fireteam_ids(peer_data.get("fireteam_ids", PackedStringArray()))
		peer_data = _apply_peer_roster_identity(peer_id, peer_data, bool(peer_data.get("is_host", peer_id == HOST_PEER_ID)))
		_peers_by_id[peer_id] = peer_data


func _build_peer_snapshot_array() -> Array:
	var result: Array = []
	var peer_ids: Array = _peers_by_id.keys()
	peer_ids.sort()
	for peer_id_variant in peer_ids:
		var peer_data: Dictionary = Dictionary(_peers_by_id[peer_id_variant]).duplicate(true)
		peer_data["fireteam_ids"] = PackedStringArray(peer_data.get("fireteam_ids", PackedStringArray()))
		result.append(peer_data)
	return result


func _refresh_peer_roster_identities() -> void:
	for peer_id_variant in _peers_by_id.keys():
		var peer_id: int = int(peer_id_variant)
		var peer_data: Dictionary = Dictionary(_peers_by_id[peer_id_variant]).duplicate(true)
		_peers_by_id[peer_id_variant] = _apply_peer_roster_identity(peer_id, peer_data, bool(peer_data.get("is_host", peer_id == HOST_PEER_ID)))


func _apply_peer_roster_identity(peer_id: int, peer_data: Dictionary, is_host_peer: bool) -> Dictionary:
	var identity: Dictionary = Dictionary(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call(
		"build_peer_roster_identity",
		peer_id,
		roster_mode,
		is_host_peer,
		"",
		peer_data.get("fireteam_ids", PackedStringArray())
	))
	for key in identity.keys():
		peer_data[key] = identity[key]
	return peer_data


func _are_all_connected_peers_ready() -> bool:
	if _peers_by_id.is_empty():
		return false
	for peer_data_variant in _peers_by_id.values():
		if not bool(Dictionary(peer_data_variant).get("ready", false)):
			return false
	return true


func _count_ready_peers() -> int:
	var count: int = 0
	for peer_data_variant in _peers_by_id.values():
		if bool(Dictionary(peer_data_variant).get("ready", false)):
			count += 1
	return count


func _is_local_peer_ready() -> bool:
	var local_peer_id: int = _get_local_peer_id()
	if not _peers_by_id.has(local_peer_id):
		return false
	return bool(Dictionary(_peers_by_id[local_peer_id]).get("ready", false))


func _is_authority_session() -> bool:
	if not _local_is_host:
		return false
	if _connection_state != STATE_HOSTING and _connection_state != STATE_MISSION:
		return false
	if not _has_active_peer():
		return true
	return multiplayer.is_server()


func _has_active_peer() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null:
		return false
	if peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func _get_local_peer_id() -> int:
	if _has_active_peer():
		var unique_id: int = multiplayer.get_unique_id()
		if unique_id > 0:
			return unique_id
	return HOST_PEER_ID if _connection_state == STATE_HOSTING else 0


func _normalize_fireteam_ids(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in Array(value):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	return result


func _get_client_role_id() -> String:
	var normalized_role_id: String = client_role_id.strip_edges().to_lower()
	if not ALLOWED_CLIENT_ROLES.has(normalized_role_id):
		return ROLE_COMMANDER
	return normalized_role_id


func _apply_local_setup_to_peer(peer_id: int) -> void:
	if not _peers_by_id.has(peer_id):
		return
	var peer_data: Dictionary = Dictionary(_peers_by_id.get(peer_id, {})).duplicate(true)
	peer_data["display_name"] = _player_name
	peer_data["team_id"] = _selected_team_slot
	peer_data["roster_entry_path"] = _selected_roster_path
	peer_data["team_play_mode"] = _team_play_mode
	peer_data["selected_map_path"] = _selected_map_path
	peer_data["connection_mode"] = _connection_mode
	_peers_by_id[peer_id] = peer_data


func _default_team_for_peer(is_host_peer: bool) -> String:
	if is_host_peer:
		return _selected_team_slot if not _selected_team_slot.is_empty() else host_team_id
	if _team_play_mode == TEAM_PLAY_MODE_COOP:
		return _selected_team_slot if not _selected_team_slot.is_empty() else host_team_id
	return client_team_id


func _normalize_player_name(value: String) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		return "Player"
	return normalized.substr(0, 32)


func _normalize_team_slot(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"team_alpha", "alpha":
			return "team_alpha"
		"team_bravo", "bravo":
			return "team_bravo"
		_:
			return "team_alpha"


func _normalize_team_play_mode(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	if VALID_TEAM_PLAY_MODES.has(normalized):
		return normalized
	return TEAM_PLAY_MODE_COOP


func _normalize_connection_mode(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	if VALID_CONNECTION_MODES.has(normalized):
		return normalized
	return CONNECTION_MODE_LAN


func _get_direct_ip_policy_text() -> String:
	if _connection_mode == CONNECTION_MODE_UPNP:
		return "UPnP mode tries to open the host UDP port automatically. Players still need a router that allows UPnP, otherwise use manual forwarding or VPN."
	if _connection_mode == CONNECTION_MODE_DIRECT_WAN:
		return "Direct IP can work over the internet only when the host UDP port is reachable through firewall/router forwarding or VPN."
	return "LAN mode expects both players on the same local network or VPN."


func _prepare_host_network_mode(port: int) -> void:
	if _connection_mode == CONNECTION_MODE_UPNP:
		_try_open_upnp_port(port)
	else:
		_reset_upnp_mapping_snapshot(port)


func _try_open_upnp_port(port: int) -> Dictionary:
	_clear_upnp_mapping()
	_upnp_mapping = {
		"enabled": true,
		"attempted": true,
		"mapped": false,
		"external_address": "",
		"port": port,
		"result": "discover_failed",
	}
	var upnp := UPNP.new()
	var discover_result: int = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		_upnp_mapping["result"] = "discover_failed:%d" % discover_result
		return _upnp_mapping.duplicate(true)
	var gateway := upnp.get_gateway()
	if gateway == null or not gateway.is_valid_gateway():
		_upnp_mapping["result"] = "gateway_invalid"
		return _upnp_mapping.duplicate(true)
	var mapping_result: int = upnp.add_port_mapping(port, port, "SternenBuergerchen Multiplayer", "UDP")
	_upnp_mapping["result"] = "mapped" if mapping_result == UPNP.UPNP_RESULT_SUCCESS else "mapping_failed:%d" % mapping_result
	_upnp_mapping["mapped"] = mapping_result == UPNP.UPNP_RESULT_SUCCESS
	_upnp_mapping["external_address"] = upnp.query_external_address()
	return _upnp_mapping.duplicate(true)


func _clear_upnp_mapping() -> void:
	if not bool(_upnp_mapping.get("mapped", false)):
		return
	var port: int = int(_upnp_mapping.get("port", 0))
	if port <= 0:
		return
	var upnp := UPNP.new()
	if upnp.discover() == UPNP.UPNP_RESULT_SUCCESS:
		upnp.delete_port_mapping(port, "UDP")
	_upnp_mapping["mapped"] = false
	_upnp_mapping["result"] = "closed"


func _reset_upnp_mapping_snapshot(port: int = 0) -> void:
	_upnp_mapping = {
		"enabled": false,
		"attempted": false,
		"mapped": false,
		"external_address": "",
		"port": port,
		"result": "not_requested",
	}
