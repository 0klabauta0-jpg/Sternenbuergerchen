extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")
const HARNESS_PATH := "res://scripts/tools/capture_release_host_client_entry_playtest.ps1"

var _passed := 0
var _failed := 0


func _initialize() -> void:
	var lobby := LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	var config: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", [
		"--release-multiplayer-host",
		"--release-multiplayer-auto-start",
		"--release-multiplayer-first-contact",
	]))
	_assert(bool(config.get("first_contact", false)), "Release deeplink enables First Contact only explicitly")
	_assert(bool(config.get("drop_decision", false)), "First Contact mode includes the proven Drop/Decision entry")
	_assert(lobby.has_method("get_release_multiplayer_first_contact_snapshot"), "Lobby exposes read-only First Contact progress")
	if lobby.has_method("get_release_multiplayer_first_contact_snapshot"):
		var snapshot: Dictionary = Dictionary(lobby.call("get_release_multiplayer_first_contact_snapshot"))
		_assert(String(snapshot.get("stage", "")) == "disabled", "First Contact progress starts disabled outside runtime automation")
		_assert(bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)), "First Contact trace is explicitly read-only")
		_assert(snapshot.has("contacts") and snapshot.has("fire_events") and snapshot.has("diagnostics"), "First Contact trace reads contact, fire and diagnostic snapshots")
	var normal: Dictionary = Dictionary(lobby.call("get_release_multiplayer_deeplink_snapshot", ["--release-multiplayer-host"]))
	_assert(not bool(normal.get("first_contact", true)), "Ordinary multiplayer Host start does not automate First Contact")

	var harness_source := FileAccess.get_file_as_string(HARNESS_PATH)
	for token in [
		"FirstContact",
		"--release-multiplayer-first-contact",
		"release_host_client_first_contact_playtest.json",
		"first_fire_converged",
		"contact_count",
		"fire_event_ids",
		"TASK_1150",
	]:
		_assert(harness_source.contains(token), "Release harness contains %s" % token)
	lobby.queue_free()
	await process_frame
	print("TASK_1150 connected release First Contact: %d/14 PASS" % (14 - _failed))
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
