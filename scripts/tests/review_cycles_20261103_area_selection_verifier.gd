extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")

# The break: a tiny commander area drag must not visit every map tile; narrowing
# candidates must preserve the old exhaustive center-in-screen-rectangle result.
class CountedTile extends RefCounted:
	var source
	var counts: Dictionary
	var world_position: Vector2:
		get:
			counts["world_reads"] += 1
			return source.world_position
	var grid_position: Vector2i:
		get:
			return source.grid_position
	func _init(tile, counter: Dictionary):
		source = tile
		counts = counter
	func _get(property: StringName) -> Variant:
		return source.get(property)

class CountedView extends "res://scripts/terrain/terrain_map_3d_view.gd":
	var projections: int = 0
	func world_to_screen_position(position: Vector2) -> Vector2:
		projections += 1
		return super.world_to_screen_position(position)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_small_rect_work_is_independent_of_map_area()
	_test_exact_results_match_old_exhaustive_selection()
	print("REVIEW_CYCLES_AREA_SELECTION_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _make_view(map):
	var view := CountedView.new()
	root.add_child(view)
	view.set_process(false)
	view.set("_terrain_map_data", map)
	view.call("_rebuild_render_tile_index", map.get_tiles())
	view.call("_read_map_transform")
	view.call("_update_camera_transform")
	return view


func _test_small_rect_work_is_independent_of_map_area() -> void:
	for side in [128, 256]:
		var map = MAP.create_empty("bounded_area_drag", Vector2i(side, side), Vector2.ZERO)
		var center_tile = map.get_tile_at_grid(Vector2i(side / 2, side / 2))
		var counters: Dictionary = {"world_reads": 0}
		var counted_tiles: Array = []
		for tile in map.get_tiles():
			counted_tiles.append(CountedTile.new(tile, counters))
		map.set("_tiles", counted_tiles)
		var view = _make_view(map)
		var center: Vector2 = view.world_to_screen_position(center_tile.world_position)
		var rect := Rect2(center - Vector2.ONE * 3.0, Vector2.ONE * 6.0)
		var expected: Array = _exhaustive_reference(view, map, rect)
		counters["world_reads"] = 0
		view.projections = 0
		var actual: Array = view.screen_rect_to_tile_world_positions(rect)
		_check(not expected.is_empty(), "%d small rectangle contains a real tile center" % side)
		_check(actual == expected, "%d small rectangle keeps the exhaustive selected centers" % side)
		_check(counters.world_reads <= 256 and view.projections <= 256, "%d small rectangle visits bounded candidates, got %d tile reads / %d projections" % [side, counters.world_reads, view.projections])
		print("AREA_SELECTION_OPERATIONS ", JSON.stringify({"side": side, "tiles": side * side, "selected": actual.size(), "tile_world_reads": counters.world_reads, "projections": view.projections}))
		view.free()


func _test_exact_results_match_old_exhaustive_selection() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		var map = MAP.create_empty("area_height_oracle", Vector2i(9, 8), Vector2(80, -40), 64.0, 32.0, 3, topology)
		for tile in map.get_tiles():
			tile.height_level = (tile.grid_position.x + 2 * tile.grid_position.y) % 3
		# Preserve loaded source ordering, rather than accidentally sorting by grid.
		var reversed_tiles: Array = map.get_tiles()
		reversed_tiles.reverse()
		map.set("_tiles", reversed_tiles)
		var view = _make_view(map)
		for yaw in [0.0, 45.0, 140.0, 255.0]:
			view.set("_camera_yaw_degrees", yaw)
			view.call("_update_camera_transform")
			var rectangles: Array[Rect2] = [
				Rect2(Vector2(-100000, -100000), Vector2(200000, 200000)),
				Rect2(Vector2(-100000, -100000), Vector2(10, 10)),
				Rect2(Vector2(10, 10), Vector2.ZERO),
			]
			for tile in map.get_tiles():
				var center: Vector2 = view.world_to_screen_position(tile.world_position)
				# Exact left/top and right/bottom boundaries retain Rect2.has_point.
				rectangles.append(Rect2(center, Vector2(40, 35)))
				rectangles.append(Rect2(center - Vector2(40, 35), Vector2(40, 35)))
				rectangles.append(Rect2(center - Vector2(14, 9), Vector2(28, 18)))
			var mismatches: int = 0
			for rect in rectangles:
				if view.screen_rect_to_tile_world_positions(rect) != _exhaustive_reference(view, map, rect):
					mismatches += 1
			_check(mismatches == 0, "%s yaw %.0f preserves height, boundary, empty, outside and source-order selection (%d mismatches)" % [topology, yaw, mismatches])
		var edited_tile = map.get_tile_at_grid(Vector2i(4, 4))
		edited_tile.height_level = 2
		var edited_center: Vector2 = view.world_to_screen_position(edited_tile.world_position)
		var edited_rect := Rect2(edited_center - Vector2(3, 3), Vector2(6, 6))
		_check(view.screen_rect_to_tile_world_positions(edited_rect) == _exhaustive_reference(view, map, edited_rect), "%s area selection reads an in-place height edit" % topology)
		var all_rect := Rect2(Vector2(-100000, -100000), Vector2(200000, 200000))
		_check(view.screen_rect_to_tile_world_positions(all_rect).size() == 72, "%s whole-map drag keeps all 72 tile centers" % topology)
		view.free()


# Frozen original algorithm: exhaustive iteration, surface-aware projection and
# Rect2.has_point in source order. It does not use candidate helpers under test.
func _exhaustive_reference(view, map, rect: Rect2) -> Array:
	var result: Array = []
	for tile in map.get_tiles():
		if tile == null or typeof(tile.world_position) != TYPE_VECTOR2:
			continue
		if rect.has_point(view.world_to_screen_position(tile.world_position)):
			result.append(tile.world_position)
	return result


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
