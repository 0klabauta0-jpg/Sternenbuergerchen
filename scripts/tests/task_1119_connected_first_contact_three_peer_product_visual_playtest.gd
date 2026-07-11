extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")
const ENET_PORT_START := 19840
const ENET_PORT_END := 19850
const BLUE_PNG := "res://tmp/task_1119_product_first_contact_blue.png"
const GOLD_PNG := "res://tmp/task_1119_product_first_contact_gold.png"
const BLUE_WORLD_PNG := "res://tmp/task_1124_first_contact_blue_world.png"
const GOLD_WORLD_PNG := "res://tmp/task_1124_first_contact_gold_world.png"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1119 Connected First Contact Three-Peer Product Visual Playtest ===")
	root.size = Vector2i(1920, 1080)
	var fixture: Dictionary = await _create_lobby_triple()
	_assert(bool(fixture.get("connected", false)), "Host and two clients connect through product lobbies")
	if not bool(fixture.get("connected", false)):
		quit(1)
		return
	var lobbies: Array = fixture["lobbies"]
	var apis: Array = fixture["apis"]
	(lobbies[0] as Node).get_node("MultiplayerSession").call("set_lobby_player_setup", {"team_play_mode": "coop", "team_slot": "team_alpha"})
	await _poll_all(apis, 24)
	var assignments: Dictionary = Dictionary(Dictionary((lobbies[0] as Node).call("get_session_snapshot")).get("assignments", {}))
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	var active_indices: Array = []
	for index in range(lobbies.size()):
		var peer_id: int = (apis[index] as MultiplayerAPI).get_unique_id()
		if not PackedStringArray(peer_fireteams.get(peer_id, PackedStringArray())).is_empty():
			active_indices.append(index)
	_assert(active_indices.size() == 2, "Product assignment exposes two active peers and one Spectator")
	for lobby_variant in lobbies:
		(lobby_variant as Node).call("set_ready", true)
	await _poll_all(apis, 36)
	_assert(bool((lobbies[0] as Node).call("start_mission")), "Host starts the product mission")
	for _index in range(40):
		await _poll_all(apis, 1)
		if _all_missions_active(lobbies):
			break
	_assert(_all_missions_active(lobbies), "All three product lobbies launch mission instances")

	var active_tokens := PackedStringArray()
	var index_by_fireteam: Dictionary = {}
	for index_variant in active_indices:
		var index: int = int(index_variant)
		var peer_id: int = (apis[index] as MultiplayerAPI).get_unique_id()
		var assigned: PackedStringArray = PackedStringArray(peer_fireteams.get(peer_id, PackedStringArray()))
		var mission: Node = (lobbies[index] as Node).get("_active_mission")
		var controller: Node = mission.get_node("TacticalController")
		var selected: PackedStringArray = PackedStringArray(controller.get("_selected_fireteam_ids"))
		var expected: String = String(assigned[0]).strip_edges().to_lower()
		active_tokens.append(expected)
		index_by_fireteam[expected] = index
		_assert(selected == PackedStringArray([expected]), "%s product mission starts focused on its assigned Fireteam" % expected.to_upper())
	var spectator_index: int = _spectator_index(apis, peer_fireteams)
	var spectator_mission: Node = (lobbies[spectator_index] as Node).get("_active_mission")
	var spectator_selection: PackedStringArray = PackedStringArray(spectator_mission.get_node("TacticalController").get("_selected_fireteam_ids"))
	_assert(spectator_selection.is_empty(), "Spectator product mission starts without command Fireteam selection")
	_assert(active_tokens.has("blue") and active_tokens.has("gold"), "Active product perspectives are BLUE and GOLD")

	var host_mission: Node = (lobbies[0] as Node).get("_active_mission")
	var host_controller: Node = host_mission.get_node("TacticalController")
	var host_driver: Node = host_mission.get_node("CombatLoopDriver")
	var host_simulation: Node = host_mission.get_node("SimulationRoot")
	var host_tick_before: int = int(host_simulation.get("tick_counter"))
	var blue_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "blue", true)))
	var gold_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "gold", true)))
	host_controller.call("set_planning_state", _build_deboarded_state(host_controller, blue_ids, gold_ids, PackedStringArray([String(peer_fireteams.get(1, PackedStringArray())[0])])))
	host_controller.call("_apply_drop_presence_state_to_units")
	_prepare_parallel_live_contacts(host_controller)
	var host_primary_view: Node = host_mission.get_node_or_null("Primary3DView")
	_assert(_fireteam_projection_is_readable(host_controller, host_primary_view, "blue"), "BLUE First Contact fixture projects as a readable two-dimensional formation")
	_assert(_fireteam_projection_is_readable(host_controller, host_primary_view, "gold"), "GOLD First Contact fixture projects as a readable two-dimensional formation")
	host_controller.call("_apply_fireteams_fire_rule_locally", PackedStringArray(["blue", "gold"]), "free", true)
	_assert(bool(host_controller.call("_apply_default_fireteam_behavior", "blue", 1)), "Host activates BLUE contact behavior")
	_assert(bool(host_controller.call("_apply_default_fireteam_behavior", "gold", 1)), "Host activates GOLD contact behavior")
	for _index in range(80):
		await _poll_all(apis, 1)
		var events: Array = Array(host_driver.call("get_fire_event_snapshot"))
		if _has_fireteam_event(events, "blue") and _has_fireteam_event(events, "gold"):
			break
	var host_events: Array = Array(host_driver.call("get_fire_event_snapshot"))
	var combat_debug: Dictionary = {
		"runs_local_authority": bool(host_driver.get("_runs_local_authority")),
		"process_mode": host_driver.process_mode,
		"simulation_process_mode": host_simulation.process_mode,
		"tick_before": host_tick_before,
		"tick_after": int(host_simulation.get("tick_counter")),
		"contact_count": Array(host_driver.call("get_contact_snapshot")).size(),
		"event_count": host_events.size(),
		"deployed_count": Array(Dictionary(host_controller.call("get_planning_state")).get("deployed_unit_ids", [])).size(),
		"blue_rule": host_controller.call("get_fireteam_fire_rule", "blue"),
		"gold_rule": host_controller.call("get_fireteam_fire_rule", "gold"),
	}
	print("TASK1119 COMBAT DEBUG %s" % JSON.stringify(combat_debug))
	_assert(bool(combat_debug.get("runs_local_authority", false)) and int(combat_debug.get("tick_after", 0)) > int(combat_debug.get("tick_before", 0)), "Product Host owns a progressing Combat tick: %s" % JSON.stringify(combat_debug))
	_assert(_has_fireteam_event(host_events, "blue") and _has_fireteam_event(host_events, "gold"), "Host produces distinct real First-Fire events for BLUE and GOLD")
	for _index in range(4):
		await _poll_all(apis, 1)
		if _product_perspectives_ready(lobbies, index_by_fireteam):
			break
	var perspective_signatures := PackedStringArray()
	for fireteam_id in ["blue", "gold"]:
		var product_index: int = int(index_by_fireteam.get(fireteam_id, -1))
		var mission: Node = (lobbies[product_index] as Node).get("_active_mission")
		var controller: Node = mission.get_node("TacticalController")
		controller.call("_update_ui")
		await process_frame
		var perspective: Dictionary = Dictionary(controller.call("get_connected_first_contact_hud_perspective_snapshot"))
		var primary_line: String = String(perspective.get("primary_line", ""))
		var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
		var primary_view: Node = mission.get_node_or_null("Primary3DView")
		var primary_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
		var client_simulation: Node = mission.get_node("SimulationRoot")
		var client_driver: Node = mission.get_node("CombatLoopDriver")
		var snapshot_debug: Dictionary = Dictionary(client_simulation.call("get_multiplayer_snapshot_debug_snapshot"))
		print("TASK1119 %s PEER DEBUG %s" % [fireteam_id.to_upper(), JSON.stringify({
			"apply_count": int(snapshot_debug.get("apply_count", 0)),
			"last_server_tick": int(Dictionary(client_simulation.get("_last_server_state")).get("tick", -1)),
			"runs_local_authority": bool(client_driver.get("_runs_local_authority")),
			"contact_count": Array(client_driver.call("get_contact_snapshot")).size(),
			"event_count": Array(client_driver.call("get_fire_event_snapshot")).size(),
			"fire_event_id": String(perspective.get("fire_event_id", "")),
		})])
		_assert(String(perspective.get("fireteam_token", "")) == fireteam_id.to_upper() and not String(perspective.get("fire_event_id", "")).is_empty(), "%s product peer reads its own real First-Fire event" % fireteam_id.to_upper())
		_assert(primary_line.begins_with("%s | CONTACT FIRE" % fireteam_id.to_upper()) and primary_line.contains("ROE") and primary_line.contains("NEXT"), "%s product peer exposes Contact, ROE and next grip" % fireteam_id.to_upper())
		_assert(String(feedback.get("selected_fireteam_status_label_text", "")).contains(primary_line) and String(feedback.get("mission_control_status_text", "")).contains(primary_line), "%s product Selected Fireteam and Mission Control agree" % fireteam_id.to_upper())
		var frame_debug: Dictionary = {
			"camera_size": float(primary_snapshot.get("camera_size", 99.0)),
			"frame_signature": String(controller.get("_connected_first_contact_world_frame_signature")),
			"contact_count": Array(controller.call("get_contact_snapshot")).size(),
			"selection": Array(controller.get("_selected_fireteam_ids")),
		}
		print("TASK1119 %s FRAME DEBUG %s" % [fireteam_id.to_upper(), JSON.stringify(frame_debug)])
		_assert(float(primary_snapshot.get("camera_size", 99.0)) >= 24.0 and float(primary_snapshot.get("camera_size", 99.0)) <= 32.0 and not String(controller.get("_connected_first_contact_world_frame_signature")).is_empty(), "%s product world frames the complete local Fireteam and Contact once: %s" % [fireteam_id.to_upper(), JSON.stringify(frame_debug)])
		_assert(_local_contact_frame_is_hud_clear(controller, primary_view), "%s complete local Fireteam and Contact stay inside the HUD-clear tactical area" % fireteam_id.to_upper())
		_assert(int(primary_snapshot.get("dropship_visual_count", -1)) == 0, "%s product Contact world removes completed empty return Dropships" % fireteam_id.to_upper())
		perspective_signatures.append(String(perspective.get("perspective_signature", "")))
	_assert(perspective_signatures.size() == 2 and not perspective_signatures[0].is_empty() and perspective_signatures[0] != perspective_signatures[1], "Product peers expose distinct stable HUD perspectives")
	var active_client_index: int = int(index_by_fireteam.get("gold", -1)) if int(index_by_fireteam.get("gold", -1)) != 0 else int(index_by_fireteam.get("blue", -1))
	var active_client_mission: Node = (lobbies[active_client_index] as Node).get("_active_mission")
	var active_client_simulation: Node = active_client_mission.get_node("SimulationRoot")
	var spectator_simulation: Node = spectator_mission.get_node("SimulationRoot")
	_assert(Array(active_client_simulation.get("command_queue")).is_empty() and Array(active_client_simulation.get("effects_queue")).is_empty() and Array(spectator_simulation.get("command_queue")).is_empty() and Array(spectator_simulation.get("effects_queue")).is_empty(), "Product clients create no local Combat commands or effects")
	_assert(bool(host_simulation.get("is_server_authoritative")), "Product Host remains authoritative during first contact")

	var capture_perspective: String = OS.get_environment("STERNENBUERGERCHEN_TASK1119_CAPTURE_PERSPECTIVE").strip_edges().to_lower()
	if DisplayServer.get_name().strip_edges().to_lower() != "headless" and capture_perspective in ["blue", "gold"]:
		await _capture_product_perspective(lobbies, int(index_by_fireteam.get(capture_perspective, -1)), BLUE_PNG if capture_perspective == "blue" else GOLD_PNG)

	_cleanup(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _build_deboarded_state(controller: Node, blue_ids: Array, gold_ids: Array, selected_fireteams: PackedStringArray) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "to_fob"
	state["embarked_unit_ids"] = []
	state["deployed_unit_ids"] = blue_ids + gold_ids
	state["selected_fireteams"] = Array(selected_fireteams)
	state["mission_drop_cards"] = [
		{"craft_id": "dropship_blue", "state": "to_fob", "embarked_unit_ids": [], "boarded_fireteam_ids": ["blue"]},
		{"craft_id": "dropship_gold", "state": "to_fob", "embarked_unit_ids": [], "boarded_fireteam_ids": ["gold"]},
	]
	return state


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _prepare_parallel_live_contacts(controller: Node) -> void:
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	if enemies.size() < 2:
		return
	_place_fireteam(controller, "blue", Vector2(120.0, 130.0))
	_place_fireteam(controller, "gold", Vector2(120.0, 230.0))
	(enemies[0] as Node2D).global_position = Vector2(220.0, 130.0)
	(enemies[1] as Node2D).global_position = Vector2(228.0, 230.0)


func _place_fireteam(controller: Node, fireteam_id: String, center: Vector2) -> void:
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var offsets: Array[Vector2] = [Vector2(-32.0, -32.0), Vector2(32.0, -32.0), Vector2(-32.0, 32.0), Vector2(32.0, 32.0), Vector2.ZERO]
	for index in range(mini(units.size(), offsets.size())):
		if units[index] is Node2D:
			(units[index] as Node2D).global_position = center + offsets[index]


func _fireteam_projection_is_readable(controller: Node, view: Node, fireteam_id: String) -> bool:
	if view == null or not view.has_method("world_to_screen_position"):
		return false
	var screen_positions: Array[Vector2] = []
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit != null:
			screen_positions.append(Vector2(view.call("world_to_screen_position", unit.global_position)))
	if screen_positions.size() < 3:
		print("TASK1119 FORMATION DEBUG %s" % JSON.stringify({"fireteam_id": fireteam_id, "unit_count": screen_positions.size()}))
		return false
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	var minimum_pair_distance: float = INF
	for first_index in range(screen_positions.size()):
		var point: Vector2 = screen_positions[first_index]
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
		for second_index in range(first_index + 1, screen_positions.size()):
			minimum_pair_distance = minf(minimum_pair_distance, point.distance_to(screen_positions[second_index]))
	var metrics: Dictionary = {
		"fireteam_id": fireteam_id,
		"minimum_pair_distance": minimum_pair_distance,
		"horizontal_span": max_x - min_x,
		"vertical_span": max_y - min_y,
	}
	var readable: bool = minimum_pair_distance >= 18.0 and float(metrics["horizontal_span"]) >= 18.0 and float(metrics["vertical_span"]) >= 18.0
	if not readable:
		print("TASK1119 FORMATION DEBUG %s" % JSON.stringify(metrics))
	return readable


func _local_contact_frame_is_hud_clear(controller: Node, view: Node) -> bool:
	if view == null or not view.has_method("world_to_screen_position") or not controller.has_method("_build_connected_first_contact_frame_positions"):
		return false
	var positions: Array = Array(controller.call("_build_connected_first_contact_frame_positions", controller.call("get_contact_snapshot")))
	if positions.size() < 2:
		return false
	var tactical_area := Rect2(Vector2(340.0, 110.0), Vector2(1180.0, 670.0))
	for position_variant in positions:
		if typeof(position_variant) != TYPE_VECTOR2:
			return false
		var screen_position: Vector2 = Vector2(view.call("world_to_screen_position", Vector2(position_variant)))
		if not tactical_area.has_point(screen_position):
			return false
	return true


func _has_fireteam_event(events: Array, fireteam_id: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY and String(Dictionary(event_variant).get("attacker_fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return true
	return false


func _product_perspectives_ready(lobbies: Array, index_by_fireteam: Dictionary) -> bool:
	for fireteam_id in ["blue", "gold"]:
		var product_index: int = int(index_by_fireteam.get(fireteam_id, -1))
		if product_index < 0:
			return false
		var mission: Node = (lobbies[product_index] as Node).get("_active_mission")
		var perspective: Dictionary = Dictionary(mission.get_node("TacticalController").call("get_connected_first_contact_hud_perspective_snapshot"))
		if String(perspective.get("fireteam_token", "")) != fireteam_id.to_upper() or String(perspective.get("fire_event_id", "")).is_empty():
			return false
	return true


func _capture_product_perspective(lobbies: Array, target_index: int, path: String) -> void:
	for index in range(lobbies.size()):
		var lobby: Control = lobbies[index] as Control
		var mission: Node = lobby.get("_active_mission")
		mission.get_node("SimulationRoot").process_mode = Node.PROCESS_MODE_DISABLED
		mission.get_node("CombatLoopDriver").process_mode = Node.PROCESS_MODE_DISABLED
		var is_target: bool = index == target_index
		lobby.visible = is_target
		if mission is Node2D:
			(mission as Node2D).visible = is_target
		var primary_view: CanvasLayer = mission.get_node_or_null("Primary3DView") as CanvasLayer
		if primary_view != null:
			primary_view.visible = is_target
			var viewport_container := primary_view.get("_viewport_container") as Control
			if viewport_container != null:
				viewport_container.visible = is_target
		var tactical_ui: CanvasLayer = mission.get_node_or_null("TacticalUI") as CanvasLayer
		if tactical_ui != null:
			tactical_ui.visible = is_target
	_assert(_capture_visibility_is_isolated(lobbies, target_index), "Product capture isolates the selected peer root without pausing other peers")
	var target_mission: Node = (lobbies[target_index] as Node).get("_active_mission")
	target_mission.get_node("TacticalController").call("_update_ui")
	var full_frame_dirty := ColorRect.new()
	full_frame_dirty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_frame_dirty.color = Color(0.0, 0.0, 0.0, 0.001)
	root.add_child(full_frame_dirty)
	full_frame_dirty.position = Vector2.ZERO
	full_frame_dirty.size = Vector2(root.size)
	var capture_size: Vector2i = root.size
	root.size = Vector2i(capture_size.x - 1, capture_size.y)
	await process_frame
	root.size = capture_size
	for _frame in range(8):
		await process_frame
	_isolate_capture_viewport_geometry(lobbies, target_index)
	_assert(_capture_layers_are_isolated(lobbies, target_index), "Product capture keeps non-target CanvasLayers hidden through the settle frames")
	_assert(_capture_viewport_containers_are_isolated(lobbies, target_index), "Product capture isolates the embedded tactical SubViewportContainer")
	_assert(_capture_viewport_geometry_is_isolated(lobbies, target_index), "Product capture moves non-target SubViewport textures outside the evidence frame")
	RenderingServer.force_draw(true)
	await process_frame
	var target_primary_view: Node = target_mission.get_node_or_null("Primary3DView")
	var target_subviewport := target_primary_view.get("_subviewport") as SubViewport if target_primary_view != null else null
	var world_image: Image = target_subviewport.get_texture().get_image() if target_subviewport != null else null
	var world_path: String = BLUE_WORLD_PNG if path == BLUE_PNG else GOLD_WORLD_PNG
	var world_error: Error = world_image.save_png(world_path) if world_image != null else ERR_CANT_CREATE
	_assert(world_image != null and world_image.get_width() == 1920 and world_image.get_height() == 1080 and world_error == OK, "%s is a valid FullHD target-world capture" % world_path.get_file())
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(path) if image != null else ERR_CANT_CREATE
	_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080 and error == OK, "%s is a valid FullHD product capture" % path.get_file())


func _capture_visibility_is_isolated(lobbies: Array, target_index: int) -> bool:
	for index in range(lobbies.size()):
		if bool((lobbies[index] as Control).visible) != (index == target_index):
			return false
	return true


func _capture_layers_are_isolated(lobbies: Array, target_index: int) -> bool:
	for index in range(lobbies.size()):
		var mission: Node = (lobbies[index] as Node).get("_active_mission")
		for layer_name in ["Primary3DView", "TacticalUI"]:
			var layer := mission.get_node_or_null(layer_name) as CanvasLayer
			if layer != null and layer.visible != (index == target_index):
				return false
	return true


func _capture_viewport_containers_are_isolated(lobbies: Array, target_index: int) -> bool:
	for index in range(lobbies.size()):
		var mission: Node = (lobbies[index] as Node).get("_active_mission")
		var primary_view: Node = mission.get_node_or_null("Primary3DView")
		var viewport_container := primary_view.get("_viewport_container") as Control if primary_view != null else null
		if viewport_container != null and viewport_container.visible != (index == target_index):
			return false
	return true


func _capture_viewport_geometry_is_isolated(lobbies: Array, target_index: int) -> bool:
	for index in range(lobbies.size()):
		if index == target_index:
			continue
		var mission: Node = (lobbies[index] as Node).get("_active_mission")
		var primary_view: Node = mission.get_node_or_null("Primary3DView")
		var viewport_container := primary_view.get("_viewport_container") as Control if primary_view != null else null
		if viewport_container != null and viewport_container.position.x < float(root.size.x * 2):
			return false
	return true


func _isolate_capture_viewport_geometry(lobbies: Array, target_index: int) -> void:
	for index in range(lobbies.size()):
		if index == target_index:
			continue
		var mission: Node = (lobbies[index] as Node).get("_active_mission")
		var primary_view: Node = mission.get_node_or_null("Primary3DView")
		var viewport_container := primary_view.get("_viewport_container") as Control if primary_view != null else null
		if viewport_container != null:
			viewport_container.position = Vector2(float(root.size.x * 3), 0.0)


func _create_lobby_triple() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var lobbies: Array = []
		for index in range(3):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1119Peer%d" % index
			root.add_child(local_root)
			set_multiplayer(api, local_root.get_path())
			var lobby: Node = LOBBY_SCENE.instantiate()
			lobby.name = "Lobby"
			local_root.add_child(lobby)
			lobby.get_node("MultiplayerSession").set("max_players", 3)
			roots.append(local_root)
			apis.append(api)
			lobbies.append(lobby)
		await process_frame
		if not bool((lobbies[0] as Node).call("host_game", port)):
			_free_roots(roots)
			continue
		if not bool((lobbies[1] as Node).call("join_game", "127.0.0.1", port)) or not bool((lobbies[2] as Node).call("join_game", "127.0.0.1", port)):
			_free_roots(roots)
			continue
		for _index in range(240):
			await _poll_all(apis, 1)
			if int(Dictionary((lobbies[0] as Node).call("get_session_snapshot")).get("connected_count", 0)) == 3:
				return {"connected": true, "roots": roots, "apis": apis, "lobbies": lobbies}
		_free_roots(roots)
		await process_frame
	return {"connected": false}


func _all_missions_active(lobbies: Array) -> bool:
	for lobby_variant in lobbies:
		if not bool((lobby_variant as Node).call("has_active_mission")):
			return false
	return true


func _spectator_index(apis: Array, peer_fireteams: Dictionary) -> int:
	for index in range(apis.size()):
		var peer_id: int = (apis[index] as MultiplayerAPI).get_unique_id()
		if PackedStringArray(peer_fireteams.get(peer_id, PackedStringArray())).is_empty():
			return index
	return -1


func _poll_all(apis: Array, frames: int) -> void:
	for _index in range(frames):
		for api_variant in apis:
			(api_variant as MultiplayerAPI).poll()
		await process_frame


func _cleanup(fixture: Dictionary) -> void:
	for lobby_variant in Array(fixture.get("lobbies", [])):
		(lobby_variant as Node).call("disconnect_game")
	_free_roots(Array(fixture.get("roots", [])))


func _free_roots(roots: Array) -> void:
	for root_variant in roots:
		(root_variant as Node).queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
