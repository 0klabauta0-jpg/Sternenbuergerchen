extends SceneTree

const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TRUTH_AUDIT_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_truth_audit.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_456_wall_segment_los_and_tile_truth_inspector.md"
const CONTRACT_PATH: String = "res://docs/dev/terrain_truth_visual_audit_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_456 Wall Segment LOS And Tile Truth Inspector ===")
	_test_runtime_wall_segment_los()
	await _test_map_editor_tile_truth_inspector()
	_test_docs_are_registered()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_456: ALL PASSED")
		quit(0)


func _test_runtime_wall_segment_los() -> void:
	var fixture: Dictionary = _build_los_fixture()
	var registry = fixture["registry"]
	var map_data = fixture["map_data"]
	var los_system = LINE_OF_SIGHT_SCRIPT.new()
	_assert(bool(los_system.call("uses_wall_segment_los")), "LineOfSightSystem advertises active wall-segment LOS")

	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	wall_tile.type_id = "wall_straight_ne"
	wall_tile.object_type_id = ""
	wall_tile.blocks_los = true
	wall_tile.object_height = 2
	wall_tile.walkable = false
	_assert(not bool(los_system.call(
		"has_line_of_sight_with_terrain",
		registry.call("grid_to_world", Vector2i(1, 1)),
		registry.call("grid_to_world", Vector2i(3, 1)),
		registry,
		1000.0
	)), "Runtime LOS blocks when sight crosses a wall segment")
	_assert(bool(los_system.call(
		"has_line_of_sight_with_terrain",
		registry.call("grid_to_world", Vector2i(2, 0)),
		registry.call("grid_to_world", Vector2i(2, 2)),
		registry,
		1000.0
	)), "Runtime LOS stays clear along the same wall side")
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	view.set("_terrain_map_data", map_data)
	_assert(Vector2i(view.call("_find_fire_sector_los_blocker_grid", Vector2i(1, 1), Vector2i(3, 1))) == Vector2i(2, 1), "Mission LOS visual blocker finder blocks crossed wall segment")
	_assert(Vector2i(view.call("_find_fire_sector_los_blocker_grid", Vector2i(2, 0), Vector2i(2, 2))) == Vector2i(2147483647, 2147483647), "Mission LOS visual blocker finder stays clear along same wall side")
	view.free()

	wall_tile.type_id = "ground_flat"
	wall_tile.object_type_id = ""
	wall_tile.blocks_los = true
	wall_tile.object_height = 2
	_assert(not bool(los_system.call(
		"has_line_of_sight_with_terrain",
		registry.call("grid_to_world", Vector2i(1, 1)),
		registry.call("grid_to_world", Vector2i(3, 1)),
		registry,
		1000.0
	)), "Non-wall LOS blocker still blocks as a whole tile")

	var policy: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_policy_snapshot"))
	_assert(bool(policy.get("combat_los_uses_segment_policy", false)), "Terrain truth policy reports active combat segment LOS")
	_assert(String(policy.get("combat_los_policy_source", "")) == "LineOfSightSystem", "Terrain truth policy names LineOfSightSystem as source")

	registry.free()


func _test_map_editor_tile_truth_inspector() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "MapEditor loads map data for inspector fixture")
	if map_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return
	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	_assert(wall_tile != null, "Inspector wall fixture tile exists")
	if wall_tile != null:
		wall_tile.type_id = "wall_straight_ne"
		wall_tile.object_type_id = ""
		wall_tile.blocks_los = true
		wall_tile.object_height = 2
		wall_tile.walkable = false
	editor.call("select_grid_for_authoring", Vector2i(2, 2))
	await _wait_frames(3)

	var snapshot: Dictionary = Dictionary(editor.call("get_selected_tile_truth_debug_snapshot"))
	_assert(bool(snapshot.get("selected", false)), "Tile truth inspector reports selected tile")
	_assert(String(snapshot.get("blocker_type", "")) == "wall_segment_candidate", "Tile truth inspector exposes wall segment blocker")
	_assert(int(snapshot.get("wall_segment_count", 0)) == 1, "Tile truth inspector exposes wall segment count")
	_assert(bool(snapshot.get("combat_los_uses_segment_policy", false)), "Tile truth inspector reports active runtime segment policy")
	_assert(bool(snapshot.get("visual_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Tile truth inspector remains read-only")

	var label := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/TerrainTruthInspectorLabel") as Label
	_assert(label != null, "Tile truth inspector label exists")
	if label != null:
		_assert(label.text.contains("W1") and label.text.contains("wall_segment_candidate"), "Tile truth inspector label summarizes wall truth")

	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var inspector: Dictionary = Dictionary(usability.get("inspector", {}))
	_assert(bool(inspector.get("terrain_truth_visible", false)), "Usability snapshot exposes terrain truth inspector visibility")
	var selected_truth: Dictionary = Dictionary(inspector.get("selected_tile_terrain_truth", {}))
	_assert(String(selected_truth.get("wall_los_policy", "")) == "edge_segment_blockers", "Usability snapshot carries selected tile LOS policy")

	editor.queue_free()
	await _wait_frames(2)


func _test_docs_are_registered() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_456 - Wall Segment LOS And Tile Truth Inspector"), "TASK_456 task file exists")
	_assert(contract_text.contains("TASK_456 verwendet diese Regel im aktiven"), "Contract documents active runtime segment LOS")
	_assert(contract_text.contains("Selektiver Tile-Truth-Inspector"), "Contract documents selected tile inspector")
	_assert(status_text.contains("TASK_456 - Wall Segment LOS And Tile Truth Inspector"), "Implementation status documents TASK_456")
	_assert(roadmap_text.contains("TASK_456 - Wall Segment LOS And Tile Truth Inspector"), "Roadmap lists TASK_456")


func _build_los_fixture() -> Dictionary:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_456_wall_segment_los", Vector2i(5, 4), Vector2.ZERO, 64.0, 32.0, 3)
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	return {
		"map_data": map_data,
		"registry": registry,
	}


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
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
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
