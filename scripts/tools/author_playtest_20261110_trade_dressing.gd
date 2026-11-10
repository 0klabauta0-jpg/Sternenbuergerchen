extends SceneTree
## Explicit offline authoring. Runtime rendering never changes navigation facts.
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var path:="res://maps/trade_outpost.json"
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var stage:=Node3D.new(); root.add_child(stage)
	var built: Dictionary=load("res://scripts/terrain/place_reference_dressing.gd").build(stage,data.place_presentation)
	var blocks:=0
	for tile: Dictionary in Array(data.tiles):
		var grid:=Vector2(float(tile.grid_position.x),float(tile.grid_position.y))
		var point: Vector2=load("res://scripts/terrain/hex_grid.gd").axial_to_plane(grid)
		for bounds: AABB in Array(built.blockers):
			var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(.58)
			if footprint.has_point(point):
				tile.walkable=false; tile.blocks_los=true; tile.object_type_id="frontier_scene_solid"
				tile.object_height=clampi(ceili(bounds.end.y/.42),1,3); tile.cover_value=80; blocks+=1; break
		if bool(tile.walkable):
			var distance:=INF
			for span in [[Vector2(14,6.9282),Vector2(16.4,4.6)],[Vector2(14,6.9282),Vector2(8,5.2)]]:
				distance=minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,span[0],span[1])))
			if distance<.72: tile.surface_type="road"
			elif distance<1.25: tile.surface_type="ground"
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(data)+"\n"); file.close()
	print("AUTHORED_TRADE solids=",blocks," bounds=",built.blockers)
	stage.queue_free(); await process_frame; quit()
