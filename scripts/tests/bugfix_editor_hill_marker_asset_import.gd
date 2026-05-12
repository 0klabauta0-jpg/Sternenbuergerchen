extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Editor Hill Marker Asset Import ===")
	_test_marker_catalog_labels_and_tooltips()
	_test_asset_catalog_imports_and_previews()
	await _test_editor_toolbar_help_and_cliff_replacement()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_marker_catalog_labels_and_tooltips() -> void:
	_assert(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", "spawn_alpha")) == "PC Spawn", "Spawn Alpha is displayed as PC Spawn")
	_assert(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", "spawn_bravo")) == "NPC Spawn", "Spawn Bravo is displayed as NPC Spawn")
	_assert(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", "recon_note")) == "Recon Node", "Recon marker uses Recon Node label")
	_assert(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_tooltip", "danger_zone")).contains("high-risk"), "Danger Zone tooltip explains the marker")
	_assert(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_tooltip", "loot_cache")).contains("does not spawn loot"), "Loot Cache tooltip states current behavior")


func _test_asset_catalog_imports_and_previews() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Tile catalog loads")
	_assert(_catalog_group_count(catalog, "space_kit_full") >= 153, "Space Kit complete group exposes imported assets")
	_assert(_catalog_group_count(catalog, "space_station_full") >= 97, "Space Station complete group exposes imported assets")
	for type_id in ["wall_straight_se", "cliff_straight_se", "slope_se", "rock_large", "station_wall", "station_floor_panel"]:
		_assert(catalog.call("get_texture", type_id) != null, "Palette preview resolves texture: %s" % type_id)
	for type_id in ["spacekit_alien", "spacekit_corridor_wall", "station_set_wall", "station_set_computer_screen"]:
		_assert(bool(catalog.call("has_type", type_id)), "Imported tile type exists: %s" % type_id)


func _test_editor_toolbar_help_and_cliff_replacement() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	_assert(editor != null, "Map editor instantiates")
	if editor == null:
		return
	_assert(_topbar_tool_order_is_left_weighted(editor), "Select, Eraser and Patrol controls sit next to the paint controls")
	_assert(_control_tooltip_contains(editor, "UI/PropertyPanel/Margin/VBox/MapSettingsToggle", "Map Settings"), "Map Settings has an explanatory tooltip")
	_assert(_control_tooltip_contains(editor, "UI/PropertyPanel/Margin/VBox/AuthoringStatusPanel/AuthoringValidationLabel", "Warnings"), "Warnings/Errors status has an explanatory tooltip")

	var map_data = editor.get("_terrain_map_data")
	var center_grid := Vector2i(6, 6)
	var west_grid := center_grid + Vector2i(-1, 0)
	_set_flat_area(map_data, center_grid, 3)
	var center = map_data.call("get_tile_at_grid", center_grid) if map_data != null else null
	var west = map_data.call("get_tile_at_grid", west_grid) if map_data != null else null
	_assert(center != null and west != null, "Hill replacement fixture has editable tiles")
	if center != null and west != null:
		editor.call("_apply_tile_patch", center, {
			"height_level": 1,
			"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF,
		})
		var center_refresh_grids: Array[Vector2i] = [center_grid]
		editor.call("_refresh_reconciled_height_edges", center_refresh_grids, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF)
		_assert(String(west.type_id).begins_with("cliff_"), "Initial cliff hill writes an adjacent auto cliff visual")

		editor.call("_apply_tile_patch", west, {
			"height_level": 1,
			"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE,
		})
		var west_refresh_grids: Array[Vector2i] = [west_grid]
		editor.call("_refresh_reconciled_height_edges", west_refresh_grids, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE)
		_assert(int(west.height_level) == 1, "Raised neighbor keeps the new hill height")
		_assert(not String(west.type_id).begins_with("cliff_"), "Raising a former auto-cliff tile clears the stale cliff visual type")
		_assert(String(west.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, "Raised former cliff tile becomes a slope edge when it still has lower neighbors")
	editor.queue_free()
	await _wait_frames(2)


func _catalog_group_count(catalog, group_id: String) -> int:
	var count: int = 0
	for type_variant in Array(catalog.call("get_all_types")):
		var type_entry: Dictionary = Dictionary(type_variant)
		if String(type_entry.get("palette_group", "")) == group_id:
			count += 1
	return count


func _topbar_tool_order_is_left_weighted(editor) -> bool:
	var row := editor.get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if row == null:
		return false
	var brush_size := row.get_node_or_null("BrushSizeOptionButton") as Control
	var select_button := row.get_node_or_null("SelectButton") as Control
	var eraser_button := row.get_node_or_null("EraserButton") as Control
	var patrol_button := row.get_node_or_null("PatrolButton") as Control
	if brush_size == null or select_button == null or eraser_button == null or patrol_button == null:
		return false
	return (
		select_button.get_index() == brush_size.get_index() + 1
		and eraser_button.get_index() == select_button.get_index() + 1
		and patrol_button.get_index() > eraser_button.get_index()
	)


func _control_tooltip_contains(editor, node_path: String, needle: String) -> bool:
	var control := editor.get_node_or_null(node_path) as Control
	return control != null and control.tooltip_text.contains(needle)


func _set_flat_area(map_data, center_grid: Vector2i, radius: int) -> void:
	if map_data == null:
		return
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile_data = map_data.call("get_tile_at_grid", center_grid + Vector2i(dx, dy))
			if tile_data == null:
				continue
			tile_data.type_id = "ground_flat"
			tile_data.object_type_id = ""
			tile_data.height_level = 0
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
			tile_data.walkable = true
			tile_data.blocks_los = false
			tile_data.cover_value = 0
			tile_data.object_height = 0


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
