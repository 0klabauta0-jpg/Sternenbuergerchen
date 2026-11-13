extends RefCounted
## Read-only geometry: terrain owns height/walkability; imported models only lift
## the drawn contour above their existing walkable floor.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const SURFACE = preload("res://scripts/terrain/regional_hex_surface.gd")

static func outline(tile, tiles: Dictionary, cell_size: float, height_step: float, model_lift: float, offset: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	var center: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position)) * cell_size
	var top: float = TILE.stand_height(tile) * height_step + model_lift + offset
	var profile: PackedFloat32Array = SURFACE.profile(tile, tiles)
	for index in range(12):
		var point: Vector2 = SURFACE.ring[index] * cell_size
		result.append(Vector3(center.x + point.x, top + (profile[index] * height_step if not profile.is_empty() else 0.0), center.y + point.y))
	return result

static func central_floor_height(model: Node3D) -> float:
	# Corridors may include high walls/ceilings. Read the lowest upward-facing
	# actual floor triangle under the center, never the model's wall-top bounds.
	var heights: Array[float] = []
	_collect_floor_triangles(model, Transform3D.IDENTITY, heights)
	return heights.min() if not heights.is_empty() else 0.0

static func _collect_floor_triangles(node: Node, parent: Transform3D, heights: Array[float]) -> void:
	var transform: Transform3D = parent * node.transform if node is Node3D else parent
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			if node.mesh is ArrayMesh and node.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES: continue
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var count: int = vertices.size() if indices.is_empty() else indices.size()
			for index in range(0, count - 2, 3):
				var ia: int = index if indices.is_empty() else indices[index]
				var ib: int = index + 1 if indices.is_empty() else indices[index + 1]
				var ic: int = index + 2 if indices.is_empty() else indices[index + 2]
				var a: Vector3 = transform * vertices[ia]
				var b: Vector3 = transform * vertices[ib]
				var c: Vector3 = transform * vertices[ic]
				var normal: Vector3 = transform.basis * normals[ia] if normals.size() == vertices.size() else (c - a).cross(b - a)
				if normal.normalized().y < 0.7: continue
				var denominator: float = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
				if absf(denominator) < 0.000001: continue
				var wa: float = ((b.z - c.z) * -c.x + (c.x - b.x) * -c.z) / denominator
				var wb: float = ((c.z - a.z) * -c.x + (a.x - c.x) * -c.z) / denominator
				var wc: float = 1.0 - wa - wb
				if minf(wa, minf(wb, wc)) >= -0.00001:
					heights.append(wa * a.y + wb * b.y + wc * c.y)
	for child in node.get_children(): _collect_floor_triangles(child, transform, heights)
