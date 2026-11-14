extends RefCounted
## Grafikpass R2: built road as one static object over all road cells.
## Render-only. Reads cell centres handed in by the view; owns no map facts,
## no collision, no navigation surface. A raised slab with side faces (user
## decision 14.11.2026: the road is an object like the landing pads, not a
## decal). The view uses the returned per-cell lift for grid lines and units.
## Follows the earlier user decision for the home base: one continuous tarred
## road with soft bends, not separate slabs or stepping stones.

const HEX = preload("res://scripts/terrain/hex_grid.gd")
## Top of the asphalt above the ground. A real slab with visible side faces,
## like the landing pads; the view lifts grid lines and units by this amount.
const DECK_HEIGHT := 0.09
## Lane width and the two rims as fractions of the cell size.
const LANE_WIDTH := 1.10
const LINE_RIM := 0.045
const KERB_RIM := 0.10
const DISC_SEGMENTS := 18
const LINK_SEGMENTS := 6
const GRADED_LIFT := 0.03
const ASPHALT := Color("46484c")
## Look after the user's "Rostgrenze" reference (14.11.2026): dark deck in a
## pale metal frame, an orange line inside the frame, small marker lights.
const KERB := Color("b9b6aa")
const KERB_SIDE := Color("8d8a80")
const EDGE_LINE := Color("d98a2b")
const MARKER_LIGHT := Color("8fe6e0")
const MARKER_SPACING := 3
const RELAX_ITERATIONS := 12
const RELAX_LIMIT := 0.42


