extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_135 2.5D Height Data Contract Verifier ===")
	_test_tile_data_derives_legacy_2_5d_fields()
	_test_map_roundtrip_persists_2_5d_fields()
	_test_legacy_map_loads_without_2_5d_fields()
	_test_catalog_exposes_2_5d_defaults()
	_test_registry_exposes_height_profile_api()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_tile_data_derives_legacy_2_5d_fields() -> void:
	var tile_data = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "legacy_wall",
		"type_id": "wall_straight_se",
		"grid_position": Vector2i(1, 2),
		"world_position": Vector2(32.0, 48.0),
		"walkable": false,
		"blocks_los": true,
		"cover_value": 50,
		"height_level": 1,
		"object_height": 2,
	})
	var serialized: Dictionary = Dictionary(tile_data.call("to_dict"))
	_assert(float(tile_data.floor_height) == 1.0, "Legacy height_level derives floor_height")
	_assert(float(tile_data.cover_height) == 2.0, "Legacy cover/object data derives cover_height")
	_assert(float(tile_data.blocks_los_height) == 2.0, "Legacy LOS blocker data derives blocks_los_height")
	_assert(bool(tile_data.is_elevated_surface), "Legacy raised tile derives is_elevated_surface")
	_assert(serialized.has("floor_height") and serialized.has("blocks_los_height"), "Tile serialization includes new 2.5D fields")


func _test_map_roundtrip_persists_2_5d_fields() -> void:
	var temp_path: String = "user://task_135_height_roundtrip.json"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_135_roundtrip", Vector2i(2, 1), Vector2.ZERO)
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	tile_data.height_level = 2
	tile_data.object_height = 1
	tile_data.floor_height = 2.5
	tile_data.unit_eye_height_bonus = 0.25
	tile_data.cover_height = 1.25
	tile_data.blocks_los_height = 3.5
	tile_data.is_elevated_surface = true
	var save_error: Error = map_data.call("save_to_file", temp_path)
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var reloaded_tile = reloaded.call("get_tile_at_grid", Vector2i(1, 0)) if reloaded != null else null
	_assert(save_error == OK, "2.5D map data saves without error")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.floor_height), 2.5), "Roundtrip restores floor_height")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.unit_eye_height_bonus), 0.25), "Roundtrip restores unit_eye_height_bonus")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.cover_height), 1.25), "Roundtrip restores cover_height")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.blocks_los_height), 3.5), "Roundtrip restores blocks_los_height")
	_assert(reloaded_tile != null and bool(reloaded_tile.is_elevated_surface), "Roundtrip restores is_elevated_surface")


func _test_legacy_map_loads_without_2_5d_fields() -> void:
	var temp_path: String = "user://task_135_legacy_map.json"
	var legacy_root: Dictionary = {
		"map_name": "task_135_legacy",
		"grid_size": {"x": 1, "y": 1},
		"tile_size": {"half_width": 64, "half_height": 32},
		"grid_origin": {"x": 0, "y": 0},
		"markers": {},
		"tiles": [
			{
				"grid_position": {"x": 0, "y": 0},
				"type_id": "wall_straight_se",
				"walkable": false,
				"blocks_los": true,
				"cover_value": 40,
				"height_level": 1,
				"object_height": 2,
				"surface_type": "rock",
				"edge_type": "cliff",
			},
		],
	}
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_root, "\t") + "\n")
	file.close()
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var tile_data = reloaded.call("get_tile_at_grid", Vector2i.ZERO) if reloaded != null else null
	_assert(tile_data != null, "Legacy map without explicit 2.5D fields still loads")
	_assert(tile_data != null and is_equal_approx(float(tile_data.floor_height), 1.0), "Legacy map derives floor_height from height_level")
	_assert(tile_data != null and float(tile_data.blocks_los_height) >= 2.0, "Legacy map derives LOS blocker height")


func _test_catalog_exposes_2_5d_defaults() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var ground: Dictionary = Dictionary(catalog.call("get_type", "ground_flat"))
	var cliff: Dictionary = Dictionary(catalog.call("get_type", "cliff_straight_se"))
	var barrel: Dictionary = Dictionary(catalog.call("get_type", "deko_barrel_se"))
	var building: Dictionary = Dictionary(catalog.call("get_type", "gebaeude_structure_closed_se"))
	_assert(ground.has("floor_height") and float(ground.get("floor_height", -1.0)) == 0.0, "Catalog ground exposes flat floor_height")
	_assert(cliff.has("is_elevated_surface") and bool(cliff.get("is_elevated_surface", false)), "Catalog cliff defaults to elevated surface")
	_assert(float(cliff.get("blocks_los_height", 0.0)) >= 1.0, "Catalog cliff exposes LOS blocker height")
	_assert(float(barrel.get("cover_height", 0.0)) > 0.0, "Catalog cover prop exposes cover_height")
	_assert(float(building.get("blocks_los_height", 0.0)) >= 3.0, "Catalog building exposes high LOS blocker height")
	var elevated_tile = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "elevated_object_test",
		"type_id": "ground_flat",
		"grid_position": Vector2i.ZERO,
		"world_position": Vector2.ZERO,
		"floor_height": 1.0,
		"is_elevated_surface": true,
	})
	_assert(catalog.call("apply_type_to_tile", elevated_tile, "gebaeude_structure_closed_se"), "Catalog applies object-layer type on elevated tile")
	_assert(float(elevated_tile.blocks_los_height) > 3.0, "Object-layer LOS height offsets by tile floor_height")


func _test_registry_exposes_height_profile_api() -> void:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	var grid_position := Vector2i(2, 3)
	var tile_data = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "height_profile_tile",
		"type_id": "custom_height_tile",
		"grid_position": grid_position,
		"world_position": registry.grid_to_world(grid_position),
		"walkable": true,
		"floor_height": 1.75,
		"unit_eye_height_bonus": 0.2,
		"cover_height": 0.9,
		"blocks_los_height": 2.1,
		"is_elevated_surface": true,
	})
	registry.register_tile(tile_data)
	var profile: Dictionary = Dictionary(registry.call("get_height_profile_at_grid", grid_position))
	_assert(is_equal_approx(float(registry.call("get_floor_height_at", grid_position)), 1.75), "TerrainRegistry exposes floor_height by grid")
	_assert(is_equal_approx(float(registry.call("get_cover_height_at", grid_position)), 0.9), "TerrainRegistry exposes cover_height by grid")
	_assert(is_equal_approx(float(registry.call("get_los_blocker_height_at", grid_position)), 2.1), "TerrainRegistry exposes LOS blocker height by grid")
	_assert(is_equal_approx(float(registry.call("get_unit_eye_height_bonus_at", grid_position)), 0.2), "TerrainRegistry exposes unit eye height bonus by grid")
	_assert(bool(registry.call("is_elevated_surface_at", grid_position)), "TerrainRegistry exposes elevated-surface flag")
	_assert(profile.has("floor_height") and profile.has("blocks_los_height"), "TerrainRegistry height profile exposes 2.5D fields")
	registry.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
