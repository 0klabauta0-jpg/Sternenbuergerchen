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
	var source := FileAccess.get_file_as_string("res://scripts/ui/multiplayer_lobby_screen.gd")
	var advance_start := source.find("func _advance_release_multiplayer_drop_decision()")
	var advance_end := source.find("func _resolve_release_local_drop_assignment", advance_start)
	var advance_source := source.substr(advance_start, advance_end - advance_start)
	_assert(advance_source.count("select_mission_dropship_fireteam") == 2, "Drop polling selects craft only for the two explicit command submissions")
	lobby.queue_free()
	await process_frame
	print("TASK_1148 release Drop/Decision deeplink: %d/6 PASS" % (6 - _failed))
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
