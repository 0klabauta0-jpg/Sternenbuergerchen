extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_358 MapEditor Undo Stroke Transactions ===")
	await _test_brush_stroke_undo_restores_all_tiles()
	await _test_height_stroke_undo_restores_auto_cliffs()
	await _test_eraser_undo_restores_structure_layer()
	await _test_empty_transaction_and_stack_limit()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_358: FAILED")
		quit(1)
	else:
		print("TASK_358: ALL PASSED")
		quit(0)


func _test_brush_stroke_undo_restores_all_tiles() -> void:
	var editor = await _make_editor()
	var center := Vector2i(4, 4)
	_prepare_square(editor, center, 1, "station_floor_panel", 0, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"))
	editor.set("_selected_type_id", "ground_flat")
	_set_brush_radius(editor, 1)
	var center_tile = _get_tile(editor, center)
	editor.call("_apply_brush_at_world_position", Vector2(center_tile.world_position))

	var undo_snapshot: Dictionary = Dictionary(editor.call("get_undo_debug_snapshot"))
	_assert(int(undo_snapshot.get("undo_depth", 0)) == 1, "Brush stroke creates one undo transaction")
	_assert(int(undo_snapshot.get("top_tile_state_count", 0)) == 9, "Brush transaction records all changed radius tiles")
	_assert(_count_tiles_with_type(editor, center, 1, "ground_flat") == 9, "Brush stroke paints the whole radius")

	editor.call("_undo_last_change")
	_assert(_count_tiles_with_type(editor, center, 1, "station_floor_panel") == 9, "One undo restores the whole brush stroke")
	_assert(int(Dictionary(editor.call("get_undo_debug_snapshot")).get("undo_depth", -1)) == 0, "Brush undo consumes one transaction")

	editor.queue_free()
	await _wait_frames(2)


func _test_height_stroke_undo_restores_auto_cliffs() -> void:
	var editor = await _make_editor()
	var center := Vector2i(4, 4)
	_prepare_square(editor, center, 2, "ground_flat", 0, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"))
	editor.set("_height_tool_mode", "set_1")
	editor.set("_height_tool_edge_type", TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"))
	_set_brush_radius(editor, 1)
	var center_tile = _get_tile(editor, center)
	editor.call("_apply_height_tool_at_world_position", Vector2(center_tile.world_position))

	var undo_snapshot: Dictionary = Dictionary(editor.call("get_undo_debug_snapshot"))
	_assert(int(undo_snapshot.get("undo_depth", 0)) == 1, "Height stroke creates one undo transaction")
	_assert(int(undo_snapshot.get("top_tile_state_count", 0)) >= 9, "Height transaction includes changed and auto-reconciled tiles")
	_assert(int(_get_tile(editor, center).height_level) == 1, "Height stroke raises the center tile")
	_assert(_count_tiles_with_prefix(editor, center, 2, "cliff_") > 0, "Height stroke creates auto cliff visuals")

	editor.call("_undo_last_change")
	_assert(int(_get_tile(editor, center).height_level) == 0, "Height undo restores center height")
	_assert(_count_tiles_with_prefix(editor, center, 2, "cliff_") == 0, "Height undo removes auto cliff visuals in the same transaction")

	editor.queue_free()
	await _wait_frames(2)


func _test_eraser_undo_restores_structure_layer() -> void:
	var editor = await _make_editor()
	var grid := Vector2i(5, 5)
	var tile = _get_tile(editor, grid)
	tile.type_id = "wall_straight_se"
	tile.object_type_id = ""
	tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE")
	tile.blocks_los = true
	tile.walkable = false
	editor.call("_apply_eraser_at_world_position", Vector2(tile.world_position))

	var undo_snapshot: Dictionary = Dictionary(editor.call("get_undo_debug_snapshot"))
	_assert(int(undo_snapshot.get("undo_depth", 0)) == 1, "Eraser creates one undo transaction")
	_assert(String(tile.type_id) == "ground_flat", "Eraser removes the structure layer")
	editor.call("_undo_last_change")
	_assert(String(tile.type_id) == "wall_straight_se", "Eraser undo restores the structure layer")

	editor.queue_free()
	await _wait_frames(2)


func _test_empty_transaction_and_stack_limit() -> void:
	var editor = await _make_editor()
	var start_depth: int = int(Dictionary(editor.call("get_undo_debug_snapshot")).get("undo_depth", 0))
	editor.call("begin_undo_transaction", "empty")
	editor.call("commit_undo_transaction")
	_assert(int(Dictionary(editor.call("get_undo_debug_snapshot")).get("undo_depth", 0)) == start_depth, "Empty transaction creates no undo entry")

	var tile = _get_tile(editor, Vector2i(4, 4))
	var undo_limit: int = int(Dictionary(editor.call("get_undo_debug_snapshot")).get("undo_limit", 0))
	for index in range(undo_limit + 3):
		editor.call("begin_undo_transaction", "limit_%d" % index)
		editor.call("record_tile_before_change", tile)
		editor.call("commit_undo_transaction")
	var stack_snapshot: Dictionary = Dictionary(editor.call("get_undo_debug_snapshot"))
	_assert(int(stack_snapshot.get("undo_depth", 0)) == undo_limit, "Undo stack limit is applied to transactions")
	_assert(int(stack_snapshot.get("top_tile_state_count", 0)) == 1, "Stack limit keeps transaction entries intact")

	editor.queue_free()
	await _wait_frames(2)


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(12)
	return editor


func _set_brush_radius(editor, radius: int) -> void:
	var option_button := editor.get_node_or_null("UI/TopBar/Margin/HBox/BrushSizeOptionButton") as OptionButton
	if option_button == null:
		return
	option_button.select(clampi(radius, 0, maxi(0, option_button.item_count - 1)))


func _prepare_square(editor, center: Vector2i, radius: int, type_id: String, height_level: int, edge_type: String) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile = _get_tile(editor, center + Vector2i(dx, dy))
			if tile == null:
				continue
			tile.type_id = type_id
			tile.object_type_id = ""
			tile.height_level = height_level
			tile.object_height = 0
			tile.edge_type = edge_type
			tile.walkable = true
			tile.blocks_los = false
			tile.cover_value = 0
	editor.call("_rebuild_tile_sprites")
	editor.call("_clear_undo_history")


func _get_tile(editor, grid_position: Vector2i):
	var map_data = editor.get("_terrain_map_data")
	if map_data == null:
		return null
	return map_data.call("get_tile_at_grid", grid_position)


func _count_tiles_with_type(editor, center: Vector2i, radius: int, type_id: String) -> int:
	var count: int = 0
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile = _get_tile(editor, center + Vector2i(dx, dy))
			if tile != null and String(tile.type_id) == type_id:
				count += 1
	return count


func _count_tiles_with_prefix(editor, center: Vector2i, radius: int, prefix: String) -> int:
	var count: int = 0
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile = _get_tile(editor, center + Vector2i(dx, dy))
			if tile != null and String(tile.type_id).strip_edges().to_lower().begins_with(prefix):
				count += 1
	return count


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
