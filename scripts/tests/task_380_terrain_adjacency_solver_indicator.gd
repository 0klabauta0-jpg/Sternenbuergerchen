extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_380 Terrain Adjacency Solver Indicator ===")
	await _test_single_tile_adjacency_indicator()
	await _test_brush_stroke_adjacency_indicator_and_disabled_toggle()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_380: ALL PASSED")
		quit(0)


func _test_single_tile_adjacency_indicator() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var disabled_snapshot: Dictionary = Dictionary(editor.call("get_adjacency_debug_overlay_snapshot"))
	_assert(not bool(disabled_snapshot.get("enabled", true)), "Adjacency debug overlay starts disabled")
	_assert(int(disabled_snapshot.get("drawn_entry_count", -1)) == 0, "Disabled adjacency overlay draws no entries")

	_assert(bool(editor.call("set_adjacency_debug_overlay_enabled", true)), "Adjacency debug overlay can be enabled")
	var single_dirty_grids: Array[Vector2i] = [Vector2i(4, 4)]
	editor.call("_refresh_dirty_visual_neighborhoods", single_dirty_grids)
	await _wait_frames(2)
	var dirty_snapshot: Dictionary = Dictionary(editor.call("get_dirty_neighborhood_debug_snapshot"))
	var overlay_snapshot: Dictionary = Dictionary(editor.call("get_adjacency_debug_overlay_snapshot"))
	var role_counts: Dictionary = Dictionary(overlay_snapshot.get("role_counts", {}))
	_assert(bool(overlay_snapshot.get("enabled", false)) and bool(overlay_snapshot.get("active", false)), "Enabled adjacency overlay reports active state after dirty refresh")
	_assert(int(overlay_snapshot.get("seed_count", 0)) == int(dirty_snapshot.get("seed_count", -1)), "Overlay seed count comes from dirty-neighborhood snapshot")
	_assert(int(overlay_snapshot.get("raw_neighborhood_candidate_count", 0)) == int(dirty_snapshot.get("raw_neighborhood_candidate_count", -1)), "Overlay raw candidate count mirrors solver snapshot")
	_assert(int(overlay_snapshot.get("cliff_wall_candidate_count", 0)) == int(dirty_snapshot.get("cliff_wall_candidate_count", -1)), "Overlay deduped candidate count mirrors solver snapshot")
	_assert(int(role_counts.get("seed", 0)) == 1, "Overlay draws one seed tile")
	_assert(int(role_counts.get("neighbor", 0)) >= 4, "Overlay draws recomputed neighbor tiles")
	_assert(int(overlay_snapshot.get("drawn_entry_count", 0)) == int(overlay_snapshot.get("entry_count", -1)), "Drawn debug entries match snapshot entries")
	var overlay: Node = editor.get_node_or_null("AdjacencyDebugOverlay")
	_assert(overlay != null and overlay.get_child_count() == int(overlay_snapshot.get("drawn_entry_count", 0)), "Adjacency overlay node contains the drawn entries")
	_assert(bool(overlay_snapshot.get("visual_only", false)) and not bool(overlay_snapshot.get("ui_sets_gameplay_truth", true)), "Adjacency overlay is visual-only")

	editor.queue_free()
	await _wait_frames(2)


func _test_brush_stroke_adjacency_indicator_and_disabled_toggle() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	editor.call("set_adjacency_debug_overlay_enabled", true)
	var stroke_dirty_grids: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5)]
	editor.call("_refresh_dirty_visual_neighborhoods", stroke_dirty_grids)
	await _wait_frames(2)
	var stroke_snapshot: Dictionary = Dictionary(editor.call("get_adjacency_debug_overlay_snapshot"))
	var stroke_roles: Dictionary = Dictionary(stroke_snapshot.get("role_counts", {}))
	_assert(int(stroke_snapshot.get("seed_count", 0)) == 2, "Brush-stroke adjacency snapshot tracks both seed tiles")
	_assert(int(stroke_snapshot.get("raw_neighborhood_candidate_count", 0)) == 10, "Brush-stroke raw candidate count preserves per-seed solver work")
	_assert(int(stroke_snapshot.get("duplicate_neighborhood_candidate_count", 0)) > 0, "Brush-stroke snapshot reports deduped overlapping neighbors")
	_assert(int(stroke_roles.get("seed", 0)) == 2, "Brush-stroke overlay distinguishes both seed tiles")
	_assert(int(stroke_roles.get("neighbor", 0)) >= 4, "Brush-stroke overlay draws recomputed neighborhood")
	var rebuild_count_before_disabled: int = int(stroke_snapshot.get("rebuild_count", 0))

	editor.call("set_adjacency_debug_overlay_enabled", false)
	await _wait_frames(2)
	var disabled_snapshot: Dictionary = Dictionary(editor.call("get_adjacency_debug_overlay_snapshot"))
	var overlay: Node = editor.get_node_or_null("AdjacencyDebugOverlay")
	_assert(not bool(disabled_snapshot.get("enabled", true)), "Adjacency overlay toggle disables debug layer")
	_assert(overlay != null and overlay.get_child_count() == 0, "Disabled adjacency overlay clears debug visuals")
	var disabled_dirty_grids: Array[Vector2i] = [Vector2i(7, 5), Vector2i(8, 5)]
	editor.call("_refresh_dirty_visual_neighborhoods", disabled_dirty_grids)
	await _wait_frames(2)
	var after_disabled_refresh: Dictionary = Dictionary(editor.call("get_adjacency_debug_overlay_snapshot"))
	_assert(int(after_disabled_refresh.get("drawn_entry_count", -1)) == 0, "Disabled adjacency overlay keeps draw entries empty after solver refresh")
	_assert(int(after_disabled_refresh.get("rebuild_count", 0)) == rebuild_count_before_disabled, "Disabled adjacency overlay avoids visual rebuilds")

	editor.queue_free()
	await _wait_frames(2)


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	return editor


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
