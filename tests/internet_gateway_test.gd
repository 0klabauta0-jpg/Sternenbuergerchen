extends SceneTree

const Session = preload("res://scripts/network/session_gateway.gd")
const Simulation = preload("res://scripts/core/simulation_root.gd")
var checks: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL ", label)

func run() -> void:
	var sim: Node = Simulation.new(3)
	root.add_child(sim)
	sim.auto_tick = false
	var session: Node = Session.new()
	root.add_child(session)
	session.setup(sim)
	check(session.has_method("join_internet"), "Internet gateway exists")
	if failed > 0:
		quit(1)
		return
	var before: Dictionary = sim.snapshot()
	for invitation: String in ["", "https://example.com#abc", "ws://example.com#" + "a".repeat(64), "wss://example.com", "wss://evil.com/path#" + "a".repeat(64), "wss://user:pass@evil.com#" + "a".repeat(64)]:
		check(session.join_internet(invitation) == ERR_INVALID_PARAMETER, "reject malformed invitation")
	check(sim.snapshot() == before, "invalid invitation cannot mutate career")
	check(session.start_internet_host("C:/missing-cloudflared.exe") == ERR_FILE_NOT_FOUND, "missing helper actionable")
	check(not session.is_guest(), "failed host remains local")
	check(session.internet_invitation().is_empty(), "no fabricated invitation")
	check(session.start_websocket_host(28131) == OK, "authenticated listener starts")
	session.queue_free()
	await process_frame
	check(not (root.get_multiplayer() as SceneMultiplayer).auth_callback.is_valid(), "direct scene free removes authentication callback")
	check(root.get_multiplayer().multiplayer_peer is OfflineMultiplayerPeer, "direct scene free removes network peer")
	session = Session.new()
	root.add_child(session)
	session.setup(sim)
	check(session.start_host(28131) == OK, "LAN hosting after scene free")
	session.disconnect_session()
	print("INTERNET_GATEWAY_TEST checks=", checks, " failed=", failed)
	quit(0 if failed == 0 else 1)
