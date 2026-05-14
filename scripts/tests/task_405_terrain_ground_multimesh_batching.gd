extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const FIXTURE_SIZE: Vector2i = Vector2i(16, 16)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_405 Terrain Ground MultiMesh Batching ===")
	await _test_space_ground_batches_without_losing_tile_coverage()
	await _test_nature_ground_batches_with_surface_entries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_space_ground_batches_without_losing_tile_coverage() -> void:
	var map_data = _build_ground_fixture_map("task_405_space_ground_batch_fixture", false)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	await _wait_frames(1)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var tile_count: int = FIXTURE_SIZE.x * FIXTURE_SIZE.y
	_assert(int(snapshot.get("tile_count", 0)) == tile_count, "Space ground fixture renders all tiles")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == tile_count, "Ground coverage remains per tile")
	_assert(int(snapshot.get("ground_multimesh_tile_count", 0)) == tile_count, "Space ground tiles are batched")
	_assert(int(snapshot.get("ground_multimesh_instance_count", 0)) > 0, "Space ground creates MultiMesh instances")
	_assert(int(snapshot.get("ground_individual_model_count", -1)) == 0, "Space ground avoids individual ground model nodes")
	_assert(Array(snapshot.get("surface_visual_entries", [])).size() == tile_count, "Surface visual entries remain per tile")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Space ground batching has no missing map assets")
	var map_budget: Dictionary = Dictionary(Dictionary(snapshot.get("render_budget_by_category", {})).get("map", {}))
	_assert(int(map_budget.get("multimesh_instance_count", 0)) >= int(snapshot.get("ground_multimesh_instance_count", 0)), "Map render budget counts ground MultiMeshes")
	_assert(int(map_budget.get("mesh_instance_count", 999999)) < int(snapshot.get("ground_mesh_count", 0)), "Map render budget no longer uses one MeshInstance per ground tile")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_nature_ground_batches_with_surface_entries() -> void:
	var map_data = _build_ground_fixture_map("task_405_nature_ground_batch_fixture", true)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	await _wait_frames(1)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var tile_count: int = FIXTURE_SIZE.x * FIXTURE_SIZE.y
	_assert(int(snapshot.get("tile_count", 0)) == tile_count, "Nature ground fixture renders all tiles")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == tile_count, "Nature ground coverage remains per tile")
	_assert(int(snapshot.get("ground_multimesh_tile_count", 0)) == tile_count, "Nature ground tiles are batched")
	_assert(int(snapshot.get("ground_multimesh_instance_count", 0)) > 0, "Nature ground creates MultiMesh instances")
	_assert(int(snapshot.get("ground_individual_model_count", -1)) == 0, "Nature ground avoids individual ground model nodes")
	_assert(int(snapshot.get("nature_surface_ground_model_count", 0)) == tile_count, "Nature ground counters remain per tile")
	_assert(Array(snapshot.get("surface_visual_entries", [])).size() == tile_count, "Nature surface entries remain per tile")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Nature ground batching has no missing map assets")
	primary_view.queue_free()
	await _wait_frames(2)


func _build_ground_fixture_map(map_id: String, use_nature_ground: bool):
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", map_id, FIXTURE_SIZE, Vector2(512.0, 256.0), 64.0, 32.0, 3)
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		tile_data.height_level = 1 if (int(tile_data.grid_position.x) + int(tile_data.grid_position.y)) % 9 == 0 else 0
		if use_nature_ground:
			tile_data.type_id = "nature_ground_dirt"
			match int(tile_data.grid_position.x) % 4:
				0:
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
				1:
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
					tile_data.type_id = "nature_ground_sand_dirt"
				2:
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
					tile_data.type_id = "nature_ground_rock_dirt"
				_:
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
		else:
			tile_data.type_id = "ground_flat"
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
	return map_data


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
