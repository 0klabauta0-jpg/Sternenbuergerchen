extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")

# Detects a return to linear TerrainMapData lookups in the real idle-frame path.
class CountedTile extends RefCounted:
	var source
	var counts: Dictionary
	var grid_position: Vector2i:
		get:
			counts["grid_reads"] += 1
			return source.grid_position
	func _init(tile, counter: Dictionary):
		source = tile
		counts = counter
	func _get(property: StringName) -> Variant:
		return source.get(property)

class ProbeView extends "res://scripts/terrain/terrain_map_3d_view.gd":
	func _create_unit_proxy(_unit: Node) -> Node3D:
		return Node3D.new()

class ProbeUnit extends Node2D:
	var unit_id: String
	func get_unit_id() -> String:
		return unit_id
	func get_team_id() -> String:
		return "team_alpha"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_real_idle_process_is_independent_of_map_area()
	_test_live_height_edits_and_map_replacement()
	print("REVIEW2_P2_HEIGHT_LOOKUP_RESULT ", JSON.stringify({"passed": _passed, "failed": _failed}))
	if _failed == 0:
		print("REVIEW2_P2_HEIGHT_LOOKUP_PASSED")
	quit(1 if _failed > 0 else 0)


func _test_real_idle_process_is_independent_of_map_area() -> void:
	for side in [128, 256]:
		var map = MAP.create_empty("review2_height", Vector2i(side, side), Vector2.ZERO)
		var counts: Dictionary = {"grid_reads": 0}
		var tiles: Array = []
		for source in map.get_tiles():
			var tile := CountedTile.new(source, counts)
			tiles.append(tile)
		map.set("_tiles", tiles)
		var view := ProbeView.new()
		root.add_child(view)
		view.set_process(false)
		view.set("_terrain_map_data", map)
		view.call("_rebuild_render_tile_index", tiles)
		view.call("_read_map_transform")
		view.set("_focus_grid_position", Vector2(side - 1, side - 1))
		view.set("_camera_size", 22.0)
		var visible_tiles: Array = view.call("_select_tiles_for_visual_render", tiles)
		view.call("_update_camera_transform")
		view.set("_visual_streaming_refresh_queued", false)
		var units: Array = []
		for number in range(12):
			var unit := ProbeUnit.new()
			unit.unit_id = "height_probe_%d" % number
			root.add_child(unit)
			unit.position = map.call("_grid_to_world", Vector2i(side / 2 - number % 3, side / 2 - number / 3))
			units.append(unit)
		view.set_unit_nodes(units)
		for _frame in range(3):
			view.call("_process", 1.0 / 60.0)
		counts["grid_reads"] = 0
		view.call("_process", 1.0 / 60.0)
		var reads: int = counts["grid_reads"]
		print("HEIGHT_IDLE_OPERATIONS ", JSON.stringify({"side": side, "tiles": tiles.size(), "visual_tiles": visible_tiles.size(), "units": units.size(), "tile_grid_reads": reads}))
		_assert(visible_tiles.size() < tiles.size(), "%d map uses a partial visual set" % side)
		_assert(reads <= 120, "%d map's 12 idle units use at most constant work, got %d tile checks" % [side, reads])
		for unit in units:
			unit.free()
		view.free()


func _test_live_height_edits_and_map_replacement() -> void:
	var map = MAP.create_empty("height_original", Vector2i(3, 3), Vector2.ZERO)
	var tile = map.get_tile_at_grid(Vector2i(2, 2))
	tile.height_level = 1
	var view = VIEW.new()
	root.add_child(view)
	view.set_process(false)
	view.configure_from_map(map)
	_assert(is_equal_approx(float(view.call("_get_grid_surface_y", Vector2i(2, 2))), 0.5), "Configured map supplies its H1 surface")
	tile.height_level = 2
	_assert(is_equal_approx(float(view.call("_get_grid_surface_y", Vector2i(2, 2))), 1.0), "In-place height edit is visible without a copied height cache")
	var replacement = MAP.create_empty("height_replacement", Vector2i(2, 2), Vector2(50, 40))
	replacement.get_tile_at_grid(Vector2i(1, 1)).height_level = 2
	view.configure_from_map(replacement)
	_assert(is_zero_approx(float(view.call("_get_grid_surface_y", Vector2i(2, 2)))), "Map replacement discards tiles absent from the new map")
	_assert(is_equal_approx(float(view.call("_get_grid_surface_y", Vector2i(1, 1))), 1.0), "Map replacement supplies new tile heights")
	view.configure_from_map(null)
	_assert(is_zero_approx(float(view.call("_get_grid_surface_y", Vector2i(1, 1)))), "Clearing the map discards its height index")
	view.free()


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
