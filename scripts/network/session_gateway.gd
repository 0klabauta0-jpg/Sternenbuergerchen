extends Node
class_name RestartSession

signal snapshot_received(snapshot: Dictionary)
signal connection_changed(message: String)
signal command_result(result: Dictionary)
signal invitation_ready(invitation: String)

const SNAPSHOT_INTERVAL: float = 0.1
const InternetAuth = preload("res://scripts/network/internet_auth.gd")
const QuickTunnel = preload("res://scripts/network/quick_tunnel.gd")
const WssBridge = preload("res://scripts/network/wss_bridge.gd")
var _simulation: Node
var _peer: MultiplayerPeer
var _auth: RefCounted
var _tunnel: Node
var _invitation: String = ""
var _secret: String = ""
var _transport: String = "solo"
var _command_window: int = 0
var _command_count: int = 0
var _bridge: Node
var _internet_url: String = ""
var _retry_count: int = 0
var _fallback_used: bool = false
var _generation: int = 0
var _guest_id: int = 0
var _guests: Dictionary = {}
var _command_windows: Dictionary = {}
var _guest_mode: bool = false
var _connected: bool = false
var _latest_snapshot: Dictionary = {}
var _last_revision: int = -1
var _elapsed: float = 0.0
var _message: String = "Solo · beide Crewmitglieder verfügbar"

func setup(simulation: Node) -> void:
	_simulation = simulation
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	_publish_snapshot(true)

func start_host(port: int = 27991) -> Error:
	disconnect_session()
	var enet := ENetMultiplayerPeer.new()
	_peer = enet
	var error: Error = enet.create_server(port, 15)
	if error != OK:
		_peer = null
		_set_message("Host konnte nicht starten · Fehler %d" % error)
		return error
	multiplayer.multiplayer_peer = _peer
	_transport = "lan"
	_connected = true
	_simulation.set("auto_tick", true)
	_set_message("Host · Port %d · bis zu 15 Gastplätze" % port)
	_last_revision = -1
	return OK

func join_host(address: String, port: int = 27991) -> Error:
	disconnect_session()
	var enet := ENetMultiplayerPeer.new()
	_peer = enet
	var error: Error = enet.create_client(address, port)
	if error != OK:
		_peer = null
		_set_message("Verbindung konnte nicht starten · Fehler %d" % error)
		return error
	_guest_mode = true
	_transport = "lan"
	_connected = false
	_latest_snapshot = {}
	_last_revision = -1
	_simulation.set("auto_tick", false)
	multiplayer.multiplayer_peer = _peer
	_set_message("Verbinde mit %s:%d …" % [address, port])
	return OK

func start_internet_host(cloudflared_path: String = "", port: int = 27992) -> Error:
	var executable: String = cloudflared_path if not cloudflared_path.is_empty() else QuickTunnel.default_executable()
	if not FileAccess.file_exists(executable):
		_set_message("Internet-Helfer fehlt. Einmal tools/install_cloudflared.ps1 ausführen.")
		return ERR_FILE_NOT_FOUND
	var error: Error = start_websocket_host(port)
	if error != OK:
		return error
	_tunnel = QuickTunnel.new()
	add_child(_tunnel)
	_tunnel.ready_url.connect(_on_tunnel_ready)
	_tunnel.failed.connect(_on_tunnel_failed)
	error = _tunnel.start(executable, port)
	if error != OK:
		_on_tunnel_failed("Internet-Helfer konnte nicht starten · Fehler %d" % error)
		return error
	_set_message("Internet-Tunnel wird aufgebaut …")
	return OK

## Loopback-only endpoint, also usable by an explicitly managed reverse proxy.
func start_websocket_host(port: int = 27992) -> Error:
	if port < 1024 or port > 65535:
		return ERR_INVALID_PARAMETER
	disconnect_session()
	var websocket := WebSocketMultiplayerPeer.new()
	_configure_websocket(websocket)
	var error: Error = websocket.create_server(port, "127.0.0.1")
	if error != OK:
		_set_message("Internet-Port belegt · Fehler %d" % error)
		return error
	_secret = Crypto.new().generate_random_bytes(32).hex_encode()
	_begin_auth(true)
	_peer = websocket
	multiplayer.multiplayer_peer = _peer
	_connected = true
	_transport = "internet"
	_invitation = "ws://127.0.0.1:%d#%s" % [port, _secret]
	_last_revision = -1
	return OK