## cells: Vector2i -> Vector3 (cell centre on its ground surface).
## The road is the union of rounded lanes between neighbouring road cells,
## so bends are curved and wide yards fill completely. Three stacked layers
## (kerb, edge line, asphalt) leave a continuous rim around the whole union.
## height_at: optional Callable(Vector2 xz) -> float, the ground surface height.
## With it the deck follows graded ramps; without it every cell is flat.
static func build(parent: Node3D, cells: Dictionary, cell_size: float, height_at: Callable = Callable()) -> MeshInstance3D:
	if cells.is_empty() or parent == null:
		return null
	var graded: bool = height_at.is_valid()
	# Neighbour table on the axial grid (same height only).
	var neighbours: Dictionary = {}
	for grid: Vector2i in cells:
		var found: Array[Vector2i] = []
		for direction: Vector2i in HEX.DIRECTIONS:
			var other: Vector2i = grid + direction
			if not cells.has(other):
				continue
			var here: Vector3 = cells[grid]
			var there: Vector3 = cells[other]
			if graded:
				# Joined when the ground is continuous across the shared edge.
				var middle := Vector2(here.x + there.x, here.z + there.z) * 0.5
				var step := Vector2(there.x - here.x, there.z - here.z) * 0.04
				if absf(float(height_at.call(middle - step)) - float(height_at.call(middle + step))) < 0.08:
					found.append(other)
			elif absf(there.y - here.y) < 0.001:
				found.append(other)
		neighbours[grid] = found
	# A lane that runs between two hex axes steps from row to row. Relax every
	# plain lane cell (exactly two neighbours) towards its neighbours so the
	# road reads as one drawn line; junctions, ends and yards stay put, and no
	# centre leaves its own cell.
	var points: Dictionary = cells.duplicate()
	var limit: float = cell_size * RELAX_LIMIT
	for iteration in range(RELAX_ITERATIONS):
		var relaxed: Dictionary = {}
		for grid: Vector2i in cells:
			var around: Array = neighbours[grid]
			if around.size() != 2:
				relaxed[grid] = points[grid]
				continue
			var target: Vector3 = Vector3(points[grid]) * 0.5 + (Vector3(points[around[0]]) + Vector3(points[around[1]])) * 0.25
			var offset: Vector3 = target - Vector3(cells[grid])
			offset.y = 0.0
			if offset.length() > limit:
				offset = offset.normalized() * limit
			relaxed[grid] = Vector3(cells[grid]) + offset
		points = relaxed
	# Reuse the exact grading decision at each relaxed road centre for both
	# the mesh and its visual support. This is cold build data, never terrain.
	var lift_by_cell: Dictionary = {}
	for grid: Vector2i in cells:
		lift_by_cell[grid] = DECK_HEIGHT + (GRADED_LIFT if _is_graded(Vector3(points[grid]), height_at, cell_size) else 0.0)
	var links: Array = []
	for grid: Vector2i in cells:
		for index in range(3):
			# Three of the six directions visit every undirected link once.
			var other: Vector2i = grid + HEX.DIRECTIONS[index]
			if (neighbours[grid] as Array).has(other):
				links.append([points[grid], points[other]])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var lane: float = LANE_WIDTH * cell_size
	var layers: Array = [
		[lane + (LINE_RIM + KERB_RIM) * 2.0 * cell_size, DECK_HEIGHT - 0.012, KERB],
		[lane + LINE_RIM * 2.0 * cell_size, DECK_HEIGHT - 0.006, EDGE_LINE],
		[lane, DECK_HEIGHT, ASPHALT],
	]
	for layer_index in range(layers.size()):
		var layer: Array = layers[layer_index]
		var half: float = float(layer[0]) * 0.5
		var lift: float = float(layer[1])
		var color: Color = layer[2]
		# Kerb and edge line are thin stacked sheets. On a graded ramp their
		# different outlines would interleave, so only the asphalt climbs it.
		var top_layer: bool = layer_index == layers.size() - 1
		for grid: Vector2i in cells:
			var cell_graded: bool = float(lift_by_cell[grid]) > DECK_HEIGHT
			if not top_layer and cell_graded:
				continue
			# A slab on a ramp sits a little prouder, so the coarser deck
			# triangles never dip below the faceted ramp cap.
			var extra: float = GRADED_LIFT if cell_graded else 0.0
			var centre: Vector3 = _on_ground(Vector3(points[grid]), height_at, lift, extra)
			var previous: Vector3 = _on_ground(Vector3(points[grid]) + Vector3(half, 0.0, 0.0), height_at, lift, extra)
			for index in range(1, DISC_SEGMENTS + 1):
				var angle: float = TAU * float(index) / float(DISC_SEGMENTS)
				var rim: Vector3 = _on_ground(Vector3(points[grid]) + Vector3(cos(angle), 0.0, sin(angle)) * half, height_at, lift, extra)
				_triangle(surface, centre, previous, rim, color)
				if layer_index == 0:
					_wall(surface, previous, rim, lift + 0.02, (previous + rim) * 0.5 - centre, KERB_SIDE)
				previous = rim
		for link: Array in links:
			var from: Vector3 = link[0]
			var to: Vector3 = link[1]
			var side := Vector3(to.z - from.z, 0.0, from.x - to.x).normalized() * half
			var pieces: int = LINK_SEGMENTS if graded else 1
			for piece in range(pieces):
				var a: Vector3 = from.lerp(to, float(piece) / float(pieces))
				var b: Vector3 = from.lerp(to, float(piece + 1) / float(pieces))
				var a_extra: float = GRADED_LIFT if _is_graded(a, height_at, cell_size) else 0.0
				var b_extra: float = GRADED_LIFT if _is_graded(b, height_at, cell_size) else 0.0
				if not top_layer and (a_extra > 0.0 or b_extra > 0.0):
					continue
				var a_left: Vector3 = _on_ground(a + side, height_at, lift, a_extra)
				var a_right: Vector3 = _on_ground(a - side, height_at, lift, a_extra)
				var b_left: Vector3 = _on_ground(b + side, height_at, lift, b_extra)
				var b_right: Vector3 = _on_ground(b - side, height_at, lift, b_extra)
				_triangle(surface, a_left, b_left, b_right, color)
				_triangle(surface, a_left, b_right, a_right, color)
				if layer_index == 0:
					_wall(surface, a_left, b_left, lift + 0.02, side, KERB_SIDE)
					_wall(surface, a_right, b_right, lift + 0.02, -side, KERB_SIDE)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.93
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.metallic = 0.0
	surface.set_material(material)
	var instance := MeshInstance3D.new()
	instance.name = "BuiltRoadDeck"
	instance.mesh = surface.commit()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta("render_only", true)
	instance.set_meta("road_cell_count", cells.size())
	instance.set_meta("road_link_count", links.size())
	instance.set_meta("road_surface_lift_by_cell", lift_by_cell)
	parent.add_child(instance)
	_add_marker_lights(instance, cells, points, neighbours, lift_by_cell, cell_size, height_at)
	return instance


