extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const MAP_EDITOR_HEIGHT_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_height_tool.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TEMP_ROUNDTRIP_PATH: String = "user://task_183_hill_authoring_roundtrip.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_183 Editor Hill Authoring Verifier ===")
	_test_height_tool_patch_contract()
	_test_catalog_placement_preserves_hill_fields()
	_test_hill_roundtrip()
	await _test_editor_surface_patch_and_refresh_contract()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_183: FAILED")
		quit(1)
	else:
		print("TASK_183: ALL PASSED")
		quit(0)


func _test_height_tool_patch_contract() -> void:
	var raise_patch: Dictionary = MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call(
		"build_height_patch",
		0,
		MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_RAISE"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE")
	)
	_assert(int(raise_patch.get("height_level", -1)) == 1, "Height tool raises H=0 to H=1")
	_assert(String(raise_patch.get("edge_type", "")) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), "Height tool applies selected slope edge above H=0")

	var raise_none_patch: Dictionary = MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call(
		"build_height_patch",
		0,
		MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_RAISE"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE")
	)
	_assert(int(raise_none_patch.get("height_level", -1)) == 1, "Height tool can raise H=0 with explicit edge none")
	_assert(String(raise_none_patch.get("edge_type", "")) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"), "Height tool preserves selected edge none above H=0")

	var set_2_patch: Dictionary = MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call(
		"build_height_patch",
		0,
		MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_SET_2"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE")
	)
	_assert(int(set_2_patch.get("height_level", -1)) == 2, "Height tool can set H=2")
	_assert(String(set_2_patch.get("edge_type", "")) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), "Height tool applies selected cliff edge at H=2")

	var lower_patch: Dictionary = MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call(
		"build_height_patch",
		1,
		MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_LOWER"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"),
		TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE")
	)
	_assert(int(lower_patch.get("height_level", -1)) == 0, "Height tool lowers H=1 to H=0")
	_assert(String(lower_patch.get("edge_type", "")) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"), "Height tool forces edge none at H=0")
	_assert(int(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("get_next_height_level", 2, MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_RAISE"))) == 2, "Height tool clamps raise at H=2")
	_assert(int(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("get_next_height_level", 0, MAP_EDITOR_HEIGHT_TOOL_SCRIPT.get("MODE_LOWER"))) == 0, "Height tool clamps lower at H=0")


func _test_catalog_placement_preserves_hill_fields() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain tile catalog loads")
	if catalog == null:
		return

	for type_id in ["wall_straight_se", "rock_large", "cliff_straight_se", "slope_se"]:
		var tile_data = _make_hill_tile(Vector2i.ZERO)
		_assert(bool(catalog.call("preserves_hill_fields_when_applied", type_id)), "%s is a hill-preserving palette type" % type_id)
		_assert(bool(catalog.call("apply_type_to_tile", tile_data, type_id)), "Catalog applies %s" % type_id)
		_assert(int(tile_data.height_level) == 2, "%s preserves height_level" % type_id)
		_assert(String(tile_data.surface_type) == TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"), "%s preserves surface_type" % type_id)
		_assert(String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), "%s preserves edge_type" % type_id)
		_assert(String(tile_data.type_id) == type_id, "%s remains the visual/catalog type_id" % type_id)

	var wall_tile = _make_hill_tile(Vector2i(1, 0))
	_assert(bool(catalog.call("apply_type_to_tile", wall_tile, "wall_straight_se")), "Catalog applies wall on hill")
	_assert(not bool(wall_tile.walkable), "Wall on hill sets walkable=false")
	_assert(bool(wall_tile.blocks_los), "Wall on hill sets blocks_los=true")
	_assert(int(wall_tile.object_height) == 2, "Wall on hill sets object_height=2")

	var object_tile = _make_hill_tile(Vector2i(2, 0))
	object_tile.type_id = "ground_flat"
	_assert(bool(catalog.call("apply_type_to_tile", object_tile, "technik_generator_se")), "Catalog applies object-layer generator on hill")
	_assert(String(object_tile.type_id) == "ground_flat", "Object-layer placement keeps terrain type_id")
	_assert(String(object_tile.object_type_id) == "technik_generator_se", "Object-layer placement stores object_type_id")
	_assert(int(object_tile.height_level) == 2, "Object-layer placement preserves height_level")
	_assert(String(object_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"), "Object-layer placement preserves surface_type")
	_assert(String(object_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), "Object-layer placement preserves edge_type")


func _test_hill_roundtrip() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_183_hill_roundtrip", Vector2i(4, 2), Vector2.ZERO)
	_assert(catalog != null and map_data != null, "Roundtrip catalog and map instantiate")
	if catalog == null or map_data == null:
		return

	var sand_slope = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	_configure_tile(sand_slope, 1, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"))

	var sand_cliff = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	_configure_tile(sand_cliff, 2, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"))

	var plateau = map_data.call("get_tile_at_grid", Vector2i(2, 0))
	_configure_tile(plateau, 2, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD"))

	var wall_hill = map_data.call("get_tile_at_grid", Vector2i(0, 1))
	_configure_tile(wall_hill, 2, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"))
	_assert(bool(catalog.call("apply_type_to_tile", wall_hill, "wall_straight_se")), "Roundtrip map applies wall on hill")

	var rock_hill = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	_configure_tile(rock_hill, 1, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD"))
	_assert(bool(catalog.call("apply_type_to_tile", rock_hill, "rock_large")), "Roundtrip map applies rock on hill")

	var save_error: Error = map_data.call("save_to_file", TEMP_ROUNDTRIP_PATH)
	_assert(save_error == OK, "Hill authoring map saves")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", TEMP_ROUNDTRIP_PATH)
	_assert(reloaded != null, "Hill authoring map reloads")
	if reloaded == null:
		return

	_assert(_tile_has_fields(reloaded.call("get_tile_at_grid", Vector2i(0, 0)), 1, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"), "", "", 0), "Sandhang survives Save/Load")
	_assert(_tile_has_fields(reloaded.call("get_tile_at_grid", Vector2i(1, 0)), 2, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"), "", "", 0), "Sand cliff survives Save/Load")
	_assert(_tile_has_fields(reloaded.call("get_tile_at_grid", Vector2i(2, 0)), 2, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_NONE"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD"), "", "", 0), "Plateau interior survives Save/Load")
	_assert(_tile_has_fields(reloaded.call("get_tile_at_grid", Vector2i(0, 1)), 2, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"), "wall_straight_se", "", 2), "Wall on hill survives Save/Load")
	_assert(_tile_has_fields(reloaded.call("get_tile_at_grid", Vector2i(1, 1)), 1, TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD"), "rock_large", "", 2), "Rock on hill survives Save/Load")


func _test_editor_surface_patch_and_refresh_contract() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return
	root.add_child(editor)
	await _wait_frames(10)

	var map_data = editor.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(2, 2)) if map_data != null else null
	_assert(tile_data != null, "Editor exposes editable TerrainMapData tile")
	if tile_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	tile_data.type_id = "wall_straight_se"
	tile_data.object_type_id = ""
	tile_data.height_level = 2
	tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD")
	tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF")
	tile_data.object_height = 2
	tile_data.walkable = false
	tile_data.blocks_los = true
	tile_data.cover_value = 35
	_assert(bool(editor.call("_apply_tile_patch", tile_data, {
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"),
	})), "Editor surface patch changes a wall-on-hill surface")
	_assert(String(tile_data.type_id) == "wall_straight_se", "Editor surface patch preserves wall type_id")
	_assert(int(tile_data.height_level) == 2, "Editor surface patch preserves height_level")
	_assert(String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), "Editor surface patch preserves edge_type")
	_assert(int(tile_data.object_height) == 2 and bool(tile_data.blocks_los) and not bool(tile_data.walkable), "Editor surface patch preserves object fields")

	var object_tile = map_data.call("get_tile_at_grid", Vector2i(3, 2))
	if object_tile != null:
		object_tile.type_id = "ground_flat"
		object_tile.object_type_id = "technik_generator_se"
		object_tile.height_level = 1
		object_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_ROAD")
		object_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE")
		object_tile.object_height = 2
		_assert(bool(editor.call("_apply_tile_patch", object_tile, {
			"surface_type": TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"),
		})), "Editor surface patch changes an object-layer tile surface")
		_assert(String(object_tile.object_type_id) == "technik_generator_se", "Editor surface patch preserves object_type_id")
		_assert(String(object_tile.type_id).is_empty(), "Editor surface patch clears stale base type_id so surface remains visible")
		_assert(int(object_tile.height_level) == 1 and String(object_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"), "Editor surface patch preserves object-layer hill fields")

	editor.call("_refresh_tile_visual", tile_data)
	await _wait_frames(4)
	var primary_view := editor.get_node_or_null("Primary3DView")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	_assert(primary_view != null and int(snapshot.get("tile_count", 0)) > 0, "Editor refresh keeps Primary3DView rendering terrain data")
	_assert(editor.find_child("SimulationRoot", true, false) == null, "Editor authoring scene does not create SimulationRoot gameplay state")

	editor.queue_free()
	await _wait_frames(2)


func _make_hill_tile(grid_position: Vector2i):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": Vector2.ZERO,
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0,
		"height_level": 2,
		"object_height": 0,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND"),
		"edge_type": TERRAIN_TILE_DATA_SCRIPT.get("EDGE_SLOPE"),
	})


func _configure_tile(tile_data, height_level: int, edge_type: String, surface_type: String) -> void:
	tile_data.height_level = height_level
	tile_data.edge_type = edge_type
	tile_data.surface_type = surface_type
	tile_data.type_id = ""
	tile_data.object_type_id = ""
	tile_data.object_height = 0
	tile_data.walkable = true
	tile_data.blocks_los = false
	tile_data.cover_value = 0


func _tile_has_fields(tile_data, height_level: int, edge_type: String, surface_type: String, type_id: String, object_type_id: String, object_height: int) -> bool:
	if tile_data == null:
		return false
	return (
		int(tile_data.height_level) == height_level
		and String(tile_data.edge_type) == edge_type
		and String(tile_data.surface_type) == surface_type
		and String(tile_data.type_id) == type_id
		and String(tile_data.object_type_id) == object_type_id
		and int(tile_data.object_height) == object_height
	)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("  FAIL: %s" % message)
