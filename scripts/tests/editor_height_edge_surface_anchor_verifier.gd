extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Editor Height Edge Surface Anchor Verifier ===")
	await _test_height_tool_generates_cliff_edges()
	await _test_stamp_brush_generates_lower_neighbor_cliff_ring()
	await _test_height_edge_reconcile_cleans_plateau_and_exposed_edges()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_height_tool_generates_cliff_edges() -> void:
	var editor = await _make_editor()
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return
	var map_data = editor.get("_terrain_map_data")
	var center = map_data.call("get_tile_at_grid", Vector2i(4, 4)) if map_data != null else null
	_assert(center != null, "Height edge fixture has center tile")
	if center == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	_set_flat_cross(map_data, Vector2i(4, 4))
	editor.set("_height_tool_mode", "set_1")
	editor.set("_height_tool_edge_type", TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF)
	editor.set("_last_painted_grid", Vector2i(-99, -99))
	editor.call("_apply_height_tool_at_world_position", Vector2(center.world_position))
	await _wait_frames(12)

	_assert(int(center.height_level) == 1, "Height tool raises selected tile to H1")
	_assert(String(center.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, "Raised isolated tile receives selected cliff edge")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(3, 4), "cliff_straight_se"), "Height tool writes west lower-neighbor cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(5, 4), "cliff_straight_nw"), "Height tool writes east lower-neighbor cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(4, 3), "cliff_straight_ne"), "Height tool writes north lower-neighbor cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(4, 5), "cliff_straight_sw"), "Height tool writes south lower-neighbor cliff tile")
	var primary_view := editor.get_node_or_null("Primary3DView") as Node
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "Raised isolated tile renders explicit lower-neighbor cliff assets")
	_assert(_surface_visuals_are_top_anchored(Array(snapshot.get("surface_visual_entries", []))), "Editor 3D view keeps ground visuals top-anchored to the surface")
	editor.queue_free()
	await _wait_frames(2)


func _test_stamp_brush_generates_lower_neighbor_cliff_ring() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var map_data = editor.get("_terrain_map_data")
	var center_grid := Vector2i(4, 4)
	var center = map_data.call("get_tile_at_grid", center_grid) if map_data != null else null
	_assert(center != null, "Stamp brush cliff fixture has center tile")
	if center == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	_set_flat_area(map_data, center_grid, 3)
	var brush_size_option := editor.call("_get_brush_size_option_button") as OptionButton
	if brush_size_option != null:
		brush_size_option.select(1)
	editor.set("_height_tool_mode", "set_1")
	editor.set("_height_tool_edge_type", TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF)
	editor.set("_last_painted_grid", Vector2i(-99, -99))
	editor.call("_apply_height_tool_at_world_position", Vector2(center.world_position))
	await _wait_frames(8)

	_assert(int(center.height_level) == 1 and String(center.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, "Stamp brush clears the raised plateau interior edge")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(2, 4), "cliff_straight_se"), "Stamp brush generates west straight cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(6, 4), "cliff_straight_nw"), "Stamp brush generates east straight cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(4, 2), "cliff_straight_ne"), "Stamp brush generates north straight cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(4, 6), "cliff_straight_sw"), "Stamp brush generates south straight cliff tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(2, 2), "cliff_corner_sw"), "Stamp brush generates northwest lower cliff corner tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(6, 2), "cliff_corner_se"), "Stamp brush generates northeast lower cliff corner tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(2, 6), "cliff_corner_nw"), "Stamp brush generates southwest lower cliff corner tile")
	_assert(_tile_is_auto_cliff_visual(map_data, Vector2i(6, 6), "cliff_corner_ne"), "Stamp brush generates southeast lower cliff corner tile")
	editor.queue_free()
	await _wait_frames(2)


func _test_height_edge_reconcile_cleans_plateau_and_exposed_edges() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var map_data = editor.get("_terrain_map_data")
	var center_grid := Vector2i(6, 6)
	var center = map_data.call("get_tile_at_grid", center_grid) if map_data != null else null
	_assert(center != null, "Plateau reconcile fixture has center tile")
	if center == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	_set_height_cross(map_data, center_grid, 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF)
	editor.call("_reconcile_height_edges_around", center_grid, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE)
	_assert(String(center.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, "Auto edge reconcile clears plateau interior edge")

	var lower_neighbor = map_data.call("get_tile_at_grid", center_grid + Vector2i(1, 0))
	lower_neighbor.height_level = 0
	lower_neighbor.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	center.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	editor.call("_reconcile_height_edges_around", lower_neighbor.grid_position, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE)
	_assert(String(center.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, "Auto edge reconcile generates preferred slope when a lower neighbor appears")
	_assert(String(lower_neighbor.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, "Lower H0 tile remains edge none")

	center.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	editor.call("_reconcile_height_edges_around", lower_neighbor.grid_position, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE)
	_assert(String(center.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, "Auto edge reconcile preserves explicit edge none authoring mode")
	editor.queue_free()
	await _wait_frames(2)


func _set_flat_cross(map_data, center_grid: Vector2i) -> void:
	if map_data == null:
		return
	for grid in [center_grid, center_grid + Vector2i(1, 0), center_grid + Vector2i(-1, 0), center_grid + Vector2i(0, 1), center_grid + Vector2i(0, -1)]:
		var tile_data = map_data.call("get_tile_at_grid", grid)
		if tile_data == null:
			continue
		tile_data.height_level = 0
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		tile_data.type_id = "ground_flat"
		tile_data.walkable = true
		tile_data.blocks_los = false


func _set_height_cross(map_data, center_grid: Vector2i, height_level: int, edge_type: String) -> void:
	if map_data == null:
		return
	for grid in [center_grid, center_grid + Vector2i(1, 0), center_grid + Vector2i(-1, 0), center_grid + Vector2i(0, 1), center_grid + Vector2i(0, -1)]:
		var tile_data = map_data.call("get_tile_at_grid", grid)
		if tile_data == null:
			continue
		tile_data.height_level = height_level
		tile_data.edge_type = edge_type


func _set_flat_area(map_data, center_grid: Vector2i, radius: int) -> void:
	if map_data == null:
		return
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile_data = map_data.call("get_tile_at_grid", center_grid + Vector2i(dx, dy))
			if tile_data == null:
				continue
			tile_data.height_level = 0
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
			tile_data.type_id = "ground_flat"
			tile_data.walkable = true
			tile_data.blocks_los = false
			tile_data.cover_value = 0
			tile_data.object_height = 0
			tile_data.object_type_id = ""


func _tile_is_auto_cliff_visual(map_data, grid: Vector2i, expected_type_id: String) -> bool:
	var tile_data = map_data.call("get_tile_at_grid", grid) if map_data != null else null
	return (
		tile_data != null
		and String(tile_data.type_id) == expected_type_id
		and int(tile_data.height_level) == 0
		and String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		and not bool(tile_data.walkable)
		and bool(tile_data.blocks_los)
	)


func _surface_visuals_are_top_anchored(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var surface_y: float = float(entry.get("surface_y", 0.0))
		var top_y: float = float(entry.get("visual_top_y", surface_y))
		if absf(top_y - surface_y) > 0.002:
			return false
	return true


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(8)
	return editor


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
