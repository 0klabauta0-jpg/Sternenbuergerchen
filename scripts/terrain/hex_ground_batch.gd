extends RefCounted
## Visual hex columns grouped by height and material, never one resource per tile.

var _groups: Dictionary = {}
var _meshes: Dictionary = {}

func clear() -> void:
	_groups.clear()

func mesh_for(height: float, radius: float, sides_only: bool = false) -> CylinderMesh:
	var key := "%0.5f:%0.5f:%s" % [height, radius, sides_only]
	if _meshes.has(key):
		return _meshes[key]
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.cap_top = not sides_only
	mesh.cap_bottom = not sides_only
	_meshes[key] = mesh
	return mesh

func queue_tile(center: Vector3, color: Color, cell_size: float, material: Material, deck: bool = false) -> void:
	var bottom_y := center.y - 0.14 if deck else -0.09
	var height := maxf(center.y - bottom_y, 0.035)
	# Thin caps receive shadows; regional cliff/ramp meshes own the height
	# silhouette. Separate them from equally thick solid columns so insertion
	# order cannot change shadow ownership.
	var key := "%0.4f:%s:flat:%s:deck:%s" % [height, color.to_html(), is_zero_approx(center.y), deck]
	if not _groups.has(key):
		_groups[key] = {"mesh":mesh_for(height, cell_size / sqrt(3.0)), "material":material, "transforms":[], "top_y":center.y, "deck":deck}
	var position := Vector3(center.x, bottom_y + height * 0.5, center.z)
	_groups[key]["transforms"].append(Transform3D(Basis.IDENTITY, position))

func flush(parent: Node3D, cast_flat_ground_shadows: bool = true) -> Dictionary:
	var tile_count := 0
	var instance_count := 0
	var shadow_count := 0
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
		if not cast_flat_ground_shadows:
			# The visible cap receives light/shadows but cannot shadow itself.
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
		if not cast_flat_ground_shadows and not bool(group["deck"]) and not is_zero_approx(float(group["top_y"])):
			# Full columns retain their actual height silhouette through a cached
			# sides-only shadow hull. No top triangles remain to cause H1 acne.
			var source: CylinderMesh = group["mesh"]
			var hull_mesh: CylinderMesh = mesh_for(source.height, source.top_radius, true)
			var hull := MultiMesh.new()
			hull.transform_format = MultiMesh.TRANSFORM_3D
			hull.mesh = hull_mesh
			hull.instance_count = transforms.size()
			for index in range(transforms.size()): hull.set_instance_transform(index, transforms[index])
			var caster := MultiMeshInstance3D.new()
			caster.name = "HexGroundSideShadow_%d" % shadow_count
			caster.multimesh = hull
			caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			parent.add_child(caster)
			shadow_count += 1
		tile_count += transforms.size()
		instance_count += 1
	_groups.clear()
	return {"tile_count":tile_count, "batch_count":instance_count, "shadow_batch_count":shadow_count}
