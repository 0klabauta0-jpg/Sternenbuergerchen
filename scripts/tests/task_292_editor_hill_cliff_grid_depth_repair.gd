extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const REFERENCE_MAP_PATH: String = "res://maps/editor_terrain_visual_recovery_reference.json"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/editor_hill_cliff_grid_depth_checklist.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_292 Editor Hill Cliff Grid Depth Repair ===")
	await _test_render_depth_snapshot()
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_render_depth_snapshot() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", REFERENCE_MAP_PATH)
	_assert(map_data != null, "Reference map loads")
	if map_data == null:
		return
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	view.call("set_selected_grid_positions", [Vector2i(3, 3)])
	await _wait_frames(10)

	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var visual: Dictionary = Dictionary(snapshot.get("editor_visual_recovery", {}))
	_assert(_float_eq(float(visual.get("height_step", 0.0)), 0.5), "Render snapshot reports height step 0.5")
	_assert(float(visual.get("grid_line_surface_y_offset", 1.0)) <= 0.06, "Grid line offset sits close to tile surface")
	_assert(bool(visual.get("grid_depth_tested", false)), "Grid material is depth-tested")
	_assert(int(snapshot.get("height_edge_model_count", 0)) > 0, "Reference renders height edge models")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1, "Selection remains visible")
	var entries: Array = Array(snapshot.get("height_edge_visual_entries", []))
	_assert(_height_edges_have_valid_spans(entries), "Height edges fill lower-neighbor-to-top spans")
	_assert(_height_edges_anchor_on_lower_neighbor_tiles(entries), "Height edge visuals are anchored on lower neighbor tiles")
	_assert(_cliffs_do_not_use_ramp_models(entries), "Cliff entries never use ramp models")
	_assert(_slopes_use_ramp_models(entries), "Slope entries use ramp models")
	_assert(_entries_use_legacy_space(edges_with_active_roles(entries)), "Active edge entries use legacy Space Kit reference")
	view.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Manual hill/cliff/grid checklist exists")
	var text: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["H0", "H1", "H2", "grid", "wall"]:
		_assert(text.to_lower().contains(required_text.to_lower()), "Checklist covers %s" % required_text)


func _height_edges_have_valid_spans(entries: Array) -> bool:
	if entries.is_empty():
		return false
	var has_two_step_span: bool = false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var base_y: float = float(entry.get("base_y", INF))
		var top_y: float = float(entry.get("top_y", -INF))
		var height_span: float = float(entry.get("height_span", 0.0))
		if base_y >= top_y:
			return false
		if not _float_eq(height_span, top_y - base_y):
			return false
		if height_span >= 1.0:
			has_two_step_span = true
	return has_two_step_span


func _height_edges_anchor_on_lower_neighbor_tiles(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var grid_position: Vector2i = Vector2i(entry.get("grid_position", Vector2i.ZERO))
		var anchor_grid_position: Vector2 = Vector2(entry.get("anchor_grid_position", Vector2(grid_position)))
		var edge_dirs: Array = Array(entry.get("edge_dirs", []))
		if edge_dirs.is_empty():
			return false
		var expected_anchor := Vector2(grid_position)
		for edge_dir_variant in edge_dirs:
			expected_anchor += Vector2(Vector2i(edge_dir_variant))
		if not _vec2_eq(anchor_grid_position, expected_anchor):
			return false
		if _vec2_eq(anchor_grid_position, Vector2(grid_position)):
			return false
	return true


func _cliffs_do_not_use_ramp_models(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("edge_type", "")) == "cliff" and String(entry.get("model_path", "")).to_lower().contains("ramp"):
			return false
	return true


func _slopes_use_ramp_models(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("edge_type", "")) == "slope" and String(entry.get("model_path", "")).to_lower().contains("ramp"):
			return true
	return false


func edges_with_active_roles(entries: Array) -> Array:
	var result: Array = []
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if ["cliff_straight", "cliff_outer_corner", "slope_steps"].has(String(entry.get("edge_role", ""))):
			result.append(entry)
	return result


func _entries_use_legacy_space(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("source_id", "")) != "kenney_space_kit":
			return false
	return true


func _float_eq(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= 0.001


func _vec2_eq(actual: Vector2, expected: Vector2) -> bool:
	return actual.distance_squared_to(expected) <= 0.0001


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


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
