extends SceneTree

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", description)

func run() -> void:
	var view = VIEW.new()
	root.add_child(view)
	check(view.has_method("set_frontier_art_enabled"), "explicit reversible art profile entry point exists")
	if not view.has_method("set_frontier_art_enabled"):
		view.queue_free()
		await process_frame
		print("FRONTIER_ART_RESULT ", JSON.stringify({"passed":passed,"failed":failed}))
		quit(1)
		return
	var map_data = MAP.create_empty("frontier_profile_verifier", Vector2i(8,8), Vector2.ZERO)
	var registry = REGISTRY.new()
	root.add_child(registry)
	for tile in map_data.get_tiles():
		registry.register_tile(tile)
	var pathfinder = PATHFINDER.new()
	var before_path: Array = pathfinder.find_path(Vector2i(0,0),Vector2i(7,7),registry)
	var before_tiles: Array = []
	for tile in map_data.get_tiles():
		before_tiles.append(tile.to_dict())
	var before_revision: int = registry.get_revision()
	view.configure_from_map(map_data)
	view.set_frontier_art_enabled(true)
	var active: Dictionary = view.get_render_snapshot()
	check(active.get("frontier_art_enabled", false), "profile reports enabled")
	check(not active.get("creates_navigation", true), "render layer creates no navigation")
	check(not active.get("creates_movement", true), "render layer creates no movement")
	check(int(active.get("tile_count", 0)) == 64, "all source tiles remain rendered")
	check(active.get("frontier_art_profile_id", "") == "frontier_illustrated_v1", "approved art family identified")
	check(before_path == pathfinder.find_path(Vector2i(0,0),Vector2i(7,7),registry), "path preserved with profile active")
	check(before_revision == registry.get_revision(), "registry revision unchanged")
	var after_tiles: Array = []
	for tile in map_data.get_tiles():
		after_tiles.append(tile.to_dict())
	check(before_tiles == after_tiles, "all serialized terrain facts unchanged")
	view.set_frontier_art_enabled(false)
	check(not view.get_render_snapshot().get("frontier_art_enabled", true), "profile turns off")
	check(before_path == pathfinder.find_path(Vector2i(0,0),Vector2i(7,7),registry), "path preserved after restoring baseline")
	view.queue_free()
	registry.queue_free()
	await process_frame
	print("FRONTIER_ART_RESULT ", JSON.stringify({"passed":passed,"failed":failed}))
	quit(1 if failed else 0)
