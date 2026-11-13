extends SceneTree

const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const HEX_PATH: String = "res://scripts/terrain/hex_grid.gd"
const HEX_TOPOLOGY: String = "hex_axial_v1"
var _passed: int = 0
var _failed: int = 0
var _hex: GDScript


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Frontier Hex Foundation Verifier ===")
	if not FileAccess.file_exists(HEX_PATH):
		_check(false, "HexGrid foundation API exists (expected red before implementation)")
		_finish()
		return
	_hex = load(HEX_PATH)
	var prototype = MAP_SCRIPT.new()
	if not prototype.has_method("get_grid_topology"):
		_check(false, "MapData exposes explicit topology (expected red before implementation)")
		_finish()
		return
	_test_geometry()
	_test_map_registry_paths()
	_test_incremental_hex_portal()
	_test_legacy()
	_finish()


func _test_geometry() -> void:
	var directions: Array = Array(_hex.call("neighbor_directions"))
	_check(directions.size() == 6, "Exactly six axial neighbor directions")
	var seen: Dictionary = {}
	for direction_variant in directions:
		var direction: Vector2i = Vector2i(direction_variant)
		seen[direction] = true
		var plane: Vector2 = _hex.call("axial_to_plane", Vector2(direction))
		_check(is_equal_approx(plane.length(), 1.0) and int(_hex.call("distance", Vector2i.ZERO, direction)) == 1, "Neighbor %s has unit physical length and hex distance" % str(direction))
	_check(seen.size() == 6 and not bool(_hex.call("are_neighbors", Vector2i.ZERO, Vector2i(1, 1))), "Directions are unique and square-only diagonal is not a hex neighbor")
	for grid in [Vector2i.ZERO, Vector2i(-4, 2), Vector2i(5, -3), Vector2i(-8, -8)]:
		var plane: Vector2 = _hex.call("axial_to_plane", Vector2(grid))
		var axial: Vector2 = _hex.call("plane_to_axial", plane)
		_check(Vector2i(_hex.call("round_axial", axial)) == grid, "Plane/axial roundtrip including negative coordinates %s" % str(grid))
	_check(Vector2i(_hex.call("round_axial", Vector2(0.49, 0.49))) != Vector2i.ZERO, "Cube rounding chooses closest physical center near a three-cell boundary")
	var boundaries_valid: bool = true
	for direction_variant in directions:
		var neighbor: Vector2i = Vector2i(direction_variant)
		var plane: Vector2 = _hex.call("axial_to_plane", Vector2(neighbor))
		var inner_axial: Vector2 = _hex.call("plane_to_axial", plane * 0.499)
		var outer_axial: Vector2 = _hex.call("plane_to_axial", plane * 0.501)
		boundaries_valid = boundaries_valid and Vector2i(_hex.call("round_axial", inner_axial)) == Vector2i.ZERO and Vector2i(_hex.call("round_axial", outer_axial)) == neighbor
	_check(boundaries_valid, "All six shared-edge boundaries pick the nearest center on either side")
	var corners: PackedVector2Array = _hex.call("corners")
	var corner_lengths_valid: bool = corners.size() == 6
	for corner in corners:
		corner_lengths_valid = corner_lengths_valid and is_equal_approx(corner.length(), 1.0 / sqrt(3.0))
	_check(corner_lengths_valid, "Pointy hex has six corners at radius 1/sqrt(3)")
	var line: Array = Array(_hex.call("line", Vector2i(-2, 1), Vector2i(3, -2)))
	var reverse_line: Array = Array(_hex.call("line", Vector2i(3, -2), Vector2i(-2, 1)))
	reverse_line.reverse()
	_check(line == reverse_line and line.size() == int(_hex.call("distance", Vector2i(-2, 1), Vector2i(3, -2))) + 1, "Hex line is reversible and has distance+1 centers")
	_check(_valid_hex_path(line), "Every consecutive hex-line cell shares an edge")


