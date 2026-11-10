extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/base_interior_navigation.json")
	var tile = map.get_tiles().back()
	var start := Time.get_ticks_usec()
	var same := true
	for index in range(2000): same = same and map.get_tile_at_grid(tile.grid_position) == tile
	var milliseconds := (Time.get_ticks_usec()-start)/1000.0
	var passed: bool = same and milliseconds < 250.0
	print("TERRAIN_LOOKUP milliseconds=",milliseconds," passed=",passed)
	quit(0 if passed else 1)
