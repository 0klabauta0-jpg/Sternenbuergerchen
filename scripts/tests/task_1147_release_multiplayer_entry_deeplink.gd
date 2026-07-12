extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")

var _failures: int = 0


func _initialize() -> void:
	var lobby := LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame

	_assert(lobby.has_method("get_release_multiplayer_deeplink_snapshot"), "Lobby exposes a read-only release multiplayer deeplink parser")
	_assert(lobby.has_method("get_release_multiplayer_playtest_snapshot"), "Lobby exposes observable release playtest state")
	if lobby.has_method("get_release_multiplayer_deeplink_snapshot"):
		var host: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", [
			"--release-multiplayer-host",
			"--release-multiplayer-port=28747",
			"--release-multiplayer-auto-start",
			"--release-multiplayer-trace=tmp/task_1147_host.json",
		]))
		_assert(bool(host.get("enabled", false)), "Host deeplink is enabled")
		_assert(String(host.get("role", "")) == "host", "Host deeplink resolves host role")
		_assert(int(host.get("port", 0)) == 28747, "Host deeplink resolves explicit port")
		_assert(bool(host.get("auto_start", false)), "Host deeplink resolves auto-start")
		_assert(String(host.get("trace_path", "")) == "tmp/task_1147_host.json", "Host deeplink resolves trace path")

		var client: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", [
			"--release-multiplayer-join",
			"--release-multiplayer-address=127.0.0.1",
			"--release-multiplayer-port=28747",
		]))
		_assert(String(client.get("role", "")) == "client", "Join deeplink resolves client role")
		_assert(String(client.get("address", "")) == "127.0.0.1", "Join deeplink resolves address")
		_assert(bool(client.get("auto_ready", false)), "Release Host/Join deeplinks auto-ready by default")

		var normal: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", ["--unrelated"]))
		_assert(not bool(normal.get("enabled", true)), "Normal lobby start stays outside playtest automation")

	lobby.queue_free()
	await process_frame
	if _failures == 0:
		print("TASK_1147 release multiplayer entry deeplink: 11/11 PASS")
		quit(0)
	else:
		push_error("TASK_1147 release multiplayer entry deeplink failed: %d" % _failures)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
