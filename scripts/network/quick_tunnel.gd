extends Node
## Owns only the portable process started by this instance. No service installation.
signal ready_url(url: String)
signal failed(reason: String)
var _pid: int = -1
var _log_path: String = ""
var _started: int = 0
var _announced: bool = false
var _poll: float = 0.0
var _allocated_url: String = ""
var _dns_http: HTTPRequest
var _dns_pending: bool = false
var _next_dns: int = 0

static func default_executable() -> String:
	var bundled: String = OS.get_executable_path().get_base_dir().path_join("tools/cloudflared.exe")
	if FileAccess.file_exists(bundled): return bundled
	return OS.get_environment("LOCALAPPDATA").path_join("SternenBuergerchen-Neustart/tools/cloudflared.exe")

func start(executable: String, port: int) -> Error:
	if not FileAccess.file_exists(executable):
		return ERR_FILE_NOT_FOUND
	process_mode = Node.PROCESS_MODE_ALWAYS
	_log_path = OS.get_cache_dir().path_join("sternen-tunnel-" + Crypto.new().generate_random_bytes(8).hex_encode() + ".log")
	var args := PackedStringArray(["tunnel", "--no-autoupdate", "--logfile", _log_path, "--protocol", "http2", "--url", "http://127.0.0.1:%d" % port])
	_pid = OS.create_process(executable, args, false)
	_started = Time.get_ticks_msec()
	_dns_http = HTTPRequest.new()
	_dns_http.timeout = 8.0
	_dns_http.body_size_limit = 8192
	add_child(_dns_http)
	_dns_http.request_completed.connect(_on_dns_checked)
	return OK if _pid > 0 else ERR_CANT_FORK

func stop() -> void:
	if _dns_http != null: _dns_http.cancel_request()
	if _pid > 0 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	set_process(false)

func _exit_tree() -> void:
	stop()

func _process(delta: float) -> void:
	if _pid <= 0:
		return
	_poll += delta
	if _poll < 0.25:
		return
	_poll = 0.0
	if not OS.is_process_running(_pid):
		stop()
		failed.emit("Internet-Tunnel beendet. Erneut hosten; LAN bleibt verfügbar.")
		return
	if _announced:
		return
	if Time.get_ticks_msec() - _started > 75000:
		stop()
		failed.emit("Internet-Tunnel oder DNS nicht erreichbar (75 s). Internet/Firewall prüfen oder LAN verwenden.")
		return
	if not FileAccess.file_exists(_log_path):
		return
	var text: String = FileAccess.get_file_as_string(_log_path)
	var regex := RegEx.new()
	regex.compile("https://[a-z0-9-]+\\.trycloudflare\\.com")
	var found: RegExMatch = regex.search(text)
	# Wait for a real edge connection as well as hostname allocation.
	if found != null and text.contains("Registered tunnel connection"):
		_allocated_url = found.get_string().replace("https://", "wss://")
		if not _dns_pending and Time.get_ticks_msec() >= _next_dns:
			_dns_pending = true
			var error: Error = _dns_http.request("https://dns.google/resolve?name=" + _allocated_url.trim_prefix("wss://") + "&type=A&edns_client_subnet=0.0.0.0/0&random_padding=" + str(Time.get_ticks_msec()))
			if error != OK:
				_dns_pending = false
				_next_dns = Time.get_ticks_msec() + 1500

func _on_dns_checked(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_dns_pending = false
	_next_dns = Time.get_ticks_msec() + 1500
	if _pid <= 0 or _announced or result != HTTPRequest.RESULT_SUCCESS or status != 200: return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary or response.get("Status") != 0 or not response.get("Answer") is Array: return
	for answer: Variant in response.Answer:
		if answer is Dictionary and answer.get("type") == 1 and answer.get("data") is String and answer.data.is_valid_ip_address():
			_announced = true
			ready_url.emit(_allocated_url)
			return
