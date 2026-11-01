extends SceneTree

const LOS_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const FOW_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const SIX_AXES: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Frontier Hex Visibility ===")
	_test_hex_axis_blockers_and_runtime_overrides()
	_test_hex_off_axis_line_and_endpoint_symmetry()
	_test_hex_range_is_physical_in_all_six_directions()
	_test_hex_fow_range_and_occlusion()
	_test_hex_dirty_axial_extent_matches_full_scan()
	_test_square_range_lines_and_wall_segments_are_unchanged()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_hex_axis_blockers_and_runtime_overrides() -> void:
	var registry: Node = _registry("hex_axial_v1", 4)
	var los = LOS_SCRIPT.new()
	for axis in SIX_AXES:
		var blocker = registry.call("get_tile_at_grid", axis)
		blocker.blocks_los = true
		blocker.object_height = 2
		_assert(not _los(los, registry, Vector2i.ZERO, axis * 3), "Hex axis %s blocks on its intermediate cell" % axis)
		_assert(not _los(los, registry, axis * 3, Vector2i.ZERO), "Hex axis %s blocks symmetrically in reverse" % axis)
		registry.call("set_runtime_tile_overrides", [{"grid_position": axis, "blocks_los_override": false}])
		_assert(_los(los, registry, Vector2i.ZERO, axis * 3), "Hex axis %s honors the authoritative runtime blocker override" % axis)
		registry.call("clear_runtime_tile_overrides")
		blocker.blocks_los = false
		blocker.object_height = 0
	registry.free()


func _test_hex_off_axis_line_and_endpoint_symmetry() -> void:
	var registry: Node = _registry("hex_axial_v1", 4)
	var los = LOS_SCRIPT.new()
	# Hand checked axial centre line: (0,0),(1,0),(1,1),(2,1),(2,2).
	# The old square interpolation skips (1,0) and (2,1).
	var blocker = registry.call("get_tile_at_grid", Vector2i(1, 0))
	blocker.blocks_los = true
	blocker.object_height = 2
	_assert(not _los(los, registry, Vector2i.ZERO, Vector2i(2, 2)), "Hex off-axis line visits the first literal intermediate hex")
	_assert(not _los(los, registry, Vector2i(2, 2), Vector2i.ZERO), "Hex off-axis blocker is symmetric at an edge tie")
	blocker.blocks_los = false
	var outside = registry.call("get_tile_at_grid", Vector2i(0, 1))
	outside.blocks_los = true
	outside.object_height = 2
	_assert(_los(los, registry, Vector2i.ZERO, Vector2i(2, 2)), "A hex outside that centre line does not block it")
	_assert(_los(los, registry, Vector2i(2, 2), Vector2i.ZERO), "The clear off-axis line also remains symmetric")
	outside.blocks_los = false
	var endpoint = registry.call("get_tile_at_grid", Vector2i(2, 2))
	endpoint.blocks_los = true
	endpoint.object_height = 3
	_assert(_los(los, registry, Vector2i.ZERO, Vector2i(2, 2)), "Target-cell occupancy does not self-occlude")
	_assert(_los(los, registry, Vector2i(2, 2), Vector2i.ZERO), "Source-cell occupancy does not self-occlude")
	endpoint.blocks_los = false
	blocker.blocks_los = true
	blocker.object_height = 0
	registry.call("get_tile_at_grid", Vector2i.ZERO).height_level = 2
	registry.call("get_tile_at_grid", Vector2i(2, 2)).height_level = 2
	_assert(_los(los, registry, Vector2i.ZERO, Vector2i(2, 2)), "Hex line preserves the existing blocker-height comparison")
	# Four-edge legacy wall descriptors are not six-edge hex wall geometry.
	# Until authored hex edges exist, an explicit blocking wall occupies its cell.
	var wall = registry.call("get_tile_at_grid", Vector2i(0, 1))
	wall.type_id = "wall_straight_ne"
	wall.blocks_los = true
	wall.object_height = 2
	_assert(not _los(los, registry, Vector2i.ZERO, Vector2i(0, 3)), "Hex blocking wall never silently applies square-edge segment geometry")
	registry.free()


func _test_hex_range_is_physical_in_all_six_directions() -> void:
	var registry: Node = _registry("hex_axial_v1", 2)
	var los = LOS_SCRIPT.new()
	# Adjacent centres are sqrt(16^2+8^2)=17.88854 physical world units.
	for axis in SIX_AXES:
		_assert(_los(los, registry, Vector2i.ZERO, axis, 18.0), "Hex neighbor %s is inside the same physical sight range" % axis)
		_assert(not _los(los, registry, Vector2i.ZERO, axis, 17.0), "Hex neighbor %s is outside the same shorter sight range" % axis)
	registry.free()


func _test_hex_fow_range_and_occlusion() -> void:
	var registry: Node = _registry("hex_axial_v1", 4)
	var observer := Node2D.new()
	observer.position = registry.call("grid_to_world", Vector2i.ZERO)
	var los = LOS_SCRIPT.new()
	for use_los in [false, true]:
		var fow = FOW_SCRIPT.new()
		fow.call("set_mode_for_team", "alpha", "unexplored_blackout")
		fow.call("update_tile_visibility_for_team", "alpha", [observer], registry, los if use_los else null, 18.0)
		for axis in SIX_AXES:
			_assert(bool(fow.call("is_tile_currently_visible", "alpha", _id(axis))), "FoW%s sees all six physical neighbors: %s" % ["+LOS" if use_los else "", axis])
		fow.call("update_tile_visibility_for_team", "alpha", [observer], registry, los if use_los else null, 17.0)
		for axis in SIX_AXES:
			_assert(not bool(fow.call("is_tile_currently_visible", "alpha", _id(axis))), "FoW%s excludes all six neighbors below physical range: %s" % ["+LOS" if use_los else "", axis])
	var blocker = registry.call("get_tile_at_grid", Vector2i(1, 0))
	blocker.blocks_los = true
	blocker.object_height = 2
	var fow = FOW_SCRIPT.new()
	fow.call("set_mode_for_team", "alpha", "unexplored_blackout")
	fow.call("update_tile_visibility_for_team", "alpha", [observer], registry, los, 100.0)
	_assert(not bool(fow.call("is_tile_currently_visible", "alpha", _id(Vector2i(2, 2)))), "FoW consumes actual hex LOS occlusion on an off-axis target")
	observer.free()
	registry.free()


