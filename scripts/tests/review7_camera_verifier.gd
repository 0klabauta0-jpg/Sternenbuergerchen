extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MISSION_SCENE = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var server_peer := ENetMultiplayerPeer.new()
	var port_used: int = -1
	for port in range(19880, 19900):
		if server_peer.create_server(port, 2) == OK:
			port_used = port
			break
	_check(port_used >= 0, "Local ENet camera fixture can listen")
	if port_used < 0:
		_finish()
		return
	var server_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
	var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
	var server_root := Node.new()
	server_root.name = "Review7CameraServer"
	root.add_child(server_root)
	set_multiplayer(server_api, server_root.get_path())
	server_api.multiplayer_peer = server_peer
	var client_root := Node.new()
	client_root.name = "Review7CameraClient"
	root.add_child(client_root)
	set_multiplayer(client_api, client_root.get_path())
	var client_peer := ENetMultiplayerPeer.new()
	var connect_error: Error = client_peer.create_client("127.0.0.1", port_used)
	_check(connect_error == OK, "Local ENet camera client can connect")
	if connect_error != OK:
		server_peer.close()
		server_root.free()
		client_root.free()
		_finish()
		return
	client_api.multiplayer_peer = client_peer
	for _frame in range(240):
		server_api.poll()
		client_api.poll()
		await process_frame
		if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and server_api.get_peers().size() == 1:
			break
	_check(client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and not client_api.is_server(), "Camera regression runs in a real connected client subtree")
	if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var mission: Node = await _make_client_mission(client_root, server_api, client_api)
		_test_same_contact_and_new_focus(mission)
		mission.free()
		await process_frame
		# The real next-mission lifecycle creates a fresh controller. It must
		# still frame the same identity, without resetting private camera caches.
		var next_mission: Node = await _make_client_mission(client_root, server_api, client_api)
		var next_controller: Node = next_mission.get_node("TacticalController")
		var next_view: Node = next_mission.get_node("Primary3DView")
		_check(String(next_controller.get("_connected_first_contact_world_frame_signature")).is_empty(), "A fresh mission starts with no first-contact frame")
		next_controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
		_pan_and_zoom(next_view)
		var before_first: Dictionary = _camera_state(next_view)
		next_controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(20000, "enemy_delta", Vector2(228.0, 130.0)))
		_check(not _same_camera(before_first, _camera_state(next_view)), "A new mission can frame the same contact identity again")
		_check(not String(next_controller.get("_connected_first_contact_world_frame_signature")).is_empty(), "New-mission framing records its own one-shot context")
		next_mission.free()
	client_peer.close()
	server_peer.close()
	client_root.free()
	server_root.free()
	await process_frame
	_finish()


func _make_client_mission(client_root: Node, server_api: MultiplayerAPI, client_api: MultiplayerAPI) -> Node:
	var mission: Node = MISSION_SCENE.instantiate()
	# Match lobby launch ordering: authority is configured BEFORE _ready.
	mission.get_node("SimulationRoot").set("is_server_authoritative", true)
	client_root.add_child(mission)
	for _frame in range(12):
		server_api.poll()
		client_api.poll()
		await process_frame
	# Freeze unrelated fixture work, retaining the real snapshot consumer,
	# CombatLoopDriver, contact cache, primary bridge and camera implementation.
	mission.process_mode = Node.PROCESS_MODE_DISABLED
	return mission


