extends SceneTree
var failed:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var map=load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/satellite_crash_site.json")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	var site: Dictionary=data.satellite_crash.freighter_wreck_01
	var stage:=Node3D.new(); root.add_child(stage)
	var visual: Node3D=load("res://scripts/terrain/location_resource_visuals.gd").build(site); stage.add_child(visual)
	var origin: Vector2=load("res://scripts/terrain/hex_grid.gd").axial_to_plane(Vector2(site.grid[0],site.grid[1])); visual.position=Vector3(origin.x,0,origin.y)
	var bounds: AABB=load("res://scripts/terrain/place_reference_dressing.gd").mesh_bounds(visual,stage)
	var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(.58)
	var covered:=0; var missing:=0
	for tile in map.get_tiles():
		var point: Vector2=load("res://scripts/terrain/hex_grid.gd").axial_to_plane(Vector2(tile.grid_position))
		if footprint.has_point(point):
			covered+=1
			if tile.walkable or not tile.blocks_los: missing+=1
	check(covered>50 and missing==0,"actual current-model wreck has matching saved movement and sight blockers")
	var registry: Node=load("res://scripts/terrain/terrain_registry.gd").new(); registry.configure_iso_grid(map.get_grid_origin(),64,32,map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var nav=load("res://scripts/meta/base_interior_navigation.gd").new(); nav.configure_graph(registry)
	for item: Dictionary in data.satellite_crash.values():
		var position: Vector2=registry.grid_to_world(Vector2i(item.grid[0],item.grid[1]))
		check(registry.is_walkable(registry.world_to_grid(position)) and not nav.find_world_path(map.get_marker_position("spawn_alpha"),position).is_empty(),"resource point has a real connected walkable approach "+item.id)
	registry.free(); stage.queue_free(); await process_frame
	print("RESOURCE_GEOMETRY failed=",failed); quit(1 if failed else 0)
