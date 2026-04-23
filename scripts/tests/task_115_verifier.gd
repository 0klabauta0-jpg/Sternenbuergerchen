extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_115 Marker System Verifier ===")
	_test_terrain_marker_roundtrip()
	await _test_map_editor_marker_workflow()
	await _test_tactical_marker_catalog_and_snap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_terrain_marker_roundtrip() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", "res://maps/test_mission_32x32_slots8.json")
	_assert(map_data != null, "TerrainMapData loads a map with legacy marker positions")
	_assert(bool(map_data.call("has_marker", "spawn_alpha")), "Legacy spawn_alpha marker still resolves after marker normalization")
	var spawn_record: Dictionary = Dictionary(map_data.call("get_marker_record", "spawn_alpha"))
	_assert(String(spawn_record.get("marker_type_id", "")) == "spawn_alpha", "Legacy fixed markers normalize to their catalog marker type")
	_assert(String(spawn_record.get("symbol", "")) == String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", "spawn_alpha")), "Legacy fixed markers inherit their catalog symbol")
	map_data.call("set_marker", "rally_point_01", "rally_point", Vector2(448.0, 349.0), {
		"name": "Entry Rally",
		"color": Color(0.22, 0.85, 0.75, 1.0),
	})
	var temp_path: String = "user://task_115_marker_roundtrip.json"
	var save_error: Error = map_data.call("save_to_file", temp_path)
	_assert(save_error == OK, "TerrainMapData saves rich marker records without error")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var rally_record: Dictionary = Dictionary(reloaded.call("get_marker_record", "rally_point_01"))
	_assert(String(rally_record.get("name", "")) == "Entry Rally", "Rich marker names survive a save/load roundtrip")
	_assert(String(rally_record.get("marker_type_id", "")) == "rally_point", "Rich marker type survives a save/load roundtrip")
	_assert(Color(rally_record.get("color", Color.WHITE)) == Color(0.22, 0.85, 0.75, 1.0), "Rich marker colors survive a save/load roundtrip")
	var absolute_temp_path: String = ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(absolute_temp_path):
		DirAccess.remove_absolute(absolute_temp_path)


func _test_map_editor_marker_workflow() -> void:
	var scene = await _load_scene("res://scenes/editor/map_editor.tscn")
	var add_type_option := scene.get_node("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerToolbarRow/AddMarkerTypeOption") as OptionButton
	var marker_list := scene.get_node("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerList") as ItemList
	_assert(add_type_option != null and marker_list != null, "Map editor exposes the dynamic marker list UI")

	_select_option_by_metadata(add_type_option, "rally_point")
	var added: bool = scene.call("_add_marker_of_selected_type")
	_assert(added, "Map editor can add a new marker from the shared editor marker type list")

	var terrain_map_data = scene.get("_terrain_map_data")
	var first_marker_id: String = String(scene.get("_selected_marker_id"))
	_assert(first_marker_id.begins_with("rally_point"), "New rally markers receive generated shared marker IDs")
	var snapped_target: Vector2 = scene.call("_snap_world_position_to_tile_center", Vector2(500.0, 333.0))
	scene.call("_move_marker_to_world_position", first_marker_id, Vector2(500.0, 333.0))
	_assert(Vector2(terrain_map_data.call("get_marker_position", first_marker_id, Vector2.ZERO)) == snapped_target, "Editor marker placement snaps to tile centers")

	scene.call("_on_marker_name_text_changed", "Forward Rally")
	scene.call("_on_marker_color_changed", Color(0.22, 0.85, 0.75, 1.0))
	var updated_record: Dictionary = Dictionary(terrain_map_data.call("get_marker_record", first_marker_id))
	_assert(String(updated_record.get("name", "")) == "Forward Rally", "Editor markers can be renamed through the marker panel")
	_assert(Color(updated_record.get("color", Color.WHITE)) == Color(0.22, 0.85, 0.75, 1.0), "Editor markers can change color through the marker panel")

	_select_option_by_metadata(add_type_option, "danger_zone")
	var second_added: bool = scene.call("_add_marker_of_selected_type")
	_assert(second_added, "Map editor can add a second marker of another shared editor type")
	var second_marker_id: String = String(scene.get("_selected_marker_id"))
	var second_before: Vector2 = Vector2(terrain_map_data.call("get_marker_position", second_marker_id, Vector2.ZERO))
	var overlap_result: bool = scene.call("_move_marker_to_world_position", second_marker_id, snapped_target)
	var second_after: Vector2 = Vector2(terrain_map_data.call("get_marker_position", second_marker_id, Vector2.ZERO))
	_assert(not overlap_result and second_after == second_before, "Editor blocks overlapping marker placement on the same tile")
	_assert(marker_list.item_count >= 2, "Map editor marker list shows multiple shared markers at once")
	scene.queue_free()
	await process_frame


func _test_tactical_marker_catalog_and_snap() -> void:
	var scene = await _load_scene("res://scenes/tests/mission_reactivity_test.tscn")
	var controller = scene.get_node("TacticalController")
	var requested_position := Vector2(287.0, 243.0)
	var snapped_position: Vector2 = controller.call("_snap_planning_position_to_tile_center", requested_position)
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", requested_position)
	var plans: Array = controller.call("get_order_plans_snapshot")
	var all_snapped: bool = true
	for plan_dict in plans:
		for waypoint_dict in Array(Dictionary(plan_dict).get("waypoints", [])):
			if Vector2(Dictionary(waypoint_dict).get("target_position", Vector2.ZERO)) != snapped_position:
				all_snapped = false
	_assert(refs.size() == 2 and all_snapped, "Player command markers on the tactical map snap to the shared tile centers")

	controller.call("_open_waypoint_command_menu", Vector2(120.0, 120.0), refs, false)
	var menu := scene.get_node("TacticalUI/WaypointCommandMenu") as PopupMenu
	var labels: PackedStringArray = []
	for index in range(menu.item_count):
		if menu.is_item_separator(index):
			continue
		labels.append(menu.get_item_text(index))
	var expected_labels: PackedStringArray = []
	for marker_type_id in PackedStringArray(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_type_ids_for_context", TERRAIN_MARKER_CATALOG_SCRIPT.CONTEXT_MISSION_PLAYER)):
		expected_labels.append(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)))
	var all_labels_present: bool = true
	for expected_label in expected_labels:
		if not labels.has(expected_label):
			all_labels_present = false
	_assert(all_labels_present, "Tactical waypoint menu is populated from the shared mission-player marker catalog")
	scene.queue_free()
	await process_frame


func _load_scene(scene_path: String) -> Node:
	var scene = load(scene_path).instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _select_option_by_metadata(option_button: OptionButton, metadata_value: String) -> void:
	for index in range(option_button.item_count):
		if String(option_button.get_item_metadata(index)) != metadata_value:
			continue
		option_button.select(index)
		return


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
