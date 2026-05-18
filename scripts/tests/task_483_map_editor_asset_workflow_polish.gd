extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_483_map_editor_asset_workflow_polish.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const ROUNDTRIP_PATH: String = "user://task_483_map_editor_asset_workflow_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_483 Map Editor Asset Workflow Polish ===")
	_test_docs()
	await _test_editor_palette_and_scale_workflow()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_483 task file exists")
	_assert(FileAccess.file_exists(WORKFLOW_CONTRACT_PATH), "Map editor asset workflow contract exists")
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(status_text.contains("TASK_483 - Map Editor Asset Workflow Polish"), "Implementation status tracks TASK_483")
	_assert(roadmap_text.contains("TASK_483 - Map Editor Asset Workflow Polish"), "Roadmap lists TASK_483")


func _test_editor_palette_and_scale_workflow() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	editor.call("_on_palette_group_button_pressed", "space_station")
	await _wait_frames(2)
	var palette: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("palette", {}))
	var icon_size: Vector2i = Vector2i(palette.get("preview_icon_size", Vector2i.ZERO))
	_assert(icon_size.x >= 40 and icon_size.y >= 40, "Palette exposes larger preview icons")
	_assert(float(palette.get("scale_max", 0.0)) >= 1.6, "Placement scale allows 1.6 authoring correction")
	_assert(_packed_string_array_is_sorted(PackedStringArray(palette.get("visible_display_names", PackedStringArray()))), "Visible palette entries are sorted by display name")
	_assert(String(palette.get("active_group", "")) == "space_station", "Space Station palette group is active")

	_assert(bool(editor.call("set_palette_type_for_authoring", "station_wall")), "Editor can select station_wall for authoring")
	_assert(bool(editor.call("set_object_placement_scale", 1.6)), "Editor accepts placement scale 1.6")
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(2, 2))), "Editor can select target tile")
	var map_data = editor.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(2, 2)) if map_data != null else null
	_assert(tile_data != null, "Target tile exists")
	if tile_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return
	editor.call("_apply_brush_at_world_position", Vector2(tile_data.world_position))
	_assert(String(tile_data.type_id) == "station_wall" or String(tile_data.object_type_id) == "station_wall", "Brush places station_wall")
	_assert(is_equal_approx(float(tile_data.object_scale), 1.6), "Brush stores placement scale on the tile")
	_assert(bool(editor.call("set_selected_object_scale", 1.25)), "Property scale command updates selected asset")
	_assert(is_equal_approx(float(tile_data.object_scale), 1.25), "Selected tile stores edited object scale")
	editor.call("_undo_last_change")
	_assert(is_equal_approx(float(tile_data.object_scale), 1.6), "Undo restores prior object scale")
	_assert(bool(editor.call("set_selected_object_scale", 1.25)), "Property scale command reapplies after undo")
	var selected_context: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("selected_tile", {}))
	_assert(is_equal_approx(float(selected_context.get("object_scale", 0.0)), 1.25), "Selected tile snapshot reports object scale")
	_assert(PackedStringArray(Dictionary(editor.call("get_authoring_action_contract_snapshot")).get("tile_patch_fields", PackedStringArray())).has("object_scale"), "Authoring contract exposes object_scale field")

	_assert(map_data.call("save_to_file", ROUNDTRIP_PATH) == OK, "Map saves object scale roundtrip")
	var loaded_map = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", ROUNDTRIP_PATH)
	var loaded_tile = loaded_map.call("get_tile_at_grid", Vector2i(2, 2)) if loaded_map != null else null
	_assert(loaded_tile != null and is_equal_approx(float(loaded_tile.object_scale), 1.25), "Object scale persists through load")

	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", loaded_map)
	await _wait_frames(10)
	var visual_root := _find_node_recursive(view, "Asset_station_wall_2_2") as Node3D
	var expected_scale: float = float(view.call("_get_asset_model_scale", "station_wall")) * 1.25
	_assert(visual_root != null, "3D view renders station wall asset node")
	if visual_root != null:
		_assert(absf(visual_root.scale.x - expected_scale) < 0.01, "3D view multiplies mapping scale by object_scale")
	view.queue_free()
	editor.queue_free()
	await _wait_frames(2)


func _packed_string_array_is_sorted(values: PackedStringArray) -> bool:
	var previous: String = ""
	for index in range(values.size()):
		var current: String = String(values[index]).strip_edges().to_lower()
		if index > 0 and current < previous:
			return false
		previous = current
	return true


func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_recursive(child, target_name)
		if found != null:
			return found
	return null


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
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
