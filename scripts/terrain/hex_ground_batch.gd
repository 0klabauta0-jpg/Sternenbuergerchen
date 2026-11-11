extends RefCounted
## Visual hex columns grouped by height and material, never one resource per tile.

var _groups: Dictionary = {}
var _meshes: Dictionary = {}

func clear() -> void:
	_groups.clear()

func mesh_for(height: float, radius: float) -> CylinderMesh:
	var key := "%0.5f:%0.5f" % [height, radius]
	if _meshes.has(key):
		return _meshes[key]
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	_meshes[key] = mesh
	return mesh

func queue_tile(center: Vector3, color: Color, cell_size: float, material: Material, deck: bool = false) -> void:
	var bottom_y := center.y - 0.14 if deck else -0.09
	var height := maxf(center.y - bottom_y, 0.035)
	var key := "%0.4f:%s" % [height, color.to_html()]
	if not _groups.has(key):
		_groups[key] = {"mesh":mesh_for(height, cell_size / sqrt(3.0)), "material":material, "transforms":[]}
	var position := Vector3(center.x, bottom_y + height * 0.5, center.z)
	_groups[key]["transforms"].append(Transform3D(Basis.IDENTITY, position))

func flush(parent: Node3D) -> Dictionary:
	var tile_count := 0
	var instance_count := 0
	for group in _groups.values():
		var transforms: Array = group["transforms"]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = group["mesh"]
		multimesh.instance_count = transforms.size()
		for index in range(transforms.size()):
			multimesh.set_instance_transform(index, transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "HexGroundBatch_%d" % instance_count
		instance.multimesh = multimesh
		instance.material_override = group["material"]
		parent.add_child(instance)
		tile_count += transforms.size()
		instance_count += 1
	_groups.clear()
	return {"tile_count":tile_count, "batch_count":instance_count}
