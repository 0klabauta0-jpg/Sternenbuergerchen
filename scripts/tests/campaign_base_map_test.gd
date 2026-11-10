extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var file := "res://maps/campaign_intro_base.json"
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
	var layout: Dictionary = raw.homebase_exploration
	var map = MAP.load_from_file(file)
	_check(not map.has_load_issue() and map.get_grid_topology() == "hex_axial_v1", "Mini base loads valid native hex data")
	_check(raw.grid_size.x >= 96 and raw.grid_size.y >= 98 and layout.interiors.size() == 2 and layout.landing_pads.size() == 2, "Campaign retains larger base, both building areas and both pads")
	var registry = REGISTRY.new()
	root.add_child(registry)
	var sizes: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), sizes.half_width, sizes.half_height, map.get_grid_topology())
	for tile in map.get_tiles():
		registry.register_tile(tile)
	var start := Vector2i(int(layout.avatar_spawn_grid[0]), int(layout.avatar_spawn_grid[1]))
	for terminal: Dictionary in layout.terminals:
		var target := Vector2i(int(terminal.grid[0]), int(terminal.grid[1]))
		_check(start == target or not PATH.new().find_path(start, target, registry).is_empty(), "Commander can reach terminal " + String(terminal.id))
	var pad: Dictionary = layout.landing_pads[0]
	_check(String(pad.id) == "homebase_pad_01" and not PATH.new().find_path(start, Vector2i(int(pad.grid[0]), int(pad.grid[1])), registry).is_empty(), "Real campaign pad identity is reachable")
	registry.queue_free()
	await process_frame
	print("CAMPAIGN_BASE failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
