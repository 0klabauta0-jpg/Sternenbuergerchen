extends RefCounted
## Authentication finishes before SceneMultiplayer exposes a peer or accepts RPCs.
signal rejected
const PROTOCOL: String = "sternenbuergerchen-teams-2"
var _api: SceneMultiplayer
var _secret: String
var _schema: int
var _host: bool
var _nonces: Dictionary = {}
var _reserved: Dictionary = {}

func setup(api: SceneMultiplayer, secret: String, schema: int, host: bool) -> void:
	_api = api
	_secret = secret
	_schema = schema
	_host = host
	api.auth_timeout = 8.0
	api.allow_object_decoding = false
	api.auth_callback = receive
	api.peer_authenticating.connect(begin)
	api.peer_authentication_failed.connect(_auth_failed)
	api.peer_disconnected.connect(forget)

func stop() -> void:
	_api.auth_callback = Callable()
	_api.peer_authenticating.disconnect(begin)
	_api.peer_authentication_failed.disconnect(_auth_failed)
	_api.peer_disconnected.disconnect(forget)
	_secret = ""
	_nonces.clear()
	_reserved.clear()

func begin(id: int) -> void:
	if not _host:
		return
	if _reserved.size()+_nonces.size() >= 15:
		_api.disconnect_peer(id)
		return
	var nonce: String = Crypto.new().generate_random_bytes(32).hex_encode()
	_nonces[id] = nonce
	_send(id, {"protocol": PROTOCOL, "schema": _schema, "nonce": nonce, "proof": _proof(nonce, "host")})

func receive(id: int, data: PackedByteArray) -> void:
	if data.size() > 1024:
		_reject(id)
		return
	var packet: Variant = JSON.parse_string(data.get_string_from_utf8())
	if not packet is Dictionary or packet.get("protocol") != PROTOCOL or packet.get("schema") != _schema:
		_reject(id)
		return
	if _host:
		var nonce: String = _nonces.get(id, "")
		if nonce.is_empty() or _reserved.size() >= 15 or _reserved.has(id) or not _equal(packet.get("proof"), _proof(nonce, "guest")):
			_reject(id)
			return
		_reserved[id] = true
		_nonces.erase(id)
		_api.complete_auth(id)
	else:
		var nonce: Variant = packet.get("nonce")
		if id != 1 or not nonce is String or nonce.length() != 64 or not _equal(packet.get("proof"), _proof(nonce, "host")):
			_reject(id)
			return
		_send(id, {"protocol": PROTOCOL, "schema": _schema, "proof": _proof(nonce, "guest")})
		_api.complete_auth(id)

func _proof(nonce: String, role: String) -> String:
	var hmac := HMACContext.new()
	hmac.start(HashingContext.HASH_SHA256, _secret.to_utf8_buffer())
	hmac.update((PROTOCOL + ":" + str(_schema) + ":" + nonce + ":" + role).to_utf8_buffer())
	return hmac.finish().hex_encode()

func _equal(received: Variant, expected: String) -> bool:
	if not received is String or received.length() != expected.length():
		return false
	var difference: int = 0
	for index: int in expected.length():
		difference |= received.unicode_at(index) ^ expected.unicode_at(index)
	return difference == 0

func _send(id: int, packet: Dictionary) -> void:
	_api.send_auth(id, JSON.stringify(packet).to_utf8_buffer())

func _reject(id: int) -> void:
	var report: bool = _host and _nonces.has(id)
	_nonces.erase(id)
	_api.disconnect_peer(id)
	if report: rejected.emit()

func _auth_failed(id: int) -> void:
	var report: bool = not _host or _nonces.has(id)
	forget(id)
	if report: rejected.emit()

func forget(id: int) -> void:
	_nonces.erase(id)
	_reserved.erase(id)
