extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_295 Map Editor Paint Toolbar Tools Polish ===")
	await _test_toolbar_exclusivity_and_eraser_safety()
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_toolbar_exclusivity_and_eraser_safety() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	_assert(editor != null, "Map editor instantiates")
	var expected_tools: PackedStringArray = PackedStringArray(["select", "terrain_brush", "eraser", "height", "marker", "patrol"])
	for tool_id in expected_tools:
		_assert(bool(editor.call("set_authoring_tool", tool_id)), "Editor can activate tool: %s" % tool_id)
		await _wait_frames(1)
		var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
		var toolbar: Dictionary = Dictionary(snapshot.get("toolbar", {}))
		_assert(String(snapshot.get("active_tool", "")) == tool_id, "Snapshot reports active tool: %s" % tool_id)
		_assert(bool(toolbar.get("exclusive", false)) and int(toolbar.get("active_count", 99)) <= 1, "Toolbar keeps tool exclusivity: %s" % tool_id)

	var map_data = editor.get("_terrain_map_data")
	var target_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2)) if map_data != null else null
	_assert(target_tile != null, "Eraser test tile exists")
	if target_tile != null:
		target_tile.type_id = "nature_ground_rock_dirt"
		target_tile.object_type_id = "nature_rock_cover"
		target_tile.height_level = 2
		target_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
		target_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
		target_tile.walkable = false
		target_tile.blocks_los = true
		target_tile.cover_value = 55
		target_tile.object_height = 2
		_assert(bool(editor.call("set_authoring_tool", "eraser")), "Eraser can be activated for object clear")
		editor.call("_apply_eraser_at_world_position", Vector2(target_tile.world_position))
		_assert(String(target_tile.object_type_id) == "", "Eraser clears object_type_id")
		_assert(String(target_tile.type_id) == "nature_ground_rock_dirt", "Eraser preserves terrain type_id under object-layer props")
		_assert(int(target_tile.height_level) == 2, "Eraser preserves height")
		_assert(String(target_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, "Eraser preserves edge type")
		_assert(String(target_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK, "Eraser preserves surface")
		_assert(bool(target_tile.walkable) and not bool(target_tile.blocks_los) and int(target_tile.cover_value) == 0 and int(target_tile.object_height) == 0, "Eraser resets only object gameplay fields")

		target_tile.object_type_id = "nature_bush_cover"
		target_tile.walkable = true
		target_tile.blocks_los = false
		target_tile.cover_value = 25
		target_tile.object_height = 1
		editor.set("_selected_type_id", "ground_flat")
		editor.call("_apply_brush_at_world_position", Vector2(target_tile.world_position))
		_assert(String(target_tile.object_type_id) == "nature_bush_cover", "Ground brush does not delete object layer")
	editor.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	var path: String = "res://docs/manual_checks/map_editor_toolbar_tools_checklist.md"
	_assert(FileAccess.file_exists(path), "Toolbar manual checklist exists")
	var text: String = _read_text(path)
	for required_text in ["Select", "Brush", "Eraser", "Height", "Undo"]:
		_assert(text.contains(required_text), "Toolbar checklist covers %s" % required_text)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


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
