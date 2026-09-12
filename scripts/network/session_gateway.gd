extends Node
class_name RestartSession

signal snapshot_received(snapshot: Dictionary)
signal connection_changed(message: String)
signal command_result(result: Dictionary)

const SNAPSHOT_INTERVAL: float = 0.1
var _simulation: Node
var _peer: ENetMultiplayerPeer
var _guest_id: int = 0
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
	_peer = ENetMultiplayerPeer.new()
	var error: Error = _peer.create_server(port, 1)
	if error != OK:
		_peer = null
		_set_message("Host konnte nicht starten · Fehler %d" % error)
		return error
	multiplayer.multiplayer_peer = _peer
	_connected = true
	_simulation.set("auto_tick", true)
	_set_message("Host · Port %d · Gastplatz frei" % port)
	_last_revision = -1
	return OK

func join_host(address: String, port: int = 27991) -> Error:
	disconnect_session()
	_peer = ENetMultiplayerPeer.new()
	var error: Error = _peer.create_client(address, port)
	if error != OK:
		_peer = null
		_set_message("Verbindung konnte nicht starten · Fehler %d" % error)
		return error
	_guest_mode = true
	_connected = false
	_latest_snapshot = {}
	_last_revision = -1
	_simulation.set("auto_tick", false)
	multiplayer.multiplayer_peer = _peer
	_set_message("Verbinde mit %s:%d …" % [address, port])
	return OK

func disconnect_session() -> void:
	if _simulation != null and not _guest_mode and _guest_id != 0:
		_simulation.clear_guest()
	_guest_id = 0
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
	if _peer != null and multiplayer.is_server() and _guest_id != 0:
		_receive_snapshot.rpc_id(_guest_id, state)

@rpc("any_peer", "call_remote", "reliable")
func _receive_command(command: Dictionary) -> void:
	if _peer == null or not multiplayer.is_server() or _guest_mode:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != _guest_id or sender == 0:
		return
	# Payload ownership fields never select the sender: the ENet connection does.
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
	if _guest_mode or _peer == null or not multiplayer.is_server():
		return
	if _guest_id != 0:
		_peer.disconnect_peer(peer_id)
		return
	_guest_id = peer_id
	_simulation.set_guest(peer_id)
	_last_revision = -1
	_set_message("Koop · Host führt Ida · Gast führt Jaro")

func _on_peer_disconnected(peer_id: int) -> void:
	if not _guest_mode and peer_id == _guest_id and _simulation != null:
		_guest_id = 0
		_simulation.clear_guest()
		_set_message("Gast getrennt · pausiert · Host führt beide")

func _on_connected_to_server() -> void:
	_connected = true
	_set_message("Koop · du führst Jaro · gemeinsame Sitzung beim Host")

func _on_connection_failed() -> void:
	_connected = false
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
