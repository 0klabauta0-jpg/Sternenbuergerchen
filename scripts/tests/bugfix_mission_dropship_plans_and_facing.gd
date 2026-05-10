extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Mission Dropship Plans And Facing ===")
	await _test_per_craft_lz_lines_render_without_inbound_ship_body()
	await _test_facing_angle_drives_fire_sector_direction()
	await _test_tile_selection_and_movement_markers_stay_on_map_tiles()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_per_craft_lz_lines_render_without_inbound_ship_body() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes controller and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_2"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(640.0, 320.0)
	planning_state["approach_angle"] = "SE"
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"state": "to_mission",
			"progress": 35.0,
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(224.0, 144.0),
			"approach_angle": "NW",
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"],
			"boarded_fireteam_ids": ["gold"],
			"has_lz_position": true,
			"lz_position": Vector2(640.0, 320.0),
			"approach_angle": "SE",
		},
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(8)

	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("dropship_visual_count", 0)) == 1, "Only the waiting in-map craft renders a Dropship body; inbound transfer craft stays body-hidden")
	_assert(int(render_snapshot.get("dropship_approach_line_count", 0)) >= 2, "Both Dropships keep their own LZ approach lines visible")
	_assert(int(render_snapshot.get("requested_lz_marker_count", 0)) >= 2, "Both Dropships keep their planned LZ tiles visible")

	var entries_before: Array = Array(controller.call("_build_mission_dropship_visual_entries", false, Vector2.ZERO))
	var second_before: Dictionary = _find_visual_entry(entries_before, "dropship_2")
	var origin_before: Vector2 = Vector2(second_before.get("approach_origin_position", Vector2.ZERO))
	controller.call("_select_approach_angle", "NW")
	await _wait_frames(4)
	var entries_after: Array = Array(controller.call("_build_mission_dropship_visual_entries", false, Vector2.ZERO))
	var second_after: Dictionary = _find_visual_entry(entries_after, "dropship_2")
	var origin_after: Vector2 = Vector2(second_after.get("approach_origin_position", Vector2.ZERO))
	_assert(not second_before.is_empty() and not second_after.is_empty(), "Selected craft produces a visual-plan entry for approach checks")
	_assert(origin_before.distance_to(origin_after) > 64.0, "Changing approach direction moves the selected craft's planned approach line immediately")
	scene.queue_free()
	await _wait_frames(2)


func _test_facing_angle_drives_fire_sector_direction() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	if controller == null or primary_view == null:
		_assert(false, "Mission scene exposes controller and Primary3DView for facing checks")
		scene.queue_free()
		await _wait_frames(2)
		return
	var blue_units: Array = Array(controller.call("_get_fireteam_units", "blue", true))
	var unit: Node = null
	for unit_variant in blue_units:
		if unit_variant is Node2D:
			unit = unit_variant
			break
	if unit == null:
		_assert(false, "Blue fireteam has at least one visible Node2D unit")
		scene.queue_free()
		await _wait_frames(2)
		return
	var facing_angle: float = 0.72
	unit.set_meta("facing_angle", facing_angle)
	var unit_position: Vector2 = (unit as Node2D).global_position
	var aim_direction: Vector2 = Vector2(primary_view.call("_resolve_unit_aim_direction", unit, unit_position)).normalized()
	var expected_direction: Vector2 = Vector2.RIGHT.rotated(facing_angle).normalized()
	_assert(aim_direction.dot(expected_direction) > 0.995, "Friendly fire sector direction follows the unit facing_angle metadata")
	scene.queue_free()
	await _wait_frames(2)


func _test_tile_selection_and_movement_markers_stay_on_map_tiles() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	if controller == null or primary_view == null:
		_assert(false, "Mission scene exposes controller and Primary3DView for marker checks")
		scene.queue_free()
		await _wait_frames(2)
		return

	primary_view.call("set_selected_grid_positions", [Vector2i(0, 0), Vector2i(-20, -20)])
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1, "Selection markers ignore off-map grid positions")

	var blue_units: Array = Array(controller.call("_get_fireteam_units", "blue", true))
	var anchor_position: Vector2 = Vector2.ZERO
	for unit_variant in blue_units:
		if unit_variant is Node2D:
			anchor_position = (unit_variant as Node2D).global_position
			break
	var order_payload: Dictionary = {
		"phase_index": 1,
		"movement_state_dicts": [
			{
				"fireteam_id": "blue",
				"advance_style": "bounding",
				"bound_origin_position": anchor_position,
				"bound_target_position": anchor_position + Vector2(48.0, 0.0),
				"current_anchor_target_position": anchor_position + Vector2(48.0, 0.0),
				"moving_unit_ids": PackedStringArray(["offmap_probe"]),
				"covering_unit_ids": PackedStringArray(),
				"current_target_positions": {
					"offmap_probe": Vector2(99999.0, 99999.0),
				},
			},
		],
	}
	primary_view.call("set_order_visual_payload", order_payload)
	await _wait_frames(2)
	snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("movement_group_marker_count", 0)) == 0, "Movement group markers skip off-map free-world targets")
	scene.queue_free()
	await _wait_frames(2)


func _find_visual_entry(entries: Array, craft_id: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry
	return {}


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