func join_internet(invitation: String) -> Error:
	var parts: PackedStringArray = invitation.strip_edges().split("#")
	var regex := RegEx.new()
	regex.compile("^(wss://[a-zA-Z0-9][a-zA-Z0-9.-]*(:[0-9]{2,5})?|ws://127\\.0\\.0\\.1:[0-9]{2,5})$")
	var key_regex := RegEx.new()
	key_regex.compile("^[a-f0-9]{64}$")
	if parts.size() != 2 or regex.search(parts[0]) == null or key_regex.search(parts[1]) == null:
		_set_message("Ungültige Einladung. Vollständigen Einladungslink mit Schlüssel einfügen.")
		return ERR_INVALID_PARAMETER
	disconnect_session()
	var websocket := WebSocketMultiplayerPeer.new()
	_configure_websocket(websocket)
	var error: Error = websocket.create_client(parts[0])
	if error != OK:
		_set_message("Internet-Verbindung konnte nicht starten · Fehler %d" % error)
		return error
	_secret = parts[1]
	_internet_url = parts[0]
	_guest_mode = true
	_transport = "internet"
	_latest_snapshot = {}
	_simulation.set("auto_tick", false)
	_begin_auth(false)
	_peer = websocket
	multiplayer.multiplayer_peer = _peer
	_set_message("Internet-Verbindung · Einladung wird geprüft …")
	return OK

func internet_invitation() -> String:
	# Local loopback invitation is only available for explicit local transport tests.
	return _invitation if _tunnel == null or _invitation.begins_with("wss://") else ""

func transport_name() -> String:
	return _transport

func _configure_websocket(peer: WebSocketMultiplayerPeer) -> void:
	peer.handshake_timeout = 4.0
	peer.inbound_buffer_size = 1048576
	peer.outbound_buffer_size = 1048576
	peer.max_queued_packets = 128
	peer.supported_protocols = PackedStringArray([InternetAuth.PROTOCOL])

func _begin_auth(host: bool) -> void:
	_auth = InternetAuth.new()
	_auth.setup(multiplayer as SceneMultiplayer, _secret, int(_simulation.snapshot().get("schema_version", -1)), host)
	_auth.rejected.connect(_on_auth_rejected)

func _on_auth_rejected() -> void:
	if _guest_mode:
		_set_message("Einladung abgewiesen: Schlüssel, Spielversion oder freie Teamplätze prüfen.")

func _on_tunnel_ready(url: String) -> void:
	_invitation = url + "#" + _secret
	_set_message("Internet bereit · Einladung kopieren · bis zu 15 Gastplätze")
	invitation_ready.emit(_invitation)

func _on_tunnel_failed(reason: String) -> void:
	disconnect_session()
	_set_message(reason)

func _retry_public_connection() -> void:
	if not _guest_mode or _transport != "internet" or _retry_count != 0: return
	var generation: int = _generation
	_retry_count += 1
	_set_message("Internetadresse wird erneut aufgelöst …")
	IP.clear_cache(_internet_url.trim_prefix("wss://"))
	await get_tree().create_timer(0.75).timeout
	if generation != _generation: return
	_start_replacement_client(_internet_url)

func _start_dns_fallback() -> void:
	if not _guest_mode or _transport != "internet" or _fallback_used: return
	_fallback_used = true
	_set_message("Internet · sichere DNS-Ersatzauflösung …")
	_reset_connecting_peer()
	_bridge = WssBridge.new()
	add_child(_bridge)
	_bridge.ready_url.connect(_start_replacement_client)
	_bridge.failed.connect(_on_bridge_failed)
	var error: Error = _bridge.start(_internet_url.trim_prefix("wss://"))
	if error != OK: _on_bridge_failed("DNS-Ersatzauflösung konnte nicht starten.")

func _reset_connecting_peer() -> void:
	if _auth != null:
		_auth.stop()
		_auth = null
	if _peer != null: _peer.close()
	_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _start_replacement_client(url: String) -> void:
	if not _guest_mode or _transport != "internet": return
	_reset_connecting_peer()
	var websocket := WebSocketMultiplayerPeer.new()
	_configure_websocket(websocket)
	if websocket.create_client(url) != OK:
		_on_bridge_failed("Internet-Verbindung konnte nicht wiederhergestellt werden.")
		return
	_begin_auth(false)
	_peer = websocket
	multiplayer.multiplayer_peer = _peer

func _on_bridge_failed(reason: String) -> void:
	_connected = false
	_reset_connecting_peer()
	_set_message(reason)

func _exit_tree() -> void:
	if _bridge != null: _bridge.stop()
	if _tunnel != null:
		_tunnel.stop()
	if _auth != null:
		_auth.stop()
		_auth = null
	if _peer != null:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_secret = ""
	_invitation = ""

func disconnect_session() -> void:
	_generation += 1
	if _bridge != null:
		_bridge.stop()
		_bridge.queue_free()
		_bridge = null
	_internet_url = ""
	_retry_count = 0
	_fallback_used = false
	if _tunnel != null:
		_tunnel.stop()
		_tunnel.queue_free()
		_tunnel = null
	if _auth != null:
		_auth.stop()
		_auth = null
	_invitation = ""
	_secret = ""
	_transport = "solo"
	_command_count = 0
	if _simulation != null and not _guest_mode and _guest_id != 0:
		_simulation.clear_guest()
	_guest_id = 0
	_guests.clear()
	_command_windows.clear()
	_connected = false
	if _peer != null:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_guest_mode = false
	_last_revision = -1
	if _simulation != null:
		_simulation.set("auto_tick", true)
		_publish_snapshot(true)
	_set_message("Solo · beide Crewmitglieder verfügbar")

