extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TILE_PROPERTY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_tile_property_overlay.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_455 Terrain Truth Editor Overlay Visibility ===")
	await _test_truth_overlay_labels_segments_and_meta()
	_test_docs_are_registered()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_455: ALL PASSED")
		quit(0)


func _test_truth_overlay_labels_segments_and_meta() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "MapEditor exposes terrain map data for overlay fixture")
	if map_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	_assert(wall_tile != null, "Wall fixture tile exists")
	if wall_tile != null:
		wall_tile.type_id = "wall_straight_ne"
		wall_tile.object_type_id = ""
		wall_tile.walkable = false
		wall_tile.blocks_los = true
		wall_tile.object_height = 2
		wall_tile.cover_value = 0
	var bush_tile = map_data.call("get_tile_at_grid", Vector2i(3, 2))
	_assert(bush_tile != null, "Object-on-ground fixture tile exists")
	if bush_tile != null:
		bush_tile.type_id = "ground_flat"
		bush_tile.object_type_id = "nature_bush_small"
		bush_tile.walkable = true
		bush_tile.blocks_los = false
		bush_tile.object_height = 1
		bush_tile.cover_value = 35

	var wall_label: String = String(TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_truth_label", wall_tile))
	var bush_label: String = String(TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_truth_label", bush_tile))
	_assert(wall_label.contains("W1"), "Truth label exposes wall segment count")
	_assert(bush_label.contains("OBJ H1"), "Truth label exposes object height on ground")

	_assert(bool(editor.call("set_tile_property_overlay_enabled", true)), "Tile property overlay can be enabled")
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(editor.call("get_tile_property_overlay_debug_snapshot"))
	_assert(bool(snapshot.get("visual_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Truth overlay remains visual-only")
	_assert(int(snapshot.get("wall_segment_candidate_count", 0)) >= 1, "Overlay snapshot counts wall segment candidates")
	_assert(int(snapshot.get("object_layer_count", 0)) >= 1, "Overlay snapshot counts object layer tiles")

	var wall_node: Node = editor.get_node_or_null("TilePropertyOverlay/TileProperty_2_2")
	_assert(wall_node != null, "Wall tile draw node exists")
	if wall_node != null:
		_assert(String(wall_node.get_meta("blocker_type", "")) == "wall_segment_candidate", "Wall node meta exposes segment blocker type")
		_assert(int(wall_node.get_meta("wall_segment_count", 0)) == 1, "Wall node meta exposes segment count")
		_assert(String(wall_node.get_meta("truth_label", "")).contains("W1"), "Wall node meta exposes truth label")
		var segment_root: Node = wall_node.get_node_or_null("WallSegments")
		_assert(segment_root != null and segment_root.get_child_count() == 1, "Wall node draws one visible wall segment line")
		if segment_root != null and segment_root.get_child_count() > 0:
			var segment_line := segment_root.get_child(0) as Line2D
			_assert(segment_line != null and segment_line.get_point_count() == 2, "Wall segment line has two visible endpoints")

	var bush_node: Node = editor.get_node_or_null("TilePropertyOverlay/TileProperty_3_2")
	_assert(bush_node != null, "Object-on-ground draw node exists")
	if bush_node != null:
		_assert(String(bush_node.get_meta("object_layer_state", "")) == "object_on_ground", "Object node meta keeps ground/object layer distinction")
		_assert(String(bush_node.get_meta("blocker_type", "")) == "object_height", "Object node meta exposes object-height blocker diagnostic")
		_assert(String(bush_node.get_meta("truth_label", "")).contains("OBJ H1"), "Object node meta exposes object truth label")

	editor.queue_free()
	await _wait_frames(2)


func _test_docs_are_registered() -> void:
	var task_text: String = _read_text("res://docs/tasks/TASK_455_terrain_truth_editor_overlay_visibility.md")
	var contract_text: String = _read_text("res://docs/dev/terrain_truth_visual_audit_contract.md")
	var status_text: String = _read_text("res://docs/IMPLEMENTATION_STATUS.md")
	var roadmap_text: String = _read_text("res://docs/TASK_ROADMAP.md")
	_assert(task_text.contains("TASK_455 - Terrain Truth Editor Overlay Visibility"), "TASK_455 task file exists")
	_assert(contract_text.contains("Sichtbare Overlay-Konvention"), "Terrain truth contract documents visible overlay convention")
	_assert(status_text.contains("TASK_455 - Terrain Truth Editor Overlay Visibility"), "Implementation status documents TASK_455")
	_assert(roadmap_text.contains("TASK_455 - Terrain Truth Editor Overlay Visibility"), "Roadmap lists TASK_455")


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	return editor


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