func _test_hex_dirty_axial_extent_matches_full_scan() -> void:
	# Sparse real registry: the target enters range after one cell of movement.
	# Its q extent is greater than the physical radius because axial axes are 60deg.
	var registry: Node = REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 16.0, 16.0, "hex_axial_v1")
	for grid in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(47, -24)]:
		_register_tile(registry, grid)
	var observer := Node2D.new()
	observer.position = registry.call("grid_to_world", Vector2i.ZERO)
	var range_world: float = 39.9 * sqrt(512.0)
	var dirty = FOW_SCRIPT.new()
	dirty.call("set_mode_for_team", "alpha", "unexplored_blackout")
	dirty.call("update_tile_visibility_for_team", "alpha", [observer], registry, null, range_world)
	_assert(not bool(dirty.call("is_tile_currently_visible", "alpha", _id(Vector2i(47, -24)))), "Sparse far axial cell starts outside the physical circle")
	observer.position = registry.call("grid_to_world", Vector2i(1, 0))
	var request: Dictionary = dirty.call("request_tile_visibility_update_for_team", "alpha", [observer], registry, null, range_world, {"work_budget_tiles": 128})
	_assert(not bool(request.get("full_scan", true)), "Hex observer movement retains the dirty-region work route")
	var work: Dictionary = {}
	var slices: int = 0
	while not bool(work.get("completed", false)) and slices < 2048:
		work = dirty.call("process_pending_tile_visibility_work", "alpha", 128)
		slices += 1
	_assert(bool(work.get("completed", false)), "Hex dirty work completes within the bounded fixture")
	var oracle = FOW_SCRIPT.new()
	oracle.call("set_mode_for_team", "alpha", "unexplored_blackout")
	oracle.call("update_tile_visibility_for_team", "alpha", [observer], registry, null, range_world)
	_assert(bool(oracle.call("is_tile_currently_visible", "alpha", _id(Vector2i(47, -24)))), "Hand-derived axial target enters the physical sight circle")
	_assert(bool(dirty.call("is_tile_currently_visible", "alpha", _id(Vector2i(47, -24)))), "Dirty candidate bounds include the wider axial q/r extents")
	for grid in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(47, -24)]:
		_assert(dirty.call("is_tile_currently_visible", "alpha", _id(grid)) == oracle.call("is_tile_currently_visible", "alpha", _id(grid)), "Hex dirty result equals full-scan visibility for %s" % grid)
	observer.free()
	registry.free()


func _test_square_range_lines_and_wall_segments_are_unchanged() -> void:
	var registry: Node = _registry("square8", 4)
	var los = LOS_SCRIPT.new()
	var blocker = registry.call("get_tile_at_grid", Vector2i(1, 0))
	blocker.blocks_los = true
	blocker.object_height = 2
	_assert(_los(los, registry, Vector2i.ZERO, Vector2i(2, 2)), "Square centre line keeps its old diagonal cells")
	blocker.blocks_los = false
	_assert(_los(los, registry, Vector2i.ZERO, Vector2i(1, 1), 18.0), "Square projected short diagonal keeps its previous range result")
	_assert(not _los(los, registry, Vector2i.ZERO, Vector2i(1, -1), 18.0), "Square projected long diagonal keeps its previous range result")
	var wall = registry.call("get_tile_at_grid", Vector2i(2, 1))
	wall.type_id = "wall_straight_ne"
	wall.blocks_los = true
	wall.object_height = 2
	_assert(not _los(los, registry, Vector2i(1, 1), Vector2i(3, 1)), "Square wall segment still blocks across its edge")
	_assert(_los(los, registry, Vector2i(2, 0), Vector2i(2, 2)), "Square wall segment still permits sight on the same side")
	registry.free()


func _los(los, registry: Node, source: Vector2i, target: Vector2i, max_range: float = -1.0) -> bool:
	return bool(los.call("has_line_of_sight_between_points", registry.call("grid_to_world", source), registry.call("grid_to_world", target), max_range, registry))


func _registry(topology: String, extent: int) -> Node:
	var registry: Node = REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 16.0, 8.0, topology)
	for q in range(-extent, extent + 1):
		for r in range(-extent, extent + 1):
			_register_tile(registry, Vector2i(q, r))
	return registry


func _register_tile(registry: Node, grid: Vector2i) -> void:
	registry.call("register_tile", TILE_SCRIPT.call("from_dict", {
		"tile_id": _id(grid), "type_id": "ground_flat", "grid_position": grid,
		"world_position": registry.call("grid_to_world", grid), "height_level": 0,
		"blocks_los": false, "object_height": 0, "walkable": true,
	}))


func _id(grid: Vector2i) -> String:
	return "tile_%d_%d" % [grid.x, grid.y]


func _assert(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: "+description)
	else:
		_failed += 1
		push_error("FAIL: "+description)
