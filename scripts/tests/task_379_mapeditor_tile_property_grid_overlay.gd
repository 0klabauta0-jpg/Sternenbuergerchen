extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TILE_PROPERTY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_tile_property_overlay.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_379 MapEditor Tile Property Grid Overlay ===")
	await _test_overlay_toggle_snapshot_and_colors()
	await _test_overlay_dirty_refresh_and_disabled_no_draw_cost()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_379: ALL PASSED")
		quit(0)


func _test_overlay_toggle_snapshot_and_colors() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var disabled_snapshot: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	_assert(not bool(disabled_snapshot.get("enabled", true)), "Tile property overlay starts disabled")
	_assert(int(disabled_snapshot.get("drawn_cell_count", -1)) == 0, "Disabled overlay draws no cells")

	_apply_property_fixture(editor)
	_assert(bool(editor.call("set_tile_property_overlay_enabled", true)), "Tile property overlay can be enabled")
	await _wait_frames(2)
	var enabled_snapshot: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	var color_roles: Dictionary = Dictionary(enabled_snapshot.get("color_roles", {}))
	_assert(bool(enabled_snapshot.get("enabled", false)) and bool(enabled_snapshot.get("active", false)), "Enabled overlay reports active debug snapshot")
	_assert(int(enabled_snapshot.get("cell_count", 0)) > 0 and int(enabled_snapshot.get("drawn_cell_count", 0)) > 0, "Enabled overlay builds visible cells")
	_assert(int(color_roles.get("blocked", 0)) >= 1, "Overlay snapshot counts blocked tiles")
	_assert(int(color_roles.get("los_block", 0)) >= 1, "Overlay snapshot counts LOS-blocking tiles")
	_assert(int(color_roles.get("cover", 0)) >= 1, "Overlay snapshot counts cover tiles")
	_assert(int(color_roles.get("height", 0)) >= 1, "Overlay snapshot counts height tiles")
	_assert(bool(enabled_snapshot.get("visual_only", false)) and not bool(enabled_snapshot.get("ui_sets_gameplay_truth", true)), "Overlay contract is visual-only")

	var overlay: Node = editor.get_node_or_null("TilePropertyOverlay")
	_assert(overlay != null and overlay.get_child_count() > 0, "2D overlay node contains drawn property cells")

	var map_data = editor.get("_terrain_map_data")
	var blocked_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1)) if map_data != null else null
	var los_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1)) if map_data != null else null
	var cover_tile = map_data.call("get_tile_at_grid", Vector2i(3, 1)) if map_data != null else null
	var height_tile = map_data.call("get_tile_at_grid", Vector2i(4, 1)) if map_data != null else null
	_assert(String(TILE_PROPERTY_OVERLAY_SCRIPT.call("get_tile_color_role", blocked_tile)) == "blocked", "Color resolver maps non-walkable tile to blocked")
	_assert(String(TILE_PROPERTY_OVERLAY_SCRIPT.call("get_tile_color_role", los_tile)) == "los_block", "Color resolver maps LOS-blocking tile to los_block")
	_assert(String(TILE_PROPERTY_OVERLAY_SCRIPT.call("get_tile_color_role", cover_tile)) == "cover", "Color resolver maps cover tile to cover")
	_assert(String(TILE_PROPERTY_OVERLAY_SCRIPT.call("get_tile_color_role", height_tile)) == "height", "Color resolver maps raised tile to height")
	_assert(String(TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_label", cover_tile)).contains("C60"), "Overlay label exposes cover value compactly")
	_assert(String(TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_label", height_tile)).contains("H2"), "Overlay label exposes height value compactly")

	editor.queue_free()
	await _wait_frames(2)


func _test_overlay_dirty_refresh_and_disabled_no_draw_cost() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	_apply_property_fixture(editor)
	editor.call("set_tile_property_overlay_enabled", true)
	await _wait_frames(2)
	var before_snapshot: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	var before_dirty_refresh_count: int = int(before_snapshot.get("dirty_refresh_count", 0))

	var map_data = editor.get("_terrain_map_data")
	var changed_tile = map_data.call("get_tile_at_grid", Vector2i(5, 1)) if map_data != null else null
	_assert(changed_tile != null, "Dirty refresh fixture tile exists")
	if changed_tile != null:
		changed_tile.cover_value = 80
		editor.call("_refresh_tile_visual", changed_tile, false)
	await _wait_frames(2)
	var after_snapshot: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	_assert(int(after_snapshot.get("dirty_refresh_count", 0)) == before_dirty_refresh_count + 1, "Overlay refreshes changed grid incrementally")
	_assert(int(after_snapshot.get("last_dirty_grid_count", 0)) == 1, "Incremental refresh tracks one changed grid")
	var changed_cell: Node = editor.get_node_or_null("TilePropertyOverlay/TileProperty_5_1")
	_assert(changed_cell != null and String(changed_cell.get_meta("color_role", "")) == "cover", "Changed grid redraws with updated cover role")

	editor.call("set_tile_property_overlay_enabled", false)
	await _wait_frames(2)
	var disabled_snapshot: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	var disabled_dirty_refresh_count: int = int(disabled_snapshot.get("dirty_refresh_count", 0))
	if changed_tile != null:
		changed_tile.blocks_los = true
		editor.call("_refresh_tile_visual", changed_tile, false)
	await _wait_frames(2)
	var after_disabled_change: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	_assert(not bool(after_disabled_change.get("enabled", true)), "Disabled overlay remains inactive after tile changes")
	_assert(int(after_disabled_change.get("drawn_cell_count", -1)) == 0, "Disabled overlay keeps draw cells cleared")
	_assert(int(after_disabled_change.get("dirty_refresh_count", 0)) == disabled_dirty_refresh_count, "Disabled overlay avoids incremental redraw work")

	editor.queue_free()
	await _wait_frames(2)


func _apply_property_fixture(editor: Node) -> void:
	var map_data = editor.get("_terrain_map_data")
	if map_data == null:
		return
	var blocked_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	if blocked_tile != null:
		blocked_tile.walkable = false
		blocked_tile.blocks_los = false
		blocked_tile.cover_value = 0
		blocked_tile.height_level = 0
	var los_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	if los_tile != null:
		los_tile.walkable = true
		los_tile.blocks_los = true
		los_tile.cover_value = 0
		los_tile.height_level = 0
	var cover_tile = map_data.call("get_tile_at_grid", Vector2i(3, 1))
	if cover_tile != null:
		cover_tile.walkable = true
		cover_tile.blocks_los = false
		cover_tile.cover_value = 60
		cover_tile.height_level = 0
	var height_tile = map_data.call("get_tile_at_grid", Vector2i(4, 1))
	if height_tile != null:
		height_tile.walkable = true
		height_tile.blocks_los = false
		height_tile.cover_value = 0
		height_tile.height_level = 2


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
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
