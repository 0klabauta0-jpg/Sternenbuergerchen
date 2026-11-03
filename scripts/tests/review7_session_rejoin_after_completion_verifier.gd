extends SceneTree

const ISOLATION_GUARD: GDScript = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const PORT_START: int = 19780
const PORT_END: int = 19790

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not ISOLATION_GUARD.require_isolated_user_data():
		return
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _run_case(false)
	await _run_case(true)
	print("=== REVIEW7 SESSION REJOIN RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW7_SESSION_REJOIN_ALL_PASSED")
	quit(1 if _failed > 0 else 0)


func _run_case(after_completion: bool) -> void:
	var label: String = "second mission" if after_completion else "first mission control"
	var fixture: Dictionary = await _create_pair(after_completion)
	_assert(bool(fixture.get("connected", false)), "%s: host/client complete real ENet setup" % label)
	if not bool(fixture.get("connected", false)):
		return
	var host: Node = fixture["host"]
	var client: Node = fixture["client"]
	var host_api: MultiplayerAPI = fixture["host_api"]
	var client_api: MultiplayerAPI = fixture["client_api"]
	var initial_peer_id: int = client_api.get_unique_id()
	var reconnect_token: String = String(client.get("_local_reconnect_token"))
	var starts: Array = []
	var blocks: Dictionary = {}
	client.connect("mission_start_requested", func(assignments: Dictionary) -> void: starts.append(assignments.duplicate(true)))
	host.connect("mission_rejoin_peer_block_changed", func(peer_id: int, blocked: bool) -> void: blocks[peer_id] = blocked)
	_assert(not JSON.stringify(host.call("get_session_snapshot")).contains(reconnect_token), "%s: reconnect secret stays out of public session snapshots" % label)
	await _ready_and_start(fixture, label + " initial start")
	if after_completion:
		# Normal lifecycle: no manual token rebinding or setup RPC is injected between missions.
		host.call("complete_mission")
		await _poll_pair(host_api, client_api, 25)
		var completed_host: Dictionary = Dictionary(host.call("get_session_snapshot"))
		var completed_client: Dictionary = Dictionary(client.call("get_session_snapshot"))
		_assert(not bool(completed_host.get("mission_started", true)) and not bool(completed_client.get("mission_started", true)), "Completion returns both connected peers to lobby")
		_assert(int(completed_host.get("connected_count", 0)) == 2 and int(completed_host.get("ready_count", -1)) == 0, "Completion keeps both connections and resets Ready")
		_assert(Dictionary(host.get("_reconnect_tokens_by_peer_id")).has(initial_peer_id), "Completion retains the connected client's authenticated rejoin identity")
		_assert(Dictionary(host.get("_pending_rejoin_identities_by_token")).is_empty(), "Completion leaves no stale disconnected mission identities")
		await _ready_and_start(fixture, label + " next start")
		_assert(starts.size() == 2, "Second mission begins through normal Ready and host Start")
	var starts_before_rejoin: int = starts.size()
	var old_assignment: Dictionary = Dictionary(host.call("build_session_assignments"))
	var old_team: String = String(Dictionary(old_assignment.get("peer_teams", {})).get(initial_peer_id, ""))
	var old_fireteams: PackedStringArray = PackedStringArray(Dictionary(old_assignment.get("peer_fireteams", {})).get(initial_peer_id, []))
	client.call("disconnect_session")
	await _poll_pair(host_api, client_api, 30)
	_assert(bool(Dictionary(host.call("get_session_snapshot")).get("mission_started", false)), "%s: host mission survives client disconnect" % label)
	_assert(Dictionary(host.get("_pending_rejoin_identities_by_token")).size() == 1, "%s: disconnect reserves the authenticated mission identity" % label)
	_assert(bool(client.call("join_session", "127.0.0.1", int(fixture["port"]))), "%s: client starts a real ENet rejoin" % label)
	await _poll_pair(host_api, client_api, 100)
	var new_peer_id: int = client_api.get_unique_id() if client_api.multiplayer_peer != null else 0
	_assert(new_peer_id > 1 and new_peer_id != initial_peer_id, "%s: rejoin uses a new ENet peer ID" % label)
	_assert(starts.size() == starts_before_rejoin + 1 and bool(Dictionary(client.call("get_session_snapshot")).get("mission_started", false)), "%s: authenticated rejoin receives a mission handoff" % label)
	var new_assignment: Dictionary = Dictionary(host.call("build_session_assignments"))
	var new_teams: Dictionary = Dictionary(new_assignment.get("peer_teams", {}))
	_assert(not new_teams.has(initial_peer_id) and String(new_teams.get(new_peer_id, "")) == old_team, "%s: new peer inherits the old authorized team without leaving an old peer assignment" % label)
	_assert(PackedStringArray(Dictionary(new_assignment.get("peer_fireteams", {})).get(new_peer_id, [])) == old_fireteams, "%s: new peer inherits the authorized Fireteams" % label)
	_assert(Dictionary(host.get("_pending_rejoin_identities_by_token")).is_empty(), "%s: authenticated handoff consumes the reserved identity" % label)
	if new_peer_id > 1 and client_api.multiplayer_peer != null and bool(Dictionary(client.call("get_session_snapshot")).get("mission_started", false)):
		_assert(bool(blocks.get(new_peer_id, false)), "%s: rejoin remains snapshot-blocked until mission runtime ACK" % label)
		client.rpc_id(1, "notify_mission_runtime_ready")
		await _poll_pair(host_api, client_api, 20)
		_assert(not bool(blocks.get(new_peer_id, true)), "%s: reliable runtime-ready ACK releases only the authenticated peer" % label)
	# Leave a pending mission identity, then test the explicit whole-session boundary.
	client.call("disconnect_session")
	await _poll_pair(host_api, client_api, 25)
	host.call("disconnect_session")
	_assert(Dictionary(host.get("_pending_rejoin_identities_by_token")).is_empty() and Dictionary(host.get("_reconnect_tokens_by_peer_id")).is_empty(), "%s: explicit session reset clears bound and pending reconnect credentials" % label)
	_assert(int(Dictionary(host.call("get_session_snapshot")).get("connected_count", -1)) == 0 and not bool(Dictionary(host.call("get_session_snapshot")).get("mission_started", true)), "%s: session reset leaves no connected peer or active mission" % label)
	await _cleanup_pair(fixture)


