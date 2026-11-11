extends SceneTree

const MAP = preload("res://scripts/terrain/terrain_map_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var names := OS.get_cmdline_user_args()
	if names.is_empty():
		names = PackedStringArray(["satellite_crash_site", "trade_outpost", "fortified_outpost"])
	var failures := 0
	for name in names:
		var started := Time.get_ticks_msec()
		var map = MAP.load_from_file("res://maps/%s.json" % name)
		var tiles: Array = map.get_tiles()
		var valid: bool = map.get_grid_size() == Vector2i(512, 256) and tiles.size() == 131072
		var min_offset := Vector2i(2147483647, 2147483647)
		var max_offset := -min_offset
		var cells := {}
		for tile in tiles:
			var axial: Vector2i = tile.grid_position
			var offset := Vector2i(axial.x + floori(axial.y * 0.5), axial.y)
			cells[offset] = true
			min_offset = Vector2i(mini(min_offset.x, offset.x), mini(min_offset.y, offset.y))
			max_offset = Vector2i(maxi(max_offset.x, offset.x), maxi(max_offset.y, offset.y))
		valid = valid and cells.size() == 131072 and max_offset - min_offset + Vector2i.ONE == Vector2i(512, 256)
		valid = valid and map.get_grid_topology() == "hex_axial_v1" and not map.has_load_issue()
		print("%s %s cells=%d offset=%s..%s parse_and_validate_ms=%d static_memory=%d" % [
			"PASS" if valid else "FAIL", name, cells.size(), min_offset, max_offset,
			Time.get_ticks_msec() - started, OS.get_static_memory_usage()])
		if not valid:
			failures += 1
	quit(1 if failures else 0)