func _test_map_registry_paths() -> void:
	var map_data = MAP_SCRIPT.call("create_empty", "hex_fixture", Vector2i(8, 8), Vector2(11, 23), 64.0, 32.0, 3, HEX_TOPOLOGY)
	_check(String(map_data.call("get_grid_topology")) == HEX_TOPOLOGY, "New hex map owns topology")
	var registry = REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2(11, 23), 64.0, 32.0, HEX_TOPOLOGY)
	for tile in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile)
	_check(String(registry.call("get_grid_topology")) == HEX_TOPOLOGY, "Registry exposes same topology")
	var roundtrip_ok: bool = true
	for grid in [Vector2i(0, 0), Vector2i(3, 4), Vector2i(-5, 2), Vector2i(2, -6)]:
		var world: Vector2 = registry.call("grid_to_world", grid)
		roundtrip_ok = roundtrip_ok and Vector2i(registry.call("world_to_grid", world)) == grid
	_check(roundtrip_ok, "Registry projected world/axial roundtrip includes negative coordinates and nonzero origin")
	var pathfinder = PATHFINDER_SCRIPT.new()
	var center := Vector2i(3, 3)
	var center_world: Vector2 = registry.call("grid_to_world", center)
	var neighbors: Array = Array(_hex.call("neighbors", center))
	var equal_costs: bool = true
	var equal_movement: bool = true
	for neighbor_variant in neighbors:
		var neighbor: Vector2i = Vector2i(neighbor_variant)
		equal_costs = equal_costs and is_equal_approx(float(pathfinder.call("get_step_cost", center, neighbor, registry)), 1.0)
		var neighbor_world: Vector2 = registry.call("grid_to_world", neighbor)
		equal_movement = equal_movement and is_equal_approx(float(registry.call("get_movement_distance", center_world, neighbor_world)), sqrt(64.0 * 64.0 + 32.0 * 32.0))
	_check(equal_costs and Array(pathfinder.call("get_neighbor_directions", registry)).size() == 6, "Actual A* has six equal-cost ground edges without square diagonal premium")
	_check(equal_movement, "All six projected neighbor movements share the same physical metric")
	var path: Array = Array(pathfinder.call("find_path", center, Vector2i(4, 4), registry))
	_check(path.size() == 3 and _valid_hex_path(path), "Square (1,1) diagonal requires two actual hex edges")
	var x_block = registry.call("get_tile_at_grid", Vector2i(4, 3))
	var y_block = registry.call("get_tile_at_grid", Vector2i(3, 2))
	x_block.walkable = false
	y_block.walkable = false
	_check(bool(pathfinder.call("can_traverse_step", center, Vector2i(4, 2), registry)), "Legal axial (1,-1) edge does not inherit square corner-cut blocking")
	y_block.walkable = true
	path = Array(pathfinder.call("find_path", center, Vector2i(5, 3), registry))
	_check(path.size() > 3 and not path.has(Vector2i(4, 3)) and _valid_hex_path(path), "A* routes around a blocked hex with legal six-neighbor edges")
	x_block.walkable = true
	var target = registry.call("get_tile_at_grid", Vector2i(4, 2))
	target.height_level = 1
	target.edge_type = "cliff"
	_check(not bool(pathfinder.call("can_traverse_step", center, Vector2i(4, 2), registry)), "Hex cliff blocks height transition")
	target.edge_type = "slope"
	_check(bool(pathfinder.call("can_traverse_step", center, Vector2i(4, 2), registry)) and is_equal_approx(float(pathfinder.call("get_step_cost", center, Vector2i(4, 2), registry)), 2.0), "Hex ramp allows height transition with one height premium and no square diagonal premium")
	target.walkable = false
	_check(not bool(pathfinder.call("can_traverse_step", center, Vector2i(4, 2), registry)), "Blocked hex remains blocked even when slope")
	target.walkable = true
	target.height_level = 0
	target.edge_type = "none"
	var graph = GRAPH_SCRIPT.new()
	_check(bool(graph.call("build_from_registry", registry, 2)), "HPA builds hex cluster graph")
	var hpa = HPA_SCRIPT.new()
	var hpa_path: Array = Array(hpa.call("find_path", Vector2i(1, 1), Vector2i(6, 1), registry, graph))
	var astar_path: Array = Array(pathfinder.call("find_path", Vector2i(1, 1), Vector2i(6, 1), registry))
	var hpa_score: Dictionary = pathfinder.call("score_path", hpa_path, registry)
	var astar_score: Dictionary = pathfinder.call("score_path", astar_path, registry)
	if not is_equal_approx(float(hpa_score.path_cost), float(astar_score.path_cost)):
		print("DIAGNOSTIC HPA=%s cost=%s A*=%s cost=%s" % [str(hpa_path), str(hpa_score.path_cost), str(astar_path), str(astar_score.path_cost)])
	_check(not hpa_path.is_empty() and Vector2i(hpa_path[0]) == Vector2i(1, 1) and Vector2i(hpa_path[-1]) == Vector2i(6, 1) and _valid_hex_path(hpa_path), "HPA path crosses clusters using valid hex edges")
	_check(is_equal_approx(float(hpa_score.path_cost), float(astar_score.path_cost)), "HPA and A* agree on open straight hex-route cost")
	var hpa_blocker = registry.call("get_tile_at_grid", Vector2i(4, 1))
	hpa_blocker.walkable = false
	registry.call("notify_tile_data_changed", [Vector2i(4, 1)])
	graph.call("rebuild_dirty_clusters_from_registry", registry, [Vector2i(4, 1)])
	hpa_path = Array(hpa.call("find_path", Vector2i(1, 1), Vector2i(6, 1), registry, graph))
	_check(not hpa_path.is_empty() and not hpa_path.has(Vector2i(4, 1)) and _valid_hex_path(hpa_path), "Incremental HPA routes around changed blocked hex without square-only edges")
	_check(Array(registry.call("get_grid_line", Vector2i(1, 1), Vector2i(6, 1))) == Array(_hex.call("line", Vector2i(1, 1), Vector2i(6, 1))), "Registry exposes topology-aware hex line")
	var temp_path: String = "user://frontier_hex_roundtrip_%d.json" % Time.get_ticks_usec()
	var marker_center: Vector2 = map_data.call("get_tile_at_grid",Vector2i(1,1)).world_position
	map_data.call("set_marker","precise_hex_center","interaction_door",marker_center)
	_check(int(map_data.call("save_to_file", temp_path)) == OK, "Hex map save succeeds")
	var loaded = MAP_SCRIPT.call("load_from_file", temp_path)
	_check(Vector2(loaded.call("get_marker_position","precise_hex_center")) == marker_center, "Existing Hex foundation roundtrip preserves exact noninteger marker center")
	var preserved_positions: bool = String(loaded.call("get_grid_topology")) == HEX_TOPOLOGY
	for tile in Array(loaded.call("get_tiles")):
		preserved_positions = preserved_positions and Vector2(tile.world_position).is_equal_approx(Vector2(registry.call("grid_to_world", Vector2i(tile.grid_position))))
	_check(preserved_positions and Array(loaded.call("get_tiles")).size() == 64, "Hex topology and all projected positions survive save/load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	registry.free()


func _test_incremental_hex_portal() -> void:
	var registry = REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0, HEX_TOPOLOGY)
	var map_data = MAP_SCRIPT.call("create_empty", "hex_diagonal_portal", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 3, HEX_TOPOLOGY)
	for tile in Array(map_data.call("get_tiles")):
		tile.walkable = Vector2i(tile.grid_position) == Vector2i(1, 2)
		registry.call("register_tile", tile)
	var graph = GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 2)
	var target = registry.call("get_tile_at_grid", Vector2i(2, 1))
	target.walkable = true
	registry.call("notify_tile_data_changed", [Vector2i(2, 1)])
	graph.call("rebuild_dirty_clusters_from_registry", registry, [Vector2i(2, 1)])
	var hpa = HPA_SCRIPT.new()
	var path: Array = Array(hpa.call("find_path", Vector2i(1, 2), Vector2i(2, 1), registry, graph))
	_check(path == [Vector2i(1, 2), Vector2i(2, 1)], "Dirty HPA rebuild discovers a new axial diagonal portal between previously disconnected clusters")
	registry.free()


