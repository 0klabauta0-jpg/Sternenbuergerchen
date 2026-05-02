extends SceneTree

const MAP_EDITOR_SCRIPT: GDScript = preload("res://scripts/editor/map_editor.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const WALL_TYPE_IDS: PackedStringArray = [
	"wall_straight_se",
	"wall_straight_sw",
	"wall_straight_ne",
	"wall_straight_nw",
]
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)
const EXPECTED_WALL_TEXTURES: Dictionary = {
	"wall_straight_se": "res://Assets/kenney_space-kit/Isometric/corridor_wall_NE.png",
	"wall_straight_sw": "res://Assets/kenney_space-kit/Isometric/corridor_wall_SE.png",
	"wall_straight_ne": "res://Assets/kenney_space-kit/Isometric/corridor_wall_NW.png",
	"wall_straight_nw": "res://Assets/kenney_space-kit/Isometric/corridor_wall_SW.png",
}
const EXPECTED_3D_WALL_ROTATION_DEGREES: Dictionary = {
	"wall_straight_se": 90.0,
	"wall_straight_sw": 180.0,
	"wall_straight_ne": 0.0,
	"wall_straight_nw": 270.0,
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Wall Direction Mapping Verifier ===")
	_test_terrain_renderer_wall_mapping()
	_test_map_editor_wall_mapping()
	await _test_terrain_map_3d_view_wall_mapping()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_terrain_renderer_wall_mapping() -> void:
	var map_root := Node2D.new()
	root.add_child(map_root)
	var renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()
	var map_data = _make_wall_map_data()
	var render_result: Dictionary = Dictionary(renderer.call("render_map", map_data, map_root))
	var walls: Dictionary = Dictionary(render_result.get("walls", {}))
	for type_id in WALL_TYPE_IDS:
		var grid_position: Vector2i = _grid_for_type_id(type_id)
		var sprites: Array = Array(walls.get(grid_position, []))
		var texture_path: String = _get_first_sprite_texture_path(sprites)
		_assert(texture_path == String(EXPECTED_WALL_TEXTURES[type_id]), "TerrainMapRenderer maps %s to %s" % [type_id, String(EXPECTED_WALL_TEXTURES[type_id]).get_file()])
	map_root.queue_free()


func _test_map_editor_wall_mapping() -> void:
	var editor = MAP_EDITOR_SCRIPT.new()
	var wall_container := Node2D.new()
	wall_container.name = "WallContainer"
	editor.add_child(wall_container)
	editor.set("_terrain_renderer", TERRAIN_MAP_RENDERER_SCRIPT.new())
	editor.set("_terrain_map_data", _make_wall_map_data())
	for tile_data in editor.get("_terrain_map_data").call("get_tiles"):
		editor.call("_create_wall_overlays_for_tile", tile_data)
	for type_id in WALL_TYPE_IDS:
		var grid_position: Vector2i = _grid_for_type_id(type_id)
		var sprite: Sprite2D = _find_editor_wall_sprite_at(editor, grid_position)
		var texture_path: String = sprite.texture.resource_path if sprite != null and sprite.texture != null else ""
		_assert(texture_path == String(EXPECTED_WALL_TEXTURES[type_id]), "MapEditor maps %s to %s" % [type_id, String(EXPECTED_WALL_TEXTURES[type_id]).get_file()])
	editor.queue_free()


func _test_terrain_map_3d_view_wall_mapping() -> void:
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", _make_wall_map_data())
	await _wait_frames(4)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("asset_model_count", 0)) == WALL_TYPE_IDS.size(), "TerrainMap3DView renders walls as calibrated Kenney GLB models")
	_assert(int(snapshot.get("asset_texture_count", 0)) == 0 and int(snapshot.get("placeholder_object_count", 0)) == 0, "TerrainMap3DView does not use Sprite3D/block fallback for calibrated wall models")
	for type_id in WALL_TYPE_IDS:
		var grid_position: Vector2i = _grid_for_type_id(type_id)
		var wall_node := _find_3d_wall_model(primary_view, type_id, grid_position)
		_assert(wall_node != null and _node_has_mesh(wall_node), "TerrainMap3DView loads %s as a 3D wall model" % type_id)
		var expected_rotation: float = float(EXPECTED_3D_WALL_ROTATION_DEGREES[type_id])
		_assert(wall_node != null and absf(wrapf(wall_node.rotation_degrees.y - expected_rotation, -180.0, 180.0)) < 0.1, "TerrainMap3DView maps %s to %.0f degree 3D rotation" % [type_id, expected_rotation])
	primary_view.queue_free()
	await _wait_frames(2)


func _make_wall_map_data():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "wall_direction_mapping", Vector2i(4, 1), Vector2.ZERO)
	var index: int = 0
	for type_id in WALL_TYPE_IDS:
		var tile_data = map_data.call("get_tile_at_grid", Vector2i(index, 0))
		tile_data.type_id = String(type_id)
		tile_data.walkable = false
		tile_data.blocks_los = true
		tile_data.object_height = 2
		index += 1
	return map_data


func _grid_for_type_id(type_id: String) -> Vector2i:
	var index: int = WALL_TYPE_IDS.find(type_id)
	return Vector2i(index, 0)


func _get_first_sprite_texture_path(sprites: Array) -> String:
	if sprites.is_empty():
		return ""
	var sprite := sprites[0] as Sprite2D
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path


func _find_editor_wall_sprite_at(editor, grid_position: Vector2i) -> Sprite2D:
	var wall_container := editor.get_node_or_null("WallContainer") as Node2D
	if wall_container == null:
		return null
	var map_data = editor.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return null
	var expected_position: Vector2 = tile_data.world_position - KENNEY_DIAMOND_CENTER
	for child in wall_container.get_children():
		var sprite := child as Sprite2D
		if sprite != null and sprite.position == expected_position:
			return sprite
	return null


func _find_3d_wall_model(primary_view: Node, type_id: String, grid_position: Vector2i) -> Node3D:
	var map_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	if map_root == null:
		return null
	return map_root.get_node_or_null("Asset_%s_%d_%d" % [type_id, grid_position.x, grid_position.y]) as Node3D


func _node_has_mesh(node: Node) -> bool:
	if node == null:
		return false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
