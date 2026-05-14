extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const FIXTURE_SIZE: Vector2i = Vector2i(16, 16)
const REQUIRED_PROPS: PackedStringArray = [
	"nature_tree_blocker",
	"nature_rock_cover",
	"nature_bush_cover",
	"nature_cactus_cover",
	"nature_deco_logs",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_408 Static Nature Prop MultiMesh Batching ===")
	await _test_dense_nature_props_are_batched()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_dense_nature_props_are_batched() -> void:
	var map_data = _build_dense_prop_fixture()
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var tile_count: int = FIXTURE_SIZE.x * FIXTURE_SIZE.y
	var entries: Array = Array(snapshot.get("nature_prop_visual_entries", []))
	_assert(int(snapshot.get("tile_count", 0)) == tile_count, "Fixture renders all tiles")
	_assert(int(snapshot.get("nature_prop_model_count", 0)) == tile_count, "Nature prop coverage remains per prop")
	_assert(entries.size() == tile_count, "Nature prop entries remain per prop")
	_assert(int(snapshot.get("static_prop_multimesh_model_count", 0)) == tile_count, "All dense fixture Nature props are batched")
	_assert(int(snapshot.get("static_prop_individual_model_count", -1)) == 0, "Dense fixture avoids individual static prop model nodes")
	_assert(int(snapshot.get("static_prop_multimesh_instance_count", 0)) > 0, "Dense fixture creates static prop MultiMesh instances")
	_assert(_entries_cover_required_props(entries), "Dense fixture covers every required Nature prop type")
	_assert(_entries_are_batched(entries), "Nature prop snapshot entries report batched rendering")
	_assert(_role_count(snapshot, "tree_blocker") > 0, "Batched prop counters keep tree role")
	_assert(_role_count(snapshot, "rock_cover") > 0, "Batched prop counters keep rock role")
	_assert(_role_count(snapshot, "bush_cover") > 0, "Batched prop counters keep bush role")
	_assert(_role_count(snapshot, "cactus_cover") > 0, "Batched prop counters keep cactus role")
	_assert(_role_count(snapshot, "deco_small") > 0, "Batched prop counters keep deco role")
	var map_budget: Dictionary = Dictionary(Dictionary(snapshot.get("render_budget_by_category", {})).get("map", {}))
	_assert(int(map_budget.get("multimesh_instance_count", 0)) >= int(snapshot.get("static_prop_multimesh_instance_count", 0)), "Map budget includes static prop MultiMeshes")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Static prop batching has no missing map asset mappings")
	primary_view.queue_free()
	await _wait_frames(2)


func _build_dense_prop_fixture():
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_408_static_prop_batch_fixture", FIXTURE_SIZE, Vector2(512.0, 256.0), 64.0, 32.0, 3)
	var prop_index: int = 0
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		tile_data.type_id = "ground_flat"
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
		tile_data.height_level = 0
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		var prop_id: String = String(REQUIRED_PROPS[prop_index % REQUIRED_PROPS.size()])
		catalog.call("apply_type_to_tile", tile_data, prop_id)
		tile_data.object_rotation_degrees = float((prop_index % 4) * 90)
		prop_index += 1
	return map_data


func _entries_cover_required_props(entries: Array) -> bool:
	for prop_id in REQUIRED_PROPS:
		var found: bool = false
		for entry_variant in entries:
			if String(Dictionary(entry_variant).get("visual_type_id", "")) == String(prop_id):
				found = true
				break
		if not found:
			return false
	return true


func _entries_are_batched(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if not bool(Dictionary(entry_variant).get("batched", false)):
			return false
	return true


func _role_count(snapshot: Dictionary, role: String) -> int:
	return int(Dictionary(snapshot.get("nature_prop_role_counts", {})).get(role, 0))


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
