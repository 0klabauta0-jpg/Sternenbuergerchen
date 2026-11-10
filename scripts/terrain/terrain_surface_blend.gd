extends RefCounted
## Render-only splat mask derived once from authored cells. No navigation state.
static func build(tiles: Array) -> Dictionary:
	if tiles.is_empty(): return {}
	var low := Vector2i(2147483647,2147483647)
	var high := Vector2i(-2147483647,-2147483647)
	for tile in tiles:
		low=low.min(tile.grid_position); high=high.max(tile.grid_position)
	var dimensions := high-low+Vector2i.ONE
	var image := Image.create(dimensions.x,dimensions.y,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,1,0))
	for tile in tiles:
		var weights := Color(0,0,0,0)
		match String(tile.surface_type):
			"road": weights.r=1.0
			"rock": weights.g=1.0
			"sand": weights.b=1.0
			"water": weights.a=1.0
		image.set_pixelv(tile.grid_position-low,weights)
	return {"image":image,"bounds":Vector4(low.x,low.y,dimensions.x,dimensions.y)}
