extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var path:="res://maps/satellite_crash_site.json"
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	var site: Dictionary=catalog.satellite_crash.freighter_wreck_01
	var root3:=Node3D.new(); root.add_child(root3)
	var visual: Node3D=load("res://scripts/terrain/location_resource_visuals.gd").build(site); root3.add_child(visual)
	var origin: Vector2=load("res://scripts/terrain/hex_grid.gd").axial_to_plane(Vector2(site.grid[0],site.grid[1]))
	visual.position=Vector3(origin.x,0,origin.y)
	var bounds: AABB=load("res://scripts/terrain/place_reference_dressing.gd").mesh_bounds(visual,root3)
	var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(.58)
	var count:=0
	for tile: Dictionary in data.tiles:
		var point: Vector2=load("res://scripts/terrain/hex_grid.gd").axial_to_plane(Vector2(tile.grid_position.x,tile.grid_position.y))
		if footprint.has_point(point):
			tile.walkable=false; tile.blocks_los=true; tile.object_type_id="resource_wreck_solid"; tile.object_height=clampi(ceili(bounds.end.y/.42),1,3); tile.cover_value=80; count+=1
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(data)+"\n"); file.close()
	print("RESOURCE_WRECK_BLOCKERS ",count," bounds=",bounds," interaction_outside=",not footprint.has_point(origin))
	root3.queue_free(); await process_frame; quit(0 if count>0 and not footprint.has_point(origin) else 1)