## Small lights on the frame of plain lane cells, on both sides, every few
## cells. Render-only child of the deck; unshaded so it reads at night too.
static func _add_marker_lights(deck: MeshInstance3D, cells: Dictionary, points: Dictionary, neighbours: Dictionary, lift_by_cell: Dictionary, cell_size: float, height_at: Callable) -> void:
	var lights := SurfaceTool.new()
	lights.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stud := BoxMesh.new()
	stud.size = Vector3(0.14, 0.04, 0.14) * cell_size
	var offset: float = (LANE_WIDTH * 0.5 + LINE_RIM + KERB_RIM * 0.5) * cell_size
	var count := 0
	for grid: Vector2i in cells:
		var around: Array = neighbours[grid]
		if around.size() != 2 or float(lift_by_cell[grid]) > DECK_HEIGHT or posmod(grid.x * 2 + grid.y, MARKER_SPACING) != 0:
			continue
		var along: Vector3 = Vector3(points[around[1]]) - Vector3(points[around[0]])
		along.y = 0.0
		if along.length_squared() < 0.0001:
			continue
		var side := Vector3(along.z, 0.0, -along.x).normalized() * offset
		for direction: float in [-1.0, 1.0]:
			var spot: Vector3 = _on_ground(Vector3(points[grid]) + side * direction, height_at, DECK_HEIGHT + 0.012)
			lights.append_from(stud, 0, Transform3D(Basis(Vector3.UP, atan2(along.x, along.z)), spot))
			count += 1
	if count == 0:
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = MARKER_LIGHT
	lights.set_material(material)
	var node := MeshInstance3D.new()
	node.name = "BuiltRoadLights"
	node.mesh = lights.commit()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_meta("render_only", true)
	deck.add_child(node)
	deck.set_meta("road_marker_light_count", count)


static func _wall(surface: SurfaceTool, a: Vector3, b: Vector3, drop: float, outward: Vector3, color: Color) -> void:
	# Vertical side face of the slab. Faces inside the union are hidden under
	# the top surface; the material is double-sided, so only the normal matters.
	var normal := Vector3(outward.x, 0.0, outward.z)
	if normal.length_squared() < 0.0000000001:
		return
	normal = normal.normalized()
	var down := Vector3(0.0, -drop, 0.0)
	for vertex: Vector3 in [a, b, b + down, a, b + down, a + down]:
		surface.set_normal(normal)
		surface.set_color(color)
		surface.add_vertex(vertex)


static func _is_graded(point: Vector3, height_at: Callable, cell_size: float) -> bool:
	if not height_at.is_valid():
		return false
	var here := float(height_at.call(Vector2(point.x, point.z)))
	# Wide enough to include the flat landing row between two rises.
	for index in range(6):
		var angle: float = TAU * float(index) / 6.0 + PI / 6.0
		var probe := Vector2(point.x, point.z) + Vector2(cos(angle), sin(angle)) * cell_size * 0.8
		if absf(float(height_at.call(probe)) - here) > 0.02:
			return true
	return false


static func _on_ground(point: Vector3, height_at: Callable, lift: float, graded_lift: float = 0.0) -> Vector3:
	if height_at.is_valid():
		point.y = float(height_at.call(Vector2(point.x, point.z)))
	return point + Vector3(0.0, lift + graded_lift, 0.0)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	# Godot front faces wind clockwise; flip so the face points upwards.
	var normal: Vector3 = (c - a).cross(b - a)
	if normal.y < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	if normal.length_squared() < 0.0000000001:
		return
	normal = normal.normalized()
	for vertex: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.set_color(color)
		surface.add_vertex(vertex)
