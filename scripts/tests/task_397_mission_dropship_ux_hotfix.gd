extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_397 Mission Dropship UX Hotfix Verifier ===")
	await _test_shipcard_approach_grid_and_visible_vector()
	await _test_drop_can_start_while_other_ship_is_unloading()
	await _test_primary_view_suppresses_legacy_unit_sprites()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_397: FAILED")
		quit(1)
	else:
		print("TASK_397: ALL PASSED")
		quit(0)


func _test_shipcard_approach_grid_and_visible_vector() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes controller and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(6)
	var alpha_grid := _find_approach_grid(scene, "dropship_alpha")
	_assert(alpha_grid != null and alpha_grid.columns == 2, "Dropship card approach buttons are arranged as a 2x2 grid")
	_assert(_approach_grid_has_compact_buttons(alpha_grid), "Approach buttons are compact enough for the shipcard")
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("dropship_approach_line_count", 0)) >= 2 and int(render_snapshot.get("dropship_approach_arrow_count", 0)) >= 2, "Primary3DView renders visible green approach vectors for both planned dropships")
	_assert(float(render_snapshot.get("dropship_approach_line_width_factor", 0.0)) >= 0.32, "Approach vector strip is wide enough to read as a clear flight lane")

	scene.queue_free()
	await _wait_frames(2)


func _test_drop_can_start_while_other_ship_is_unloading() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes tactical controller for parallel unloading check")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_until_drop_phase(controller, "unloading", 80)
	_assert(String(controller.get("_drop_sequence_craft_id")) == "dropship_alpha" and String(controller.get("_drop_sequence_phase")) == "unloading", "Alpha reaches unload phase before Beta is commanded")

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_beta")
	await _wait_frames(4)
	var parallel_sequences: Dictionary = Dictionary(controller.get("_parallel_drop_sequences_by_craft"))
	var drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var alpha_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(parallel_sequences.has("dropship_alpha") and String(controller.get("_drop_sequence_craft_id")) == "dropship_beta", "Beta Drop starts while Alpha remains tracked as its own live sequence")
	_assert(String(alpha_card.get("state", "")) == "unloading" and String(beta_card.get("state", "")) == "inbound", "Shipcard states stay independent during overlapping drop phases")

	scene.queue_free()
	await _wait_frames(2)


func _test_primary_view_suppresses_legacy_unit_sprites() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for legacy visual suppression")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var forced_sprite := _find_first_unit_sprite(scene)
	if forced_sprite != null:
		forced_sprite.visible = true
	controller.call("_suppress_legacy_2d_readability_overlays")
	await _wait_frames(2)
	_assert(forced_sprite == null or not forced_sprite.visible, "Primary 2.5D view suppresses old unit Sprite2D visuals")
	_assert(_count_visible_unit_sprite_children(scene) == 0, "No legacy NPC sprite children remain visible on the 2.5D mission map")

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
	}


func _wait_until_drop_phase(controller: Node, phase: String, max_frames: int) -> void:
	for _index in range(max_frames):
		if String(controller.get("_drop_sequence_phase")) == phase:
			return
		controller.call("_update_drop_sequence", 0.16)
		await process_frame


func _find_approach_grid(root_node: Node, craft_id: String) -> GridContainer:
	for node in _collect_nodes(root_node):
		var grid := node as GridContainer
		if grid != null \
			and bool(grid.get_meta("mission_dropship_card_approach_grid", false)) \
			and String(grid.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id:
			return grid
	return null


func _approach_grid_has_compact_buttons(grid: GridContainer) -> bool:
	if grid == null or grid.get_child_count() != 4:
		return false
	for child in grid.get_children():
		var button := child as Button
		if button == null or not bool(button.get_meta("mission_dropship_card_command_button", false)):
			return false
		if button.custom_minimum_size.x > 25.0 or button.custom_minimum_size.y > 16.0:
			return false
	return true


func _find_first_unit_sprite(root_node: Node) -> Sprite2D:
	for unit in _collect_unit_nodes(root_node):
		for child in unit.get_children():
			var sprite := child as Sprite2D
			if sprite != null:
				return sprite
	return null


func _count_visible_unit_sprite_children(root_node: Node) -> int:
	var count: int = 0
	for unit in _collect_unit_nodes(root_node):
		for child in unit.get_children():
			if child is Sprite2D and (child as Sprite2D).visible:
				count += 1
	return count


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
	if mission_root == null:
		return result
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


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


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