func dispatch(command: Dictionary) -> Dictionary:
	if _simulation == null:
		return _reject(command, "Simulation ist noch nicht bereit.")
	if _guest_mode:
		if not _connected:
			return _reject(command, "Keine Verbindung zum Host.")
		_receive_command.rpc_id(1, command)
		return {"ok": true, "pending": true, "reason": "Warte auf Host", "request_id": command.get("request_id", "")}
	var result: Dictionary = _simulation.submit(command, 1)
	command_result.emit(result.duplicate(true))
	return result

func current_snapshot() -> Dictionary:
	if not _guest_mode and _simulation != null:
		return _simulation.snapshot()
	return _latest_snapshot.duplicate(true)

func is_guest() -> bool:
	return _guest_mode

func status_text() -> String:
	return _message

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < SNAPSHOT_INTERVAL or _guest_mode or _simulation == null:
		return
	_elapsed = 0.0
	_publish_snapshot()

func _publish_snapshot(force: bool = false) -> void:
	if _simulation == null or _guest_mode:
		return
	var state: Dictionary = _simulation.snapshot()
	var revision: int = int(state.get("revision", -1))
	if not force and revision == _last_revision:
		return
	_latest_snapshot = state
	_last_revision = revision
	snapshot_received.emit(state.duplicate(true))
	if _peer != null and multiplayer.is_server():
		for peer_id:int in _guests:
			var projection:Dictionary=_simulation.snapshot_for(peer_id) if _simulation.has_method("snapshot_for") else state
			_receive_snapshot.rpc_id(peer_id,projection)

@rpc("any_peer", "call_remote", "reliable")
func _receive_command(command: Dictionary) -> void:
	if _peer == null or not multiplayer.is_server() or _guest_mode:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if not _guests.has(sender) or sender == 0:
		return
	# Payload ownership fields never select the sender: the authenticated connection does.
	if _transport == "internet":
		var now: int = Time.get_ticks_msec()
		var window:Dictionary=_command_windows.get(sender,{"start":now,"count":0})
		if now-int(window.start)>=1000:window={"start":now,"count":0}
		window.count+=1;_command_windows[sender]=window
		if int(window.count)>30 or var_to_bytes(command).size()>4096:
			_receive_result.rpc_id(sender, {"ok": false, "reason": "Zu viele oder zu große Befehle.", "request_id": str(command.get("request_id", "")).left(96)})
			return
	var result: Dictionary = _simulation.submit(command, sender)
	_receive_result.rpc_id(sender, result)

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(state: Dictionary) -> void:
	if not _guest_mode or multiplayer.get_remote_sender_id() != 1:
		return
	_latest_snapshot = state.duplicate(true)
	_last_revision = int(state.get("revision", -1))
	snapshot_received.emit(_latest_snapshot.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func _receive_result(result: Dictionary) -> void:
	if _guest_mode and multiplayer.get_remote_sender_id() == 1:
		command_result.emit(result.duplicate(true))

func _on_peer_connected(peer_id: int) -> void:
	if _guest_mode or _peer==null or not multiplayer.is_server():return
	if _guests.size()>=15:
		_peer.disconnect_peer(peer_id);return
	_guests[peer_id]=true
	_guest_id=int(_guests.keys()[0])
	_simulation.set_guest(peer_id)
	if _simulation.has_method("accepts_peer") and not _simulation.accepts_peer(peer_id):
		_guests.erase(peer_id);_peer.disconnect_peer(peer_id);return
	_last_revision=-1
	_set_message("%d Commander verbunden" % (_guests.size()+1))

func _on_peer_disconnected(peer_id: int) -> void:
	if not _guest_mode and _guests.has(peer_id) and _simulation!=null:
		_guests.erase(peer_id);_command_windows.erase(peer_id)
		_guest_id=int(_guests.keys()[0]) if not _guests.is_empty() else 0
		_simulation.clear_guest(peer_id)
		_set_message("Commander getrennt · Sitzung pausiert")

func _on_connected_to_server() -> void:
	_connected = true
	_set_message("Koop · gemeinsame Crew · Sitzung beim Host")

func _on_connection_failed() -> void:
	_connected = false
	if _guest_mode and _internet_url.begins_with("wss://") and _internet_url.ends_with(".trycloudflare.com") and not _fallback_used:
		if _retry_count == 0:
			_retry_public_connection.call_deferred()
		else:
			_start_dns_fallback.call_deferred()
		return
	_set_message("Verbindung fehlgeschlagen · erneut verbinden oder Solo wählen")

func _on_server_disconnected() -> void:
	_connected = false
	_set_message("Host getrennt · letzter bestätigter Stand · erneut verbinden")

func _reject(command: Dictionary, reason: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": reason, "request_id": command.get("request_id", "")}
	command_result.emit(result)
	return result

func _set_message(message: String) -> void:
	_message = message
	connection_changed.emit(message)
