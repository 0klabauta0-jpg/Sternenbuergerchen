extends SceneTree
## Ownership regression only. Native Retry4 is the real client-loop RED.

const GUARD: GDScript = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SESSION: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
var _passed: int = 0
var _failed: int = 0
var _tick_events: int = 0


func _init() -> void:
	if GUARD.require_isolated_user_data():
		call_deferred("_run")


func _run() -> void:
	var clock: Node = root.get_node("NetworkTime")
	var synchronizer: Node = root.get_node("NetworkTimeSynchronizer")
	clock.connect("before_tick", func(_delta: float, _tick: int) -> void: _tick_events += 1)
	var session: Node = SESSION.new()
	session.name = "DisconnectClockSession"
	root.add_child(session)
	var started: bool = false
	var host_port: int = 0
	for port in range(19430, 19441):
		if bool(session.call("start_host", port)):
			started = true
			host_port = port
			break
	_expect(started, "Actual root session creates an ENet host")
	var deadline: int = Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline and (not bool(clock.call("_is_active")) or _tick_events < 2):
		await create_timer(0.01).timeout
	_expect(bool(clock.call("_is_active")) and _tick_events >= 2, "NetworkEvents starts actual root Netfox ticking")
	_expect(session.multiplayer == clock.multiplayer, "Root session and Netfox really own the same MultiplayerAPI")
	var branch := Node.new()
	branch.name = "IndependentSessionScope"
	root.add_child(branch)
	var foreign_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
	foreign_api.multiplayer_peer = OfflineMultiplayerPeer.new()
	set_multiplayer(foreign_api, branch.get_path())
	var foreign_session: Node = SESSION.new()
	foreign_session.name = "ForeignSession"
	branch.add_child(foreign_session)
	_expect(foreign_session.multiplayer != clock.multiplayer and foreign_api.multiplayer_peer != null, "Independent subtree really uses a different MultiplayerAPI with a peer")
	foreign_session.call("disconnect_session")
	_expect(bool(clock.call("_is_active")), "Foreign session disconnect preserves the root Netfox clock")
	branch.queue_free()
	await process_frame
	var ticks_before_restart: int = _tick_events
	_expect(bool(session.call("start_host", host_port)), "Public start_host replaces an already active real host in the same frame")
	await create_timer(0.2).timeout
	_expect(bool(clock.call("_is_active")), "Host-to-host same-frame replacement restarts its owned Netfox clock")
	_expect(_tick_events > ticks_before_restart, "Host-to-host replacement emits actual new Netfox ticks")
	session.call("disconnect_session")
	var ticks_before_reconnect: int = _tick_events
	_expect(bool(session.call("start_host", host_port)), "Public disconnect and start_host succeed in the same frame")
	await create_timer(0.2).timeout
	_expect(bool(clock.call("_is_active")), "Same-frame public disconnect-to-host restarts its owned clock")
	_expect(_tick_events > ticks_before_reconnect, "Same-frame disconnect-to-host emits actual new Netfox ticks")
	session.call("disconnect_session", "Public owner clock stop")
	_expect(not bool(clock.call("_is_active")), "Own public disconnect stops the Netfox tick clock immediately")
	_expect(not bool(synchronizer.get("_active")), "Own public disconnect leaves the synchronizer stopped")
	var snapshot: Dictionary = session.call("get_session_snapshot")
	_expect(String(snapshot.get("connection_state", "")) == "idle" and not bool(snapshot.get("has_active_peer", true)) and int(snapshot.get("connected_count", -1)) == 0, "Public disconnect preserves the complete existing session reset")
	var stopped_tick_events: int = _tick_events
	await create_timer(maxf(0.8, float(synchronizer.get("sync_interval")) * 2.2)).timeout
	_expect(_tick_events == stopped_tick_events, "No Netfox ticks after more than two real sync intervals")
	session.call("disconnect_session")
	_expect(not bool(clock.call("_is_active")) and not bool(synchronizer.get("_active")), "Repeated public disconnect is idempotently stopped")
	clock.call("stop") # RED cleanup also drains the real addon without peer reuse.
	await create_timer(float(synchronizer.get("sync_interval")) + 0.1).timeout
	session.queue_free()
	await process_frame
	print("MULTIPLAYER_DISCONNECT_OWNER: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