func _test_legacy() -> void:
	var map_data = MAP_SCRIPT.call("create_empty", "legacy_fixture", Vector2i(8, 8), Vector2.ZERO)
	_check(String(map_data.call("get_grid_topology")) == "square8", "Existing create_empty callers remain square8")
	var registry = REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0)
	for tile in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile)
	_check(Vector2(registry.call("grid_to_world", Vector2i(5, 1))) == Vector2(256, 192), "Legacy isometric positions unchanged")
	var pathfinder = PATHFINDER_SCRIPT.new()
	var first: Array = Array(pathfinder.call("find_path", Vector2i(3, 3), Vector2i(5, 5), registry))
	var second: Array = Array(pathfinder.call("find_path", Vector2i(3, 3), Vector2i(5, 1), registry))
	var score: Dictionary = pathfinder.call("score_path", first, registry)
	_check(first == [Vector2i(3, 3), Vector2i(4, 4), Vector2i(5, 5)] and second == [Vector2i(3, 3), Vector2i(4, 2), Vector2i(5, 1)] and is_equal_approx(float(score.path_cost), 2.0 * sqrt(2.0)), "Both legacy baseline paths and diagonal cost remain unchanged")
	# Station64 is now a productive authored Hex map. Keep this legacy-wire
	# assertion against an actual topology-less file, not that migrated content.
	var legacy_path := "user://frontier_legacy_no_topology_%d.json" % Time.get_ticks_usec()
	var legacy_map = MAP_SCRIPT.call("create_empty", "legacy_wire_fixture", Vector2i(64,64), Vector2.ZERO)
	legacy_map.call("save_to_file", legacy_path)
	var legacy_wire: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(legacy_path))
	legacy_wire.erase("grid_topology")
	legacy_wire.erase("tactical_grid_rules")
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_wire))
	legacy_file.close()
	var old_map = MAP_SCRIPT.call("load_from_file", legacy_path)
	_check(String(old_map.call("get_grid_topology")) == "square8" and Array(old_map.call("get_tiles")).size() == 4096, "Actual legacy wire file without topology loads as square8")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	_check(is_equal_approx(float(registry.call("get_movement_distance", Vector2.ZERO, Vector2(10, 20))), Vector2(10, 20).length()), "Legacy movement metric remains projected world distance")
	registry.free()


func _valid_hex_path(path: Array) -> bool:
	for index in range(1, path.size()):
		if not bool(_hex.call("are_neighbors", Vector2i(path[index - 1]), Vector2i(path[index]))):
			return false
	return not path.is_empty()


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + description)
	else:
		_failed += 1
		print("FAIL: " + description)


func _finish() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("FRONTIER_HEX_FOUNDATION_ALL_PASS" if _failed == 0 else "FRONTIER_HEX_FOUNDATION_FAILED")
	quit(0 if _failed == 0 else 1)
