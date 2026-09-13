extends SceneTree
const Session = preload("res://scripts/network/session_gateway.gd")
const Simulation = preload("res://scripts/core/simulation_root.gd")
var session: Node
var sim: Node
var output: String
var role: String
var public_tunnel: bool = false
var force_dns_fallback: bool = false
var port: int = 28119
var checks: Array[Dictionary] = []
var results: Array[Dictionary] = []
var received: int = 0
var auth_rejections: int = 0
var statuses: Array[String] = []

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
		if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
		if arg == "--public": public_tunnel = true
		if arg == "--force-dns-fallback": force_dns_fallback = true
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks.append({"ok": ok, "label": label})
	if not ok: printerr("FAIL ", role, ": ", label)

func write(name: String, value: Variant) -> void:
	var file := FileAccess.open(output.path_join(name + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

func read(name: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(output.path_join(name + ".json")))

func exists(name: String) -> bool:
	return FileAccess.file_exists(output.path_join(name + ".json"))

func wait_until(predicate: Callable, seconds: float = 10.0) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return true
		await create_timer(0.05).timeout
	return false

func run() -> void:
	sim = Simulation.new(3)
	sim.name = "Simulation"
	root.add_child(sim)
	session = Session.new()
	session.name = "Session"
	root.add_child(session)
	session.setup(sim)
	session.command_result.connect(func(result: Dictionary) -> void: results.append(result))
	session.connection_changed.connect(func(message: String) -> void:
		statuses.append(message)
		write(role + "-statuses", statuses))
	session.snapshot_received.connect(func(_snapshot: Dictionary) -> void: received += 1)
	if role == "host": await host_run()
	else: await guest_run()
	var failed: int = 0
	for entry: Dictionary in checks:
		if not entry.ok: failed += 1
	write(role + "-result", {"checks": checks, "failed": failed, "snapshots": received, "public": public_tunnel, "forced_dns_fallback": force_dns_fallback, "statuses": statuses})
	session.disconnect_session()
	await process_frame
	print("INTERNET_PROCESS ", role, " checks=", checks.size(), " failed=", failed)
	quit(0 if failed == 0 else 1)

func host_run() -> void:
	var error: Error = session.start_internet_host("", port) if public_tunnel else session.start_websocket_host(port)
	check(error == OK, "host transport starts")
	if error != OK: return
	session.get("_auth").rejected.connect(func() -> void:
		auth_rejections += 1
		write("rejection-count", auth_rejections))
	check(await wait_until(func() -> bool: return not session.internet_invitation().is_empty(), 80.0), "real invitation ready")
	if session.internet_invitation().is_empty(): return
	write("invitation", {"invitation": session.internet_invitation()})
	check(await wait_until(func() -> bool: return exists("invalid-done"), 100.0), "invalid clients completed")
	check(auth_rejections == 3, "server actually rejected key, schema and protocol")
	check(int(sim.snapshot().crew.jaro.owner) == 1, "invalid peers never obtain crew")
	check(sim.get("_receipts").is_empty(), "invalid peers never reach command core")
	write("invalid-checked", true)
	check(await wait_until(func() -> bool: return exists("commands-done"), 25.0), "authenticated commands completed")
	var snapshot: Dictionary = sim.snapshot()
	check(snapshot.crew.ida.target == [0.0, 0.0], "forged sender cannot move Ida")
	check(Vector2(snapshot.crew.jaro.position[0], snapshot.crew.jaro.position[1]).distance_to(Vector2(2, 5)) < 0.1, "real authoritative movement arrived")
	check(snapshot.credits == 180, "guest cannot spend host credits")
	var own_receipts: int = 0
	for receipt: String in sim.get("_receipts"):
		if receipt.ends_with(":internet-own"): own_receipts += 1
	check(own_receipts == 1, "duplicate request exactly one receipt")
	session.dispatch({"type":"toggle_pause", "request_id":"internet-pause"})
	var paused: Dictionary = sim.snapshot()
	write("paused", paused)
	check(await wait_until(func() -> bool: return exists("pause-seen")), "shared pause received")
	var save_path: String = output.path_join("host-career.json")
	var save_result: Dictionary = sim.save_game(save_path)
	check(save_result.ok, "real paused save succeeds: " + str(save_result.reason))
	session.dispatch({"type":"move", "request_id":"internet-newtarget", "unit_id":"ida", "position":[4,4]})
	var newer: int = int(sim.snapshot().revision)
	var load_result: Dictionary = sim.load_game(save_path)
	check(load_result.ok, "real save restored: " + str(load_result.reason))
	check(int(sim.snapshot().revision) > newer, "load revision remains monotone")
	write("restored", sim.snapshot())
	check(await wait_until(func() -> bool: return exists("disconnecting")), "guest starts disconnect")
	check(await wait_until(func() -> bool: return int(sim.snapshot().crew.jaro.owner) == 1), "disconnect returns crew to host")
	check(sim.snapshot().paused, "disconnect pauses")
	write("rejoin-ready", true)
	check(await wait_until(func() -> bool: return exists("guest-done"), 20.0), "guest reconnected and checked")
	check(session.dispatch({"type":"assign_work", "request_id":"internet-armor-work", "unit_id":"ida", "recipe_id":"armor"}).ok, "host starts real v3 armor work")
	session.dispatch({"type":"toggle_pause", "request_id":"internet-v3-unpause"})
	check(await wait_until(func() -> bool: return int(sim.snapshot().inventory.get("armor", 0)) == 1, 25.0), "armor crafted after walking and work")
	check(session.dispatch({"type":"equip", "request_id":"internet-armor-equip", "unit_id":"ida", "item":"armor"}).ok, "host equips actual armor")
	check(session.dispatch({"type":"travel", "request_id":"internet-tradepost", "destination":"tradepost"}).ok, "host starts new map travel")
	check(await wait_until(func() -> bool: return sim.snapshot().region == "tradepost", 30.0), "new map reached after real boarding and flight")
	session.dispatch({"type":"toggle_pause", "request_id":"internet-v3-pause"})
	write("host-final", sim.snapshot())
	check(await wait_until(func() -> bool: return exists("v3-seen")), "guest confirms v3 equipment and region")
	# Give guest time to finish before the host closes its tunnel.
	await create_timer(0.4).timeout

func _wrong_protocol(id: int, _data: PackedByteArray) -> void:
	(root.get_multiplayer() as SceneMultiplayer).send_auth(id, '{"protocol":"incompatible","schema":-1}'.to_utf8_buffer())

func join_invitation(invitation: String) -> Error:
	var error: Error = session.join_internet(invitation)
	if error == OK and force_dns_fallback:
		# Select the real production fallback, without changing game/auth success state.
		session.call("_start_dns_fallback")
	return error

func guest_run() -> void:
	var invitation: String = read("invitation").invitation
	var attempt_index: int = 0
	for mode: String in ["key", "schema", "protocol"]:
		attempt_index += 1
		var attempt: String = invitation
		if mode == "key": attempt = invitation.get_slice("#", 0) + "#" + "0".repeat(64)
		check(join_invitation(attempt) == OK, "invalid " + mode + " transport attempted")
		var deadline: int = Time.get_ticks_msec() + 30000
		while Time.get_ticks_msec() < deadline:
			if exists("rejection-count") and int(read("rejection-count")) >= attempt_index: break
			if session.get("_auth") != null:
				if mode == "schema": session.get("_auth").set("_schema", -1)
				if mode == "protocol": (root.get_multiplayer() as SceneMultiplayer).auth_callback = _wrong_protocol
			await process_frame
		check(exists("rejection-count") and int(read("rejection-count")) >= attempt_index, "host actually rejects invalid " + mode)
		check(session.current_snapshot().is_empty(), "invalid " + mode + " receives no snapshot")
		check(not bool(session.get("_connected")), "invalid " + mode + " never connects")
		session.disconnect_session()
	write("invalid-done", true)
	check(await wait_until(func() -> bool: return exists("invalid-checked")), "host confirms invalid isolation")
	check(join_invitation(invitation) == OK, "valid invitation starts")
	check(await wait_until(func() -> bool: return not session.current_snapshot().is_empty(), 20.0), "authenticated snapshot arrives")
	if session.current_snapshot().is_empty(): return
	check(session.current_snapshot().crew.jaro.owner == root.get_multiplayer().get_unique_id(), "authenticated guest owns Jaro")
	results.clear()
	var own: Dictionary = {"type":"move", "request_id":"internet-own", "unit_id":"jaro", "position":[2,5]}
	session.dispatch(own)
	session.dispatch(own)
	session.dispatch({"type":"move", "request_id":"internet-foreign", "sender_id":1, "unit_id":"ida", "position":[33,33]})
	session.dispatch({"type":"trade", "request_id":"internet-trade", "side":"buy", "item":"parts", "amount":1})
	check(await wait_until(func() -> bool: return results.size() >= 4), "host acknowledges four packets")
	if results.size() >= 4:
		check(results[0].ok and results[1] == results[0], "duplicate gets identical authoritative receipt")
		check(not results[2].ok and not results[3].ok, "ownership and host transaction rejected")
	await create_timer(1.2).timeout
	write("commands-done", true)
	check(await wait_until(func() -> bool: return exists("paused") and session.current_snapshot().get("paused", false)), "shared pause arrives")
	write("guest-paused", session.current_snapshot())
	write("pause-seen", true)
	check(await wait_until(func() -> bool: return exists("restored") and int(session.current_snapshot().get("revision", -1)) == int(read("restored").revision)), "restored snapshot revision arrives")
	write("guest-restored", session.current_snapshot())
	write("disconnecting", true)
	session.disconnect_session()
	check(await wait_until(func() -> bool: return exists("rejoin-ready")), "host processed disconnect")
	check(join_invitation(invitation) == OK, "same invitation reconnects")
	check(await wait_until(func() -> bool: return not session.current_snapshot().is_empty(), 20.0), "reconnect receives full snapshot")
	if not session.current_snapshot().is_empty():
		check(session.current_snapshot().paused and session.current_snapshot().credits == 180, "reconnect preserves pause and money")
		check(session.current_snapshot().crew.jaro.owner == root.get_multiplayer().get_unique_id(), "reconnect restores Jaro ownership")
	write("guest-done", true)
	check(await wait_until(func() -> bool: return exists("host-final") and int(session.current_snapshot().get("revision", -1)) == int(read("host-final").revision), 65.0), "host final snapshot recorded and received")
	check(session.current_snapshot().get("schema_version") == 3, "v3 snapshot crosses public gateway")
	check(session.current_snapshot().crew.ida.equipment.get("armor") == "armor", "actual crafted and equipped armor replicated")
	check(session.current_snapshot().region == "tradepost", "new region replicated")
	write("guest-final", session.current_snapshot())
	write("v3-seen", true)
