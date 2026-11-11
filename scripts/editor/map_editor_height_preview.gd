extends Node3D
## Ephemeral presentation only: bounded tile copies, no registry/history writes.
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const HEIGHT = preload("res://scripts/editor/map_editor_height_tool.gd")
const SURFACE = preload("res://scripts/terrain/regional_hex_surface.gd")
var _signature := ""
var rebuild_count := 0

static func plan(map, center: Vector2i, radius: int, mode: String, edge: String, chosen: bool, ramp: bool, direction: int, blocked: Callable = Callable(), visited: Dictionary = {}) -> Dictionary:
	var tiles := {}
	var footprint: Array[Vector2i] = []
	for x in range(-radius - 1, radius + 2):
		for y in range(-radius - 1, radius + 2):
			var grid := center + Vector2i(x, y)
			if HEX.distance(center, grid) > radius + 1: continue
			var tile = map.get_tile_at_grid(grid)
			if tile != null: tiles[grid] = tile
	for grid: Vector2i in tiles.keys():
		if HEX.distance(center, grid) > radius or (blocked.is_valid() and blocked.call(grid)): continue
		var source = tiles[grid]
		var copy = TILE.from_dict(source.to_dict())
		if not visited.has(grid):
			var patch := HEIGHT.build_tile_height_patch(source, mode, edge, chosen, ramp, direction)
			copy.height_level = int(patch.height_level)
			copy.ramp_direction = int(patch.get("ramp_direction", source.ramp_direction))
			copy.edge_type = String(patch.edge_type)
		tiles[grid] = copy
		footprint.append(grid)
	var facts: Array = []
	for grid: Vector2i in tiles:
		var tile = tiles[grid]
		facts.append([grid, tile.height_level, tile.ramp_direction, tile.walkable, tile.object_type_id])
	return {"tiles":tiles,"footprint":footprint,"signature":JSON.stringify([map.get_instance_id(), center, radius, facts])}

func show_plan(view: Node, planned: Dictionary) -> void:
	visible = true
	var cell_size: float = view.call("_get_3d_cell_size")
	var height_step: float = view.call("_get_3d_height_step")
	var signature := JSON.stringify([planned.signature, cell_size, height_step])
	if _signature == signature: return
	_signature = signature
	rebuild_count += 1
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var caps := SurfaceTool.new()
	caps.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lines := SurfaceTool.new()
	lines.begin(Mesh.PRIMITIVE_LINES)
	for grid: Vector2i in planned.footprint:
		var tile = planned.tiles[grid]
		var center: Vector3 = view.call("_grid_to_3d_position", Vector2(grid), TILE.stand_height(tile) * height_step + .035)
		var profile: PackedFloat32Array = SURFACE.profile(tile, planned.tiles)
		var color := Color(.96,.69,.22,.45) if tile.ramp_direction >= 0 else Color(.2,.82,.9,.38)
		for index in range(12):
			var a := _point(center,index,profile,cell_size,height_step)
			var b := _point(center,(index+1)%12,profile,cell_size,height_step)
			for vertex in [center,a,b]:
				caps.set_color(color)
				caps.add_vertex(vertex)
			for vertex in [a,b]:
				lines.set_color(Color(color.r,color.g,color.b,.95))
				lines.add_vertex(vertex + Vector3.UP*.015)
		if tile.ramp_direction >= 0:
			var axis := HEX.axial_to_plane(Vector2(HEX.DIRECTIONS[tile.ramp_direction])).normalized()
			var low := center + Vector3(-axis.x*cell_size*.35,-height_step*.35,-axis.y*cell_size*.35)
			var high := center + Vector3(axis.x*cell_size*.35,height_step*.35,axis.y*cell_size*.35)
			for vertex in [low,high,high,high-Vector3(axis.x*.16,0,axis.y*.16)*cell_size+Vector3(-axis.y,0,axis.x)*cell_size*.1,high,high-Vector3(axis.x*.16,0,axis.y*.16)*cell_size-Vector3(-axis.y,0,axis.x)*cell_size*.1]:
				lines.set_color(Color(1,1,.8,1))
				lines.add_vertex(vertex + Vector3.UP*.05)
	if not planned.footprint.is_empty():
		_add_mesh(caps, "PlannedCaps")
		_add_mesh(lines, "HeightDirectionOutline")

func _point(center: Vector3, index: int, profile: PackedFloat32Array, size: float, step: float) -> Vector3:
	var point: Vector2 = SURFACE.ring[index]
	return center + Vector3(point.x*size, (profile[index] if not profile.is_empty() else 0.0)*step, point.y*size)

func _add_mesh(surface: SurfaceTool, title: String) -> void:
	var instance := MeshInstance3D.new()
	instance.name = title
	instance.mesh = surface.commit()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	instance.material_override = material
	add_child(instance)
