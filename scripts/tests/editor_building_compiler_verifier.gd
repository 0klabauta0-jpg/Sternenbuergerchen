extends SceneTree
const IMPORTER=preload("res://scripts/editor/map_builder_scene_importer.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var failed:=0
	var importer=IMPORTER.new()
	var result: Dictionary=importer.build_map_from_authoring({"grid_size":Vector2i(16,16),"placements":[{"type_id":"frontier_hall_exterior","grid_position":Vector2i(8,8)}]})
	if not result.ok: failed+=1; print("FAIL: compiler accepts safe multi-cell building")
	else:
		var map=result.map_data
		if Array(map.get_place_presentation().get("props",[])).size()!=1: failed+=1
		if map.get_tile_at_grid(Vector2i(8,8)).walkable or map.get_tile_at_grid(Vector2i(9,8)).walkable: failed+=1
	for placements in [
		[{"type_id":"frontier_hall_exterior","grid_position":Vector2i(8,8)},{"type_id":"station_wall","grid_position":Vector2i(9,8)}],
		[{"type_id":"frontier_hall_exterior","grid_position":Vector2i(0,0)}],
		[{"type_id":"factory_building_a","grid_position":Vector2i(8,8)}]]:
		var rejected: Dictionary=importer.build_map_from_authoring({"grid_size":Vector2i(16,16),"placements":placements})
		if rejected.ok: failed+=1; print("FAIL: unsafe compiler placement accepted")
	print("EDITOR_BUILDING_COMPILER failed=",failed); quit(1 if failed else 0)
