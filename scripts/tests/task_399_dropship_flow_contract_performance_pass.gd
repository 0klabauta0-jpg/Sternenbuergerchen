extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_399 Dropship Flow Contract Performance Pass Verifier ===")
	await _test_deboarding_runtime_feedback_is_throttled()
	await _test_parallel_drop_runtime_feedback_is_throttled()
	await _test_legacy_unit_suppression_is_cached_but_explicit_call_still_works()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_399: FAILED")
		quit(1)
	else:
		print("TASK_399: ALL PASSED")
		quit(0)


func _test_deboarding_runtime_feedback_is_throttled() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for deboarding feedback throttle")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_until_drop_phase(controller, "unloading", 80)
	controller.call("_debug_reset_mission_dropship_runtime_performance_counters")
	var simulated_frames: int = 24
	for _index in range(simulated_frames):
		controller.call("_update_drop_sequence", 0.05)
		await process_frame
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_dropship_runtime_performance_snapshot"))
	var flush_count: int = int(snapshot.get("runtime_feedback_flush_count", 999))
	_assert(flush_count > 0, "Deboarding still flushes runtime feedback during progress")
	_assert(flush_count < simulated_frames / 2, "Deboarding does not rebuild full mission HUD on every simulated frame")
	_assert(int(snapshot.get("runtime_planning_emit_count", -1)) == flush_count, "Throttled deboarding keeps planning emits paired with runtime feedback flushes")

	scene.queue_free()
	await _wait_frames(2)


func _test_parallel_drop_runtime_feedback_is_throttled() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for parallel feedback throttle")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_until_drop_phase(controller, "unloading", 80)
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_beta")
	await _wait_frames(4)
	controller.call("_debug_reset_mission_dropship_runtime_performance_counters")
	var simulated_frames: int = 20
	for _index in range(simulated_frames):
		controller.call("_update_drop_sequence", 0.05)
		await process_frame
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_dropship_runtime_performance_snapshot"))
	var flush_count: int = int(snapshot.get("runtime_feedback_flush_count", 999))
	var drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var beta_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(not beta_card.is_empty() and String(beta_card.get("state", "")).strip_edges() in ["inbound", "landed", "unloading", "outbound", "to_homebase"], "Parallel Dropship keeps updating its independent card state")
	_assert(flush_count < simulated_frames, "Parallel Dropships do not force full UI/planning feedback on every motion frame")

	scene.queue_free()
	await _wait_frames(2)


func _test_legacy_unit_suppression_is_cached_but_explicit_call_still_works() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for legacy suppression cache")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_debug_reset_mission_dropship_runtime_performance_counters")
	for _index in range(4):
		controller.call("_update_ui")
		await process_frame
	var cached_snapshot: Dictionary = Dictionary(controller.call("get_mission_dropship_runtime_performance_snapshot"))
	_assert(int(cached_snapshot.get("legacy_unit_visual_suppression_count", 999)) <= 1, "Normal HUD refresh does not repeat recursive legacy unit suppression every time")

	var forced_sprite := _find_first_unit_sprite(scene)
	if forced_sprite != null:
		forced_sprite.visible = true
	controller.call("_suppress_legacy_2d_readability_overlays")
	await _wait_frames(2)
	_assert(forced_sprite == null or not forced_sprite.visible, "Explicit legacy unit suppression still hides old Sprite2D children")

	scene.queue_free()
	await _wait_frames(2)


func _build_mission_scene_with_two_waiting_dropships() -> Node:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null:
		return scene
	var unit_ids: Array = _collect_friendly_unit_ids(scene)
	if unit_ids.size() < 4:
		unit_ids = ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_source"] = "homebase_direct"
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["drop_ship_staged"] = true
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(384.0, 224.0)
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		_build_waiting_mission_card("dropship_alpha", "Dropship Alpha", unit_ids.slice(0, 2), "alpha_ft", "NW", Vector2(384.0, 224.0)),
		_build_waiting_mission_card("dropship_beta", "Dropship Beta", unit_ids.slice(2, 4), "beta_ft", "SE", Vector2(672.0, 352.0)),
	]
	controller.call("set_planning_state", planning_state)
	controller.call("_update_ui")
	await _wait_frames(6)
	return scene


func _build_waiting_mission_card(craft_id: String, display_name: String, unit_ids: Array, fireteam_id: String, approach_angle: String, lz_position: Vector2) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": "waiting",
		"progress": 100.0,
		"embarked_unit_ids": unit_ids.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"queued_fireteam_ids": [fireteam_id],
		"passenger_count": unit_ids.size(),
		"has_lz_position": true,
		"lz_position": lz_position,
		"approach_angle": approach_angle,
		"drop_ship_staged": true,
		"payload_source": "homebase_direct",
	}


func _wait_until_drop_phase(controller: Node, phase: String, max_frames: int) -> void:
	for _index in range(max_frames):
		if String(controller.get("_drop_sequence_phase")) == phase:
			return
		controller.call("_update_drop_sequence", 0.16)
		await process_frame


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _find_first_unit_sprite(root_node: Node) -> Sprite2D:
	for unit in _collect_unit_nodes(root_node):
		for child in unit.get_children():
			var sprite := child as Sprite2D
			if sprite != null:
				return sprite
	return null


func _collect_unit_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	for node in _collect_nodes(root_node):
		if node.has_method("get_unit_id") and node.has_method("get_team_id"):
			result.append(node)
	return result


func _collect_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	for node in _collect_nodes(mission_root):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		var unit_id: String = String(node.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			result.append(unit_id)
	result.sort()
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
