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
	print("=== TASK_407 Static Tile Visual Batching Completion ===")
	await _test_static_tile_layers_are_batched()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_static_tile_layers_are_batched() -> void:
	var map_data = _build_static_tile_batch_fixture()
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	await _wait_frames(1)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var tile_count: int = FIXTURE_SIZE.x * FIXTURE_SIZE.y
	_assert(int(snapshot.get("tile_count", 0)) == tile_count, "Fixture renders all tiles")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == tile_count, "Ground coverage remains per tile")
	_assert(int(snapshot.get("ground_multimesh_tile_count", 0)) == tile_count, "All fixture ground tiles are batched")
	_assert(int(snapshot.get("ground_individual_model_count", -1)) == 0, "Fixture avoids individual ground model nodes")
	_assert(int(snapshot.get("space_station_model_count", 0)) >= 8, "Station floor ground remains counted while batched")
	_assert(_surface_entries_include_model_key(snapshot, "modular_floor_raised"), "Fixture batches Modular raised floor ground")
	_assert(int(snapshot.get("surface_tint_count", 0)) > 0, "Fixture renders non-ground surface tint coverage")
	_assert(int(snapshot.get("surface_tint_batched_tile_count", 0)) == int(snapshot.get("surface_tint_count", -1)), "Surface tints are batched")
	_assert(int(snapshot.get("surface_tint_multimesh_instance_count", 0)) > 0, "Surface tints create MultiMesh instances")
	_assert(int(snapshot.get("height_edge_model_count", 0)) > 0, "Fixture renders height edge coverage")
	_assert(int(snapshot.get("height_edge_multimesh_model_count", 0)) == int(snapshot.get("height_edge_model_count", -1)), "Height edge models are batched")
	_assert(int(snapshot.get("height_edge_individual_model_count", -1)) == 0, "Fixture avoids individual height edge model nodes")
	var map_budget: Dictionary = Dictionary(Dictionary(snapshot.get("render_budget_by_category", {})).get("map", {}))
	var required_multimeshes: int = int(snapshot.get("ground_multimesh_instance_count", 0)) \
		+ int(snapshot.get("surface_tint_multimesh_instance_count", 0)) \
		+ int(snapshot.get("height_edge_multimesh_instance_count", 0))
	_assert(int(map_budget.get("multimesh_instance_count", 0)) >= required_multimeshes, "Map budget includes static tile MultiMesh instances")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Static tile batching has no missing map asset mappings")
	primary_view.queue_free()
	await _wait_frames(2)


func _build_static_tile_batch_fixture():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_407_static_tile_batch_fixture", FIXTURE_SIZE, Vector2(512.0, 256.0), 64.0, 32.0, 3)
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		tile_data.type_id = "ground_flat"
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		match int(tile_data.grid_position.x) % 4:
			0:
				tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
			1:
				tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
			2:
				tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
			_:
				tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
		if int(tile_data.grid_position.y) == 0:
			match int(tile_data.grid_position.x) % 4:
				0:
					tile_data.type_id = "station_floor_panel"
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
				1:
					tile_data.type_id = "station_set_floor_panel"
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
				2:
					tile_data.type_id = "modular_floor"
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
				_:
					tile_data.type_id = "modular_floor_big"
					tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
		if tile_data.grid_position == Vector2i(0, 1):
			tile_data.type_id = "modular_floor_raised"
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
	for x in range(5, 11):
		for y in range(5, 11):
			var hill_tile = map_data.call("get_tile_at_grid", Vector2i(x, y))
			hill_tile.height_level = 2
			hill_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	return map_data


func _surface_entries_include_model_key(snapshot: Dictionary, model_key: String) -> bool:
	for entry_variant in Array(snapshot.get("surface_visual_entries", [])):
		if String(Dictionary(entry_variant).get("model_key", "")) == model_key:
			return true
	return false


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
