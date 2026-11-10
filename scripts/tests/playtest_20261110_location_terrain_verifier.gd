extends SceneTree
var failed := 0
func _init() -> void: call_deferred("_run")
func _run() -> void:
	for file in ["campaign_intro_base", "homebase_frontier_exploration", "satellite_crash_site", "trade_outpost"]:
		var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/"+file+".json")
		_check(not map.has_load_issue(), file+" loads authored hex map")
		_check(map.get_tiles().size() >= 9000, file+" is an extensive place rather than a tiny isolated board")
		var registry: Node = load("res://scripts/terrain/terrain_registry.gd").new()
		registry.configure_iso_grid(map.get_grid_origin(),64,32,map.get_grid_topology())
		var negative_free := false
		var former_edge_free := false
		for tile in map.get_tiles():
			registry.register_tile(tile)
			if tile.grid_position.x < -10 and tile.grid_position.y < -10 and tile.walkable: negative_free = true
			if tile.grid_position == Vector2i(0,8) and tile.walkable: former_edge_free = true
		_check(negative_free and former_edge_free, file+" has reachable surrounding terrain, without old block fence")
		var valid_sites := 0
		for grid in [Vector2i(5,5),Vector2i(15,15),Vector2i(-10,-10),Vector2i(30,30)]:
			if bool(load("res://scripts/mission/field_landing_contract.gd").validate(registry,grid,[]).ok): valid_sites += 1
		_check(valid_sites >= 2, file+" offers separated safe landing areas")
		registry.free()
	print("LOCATION_TERRAIN failed=",failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value: failed += 1
	print("PASS: " if value else "FAIL: ", label)
