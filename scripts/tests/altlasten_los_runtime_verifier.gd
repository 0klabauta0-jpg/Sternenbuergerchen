extends SceneTree

const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const NONE = Vector2i(2147483647, 2147483647)
var failed := 0
var passed := 0

class DisplayProbe extends VIEW:
	var rebuilds := 0
	func _rebuild_order_visuals() -> void: rebuilds += 1
	func _request_viewport_redraw(_continuous: bool = false, _duration: int = 0) -> void: pass


func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		_test_door(topology)
	_test_map_only_edits()
	_test_stationary_display_refresh()
	_test_sparse_endpoint_height()
	_test_endpoint_and_expired_registry()
	print("ALTLASTEN_LOS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _test_door(topology: String) -> void:
	var map = MAP.create_empty("LOS regression", Vector2i(5, 3), Vector2.ZERO, 64.0, 32.0, 3)
	map.set("_grid_topology", topology)
	var door = map.get_tile_at_grid(Vector2i(2, 1))
	door.blocks_los = true
	door.object_height = 2
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, topology)
	for tile in map.get_tiles(): registry.register_tile(tile)
	var view = VIEW.new()
	view.set("_terrain_map_data", map)
	check(view.has_method("set_runtime_terrain_registry"), "explicit runtime registry binding")
	if view.has_method("set_runtime_terrain_registry"):
		view.call("set_runtime_terrain_registry", registry)
	var los = LOS.new()
	var a: Vector2 = map.get_tile_at_grid(Vector2i(0, 1)).world_position
	var b: Vector2 = map.get_tile_at_grid(Vector2i(4, 1)).world_position
	# Registry world coordinates for the fixture must match the selected topology.
	if topology == "hex_axial_v1":
		for tile in map.get_tiles(): tile.world_position = registry.grid_to_world(tile.grid_position)
		a = registry.grid_to_world(Vector2i(0, 1))
		b = registry.grid_to_world(Vector2i(4, 1))
	check(_blocker(view) == Vector2i(2, 1), "%s authored closed door visible" % topology)
	check(not los.has_line_of_sight_between_points(a, b, -1.0, registry), "%s runtime initially blocked" % topology)
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(2, 1), "blocks_los_override": false, "object_height_override": 0, "walkable_override": true}])
	var revision: int = registry.get_revision()
	check(los.has_line_of_sight_between_points(a, b, -1.0, registry), "%s runtime opened" % topology)
	check(_blocker(view) == NONE, "%s warmed display cache observes opened door" % topology)
	check(_blocker(view) == NONE and registry.get_revision() == revision, "%s repeated display read is pure" % topology)
	registry.clear_runtime_tile_overrides()
	check(_blocker(view) == Vector2i(2, 1), "%s warmed display observes reclosed door" % topology)
	var replacement = REGISTRY.new()
	replacement.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, topology)
	for tile in map.get_tiles(): replacement.register_tile(tile)
	replacement.set_runtime_tile_overrides([{"grid_position": Vector2i(2, 1), "blocks_los_override": false, "object_height_override": 0, "walkable_override": true}])
	if view.has_method("set_runtime_terrain_registry"): view.call("set_runtime_terrain_registry", replacement)
	check(_blocker(view) == NONE, "%s replacement registry cannot reuse old blocker" % topology)
	check(door.blocks_los and door.object_height == 2, "%s display did not mutate authored door" % topology)
	view.free()
	registry.free()
	replacement.free()

func _blocker(view: Node) -> Vector2i:
	return view.call("_find_fire_sector_los_blocker_grid_cached", Vector2i(0, 1), Vector2i(4, 1))

func _test_map_only_edits() -> void:
	var map = MAP.create_empty("Editor LOS", Vector2i(5, 3), Vector2.ZERO, 64.0, 32.0, 3)
	var view = VIEW.new()
	view.set("_terrain_map_data", map)
	check(_blocker(view) == NONE, "map-only authoring starts clear")
	var tile = map.get_tile_at_grid(Vector2i(2, 1))
	tile.blocks_los = true
	tile.object_height = 2
	check(_blocker(view) == Vector2i(2, 1), "map-only authoring edit cannot reuse stale cache")
	view.free()

func _test_stationary_display_refresh() -> void:
	var registry = REGISTRY.new()
	var view = DisplayProbe.new()
	var order_root := Node3D.new()
	view.set("_order_root", order_root)
	view.set("_order_payload", {"fire_sector_overlay_enabled": true, "selected_fireteam_ids": PackedStringArray(["ft1"])})
	if view.has_method("set_runtime_terrain_registry"): view.call("set_runtime_terrain_registry", registry)
	view.set("_last_dynamic_order_visual_refresh_msec", -10000)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var first: int = view.rebuilds
	view.set("_last_dynamic_order_visual_refresh_msec", -10000)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	check(first > 0 and view.rebuilds == first, "unchanged stationary display does not rebuild")
	registry.set_runtime_tile_overrides([])
	view.set("_last_dynamic_order_visual_refresh_msec", -10000)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	check(view.rebuilds == first + 1, "terrain revision refreshes stationary display without a new order")
	view.set("_order_root", null)
	order_root.free()
	view.free()
	registry.free()

func _test_sparse_endpoint_height() -> void:
	var map = MAP.create_empty("Sparse endpoint", Vector2i(4, 1), Vector2.ZERO, 64.0, 32.0, 3)
	map.get_tile_at_grid(Vector2i(0, 0)).height_level = 3
	var blocker = map.get_tile_at_grid(Vector2i(1, 0))
	blocker.blocks_los = true
	blocker.object_height = 2
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 0)]: registry.register_tile(map.get_tile_at_grid(grid))
	var a: Vector2 = registry.grid_to_world(Vector2i(-1, 0))
	var b: Vector2 = registry.grid_to_world(Vector2i(3, 0))
	check(LOS.new().has_line_of_sight_between_points(a, b, -1.0, registry), "sparse endpoint retains nearest-tile runtime height")
	registry.free()

func _test_endpoint_and_expired_registry() -> void:
	var map = MAP.create_empty("Endpoint/expiry", Vector2i(3, 1), Vector2.ZERO, 64.0, 32.0, 3)
	var target := Vector2i(2, 0)
	map.get_tile_at_grid(target).blocks_los = true
	map.get_tile_at_grid(target).object_height = 2
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for tile in map.get_tiles(): registry.register_tile(tile)
	var view = VIEW.new()
	view.set("_terrain_map_data", map)
	view.call("set_runtime_terrain_registry", registry)
	var los = LOS.new()
	var a: Vector2 = registry.grid_to_world(Vector2i.ZERO)
	var b: Vector2 = registry.grid_to_world(target)
	check(los.has_line_of_sight_between_points(a, b, -1.0, registry), "runtime excludes a target's own blocker cell")
	check(los.has_line_of_sight_between_points(b, b, -1.0, registry), "runtime same-cell sight keeps its endpoint semantics")
	check(view.call("_find_fire_sector_los_blocker_grid_cached", Vector2i.ZERO, target) == target, "preview clips at an unoccupied blocked endpoint")
	registry.set_runtime_tile_overrides([{"grid_position": target, "blocks_los_override": false}])
	check(view.call("_find_fire_sector_los_blocker_grid_cached", Vector2i.ZERO, target) == NONE, "preview endpoint respects runtime override")
	registry.free()
	check(view.call("_find_fire_sector_los_blocker_grid_cached", Vector2i.ZERO, target) == target, "expired registry drops cached override and reads map fallback")
	view.free()
