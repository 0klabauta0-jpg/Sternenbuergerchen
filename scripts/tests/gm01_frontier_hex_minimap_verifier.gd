extends SceneTree
## Read-only presenter checks; synthetic cell authoring never touches the real map.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const OVERLAY = preload("res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd")
const VISUAL = preload("res://scripts/mission/mission_briefing_minimap_visual_presenter.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const SOURCE := "res://maps/Ground_Mission01_32x32.json"
const ROW_HEIGHT := 0.8660254037844386
var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func _vector(value: Dictionary) -> Vector2:
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))


func _near(actual: Vector2, expected: Vector2) -> bool:
	return actual.distance_to(expected) < 0.002


func _fingerprint(data) -> String:
	var cells: Array = []
	for tile in data.get_tiles():
		cells.append(tile.to_dict())
	return JSON.stringify({"tiles": cells, "markers": data.get_markers()}).sha256_text()


func _scenario():
	var scenario = SCENARIO.new()
	scenario.briefing = {"minimap_mode": "terrain_only", "annotations": [
		{"kind": "objective", "target_id": "objective_point", "text": "Projection probe"},
	]}
	return scenario


func _run() -> void:
	_test_negative_axial_fixture()
	_test_legacy_fixture()
	_test_regular_map()
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	if failed == 0:
		print("GM01_FRONTIER_HEX_MINIMAP_ALL_PASS")
	quit(0 if failed == 0 else 1)


func _test_negative_axial_fixture() -> void:
	var data = MAP.create_empty("negative_axial_minimap", Vector2i(4, 4), Vector2(111.0, -37.0), 16.0, 8.0, 3, "hex_axial_v1")
	# Explicit offline fixture construction: reshape the existing 16 cell objects.
	# Production MapData loading remains responsible for their saved positions.
	for tile in data.get_tiles():
		var column: int = tile.grid_position.x
		var row: int = tile.grid_position.y
		tile.grid_position = Vector2i(column - floori(float(row) * 0.5), row)
		var x: float = float(column) + 0.5 * float(row % 2)
		var z: float = float(row) * ROW_HEIGHT
		tile.world_position = Vector2(111.0 + (x - z) * 16.0, -37.0 + (x + z) * 8.0)
	var negative_tile = data.get_tile_at_grid(Vector2i(-1, 2))
	_check(negative_tile != null and data.get_tiles().size() == 16, "Odd-row fixture retains negative axial q and all sixteen real cells")
	data.set_marker_position("objective_point", negative_tile.world_position)
	var before := _fingerprint(data)
	var presenter = OVERLAY.new()
	var snapshot: Dictionary = presenter.build_snapshot(_scenario(), data)
	var bounds: Dictionary = snapshot["map_bounds"]
	# Literal geometric extrema: col0/row3, col3/row0 and col3/row3.
	var expected_min := Vector2(77.43078061834694, -37.0)
	var expected_max := Vector2(159.0, 11.784609690826528)
	_check(_near(_vector(bounds["min"]), expected_min) and _near(_vector(bounds["max"]), expected_max), "Hex minimap bounds follow actual negative-q rectangle, including nonzero origin")
	var marker: Dictionary = Array(snapshot.get("entries", []))[0]
	var marker_world := Vector2(83.28718707889796, -23.143593539448982)
	var expected_uv := (marker_world - expected_min) / (expected_max - expected_min)
	_check(bool(marker.get("has_position", false)) and _near(_vector(marker["world_position"]), marker_world) and _near(_vector(marker["minimap_position_uv"]), expected_uv), "Negative-q objective marker projects to its actual interior minimap position")
	_check(_near(presenter.call("_grid_to_world", data, Vector2i(-1, 2)), marker_world), "Empty-map/fallback coordinate dispatch uses Hex axial geometry")
	var visual: Dictionary = VISUAL.new().build_snapshot(data, snapshot)
	var samples: Array = visual.get("terrain_samples", [])
	var negative_seen := false
	for sample in samples:
		if int(sample.get("grid", {}).get("x", 0)) < 0:
			negative_seen = true
	_check(samples.size() == 16 and negative_seen, "Visual minimap retains negative-q terrain samples in the same bounds")
	_check(_fingerprint(data) == before, "Both presenters leave every source cell and marker unchanged")


func _test_legacy_fixture() -> void:
	var data = MAP.create_empty("legacy_minimap", Vector2i(4, 3), Vector2(111.0, -37.0), 16.0, 8.0)
	data.set_marker_position("objective_point", Vector2(111.0, -21.0))
	var presenter = OVERLAY.new()
	var snapshot: Dictionary = presenter.build_snapshot(_scenario(), data)
	var bounds: Dictionary = snapshot["map_bounds"]
	_check(_near(_vector(bounds["min"]), Vector2(79.0, -37.0)) and _near(_vector(bounds["max"]), Vector2(159.0, 3.0)), "Legacy Square8 full-rectangle minimap bounds remain unchanged")
	var marker: Dictionary = Array(snapshot.get("entries", []))[0]
	_check(_near(_vector(marker["minimap_position_uv"]), Vector2(0.4, 0.4)), "Legacy objective projection remains unchanged")
	_check(_near(presenter.call("_grid_to_world", data, Vector2i(1, 1)), Vector2(111.0, -21.0)), "Fallback keeps the existing Square8 coordinate dispatch")


func _test_regular_map() -> void:
	var source_sha := FileAccess.get_sha256(SOURCE)
	var data = MAP.load_from_file(SOURCE)
	_check(data != null and not data.has_load_issue() and data.get_grid_topology() == "hex_axial_v1" and data.get_grid_size() == Vector2i(48, 48), "Regular GM01 uses the actual saved 48x48 Hex map")
	if data == null or data.get_tiles().is_empty():
		return
	var before := _fingerprint(data)
	var snapshot: Dictionary = OVERLAY.new().build_snapshot(null, data)
	var bounds: Dictionary = snapshot["map_bounds"]
	var min_world := Vector2(INF, INF)
	var max_world := Vector2(-INF, -INF)
	var negative_count := 0
	for tile in data.get_tiles():
		min_world = min_world.min(tile.world_position)
		max_world = max_world.max(tile.world_position)
		if tile.grid_position.x < 0:
			negative_count += 1
	_check(negative_count > 0 and data.get_tiles().size() == 2304 and _near(_vector(bounds["min"]), min_world) and _near(_vector(bounds["max"]), max_world), "Regular GM01 minimap encloses all 2304 saved Hex cells, including its negative-q side")
	var visual: Dictionary = VISUAL.new().build_snapshot(data, snapshot)
	_check(int(visual.get("sample_count", 0)) == 2304, "Regular GM01 minimap includes every cell at the existing 48-axis sampling limit")
	_check(_fingerprint(data) == before and FileAccess.get_sha256(SOURCE) == source_sha, "Regular-map minimap checks change neither memory facts nor saved source bytes")
