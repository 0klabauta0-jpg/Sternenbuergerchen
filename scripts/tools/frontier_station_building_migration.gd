extends RefCounted
## Offline authoring only. Runtime rendering reads saved facts and never calls this.
const CATALOG_PATH := "res://data/frontier_building_visual_catalog.json"
static func apply(map_data) -> bool:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	var presentation: Dictionary = map_data.get_place_presentation()
	var props: Array = presentation.get("props", [])
	var anchors: Array = []
	for tile in map_data.get_tiles():
		if String(tile.object_type_id) in ["factory_building_a", "factory_building_d"]: anchors.append(tile)
	for anchor in anchors:
		var id := "frontier_habitat_exterior" if String(anchor.object_type_id) == "factory_building_a" else "frontier_hall_exterior"
		var entry: Dictionary = catalog[id]
		var minimum: Array = entry.min
		var maximum: Array = entry.max
		var scale_value: float = anchor.object_scale
		var yaw: float = anchor.object_rotation_degrees
		# Keep the authored watch-route points outside the larger current hulls.
		# Rotate the one-cell inward shift with the stamped source sector.
		var inward := Vector2.RIGHT if id == "frontier_habitat_exterior" else Vector2.LEFT
		var center: Vector2 = Vector2(anchor.grid_position) + inward.rotated(deg_to_rad(yaw - 180.0)).round()
		var transform := Transform2D(deg_to_rad(yaw), center)
		var rect := Rect2()
		var first := true
		for x in [float(minimum[0]), float(maximum[0])]:
			for z in [float(minimum[2]), float(maximum[2])]:
				var point: Vector2 = transform * (Vector2(x,z) * scale_value)
				if first: rect = Rect2(point,Vector2.ZERO); first = false
				else: rect = rect.expand(point)
		var reserved: Array = []
		for x in range(floori(rect.position.x - .5), ceili(rect.end.x + .5) + 1):
			for z in range(floori(rect.position.y - .5), ceili(rect.end.y + .5) + 1):
				if not rect.intersects(Rect2(Vector2(x-.5,z-.5),Vector2.ONE)): continue
				var tile = map_data.get_tile_at_grid(Vector2i(x,z))
				if tile == null: push_error("Building outside map"); return false
				if tile != anchor and not String(tile.object_type_id) in ["", "frontier_scene_solid"]: push_error("Building overlaps an authored object"); return false
				reserved.append([x,z])
		for grid in reserved:
			var tile = map_data.get_tile_at_grid(Vector2i(grid[0],grid[1]))
			tile.object_type_id = "frontier_scene_solid"
			tile.walkable = false
			tile.blocks_los = true
			tile.cover_value = 80
			tile.object_height = mini(3, ceili(float(maximum[1]) * scale_value / .42))
		props.append({"asset_id": id, "path": entry.model_path, "center": [center.x,center.y], "scale": scale_value, "rotation_degrees": yaw, "elevation": float(anchor.height_level)*.5, "reserved_grids": reserved})
	if not anchors.is_empty():
		presentation["props"] = props
		presentation["migration_id"] = "frontier_buildings_20261110"
		map_data.set_place_presentation(presentation)
	map_data.set_terrain_visual_theme_id("frontier_illustrated_v1")
	return true
