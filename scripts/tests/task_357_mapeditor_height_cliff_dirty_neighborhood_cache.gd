extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_357 MapEditor Height Cliff Dirty Neighborhood Cache ===")
	await _test_radius_brush_deduplicates_flat_neighborhoods()
	await _test_height_tool_batches_cliff_and_corner_candidates()
	await _test_wall_neighborhood_refresh_uses_dirty_batch()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_357: FAILED")
		quit(1)
	else:
		print("TASK_357: ALL PASSED")
		quit(0)


func _test_radius_brush_deduplicates_flat_neighborhoods() -> void:
	var editor = await _make_editor()
	var center := Vector2i(4, 4)
	_prepare_square(editor, center, 1, "station_floor_panel", 0, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"))
	editor.set("_selected_type_id", "ground_flat")
	_set_brush_radius(editor, 1)
	var center_tile = _get_tile(editor, center)
	editor.call("_apply_brush_at_world_position", Vector2(center_tile.world_position))

	var snapshot: Dictionary = Dictionary(editor.call("get_dirty_neighborhood_debug_snapshot"))
	_assert(int(snapshot.get("seed_count", 0)) == 9, "Radius-1 brush records each changed tile once")
	_assert(int(snapshot.get("raw_neighborhood_candidate_count", 0)) == 45, "Radius-1 brush tracks raw tile-plus-neighbor candidates")
	_assert(int(snapshot.get("cliff_wall_candidate_count", 0)) == 21, "Radius-1 brush deduplicates overlapping cliff/wall neighborhoods")
	_assert(int(snapshot.get("duplicate_neighborhood_candidate_count", 0)) == 24, "Radius-1 brush reports removed duplicate neighborhood candidates")
	_assert(int(snapshot.get("object_candidate_count", 0)) == 9, "Radius-1 brush refreshes each object candidate once")

	editor.queue_free()
	await _wait_frames(2)


func _test_height_tool_batches_cliff_and_corner_candidates() -> void:
	var editor = await _make_editor()
	var center := Vector2i(4, 4)
	_prepare_square(editor, center, 2, "ground_flat", 0, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"))
	editor.set("_height_tool_mode", "set_1")
	editor.set("_height_tool_edge_type", TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"))
	_set_brush_radius(editor, 1)
	var center_tile = _get_tile(editor, center)
	editor.call("_apply_height_tool_at_world_position", Vector2(center_tile.world_position))

	var snapshot: Dictionary = Dictionary(editor.call("get_dirty_neighborhood_debug_snapshot"))
	_assert(int(snapshot.get("seed_count", 0)) >= 9, "Height brush batches changed and reconciled grids")
	_assert(int(snapshot.get("duplicate_neighborhood_candidate_count", 0)) > 0, "Height brush deduplicates overlapping cliff/corner neighborhoods")
	_assert(int(snapshot.get("cliff_refresh_count", 0)) > 0, "Height brush refreshes cliff visual candidates")
	_assert(_count_tiles_with_prefix(editor, center, 2, "cliff_") > 0, "Height brush still creates lower cliff visual tiles")
	_assert(int(_get_tile(editor, center).height_level) == 1, "Height brush keeps terrain height truth in TerrainMapData")

	editor.queue_free()
	await _wait_frames(2)


func _test_wall_neighborhood_refresh_uses_dirty_batch() -> void:
	var editor = await _make_editor()
	var wall_grid := Vector2i(5, 5)
	var wall_tile = _get_tile(editor, wall_grid)
	wall_tile.type_id = "wall_straight_se"
	wall_tile.object_type_id = ""
	wall_tile.height_level = 0
	wall_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE")
	wall_tile.blocks_los = true
	wall_tile.walkable = false
	var wall_dirty_grids: Array[Vector2i] = [wall_grid]
	editor.call("_refresh_dirty_visual_neighborhoods", wall_dirty_grids)

	var snapshot: Dictionary = Dictionary(editor.call("get_dirty_neighborhood_debug_snapshot"))
	_assert(int(snapshot.get("seed_count", 0)) == 1, "Single wall refresh records one dirty seed")
	_assert(int(snapshot.get("cliff_wall_candidate_count", 0)) == 5, "Single wall refresh checks tile plus four neighbors once")
	_assert(int(snapshot.get("object_candidate_count", 0)) == 1, "Single wall refresh keeps object candidates scoped to the changed tile")
	_assert(bool(editor.call("_is_object_type", wall_tile)), "Wall tile remains a structure/object visual candidate")

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


func _get_tile(editor, grid_position: Vector2i):
	var map_data = editor.get("_terrain_map_data")
	if map_data == null:
		return null
	return map_data.call("get_tile_at_grid", grid_position)


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
