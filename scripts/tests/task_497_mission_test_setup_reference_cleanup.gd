extends SceneTree

const MISSION_SETUP_SCRIPT: GDScript = preload("res://scripts/tests/mission_test_setup.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SETUP_PATH: String = "res://scripts/tests/mission_test_setup.gd"
const TASK_PATH: String = "res://docs/tasks/TASK_497_mission_test_setup_reference_cleanup.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_64x64.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_497 Mission TestSetup Reference Cleanup ===")
	_test_source_contract()
	await _test_scene_exports_simulation_root_path()
	_test_json_terrain_priority_on_large_map()
	_test_legacy_fallback_is_bounded_fixture_data()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_source_contract() -> void:
	var source: String = _read_text(SETUP_PATH)
	_assert(source.contains("@export var simulation_root_path: NodePath"), "MissionTestSetup exposes SimulationRoot as an exported NodePath")
	_assert(not source.contains("get_node_or_null(\"../SimulationRoot\")"), "MissionTestSetup no longer hardcodes ../SimulationRoot")
	_assert(not source.contains("func _find_tile_sprite_at"), "Unused TileSprite nearest-search helper is removed")
	_assert(source.contains("LEGACY_FALLBACK_BLOCKED_TILES") and source.contains("_build_legacy_fallback_tile_payload"), "Legacy hardcoded terrain fallback is isolated as fixture data")


func _test_scene_exports_simulation_root_path() -> void:
	var scene: Node = MISSION_SCENE.instantiate()
	_assert(scene != null, "Mission reactivity scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(2)

	var setup: Node = scene.get_node_or_null("MissionSetup")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(setup != null and simulation_root != null, "Mission scene exposes MissionSetup and SimulationRoot")
	if setup != null and simulation_root != null:
		_assert(NodePath(setup.get("simulation_root_path")) == NodePath("../SimulationRoot"), "MissionSetup scene serializes simulation_root_path")
		_assert(setup.call("_get_simulation_root") == simulation_root, "MissionSetup resolves SimulationRoot through the exported path")

	scene.queue_free()
	await _wait_frames(2)


func _test_json_terrain_priority_on_large_map() -> void:
	var fixture: Node = Node.new()
	fixture.name = "Task497TerrainFixture"

	var terrain_registry: Node = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	fixture.add_child(terrain_registry)

	var setup: Node = MISSION_SETUP_SCRIPT.new()
	setup.name = "MissionSetup"
	fixture.add_child(setup)
	setup.set("terrain_registry_path", setup.get_path_to(terrain_registry))
	setup.set("map_file_path", LARGE_MAP_PATH)
	setup.set("use_2_5d_primary_view", true)

	var resolved_registry = setup.call("_setup_terrain_registry")
	_assert(resolved_registry == terrain_registry, "MissionTestSetup resolves the configured TerrainRegistry")
	_assert(Array(terrain_registry.call("get_all_tiles")).size() == 4096, "64x64 JSON map registers 4096 TerrainRegistry tiles")
	var loaded_map = setup.get("_loaded_terrain_map_data")
	_assert(loaded_map != null and Vector2i(loaded_map.call("get_grid_size")) == Vector2i(64, 64), "JSON TerrainMapData remains the primary load path")
	var first_tile = terrain_registry.call("get_tile_at_grid", Vector2i.ZERO)
	_assert(first_tile != null and not String(first_tile.tile_id).begins_with("legacy_tile_"), "64x64 JSON load does not enter the legacy hardcode fallback")

	fixture.free()


func _test_legacy_fallback_is_bounded_fixture_data() -> void:
	var setup: Node = MISSION_SETUP_SCRIPT.new()
	var blocked_payload: Dictionary = Dictionary(setup.call("_build_legacy_fallback_tile_payload", Vector2i(4, 2), Vector2(128.0, 64.0)))
	var cover_payload: Dictionary = Dictionary(setup.call("_build_legacy_fallback_tile_payload", Vector2i(5, 3), Vector2(160.0, 96.0)))
	var default_payload: Dictionary = Dictionary(setup.call("_build_legacy_fallback_tile_payload", Vector2i(9, 9), Vector2(320.0, 288.0)))

	_assert(String(blocked_payload.get("tile_id", "")).begins_with("legacy_tile_"), "Legacy fallback tile ids are visibly marked")
	_assert(not bool(blocked_payload.get("walkable", true)) and bool(blocked_payload.get("blocks_los", false)), "Legacy blocked/LOS fixture values are preserved")
	_assert(int(cover_payload.get("cover_value", 0)) == 35 and int(cover_payload.get("height_level", 0)) == 2 and String(cover_payload.get("surface_type", "")) == "rock", "Legacy cover/height/surface fixture values are preserved")
	_assert(bool(default_payload.get("walkable", false)) and int(default_payload.get("cover_value", -1)) == 0 and String(default_payload.get("surface_type", "")) == "ground", "Legacy default fixture values stay bounded")
	setup.free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("TASK_497 - Mission TestSetup Reference Cleanup"), "TASK_497 task file exists")
	_assert(status_text.contains("TASK_497 - Mission TestSetup Reference Cleanup"), "Implementation status documents TASK_497")


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
