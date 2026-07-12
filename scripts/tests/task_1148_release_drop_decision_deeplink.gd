extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")

var _failed := 0


func _initialize() -> void:
	var lobby := LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	var config: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", [
		"--release-multiplayer-host",
		"--release-multiplayer-auto-start",
		"--release-multiplayer-drop-decision",
	]))
	_assert(bool(config.get("drop_decision", false)), "Release deeplink enables connected Drop/Decision playtest explicitly")
	_assert(lobby.has_method("get_release_multiplayer_drop_decision_snapshot"), "Lobby exposes read-only Drop/Decision progress")
	if lobby.has_method("get_release_multiplayer_drop_decision_snapshot"):
		var snapshot: Dictionary = Dictionary(lobby.call("get_release_multiplayer_drop_decision_snapshot"))
		_assert(String(snapshot.get("stage", "")) == "disabled", "Drop/Decision progress is disabled outside explicit runtime start")
		_assert(bool(snapshot.get("ui_sets_gameplay_truth", true)) == false, "Drop/Decision snapshot does not claim gameplay authority")
	var normal: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", ["--release-multiplayer-host"]))
	_assert(not bool(normal.get("drop_decision", true)), "Ordinary release Host deeplink does not automate gameplay")
	lobby.queue_free()
	await process_frame
	print("TASK_1148 release Drop/Decision deeplink: %d/5 PASS" % (5 - _failed))
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
