extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Multiplayer ENet Connectivity Smoke ===")
	await _test_localhost_enet_peer_connects()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_localhost_enet_peer_connects() -> void:
	var port: int = 19327
	var server := ENetMultiplayerPeer.new()
	var client := ENetMultiplayerPeer.new()
	var server_error: int = server.create_server(port, 2)
	_assert(server_error == OK, "ENet server can bind a local direct-IP test port")
	if server_error != OK:
		return
	var client_error: int = client.create_client("127.0.0.1", port)
	_assert(client_error == OK, "ENet client accepts localhost direct-IP target")
	if client_error != OK:
		server.close()
		return
	var connected: bool = false
	for _index in range(180):
		server.poll()
		client.poll()
		if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			connected = true
			break
		await process_frame
	_assert(connected, "Localhost ENet client reaches CONNECTION_CONNECTED through the direct-IP path")
	client.close()
	server.close()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