func _ready_and_start(fixture: Dictionary, label: String) -> void:
	var host: Node = fixture["host"]
	var client: Node = fixture["client"]
	var host_api: MultiplayerAPI = fixture["host_api"]
	var client_api: MultiplayerAPI = fixture["client_api"]
	_assert(bool(host.call("set_local_ready", true)) and bool(client.call("set_local_ready", true)), "%s: both peers submit normal Ready commands" % label)
	await _poll_pair(host_api, client_api, 25)
	_assert(bool(host.call("can_start_mission")) and bool(host.call("request_start_mission")), "%s: ready host starts mission" % label)
	await _poll_pair(host_api, client_api, 25)
	_assert(bool(Dictionary(client.call("get_session_snapshot")).get("mission_started", false)), "%s: client receives normal mission start" % label)


func _create_pair(second_case: bool) -> Dictionary:
	for port in range(PORT_START, PORT_END + 1):
		var host_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var host_root := Node.new()
		var client_root := Node.new()
		host_root.name = "Review7HostSecond" if second_case else "Review7HostFirst"
		client_root.name = "Review7ClientSecond" if second_case else "Review7ClientFirst"
		root.add_child(host_root)
		root.add_child(client_root)
		set_multiplayer(host_api, host_root.get_path())
		set_multiplayer(client_api, client_root.get_path())
		var host: Node = SESSION_SCRIPT.new()
		var client: Node = SESSION_SCRIPT.new()
		host.name = "Session"
		client.name = "Session"
		host_root.add_child(host)
		client_root.add_child(client)
		var fixture: Dictionary = {"host_api": host_api, "client_api": client_api, "host_root": host_root, "client_root": client_root, "host": host, "client": client, "port": port}
		if not bool(host.call("start_host", port)) or not bool(client.call("join_session", "127.0.0.1", port)):
			await _cleanup_pair(fixture)
			continue
		for _index in range(180):
			await _poll_pair(host_api, client_api, 1)
			if int(Dictionary(host.call("get_session_snapshot")).get("connected_count", 0)) == 2 and not Dictionary(host.get("_reconnect_tokens_by_peer_id")).is_empty():
				fixture["connected"] = true
				return fixture
		await _cleanup_pair(fixture)
	return {"connected": false}


func _poll_pair(host_api: MultiplayerAPI, client_api: MultiplayerAPI, frames: int) -> void:
	for _index in range(frames):
		host_api.poll()
		client_api.poll()
		await create_timer(0.01).timeout


func _cleanup_pair(fixture: Dictionary) -> void:
	var host: Node = fixture.get("host", null)
	var client: Node = fixture.get("client", null)
	if client != null:
		client.call("disconnect_session")
	if host != null:
		host.call("disconnect_session")
	var host_root: Node = fixture.get("host_root", null)
	var client_root: Node = fixture.get("client_root", null)
	if host_root != null:
		host_root.queue_free()
	if client_root != null:
		client_root.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