func _test_same_contact_and_new_focus(mission: Node) -> void:
	var controller: Node = mission.get_node("TacticalController")
	var view: Node = mission.get_node("Primary3DView")
	var driver: Node = mission.get_node("CombatLoopDriver")
	_check(bool(controller.call("_is_connected_network_snapshot_client")) and not bool(driver.get("_runs_local_authority")), "Fixture consumes remote snapshots instead of running local combat authority")
	_check(Array(controller.call("_get_fireteam_units", "blue", true)).size() > 0 and Array(controller.call("_get_fireteam_units", "gold", true)).size() > 0, "Real mission supplies members for both focus contexts")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	_pan_and_zoom(view)
	var before_first: Dictionary = _camera_state(view)
	controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(10000, "enemy_delta", Vector2(228.0, 130.0)))
	_check(Array(controller.call("get_contact_snapshot")).size() == 1, "Normal authority snapshot consumer publishes the first contact")
	_check(not _same_camera(before_first, _camera_state(view)), "First connected contact frames local members and target")
	var first_signature: String = String(controller.get("_connected_first_contact_world_frame_signature"))
	_check(not first_signature.is_empty(), "Successful first frame records its context")
	_pan_and_zoom(view)
	var manual: Dictionary = _camera_state(view)
	controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(10001, "enemy_delta", Vector2(228.0, 130.0)))
	_check(_same_camera(manual, _camera_state(view)), "Unchanged same-ID contact preserves manual pan and zoom")
	controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(10002, "enemy_delta", Vector2(292.0, 130.0)))
	_check(_same_camera(manual, _camera_state(view)), "Moving same-ID contact preserves manual pan and zoom through normal snapshot refresh")
	var moved_contacts: Array = Array(controller.call("get_contact_snapshot"))
	_check(not moved_contacts.is_empty() and Vector2(Dictionary(moved_contacts[0]).get("approximate_position", Vector2.ZERO)).is_equal_approx(Vector2(292.0, 130.0)), "Moving-contact snapshot is still consumed for current contact visuals")
	_check(String(controller.get("_connected_first_contact_world_frame_signature")) == first_signature, "Position changes retain the original first-contact context")
	controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(10003, "enemy_echo", Vector2(180.0, 195.0)))
	_check(not _same_camera(manual, _camera_state(view)), "A different target identity can receive a new initial frame")
	_check(String(controller.get("_connected_first_contact_world_frame_signature")) != first_signature, "New target records a distinct first-contact context")
	controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(10004, "enemy_echo", Vector2(180.0, 195.0), "gold"))
	_pan_and_zoom(view)
	var before_selection: Dictionary = _camera_state(view)
	controller.call("_set_selected_fireteams", PackedStringArray(["gold"]), false)
	_check(not _same_camera(before_selection, _camera_state(view)), "Changing the selected local fireteam still permits initial contact framing")
	_pan_and_zoom(view)
	var gold_manual: Dictionary = _camera_state(view)
	controller.call("_on_multiplayer_authority_snapshot_applied", _snapshot(10005, "enemy_echo", Vector2(240.0, 195.0), "gold"))
	_check(_same_camera(gold_manual, _camera_state(view)), "Moving same-ID GOLD contact also preserves manual camera")


func _snapshot(tick: int, target_id: String, position: Vector2, fireteam_id: String = "blue") -> Dictionary:
	return {
		"tick": tick,
		"contacts": [{
			"fireteam_id": fireteam_id, "unit_id": target_id, "target_id": target_id,
			"team_id": "team_bravo", "last_known_position": position,
			"approximate_position": position, "detection_state": "confirmed",
			"report_state": "current", "confidence": 1.0,
		}],
		"fire_events": [], "tactical_rules": [], "dropship": {}, "mission_interactions": {},
	}


func _pan_and_zoom(view: Node) -> void:
	view.call("pan_camera", Vector2(1.0, 0.0), 0.75)
	view.call("zoom_camera", 2.0)


func _camera_state(view: Node) -> Dictionary:
	return {"focus": Vector2(view.call("get_camera_focus_grid_position")), "size": float(view.call("get_camera_size"))}


func _same_camera(first: Dictionary, second: Dictionary) -> bool:
	return Vector2(first["focus"]).is_equal_approx(Vector2(second["focus"])) and is_equal_approx(float(first["size"]), float(second["size"]))


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)


func _finish() -> void:
	print("REVIEW7_CAMERA_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
