extends Node
## Process-local DNS fallback. Carries raw WebSocket bytes through verified TLS.
## Godot's WebSocket client cannot override DNS without adding a second Host header.
signal ready_url(url: String)
signal failed(reason: String)
var _host: String = ""
var _http: HTTPRequest
var _server := TCPServer.new()
var _tcp := StreamPeerTCP.new()
var _tls: StreamPeerTLS
var _local: StreamPeerTCP
var _up := PackedByteArray()
var _down := PackedByteArray()
var _header_done: bool = false
var _started: int = 0
var _phase: String = "idle"
var _dns_attempts: int = 0
const BUFFER_LIMIT: int = 1048576

func start(host: String) -> Error:
	var regex := RegEx.new()
	regex.compile("^[a-z0-9-]+\\.trycloudflare\\.com$")
	if regex.search(host) == null: return ERR_INVALID_PARAMETER
	_host = host
	_started = Time.get_ticks_msec()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	_http.body_size_limit = 8192
	add_child(_http)
	_http.request_completed.connect(_resolved)
	return _request_dns()

func _request_dns() -> Error:
	_phase = "dns"
	_dns_attempts += 1
	return _http.request("https://dns.google/resolve?name=" + _host + "&type=A&edns_client_subnet=0.0.0.0/0&random_padding=" + str(Time.get_ticks_msec()), PackedStringArray(["Accept: application/dns-json"]))

func _retry_dns() -> void:
	_phase = "dns_wait"
	await get_tree().create_timer(1.5).timeout
	if _phase != "dns_wait": return
	if _request_dns() != OK: _fail("DNS-Ersatzauflösung konnte nicht wiederholt werden.")

func _resolved(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _phase != "dns": return
	if result != HTTPRequest.RESULT_SUCCESS or status != 200:
		_fail("Sichere DNS-Ersatzauflösung nicht erreichbar.")
		return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary or response.get("Status") != 0 or not response.get("Answer") is Array:
		if _dns_attempts < 6:
			_retry_dns.call_deferred()
			return
		_fail("Internetadresse ist noch nicht auflösbar. Einladung später erneut versuchen.")
		return
	var address: String = ""
	for answer: Variant in response.Answer:
		if answer is Dictionary and answer.get("type") == 1 and answer.get("data") is String and answer.data.is_valid_ip_address():
			address = answer.data
			break
	if address.is_empty() or _tcp.connect_to_host(address, 443) != OK:
		_fail("Internetadresse nicht erreichbar.")
		return
	_phase = "tcp"

func stop() -> void:
	_phase = "idle"
	if _http != null: _http.cancel_request()
	_server.stop()
	if _local != null: _local.disconnect_from_host()
	if _tls != null: _tls.disconnect_from_stream()
	_tcp.disconnect_from_host()
	_up.clear()
	_down.clear()
	set_process(false)

func _exit_tree() -> void:
	stop()

func _fail(reason: String) -> void:
	stop()
	failed.emit(reason)

func _process(_delta: float) -> void:
	if _phase == "idle": return
	if _phase != "stream" and Time.get_ticks_msec() - _started > 20000:
		_fail("Internet-Verbindung nach 20 Sekunden abgebrochen.")
		return
	if _phase == "tcp":
		_tcp.poll()
		if _tcp.get_status() == StreamPeerTCP.STATUS_ERROR:
			_fail("Cloudflare-Verbindung fehlgeschlagen.")
		elif _tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			_tls = StreamPeerTLS.new()
			if _tls.connect_to_stream(_tcp, _host, TLSOptions.client()) != OK:
				_fail("Sichere TLS-Verbindung fehlgeschlagen.")
				return
			_phase = "tls"
	if _phase == "tls":
		_tls.poll()
		if _tls.get_status() == StreamPeerTLS.STATUS_CONNECTED:
			if _server.listen(0, "127.0.0.1") != OK:
				_fail("Lokale Internet-Weiterleitung konnte nicht starten.")
				return
			_phase = "local"
			ready_url.emit("ws://127.0.0.1:%d" % _server.get_local_port())
		elif _tls.get_status() != StreamPeerTLS.STATUS_HANDSHAKING:
			_fail("TLS-Zertifikat oder Verbindung ungültig.")
	if _phase == "local" and _server.is_connection_available():
		_local = _server.take_connection()
		_server.stop()
		_phase = "stream"
	if _phase != "stream": return
	_local.poll()
	_tls.poll()
	if _local.get_status() != StreamPeerTCP.STATUS_CONNECTED or _tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
		_fail("Internet-Verbindung beendet. Erneut beitreten.")
		return
	var available: int = mini(_local.get_available_bytes(), 16384)
	if available > 0:
		var data: Array = _local.get_data(available)
		if data[0] != OK:
			_fail("Lokale Verbindung unterbrochen.")
			return
		_up.append_array(data[1])
	if not _header_done:
		var header: String = _up.get_string_from_ascii()
		var end: int = header.find("\r\n\r\n")
		if end >= 0:
			var lines: PackedStringArray = header.substr(0, end).split("\r\n")
			var rewritten: String = ""
			for line: String in lines:
				if line.to_lower().begins_with("host:"): line = "Host: " + _host
				rewritten += line + "\r\n"
			var tail: PackedByteArray = _up.slice(end + 4)
			_up = (rewritten + "\r\n").to_ascii_buffer()
			_up.append_array(tail)
			_header_done = true
		elif _up.size() > 8192:
			_fail("Ungültiger WebSocket-Handshake.")
			return
	if _header_done and not _up.is_empty():
		var sent: Array = _tls.put_partial_data(_up)
		if sent[0] != OK and sent[0] != ERR_BUSY:
			_fail("Internet-Senden fehlgeschlagen.")
			return
		_up = _up.slice(int(sent[1]))
	available = mini(_tls.get_available_bytes(), 16384)
	if available > 0:
		var data: Array = _tls.get_data(available)
		if data[0] != OK:
			_fail("Internet-Empfang unterbrochen.")
			return
		_down.append_array(data[1])
	if not _down.is_empty():
		var sent: Array = _local.put_partial_data(_down)
		if sent[0] != OK and sent[0] != ERR_BUSY:
			_fail("Lokaler Empfang unterbrochen.")
			return
		_down = _down.slice(int(sent[1]))
	if _up.size() > BUFFER_LIMIT or _down.size() > BUFFER_LIMIT:
		_fail("Internet-Verbindung zu langsam; Puffergrenze erreicht.")
