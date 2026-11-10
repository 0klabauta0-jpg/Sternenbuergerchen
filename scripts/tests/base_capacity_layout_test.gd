extends SceneTree
var failures := 0
var checks := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _run() -> void:
	var nav_script = load("res://scripts/meta/base_interior_navigation.gd")
	var helper = load("res://scripts/meta/base_capacity_layout.gd")
	var terrain = load("res://scripts/terrain/terrain_registry.gd").new()
	root.add_child(terrain)
	var map_data = nav_script.load_map("res://maps/campaign_intro_base.json")
	var tile_size: Dictionary = map_data.get_tile_size()
	terrain.configure_iso_grid(map_data.get_grid_origin(),tile_size.half_width,tile_size.half_height,map_data.get_grid_topology())
	for tile in map_data.get_tiles(): terrain.register_tile(tile)
	var nav = nav_script.new()
	nav.configure_graph(terrain)
	var source: Dictionary = nav_script.layout("res://maps/campaign_intro_base.json")
	for spec in [[8,3],[20,5],[30,6],[4,2]]:
		var expanded: Dictionary = helper.expand(source,terrain,nav,int(spec[0]),{"beds":spec[0],"pads":spec[1]})
		check(expanded.beds.size() == int(spec[0]),"Exact bed capacity %d" % int(spec[0]))
		check(expanded.landing_pads.size() == int(spec[1]),"Exact pad capacity %d" % int(spec[1]))
		check(expanded.beds[0] == source.beds[0] and expanded.beds[1] == source.beds[1],"Furnished beds preserved")
		var origin: Vector2 = terrain.grid_to_world(Vector2i(int(source.avatar_spawn_grid[0]),int(source.avatar_spawn_grid[1])))
		var coords := {}
		for entry: Dictionary in expanded.beds + expanded.landing_pads:
			var grid := Vector2i(int(entry.grid[0]),int(entry.grid[1]))
			check(not coords.has(grid),"No overlapping approach positions")
			coords[grid] = true
			check(not nav.find_world_path(origin,terrain.grid_to_world(grid)).is_empty(),"Actual navigation reaches " + String(entry.id))
	check(source.beds.size() == 2 and source.landing_pads.size() == 2,"Source layout not mutated")
	terrain.free()
	print("Base capacity: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
