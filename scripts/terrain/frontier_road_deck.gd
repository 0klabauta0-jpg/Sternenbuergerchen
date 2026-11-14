extends RefCounted
## Grafikpass R2: built road as one static object over all road cells.
## Render-only. Reads cell centres handed in by the view; owns no map facts,
## no collision, no navigation surface. The deck stays below the hex line
## offset, so grid, selection and units keep their existing heights.
## Follows the earlier user decision for the home base: one continuous tarred
## road with soft bends, not separate slabs or stepping stones.

const HEX = preload("res://scripts/terrain/hex_grid.gd")
const DECK_HEIGHT := 0.030
## Lane width and the two rims as fractions of the cell size.
const LANE_WIDTH := 0.80
const LINE_RIM := 0.045
const KERB_RIM := 0.075
const DISC_SEGMENTS := 18
const ASPHALT := Color("46484c")
const KERB := Color("a59f90")
const EDGE_LINE := Color("d6cba0")


## cells: Vector2i -> Vector3 (cell centre on its ground surface).
## The road is the union of rounded lanes between neighbouring road cells,
## so bends are curved and wide yards fill completely. Three stacked layers
## (kerb, edge line, asphalt) leave a continuous rim around the whole union.
static func build(parent: Node3D, cells: Dictionary, cell_size: float) -> MeshInstance3D:
	if cells.is_empty() or parent == null:
		return null
	var links: Array = []
	for grid: Vector2i in cells:
		var centre: Vector3 = cells[grid]
		for edge in range(3):
			# Three of the six directions visit every undirected link once.
			var angle: float = deg_to_rad(60.0 * float(edge))
			var neighbour_plane := Vector2(centre.x, centre.z) / cell_size + Vector2(cos(angle), sin(angle))
			var neighbour: Vector2i = HEX.round_axial(HEX.plane_to_axial(neighbour_plane))
			if cells.has(neighbour) and absf(Vector3(cells[neighbour]).y - centre.y) < 0.001:
				links.append([centre, cells[neighbour]])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var lane: float = LANE_WIDTH * cell_size
	var layers: Array = [
		[lane + (LINE_RIM + KERB_RIM) * 2.0 * cell_size, DECK_HEIGHT - 0.008, KERB],
		[lane + LINE_RIM * 2.0 * cell_size, DECK_HEIGHT - 0.004, EDGE_LINE],
		[lane, DECK_HEIGHT, ASPHALT],
	]
	for layer: Array in layers:
		var half: float = float(layer[0]) * 0.5
		var lift := Vector3(0.0, float(layer[1]), 0.0)
		var color: Color = layer[2]
		for grid: Vector2i in cells:
			var centre: Vector3 = Vector3(cells[grid]) + lift
			for index in range(DISC_SEGMENTS):
				var a: float = TAU * float(index) / float(DISC_SEGMENTS)
				var b: float = TAU * float(index + 1) / float(DISC_SEGMENTS)
				_triangle(surface, centre, centre + Vector3(cos(a), 0.0, sin(a)) * half, centre + Vector3(cos(b), 0.0, sin(b)) * half, Vector3.UP, color)
		for link: Array in links:
			var from: Vector3 = Vector3(link[0]) + lift
			var to: Vector3 = Vector3(link[1]) + lift
			var side := Vector3(to.z - from.z, 0.0, from.x - to.x).normalized() * half
			_quad(surface, from + side, to + side, to - side, from - side, Vector3.UP, color)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.93
	material.metallic = 0.0
	surface.set_material(material)
	var instance := MeshInstance3D.new()
	instance.name = "BuiltRoadDeck"
	instance.mesh = surface.commit()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta("render_only", true)
	instance.set_meta("road_cell_count", cells.size())
	instance.set_meta("road_link_count", links.size())
	parent.add_child(instance)
	return instance


static func _flat(point: Vector2) -> Vector3:
	return Vector3(point.x, 0.0, point.y)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
	# Godot front faces wind clockwise; flip so the face points along `normal`.
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var swap := b
		b = c
		c = swap
	for vertex: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.set_color(color)
		surface.add_vertex(vertex)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	_triangle(surface, a, b, c, normal, color)
	_triangle(surface, a, c, d, normal, color)
