extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_primary_view_adapter.gd")
const MAP_EDITOR_HEIGHT_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_height_tool.gd")
const MAP_EDITOR_PATROL_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_patrol_tool.gd")
const MAP_EDITOR_MARKER_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_marker_tool.gd")

var _passed: int = 0
var _failed: int = 0


class FakePrimaryView:
	extends Node

	var render_count: int = 0
	var selected_grids: Array = []

	func render_map(_terrain_map_data) -> void:
		render_count += 1

	func set_selected_grid_positions(grids: Array) -> void:
		selected_grids = grids.duplicate()

	func screen_to_world_position(screen_position: Vector2) -> Vector2:
		return screen_position + Vector2(10.0, 20.0)


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_163 Map Editor Module Split Verifier ===")
	_test_primary_view_adapter_owns_2_5d_bridge()
	_test_height_tool_builds_existing_patch_contract()
	_test_patrol_tool_preserves_patrol_path_contract()
	_test_marker_tool_preserves_marker_placement_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_primary_view_adapter_owns_2_5d_bridge() -> void:
	var editor := Node2D.new()
	root.add_child(editor)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	editor.add_child(camera)
	var terrain := Node2D.new()
	terrain.name = "Terrain"
	terrain.visible = true
	editor.add_child(terrain)
	var primary := FakePrimaryView.new()
	primary.name = "Primary3DView"
	editor.add_child(primary)

	var ensured = MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("ensure_primary_view", editor, null, PackedStringArray(["Terrain"]), null)
	_assert(ensured == primary, "Primary view adapter reuses an existing Primary3DView")
	_assert(not terrain.visible and not camera.enabled, "Primary view adapter hides legacy 2D map surfaces")
	MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("refresh_map_view", primary, null, [], Vector2i(2, 3))
	_assert(primary.render_count == 1, "Primary view adapter forwards map render refresh")
	_assert(primary.selected_grids.size() == 1 and Vector2i(primary.selected_grids[0]) == Vector2i(2, 3), "Primary view adapter forwards selection fallback")
	var world_position: Vector2 = MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("screen_to_editor_world_position", primary, Vector2(1.0, 2.0), Vector2.ZERO)
	_assert(world_position == Vector2(11.0, 22.0), "Primary view adapter owns 2.5D picking fallback")
	editor.free()


func _test_height_tool_builds_existing_patch_contract() -> void:
	var raise_patch: Dictionary = Dictionary(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("build_height_patch", 0, "raise", "slope", "none"))
	var lower_patch: Dictionary = Dictionary(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("build_height_patch", 1, "lower", "cliff", "none"))
	var set_patch: Dictionary = Dictionary(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("build_height_patch", 0, "set_2", "cliff", "none"))
	_assert(int(raise_patch.get("height_level", -1)) == 1 and String(raise_patch.get("edge_type", "")) == "slope", "Height tool builds raise patch with selected edge")
	_assert(int(lower_patch.get("height_level", -1)) == 0 and String(lower_patch.get("edge_type", "")) == "none", "Height tool clears edge when lowered to ground")
	_assert(int(set_patch.get("height_level", -1)) == 2 and String(set_patch.get("edge_type", "")) == "cliff", "Height tool builds set-height patch")


func _test_patrol_tool_preserves_patrol_path_contract() -> void:
	var map_data = _make_map_data()
	_assert(bool(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("add_waypoint", map_data, "enemy_delta", Vector2(10.0, 20.0))), "Patrol tool adds waypoint")
	_assert(bool(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("move_waypoint", map_data, "enemy_delta", 0, Vector2(30.0, 40.0))), "Patrol tool moves waypoint")
	var index: int = int(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("find_waypoint_index_at", map_data, "enemy_delta", Vector2(31.0, 41.0), 8.0))
	_assert(index == 0, "Patrol tool finds nearest waypoint")
	_assert(bool(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("remove_waypoint", map_data, "enemy_delta", 0)), "Patrol tool removes waypoint")
	_assert(Array(map_data.call("get_patrol_path", "enemy_delta")).is_empty(), "Patrol tool keeps TerrainMapData patrol path contract")


func _test_marker_tool_preserves_marker_placement_contract() -> void:
	var map_data = _make_map_data()
	var tile_a = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var tile_b = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	var tile_c = map_data.call("get_tile_at_grid", Vector2i(0, 1))
	map_data.call("set_marker", "spawn_alpha", "spawn_alpha", Vector2(tile_a.world_position))
	map_data.call("set_marker", "spawn_bravo", "spawn_bravo", Vector2(tile_b.world_position))
	var found_marker_id: String = String(MAP_EDITOR_MARKER_TOOL_SCRIPT.call("find_marker_id_at_world_position", map_data, Vector2(tile_a.world_position), 8.0))
	_assert(found_marker_id == "spawn_alpha", "Marker tool finds marker by world position")
	_assert(not bool(MAP_EDITOR_MARKER_TOOL_SCRIPT.call("can_place_marker_at_world_position", map_data, "objective_point", Vector2(tile_a.world_position))), "Marker tool rejects occupied marker tile")
	_assert(bool(MAP_EDITOR_MARKER_TOOL_SCRIPT.call("can_place_marker_at_world_position", map_data, "objective_point", Vector2(tile_c.world_position))), "Marker tool accepts free marker tile")
	var free_position = MAP_EDITOR_MARKER_TOOL_SCRIPT.call("find_first_available_marker_world_position", map_data, Vector2(tile_a.world_position), "objective_point")
	_assert(typeof(free_position) == TYPE_VECTOR2 and Vector2(free_position) == Vector2(tile_c.world_position), "Marker tool finds first free marker tile")


func _make_map_data():
	return TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_163_module_split", Vector2i(2, 2), Vector2.ZERO, 64.0, 32.0, 3)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
