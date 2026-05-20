extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_492 Map Editor Network Drag Snap Tools ===")
	_test_docs()
	await _test_runtime_network_drag_tools()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_492 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Road, Rail, Pipe, Wall und Cliff"), "Task documents the network tool families")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Network Drag Tools"), "Workflow contract documents Network Drag Tools")
	_assert(_read_text(STATUS_PATH).contains("TASK_492 - Map Editor Network Drag Snap Tools"), "Implementation status tracks TASK_492")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_492 - Map Editor Network Drag Snap Tools"), "Roadmap lists TASK_492")


func _test_runtime_network_drag_tools() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	var tool_ids: PackedStringArray = PackedStringArray(builder.get("tool_ids", PackedStringArray()))
	for required_tool in ["pipe_line", "wall_line", "cliff_line", "factory", "space_floor"]:
		_assert(tool_ids.has(required_tool), "Runtime builder exposes %s" % required_tool)
	var network: Dictionary = Dictionary(builder.get("network", {}))
	var definitions: Dictionary = Dictionary(network.get("definitions", {}))
	for kind in ["road", "rail", "pipe", "wall", "cliff"]:
		_assert(bool(Dictionary(definitions.get(kind, {})).get("available", false)), "Network definition is available for %s" % kind)

	_assert(bool(editor.call("activate_runtime_builder_tool", "road_line")), "Road line tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("active_tool", "")) == "network_drag", "Road line switches active tool to network drag")
	_assert(String(Dictionary(snapshot.get("network_drag_tool", {})).get("kind", "")) == "road", "Network drag kind is road")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "road", Vector2i(1, 1), Vector2i(4, 1))), "Road line path applies")
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "Editor exposes terrain map data for verification")
	if map_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return
	_assert(_tile_type_id(map_data, Vector2i(1, 1)) == "spacekit_terrain_road_end", "Road line start becomes an end piece")
	_assert(_tile_type_id(map_data, Vector2i(2, 1)) == "spacekit_terrain_road_straight", "Road line middle becomes a straight piece")
	_assert(_tile_type_id(map_data, Vector2i(4, 1)) == "spacekit_terrain_road_end", "Road line end becomes an end piece")
	_assert(String(_tile_at(map_data, Vector2i(2, 1)).surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Road line writes road surface truth")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "road", Vector2i(2, 0), Vector2i(2, 2))), "Second road stroke applies")
	_assert(_tile_type_id(map_data, Vector2i(2, 1)) == "spacekit_terrain_road_cross", "Existing road neighbor updates to a cross piece")

	_assert(bool(editor.call("set_object_placement_scale", 1.6)), "Editor accepts corrected network placement scale")
	_assert(bool(editor.call("activate_runtime_builder_tool", "pipe_line")), "Pipe line tool activates")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "pipe", Vector2i(0, 4), Vector2i(2, 5))), "Pipe elbow path applies")
	_assert(_tile_object_type_id(map_data, Vector2i(0, 4)) == "spacekit_pipe_end", "Pipe path start becomes an end piece")
	_assert(_tile_object_type_id(map_data, Vector2i(1, 4)) == "spacekit_pipe_straight", "Pipe path middle becomes a straight piece")
	_assert(_tile_object_type_id(map_data, Vector2i(2, 4)) == "spacekit_pipe_corner", "Pipe path bend becomes a corner piece")
	_assert(is_equal_approx(float(_tile_at(map_data, Vector2i(1, 4)).object_scale), 1.6), "Pipe path stores placement scale")

	_assert(bool(editor.call("activate_runtime_builder_tool", "rail_line")), "Rail line tool activates")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "rail", Vector2i(4, 4), Vector2i(4, 6))), "Rail line path applies")
	_assert(_tile_object_type_id(map_data, Vector2i(4, 4)) == "spacekit_rail_end", "Rail path start becomes an end piece")
	_assert(_tile_object_type_id(map_data, Vector2i(4, 5)) == "spacekit_rail", "Rail path middle becomes a straight piece")

	_assert(bool(editor.call("activate_runtime_builder_tool", "wall_line")), "Wall line tool activates")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "wall", Vector2i(5, 0), Vector2i(7, 0))), "Wall line path applies")
	_assert(_tile_type_id(map_data, Vector2i(5, 0)) == "modular_wall", "Wall line places modular wall segments")

	_assert(bool(editor.call("activate_runtime_builder_tool", "cliff_line")), "Cliff line tool activates")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "cliff", Vector2i(0, 7), Vector2i(2, 7))), "Cliff line path applies")
	_assert(_tile_type_id(map_data, Vector2i(1, 7)).begins_with("cliff_"), "Cliff line places cliff segments")

	_assert(bool(editor.call("activate_runtime_builder_tool", "factory")), "Factory quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("selected_type_id", "")) == "factory_building_a", "Factory quick tool selects the factory kit")
	_assert(bool(editor.call("activate_runtime_builder_tool", "space_floor")), "Space floor quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("selected_type_id", "")) == "modular_floor", "Space floor quick tool selects modular floor")
	editor.queue_free()
	await _wait_frames(2)


func _tile_at(map_data, grid_position: Vector2i):
	return map_data.call("get_tile_at_grid", grid_position) if map_data != null else null


func _tile_type_id(map_data, grid_position: Vector2i) -> String:
	var tile_data = _tile_at(map_data, grid_position)
	return String(tile_data.type_id).strip_edges().to_lower() if tile_data != null else ""


func _tile_object_type_id(map_data, grid_position: Vector2i) -> String:
	var tile_data = _tile_at(map_data, grid_position)
	return String(tile_data.object_type_id).strip_edges().to_lower() if tile_data != null else ""


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
